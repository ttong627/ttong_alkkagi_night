/// 길목 알 자동 발사대 5계통 × 버전(1형~4형) 및 중앙 자동 보호 장치 모델.
enum LauncherType {
  rapid(
    id: 'rapid',
    name: '속사 탄지기',
    roleSummary: '떼 지어 몰려오는 초소형·소형 독쥐·들개 대군 연속 관통 소탕',
    tierNames: ['1형 단발 목제기', '2형 쌍발 연노기', '3형 삼연속 회전기', '4형 폭풍 만발 탄지진'],
    baseCooldownSec: 1.12,
    baseDamage: 20.0,
    projectileSpeed: 355.0,
    unlockChapter: 1,
    buildCostTokens: 45,
    colorHex: 0xFF4EA8DE,
  ),
  heavy(
    id: 'heavy',
    name: '중포 탄지기',
    roleSummary: '대형 중갑 변이체 장갑 파쇄·범위 충격파 및 절벽 추락 유도',
    tierNames: ['1형 외발 투석기', '2형 철심 강타포', '3형 파쇄 관통대포', '4형 천추 파성포'],
    baseCooldownSec: 2.15,
    baseDamage: 48.0,
    projectileSpeed: 295.0,
    unlockChapter: 1,
    buildCostTokens: 55,
    colorHex: 0xFFF77F00,
  ),
  curveSpin(
    id: 'curveSpin',
    name: '곡사 회전기',
    roleSummary: '휘어 치는 관통 회전탄으로 방패병 측면 타격 및 대열 교란',
    tierNames: ['1형 스핀 발사기', '2형 곡선 탄지기', '3형 갈고리 견인포', '4형 태극 회오리포'],
    baseCooldownSec: 1.62,
    baseDamage: 32.0,
    projectileSpeed: 315.0,
    unlockChapter: 2,
    buildCostTokens: 52,
    colorHex: 0xFF72EFDD,
  ),
  frostField(
    id: 'frostField',
    name: '한빙 역장기',
    roleSummary: '서리 한파 범위 감속·빙결로 구불길 굽이에 적 대군을 묶어 집중 타격',
    tierNames: ['1형 냉기 조약돌기', '2형 서리 안개기', '3형 빙결 족쇄포', '4형 만년 빙옥 결계포'],
    baseCooldownSec: 1.78,
    baseDamage: 24.0,
    projectileSpeed: 305.0,
    unlockChapter: 3,
    buildCostTokens: 50,
    colorHex: 0xFF90E0EF,
  ),
  qiAmplifier(
    id: 'qiAmplifier',
    name: '내공 증폭기',
    roleSummary: '주변 초소 연사·화력·회심 증폭 + 중앙 수호탑 내공 충전 및 결계 수복',
    tierNames: ['1형 기운 공명석', '2형 문파 기운 주입기', '3형 회심 증폭 진법', '4형 기명 사방진'],
    baseCooldownSec: 2.35,
    baseDamage: 26.0,
    projectileSpeed: 330.0,
    unlockChapter: 5,
    buildCostTokens: 60,
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
  final int unlockChapter;
  final int buildCostTokens;
  final int colorHex;

  String tierLabel(int tier) => tierNames[(tier - 1).clamp(0, 3)];

  /// 전투 중 현장 증표로 버전을 올리는 비용 (1→2형, 2→3형, 3→4형).
  int inBattleUpgradeCost(int currentTier) {
    switch (currentTier) {
      case 1:
        return (buildCostTokens * 0.85).round();
      case 2:
        return (buildCostTokens * 1.35).round();
      case 3:
        return (buildCostTokens * 1.95).round();
      default:
        return 0;
    }
  }

  /// 버전(1~4형)에 따른 연사 속도 배수.
  double tierFireRateMultiplier(int tier) {
    switch (tier.clamp(1, 4)) {
      case 1:
        return 1.0;
      case 2:
        return 1.22;
      case 3:
        return 1.48;
      case 4:
        return 1.78;
      default:
        return 1.0;
    }
  }

  /// 버전(1~4형)에 따른 단발 피해 배수.
  double tierDamageMultiplier(int tier) {
    switch (tier.clamp(1, 4)) {
      case 1:
        return 1.0;
      case 2:
        return 1.32;
      case 3:
        return 1.72;
      case 4:
        return 2.25;
      default:
        return 1.0;
    }
  }

  /// 속사 탄지기 버전별 동시 발사 수.
  int projectilesPerShot(int tier) {
    if (this == LauncherType.rapid) {
      if (tier >= 4) return 3;
      if (tier >= 2) return 2;
    }
    return 1;
  }

  /// 대장간 영구 강화 비용 (돌연변이 처치 드롭 증표 전용).
  int permanentUpgradeCost(int currentLevel) =>
      45 + currentLevel * 38 + (currentLevel * currentLevel * 12);
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
    final shieldHp = (280.0 + centralLevel * 48.0) *
        realmDefenseMult *
        (1.0 + meridianShieldBonus + coreFortitudeBonus);
    final towerHp = (220.0 + centralLevel * 38.0) *
        realmDefenseMult *
        (1.0 + coreFortitudeBonus);
    final interval = (0.94 / (1.0 + centralLevel * 0.055 + meridianReloadBonus))
        .clamp(0.36, 1.05);
    final dmg = (33.0 + centralLevel * 6.8) * (1.0 + coreFirepowerBonus);
    return CentralGuardianSpec(
      coreLevel: centralLevel,
      shieldMaxHp: shieldHp,
      coreMaxHp: towerHp,
      fireIntervalSec: interval,
      baseDamage: dmg,
      shieldWavePush: 55.0 + centralLevel * 4.5,
    );
  }

  static int permanentUpgradeCost(int currentLevel) =>
      50 + currentLevel * 42 + (currentLevel * currentLevel * 14);
}
