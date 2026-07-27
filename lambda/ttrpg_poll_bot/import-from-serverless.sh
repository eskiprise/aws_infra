#!/usr/bin/env bash
set -euo pipefail

# Migrates ttrpg_poll_bot's live Lambda/API Gateway/IAM/event-source-mapping resources
# from Serverless Framework's CloudFormation stack into this Terraform module — WITHOUT
# destroying or recreating anything. Run from THIS directory, after `terraform init`.
#
# This does NOT auto-chain the risky steps. It runs in phases, pausing for you to look
# at the output and press Enter before anything state-changing happens, and it never
# runs `terraform apply` or deletes the CloudFormation stack itself — those are printed
# as a final command for you to run once you're satisfied `terraform plan` is clean.
#
# Assumes: service name "telegram-poll-bot", stage "prod", region eu-west-2 (matching
# how this bot has always been deployed). If any of Serverless's default naming
# assumptions below don't hold, the script fails loudly with what to check instead of
# guessing further.

REGION="eu-west-2"
SERVICE="telegram-poll-bot"
STAGE="prod"

pause() {
  echo
  read -r -p ">>> $1 — press Enter to continue, Ctrl+C to stop here. " _
}

echo "=== Phase 1: Discover ==="

WEBHOOK_NAME="${SERVICE}-${STAGE}-webhook"
SIGNUP_NAME="${SERVICE}-${STAGE}-notifySignup"
FEEDBACK_NAME="${SERVICE}-${STAGE}-notifyFeedback"
ROLE_NAME="${SERVICE}-${STAGE}-${REGION}-lambdaRole"

echo "--- Confirming the 3 Lambda functions exist ---"
WEBHOOK_ARN=$(aws lambda get-function --region "$REGION" --function-name "$WEBHOOK_NAME" --query 'Configuration.FunctionArn' --output text)
aws lambda get-function --region "$REGION" --function-name "$SIGNUP_NAME" >/dev/null
aws lambda get-function --region "$REGION" --function-name "$FEEDBACK_NAME" >/dev/null
echo "OK: $WEBHOOK_NAME, $SIGNUP_NAME, $FEEDBACK_NAME all exist."

echo "--- Confirming the shared IAM role and its inline policy name ---"
aws iam get-role --role-name "$ROLE_NAME" >/dev/null
INLINE_POLICY_NAME=$(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'PolicyNames[0]' --output text)
POLICY_COUNT=$(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'length(PolicyNames)' --output text)
if [ "$POLICY_COUNT" != "1" ]; then
  echo "STOP: expected exactly 1 inline policy on $ROLE_NAME, found $POLICY_COUNT. Check manually before continuing." >&2
  exit 1
fi
echo "OK: role $ROLE_NAME, inline policy '$INLINE_POLICY_NAME'"

echo "--- Finding the HTTP API by its integration target (not by guessing a name) ---"
API_ID=""
INTEGRATION_ID=""
for id in $(aws apigatewayv2 get-apis --region "$REGION" --query 'Items[].ApiId' --output text); do
  match=$(aws apigatewayv2 get-integrations --region "$REGION" --api-id "$id" \
    --query "Items[?contains(IntegrationUri, '${WEBHOOK_ARN}')].IntegrationId" --output text)
  if [ -n "$match" ]; then
    API_ID="$id"
    INTEGRATION_ID="$match"
    break
  fi
done
if [ -z "$API_ID" ]; then
  echo "STOP: no HTTP API found with an integration targeting $WEBHOOK_ARN." >&2
  exit 1
fi
API_NAME=$(aws apigatewayv2 get-api --region "$REGION" --api-id "$API_ID" --query 'Name' --output text)
POST_ROUTE_ID=$(aws apigatewayv2 get-routes --region "$REGION" --api-id "$API_ID" --query "Items[?RouteKey=='POST /webhook'].RouteId" --output text)
GET_ROUTE_ID=$(aws apigatewayv2 get-routes --region "$REGION" --api-id "$API_ID" --query "Items[?RouteKey=='GET /webhook'].RouteId" --output text)
STAGE_NAME=$(aws apigatewayv2 get-stages --region "$REGION" --api-id "$API_ID" --query 'Items[0].StageName' --output text)
echo "OK: API $API_ID (real name: '$API_NAME'), integration $INTEGRATION_ID, POST route $POST_ROUTE_ID, GET route $GET_ROUTE_ID, stage '$STAGE_NAME'"
if [ "$API_NAME" != "telegram-poll-bot-prod" ]; then
  echo "NOTE: api_gateway.tf hardcodes name = \"telegram-poll-bot-prod\" but the real name is \"$API_NAME\" — update that file to match before running terraform plan (a name mismatch is a safe in-place update, not destructive, but fix it for a clean plan)."
fi

echo "--- Finding the two event source mapping UUIDs ---"
SIGNUP_ESM_UUID=$(aws lambda list-event-source-mappings --region "$REGION" --function-name "$SIGNUP_NAME" --query 'EventSourceMappings[0].UUID' --output text)
FEEDBACK_ESM_UUID=$(aws lambda list-event-source-mappings --region "$REGION" --function-name "$FEEDBACK_NAME" --query 'EventSourceMappings[0].UUID' --output text)
echo "OK: notifySignup mapping $SIGNUP_ESM_UUID, notifyFeedback mapping $FEEDBACK_ESM_UUID"

pause "Discovery done — review the values above (especially any NOTE about a name mismatch) before importing"

echo
echo "=== Phase 2: Import ==="

# Safe to re-run: skips anything already imported (e.g. if a previous run got partway
# through and stopped) instead of erroring on "resource already managed by Terraform".
import_if_missing() {
  local address=$1 id=$2
  if terraform state show "$address" >/dev/null 2>&1; then
    echo "skip (already imported): $address"
  else
    terraform import "$address" "$id"
  fi
}

import_if_missing aws_iam_role.lambda_role "$ROLE_NAME"
import_if_missing 'aws_iam_role_policy.bot_permissions' "${ROLE_NAME}:${INLINE_POLICY_NAME}"
# No separate AWSLambdaBasicExecutionRole attachment exists — confirmed by an earlier run
# of this script: Serverless Framework bundled the basic logging statements into the same
# single inline policy imported above, rather than attaching the AWS managed policy.

import_if_missing module.webhook.aws_lambda_function.this[0] "$WEBHOOK_NAME"
import_if_missing module.notify_signup.aws_lambda_function.this[0] "$SIGNUP_NAME"
import_if_missing module.notify_feedback.aws_lambda_function.this[0] "$FEEDBACK_NAME"

import_if_missing aws_apigatewayv2_api.bot "$API_ID"
import_if_missing aws_apigatewayv2_integration.webhook "${API_ID}/${INTEGRATION_ID}"
import_if_missing aws_apigatewayv2_route.webhook_post "${API_ID}/${POST_ROUTE_ID}"
import_if_missing aws_apigatewayv2_route.webhook_get "${API_ID}/${GET_ROUTE_ID}"
import_if_missing aws_apigatewayv2_stage.default "${API_ID}/${STAGE_NAME}"

import_if_missing aws_lambda_event_source_mapping.notify_signup "$SIGNUP_ESM_UUID"
import_if_missing aws_lambda_event_source_mapping.notify_feedback "$FEEDBACK_ESM_UUID"

# The module's own CloudWatch Log Groups (the module manages these directly, separate
# from the IAM logs-policy question above) — these already exist since the bot's been
# running and logging, so they need importing too or `apply` fails with "already exists".
import_if_missing module.webhook.aws_cloudwatch_log_group.lambda[0] "/aws/lambda/${WEBHOOK_NAME}"
import_if_missing module.notify_signup.aws_cloudwatch_log_group.lambda[0] "/aws/lambda/${SIGNUP_NAME}"
import_if_missing module.notify_feedback.aws_cloudwatch_log_group.lambda[0] "/aws/lambda/${FEEDBACK_NAME}"

# aws_lambda_permission IS importable (function_name/statement_id) — since the bot
# already receives webhooks successfully today, this permission must already exist.
import_if_missing aws_lambda_permission.apigw "${WEBHOOK_NAME}/AllowAPIGatewayInvoke"

pause "Import done — now run: terraform plan"

echo
echo "=== Phase 3: You check the plan yourself ==="
echo "Run 'terraform plan' now. It should show NO changes to any real resource (tag-only"
echo "or cosmetic diffs are fine). If it proposes replacing/destroying a Lambda, the API,"
echo "or an event source mapping — STOP and investigate before running 'terraform apply'."
echo
echo "=== Phase 4 (only after the plan is clean and applied): retire the old stack ==="
echo "This does NOT run automatically. Once you're confident, retire Serverless's"
echo "CloudFormation bookkeeping WITHOUT touching any real resource:"
echo
echo "  aws cloudformation list-stack-resources --region $REGION --stack-name ${SERVICE}-${STAGE} \\"
echo "    --query 'StackResourceSummaries[].LogicalResourceId' --output text"
echo
echo "Feed that whole list into:"
echo
echo "  aws cloudformation delete-stack --region $REGION --stack-name ${SERVICE}-${STAGE} \\"
echo "    --retain-resources <paste the logical IDs from above, space-separated>"
echo
echo "This deletes the STACK RECORD only — every physical resource (already Terraform-"
echo "managed at this point) is retained untouched."
