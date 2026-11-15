import 'dart:math';

import 'campaign.dart';
import 'launchers.dart';
import 'materials.dart';
import 'mutants.dart';

/// 수호 제련·제조 재료 4종 (임무·출석·무한 혈전 보상으로 획득하여 전술 비약 제조에 사용).
enum CraftMaterial {
  hyeoncheolOre('현철편', '무거운 수호석 파편 · 방어막 보강 재료', 0xFF9AA5B4),
  moonHerb('야광초', '달빛을 머금은 영초 · 기공 회복 재료', 0xFF5EEAD4),
  frostJade('한빙옥', '차가운 기운의 옥석 · 결정 파쇄 재료', 0xFF7DD3FC),
  thunderPowder('천뢰화약', '벼락 기운을 응축한 가루 · 극광 회심 재료', 0xFFFBBF24);

  const CraftMaterial(this.label, this.summary, this.colorHex);
  final String label;
  final String summary;
  final int colorHex;
}

/// 전장 위기 순간 원터치로 발동하는 일회용 전술 비약·부적 3종.
enum TacticalConsumable {
  qiSurgePill(
    '기공 급속단',
    '내공 3.0칸 즉시 완충 + 문파 무공 즉시 준비',
    0xFF34D399,
    {CraftMaterial.moonHerb: 2, CraftMaterial.frostJade: 1},
  ),
  guardianRepairSeal(
    '수호탑 수리패',
    '외곽 방어막 +45% · 중앙 수호탑 +35% 복구 및 마을 생태계 정화',
    0xFF60A5FA,
    {CraftMaterial.hyeoncheolOre: 2, CraftMaterial.moonHerb: 1},
  ),
  auroraCritCharm(
    '극광 회심부',
    '8초간 모든 자동 발사대 연사력 1.5배 & 전탄 확정 회심(크리티컬)',
    0xFFF59E0B,
    {CraftMaterial.thunderPowder: 2, CraftMaterial.frostJade: 1},
  );

  const TacticalConsumable(
    this.label,
    this.effectSummary,
    this.colorHex,
    this.recipe,
  );

  final String label;
  final String effectSummary;
  final int colorHex;
  final Map<CraftMaterial, int> recipe;
}

/// 출석·임무·업적 공통 보상 꾸러미.
class NightRewardBundle {
  const NightRewardBundle({
    this.tokens = 0,
    this.elixirs = 0,
    this.trainingSeals = 0,
    this.supportTokens = 0,
    this.shards = 0,
    this.materials = const {},
    this.consumables = const {},
  });

  final int tokens;
  final int elixirs;
  final int trainingSeals;
  final int supportTokens;
  final int shards;
  final Map<CraftMaterial, int> materials;
  final Map<TacticalConsumable, int> consumables;

  String toSummaryText() {
    final parts = <String>[];
    if (tokens > 0) parts.add('증표 +$tokens');
    if (elixirs > 0) parts.add('영약 +$elixirs');
    if (trainingSeals > 0) parts.add('인장 +$trainingSeals');
    if (supportTokens > 0) parts.add('지원패 +$supportTokens');
    if (shards > 0) parts.add('신물조각 +$shards');
    for (final e in materials.entries) {
      parts.add('${e.key.label} +${e.value}');
    }
    for (final e in consumables.entries) {
      parts.add('${e.key.label} +${e.value}');
    }
    return parts.join(' · ');
  }
}

/// 7일 순환 출석 보상표 (빠진 날이 있어도 초기화되지 않고 다음 칸으로 이어짐).
class NightAttendance {
  static const List<NightRewardBundle> sevenDayRewards = [
    NightRewardBundle(
      tokens: 80,
      trainingSeals: 12,
      materials: {CraftMaterial.moonHerb: 2},
    ),
    NightRewardBundle(
      tokens: 100,
      elixirs: 2,
      materials: {CraftMaterial.hyeoncheolOre: 2},
    ),
    NightRewardBundle(
      tokens: 130,
      trainingSeals: 18,
      consumables: {TacticalConsumable.qiSurgePill: 1},
    ),
    NightRewardBundle(
      tokens: 150,
      elixirs: 3,
      materials: {CraftMaterial.frostJade: 2},
    ),
    NightRewardBundle(
      tokens: 180,
      supportTokens: 1,
      consumables: {TacticalConsumable.guardianRepairSeal: 1},
    ),
    NightRewardBundle(
      tokens: 220,
      elixirs: 4,
      shards: 2,
      materials: {CraftMaterial.thunderPowder: 2},
    ),
    NightRewardBundle(
      tokens: 320,
      elixirs: 6,
      supportTokens: 2,
      shards: 4,
      consumables: {TacticalConsumable.auroraCritCharm: 1},
    ),
  ];

  /// 기기 시계가 미래로 잘못 갔다가 돌아온 경우 방어(최대 오늘 기준 보정).
  static String saneDayKey(String savedDay, String todayKey) {
    if (savedDay.isEmpty) return '';
    if (savedDay.compareTo(todayKey) > 0) return todayKey;
    return savedDay;
  }
}

/// 일일·주간·월간 임무 행동 지표.
enum NightDeed {
  battleWin('야간 수호 승리'),
  mutantKills('심야 돌연변이 토벌'),
  cliffPporok('절벽 뽀록 추락 유도'),
  meditate('기명 심법 단전 운기'),
  serendipityHit('설렘 기연 발동'),
  perfectDefense('무피해(★3) 마을 수호');

  const NightDeed(this.label);
  final String label;
}

enum QuestPeriodKind {
  daily('일일 임무'),
  weekly('주간 임무'),
  monthly('월간 임무');

  const QuestPeriodKind(this.label);
  final String label;
}

class NightMissionSpec {
  const NightMissionSpec({
    required this.id,
    required this.period,
    required this.deed,
    required this.goal,
    required this.title,
    required this.reward,
  });

  final String id;
  final QuestPeriodKind period;
  final NightDeed deed;
  final int goal;
  final String title;
  final NightRewardBundle reward;
}

/// 임무 생성 및 주간/월간 기간 키 계산기.
class NightQuestCatalog {
  static const List<NightMissionSpec> _dailyPool = [
    NightMissionSpec(
      id: 'd_win_1',
      period: QuestPeriodKind.daily,
      deed: NightDeed.battleWin,
      goal: 1,
      title: '심야 기습으로부터 마을 1회 수호',
      reward: NightRewardBundle(
        tokens: 65,
        trainingSeals: 10,
        materials: {CraftMaterial.moonHerb: 1},
      ),
    ),
    NightMissionSpec(
      id: 'd_kills_25',
      period: QuestPeriodKind.daily,
      deed: NightDeed.mutantKills,
      goal: 25,
      title: '심야 돌연변이 25마리 자동 격퇴',
      reward: NightRewardBundle(
        tokens: 75,
        materials: {CraftMaterial.hyeoncheolOre: 2},
      ),
    ),
    NightMissionSpec(
      id: 'd_meditate_3',
      period: QuestPeriodKind.daily,
      deed: NightDeed.meditate,
      goal: 3,
      title: '기명 심법 단전 운기 3회 수행',
      reward: NightRewardBundle(
        trainingSeals: 14,
        elixirs: 1,
        materials: {CraftMaterial.frostJade: 1},
      ),
    ),
    NightMissionSpec(
      id: 'd_pporok_3',
      period: QuestPeriodKind.daily,
      deed: NightDeed.cliffPporok,
      goal: 3,
      title: '절벽 기우뚱 뽀록 추락 3회 달성',
      reward: NightRewardBundle(
        tokens: 80,
        materials: {CraftMaterial.thunderPowder: 1},
      ),
    ),
    NightMissionSpec(
      id: 'd_seren_2',
      period: QuestPeriodKind.daily,
      deed: NightDeed.serendipityHit,
      goal: 2,
      title: '전장 또는 수련에서 기연 2회 맞이하기',
      reward: NightRewardBundle(
        elixirs: 2,
        materials: {CraftMaterial.moonHerb: 1, CraftMaterial.frostJade: 1},
      ),
    ),
    NightMissionSpec(
      id: 'd_star3_1',
      period: QuestPeriodKind.daily,
      deed: NightDeed.perfectDefense,
      goal: 1,
      title: '마을 생태계 무피해(★3) 수호 1회 달성',
      reward: NightRewardBundle(
        tokens: 90,
        elixirs: 2,
        materials: {CraftMaterial.thunderPowder: 1},
      ),
    ),
  ];

  static const NightRewardBundle dailyAllClearBonus = NightRewardBundle(
    tokens: 120,
    elixirs: 2,
    supportTokens: 1,
    shards: 1,
  );

  static const List<NightMissionSpec> weeklyMissions = [
    NightMissionSpec(
      id: 'w_win_8',
      period: QuestPeriodKind.weekly,
      deed: NightDeed.battleWin,
      goal: 8,
      title: '이번 주 야간 수호 8회 승리',
      reward: NightRewardBundle(
        tokens: 260,
        elixirs: 4,
        shards: 2,
        consumables: {TacticalConsumable.guardianRepairSeal: 1},
      ),
    ),
    NightMissionSpec(
      id: 'w_kills_180',
      period: QuestPeriodKind.weekly,
      deed: NightDeed.mutantKills,
      goal: 180,
      title: '이번 주 돌연변이 180마리 토벌',
      reward: NightRewardBundle(
        tokens: 300,
        supportTokens: 1,
        materials: {
          CraftMaterial.hyeoncheolOre: 3,
          CraftMaterial.thunderPowder: 2,
        },
      ),
    ),
    NightMissionSpec(
      id: 'w_meditate_15',
      period: QuestPeriodKind.weekly,
      deed: NightDeed.meditate,
      goal: 15,
      title: '이번 주 단전 운기 호흡 15회 수행',
      reward: NightRewardBundle(
        trainingSeals: 45,
        elixirs: 4,
        consumables: {TacticalConsumable.qiSurgePill: 2},
      ),
    ),
  ];

  static const List<NightMissionSpec> monthlyMissions = [
    NightMissionSpec(
      id: 'm_win_25',
      period: QuestPeriodKind.monthly,
      deed: NightDeed.battleWin,
      goal: 25,
      title: '이번 달 야간 수호 25회 승리',
      reward: NightRewardBundle(
        tokens: 700,
        elixirs: 10,
        supportTokens: 2,
        shards: 5,
      ),
    ),
    NightMissionSpec(
      id: 'm_pporok_40',
      period: QuestPeriodKind.monthly,
      deed: NightDeed.cliffPporok,
      goal: 40,
      title: '이번 달 절벽 뽀록 추락 40회 달성',
      reward: NightRewardBundle(
        tokens: 550,
        elixirs: 8,
        shards: 4,
        consumables: {TacticalConsumable.auroraCritCharm: 2},
      ),
    ),
  ];

  /// 날짜 문자열(`YYYY-MM-DD`)을 씨앗으로 오늘의 일일 임무 3종 추출.
  static List<NightMissionSpec> dailyOf(String dayKey) {
    final seed = dayKey.codeUnits.fold<int>(17, (acc, c) => acc * 31 + c);
    final shuffled = List<NightMissionSpec>.from(_dailyPool)..shuffle(Random(seed));
    final picked = <NightMissionSpec>[];
    for (final m in shuffled) {
      if (picked.any((x) => x.deed == m.deed)) continue;
      picked.add(m);
      if (picked.length == 3) break;
    }
    return picked;
  }

  static String weekKeyOf(String dayKey) {
    final dt = DateTime.tryParse(dayKey) ?? DateTime(2026, 1, 1);
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    return 'W${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  static String monthKeyOf(String dayKey) {
    if (dayKey.length >= 7) return 'M${dayKey.substring(0, 7)}';
    return 'M2026-01';
  }
}

/// 영구 업적(칭호) 12종.
class NightAchievementSpec {
  const NightAchievementSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reward,
  });

  final String id;
  final String title;
  final String subtitle;
  final NightRewardBundle reward;

  static const List<NightAchievementSpec> all = [
    NightAchievementSpec(
      id: 'ach_first_dawn',
      title: '첫 새벽의 수호자',
      subtitle: '제1장 첫 야간 기습 방어 승리',
      reward: NightRewardBundle(tokens: 80, elixirs: 2),
    ),
    NightAchievementSpec(
      id: 'ach_ch1_clear',
      title: '청석촌 구원자',
      subtitle: '제1장 모든 밤(11단계) 완전 평정',
      reward: NightRewardBundle(tokens: 150, elixirs: 3, supportTokens: 1),
    ),
    NightAchievementSpec(
      id: 'ach_ch3_clear',
      title: '유리 나루터 파수꾼',
      subtitle: '제3장 유화당 심야 수호 완료',
      reward: NightRewardBundle(tokens: 240, elixirs: 4, shards: 2),
    ),
    NightAchievementSpec(
      id: 'ach_ch6_clear',
      title: '용문 객잔의 영웅',
      subtitle: '제6장 혈무교주 격퇴 및 묵현 합류',
      reward: NightRewardBundle(tokens: 380, elixirs: 6, supportTokens: 2),
    ),
    NightAchievementSpec(
      id: 'ach_ch10_clear',
      title: '탄지무림 태초 수호신',
      subtitle: '제10장 심야에 물든 태초 탄신 정화 완수',
      reward: NightRewardBundle(tokens: 800, elixirs: 15, supportTokens: 3, shards: 6),
    ),
    NightAchievementSpec(
      id: 'ach_meridian_5',
      title: '기맥 관통자',
      subtitle: '십대 경맥 5단계(대맥) 개통 달성',
      reward: NightRewardBundle(trainingSeals: 30, elixirs: 3),
    ),
    NightAchievementSpec(
      id: 'ach_meridian_10',
      title: '생사현관 대종사',
      subtitle: '십대 경맥 10단계 전체 개통 완성',
      reward: NightRewardBundle(tokens: 450, elixirs: 10, supportTokens: 2),
    ),
    NightAchievementSpec(
      id: 'ach_pporok_20',
      title: '절벽 뽀록의 달인',
      subtitle: '누적 절벽 뽀록 추락 20회 달성',
      reward: NightRewardBundle(tokens: 180, shards: 2),
    ),
    NightAchievementSpec(
      id: 'ach_bank_15',
      title: '어부지리 도탄 명수',
      subtitle: '회전 다각형 기둥 반사 타격 누적 15회 달성',
      reward: NightRewardBundle(tokens: 180, elixirs: 3),
    ),
    NightAchievementSpec(
      id: 'ach_chain_15',
      title: '삼각 파쇄 진법가',
      subtitle: '3연쇄 삼각 파쇄 폭발 누적 15회 달성',
      reward: NightRewardBundle(tokens: 200, elixirs: 4),
    ),
    NightAchievementSpec(
      id: 'ach_convoy_5',
      title: '강호 병참 총관',
      subtitle: '구출 마을 물자 호송 5회 완수',
      reward: NightRewardBundle(tokens: 220, supportTokens: 2),
    ),
    NightAchievementSpec(
      id: 'ach_endless_10',
      title: '끝없는 밤의 파수대',
      subtitle: '심야 무한 혈전 10물결 이상 돌파',
      reward: NightRewardBundle(tokens: 350, elixirs: 6, shards: 3),
    ),
  ];
}

/// 심야 무한 혈전(생존 투기장) 동적 물결 생성기 (`EndlessCatalog` 별칭 호환).
typedef EndlessCatalog = EndlessWaveBuilder;

class EndlessWaveBuilder {
  static StageSpec buildEndlessStage({
    required int waveCount,
    required int chapterTheme,
  }) {
    final safeTheme = chapterTheme.clamp(1, 10);
    final totalWaves = waveCount.clamp(5, 30);
    final waves = <List<WaveSpawnGroup>>[];

    for (int w = 1; w <= totalWaves; w++) {
      final groups = <WaveSpawnGroup>[
        WaveSpawnGroup(
          kind: w % 2 == 0 ? MutantKind.sickHound : MutantKind.swarmRat,
          count: 4 + w * 2,
          intervalSec: (0.78 - w * 0.015).clamp(0.32, 0.78),
          laneIndex: w % 3,
        ),
        WaveSpawnGroup(
          kind: w % 2 == 0 ? MutantKind.plagueToad : MutantKind.shieldYacha,
          count: 2 + (w ~/ 2),
          intervalSec: 1.05,
          laneIndex: (w + 1) % 3,
        ),
      ];
      if (w >= 3) {
        groups.add(
          WaveSpawnGroup(
            kind: w % 3 == 0 ? MutantKind.bloodCocoon : MutantKind.ironBoar,
            count: 1 + (w ~/ 3),
            intervalSec: 1.35,
            laneIndex: (w + 2) % 3,
          ),
        );
      }
      // 3파도마다 스피드·맷집·공격력 특화 중간보스가 일반 변이체 무리와 함께 교대 동반 침략!
      if (w % 3 == 0) {
        final midCycle = ((w ~/ 3) - 1) % 3;
        final MutantKind midBoss;
        final String midTitle;
        if (midCycle == 0) {
          midBoss = MutantKind.swiftShadowBoss;
          midTitle = '무한 제$w물결 기습장 혈영 질풍귀';
        } else if (midCycle == 1) {
          midBoss = MutantKind.ironColossusBoss;
          midTitle = '무한 제$w물결 철벽수 현철 중갑거수';
        } else {
          midBoss = MutantKind.crimsonBreakerBoss;
          midTitle = '무한 제$w물결 파성귀 적염 파성귀';
        }
        groups.add(
          WaveSpawnGroup(
            kind: midBoss,
            count: 1,
            intervalSec: 1.55,
            laneIndex: (w ~/ 3) % 3,
            customBossTitle: midTitle,
          ),
        );
      }
      if (w >= 5 && w % 5 == 0) {
        groups.add(
          WaveSpawnGroup(
            kind: w >= 15 ? MutantKind.chapterOverlord : MutantKind.raiderHeukpung,
            count: 1,
            intervalSec: 1.8,
            laneIndex: 1,
            customBossTitle: '무한 혈전 제$w물결 심야 마수',
            customPortrait: CampaignCatalog.chapterOf(safeTheme).bossPortraitPrefix,
          ),
        );
      }
      waves.add(groups);
    }

    return StageSpec(
      globalIndex: 999,
      chapterNumber: safeTheme,
      stageNumber: totalWaves,
      title: '심야 무한 혈전 · $totalWaves물결 도전',
      subtitle: '3물결마다 스피드·맷집·공격력 중간보스가 동반 침략하는 한계 시험장!',
      tacticalHint: '중포·한빙·곡사 거점을 고루 섞고 위기 순간 전술 비약과 지원패를 활용하세요.',
      recommendedStone: StoneMaterial.bingbaek,
      recommendedLaunchers: const [
        LauncherType.heavy,
        LauncherType.frostField,
        LauncherType.curveSpin,
      ],
      isBossStage: true,
      waves: waves,
      startingFieldTokens: 90 + totalWaves * 5,
      clearElixirBonus: 3 + (totalWaves ~/ 5),
    );
  }
}

/// 게임 내 확률 100% 투명 공개 항목 (유료 확률형 상자 없음 · 순수 인게임 물리·기연 수치).
class OddsDisclosureRow {
  const OddsDisclosureRow({
    required this.category,
    required this.name,
    required this.rateText,
    required this.detail,
  });

  final String category;
  final String name;
  final String rateText;
  final String detail;

  static const List<OddsDisclosureRow> all = [
    OddsDisclosureRow(
      category: '지형 · 물리 뽀록',
      name: '절벽 가장자리 기우뚱 추락 (뽀록)',
      rateText: '35.0%',
      detail: '밀침 충격을 받아 절벽 경계에 걸친 일반·중형 변이체가 즉시 추락 처치될 확률',
    ),
    OddsDisclosureRow(
      category: '지형 · 물리 뽀록',
      name: '회전 다각형 기둥 어부지리 도탄',
      rateText: '물리 각도 100% 실측',
      detail: '기둥 회전 위상과 충돌 법선에 따라 반사 속도 ×1.18 증폭 및 측면 방패 우회',
    ),
    OddsDisclosureRow(
      category: '전장 기연',
      name: '거대 황금 수호석 (크리티컬 기연)',
      rateText: '기본 8.0% ~ 최대 14.0%',
      detail: '중앙 수호탑 발사 시 피해량 2.4배 · 충격량 1.8배 거대 황금탄 발동 (독맥 개통 시 +6%p)',
    ),
    OddsDisclosureRow(
      category: '전장 기연',
      name: '일거양득 2연사 (한 번 더! 기연)',
      rateText: '기본 11.0% ~ 최대 17.0%',
      detail: '길목 발사대 격발 시 대기 시간 없이 추가 수호 알 1발 즉시 연사 (독맥 개통 시 +6%p)',
    ),
    OddsDisclosureRow(
      category: '전장 기연',
      name: '황금 보급 두꺼비 출현',
      rateText: '전투 중반 100% (판당 1회)',
      detail: '전투 개시 14초 경과 시 전장 가로질러 등장 · 도탄 적중 시 현장 증표 +45 및 영약 +1 확정',
    ),
    OddsDisclosureRow(
      category: '출두 · 수련 기연',
      name: '무림수호단 출두 대박 / 앙코르 재출두',
      rateText: '대박 25~31% · 한 번 더 18~24%',
      detail: '지원패 발동 시 마을 생태계 100% 정화 또는 다음 물결 공짜 재출두 발동',
    ),
    OddsDisclosureRow(
      category: '출두 · 수련 기연',
      name: '단전 운기 대성공 (크리티컬 · 한 번 더)',
      rateText: '황금 고리 조준 시 회심 100%',
      detail: '일반 터치 시 회심 8~11% · 한 번 더 20~26% 추가 내공 및 수련 인장 획득',
    ),
    OddsDisclosureRow(
      category: '호송 · 탐색 · 길조',
      name: '물자 호송 / 심야 탐색 대풍년 기연',
      rateText: '대풍년 26~34% · 한 번 더 22~28%',
      detail: '보상 2배 또는 지원패 +1 추가 수령 · 보름달 길조 게이지 100% 도달 시 특급 기연 100% 확정',
    ),
  ];
}
