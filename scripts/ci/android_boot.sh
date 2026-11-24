#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Boots the AVD <name> for devices.yml's own emulator steps (the Android
# TV image, which the emulator runner cannot boot: its adbd goes away for a
# moment after the boot). At most two attempts of 8 minutes each: the
# first boots the AVD as it is, the second wipes its data. An attempt ends
# early when the emulator process dies. Each attempt and why it ended go to
# emu-logs/boot.tsv, the emulator's own output to emu-logs/boot-<n>.log.
# Fails when neither attempt boots: the caller writes the summary line.
#
#   bash scripts/ci/android_boot.sh <name>
set -u
name=$1
mkdir -p emu-logs
: > emu-logs/boot.tsv
# Booted: adb sees the device and sys.boot_completed reads 1 twice in a
# row (the TV image's adbd goes away for a moment right after).
booted() {
  local ok=0
  for _ in $(seq 1 160); do
    kill -0 "$emu" 2> /dev/null || return 2
    if [ "$(timeout 10 adb shell getprop sys.boot_completed 2> /dev/null | tr -d '\r')" = 1 ]; then
      ok=$((ok + 1))
      [ $ok -ge 2 ] && return 0
    else
      ok=0
    fi
    sleep 3
  done
  return 1
}
for attempt in 1 2; do
  extra=()
  [ $attempt = 2 ] && extra=(-wipe-data)
  start=$(date +%s)
  "$ANDROID_HOME/emulator/emulator" -avd "$name" -no-window -gpu swiftshader_indirect \
    -no-boot-anim -no-snapshot -camera-back none "${extra[@]}" > "emu-logs/boot-$attempt.log" 2>&1 &
  emu=$!
  # The device shows up within the attempt's 8 minutes, or not at all.
  if timeout 480 adb wait-for-device; then
    booted
    r=$?
  else
    r=1
  fi
  took=$(( $(date +%s) - start ))
  case $r in
    0) printf '%s\tbooted\t%ss\n' $attempt $took >> emu-logs/boot.tsv; echo "booted on attempt $attempt in ${took}s"; exit 0 ;;
    2) why='emulator process died' ;;
    *) why='no boot in 8 minutes' ;;
  esac
  printf '%s\t%s\t%ss\n' $attempt "$why" $took >> emu-logs/boot.tsv
  echo "::warning::boot attempt $attempt of $name: $why"
  tail -30 "emu-logs/boot-$attempt.log"
  kill "$emu" 2> /dev/null
  sleep 3
  kill -9 "$emu" 2> /dev/null
  # The launcher's qemu child, if it outlived the launcher.
  pkill -9 qemu-system 2> /dev/null
  timeout 20 adb kill-server > /dev/null 2>&1 || true
done
echo "::error::the emulator $name did not boot in two attempts"
exit 1
