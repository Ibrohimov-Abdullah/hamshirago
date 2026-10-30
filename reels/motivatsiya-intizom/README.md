# Reel: “Motivatsiyami yoki intizom?”

The reel is generated from code: animated graphics, word-timed subtitles, an original
music bed with sound effects, and an optional native Uzbek voiceover.

| File | What it is |
| --- | --- |
| `out/reel.mp4` | Final reel, 1080×1920, 30 fps, H.264 + AAC, normalised to −14 LUFS |
| `out/reel_no_audio.mp4` | Same video with no sound, for adding Instagram audio or your own voice in the app |
| `out/cover.jpg` / `out/cover.png` | Reel cover, 1080×1920 |
| `out/cover_grid_preview_3x4.jpg` | Preview of the cover as it appears in the profile grid |
| `CAPTION.md` | Caption, hashtags and a pinned comment |

## Add the native Uzbek voiceover

The voice comes from Microsoft's Uzbek neural voices (`uz-UZ-SardorNeural`, male, and
`uz-UZ-MadinaNeural`, female). They are native speakers, so there is no foreign accent.
Subtitles follow the voice's word timings.

### macOS: one step

Paste this into Terminal (needs internet; takes a few minutes):

```bash
cd ~/Desktop && git clone --depth 1 --filter=blob:none --sparse --branch claude/instagram-reel-motivation-discipline-guvxes https://github.com/Ibrohimov-Abdullah/hamshirago.git kelajak-reel && cd kelajak-reel && git sparse-checkout set reels/motivatsiya-intizom && bash reels/motivatsiya-intizom/make_reel_mac.sh
```

It installs the Python packages (ffmpeg comes with `imageio-ffmpeg`, no Homebrew needed),
renders `out/reel_sardor.mp4` and `out/reel_madina.mp4`, and opens the folder.

### Manual

```bash
python3 -m pip install --user edge-tts pillow numpy imageio-ffmpeg
python3 build_reel.py --voice uz-UZ-SardorNeural
python3 build_reel.py --voice uz-UZ-MadinaNeural
python3 build_reel.py --no-voice
```

Without `--require-voice`, an unreachable voice server (`speech.platform.bing.com`) makes
the build fall back to a music-only `out/reel.mp4`. The bot handle is spoken as
“Kelajak Testi bot” and the price as “bir ming to‘qqiz yuz to‘qson so‘m”; both are set in
`SEGMENTS` in `build_reel.py`.

`python3 make_cover.py` regenerates the cover. Fonts: Inter (SIL OFL 1.1, see `fonts/OFL.txt`).
