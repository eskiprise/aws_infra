{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "arn:aws:logs:${region}:${account_id}:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${region}:${account_id}:log-group:/aws/lambda/${function_name}:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": [
        "${users_table}",
        "${signup_requests_table}",
        "${signup_requests_table}/index/*",
        "${game_systems_table}",
        "${games_table}",
        "${game_participants_table}",
        "${game_poll_votes_table}",
        "${game_comments_table}",
        "${settings_table}",
        "${telegram_rating_votes_table}",
        "${telegram_rating_votes_table}/index/*",
        "${telegram_rating_polls_table}",
        "${telegram_rating_polls_table}/index/*",
        "${telegram_feedback_table}",
        "${telegram_xp_ledger_table}",
        "${telegram_player_level_table}",
        "${telegram_achievements_table}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cognito-idp:AdminCreateUser"
      ],
      "Resource": "${user_pool_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${avatars_bucket_arn}/*"
    },
    {
      "Effect": "Allow",
      "Action": "ssm:GetParameter",
      "Resource": "${telegram_bot_token_param_arn}"
    }
  ]
}
