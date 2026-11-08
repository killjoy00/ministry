#!/usr/bin/env bash
set -euo pipefail
# Pack native Linux with a launcher and preserved executable permissions.
for file in build/ministry-of-coincidences-linux.x86_64 build/ministry-of-coincidences-linux.pck build/ministry-of-coincidences-windows.exe build/ministry-of-coincidences-windows.pck; do
  test -s "$file" || { echo "Missing exported game file: $file" >&2; exit 1; }
done
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
folder="$tmp/The Ministry of Coincidences"
mkdir -p "$folder"
cp build/ministry-of-coincidences-linux.x86_64 build/ministry-of-coincidences-linux.pck "$folder/"
cat > "$folder/Play Ministry.sh" <<'LAUNCH'
#!/bin/sh
cd "$(dirname "$0")" || exit 1
exec ./ministry-of-coincidences-linux.x86_64 "$@"
LAUNCH
chmod +x "$folder/Play Ministry.sh" "$folder/ministry-of-coincidences-linux.x86_64"
cat > "$folder/README.txt" <<'DOC'
THE MINISTRY OF COINCIDENCES — STEAM DECK PRE-ALPHA
Extract this archive in Steam Deck Desktop Mode.
Launch Play Ministry.sh, or add that file as a Non-Steam Game.
Keep the .pck and the Linux binary in the same folder. Do not force Proton.
D-pad navigate · A select · LB/RB cycle stamps · X approve · Y advance · B clear
Offline single-player; local autosaves. Steam Deck verification is pending.
DOC
tar -C "$tmp" -czf build/ministry-steam-deck-linux.tar.gz 'The Ministry of Coincidences'
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
with ZipFile("build/ministry-windows.zip", "w", ZIP_DEFLATED, compresslevel=6) as z:
    for filename in ("ministry-of-coincidences-windows.exe", "ministry-of-coincidences-windows.pck"):
        p = Path("build") / filename
        z.write(p, filename)
PY
fi
echo "Packaged Steam Deck and Windows builds"
