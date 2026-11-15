/// 심야 돌연변이·중간보스·대수괴 12종 분류 및 전투력 3대 분화(스피드·맷집·공격력) 정의.
enum MutantKind {
  swarmRat(
    id: 'swarmRat',
    name: '심야 독쥐',
    roleTag: '속공 군집형',
    speedRating: 4,
    toughnessRating: 1,
    attackRating: 1,
    baseHp: 34.0,
    speed: 64.0,
    mass: 0.75,
    radius: 11.0,
    dropTokens: 3,
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
    speedRating: 5,
    toughnessRating: 2,
    attackRating: 2,
    baseHp: 52.0,
    speed: 76.0,
    mass: 0.95,
    radius: 12.5,
    dropTokens: 4,
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
    speedRating: 2,
    toughnessRating: 4,
    attackRating: 3,
    baseHp: 138.0,
    speed: 41.0,
    mass: 2.35,
    radius: 16.5,
    dropTokens: 8,
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
    speedRating: 2,
    toughnessRating: 4,
    attackRating: 3,
    baseHp: 115.0,
    speed: 45.0,
    mass: 1.75,
    radius: 15.0,
    dropTokens: 8,
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
    speedRating: 1,
    toughnessRating: 3,
    attackRating: 3,
    baseHp: 96.0,
    speed: 37.0,
    mass: 1.45,
    radius: 15.5,
    dropTokens: 9,
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
    speedRating: 3,
    toughnessRating: 3,
    attackRating: 2,
    baseHp: 88.0,
    speed: 49.0,
    mass: 1.25,
    radius: 14.5,
    dropTokens: 7,
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
  swiftShadowBoss(
    id: 'swiftShadowBoss',
    name: '혈영 질풍귀',
    roleTag: '초고속 기습 중간보스',
    speedRating: 5,
    toughnessRating: 2,
    attackRating: 3,
    baseHp: 210.0,
    speed: 78.0,
    mass: 1.85,
    radius: 18.5,
    dropTokens: 18,
    attackPower: 34.0,
    armorReduction: 0.05,
    frontShieldReduction: 0.0,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    gaitId: 'shadowDash',
    colorHex: 0xFFC77DFF,
    screams: ['크악! 내 질풍보를 따라잡다니!', '그림자 속으로 후퇴한다!'],
  ),
  ironColossusBoss(
    id: 'ironColossusBoss',
    name: '현철 중갑거수',
    roleTag: '난공불락 맷집 중간보스',
    speedRating: 1,
    toughnessRating: 5,
    attackRating: 3,
    baseHp: 350.0,
    speed: 29.0,
    mass: 3.35,
    radius: 21.0,
    dropTokens: 24,
    attackPower: 36.0,
    armorReduction: 0.22,
    frontShieldReduction: 0.30,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    gaitId: 'colossusTread',
    colorHex: 0xFF90A4AE,
    screams: ['쿠구궁… 내 삼중 현철갑이…!', '이 무거운 몸이 밀리다니!'],
  ),
  crimsonBreakerBoss(
    id: 'crimsonBreakerBoss',
    name: '적염 파성귀',
    roleTag: '파성 강타 중간보스',
    speedRating: 3,
    toughnessRating: 3,
    attackRating: 5,
    baseHp: 255.0,
    speed: 45.0,
    mass: 2.45,
    radius: 19.5,
    dropTokens: 22,
    attackPower: 64.0,
    armorReduction: 0.08,
    frontShieldReduction: 0.10,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    gaitId: 'breakerSlam',
    colorHex: 0xFFFF4D00,
    screams: ['으아악! 내 파성 철퇴가 부러졌다!', '방어막 한 방만 더 치면 됐는데!'],
  ),
  raiderHeukpung(
    id: 'heukpung',
    name: '약탈 선봉 흑풍',
    roleTag: '약탈 돌격 우두머리',
    speedRating: 3,
    toughnessRating: 4,
    attackRating: 4,
    baseHp: 390.0,
    speed: 40.0,
    mass: 2.90,
    radius: 20.0,
    dropTokens: 28,
    attackPower: 52.0,
    armorReduction: 0.14,
    frontShieldReduction: 0.20,
    poisonAura: false,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    gaitId: 'dualCleaverRush',
    portraitPrefix: 'budumok',
    colorHex: 0xFFE63946,
    screams: ['크악! 훔친 식량 보따리 두고 간다!', '다음 밤엔 두고 보자!'],
  ),
  rivalMukhyeon(
    id: 'mukhyeonBoss',
    name: '독기에 물든 묵현',
    roleTag: '흑화 검기 우두머리',
    speedRating: 4,
    toughnessRating: 4,
    attackRating: 5,
    baseHp: 460.0,
    speed: 46.0,
    mass: 2.75,
    radius: 20.0,
    dropTokens: 34,
    attackPower: 58.0,
    armorReduction: 0.16,
    frontShieldReduction: 0.25,
    poisonAura: true,
    splitsOnDeath: false,
    isMidBoss: true,
    isBoss: true,
    gaitId: 'swordGlide',
    portraitPrefix: 'mukhyeon',
    colorHex: 0xFF5A189A,
    screams: ['크윽… 이 따뜻한 정화의 기운은…!', '사부의 뜻이… 이런 것이었나…'],
  ),
  chapterOverlord(
    id: 'chapterBoss',
    name: '심야 대요마',
    roleTag: '천상 대수괴',
    speedRating: 2,
    toughnessRating: 5,
    attackRating: 5,
    baseHp: 560.0,
    speed: 36.0,
    mass: 3.40,
    radius: 23.0,
    dropTokens: 45,
    attackPower: 75.0,
    armorReduction: 0.20,
    frontShieldReduction: 0.22,
    poisonAura: true,
    splitsOnDeath: false,
    isMidBoss: false,
    isBoss: true,
    gaitId: 'overlordFloat',
    portraitPrefix: 'tansin',
    colorHex: 0xFFFF0054,
    screams: ['크아아아— 독기가 걷힌다!!', '새벽빛이… 눈부시다…!'],
  );

  const MutantKind({
    required this.id,
    required this.name,
    required this.roleTag,
    required this.speedRating,
    required this.toughnessRating,
    required this.attackRating,
    required this.baseHp,
    required this.speed,
    required this.mass,
    required this.radius,
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
    this.portraitPrefix,
  });

  final String id;
  final String name;
  final String roleTag;
  final int speedRating;
  final int toughnessRating;
  final int attackRating;
  final double baseHp;
  final double speed;
  final double mass;
  final double radius;
  final int dropTokens;
  final double attackPower;
  final double armorReduction;
  final double frontShieldReduction;
  final bool poisonAura;
  final bool splitsOnDeath;
  final bool isMidBoss;
  final bool isBoss;
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

  /// 스피드·맷집·공격력 특징 및 상성 공략법 설명.
  String get traitDesc {
    switch (this) {
      case MutantKind.swarmRat:
        return '빠른 발로 떼 지어 길목을 파고들지만 맷집과 공격력은 약합니다. 속사 탄지기와 가벼운 만년기주로 손쉽게 일소하세요.';
      case MutantKind.sickHound:
        return '매우 빠른 질주와 주기적 도약 가속으로 방어막에 순식간에 달라붙습니다. 한빙 역장기의 냉기 감속으로 발을 묶으세요.';
      case MutantKind.ironBoar:
        return '두꺼운 철갑 외피와 무거운 체중으로 밀침을 버티며 돌진합니다. 현철·운철 등 고밀도 수호석과 중포 탄지기로 장갑을 관통하세요.';
      case MutantKind.shieldYacha:
        return '정면의 거대한 뼈방패로 직선 수호 알 피해를 대폭 흘려냅니다. 곡사 회전기나 담장·회전 기둥 도탄으로 측면을 노리세요.';
      case MutantKind.plagueToad:
        return '폴짝이며 도약 전진하고 마을 근처에서 독안개를 뿜어 논밭을 시들게 합니다. 사거리 밖에서 회심 타격으로 조기 정화하세요.';
      case MutantKind.bloodCocoon:
        return '일반 타격으로 쓰러지면 독쥐 두 마리로 분열합니다. 회심 박살을 일으키면 분열을 원천 봉쇄하고 연쇄 폭발을 터뜨립니다.';
      case MutantKind.swiftShadowBoss:
        return '중간보스 · 주기적으로 질풍보를 발동해 1.55배 초고속으로 기습합니다! 한빙 역장기와 예측 조준 수련으로 기동력을 꺾으세요.';
      case MutantKind.ironColossusBoss:
        return '중간보스 · 걸음은 느리지만 삼중 현철갑과 거대한 질량을 지닌 난공불락 거수입니다! 중포 탄지기와 무거운 수호석으로 장갑을 반관통하세요.';
      case MutantKind.crimsonBreakerBoss:
        return '중간보스 · 방어막과 수호탑에 치명적인 파성 철퇴 강타와 진동 충격파를 퍼붓습니다! 방어막 접근 전 내공탄과 어기어석으로 집중 제압하세요.';
      case MutantKind.raiderHeukpung:
        return '우두머리 · 약탈 무리를 이끌고 쌍식칼로 맹돌격하는 선봉장입니다. 중포 탄지기 승급과 동료 석두의 밀침으로 진격을 저지하세요.';
      case MutantKind.rivalMukhyeon:
        return '우두머리 · 빠른 검기 활보와 독기 오라, 매서운 참격을 겸비한 숙적입니다. 내공 증폭기와 정화 회심탄으로 독기를 씻어내세요.';
      case MutantKind.chapterOverlord:
        return '대수괴 · 압도적인 체력과 중갑, 파멸적인 공격력으로 마을 전체를 위협하는 최종 재앙입니다. 전 거점 승급과 영수·동료 총력전으로 맞서세요.';
    }
  }
}
