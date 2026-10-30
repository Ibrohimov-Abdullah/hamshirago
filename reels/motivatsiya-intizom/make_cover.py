"""Reel cover (1080x1920). Key content stays inside the centre 1080x1080 so it
survives Instagram's 3:4 profile-grid crop and the 1:1 feed preview."""
import os

from reel_gfx import (AMBER, BLACK, DIM, GREEN, H, INK, RED, SEMI, TEAL, VIOLET, W, WHITE,
                      XBOLD, Background, Frame, circle, glow, rrect, text_width)

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    fr = Frame(Background(seed=11).render(2.0, VIOLET, TEAL, 0.75, 0.6))
    cx = W / 2

    # brand
    fr.blit(rrect(320, 58, 29, (255, 255, 255, 20), (255, 255, 255, 50), 2), cx, 330)
    fr.blit(circle(14, AMBER + (255,)), cx - 122, 330)
    fr.text("KELAJAK TESTI", SEMI, 24, WHITE, cx + 14, 330, tracking=4, shadow=0)

    # hook line: Du (green) -> Ju (red)
    y = 520
    fr.blit(rrect(86, 86, 24, GREEN + (255,)), cx - 260, y)
    fr.text("Du", XBOLD, 36, INK, cx - 260, y, shadow=0)
    fr.text("→", XBOLD, 54, DIM, cx - 165, y - 4)
    fr.blit(rrect(86, 86, 24, RED + (255,)), cx - 70, y)
    fr.text("Ju", XBOLD, 36, INK, cx - 70, y, shadow=0)
    fr.text("yana eski odatlar?", SEMI, 38, WHITE, cx + 6, y, anchor="l")

    # title
    fr.blit(glow(760, 150, 75, VIOLET, 60, 0.75), cx, 735)
    fr.text("Motivatsiyami", BLACK, 124, WHITE, cx, 735)
    fr.text("yoki", SEMI, 62, AMBER, cx, 868)
    fr.blit(glow(780, 170, 85, TEAL, 70, 0.8), cx, 1020)
    fr.text("INTIZOM?", BLACK, 176, TEAL, cx, 1020)

    # facts row
    y = 1215
    items = [("28 savol", WHITE), ("9 yo‘nalish", WHITE), ("Bepul", GREEN)]
    widths = [text_width(t, XBOLD, 36) + 56 for t, _ in items]
    x = cx - (sum(widths) + 24 * (len(items) - 1)) / 2
    for (label, col), w in zip(items, widths):
        fr.blit(rrect(int(w), 74, 37, (255, 255, 255, 22), (255, 255, 255, 60), 2),
                x + w / 2, y)
        fr.text(label, XBOLD, 36, col, x + w / 2, y)
        x += w + 24

    # bot handle
    fr.blit(glow(700, 104, 52, AMBER, 30, 0.7), cx, 1365)
    fr.blit(rrect(700, 104, 52, AMBER + (255,)), cx, 1365)
    fr.text("@kelajak_testi_bot", BLACK, 48, INK, cx, 1365, shadow=0)

    out = os.path.join(HERE, "out")
    os.makedirs(out, exist_ok=True)
    im = fr.im.convert("RGB")
    im.save(os.path.join(out, "cover.png"), optimize=True)
    im.save(os.path.join(out, "cover.jpg"), quality=95)
    im.crop((0, 240, W, 1680)).save(os.path.join(out, "cover_grid_preview_3x4.jpg"), quality=92)
    print("wrote cover.png / cover.jpg")


if __name__ == "__main__":
    main()
