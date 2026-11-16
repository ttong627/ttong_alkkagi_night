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

/// 발사대 설치 거점 좌표.
class LauncherMountSlot {
  const LauncherMountSlot({
    required this.slotIndex,
    required this.pos,
    required this.recommendedType,
  });

  final int slotIndex;
  final Vec2 pos;
  final LauncherType recommendedType;
}

/// 난이도 3단계.
enum DefenseDifficulty {
  easy(
    id: 'easy',
    name: '쉬움 · 마을 지킴이',
    hpMult: 0.78,
    speedMult: 0.90,
    rewardMult: 1.0,
    summary: '여유로운 호흡으로 스토리와 자동 발사 진법을 즐기는 난이도',
  ),
  normal(
    id: 'normal',
    name: '보통 · 강호 수호자',
    hpMult: 1.00,
    speedMult: 1.00,
    rewardMult: 1.25,
    summary: '길목 발사대와 알 상성을 맞추며 깨는 표준 난이도 (보상 +25%)',
  ),
  nightmare(
    id: 'nightmare',
    name: '악몽 · 심야 혈전',
    hpMult: 1.68,
    speedMult: 1.16,
    rewardMult: 1.65,
    summary: '정교한 진법과 내공·영수 성장이 요구되는 고수용 도전 (보상 +65%)',
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

  /// 이 관문에서 배치 가능한 길목 초소 발판 수 (1-1의 2곳에서 시작해 10장 결전의 10곳까지 점진적 확장!).
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

  /// 제어점 배열을 3차 카트멀-롬 스플라인(Catmull-Rom Cubic Spline)과 등간격(7px) 샘플링으로 보간하여
  /// 돌연변이들이 꺾임 없이 물 흐르듯 부드럽게 휘돌아 내려오는 연속 곡선 경로를 생성한다.
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
              (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3);
      return Vec2(x.clamp(22.0, CampaignCatalog.arenaWidth - 22.0), y);
    }

    final dense = <Vec2>[];
    for (int i = 0; i < raw.length - 1; i++) {
      final p0 = i == 0 ? raw[0] : raw[i - 1];
      final p1 = raw[i];
      final p2 = raw[i + 1];
      final p3 = (i + 2 < raw.length) ? raw[i + 2] : raw.last;
      final segLen = p1.distanceTo(p2);
      final subSteps = math.max(6, (segLen / 6.5).ceil());
      for (int s = 0; s < subSteps; s++) {
        dense.add(catmullRom(p0, p1, p2, p3, s / subSteps));
      }
    }
    dense.add(raw.last);

    // 등간격(7.0px)으로 한 번 더 정돈하여 코너에서 속도가 빨라지거나 느려지는 현상 제거
    final uniform = <Vec2>[dense.first];
    double acc = 0.0;
    for (int i = 1; i < dense.length; i++) {
      final d = dense[i].distanceTo(uniform.last);
      acc += d;
      if (acc >= 7.0 || i == dense.length - 1) {
        uniform.add(dense[i]);
        acc = 0.0;
      }
    }
    return uniform;
  }
}

/// 《수호알까기 · 탄지무림 심야기습》 1~10장(총 111단계) 전체 캠페인 생성기.
class CampaignCatalog {
  static const double arenaWidth = 400.0;
  static const double arenaHeight = 680.0;
  /// 맨 아래 마을 어귀 정중앙 주 발사대(자동·수동 겸용 중앙 기명 수호탑) 좌표.
  static const Vec2 centralTowerPos = Vec2(200.0, 580.0);
  /// 맨 아래 마을 본진 보호 결계 중심 (식량창고·논밭·외양간을 감싸는 남단 반구형 수호진).
  static const Vec2 villageCenter = Vec2(200.0, 616.0);
  static const double outerShieldRadius = 82.0;
  static const double centralTowerRadius = 25.0;

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
          '태극석 균열로 쏟아진 심야 독기 속에 돌연변이 무리가 위쪽 산비탈 굽이길을 따라 맨 아래 흙먼지 마을로 쳐들어온다! 중앙 수호탑과 길목 빈 초소 배치를 지휘해 식량·논밭·가축을 지켜내라!',
      unlockNotice: '기명 심법 수련 개방 · 첫째 문양(각성) · 의용대 지원패 전수',
      surfaceFriction: 1.05,
      stageCount: 10,
      lanes: const [
        [
          Vec2(68, 28),
          Vec2(150, 94),
          Vec2(62, 178),
          Vec2(154, 266),
          Vec2(72, 364),
          Vec2(156, 456),
          Vec2(186, 526),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(332, 28),
          Vec2(250, 94),
          Vec2(338, 178),
          Vec2(246, 266),
          Vec2(328, 364),
          Vec2(244, 456),
          Vec2(214, 526),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 392), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(118, 316), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(282, 316), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(200, 140), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(112, 222), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(288, 222), recommendedType: LauncherType.heavy),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 304), radius: 17, sides: 4, rotationSpeedRad: 0.9, restitutionBoost: 1.35),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 275), radius: 30, label: '서쪽 산비탈 절벽'),
        CliffZone(center: Vec2(382, 275), radius: 30, label: '동쪽 산비탈 절벽'),
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
          '피난민들이 모인 통통 객잔의 대곡식 창고를 탐식 변이 대군이 좌우 대교차 비탈길로 덮친다! 구불구불한 기름길 굽이에 발사대를 세워 첫 식량 호송 수레를 띄워라!',
      unlockNotice: '물자 호송 시스템 정식 개통 · 동료 반달 합류 · 곡사 회전기 개방',
      surfaceFriction: 0.72,
      stageCount: 11,
      lanes: const [
        [
          Vec2(62, 28),
          Vec2(186, 88),
          Vec2(314, 154),
          Vec2(246, 246),
          Vec2(88, 324),
          Vec2(146, 432),
          Vec2(188, 524),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(338, 28),
          Vec2(214, 88),
          Vec2(86, 154),
          Vec2(154, 246),
          Vec2(312, 324),
          Vec2(254, 432),
          Vec2(212, 524),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 376), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(200, 188), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(102, 242), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(298, 242), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(94, 468), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(306, 468), recommendedType: LauncherType.heavy),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(66, 232), radius: 16, sides: 6, rotationSpeedRad: 1.2, restitutionBoost: 1.42),
        TerrainPillar(center: Vec2(334, 232), radius: 16, sides: 6, rotationSpeedRad: -1.2, restitutionBoost: 1.42),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 355), radius: 30, label: '객잔 뒤편 계곡'),
        CliffZone(center: Vec2(382, 355), radius: 30, label: '장독대 낭떠러지'),
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
          '봄에 뿌릴 씨앗과 어미 가축들이 모인 거북 장터에 밤비가 내리고, 독기에 손댄 사형 묵현(1차)과 그림자 변이 무리가 얽히고설킨 세 갈래 장터 골목으로 침투한다!',
      unlockNotice: '전국 호송망 확장 · 영수 영귀 금강 개방 · 한빙 역장기 개방',
      surfaceFriction: 0.92,
      stageCount: 11,
      lanes: const [
        [
          Vec2(58, 28),
          Vec2(58, 114),
          Vec2(142, 168),
          Vec2(68, 258),
          Vec2(144, 350),
          Vec2(92, 438),
          Vec2(178, 524),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(200, 26),
          Vec2(264, 102),
          Vec2(138, 198),
          Vec2(262, 296),
          Vec2(146, 396),
          Vec2(200, 488),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(342, 28),
          Vec2(342, 114),
          Vec2(258, 168),
          Vec2(332, 258),
          Vec2(256, 350),
          Vec2(308, 438),
          Vec2(222, 524),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(204, 346), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(106, 212), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(294, 212), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(146, 468), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(254, 468), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(194, 144), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 246), radius: 17, sides: 5, rotationSpeedRad: 1.1, restitutionBoost: 1.38),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 290), radius: 28, label: '장터 수로 낭떠러지'),
        CliffZone(center: Vec2(382, 290), radius: 28, label: '성벽 아래 해자'),
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
          '각 마을 수호탑 보급에 필요한 천년 목재와 산길 봉화대를 되찾기 위해 쿠비 산채로 향한다. 아홉 굽이 숲길 고비마다 초소를 세워 산채 두목 쿠비를 구출하라!',
      unlockNotice: '심야 탐색 시스템 정식 개통 · 둘째 문양(동행) · 동료 구르미 합류',
      surfaceFriction: 1.00,
      stageCount: 12,
      lanes: const [
        [
          Vec2(64, 28),
          Vec2(148, 86),
          Vec2(72, 172),
          Vec2(156, 258),
          Vec2(78, 358),
          Vec2(152, 452),
          Vec2(186, 526),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(200, 26),
          Vec2(152, 118),
          Vec2(248, 206),
          Vec2(156, 308),
          Vec2(244, 404),
          Vec2(200, 496),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(336, 28),
          Vec2(252, 86),
          Vec2(328, 172),
          Vec2(244, 258),
          Vec2(322, 358),
          Vec2(248, 452),
          Vec2(214, 526),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 356), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(198, 162), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(116, 408), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(284, 408), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(112, 128), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(288, 128), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(200, 462), recommendedType: LauncherType.frostField),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(96, 258), radius: 16, sides: 3, rotationSpeedRad: 1.4, restitutionBoost: 1.44),
        TerrainPillar(center: Vec2(304, 258), radius: 16, sides: 3, rotationSpeedRad: -1.4, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 325), radius: 30, label: '산채 천길 벼랑'),
        CliffZone(center: Vec2(382, 325), radius: 30, label: '구름다리 절벽'),
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
          '중갑 변이체를 뚫을 고대 기관술의 본산 로직 학당! 꺾여 도는 기관 미궁 회랑에서 흔들리는 눈빛의 묵현(2차)을 넘어 내공 증폭기와 자동 어기어석의 비전을 열어라!',
      unlockNotice: '내공 증폭기 개방 · 셋째 문양(자동 어기어석) · 동료 정각 합류',
      surfaceFriction: 0.80,
      stageCount: 11,
      lanes: const [
        [
          Vec2(64, 28),
          Vec2(64, 132),
          Vec2(156, 152),
          Vec2(156, 248),
          Vec2(74, 288),
          Vec2(74, 396),
          Vec2(166, 468),
          Vec2(190, 528),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(200, 26),
          Vec2(258, 96),
          Vec2(142, 188),
          Vec2(258, 284),
          Vec2(142, 378),
          Vec2(200, 472),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(336, 28),
          Vec2(336, 132),
          Vec2(244, 152),
          Vec2(244, 248),
          Vec2(326, 288),
          Vec2(326, 396),
          Vec2(234, 468),
          Vec2(210, 528),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 332), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(122, 342), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(278, 342), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(200, 236), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(116, 94), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(284, 94), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(114, 434), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(286, 434), recommendedType: LauncherType.frostField),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(106, 214), radius: 16, sides: 8, rotationSpeedRad: 1.25, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(294, 214), radius: 16, sides: 8, rotationSpeedRad: -1.25, restitutionBoost: 1.45),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 250), radius: 28, label: '학당 서쪽 연못 해자'),
        CliffZone(center: Vec2(382, 250), radius: 28, label: '학당 동쪽 절벽'),
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
          '혹한의 밤, 네 갈래 굽이치는 계단 회랑으로 밀려드는 대군 속에서 묵현(3차)을 정화 탄지로 구원하고 맹주와 함께 흑화 마룡수를 격파하라!',
      unlockNotice: '황금 지원패(무림수호단 출두야~~!!) 완성 · 동료 용아 및 위기 난입 묵현 합류',
      surfaceFriction: 0.76,
      stageCount: 12,
      lanes: const [
        [
          Vec2(52, 28),
          Vec2(118, 98),
          Vec2(62, 192),
          Vec2(134, 282),
          Vec2(78, 382),
          Vec2(156, 472),
          Vec2(188, 530),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(152, 26),
          Vec2(228, 108),
          Vec2(154, 208),
          Vec2(226, 312),
          Vec2(162, 416),
          Vec2(194, 512),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(248, 26),
          Vec2(172, 108),
          Vec2(246, 208),
          Vec2(174, 312),
          Vec2(238, 416),
          Vec2(206, 512),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(348, 28),
          Vec2(282, 98),
          Vec2(338, 192),
          Vec2(266, 282),
          Vec2(322, 382),
          Vec2(244, 472),
          Vec2(212, 530),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 364), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(118, 336), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(282, 336), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(104, 148), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(296, 148), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(200, 258), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(114, 444), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(286, 444), recommendedType: LauncherType.heavy),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 158), radius: 17, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.45),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 330), radius: 28, label: '본단 빙벽 협곡'),
        CliffZone(center: Vec2(382, 330), radius: 28, label: '본단 화염 구렁'),
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
          '서쪽 독기의 기둥을 쫓아 도착한 열사의 협곡! 거대한 모래언덕을 뱀처럼 감아 내려오는 협곡길을 틀어막고 사막 백성들의 오아시스를 지켜내라!',
      unlockNotice: '4형(극의) 발사대 제련 완성 · 천마 화신 영입 개방',
      surfaceFriction: 1.15,
      stageCount: 11,
      lanes: const [
        [
          Vec2(58, 28),
          Vec2(154, 92),
          Vec2(66, 184),
          Vec2(158, 276),
          Vec2(72, 376),
          Vec2(156, 466),
          Vec2(188, 528),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(200, 26),
          Vec2(268, 112),
          Vec2(132, 216),
          Vec2(268, 322),
          Vec2(144, 424),
          Vec2(200, 508),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(342, 28),
          Vec2(246, 92),
          Vec2(334, 184),
          Vec2(242, 276),
          Vec2(328, 376),
          Vec2(244, 466),
          Vec2(212, 528),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 372), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(122, 328), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(278, 328), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(200, 164), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(108, 138), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(292, 138), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(114, 436), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(286, 436), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(200, 268), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(106, 232), radius: 16, sides: 4, rotationSpeedRad: 1.3, restitutionBoost: 1.40),
        TerrainPillar(center: Vec2(294, 232), radius: 16, sides: 4, rotationSpeedRad: -1.3, restitutionBoost: 1.40),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 305), radius: 30, label: '모래 소용돌이 구렁'),
        CliffZone(center: Vec2(382, 305), radius: 30, label: '협곡 낭떠러지'),
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
          '굶주린 바닷가 마을들에 구호 곡식을 나르는 해적왕의 함대! 출렁이는 연결 판자 다리를 타고 넘어오는 심해 괴수 떼를 뱃전 도탄으로 바다에 빠뜨려라!',
      unlockNotice: '영수 천룡 금룡 개방 · 동료 검황 영입 개방',
      surfaceFriction: 0.84,
      stageCount: 11,
      lanes: const [
        [
          Vec2(66, 28),
          Vec2(142, 104),
          Vec2(66, 198),
          Vec2(148, 288),
          Vec2(76, 386),
          Vec2(160, 472),
          Vec2(188, 528),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(200, 26),
          Vec2(136, 118),
          Vec2(264, 212),
          Vec2(136, 314),
          Vec2(260, 412),
          Vec2(200, 504),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(334, 28),
          Vec2(258, 104),
          Vec2(334, 198),
          Vec2(252, 288),
          Vec2(324, 386),
          Vec2(240, 472),
          Vec2(212, 528),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 362), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(114, 342), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(286, 342), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(200, 262), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(106, 152), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(294, 152), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(114, 442), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(286, 442), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(200, 86), recommendedType: LauncherType.curveSpin),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 162), radius: 17, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.48),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 285), radius: 30, label: '좌현 검푸른 밤바다'),
        CliffZone(center: Vec2(382, 285), radius: 30, label: '우현 소용돌이 바다'),
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
          '대지에서 독기가 치솟는 화염산 분화구! 구불구불 휘감아 내려오는 네 갈래 용암 바위길의 변이 대군을 분화구 절벽 아래로 밀어 넣어 천상 계단을 열어라!',
      unlockNotice: '한철·신물 수호석 제련 극대화 · 동료 무량 신승 개방 · 천상 계단 개통',
      surfaceFriction: 0.90,
      stageCount: 12,
      lanes: const [
        [
          Vec2(52, 28),
          Vec2(124, 96),
          Vec2(64, 188),
          Vec2(136, 278),
          Vec2(78, 378),
          Vec2(156, 468),
          Vec2(188, 528),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(152, 26),
          Vec2(228, 106),
          Vec2(156, 204),
          Vec2(228, 306),
          Vec2(162, 412),
          Vec2(194, 508),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(248, 26),
          Vec2(172, 106),
          Vec2(244, 204),
          Vec2(172, 306),
          Vec2(238, 412),
          Vec2(206, 508),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(348, 28),
          Vec2(276, 96),
          Vec2(336, 188),
          Vec2(264, 278),
          Vec2(322, 378),
          Vec2(244, 468),
          Vec2(212, 528),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 358), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(122, 332), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(278, 332), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(200, 254), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(104, 144), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(296, 144), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(112, 438), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(288, 438), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(198, 92), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(200, 456), recommendedType: LauncherType.qiAmplifier),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(106, 232), radius: 16, sides: 5, rotationSpeedRad: 1.6, restitutionBoost: 1.46),
        TerrainPillar(center: Vec2(294, 232), radius: 16, sides: 5, rotationSpeedRad: -1.6, restitutionBoost: 1.46),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 325), radius: 30, label: '서쪽 용암 분화구'),
        CliffZone(center: Vec2(382, 325), radius: 30, label: '동쪽 용암 절벽'),
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
          '구름 위 천상 탄신전! 태극 문양으로 휘돌아 내려오는 천상 회랑에서 1~9장 우두머리 환영을 9연속 정화하고, 마지막 10단계에서 태초 탄신을 구원하라!',
      unlockNotice: '열 마을 완전 정화 대단원 귀향 엔딩 · 수호신 칭호 획득',
      surfaceFriction: 0.82,
      stageCount: 10,
      lanes: const [
        [
          Vec2(54, 28),
          Vec2(132, 94),
          Vec2(66, 184),
          Vec2(142, 274),
          Vec2(80, 376),
          Vec2(158, 468),
          Vec2(188, 528),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(154, 26),
          Vec2(236, 104),
          Vec2(152, 204),
          Vec2(234, 306),
          Vec2(160, 412),
          Vec2(194, 508),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(246, 26),
          Vec2(164, 104),
          Vec2(248, 204),
          Vec2(166, 306),
          Vec2(240, 412),
          Vec2(206, 508),
          centralTowerPos,
          villageCenter,
        ],
        [
          Vec2(346, 28),
          Vec2(268, 94),
          Vec2(334, 184),
          Vec2(258, 274),
          Vec2(320, 376),
          Vec2(242, 468),
          Vec2(212, 528),
          centralTowerPos,
          villageCenter,
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 358), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(122, 330), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(278, 330), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(200, 254), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(102, 142), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(298, 142), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(112, 438), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(288, 438), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(200, 84), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(200, 454), recommendedType: LauncherType.qiAmplifier),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 154), radius: 17, sides: 8, rotationSpeedRad: 1.7, restitutionBoost: 1.50),
        TerrainPillar(center: Vec2(106, 228), radius: 15, sides: 6, rotationSpeedRad: -1.4, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(294, 228), radius: 15, sides: 6, rotationSpeedRad: 1.4, restitutionBoost: 1.45),
      ],
      cliffs: const [
        CliffZone(center: Vec2(18, 308), radius: 30, label: '천상 운해 낭떠러지'),
        CliffZone(center: Vec2(382, 308), radius: 30, label: '은하 절벽'),
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

  /// 관문이 진행될수록 배치 가능한 길목 초소 장소가 2곳에서 10곳까지 점진적으로 늘어난다!
  static int _maxMountCountFor(int ch, int st) {
    switch (ch) {
      case 1:
        if (st <= 3) return 2;
        if (st <= 7) return 3;
        return 4;
      case 2:
        return st <= 5 ? 4 : 5;
      case 3:
        return st <= 5 ? 5 : 6;
      case 4:
        return st <= 6 ? 6 : 7;
      case 5:
        return st <= 5 ? 7 : 8;
      case 6:
        return st <= 6 ? 7 : 8;
      case 7:
        return st <= 5 ? 8 : 9;
      case 8:
        return st <= 5 ? 8 : 9;
      case 9:
        return st <= 6 ? 9 : 10;
      default:
        return st <= 4 ? 9 : 10;
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
        // 10장은 원작과 동일한 보스 10연전(1~9장 심야 환영 보스 + 10단계 태초 탄신)!
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
                  ? '태극석의 균열을 메워 열 마을의 논밭과 생명을 되살려라! (초소 $mountCap곳 총동원)'
                  : '${refChapter.villageName} 우두머리의 심야 환영 결전 · 배치 초소 $mountCap곳 개방',
              tacticalHint: isFinalGod
                  ? '열 곳의 초소 발판에 내공 증폭기 + 중포·한빙·곡사·속사를 촘촘히 세워 최후의 대군단을 정화하세요!'
                  : '네 갈래 천상 회랑의 굽이마다 초소를 확장 배치하고 우두머리를 집중 타격하세요!',
              recommendedStone: StoneMaterial.values[(st + 2).clamp(0, 12)],
              recommendedLaunchers: const [
                LauncherType.qiAmplifier,
                LauncherType.heavy,
                LauncherType.frostField,
                LauncherType.curveSpin,
                LauncherType.rapid,
              ],
              startingFieldTokens: 105 + st * 5,
              clearElixirBonus: isFinalGod ? 10 : 4,
              isBossStage: true,
              maxMountCount: mountCap,
              waves: _buildChapter10BossWaves(st, laneCount, refChapter),
              introDialogue: st == 1
                  ? const [
                      StoryLine(
                        speaker: '무림맹주',
                        portraitPrefix: 'maengju',
                        text: '여기가 구름 위 천상 탄신전이다! 심야의 독기가 지금까지의 우두머리 환영 아홉을 세워 길을 막고 있구나!',
                      ),
                      StoryLine(
                        speaker: '묵현',
                        portraitPrefix: 'mukhyeon',
                        text: '아홉에서 열 곳까지 열린 천상 초소들을 빠짐없이 장악하면 반드시 뚫을 수 있다. 가자!',
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
                            text: '열 마을 백성들의 염원이 모두 네 수호탑에 모여 있다! 마지막 밤을 밝혀라!',
                          ),
                        ]
                      : const [],
              outroDialogue: isFinalGod ? epilogueDialogue : const [],
            ),
          );
        }
        continue;
      }

      // 1~9장 각 10~12단계 생성
      for (int st = 1; st <= ch.stageCount; st++) {
        globalIdx++;
        final isChapterBoss = st == ch.stageCount;
        final isHeukpungStage = st == ch.stageCount - 1;
        final isMukhyeonStage = (ch.number == 3 || ch.number == 5 || ch.number == 6) && st == (ch.stageCount ~/ 2);
        final mountCap = _maxMountCountFor(ch.number, st).clamp(1, ch.mounts.length);
        final rescueHero = _rescueCompanionFor(ch.number, st);
        final rescuePet = _rescueBeastFor(ch.number, st);
        final rescuesMukhyeon = ch.number == 6 && st == 12;

        String stageTitle;
        String sub;
        if (isChapterBoss) {
          stageTitle = '${ch.number}-$st 결전 · ${ch.bossName}';
          sub = '${ch.villageName} 최종 심야 방어전 (초소 $mountCap곳)';
        } else if (isHeukpungStage) {
          stageTitle = '${ch.number}-$st 약탈 저지 · 부두목 흑풍';
          sub = '식량 수레를 노리는 약탈 선봉장 흑풍 격퇴 (초소 $mountCap곳)';
        } else if (isMukhyeonStage) {
          stageTitle = '${ch.number}-$st 숙적 조우 · 사형 묵현';
          sub = ch.number == 6
              ? '독기에 삼켜진 묵현을 정화 탄지로 구원하라! (초소 $mountCap곳)'
              : '폭주하는 사형 묵현의 야간 기습! (초소 $mountCap곳)';
        } else if (rescueHero != null) {
          stageTitle = '${ch.number}-$st 구출 작전 · 동료 ${rescueHero.name}';
          sub = '고립된 ${rescueHero.title} [${rescueHero.name}] 구출 및 길목 사수! (초소 $mountCap곳)';
        } else if (rescuePet != null) {
          stageTitle = '${ch.number}-$st 영수 구출 · ${rescuePet.name}';
          sub = '독기 포위망에 갇힌 신비 영수 [${rescuePet.name}] 구원 작전! (초소 $mountCap곳)';
        } else {
          stageTitle = '${ch.number}-$st 야간 길목 수호 ($st차 밤)';
          if (st >= 2) {
            final midKind = _midBossKindFor(ch.number, st);
            sub = '${ch.villageName} 방어 (초소 $mountCap곳) · 중간보스 [${midKind.name}] 동반 침략!';
          } else {
            sub = '${ch.villageName} 산비탈 굽이길 방어 · 배치 초소 $mountCap곳 개방';
          }
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
            startingFieldTokens: 48 + (ch.number - 1) * 5,
            clearElixirBonus: isChapterBoss
                ? 5
                : ((isHeukpungStage || isMukhyeonStage || rescueHero != null || rescuePet != null) ? 3 : 1),
            isBossStage: isChapterBoss || isHeukpungStage || isMukhyeonStage,
            maxMountCount: mountCap,
            rescueCompanion: rescueHero,
            rescueBeast: rescuePet,
            alsoRescuesMukhyeon: rescuesMukhyeon,
            waves: _buildNormalChapterWaves(
              chapter: ch,
              stage: st,
              laneCount: laneCount,
              isChapterBoss: isChapterBoss,
              isHeukpung: isHeukpungStage,
              isMukhyeon: isMukhyeonStage,
            ),
            introDialogue: _introDialogueFor(ch, st, isChapterBoss, isMukhyeonStage),
            outroDialogue: _outroDialogueFor(ch, st, isChapterBoss, isMukhyeonStage),
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
      return '제2물결 특화 중간보스에 이어 최종 우두머리가 강림합니다! 내공·한빙 보조와 중포 승급으로 돌파하세요!';
    }
    if (heukpung) {
      return '중간보스 기습 뒤 약탈 선봉 흑풍이 돌격합니다. 중포 탄지기와 석두·영수 방어 조건을 활용하세요!';
    }
    if (st >= 2) {
      final mid = _midBossKindFor(ch, st);
      if (mid == MutantKind.swiftShadowBoss) {
        return '초고속 기습 중간보스 [혈영 질풍귀]가 고속 무리와 동반 침략합니다! 한빙 역장기와 속사 탄지기로 기동력을 꺾으세요!';
      } else if (mid == MutantKind.ironColossusBoss) {
        return '난공불락 맷집 중간보스 [현철 중갑거수]가 중갑 무리와 함께 진격합니다! 중포 탄지기와 무거운 수호석으로 장갑을 반관통하세요!';
      } else {
        return '파성 강타 중간보스 [적염 파성귀]가 방어막을 노리고 강습합니다! 방어막 접근 전 내공탄과 어기어석으로 집중 타격하세요!';
      }
    }
    return '속사 탄지기로 독쥐·들개 무리를 빠르게 정리해 현장 증표를 모으고 발사대 버전을 올리세요!';
  }

  static List<List<WaveSpawnGroup>> _buildNormalChapterWaves({
    required ChapterSpec chapter,
    required int stage,
    required int laneCount,
    required bool isChapterBoss,
    required bool isHeukpung,
    required bool isMukhyeon,
  }) {
    final ch = chapter.number;
    final swarmCount = 22 + ch * 3 + stage * 2;
    final mediumCount = (5 + ch ~/ 2 + stage ~/ 2).clamp(5, 18);
    final waves = <List<WaveSpawnGroup>>[];

    // 1웨이브: 심야 선봉 대군 쇄도 (약 9.5~11초간 사방 균열문에서 변이 무리가 까맣게 쏟아져 긴장감 형성!)
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: swarmCount,
        laneIndex: 0,
        intervalSec: (0.40 - ch * 0.010).clamp(0.24, 0.40),
      ),
      WaveSpawnGroup(
        kind: MutantKind.sickHound,
        count: (swarmCount * 0.62).round().clamp(12, 34),
        laneIndex: 1 % laneCount,
        intervalSec: (0.50 - ch * 0.012).clamp(0.32, 0.50),
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.bloodCocoon,
        count: (mediumCount - 1).clamp(4, 14),
        laneIndex: 2 % laneCount,
        intervalSec: 0.96,
      ),
    ]);

    // 2웨이브: 중견 대군 기습 — 2단계 이상 모든 스테이지에서 스피드·맷집·공격력 특화 중간보스가 대규모 변이 군단과 동반 침략!
    if (stage >= 2) {
      final midKind = _midBossKindFor(ch, stage);
      final midTitle = _midBossCustomTitle(ch, midKind);
      final bossLane = (stage + 1) % laneCount;

      if (midKind == MutantKind.swiftShadowBoss) {
        waves.add([
          WaveSpawnGroup(
            kind: MutantKind.sickHound,
            count: (15 + ch * 2 + stage).clamp(15, 38),
            laneIndex: stage % laneCount,
            intervalSec: 0.36,
          ),
          WaveSpawnGroup(
            kind: MutantKind.swarmRat,
            count: (swarmCount + 6).clamp(24, 52),
            laneIndex: (stage + 2) % laneCount,
            intervalSec: 0.28,
          ),
          WaveSpawnGroup(
            kind: ch >= 2 ? MutantKind.ironBoar : MutantKind.bloodCocoon,
            count: (4 + ch ~/ 2).clamp(4, 12),
            laneIndex: (stage + 1) % laneCount,
            intervalSec: 1.05,
          ),
          WaveSpawnGroup(
            kind: MutantKind.swiftShadowBoss,
            count: 1,
            laneIndex: bossLane,
            intervalSec: 1.60,
            customBossTitle: midTitle,
          ),
        ]);
      } else if (midKind == MutantKind.ironColossusBoss) {
        waves.add([
          WaveSpawnGroup(
            kind: MutantKind.swarmRat,
            count: (swarmCount + 4).clamp(22, 48),
            laneIndex: (stage + 1) % laneCount,
            intervalSec: 0.30,
          ),
          WaveSpawnGroup(
            kind: ch >= 2 ? MutantKind.ironBoar : MutantKind.sickHound,
            count: (6 + ch ~/ 2 + stage ~/ 3).clamp(6, 16),
            laneIndex: stage % laneCount,
            intervalSec: 0.88,
          ),
          WaveSpawnGroup(
            kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.bloodCocoon,
            count: (7 + ch ~/ 2).clamp(7, 16),
            laneIndex: (stage + 2) % laneCount,
            intervalSec: 0.84,
          ),
          WaveSpawnGroup(
            kind: MutantKind.ironColossusBoss,
            count: 1,
            laneIndex: bossLane,
            intervalSec: 1.75,
            customBossTitle: midTitle,
          ),
        ]);
      } else {
        waves.add([
          WaveSpawnGroup(
            kind: MutantKind.swarmRat,
            count: (swarmCount + 4).clamp(22, 48),
            laneIndex: (stage + 1) % laneCount,
            intervalSec: 0.30,
          ),
          WaveSpawnGroup(
            kind: ch >= 3 ? MutantKind.bloodCocoon : MutantKind.sickHound,
            count: (10 + ch + stage ~/ 3).clamp(10, 24),
            laneIndex: stage % laneCount,
            intervalSec: 0.62,
          ),
          WaveSpawnGroup(
            kind: ch >= 2 ? MutantKind.plagueToad : MutantKind.ironBoar,
            count: (5 + ch ~/ 2).clamp(5, 14),
            laneIndex: (stage + 2) % laneCount,
            intervalSec: 0.94,
          ),
          WaveSpawnGroup(
            kind: MutantKind.crimsonBreakerBoss,
            count: 1,
            laneIndex: bossLane,
            intervalSec: 1.65,
            customBossTitle: midTitle,
          ),
        ]);
      }
    } else {
      waves.add([
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: swarmCount + 6,
          laneIndex: ((stage + 1) % laneCount),
          intervalSec: 0.32,
        ),
        WaveSpawnGroup(
          kind: MutantKind.sickHound,
          count: (14 + ch * 2).clamp(14, 32),
          laneIndex: (stage % laneCount),
          intervalSec: 0.46,
        ),
        WaveSpawnGroup(
          kind: MutantKind.ironBoar,
          count: (4 + ch ~/ 3).clamp(4, 9),
          laneIndex: 1 % laneCount,
          intervalSec: 1.18,
        ),
      ]);
    }

    // 3웨이브: 다방면 포위 압박 총쇄도!
    final thirdWave = <WaveSpawnGroup>[
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 8).clamp(26, 56),
        laneIndex: ((stage + 2) % laneCount),
        intervalSec: (0.30 - ch * 0.008).clamp(0.20, 0.30),
      ),
      WaveSpawnGroup(
        kind: MutantKind.sickHound,
        count: (13 + ch * 2 + stage ~/ 2).clamp(14, 36),
        laneIndex: ((stage + 1) % laneCount),
        intervalSec: 0.42,
      ),
      WaveSpawnGroup(
        kind: ch >= 3 ? MutantKind.plagueToad : MutantKind.bloodCocoon,
        count: (5 + ch ~/ 2).clamp(5, 14),
        laneIndex: (stage % laneCount),
        intervalSec: 0.92,
      ),
      if (ch >= 2)
        WaveSpawnGroup(
          kind: MutantKind.shieldYacha,
          count: (5 + ch ~/ 2).clamp(5, 14),
          laneIndex: (laneCount - 1),
          intervalSec: 0.88,
        ),
    ];
    if (ch >= 6 && stage >= 4) {
      final secondMid = _midBossKindFor(ch + 1, stage + 1);
      thirdWave.add(
        WaveSpawnGroup(
          kind: secondMid,
          count: 1,
          laneIndex: (stage + 2) % laneCount,
          intervalSec: 1.70,
          customBossTitle: _midBossCustomTitle(ch, secondMid),
        ),
      );
    }
    waves.add(thirdWave);

    // 4웨이브: 심야 대군 클라이맥스 총공세 + 최종 우두머리 강림!
    final fourthWave = <WaveSpawnGroup>[
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 12).clamp(30, 64),
        laneIndex: (stage % laneCount),
        intervalSec: (0.28 - ch * 0.008).clamp(0.18, 0.28),
      ),
      WaveSpawnGroup(
        kind: ch >= 4 ? MutantKind.bloodCocoon : MutantKind.sickHound,
        count: (13 + ch * 2).clamp(14, 32),
        laneIndex: 1 % laneCount,
        intervalSec: 0.46,
      ),
      WaveSpawnGroup(
        kind: MutantKind.ironBoar,
        count: (4 + ch ~/ 2 + stage ~/ 4).clamp(4, 14),
        laneIndex: 0,
        intervalSec: 0.98,
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.plagueToad,
        count: (5 + ch ~/ 2).clamp(5, 14),
        laneIndex: (laneCount - 1),
        intervalSec: 0.88,
      ),
    ];

    if (isHeukpung) {
      fourthWave.add(
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
      fourthWave.add(
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
      fourthWave.add(
        WaveSpawnGroup(
          kind: MutantKind.chapterOverlord,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 2.0,
          customBossTitle: chapter.bossName,
          customPortrait: chapter.bossPortraitPrefix,
        ),
      );
    }

    waves.add(fourthWave);
    return waves;
  }

  static List<List<WaveSpawnGroup>> _buildChapter10BossWaves(
    int stage,
    int laneCount,
    ChapterSpec refChapter,
  ) {
    final isFinal = stage == 10;
    final vanguardMidBoss = _midBossKindFor(10, stage);
    final secondMidBoss = _midBossKindFor(10, stage + 1);
    return [
      [
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: 38 + stage * 2,
          laneIndex: (stage + 1) % laneCount,
          intervalSec: 0.28,
        ),
        WaveSpawnGroup(
          kind: MutantKind.sickHound,
          count: 22 + stage,
          laneIndex: 0,
          intervalSec: 0.38,
        ),
        WaveSpawnGroup(
          kind: MutantKind.shieldYacha,
          count: 9 + stage ~/ 2,
          laneIndex: laneCount - 1,
          intervalSec: 0.85,
        ),
        if (stage >= 2)
          WaveSpawnGroup(
            kind: vanguardMidBoss,
            count: 1,
            laneIndex: stage % laneCount,
            intervalSec: 1.60,
            customBossTitle: _midBossCustomTitle(10, vanguardMidBoss),
          ),
      ],
      [
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: 42 + stage * 2,
          laneIndex: stage % laneCount,
          intervalSec: 0.26,
        ),
        WaveSpawnGroup(
          kind: MutantKind.bloodCocoon,
          count: 13 + stage ~/ 2,
          laneIndex: 3 % laneCount,
          intervalSec: 0.72,
        ),
        WaveSpawnGroup(
          kind: MutantKind.ironBoar,
          count: 8 + stage ~/ 2,
          laneIndex: 1 % laneCount,
          intervalSec: 0.96,
        ),
        WaveSpawnGroup(
          kind: secondMidBoss,
          count: 1,
          laneIndex: (stage + 2) % laneCount,
          intervalSec: 1.70,
          customBossTitle: _midBossCustomTitle(10, secondMidBoss),
        ),
      ],
      [
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: 44 + stage * 2,
          laneIndex: (stage + 3) % laneCount,
          intervalSec: 0.24,
        ),
        WaveSpawnGroup(
          kind: MutantKind.sickHound,
          count: 22 + stage,
          laneIndex: 2 % laneCount,
          intervalSec: 0.38,
        ),
        WaveSpawnGroup(
          kind: MutantKind.shieldYacha,
          count: 9 + stage ~/ 2,
          laneIndex: 0,
          intervalSec: 0.82,
        ),
      ],
      [
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: 48 + stage * 2,
          laneIndex: (stage + 2) % laneCount,
          intervalSec: 0.22,
        ),
        WaveSpawnGroup(
          kind: MutantKind.ironBoar,
          count: 9 + stage ~/ 2,
          laneIndex: 1 % laneCount,
          intervalSec: 0.92,
        ),
        WaveSpawnGroup(
          kind: MutantKind.plagueToad,
          count: 8 + stage ~/ 2,
          laneIndex: 2 % laneCount,
          intervalSec: 0.96,
        ),
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
    bool isMukhyeon,
  ) {
    if (ch.number == 1 && st == 1) {
      return const [
        StoryLine(
          speaker: '촌장',
          portraitPrefix: 'chonjang',
          text: '큰일이구나! 하늘의 태극석에 금이 가면서 산짐승들이 심야 돌연변이가 되어 마을로 몰려오고 있다!',
        ),
        StoryLine(
          speaker: '촌장',
          portraitPrefix: 'chonjang',
          text: '점령당한 이웃 마을은 식량이 썩고 농작물도 못 자라며 가축마저 병들어 결국 다들 고향을 떠났단다….',
        ),
        StoryLine(
          speaker: '석두',
          portraitPrefix: 'seokdu',
          text: '본진 수호탑만으로는 밀려오는 대군을 절대 막을 수 없습니다! 초기 군수 기력(⚡)으로 먼저 첫 초소를 세우고, 변이를 잡아 모은 기력 구슬과 돌파 비급으로 방어선을 확장합시다!',
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
    if (isMukhyeon && ch.number == 6) {
      return const [
        StoryLine(
          speaker: '묵현',
          portraitPrefix: 'mukhyeon',
          text: '크으윽… 마을을 지키려 삼킨 독기가… 내 정신을 집어삼키려 한다…! 나를 막아라 사제여!!',
        ),
      ];
    }
    if (isBoss) {
      return [
        StoryLine(
          speaker: '연비',
          portraitPrefix: 'yeonbi',
          text: '밤안개가 가장 짙어졌어요! ${ch.bossName}의 거대한 독기가 길목 끝에서 다가옵니다!',
        ),
      ];
    }
    return const [];
  }

  static List<StoryLine> _outroDialogueFor(
    ChapterSpec ch,
    int st,
    bool isBoss,
    bool isMukhyeon,
  ) {
    if (isMukhyeon && ch.number == 6) {
      return const [
        StoryLine(
          speaker: '묵현',
          portraitPrefix: 'mukhyeon',
          text: '아아… 따뜻한 기명석의 빛이 내 안의 독기를 씻어 내렸구나… 사부의 말씀이 맞았다. 이제부터 내 검은 너희와 마을을 지키는 데 쓰겠다!',
        ),
      ];
    }
    if (!isBoss) return const [];
    switch (ch.number) {
      case 1:
        return const [
          StoryLine(
            speaker: '촌장',
            portraitPrefix: 'chonjang',
            text: '장하다! 우리 흙먼지 마을은 지켰으나 아랫마을 통통 객잔 곡식 창고가 무너지면 모두가 굶게 된다. 이 의용대 지원패를 들고 구원하러 가거라!',
          ),
        ];
      case 2:
        return const [
          StoryLine(
            speaker: '통통',
            portraitPrefix: 'tongtong',
            text: '하하하! 덕분이다! 객잔 곡식 창고가 무사하니 지금 바로 흙먼지 마을로 첫 식량·영약 호송 마차를 출발시키마!',
          ),
        ];
      case 4:
        return const [
          StoryLine(
            speaker: '쿠비',
            portraitPrefix: 'kubi',
            text: '산채 목재와 봉화대를 되찾았다! 이제 우리 산채 정찰대가 밤마다 산야를 돌며 영약과 지원패를 찾아오겠다!',
          ),
        ];
      case 6:
        return const [
          StoryLine(
            speaker: '무림맹주',
            portraitPrefix: 'maengju',
            text: '여섯 거점의 무사들을 묶어 「무림수호단」을 창설한다! 이 황금 지원패를 들면 언제든 전군이 달려와 돌연변이를 싹 쓸어버릴 것이다!',
          ),
        ];
      default:
        return [
          StoryLine(
            speaker: '청명',
            portraitPrefix: 'cheongmyeong',
            text: '새벽해가 밝았습니다! ${ch.villageName}의 논밭과 외양간이 다시 살아나고 있습니다! (${ch.unlockNotice})',
          ),
        ];
    }
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
