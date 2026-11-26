"""앱·게임 규칙 코드의 한국어 문자열을 번역 틀로 뽑는다.

  python app/tool/i18n/extract.py      # → app/tool/i18n/source_ko.json

- 이어 붙은 문자열('a' 'b')은 하나로 합친다.
- ${식}·$이름 은 {0}·{1} … 자리로 바꾼다(번역문에서도 같은 자리를 쓴다).
- 주석·시험 파일은 뺀다.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
SOURCES = [REPO / "app" / "lib", REPO / "packages" / "defense_core" / "lib"]
OUT = Path(__file__).resolve().parent / "source_ko.json"
HANGUL = re.compile("[가-힣]")


def strip_comments(src: str) -> str:
    """// 주석만 지운다(문자열 안의 // 는 남긴다)."""
    out, i, n = [], 0, len(src)
    quote = None
    while i < n:
        c = src[i]
        if quote:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if src.startswith(quote, i):
                out.append(src[i + 1:i + len(quote)])
                i += len(quote)
                quote = None
                continue
            i += 1
            continue
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        for q in ("'''", '"""', "'", '"'):
            if src.startswith(q, i):
                quote = q
                out.append(q)
                i += len(q)
                break
        else:
            out.append(c)
            i += 1
    return "".join(out)


LIT = re.compile(r"(r?)('(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\")")


def literal_runs(code: str):
    """이어 붙은 문자열 덩어리를 하나씩 낸다."""
    pos = 0
    while True:
        m = LIT.search(code, pos)
        if not m:
            return
        parts = [m]
        end = m.end()
        while True:
            gap = re.match(r"\s*", code[end:])
            nm = LIT.match(code, end + gap.end())
            if not nm:
                break
            parts.append(nm)
            end = nm.end()
        yield parts
        pos = end


def to_template(parts) -> str | None:
    text = ""
    for m in parts:
        raw = m.group(2)[1:-1]
        if m.group(1):
            text += raw
            continue
        text += raw
    if not HANGUL.search(text):
        return None
    # ${...} 를 짝 괄호까지 찾아 자리로
    out, i, k = [], 0, 0
    while i < len(text):
        if text.startswith("\\$", i):
            out.append("$")
            i += 2
            continue
        if text.startswith("${", i):
            depth, j = 1, i + 2
            while j < len(text) and depth:
                depth += {"{": 1, "}": -1}.get(text[j], 0)
                j += 1
            out.append("{%d}" % k)
            k += 1
            i = j
            continue
        m = re.match(r"\$[A-Za-z_][A-Za-z0-9_]*", text[i:])
        if m:
            out.append("{%d}" % k)
            k += 1
            i += m.end()
            continue
        out.append(text[i])
        i += 1
    t = "".join(out)
    t = t.replace("\\n", "\n").replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")
    return t


def main() -> int:
    found: dict[str, list[str]] = {}
    for root in SOURCES:
        for f in sorted(root.rglob("*.dart")):
            code = strip_comments(f.read_text(encoding="utf-8"))
            for parts in literal_runs(code):
                t = to_template(parts)
                if t is None:
                    continue
                found.setdefault(t, []).append(f.relative_to(REPO).as_posix())
    items = sorted(found)
    OUT.write_text(json.dumps(items, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    chars = sum(len(t) for t in items)
    holes = sum(1 for t in items if "{0}" in t)
    print(f"틀 {len(items)}개 · {chars}글자 · 자리 있는 것 {holes}개 → {OUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
