"""
CloudWatch Logs subscription-filter target — forwards ERROR-level log lines from the
4 monitored ttrpg_club prod Lambdas straight to Telegram. One message per invocation
(a single invocation can batch several matched log lines), so a burst of errors sends
one readable digest instead of flooding the chat with individual messages.

Reuses the live prod poll bot's own token (fetched fresh from SSM, cached per warm
container) rather than registering a separate alerting bot — this is purely an
operations notification, not a user-facing bot feature.
"""
import base64
import gzip
import json
import os
import urllib.request

import boto3

ssm = boto3.client("ssm")
_cached_token = None

MAX_TELEGRAM_MESSAGE_LENGTH = 4096
MAX_EVENTS_PER_MESSAGE = 10  # keep a burst readable rather than one giant wall of text


def _bot_token() -> str:
    global _cached_token
    if _cached_token is None:
        param = ssm.get_parameter(Name=os.environ["BOT_TOKEN_SSM_PARAMETER"], WithDecryption=True)
        _cached_token = param["Parameter"]["Value"]
    return _cached_token


def _function_name_from_log_group(log_group: str) -> str:
    return log_group.removeprefix("/aws/lambda/")


def _format_event(raw_message: str) -> str:
    """A matched log line is itself a JSON object (Lambda's Advanced Logging Controls
    JSON format) — pull out the human-readable parts. Falls back to the raw line if it
    doesn't parse, so a malformed line still reaches Telegram instead of vanishing."""
    try:
        parsed = json.loads(raw_message)
    except (ValueError, TypeError):
        return raw_message.strip()

    timestamp = parsed.get("timestamp", "")
    message = parsed.get("message", raw_message.strip())
    request_id = parsed.get("requestId")
    line = f"{timestamp}  {message}"
    if request_id:
        line += f"\n(requestId: {request_id})"
    return line


def lambda_handler(event, context):
    compressed = base64.b64decode(event["awslogs"]["data"])
    payload = json.loads(gzip.decompress(compressed))

    log_group = payload.get("logGroup", "unknown-log-group")
    function_name = _function_name_from_log_group(log_group)
    log_events = payload.get("logEvents", [])
    if not log_events:
        return  # subscription filters can deliver control messages with no events

    formatted = [_format_event(e["message"]) for e in log_events[:MAX_EVENTS_PER_MESSAGE]]
    omitted = len(log_events) - len(formatted)

    text = f"🚨 {len(log_events)} error(s) in {function_name}\n\n" + "\n\n".join(formatted)
    if omitted > 0:
        text += f"\n\n…and {omitted} more in this batch."
    if len(text) > MAX_TELEGRAM_MESSAGE_LENGTH:
        text = text[: MAX_TELEGRAM_MESSAGE_LENGTH - 20] + "\n…(truncated)"

    body = json.dumps({"chat_id": os.environ["ADMIN_CHAT_ID"], "text": text}).encode()
    req = urllib.request.Request(
        f"https://api.telegram.org/bot{_bot_token()}/sendMessage",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        resp.read()
