# aws_infra
This repository represents the infrastructure for my personal AWS cloud

## Contents
- DynamoDB Tables
  - compliments: table for the compliments for my Telegram Bot;
  - users: table where telegram users are stored;
  - `dynamodb/ttrpg_club/dev/` and `dynamodb/ttrpg_club/prod/`: **all 11 ttrpg_club tables,
    one environment per folder, each folder a single Terraform state** — no more visiting
    a separate directory per table. Two fully independent, symmetric environments: table
    names are prefixed `ttrpg_club_dev_*` / `ttrpg_club_prod_*` respectively. The 5
    tables in each: `users`, `signup_requests`, `game_systems`, `game_comments` (keyed by
    Telegram `pollId`, not a site-native game id — see `../ttrpg_website2` for the
    application code), `settings`, plus `telegram_rating_polls` /
    `telegram_rating_votes` (the Telegram Mini App's personal-stats feature — capture
    `/rate` poll answers straight from the club's Telegram chat, keyed purely by
    Telegram user ID; the polls table remembers each poll's creator/GM via a
    `creatorUserId-index` GSI) and `telegram_feedback` (detailed, mostly-anonymous
    session feedback submitted via the Mini App's feedback form; its DynamoDB Stream
    triggers a notifier in `../ttrpg_poll_bot` that DMs the GM). Both publish their
    signup-requests/feedback stream ARNs to SSM under `/ttrpg_club/<env>/...` for
    `../ttrpg_poll_bot` to read.
  - **Migrating from the old per-table layout**: if you still have the 11 old
    `dynamodb/ttrpg_club_<table>/` directories, they're superseded by
    `dynamodb/ttrpg_club/dev/` above — see that folder's `migrate-dev-state.sh`, which
    moves each table's existing Terraform state into the consolidated one via
    `terraform state mv` (never destroys/recreates anything). Only delete the old
    directories after `terraform plan` in the new one shows "No changes."
  - `dynamodb/entutor/prod/`: **all 5 tables for the EnTutor English-vocabulary bot
    in one folder / one state**, same consolidated shape as `ttrpg_club` above.
    `entutor_prod_users` (an `active-index` GSI so the hourly scheduler never scans),
    `entutor_prod_words` (a `cefr-rank-index` GSI — "next unseen words at this level,
    most frequent first" in a single Query), `entutor_prod_cards` (per-user spaced-
    repetition state, with a `dueDate-index` **LSI** driving the one query behind every
    daily session), `entutor_prod_exercises` (the cloze exercises — global and shared by
    every user, which is why adding users adds no content cost), and
    `entutor_prod_sessions` (one day's seven items; **TTL on `expiresAt`** so it prunes
    itself). Application code is in `../entutor`.
- Lambda. Every lambda is connected to my TG Bots.
  - bot_alert: Lambda which is triggered by cron and sends users compliments;
  - bot: Lambda that processes all incoming messages;
  - json_refiner: a bot that formats "Python Dict" to standard JSON format;
  - `ttrpg_club_api_dev` / `ttrpg_club_api_prod`: the TTRPG club website's API (Node.js/TS,
    one Lambda behind an HTTP API that routes internally — see ttrpg_website2/backend),
    a fully symmetric dev/prod pair — see "Website stack" below. Replaces the old
    unsuffixed `ttrpg_club_api` module (retired).
  - `ttrpg_poll_bot_dev` / `ttrpg_poll_bot_prod`: the club's Telegram bot (Python), 3
    functions each — `webhook` (behind its own HTTP API, receives Telegram updates),
    `notifySignup` and `notifyFeedback` (each triggered directly by a DynamoDB Stream
    from that same environment's `dynamodb/ttrpg_club/<env>` tables). Fully independent
    stacks: separate IAM roles, separate API Gateways (separate webhook URLs/bots),
    separate Terraform-managed SSM placeholders for the bot token and admin chat ID
    (`/ttrpg_club/<env>/poll_bot/token`, `/ttrpg_club/<env>/telegram_admin_chat_id`).
    Originally deployed via Serverless Framework/CloudFormation, then migrated to one
    combined Terraform module, then split into these two standalone modules — see
    `lambda/ttrpg_poll_bot/migrate-to-split-modules.sh` for that last, zero-downtime
    split (the live prod bot's function names/API Gateway never changed across any of
    these migrations, so its registered Telegram webhook was never disrupted). If
    migrating an existing Serverless deployment from scratch, see
    `ttrpg_poll_bot_prod/import-from-serverless.sh`.
  - `entutor_prod`: the EnTutor English-vocabulary bot (Python, see `../entutor`), 3
    functions behind one shared IAM role — `webhook` (behind its own HTTP API, receives
    Telegram updates and grades inline-button answers), `scheduler` (EventBridge, runs
    **hourly** and queues the users whose *local* clock reads 14:00 — that's how
    per-user timezones work without a cron rule per zone), and `sender` (SQS-triggered,
    builds and delivers one user's daily session). The SQS queue between scheduler and
    sender exists for Telegram's ~30 msg/s cap: reserved concurrency on `sender`
    throttles the fan-out and a DLQ catches users who fail three times. Terraform-managed
    SSM placeholders for the bot token and the webhook secret
    (`/entutor/prod/bot/token`, `/entutor/prod/bot/webhook_secret`) — the webhook Lambda
    verifies Telegram's `X-Telegram-Bot-Api-Secret-Token` header and 403s otherwise,
    since the API Gateway URL is necessarily public. **No Anthropic API key**: exercise
    content is generated offline and seeded into DynamoDB, so nothing here calls an LLM
    at runtime.
- Lambda Layers: so that one layer could be reused inside all my lambda functions;
- S3 / CloudFront: `ttrpg_club_frontend_dev` / `ttrpg_club_frontend_prod` (static site
  hosting) and `ttrpg_club_avatars_dev` / `ttrpg_club_avatars_prod` (member/GM profile
  pictures) — symmetric dev/prod pairs, replacing the old unsuffixed
  `ttrpg_club_frontend` / `ttrpg_club_avatars` modules (retired). Note:
  `ttrpg_club_frontend_dev` was originally stood up as an unrelated sandbox for
  `ttrpg_poll_bot`'s Mini App testing before being adopted as the website's real dev
  frontend — both purposes now live on the same bucket/distribution.
- SSM: the generic `ssm` module (personal bot secrets, unrelated to the ttrpg_club
  stack). (An early, now-superseded `ssm/ttrpg_club` module's two placeholder
  parameters may still exist, unused — safe to ignore or delete manually via
  `aws ssm delete-parameter`.)
- IAM: `github_actions_ttrpg_club`, `github_actions_ttrpg_poll_bot`, and
  `github_actions_entutor` — one OIDC deploy role per repo. All three share the single
  account-wide `token.actions.githubusercontent.com` OIDC provider (AWS allows only one
  per URL), which `github_actions_ttrpg_club` creates and the others reference. Each role
  is deliberately narrow: `lambda:UpdateFunctionCode` on its own functions and nothing
  else, because Terraform owns the infrastructure and CI only ships code.
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

### Website stack (dev and prod)

Two fully independent, symmetric environments — nothing is shared between them (own
DynamoDB tables, own avatars bucket, own frontend bucket/CloudFront, own API
Lambda/API Gateway, own Telegram bot) except the one genuinely shared piece:
`dns/dnaclub_com_ua` (one Route 53 zone + two ACM certs covering both
`dnaclub.com.ua`/`www.dnaclub.com.ua` (prod) and `dev.dnaclub.com.ua` (dev), since it's
a single registered domain). Auth is Telegram-based (Login Widget on the site, `initData`
in the Mini App) — no Cognito, no per-environment user pool. Apply order per environment
(`<env>` = `dev` or `prod`; order matters where one module reads another's remote state):
1. `dynamodb/ttrpg_club/<env>` (all 11 tables, one `terraform apply`)
2. `s3/ttrpg_club_avatars_<env>`
3. `dns/dnaclub_com_ua` — **once per domain, not per environment.** Creates the Route 53
   zone and both certificates; requires the domain's nameservers to already be pointed
   at this zone's `name_servers` output (registered separately — Route 53 Domains
   doesn't sell `.com.ua`), so DNS validation can complete. Re-running `apply` after
   updating nameservers is expected if it doesn't validate on the first try. Its Route 53
   ALIAS records target CloudFront's fixed, universal hosted zone ID (`Z2FDTNDATAQYW2`,
   hardcoded in `main.tf`, the same for every CloudFront distribution on every AWS
   account) rather than reading it from the frontend modules' state — that's what keeps
   this dependency one-directional instead of circular. It does still read both frontend
   modules' `distribution_domain_name` output, so on a from-scratch environment (not the
   case for `dev`/`prod` today — their frontend stacks already exist) each frontend
   module needs at least one prior apply before `dns`'s first-ever apply.
4. `s3_cloudfront/ttrpg_club_frontend_<env>` — sets `aliases` and the real ACM
   certificate (from step 3's output, replacing the default CloudFront cert), and, prod
   only, a CloudFront Function 301-redirecting `www.dnaclub.com.ua` to the apex.
5. `npm run build --workspace backend` in `ttrpg_website2` (bundles the Lambda code both
   `lambda/ttrpg_club_api_dev` and `_prod` reference — same code, different config)
6. `lambda/ttrpg_club_api_<env>` — `cors_allowed_origins` defaults to that environment's
   real domain(s) (dev also includes `http://localhost:5173` for local frontend dev).
   `admin_telegram_ids` defaults to `[]` (see "First admin" below). Dev only:
   `dev_login_secret` defaults to `""` (disabled) — set a real value to use
   `npm run dev:frontend` with a working login, since the Telegram Login Widget only
   authorizes on the domain registered with BotFather and can never work on localhost.
7. Re-apply `iam/github_actions_ttrpg_club` once *both* environments' steps 4 and 6 have
   been applied at least once — its policy covers both stacks' exact resource ARNs via
   remote state, so it must come after them.

Then, per environment, sync the frontend build and invalidate the CDN cache:
```
npm run build --workspace frontend   # in ttrpg_website2, with .env pointed at that env's outputs below
aws s3 sync frontend/dist s3://<bucket from step 4 output> --delete
aws cloudfront create-invalidation --distribution-id <step 4 output> --paths "/*"
```

Frontend `.env` values come from that environment's own modules' outputs:
`VITE_API_BASE_URL` ← `lambda/ttrpg_club_api_<env>` `api_base_url`;
`VITE_TELEGRAM_BOT_USERNAME` ← the bot registered for that environment (`ttrpgpollbot`
for prod, `ttrpgpolltestbot` for dev — see the poll bot section below; the same bot must
also have `/setdomain` pointed at that environment's domain via BotFather, or the widget
won't authorize);
`VITE_AVATAR_CDN_BASE_URL` ← `https://` + `s3/ttrpg_club_avatars_<env>`
`distribution_domain_name`.

**First admin**: there's no bootstrap step — log in with Telegram once (creates your
`users` row automatically), find your numeric Telegram user id (e.g. via @userinfobot),
add it to that environment's `admin_telegram_ids` in `lambda/ttrpg_club_api_<env>`, and
re-apply. Takes effect immediately on your next request — admin status is checked
per-request against this list, never baked into a session token, so there's nothing to
log out and back into.

Both environments' backend Lambdas also need the real Telegram bot token in SSM (a
Terraform-managed placeholder is created by `lambda/ttrpg_poll_bot_<env>`, value
`"replace_me!"` until set for real — see the poll bot section below) — this is what
verifies both the Mini App's `initData` signature for `/telegram/*` routes and the
website's Login Widget signature for `POST /auth/telegram` (same token, two different
HMAC schemes — see `backend/src/lib/telegramAuth.ts`), and is also what session JWTs
are signed with (a key derived from it, not a separate secret — see
`backend/src/lib/session.ts`).

**CI/CD branch promotion**: `ttrpg_website2`'s `deploy-backend.yml` / `deploy-frontend.yml`
trigger on push to either `develop` (deploys to the dev stack) or `main` (deploys to the
prod stack), selecting a GitHub Environment (`development` / `production`) by branch
name so each deploy reads that environment's own variables (`LAMBDA_FUNCTION_NAME`,
`FRONTEND_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, `VITE_API_BASE_URL`,
`VITE_TELEGRAM_BOT_USERNAME`, `VITE_AVATAR_CDN_BASE_URL`) — both environments need these
6 variables set (in the repo's Settings → Environments), pointed at each stack's own
Terraform outputs. The `AWS_DEPLOY_ROLE_ARN` secret is shared (one broadened role, not
per-environment) since step 7 above already scopes its policy to both stacks' exact
resource ARNs.

### Poll bot stack (dev and prod)

Also two fully independent, symmetric environments, each its own module
(`lambda/ttrpg_poll_bot_dev`, `lambda/ttrpg_poll_bot_prod`) with its own IAM role, own
API Gateway (own webhook URL — register each with its own Telegram bot via
@BotFather), and its own Terraform-managed SSM placeholders (bot token + admin chat
ID). Apply order per environment: that environment's `dynamodb/ttrpg_club/<env>` (see
Website stack above) must exist first (it publishes the stream ARNs this module reads),
then `../ttrpg_poll_bot/build.sh` (shared code, built once), then
`lambda/ttrpg_poll_bot_<env>` itself.

After applying, set the real bot token and admin chat ID over the Terraform-managed
placeholders:
```
aws ssm put-parameter --name "/ttrpg_club/<env>/poll_bot/token" --type SecureString --value "<real token>" --overwrite
aws ssm put-parameter --name "/ttrpg_club/<env>/telegram_admin_chat_id" --type SecureString --value "<real chat id>" --overwrite
```
then register `terraform output webhook_url` as that bot's Telegram webhook.

## Lambda
To deploy lambda functions it is needed to have them locally near the "aws_infra" repository.

## Technical Debt
1. In the future, lambda should be fetched from repositories and its repository should contain the terraform module to deploy it.
2. Draw a diagram of the infrastructure.
3. Separate API Gateway from Lambda folder.
