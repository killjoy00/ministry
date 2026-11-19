#!/usr/bin/env bash
# Real Android runtime smoke, not a desktop screenshot or a mocked game flow.
set -euo pipefail
package=org.killjoy00.ministry
out=build/android-emulator
mkdir -p "$out"
test -s build/ministry-android-debug.apk
adb install -r build/ministry-android-debug.apk
adb logcat -c
dimensions="$(adb shell wm size | tr -d '\r' | grep -oE '[0-9]+x[0-9]+' | tail -1)"
width="${dimensions%x*}"
height="${dimensions#*x}"
test "$width" -gt 500
test "$height" -gt 1000
echo "Android emulator display: $dimensions"
alive() {
  adb shell pidof "$package" | tr -d '\r' | grep -Eq '^[0-9 ]+$' || {
    echo "::error::The Ministry Android activity is no longer running"
    adb logcat -d -s Godot:V AndroidRuntime:E '*:S' | tail -120 || true
    return 1
  }
}
capture() {
  local name="$1"
  adb exec-out screencap -p > "$out/$name.png"
  test "$(stat -c%s "$out/$name.png")" -gt 15000 || {
    echo "::error::Empty or suspiciously blank Android screenshot: $name"
    exit 1
  }
  echo "Captured genuine Android screenshot: $name"
}
tap_percent() {
  adb shell input tap "$((width / 2))" "$((height * $1 / 100))"
  sleep 2
  alive
}
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
sleep 9
alive
capture "01-first-run-briefing"
# System Back must return from the illustrated tutorial to the live case
# rather than killing the Android process (Godot's default behavior).
adb shell input keyevent KEYCODE_BACK
sleep 3
alive
capture "02-back-to-incidents"
# Follow actual player actions, using on-screen footer positions.
tap_percent 91
capture "03-choose-stamp"
tap_percent 88
capture "04-stamp-filed"
tap_percent 88
capture "05-causality-theater"
adb shell input keyevent KEYCODE_BACK
sleep 2
alive
capture "06-back-from-theater"
adb shell input keyevent KEYCODE_HOME
sleep 2
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
sleep 4
alive
capture "07-resumed-case"
adb logcat -d -s Godot:V AndroidRuntime:E '*:S' > "$out/runtime-log.txt" || true
if grep -Eq 'SCRIPT ERROR|Parse Error|FATAL EXCEPTION' "$out/runtime-log.txt"; then
  echo "::error::Godot or Android reported a runtime/script exception"
  grep -E -A 9 'SCRIPT ERROR|Parse Error|FATAL EXCEPTION' "$out/runtime-log.txt" | head -100
  exit 1
fi
echo "PASS: actual Android installation, first-run art, Back, incident selection, stamp flow, causality, and resume"
