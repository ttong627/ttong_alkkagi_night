# -*- coding: utf-8 -*-
"""코덱스가 생성한 심야기습 전용 앱 아이콘으로 안드로이드 런처 아이콘과 스토어 대표 그래픽을 생성한다.

사용법:
  python app\\tool\\art\\apply_night_appicon.py [appicon_night_a]
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
RAW = HERE / "gen" / "night"
RES = REPO / "app" / "android" / "app" / "src" / "main" / "res"
STORE = REPO / "store"
FONT = REPO / "app" / "assets" / "fonts" / "BlackHanSans-Regular.ttf"
DENS = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


def load_source(name: str) -> Image.Image:
    cands = [p for p in RAW.glob(f"{name}.*") if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp")]
    if not cands:
        raise FileNotFoundError(f"아이콘 원본을 찾을 수 없습니다: {RAW / name}")
    return Image.open(cands[0]).convert("RGB")


def rounded(im: Image.Image, ratio: float) -> Image.Image:
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, im.width - 1, im.height - 1),
        int(im.width * ratio),
        fill=255,
    )
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def adaptive_bg(src: Image.Image, side: int) -> Image.Image:
    bg = src.resize((side, side), Image.LANCZOS).filter(ImageFilter.GaussianBlur(max(2, side // 22))).convert("RGBA")
    inner = round(side * 0.78)
    fg = rounded(src.resize((inner, inner), Image.LANCZOS), 0.18)
    bg.alpha_composite(fg, ((side - inner) // 2, (side - inner) // 2))
    return bg.convert("RGB")


def make_feature_graphic(src_icon: Image.Image) -> Image.Image:
    w, h = 1024, 500
    splash_p = REPO / "app" / "assets" / "images" / "scenes" / "bg_night_splash.webp"
    lobby_p = REPO / "app" / "assets" / "images" / "scenes" / "bg_night_lobby.webp"
    bg_path = splash_p if splash_p.exists() else (lobby_p if lobby_p.exists() else REPO / "app" / "assets" / "images" / "scenes" / "bg_lobby.webp")
    bg_img = Image.open(bg_path).convert("RGB")
    scale = w / bg_img.width
    bg_img = bg_img.resize((w, round(bg_img.height * scale)), Image.LANCZOS)
    top = min(max(0, round(bg_img.height * 0.14)), max(0, bg_img.height - h))
    canvas = bg_img.crop((0, top, w, top + h)).convert("RGBA")

    shade = Image.new("RGBA", (w, h), (10, 14, 28, 0))
    draw_s = ImageDraw.Draw(shade)
    for x in range(w):
        alpha = int(225 * max(0.0, 1.0 - x / (w * 0.78)))
        draw_s.line([(x, 0), (x, h)], fill=(10, 14, 28, alpha))
    canvas.alpha_composite(shade)

    icon_card = rounded(src_icon.resize((350, 350), Image.LANCZOS), 0.20)
    glow = Image.new("RGBA", (392, 392), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle((12, 12, 380, 380), 78, fill=(255, 209, 102, 165))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(14)), (w - 350 - 58 - 21, (h - 392) // 2))
    canvas.alpha_composite(icon_card, (w - 350 - 58, (h - 350) // 2))

    d = ImageDraw.Draw(canvas)
    f_big = ImageFont.truetype(str(FONT), 82)
    f_mid = ImageFont.truetype(str(FONT), 44)
    f_sub = ImageFont.truetype(str(FONT), 23)
    f_corp = ImageFont.truetype(str(FONT), 21)

    d.text((54, 86), "수호알까기", font=f_big, fill=(255, 214, 102), stroke_width=6, stroke_fill=(16, 12, 32))
    d.text((56, 190), "탄지무림 심야기습", font=f_mid, fill=(255, 255, 255), stroke_width=5, stroke_fill=(16, 12, 32))
    d.text((58, 286), "자동 탄지 진법과 영수, 동료로 열 마을을 지켜라!", font=f_sub, fill=(144, 240, 228), stroke_width=4, stroke_fill=(12, 18, 30))
    d.text((58, 334), "실패 없는 경맥 수련 | 무림수호단 출두 | 오프라인 완결", font=f_corp, fill=(235, 238, 248), stroke_width=3, stroke_fill=(12, 18, 30))
    d.text((58, 434), "(주)웰쉐어로지스", font=f_corp, fill=(215, 222, 238), stroke_width=3, stroke_fill=(12, 18, 30))
    return canvas.convert("RGB")


def main() -> int:
    name = sys.argv[1] if len(sys.argv) > 1 else "appicon_night_a"
    src = load_source(name)
    STORE.mkdir(parents=True, exist_ok=True)
    for dens, mult in DENS.items():
        d = RES / f"mipmap-{dens}"
        d.mkdir(parents=True, exist_ok=True)
        src.resize((round(48 * mult), round(48 * mult)), Image.LANCZOS).save(d / "ic_launcher.png", optimize=True)
        side = round(108 * mult)
        adaptive_bg(src, side).save(d / "ic_launcher_background.png", optimize=True)
        Image.new("RGBA", (side, side), (0, 0, 0, 0)).save(d / "ic_launcher_foreground.png", optimize=True)

    src.resize((512, 512), Image.LANCZOS).save(STORE / "icon-512.png", optimize=True)
    # 웹 파비콘 및 앱 내 로고용 아이콘도 함께 갱신
    web_icons = REPO / "app" / "web" / "icons"
    if web_icons.exists():
        src.resize((192, 192), Image.LANCZOS).save(web_icons / "Icon-192.png", optimize=True)
        src.resize((512, 512), Image.LANCZOS).save(web_icons / "Icon-512.png", optimize=True)
        src.resize((192, 192), Image.LANCZOS).save(web_icons / "Icon-maskable-192.png", optimize=True)
        src.resize((512, 512), Image.LANCZOS).save(web_icons / "Icon-maskable-512.png", optimize=True)
    fav = REPO / "app" / "web" / "favicon.png"
    if fav.parent.exists():
        src.resize((64, 64), Image.LANCZOS).save(fav, optimize=True)

    make_feature_graphic(src).save(STORE / "feature-graphic-1024x500.png", optimize=True)
    print(f"✅ 심야기습 전용 앱 아이콘 및 스토어 그래픽 생성 완료: {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
