/// 알 재질 13종(1~13단) · 모양 3종 · 문파 내공 무공 4종 정의.
enum StoneMaterial {
  cheongok(
    id: 'cheongok',
    name: '청옥',
    grade: 1,
    minChapter: 1,
    density: 1.0,
    damping: 1.15,
    restitution: 0.84,
    unlockTokens: 0,
    specialDesc: '표준 균형 수호석 — 모든 발사대와 무난하게 조화됨',
    hitSound: 'hit_cheongok.ogg',
    colorHex: 0xFF3CB39A,
  ),
  manyeonGiju(
    id: 'wood',
    name: '만년기주',
    grade: 2,
    minChapter: 1,
    density: 0.65,
    damping: 0.90,
    restitution: 0.80,
    unlockTokens: 90,
    specialDesc: '가볍고 탄속이 빨라 소형 독쥐·들개 무리 추격에 유리 (+탄속 18%)',
    hitSound: 'hit_wood.ogg',
    colorHex: 0xFFC58B4E,
  ),
  hyeoncheol(
    id: 'hyeoncheol',
    name: '현철',
    grade: 3,
    minChapter: 2,
    density: 2.35,
    damping: 1.65,
    restitution: 0.74,
    unlockTokens: 190,
    specialDesc: '묵직한 흑철 중량으로 중갑 돌진 변이체를 강하게 밀쳐냄 (+밀침 25%)',
    hitSound: 'hit_hyeoncheol.ogg',
    colorHex: 0xFF5D6B7A,
  ),
  obsidian(
    id: 'obsidian',
    name: '흑요석',
    grade: 4,
    minChapter: 3,
    density: 1.55,
    damping: 1.05,
    restitution: 0.88,
    unlockTokens: 320,
    specialDesc: '예리한 파편 충격으로 충돌 주변 적에게 추가 파편 피해 (+범위 파편)',
    hitSound: 'hit_cheongok.ogg',
    colorHex: 0xFF3E2F5B,
  ),
  banseok(
    id: 'granite',
    name: '반석',
    grade: 5,
    minChapter: 4,
    density: 2.20,
    damping: 2.10,
    restitution: 0.62,
    unlockTokens: 480,
    specialDesc: '충돌 후 길목에 잠깐 버티며 뒤따르는 변이체 진격을 저지',
    hitSound: 'hit_hyeoncheol.ogg',
    colorHex: 0xFF9C8F7A,
  ),
  bingbaek(
    id: 'ice',
    name: '빙백한옥',
    grade: 6,
    minChapter: 5,
    density: 1.05,
    damping: 0.25,
    restitution: 0.94,
    unlockTokens: 700,
    specialDesc: '매끄럽게 미끄러지며 다중 도탄 연타 + 적 이동속도 20% 냉기 둔화',
    hitSound: 'hit_ice.ogg',
    colorHex: 0xFF7CE0FF,
  ),
  geumgang(
    id: 'diamond',
    name: '금강석',
    grade: 7,
    minChapter: 6,
    density: 1.15,
    damping: 0.55,
    restitution: 0.95,
    unlockTokens: 980,
    specialDesc: '초고속 직선 돌파력과 높은 회심율 보정 (+회심 8%)',
    hitSound: 'hit_cheongok.ogg',
    colorHex: 0xFFB8F2FF,
  ),
  jageum(
    id: 'jageum',
    name: '자금석',
    grade: 8,
    minChapter: 7,
    density: 1.85,
    damping: 1.25,
    restitution: 0.70,
    unlockTokens: 1350,
    specialDesc: '자줏빛 금결 기운이 방패·중갑 변이체의 외피 방어를 45% 무시',
    hitSound: 'hit_hyeoncheol.ogg',
    colorHex: 0xFF9D5CE6,
  ),
  uncheol(
    id: 'uncheol',
    name: '운철',
    grade: 9,
    minChapter: 8,
    density: 2.75,
    damping: 1.40,
    restitution: 0.66,
    unlockTokens: 1850,
    specialDesc: '하늘 운석의 압도적 질량으로 착탄 지점 충격파 발생 (+장외율 대폭 상승)',
    hitSound: 'hit_hyeoncheol.ogg',
    colorHex: 0xFF4F7CAC,
  ),
  hancheol(
    id: 'hancheol',
    name: '한철',
    grade: 10,
    minChapter: 9,
    density: 2.50,
    damping: 1.20,
    restitution: 0.64,
    unlockTokens: 2450,
    specialDesc: '극한의 냉기 결빙과 중량 밀침을 동시에 가하는 명품 수호석',
    hitSound: 'hit_ice.ogg',
    colorHex: 0xFF48CAE4,
  ),
  onok(
    id: 'onok',
    name: '천년온옥',
    grade: 11,
    minChapter: 8,
    density: 1.45,
    damping: 0.85,
    restitution: 0.60,
    unlockTokens: 0,
    shardRequired: 20,
    specialDesc: '[제8장 · 신물 조각 20개] 변이체 정화마다 외곽 기공 방어막 내구도 2.2% 자동 회복!',
    hitSound: 'hit_cheongok.ogg',
    colorHex: 0xFF72EFDD,
  ),
  yongrin(
    id: 'yongrin',
    name: '용린석',
    grade: 12,
    minChapter: 9,
    density: 2.15,
    damping: 0.95,
    restitution: 0.56,
    unlockTokens: 0,
    shardRequired: 30,
    specialDesc: '[제9장 · 신물 조각 30개] 용의 기운이 일렁이며 길목 폭 전체 광역 밀침 +35%!',
    hitSound: 'hit_hyeoncheol.ogg',
    colorHex: 0xFFFFB703,
  ),
  taegeuk(
    id: 'taegeuk',
    name: '태극석',
    grade: 13,
    minChapter: 10,
    density: 1.85,
    damping: 0.70,
    restitution: 0.52,
    unlockTokens: 0,
    shardRequired: 40,
    specialDesc: '[제10장 · 신물 조각 40개] 튕길 때마다 위력이 줄지 않고 음양 도탄으로 전장을 정화!',
    hitSound: 'critical.ogg',
    colorHex: 0xFFFFD166,
  );

  const StoneMaterial({
    required this.id,
    required this.name,
    required this.grade,
    required this.minChapter,
    required this.density,
    required this.damping,
    required this.restitution,
    required this.unlockTokens,
    required this.specialDesc,
    required this.hitSound,
    required this.colorHex,
    this.shardRequired = 0,
  });

  final String id;
  final String name;
  final int grade;
  final int minChapter;
  final double density;
  final double damping;
  final double restitution;
  final int unlockTokens;
  final int shardRequired;
  final String specialDesc;
  final String hitSound;
  final int colorHex;

  bool get isShardStone => shardRequired > 0;

  /// 단수가 올라갈수록 타격 피해 배수가 단단하게 증가 (1단 1.00 → 13단 2.68).
  double get damageMultiplier => 1.0 + (grade - 1) * 0.14;

  /// 단수가 올라갈수록 상대를 밀어내는 충격 배수 증가 (1단 1.15 → 13단 1.87).
  double get knockbackMultiplier => 1.15 + (grade - 1) * 0.06;

  /// 도탄 시 속도 유지율 (태극석은 감쇠 없음).
  double get bounceKeep => grade == 13 ? 1.02 : (0.74 + grade * 0.015).clamp(0.74, 0.96);
}

/// 수호 알 모양 3종.
enum StoneShape {
  flat(
    id: 'flat',
    name: '납작한 돌',
    summary: '노린 길목 지점에 안정적으로 꽂히며 정밀 제압 (+명중·회심 6%)',
    speedFactor: 1.04,
    spinCurveFactor: 0.45,
    knockbackFactor: 0.96,
    critBonus: 0.06,
    maxBounces: 2,
  ),
  round(
    id: 'round',
    name: '둥근 돌',
    summary: '직진 타격과 담장·기둥 반발 도탄이 고르게 조화됨 (표준 균형)',
    speedFactor: 1.00,
    spinCurveFactor: 0.75,
    knockbackFactor: 1.04,
    critBonus: 0.03,
    maxBounces: 3,
  ),
  sphere(
    id: 'sphere',
    name: '구형 돌',
    summary: '굽은 산길 휘어 치기 극대화 + 다중 도탄 연타 (+최대 도탄 5회)',
    speedFactor: 0.96,
    spinCurveFactor: 1.20,
    knockbackFactor: 1.12,
    critBonus: 0.02,
    maxBounces: 5,
  );

  const StoneShape({
    required this.id,
    required this.name,
    required this.summary,
    required this.speedFactor,
    required this.spinCurveFactor,
    required this.knockbackFactor,
    required this.critBonus,
    required this.maxBounces,
  });

  final String id;
  final String name;
  final String summary;
  final double speedFactor;
  final double spinCurveFactor;
  final double knockbackFactor;
  final double critBonus;
  final int maxBounces;
}

/// 4대 문파 내공 무공 (중앙 보호 장치 및 내공 증폭기에서 자동 발동).
enum SectTechnique {
  swordQi(
    id: 'swordQi',
    sectName: '청풍검문',
    skillName: '검기 관통탄',
    description: '1칸 내공 완충 시 첫 변이체를 뚫고 일직선 대열 최대 4마리 연속 관통!',
    soundAsset: 'tech_swordQi.ogg',
    colorHex: 0xFF4CC9F0,
  ),
  ironFist(
    id: 'ironFist',
    sectName: '금강권문',
    skillName: '진각 파쇄탄',
    description: '1칸 내공 완충 시 착탄 지점 반경 충격파로 몰려오던 무리 전체 후방 밀침!',
    soundAsset: 'tech_stomp.ogg',
    colorHex: 0xFFFF9F1C,
  ),
  taiji(
    id: 'taiji',
    sectName: '태극도문',
    skillName: '태극 유도탄',
    description: '산길 굴곡을 따라 휘어 날아가며 내공 충전 속도 +25% · 방패 우회 특화!',
    soundAsset: 'tech_taiji.ogg',
    colorHex: 0xFF80ED99,
  ),
  shadowClone(
    id: 'shadowClone',
    sectName: '영월살문',
    skillName: '분신 쌍영탄',
    description: '변이체 적중 순간 알이 둘로 갈라져 양옆 길목 변이체를 동시 타격!',
    soundAsset: 'tech_clone.ogg',
    colorHex: 0xFFC77DFF,
  );

  const SectTechnique({
    required this.id,
    required this.sectName,
    required this.skillName,
    required this.description,
    required this.soundAsset,
    required this.colorHex,
  });

  final String id;
  final String sectName;
  final String skillName;
  final String description;
  final String soundAsset;
  final int colorHex;
}
