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
REMOTE_URL="https://github.com/dicksonmaina/system-heartbeat-log.git"
BRANCH="main"

cd "$REPO_DIR" || { echo "$(date -Iseconds) FATAL: cannot cd to $REPO_DIR" >> "$RUN_LOG"; exit 1; }

TS="$(date -Iseconds)"
HOST="$(hostname)"
USER_NAME="$(whoami 2>/dev/null || echo unknown)"

# 1. Append timestamped line
{
  echo "${TS}  host=${HOST}  user=${USER_NAME}  automated heartbeat"
} >> "$LOG_FILE"

# 2. Commit
git add activity-log.txt
# Only commit if there's actually a change
if git diff --cached --quiet; then
  echo "${TS}  no changes to commit" >> "$RUN_LOG"
else
  COMMIT_MSG="automated heartbeat - ${TS}"
  if git commit -m "$COMMIT_MSG" >> "$RUN_LOG" 2>&1; then
    echo "${TS}  committed: $COMMIT_MSG" >> "$RUN_LOG"
  else
    echo "${TS}  git commit FAILED" >> "$RUN_LOG"
    exit 1
  fi
fi

# 3. Push (best effort). If no remote is set yet, or auth is missing,
#    log the failure but do not error - the local log + commit are the
#    honest record that the automation ran.
if git remote get-url origin >/dev/null 2>&1; then
  if git push origin "$BRANCH" >> "$RUN_LOG" 2>&1; then
    echo "${TS}  push OK (${BRANCH})" >> "$RUN_LOG"
  else
    echo "${TS}  push FAILED (see preceding lines for details)" >> "$RUN_LOG"
  fi
else
  echo "${TS}  no remote 'origin' configured - skipping push. To enable: git -C \"$REPO_DIR\" remote add origin $REMOTE_URL" >> "$RUN_LOG"
fi

exit 0