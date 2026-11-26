# 번역 지침 — 《수호알까기 · 탄지무림 심야기습》

모바일 무협 판타지 타워 디펜스 게임의 화면 글이다. 원문은 한국어.

## 반드시 지킬 것
1. 입력은 한국어 문자열 배열(JSON). 출력은 `{ "한국어 원문": "번역" }` JSON 객체 — **원문 키는 한 글자도 바꾸지 말고** 배열의 모든 항목을 넣는다.
2. `{0}` `{1}` … 자리표는 번역문에 **같은 번호를 같은 개수만큼** 그대로 둔다(순서는 그 언어 어순대로 옮겨도 된다).
3. 이모지(⚡ ☯ 🌕 ★ ✦ 🔥 …)·숫자·`%`·`×`·`⚡` 기호·줄바꿈(`\n`)은 그대로 둔다.
4. 번역문에 한국어 글자가 남으면 안 된다.
5. 짧은 단추·이름표는 짧게(원문보다 많이 길어지지 않게). 휴대폰 화면에 들어가야 한다.
6. 개발용 로그 문장(예: 「저장 불러오기 예외 복구: {0}」)도 그냥 번역한다.

## 말투
- 무협 판타지 분위기, 그러나 읽기 쉽게. 존댓말 문장은 그 언어의 정중한 게임 안내 말투로.
- 지나친 감탄사 반복(!!)은 하나로 줄여도 된다.

## 용어 — 같은 말은 같은 낱말로 (영어 기준 · 다른 언어는 이 뜻으로 일관되게)
| 한국어 | 영어 |
|---|---|
| 수호알까기 · 탄지무림 심야기습 | Guardian Flick: Murim Night Raid |
| 탄지 | Flick |
| 현(제1현~제10현) | County (County 1~10) |
| 마을 · 판 | Village · Stage |
| 물결 | Wave |
| 초소 | Outpost |
| 발사대 | Launcher |
| 수호탑(중앙 기명 수호탑) | Guardian Tower |
| 방어막 · 결계 | Shield · Barrier |
| 수호석 | Guardian Stone |
| 영수 | Spirit Beast |
| 동료 | Companion |
| 증표(수호 증표) | Token |
| 영약(천기 영약) | Elixir |
| 지원패 | Support Seal |
| 무림수호단 출두 | Murim Guard Charge |
| 기력(군수 기력 ⚡) | Qi |
| 내공 | Inner Power |
| 경맥 · 혈자리 | Meridian · Acupoint |
| 경지 | Realm |
| 기연 | Fortune |
| 기연 소환 | Fortune Summon |
| 태극 기연판 | Taiji Fortune Wheel |
| 비급 | Secret Art |
| 비약 | Potion |
| 보름달 길조 | Full Moon Omen |
| 돌연변이 · 변이체 | Mutant |
| 두목 · 행동대장 · 대수괴 | Chieftain · Vanguard Captain · Archfiend |
| 윤회 심판전 | Samsara Trial |
| 환생 | Rebirth |
| 쉬움 · 보통 · 악몽 | Easy · Normal · Nightmare |
| 물자 호송 · 심야 탐색 | Supply Convoy · Night Scouting |
| 대장간 | Forge |
| 도감 | Codex |
| 본영 | Headquarters |
| 무한 혈전 | Endless Battle |

- 사람·동물·괴물·장소 고유 이름은 라틴 문자 언어에서는 로마자로 옮기고(예: 석두 → Seokdu), 한자 문화권(일본어·중국어)에서는 그 뜻이 살아나는 표기로 한 번 정하면 끝까지 같게 쓴다.
