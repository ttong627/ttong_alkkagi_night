/// 길목 알 자동 발사대 5계통 × 버전(1형~4형) 및 중앙 자동 보호 장치 모델.
enum LauncherType {
  rapid(
    id: 'rapid',
    name: '속사 탄지기',
    roleSummary: '초고속 다연발(2~5갈래) 관통 탄막으로 몰려오는 독쥐·들개 대군을 순식간에 갈아버림',
    tierNames: ['1형 쌍발 속사기', '2형 삼연발 연노기', '3형 사연속 폭풍기', '4형 오발 천뢰 기관진'],
    baseCooldownSec: 0.38,
    baseDamage: 14.5,
    projectileSpeed: 495.0,
    unlockChapter: 1,
    buildCostTokens: 45,
    colorHex: 0xFF4EA8DE,
  ),
  heavy(
    id: 'heavy',
    name: '중포 탄지기',
    roleSummary: '묵직한 대구경 포탄으로 중갑 변이체 장갑 파쇄·대폭발 충격파 및 절벽 추락 유도',
    tierNames: ['1형 강타 투석포', '2형 철심 폭렬포', '3형 파쇄 진동대포', '4형 천추 파성 거포'],
    baseCooldownSec: 1.08,
    baseDamage: 52.0,
    projectileSpeed: 430.0,
    unlockChapter: 1,
    buildCostTokens: 55,
    colorHex: 0xFFF77F00,
  ),
  curveSpin(
    id: 'curveSpin',
    name: '곡사 회전기',
    roleSummary: 'S자로 휘어 치는 고속 다중 관통 회전 칼날탄으로 방패병 측면과 적 대열을 통째로 훑음',
    tierNames: ['1형 회전 비검기', '2형 쌍류 부메랑포', '3형 갈고리 파쇄포', '4형 태극 칼날 회오리포'],
    baseCooldownSec: 0.76,
    baseDamage: 24.0,
    projectileSpeed: 450.0,
    unlockChapter: 2,
    buildCostTokens: 52,
    colorHex: 0xFF72EFDD,
  ),
  frostField(
    id: 'frostField',
    name: '한빙 역장기',
    roleSummary: '부채꼴 냉기 산탄(2~3발)으로 적 대군을 얼려 묶고 서리 폭발로 연쇄 쇄빙 타격',
    tierNames: ['1형 쌍발 냉기포', '2형 서리 산탄기', '3형 삼발 빙결 족쇄포', '4형 만년 빙옥 폭풍포'],
    baseCooldownSec: 0.90,
    baseDamage: 16.5,
    projectileSpeed: 415.0,
    unlockChapter: 3,
    buildCostTokens: 50,
    colorHex: 0xFF90E0EF,
  ),
  qiAmplifier(
    id: 'qiAmplifier',
    name: '내공 증폭기',
    roleSummary: '고속 관통 기공탄 사격 + 주변 초소 폭풍 가속·화력 증폭 및 중앙탑 내공 급속 충전',
    tierNames: ['1형 기운 공명석', '2형 문파 가속 주입기', '3형 회심 폭주 진법', '4형 기명 천하 사방진'],
    baseCooldownSec: 1.05,
    baseDamage: 23.0,
    projectileSpeed: 460.0,
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

  /// 발사대 종류 및 버전(1~4형)별 1회 사격당 동시 발사 탄알 수 (시원한 탄막 일제사격!).
  int projectilesPerShot(int tier) {
    final t = tier.clamp(1, 4);
    switch (this) {
      case LauncherType.rapid:
        if (t >= 4) return 5;
        if (t >= 3) return 4;
        if (t >= 2) return 3;
        return 2;
      case LauncherType.frostField:
        return t >= 3 ? 3 : 2;
      case LauncherType.curveSpin:
        return t >= 2 ? 2 : 1;
      case LauncherType.heavy:
        return t >= 4 ? 2 : 1;
      case LauncherType.qiAmplifier:
        return t >= 3 ? 2 : 1;
    }
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
    // 본진은 최후의 근접 방어선 역할만 수행하도록 내구도·자동 사격 주기를 정밀 설계 (무배치 방치 시 반드시 함락!)
    final shieldHp = (135.0 + centralLevel * 28.0) *
        realmDefenseMult *
        (1.0 + meridianShieldBonus + coreFortitudeBonus);
    final towerHp = (110.0 + centralLevel * 22.0) *
        realmDefenseMult *
        (1.0 + coreFortitudeBonus);
    final interval = (1.42 / (1.0 + centralLevel * 0.045 + meridianReloadBonus))
        .clamp(0.58, 1.55);
    final dmg = (18.5 + centralLevel * 4.2) * (1.0 + coreFirepowerBonus);
    return CentralGuardianSpec(
      coreLevel: centralLevel,
      shieldMaxHp: shieldHp,
      coreMaxHp: towerHp,
      fireIntervalSec: interval,
      baseDamage: dmg,
      shieldWavePush: 36.0 + centralLevel * 3.0,
    );
  }

  static int permanentUpgradeCost(int currentLevel) =>
      50 + currentLevel * 42 + (currentLevel * currentLevel * 14);
}
