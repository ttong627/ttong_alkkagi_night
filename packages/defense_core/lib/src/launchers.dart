/// 길목 알 자동 발사대 5계통 × 버전(1형~5형) 및 고유 전술 사거리·중앙 자동 보호 장치 모델.
enum LauncherType {
  rapid(
    id: 'rapid',
    name: '속사 탄지기',
    roleSummary: '근·중거리(156) 초고속 다연발 탄막으로 고속 군집 학살 (중갑·방패병에겐 위력 반감)',
    tierNames: ['1형 쌍발 속사기', '2형 삼연발 연노기', '3형 사연속 폭풍기', '4형 오발 천뢰 기관진'],
    baseCooldownSec: 0.40,
    baseDamage: 17.5,
    projectileSpeed: 620.0,
    baseRangePx: 156.0,
    minRangePx: 0.0,
    unlockChapter: 1,
    buildCostTokens: 45,
    colorHex: 0xFF4EA8DE,
  ),
  heavy(
    id: 'heavy',
    name: '중포 탄지기',
    roleSummary: '장거리(212 · 코앞 68 사각) 대구경 곡사 포격으로 중갑·보스 외각 파쇄 (고속군집 취약)',
    tierNames: ['1형 강타 투석포', '2형 철심 폭렬포', '3형 파쇄 진동대포', '4형 천추 파성 거포'],
    baseCooldownSec: 1.48,
    baseDamage: 82.0,
    projectileSpeed: 550.0,
    baseRangePx: 212.0,
    minRangePx: 68.0,
    unlockChapter: 1,
    buildCostTokens: 56,
    colorHex: 0xFFF77F00,
  ),
  curveSpin(
    id: 'curveSpin',
    name: '곡사 회전기',
    roleSummary: '중거리(174) 부메랑 칼날탄으로 전면 방패·보스 측면 약점 우회 절단',
    tierNames: ['1형 회전 비검기', '2형 쌍류 부메랑포', '3형 갈고리 파쇄포', '4형 태극 칼날 회오리포'],
    baseCooldownSec: 0.80,
    baseDamage: 30.5,
    projectileSpeed: 585.0,
    baseRangePx: 174.0,
    minRangePx: 0.0,
    unlockChapter: 2,
    buildCostTokens: 54,
    colorHex: 0xFF72EFDD,
  ),
  frostField(
    id: 'frostField',
    name: '한빙 역장기',
    roleSummary: '초근접(138) 협곡 빙결 제어 전용! 빙결 적에게 타 병종 +45% 파쇄 피해 (단독 화력 낮음)',
    tierNames: ['1형 쌍발 냉기포', '2형 서리 산탄기', '3형 삼발 빙결 족쇄포', '4형 만년 빙옥 폭풍포'],
    baseCooldownSec: 1.08,
    baseDamage: 2.5,
    projectileSpeed: 535.0,
    baseRangePx: 138.0,
    minRangePx: 0.0,
    unlockChapter: 3,
    buildCostTokens: 52,
    colorHex: 0xFF90E0EF,
  ),
  qiAmplifier(
    id: 'qiAmplifier',
    name: '내공 증폭기',
    roleSummary: '인접(195) 다른 계통 포탑의 화력·연사·사거리를 대폭 증폭 및 내공 충전 (자체 살상력 낮음)',
    tierNames: ['1형 기운 공명석', '2형 문파 가속 주입기', '3형 회심 폭주 진법', '4형 기명 천하 사방진'],
    baseCooldownSec: 1.28,
    baseDamage: 2.2,
    projectileSpeed: 570.0,
    baseRangePx: 180.0,
    minRangePx: 0.0,
    unlockChapter: 5,
    buildCostTokens: 62,
    colorHex: 0xFFFFD166,
  );

  const LauncherType({
    required this.id,
    required this.name,
    required this.roleSummary,
    required this.tierNames,
    required this.baseCooldownSec,
    required this.baseDamage,
    required this.projectileSpeed,
    required this.baseRangePx,
    required this.minRangePx,
    required this.unlockChapter,
    required this.buildCostTokens,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String roleSummary;
  final List<String> tierNames;
  final double baseCooldownSec;
  final double baseDamage;
  final double projectileSpeed;
  final double baseRangePx;
  final double minRangePx;
  final int unlockChapter;
  final int buildCostTokens;
  final int colorHex;

  /// 전장 내 이미 배치된 발사대 수에 비례하여 증가하는 체증 건설 비용!
  /// (초중반 무지성 포탑 도배를 +14⚡씩 강하게 억제하되, 10~14초소 대협곡 확장이 가능하도록 최대 +70⚡ 상한 적용)
  int progressiveBuildCost(int existingLauncherCount) =>
      buildCostTokens + (existingLauncherCount.clamp(0, 20) * 14).clamp(0, 70);

  /// 승급 단계(1~5형)에 따른 기본 유효 사거리 (단당 +6%만 정밀 확장하여 초소 위치 전략성 유지!).
  double effectiveBaseRange(int tier) =>
      baseRangePx * (1.0 + (tier.clamp(1, 5) - 1) * 0.06);

  String tierLabel(int tier) {
    if (tier >= 5) return '★5형 태초 신기($name)';
    return tierNames[(tier - 1).clamp(0, 3)];
  }

  /// 전투 중 현장 증표로 버전을 올리는 비용 (1→2형, 2→3형, 3→4형 · 5형은 연성 합치기/기연 초월 전용!).
  int inBattleUpgradeCost(int currentTier) {
    switch (currentTier) {
      case 1:
        return (buildCostTokens * 1.05).round();
      case 2:
        return (buildCostTokens * 1.65).round();
      case 3:
        return (buildCostTokens * 2.35).round();
      default:
        return 0;
    }
  }

  /// 버전(1~5형)에 따른 연사 속도 배수.
  double tierFireRateMultiplier(int tier) {
    switch (tier.clamp(1, 5)) {
      case 1:
        return 1.0;
      case 2:
        return 1.24;
      case 3:
        return 1.52;
      case 4:
        return 1.84;
      case 5:
        return 2.35;
      default:
        return 1.0;
    }
  }

  /// 버전(1~5형)에 따른 단발 피해 배수.
  double tierDamageMultiplier(int tier) {
    switch (tier.clamp(1, 5)) {
      case 1:
        return 1.0;
      case 2:
        return 1.35;
      case 3:
        return 1.78;
      case 4:
        return 2.32;
      case 5:
        return 3.25;
      default:
        return 1.0;
    }
  }

  /// 발사대 종류 및 버전(1~5형)별 1회 사격당 동시 발사 탄알 수 (시원한 탄막 일제사격!).
  int projectilesPerShot(int tier) {
    final t = tier.clamp(1, 5);
    switch (this) {
      case LauncherType.rapid:
        if (t >= 5) return 7;
        if (t >= 4) return 5;
        if (t >= 3) return 4;
        if (t >= 2) return 3;
        return 2;
      case LauncherType.frostField:
        return t >= 4 ? 2 : 1;
      case LauncherType.curveSpin:
        if (t >= 5) return 3;
        return t >= 2 ? 2 : 1;
      case LauncherType.heavy:
        if (t >= 5) return 3;
        return t >= 4 ? 2 : 1;
      case LauncherType.qiAmplifier:
        return 1;
    }
  }

  /// 대장간 영구 강화 비용 (돌연변이 처치 드롭 증표 전용).
  int permanentUpgradeCost(int currentLevel) =>
      45 + currentLevel * 34 + (currentLevel * currentLevel * 9);
}

/// 중앙 자동 알 발사 보호 장치(기명 수호탑) & 외곽 기공 방어막 스펙 계산기.
class CentralGuardianSpec {
  const CentralGuardianSpec({
    required this.coreLevel,
    required this.shieldMaxHp,
    required this.coreMaxHp,
    required this.fireIntervalSec,
    required this.baseDamage,
    required this.shieldWavePush,
  });

  final int coreLevel;
  final double shieldMaxHp;
  final double coreMaxHp;
  final double fireIntervalSec;
  final double baseDamage;
  final double shieldWavePush;

  factory CentralGuardianSpec.fromLevels({
    required int centralLevel,
    required double realmDefenseMult,
    required double meridianShieldBonus,
    required double meridianReloadBonus,
    required double coreFortitudeBonus,
    required double coreFirepowerBonus,
  }) {
    // 중앙 수호탑 자동 방어는 최후방 결계 코앞의 비상 견제 역할만 수행하며,
    // 길목 거점을 개척·설치하지 않으면 결계가 반드시 돌파되도록 긴장감 있게 설계!
    final shieldHp = (240.0 + centralLevel * 30.0) *
        realmDefenseMult *
        (1.0 + meridianShieldBonus + coreFortitudeBonus);
    final towerHp = (210.0 + centralLevel * 25.0) *
        realmDefenseMult *
        (1.0 + coreFortitudeBonus);
    final interval = (1.58 / (1.0 + centralLevel * 0.045 + meridianReloadBonus))
        .clamp(0.65, 1.70);
    final dmg = (13.0 + centralLevel * 3.6) * (1.0 + coreFirepowerBonus);
    return CentralGuardianSpec(
      coreLevel: centralLevel,
      shieldMaxHp: shieldHp,
      coreMaxHp: towerHp,
      fireIntervalSec: interval,
      baseDamage: dmg,
      shieldWavePush: 32.0 + centralLevel * 2.8,
    );
  }

  static int permanentUpgradeCost(int currentLevel) =>
      50 + currentLevel * 38 + (currentLevel * currentLevel * 10);
}
