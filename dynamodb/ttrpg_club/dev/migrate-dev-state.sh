#!/usr/bin/env bash
set -euo pipefail

# One-time migration: moves the 11 existing ttrpg_club DynamoDB tables out of their
# old, separate per-table Terraform states and into this consolidated
# dynamodb/ttrpg_club/dev state — WITHOUT destroying or recreating anything real.
# This only ever READS the old remote states (via `terraform state pull`); it never
# modifies or deletes them, so nothing is lost even if this is interrupted partway.
#
# Note: the two `aws_ssm_parameter` resources (signup_requests_stream_arn,
# telegram_feedback_stream_arn) are NOT migrated here — they were never actually
# `terraform apply`'d in the old per-table directories, so there's nothing to move.
# They get created fresh by the first real `terraform apply` in this directory, which
# is the correct, safe action for a resource that doesn't exist yet.
#
# Prerequisites:
#   1. Run `terraform init` in THIS directory first, so the new (empty) destination
#      state exists at dynamodb/ttrpg_club/dev/terraform.tfstate.
#   2. Run this script FROM this directory: `./migrate-dev-state.sh`
#   3. All 11 old aws_infra/dynamodb/ttrpg_club_* directories must still exist
#      untouched — don't delete them until AFTER the safety check below passes.
#
# After this script finishes: run `terraform plan` in this directory. It should show
# only the 2 SSM parameters as "to add" (0 to change/destroy on the 11 tables) — that's
# the proof the migration worked and nothing will be destroyed or recreated. If it
# proposes touching any table, STOP and investigate before running `terraform apply`.
#
# Safety net: a trap below pushes whatever has been accumulated so far no matter how
# the script exits, and always prints the working file's path — so even if some future
# run fails partway, the already-migrated resources aren't silently lost the way they
# were the first time this ran (see the fix for that in git history).

WORKDIR=$(mktemp -d)
NEW_STATE="$WORKDIR/dev.tfstate"
echo "Working files: $WORKDIR"

trap 'echo; echo "Pushing whatever was accumulated in $NEW_STATE ..."; terraform state push "$NEW_STATE" && echo "Pushed." || echo "Push failed — recover manually with: terraform state push $NEW_STATE"' EXIT

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
move ttrpg_club_game_systems          module.dynamodb_table module.game_systems
move ttrpg_club_games                 module.dynamodb_table module.games
move ttrpg_club_game_participants     module.dynamodb_table module.game_participants
move ttrpg_club_game_poll_votes       module.dynamodb_table module.game_poll_votes
move ttrpg_club_game_comments         module.dynamodb_table module.game_comments
move ttrpg_club_settings              module.dynamodb_table module.settings
move ttrpg_club_telegram_rating_polls module.dynamodb_table module.telegram_rating_polls
move ttrpg_club_telegram_rating_votes module.dynamodb_table module.telegram_rating_votes
move ttrpg_club_telegram_feedback     module.dynamodb_table module.telegram_feedback

echo
echo "All moves done — the EXIT trap above will push the result now."
