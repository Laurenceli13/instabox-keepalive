#!/bin/bash
set -u

# Only keep machines awake during these Asia/Shanghai windows:
# 00:35-07:50, 08:30-13:00, 13:35-18:00, 18:35-23:59
if [ "${INSTABOX_FORCE:-0}" != "1" ]; then
  now=$((10#$(TZ=Asia/Shanghai date +%H%M)))
  if ! (( (now >= 35 && now <= 750) || (now >= 830 && now <= 1300) || (now >= 1335 && now <= 1800) || (now >= 1835 && now <= 2359) )); then
    exit 0
  fi
fi

LOG=/var/log/instabox-keepalive.log
exec 9>/run/instabox-keepalive.lock
flock -n 9 || exit 0

total=0
failed=0
for token_file in /etc/instabox-keepalive/tokens/*; do
  [ -f "$token_file" ] || continue
  total=$((total + 1))
  TOKEN="$(cat "$token_file")"
  name="$(basename "$token_file")"
  (
    echo "=== $(date -u +%FT%TZ) $name ==="
    timeout 75 ssh -p 2222 \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=25 \
      -o ServerAliveInterval=10 \
      -o ServerAliveCountMax=2 \
      -o PreferredAuthentications=none \
      -o PubkeyAuthentication=no \
      -o PasswordAuthentication=no \
      "${TOKEN}@ssh.instabox.sh" \
      'echo connected: $(hostname); date -u; uptime; sleep 10'
    rc=$?
    echo "rc=$rc"
    exit "$rc"
  ) >> "$LOG" 2>&1
  rc=$?
  if [ "$rc" -ne 0 ]; then
    failed=$((failed + 1))
  fi
done

if [ -f "$LOG" ] && [ "$(stat -c%s "$LOG")" -gt 2097152 ]; then
  tail -c 1048576 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

if [ "$total" -eq 0 ]; then
  exit 0
fi
[ "$failed" -eq 0 ]
