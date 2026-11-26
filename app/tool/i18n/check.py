"""번역 결과 점검: 빠진 원문·자리표 어긋남·한국어 남음.

  python app/tool/i18n/check.py <언어코드> [조각 파일들…]   # 조각을 합쳐 assets/i18n/<언어>.json 으로
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parents[1] / "assets" / "i18n"
HOLE = re.compile(r"\{(\d+)\}")
HANGUL = re.compile("[가-힣]")


def problems(src: list[str], table: dict) -> list[str]:
    bad = []
    for ko in src:
        out = table.get(ko)
        if not isinstance(out, str) or not out.strip():
            bad.append(f"빠짐: {ko[:40]!r}")
            continue
        if sorted(HOLE.findall(ko)) != sorted(HOLE.findall(out)):
            bad.append(f"자리표: {ko[:40]!r} → {out[:40]!r}")
        if HANGUL.search(out):
            bad.append(f"한국어 남음: {out[:40]!r}")
    return bad


def main() -> int:
    code, parts = sys.argv[1], sys.argv[2:]
    src = json.loads((HERE / "source_ko.json").read_text(encoding="utf-8"))
    table: dict = {}
    for p in parts:
        table.update(json.loads(Path(p).read_text(encoding="utf-8")))
    bad = problems(src, table)
    for b in bad[:30]:
        print(" ", b)
    over = json.loads((HERE / "overrides.json").read_text(encoding="utf-8")).get(code, {})
    table.update({k: v for k, v in over.items() if k in src})
    keep = {ko: table[ko] for ko in src if isinstance(table.get(ko), str)
            and sorted(HOLE.findall(ko)) == sorted(HOLE.findall(table[ko])) and not HANGUL.search(table[ko])}
    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / f"{code}.json").write_text(json.dumps(keep, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"{code}: {len(keep)}/{len(src)} 통과 · 문제 {len(bad)}")
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
