#!/bin/bash
# One-step build for macOS (also works on Linux): installs the Python packages,
# then renders the reel with both native Uzbek voices into ./out
set -e
cd "$(dirname "$0")"

echo "==> Installing Python packages (edge-tts, pillow, numpy, imageio-ffmpeg)"
python3 -m pip install --user --upgrade --quiet pip
python3 -m pip install --user --upgrade --quiet edge-tts pillow numpy imageio-ffmpeg

echo "==> Rendering with Sardor (male voice)"
python3 build_reel.py --voice uz-UZ-SardorNeural --require-voice

echo "==> Rendering with Madina (female voice)"
python3 build_reel.py --voice uz-UZ-MadinaNeural --require-voice

echo "==> Done: out/reel_sardor.mp4 and out/reel_madina.mp4"
open out 2>/dev/null || true
