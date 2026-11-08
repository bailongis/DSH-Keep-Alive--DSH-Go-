#!/system/bin/sh
MODDIR=/data/adb/modules/dsh_keepalive
if [ -f "$MODDIR/watchdog.pid" ]; then
  kill "$(cat "$MODDIR/watchdog.pid")" 2>/dev/null
  rm -f "$MODDIR/watchdog.pid"
fi
