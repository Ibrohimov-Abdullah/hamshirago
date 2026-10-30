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

The voice comes from Microsoft's Uzbek neural voices (`uz-UZ-SardorNeural`, male, which is
the default, and `uz-UZ-MadinaNeural`, female). They are native speakers, so there is no
foreign accent. Subtitles follow the voice's word timings.

```bash
pip install edge-tts pillow numpy      # also needs ffmpeg
python3 build_reel.py                  # Sardor (male)
python3 build_reel.py --voice uz-UZ-MadinaNeural
python3 build_reel.py --no-voice       # music + text only
```

If the voice server (`speech.platform.bing.com`) is unreachable, the build falls back to
the music-only version and prints a notice. The bot handle is spoken as “Kelajak Testi bot”
and the price as “bir ming to‘qqiz yuz to‘qson so‘m”. Both are set in `SEGMENTS` in
`build_reel.py`.

`python3 make_cover.py` regenerates the cover.
