# -*- coding: utf-8 -*-
"""《수호알까기 · 탄지무림 심야기습》 돌연변이 12종 생체역학 모션 및 중간보스 동반 침공 영상 합성기.

역할:
1. 코덱스로 제작한 돌연변이·중간보스·대수괴 기본 원화(`mut_*.webp`)와 공격 원화(`mut_*_atk.webp`),
   심야 침공 균열문(`fx_breach_gate.webp`), 심야 전장 바닥(`floor_night_ch3.webp`), 기명 수호탑을 불러온다.
2. Dart 게임 엔진(`mutant_motion_engine.dart`)과 100% 동일한 발목 축 스쿼시·스트레치, 포물선 도약,
   중갑 발구름 충격파, 초고속 잔상 질주, 전방 덮치기(Windup → Strike → Follow-through) 수식으로
   1920x1080 초당 60프레임 고화질 영상(`돌연변이_침공모션_프리뷰.mp4`)을 생성한다.
   - 제1부(0~5.5초): 돌연변이·중간보스·대수괴 12종 전체 모션 & 스피드·맷집·공격력 전투력 비교 도감 시연
   - 제2부(5.5~11.0초): 상단 독기 균열문 개방 → 군집 침공 + 3대 특화 중간보스 동반 침략 & 방어막 강타 실전 시연
3. 주요 검증 프레임 PNG도 함께 뽑아 육안 검수에 사용한다.
"""
from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
import numpy as np
from PIL import Image, ImageDraw, ImageFont

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

HERE = Path(__file__).resolve().parent
APP_DIR = HERE.parents[1]
ASSETS_IMG = APP_DIR / "assets" / "images"
OUT_DIR = HERE / "out"

W, H = 1920, 1080
FPS = 60
TOTAL_SEC = 10.5
TOTAL_FRAMES = int(FPS * TOTAL_SEC)

SPECIES = [
    {"id": "swarmRat", "name": "심야 독쥐", "role": "속공 군집형", "spd": 4, "tgh": 1, "atk": 1, "cp": 115, "gait": "scamper", "col": (199, 125, 255)},
    {"id": "sickHound", "name": "역병 들개", "role": "초고속 추격형", "spd": 5, "tgh": 2, "atk": 2, "cp": 185, "gait": "gallop", "col": (157, 78, 221)},
    {"id": "ironBoar", "name": "철피 멧돼지", "role": "중장갑 돌파형", "spd": 2, "tgh": 4, "atk": 3, "cp": 390, "gait": "heavyStomp", "col": (255, 159, 28)},
    {"id": "shieldYacha", "name": "뼈방패 야차", "role": "전면 방패형", "spd": 2, "tgh": 4, "atk": 3, "cp": 365, "gait": "shieldMarch", "col": (255, 209, 102)},
    {"id": "plagueToad", "name": "독안개 두꺼비", "role": "맹독 침식형", "spd": 1, "tgh": 3, "atk": 3, "cp": 310, "gait": "toxicHop", "col": (199, 125, 255)},
    {"id": "bloodCocoon", "name": "혈독 분열충", "role": "자폭 분열형", "spd": 3, "tgh": 3, "atk": 2, "cp": 295, "gait": "carapaceScuttle", "col": (255, 0, 84)},
    {"id": "swiftShadowBoss", "name": "혈영 질풍귀", "role": "초고속 기습 중간보스", "spd": 5, "tgh": 2, "atk": 3, "cp": 860, "gait": "shadowDash", "col": (224, 170, 255)},
    {"id": "ironColossusBoss", "name": "현철 중갑거수", "role": "철벽 맷집 중간보스", "spd": 1, "tgh": 5, "atk": 3, "cp": 1080, "gait": "colossusTread", "col": (144, 224, 239)},
    {"id": "crimsonBreakerBoss", "name": "적염 파성귀", "role": "파성 강타 중간보스", "spd": 3, "tgh": 3, "atk": 5, "cp": 990, "gait": "breakerSlam", "col": (255, 77, 0)},
    {"id": "heukpung", "name": "약탈 선봉 흑풍", "role": "약탈 돌격 우두머리", "spd": 3, "tgh": 4, "atk": 4, "cp": 1180, "gait": "dualCleaverRush", "col": (230, 57, 70)},
    {"id": "mukhyeonBoss", "name": "독기에 물든 묵현", "role": "흑화 검기 우두머리", "spd": 4, "tgh": 4, "atk": 5, "cp": 1420, "gait": "swordGlide", "col": (157, 78, 221)},
    {"id": "chapterBoss", "name": "심야 대요마", "role": "천상 대수괴", "spd": 2, "tgh": 5, "atk": 5, "cp": 1950, "gait": "overlordFloat", "col": (255, 0, 84)},
]


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        Path(r"C:\Windows\Fonts\malgunbd.ttf" if bold else r"C:\Windows\Fonts\malgun.ttf"),
        APP_DIR / "assets" / "fonts" / "DoHyeon-Regular.ttf",
    ]
    for c in candidates:
        if c.exists():
            return ImageFont.truetype(str(c), size)
    return ImageFont.load_default()


def sample_motion(gait: str, phase: float, t: float, uid: int, heading: float, atk_timer: float, dash_timer: float) -> dict:
    """Dart `MutantMotionEngine.sample` 과 동일한 생체역학 모션 수식."""
    lift_y = 0.0
    sway_x = 0.0
    sx, sy = 1.0, 1.0
    tilt = 0.0
    foot_impact = 0.0
    afterimages = 0
    move_bank = math.cos(heading) * 0.09

    if gait == "scamper":
        s = math.sin(phase * 2.1)
        hop = abs(s)
        lift_y = -hop * 6.0
        sway_x = math.sin(phase * 1.05 + uid) * 4.0
        sy = 0.92 + hop * 0.14
        sx = 1.0 / sy
        tilt = move_bank + math.sin(phase * 1.05) * 0.13
        foot_impact = max(0.0, 1.0 - hop)
    elif gait == "gallop":
        g = math.sin(phase * 1.75)
        leap = max(0.0, g)
        land = max(0.0, -g)
        lift_y = -leap * 12.0
        sway_x = math.cos(phase * 0.88 + uid) * 3.5
        sy = 1.0 + leap * 0.14 - land * 0.11
        sx = 1.0 / sy
        tilt = move_bank * 1.35 + g * 0.11
        foot_impact = (land - 0.72) / 0.28 if land > 0.72 else 0.0
        afterimages = 2 if dash_timer > 0 else 0
    elif gait == "heavyStomp":
        w = math.sin(phase * 1.15)
        stomp = abs(w) ** 2.2
        lift_y = -(1.0 - stomp) * 5.0
        sway_x = w * 4.0
        sx = 0.96 + stomp * 0.11
        sy = 1.0 / sx
        tilt = move_bank * 0.8 + w * 0.10
        foot_impact = (stomp - 0.82) / 0.18 if stomp > 0.82 else 0.0
    elif gait == "shieldMarch":
        m = math.sin(phase * 1.25)
        step = abs(m)
        lift_y = -step * 4.5
        sway_x = m * 2.5
        sx = 1.04 - step * 0.06
        sy = 1.0 / sx
        tilt = move_bank * 0.6 + m * 0.06
        foot_impact = 0.7 if (1.0 - step) > 0.78 else 0.0
    elif gait == "toxicHop":
        norm = ((phase * 0.42) % (2 * math.pi)) / (2 * math.pi)
        if norm < 0.24:
            crouch = math.sin((norm / 0.24) * math.pi)
            sx = 1.0 + crouch * 0.18
            sy = 1.0 / sx
        elif norm < 0.76:
            air_t = (norm - 0.24) / 0.52
            arc = math.sin(air_t * math.pi)
            lift_y = -arc * 19.0
            sy = 1.0 + arc * 0.16
            sx = 1.0 / sy
            tilt = move_bank + math.cos(air_t * math.pi) * 0.08
        else:
            splat = math.sin(((norm - 0.76) / 0.24) * math.pi)
            sx = 1.0 + splat * 0.15
            sy = 1.0 / sx
            foot_impact = splat
    elif gait == "carapaceScuttle":
        sc = math.sin(phase * 2.4)
        pulse = math.sin(t * 8.5 + uid) * 0.055
        lift_y = -abs(sc) * 4.0
        sway_x = math.cos(phase * 1.2) * 3.5
        sx = 1.0 + pulse + abs(sc) * 0.04
        sy = 1.0 + pulse - abs(sc) * 0.04
        tilt = move_bank + sc * 0.09
    elif gait == "shadowDash":
        d = math.sin(phase * 2.2)
        lift_y = -6.0 - abs(d) * 7.5
        sway_x = math.sin(phase * 1.1 + uid) * (7.5 if dash_timer > 0 else 4.2)
        sy = 1.05 + abs(d) * 0.08
        sx = 1.0 / sy
        tilt = move_bank * 1.6 + d * 0.12
        afterimages = 3 if dash_timer > 0 else 2
        foot_impact = 0.75 if abs(d) < 0.22 else 0.0
    elif gait == "colossusTread":
        tr = math.sin(phase * 0.78)
        heavy_land = (1.0 - abs(tr)) ** 3.0
        lift_y = -abs(tr) * 7.0
        sway_x = tr * 5.0
        sx = 1.0 + heavy_land * 0.12
        sy = 1.0 / sx
        tilt = tr * 0.08
        foot_impact = heavy_land if heavy_land > 0.65 else 0.0
    elif gait == "breakerSlam":
        br = math.sin(phase * 1.08)
        lift_y = -abs(br) * 7.5
        sway_x = br * 4.6
        sy = 0.96 + abs(br) * 0.10
        sx = 1.0 / sy
        tilt = move_bank + br * 0.14
        foot_impact = 0.85 if abs(br) < 0.22 else 0.0
    elif gait == "dualCleaverRush":
        hk = math.sin(phase * 1.45)
        lift_y = -abs(hk) * 8.0
        sway_x = hk * 4.0
        sy = 0.95 + abs(hk) * 0.11
        sx = 1.0 / sy
        tilt = move_bank * 1.2 + hk * 0.12
    elif gait == "swordGlide":
        lift_y = -9.0 - math.sin(t * 3.4 + uid) * 5.5
        sway_x = math.sin(t * 2.2 + uid) * 6.0
        sy = 1.02 + math.sin(t * 3.4) * 0.04
        sx = 1.0 / sy
        tilt = move_bank * 1.3 + math.cos(t * 2.2) * 0.08
        afterimages = 2
    else:  # overlordFloat
        lift_y = -12.0 - math.sin(t * 2.5) * 7.0
        sway_x = math.sin(t * 1.4) * 4.8
        pulse = math.sin(t * 4.2) * 0.05
        sx = 1.0 + pulse
        sy = 1.0 - pulse * 0.6
        tilt = math.sin(t * 1.4) * 0.06
        afterimages = 2

    thrust = 0.0
    slash_alpha = 0.0
    atk_blend = 0.0
    if atk_timer > 0.01:
        at = max(0.0, min(1.0, 1.0 - atk_timer))
        if at < 0.25:
            w = at / 0.25
            thrust = -9.0 * w
            sx *= 1.0 + 0.10 * w
            sy *= 1.0 - 0.08 * w
            atk_blend = w * 0.7
        elif at < 0.65:
            s = (at - 0.25) / 0.40
            punch = math.sin(s * math.pi)
            thrust = 22.0 * punch
            lift_y -= 7.0 * punch
            sy *= 1.0 + 0.14 * punch
            sx *= 1.0 - 0.09 * punch
            slash_alpha = punch
            atk_blend = 1.0
        else:
            r = (1.0 - at) / 0.35
            thrust = 6.5 * r
            slash_alpha = 0.35 * r
            atk_blend = r

    h_ratio = max(0.0, min(1.0, -lift_y / 22.0))
    return {
        "lift_y": lift_y,
        "sway_x": sway_x,
        "thrust": thrust,
        "sx": max(0.76, min(1.32, sx)),
        "sy": max(0.76, min(1.32, sy)),
        "tilt_deg": -math.degrees(max(-0.6, min(0.6, tilt))),
        "shadow_scale": (1.0 - h_ratio * 0.36) * max(0.85, min(1.2, sx)),
        "shadow_alpha": int(255 * max(0.16, min(0.54, 0.48 - h_ratio * 0.22))),
        "foot_impact": max(0.0, min(1.0, foot_impact)),
        "use_atk": atk_blend >= 0.45,
        "afterimages": afterimages,
        "slash_alpha": slash_alpha,
    }


def paste_transformed(canvas: Image.Image, sprite: Image.Image, cx: float, cy: float, base_size: int, sx: float, sy: float, tilt_deg: float, alpha_mult: float = 1.0):
    nw = max(8, int(base_size * sx))
    nh = max(8, int(base_size * sy))
    im = sprite.resize((nw, nh), Image.BILINEAR)
    if abs(tilt_deg) > 0.4:
        im = im.rotate(tilt_deg, resample=Image.BILINEAR, expand=True)
    if alpha_mult < 0.99:
        r, g, b, a = im.split()
        a = a.point(lambda p: int(p * alpha_mult))
        im = Image.merge("RGBA", (r, g, b, a))
    # 발바닥 기준 정렬 보정
    px = int(cx - im.width / 2)
    py = int(cy - im.height * 0.62)
    canvas.alpha_composite(im, (px, py))


def draw_creature(canvas: Image.Image, draw: ImageDraw.ImageDraw, sp_base: Image.Image, sp_atk: Image.Image, cx: float, cy: float, size: int, m: dict, col: tuple[int, int, int], heading: float = math.pi / 2):
    # 1. 지면 그림자
    sw = int(size * 0.68 * m["shadow_scale"])
    sh = int(size * 0.24 * m["shadow_scale"])
    sy_pos = int(cy + size * 0.30)
    draw.ellipse([cx - sw // 2, sy_pos - sh // 2, cx + sw // 2, sy_pos + sh // 2], fill=(4, 7, 15, m["shadow_alpha"]))

    # 2. 발구름 충격파/먼지 고리
    if m["foot_impact"] > 0.15:
        ring_r = int(size * (0.36 + 0.28 * (1.0 - m["foot_impact"])))
        ring_a = int(165 * m["foot_impact"])
        draw.ellipse([cx - ring_r, sy_pos - ring_r // 2, cx + ring_r, sy_pos + ring_r // 2], outline=(*col, ring_a), width=3)

    dx = math.cos(heading) * m["thrust"] + m["sway_x"]
    dy = math.sin(heading) * m["thrust"] + m["lift_y"]
    chosen = sp_atk if m["use_atk"] else sp_base

    # 3. 초고속 기습·보스 잔상
    for idx in range(m["afterimages"], 0, -1):
        lag = idx * 11.0
        paste_transformed(
            canvas,
            chosen,
            cx + dx - math.cos(heading) * lag,
            cy + dy - math.sin(heading) * lag,
            size,
            m["sx"] * 0.96,
            m["sy"] * 0.96,
            m["tilt_deg"],
            alpha_mult=0.22 / idx,
        )

    # 4. 본체 원화(발목 피벗 스쿼시·스트레치)
    paste_transformed(canvas, chosen, cx + dx, cy + dy, size, m["sx"], m["sy"], m["tilt_deg"])

    # 5. 전방 공격 궤적 호
    if m["slash_alpha"] > 0.08:
        sa = int(230 * m["slash_alpha"])
        arc_r = int(size * 0.62)
        ax = cx + dx + math.cos(heading) * (size * 0.24)
        ay = cy + dy + math.sin(heading) * (size * 0.24)
        deg = math.degrees(heading)
        draw.arc([ax - arc_r, ay - arc_r, ax + arc_r, ay + arc_r], start=deg - 65, end=deg + 65, fill=(*col, sa), width=6)
        draw.arc([ax - arc_r + 6, ay - arc_r + 6, ax + arc_r - 6, ay + arc_r - 6], start=deg - 48, end=deg + 48, fill=(255, 255, 255, sa), width=3)


def make_bar(draw: ImageDraw.ImageDraw, x: int, y: int, label: str, rating: int, color: tuple[int, int, int], font_s):
    draw.text((x, y - 2), label, font=font_s, fill=(210, 222, 240, 255))
    bx = x + 56
    for i in range(5):
        rx = bx + i * 22
        fill = (*color, 245) if i < rating else (38, 48, 72, 200)
        draw.rounded_rectangle([rx, y + 3, rx + 18, y + 15], radius=3, fill=fill)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    font_title = load_font(29, bold=True)
    font_sub = load_font(19)
    font_card = load_font(21, bold=True)
    font_small = load_font(15)

    # 원화 로드
    sprites_base: dict[str, Image.Image] = {}
    sprites_atk: dict[str, Image.Image] = {}
    for sp in SPECIES:
        sid = sp["id"]
        p_base = ASSETS_IMG / "mutants" / f"mut_{sid}.webp"
        p_atk = ASSETS_IMG / "mutants" / f"mut_{sid}_atk.webp"
        sprites_base[sid] = Image.open(p_base).convert("RGBA")
        sprites_atk[sid] = Image.open(p_atk).convert("RGBA") if p_atk.exists() else sprites_base[sid]

    breach_img = Image.open(ASSETS_IMG / "fx" / "fx_breach_gate.webp").convert("RGBA")
    tower_img = Image.open(ASSETS_IMG / "launchers" / "tower_guardian.webp").convert("RGBA")
    barrier_img = Image.open(ASSETS_IMG / "fx" / "fx_barrier.webp").convert("RGBA")
    floor_img = Image.open(ASSETS_IMG / "scenes" / "floor_night_ch3.webp").convert("RGB").resize((W, H), Image.BILINEAR)
    dark_overlay = Image.new("RGBA", (W, H), (8, 12, 24, 178))
    bg_scene = Image.alpha_composite(floor_img.convert("RGBA"), dark_overlay)

    out_mp4 = OUT_DIR / "돌연변이_침공모션_프리뷰.mp4"
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
    cmd = [
        ffmpeg_exe, "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{W}x{H}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",
        "-an",
        "-vcodec", "libx264",
        "-pix_fmt", "yuv420p",
        "-preset", "fast",
        "-crf", "19",
        str(out_mp4),
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)

    # 제2부 침공 개체 구성 (군집 + 3대 중간보스 동반 침략!)
    invaders = [
        {"sid": "swiftShadowBoss", "lane_x0": 420, "lane_x1": 760, "spd": 148, "y0": 150, "size": 148, "uid": 1},
        {"sid": "ironColossusBoss", "lane_x0": 960, "lane_x1": 960, "spd": 74, "y0": 175, "size": 168, "uid": 2},
        {"sid": "crimsonBreakerBoss", "lane_x0": 1500, "lane_x1": 1160, "spd": 106, "y0": 160, "size": 156, "uid": 3},
        {"sid": "sickHound", "lane_x0": 340, "lane_x1": 690, "spd": 162, "y0": 95, "size": 98, "uid": 4},
        {"sid": "swarmRat", "lane_x0": 510, "lane_x1": 810, "spd": 142, "y0": 80, "size": 86, "uid": 5},
        {"sid": "ironBoar", "lane_x0": 860, "lane_x1": 900, "spd": 92, "y0": 105, "size": 112, "uid": 6},
        {"sid": "shieldYacha", "lane_x0": 1060, "lane_x1": 1020, "spd": 96, "y0": 110, "size": 108, "uid": 7},
        {"sid": "plagueToad", "lane_x0": 1410, "lane_x1": 1110, "spd": 84, "y0": 95, "size": 108, "uid": 8},
        {"sid": "bloodCocoon", "lane_x0": 1580, "lane_x1": 1230, "spd": 114, "y0": 85, "size": 102, "uid": 9},
    ]
    sp_lookup = {s["id"]: s for s in SPECIES}

    for f_idx in range(TOTAL_FRAMES):
        t = f_idx / FPS
        frame = bg_scene.copy()
        draw = ImageDraw.Draw(frame, "RGBA")

        if t < 5.5:
            # ── 제1부: 12종 생체역학 모션 & 전투력 3대 분화 쇼케이스 ──
            draw.rounded_rectangle([40, 22, W - 40, 96], radius=16, fill=(14, 20, 36, 232), outline=(255, 209, 102, 200), width=2)
            draw.text((68, 36), "《수호알까기 · 탄지무림 심야기습》 코덱스 돌연변이 12종 생체역학 모션 & 전투력 분화 검증", font=font_title, fill=(255, 209, 102, 255))
            draw.text((1345, 46), "스피드 · 맷집 · 공격력 3대 특화 | 60프레임 실시간 변환", font=font_sub, fill=(114, 239, 221, 255))

            cols, rows = 4, 3
            cw, ch_box = 446, 302
            for idx, sp in enumerate(SPECIES):
                gx = 46 + (idx % cols) * (cw + 18)
                gy = 114 + (idx // cols) * (ch_box + 14)
                is_boss = idx >= 6
                border_col = (*sp["col"], 220 if is_boss else 145)
                draw.rounded_rectangle([gx, gy, gx + cw, gy + ch_box], radius=16, fill=(18, 25, 44, 224), outline=border_col, width=3 if is_boss else 2)

                # 주기적 공격 시연(2.5초마다 전방 강타 포즈 시연!)
                cyc_t = (t + idx * 0.22) % 2.4
                atk_timer = max(0.0, 1.0 - (cyc_t - 1.45) / 0.72) if 1.45 <= cyc_t <= 2.17 else 0.0
                dash_timer = 0.5 if (sp["gait"] in ("shadowDash", "gallop") and cyc_t < 0.8) else 0.0
                phase = t * (3.2 + sp["spd"] * 0.65) + idx

                m = sample_motion(sp["gait"], phase, t, idx + 1, math.pi / 2, atk_timer, dash_timer)
                draw_creature(
                    frame,
                    draw,
                    sprites_base[sp["id"]],
                    sprites_atk[sp["id"]],
                    gx + 108,
                    gy + 168,
                    138 if is_boss else 120,
                    m,
                    sp["col"],
                )

                # 우측 명칭 및 능력치 막대
                tx = gx + 214
                draw.text((tx, gy + 20), sp["name"], font=font_card, fill=(255, 209, 102, 255) if is_boss else (245, 248, 255, 255))
                draw.text((tx, gy + 52), f"{sp['role']} · 전투력 {sp['cp']}", font=font_small, fill=(*sp["col"], 255))
                make_bar(draw, tx, gy + 94, "스피드", sp["spd"], (114, 239, 221), font_small)
                make_bar(draw, tx, gy + 126, "맷  집", sp["tgh"], (76, 201, 240), font_small)
                make_bar(draw, tx, gy + 158, "공격력", sp["atk"], (255, 95, 109), font_small)
                state_txt = "▶ 돌격·강타 자세 발동!" if m["use_atk"] else "● 생체 보행·호흡 주행"
                draw.text((tx, gy + 204), state_txt, font=font_small, fill=(255, 209, 102, 255) if m["use_atk"] else (184, 196, 217, 255))
        else:
            # ── 제2부: 상단 침공 균열문 + 군집·중간보스 3종 동반 침략 실전 시연 ──
            st = t - 5.5
            # 경보 현수막
            draw.rounded_rectangle([310, 24, W - 310, 96], radius=18, fill=(44, 12, 24, 238), outline=(255, 77, 109, 240), width=3)
            draw.text((356, 40), "[긴급 경보] 중간보스 동반 대침공! 혈영 질풍귀(속도) · 현철 중갑거수(맷집) · 적염 파성귀(공격력) 기습!", font=font_card, fill=(255, 209, 102, 255))

            # 침공 길목 3줄
            for lx0, lx1 in [(420, 760), (960, 960), (1500, 1160)]:
                draw.line([(lx0, 130), (lx1, 835)], fill=(54, 68, 98, 125), width=62)
                # 상단 침공 균열문 회전
                rot_gate = breach_img.resize((164, 164), Image.BILINEAR).rotate((t * 85) % 360, resample=Image.BILINEAR)
                frame.alpha_composite(rot_gate, (lx0 - 82, 68))

            # 하단 기명 수호탑 + 외곽 기공 방어막
            tcx, tcy = 960, 900
            rot_bar = barrier_img.resize((460, 460), Image.BILINEAR).rotate((-t * 28) % 360, resample=Image.BILINEAR)
            frame.alpha_composite(rot_bar, (tcx - 230, tcy - 230))
            draw.ellipse([tcx - 220, tcy - 220, tcx + 220, tcy + 220], outline=(76, 201, 240, 210), width=5)
            t_img = tower_img.resize((156, 156), Image.BILINEAR)
            frame.alpha_composite(t_img, (tcx - 78, tcy - 82))

            # 침공 무리 & 중간보스 전진 및 방어막 충돌 강타!
            for inv in sorted(invaders, key=lambda item: item["y0"]):
                sp = sp_lookup[inv["sid"]]
                travel = st * inv["spd"]
                prog = min(1.0, travel / 540.0)
                cx = inv["lane_x0"] + (inv["lane_x1"] - inv["lane_x0"]) * prog
                cy = inv["y0"] + 540.0 * prog
                heading = math.atan2(inv["lane_x1"] != inv["lane_x0"] and 540.0 or 540.0, inv["lane_x1"] - inv["lane_x0"])

                # 방어막 도달 시 연속 덮치기 강타!
                atk_timer = 0.0
                if prog >= 0.96:
                    hit_cyc = (st * 1.6 + inv["uid"] * 0.3) % 1.0
                    atk_timer = max(0.0, 1.0 - hit_cyc)
                dash_timer = 0.6 if (sp["gait"] == "shadowDash" and (st % 1.8) < 0.7) else 0.0
                phase = t * (3.0 + sp["spd"] * 0.75) + inv["uid"]
                m = sample_motion(sp["gait"], phase, t, inv["uid"], heading, atk_timer, dash_timer)
                draw_creature(
                    frame,
                    draw,
                    sprites_base[sp["id"]],
                    sprites_atk[sp["id"]],
                    cx,
                    cy,
                    inv["size"],
                    m,
                    sp["col"],
                    heading=heading,
                )
                if inv["uid"] <= 3:
                    draw.rounded_rectangle([cx - 112, cy - inv["size"] * 0.62, cx + 112, cy - inv["size"] * 0.62 + 28], radius=8, fill=(12, 16, 28, 215), outline=(*sp["col"], 220), width=2)
                    draw.text((cx - 98, cy - inv["size"] * 0.62 + 4), f"{sp['name']} · 전투력 {sp['cp']}", font=font_small, fill=(255, 209, 102, 255))

        rgb_bytes = frame.convert("RGB").tobytes()
        assert proc.stdin is not None
        proc.stdin.write(rgb_bytes)

        if f_idx in (int(1.7 * FPS), int(4.2 * FPS), int(8.6 * FPS)):
            snap = OUT_DIR / f"preview_frame_{f_idx:04d}.png"
            frame.convert("RGB").save(snap)

    assert proc.stdin is not None
    proc.stdin.close()
    stderr_out = proc.stderr.read().decode("utf-8", errors="ignore") if proc.stderr else ""
    rc = proc.wait()
    if rc != 0:
        print(f"⛔ 영상 인코딩 실패(rc={rc}): {stderr_out[-400:]}")
        return 1

    size_mb = out_mp4.stat().st_size / (1024 * 1024)
    print(f"✅ 돌연변이 침공 모션 영상 생성 완료: {out_mp4} ({size_mb:.2f} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
