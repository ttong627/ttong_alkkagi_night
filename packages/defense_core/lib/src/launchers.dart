/// 길목 알 자동 발사대 5계통 × 버전(1형~5형) 및 고유 전술 사거리·중앙 자동 보호 장치 모델.
enum LauncherType {
  rapid(
    id: 'rapid',
    name: '속사 탄지기',
    roleSummary: '근·중거리(122) 굽이 안에 들어온 적에게 초고속 다연발(2~7갈래) 탄막 집중 사격',
    tierNames: ['1형 쌍발 속사기', '2형 삼연발 연노기', '3형 사연속 폭풍기', '4형 오발 천뢰 기관진'],
    baseCooldownSec: 0.38,
    baseDamage: 18.0,
    projectileSpeed: 485.0,
    baseRangePx: 122.0,
    minRangePx: 0.0,
    unlockChapter: 1,
    buildCostTokens: 45,
    colorHex: 0xFF4EA8DE,
  ),
  heavy(
    id: 'heavy',
    name: '중포 탄지기',
    roleSummary: '장거리(162 · 코앞 34 사각) 대구경 곡사 포격으로 먼 굽이 중갑 변이 파쇄 및 절벽 추락',
    tierNames: ['1형 강타 투석포', '2형 철심 폭렬포', '3형 파쇄 진동대포', '4형 천추 파성 거포'],
    baseCooldownSec: 1.06,
    baseDamage: 64.0,
    projectileSpeed: 420.0,
    baseRangePx: 162.0,
    minRangePx: 34.0,
    unlockChapter: 1,
    buildCostTokens: 55,
    colorHex: 0xFFF77F00,
  ),
  curveSpin(
    id: 'curveSpin',
    name: '곡사 회전기',
    roleSummary: '중거리(134) S자 부메랑 칼날탄으로 위·아래 두 굽이 대열과 방패병 측면을 동시에 훑음',
    tierNames: ['1형 회전 비검기', '2형 쌍류 부메랑포', '3형 갈고리 파쇄포', '4형 태극 칼날 회오리포'],
    baseCooldownSec: 0.74,
    baseDamage: 29.5,
    projectileSpeed: 440.0,
    baseRangePx: 134.0,
    minRangePx: 0.0,
    unlockChapter: 2,
    buildCostTokens: 52,
    colorHex: 0xFF72EFDD,
  ),
  frostField(
    id: 'frostField',
    name: '한빙 역장기',
    roleSummary: '초근접(108) 굽이 목지점 전용! 짧은 사거리 대신 지나가는 대군을 통째로 얼려 묶음',
    tierNames: ['1형 쌍발 냉기포', '2형 서리 산탄기', '3형 삼발 빙결 족쇄포', '4형 만년 빙옥 폭풍포'],
    baseCooldownSec: 0.86,
    baseDamage: 21.0,
    projectileSpeed: 405.0,
    baseRangePx: 108.0,
    minRangePx: 0.0,
    unlockChapter: 3,
    buildCostTokens: 50,
    colorHex: 0xFF90E0EF,
  ),
  qiAmplifier(
    id: 'qiAmplifier',
    name: '내공 증폭기',
    roleSummary: '중거리(138) 관통 기공탄 + 인접(125) 초소 사거리·연사·화력 증폭 및 내공 충전',
    tierNames: ['1형 기운 공명석', '2형 문파 가속 주입기', '3형 회심 폭주 진법', '4형 기명 천하 사방진'],
    baseCooldownSec: 1.00,
    baseDamage: 28.0,
    projectileSpeed: 445.0,
    baseRangePx: 138.0,
    minRangePx: 0.0,
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

  /// 승급 단계(1~5형)에 따른 기본 유효 사거리 (단당 +6%만 정밀 확장하여 초소 위치 전략성 유지!).
  double effectiveBaseRange(int tier) =>
      baseRangePx * (1.0 + (tier.clamp(1, 5) - 1) * 0.06);

  String tierLabel(int tier) {
    if (tier >= 5) return '★5형 태초 신기($name)';
    return tierNames[(tier - 1).clamp(0, 3)];
  }

  /// 전투 중 현장 증표로 버전을 올리는 비용 (1→2형, 2→3형, 3→4형 · 5형은 합치기/기연 초월 전용!).
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

  /// 버전(1~5형)에 따른 연사 속도 배수.
  double tierFireRateMultiplier(int tier) {
    switch (tier.clamp(1, 5)) {
      case 1:
        return 1.0;
      case 2:
        return 1.22;
      case 3:
        return 1.48;
      case 4:
        return 1.78;
      case 5:
        return 2.28;
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
        return 1.32;
      case 3:
        return 1.72;
      case 4:
        return 2.25;
      case 5:
        return 3.15;
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
        if (t >= 5) return 4;
        return t >= 3 ? 3 : 2;
      case LauncherType.curveSpin:
        if (t >= 5) return 3;
        return t >= 2 ? 2 : 1;
      case LauncherType.heavy:
        if (t >= 5) return 3;
        return t >= 4 ? 2 : 1;
      case LauncherType.qiAmplifier:
        if (t >= 5) return 3;
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
    // 초보자가 첫 18~20초간 화면을 둘러보다가 배치해도 여유 있게 살아남되,
    // 끝까지 아무것도 안 하고 방치하면 약 26~32초경(1~2물결)에 반드시 함락되도록 내구도 정밀 설계!
    final shieldHp = (275.0 + centralLevel * 32.0) *
        realmDefenseMult *
        (1.0 + meridianShieldBonus + coreFortitudeBonus);
    final towerHp = (225.0 + centralLevel * 26.0) *
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
