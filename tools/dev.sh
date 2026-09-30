#!/usr/bin/env bash
# Development commands. Uses $GODOT, or the portable binary in tools/godot/.
#   tools/dev.sh setup   download Godot 4.7.2 into tools/godot/ (Windows build)
#   tools/dev.sh test    unit tests (headless)
#   tools/dev.sh smoke   boot the real world and play the whole Vertical Slice (headless)
#   tools/dev.sh shots   render review screenshots into build/screenshots/
#   tools/dev.sh run     play the game
#   tools/dev.sh edit    open the Godot editor
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT_VERSION="4.7.2"
GODOT="${GODOT:-tools/godot/Godot_v${GODOT_VERSION}-stable_win64_console.exe}"

import() { "$GODOT" --headless --path . --import >/dev/null 2>&1 || true; }

case "${1:-}" in
  setup)
    mkdir -p tools/godot
    curl -sL -o tools/godot/godot.zip "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_win64.exe.zip"
    unzip -oq tools/godot/godot.zip -d tools/godot && rm tools/godot/godot.zip
    "$GODOT" --version ;;
  test)  import; "$GODOT" --headless --path . -s tests/run_tests.gd ;;
  smoke) import; "$GODOT" --headless --path . -s tests/smoke_world.gd ;;
  shots) import; mkdir -p build/screenshots; "$GODOT" --path . -s tests/screenshot_tour.gd -- "$(pwd)/build/screenshots" ;;
  run)   import; "$GODOT" --path . ;;
  edit)  "$GODOT" --path . --editor ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
