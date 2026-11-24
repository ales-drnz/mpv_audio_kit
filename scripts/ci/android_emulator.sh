#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Runs test_app's Android integration tests on the booted emulator, from
# test_app, for .github/workflows/devices.yml: the audiotrack ones (F277,
# F276, F278), the players of an exiting isolate or engine (F170), the media
# session through Media3 (media_session_test), the media keys of a remote
# (android_remote_keys_test) and its service through a call
# (android_focus_foreground_test, F172). <api> names the logs: 36-tv for
# the Android TV image, 34-wear for the Wear OS one. libmpv-scripts' check
# of the kit runs this script, and android_boot.sh, from the kit it checks
# out.
# The F278 test needs audioserver killed from the host while it plays: it
# prints "[f278] playing" when it is ready, this script then kills
# audioserver, writes f278_killed in the app's cache once a new one is up,
# and the test checks that the output comes back. That test
# runs last, so no other test meets an audioserver restarting. adb root
# restarts adbd, which cuts flutter test and logcat off the device, so it
# runs once at the start, before both. Logs go to emu-logs/. The tests get
# MAK_CI and MAK_LIBMPV_RELEASE, the release of the binary under test, so a
# fix up to that release fails instead of skipping (skipBeforeRelease).
#
#   bash ../scripts/ci/android_emulator.sh <api>
set -u
api=$1
defines=(--dart-define=MAK_CI=true "--dart-define=MAK_LIBMPV_RELEASE=${MAK_LIBMPV_RELEASE:?the release of the libmpv under test}")
mkdir -p emu-logs
# adb with an end: a call on a device that stopped answering waits forever
# otherwise (an adb wait-for-device once waited 94 minutes). For the calls
# that return at once; the captures and flutter test have their own.
a() { timeout 20 adb "$@"; }
# Waits for the device after adbd restarts or the emulator boots again:
# until it answers its properties, flutter sees it as "API null" and finds
# no device (seen on API 34). boot holds the boot it waited for.
ready() {
  timeout 600 adb wait-for-device || return 1
  for _ in $(seq 1 300); do
    [ "$(a shell getprop sys.boot_completed | tr -d '\r')" = 1 ] &&
      [ -n "$(a shell getprop ro.build.version.sdk | tr -d '\r')" ] && break
    sleep 1
  done
  boot=$(a shell cat /proc/sys/kernel/random/boot_id | tr -d '\r')
}
# Whether the emulator went away under the last file: adb lost it, or it
# booted again (seen on the TV image of API 36). That file then says
# nothing about the code: infra, and the next one waits for the device.
lost() {
  [ "$(a get-state 2>/dev/null)" != device ] ||
    [ "$(a shell cat /proc/sys/kernel/random/boot_id 2>/dev/null | tr -d '\r')" != "$boot" ]
}
recover() { # file
  echo "::warning::the emulator went away under $1 on API $api, emulator process $(pgrep -f qemu-system >/dev/null && echo alive || echo gone)"
  mend
}
# Whether the link to the device works: adb sees it, a shell answers and
# logcat hands over its last line. flutter test finds the app's VM service
# in logcat and talks to it over an adb forward: over a broken link a file
# hangs or fails before its tests start, whatever its code (seen on the TV
# image of API 36, where the link drops while the emulator runs on).
link_ok() {
  [ "$(timeout 10 adb get-state 2>/dev/null)" = device ] &&
    [ "$(timeout 10 adb shell echo ok 2>/dev/null | tr -d '\r')" = ok ] &&
    timeout 20 adb logcat -d -t 1 > /dev/null 2>&1
}
# The capture of logcat into emu-logs, from the device's clock on, so a
# new capture does not copy the buffer again. A capture dies with the link.
logcat_pid=''
start_logcat() {
  local since
  [ -n "$logcat_pid" ] && kill "$logcat_pid" 2> /dev/null
  since=$(timeout 10 adb shell "date '+%m-%d %H:%M:%S.000'" 2> /dev/null | tr -d '\r')
  # One -b per buffer: API 24 does not take a list.
  adb logcat -b main -b system -b crash -b events -v time ${since:+-T "$since"} >> "emu-logs/logcat-$api.txt" 2>&1 &
  logcat_pid=$!
}
# Mends a broken link: adb reconnect, then a new adb server, then the wait
# for the device. A link that works is left alone.
mend() {
  link_ok && return 0
  timeout 30 adb reconnect > /dev/null 2>&1 || true
  sleep 3
  if ! link_ok; then
    a kill-server > /dev/null 2>&1 || true
    a start-server > /dev/null 2>&1 || true
  fi
  ready
}
# Before every try: a link that works, a capture of logcat that runs, and
# nothing left of the try before (the app, the forwards of its VM service).
# A broken link is mended instead of spending a try on it. Fails when the
# link stays broken.
prepare() { # what
  if ! link_ok; then
    echo "::warning::the adb link was broken before $1 on API $api: mending it"
    mend
  fi
  { [ -n "$logcat_pid" ] && kill -0 "$logcat_pid" 2> /dev/null; } || start_logcat
  timeout 20 adb shell am force-stop $app > /dev/null 2>&1 || true
  timeout 10 adb forward --remove-all > /dev/null 2>&1 || true
  link_ok
}
app=com.alesdrnz.mpv_audio_kit_test_app
timeout 30 adb root || true
sleep 2
ready
echo "adb as $(a shell id -un | tr -d '\r'), API $(a shell getprop ro.build.version.sdk | tr -d '\r')"
# The package verifier of the Google APIs image is a suspect of the adb
# installs that never finish (API 24).
a shell settings put global verifier_verify_adb_installs 0 || true
a shell settings put global package_verifier_enable 0 || true
# flutter test installs the app with adb install, which streams the APK
# into cmd package install. On Android 7 (API 24 and 25) that stream
# stalls on some hosts: the install session starts (free_cache in the
# log), the APK never arrives, and the try waits to its end. Seen on the
# AWS runners from 24-11-2026, on half of the installs; the Azure ones
# install in 5 s. adb install --no-streaming pushes the APK and runs pm
# install instead, and emu-logs/flutter-adb-<api>.log lists those
# installs. flutter takes <sdk>/cmdline-tools/adb before
# platform-tools/adb (AndroidSdk.getPlatformToolsPath in flutter_tools),
# so an adb there that adds the flag reaches flutter's installs alone:
# the adb calls of this script are unchanged.
api_level=$(a shell getprop ro.build.version.sdk | tr -d '\r')
sdk_dir=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
if [ -n "$api_level" ] && [ "$api_level" -lt 26 ] && [ -n "$sdk_dir" ] &&
  [ -x "$sdk_dir/platform-tools/adb" ] && [ ! -e "$sdk_dir/cmdline-tools/adb" ]; then
  flutter_adb="$sdk_dir/cmdline-tools/adb"
  mkdir -p "$sdk_dir/cmdline-tools"
  cat > "$flutter_adb" <<EOF
#!/usr/bin/env bash
# From scripts/ci/android_emulator.sh: adb install without streaming.
args=()
added=0
for x in "\$@"; do
  args+=("\$x")
  if [ \$added = 0 ] && [ "\$x" = install ]; then args+=(--no-streaming); added=1; fi
done
[ \$added = 1 ] && echo "\$(date +%T) \${args[*]}" >> "$PWD/emu-logs/flutter-adb-$api.log"
exec "$sdk_dir/platform-tools/adb" "\${args[@]}"
EOF
  chmod +x "$flutter_adb"
  trap 'rm -f "$flutter_adb"' EXIT
  echo "flutter installs with adb install --no-streaming on API $api_level"
fi
a logcat -b all -c || true
# events carries the activity relaunches and configuration changes.
: > "emu-logs/logcat-$api.txt"
start_logcat
# A file that hangs prints nothing: once seen, the activity recreated under
# a running test (API 34: CONFIG_ASSETS_PATHS, a change of the app's asset
# paths after boot, which no configChanges can keep out) and adb install
# stuck before the app ran (API 24).
# Each file gets 8 minutes; one that times out dumps the device state and
# runs once more. Its outcome is pass, fail or infra. fail: a test failed,
# or the file hung once its tests had started. infra: every try timed out
# before any test started (an install that never ended, an app that never
# attached), or the emulator went away before one did, which says nothing
# about the code. A try that ends before its tests start on a link found
# broken after it does not count: the file gets one more, three at most.
# Only fail fails the job. An infra file runs once more at the end, on a
# device booted again; still infra, it is a warning and a line of the
# summary, which the Summary job of devices.yml fails on.
dump() {
  local pid; pid=$(a shell pidof $app | tr -d '\r')
  { echo "== $1 at $(date +%T), pid ${pid:-none}"
    a shell pm path $app
    a shell dumpsys activity activities | grep -A4 "$app" | head -40
    [ -n "$pid" ] && a shell debuggerd -b "$pid"
    a shell dumpsys media.audio_flinger | head -80
  } > "emu-logs/hang-$1-$api.txt" 2>&1
}
# Whether the flutter test log $1 shows a test that started: a progress
# line past the loading of the file.
started() { grep -E '[0-9]+:[0-9]+ \+[0-9]+[^:]*: ' "$1" | grep -qv -e ': loading ' -e ': Some tests failed'; }
fails=0
infras=0
summary="emu-logs/summary-$api.txt"
: > "$summary"
infra_files=()
streak=0
repass=0
# The logs of the second pass: <name>-<api>-<try>-repass.log.
tag=''

outcome() { # file, pass | fail | infra | skip
  if [ $repass = 1 ]; then
    # The second pass of a file that never started: its line says both.
    if [ "$2" = infra ]; then
      echo "::warning::$1 never started on API $api, twice: infrastructure. Run it again before a release."
      return
    fi
    infras=$((infras - 1))
    python3 -I - "$summary" "$1" "$2" <<'PY'
import sys
path, name, result = sys.argv[1:]
lines = open(path).read().splitlines()
lines = [f'{name} {result} (infra, then re-pass)' if l == f'{name} infra' else l for l in lines]
open(path, 'w').write('\n'.join(lines) + '\n')
PY
    echo "$1 $2 (infra, then re-pass)"
    [ "$2" = fail ] && { fails=$((fails + 1)); echo "::error::$1 failed on API $api"; }
    return
  fi
  echo "$1 $2" | tee -a "$summary"
  case $2 in
    fail) fails=$((fails + 1)); streak=0; echo "::error::$1 failed on API $api" ;;
    infra)
      infras=$((infras + 1))
      infra_files+=("$1")
      streak=$((streak + 1))
      echo "::warning::$1 never started on API $api: a second pass runs it again at the end."
      # Two files in a row that never started: the device is stuck (an
      # install that never ends, seen on API 24 for every file after
      # one), and the next files would only spend their tries on it.
      if [ $streak -ge 2 ]; then
        reboot_device "two files in a row never started" || true
        streak=0
      fi
      ;;
    *) streak=0 ;;
  esac
}
# Whether the try that left log $1 says nothing about the code: none of
# its tests started, and the emulator went away or the link is broken.
link_lost() { ! started "$1" && { lost || ! link_ok; }; }
# A try in the background: flutter test of file $1 into log $2, its pid in
# ftpid. A try whose app never attaches ends at 4 minutes, not at the 8 of
# a try whose tests run: the app is up a second after its install, and
# flutter test finds it through logcat within seconds when the device
# works (the TV image's log once stalled and every file after waited 2x8
# minutes). nostart says when a try ended that way.
flutter_try() { # file, log
  timeout -s INT -k 30 480 flutter test "integration_test/$1" -d emulator-5554 -r expanded "${defines[@]}" > "$2" 2>&1 &
  ftpid=$!
  ft0=$SECONDS
  nostart=0
}
# Ends the try of log $1 when its 4 minutes to start are over.
start_deadline() { # log
  if [ $nostart = 0 ] && ! started "$1" && [ $((SECONDS - ft0)) -ge "${MAK_START_DEADLINE:-240}" ]; then
    echo "::warning::no test started in ${MAK_START_DEADLINE:-240} s on API $api: ending the try"
    kill -INT "$ftpid" 2> /dev/null
    nostart=1
  fi
}
# The size of the capture of logcat: a try during which it did not grow
# had a device whose log stalled, and flutter test, which reads logcat to
# find the app, could not attach whatever the code.
capture_size() { stat -c %s "emu-logs/logcat-$api.txt" 2> /dev/null || echo 0; }
# Boots the emulator again, for a log that stalled or the second pass.
reboot_device() { # why
  echo "::warning::$1 on API $api: booting the emulator again"
  timeout 30 adb reboot > /dev/null 2>&1 || true
  sleep 10
  # A new boot: ready takes its boot_id, which lost() compares against.
  # adbd comes back unprivileged after a reboot: root again, for F278.
  mend && ready && { timeout 30 adb root > /dev/null 2>&1 || true; sleep 2; mend && ready; } || return 1
  start_logcat
}
run() {
  local name=$1 try=0 spent=0 r log result='' hung=0 size0
  while [ $spent -lt 2 ] && [ $try -lt 3 ]; do
    try=$((try + 1))
    log="emu-logs/$name-$api-$try$tag.log"
    echo "== $name on API $api (try $try)"
    prepare "$name" || { echo "::warning::no adb link for $name on API $api"; spent=$((spent + 1)); continue; }
    size0=$(capture_size)
    flutter_try "$name" "$log"
    while kill -0 "$ftpid" 2> /dev/null; do start_deadline "$log"; sleep 2; done
    wait "$ftpid"
    r=$?
    [ $nostart = 1 ] && r=124
    cat "$log"
    [ "$r" = 0 ] && { result=pass; break; }
    if link_lost "$log"; then recover "$name"; continue; fi
    # A log that did not grow over a try that never started: the device's
    # log stalled. It boots again, and the try does not count.
    if ! started "$log" && [ "$(capture_size)" = "$size0" ]; then
      reboot_device "the log stalled under $name" || true
      continue
    fi
    spent=$((spent + 1))
    if [ "$r" != 124 ] && [ "$r" != 137 ]; then result=fail; break; fi
    started "$log" && hung=1
    echo "::warning::$name timed out on API $api (try $try$([ $hung = 1 ] && echo ', tests running'))"
    dump "$name-$try"
  done
  if [ -z "$result" ]; then
    if [ $hung = 1 ]; then result=fail; else result=infra; fi
  fi
  outcome "$name" "$result"
}
run android_audiotrack_test.dart
run android_audiotrack_pause_test.dart
run android_owner_exit_test.dart
run android_engine_exit_test.dart
run media_session_test.dart
run android_focus_foreground_test.dart
# The media keys: the test prints "[key] KEYCODE_..." and waits for the
# player to follow. Two ways, each with the tries of run (the keys go out
# only once the test runs, so a try that never started sent none):
# input presses the key as a remote or a headset does, through the window
# in front first; dispatch hands it to the media sessions with `media
# dispatch`, as with another app in front.
run_keys() { # input | dispatch
  local via=$1 keys=android_remote_keys_test.dart try=0 spent=0 result=''
  while [ $spent -lt 2 ] && [ $try -lt 3 ]; do
    try=$((try + 1))
    echo "== $keys on API $api, keys by $via (try $try)"
    if ! prepare "$keys:$via"; then
      echo "::warning::no adb link for $keys:$via on API $api"
      spent=$((spent + 1))
      continue
    fi
    keys_try "$via" "$try"
    case $? in
      0) result=pass; break ;;
      2) recover "$keys:$via"; continue ;;
      3) spent=$((spent + 1)); result=fail; break ;;
    esac
    spent=$((spent + 1))
    dump "keys-$via-$try"
  done
  [ -z "$result" ] && result=infra
  outcome "$keys:$via" "$result"
}
# One try of the keys by $1, number $2: 0 pass, 1 timed out before the
# tests started, 2 a link lost before they started, 3 fail.
keys_try() { # input | dispatch, try
  local via=$1 keys=android_remote_keys_test.dart log pid sent=0 r key cues
  log="emu-logs/keys-$via-$api-$2$tag.log"
  flutter_try "$keys" "$log"
  pid=$ftpid
  while kill -0 $pid 2>/dev/null; do
    start_deadline "$log"
    mapfile -t cues < <(grep -o '\[key\] KEYCODE_[A-Z_]*' "$log")
    while [ $sent -lt ${#cues[@]} ]; do
      key=${cues[$sent]#\[key\] }
      echo "pressing $key by $via at $(date +%T)"
      if [ "$via" = input ]; then
        a shell input keyevent "$key"
      else
        # media dispatch names the keys without KEYCODE_MEDIA_, in lower
        # case and with dashes.
        k=${key#KEYCODE_MEDIA_}
        k=${k,,}
        # Android 11 and later: cmd media_session; the media tool up to 9.
        if [ "$sdk" -ge 30 ]; then
          a shell cmd media_session dispatch "${k//_/-}"
        else
          a shell media dispatch "${k//_/-}"
        fi
      fi
      sent=$((sent + 1))
      # Which session Android hands media keys to, and the state of each.
      a shell dumpsys media_session > "emu-logs/media-session-$via-$api-$2-$sent-$key.txt" 2>&1
    done
    sleep 0.2
  done
  wait $pid
  r=$?
  [ $nostart = 1 ] && r=124
  cat "$log"
  if [ $r = 0 ]; then return 0; fi
  if link_lost "$log"; then return 2; fi
  if { [ $r = 124 ] || [ $r = 137 ]; } && ! started "$log"; then return 1; fi
  return 3
}
sdk=$(a shell getprop ro.build.version.sdk | tr -d '\r')
run_keys input
# Android 10 has no tool that reaches the sessions: its media tool hands
# them nothing, and cmd media_session came with 11.
if [ "$sdk" = 29 ]; then
  outcome "android_remote_keys_test.dart:dispatch" skip
else
  run_keys dispatch
fi
# F278: the test waits for the kill. One try: the kill is part of it.
f278=android_audiotrack_dead_object_test.dart
run_f278() {
  local log pid r before after
  # Killing audioserver takes root, which a production image refuses (the TV
  # image of API 36): there the phones cover F278.
  if [ "$(a shell id -un | tr -d '\r')" != root ]; then
    outcome $f278 skip
    return
  fi
  log="emu-logs/dead-object-$api${1:+-$1}.log"
  echo "== $f278 on API $api"
  prepare $f278 || echo "::warning::no adb link for $f278 on API $api"
  flutter_try "$f278" "$log"
  pid=$ftpid
  for _ in $(seq 1 600); do
    grep -q '\[f278\] playing' "$log" && break
    kill -0 $pid 2>/dev/null || break
    start_deadline "$log"
    sleep 0.5
  done
  if grep -q '\[f278\] playing' "$log"; then
    before=$(a shell pidof audioserver | tr -d '\r')
    a shell kill -9 "$before" || a shell killall audioserver || true
    for _ in $(seq 1 20); do
      after=$(a shell pidof audioserver | tr -d '\r')
      [ -n "$after" ] && [ "$after" != "$before" ] && break
      sleep 0.5
    done
    echo "audioserver pid ${before:-none} then ${after:-none} at $(date +%T)"
    if [ -n "$before" ] && [ -n "$after" ] && [ "$after" != "$before" ]; then
      # The test waits for this file, not for a stop: Android's AudioTrack can
      # restore the track by itself, and then playback never stops.
      a shell run-as $app touch cache/f278_killed
    else
      echo "::warning::audioserver was not restarted on API $api"
    fi
  fi
  wait $pid
  r=$?
  [ $nostart = 1 ] && r=124
  cat "$log"
  if [ $r = 0 ]; then
    outcome $f278 pass
  elif ! started "$log" && lost; then
    recover $f278
    outcome $f278 infra
  elif { [ $r = 124 ] || [ $r = 137 ]; } && ! started "$log"; then
    dump "$f278"
    outcome $f278 infra
  else
    outcome $f278 fail
  fi
}
run_f278
# The files that never started get one more pass, on a device booted
# again, so a stuck install or a lost link of the first pass does not reach
# the release as "run it again". Never a file that ran and failed: its
# result stands. The summary keeps both: "<file> pass (infra, then re-pass)"
# or the infra line as it was, which the Summary job of devices.yml fails on.
if [ ${#infra_files[@]} -gt 0 ]; then
  echo "== a second pass for ${#infra_files[@]} file(s) that never started on API $api"
  first=("${infra_files[@]}")
  infra_files=()
  if reboot_device "a second pass"; then
    repass=1
    tag=-repass
    for item in "${first[@]}"; do
      case $item in
        "$f278") run_f278 repass ;;
        android_remote_keys_test.dart:*) run_keys "${item#*:}" ;;
        *) run "$item" ;;
      esac
    done
    repass=0
  else
    echo "::warning::the emulator of API $api did not come back for the second pass"
  fi
fi
{
  echo "### Android emulator API $api"
  echo
  echo "| file | outcome |"
  echo "|---|---|"
  while read -r file result; do echo "| $file | $result |"; done < "$summary"
  [ $infras -gt 0 ] && echo && echo "$infras file(s) never started, after a second pass: run them again before a release."
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
[ $fails = 0 ]
