# aws_infra
This repository represents the infrastructure for my personal AWS cloud

## Contents
- DynamoDB Tables
  - compliments: table for the compliments for my Telegram Bot;
  - users: table where telegram users are stored;
  - `dynamodb/ttrpg_club/dev/` and `dynamodb/ttrpg_club/prod/`: **all 11 ttrpg_club tables,
    one environment per folder, each folder a single Terraform state** — no more visiting
    a separate directory per table. `dev` is the live environment (real member data,
    read by `lambda/ttrpg_club_api`); `prod` is a separate, empty environment, now read
    by `lambda/ttrpg_club_api_prod` — see "Production website stack" below. The 11 tables
    in each: `users`,
    `signup_requests`, `game_systems`, `games`, `game_participants`, `game_poll_votes`,
    `game_comments`, `settings` (the original 8, see `../ttrpg_website2` for the
    application code), plus `telegram_rating_polls` / `telegram_rating_votes` (the
    Telegram Mini App's personal-stats feature — capture `/rate` poll answers straight
    from the club's Telegram chat, keyed purely by Telegram user ID; the polls table
    remembers each poll's creator/GM via a `creatorUserId-index` GSI) and
    `telegram_feedback` (detailed, mostly-anonymous session feedback submitted via the
    Mini App's feedback form; its DynamoDB Stream triggers a notifier in
    `../ttrpg_poll_bot` that DMs the GM). Prod table names are prefixed
    `ttrpg_club_prod_*`; dev keeps the original unprefixed names. Both publish their
    signup-requests/feedback stream ARNs to SSM (`/ttrpg_club/...` for dev,
    `/ttrpg_club/prod/...` for prod) for `../ttrpg_poll_bot` to read.
  - **Migrating from the old per-table layout**: if you still have the 11 old
    `dynamodb/ttrpg_club_<table>/` directories, they're superseded by
    `dynamodb/ttrpg_club/dev/` above — see that folder's `migrate-dev-state.sh`, which
    moves each table's existing Terraform state into the consolidated one via
    `terraform state mv` (never destroys/recreates anything). Only delete the old
    directories after `terraform plan` in the new one shows "No changes."
- Lambda. Contains 3 lambda functions. Every lambda is connected to my TG Bots.
  - bot_alert: Lambda which is triggered by cron and sends users compliments;
  - bot: Lambda that processes all incoming messages;
  - json_refiner: a bot that formats "Python Dict" to standard JSON format;
  - ttrpg_club_api: the TTRPG club website's API (Node.js/TS, one Lambda behind an HTTP API
    that routes internally — see ttrpg_website2/backend). `ttrpg_club_api_prod` is its
    full production counterpart — see "Production website stack" below.
  - ttrpg_poll_bot: the club's Telegram bot (Python), 3 functions — `webhook` (behind its
    own HTTP API, receives Telegram updates), `notifySignup` and `notifyFeedback` (each
    triggered directly by a DynamoDB Stream from two of the `dynamodb/ttrpg_club/dev`
    tables above). Previously deployed via Serverless Framework/CloudFormation; migrated
    to this Terraform module so it works the same way as `ttrpg_club_api` — Terraform
    owns the infra, code ships separately via `aws lambda update-function-code` (see
    `../ttrpg_poll_bot/build.sh` and its GitHub Actions workflow). If migrating an
    existing Serverless deployment rather than starting fresh, see this module's
    `import-from-serverless.sh` — it imports the live resources with zero downtime
    instead of recreating them.
    Also creates an isolated `-dev-` copy of all 3 functions (own IAM role, own bot
    token, own `/dev/webhook` route on the same API Gateway) pointed at the
    (currently empty) `dynamodb/ttrpg_club/prod` tables instead of the real `dev` ones —
    a safe sandbox for testing bot changes without touching real club data. See
    `../ttrpg_poll_bot/README_LAMBDA.md`'s "Dev Stage" section.
- Lambda Layers: so that one layer could be reused inside all my lambda functions;
- Cognito: `ttrpg_club` — User Pool for the club website (admin-provisioned members only,
  no public self-signup). `ttrpg_club_prod` is a separate, empty prod user pool — see
  "Production website stack" below.
- S3 / CloudFront: `ttrpg_club_frontend` (static site hosting) and `ttrpg_club_avatars`
  (member/GM profile pictures). `ttrpg_club_frontend_prod` and `ttrpg_club_avatars_prod`
  are their prod counterparts (`ttrpg_club_frontend_dev`, despite the name, is unrelated —
  it's a sandbox for `ttrpg_poll_bot`'s Mini App testing, not a website environment).
- SSM: the generic `ssm` module (personal bot secrets). (An earlier `ssm/ttrpg_club`
  module briefly existed for a dedicated club bot token/chat-id — since superseded by
  reusing `ttrpg_poll_bot` instead, those files were removed. The two placeholder
  parameters it created may still exist in SSM, unused — safe to ignore or delete
  manually via `aws ssm delete-parameter`.)
- Security Groups
- VPC

## How to Apply
To apply all of the resources you need to apply them in particular order:
1. init
2. VPC
3. Security Groups
4. Lambda Layers
5. DynamoDB
6. Lambda

For the TTRPG club website specifically, apply in this order (each is an independent
root module/state, so order matters where one references another's remote state —
notably, `dynamodb/ttrpg_club/dev` must be applied *before* `lambda/ttrpg_club_api`,
which reads all 11 table outputs from it):
1. `dynamodb/ttrpg_club/dev` (all 11 tables, one `terraform apply`)
2. `cognito/ttrpg_club`
3. `s3/ttrpg_club_avatars`
4. `s3_cloudfront/ttrpg_club_frontend`
5. `npm run build --workspace backend` in `ttrpg_website2` (bundles the Lambda code
   `lambda/ttrpg_club_api` references)
6. `lambda/ttrpg_club_api`
7. In `../ttrpg_poll_bot`: `serverless deploy --param="adminChatId=<your chat id>"`. The
   signup-requests and feedback stream ARNs need no `--param` — step 1 above publishes
   both stream ARNs to SSM (`/ttrpg_club/signup_requests_stream_arn`,
   `/ttrpg_club/telegram_feedback_stream_arn`) that `ttrpg_poll_bot`'s `serverless.yml`
   reads directly via `${ssm:...}`. Add `--param="miniAppDeepLink=<t.me deep link>"`
   once you've registered the Mini App with @BotFather (see
   `../ttrpg_poll_bot/README_LAMBDA.md`'s Personal Stats and Session Feedback sections).

After step 4, sync the frontend build and invalidate the CDN cache:
```
npm run build --workspace frontend   # in ttrpg_website2, with .env pointed at the outputs below
aws s3 sync frontend/dist s3://ttrpg-club-frontend --delete
aws cloudfront create-invalidation --distribution-id <s3_cloudfront/ttrpg_club_frontend output> --paths "/*"
```

Frontend `.env` values come from these modules' outputs: `VITE_API_BASE_URL` ←
`lambda/ttrpg_club_api` `api_base_url`; `VITE_COGNITO_USER_POOL_ID` /
`VITE_COGNITO_CLIENT_ID` ← `cognito/ttrpg_club`; `VITE_AVATAR_CDN_BASE_URL` ←
`https://` + `s3/ttrpg_club_avatars` `distribution_domain_name`.

The very first admin needs to be created manually (there's no admin until one exists):
`aws cognito-idp admin-create-user` + `aws cognito-idp admin-add-user-to-group --group-name admin`,
plus a matching item in `ttrpg_club_users` with `"roles": ["admin"]`.

### Production website stack

A second, fully independent copy of the whole website stack — its own Cognito user
pool, avatars bucket, frontend bucket/CloudFront, and API Lambda/API Gateway — reading
`dynamodb/ttrpg_club/prod` (empty; a brand-new member base, not the real `dev` data).
No custom domain yet — both stacks use bare CloudFront/execute-api URLs. Apply order,
same dependency shape as the dev stack above:
1. `dynamodb/ttrpg_club/prod` (already exists/applied)
2. `cognito/ttrpg_club_prod`
3. `s3/ttrpg_club_avatars_prod`
4. `s3_cloudfront/ttrpg_club_frontend_prod`
5. `npm run build --workspace backend` in `ttrpg_website2` (same bundle `lambda/ttrpg_club_api_prod` reads — both stacks run identical code)
6. `lambda/ttrpg_club_api_prod`
7. Re-apply `iam/github_actions_ttrpg_club` — its policy now covers both stacks, and it reads step 4's and step 6's outputs via remote state, so it must come *after* them.

Then the same frontend sync/invalidation and first-admin steps as above, targeted at
this stack's own bucket/distribution/user pool (nothing is shared between the two
stacks — a prod admin has to be created here too, independently of dev's).

**CI/CD branch promotion**: `ttrpg_website2`'s `deploy-backend.yml` / `deploy-frontend.yml`
trigger on push to either `develop` (deploys to the dev stack) or `main` (deploys to
this prod stack), selecting a GitHub Environment (`development` / `production`) by
branch name so each deploy reads that environment's own variables
(`LAMBDA_FUNCTION_NAME`, `FRONTEND_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`,
`VITE_API_BASE_URL`, `VITE_COGNITO_USER_POOL_ID`, `VITE_COGNITO_CLIENT_ID`,
`VITE_AVATAR_CDN_BASE_URL`) — both environments need these 7 variables set (in the repo's
Settings → Environments), pointed at each stack's own Terraform outputs. The
`AWS_DEPLOY_ROLE_ARN` secret is shared (one broadened role, not per-environment) since
step 7 above already scopes its policy to both stacks' exact resource ARNs.

## Lambda
To deploy lambda functions it is needed to have them locally near the "aws_infra" repository.

## Technical Debt
1. In the future, lambda should be fetched from repositories and its repository should contain the terraform module to deploy it.
2. Draw a diagram of the infrastructure.
3. Separate API Gateway from Lambda folder.
