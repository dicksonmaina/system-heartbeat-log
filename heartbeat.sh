#!/usr/bin/env bash
# heartbeat.sh
# Daily automated heartbeat:
#   1. Append an ISO-8601 timestamped line to activity-log.txt
#   2. git add + git commit (honest commit message)
#   3. git push (best effort; logged on failure so the schedule still runs)
#
# Intended to be invoked by Windows Task Scheduler. Do not run by hand
# pretending it is anything other than what it is.

set -u

REPO_DIR="C:/Users/user/workspace/system-heartbeat-log"
LOG_FILE="${REPO_DIR}/activity-log.txt"
RUN_LOG="${REPO_DIR}/heartbeat.log"
TOKEN_FILE="C:/Users/user/.config/system-heartbeat-log/token"
DEFAULT_REMOTE_URL="https://github.com/dicksonmaina/system-heartbeat-log.git"
BRANCH="main"

cd "$REPO_DIR" || { echo "$(date -Iseconds) FATAL: cannot cd to $REPO_DIR" >> "$RUN_LOG"; exit 1; }

TS="$(date -Iseconds)"
HOST="$(hostname)"
USER_NAME="$(whoami 2>/dev/null || echo unknown)"

# 1. Append timestamped line
echo "${TS}  host=${HOST}  user=${USER_NAME}  automated heartbeat" >> "$LOG_FILE"

# 2. Commit
git -c credential.helper= add activity-log.txt
if git -c credential.helper= diff --cached --quiet; then
  echo "${TS}  no changes to commit" >> "$RUN_LOG"
else
  COMMIT_MSG="automated heartbeat - ${TS}"
  if git -c credential.helper= commit -m "$COMMIT_MSG" >> "$RUN_LOG" 2>&1; then
    echo "${TS}  committed: $COMMIT_MSG" >> "$RUN_LOG"
  else
    echo "${TS}  git commit FAILED" >> "$RUN_LOG"
    exit 1
  fi
fi

# 3. Push (best effort). Use the existing remote if configured; otherwise
#    build a credential-embedded URL from a local token file outside the
#    repo so the secret is never accidentally committed.
PUSH_URL=""
if git -c credential.helper= remote get-url origin >/dev/null 2>&1; then
  PUSH_URL="$(git -c credential.helper= remote get-url origin)"
fi

if [ -z "$PUSH_URL" ] || [[ "$PUSH_URL" != https://*@* ]]; then
  if [ -r "$TOKEN_FILE" ]; then
    TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"
    if [ -n "$TOKEN" ]; then
      PUSH_URL="https://${TOKEN}@github.com/dicksonmaina/system-heartbeat-log.git"
    fi
  fi
fi

if [ -z "$PUSH_URL" ]; then
  echo "${TS}  no remote and no token file at $TOKEN_FILE - skipping push" >> "$RUN_LOG"
  exit 0
fi

# Use -c credential.helper= to bypass the broken global gh auth helper.
if git -c credential.helper= push "$PUSH_URL" "$BRANCH" >> "$RUN_LOG" 2>&1; then
  echo "${TS}  push OK (${BRANCH})" >> "$RUN_LOG"
else
  echo "${TS}  push FAILED (see preceding lines for details)" >> "$RUN_LOG"
fi

exit 0