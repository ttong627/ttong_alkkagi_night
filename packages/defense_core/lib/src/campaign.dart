import 'dart:math' as math;

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
  final List<StoryLine> introDialogue;
  final List<StoryLine> outroDialogue;

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
}

/// 《수호알까기 · 탄지무림 심야기습》 1~10장(총 111단계) 전체 캠페인 생성기.
class CampaignCatalog {
  static const double arenaWidth = 400.0;
  static const double arenaHeight = 680.0;
  static const Vec2 villageCenter = Vec2(200.0, 565.0);
  static const double outerShieldRadius = 86.0;
  static const double centralTowerRadius = 26.0;

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
          '태극석 균열로 쏟아진 심야 독기 속에 첫 돌연변이 무리가 흙먼지 마을을 기습한다. 촌장과 함께 기명 수호탑을 세워 식량 창고와 논밭, 가축을 지켜내야 한다!',
      unlockNotice: '기명 심법 수련 개방 · 첫째 문양(각성) · 의용대 지원패 전수',
      surfaceFriction: 1.05,
      stageCount: 10,
      lanes: const [
        [Vec2(78, 28), Vec2(95, 190), Vec2(132, 355), Vec2(175, 490), villageCenter],
        [Vec2(322, 28), Vec2(305, 190), Vec2(268, 355), Vec2(225, 490), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(142, 225), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(258, 225), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(115, 395), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(285, 395), recommendedType: LauncherType.heavy),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 290), radius: 19, sides: 4, rotationSpeedRad: 0.9, restitutionBoost: 1.35),
      ],
      cliffs: const [
        CliffZone(center: Vec2(26, 295), radius: 36, label: '서쪽 산비탈 절벽'),
        CliffZone(center: Vec2(374, 295), radius: 36, label: '동쪽 산비탈 절벽'),
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
          '피난민들이 모인 통통 객잔의 대곡식 창고를 탐식 변이체들이 덮친다! 기름진 비탈길 도탄과 묵직한 현철 알로 창고를 지켜 고향으로 첫 식량 호송 수레를 띄워라!',
      unlockNotice: '물자 호송 시스템 정식 개통 · 동료 반달 합류 · 곡사 회전기 개방',
      surfaceFriction: 0.72,
      stageCount: 11,
      lanes: const [
        [Vec2(64, 28), Vec2(128, 175), Vec2(96, 340), Vec2(165, 485), villageCenter],
        [Vec2(336, 28), Vec2(272, 175), Vec2(304, 340), Vec2(235, 485), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(198, 175), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(148, 325), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(252, 325), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(200, 438), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(82, 255), radius: 18, sides: 6, rotationSpeedRad: 1.2, restitutionBoost: 1.42),
        TerrainPillar(center: Vec2(318, 255), radius: 18, sides: 6, rotationSpeedRad: -1.2, restitutionBoost: 1.42),
      ],
      cliffs: const [
        CliffZone(center: Vec2(24, 365), radius: 38, label: '객잔 뒤편 계곡'),
        CliffZone(center: Vec2(376, 365), radius: 38, label: '장독대 낭떠러지'),
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
          '봄에 뿌릴 씨앗과 어미 가축들이 모인 거북 장터에 밤비가 내리고, 독기의 힘에 손댄 사형 묵현(1차)과 그림자 변이 자객 무리가 세 갈래 골목으로 침투한다!',
      unlockNotice: '전국 호송망 확장 · 영수 영귀 금강 개방 · 한빙 역장기 개방',
      surfaceFriction: 0.92,
      stageCount: 11,
      lanes: const [
        [Vec2(55, 28), Vec2(78, 210), Vec2(120, 380), Vec2(168, 495), villageCenter],
        [Vec2(200, 24), Vec2(200, 215), Vec2(200, 385), Vec2(200, 488), villageCenter],
        [Vec2(345, 28), Vec2(322, 210), Vec2(280, 380), Vec2(232, 495), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(136, 195), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(264, 195), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(132, 355), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(268, 355), recommendedType: LauncherType.heavy),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 285), radius: 20, sides: 5, rotationSpeedRad: 1.1, restitutionBoost: 1.38),
      ],
      cliffs: const [
        CliffZone(center: Vec2(22, 285), radius: 36, label: '장터 수로 낭떠러지'),
        CliffZone(center: Vec2(378, 285), radius: 36, label: '성벽 아래 해자'),
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
          '각 마을 수호탑 보급에 필요한 천년 목재와 산길 봉화대를 되찾기 위해 쿠비 산채로 향한다. 굽이치는 숲길에서 곡사 회전기와 도탄으로 산채 두목 쿠비를 구출하라!',
      unlockNotice: '심야 탐색 시스템 정식 개통 · 둘째 문양(동행) · 동료 구르미 합류',
      surfaceFriction: 1.00,
      stageCount: 12,
      lanes: const [
        [Vec2(60, 28), Vec2(130, 160), Vec2(75, 315), Vec2(155, 475), villageCenter],
        [Vec2(200, 25), Vec2(225, 195), Vec2(175, 345), Vec2(200, 480), villageCenter],
        [Vec2(340, 28), Vec2(270, 160), Vec2(325, 315), Vec2(245, 475), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(155, 225), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(245, 225), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(120, 388), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(280, 388), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(200, 422), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(105, 235), radius: 17, sides: 3, rotationSpeedRad: 1.4, restitutionBoost: 1.44),
        TerrainPillar(center: Vec2(295, 235), radius: 17, sides: 3, rotationSpeedRad: -1.4, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(24, 320), radius: 40, label: '산채 천길 벼랑'),
        CliffZone(center: Vec2(376, 320), radius: 40, label: '구름다리 절벽'),
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
          '중갑 변이체를 뚫을 고대 기관술의 본산 로직 학당! 흔들리는 눈빛의 묵현(2차)을 넘어 학당을 구하면 내공 증폭기와 자동 어기어석의 비전이 열린다!',
      unlockNotice: '내공 증폭기 개방 · 셋째 문양(자동 어기어석) · 동료 정각 합류',
      surfaceFriction: 0.80,
      stageCount: 11,
      lanes: const [
        [Vec2(70, 28), Vec2(70, 235), Vec2(135, 385), Vec2(172, 490), villageCenter],
        [Vec2(200, 28), Vec2(200, 225), Vec2(200, 385), Vec2(200, 488), villageCenter],
        [Vec2(330, 28), Vec2(330, 235), Vec2(265, 385), Vec2(228, 490), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 305), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(132, 225), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(268, 225), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(132, 392), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(268, 392), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(135, 305), radius: 18, sides: 8, rotationSpeedRad: 1.25, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(265, 305), radius: 18, sides: 8, rotationSpeedRad: -1.25, restitutionBoost: 1.45),
      ],
      cliffs: const [
        CliffZone(center: Vec2(24, 250), radius: 38, label: '학당 서쪽 연못 해자'),
        CliffZone(center: Vec2(376, 250), radius: 38, label: '학당 동쪽 절벽'),
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
          '혹한의 밤, 포위된 무림맹 본단에서 독기에 삼켜질 뻔한 묵현(3차)을 정화 탄지로 구원하고 맹주와 함께 흑화 마룡수를 격파하라! 승전 후 전군 총돌격 황금 지원패가 완성된다!',
      unlockNotice: '황금 지원패(무림수호단 출두야~~!!) 완성 · 동료 용아 및 위기 난입 묵현 합류',
      surfaceFriction: 0.76,
      stageCount: 12,
      lanes: const [
        [Vec2(48, 28), Vec2(72, 220), Vec2(118, 385), Vec2(165, 495), villageCenter],
        [Vec2(148, 24), Vec2(162, 220), Vec2(176, 385), Vec2(188, 490), villageCenter],
        [Vec2(252, 24), Vec2(238, 220), Vec2(224, 385), Vec2(212, 490), villageCenter],
        [Vec2(352, 28), Vec2(328, 220), Vec2(282, 385), Vec2(235, 495), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 295), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(112, 235), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(288, 235), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(128, 395), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(272, 395), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 185), radius: 20, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.45),
      ],
      cliffs: const [
        CliffZone(center: Vec2(22, 330), radius: 38, label: '본단 빙벽 협곡'),
        CliffZone(center: Vec2(378, 330), radius: 38, label: '본단 화염 구렁'),
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
          '서쪽 하늘로 치솟는 독기의 기둥을 쫓아 도착한 열사의 협곡! 사막 백성들의 마지막 생명수 오아시스를 지키고 4형 극의 발사대용 금강석·반석 광맥을 확보하라!',
      unlockNotice: '4형(극의) 발사대 제련 완성 · 천마 화신 영입 개방',
      surfaceFriction: 1.15,
      stageCount: 11,
      lanes: const [
        [Vec2(58, 28), Vec2(95, 200), Vec2(125, 365), Vec2(170, 490), villageCenter],
        [Vec2(200, 24), Vec2(190, 195), Vec2(210, 360), Vec2(200, 488), villageCenter],
        [Vec2(342, 28), Vec2(305, 200), Vec2(275, 365), Vec2(230, 490), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 285), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(138, 210), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(262, 210), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(142, 390), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(258, 390), recommendedType: LauncherType.curveSpin),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(125, 295), radius: 19, sides: 4, rotationSpeedRad: 1.3, restitutionBoost: 1.40),
        TerrainPillar(center: Vec2(275, 295), radius: 19, sides: 4, rotationSpeedRad: -1.3, restitutionBoost: 1.40),
      ],
      cliffs: const [
        CliffZone(center: Vec2(25, 300), radius: 40, label: '모래 소용돌이 구렁'),
        CliffZone(center: Vec2(375, 300), radius: 40, label: '협곡 낭떠러지'),
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
          '굶주린 바닷가 마을들에 구호 곡식을 나르는 해적왕의 함대를 심해 괴수로부터 호위하라! 뱃전 도탄으로 괴수를 바다에 빠뜨리면 화염산 앞바다까지 뱃길이 열린다!',
      unlockNotice: '영수 천룡 금룡 개방 · 동료 검황 영입 개방',
      surfaceFriction: 0.84,
      stageCount: 11,
      lanes: const [
        [Vec2(68, 28), Vec2(84, 205), Vec2(118, 370), Vec2(168, 492), villageCenter],
        [Vec2(200, 24), Vec2(200, 205), Vec2(200, 370), Vec2(200, 488), villageCenter],
        [Vec2(332, 28), Vec2(316, 205), Vec2(282, 370), Vec2(232, 492), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 290), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(138, 205), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(262, 205), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(138, 392), recommendedType: LauncherType.rapid),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(262, 392), recommendedType: LauncherType.frostField),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 195), radius: 19, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.48),
      ],
      cliffs: const [
        CliffZone(center: Vec2(24, 280), radius: 42, label: '좌현 검푸른 밤바다'),
        CliffZone(center: Vec2(376, 280), radius: 42, label: '우현 소용돌이 바다'),
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
          '대지에서 독기가 치솟는 화염산 분화구! 염마녀와 힘을 합쳐 운철·한철을 벼려내고 네 갈래 용암 길목의 변이 대군을 용암 절벽 아래로 밀어 넣어 천상 계단을 열어라!',
      unlockNotice: '한철·신물 수호석 제련 극대화 · 동료 무량 신승 개방 · 천상 계단 개통',
      surfaceFriction: 0.90,
      stageCount: 12,
      lanes: const [
        [Vec2(50, 28), Vec2(78, 210), Vec2(120, 380), Vec2(166, 492), villageCenter],
        [Vec2(150, 24), Vec2(164, 215), Vec2(178, 380), Vec2(190, 490), villageCenter],
        [Vec2(250, 24), Vec2(236, 215), Vec2(222, 380), Vec2(210, 490), villageCenter],
        [Vec2(350, 28), Vec2(322, 210), Vec2(280, 380), Vec2(234, 492), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 295), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(115, 225), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(285, 225), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(128, 395), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(272, 395), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(125, 310), radius: 18, sides: 5, rotationSpeedRad: 1.6, restitutionBoost: 1.46),
        TerrainPillar(center: Vec2(275, 310), radius: 18, sides: 5, rotationSpeedRad: -1.6, restitutionBoost: 1.46),
      ],
      cliffs: const [
        CliffZone(center: Vec2(24, 325), radius: 42, label: '서쪽 용암 분화구'),
        CliffZone(center: Vec2(376, 325), radius: 42, label: '동쪽 용암 절벽'),
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
          '구름 위 천상 탄신전! 독기가 되살려낸 1~9장 폭주 우두머리 환영을 9연속 정화하고, 마지막 10단계에서 오염된 태초 탄신을 구원해 열 마을에 영원한 봄과 풍년을 되찾아라!',
      unlockNotice: '열 마을 완전 정화 대단원 귀향 엔딩 · 수호신 칭호 획득',
      surfaceFriction: 0.82,
      stageCount: 10,
      lanes: const [
        [Vec2(52, 28), Vec2(82, 210), Vec2(122, 380), Vec2(168, 492), villageCenter],
        [Vec2(152, 24), Vec2(165, 215), Vec2(178, 380), Vec2(190, 490), villageCenter],
        [Vec2(248, 24), Vec2(235, 215), Vec2(222, 380), Vec2(210, 490), villageCenter],
        [Vec2(348, 28), Vec2(318, 210), Vec2(278, 380), Vec2(232, 492), villageCenter],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(200, 290), recommendedType: LauncherType.qiAmplifier),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(116, 220), recommendedType: LauncherType.heavy),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(284, 220), recommendedType: LauncherType.frostField),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(128, 392), recommendedType: LauncherType.curveSpin),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(272, 392), recommendedType: LauncherType.rapid),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(200, 185), radius: 20, sides: 8, rotationSpeedRad: 1.7, restitutionBoost: 1.50),
        TerrainPillar(center: Vec2(122, 305), radius: 17, sides: 6, rotationSpeedRad: -1.4, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(278, 305), radius: 17, sides: 6, rotationSpeedRad: 1.4, restitutionBoost: 1.45),
      ],
      cliffs: const [
        CliffZone(center: Vec2(24, 305), radius: 44, label: '천상 운해 낭떠러지'),
        CliffZone(center: Vec2(376, 305), radius: 44, label: '은하 절벽'),
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
          result.add(
            StageSpec(
              chapterNumber: 10,
              stageNumber: st,
              globalIndex: globalIdx,
              title: isFinalGod
                  ? '최종 관문 · 오염된 태초 탄신 구원'
                  : '천상 $st관문 · ${refChapter.bossName} 심야 환영',
              subtitle: isFinalGod
                  ? '태극석의 균열을 메워 열 마을의 논밭과 생명을 되살려라!'
                  : '${refChapter.villageName}에서 물리쳤던 우두머리의 심야 환영 결전',
              tacticalHint: isFinalGod
                  ? '내공 증폭기 + 중포·한빙·속사 균형 배치 및 고단수 수호석 장착 권장'
                  : '보스 호위 변이체를 속사·한빙으로 묶고 중포·곡사로 우두머리를 집중 타격하세요',
              recommendedStone: StoneMaterial.values[(st + 2).clamp(0, 12)],
              recommendedLaunchers: const [
                LauncherType.qiAmplifier,
                LauncherType.heavy,
                LauncherType.frostField,
                LauncherType.curveSpin,
                LauncherType.rapid,
              ],
              startingFieldTokens: 175 + st * 10,
              clearElixirBonus: isFinalGod ? 10 : 4,
              isBossStage: true,
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
                        text: '각 관문에 맞춰 자동 발사 진법만 바르게 가다듬으면 반드시 뚫을 수 있다. 가자!',
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

        String stageTitle;
        String sub;
        if (isChapterBoss) {
          stageTitle = '${ch.number}-$st 결전 · ${ch.bossName}';
          sub = '${ch.villageName}의 운명을 건 최종 심야 방어전';
        } else if (isHeukpungStage) {
          stageTitle = '${ch.number}-$st 약탈 저지 · 부두목 흑풍';
          sub = '식량 수레를 노리는 약탈 선봉장 흑풍을 격퇴하고 증표를 탈환하라!';
        } else if (isMukhyeonStage) {
          stageTitle = '${ch.number}-$st 숙적 조우 · 사형 묵현';
          sub = ch.number == 6
              ? '독기에 삼켜진 묵현을 정화 탄지로 구원하라!'
              : '어긋난 힘으로 폭주하는 사형 묵현의 야간 기습!';
        } else {
          stageTitle = '${ch.number}-$st 야간 길목 수호 ($st차 밤)';
          if (st >= 2) {
            final midKind = _midBossKindFor(ch.number, st);
            sub = '${ch.villageName} 길목 방어 · 중간보스 [${midKind.name}(${midKind.roleTag})] 동반 침략!';
          } else {
            sub = '${ch.villageName} 외곽 산·들 길목 기습 방어';
          }
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
            recommendedLaunchers: ch.mounts.map((m) => m.recommendedType).toList(),
            startingFieldTokens: 112 + ch.number * 16 + st * 5,
            clearElixirBonus: isChapterBoss ? 5 : (isHeukpungStage || isMukhyeonStage ? 2 : 1),
            isBossStage: isChapterBoss || isHeukpungStage || isMukhyeonStage,
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
    final baseCount = 4 + ch + (stage ~/ 2);
    final waves = <List<WaveSpawnGroup>>[];

    // 1웨이브: 선봉 정찰 기습
    waves.add([
      WaveSpawnGroup(
        kind: stage % 2 == 1 ? MutantKind.swarmRat : MutantKind.sickHound,
        count: baseCount,
        laneIndex: 0,
        intervalSec: 1.15,
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.sickHound : MutantKind.swarmRat,
        count: (baseCount * 0.8).round().clamp(3, 16),
        laneIndex: 1 % laneCount,
        intervalSec: 1.25,
      ),
    ]);

    // 2웨이브: 중견 압박 기습 — 2단계 이상 모든 스테이지에서 스피드·맷집·공격력 특화 중간보스가 일반 무리와 동반 침략!
    if (stage >= 2) {
      final midKind = _midBossKindFor(ch, stage);
      final midTitle = _midBossCustomTitle(ch, midKind);
      final bossLane = (stage + 1) % laneCount;

      if (midKind == MutantKind.swiftShadowBoss) {
        // 스피드 특화 중간보스 + 들개·독쥐 초고속 기습대 동시 침공
        waves.add([
          WaveSpawnGroup(
            kind: MutantKind.sickHound,
            count: (2 + ch ~/ 2 + stage ~/ 4).clamp(2, 8),
            laneIndex: stage % laneCount,
            intervalSec: 1.25,
          ),
          WaveSpawnGroup(
            kind: MutantKind.swarmRat,
            count: (baseCount - 1).clamp(3, 14),
            laneIndex: (stage + 2) % laneCount,
            intervalSec: 0.98,
          ),
          WaveSpawnGroup(
            kind: MutantKind.swiftShadowBoss,
            count: 1,
            laneIndex: bossLane,
            intervalSec: 1.50,
            customBossTitle: midTitle,
          ),
        ]);
      } else if (midKind == MutantKind.ironColossusBoss) {
        // 맷집 특화 중간보스 + 멧돼지·야차 중갑 돌파대 동시 침공
        waves.add([
          WaveSpawnGroup(
            kind: ch >= 2 ? MutantKind.ironBoar : MutantKind.sickHound,
            count: (2 + ch ~/ 3 + stage ~/ 5).clamp(2, 6),
            laneIndex: stage % laneCount,
            intervalSec: 1.75,
          ),
          WaveSpawnGroup(
            kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.swarmRat,
            count: (2 + ch ~/ 3).clamp(2, 6),
            laneIndex: (stage + 2) % laneCount,
            intervalSec: 1.65,
          ),
          WaveSpawnGroup(
            kind: MutantKind.ironColossusBoss,
            count: 1,
            laneIndex: bossLane,
            intervalSec: 1.80,
            customBossTitle: midTitle,
          ),
        ]);
      } else {
        // 공격력 특화 중간보스 + 분열충·두꺼비 파성 강습대 동시 침공
        waves.add([
          WaveSpawnGroup(
            kind: ch >= 3 ? MutantKind.bloodCocoon : MutantKind.sickHound,
            count: (2 + ch ~/ 3 + stage ~/ 5).clamp(2, 6),
            laneIndex: stage % laneCount,
            intervalSec: 1.60,
          ),
          WaveSpawnGroup(
            kind: ch >= 2 ? MutantKind.plagueToad : MutantKind.swarmRat,
            count: (2 + ch ~/ 3).clamp(2, 6),
            laneIndex: (stage + 2) % laneCount,
            intervalSec: 1.70,
          ),
          WaveSpawnGroup(
            kind: MutantKind.crimsonBreakerBoss,
            count: 1,
            laneIndex: bossLane,
            intervalSec: 1.70,
            customBossTitle: midTitle,
          ),
        ]);
      }
    } else {
      waves.add([
        WaveSpawnGroup(
          kind: MutantKind.sickHound,
          count: (2 + ch ~/ 2).clamp(2, 6),
          laneIndex: (stage % laneCount),
          intervalSec: 1.75,
        ),
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: baseCount,
          laneIndex: ((stage + 2) % laneCount),
          intervalSec: 1.05,
        ),
      ]);
    }

    // 3웨이브: 심야 본대 또는 보스 강림
    final thirdWave = <WaveSpawnGroup>[
      WaveSpawnGroup(
        kind: ch >= 4 ? MutantKind.bloodCocoon : MutantKind.ironBoar,
        count: (2 + ch ~/ 2).clamp(2, 7),
        laneIndex: 0,
        intervalSec: 1.65,
      ),
      WaveSpawnGroup(
        kind: ch >= 3 ? MutantKind.shieldYacha : MutantKind.sickHound,
        count: (3 + ch ~/ 2).clamp(3, 8),
        laneIndex: (laneCount - 1),
        intervalSec: 1.50,
      ),
    ];

    if (isHeukpung) {
      thirdWave.add(
        WaveSpawnGroup(
          kind: MutantKind.raiderHeukpung,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 2.0,
          customBossTitle: '약탈 선봉 부두목 흑풍',
          customPortrait: 'budumok',
        ),
      );
    } else if (isMukhyeon) {
      thirdWave.add(
        WaveSpawnGroup(
          kind: MutantKind.rivalMukhyeon,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 2.0,
          customBossTitle: ch == 6 ? '독기에 잠식된 묵현 (최종 정화)' : '폭주하는 사형 묵현',
          customPortrait: 'mukhyeon',
        ),
      );
    } else if (isChapterBoss) {
      thirdWave.add(
        WaveSpawnGroup(
          kind: MutantKind.chapterOverlord,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 2.2,
          customBossTitle: chapter.bossName,
          customPortrait: chapter.bossPortraitPrefix,
        ),
      );
    }

    waves.add(thirdWave);
    return waves;
  }

  static List<List<WaveSpawnGroup>> _buildChapter10BossWaves(
    int stage,
    int laneCount,
    ChapterSpec refChapter,
  ) {
    final isFinal = stage == 10;
    final vanguardMidBoss = _midBossKindFor(10, stage);
    return [
      [
        WaveSpawnGroup(
          kind: MutantKind.sickHound,
          count: 6 + stage ~/ 2,
          laneIndex: 0,
          intervalSec: 1.05,
        ),
        WaveSpawnGroup(
          kind: MutantKind.shieldYacha,
          count: 3 + stage ~/ 3,
          laneIndex: laneCount - 1,
          intervalSec: 1.45,
        ),
        if (stage >= 2)
          WaveSpawnGroup(
            kind: vanguardMidBoss,
            count: 1,
            laneIndex: stage % laneCount,
            intervalSec: 1.65,
            customBossTitle: _midBossCustomTitle(10, vanguardMidBoss),
          ),
      ],
      [
        WaveSpawnGroup(
          kind: MutantKind.ironBoar,
          count: 4 + stage ~/ 3,
          laneIndex: 1 % laneCount,
          intervalSec: 1.55,
        ),
        WaveSpawnGroup(
          kind: MutantKind.plagueToad,
          count: 3 + stage ~/ 4,
          laneIndex: 2 % laneCount,
          intervalSec: 1.65,
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
          text: '걱정 마십시오 촌장님! 마을 한가운데 기명 수호탑과 방어막을 세웠고, 길목마다 자동 알 발사대와 저희가 지키고 있습니다!',
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
