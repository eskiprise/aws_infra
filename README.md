# aws_infra
This repository represents the infrastructure for my personal AWS cloud

## Contents
- DynamoDB Tables
  - compliments: table for the compliments for my Telegram Bot;
  - users: table where telegram users are stored;
  - ttrpg_club_*: 8 tables for the TTRPG club website (users, signup_requests, game_systems,
    games, game_participants, game_poll_votes, game_comments, settings) — see
    `../ttrpg_website2` for the application code.
  - ttrpg_club_telegram_rating_polls / ttrpg_club_telegram_rating_votes: 2 tables backing the
    Telegram Mini App's personal stats feature — capture `/rate` poll answers straight from
    the club's Telegram chat, keyed purely by Telegram user ID (voters need not be registered
    club members). Read by `lambda/ttrpg_club_api`'s `POST /telegram/stats` endpoint, written
    by `../ttrpg_poll_bot`'s webhook. See `../ttrpg_poll_bot/README_LAMBDA.md`.
- Lambda. Contains 3 lambda functions. Every lambda is connected to my TG Bots.
  - bot_alert: Lambda which is triggered by cron and sends users compliments;
  - bot: Lambda that processes all incoming messages;
  - json_refiner: a bot that formats "Python Dict" to standard JSON format;
  - ttrpg_club_api: the TTRPG club website's API (Node.js/TS, one Lambda behind an HTTP API
    that routes internally — see ttrpg_website2/backend).
  - New club signups are NOT notified via a dedicated bot/Lambda here — instead, a new
    `notifySignup` function was added directly to the separate `ttrpg_poll_bot` repo
    (Serverless Framework, not this repo), triggered by `ttrpg_club_signup_requests`'
    DynamoDB Stream. It reuses that bot's existing token/session. See
    `../ttrpg_poll_bot/serverless.yml` and `lambda_handler.py`.
- Lambda Layers: so that one layer could be reused inside all my lambda functions;
- Cognito: `ttrpg_club` — User Pool for the club website (admin-provisioned members only,
  no public self-signup).
- S3 / CloudFront: `ttrpg_club_frontend` (static site hosting) and `ttrpg_club_avatars`
  (member/GM profile pictures).
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
root module/state, so order matters where one references another's remote state):
1. `dynamodb/ttrpg_club_*` (all 8, any order)
2. `cognito/ttrpg_club`
3. `s3/ttrpg_club_avatars`
4. `s3_cloudfront/ttrpg_club_frontend`
5. `npm run build --workspace backend` in `ttrpg_website2` (bundles the Lambda code
   `lambda/ttrpg_club_api` references)
6. `lambda/ttrpg_club_api`
7. `dynamodb/ttrpg_club_telegram_rating_polls` and `dynamodb/ttrpg_club_telegram_rating_votes`
   (any order, independent of the 8 tables above)
8. In `../ttrpg_poll_bot`: get the signup-requests stream ARN with
   `terraform output -raw dynamodb_table_stream_arn` (run from
   `dynamodb/ttrpg_club_signup_requests`), then
   `serverless deploy --param="adminChatId=<your chat id>" --param="signupRequestsStreamArn=<that ARN>"`
   — add `--param="miniAppDeepLink=<t.me deep link>"` once you've registered the Mini App
   with @BotFather (see `../ttrpg_poll_bot/README_LAMBDA.md`'s Personal Stats section).

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

## Lambda
To deploy lambda functions it is needed to have them locally near the "aws_infra" repository.

## Technical Debt
1. In the future, lambda should be fetched from repositories and its repository should contain the terraform module to deploy it.
2. Draw a diagram of the infrastructure.
3. Separate API Gateway from Lambda folder.
