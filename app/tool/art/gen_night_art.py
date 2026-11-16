# -*- coding: utf-8 -*-
"""《수호알까기 · 탄지무림 심야기습》 전용 원화 71종을 코덱스(ChatGPT 구독 내장 그림 도구)로 생성·적용한다.

특징:
1. 유료 API 키 0개 — 오직 로컬 로그인된 codex exec 만 호출한다.
2. 병렬 에이전트 안전성 — codex 출력의 `session id: <UUID>` 폴더(`~/.codex/generated_images/<UUID>`)를
   우선 조회하여 동시 생성 시 다른 에이전트의 그림이 섞이는 현상을 원천 차단한다.
3. 이중 크로마키 — 초록(#00FF00) 및 마젠타(#FF00FF) 배경 분리기를 모두 지원하여
   청옥·온옥·야광초·논밭처럼 초록/청록 빛깔이 들어가는 수호석·아이콘도 구멍 없이 깔끔하게 누끼를 딴다.

사용법:
  python app\\tool\\art\\gen_night_art.py draw --only night_token
  python app\\tool\\art\\gen_night_art.py draw --group bg,floor --jobs 3
  python app\\tool\\art\\gen_night_art.py apply
  python app\\tool\\art\\gen_night_art.py sheet
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
ASSETS = REPO / "app" / "assets" / "images"
RAW_OUT = HERE / "gen" / "night"
SHEET_OUT = HERE / "gen" / "sheets"
STYLE_REF_WEBP = ASSETS / "chars" / "banDal_idle.webp"
CODEX_IMAGES = Path.home() / ".codex" / "generated_images"
CODEX_JS = Path.home() / "AppData" / "Roaming" / "npm" / "node_modules" / "@openai" / "codex" / "bin" / "codex.js"
IMG_EXT = (".png", ".jpg", ".jpeg", ".webp")
SESSION_RE = re.compile(r"session id:\s*([0-9a-fA-F-]{36})", re.IGNORECASE)

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SIZE_MAP = {
    "bg": (1080, 1920),
    "floor": (1024, 1024),
    "scene_wide": (1280, 720),
    "card_wide": (640, 360),
    "card_sq": (512, 512),
    "mutant": (384, 384),
    "launcher": (384, 384),
    "stone": (280, 280),
    "icon": (320, 320),
    "fx": (384, 384),
    "appicon": (1024, 1024),
}

DEST_FOLDER = {
    "bg": "scenes",
    "floor": "scenes",
    "scene_wide": "scenes",
    "card_wide": "scenes",
    "card_sq": "scenes",
    "mutant": "mutants",
    "launcher": "launchers",
    "stone": "stones",
    "icon": "icons",
    "fx": "fx",
}


def load_spec() -> dict:
    return json.loads((HERE / "night_art_spec.json").read_text(encoding="utf-8"))


def ensure_style_ref() -> Path:
    ref = RAW_OUT / "_style_ref.png"
    if not ref.exists():
        RAW_OUT.mkdir(parents=True, exist_ok=True)
        im = Image.open(STYLE_REF_WEBP).convert("RGBA")
        bg = Image.new("RGBA", im.size, (24, 28, 44, 255))
        bg.alpha_composite(im)
        bg.convert("RGB").save(ref)
    return ref


def find_raw(item_id: str) -> Path | None:
    for ext in IMG_EXT:
        p = RAW_OUT / f"{item_id}{ext}"
        if p.exists() and p.stat().st_size > 1024:
            return p
    return None


def codex_base_cmd(model: str) -> list[str]:
    pins = [
        "-c", f'model="{model}"',
        "-c", 'model_reasoning_effort="low"',
        "-c", "mcp_servers={}",
    ]
    node = shutil.which("node")
    if node and CODEX_JS.exists():
        return [node, str(CODEX_JS)] + pins
    exe = shutil.which("codex")
    if not exe:
        raise RuntimeError("codex 실행 파일을 찾을 수 없습니다.")
    return [exe] + pins


def pick_session_image(combined_out: str, stdout_text: str, t0: float) -> Path | None:
    # 1순위: session id 전용 폴더 내부 이미지 (병렬 충돌 0%)
    m = SESSION_RE.search(combined_out)
    if m and CODEX_IMAGES.exists():
        sdir = CODEX_IMAGES / m.group(1)
        if sdir.exists():
            cands = sorted(
                (p for p in sdir.rglob("*") if p.is_file() and p.suffix.lower() in IMG_EXT),
                key=lambda p: p.stat().st_mtime,
            )
            if cands:
                return cands[-1]

    # 2순위: 코덱스가 마지막 줄에 명시한 실제 파일 경로
    for line in reversed(stdout_text.strip().splitlines()):
        cleaned = line.strip().strip("`\"'")
        if not cleaned or len(cleaned) > 260:
            continue
        try:
            p = Path(cleaned)
            if p.suffix.lower() in IMG_EXT and p.exists():
                return p
        except OSError:
            continue

    # 3순위: 단일 실행일 때만 시각 기준 탐색
    if CODEX_IMAGES.exists():
        cands = sorted(
            (p for p in CODEX_IMAGES.rglob("*") if p.is_file() and p.suffix.lower() in IMG_EXT and p.stat().st_mtime >= t0),
            key=lambda p: p.stat().st_mtime,
        )
        if cands:
            return cands[-1]
    return None


def draw_one_codex(item: dict, kind_spec: dict, ref_path: Path, model: str) -> Path | None:
    ratio = kind_spec["ratio"]
    style_text = kind_spec["style"]
    prompt = f"{item['desc']}\n\n{style_text}"
    msg = (
        f"이미지를 정확히 한 장 생성해 줘. 비율 {ratio}. "
        "첨부한 그림은 한국 무협 게임의 손그림 셀 채색 화풍 기준(선 굵기·붓질·색감·명암)이다. "
        "첨부 그림 속 인물은 절대 따라 그리지 말고 아래 대상만 그린다. "
        "파일 쓰기나 셸 명령은 쓰지 말고 오직 내장 이미지 생성 도구만 호출해.\n"
        f"내용: {prompt}\n"
        "생성한 이미지 파일의 절대 경로만 마지막 줄에 출력해."
    )
    args = codex_base_cmd(model) + ["exec", "--skip-git-repo-check", msg, "-i", str(ref_path)]
    t0 = time.time()
    proc = subprocess.run(
        args,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
        stdin=subprocess.DEVNULL,
        timeout=600,
    )
    combined = f"{proc.stdout or ''}\n{proc.stderr or ''}"
    src = pick_session_image(combined, proc.stdout or "", t0)
    if src is None:
        tail = combined[-320:].replace("\n", " ")
        print(f"  ⛔[{item['id']}] 코덱스 이미지 미생성 (rc={proc.returncode}): {tail}", flush=True)
        return None
    RAW_OUT.mkdir(parents=True, exist_ok=True)
    dest = RAW_OUT / f"{item['id']}{src.suffix.lower()}"
    shutil.copy2(src, dest)
    return dest


def key_green(im: Image.Image) -> Image.Image:
    a = np.asarray(im.convert("RGBA")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    lead = g - np.maximum(r, b)
    alpha = np.clip(1.0 - (lead - 36.0) / (115.0 - 36.0), 0.0, 1.0)
    spill = lead > 0
    g2 = np.where(spill, np.maximum(r, b) + (g - np.maximum(r, b)) * 0.12, g)
    out = np.stack([r, g2, b, a[..., 3] * alpha], -1)
    return Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA")


def key_magenta(im: Image.Image) -> Image.Image:
    """초록/청록 피사체(청옥·온옥·야광초·논밭 등)를 보존하기 위한 마젠타(#FF00FF) 크로마키."""
    a = np.asarray(im.convert("RGBA")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    rb_min = np.minimum(r, b)
    lead = rb_min - g
    alpha = np.clip(1.0 - (lead - 36.0) / (115.0 - 36.0), 0.0, 1.0)
    spill = lead > 0
    r2 = np.where(spill, g + (r - g) * 0.25, r)
    b2 = np.where(spill, g + (b - g) * 0.25, b)
    out = np.stack([r2, g, b2, a[..., 3] * alpha], -1)
    return Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA")


def cover_crop(im: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    w, h = target_size
    scale = max(w / im.width, h / im.height)
    resized = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    x = (resized.width - w) // 2
    y = (resized.height - h) // 2
    return resized.crop((x, y, x + w, y + h))


def cutout_square(im: Image.Image, target_size: tuple[int, int], chroma: str) -> Image.Image:
    keyed = key_magenta(im) if chroma == "magenta" else key_green(im)
    mask = keyed.getchannel("A").point(lambda v: 255 if v > 24 else 0)
    bbox = mask.getbbox()
    if bbox:
        keyed = keyed.crop(bbox)
    side = max(16, round(max(keyed.size) / 0.88))
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.alpha_composite(keyed, ((side - keyed.width) // 2, (side - keyed.height) // 2))
    return sq.resize(target_size, Image.LANCZOS)


def apply_one(item: dict) -> Path | None:
    kind = item["kind"]
    if kind.startswith("appicon"):
        return find_raw(item["id"])
    src = find_raw(item["id"])
    if not src:
        return None
    base_kind = "icon" if kind == "icon_magenta" else ("stone" if kind == "stone_magenta" else ("launcher" if kind == "launcher_magenta" else kind))
    chroma = "magenta" if kind.endswith("_magenta") else "green"
    out_dir = ASSETS / DEST_FOLDER[base_kind]
    out_dir.mkdir(parents=True, exist_ok=True)
    dest = out_dir / f"{item['id']}.webp"
    im = Image.open(src)
    target_sz = SIZE_MAP[base_kind]
    if base_kind in ("bg", "floor"):
        cover_crop(im.convert("RGB"), target_sz).save(dest, "WEBP", quality=84, method=6)
    elif base_kind in ("scene_wide", "card_wide", "card_sq"):
        cover_crop(im.convert("RGB"), target_sz).save(dest, "WEBP", quality=90, method=6)
    else:
        cutout_square(im, target_sz, chroma).save(dest, "WEBP", quality=90, method=6)
    return dest


def cmd_draw(args) -> int:
    spec = load_spec()
    only_ids = {x.strip() for x in args.only.split(",") if x.strip()}
    groups = {x.strip() for x in args.group.split(",") if x.strip()}

    items = []
    for it in spec["items"]:
        if only_ids and it["id"] not in only_ids:
            continue
        if groups and it["group"] not in groups:
            continue
        if not args.redo and find_raw(it["id"]):
            continue
        items.append(it)

    if not items:
        print("이미 모든 대상 원화가 준비되어 있습니다.")
        return 0

    ref = ensure_style_ref()
    print(f"■ 코덱스 원화 생성 시작: 총 {len(items)}종 · 병렬 {args.jobs} · 모델 {args.model}", flush=True)

    def worker(it: dict) -> tuple[str, bool, float]:
        t0 = time.time()
        kind_spec = spec["kinds"][it["kind"]]
        got = None
        for attempt in range(1, args.tries + 1):
            try:
                got = draw_one_codex(it, kind_spec, ref, args.model)
            except Exception as exc:
                print(f"  ⚠️[{it['id']}] {attempt}차 오류: {exc}", flush=True)
                got = None
            if got is not None:
                break
        sec = round(time.time() - t0, 1)
        if got is not None:
            applied = apply_one(it)
            print(f"✅ {it['id']} ({sec}초) → {applied.name if applied else got.name}", flush=True)
            return it["id"], True, sec
        print(f"⛔ {it['id']} 실패 ({sec}초)", flush=True)
        return it["id"], False, sec

    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        results = list(pool.map(worker, items))

    failed = [r[0] for r in results if not r[1]]
    print(f"\n■ 완료: {len(results) - len(failed)}/{len(results)} 성공 · 실패: {failed}", flush=True)
    return 1 if failed else 0


def cmd_apply(args) -> int:
    spec = load_spec()
    only_ids = {x.strip() for x in args.only.split(",") if x.strip()}
    missing = []
    hashes: dict[str, str] = {}
    dups: list[tuple[str, str]] = []

    for it in spec["items"]:
        if only_ids and it["id"] not in only_ids:
            continue
        raw = find_raw(it["id"])
        if not raw:
            missing.append(it["id"])
            continue
        digest = hashlib.sha256(raw.read_bytes()).hexdigest()
        if digest in hashes:
            dups.append((hashes[digest], it["id"]))
        else:
            hashes[digest] = it["id"]
        dest = apply_one(it)
        if dest and not it["kind"].startswith("appicon"):
            print(f"적용 완료: {dest.relative_to(REPO)} ({dest.stat().st_size // 1024}KB)")

    if dups:
        print(f"⛔ 중복 해시 발견(재생성 필요): {dups}")
    if missing:
        print(f"⛔ 미생성 항목({len(missing)}종): {missing}")
    return 1 if (missing or dups) else 0


def cmd_sheet(args) -> int:
    spec = load_spec()
    SHEET_OUT.mkdir(parents=True, exist_ok=True)
    groups = {x.strip() for x in args.group.split(",") if x.strip()}
    by_group: dict[str, list[dict]] = {}
    for it in spec["items"]:
        if groups and it["group"] not in groups:
            continue
        by_group.setdefault(it["group"], []).append(it)

    for grp, items in by_group.items():
        if grp == "lobby_game_ui_8":
            cell = (420, 320)
            cols = 4
        elif grp == "bg":
            cell = (216, 384)
            cols = 6
        elif grp == "floor":
            cell = (220, 220)
            cols = 6
        else:
            cell = (180, 180)
            cols = 5
        rows = (len(items) + cols - 1) // cols
        canvas = Image.new("RGB", (cols * cell[0], rows * cell[1]), (22, 26, 40))
        for idx, it in enumerate(items):
            kind = it["kind"]
            if kind.startswith("appicon"):
                f = find_raw(it["id"])
            else:
                base_kind = "icon" if kind == "icon_magenta" else ("stone" if kind == "stone_magenta" else ("launcher" if kind == "launcher_magenta" else kind))
                f = ASSETS / DEST_FOLDER[base_kind] / f"{it['id']}.webp"
            if not f or not f.exists():
                continue
            im = Image.open(f).convert("RGBA")
            im.thumbnail((cell[0] - 12, cell[1] - 12), Image.LANCZOS)
            ox = (idx % cols) * cell[0] + (cell[0] - im.width) // 2
            oy = (idx // cols) * cell[1] + (cell[1] - im.height) // 2
            canvas.paste(im, (ox, oy), im)
        out_file = SHEET_OUT / f"_sheet_{grp}.jpg"
        canvas.save(out_file, quality=90)
        print(f"검수 시트 생성: {out_file}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["draw", "apply", "sheet"])
    ap.add_argument("--group", default="")
    ap.add_argument("--only", default="")
    ap.add_argument("--redo", action="store_true")
    ap.add_argument("--jobs", type=int, default=2)
    ap.add_argument("--tries", type=int, default=2)
    ap.add_argument("--model", default="gpt-6.1-sol")
    args = ap.parse_args()
    RAW_OUT.mkdir(parents=True, exist_ok=True)
    return {"draw": cmd_draw, "apply": cmd_apply, "sheet": cmd_sheet}[args.cmd](args)


if __name__ == "__main__":
    raise SystemExit(main())
