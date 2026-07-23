# aws_infra
This repository represents the infrastructure for my personal AWS cloud

## Contents
- DynamoDB Tables
  - compliments: table for the compliments for my Telegram Bot;
  - users: table where telegram users are stored;
  - ttrpg_club_*: 8 tables for the TTRPG club website (users, signup_requests, game_systems,
    games, game_participants, game_poll_votes, game_comments, settings) — see
    `../ttrpg_website` for the application code.
- Lambda. Contains 3 lambda functions. Every lambda is connected to my TG Bots.
  - bot_alert: Lambda which is triggered by cron and sends users compliments;
  - bot: Lambda that processes all incoming messages;
  - json_refiner: a bot that formats "Python Dict" to standard JSON format;
  - ttrpg_club_api: the TTRPG club website's API (Node.js/TS, one Lambda behind an HTTP API
    that routes internally — see ttrpg_website/backend);
  - ttrpg_club_notifier: posts new club signup requests to a dedicated Telegram bot,
    triggered by ttrpg_club_signup_requests' DynamoDB Stream.
- Lambda Layers: so that one layer could be reused inside all my lambda functions;
- Cognito: `ttrpg_club` — User Pool for the club website (admin-provisioned members only,
  no public self-signup).
- S3 / CloudFront: `ttrpg_club_frontend` (static site hosting) and `ttrpg_club_avatars`
  (member/GM profile pictures).
- SSM: the generic `ssm` module (personal bot secrets) plus `ssm/ttrpg_club` (the club's
  own Telegram bot token + admin chat ID, kept in a separate state so it can never
  collide with the personal bot's parameters).
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
3. `ssm/ttrpg_club` — then manually set the real parameter values (see below)
4. `s3/ttrpg_club_avatars`
5. `s3_cloudfront/ttrpg_club_frontend`
6. `npm run build --workspace backend` in `ttrpg_website` (bundles the Lambda code the
   next two modules reference)
7. `lambda/ttrpg_club_api` and `lambda/ttrpg_club_notifier`

After step 3 applies, the two SSM parameters exist as placeholders (`"replace_me!"`) —
set their real values once you've created the club's Telegram bot via @BotFather:
```
aws ssm put-parameter --name /ttrpg-club/telegram-bot-token --value "<bot token>" --type SecureString --overwrite
aws ssm put-parameter --name /ttrpg-club/telegram-admin-chat-id --value "<chat id>" --type SecureString --overwrite
```

After step 7, sync the frontend build and invalidate the CDN cache:
```
npm run build --workspace frontend   # in ttrpg_website, with .env pointed at the outputs below
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
