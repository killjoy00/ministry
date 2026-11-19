#!/usr/bin/env bash
# Real Android runtime smoke, not a desktop screenshot or a mocked game flow.
set -euo pipefail
package=org.killjoy00.ministry
out=build/android-emulator
mkdir -p "$out"
test -s build/ministry-android-debug.apk
adb install -r build/ministry-android-debug.apk
adb logcat -c
# A lighter device framebuffer avoids CPU-starved launcher ANRs in CI, while
# preserving a tall, portrait Android phone and exercising the native APK.
adb shell wm size 720x1600
dimensions="$(adb shell wm size | tr -d '\r' | grep -oE '[0-9]+x[0-9]+' | tail -1)"
width="${dimensions%x*}"
height="${dimensions#*x}"
test "$width" -gt 500
test "$height" -gt 1000
echo "Android emulator display: $dimensions"
diagnose() {
  adb logcat -d -v threadtime > "$out/android-full-logcat.txt" || true
  adb shell dumpsys gfxinfo "$package" > "$out/android-gfxinfo.txt" || true
  adb shell dumpsys SurfaceFlinger --list > "$out/android-surfaces.txt" || true
  adb shell dumpsys activity activities > "$out/android-activities.txt" || true
  echo "Relevant Android/Godot startup messages:"
  grep -Ei 'Godot|OpenGL|Vulkan|EGL|shader|androidruntime|fatal exception|ANR|failed|permission' "$out/android-full-logcat.txt" | tail -130 || true
}
alive() {
  adb shell pidof "$package" | tr -d '\r' | grep -Eq '^[0-9 ]+$' || {
    echo "::error::The Ministry Android activity is no longer running"
    diagnose
    return 1
  }
}
capture() {
  local name="$1"
  # pidof alone is not enough: in the first run the game was alive BEHIND an
  # unresponsive Pixel Launcher dialog. Check the actual focused window.
  local focus
  focus="$(adb shell dumpsys window | grep -m1 'mCurrentFocus=' | tr -d '\r' || true)"
  echo "Focused Android window before $name: $focus"
  if [[ "$focus" != *"$package"* ]]; then
    echo "::error::The game is not the Android foreground window for $name"
    adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | head -5 || true
    diagnose
    exit 1
  fi
  local bytes=0
  # On a cold software-rendered emulator the first few frames can be blank.
  # Do not accept a blank frame; retry briefly and keep the actual failure.
  for attempt in 1 2 3 4; do
    adb exec-out screencap -p > "$out/$name.png"
    bytes="$(stat -c%s "$out/$name.png")"
    if (( bytes >= 100000 )); then
      break
    fi
    echo "Frame $attempt for $name is still blank/monochrome ($bytes bytes)"
    if (( attempt < 4 )); then sleep 10; fi
  done
  if (( bytes < 100000 )); then
    echo "::error::Android screen has no substantial game art ($bytes bytes): $name"
    diagnose
    exit 1
  fi
  echo "Captured native Android game screenshot: $name ($bytes bytes)"
}
tap_percent() {
  adb shell input tap "$((width / 2))" "$((height * $1 / 100))"
  sleep 2
  alive
}
# The hosted emulator's AOSP launcher can hang during cold boot even while
# Godot is running. Avoid launching through the home screen.
adb shell am force-stop com.android.launcher3 || true
adb shell am start -W -n "$package/com.godot.game.GodotAppLauncher"
sleep 18
alive
capture "01-first-run-briefing"
# System Back must return from the illustrated tutorial to the live case
# rather than killing the Android process (Godot's default behavior).
adb shell input keyevent KEYCODE_BACK
sleep 3
alive
capture "02-back-to-incidents"
# The native touchscreen must SCROLL when dragged from an incident card.
# Previously buttons/panels consumed the touch gesture, leaving the list fixed.
adb shell input swipe "$((width / 2))" "$((height * 67 / 100))" "$((width / 2))" "$((height * 33 / 100))" 530
sleep 2
capture "02a-incidents-after-touch-scroll"
if cmp -s "$out/02-back-to-incidents.png" "$out/02a-incidents-after-touch-scroll.png"; then
  echo "::error::Incident list did not respond to a real Android touch swipe"
  exit 1
fi
# Real Android 720x1600 screenshot inspection: the first "NEXT" action
# spans y1330-1420 (center ~1376 = 86%), NOT 91% (empty safe margin).
# Stamps screen "FILE NUDGE" sits at y1287-1375 (~83%), while the
# secondary "NO STAMP" action sits below it (88% must never be used).
tap_percent 86
capture "03-choose-stamp"
adb shell input swipe "$((width / 2))" "$((height * 66 / 100))" "$((width / 2))" "$((height * 34 / 100))" 530
sleep 2
capture "03a-stamps-after-touch-scroll"
if cmp -s "$out/03-choose-stamp.png" "$out/03a-stamps-after-touch-scroll.png"; then
  echo "::error::Stamp gallery did not respond to a real Android touch swipe"
  exit 1
fi
tap_percent 83
capture "04-stamp-filed"
tap_percent 83
capture "05-causality-theater"
# These are different actual game screens. Identical screenshots mean the
# supposed taps did not reach the UI; screenshot filesize alone can lie.
for pair in '02-back-to-incidents 03-choose-stamp' '03-choose-stamp 04-stamp-filed' '04-stamp-filed 05-causality-theater'; do
  read -r before after <<< "$pair"
  if cmp -s "$out/$before.png" "$out/$after.png"; then
    echo "::error::Android screenshots did not change between $before and $after"
    exit 1
  fi
done
adb shell input keyevent KEYCODE_BACK
sleep 2
alive
capture "06-back-from-theater"
adb shell input keyevent KEYCODE_HOME
sleep 2
# The hosted emulator's AOSP launcher can hang during cold boot even while
# Godot is running. Avoid launching through the home screen.
adb shell am force-stop com.android.launcher3 || true
adb shell am start -W -n "$package/com.godot.game.GodotAppLauncher"
sleep 4
alive
capture "07-resumed-case"
adb logcat -d -s Godot:V AndroidRuntime:E '*:S' > "$out/runtime-log.txt" || true
diagnose
if grep -Eq 'SCRIPT ERROR|Parse Error|FATAL EXCEPTION' "$out/runtime-log.txt"; then
  echo "::error::Godot or Android reported a runtime/script exception"
  grep -E -A 9 'SCRIPT ERROR|Parse Error|FATAL EXCEPTION' "$out/runtime-log.txt" | head -100
  exit 1
fi
echo "PASS: actual Android installation, first-run art, Back, incident selection, stamp flow, causality, and resume"
