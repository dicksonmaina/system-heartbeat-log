# system-heartbeat-log

Automated daily "heartbeat" commit to prove the local machine is alive and
that scheduled automation is running. Intentionally kept in its own repo
so it is **obviously** what it is - never disguised as project activity.

## What runs

- A bash script `heartbeat.sh` is invoked by Windows Task Scheduler once per day.
- It appends an ISO-8601 timestamped line to `activity-log.txt`.
- It `git add` + `git commit`s the change (commit message clearly says "automated heartbeat").
- It attempts `git push` to the configured remote (best effort; logged on failure).

## Schedule

Daily at 12:07 local time (slightly offset to avoid collision with other
daily tasks on this machine). Wired up via `Register-ScheduledTask` / `schtasks`
to run `bash.exe C:\Users\user\workspace\system-heartbeat-log\heartbeat.sh`.

## Repo location

`C:\Users\user\workspace\system-heartbeat-log`

## Remote

`https://github.com/dicksonmaina/system-heartbeat-log.git` (configure once a
GitHub credential with push access is available - see `heartbeat.sh`).