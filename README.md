# Instabox Keepalive

Keeps all four Instabox machines awake during the configured Asia/Shanghai
windows by opening a short SSH session through the Instabox SSH gateway every
five minutes.

## How it works

- GitHub Actions schedule: every 5 minutes (`*/5 * * * *`), but it only connects
  during the Asia/Shanghai keepalive windows below
- SSH gateway: `ssh.instabox.sh:2222`
- Authentication: Instabox gateway token as the SSH username, stored in the
  repository secrets:
  - `INSTABOX_SSH_USER` — `agent-browser-hjpf`
  - `INSTABOX_SSH_USER_2` — `agent-browser-uyll`
  - `INSTABOX_SSH_USER_KJDM` — `agent-browser-kjdm`
  - `INSTABOX_SSH_USER_MXPL` — `agent-browser-mxpl`
- The session runs `date`, `uptime`, and then stays open for 10 seconds before
  exiting, which counts as activity and prevents the free-tier 30-minute idle
  pause.

Keepalive windows (Asia/Shanghai):

```text
00:35-07:50
08:30-13:00
13:35-18:00
18:35-23:59
```

Outside those windows the workflow exits without touching the machine, so the
free tier can auto-pause and reset its 480-minute continuous-run counter.

The workflow logs never print the token. The repository contains no credentials.

The primary keepalive runs on Oracle Phoenix `phx-amd-01` through
`instabox-keepalive.timer`. That script reads every Token file in
`/etc/instabox-keepalive/tokens`, so adding a machine there also requires no
script change. Its source is mirrored at `oracle/instabox-keepalive.sh`, and it
returns failure unless every token file produces a successful SSH session.
GitHub Actions remains the backup path.

## Manual run

Open the **Actions** tab and run **instabox-keepalive** via
`Run workflow`, or:

```bash
gh workflow run keepalive.yml \
  --repo Laurenceli13/instabox-keepalive
```

## Notes

- GitHub scheduled workflows can be delayed during peak periods. The 5-minute
  cadence leaves margin under Instabox's 30-minute idle threshold.
- GitHub disables scheduled workflows after 60 days without repository
  activity. `repo-activity.yml` commits a timestamp on the first day of each
  month to keep the schedule enabled.
- Free-tier Instabox machines may still pause during a prolonged GitHub Actions
  outage; the next successful run wakes the machine again.
