import 'dart:math' as math;

import 'allies.dart';
import 'launchers.dart';
import 'materials.dart';
import 'mutants.dart';

/// 2차원 좌표.
class Vec2 {
  const Vec2(this.x, this.y);
  final double x;
  final double y;

  Vec2 operator +(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 operator -(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);

  double get length {
    if (!x.isFinite || !y.isFinite) return 0;
    final l2 = x * x + y * y;
    if (l2 <= 0 || !l2.isFinite) return 0;
    return math.sqrt(l2);
  }

  Vec2 get normalized {
    final l = length;
    if (l < 1e-6 || !l.isFinite) return const Vec2(0, -1);
    return Vec2(x / l, y / l);
  }

  double distanceTo(Vec2 o) => (this - o).length;
}

/// 줄거리 대사 한 줄.
class StoryLine {
  const StoryLine({
    required this.speaker,
    required this.portraitPrefix,
    required this.text,
  });

  final String speaker;
  final String portraitPrefix;
  final String text;
}

/// 회전 다각형 기둥 또는 반사 담장 지물.
class TerrainPillar {
  const TerrainPillar({
    required this.center,
    required this.radius,
    required this.sides,
    required this.rotationSpeedRad,
    required this.restitutionBoost,
  });

  final Vec2 center;
  final double radius;
  final int sides;
  final double rotationSpeedRad;
  final double restitutionBoost;
}

/// 낭떠러지 추락 구역(절벽 걸침 35% 뽀록 판정 포함).
class CliffZone {
  const CliffZone({
    required this.center,
    required this.radius,
    required this.label,
  });

  final Vec2 center;
  final double radius;
  final String label;
}

/// 초소 거점의 5대 전략 지형 특성 (단조로운 빈 발판 대신 지형마다 고유 전술 보너스 부여!).
enum MountTerrainType {
  highWatchtower(
    id: 'watchtower',
    name: '고지 망루',
    shortBadge: '🏔️고지망루',
    bonusSummary: '사거리 +24% · 보스 약점 저격 보정',
    colorHex: 0xFFFFD166,
    rangeMult: 1.24,
    damageMult: 1.05,
    reloadMult: 1.00,
    knockbackMult: 1.00,
    pierceBonus: 0,
    critBonus: 0.05,
    cracksBossWeakPoint: true,
  ),
  chokeGate(
    id: 'chokeGate',
    name: '협곡 관문',
    shortBadge: '⛩️협곡관문',
    bonusSummary: '밀침 +35% · 관통 +1 · 폭발 반경 +20%',
    colorHex: 0xFF72EFDD,
    rangeMult: 1.00,
    damageMult: 1.06,
    reloadMult: 1.00,
    knockbackMult: 1.35,
    pierceBonus: 1,
    critBonus: 0.0,
    cracksBossWeakPoint: false,
  ),
  fortressBastion(
    id: 'bastion',
    name: '성루 포대',
    shortBadge: '🏯성루포대',
    bonusSummary: '화력 +22% · 회심 확률 +10%',
    colorHex: 0xFFFF6B35,
    rangeMult: 1.05,
    damageMult: 1.22,
    reloadMult: 1.00,
    knockbackMult: 1.12,
    pierceBonus: 0,
    critBonus: 0.10,
    cracksBossWeakPoint: false,
  ),
  spiritSpring(
    id: 'spiritSpring',
    name: '기맥 영천',
    shortBadge: '☯️기맥영천',
    bonusSummary: '연사 +24% · 내공 충전 1.8배 · 오라 확장',
    colorHex: 0xFFC77DFF,
    rangeMult: 1.08,
    damageMult: 1.00,
    reloadMult: 1.24,
    knockbackMult: 1.00,
    pierceBonus: 0,
    critBonus: 0.04,
    cracksBossWeakPoint: false,
  ),
  ambushRidge(
    id: 'ambushRidge',
    name: '측면 매복암',
    shortBadge: '🗡️측면매복',
    bonusSummary: '보스 장갑판 파쇄 · 관통 +1 · 화력 +14%',
    colorHex: 0xFF80ED99,
    rangeMult: 1.08,
    damageMult: 1.14,
    reloadMult: 1.08,
    knockbackMult: 1.05,
    pierceBonus: 1,
    critBonus: 0.08,
    cracksBossWeakPoint: true,
  );

  const MountTerrainType({
    required this.id,
    required this.name,
    required this.shortBadge,
    required this.bonusSummary,
    required this.colorHex,
    required this.rangeMult,
    required this.damageMult,
    required this.reloadMult,
    required this.knockbackMult,
    required this.pierceBonus,
    required this.critBonus,
    required this.cracksBossWeakPoint,
  });

  final String id;
  final String name;
  final String shortBadge;
  final String bonusSummary;
  final int colorHex;
  final double rangeMult;
  final double damageMult;
  final double reloadMult;
  final double knockbackMult;
  final int pierceBonus;
  final double critBonus;
  final bool cracksBossWeakPoint;
}

/// 발사대 설치 거점 좌표 · 지형 특성 · 마기 암석 개척 비용.
class LauncherMountSlot {
  const LauncherMountSlot({
    required this.slotIndex,
    required this.pos,
    required this.recommendedType,
    this.terrainType = MountTerrainType.fortressBastion,
  });

  final int slotIndex;
  final Vec2 pos;
  final LauncherType recommendedType;
  final MountTerrainType terrainType;

  /// 최후방 기본 2개 거점(0, 1번) 외의 전방 전략 지형 거점은 마기 암석 잔해를 먼저 개척해야 포대를 축조할 수 있다!
  int get excavationCost {
    if (slotIndex <= 1) return 0;
    if (slotIndex <= 3) return 24;
    if (slotIndex <= 6) return 28;
    if (slotIndex <= 9) return 32;
    return 36;
  }
}

/// 난이도 3단계 (싱거운 프리패스를 없애고, 입문부터 긴장감 넘치는 수성 재미 제공!).
enum DefenseDifficulty {
  easy(
    id: 'easy',
    name: '쉬움 · 마을 지킴이',
    hpMult: 1.00,
    speedMult: 0.95,
    rewardMult: 1.0,
    summary: '거점 개척과 지형 포진의 기본기를 익히며 막아내는 입문 난이도',
  ),
  normal(
    id: 'normal',
    name: '보통 · 강호 수호자',
    hpMult: 1.24,
    speedMult: 1.05,
    rewardMult: 1.25,
    summary: '기력 운용·거점 개척·5병종 상성·보스 약점 저격이 필수인 표준 진검 난이도 (영구 보상 +25%)',
  ),
  nightmare(
    id: 'nightmare',
    name: '악몽 · 심야 혈전',
    hpMult: 1.68,
    speedMult: 1.15,
    rewardMult: 1.65,
    summary: '극한의 진법 설계와 내공·영수 성장이 요구되는 고수용 사투 (영구 보상 +65%)',
  );

  const DefenseDifficulty({
    required this.id,
    required this.name,
    required this.hpMult,
    required this.speedMult,
    required this.rewardMult,
    required this.summary,
  });

  final String id;
  final String name;
  final double hpMult;
  final double speedMult;
  final double rewardMult;
  final String summary;
}

/// 웨이브(기습 물결) 단위 스폰 정보.
class WaveSpawnGroup {
  const WaveSpawnGroup({
    required this.kind,
    required this.count,
    required this.laneIndex,
    required this.intervalSec,
    this.customBossTitle,
    this.customPortrait,
  });

  final MutantKind kind;
  final int count;
  final int laneIndex;
  final double intervalSec;
  final String? customBossTitle;
  final String? customPortrait;
}

/// 개별 스테이지 명세.
class StageSpec {
  const StageSpec({
    required this.chapterNumber,
    required this.stageNumber,
    required this.globalIndex,
    required this.title,
    required this.subtitle,
    required this.tacticalHint,
    required this.recommendedStone,
    required this.recommendedLaunchers,
    required this.startingFieldTokens,
    required this.waves,
    required this.clearElixirBonus,
    required this.isBossStage,
    this.maxMountCount = 6,
    this.rescueCompanion,
    this.rescueBeast,
    this.alsoRescuesMukhyeon = false,
    this.introDialogue = const [],
    this.outroDialogue = const [],
  });

  final int chapterNumber;
  final int stageNumber;
  final int globalIndex;
  final String title;
  final String subtitle;
  final String tacticalHint;
  final StoneMaterial recommendedStone;
  final List<LauncherType> recommendedLaunchers;
  final int startingFieldTokens;
  final List<List<WaveSpawnGroup>> waves;
  final int clearElixirBonus;
  final bool isBossStage;

  /// 이 관문에서 배치 가능한 길목 초소 발판 수 (1-1의 4곳에서 시작해 9~10장 결전의 14곳까지 점진 확장!).
  final int maxMountCount;

  /// 이 관문을 처음 정화했을 때 구출되어 즉시 아군에 합류하는 동료 무림인.
  final CompanionHero? rescueCompanion;

  /// 이 관문을 처음 정화했을 때 구출되어 즉시 동행 합류하는 신비 영수.
  final SpiritBeast? rescueBeast;

  /// 6장 결전처럼 특별 난입 동료 묵현이 함께 정화 합류하는지 여부.
  final bool alsoRescuesMukhyeon;

  final List<StoryLine> introDialogue;
  final List<StoryLine> outroDialogue;

  bool get hasRescueReward => rescueCompanion != null || rescueBeast != null;

  String get rescueBadgeText {
    if (rescueCompanion != null && alsoRescuesMukhyeon) {
      return '동료 [${rescueCompanion!.name} · 묵현] 구출';
    }
    if (rescueCompanion != null) {
      return '동료 [${rescueCompanion!.name}] 구출';
    }
    if (rescueBeast != null) {
      return '영수 [${rescueBeast!.name}] 구출';
    }
    return '';
  }

  String get code => '$chapterNumber-$stageNumber';
}

/// 각 장(1~10장) 명세.
class ChapterSpec {
  const ChapterSpec({
    required this.number,
    required this.title,
    required this.villageName,
    required this.actLabel,
    required this.bgAsset,
    required this.floorAsset,
    required this.bgmAsset,
    required this.bossName,
    required this.bossPortraitPrefix,
    required this.storySummary,
    required this.unlockNotice,
    required this.surfaceFriction,
    required this.lanes,
    required this.mounts,
    required this.pillars,
    required this.cliffs,
    required this.stageCount,
  });

  final int number;
  final String title;
  final String villageName;
  final String actLabel;
  final String bgAsset;
  final String floorAsset;
  final String bgmAsset;
  final String bossName;
  final String bossPortraitPrefix;
  final String storySummary;
  final String unlockNotice;
  final double surfaceFriction;
  final List<List<Vec2>> lanes;
  final List<LauncherMountSlot> mounts;
  final List<TerrainPillar> pillars;
  final List<CliffZone> cliffs;
  final int stageCount;

  /// 제어점 배열을 3차 카트멀-롬 스플라인과 등간격(8px) 샘플링으로 보간하여
  /// 12굽이 천리협곡 전체를 부드럽고 정교하게 휘돌아 내려오는 연속 곡선 경로를 생성한다.
  List<Vec2> smoothedLane(int laneIndex) {
    final raw = lanes[laneIndex % lanes.length];
    if (raw.length < 3) return raw;

    Vec2 catmullRom(Vec2 p0, Vec2 p1, Vec2 p2, Vec2 p3, double t) {
      final t2 = t * t;
      final t3 = t2 * t;
      final x = 0.5 *
          ((2.0 * p1.x) +
              (-p0.x + p2.x) * t +
              (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
              (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3);
      final y = 0.5 *
          ((2.0 * p1.y) +
              (-p0.y + p2.y) * t +
              (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
              (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.x * 0.0 + p3.y) * t3);
      return Vec2(x.clamp(28.0, CampaignCatalog.arenaWidth - 28.0), y);
    }

    final dense = <Vec2>[];
    for (int i = 0; i < raw.length - 1; i++) {
      final p0 = i == 0 ? raw[0] : raw[i - 1];
      final p1 = raw[i];
      final p2 = raw[i + 1];
      final p3 = (i + 2 < raw.length) ? raw[i + 2] : raw.last;
      final segLen = p1.distanceTo(p2);
      final subSteps = math.max(10, (segLen / 7.5).ceil());
      for (int s = 0; s < subSteps; s++) {
        dense.add(catmullRom(p0, p1, p2, p3, s / subSteps));
      }
    }
    dense.add(raw.last);

    final uniform = <Vec2>[dense.first];
    double acc = 0.0;
    for (int i = 1; i < dense.length; i++) {
      final d = dense[i].distanceTo(uniform.last);
      acc += d;
      if (acc >= 8.0 || i == dense.length - 1) {
        uniform.add(dense[i]);
        acc = 0.0;
      }
    }
    return uniform;
  }
}

/// 《수호알까기 · 탄지무림 심야기습》 1~10장(총 111단계) 720×1360 천리협곡 12굽이 캠페인 생성기.
class CampaignCatalog {
  /// 초장거리 12굽이 천리협곡(실연장 3,800~5,100px!)을 구현하는 720×1360 광활 대장정 전장!
  static const double arenaWidth = 720.0;
  static const double arenaHeight = 1360.0;

  /// 맨 아래 마을 어귀 정중앙 주 발사대(근접 비상 방어 · 수동 탄지 · 🎯보스 약점 정밀저격 겸용) 좌표.
  static const Vec2 centralTowerPos = Vec2(360.0, 1196.0);

  /// 맨 아래 마을 본진 보호 결계 중심 (식량창고·논밭·외양간을 감싸는 남단 반구형 수호진).
  static const Vec2 villageCenter = Vec2(360.0, 1262.0);
  static const double outerShieldRadius = 114.0;
  static const double centralTowerRadius = 30.0;

  // 12굽이 초장거리 구곡양장 표준 템플릿 생성 헬퍼 (전 차선 실연장 3,900~5,100px 보장!)
  static List<Vec2> _serpentineLeftStart({double sway = 0.0}) => [
        Vec2(72 + sway, 42),
        Vec2(648 - sway, 106),
        Vec2(654 - sway, 178),
        Vec2(68 + sway, 250),
        Vec2(66 + sway, 324),
        Vec2(652 - sway, 398),
        Vec2(654 - sway, 474),
        Vec2(70 + sway, 550),
        Vec2(70 + sway, 628),
        Vec2(650 - sway, 706),
        Vec2(650 - sway, 786),
        Vec2(74 + sway, 868),
        Vec2(78 + sway, 952),
        Vec2(636 - sway, 1032),
        const Vec2(342, 1114),
        centralTowerPos,
        villageCenter,
      ];

  static List<Vec2> _serpentineRightStart({double sway = 0.0}) => [
        Vec2(648 - sway, 42),
        Vec2(72 + sway, 106),
        Vec2(66 + sway, 178),
        Vec2(652 - sway, 250),
        Vec2(654 - sway, 324),
        Vec2(68 + sway, 398),
        Vec2(66 + sway, 474),
        Vec2(650 - sway, 550),
        Vec2(650 - sway, 628),
        Vec2(70 + sway, 706),
        Vec2(70 + sway, 786),
        Vec2(646 - sway, 868),
        Vec2(642 - sway, 952),
        Vec2(84 + sway, 1032),
        const Vec2(378, 1114),
        centralTowerPos,
        villageCenter,
      ];

  static List<Vec2> _serpentineCenterWeave({bool goLeftFirst = true}) => goLeftFirst
      ? const [
          Vec2(360, 38),
          Vec2(68, 118),
          Vec2(652, 214),
          Vec2(68, 312),
          Vec2(652, 412),
          Vec2(70, 514),
          Vec2(650, 618),
          Vec2(72, 724),
          Vec2(648, 832),
          Vec2(78, 940),
          Vec2(638, 1038),
          Vec2(360, 1118),
          centralTowerPos,
          villageCenter,
        ]
      : const [
          Vec2(360, 38),
          Vec2(652, 118),
          Vec2(68, 214),
          Vec2(652, 312),
          Vec2(68, 412),
          Vec2(650, 514),
          Vec2(70, 618),
          Vec2(648, 724),
          Vec2(72, 832),
          Vec2(642, 940),
          Vec2(82, 1038),
          Vec2(360, 1118),
          centralTowerPos,
          villageCenter,
        ];

  static final List<ChapterSpec> chapters = [
    ChapterSpec(
      number: 1,
      title: '제1장 · 하산의 길',
      villageName: '흙먼지 마을',
      actLabel: '【기 · 생존 기반 구출】',
      bgAsset: 'assets/images/scenes/bg_night_ch1.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch1.webp',
      bgmAsset: 'bgm_dustyYard.ogg',
      bossName: '독기에 미친 산군',
      bossPortraitPrefix: 'chonjang',
      storySummary:
          '태극석 균열로 쏟아진 심야 독기 속에 돌연변이 대군이 열두 굽이 천리 산비탈 잔도를 따라 남단 흙먼지 마을로 쳐들어온다! 마기 암석을 개척하고 지형 요충지에 포대를 축조해 6~8물결 공세를 버텨내라!',
      unlockNotice: '기명 심법 수련 개방 · 첫째 문양(각성) · 의용대 지원패 전수',
      surfaceFriction: 1.05,
      stageCount: 10,
      lanes: [
        _serpentineLeftStart(sway: 0),
        _serpentineRightStart(sway: 8),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 996), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(214, 828), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(506, 668), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(214, 512), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(506, 360), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(214, 214), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(506, 910), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(360, 590), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.ambushRidge),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(360, 748), radius: 20, sides: 4, rotationSpeedRad: 0.9, restitutionBoost: 1.35),
        TerrainPillar(center: Vec2(360, 436), radius: 19, sides: 5, rotationSpeedRad: -1.0, restitutionBoost: 1.38),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 590), radius: 38, label: '서쪽 산비탈 절벽'),
        CliffZone(center: Vec2(694, 590), radius: 38, label: '동쪽 산비탈 절벽'),
        CliffZone(center: Vec2(26, 910), radius: 34, label: '하단 벼랑 계곡'),
      ],
    ),
    ChapterSpec(
      number: 2,
      title: '제2장 · 기름진 난장',
      villageName: '통통 객잔 식량창고',
      actLabel: '【기 · 생존 기반 구출】',
      bgAsset: 'assets/images/scenes/bg_night_ch2.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch2.webp',
      bgmAsset: 'bgm_oilyTable.ogg',
      bossName: '탐식 거대 변이주방장',
      bossPortraitPrefix: 'tongtong',
      storySummary:
          '피난민들이 모인 통통 객잔의 대곡식 창고를 탐식 변이 대군이 미끄러운 열두 굽이 기름 잔도로 덮친다! 마기 바위를 깨고 고지 망루·매복암을 개척하라!',
      unlockNotice: '물자 호송 시스템 정식 개통 · 동료 반달 합류 · 곡사 회전기 개방',
      surfaceFriction: 0.72,
      stageCount: 11,
      lanes: [
        _serpentineLeftStart(sway: 6),
        _serpentineRightStart(sway: 0),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 992), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(506, 826), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(214, 668), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(506, 512), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(214, 360), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(506, 214), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(360, 590), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(214, 910), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(162, 436), radius: 19, sides: 6, rotationSpeedRad: 1.2, restitutionBoost: 1.42),
        TerrainPillar(center: Vec2(558, 436), radius: 19, sides: 6, rotationSpeedRad: -1.2, restitutionBoost: 1.42),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 746), radius: 38, label: '객잔 뒤편 계곡'),
        CliffZone(center: Vec2(694, 746), radius: 38, label: '장독대 낭떠러지'),
        CliffZone(center: Vec2(694, 360), radius: 34, label: '뒷산 기름 절벽'),
      ],
    ),
    ChapterSpec(
      number: 3,
      title: '제3장 · 거북 장터 야습',
      villageName: '거북 장터 종자·우시장',
      actLabel: '【기 · 생존 기반 구출】',
      bgAsset: 'assets/images/scenes/bg_night_ch3.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch3.webp',
      bgmAsset: 'bgm_turtleMarket.ogg',
      bossName: '그림자 변이 자객단주',
      bossPortraitPrefix: 'jagaek',
      storySummary:
          '봄에 뿌릴 씨앗과 어미 가축들이 모인 거북 장터에 밤비가 내리고, 그림자 변이 무리가 세 갈래 열두 굽이 장터 회랑을 돌아 침투한다!',
      unlockNotice: '전국 호송망 확장 · 영수 영귀 금강 개방 · 한빙 역장기 개방',
      surfaceFriction: 0.92,
      stageCount: 11,
      lanes: [
        _serpentineLeftStart(sway: 4),
        _serpentineCenterWeave(goLeftFirst: true),
        _serpentineRightStart(sway: 4),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 994), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(210, 826), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(510, 826), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 668), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(210, 512), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(510, 512), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(360, 360), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(210, 214), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(510, 214), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(360, 512), radius: 20, sides: 5, rotationSpeedRad: 1.1, restitutionBoost: 1.38),
        TerrainPillar(center: Vec2(168, 910), radius: 18, sides: 6, rotationSpeedRad: -1.2, restitutionBoost: 1.40),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 590), radius: 36, label: '장터 수로 낭떠러지'),
        CliffZone(center: Vec2(694, 590), radius: 36, label: '성벽 아래 해자'),
        CliffZone(center: Vec2(26, 286), radius: 34, label: '북문 해자 구렁'),
      ],
    ),
    ChapterSpec(
      number: 4,
      title: '제4장 · 야성의 숲',
      villageName: '쿠비 산채 봉화대',
      actLabel: '【승 · 반격 진법과 구원군】',
      bgAsset: 'assets/images/scenes/bg_night_ch4.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch4.webp',
      bgmAsset: 'bgm_kubiForest.ogg',
      bossName: '숲의 천년 역병주',
      bossPortraitPrefix: 'kubi',
      storySummary:
          '각 마을 수호탑 보급에 필요한 천년 목재와 산길 봉화대를 되찾기 위해 쿠비 산채로 향한다. 열두 굽이 대삼림 협곡의 망루·매복암을 개척하라!',
      unlockNotice: '심야 탐색 시스템 정식 개통 · 둘째 문양(동행) · 동료 구르미 합류',
      surfaceFriction: 1.00,
      stageCount: 12,
      lanes: [
        _serpentineLeftStart(sway: 0),
        _serpentineCenterWeave(goLeftFirst: false),
        _serpentineRightStart(sway: 0),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 996), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(210, 910), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(510, 910), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 746), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(210, 590), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(510, 590), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(360, 436), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(210, 286), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(510, 286), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(360, 178), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(182, 436), radius: 19, sides: 3, rotationSpeedRad: 1.4, restitutionBoost: 1.44),
        TerrainPillar(center: Vec2(538, 436), radius: 19, sides: 3, rotationSpeedRad: -1.4, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 668), radius: 38, label: '산채 천길 벼랑'),
        CliffZone(center: Vec2(694, 668), radius: 38, label: '구름다리 절벽'),
        CliffZone(center: Vec2(694, 286), radius: 34, label: '북쪽 암벽 계곡'),
      ],
    ),
    ChapterSpec(
      number: 5,
      title: '제5장 · 철벽의 진인',
      villageName: '로직 학당 기관전',
      actLabel: '【승 · 반격 진법과 구원군】',
      bgAsset: 'assets/images/scenes/bg_night_ch5.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch5.webp',
      bgmAsset: 'bgm_logicMarble.ogg',
      bossName: '폭주 기관 거신병',
      bossPortraitPrefix: 'logic',
      storySummary:
          '중갑 변이체를 뚫을 고대 기관술의 본산 로직 학당! 열두 번 꺾여 도는 거대 기관 미궁 회랑을 개척하고 내공 증폭기와 어기어석의 비전을 열어라!',
      unlockNotice: '내공 증폭기 개방 · 셋째 문양(자동 어기어석) · 동료 정각 합류',
      surfaceFriction: 0.80,
      stageCount: 11,
      lanes: [
        _serpentineLeftStart(sway: 2),
        _serpentineCenterWeave(goLeftFirst: true),
        _serpentineRightStart(sway: 2),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 998), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(210, 910), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(510, 910), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 826), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(506, 746), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(214, 746), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(210, 590), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(510, 590), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(360, 436), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(210, 286), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(510, 286), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.spiritSpring),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(184, 512), radius: 19, sides: 8, rotationSpeedRad: 1.25, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(536, 512), radius: 19, sides: 8, rotationSpeedRad: -1.25, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(360, 286), radius: 18, sides: 6, rotationSpeedRad: 1.15, restitutionBoost: 1.42),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 512), radius: 36, label: '학당 서쪽 연못 해자'),
        CliffZone(center: Vec2(694, 512), radius: 36, label: '학당 동쪽 절벽'),
        CliffZone(center: Vec2(26, 868), radius: 34, label: '기관 지하 수렁'),
      ],
    ),
    ChapterSpec(
      number: 6,
      title: '제6장 · 무림맹 본단 혈전',
      villageName: '무림맹 대광장',
      actLabel: '【승 · 1부 절정 결전】',
      bgAsset: 'assets/images/scenes/bg_night_ch6.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch6.webp',
      bgmAsset: 'bgm_murimIce.ogg',
      bossName: '심야 흑화 마룡수',
      bossPortraitPrefix: 'maengju',
      storySummary:
          '혹한의 밤, 네 갈래 열두 굽이 설원 계단 회랑에서 묵현(3차)을 정화 탄지로 구원하고 맹주와 함께 3페이즈 흑화 마룡수를 격파하라!',
      unlockNotice: '황금 지원패(무림수호단 출두야~~!!) 완성 · 동료 용아 및 위기 난입 묵현 합류',
      surfaceFriction: 0.76,
      stageCount: 12,
      lanes: [
        _serpentineLeftStart(sway: 0),
        _serpentineCenterWeave(goLeftFirst: true),
        _serpentineCenterWeave(goLeftFirst: false),
        _serpentineRightStart(sway: 0),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 998), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(210, 910), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(510, 910), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 826), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(214, 746), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(506, 998), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(210, 590), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(510, 590), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(360, 436), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(210, 286), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(510, 286), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(360, 178), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(360, 590), radius: 21, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(174, 828), radius: 18, sides: 6, rotationSpeedRad: -1.35, restitutionBoost: 1.42),
        TerrainPillar(center: Vec2(546, 828), radius: 18, sides: 6, rotationSpeedRad: 1.35, restitutionBoost: 1.42),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 668), radius: 38, label: '본단 빙벽 협곡'),
        CliffZone(center: Vec2(694, 668), radius: 38, label: '본단 화염 구렁'),
        CliffZone(center: Vec2(26, 286), radius: 34, label: '설원 천길 절벽'),
      ],
    ),
    ChapterSpec(
      number: 7,
      title: '제7장 · 열사의 협곡',
      villageName: '사막 오아시스 성채',
      actLabel: '【전 · 독기 근원 대원정】',
      bgAsset: 'assets/images/scenes/bg_night_ch7.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch7.webp',
      bgmAsset: 'bgm_dustyYard.ogg',
      bossName: '모래폭풍 사막 역병왕',
      bossPortraitPrefix: 'sawang',
      storySummary:
          '서쪽 독기의 기둥을 쫓아 도착한 열사의 천리 대협곡! 거대한 모래언덕을 열두 번 휘감아 내려오는 사구 회랑 거점을 개척해 오아시스를 지켜내라!',
      unlockNotice: '4형(극의) 발사대 제련 완성 · 천마 화신 영입 개방',
      surfaceFriction: 1.15,
      stageCount: 11,
      lanes: [
        _serpentineLeftStart(sway: 6),
        _serpentineCenterWeave(goLeftFirst: true),
        _serpentineRightStart(sway: 6),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 998), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(210, 910), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(510, 910), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 826), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(214, 746), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(506, 998), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(210, 590), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(510, 590), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(360, 436), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(210, 286), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(510, 286), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(360, 178), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(182, 512), radius: 19, sides: 4, rotationSpeedRad: 1.3, restitutionBoost: 1.40),
        TerrainPillar(center: Vec2(538, 512), radius: 19, sides: 4, rotationSpeedRad: -1.3, restitutionBoost: 1.40),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 628), radius: 38, label: '모래 소용돌이 구렁'),
        CliffZone(center: Vec2(694, 628), radius: 38, label: '협곡 낭떠러지'),
        CliffZone(center: Vec2(694, 286), radius: 34, label: '열사 절벽 해자'),
      ],
    ),
    ChapterSpec(
      number: 8,
      title: '제8장 · 흑룡 해적선 구호항',
      villageName: '구호 곡식 함대 갑판',
      actLabel: '【전 · 독기 근원 대원정】',
      bgAsset: 'assets/images/scenes/bg_night_ch8.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch8.webp',
      bgmAsset: 'bgm_oilyTable.ogg',
      bossName: '심해 흑독 대촉수왕',
      bossPortraitPrefix: 'haejeok',
      storySummary:
          '굶주린 바닷가 마을들에 구호 곡식을 나르는 해적왕의 대함대! 연결된 대선단 갑판 열두 굽이 현측 망루를 개척해 심해 괴수 대군을 수장하라!',
      unlockNotice: '영수 천룡 금룡 개방 · 동료 검황 영입 개방',
      surfaceFriction: 0.84,
      stageCount: 11,
      lanes: [
        _serpentineLeftStart(sway: 3),
        _serpentineCenterWeave(goLeftFirst: false),
        _serpentineRightStart(sway: 3),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 998), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(510, 868), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(210, 868), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 910), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(214, 998), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(360, 746), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(210, 590), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(510, 590), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(360, 436), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(210, 286), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(510, 286), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(360, 590), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 12, pos: Vec2(360, 178), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(360, 360), radius: 20, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.48),
        TerrainPillar(center: Vec2(172, 786), radius: 18, sides: 5, rotationSpeedRad: -1.4, restitutionBoost: 1.44),
        TerrainPillar(center: Vec2(548, 786), radius: 18, sides: 5, rotationSpeedRad: 1.4, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 590), radius: 38, label: '좌현 검푸른 밤바다'),
        CliffZone(center: Vec2(694, 590), radius: 38, label: '우현 소용돌이 바다'),
        CliffZone(center: Vec2(26, 910), radius: 34, label: '선미 심해 급류'),
      ],
    ),
    ChapterSpec(
      number: 9,
      title: '제9장 · 화염산 봉인굴',
      villageName: '화염산 봉인 제단',
      actLabel: '【전 · 독기 근원 대원정】',
      bgAsset: 'assets/images/scenes/bg_night_ch9.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch9.webp',
      bgmAsset: 'bgm_clash.ogg',
      bossName: '분화구 심연 염마왕',
      bossPortraitPrefix: 'hongryeon',
      storySummary:
          '대지에서 독기가 치솟는 화염산 대분화구! 열두 번 휘감아 내려오는 천리 용암 절벽길 14개 전략 거점을 개척해 천상 계단을 열어라!',
      unlockNotice: '한철·신물 수호석 제련 극대화 · 동료 무량 신승 개방 · 천상 계단 개통',
      surfaceFriction: 0.90,
      stageCount: 12,
      lanes: [
        _serpentineLeftStart(sway: 0),
        _serpentineCenterWeave(goLeftFirst: true),
        _serpentineCenterWeave(goLeftFirst: false),
        _serpentineRightStart(sway: 0),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 998), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(210, 910), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(510, 910), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 826), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(214, 746), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(506, 998), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(190, 706), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(530, 706), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(210, 550), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(510, 550), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(360, 590), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(210, 324), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 12, pos: Vec2(510, 324), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 13, pos: Vec2(360, 178), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(182, 436), radius: 19, sides: 5, rotationSpeedRad: 1.6, restitutionBoost: 1.46),
        TerrainPillar(center: Vec2(538, 436), radius: 19, sides: 5, rotationSpeedRad: -1.6, restitutionBoost: 1.46),
        TerrainPillar(center: Vec2(360, 668), radius: 18, sides: 6, rotationSpeedRad: 1.35, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 668), radius: 38, label: '서쪽 용암 분화구'),
        CliffZone(center: Vec2(694, 668), radius: 38, label: '동쪽 용암 절벽'),
        CliffZone(center: Vec2(694, 286), radius: 34, label: '북쪽 화구 심연'),
      ],
    ),
    ChapterSpec(
      number: 10,
      title: '제10장 · 천상 탄신전',
      villageName: '태초 태극석 신전 (보스 10연전)',
      actLabel: '【결 · 최종 정화 결전】',
      bgAsset: 'assets/images/scenes/bg_night_ch10.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch10.webp',
      bgmAsset: 'bgm_boss.ogg',
      bossName: '심야에 물든 태초 탄신',
      bossPortraitPrefix: 'tansin',
      storySummary:
          '구름 위 광활한 천상 탄신전! 열두 굽이 태극 대회랑 14개 성좌 거점을 개척·장악해 8물결 대공세와 3페이즈 다단 변이 대수괴들을 정밀 파쇄하라!',
      unlockNotice: '열 마을 완전 정화 대단원 귀향 엔딩 · 수호신 칭호 획득',
      surfaceFriction: 0.82,
      stageCount: 10,
      lanes: [
        _serpentineLeftStart(sway: 0),
        _serpentineCenterWeave(goLeftFirst: true),
        _serpentineCenterWeave(goLeftFirst: false),
        _serpentineRightStart(sway: 0),
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 998), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(210, 910), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(510, 910), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(360, 826), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(214, 746), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(506, 998), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(190, 706), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(530, 706), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(210, 550), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(510, 550), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(360, 590), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(210, 324), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 12, pos: Vec2(510, 324), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 13, pos: Vec2(360, 178), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(360, 398), radius: 22, sides: 8, rotationSpeedRad: 1.7, restitutionBoost: 1.50),
        TerrainPillar(center: Vec2(182, 474), radius: 19, sides: 6, rotationSpeedRad: -1.4, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(538, 474), radius: 19, sides: 6, rotationSpeedRad: 1.4, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(360, 668), radius: 19, sides: 8, rotationSpeedRad: -1.5, restitutionBoost: 1.48),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 628), radius: 38, label: '천상 운해 낭떠러지'),
        CliffZone(center: Vec2(694, 628), radius: 38, label: '은하 절벽'),
        CliffZone(center: Vec2(26, 286), radius: 34, label: '성좌 허공 해자'),
        CliffZone(center: Vec2(694, 910), radius: 34, label: '천상 남단 심연'),
      ],
    ),
  ];

  static ChapterSpec chapterOf(int chapterNumber) =>
      chapters[(chapterNumber - 1).clamp(0, chapters.length - 1)];

  static final List<StageSpec> allStages = _buildAllStages();

  static List<StageSpec> stagesOfChapter(int chapterNumber) =>
      allStages.where((s) => s.chapterNumber == chapterNumber).toList();

  static StageSpec stageAt(int chapterNumber, int stageNumber) =>
      allStages.firstWhere(
        (s) => s.chapterNumber == chapterNumber && s.stageNumber == stageNumber,
        orElse: () => allStages.first,
      );

  /// 현재 클리어 기록 이후 가장 가까운 동료·영수 구출 작전 관문을 반환한다.
  static StageSpec? nextRescueStageAfter(int clearedGlobalStage) {
    for (final s in allStages) {
      if (s.globalIndex > clearedGlobalStage && s.hasRescueReward) {
        return s;
      }
    }
    return null;
  }

  /// 관문이 진행될수록 배치 가능한 광역 지형 초소 장소가 4곳(1-1)에서 최대 14곳(9~10장)까지 점진적으로 늘어난다!
  static int _maxMountCountFor(int ch, int st) {
    switch (ch) {
      case 1:
        if (st <= 3) return 4;
        if (st <= 7) return 5;
        return 6;
      case 2:
        return st <= 5 ? 6 : 7;
      case 3:
        return st <= 5 ? 7 : 8;
      case 4:
        return st <= 6 ? 8 : 9;
      case 5:
        return st <= 5 ? 9 : 10;
      case 6:
        return st <= 6 ? 10 : 11;
      case 7:
        return st <= 5 ? 11 : 12;
      case 8:
        return st <= 5 ? 12 : 13;
      case 9:
        return st <= 6 ? 13 : 14;
      default:
        return st <= 4 ? 13 : 14;
    }
  }

  /// 1~9장 캠페인 전반에 걸쳐 동료 13인과 영수 4종을 지속적으로 구출·영입하는 시간표.
  static CompanionHero? _rescueCompanionFor(int ch, int st) {
    if (ch == 1 && st == 4) return CompanionHero.yeonbi;
    if (ch == 1 && st == 8) return CompanionHero.cheongmyeong;
    if (ch == 2 && st == 11) return CompanionHero.bandal;
    if (ch == 3 && st == 5) return CompanionHero.chwiseon;
    if (ch == 4 && st == 5) return CompanionHero.mukgaek;
    if (ch == 4 && st == 12) return CompanionHero.gurumi;
    if (ch == 5 && st == 5) return CompanionHero.seolhwa;
    if (ch == 5 && st == 11) return CompanionHero.jeonggak;
    if (ch == 6 && st == 12) return CompanionHero.yonga;
    if (ch == 7 && st == 6) return CompanionHero.magyo;
    if (ch == 8 && st == 11) return CompanionHero.geomhwang;
    if (ch == 9 && st == 6) return CompanionHero.sinseung;
    return null;
  }

  static SpiritBeast? _rescueBeastFor(int ch, int st) {
    if (ch == 2 && st == 5) return SpiritBeast.geumgangTurtle;
    if (ch == 3 && st == 11) return SpiritBeast.cheonghak;
    if (ch == 6 && st == 5) return SpiritBeast.baekho;
    if (ch == 8 && st == 5) return SpiritBeast.geumryong;
    return null;
  }

  static List<StageSpec> _buildAllStages() {
    final result = <StageSpec>[];
    int globalIdx = 0;

    for (final ch in chapters) {
      final laneCount = ch.lanes.length;
      if (ch.number == 10) {
        for (int st = 1; st <= 10; st++) {
          globalIdx++;
          final isFinalGod = st == 10;
          final refChapter = isFinalGod ? ch : chapters[st - 1];
          final mountCap = _maxMountCountFor(10, st).clamp(1, ch.mounts.length);
          result.add(
            StageSpec(
              chapterNumber: 10,
              stageNumber: st,
              globalIndex: globalIdx,
              title: isFinalGod
                  ? '최종 관문 · 오염된 태초 탄신 구원'
                  : '천상 $st관문 · ${refChapter.bossName} 심야 환영',
              subtitle: isFinalGod
                  ? '태극석의 균열을 메워 열 마을의 논밭과 생명을 되살려라! (8물결 · 초소 $mountCap곳)'
                  : '${refChapter.villageName} 우두머리의 심야 환영 8물결 혈전 · 초소 $mountCap곳 개방',
              tacticalHint: isFinalGod
                  ? '14곳 성좌 지형 거점의 마기 암석을 개척하고, 3페이즈 다단 각성하는 태초 탄신의 🎯약점 핵을 정밀 저격해 외각 장갑을 파쇄하세요!'
                  : '네 갈래 천상 12굽이 회랑의 망루·매복암을 개척하고 3페이즈 우두머리의 🎯노출 약점을 집중 타격하세요!',
              recommendedStone: StoneMaterial.values[(st + 2).clamp(0, 12)],
              recommendedLaunchers: const [
                LauncherType.qiAmplifier,
                LauncherType.heavy,
                LauncherType.frostField,
                LauncherType.curveSpin,
                LauncherType.rapid,
              ],
              startingFieldTokens: 92 + st * 5,
              clearElixirBonus: isFinalGod ? 10 : 4,
              isBossStage: true,
              maxMountCount: mountCap,
              waves: _buildChapter10BossWaves(st, laneCount, refChapter),
              introDialogue: st == 1
                  ? const [
                      StoryLine(
                        speaker: '무림맹주',
                        portraitPrefix: 'maengju',
                        text: '여기가 구름 위 천상 탄신전이다! 심야의 독기가 열두 굽이 천상 회랑마다 마기 암석과 우두머리 환영을 세워 막고 있구나!',
                      ),
                      StoryLine(
                        speaker: '묵현',
                        portraitPrefix: 'mukhyeon',
                        text: '전방 고지 망루로 적 선봉을 요격하고, 약점 핵(🎯)을 정밀 저격해 외각 장갑을 부숴야 한다. 가자!',
                      ),
                    ]
                  : isFinalGod
                      ? const [
                          StoryLine(
                            speaker: '태초 탄신',
                            portraitPrefix: 'tansin',
                            text: '크으으… 내 가슴의 태극석에 스민 심야 독기를… 그대들의 정화 수호탑으로 깨뜨려 다오…!',
                          ),
                          StoryLine(
                            speaker: '촌장',
                            portraitPrefix: 'chonjang',
                            text: '열 마을 백성들의 염원이 모두 네 수호탑에 모여 있다! 마지막 여덟 물결을 버텨 새벽을 밝혀라!',
                          ),
                        ]
                      : [
                          StoryLine(
                            speaker: '묵현',
                            portraitPrefix: 'mukhyeon',
                            text: '천상 제$st관문! 과거 [${refChapter.villageName}]을 위협했던 「${refChapter.bossName}」의 심야 환영이 3페이즈 진신으로 가로막고 있다!',
                          ),
                        ],
              outroDialogue: isFinalGod
                  ? epilogueDialogue
                  : [
                      StoryLine(
                        speaker: '청명',
                        portraitPrefix: 'cheongmyeong',
                        text: '「${refChapter.bossName}」의 천상 독기 환영을 정화했습니다! 태극석 신전 정상까지 ${10 - st}관문 남았습니다!',
                      ),
                    ],
            ),
          );
        }
        continue;
      }

      // 1~9장 각 10~12단계 생성 (6~8물결 심야 대장정!)
      for (int st = 1; st <= ch.stageCount; st++) {
        globalIdx++;
        final isChapterBoss = st == ch.stageCount;
        final isHeukpungStage = st == ch.stageCount - 1;
        final isMukhyeonStage = (ch.number == 3 || ch.number == 5 || ch.number == 6) && st == (ch.stageCount ~/ 2);
        final mountCap = _maxMountCountFor(ch.number, st).clamp(1, ch.mounts.length);
        final rescueHero = _rescueCompanionFor(ch.number, st);
        final rescuePet = _rescueBeastFor(ch.number, st);
        final rescuesMukhyeon = ch.number == 6 && st == 12;

        final waves = _buildNormalChapterWaves(
          chapter: ch,
          stage: st,
          laneCount: laneCount,
          isChapterBoss: isChapterBoss,
          isHeukpung: isHeukpungStage,
          isMukhyeon: isMukhyeonStage,
          hasRescue: rescueHero != null || rescuePet != null,
        );
        final wCnt = waves.length;

        String stageTitle;
        String sub;
        if (isChapterBoss) {
          stageTitle = '${ch.number}-$st 결전 · ${ch.bossName}';
          sub = '${ch.villageName} 최종 $wCnt물결 심야 결전 (초소 $mountCap곳)';
        } else if (isHeukpungStage) {
          stageTitle = '${ch.number}-$st 약탈 저지 · 부두목 흑풍';
          sub = '식량 수레를 노리는 약탈 선봉장 흑풍 $wCnt물결 격퇴 (초소 $mountCap곳)';
        } else if (isMukhyeonStage) {
          stageTitle = '${ch.number}-$st 숙적 조우 · 사형 묵현';
          sub = ch.number == 6
              ? '독기에 삼켜진 묵현을 $wCnt물결 정화 탄지로 구원하라! (초소 $mountCap곳)'
              : '폭주하는 사형 묵현의 $wCnt물결 야간 기습! (초소 $mountCap곳)';
        } else if (rescueHero != null) {
          stageTitle = '${ch.number}-$st 구출 작전 · 동료 ${rescueHero.name}';
          sub = '고립된 ${rescueHero.title} [${rescueHero.name}] $wCnt물결 구출전! (초소 $mountCap곳)';
        } else if (rescuePet != null) {
          stageTitle = '${ch.number}-$st 영수 구출 · ${rescuePet.name}';
          sub = '독기 포위망에 갇힌 영수 [${rescuePet.name}] $wCnt물결 구원 작전! (초소 $mountCap곳)';
        } else {
          stageTitle = '${ch.number}-$st 야간 길목 수호 ($st차 밤)';
          final midKind = st == 1 ? MutantKind.swiftShadowBoss : _midBossKindFor(ch.number, st);
          sub = '${ch.villageName} 12굽이 $wCnt물결 방어 (초소 $mountCap곳) · 두목 [${midKind.name}] 침략!';
        }

        if ((isChapterBoss || isHeukpungStage || isMukhyeonStage) &&
            (rescueHero != null || rescuePet != null)) {
          final rescueTag = rescueHero != null
              ? (rescuesMukhyeon ? '동료 ${rescueHero.name}·묵현 합류!' : '동료 ${rescueHero.name} 구출!')
              : '영수 ${rescuePet!.name} 구출!';
          sub = '$sub · ★$rescueTag';
        }

        final recStoneIndex = ((ch.number - 1) + (st ~/ 4)).clamp(0, 9);
        final recStone = StoneMaterial.values[recStoneIndex];

        result.add(
          StageSpec(
            chapterNumber: ch.number,
            stageNumber: st,
            globalIndex: globalIdx,
            title: stageTitle,
            subtitle: sub,
            tacticalHint: _hintForStage(ch.number, st, isChapterBoss, isHeukpungStage),
            recommendedStone: recStone,
            recommendedLaunchers: ch.mounts.take(mountCap).map((m) => m.recommendedType).toList(),
            // 초기 군수 기력 긴축 (1장 48⚡: 시작 시 오직 첫 탑 1기만 건설 가능! 이후 적 격살·개척으로 확장!)
            startingFieldTokens: 48 + (ch.number - 1) * 6,
            clearElixirBonus: isChapterBoss
                ? 5
                : ((isHeukpungStage || isMukhyeonStage || rescueHero != null || rescuePet != null) ? 3 : 1),
            isBossStage: isChapterBoss || isHeukpungStage || isMukhyeonStage,
            maxMountCount: mountCap,
            rescueCompanion: rescueHero,
            rescueBeast: rescuePet,
            alsoRescuesMukhyeon: rescuesMukhyeon,
            waves: waves,
            introDialogue: _introDialogueFor(
              ch,
              st,
              isChapterBoss,
              isHeukpungStage,
              isMukhyeonStage,
              rescueHero,
              rescuePet,
            ),
            outroDialogue: _outroDialogueFor(
              ch,
              st,
              isChapterBoss,
              isHeukpungStage,
              isMukhyeonStage,
              rescueHero,
              rescuePet,
            ),
          ),
        );
      }
    }
    return result;
  }

  static MutantKind _midBossKindFor(int ch, int stage) {
    switch ((ch + stage) % 3) {
      case 0:
        return MutantKind.swiftShadowBoss;
      case 1:
        return MutantKind.ironColossusBoss;
      default:
        return MutantKind.crimsonBreakerBoss;
    }
  }

  static String _midBossCustomTitle(int ch, MutantKind midKind) {
    const swiftPrefixes = [
      '산비탈 기습 선봉',
      '기름길 질풍대장',
      '장터 골목 암습장',
      '야성림 그림자',
      '기관 회랑 쾌속귀',
      '빙설 폭풍 기습장',
      '모래바람 추격왕',
      '검은 파도 쾌속귀',
      '화염 협곡 섬광귀',
      '천상 운해 기습장',
    ];
    const colossusPrefixes = [
      '바위고개 철벽장',
      '객잔 창고 중갑병',
      '우시장 철벽 수문장',
      '천년고목 중장갑',
      '로직 학당 강철수',
      '무림맹 빙갑 거수',
      '열사 암벽 거신',
      '심해 철갑 거수',
      '용암 외피 중갑수',
      '천상 금강 수문장',
    ];
    const breakerPrefixes = [
      '성책 파괴자',
      '대곡창 파성병',
      '장터 성문 파괴자',
      '봉화대 파성귀',
      '기관진 분쇄자',
      '대광장 결계 파괴자',
      '오아시스 파성왕',
      '구호함대 갑판 파쇄자',
      '분화구 업화 파성귀',
      '천상 신전 파성귀',
    ];
    final idx = (ch - 1).clamp(0, 9);
    switch (midKind) {
      case MutantKind.swiftShadowBoss:
        return '${swiftPrefixes[idx]} 혈영 질풍귀';
      case MutantKind.ironColossusBoss:
        return '${colossusPrefixes[idx]} 현철 중갑거수';
      case MutantKind.crimsonBreakerBoss:
        return '${breakerPrefixes[idx]} 적염 파성귀';
      default:
        return midKind.name;
    }
  }

  static String _hintForStage(int ch, int st, bool boss, bool heukpung) {
    if (boss) {
      return '8물결 최종 결전! 마기 암석을 개척해 요충지를 장악하고, 3페이즈 대수괴의 빛나는 🎯약점 핵을 직접 터치(정밀 저격)해 장갑을 깨뜨리세요!';
    }
    if (heukpung) {
      return '약탈 선봉 흑풍이 7물결 대군과 함께 3페이즈 폭주를 일으킵니다! 전방 매복암을 개척하고 🎯약점을 정밀 타격하세요!';
    }
    final mid = _midBossKindFor(ch, st);
    if (mid == MutantKind.swiftShadowBoss) {
      return '포탑이 늘어날수록 건설비가 증가합니다! 거점 마기 암석을 신중히 개척하고 2차 재변이 [혈영 질풍귀]의 🎯약점을 저격하세요!';
    } else if (mid == MutantKind.ironColossusBoss) {
      return '중간보스 [현철 중갑거수]는 마기 침식과 2차 철갑 재변이를 일으킵니다! 오염된 포탑을 터치해 정화하고 고지 망루 중포로 파쇄하세요!';
    } else {
      return '중간보스 [적염 파성귀]의 2차 광폭화 돌파를 막으려면 12굽이 상단 거점을 미리 개척하고 🎯약점 핵을 정밀 연타하세요!';
    }
  }

  /// 6물결(일반) ~ 7물결(구출·중견보스) ~ 8물결(장 보스 대결전)의 진득한 디펜스 공방전 구성!
  static List<List<WaveSpawnGroup>> _buildNormalChapterWaves({
    required ChapterSpec chapter,
    required int stage,
    required int laneCount,
    required bool isChapterBoss,
    required bool isHeukpung,
    required bool isMukhyeon,
    required bool hasRescue,
  }) {
    final ch = chapter.number;
    final swarmCount = 24 + ch * 4 + stage * 2;
    final mediumCount = (6 + ch ~/ 2 + stage ~/ 2).clamp(6, 20);
    final midKind = _midBossKindFor(ch, stage);
    final midTitle = _midBossCustomTitle(ch, midKind);
    final secondMidKind = _midBossKindFor(ch + 1, stage + 1);
    final secondMidTitle = _midBossCustomTitle(ch, secondMidKind);
    final waves = <List<WaveSpawnGroup>>[];

    // [1물결] 심야 선봉 강습대 (첫 포탑 1기 축조 판단 및 초기 기력 수급 구간)
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: swarmCount,
        laneIndex: 0,
        intervalSec: (0.42 - ch * 0.010).clamp(0.26, 0.42),
      ),
      WaveSpawnGroup(
        kind: MutantKind.sickHound,
        count: (swarmCount * 0.55).round().clamp(11, 30),
        laneIndex: 1 % laneCount,
        intervalSec: (0.52 - ch * 0.012).clamp(0.34, 0.52),
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.bloodCocoon,
        count: (mediumCount - 2).clamp(4, 12),
        laneIndex: 2 % laneCount,
        intervalSec: 0.98,
      ),
    ]);

    // [2물결] 기동 양동 돌격대 + (2단계 이상) 1차 2단 변이 중간보스 조기 침략! (초반부터 팽팽한 긴장감 부여!)
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 4).clamp(24, 48),
        laneIndex: (stage + 1) % laneCount,
        intervalSec: (0.36 - ch * 0.009).clamp(0.22, 0.36),
      ),
      WaveSpawnGroup(
        kind: MutantKind.sickHound,
        count: (14 + ch * 2).clamp(14, 34),
        laneIndex: stage % laneCount,
        intervalSec: 0.44,
      ),
      WaveSpawnGroup(
        kind: MutantKind.ironBoar,
        count: (4 + ch ~/ 2).clamp(4, 11),
        laneIndex: (stage + 2) % laneCount,
        intervalSec: 1.05,
      ),
      if (stage >= 2)
        WaveSpawnGroup(
          kind: midKind,
          count: 1,
          laneIndex: (stage + 1) % laneCount,
          intervalSec: 1.65,
          customBossTitle: midTitle,
        ),
    ]);

    // [3물결] 중견 돌파군 (전방 마기 암석 거점 개척 필수 구간)
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 6).clamp(26, 52),
        laneIndex: stage % laneCount,
        intervalSec: 0.31,
      ),
      WaveSpawnGroup(
        kind: ch >= 3 ? MutantKind.plagueToad : MutantKind.bloodCocoon,
        count: (7 + ch + stage ~/ 3).clamp(7, 18),
        laneIndex: (stage + 1) % laneCount,
        intervalSec: 0.78,
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.ironBoar,
        count: (5 + ch ~/ 2).clamp(5, 14),
        laneIndex: (laneCount - 1),
        intervalSec: 0.88,
      ),
    ]);

    // [4물결] 다차선 중갑·자폭 포위 압박군
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.sickHound,
        count: (16 + ch * 2 + stage ~/ 2).clamp(16, 38),
        laneIndex: (stage + 2) % laneCount,
        intervalSec: 0.38,
      ),
      WaveSpawnGroup(
        kind: MutantKind.bloodCocoon,
        count: (8 + ch + stage ~/ 2).clamp(8, 22),
        laneIndex: 0,
        intervalSec: 0.72,
      ),
      WaveSpawnGroup(
        kind: MutantKind.ironBoar,
        count: (5 + ch ~/ 2 + stage ~/ 3).clamp(5, 14),
        laneIndex: 1 % laneCount,
        intervalSec: 0.94,
      ),
      if (ch >= 2)
        WaveSpawnGroup(
          kind: MutantKind.plagueToad,
          count: (4 + ch ~/ 2).clamp(4, 12),
          laneIndex: (laneCount - 1),
          intervalSec: 0.96,
        ),
    ]);

    // [5물결] 심야 정예 파성 군단 (고단계 포탑 승급 및 진법 시너지 시험대)
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 10).clamp(30, 58),
        laneIndex: (stage + 1) % laneCount,
        intervalSec: (0.28 - ch * 0.008).clamp(0.19, 0.28),
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.sickHound,
        count: (8 + ch + stage ~/ 3).clamp(8, 20),
        laneIndex: stage % laneCount,
        intervalSec: 0.76,
      ),
      WaveSpawnGroup(
        kind: MutantKind.ironBoar,
        count: (6 + ch ~/ 2).clamp(6, 15),
        laneIndex: (stage + 2) % laneCount,
        intervalSec: 0.90,
      ),
      if (ch >= 4 && stage >= 3)
        WaveSpawnGroup(
          kind: secondMidKind,
          count: 1,
          laneIndex: stage % laneCount,
          intervalSec: 1.70,
          customBossTitle: secondMidTitle,
        ),
    ]);

    // 구출전·중견보스전·장 결전은 7~8물결까지 이어지는 대혈전으로 확장!
    if (hasRescue || isHeukpung || isMukhyeon || isChapterBoss) {
      waves.add([
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: (swarmCount + 12).clamp(32, 62),
          laneIndex: 0,
          intervalSec: 0.24,
        ),
        WaveSpawnGroup(
          kind: MutantKind.plagueToad,
          count: (6 + ch ~/ 2).clamp(6, 15),
          laneIndex: 1 % laneCount,
          intervalSec: 0.84,
        ),
        WaveSpawnGroup(
          kind: MutantKind.bloodCocoon,
          count: (9 + ch).clamp(9, 22),
          laneIndex: (laneCount - 1),
          intervalSec: 0.68,
        ),
        WaveSpawnGroup(
          kind: secondMidKind,
          count: 1,
          laneIndex: (stage + 2) % laneCount,
          intervalSec: 1.65,
          customBossTitle: secondMidTitle,
        ),
      ]);
    }

    if (isChapterBoss) {
      // 장 최종 보스전 전용 [7물결] 친위 호위군 총돌격!
      waves.add([
        WaveSpawnGroup(
          kind: MutantKind.sickHound,
          count: (20 + ch * 2).clamp(22, 42),
          laneIndex: 1 % laneCount,
          intervalSec: 0.32,
        ),
        WaveSpawnGroup(
          kind: MutantKind.shieldYacha,
          count: (8 + ch ~/ 2).clamp(8, 16),
          laneIndex: 0,
          intervalSec: 0.78,
        ),
        WaveSpawnGroup(
          kind: MutantKind.ironBoar,
          count: (7 + ch ~/ 2).clamp(7, 15),
          laneIndex: (laneCount - 1),
          intervalSec: 0.86,
        ),
        WaveSpawnGroup(
          kind: midKind,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 1.60,
          customBossTitle: midTitle,
        ),
      ]);
    }

    // [최종 클라이맥스 물결 (6 / 7 / 8물결)]: 심야 총공세 + 우두머리(또는 1-1 포함 2단 재변이 선봉 두목) 강림!
    final finaleWave = <WaveSpawnGroup>[
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 14).clamp(32, 66),
        laneIndex: (stage % laneCount),
        intervalSec: (0.26 - ch * 0.008).clamp(0.17, 0.26),
      ),
      WaveSpawnGroup(
        kind: ch >= 4 ? MutantKind.bloodCocoon : MutantKind.sickHound,
        count: (14 + ch * 2).clamp(15, 34),
        laneIndex: 1 % laneCount,
        intervalSec: 0.44,
      ),
      WaveSpawnGroup(
        kind: MutantKind.ironBoar,
        count: (5 + ch ~/ 2 + stage ~/ 4).clamp(5, 15),
        laneIndex: 0,
        intervalSec: 0.94,
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.plagueToad,
        count: (5 + ch ~/ 2).clamp(5, 15),
        laneIndex: (laneCount - 1),
        intervalSec: 0.86,
      ),
    ];

    if (isHeukpung) {
      finaleWave.add(
        WaveSpawnGroup(
          kind: MutantKind.raiderHeukpung,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 1.8,
          customBossTitle: '약탈 선봉 부두목 흑풍',
          customPortrait: 'budumok',
        ),
      );
    } else if (isMukhyeon) {
      finaleWave.add(
        WaveSpawnGroup(
          kind: MutantKind.rivalMukhyeon,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 1.8,
          customBossTitle: ch == 6 ? '독기에 잠식된 묵현 (최종 정화)' : '폭주하는 사형 묵현',
          customPortrait: 'mukhyeon',
        ),
      );
    } else if (isChapterBoss) {
      finaleWave.add(
        WaveSpawnGroup(
          kind: MutantKind.chapterOverlord,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 2.0,
          customBossTitle: chapter.bossName,
          customPortrait: chapter.bossPortraitPrefix,
        ),
      );
    } else {
      // 일반 관문(1-1 포함!)의 마지막 물결에도 반드시 2단 재변이 특화 두목이 지휘관으로 출전해 쫄깃한 마무리 승부 선사!
      finaleWave.add(
        WaveSpawnGroup(
          kind: stage == 1 ? MutantKind.swiftShadowBoss : secondMidKind,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 1.75,
          customBossTitle: _midBossCustomTitle(
            ch,
            stage == 1 ? MutantKind.swiftShadowBoss : secondMidKind,
          ),
        ),
      );
    }

    waves.add(finaleWave);
    return waves;
  }

  /// 제10장 보스 10연전 — 전 관문 8물결 천상 총결전!
  static List<List<WaveSpawnGroup>> _buildChapter10BossWaves(
    int stage,
    int laneCount,
    ChapterSpec refChapter,
  ) {
    final isFinal = stage == 10;
    final vanguardMidBoss = _midBossKindFor(10, stage);
    final secondMidBoss = _midBossKindFor(10, stage + 1);
    final thirdMidBoss = _midBossKindFor(10, stage + 2);
    return [
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 36 + stage * 2, laneIndex: 0, intervalSec: 0.28),
        WaveSpawnGroup(kind: MutantKind.sickHound, count: 20 + stage, laneIndex: 1 % laneCount, intervalSec: 0.38),
        WaveSpawnGroup(kind: MutantKind.shieldYacha, count: 8 + stage ~/ 2, laneIndex: laneCount - 1, intervalSec: 0.86),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 40 + stage * 2, laneIndex: (stage + 1) % laneCount, intervalSec: 0.26),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 8 + stage ~/ 2, laneIndex: 2 % laneCount, intervalSec: 0.94),
        WaveSpawnGroup(
          kind: vanguardMidBoss,
          count: 1,
          laneIndex: stage % laneCount,
          intervalSec: 1.60,
          customBossTitle: _midBossCustomTitle(10, vanguardMidBoss),
        ),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.sickHound, count: 24 + stage, laneIndex: 0, intervalSec: 0.36),
        WaveSpawnGroup(kind: MutantKind.bloodCocoon, count: 12 + stage ~/ 2, laneIndex: 3 % laneCount, intervalSec: 0.72),
        WaveSpawnGroup(kind: MutantKind.plagueToad, count: 8 + stage ~/ 2, laneIndex: 1 % laneCount, intervalSec: 0.90),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 44 + stage * 2, laneIndex: stage % laneCount, intervalSec: 0.24),
        WaveSpawnGroup(kind: MutantKind.shieldYacha, count: 10 + stage ~/ 2, laneIndex: 2 % laneCount, intervalSec: 0.82),
        WaveSpawnGroup(
          kind: secondMidBoss,
          count: 1,
          laneIndex: (stage + 2) % laneCount,
          intervalSec: 1.65,
          customBossTitle: _midBossCustomTitle(10, secondMidBoss),
        ),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.sickHound, count: 26 + stage, laneIndex: (stage + 1) % laneCount, intervalSec: 0.34),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 9 + stage ~/ 2, laneIndex: 0, intervalSec: 0.88),
        WaveSpawnGroup(kind: MutantKind.bloodCocoon, count: 13 + stage ~/ 2, laneIndex: laneCount - 1, intervalSec: 0.68),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 46 + stage * 2, laneIndex: 3 % laneCount, intervalSec: 0.23),
        WaveSpawnGroup(kind: MutantKind.plagueToad, count: 9 + stage ~/ 2, laneIndex: 1 % laneCount, intervalSec: 0.86),
        WaveSpawnGroup(
          kind: thirdMidBoss,
          count: 1,
          laneIndex: (stage + 1) % laneCount,
          intervalSec: 1.60,
          customBossTitle: _midBossCustomTitle(10, thirdMidBoss),
        ),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 48 + stage * 2, laneIndex: 0, intervalSec: 0.22),
        WaveSpawnGroup(kind: MutantKind.shieldYacha, count: 11 + stage ~/ 2, laneIndex: 1 % laneCount, intervalSec: 0.78),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 10 + stage ~/ 2, laneIndex: 2 % laneCount, intervalSec: 0.84),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 52 + stage * 2, laneIndex: (stage + 2) % laneCount, intervalSec: 0.20),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 10 + stage ~/ 2, laneIndex: 1 % laneCount, intervalSec: 0.88),
        WaveSpawnGroup(kind: MutantKind.plagueToad, count: 9 + stage ~/ 2, laneIndex: 2 % laneCount, intervalSec: 0.92),
        WaveSpawnGroup(
          kind: MutantKind.chapterOverlord,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 2.2,
          customBossTitle: isFinal ? '심야에 물든 태초 탄신' : '${refChapter.bossName} (천상 환영)',
          customPortrait: isFinal ? 'tansin' : refChapter.bossPortraitPrefix,
        ),
      ],
    ];
  }

  static List<StoryLine> _introDialogueFor(
    ChapterSpec ch,
    int st,
    bool isBoss,
    bool isHeukpung,
    bool isMukhyeon,
    CompanionHero? rescueHero,
    SpiritBeast? rescuePet,
  ) {
    if (ch.number == 1 && st == 1) {
      return const [
        StoryLine(
          speaker: '촌장',
          portraitPrefix: 'chonjang',
          text: '큰일이구나! 하늘의 태극석에 금이 가면서 산짐승들이 심야 돌연변이가 되어 열두 굽이 산비탈로 몰려오고 있다!',
        ),
        StoryLine(
          speaker: '석두',
          portraitPrefix: 'seokdu',
          text: '북중단 고지 망루(2번)에 세우면 선봉을 조기 타격하고, 남단 관문(1번)에 세우면 마을 목을 굳건히 지킵니다! 지휘를 내려주십시오!',
        ),
      ];
    }
    if (st == 1) {
      return [
        StoryLine(
          speaker: '청명',
          portraitPrefix: 'cheongmyeong',
          text: '${ch.villageName}에 도착했습니다! ${ch.storySummary}',
        ),
      ];
    }
    if (isMukhyeon) {
      if (ch.number == 3) {
        return const [
          StoryLine(
            speaker: '묵현',
            portraitPrefix: 'mukhyeon',
            text: '비켜라 사제여… 심야의 독기를 삼켜서라도 더 강한 힘을 얻어야만 세상을 구할 수 있다!',
          ),
          StoryLine(
            speaker: '청명',
            portraitPrefix: 'cheongmyeong',
            text: '사형! 독기가 검끝을 잠식하고 있어요! 정화의 수호석으로 정신을 일깨워 드려야 합니다!',
          ),
        ];
      }
      if (ch.number == 5) {
        return const [
          StoryLine(
            speaker: '묵현',
            portraitPrefix: 'mukhyeon',
            text: '크윽… 머릿속에서 마기의 속삭임이 멈추지 않는다…! 내 검을 꺾을 수 있겠느냐!!',
          ),
        ];
      }
      return const [
        StoryLine(
          speaker: '묵현',
          portraitPrefix: 'mukhyeon',
          text: '크으윽… 마을을 지키려 삼킨 독기가… 내 정신을 집어삼키려 한다…! 나를 막아라 사제여!!',
        ),
      ];
    }
    if (isHeukpung) {
      return [
        StoryLine(
          speaker: '부두목 흑풍',
          portraitPrefix: 'budumok',
          text: '크하하하! ${ch.villageName}의 식량 수레와 영약은 이 흑풍 님이 전부 약탈해 가마!!',
        ),
        const StoryLine(
          speaker: '석두',
          portraitPrefix: 'seokdu',
          text: '약탈 선봉 흑풍입니다! 3페이즈 광폭화 전에 회전 약점(🎯)을 정밀 저격해 꺾어야 합니다!',
        ),
      ];
    }
    if (rescueHero != null && !isBoss) {
      return [
        StoryLine(
          speaker: rescueHero.name,
          portraitPrefix: rescueHero.portraitPrefix,
          text: '여기는 ${rescueHero.title} ${rescueHero.name}! 열두 굽이 협곡에 변이 무리가 겹겹이 포위했습니다! 7물결만 버텨 주십시오!',
        ),
      ];
    }
    if (rescuePet != null && !isBoss) {
      return [
        StoryLine(
          speaker: '연비',
          portraitPrefix: 'yeonbi',
          text: '저기 독기 안개 속에서 신비 영수 [${rescuePet.name}]의 울음소리가 들려요! 포위망을 뚫고 구원해요!',
        ),
      ];
    }
    if (isBoss) {
      return [
        StoryLine(
          speaker: '연비',
          portraitPrefix: 'yeonbi',
          text: '밤안개가 가장 짙어졌어요! ${ch.bossName}의 8물결 본대가 열두 굽이 끝에서 다가옵니다!',
        ),
        if (rescueHero != null)
          StoryLine(
            speaker: rescueHero.name,
            portraitPrefix: rescueHero.portraitPrefix,
            text: '대수괴의 외각 장갑 핵(🎯)을 깨뜨려 주십시오! 포위망을 뚫고 즉시 합류하겠습니다!',
          ),
      ];
    }
    return const [];
  }

  static List<StoryLine> _outroDialogueFor(
    ChapterSpec ch,
    int st,
    bool isBoss,
    bool isHeukpung,
    bool isMukhyeon,
    CompanionHero? rescueHero,
    SpiritBeast? rescuePet,
  ) {
    if (isMukhyeon) {
      if (ch.number == 6) {
        return const [
          StoryLine(
            speaker: '묵현',
            portraitPrefix: 'mukhyeon',
            text: '아아… 따뜻한 기명석의 빛이 내 안의 독기를 씻어 내렸구나… 사부의 말씀이 맞았다. 이제부터 내 검은 너희와 마을을 지키는 데 쓰겠다!',
          ),
        ];
      }
      return const [
        StoryLine(
          speaker: '묵현',
          portraitPrefix: 'mukhyeon',
          text: '윽… 만만치 않군! 하지만 아직 독기의 근원은 깊다… 다음 관문에서 다시 보자!',
        ),
      ];
    }
    if (isHeukpung) {
      return [
        StoryLine(
          speaker: '부두목 흑풍',
          portraitPrefix: 'budumok',
          text: '크악! 이놈들의 지형 진법과 약점 저격에 당하다니… 수레는 두고 후퇴다!!',
        ),
      ];
    }
    if (!isBoss && rescueHero != null) {
      return [
        StoryLine(
          speaker: rescueHero.name,
          portraitPrefix: rescueHero.portraitPrefix,
          text: '구원해 주셔서 감사합니다! 이제부터 저 ${rescueHero.title} [${rescueHero.name}]의 무공(${rescueHero.skillDesc})으로 수호진을 함께 지키겠습니다!',
        ),
      ];
    }
    if (!isBoss && rescuePet != null) {
      return [
        StoryLine(
          speaker: '청명',
          portraitPrefix: 'cheongmyeong',
          text: '해냈습니다! 독기가 걷히며 신비 영수 [${rescuePet.name}]가 감응하여 우리 수호진과 계약을 맺었습니다! (${rescuePet.battleCry})',
        ),
      ];
    }
    if (!isBoss) return const [];
    final bossOutro = <StoryLine>[];
    switch (ch.number) {
      case 1:
        bossOutro.add(
          const StoryLine(
            speaker: '촌장',
            portraitPrefix: 'chonjang',
            text: '장하다! 우리 흙먼지 마을은 지켰으나 아랫마을 통통 객잔 곡식 창고가 무너지면 모두가 굶게 된다. 이 의용대 지원패를 들고 구원하러 가거라!',
          ),
        );
        break;
      case 2:
        bossOutro.add(
          const StoryLine(
            speaker: '통통',
            portraitPrefix: 'tongtong',
            text: '하하하! 덕분이다! 객잔 곡식 창고가 무사하니 지금 바로 흙먼지 마을로 첫 식량·영약 호송 마차를 출발시키마!',
          ),
        );
        break;
      case 4:
        bossOutro.add(
          const StoryLine(
            speaker: '쿠비',
            portraitPrefix: 'kubi',
            text: '산채 목재와 봉화대를 되찾았다! 이제 우리 산채 정찰대가 밤마다 산야를 돌며 영약과 지원패를 찾아오겠다!',
          ),
        );
        break;
      case 6:
        bossOutro.add(
          const StoryLine(
            speaker: '무림맹주',
            portraitPrefix: 'maengju',
            text: '여섯 거점의 무사들을 묶어 「무림수호단」을 창설한다! 이 황금 지원패를 들면 언제든 전군이 달려와 돌연변이를 싹 쓸어버릴 것이다!',
          ),
        );
        break;
      default:
        bossOutro.add(
          StoryLine(
            speaker: '청명',
            portraitPrefix: 'cheongmyeong',
            text: '새벽해가 밝았습니다! ${ch.villageName}의 논밭과 외양간이 다시 살아나고 있습니다! (${ch.unlockNotice})',
          ),
        );
    }
    if (rescueHero != null) {
      bossOutro.add(
        StoryLine(
          speaker: rescueHero.name,
          portraitPrefix: rescueHero.portraitPrefix,
          text: '저 [${rescueHero.name}]도 오늘부터 수호진의 일원으로 끝까지 동행하겠습니다!',
        ),
      );
    } else if (rescuePet != null) {
      bossOutro.add(
        StoryLine(
          speaker: '연비',
          portraitPrefix: 'yeonbi',
          text: '신비 영수 [${rescuePet.name}]도 정화되어 우리 곁으로 날아왔어요!',
        ),
      );
    }
    return bossOutro;
  }

  static const List<StoryLine> epilogueDialogue = [
    StoryLine(
      speaker: '태초 탄신',
      portraitPrefix: 'tansin',
      text: '고맙구나… 그대들이 지켜낸 정화의 알이 태극석의 금을 완전히 이었도다. 이제 심야의 독기는 영원히 걷혔다!',
    ),
    StoryLine(
      speaker: '촌장',
      portraitPrefix: 'chonjang',
      text: '보거라! 지나온 아홉 마을의 시들었던 논밭마다 푸른 벼가 물결치고, 외양간에 건강한 송아지 울음소리가 가득하구나!',
    ),
    StoryLine(
      speaker: '묵현',
      portraitPrefix: 'mukhyeon',
      text: '보따리를 메고 떠났던 사람들도 모두 고향 마당으로 돌아오고 있다. …자, 이제 싸움이 아니라 마음 편히 웃으며 한 판 두자꾸나!',
    ),
  ];
}
