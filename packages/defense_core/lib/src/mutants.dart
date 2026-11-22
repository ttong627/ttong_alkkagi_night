/// 심야 돌연변이·공중 비행 변이·행동대장·중간보스·천련 대수괴 14종 분류 및 전투력 분화 정의.
enum MutantKind {
  swarmRat(
    id: 'swarmRat',
    name: '심야 독쥐',
    roleTag: '속공 군집형',
    sizeClassLabel: '초소형 군집',
    speedRating: 4,
    toughnessRating: 1,
    attackRating: 1,
    baseHp: 32.0,
    swarmHpFactor: 0.42,
    speed: 68.0,
    mass: 0.65,
    radius: 8.2,
    visualDiameter: 19.0,
    bodyWidthRatio: 0.96,
    dropTokens: 1,
    attackPower: 10.0,
    armorReduction: 0.0,
    frontShieldReduction: 0.0,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: false,
    gaitId: 'scamper',
    colorHex: 0xFF7B2CBF,
    screams: ['찍이익!', '내 치즈가…!', '으악 낭떠러지다!'],
  ),
  sickHound(
    id: 'sickHound',
    name: '역병 들개',
    roleTag: '초고속 추격형',
    sizeClassLabel: '소형 추격',
    speedRating: 5,
    toughnessRating: 2,
    attackRating: 2,
    baseHp: 48.0,
    swarmHpFactor: 0.50,
    speed: 80.0,
    mass: 0.85,
    radius: 10.5,
    visualDiameter: 27.0,
    bodyWidthRatio: 1.15,
    dropTokens: 1,
    attackPower: 15.0,
    armorReduction: 0.0,
    frontShieldReduction: 0.0,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: false,
    gaitId: 'gallop',
    colorHex: 0xFF9D4EDD,
    screams: ['깨갱—!', '너무 빠르잖아!', '살려줘멍!'],
  ),
  ironBoar(
    id: 'ironBoar',
    name: '철피 멧돼지',
    roleTag: '중장갑 돌파형',
    sizeClassLabel: '대형 중갑',
    speedRating: 2,
    toughnessRating: 4,
    attackRating: 3,
    baseHp: 138.0,
    swarmHpFactor: 0.80,
    speed: 41.0,
    mass: 2.35,
    radius: 19.5,
    visualDiameter: 58.0,
    bodyWidthRatio: 1.18,
    dropTokens: 6,
    attackPower: 28.0,
    armorReduction: 0.14,
    frontShieldReduction: 0.25,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: false,
    gaitId: 'heavyStomp',
    colorHex: 0xFF6C757D,
    screams: ['꿀꺽?!', '내 철갑이 깨지다니!', '으아아 굴러떨어진다!'],
  ),
  shieldYacha(
    id: 'shieldYacha',
    name: '뼈방패 야차',
    roleTag: '전면 방패형',
    sizeClassLabel: '중형 방패병',
    speedRating: 2,
    toughnessRating: 4,
    attackRating: 3,
    baseHp: 115.0,
    swarmHpFactor: 0.76,
    speed: 45.0,
    mass: 1.75,
    radius: 15.2,
    visualDiameter: 43.0,
    bodyWidthRatio: 1.06,
    dropTokens: 5,
    attackPower: 24.0,
    armorReduction: 0.08,
    frontShieldReduction: 0.58,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: false,
    gaitId: 'shieldMarch',
    colorHex: 0xFFE07A5F,
    screams: ['옆구리는 반칙이야!', '방패가 돌아갔어!', '커헉!'],
  ),
  plagueToad(
    id: 'plagueToad',
    name: '독안개 두꺼비',
    roleTag: '맹독 침식형',
    sizeClassLabel: '대형 맹독수',
    speedRating: 1,
    toughnessRating: 3,
    attackRating: 3,
    baseHp: 96.0,
    swarmHpFactor: 0.78,
    speed: 37.0,
    mass: 1.45,
    radius: 17.5,
    visualDiameter: 51.0,
    bodyWidthRatio: 1.20,
    dropTokens: 6,
    attackPower: 23.0,
    armorReduction: 0.05,
    frontShieldReduction: 0.0,
    poisonAura: true,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: false,
    gaitId: 'toxicHop',
    colorHex: 0xFF52B788,
    screams: ['개굴악!!', '내 독주머니가!', '풍덩—!'],
  ),
  bloodCocoon(
    id: 'bloodCocoon',
    name: '혈독 분열충',
    roleTag: '자폭 분열형',
    sizeClassLabel: '중소형 분열충',
    speedRating: 3,
    toughnessRating: 3,
    attackRating: 2,
    baseHp: 88.0,
    swarmHpFactor: 0.72,
    speed: 49.0,
    mass: 1.25,
    radius: 13.0,
    visualDiameter: 35.0,
    bodyWidthRatio: 1.04,
    dropTokens: 5,
    attackPower: 20.0,
    armorReduction: 0.0,
    frontShieldReduction: 0.0,
    poisonAura: false,
    splitsOnDeath: true,
    isMidBoss: false,
    isBoss: false,
    gaitId: 'carapaceScuttle',
    colorHex: 0xFFD90429,
    screams: ['펑! 어라 왜 안 갈라져?!', '박살 났다아!', '으악!'],
  ),
  bloodWingBat(
    id: 'bloodWingBat',
    name: '혈익 흡혈박쥐',
    roleTag: '공중 강습형',
    sizeClassLabel: '소형 공중군집',
    speedRating: 5,
    toughnessRating: 2,
    attackRating: 2,
    baseHp: 42.0,
    swarmHpFactor: 0.48,
    speed: 74.0,
    mass: 0.72,
    radius: 10.2,
    visualDiameter: 30.0,
    bodyWidthRatio: 1.24,
    dropTokens: 2,
    attackPower: 14.0,
    armorReduction: 0.0,
    frontShieldReduction: 0.0,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: false,
    isFlying: true,
    baseHitShield: 0,
    gaitId: 'wingFlap',
    colorHex: 0xFFE63946,
    screams: ['끼이이익— 날개가!!', '하늘에서 추락한다아!', '대공 탄막이다!'],
  ),
  abyssalGargoyle(
    id: 'abyssalGargoyle',
    name: '심연 철익귀',
    roleTag: '공중 폭격 행동대장',
    sizeClassLabel: '특대형 공중대장',
    speedRating: 4,
    toughnessRating: 4,
    attackRating: 4,
    baseHp: 235.0,
    swarmHpFactor: 1.0,
    speed: 48.0,
    mass: 2.15,
    radius: 22.5,
    visualDiameter: 78.0,
    bodyWidthRatio: 1.22,
    dropTokens: 22,
    attackPower: 42.0,
    armorReduction: 0.10,
    frontShieldReduction: 0.08,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    isFlying: true,
    baseHitShield: 130,
    gaitId: 'skyDiveBoss',
    colorHex: 0xFF7209B7,
    screams: ['크아악! 내 강철 날개가 꺾였다!', '상공에서 격추당하다니!'],
  ),
  swiftShadowBoss(
    id: 'swiftShadowBoss',
    name: '혈영 질풍귀',
    roleTag: '초고속 기습 중간보스',
    sizeClassLabel: '특대형 기습보스',
    speedRating: 5,
    toughnessRating: 2,
    attackRating: 3,
    baseHp: 210.0,
    swarmHpFactor: 1.0,
    speed: 78.0,
    mass: 1.85,
    radius: 22.0,
    visualDiameter: 74.0,
    bodyWidthRatio: 1.04,
    dropTokens: 20,
    attackPower: 34.0,
    armorReduction: 0.05,
    frontShieldReduction: 0.0,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    baseHitShield: 120,
    gaitId: 'shadowDash',
    colorHex: 0xFFC77DFF,
    screams: ['크악! 내 질풍보를 따라잡다니!', '그림자 속으로 후퇴한다!'],
  ),
  ironColossusBoss(
    id: 'ironColossusBoss',
    name: '현철 중갑거수',
    roleTag: '난공불락 맷집 중간보스',
    sizeClassLabel: '거신형 철갑보스',
    speedRating: 1,
    toughnessRating: 5,
    attackRating: 3,
    baseHp: 350.0,
    swarmHpFactor: 1.0,
    speed: 29.0,
    mass: 3.35,
    radius: 26.5,
    visualDiameter: 92.0,
    bodyWidthRatio: 1.18,
    dropTokens: 26,
    attackPower: 36.0,
    armorReduction: 0.22,
    frontShieldReduction: 0.30,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    baseHitShield: 180,
    gaitId: 'colossusTread',
    colorHex: 0xFF90A4AE,
    screams: ['쿠구궁… 내 삼중 현철갑이…!', '이 무거운 몸이 밀리다니!'],
  ),
  crimsonBreakerBoss(
    id: 'crimsonBreakerBoss',
    name: '적염 파성귀',
    roleTag: '파성 강타 중간보스',
    sizeClassLabel: '특대형 파성보스',
    speedRating: 3,
    toughnessRating: 3,
    attackRating: 5,
    baseHp: 255.0,
    swarmHpFactor: 1.0,
    speed: 45.0,
    mass: 2.45,
    radius: 23.5,
    visualDiameter: 82.0,
    bodyWidthRatio: 1.10,
    dropTokens: 24,
    attackPower: 64.0,
    armorReduction: 0.08,
    frontShieldReduction: 0.10,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    baseHitShield: 150,
    gaitId: 'breakerSlam',
    colorHex: 0xFFFF4D00,
    screams: ['으아악! 내 파성 철퇴가 부러졌다!', '방어막 한 방만 더 치면 됐는데!'],
  ),
  raiderHeukpung(
    id: 'heukpung',
    name: '약탈 선봉 흑풍',
    roleTag: '약탈 돌격 우두머리',
    sizeClassLabel: '특대형 돌격장',
    speedRating: 3,
    toughnessRating: 4,
    attackRating: 4,
    baseHp: 390.0,
    swarmHpFactor: 1.0,
    speed: 40.0,
    mass: 2.90,
    radius: 23.5,
    visualDiameter: 80.0,
    bodyWidthRatio: 1.08,
    dropTokens: 30,
    attackPower: 52.0,
    armorReduction: 0.14,
    frontShieldReduction: 0.20,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    baseHitShield: 360,
    gaitId: 'dualCleaverRush',
    portraitPrefix: 'budumok',
    colorHex: 0xFFE63946,
    screams: ['크악! 훔친 식량 보따리 두고 간다!', '다음 밤엔 두고 보자!'],
  ),
  rivalMukhyeon(
    id: 'mukhyeonBoss',
    name: '독기에 물든 묵현',
    roleTag: '흑화 검기 우두머리',
    sizeClassLabel: '특대형 흑화검귀',
    speedRating: 4,
    toughnessRating: 4,
    attackRating: 5,
    baseHp: 460.0,
    swarmHpFactor: 1.0,
    speed: 46.0,
    mass: 2.75,
    radius: 23.0,
    visualDiameter: 78.0,
    bodyWidthRatio: 1.02,
    dropTokens: 36,
    attackPower: 58.0,
    armorReduction: 0.16,
    frontShieldReduction: 0.25,
    poisonAura: true,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    baseHitShield: 450,
    gaitId: 'swordGlide',
    portraitPrefix: 'mukhyeon',
    colorHex: 0xFF5A189A,
    screams: ['크윽… 이 따뜻한 정화의 기운은…!', '사부의 뜻이… 이런 것이었나…'],
  ),
  chapterOverlord(
    id: 'chapterBoss',
    name: '심야 대요마',
    roleTag: '천상 천련 대수괴',
    sizeClassLabel: '초거대 천련보스',
    speedRating: 2,
    toughnessRating: 5,
    attackRating: 5,
    baseHp: 560.0,
    swarmHpFactor: 1.0,
    speed: 36.0,
    mass: 3.40,
    radius: 30.0,
    visualDiameter: 108.0,
    bodyWidthRatio: 1.12,
    dropTokens: 50,
    attackPower: 75.0,
    armorReduction: 0.20,
    frontShieldReduction: 0.22,
    poisonAura: true,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: true,
    baseHitShield: 1000,
    gaitId: 'overlordFloat',
    portraitPrefix: 'tansin',
    colorHex: 0xFFFF0054,
    screams: ['크아아아— 천련 마갑이 깨지고 독기가 걷힌다!!', '새벽빛이… 눈부시다…!'],
  );

  const MutantKind({
    required this.id,
    required this.name,
    required this.roleTag,
    required this.sizeClassLabel,
    required this.speedRating,
    required this.toughnessRating,
    required this.attackRating,
    required this.baseHp,
    required this.swarmHpFactor,
    required this.speed,
    required this.mass,
    required this.radius,
    required this.visualDiameter,
    required this.bodyWidthRatio,
    required this.dropTokens,
    required this.attackPower,
    required this.armorReduction,
    required this.frontShieldReduction,
    required this.poisonAura,
    required this.splitsOnDeath,
    required this.isMidBoss,
    required this.isBoss,
    required this.gaitId,
    required this.colorHex,
    required this.screams,
    this.isFlying = false,
    this.baseHitShield = 0,
    this.portraitPrefix,
  });

  final String id;
  final String name;
  final String roleTag;
  final String sizeClassLabel;
  final int speedRating;
  final int toughnessRating;
  final int attackRating;
  final double baseHp;
  final double swarmHpFactor;
  final double speed;
  final double mass;
  final double radius;
  final double visualDiameter;
  final double bodyWidthRatio;
  final int dropTokens;
  final double attackPower;
  final double armorReduction;
  final double frontShieldReduction;
  final bool poisonAura;
  final bool splitsOnDeath;
  final bool isMidBoss;
  final bool isBoss;
  final bool isFlying;
  final int baseHitShield;
  final String gaitId;
  final String? portraitPrefix;
  final int colorHex;
  final List<String> screams;

  /// 기존 참조와의 하위 호환성을 위한 방어막 타격력 게터.
  double get shieldDamage => attackPower;

  /// 체력·장갑·속도·질량·공격력을 종합한 직관적 전투력 지수.
  int get combatPower {
    final effectiveHp = baseHp * (1.0 + armorReduction * 1.1 + frontShieldReduction * 0.40);
    final speedBonus = speed > 65.0 ? (speed - 65.0) * 1.8 : 0.0;
    final dashSkillBonus = gaitId == 'shadowDash' ? 115.0 : 0.0;
    final raw = effectiveHp * 1.14 +
        attackPower * 3.8 +
        speed * 0.42 +
        speedBonus +
        mass * 20.0 +
        frontShieldReduction * 60.0 +
        (poisonAura ? 24.0 : 0.0) +
        (splitsOnDeath ? 24.0 : 0.0) +
        dashSkillBonus;
    final bossScale = isBoss ? (isMidBoss ? 1.45 : 1.57) : 1.0;
    return (raw * bossScale).round();
  }

  /// 스피드·맷집·공격력·체급 특징 및 상성 공략법 설명.
  String get traitDesc {
    switch (this) {
      case MutantKind.swarmRat:
        return '[초소형 군집] 작은 몸집으로 수십 마리씩 바글바글 떼 지어 길목을 파고듭니다. 속사 탄지기의 연속 관통탄으로 한꺼번에 쓸어버리세요.';
      case MutantKind.sickHound:
        return '[소형 추격] 날렵한 체형으로 무리 지어 질주하며 도약 가속으로 방어막을 덮칩니다. 한빙 역장기의 냉기 감속으로 발을 묶으세요.';
      case MutantKind.ironBoar:
        return '[대형 중갑] 독쥐의 3배에 달하는 육중한 강철 덩치로 밀침을 버티며 돌진합니다. 현철·운철 수호석과 중포 탄지기로 장갑을 부수세요.';
      case MutantKind.shieldYacha:
        return '[중형 방패병] 정면의 두꺼운 뼈방패로 직선 수호 알 피해를 흘려냅니다. 곡사 회전기나 담장·회전 기둥 도탄으로 옆구리를 노리세요.';
      case MutantKind.plagueToad:
        return '[대형 맹독수] 묵직하게 도약 전진하며 마을 근처에서 독안개를 뿜어 논밭을 시들게 합니다. 사거리 밖에서 회심 타격으로 조기 정화하세요.';
      case MutantKind.bloodCocoon:
        return '[중소형 분열충] 등 위의 붉은 독주머니가 터지면 독쥐 무리로 분열합니다. 회심 박살을 일으키면 분열을 봉쇄하고 연쇄 폭발을 터뜨립니다.';
      case MutantKind.bloodWingBat:
        return '[소형 공중군집 · 🪽비행] 낭떠러지와 지상 장애물을 무시하고 상공에서 급강하 습격합니다! 속사 탄지기와 곡사 회전기의 대공 화망으로 격추하세요.';
      case MutantKind.abyssalGargoyle:
        return '[특대형 공중 행동대장 · 🪽비행 · 🛡️100타+ 백련마갑] 창공을 가르며 강림하는 공중 행동대장입니다! 100대 이상의 연타 세례와 정밀 약점 저격으로 날개를 꺾으세요.';
      case MutantKind.swiftShadowBoss:
        return '[특대형 기습 행동대장 · 🛡️100타+ 백련마갑] 질풍보를 발동해 1.55배 초고속으로 기습하는 두목입니다! 한빙 역장기 감속과 연타 집중으로 기동력을 꺾으세요.';
      case MutantKind.ironColossusBoss:
        return '[거신형 철갑 중간보스 · 🛡️180타+ 백련마갑] 길을 가득 메우는 거대한 삼중 현철갑 골렘입니다! 중포 파편 연타와 약점 저격으로 두꺼운 마갑을 부수세요.';
      case MutantKind.crimsonBreakerBoss:
        return '[특대형 파성 중간보스 · 🛡️150타+ 백련마갑] 방어막과 수호탑에 치명적인 파성 철퇴 강타를 퍼붓습니다! 150타 이상 연타 화망으로 제압하세요.';
      case MutantKind.raiderHeukpung:
        return '[특대형 약탈 부두목 · 🛡️360타+ 백련마갑] 대규모 약탈 무리를 이끌고 쌍식칼로 맹돌격하는 부두목입니다. 전 초소 다중 연타와 정밀 저격으로 격퇴하세요.';
      case MutantKind.rivalMukhyeon:
        return '[특대형 흑화 숙적 · 🛡️450타+ 백련마갑] 검기 활보와 독기 오라를 두른 숙적입니다. 내공 증폭기와 수백 회 정화 연타로 독기를 씻어내세요.';
      case MutantKind.chapterOverlord:
        return '[초거대 각 장 최종보스 · 🛡️1,000타+ 천련마갑] 각 장을 지배하는 3페이즈 최종 대수괴입니다! 1,000대 이상의 총력 연타와 🎯약점 파쇄 없이는 결코 쓰러지지 않습니다.';
    }
  }
}
