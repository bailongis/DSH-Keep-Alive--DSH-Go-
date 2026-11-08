#!/system/bin/sh
# SukiSU module: DSH keep-alive (late_start service)
export PATH=/system/bin:/system/xbin:$PATH
PKG=io.github.ccch1mneyyy.dsh_app
MODDIR=/data/adb/modules/dsh_keepalive
LOGDIR=/sdcard/Download/DSH-Go
LOG=$LOGDIR/keepalive.log

mkdir -p "$LOGDIR" 2>/dev/null
chmod 755 "$LOGDIR" 2>/dev/null
touch "$LOG" 2>/dev/null
chmod 644 "$LOG" 2>/dev/null

log() {
  echo "$(date '+%F %T') $*" >> "$LOG" 2>/dev/null
}

log "service.sh start"

# 1) phantom process killer off (global; does not change Doze)
settings put global settings_enable_monitor_phantom_procs false
device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null \
  || cmd device_config put activity_manager max_phantom_processes 2147483647

# 2) DSH only: Doze whitelist, background appops, active standby bucket
dumpsys deviceidle whitelist +$PKG
cmd appops set $PKG RUN_ANY_IN_BACKGROUND allow
cmd appops set $PKG RUN_IN_BACKGROUND allow
am set-standby-bucket $PKG active 2>/dev/null
am set-inactive $PKG false 2>/dev/null

# 3) keep Doze enabled for all other apps
dumpsys deviceidle enable

# 4) kill previous watchdog only if the PID still belongs to our script
OLD=$(cat "$MODDIR/watchdog.pid" 2>/dev/null)
if [ -n "$OLD" ] && [ -r "/proc/$OLD/cmdline" ] && tr '\0' ' ' < "/proc/$OLD/cmdline" | grep -q "$PKG"; then
  kill "$OLD" 2>/dev/null
fi

# 5) watchdog: detached via setsid, survives Termux closing
setsid /system/bin/sh -c '
  PKG=io.github.ccch1mneyyy.dsh_app
  LOG=/sdcard/Download/DSH-Go/keepalive.log
  PIDFILE=/data/adb/modules/dsh_keepalive/watchdog.pid
  echo $$ > "$PIDFILE"
  log() { echo "$(date "+%F %T") $*" >> "$LOG" 2>/dev/null; }
  launch() {
    monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    if ! pidof "$PKG" >/dev/null 2>&1; then
      ACT=$(cmd package resolve-activity --brief "$PKG" 2>/dev/null | tail -1)
      [ -n "$ACT" ] && am start -n "$ACT" >/dev/null 2>&1
    fi
  }
  START=$(date +%s)
  sleep 20
  if ! pidof "$PKG" >/dev/null 2>&1; then
    launch
    log "boot launch"
    sleep 15
  fi
  while true; do
    if ! pidof "$PKG" >/dev/null 2>&1; then
      launch
      log "watchdog relaunch"
      sleep 15
    elif [ $(( $(date +%s) - START )) -gt 180 ] \
         && ! pgrep -f "[l]ibproot.so" >/dev/null 2>&1; then
      log "engine missing, force-stop and relaunch"
      am force-stop "$PKG" >/dev/null 2>&1
      sleep 2
      launch
      sleep 20
    fi
    sleep 10
  done
' >/dev/null 2>&1 < /dev/null &
sleep 1
log "watchdog started pid=$(cat "$MODDIR/watchdog.pid" 2>/dev/null)"
