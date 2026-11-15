# 《수호알까기 · 탄지무림 심야기습》

`알까기 · 탄지무림`의 세계관과 10장 여정을 계승한 **무협 자동 물리 수호(디펜스) 게임**입니다.

## 핵심 특징
- **수동 튕기기 폐지 · 100% 조건부 자동 발사**: 중앙 자동 알 발사 보호 장치(기명 수호탑), 외곽 기공 방어막, 산·들 길목 자동 알 발사대 5계통(1~4형), 수호 알 1~13단(모양 3종), 영수 5종, 동료 14인이 설정 조건에 따라 100% 자동으로 싸웁니다.
- **초간단 기명 심법 수련 (알까기 없음 · 실패 0%)**: 단전 구슬을 가볍게 터치(또는 자동 운기 스위치 가동)하고, 빛나는 혈자리 구슬 3~5개를 톡톡 점등하는 것만으로 내공과 십대 경맥(1~10단계)이 막힘없이 개통됩니다.
- **명쾌한 재화 분리**:
  - **변이 토벌 증표**: 돌연변이 처치 시 드롭 → 중앙 보호 장치 · 길목 자동 발사대 강화 및 업그레이드 전용
  - **신비 영약**: 기연 · 물자 호송 · 심야 탐색 · 보스 정화 보상 → 영수 · 동료 강화 및 내공 8경지 승급 전용
- **설렘 기연 & 무림수호단 출두 지원패**:
  - 보름달 길조 게이지 + 전 구간 **크리티컬 기연 & 한 번 더! 기연**
  - 조건 달성 · 기연 · 탐색 3대 경로로 얻는 **지원패** 발동 시 태평소 풍악과 함께 아군 전체가 돌격해 온 길목 돌연변이를 싹 몰아 전멸!
- **전 10장(111단계) 구성 조정 클리어 검증 완료**: `packages/defense_core/bin/defense_verify_sim.dart` 모의실험으로 손 조작 0회 · 지원패 0회 · 행운 기연 0% 순수 구성만으로도 전 단계 클리어 가능함을 검증했습니다.

## 실행 및 검증 명령어
```powershell
# 1. 방어 물리 코어 정적 분석 · 단위 시험 · 111단계 전수 검증
cd D:\ttong_alkkagi_night\packages\defense_core
D:\flutter_3476\bin\dart.bat analyze --fatal-infos
D:\flutter_3476\bin\dart.bat test
D:\flutter_3476\bin\dart.bat run bin/defense_verify_sim.dart

# 2. 플러터 앱 정적 분석 · 위젯 통합 시험 · 빌드
cd D:\ttong_alkkagi_night\app
D:\flutter_3476\bin\flutter.bat analyze --fatal-infos
D:\flutter_3476\bin\flutter.bat test
D:\flutter_3476\bin\flutter.bat build web --release
D:\flutter_3476\bin\flutter.bat build apk --release --flavor sideload
```
