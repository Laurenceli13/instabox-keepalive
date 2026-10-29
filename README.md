# Instabox Keepalive

Keeps the Instabox machine `agent-browser-hjpf` awake by opening a short SSH
session through the Instabox SSH gateway every five minutes.

## How it works

- GitHub Actions schedule: every 5 minutes (`*/5 * * * *`)
- SSH gateway: `ssh.instabox.sh:2222`
- Authentication: Instabox gateway token as the SSH username, stored in the
  repository secret `INSTABOX_SSH_USER`
- The session runs `date`, `uptime`, and then stays open for 10 seconds before
  exiting, which counts as activity and prevents the free-tier 30-minute idle
  pause.

The workflow logs never print the token. The repository contains no credentials.

## Manual run

Open the **Actions** tab and run **instabox-keepalive** via
`Run workflow`, or:

```bash
gh workflow run instabox-keepalive.yml \
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
