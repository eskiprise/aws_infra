#!/usr/bin/env bash
set -euo pipefail

# One-time migration: moves the 11 existing ttrpg_club DynamoDB tables (+ 2
# aws_ssm_parameter resources) out of their old, separate per-table Terraform states
# and into this consolidated dynamodb/ttrpg_club/dev state — WITHOUT destroying or
# recreating anything real. This only ever READS the old remote states (via
# `terraform state pull`); it never modifies or deletes them, so nothing is lost even
# if this is interrupted partway — just re-run it.
#
# Prerequisites:
#   1. Run `terraform init` in THIS directory first, so the new (empty) destination
#      state exists at dynamodb/ttrpg_club/dev/terraform.tfstate.
#   2. Run this script FROM this directory: `./migrate-dev-state.sh`
#   3. All 11 old aws_infra/dynamodb/ttrpg_club_* directories must still exist
#      untouched — don't delete them until AFTER the safety check below passes.
#
# After this script finishes: run `terraform plan` in this directory. It MUST print
# "No changes. Your infrastructure matches the configuration." — that's the proof
# nothing will be destroyed or recreated. If it shows anything else, STOP and
# investigate before running `terraform apply` anywhere.

WORKDIR=$(mktemp -d)
NEW_STATE="$WORKDIR/dev.tfstate"
echo "Working files: $WORKDIR"

terraform state pull > "$NEW_STATE"

move() {
  local old_dir=$1 old_addr=$2 new_addr=$3
  local old_state="$WORKDIR/${old_dir}.tfstate"
  if [ ! -f "$old_state" ]; then
    echo "--- pulling state for ${old_dir} ---"
    (cd "../../${old_dir}" && terraform init -input=false >/dev/null && terraform state pull) > "$old_state"
  fi
  echo "--- moving ${old_dir}: ${old_addr} -> ${new_addr} ---"
  terraform state mv -state="$old_state" -state-out="$NEW_STATE" "$old_addr" "$new_addr"
}

move ttrpg_club_users                 module.dynamodb_table module.users
move ttrpg_club_signup_requests       module.dynamodb_table module.signup_requests
move ttrpg_club_signup_requests       aws_ssm_parameter.stream_arn aws_ssm_parameter.signup_requests_stream_arn
move ttrpg_club_game_systems          module.dynamodb_table module.game_systems
move ttrpg_club_games                 module.dynamodb_table module.games
move ttrpg_club_game_participants     module.dynamodb_table module.game_participants
move ttrpg_club_game_poll_votes       module.dynamodb_table module.game_poll_votes
move ttrpg_club_game_comments         module.dynamodb_table module.game_comments
move ttrpg_club_settings              module.dynamodb_table module.settings
move ttrpg_club_telegram_rating_polls module.dynamodb_table module.telegram_rating_polls
move ttrpg_club_telegram_rating_votes module.dynamodb_table module.telegram_rating_votes
move ttrpg_club_telegram_feedback     module.dynamodb_table module.telegram_feedback
move ttrpg_club_telegram_feedback     aws_ssm_parameter.stream_arn aws_ssm_parameter.telegram_feedback_stream_arn

terraform state push "$NEW_STATE"

echo
echo "Migration complete. Now run: terraform plan"
echo "It MUST say \"No changes.\" before you do anything else (including deleting the old directories)."
