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
    hpMult: 0.92,
    speedMult: 0.93,
    rewardMult: 1.0,
    summary: '거점 개척과 지형 포진의 기본기를 익히며 막아내는 입문 난이도',
  ),
  normal(
    id: 'normal',
    name: '보통 · 강호 수호자',
    hpMult: 1.26,
    speedMult: 1.05,
    rewardMult: 1.25,
    summary: '기력 운용·거점 개척·5병종 상성·보스 약점 저격이 필수인 표준 진검 난이도 (영구 보상 +25%)',
  ),
  nightmare(
    id: 'nightmare',
    name: '악몽 · 심야 혈전',
    hpMult: 1.88,
    speedMult: 1.18,
    rewardMult: 1.55,
    summary: '극한의 진법 설계와 내공·영수 성장이 요구되는 고수용 사투 (영구 보상 +55%)',
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
    this.customHitShield,
    this.hierarchyRank,
  });

  final MutantKind kind;
  final int count;
  final int laneIndex;
  final double intervalSec;
  final String? customBossTitle;
  final String? customPortrait;
  final int? customHitShield;
  final String? hierarchyRank;
}

/// 현(縣) 정화 완료 후 다음 현으로 대행군할 때 재생되는 시네마틱 여정 명세 (1→2현 ~ 9→10현 총 9종 완전 고유 구성!).
class CountyTransitionSpec {
  const CountyTransitionSpec({
    required this.fromChapter,
    required this.toChapter,
    required this.fromCountyName,
    required this.toCountyName,
    required this.travelTitle,
    required this.travelVehicleBadge,
    required this.motionAssetKey,
    required this.narrationLines,
    required this.unlockHighlight,
  });

  final int fromChapter;
  final int toChapter;
  final String fromCountyName;
  final String toCountyName;
  final String travelTitle;
  final String travelVehicleBadge;
  final String motionAssetKey;
  final List<String> narrationLines;
  final String unlockHighlight;
}

/// 개별 스테이지(현내 1~10번 마을 관문) 명세.
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
    this.villageNodeName = '',
    this.villageMapCoord = const Vec2(0.5, 0.5),
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

  /// 해당 현(縣) 안에서의 고유 마을·요충지 명칭 (1번 초입 마을 ~ 10번 현청 본전).
  final String villageNodeName;

  /// 현내 10개 마을 행군 지도에서의 정규화 좌표 (0.0~1.0).
  final Vec2 villageMapCoord;

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

/// 각 장(1~10장) 명세 — 코덱스 10종 완전 차별화 맵 원화(도로·다리·석조 좌대·수호 제단·마을 건물) 1:1 픽셀 보정 및 장별 고유 특색 정의.
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
    this.towerPos = const Vec2(360.0, 885.0),
    this.granaryPos = const Vec2(105.0, 960.0),
    this.cropsPos = const Vec2(360.0, 1185.0),
    this.livestockPos = const Vec2(610.0, 965.0),
    this.roadVisualSpine = const [],
    this.visualGuideLanes = const [],
    this.actionCaptainTitle = '선봉 행동대장',
    this.midBossSquadTitle = '심야 중간보스',
    this.routeTopologyTag = '산비탈 대각 회랑',
    this.chapterTraitTitle = '하산 순풍',
    this.chapterTraitDesc = '초소 축조 속도 향상 · 탄알 직진 안정화',
    this.isOrthogonalLabyrinth = false,
    this.buildCostMultiplier = 1.0,
    this.buildDurationSec = 2.0,
    this.excavationCostMultiplier = 1.0,
    this.swarmVolumeMultiplier = 1.0,
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

  /// 각 장 맵 원화 속 원형 석조 수호 제단 정중앙 좌표!
  final Vec2 towerPos;

  /// 각 장 맵 원화 속 식량 창고 · 황금 논밭 · 가축 외양간 실제 좌표!
  final Vec2 granaryPos;
  final Vec2 cropsPos;
  final Vec2 livestockPos;

  /// 맵 원화 석조 도로 중심을 따라 은은한 기맥 광선을 그리기 위한 기준선.
  final List<Vec2> roadVisualSpine;

  /// 다중 진입로(X자 교차·3운하·남북 양면·4전함·6화산섬·7부유섬) 전체를 보여주는 비중복 시각 유도선 목록.
  final List<List<Vec2>> visualGuideLanes;

  /// 각 장 지휘 계층: 행동대장(100타+) · 중간보스(200~600타+) 명칭.
  final String actionCaptainTitle;
  final String midBossSquadTitle;

  /// 장별 완전히 다른 침공 루트 위상 태그 (캠페인 카드·전투 상단 배지 표시용).
  final String routeTopologyTag;

  /// 장별 고유 전장 특색 명칭 및 능력치 효과 요약.
  final String chapterTraitTitle;
  final String chapterTraitDesc;

  /// 제5장 시계태엽 직각 미궁처럼 90도 직각 복도 보간을 적용할지 여부.
  final bool isOrthogonalLabyrinth;

  /// 장이 올라갈수록 포대 설치가 까다로워지는 건설비·축조시간·개척비·물량 배율!
  final double buildCostMultiplier;
  final double buildDurationSec;
  final double excavationCostMultiplier;
  final double swarmVolumeMultiplier;

  /// 각 장 수호탑 위치(하단/중앙/상단·좌/우)에 맞춰 수동 탄지 사거리(365px) 안에서 항상 맞힐 수 있는 ×2 배율 복제진 기본 좌표!
  Vec2 get cloneGateBasePos {
    final anchorX = (towerPos.x * 0.62 + 360.0 * 0.38).clamp(165.0, 555.0);
    if (towerPos.y < 360.0) {
      return Vec2(anchorX, (towerPos.y + 175.0).clamp(360.0, 540.0));
    }
    if (towerPos.y < 760.0) {
      return Vec2(anchorX, (towerPos.y - 178.0).clamp(360.0, 520.0));
    }
    return Vec2(anchorX, (towerPos.y - 185.0).clamp(585.0, 820.0));
  }

  /// 각 장 수호탑 위치에 맞춰 기본 수동 탄지 사거리(365px) 안에 들어오는 🎯 화력 증폭 과녁패 기본 좌표!
  Vec2 get powerTargetBasePos {
    final anchorX = (towerPos.x * 0.55 + 360.0 * 0.45).clamp(175.0, 545.0);
    if (towerPos.y < 360.0) {
      return Vec2(anchorX, (towerPos.y + 275.0).clamp(450.0, 620.0));
    }
    if (towerPos.y < 760.0) {
      return Vec2(anchorX, (towerPos.y + 185.0).clamp(740.0, 890.0));
    }
    return Vec2(anchorX, (towerPos.y - 295.0).clamp(510.0, 790.0));
  }

  static List<Vec2> _orthogonalUniform(List<Vec2> raw) {
    if (raw.length < 2) return raw;
    final dense = <Vec2>[];
    for (int i = 0; i < raw.length - 1; i++) {
      final p1 = raw[i];
      final p2 = raw[i + 1];
      final segLen = p1.distanceTo(p2);
      final steps = math.max(2, (segLen / 6.0).ceil());
      for (int s = 0; s < steps; s++) {
        final t = s / steps;
        dense.add(
          Vec2(
            (p1.x + (p2.x - p1.x) * t).clamp(28.0, CampaignCatalog.arenaWidth - 28.0),
            p1.y + (p2.y - p1.y) * t,
          ),
        );
      }
    }
    dense.add(raw.last);
    final uniform = <Vec2>[dense.first];
    double acc = 0.0;
    for (int i = 1; i < dense.length; i++) {
      acc += dense[i].distanceTo(uniform.last);
      if (acc >= 8.0 || i == dense.length - 1) {
        uniform.add(dense[i]);
        acc = 0.0;
      }
    }
    return uniform;
  }

  static List<Vec2> _catmullSplineUniform(List<Vec2> raw) {
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

  static final Map<int, List<Vec2>> _smoothedLaneCache = <int, List<Vec2>>{};
  static final Map<int, List<Vec2>> _smoothedSpineCache = <int, List<Vec2>>{};
  static final Map<int, List<List<Vec2>>> _smoothedGuidesCache =
      <int, List<List<Vec2>>>{};

  List<Vec2> _interpolatePath(List<Vec2> raw) =>
      isOrthogonalLabyrinth ? _orthogonalUniform(raw) : _catmullSplineUniform(raw);

  /// 제어점 배열을 장 특성에 맞춰(3차 카트멀-롬 곡선 또는 90° 직각 미궁 복도) 8px 등간격으로 보간(정적 캐시 적용).
  List<Vec2> smoothedLane(int laneIndex) {
    final normIdx = laneIndex % lanes.length;
    final key = number * 100 + normIdx;
    return _smoothedLaneCache.putIfAbsent(
      key,
      () => List<Vec2>.unmodifiable(_interpolatePath(lanes[normIdx])),
    );
  }

  /// 시각 유도선용 도로 기준 스플라인 반환(정적 캐시 적용).
  List<Vec2> get smoothedVisualSpine => _smoothedSpineCache.putIfAbsent(
        number,
        () => List<Vec2>.unmodifiable(
          roadVisualSpine.length >= 2
              ? _interpolatePath(roadVisualSpine)
              : smoothedLane(0),
        ),
      );

  /// 전장의 모든 고유 침공 갈래를 깔끔하게 렌더링하기 위한 스플라인 배열(정적 캐시 적용).
  List<List<Vec2>> get smoothedVisualGuides => _smoothedGuidesCache.putIfAbsent(
        number,
        () {
          if (visualGuideLanes.isNotEmpty) {
            return List<List<Vec2>>.unmodifiable(
              visualGuideLanes
                  .map((l) => List<Vec2>.unmodifiable(_interpolatePath(l)))
                  .toList(),
            );
          }
          return List<List<Vec2>>.unmodifiable(<List<Vec2>>[smoothedVisualSpine]);
        },
      );

  /// 해당 장의 평균 침공 경로 총 연장(px) 계산.
  double get averageLaneLengthPx {
    if (lanes.isEmpty) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < lanes.length; i++) {
      final pts = smoothedLane(i);
      for (int k = 1; k < pts.length; k++) {
        sum += pts[k].distanceTo(pts[k - 1]);
      }
    }
    return sum / lanes.length;
  }

  /// 공중 비행 돌연변이(혈익 흡혈박쥐 · 심연 철익귀) 전용 상공 선회 강하 항로 (남북·역진격·해상·천상 지형 모두 완벽 대응)!
  List<Vec2> aerialLane(int index) {
    final fromLeft = index.isEven;
    final startGate = (number == 10 && !fromLeft)
        ? const Vec2(598.0, 122.0)
        : (lanes.isNotEmpty
            ? lanes[index % lanes.length].first
            : Vec2(fromLeft ? 156.0 : 564.0, 96.0));
    final dy = towerPos.y - startGate.y;
    final raw = <Vec2>[
      startGate,
      Vec2(fromLeft ? 540.0 : 180.0, (startGate.y + dy * 0.24).clamp(90.0, 1260.0)),
      Vec2(fromLeft ? 175.0 : 545.0, (startGate.y + dy * 0.50).clamp(90.0, 1260.0)),
      Vec2(fromLeft ? 535.0 : 185.0, (startGate.y + dy * 0.74).clamp(90.0, 1260.0)),
      Vec2(
        (towerPos.x + (fromLeft ? 92.0 : -92.0)).clamp(64.0, 656.0),
        (towerPos.y - dy.sign * 68.0).clamp(90.0, 1260.0),
      ),
      Vec2(
        (towerPos.x + (fromLeft ? -86.0 : 86.0)).clamp(64.0, 656.0),
        (towerPos.y + dy.sign * 24.0).clamp(90.0, 1260.0),
      ),
      towerPos,
    ];
    return _catmullSplineUniform(raw);
  }

  /// 각 장(1~10장)을 아우르는 대행정 구역 「현(縣)」 정식 명칭.
  String get countyName => switch (number) {
        1 => '제1현 · 청산 흙먼지현',
        2 => '제2현 · 통통 객잔현',
        3 => '제3현 · 청옥 거북장터현',
        4 => '제4현 · 쿠비 봉화산현',
        5 => '제5현 · 황동 기관학당현',
        6 => '제6현 · 만년설 백옥무림현',
        7 => '제7현 · 적월 열사사막현',
        8 => '제8현 · 창파 등대함대현',
        9 => '제9현 · 흑요 적염화산현',
        _ => '제10현 · 천상 태극신전현',
      };

  String get shortCountyName => countyName.split(' · ').last;

  static const Map<int, List<String>> _countyVillageNames = {
    1: [
      '산기슭 입구촌',
      '솔바람 약초막',
      '폭포 물레방아터',
      '바위고개 약초마을',
      '청석 비탈촌',
      '절벽 숯가마터',
      '비룡 협곡 나루',
      '청명 도관 마을',
      '뒷산 곡창 목책',
      '흙먼지 신당 본촌',
    ],
    2: [
      '북문 장승거리',
      '등불 주막촌',
      '기름 방앗간 마을',
      '교차로 마구간촌',
      '금강 우물 장터',
      '남쪽 쌀자루 거리',
      '야간 포목 골목',
      '동문 수레 정류장',
      '대곡창 외성 마을',
      '통통 객잔 본채',
    ],
    3: [
      '청옥 수문 나루',
      '초승달 어시장',
      '종자 창고 마을',
      '연등 다리목촌',
      '취선 양조장 마을',
      '버드나무 수로촌',
      '우시장 목책 마을',
      '비단 포구 거리',
      '중앙 석교 장터',
      '거북 현청 대장터',
    ],
    4: [
      '야성 대숲 초입',
      '출렁다리 산막',
      '천년고목 사냥촌',
      '절벽 횃불 초소',
      '묵객 암각화 마을',
      '산마루 목재소',
      '구름 안개 다락촌',
      '독수리 망루촌',
      '산채 외곽 성책',
      '쿠비 대봉화 본채',
    ],
    5: [
      '태엽 외성 관문',
      '황동 수차 마을',
      '증기 대장간 거리',
      '직각 회랑 기숙촌',
      '설화 빙기 연구소',
      '청동 종루 마을',
      '기맥 도관 광장',
      '톱니 승강기 초소',
      '내성 방호벽 구역',
      '로직 기관학당 본전',
    ],
    6: [
      '설원 초입 역참',
      '빙하 협곡 마을',
      '한옥 온천 산장',
      '서리 소나무 촌락',
      '백호 설산 제단',
      '백옥 석교 마을',
      '무림맹 연무장촌',
      '장로원 외곽 마을',
      '호법 금강문 거리',
      '백옥 무림맹 대광장',
    ],
    7: [
      '모래폭풍 초소촌',
      '붉은 바위 협곡촌',
      '선인장 우물 마을',
      '낙타 대상 숙영지',
      '고대 사구 유적촌',
      '마교 흑사 오아시스',
      '열사 절벽 동굴촌',
      '일월 성화대 마을',
      '적사 외성 성문촌',
      '일월 절벽성채 본전',
    ],
    8: [
      '해안 방파제 어촌',
      '달빛 조선소 마을',
      '갑판 보급 부두',
      '검은 파도 암초진',
      '금룡 해신 사당촌',
      '구호 곡식 선창가',
      '전함 연결 잔교촌',
      '쌍둥이 봉화 방어항',
      '기함 호위 선단',
      '구호 대등대 본항',
    ],
    9: [
      '검은 재 산기슭촌',
      '용암 개울 대장촌',
      '유황 온천 대피소',
      '사슬 현수교 관문',
      '흑요석 광산 마을',
      '신승 금강 암자촌',
      '업화 분화구 초소',
      '적염 결계석 마을',
      '화산 외성 성채',
      '적염 봉인신전 본단',
    ],
    10: [
      '운해 승천 초입문',
      '청산 성좌 부유대',
      '객잔 성좌 부유대',
      '장터 성좌 부유대',
      '봉화 성좌 부유대',
      '기관 성좌 부유대',
      '백옥 성좌 부유대',
      '열사·창파 성좌대',
      '적염 성좌 회랑',
      '태초 태극석 본전',
    ],
  };

  /// 현내 1~10번 마을 고유 명칭 조회.
  String villageNodeNameAt(int stageNumber) {
    final names = _countyVillageNames[number] ?? _countyVillageNames[1]!;
    return names[(stageNumber - 1).clamp(0, names.length - 1)];
  }

  /// 각 현의 고유 지형 경로(대각 산길·X교차·3운하·나선절벽·직각미궁·양면광장·역진격사막·해상함대·화산사슬·천상부유섬)를 따라 배치된 10개 마을 정규화 지도 좌표!
  static const Map<int, List<Vec2>> _countyVillageMapCoords = {
    1: [
      Vec2(0.16, 0.16),
      Vec2(0.30, 0.24),
      Vec2(0.48, 0.30),
      Vec2(0.68, 0.36),
      Vec2(0.54, 0.46),
      Vec2(0.32, 0.53),
      Vec2(0.22, 0.64),
      Vec2(0.38, 0.72),
      Vec2(0.56, 0.79),
      Vec2(0.74, 0.85),
    ],
    2: [
      Vec2(0.14, 0.18),
      Vec2(0.84, 0.18),
      Vec2(0.28, 0.34),
      Vec2(0.70, 0.34),
      Vec2(0.50, 0.48),
      Vec2(0.24, 0.60),
      Vec2(0.76, 0.60),
      Vec2(0.36, 0.73),
      Vec2(0.64, 0.75),
      Vec2(0.50, 0.86),
    ],
    3: [
      Vec2(0.22, 0.16),
      Vec2(0.52, 0.16),
      Vec2(0.82, 0.20),
      Vec2(0.74, 0.36),
      Vec2(0.48, 0.38),
      Vec2(0.24, 0.42),
      Vec2(0.38, 0.58),
      Vec2(0.68, 0.62),
      Vec2(0.46, 0.76),
      Vec2(0.22, 0.84),
    ],
    4: [
      Vec2(0.84, 0.16),
      Vec2(0.84, 0.44),
      Vec2(0.80, 0.76),
      Vec2(0.52, 0.84),
      Vec2(0.20, 0.80),
      Vec2(0.16, 0.50),
      Vec2(0.22, 0.22),
      Vec2(0.52, 0.22),
      Vec2(0.64, 0.42),
      Vec2(0.48, 0.54),
    ],
    5: [
      Vec2(0.16, 0.16),
      Vec2(0.52, 0.16),
      Vec2(0.52, 0.34),
      Vec2(0.20, 0.34),
      Vec2(0.20, 0.56),
      Vec2(0.62, 0.56),
      Vec2(0.82, 0.56),
      Vec2(0.82, 0.74),
      Vec2(0.46, 0.76),
      Vec2(0.72, 0.86),
    ],
    6: [
      Vec2(0.50, 0.14),
      Vec2(0.24, 0.24),
      Vec2(0.76, 0.24),
      Vec2(0.18, 0.84),
      Vec2(0.82, 0.84),
      Vec2(0.32, 0.70),
      Vec2(0.68, 0.70),
      Vec2(0.28, 0.46),
      Vec2(0.72, 0.46),
      Vec2(0.50, 0.50),
    ],
    7: [
      Vec2(0.20, 0.86),
      Vec2(0.80, 0.86),
      Vec2(0.34, 0.72),
      Vec2(0.66, 0.72),
      Vec2(0.50, 0.58),
      Vec2(0.22, 0.46),
      Vec2(0.78, 0.46),
      Vec2(0.36, 0.32),
      Vec2(0.64, 0.30),
      Vec2(0.50, 0.16),
    ],
    8: [
      Vec2(0.84, 0.16),
      Vec2(0.66, 0.24),
      Vec2(0.78, 0.38),
      Vec2(0.54, 0.42),
      Vec2(0.34, 0.48),
      Vec2(0.64, 0.60),
      Vec2(0.44, 0.66),
      Vec2(0.24, 0.68),
      Vec2(0.42, 0.80),
      Vec2(0.20, 0.86),
    ],
    9: [
      Vec2(0.50, 0.15),
      Vec2(0.24, 0.28),
      Vec2(0.76, 0.28),
      Vec2(0.50, 0.44),
      Vec2(0.22, 0.56),
      Vec2(0.78, 0.56),
      Vec2(0.54, 0.68),
      Vec2(0.74, 0.78),
      Vec2(0.44, 0.82),
      Vec2(0.22, 0.86),
    ],
    10: [
      Vec2(0.20, 0.18),
      Vec2(0.44, 0.16),
      Vec2(0.72, 0.22),
      Vec2(0.82, 0.38),
      Vec2(0.60, 0.46),
      Vec2(0.34, 0.48),
      Vec2(0.18, 0.60),
      Vec2(0.42, 0.68),
      Vec2(0.70, 0.72),
      Vec2(0.50, 0.85),
    ],
  };

  Vec2 villageMapCoordAt(int stageNumber) {
    final pts = _countyVillageMapCoords[number] ?? _countyVillageMapCoords[1]!;
    return pts[(stageNumber - 1).clamp(0, pts.length - 1)];
  }
}

/// 《수호알까기 · 탄지무림 심야기습》 1~10현(각 현 10마을 = 총 100판) 720×1360 개별 지형 보정 캠페인 생성기.
class CampaignCatalog {
  static const double arenaWidth = 720.0;
  static const double arenaHeight = 1360.0;

  /// 기본 수호 제단 및 결계 기준 상수 (실제 전투에서는 각 장의 `chapter.towerPos`를 1:1로 사용!).
  static const Vec2 centralTowerPos = Vec2(360.0, 885.0);
  static const Vec2 villageCenter = Vec2(360.0, 885.0);
  static const double outerShieldRadius = 60.0;
  static const double centralTowerRadius = 28.0;

  static List<Vec2> _orbitAltarRing(
    Vec2 center,
    double radius,
    double startDeg, {
    required bool clockwise,
    int steps = 12,
    double stepDegAbs = 46.0,
  }) {
    final safeR = math.max(46.0, radius);
    final stepDeg = clockwise ? stepDegAbs : -stepDegAbs;
    return List<Vec2>.generate(steps, (k) {
      final rad = (startDeg + k * stepDeg) * math.pi / 180.0;
      return Vec2(
        (center.x + math.cos(rad) * safeR).clamp(32.0, arenaWidth - 32.0),
        (center.y + math.sin(rad) * safeR).clamp(48.0, arenaHeight - 36.0),
      );
    });
  }

  static final List<ChapterSpec> chapters = [
    // ==================== 제1장: 좌상단 산채문 → 대각 산비탈 3굽이 → 우하단 신당 마당 (~2,860px) ====================
    ChapterSpec(
      number: 1,
      title: '제1장 · 하산의 길',
      villageName: '흙먼지 마을',
      actLabel: '【기 · 생존 기반 구출】',
      routeTopologyTag: '좌상→우하 대각 산비탈 3굽이',
      chapterTraitTitle: '하산 순풍 지형',
      chapterTraitDesc: '초소 축조 속도 표준(2.0초) · 입문 단거리 산길 · 탄알 직진 안정화',
      buildCostMultiplier: 1.00,
      buildDurationSec: 2.00,
      excavationCostMultiplier: 1.00,
      swarmVolumeMultiplier: 1.00,
      bgAsset: 'assets/images/scenes/bg_night_ch1.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch1.webp',
      bgmAsset: 'bgm_dustyYard.ogg',
      bossName: '독기에 미친 천련 산군',
      actionCaptainTitle: '산비탈 행동대장 혈익귀',
      midBossSquadTitle: '바위고개 철벽 부두목',
      bossPortraitPrefix: 'chonjang',
      storySummary:
          '좌측 천길 폭포 옆 소나무 산비탈 3굽이 외길을 따라 심야 변이군과 행동대장(100타+)·중간보스·천련 산군(1,000타+)이 우하단 신당 마당으로 쳐들어온다!',
      unlockNotice: '기명 심법 수련 개방 · 첫째 문양(각성) · 의용대 지원패 전수',
      surfaceFriction: 1.05,
      stageCount: 10,
      towerPos: const Vec2(468, 980),
      granaryPos: const Vec2(656, 912),
      cropsPos: const Vec2(618, 1072),
      livestockPos: const Vec2(468, 1138),
      roadVisualSpine: const [
        Vec2(138, 118),
        Vec2(185, 195),
        Vec2(305, 268),
        Vec2(448, 326),
        Vec2(546, 390),
        Vec2(542, 456),
        Vec2(435, 505),
        Vec2(285, 536),
        Vec2(176, 588),
        Vec2(156, 658),
        Vec2(198, 735),
        Vec2(288, 822),
        Vec2(382, 908),
        Vec2(468, 980),
      ],
      visualGuideLanes: const [
        [
          Vec2(138, 118),
          Vec2(185, 195),
          Vec2(305, 268),
          Vec2(448, 326),
          Vec2(546, 390),
          Vec2(542, 456),
          Vec2(435, 505),
          Vec2(285, 536),
          Vec2(176, 588),
          Vec2(156, 658),
          Vec2(198, 735),
          Vec2(288, 822),
          Vec2(382, 908),
          Vec2(468, 980),
        ],
      ],
      lanes: [
        [
          const Vec2(138, 118),
          const Vec2(185, 195),
          const Vec2(305, 268),
          const Vec2(448, 326),
          const Vec2(546, 390),
          const Vec2(542, 456),
          const Vec2(435, 505),
          const Vec2(285, 536),
          const Vec2(176, 588),
          const Vec2(156, 658),
          const Vec2(198, 735),
          const Vec2(156, 658),
          const Vec2(176, 588),
          const Vec2(285, 536),
          const Vec2(435, 505),
          const Vec2(285, 536),
          const Vec2(176, 588),
          const Vec2(156, 658),
          const Vec2(198, 735),
          const Vec2(288, 822),
          const Vec2(382, 908),
          ..._orbitAltarRing(
            const Vec2(468, 980),
            76,
            -145,
            clockwise: true,
            steps: 9,
            stepDegAbs: 46,
          ),
          const Vec2(468, 980),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(326, 756), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(212, 808), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(246, 616), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(236, 478), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(468, 396), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(478, 246), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(566, 555), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(168, 285), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(388, 636), radius: 18, sides: 4, rotationSpeedRad: 0.9, restitutionBoost: 1.35),
        TerrainPillar(center: Vec2(368, 315), radius: 18, sides: 5, rotationSpeedRad: -1.0, restitutionBoost: 1.38),
      ],
      cliffs: const [
        CliffZone(center: Vec2(58, 640), radius: 42, label: '서쪽 비류 폭포 낭떠러지'),
        CliffZone(center: Vec2(688, 560), radius: 36, label: '동쪽 기암 절벽'),
        CliffZone(center: Vec2(82, 1080), radius: 44, label: '하단 폭포 심연'),
      ],
    ),

    // ==================== 제2장: 좌·우 측면 성문 진입 → 중앙 X자 대교차로 → 하단 청동 화로 (~3,260px) ====================
    ChapterSpec(
      number: 2,
      title: '제2장 · 기름진 난장',
      villageName: '통통 객잔 식량창고',
      actLabel: '【기 · 생존 기반 구출】',
      routeTopologyTag: '좌·우 측면 성문 X자 대교차로',
      chapterTraitTitle: '객잔 기름장판 · 화약유폭',
      chapterTraitDesc: '수호석 탄속 +15% · 화약통 유폭 피해 +45% · 미끄럼 밀침 증폭',
      buildCostMultiplier: 1.04,
      buildDurationSec: 2.15,
      excavationCostMultiplier: 1.06,
      swarmVolumeMultiplier: 1.10,
      bgAsset: 'assets/images/scenes/bg_night_ch2.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch2.webp',
      bgmAsset: 'bgm_oilyTable.ogg',
      bossName: '탐식 천련 변이주방장',
      actionCaptainTitle: '객잔 행동대장 기름익귀',
      midBossSquadTitle: '대곡창 파성 부두목',
      bossPortraitPrefix: 'tongtong',
      storySummary:
          '북쪽 객잔 본관 대신 좌·우 측면 성문 두 곳에서 동시에 쏟아져 나온 탐식 변이군이 한복판 X자 사거리를 교차 돌파하며 하단 청동 화로를 덮친다!',
      unlockNotice: '물자 호송 시스템 정식 개통 · 동료 반달 합류 · 곡사 회전기 개방',
      surfaceFriction: 0.68,
      stageCount: 10,
      towerPos: const Vec2(360, 1084),
      granaryPos: const Vec2(268, 845),
      cropsPos: const Vec2(452, 845),
      livestockPos: const Vec2(642, 695),
      roadVisualSpine: const [
        Vec2(74, 215),
        Vec2(195, 395),
        Vec2(360, 595),
        Vec2(535, 795),
        Vec2(642, 920),
        Vec2(565, 1028),
        Vec2(360, 1084),
      ],
      visualGuideLanes: const [
        [
          Vec2(74, 215),
          Vec2(195, 395),
          Vec2(360, 595),
          Vec2(535, 795),
          Vec2(642, 920),
          Vec2(565, 1028),
          Vec2(360, 1084),
        ],
        [
          Vec2(646, 215),
          Vec2(525, 395),
          Vec2(360, 595),
          Vec2(185, 795),
          Vec2(78, 920),
          Vec2(155, 1028),
          Vec2(360, 1084),
        ],
      ],
      lanes: [
        const [
          Vec2(74, 215),
          Vec2(195, 395),
          Vec2(360, 595),
          Vec2(525, 395),
          Vec2(622, 262),
          Vec2(525, 395),
          Vec2(360, 595),
          Vec2(185, 795),
          Vec2(108, 888),
          Vec2(185, 795),
          Vec2(360, 595),
          Vec2(535, 795),
          Vec2(642, 920),
          Vec2(565, 1028),
          Vec2(360, 1018),
          Vec2(155, 1028),
          Vec2(245, 1068),
          Vec2(360, 1084),
        ],
        const [
          Vec2(646, 215),
          Vec2(525, 395),
          Vec2(360, 595),
          Vec2(195, 395),
          Vec2(98, 262),
          Vec2(195, 395),
          Vec2(360, 595),
          Vec2(535, 795),
          Vec2(612, 888),
          Vec2(535, 795),
          Vec2(360, 595),
          Vec2(185, 795),
          Vec2(78, 920),
          Vec2(155, 1028),
          Vec2(360, 1018),
          Vec2(565, 1028),
          Vec2(475, 1068),
          Vec2(360, 1084),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(224, 608), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(496, 608), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(216, 914), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(504, 914), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(288, 404), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(432, 404), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(152, 1112), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(568, 1112), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(360, 488), radius: 18, sides: 6, rotationSpeedRad: 1.2, restitutionBoost: 1.44),
        TerrainPillar(center: Vec2(360, 718), radius: 18, sides: 6, rotationSpeedRad: -1.2, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(28, 746), radius: 36, label: '객잔 서쪽 낭떠러지'),
        CliffZone(center: Vec2(692, 360), radius: 38, label: '동쪽 연못 수로 해자'),
        CliffZone(center: Vec2(692, 746), radius: 36, label: '장독대 절벽'),
      ],
    ),

    // ==================== 제3장: 북쪽 3수문 → 평행 3운하 섬 & 아치교 → 좌하단 현무 반도 (~3,720px) ====================
    ChapterSpec(
      number: 3,
      title: '제3장 · 거북 장터 야습',
      villageName: '거북 장터 종자·우시장',
      actLabel: '【기 · 생존 기반 구출】',
      routeTopologyTag: '3수문 청옥 운하섬 → 좌하단 현무반도',
      chapterTraitTitle: '청옥 수로 한기 공명',
      chapterTraitDesc: '한빙 빙결·감속 지속 +35% · 아치 돌다리 수로 해자 추락 강화',
      buildCostMultiplier: 1.09,
      buildDurationSec: 2.30,
      excavationCostMultiplier: 1.12,
      swarmVolumeMultiplier: 1.18,
      bgAsset: 'assets/images/scenes/bg_night_ch3.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch3.webp',
      bgmAsset: 'bgm_turtleMarket.ogg',
      bossName: '그림자 천련 자객단주',
      actionCaptainTitle: '운하 행동대장 암영익귀',
      midBossSquadTitle: '우시장 철갑 수문장',
      bossPortraitPrefix: 'jagaek',
      storySummary:
          '북쪽 세 개의 수문에서 쏟아져 내려온 자객 변이군이 3개의 일자 청옥 운하 섬과 아치형 반달 다리를 종횡으로 건너 좌하단 거대 현무 반도를 노린다!',
      unlockNotice: '전국 호송망 확장 · 영수 영귀 금강 개방 · 한빙 역장기 개방',
      surfaceFriction: 0.95,
      stageCount: 10,
      towerPos: const Vec2(172, 1042),
      granaryPos: const Vec2(628, 885),
      cropsPos: const Vec2(488, 1185),
      livestockPos: const Vec2(632, 1095),
      roadVisualSpine: const [
        Vec2(360, 96),
        Vec2(316, 276),
        Vec2(444, 276),
        Vec2(486, 406),
        Vec2(444, 594),
        Vec2(332, 745),
        Vec2(238, 845),
        Vec2(172, 1042),
      ],
      visualGuideLanes: const [
        [
          Vec2(196, 96),
          Vec2(152, 276),
          Vec2(276, 276),
          Vec2(316, 406),
          Vec2(276, 594),
          Vec2(148, 725),
          Vec2(108, 855),
          Vec2(172, 1042),
        ],
        [
          Vec2(360, 96),
          Vec2(316, 276),
          Vec2(444, 276),
          Vec2(486, 406),
          Vec2(444, 594),
          Vec2(332, 745),
          Vec2(238, 845),
          Vec2(172, 1042),
        ],
        [
          Vec2(524, 96),
          Vec2(564, 276),
          Vec2(564, 594),
          Vec2(508, 755),
          Vec2(422, 862),
          Vec2(308, 932),
          Vec2(172, 1042),
        ],
      ],
      lanes: [
        [
          const Vec2(196, 96),
          const Vec2(152, 276),
          const Vec2(276, 276),
          const Vec2(444, 276),
          const Vec2(564, 330),
          const Vec2(564, 550),
          const Vec2(444, 594),
          const Vec2(276, 594),
          const Vec2(152, 550),
          const Vec2(152, 330),
          const Vec2(276, 276),
          const Vec2(316, 430),
          const Vec2(276, 594),
          const Vec2(148, 735),
          const Vec2(108, 855),
          ..._orbitAltarRing(
            const Vec2(188, 1046),
            58,
            -110,
            clockwise: true,
            steps: 28,
            stepDegAbs: 44,
          ),
          const Vec2(172, 1042),
        ],
        [
          const Vec2(524, 96),
          const Vec2(564, 276),
          const Vec2(444, 276),
          const Vec2(276, 276),
          const Vec2(152, 330),
          const Vec2(152, 550),
          const Vec2(276, 594),
          const Vec2(444, 594),
          const Vec2(564, 550),
          const Vec2(564, 330),
          const Vec2(444, 276),
          const Vec2(486, 430),
          const Vec2(444, 594),
          const Vec2(508, 755),
          const Vec2(422, 862),
          const Vec2(308, 932),
          ..._orbitAltarRing(
            const Vec2(188, 1046),
            58,
            -25,
            clockwise: false,
            steps: 26,
            stepDegAbs: 44,
          ),
          const Vec2(172, 1042),
        ],
        [
          const Vec2(360, 96),
          const Vec2(316, 276),
          const Vec2(444, 276),
          const Vec2(564, 330),
          const Vec2(564, 550),
          const Vec2(444, 594),
          const Vec2(276, 594),
          const Vec2(152, 550),
          const Vec2(152, 330),
          const Vec2(276, 276),
          const Vec2(444, 276),
          const Vec2(486, 430),
          const Vec2(444, 594),
          const Vec2(332, 745),
          const Vec2(238, 845),
          ..._orbitAltarRing(
            const Vec2(188, 1046),
            58,
            -60,
            clockwise: true,
            steps: 27,
            stepDegAbs: 44,
          ),
          const Vec2(172, 1042),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(360, 594), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(184, 594), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(360, 406), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(536, 594), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(196, 406), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(524, 406), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(196, 246), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(360, 246), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(524, 246), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(276, 440), radius: 18, sides: 5, rotationSpeedRad: 1.1, restitutionBoost: 1.38),
        TerrainPillar(center: Vec2(444, 440), radius: 18, sides: 6, rotationSpeedRad: -1.2, restitutionBoost: 1.40),
      ],
      cliffs: const [
        CliffZone(center: Vec2(88, 520), radius: 36, label: '서쪽 청옥 대운하'),
        CliffZone(center: Vec2(276, 440), radius: 30, label: '제1수로 급류'),
        CliffZone(center: Vec2(444, 440), radius: 30, label: '제2수로 급류'),
      ],
    ),

    // ==================== 제4장: 우상단 산채문 → 외곽 4면 절벽 시계방향 대나선 → 정중앙 봉화 요새 (~4,338px) ====================
    ChapterSpec(
      number: 4,
      title: '제4장 · 야성의 숲',
      villageName: '쿠비 산채 봉화대',
      actLabel: '【승 · 반격 진법과 구원군】',
      routeTopologyTag: '외곽 절벽 대나선 → 정중앙 봉화요새',
      chapterTraitTitle: '산채 고지 봉화 시야',
      chapterTraitDesc: '중앙·망루 사거리 +24% · 360° 전방위 조준 개방 · 대공 추격 탄속 +18%',
      buildCostMultiplier: 1.14,
      buildDurationSec: 2.45,
      excavationCostMultiplier: 1.18,
      swarmVolumeMultiplier: 1.26,
      bgAsset: 'assets/images/scenes/bg_night_ch4.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch4.webp',
      bgmAsset: 'bgm_kubiForest.ogg',
      bossName: '대삼림 천련 역병군주',
      actionCaptainTitle: '출렁다리 행동대장 취독귀',
      midBossSquadTitle: '봉화대 파성 부두목',
      bossPortraitPrefix: 'kubi',
      storySummary:
          '우상단 산채 성문을 뚫은 변이 대군이 전장 네 변의 천길 절벽길과 3아치 석교·출렁다리를 시계방향 대나선으로 일주해 한복판 정중앙 봉화 요새를 포위한다!',
      unlockNotice: '심야 탐색 시스템 정식 개통 · 둘째 문양(동행) · 동료 구르미 합류',
      surfaceFriction: 1.00,
      stageCount: 10,
      towerPos: const Vec2(365, 672),
      granaryPos: const Vec2(282, 575),
      cropsPos: const Vec2(462, 595),
      livestockPos: const Vec2(365, 755),
      roadVisualSpine: const [
        Vec2(636, 145),
        Vec2(628, 235),
        Vec2(658, 345),
        Vec2(668, 495),
        Vec2(668, 695),
        Vec2(664, 895),
        Vec2(612, 1025),
        Vec2(515, 1086),
        Vec2(355, 1102),
        Vec2(185, 1084),
        Vec2(76, 995),
        Vec2(54, 845),
        Vec2(54, 625),
        Vec2(54, 415),
        Vec2(64, 265),
        Vec2(155, 224),
        Vec2(285, 242),
        Vec2(415, 226),
        Vec2(502, 238),
        Vec2(522, 295),
        Vec2(465, 365),
        Vec2(352, 418),
        Vec2(342, 482),
        Vec2(365, 575),
        Vec2(365, 672),
      ],
      visualGuideLanes: const [
        [
          Vec2(636, 145),
          Vec2(628, 235),
          Vec2(658, 345),
          Vec2(668, 495),
          Vec2(668, 695),
          Vec2(664, 895),
          Vec2(612, 1025),
          Vec2(515, 1086),
          Vec2(355, 1102),
          Vec2(185, 1084),
          Vec2(76, 995),
          Vec2(54, 845),
          Vec2(54, 625),
          Vec2(54, 415),
          Vec2(64, 265),
          Vec2(155, 224),
          Vec2(285, 242),
          Vec2(415, 226),
          Vec2(502, 238),
          Vec2(522, 295),
          Vec2(465, 365),
          Vec2(352, 418),
          Vec2(342, 482),
          Vec2(365, 575),
          Vec2(365, 672),
        ],
      ],
      lanes: [
        [
          const Vec2(636, 145),
          const Vec2(628, 235),
          const Vec2(658, 345),
          const Vec2(668, 495),
          const Vec2(668, 695),
          const Vec2(664, 895),
          const Vec2(612, 1025),
          const Vec2(515, 1086),
          const Vec2(355, 1102),
          const Vec2(185, 1084),
          const Vec2(355, 1102),
          const Vec2(515, 1086),
          const Vec2(355, 1102),
          const Vec2(185, 1084),
          const Vec2(76, 995),
          const Vec2(54, 845),
          const Vec2(54, 625),
          const Vec2(54, 415),
          const Vec2(64, 265),
          const Vec2(155, 224),
          const Vec2(285, 242),
          const Vec2(415, 226),
          const Vec2(502, 238),
          const Vec2(522, 295),
          const Vec2(465, 365),
          const Vec2(352, 418),
          const Vec2(342, 482),
          ..._orbitAltarRing(
            const Vec2(365, 672),
            56,
            -90,
            clockwise: true,
            steps: 11,
            stepDegAbs: 46,
          ),
          const Vec2(365, 672),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(386, 514), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(424, 344), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(82, 512), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(96, 728), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(236, 1028), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(476, 1028), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(636, 816), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(636, 598), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(624, 396), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(82, 312), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.highWatchtower),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(225, 360), radius: 18, sides: 3, rotationSpeedRad: 1.4, restitutionBoost: 1.44),
        TerrainPillar(center: Vec2(520, 880), radius: 18, sides: 3, rotationSpeedRad: -1.4, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(198, 845), radius: 46, label: '봉화대 서남 천길 심연'),
        CliffZone(center: Vec2(538, 725), radius: 44, label: '폭포 구렁 낭떠러지'),
        CliffZone(center: Vec2(355, 1245), radius: 42, label: '석교 아래 급류 계곡'),
      ],
    ),

    // ==================== 제5장: 좌·우 북문 → 100% 90° 직각 시계태엽 대리석 미궁 → 우하단 천구의 (~4,785px) ====================
    ChapterSpec(
      number: 5,
      title: '제5장 · 철벽의 진인',
      villageName: '로직 학당 기관전',
      actLabel: '【승 · 반격 진법과 구원군】',
      routeTopologyTag: '90° 직각 시계태엽 미궁 → 우하단 천구의',
      chapterTraitTitle: '기관 직각 반사 · 증폭 과부하',
      chapterTraitDesc: '모든 탄알 벽면 도탄 +2회 · 내공 증폭기 버프 효율 +35%',
      isOrthogonalLabyrinth: true,
      buildCostMultiplier: 1.19,
      buildDurationSec: 2.60,
      excavationCostMultiplier: 1.25,
      swarmVolumeMultiplier: 1.35,
      bgAsset: 'assets/images/scenes/bg_night_ch5.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch5.webp',
      bgmAsset: 'bgm_logicMarble.ogg',
      bossName: '폭주 천련 기관거신병',
      actionCaptainTitle: '태엽회랑 행동대장 철익귀',
      midBossSquadTitle: '천구의 강철 중갑장',
      bossPortraitPrefix: 'logic',
      storySummary:
          '곡선이 단 하나도 없는 90도 직각 대리석·황동 태엽 미궁 복도를 따라 기관 변이 대군이 직각 행군하며 우하단 청옥 천구의 코어를 노린다!',
      unlockNotice: '내공 증폭기 개방 · 셋째 문양(자동 어기어석) · 동료 정각 합류',
      surfaceFriction: 0.78,
      stageCount: 10,
      towerPos: const Vec2(512, 1052),
      granaryPos: const Vec2(95, 1045),
      cropsPos: const Vec2(95, 1215),
      livestockPos: const Vec2(225, 1145),
      roadVisualSpine: const [
        Vec2(108, 125),
        Vec2(108, 282),
        Vec2(272, 282),
        Vec2(272, 422),
        Vec2(94, 422),
        Vec2(94, 555),
        Vec2(288, 555),
        Vec2(288, 696),
        Vec2(108, 696),
        Vec2(108, 872),
        Vec2(512, 872),
        Vec2(512, 1052),
      ],
      visualGuideLanes: const [
        [
          Vec2(108, 125),
          Vec2(108, 282),
          Vec2(272, 282),
          Vec2(272, 422),
          Vec2(94, 422),
          Vec2(94, 555),
          Vec2(288, 555),
          Vec2(288, 696),
          Vec2(108, 696),
          Vec2(108, 892),
          Vec2(428, 892),
          Vec2(428, 932),
          Vec2(512, 932),
          Vec2(512, 1052),
        ],
        [
          Vec2(616, 125),
          Vec2(616, 204),
          Vec2(456, 204),
          Vec2(456, 318),
          Vec2(616, 318),
          Vec2(616, 444),
          Vec2(498, 444),
          Vec2(498, 582),
          Vec2(624, 582),
          Vec2(624, 718),
          Vec2(512, 718),
          Vec2(512, 932),
          Vec2(512, 1052),
        ],
      ],
      lanes: const [
        [
          Vec2(108, 125),
          Vec2(108, 282),
          Vec2(272, 282),
          Vec2(272, 422),
          Vec2(94, 422),
          Vec2(94, 555),
          Vec2(288, 555),
          Vec2(288, 696),
          Vec2(108, 696),
          Vec2(108, 892),
          Vec2(428, 892),
          Vec2(428, 936),
          Vec2(598, 936),
          Vec2(598, 1146),
          Vec2(428, 1146),
          Vec2(428, 936),
          Vec2(598, 936),
          Vec2(598, 1146),
          Vec2(428, 1146),
          Vec2(428, 936),
          Vec2(598, 936),
          Vec2(598, 1146),
          Vec2(428, 1146),
          Vec2(428, 936),
          Vec2(598, 936),
          Vec2(598, 1146),
          Vec2(428, 1146),
          Vec2(428, 936),
          Vec2(512, 936),
          Vec2(512, 1052),
        ],
        [
          Vec2(616, 125),
          Vec2(616, 204),
          Vec2(456, 204),
          Vec2(456, 318),
          Vec2(616, 318),
          Vec2(616, 444),
          Vec2(498, 444),
          Vec2(498, 582),
          Vec2(624, 582),
          Vec2(624, 718),
          Vec2(512, 718),
          Vec2(512, 936),
          Vec2(428, 936),
          Vec2(428, 1146),
          Vec2(598, 1146),
          Vec2(598, 936),
          Vec2(428, 936),
          Vec2(428, 1146),
          Vec2(598, 1146),
          Vec2(598, 936),
          Vec2(428, 936),
          Vec2(428, 1146),
          Vec2(598, 1146),
          Vec2(598, 936),
          Vec2(428, 936),
          Vec2(428, 1146),
          Vec2(598, 1146),
          Vec2(598, 936),
          Vec2(428, 936),
          Vec2(428, 1146),
          Vec2(512, 1146),
          Vec2(512, 1052),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(494, 756), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(106, 912), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(242, 756), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(632, 608), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(86, 612), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(558, 512), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(218, 488), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(472, 368), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(108, 344), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(566, 252), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(606, 178), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.highWatchtower),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(368, 565), radius: 20, sides: 8, rotationSpeedRad: 1.35, restitutionBoost: 1.48),
        TerrainPillar(center: Vec2(368, 295), radius: 18, sides: 8, rotationSpeedRad: -1.35, restitutionBoost: 1.48),
      ],
      cliffs: const [
        CliffZone(center: Vec2(368, 565), radius: 44, label: '중앙 대태엽 기어 구동공'),
        CliffZone(center: Vec2(368, 760), radius: 34, label: '기관 동력 심연'),
        CliffZone(center: Vec2(28, 512), radius: 30, label: '서쪽 기관 수렁'),
      ],
    ),

    // ==================== 제6장: 북설산 성문 + 남빙하 성문 상하 양면 협공 → 정중앙 백옥 대광장 (~5,248px) ====================
    ChapterSpec(
      number: 6,
      title: '제6장 · 무림맹 본단 혈전',
      villageName: '무림맹 대광장',
      actLabel: '【승 · 1부 절정 결전】',
      routeTopologyTag: '북설산·남빙하 양면포위 → 정중앙 광장',
      chapterTraitTitle: '무림맹 정오 호법진',
      chapterTraitDesc: '외곽 방어막 최대치 +30% · 360° 상하 양면 방어 · 다병종 시너지 +20%',
      buildCostMultiplier: 1.24,
      buildDurationSec: 2.75,
      excavationCostMultiplier: 1.32,
      swarmVolumeMultiplier: 1.45,
      bgAsset: 'assets/images/scenes/bg_night_ch6.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch6.webp',
      bgmAsset: 'bgm_murimIce.ogg',
      bossName: '심야 천련 흑화마룡수',
      actionCaptainTitle: '설원 행동대장 한빙철익귀',
      midBossSquadTitle: '쌍룡계단 파성 부두목',
      bossPortraitPrefix: 'maengju',
      storySummary:
          '북쪽 설산 계단과 남쪽 만년 빙하 협곡 위·아래 양면에서 동시에 변이 대군이 몰려와 정중앙 백옥 대광장을 겹겹이 포위한다! 사형 묵현을 구원하라!',
      unlockNotice: '황금 지원패(무림수호단 출두야~~!!) 완성 · 동료 용아 및 위기 난입 묵현 합류',
      surfaceFriction: 0.76,
      stageCount: 10,
      towerPos: const Vec2(360, 596),
      granaryPos: const Vec2(64, 565),
      cropsPos: const Vec2(360, 468),
      livestockPos: const Vec2(656, 565),
      roadVisualSpine: const [
        Vec2(360, 92),
        Vec2(435, 162),
        Vec2(265, 228),
        Vec2(442, 298),
        Vec2(345, 378),
        Vec2(360, 468),
        Vec2(360, 596),
      ],
      visualGuideLanes: const [
        [
          Vec2(360, 92),
          Vec2(435, 162),
          Vec2(265, 228),
          Vec2(442, 298),
          Vec2(345, 378),
          Vec2(360, 468),
          Vec2(360, 596),
        ],
        [
          Vec2(360, 1245),
          Vec2(305, 1142),
          Vec2(445, 1042),
          Vec2(272, 942),
          Vec2(368, 842),
          Vec2(360, 732),
          Vec2(360, 596),
        ],
      ],
      lanes: [
        [
          const Vec2(360, 92),
          const Vec2(435, 162),
          const Vec2(265, 228),
          const Vec2(442, 298),
          const Vec2(345, 378),
          const Vec2(442, 298),
          const Vec2(265, 228),
          const Vec2(442, 298),
          const Vec2(345, 378),
          ..._orbitAltarRing(
            const Vec2(360, 596),
            96,
            -90,
            clockwise: true,
            steps: 60,
            stepDegAbs: 36,
          ),
          const Vec2(360, 596),
        ],
        [
          const Vec2(360, 1245),
          const Vec2(305, 1142),
          const Vec2(445, 1042),
          const Vec2(272, 942),
          const Vec2(368, 842),
          const Vec2(272, 942),
          const Vec2(445, 1042),
          const Vec2(272, 942),
          const Vec2(368, 842),
          ..._orbitAltarRing(
            const Vec2(360, 596),
            96,
            90,
            clockwise: false,
            steps: 60,
            stepDegAbs: 36,
          ),
          const Vec2(360, 596),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(228, 398), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(492, 398), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(232, 804), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(488, 804), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(180, 516), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(540, 516), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(180, 688), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(540, 688), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(168, 446), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(552, 446), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(168, 754), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(552, 754), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.spiritSpring),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(246, 596), radius: 18, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(474, 596), radius: 18, sides: 6, rotationSpeedRad: -1.5, restitutionBoost: 1.45),
      ],
      cliffs: const [
        CliffZone(center: Vec2(108, 960), radius: 42, label: '서남 빙벽 천길 협곡'),
        CliffZone(center: Vec2(612, 960), radius: 42, label: '동남 빙하 폭포 구렁'),
        CliffZone(center: Vec2(48, 260), radius: 34, label: '북서 설산 낭떠러지'),
      ],
    ),

    // ==================== 제7장: 하단 사막 쌍문 출발 → 남→북 역진격 거대 8자 오아시스 → 최상단 일월성채 (~5,620px) ====================
    ChapterSpec(
      number: 7,
      title: '제7장 · 열사의 협곡',
      villageName: '사막 일월 절벽성채',
      actLabel: '【전 · 독기 근원 대원정】',
      routeTopologyTag: '남→북 역진격 8자 협곡 → 상단 성채',
      chapterTraitTitle: '열사 광풍 · 태양 작열',
      chapterTraitDesc: '하단→상단 역방향 기습 · 변이 이속 +8% · 치명타 시 태양 화염 폭발!',
      buildCostMultiplier: 1.29,
      buildDurationSec: 2.90,
      excavationCostMultiplier: 1.38,
      swarmVolumeMultiplier: 1.55,
      bgAsset: 'assets/images/scenes/bg_night_ch7.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch7.webp',
      bgmAsset: 'bgm_dustyYard.ogg',
      bossName: '모래폭풍 천련 사막역병왕',
      actionCaptainTitle: '사구 행동대장 열풍익귀',
      midBossSquadTitle: '오아시스 파성 거신장',
      bossPortraitPrefix: 'sawang',
      storySummary:
          '화면 맨 아래 남쪽 모래폭풍 성문 두 곳에서 역방향으로 치고 올라오는 변이 대군이 거대 8자(∞) 오아시스 다리를 교차 등반해 최상단 일월 성채를 공격한다!',
      unlockNotice: '4형(극의) 발사대 제련 완성 · 천마 화신 영입 개방',
      surfaceFriction: 1.12,
      stageCount: 10,
      towerPos: const Vec2(360, 212),
      granaryPos: const Vec2(76, 138),
      cropsPos: const Vec2(92, 198),
      livestockPos: const Vec2(628, 198),
      roadVisualSpine: const [
        Vec2(118, 1245),
        Vec2(202, 1125),
        Vec2(156, 965),
        Vec2(156, 825),
        Vec2(360, 696),
        Vec2(546, 595),
        Vec2(552, 465),
        Vec2(468, 355),
        Vec2(360, 305),
        Vec2(360, 212),
      ],
      visualGuideLanes: const [
        [
          Vec2(118, 1245),
          Vec2(202, 1125),
          Vec2(156, 965),
          Vec2(156, 825),
          Vec2(360, 696),
          Vec2(546, 595),
          Vec2(552, 465),
          Vec2(468, 355),
          Vec2(360, 305),
          Vec2(360, 212),
        ],
        [
          Vec2(602, 1245),
          Vec2(518, 1125),
          Vec2(564, 965),
          Vec2(564, 825),
          Vec2(360, 696),
          Vec2(174, 595),
          Vec2(168, 465),
          Vec2(252, 355),
          Vec2(360, 305),
          Vec2(360, 212),
        ],
      ],
      lanes: const [
        [
          Vec2(118, 1245),
          Vec2(202, 1125),
          Vec2(156, 965),
          Vec2(156, 825),
          Vec2(360, 696),
          Vec2(564, 825),
          Vec2(564, 965),
          Vec2(360, 1068),
          Vec2(156, 965),
          Vec2(156, 825),
          Vec2(360, 696),
          Vec2(564, 825),
          Vec2(564, 965),
          Vec2(360, 1068),
          Vec2(156, 965),
          Vec2(156, 825),
          Vec2(360, 696),
          Vec2(546, 595),
          Vec2(552, 465),
          Vec2(360, 312),
          Vec2(168, 465),
          Vec2(174, 595),
          Vec2(360, 696),
          Vec2(546, 595),
          Vec2(552, 465),
          Vec2(360, 312),
          Vec2(168, 465),
          Vec2(252, 355),
          Vec2(360, 298),
          Vec2(360, 212),
        ],
        [
          Vec2(602, 1245),
          Vec2(518, 1125),
          Vec2(564, 965),
          Vec2(564, 825),
          Vec2(360, 696),
          Vec2(156, 825),
          Vec2(156, 965),
          Vec2(360, 1068),
          Vec2(564, 965),
          Vec2(564, 825),
          Vec2(360, 696),
          Vec2(156, 825),
          Vec2(156, 965),
          Vec2(360, 1068),
          Vec2(564, 965),
          Vec2(564, 825),
          Vec2(360, 696),
          Vec2(174, 595),
          Vec2(168, 465),
          Vec2(360, 312),
          Vec2(552, 465),
          Vec2(546, 595),
          Vec2(360, 696),
          Vec2(174, 595),
          Vec2(168, 465),
          Vec2(360, 312),
          Vec2(552, 465),
          Vec2(468, 355),
          Vec2(360, 298),
          Vec2(360, 212),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(172, 344), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(548, 344), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(106, 434), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(614, 434), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(108, 578), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(612, 578), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(172, 732), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(548, 732), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(102, 822), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(618, 822), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(118, 968), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(602, 968), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.highWatchtower),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(360, 495), radius: 19, sides: 4, rotationSpeedRad: 1.35, restitutionBoost: 1.42),
        TerrainPillar(center: Vec2(360, 905), radius: 19, sides: 4, rotationSpeedRad: -1.35, restitutionBoost: 1.42),
      ],
      cliffs: const [
        CliffZone(center: Vec2(360, 495), radius: 48, label: '상단 오아시스 심연'),
        CliffZone(center: Vec2(360, 905), radius: 48, label: '하단 오아시스 심연'),
        CliffZone(center: Vec2(28, 696), radius: 34, label: '열사 서쪽 벼랑'),
      ],
    ),

    // ==================== 제8장: 우상단 해적선 2척 → 사선 4척 대함선 도교 지그재그 → 좌하단 등대 구호항 (~6,080px) ====================
    ChapterSpec(
      number: 8,
      title: '제8장 · 흑룡 해적선 구호항',
      villageName: '구호 곡식 함대 등대항',
      actLabel: '【전 · 독기 근원 대원정】',
      routeTopologyTag: '우상 해적선 → 4척 전함 도교 → 좌하 등대항',
      chapterTraitTitle: '폭풍 파도 현측 포격',
      chapterTraitDesc: '전 포대 밀침(넉백) +38% · 현측 바다 추락 낙사 판정 강화',
      buildCostMultiplier: 1.34,
      buildDurationSec: 3.05,
      excavationCostMultiplier: 1.45,
      swarmVolumeMultiplier: 1.65,
      bgAsset: 'assets/images/scenes/bg_night_ch8.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch8.webp',
      bgmAsset: 'bgm_oilyTable.ogg',
      bossName: '심해 천련 흑독대촉수왕',
      actionCaptainTitle: '함대 상공 행동대장 흑랑익귀',
      midBossSquadTitle: '현측 철갑 파쇄장',
      bossPortraitPrefix: 'haejeok',
      storySummary:
          '거친 밤바다 우상단 해적 돌격선에서 넘어온 심해 변이 대군이 사선으로 연결된 4척의 거대 전함 갑판과 도교를 지그재그로 돌파해 좌하단 석조 등대 구호항을 습격한다!',
      unlockNotice: '영수 천룡 금룡 개방 · 동료 검황 영입 개방',
      surfaceFriction: 0.82,
      stageCount: 10,
      towerPos: const Vec2(172, 1148),
      granaryPos: const Vec2(242, 1138),
      cropsPos: const Vec2(358, 1185),
      livestockPos: const Vec2(126, 1085),
      roadVisualSpine: const [
        Vec2(655, 148),
        Vec2(545, 205),
        Vec2(395, 175),
        Vec2(265, 145),
        Vec2(395, 248),
        Vec2(348, 338),
        Vec2(255, 385),
        Vec2(435, 475),
        Vec2(395, 578),
        Vec2(275, 615),
        Vec2(455, 705),
        Vec2(378, 785),
        Vec2(265, 815),
        Vec2(515, 925),
        Vec2(355, 965),
        Vec2(282, 1045),
        Vec2(172, 1148),
      ],
      visualGuideLanes: const [
        [
          Vec2(655, 148),
          Vec2(545, 205),
          Vec2(395, 175),
          Vec2(265, 145),
          Vec2(395, 248),
          Vec2(348, 338),
          Vec2(255, 385),
          Vec2(435, 475),
          Vec2(395, 578),
          Vec2(275, 615),
          Vec2(455, 705),
          Vec2(378, 785),
          Vec2(265, 815),
          Vec2(515, 925),
          Vec2(355, 965),
          Vec2(282, 1045),
          Vec2(172, 1148),
        ],
        [
          Vec2(668, 435),
          Vec2(535, 492),
          Vec2(435, 475),
          Vec2(395, 578),
          Vec2(275, 615),
          Vec2(455, 705),
          Vec2(378, 785),
          Vec2(265, 815),
          Vec2(515, 925),
          Vec2(355, 965),
          Vec2(282, 1045),
          Vec2(172, 1148),
        ],
      ],
      lanes: const [
        [
          Vec2(655, 148),
          Vec2(545, 205),
          Vec2(395, 175),
          Vec2(235, 138),
          Vec2(515, 265),
          Vec2(235, 138),
          Vec2(395, 248),
          Vec2(348, 338),
          Vec2(225, 378),
          Vec2(525, 515),
          Vec2(225, 378),
          Vec2(485, 495),
          Vec2(395, 578),
          Vec2(235, 605),
          Vec2(535, 735),
          Vec2(235, 605),
          Vec2(535, 735),
          Vec2(378, 785),
          Vec2(245, 795),
          Vec2(585, 945),
          Vec2(245, 795),
          Vec2(585, 945),
          Vec2(245, 795),
          Vec2(465, 905),
          Vec2(355, 965),
          Vec2(282, 1045),
          Vec2(225, 1108),
          Vec2(172, 1148),
        ],
        [
          Vec2(668, 435),
          Vec2(535, 492),
          Vec2(435, 475),
          Vec2(245, 392),
          Vec2(525, 515),
          Vec2(245, 392),
          Vec2(485, 495),
          Vec2(395, 578),
          Vec2(235, 605),
          Vec2(535, 735),
          Vec2(235, 605),
          Vec2(535, 735),
          Vec2(235, 605),
          Vec2(535, 735),
          Vec2(378, 785),
          Vec2(245, 795),
          Vec2(585, 945),
          Vec2(245, 795),
          Vec2(585, 945),
          Vec2(245, 795),
          Vec2(585, 945),
          Vec2(355, 965),
          Vec2(282, 1045),
          Vec2(225, 1108),
          Vec2(172, 1148),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(304, 826), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(434, 888), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(536, 926), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(218, 622), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(346, 672), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(468, 718), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(216, 398), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(342, 446), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(458, 492), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(198, 166), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(322, 202), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(448, 236), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 12, pos: Vec2(152, 1068), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(348, 338), radius: 18, sides: 6, rotationSpeedRad: 1.5, restitutionBoost: 1.48),
        TerrainPillar(center: Vec2(395, 578), radius: 18, sides: 5, rotationSpeedRad: -1.4, restitutionBoost: 1.44),
        TerrainPillar(center: Vec2(378, 785), radius: 18, sides: 5, rotationSpeedRad: 1.4, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(72, 740), radius: 46, label: '좌현 검푸른 폭풍 해역'),
        CliffZone(center: Vec2(638, 690), radius: 46, label: '우현 심해 소용돌이'),
        CliffZone(center: Vec2(560, 1180), radius: 48, label: '남동 암초 급류 바다'),
      ],
    ),

    // ==================== 제9장: 끓는 용암 위 6개 육각 화산섬 쇠사슬 다리망 → 좌하단 적염신전 (~6,580px) ====================
    ChapterSpec(
      number: 9,
      title: '제9장 · 화염산 봉인굴',
      villageName: '화염산 적염 봉인신전',
      actLabel: '【전 · 독기 근원 대원정】',
      routeTopologyTag: '6화산섬 사슬현수교 → 좌하단 봉인진',
      chapterTraitTitle: '지옥 화구 용암 분출',
      chapterTraitDesc: '회심 타격 시 용암 화염기둥 폭발 · 변이 공격력 +15%',
      buildCostMultiplier: 1.39,
      buildDurationSec: 3.20,
      excavationCostMultiplier: 1.52,
      swarmVolumeMultiplier: 1.76,
      bgAsset: 'assets/images/scenes/bg_night_ch9.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch9.webp',
      bgmAsset: 'bgm_clash.ogg',
      bossName: '분화구 천련 심연염마왕',
      actionCaptainTitle: '화구 상공 행동대장 염익귀',
      midBossSquadTitle: '현무암교 용암 거수장',
      bossPortraitPrefix: 'hongryeon',
      storySummary:
          '시뻘겋게 끓는 용암 바다 위 6개의 육각 흑요석 화산섬을 잇는 쇠사슬 현수교 거미줄을 건너 심연염마왕(1,000타+) 군단이 좌하단 적염 봉인 신전으로 진격한다!',
      unlockNotice: '한철·신물 수호석 제련 극대화 · 동료 무량 신승 개방 · 천상 계단 개통',
      surfaceFriction: 0.90,
      stageCount: 10,
      towerPos: const Vec2(202, 1098),
      granaryPos: const Vec2(535, 875),
      cropsPos: const Vec2(555, 985),
      livestockPos: const Vec2(635, 925),
      roadVisualSpine: const [
        Vec2(358, 115),
        Vec2(332, 355),
        Vec2(265, 565),
        Vec2(405, 725),
        Vec2(505, 865),
        Vec2(375, 1025),
        Vec2(202, 1098),
      ],
      visualGuideLanes: const [
        [
          Vec2(112, 155),
          Vec2(145, 365),
          Vec2(228, 535),
          Vec2(215, 765),
          Vec2(202, 965),
          Vec2(202, 1098),
        ],
        [
          Vec2(358, 115),
          Vec2(332, 355),
          Vec2(265, 565),
          Vec2(405, 725),
          Vec2(505, 865),
          Vec2(375, 1025),
          Vec2(202, 1098),
        ],
        [
          Vec2(598, 195),
          Vec2(578, 525),
          Vec2(555, 815),
          Vec2(495, 935),
          Vec2(375, 1025),
          Vec2(202, 1098),
        ],
      ],
      lanes: [
        [
          const Vec2(112, 155),
          const Vec2(145, 365),
          const Vec2(228, 535),
          const Vec2(332, 355),
          const Vec2(358, 145),
          const Vec2(332, 355),
          const Vec2(265, 565),
          const Vec2(465, 425),
          const Vec2(585, 255),
          const Vec2(578, 525),
          const Vec2(555, 815),
          const Vec2(405, 725),
          const Vec2(255, 565),
          const Vec2(215, 765),
          const Vec2(202, 965),
          const Vec2(375, 1025),
          const Vec2(505, 885),
          const Vec2(405, 725),
          const Vec2(255, 585),
          const Vec2(405, 725),
          const Vec2(505, 885),
          const Vec2(375, 1025),
          ..._orbitAltarRing(
            const Vec2(216, 1096),
            56,
            -30,
            clockwise: true,
            steps: 38,
            stepDegAbs: 42,
          ),
          const Vec2(202, 1098),
        ],
        [
          const Vec2(598, 195),
          const Vec2(465, 425),
          const Vec2(255, 565),
          const Vec2(145, 365),
          const Vec2(112, 165),
          const Vec2(145, 365),
          const Vec2(255, 565),
          const Vec2(332, 355),
          const Vec2(358, 145),
          const Vec2(332, 355),
          const Vec2(255, 585),
          const Vec2(405, 725),
          const Vec2(555, 815),
          const Vec2(578, 525),
          const Vec2(555, 815),
          const Vec2(405, 725),
          const Vec2(255, 585),
          const Vec2(215, 765),
          const Vec2(202, 965),
          const Vec2(375, 1025),
          const Vec2(505, 885),
          const Vec2(375, 1025),
          ..._orbitAltarRing(
            const Vec2(216, 1096),
            56,
            -90,
            clockwise: false,
            steps: 36,
            stepDegAbs: 42,
          ),
          const Vec2(202, 1098),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(76, 1146), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(332, 1146), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(202, 1236), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(442, 918), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(634, 1004), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(634, 796), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(112, 598), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(342, 598), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(56, 242), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(178, 268), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(284, 184), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(434, 184), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 12, pos: Vec2(504, 282), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 13, pos: Vec2(658, 298), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(255, 565), radius: 19, sides: 5, rotationSpeedRad: 1.6, restitutionBoost: 1.46),
        TerrainPillar(center: Vec2(465, 425), radius: 18, sides: 5, rotationSpeedRad: -1.6, restitutionBoost: 1.46),
        TerrainPillar(center: Vec2(405, 725), radius: 18, sides: 6, rotationSpeedRad: 1.35, restitutionBoost: 1.44),
      ],
      cliffs: const [
        CliffZone(center: Vec2(72, 780), radius: 46, label: '서쪽 끓는 용암강'),
        CliffZone(center: Vec2(465, 585), radius: 42, label: '중앙 화산 용암 해자'),
        CliffZone(center: Vec2(515, 1185), radius: 48, label: '남동 분화구 심연'),
      ],
    ),

    // ==================== 제10장: 운해 위 7성좌 백옥 부유섬 황금 무지개교 대순례 → 태극 신전 (~7,250px) ====================
    ChapterSpec(
      number: 10,
      title: '제10장 · 천상 탄신전',
      villageName: '태초 태극석 부유신전 (보스 10연전)',
      actLabel: '【결 · 최종 정화 결전】',
      routeTopologyTag: '7성좌 부유섬 무지개교 → 태극신전',
      chapterTraitTitle: '태초 성좌 공명 · 천상 결전',
      chapterTraitDesc: '회심 피해 +45% · 내공 충전 +30% · 최장 순례길 · 포대 건설 난도 최고조',
      buildCostMultiplier: 1.45,
      buildDurationSec: 3.40,
      excavationCostMultiplier: 1.60,
      swarmVolumeMultiplier: 1.88,
      bgAsset: 'assets/images/scenes/bg_night_ch10.webp',
      floorAsset: 'assets/images/scenes/floor_night_ch10.webp',
      bgmAsset: 'bgm_boss.ogg',
      bossName: '심야에 물든 태초 탄신',
      actionCaptainTitle: '천상 행동대장 성좌철익귀',
      midBossSquadTitle: '태극회랑 금강 수문장',
      bossPortraitPrefix: 'tansin',
      storySummary:
          '끝없는 밤구름 바다 위에 떠 있는 7개의 백옥 성좌 부유섬과 황금 무지개 다리를 차례차례 순례하며 1,200~2,000타+ 천련 보스 10연전이 태극 음양 신전으로 강림한다!',
      unlockNotice: '열 마을 완전 정화 대단원 귀향 엔딩 · 수호신 칭호 획득',
      surfaceFriction: 0.82,
      stageCount: 10,
      towerPos: const Vec2(360, 1002),
      granaryPos: const Vec2(114, 1192),
      cropsPos: const Vec2(616, 1212),
      livestockPos: const Vec2(604, 1092),
      roadVisualSpine: const [
        Vec2(146, 112),
        Vec2(188, 265),
        Vec2(245, 222),
        Vec2(310, 192),
        Vec2(382, 225),
        Vec2(450, 265),
        Vec2(518, 325),
        Vec2(564, 382),
        Vec2(518, 448),
        Vec2(456, 488),
        Vec2(385, 548),
        Vec2(310, 588),
        Vec2(252, 648),
        Vec2(210, 688),
        Vec2(248, 845),
        Vec2(360, 1002),
      ],
      visualGuideLanes: const [
        [
          Vec2(146, 112),
          Vec2(188, 265),
          Vec2(245, 222),
          Vec2(310, 192),
          Vec2(382, 225),
          Vec2(450, 265),
          Vec2(518, 325),
          Vec2(564, 382),
          Vec2(518, 448),
          Vec2(456, 488),
          Vec2(385, 548),
          Vec2(310, 588),
          Vec2(252, 648),
          Vec2(210, 688),
          Vec2(248, 845),
          Vec2(360, 1002),
        ],
      ],
      lanes: [
        [
          const Vec2(146, 112),
          const Vec2(188, 265),
          const Vec2(245, 222),
          const Vec2(310, 192),
          const Vec2(382, 225),
          const Vec2(450, 265),
          const Vec2(518, 325),
          const Vec2(564, 382),
          const Vec2(518, 448),
          const Vec2(456, 488),
          const Vec2(385, 548),
          const Vec2(310, 588),
          const Vec2(252, 648),
          const Vec2(210, 688),
          const Vec2(252, 648),
          const Vec2(310, 588),
          const Vec2(385, 548),
          const Vec2(456, 488),
          const Vec2(518, 448),
          const Vec2(564, 382),
          const Vec2(518, 325),
          const Vec2(450, 265),
          const Vec2(382, 225),
          const Vec2(310, 192),
          const Vec2(382, 225),
          const Vec2(450, 265),
          const Vec2(518, 325),
          const Vec2(564, 382),
          const Vec2(518, 448),
          const Vec2(456, 488),
          const Vec2(385, 548),
          const Vec2(310, 588),
          const Vec2(252, 648),
          const Vec2(210, 688),
          const Vec2(252, 648),
          const Vec2(310, 588),
          const Vec2(385, 548),
          const Vec2(456, 488),
          const Vec2(385, 548),
          const Vec2(310, 588),
          const Vec2(252, 648),
          const Vec2(210, 688),
          const Vec2(248, 845),
          ..._orbitAltarRing(
            const Vec2(360, 1002),
            64,
            -125,
            clockwise: true,
            steps: 80,
            stepDegAbs: 38,
          ),
          const Vec2(360, 1002),
        ],
        [
          const Vec2(158, 118),
          const Vec2(198, 258),
          const Vec2(252, 218),
          const Vec2(316, 188),
          const Vec2(388, 220),
          const Vec2(456, 262),
          const Vec2(524, 322),
          const Vec2(570, 382),
          const Vec2(524, 452),
          const Vec2(462, 492),
          const Vec2(390, 552),
          const Vec2(316, 592),
          const Vec2(258, 652),
          const Vec2(216, 692),
          const Vec2(258, 652),
          const Vec2(316, 592),
          const Vec2(390, 552),
          const Vec2(462, 492),
          const Vec2(524, 452),
          const Vec2(570, 382),
          const Vec2(524, 322),
          const Vec2(456, 262),
          const Vec2(388, 220),
          const Vec2(316, 188),
          const Vec2(388, 220),
          const Vec2(456, 262),
          const Vec2(524, 322),
          const Vec2(570, 382),
          const Vec2(524, 452),
          const Vec2(462, 492),
          const Vec2(390, 552),
          const Vec2(316, 592),
          const Vec2(258, 652),
          const Vec2(216, 692),
          const Vec2(258, 652),
          const Vec2(316, 592),
          const Vec2(390, 552),
          const Vec2(462, 492),
          const Vec2(390, 552),
          const Vec2(316, 592),
          const Vec2(258, 652),
          const Vec2(216, 692),
          const Vec2(254, 848),
          ..._orbitAltarRing(
            const Vec2(360, 1002),
            64,
            -125,
            clockwise: false,
            steps: 80,
            stepDegAbs: 38,
          ),
          const Vec2(360, 1002),
        ],
      ],
      mounts: const [
        LauncherMountSlot(slotIndex: 0, pos: Vec2(178, 712), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 1, pos: Vec2(240, 712), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 2, pos: Vec2(278, 612), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 3, pos: Vec2(342, 612), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 4, pos: Vec2(424, 512), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 5, pos: Vec2(488, 512), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 6, pos: Vec2(532, 404), recommendedType: LauncherType.curveSpin, terrainType: MountTerrainType.fortressBastion),
        LauncherMountSlot(slotIndex: 7, pos: Vec2(596, 404), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 8, pos: Vec2(418, 288), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 9, pos: Vec2(482, 288), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.ambushRidge),
        LauncherMountSlot(slotIndex: 10, pos: Vec2(278, 206), recommendedType: LauncherType.qiAmplifier, terrainType: MountTerrainType.spiritSpring),
        LauncherMountSlot(slotIndex: 11, pos: Vec2(342, 206), recommendedType: LauncherType.frostField, terrainType: MountTerrainType.chokeGate),
        LauncherMountSlot(slotIndex: 12, pos: Vec2(156, 288), recommendedType: LauncherType.heavy, terrainType: MountTerrainType.highWatchtower),
        LauncherMountSlot(slotIndex: 13, pos: Vec2(222, 288), recommendedType: LauncherType.rapid, terrainType: MountTerrainType.fortressBastion),
      ],
      pillars: const [
        TerrainPillar(center: Vec2(382, 395), radius: 20, sides: 8, rotationSpeedRad: 1.7, restitutionBoost: 1.50),
        TerrainPillar(center: Vec2(486, 422), radius: 19, sides: 6, rotationSpeedRad: -1.4, restitutionBoost: 1.45),
        TerrainPillar(center: Vec2(305, 818), radius: 19, sides: 8, rotationSpeedRad: -1.5, restitutionBoost: 1.48),
      ],
      cliffs: const [
        CliffZone(center: Vec2(76, 515), radius: 46, label: '천상 서쪽 운해 심연'),
        CliffZone(center: Vec2(638, 665), radius: 46, label: '은하 무량 절벽'),
        CliffZone(center: Vec2(96, 865), radius: 42, label: '성좌 허공 해자'),
        CliffZone(center: Vec2(628, 925), radius: 42, label: '천상 동남 심연'),
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

  /// 제1현~제9현 정화 완료 시 다음 현으로 대행군하는 9종 시네마틱 여정 카탈로그.
  static const List<CountyTransitionSpec> countyTransitions = [
    CountyTransitionSpec(
      fromChapter: 1,
      toChapter: 2,
      fromCountyName: '제1현 · 청산 흙먼지현',
      toCountyName: '제2현 · 통통 객잔현',
      travelTitle: '제1현 정화 완수 · 등불 보급마차 하산 행군',
      travelVehicleBadge: '🏮 야간 청옥 보급마차단',
      motionAssetKey: 'county_travel_1_to_2',
      narrationLines: [
        '청산 흙먼지현 10개 마을의 산비탈 독기가 걷히고, 백성들이 등불을 밝혀 수호단을 배웅합니다.',
        '청옥 수호석을 실은 야간 보급마차단이 폭포 산길을 내려가 식량 요충지 「통통 객잔현」 대교차로로 진군합니다!',
      ],
      unlockHighlight: '물자 호송 마차 개통 · 곡사 회전기 개방 · 동료 반달 & 영귀 금강 구출 개시',
    ),
    CountyTransitionSpec(
      fromChapter: 2,
      toChapter: 3,
      fromCountyName: '제2현 · 통통 객잔현',
      toCountyName: '제3현 · 청옥 거북장터현',
      travelTitle: '제2현 정화 완수 · 청옥 운하 나룻배 도하',
      travelVehicleBadge: '⛵ 연등 수문 나룻배 선단',
      motionAssetKey: 'county_travel_2_to_3',
      narrationLines: [
        '통통 객잔현 대곡창을 지켜낸 수호단이 연꽃 등불이 떠다니는 밤안개 수로에 나룻배를 띄웁니다.',
        '거대 청옥 현무 석상이 수호하는 세 물길의 상업 거점 「청옥 거북장터현」으로 물길을 가릅니다!',
      ],
      unlockHighlight: '한빙 역장기 개방 · 영수 청학 구출 · 숙적 사형 묵현 첫 조우',
    ),
    CountyTransitionSpec(
      fromChapter: 3,
      toChapter: 4,
      fromCountyName: '제3현 · 청옥 거북장터현',
      toCountyName: '제4현 · 쿠비 봉화산현',
      travelTitle: '제3현 정화 완수 · 천길 절벽 횃불 등반',
      travelVehicleBadge: '🔥 산악 출렁다리 횃불대',
      motionAssetKey: 'county_travel_3_to_4',
      narrationLines: [
        '거북장터현의 운하와 우시장이 평온을 되찾자, 산꼭대기 봉화대에서 구원 신호탄이 밤하늘을 가릅니다!',
        '수호단이 횃불을 높이 들고 아찔한 절벽 잔도와 출렁다리를 건너 「쿠비 봉화산현」 요새로 오릅니다!',
      ],
      unlockHighlight: '심야 탐색 시스템 개통 · 고지 봉화 전방위 사거리 가호 · 동료 묵객·구르미 합류',
    ),
    CountyTransitionSpec(
      fromChapter: 4,
      toChapter: 5,
      fromCountyName: '제4현 · 쿠비 봉화산현',
      toCountyName: '제5현 · 황동 기관학당현',
      travelTitle: '제4현 정화 완수 · 황동 시계태엽 대교 진군',
      travelVehicleBadge: '⚙️ 기맥 증기 태엽교 행군',
      motionAssetKey: 'county_travel_4_to_5',
      narrationLines: [
        '쿠비 봉화산현의 봉화가 일제히 점화되어 동방 산맥 너머 기관 성채의 길목을 환히 비춥니다.',
        '거대한 황동 톱니바퀴와 청색 기맥 도관이 맞물려 돌아가는 태엽 대교를 건너 「황동 기관학당현」에 입성합니다!',
      ],
      unlockHighlight: '내공 증폭기 개방 · 직각 반사 도탄 미궁 · 동료 설화·정각 구출',
    ),
    CountyTransitionSpec(
      fromChapter: 5,
      toChapter: 6,
      fromCountyName: '제5현 · 황동 기관학당현',
      toCountyName: '제6현 · 만년설 백옥무림현',
      travelTitle: '제5현 정화 완수 · 만년설 빙하 협곡 돌파',
      travelVehicleBadge: '❄️ 호신강기 설원 선봉대',
      motionAssetKey: 'county_travel_5_to_6',
      narrationLines: [
        '기관학당현의 천구의가 심야 독기의 중심축이 북방 설산 무림맹 본단에 있음을 가리킵니다.',
        '황금 호신강기로 칼바람 눈보라를 가르며 얼음 협곡을 돌파해 「만년설 백옥무림현」 대광장으로 향합니다!',
      ],
      unlockHighlight: '무림수호단 황금 지원패 완성 · 영수 백호 & 동료 용아·사형 묵현 귀순 합류',
    ),
    CountyTransitionSpec(
      fromChapter: 6,
      toChapter: 7,
      fromCountyName: '제6현 · 만년설 백옥무림현',
      toCountyName: '제7현 · 적월 열사사막현',
      travelTitle: '제6현 정화 완수 · 적월 열사 사막 기마 원정',
      travelVehicleBadge: '🐪 신수 백호 · 사막 기마단',
      motionAssetKey: 'county_travel_6_to_7',
      narrationLines: [
        '백옥무림현에서 독기를 씻어낸 사형 묵현과 무림수호단이 합류하여 서역 대원정의 깃발을 올립니다!',
        '붉은 보름달 아래 신수 백호가 앞장서 모래폭풍 사구와 붉은 바위 아치를 넘어 「적월 열사사막현」으로 질주합니다!',
      ],
      unlockHighlight: '역방향 8자 사막 협곡 공방 · 4형 극의 발사대 제련 · 천마 화신 합류',
    ),
    CountyTransitionSpec(
      fromChapter: 7,
      toChapter: 8,
      fromCountyName: '제7현 · 적월 열사사막현',
      toCountyName: '제8현 · 창파 등대함대현',
      travelTitle: '제7현 정화 완수 · 황금 거북선 구호함대 출항',
      travelVehicleBadge: '🚢 용두 거북선 구호 기함',
      motionAssetKey: 'county_travel_7_to_8',
      narrationLines: [
        '열사사막현 성채를 구원한 수호단이 남해 포구에서 황금 기맥 돛을 올린 거북선 구호 기함에 승선합니다!',
        '거친 심야 파도를 가르며 등대 불빛이 비추는 바다의 보루 「창파 등대함대현」으로 총진격합니다!',
      ],
      unlockHighlight: '해상 4전함 갑판 현측 포격 · 영수 금룡 & 동료 검황 구출 합류',
    ),
    CountyTransitionSpec(
      fromChapter: 8,
      toChapter: 9,
      fromCountyName: '제8현 · 창파 등대함대현',
      toCountyName: '제9현 · 흑요 적염화산현',
      travelTitle: '제8현 정화 완수 · 용암 지옥 사슬현수교 돌파',
      travelVehicleBadge: '⛓️ 청학·현무 호위 화산 돌파대',
      motionAssetKey: 'county_travel_8_to_9',
      narrationLines: [
        '구호 함대가 지켜낸 곡식선이 아홉 현 백성들에게 닿고, 수호단은 마침내 지상의 마지막 마굴 화염산에 상륙합니다.',
        '신수 청학과 금강귀의 비호를 받으며 끓어오르는 용암 강 위 쇠사슬 다리를 건너 「흑요 적염화산현」 심장부로 진군합니다!',
      ],
      unlockHighlight: '6화산섬 용암 분출 결전 · 신물 수호석 완성 · 동료 무량 신승 합류',
    ),
    CountyTransitionSpec(
      fromChapter: 9,
      toChapter: 10,
      fromCountyName: '제9현 · 흑요 적염화산현',
      toCountyName: '제10현 · 천상 태극신전현',
      travelTitle: '제9현 정화 완수 · 황금 비룡 오색 운해 승천',
      travelVehicleBadge: '🐉 천룡 금룡 · 오색 옥계단 승천',
      motionAssetKey: 'county_travel_9_to_10',
      narrationLines: [
        '지상 아홉 현(90개 마을)의 봉인이 모두 정화되자, 하늘로 통하는 오색 청옥 구름 계단이 찬란하게 열립니다!',
        '황금 신룡과 열네 수호 영웅이 은하 운해를 박차고 마지막 10연전이 기다리는 「천상 태극신전현」으로 승천합니다!',
      ],
      unlockHighlight: '최종 제10현 천상 보스 10연전(91~100판) 개막 · 태초 태극석 완전 정화 결전!',
    ),
  ];

  static CountyTransitionSpec? countyTransitionAfter(int clearedChapter) {
    for (final t in countyTransitions) {
      if (t.fromChapter == clearedChapter) return t;
    }
    return null;
  }

  /// 관문이 진행될수록 배치 가능한 광역 지형 초소 장소가 4곳(1-1)에서 최대 14곳(9~10현)까지 점진적으로 늘어난다!
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
        return st <= 5 ? 8 : 9;
      case 5:
        return st <= 5 ? 9 : 10;
      case 6:
        return st <= 5 ? 10 : 11;
      case 7:
        return st <= 5 ? 11 : 12;
      case 8:
        return st <= 5 ? 12 : 13;
      case 9:
        return st <= 5 ? 13 : 14;
      default:
        return st <= 4 ? 13 : 14;
    }
  }

  /// 1~9현(각 10판) 캠페인 전반에 걸쳐 동료 13인과 영수 4종을 빈틈없이 구출·영입하는 정밀 시간표 (총 16개 구출 관문).
  static CompanionHero? _rescueCompanionFor(int ch, int st) {
    if (ch == 1 && st == 4) return CompanionHero.yeonbi;
    if (ch == 1 && st == 8) return CompanionHero.cheongmyeong;
    if (ch == 2 && st == 10) return CompanionHero.bandal;
    if (ch == 3 && st == 5) return CompanionHero.chwiseon;
    if (ch == 4 && st == 5) return CompanionHero.mukgaek;
    if (ch == 4 && st == 10) return CompanionHero.gurumi;
    if (ch == 5 && st == 5) return CompanionHero.seolhwa;
    if (ch == 5 && st == 10) return CompanionHero.jeonggak;
    if (ch == 6 && st == 10) return CompanionHero.yonga;
    if (ch == 7 && st == 6) return CompanionHero.magyo;
    if (ch == 8 && st == 10) return CompanionHero.geomhwang;
    if (ch == 9 && st == 6) return CompanionHero.sinseung;
    return null;
  }

  static SpiritBeast? _rescueBeastFor(int ch, int st) {
    if (ch == 2 && st == 5) return SpiritBeast.geumgangTurtle;
    if (ch == 3 && st == 10) return SpiritBeast.cheonghak;
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
          final vName = ch.villageNodeNameAt(st);
          final vCoord = ch.villageMapCoordAt(st);
          result.add(
            StageSpec(
              chapterNumber: 10,
              stageNumber: st,
              globalIndex: globalIdx,
              villageNodeName: vName,
              villageMapCoord: vCoord,
              title: isFinalGod
                  ? '10-10 최종 결전 · 태초 탄신 구원 ($vName)'
                  : '10-$st 천상 관문 · ${refChapter.bossName} 환영 ($vName)',
              subtitle: isFinalGod
                  ? '태극석의 균열을 메워 열 현 백 마을의 논밭과 생명을 되살려라! (8물결 · 초소 $mountCap곳)'
                  : '$vName · ${refChapter.villageName} 우두머리 심야 환영 8물결 혈전 (초소 $mountCap곳)',
              tacticalHint: isFinalGod
                  ? '14곳 성좌 지형 거점의 마기 암석을 개척하고, 3페이즈 다단 각성하는 태초 탄신의 🎯약점 핵을 정밀 저격해 외각 장갑을 파쇄하세요!'
                  : '일곱 성좌 부유섬 황금 무지개교의 망루·매복암을 개척하고 3페이즈 우두머리의 🎯노출 약점을 집중 타격하세요!',
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
                            text: '열 현 백 마을 백성들의 염원이 모두 네 수호탑에 모여 있다! 마지막 여덟 물결을 버텨 새벽을 밝혀라!',
                          ),
                        ]
                      : [
                          StoryLine(
                            speaker: '묵현',
                            portraitPrefix: 'mukhyeon',
                            text: '천상 제$st관문 [$vName]! 과거 [${refChapter.villageName}]을 위협했던 「${refChapter.bossName}」의 심야 환영이 3페이즈 진신으로 가로막고 있다!',
                          ),
                        ],
              outroDialogue: isFinalGod
                  ? epilogueDialogue
                  : [
                      StoryLine(
                        speaker: '청명',
                        portraitPrefix: 'cheongmyeong',
                        text: '「${refChapter.bossName}」의 천상 독기 환영을 정화했습니다! 태극석 신전 정상까지 ${10 - st}판 남았습니다!',
                      ),
                    ],
            ),
          );
        }
        continue;
      }

      // 1~9현 각 정확히 10판(10개 마을) 생성 -> 10현 × 10판 = 총 100판 대장정!
      for (int st = 1; st <= ch.stageCount; st++) {
        globalIdx++;
        final isChapterBoss = st == ch.stageCount;
        final isHeukpungStage = st == ch.stageCount - 1;
        final isMukhyeonStage =
            (ch.number == 3 || ch.number == 5 || ch.number == 6) && st == (ch.stageCount ~/ 2);
        final mountCap = _maxMountCountFor(ch.number, st).clamp(1, ch.mounts.length);
        final rescueHero = _rescueCompanionFor(ch.number, st);
        final rescuePet = _rescueBeastFor(ch.number, st);
        final rescuesMukhyeon = ch.number == 6 && st == ch.stageCount;
        final vName = ch.villageNodeNameAt(st);
        final vCoord = ch.villageMapCoordAt(st);

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
          stageTitle = '${ch.number}-$st 현 결전 · ${ch.bossName} ($vName)';
          sub = '${ch.shortCountyName} [$vName] 최종 $wCnt물결 심야 결전 (초소 $mountCap곳)';
        } else if (isHeukpungStage) {
          stageTitle = '${ch.number}-$st 약탈 저지 · 부두목 흑풍 ($vName)';
          sub = '[$vName] 식량 수레를 노리는 약탈 선봉장 흑풍 $wCnt물결 격퇴 (초소 $mountCap곳)';
        } else if (isMukhyeonStage) {
          stageTitle = '${ch.number}-$st 숙적 조우 · 사형 묵현 ($vName)';
          sub = ch.number == 6
              ? '[$vName] 독기에 삼켜진 묵현을 $wCnt물결 정화 탄지로 구원하라! (초소 $mountCap곳)'
              : '[$vName] 폭주하는 사형 묵현의 $wCnt물결 야간 기습! (초소 $mountCap곳)';
        } else if (rescueHero != null) {
          stageTitle = '${ch.number}-$st 구출 작전 · 동료 ${rescueHero.name} ($vName)';
          sub = '[$vName] 고립된 ${rescueHero.title} [${rescueHero.name}] $wCnt물결 구출전! (초소 $mountCap곳)';
        } else if (rescuePet != null) {
          stageTitle = '${ch.number}-$st 영수 구출 · ${rescuePet.name} ($vName)';
          sub = '[$vName] 독기 포위망에 갇힌 영수 [${rescuePet.name}] $wCnt물결 구원 작전! (초소 $mountCap곳)';
        } else {
          stageTitle = '${ch.number}-$st $vName 수호 ($st번째 마을)';
          final midKind = st == 1 ? MutantKind.swiftShadowBoss : _midBossKindFor(ch.number, st);
          sub = '${ch.shortCountyName} [$vName · ${ch.routeTopologyTag}] $wCnt물결 방어 (초소 $mountCap곳) · 두목 [${midKind.name}] 침략!';
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
            villageNodeName: vName,
            villageMapCoord: vCoord,
            title: stageTitle,
            subtitle: sub,
            tacticalHint: _hintForStage(ch.number, st, isChapterBoss, isHeukpungStage),
            recommendedStone: recStone,
            recommendedLaunchers: ch.mounts.take(mountCap).map((m) => m.recommendedType).toList(),
            // 초기 군수 기력 긴축 (1장 48⚡ 고정 · 전 장 모두 시작 시 오직 첫 탑 1기만 건설 가능하며 이후 적 격살·개척으로 확장!)
            startingFieldTokens: ch.number == 1
                ? 48
                : math.max(
                    48 + (ch.number - 1) * 8,
                    (ch.mounts.first.recommendedType.progressiveBuildCost(0) *
                                ch.buildCostMultiplier)
                            .round() +
                        6,
                  ),
            clearElixirBonus: isChapterBoss
                ? 6
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
      return '중간보스 [적염 파성귀]의 2차 광폭화 돌파를 막으려면 상단 요충 거점을 미리 개척하고 🎯약점 핵을 정밀 연타하세요!';
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
    final baseSwarm = 24 + ch * 4 + stage * 2;
    final swarmCount = (baseSwarm * chapter.swarmVolumeMultiplier).round().clamp(28, 128);
    final mediumCount = ((6 + ch ~/ 2 + stage ~/ 2) * (0.85 + chapter.swarmVolumeMultiplier * 0.15))
        .round()
        .clamp(6, 28);
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

    // [2물결] 기동 양동 돌격대 + (2단계 이상) 100타+ 행동대장 조기 침략!
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
          customBossTitle: '행동대장 · $midTitle',
          customHitShield: 105 + ch * 12,
          hierarchyRank: '행동대장',
        ),
    ]);

    // [3물결] 중견 돌파군 + 🪽공중 비행 변이(혈익 흡혈박쥐) 편대 출격!
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 4).clamp(24, 50),
        laneIndex: stage % laneCount,
        intervalSec: 0.32,
      ),
      if (ch >= 2 || stage >= 3)
        WaveSpawnGroup(
          kind: MutantKind.bloodWingBat,
          count: (6 + ch + stage ~/ 3).clamp(6, 18),
          laneIndex: (stage + 1) % laneCount,
          intervalSec: 0.56,
        ),
      WaveSpawnGroup(
        kind: ch >= 3 ? MutantKind.plagueToad : MutantKind.bloodCocoon,
        count: (6 + ch + stage ~/ 3).clamp(6, 17),
        laneIndex: (stage + 1) % laneCount,
        intervalSec: 0.80,
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.ironBoar,
        count: (5 + ch ~/ 2).clamp(5, 14),
        laneIndex: (laneCount - 1),
        intervalSec: 0.88,
      ),
    ]);

    // [4물결] 다차선 중갑·자폭 포위 압박군 + (중후반·결전) 🪽공중 폭격 행동대장 [심연 철익귀] 강림!
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.sickHound,
        count: (15 + ch * 2 + stage ~/ 2).clamp(15, 36),
        laneIndex: (stage + 2) % laneCount,
        intervalSec: 0.39,
      ),
      WaveSpawnGroup(
        kind: MutantKind.bloodCocoon,
        count: (8 + ch + stage ~/ 2).clamp(8, 20),
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
          count: (4 + ch ~/ 2).clamp(4, 11),
          laneIndex: (laneCount - 1),
          intervalSec: 0.96,
        ),
      if (isChapterBoss || isHeukpung || isMukhyeon || stage >= 5)
        WaveSpawnGroup(
          kind: MutantKind.abyssalGargoyle,
          count: 1,
          laneIndex: stage % laneCount,
          intervalSec: 1.75,
          customBossTitle: chapter.actionCaptainTitle,
          customHitShield: 120 + ch * 14,
          hierarchyRank: '공중 행동대장',
        ),
    ]);

    // [5물결] 심야 정예 파성 군단 + 중간보스(200타+ 백련마갑) 진격!
    waves.add([
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 8).clamp(28, 56),
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
      if (ch >= 3 && stage >= 3)
        WaveSpawnGroup(
          kind: secondMidKind,
          count: 1,
          laneIndex: stage % laneCount,
          intervalSec: 1.70,
          customBossTitle: '중간보스 · $secondMidTitle',
          customHitShield: 200 + ch * 24,
          hierarchyRank: '중간보스',
        ),
    ]);

    // 구출전·중견보스전·장 결전은 7~8물결까지 이어지는 대혈전으로 확장!
    if (hasRescue || isHeukpung || isMukhyeon || isChapterBoss) {
      waves.add([
        WaveSpawnGroup(
          kind: MutantKind.swarmRat,
          count: (swarmCount + 10).clamp(30, 60),
          laneIndex: 0,
          intervalSec: 0.25,
        ),
        WaveSpawnGroup(
          kind: MutantKind.bloodWingBat,
          count: (8 + ch).clamp(8, 20),
          laneIndex: (stage + 1) % laneCount,
          intervalSec: 0.48,
        ),
        WaveSpawnGroup(
          kind: MutantKind.plagueToad,
          count: (6 + ch ~/ 2).clamp(6, 14),
          laneIndex: 1 % laneCount,
          intervalSec: 0.86,
        ),
        WaveSpawnGroup(
          kind: secondMidKind,
          count: 1,
          laneIndex: (stage + 2) % laneCount,
          intervalSec: 1.65,
          customBossTitle: '${chapter.midBossSquadTitle} · ${secondMidKind.name}',
          customHitShield: 240 + ch * 28,
          hierarchyRank: '중간보스',
        ),
      ]);
    }

    if (isChapterBoss) {
      // 장 최종 보스전 전용 [7물결] 친위 중간보스 + 공중 행동대장 쌍두 돌격!
      waves.add([
        WaveSpawnGroup(
          kind: MutantKind.sickHound,
          count: (20 + ch * 2).clamp(22, 40),
          laneIndex: 1 % laneCount,
          intervalSec: 0.33,
        ),
        WaveSpawnGroup(
          kind: MutantKind.bloodWingBat,
          count: (10 + ch).clamp(10, 22),
          laneIndex: 0,
          intervalSec: 0.45,
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
          customBossTitle: '친위 중간보스 · $midTitle',
          customHitShield: 320 + ch * 35,
          hierarchyRank: '중간보스',
        ),
      ]);
    }

    // [최종 클라이맥스 물결 (6 / 7 / 8물결)]: 심야 총공세 + 100타 행동대장 / 500타 중간보스 / 1,000타+ 장 보스 강림!
    final finaleWave = <WaveSpawnGroup>[
      WaveSpawnGroup(
        kind: MutantKind.swarmRat,
        count: (swarmCount + 12).clamp(30, 64),
        laneIndex: (stage % laneCount),
        intervalSec: (0.26 - ch * 0.008).clamp(0.17, 0.26),
      ),
      if (ch >= 2 || stage >= 2)
        WaveSpawnGroup(
          kind: MutantKind.bloodWingBat,
          count: (6 + ch + stage ~/ 3).clamp(6, 20),
          laneIndex: (stage + 1) % laneCount,
          intervalSec: 0.50,
        ),
      WaveSpawnGroup(
        kind: ch >= 4 ? MutantKind.bloodCocoon : MutantKind.sickHound,
        count: (12 + ch * 2).clamp(13, 32),
        laneIndex: 1 % laneCount,
        intervalSec: 0.46,
      ),
      WaveSpawnGroup(
        kind: MutantKind.ironBoar,
        count: (5 + ch ~/ 2 + stage ~/ 4).clamp(5, 14),
        laneIndex: 0,
        intervalSec: 0.94,
      ),
      WaveSpawnGroup(
        kind: ch >= 2 ? MutantKind.shieldYacha : MutantKind.plagueToad,
        count: (5 + ch ~/ 2).clamp(5, 14),
        laneIndex: (laneCount - 1),
        intervalSec: 0.88,
      ),
    ];

    if (isHeukpung) {
      finaleWave.add(
        WaveSpawnGroup(
          kind: MutantKind.raiderHeukpung,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 1.8,
          customBossTitle: '약탈 부두목 흑풍',
          customPortrait: 'budumok',
          customHitShield: 450 + ch * 65,
          hierarchyRank: '중간보스',
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
          customHitShield: 520 + ch * 75,
          hierarchyRank: '중간보스',
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
          customHitShield: 1000 + (ch - 1) * 80,
          hierarchyRank: '장 보스',
        ),
      );
    } else {
      // 일반 관문(1-1 포함!)의 마지막 물결에도 반드시 100타+ 행동대장/중간보스가 지휘관으로 출전!
      final finBossKind = stage == 1
          ? MutantKind.swiftShadowBoss
          : (stage.isEven && stage >= 4 ? MutantKind.abyssalGargoyle : secondMidKind);
      finaleWave.add(
        WaveSpawnGroup(
          kind: finBossKind,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 1.75,
          customBossTitle: finBossKind == MutantKind.abyssalGargoyle
              ? chapter.actionCaptainTitle
              : _midBossCustomTitle(ch, finBossKind),
          customHitShield: 115 + ch * 16 + stage * 4,
          hierarchyRank: stage <= 3 ? '행동대장' : '중간보스',
        ),
      );
    }

    waves.add(finaleWave);
    return waves;
  }

  /// 제10장 보스 10연전 — 전 관문 8물결 천상 총결전 (행동대장 250타+ → 중간보스 500타+ → 천련 보스 1,200~2,000타+)!
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
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 52 + stage * 3, laneIndex: 0, intervalSec: 0.24),
        WaveSpawnGroup(kind: MutantKind.bloodWingBat, count: 16 + stage, laneIndex: 1 % laneCount, intervalSec: 0.40),
        WaveSpawnGroup(kind: MutantKind.shieldYacha, count: 10 + stage ~/ 2, laneIndex: laneCount - 1, intervalSec: 0.80),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 58 + stage * 3, laneIndex: (stage + 1) % laneCount, intervalSec: 0.22),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 10 + stage ~/ 2, laneIndex: 2 % laneCount, intervalSec: 0.88),
        WaveSpawnGroup(
          kind: vanguardMidBoss,
          count: 1,
          laneIndex: stage % laneCount,
          intervalSec: 1.60,
          customBossTitle: '천상 행동대장 · ${_midBossCustomTitle(10, vanguardMidBoss)}',
          customHitShield: 240 + stage * 15,
          hierarchyRank: '행동대장',
        ),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.sickHound, count: 32 + stage * 2, laneIndex: 0, intervalSec: 0.30),
        WaveSpawnGroup(kind: MutantKind.bloodWingBat, count: 18 + stage, laneIndex: 2 % laneCount, intervalSec: 0.38),
        WaveSpawnGroup(kind: MutantKind.plagueToad, count: 10 + stage ~/ 2, laneIndex: 1 % laneCount, intervalSec: 0.84),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 64 + stage * 3, laneIndex: stage % laneCount, intervalSec: 0.20),
        WaveSpawnGroup(kind: MutantKind.shieldYacha, count: 12 + stage ~/ 2, laneIndex: 2 % laneCount, intervalSec: 0.78),
        WaveSpawnGroup(
          kind: MutantKind.abyssalGargoyle,
          count: 1,
          laneIndex: (stage + 2) % laneCount,
          intervalSec: 1.65,
          customBossTitle: '천상 공중 행동대장 성좌철익귀',
          customHitShield: 280 + stage * 18,
          hierarchyRank: '공중 행동대장',
        ),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.sickHound, count: 36 + stage * 2, laneIndex: (stage + 1) % laneCount, intervalSec: 0.28),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 12 + stage ~/ 2, laneIndex: 0, intervalSec: 0.82),
        WaveSpawnGroup(
          kind: secondMidBoss,
          count: 1,
          laneIndex: laneCount - 1,
          intervalSec: 1.62,
          customBossTitle: '천상 중간보스 · ${_midBossCustomTitle(10, secondMidBoss)}',
          customHitShield: 420 + stage * 25,
          hierarchyRank: '중간보스',
        ),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 72 + stage * 3, laneIndex: 3 % laneCount, intervalSec: 0.19),
        WaveSpawnGroup(kind: MutantKind.plagueToad, count: 12 + stage ~/ 2, laneIndex: 1 % laneCount, intervalSec: 0.80),
        WaveSpawnGroup(
          kind: thirdMidBoss,
          count: 1,
          laneIndex: (stage + 1) % laneCount,
          intervalSec: 1.60,
          customBossTitle: '천상 부두목 · ${_midBossCustomTitle(10, thirdMidBoss)}',
          customHitShield: 520 + stage * 30,
          hierarchyRank: '중간보스',
        ),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 78 + stage * 3, laneIndex: 0, intervalSec: 0.18),
        WaveSpawnGroup(kind: MutantKind.bloodWingBat, count: 22 + stage, laneIndex: 1 % laneCount, intervalSec: 0.34),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 13 + stage ~/ 2, laneIndex: 2 % laneCount, intervalSec: 0.80),
      ],
      [
        WaveSpawnGroup(kind: MutantKind.swarmRat, count: 84 + stage * 3, laneIndex: (stage + 2) % laneCount, intervalSec: 0.17),
        WaveSpawnGroup(kind: MutantKind.bloodWingBat, count: 24 + stage, laneIndex: 0, intervalSec: 0.34),
        WaveSpawnGroup(kind: MutantKind.ironBoar, count: 14 + stage ~/ 2, laneIndex: 1 % laneCount, intervalSec: 0.82),
        WaveSpawnGroup(
          kind: MutantKind.chapterOverlord,
          count: 1,
          laneIndex: laneCount ~/ 2,
          intervalSec: 2.2,
          customBossTitle: isFinal ? '심야에 물든 태초 탄신' : '${refChapter.bossName} (천상 환영)',
          customPortrait: isFinal ? 'tansin' : refChapter.bossPortraitPrefix,
          customHitShield: isFinal ? 2000 : (1200 + stage * 65),
          hierarchyRank: '장 보스',
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
