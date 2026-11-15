/// 내공 8경지 · 영수 5종 · 동료 14인(13종 + 특별 난입 묵현) 및 자동 발동 조건 모델.
enum NaegongRealm {
  samryu(indexStep: 0, name: '삼류', reqNaegong: 0, reqElixir: 0, startQiBars: 0.0, eogieoseokCount: 1, powerMult: 1.00, defenseMult: 1.00),
  iryu(indexStep: 1, name: '이류', reqNaegong: 80, reqElixir: 2, startQiBars: 0.3, eogieoseokCount: 1, powerMult: 1.10, defenseMult: 1.08),
  illyu(indexStep: 2, name: '일류', reqNaegong: 220, reqElixir: 5, startQiBars: 0.6, eogieoseokCount: 1, powerMult: 1.22, defenseMult: 1.18),
  jeoljeong(indexStep: 3, name: '절정', reqNaegong: 460, reqElixir: 9, startQiBars: 1.0, eogieoseokCount: 2, powerMult: 1.36, defenseMult: 1.30),
  chojeoljeong(indexStep: 4, name: '초절정', reqNaegong: 820, reqElixir: 15, startQiBars: 1.3, eogieoseokCount: 2, powerMult: 1.52, defenseMult: 1.44),
  hwagyeong(indexStep: 5, name: '화경', reqNaegong: 1320, reqElixir: 22, startQiBars: 1.6, eogieoseokCount: 2, powerMult: 1.70, defenseMult: 1.60),
  hyeongyeong(indexStep: 6, name: '현경', reqNaegong: 1950, reqElixir: 32, startQiBars: 2.0, eogieoseokCount: 3, powerMult: 1.92, defenseMult: 1.78),
  saengsagyeong(indexStep: 7, name: '생사경', reqNaegong: 2700, reqElixir: 45, startQiBars: 2.5, eogieoseokCount: 3, powerMult: 2.18, defenseMult: 2.00);

  const NaegongRealm({
    required this.indexStep,
    required this.name,
    required this.reqNaegong,
    required this.reqElixir,
    required this.startQiBars,
    required this.eogieoseokCount,
    required this.powerMult,
    required this.defenseMult,
  });

  final int indexStep;
  final String name;
  final int reqNaegong;
  final int reqElixir;
  final double startQiBars;
  final int eogieoseokCount;
  final double powerMult;
  final double defenseMult;

  NaegongRealm? get nextRealm =>
      indexStep + 1 < NaegongRealm.values.length ? NaegongRealm.values[indexStep + 1] : null;
}

/// 동료·영수·지원패가 자동으로 나서는 조건(플레이어가 전술 화면에서 자유 선택 가능).
enum AutoTriggerCondition {
  anyEnemyInRange('길목 침입 즉시 자동 요격', '사거리 안에 변이체가 들어오면 지체 없이 발동'),
  denseCluster('밀집 무리 포착 (4마리↑)', '한 길목에 변이체가 4마리 이상 뭉쳤을 때 집중 타격'),
  heavyOrBoss('중갑 · 우두머리 우선 타격', '철피 중갑 변이체나 흑풍·보스가 나타났을 때 발동'),
  shieldCrisis('방어막 위기 수호 (60%↓)', '외곽 기공 방어막이 60% 이하로 깎였을 때 긴급 개입'),
  qiFullBurst('내공 완충 연계 발동', '내공 게이지가 차올라 무공·어기어석이 나갈 때 합동 사격');

  const AutoTriggerCondition(this.label, this.detail);
  final String label;
  final String detail;
}

/// 영수 5종 (영약으로 레벨 1~10 강화).
enum SpiritBeast {
  nalssaendol(
    id: 'nalssaendol',
    name: '다람쥐 날쌘돌',
    unlockChapter: 1,
    unlockElixirs: 0,
    baseCooldownSec: 4.5,
    defaultCondition: AutoTriggerCondition.anyEnemyInRange,
    skillSummary: '중앙 보호 장치 사격마다 도토리 기공탄을 함께 자동 발사해 앞줄 견제!',
    battleCry: '찍찍! 우리 마을 곡식은 못 건드려!',
    colorHex: 0xFFE9C46A,
  ),
  geumgangTurtle(
    id: 'geumgang',
    name: '영귀 금강',
    unlockChapter: 3,
    unlockElixirs: 4,
    baseCooldownSec: 9.5,
    defaultCondition: AutoTriggerCondition.shieldCrisis,
    skillSummary: '외곽 방어막 위기 시 현무 등껍질 결계로 방어막 18% 즉시 수복 + 접근 적 밀침!',
    battleCry: '크오오—! 현무의 등껍질은 뚫리지 않는다!',
    colorHex: 0xFF2A9D8F,
  ),
  cheonghak(
    id: 'cheonghak',
    name: '선학 청학',
    unlockChapter: 4,
    unlockElixirs: 6,
    baseCooldownSec: 7.0,
    defaultCondition: AutoTriggerCondition.anyEnemyInRange,
    skillSummary: '은빛 날개 바람으로 모든 발사대 탄속 +20% · 회심률 +10% 버프 및 원거리 관통탄!',
    battleCry: '끼룩—! 밤안개를 걷어 내리라!',
    colorHex: 0xFF90E0EF,
  ),
  baekho(
    id: 'baekho',
    name: '신수 백호',
    unlockChapter: 6,
    unlockElixirs: 10,
    baseCooldownSec: 8.5,
    defaultCondition: AutoTriggerCondition.denseCluster,
    skillSummary: '밀집 길목을 향해 백호 포효와 함께 강화 쌍알(2발) 동시 발사 + 대량 장외 추락!',
    battleCry: '어흥—!! 산군의 포효를 받아라!',
    colorHex: 0xFFF8F9FA,
  ),
  geumryong(
    id: 'geumryong',
    name: '천룡 금룡',
    unlockChapter: 8,
    unlockElixirs: 16,
    baseCooldownSec: 10.5,
    defaultCondition: AutoTriggerCondition.heavyOrBoss,
    skillSummary: '황금 용이 길목을 휩쓸며 수호 알 4발 일제 투하 + 적중 일반 변이체 즉시 연쇄 박살!',
    battleCry: '크아아앙—! 황금 용린의 심판이다!',
    colorHex: 0xFFFFB703,
  );

  const SpiritBeast({
    required this.id,
    required this.name,
    required this.unlockChapter,
    required this.unlockElixirs,
    required this.baseCooldownSec,
    required this.defaultCondition,
    required this.skillSummary,
    required this.battleCry,
    required this.colorHex,
  });

  final String id;
  final String name;
  final int unlockChapter;
  final int unlockElixirs;
  final double baseCooldownSec;
  final AutoTriggerCondition defaultCondition;
  final String skillSummary;
  final String battleCry;
  final int colorHex;

  int upgradeElixirCost(int currentLevel) => 2 + currentLevel * 2;
}

/// 동료 영웅 14인 (초소 최대 3인 편성 + 6장 이후 위기 시 묵현 특별 자동 난입).
enum CompanionHero {
  seokdu(
    id: 'seokdu',
    name: '석두',
    title: '바위 주먹 의용대장',
    portraitPrefix: 'seokdu',
    unlockChapter: 1,
    unlockElixirs: 0,
    cooldownSec: 6.2,
    defaultCondition: AutoTriggerCondition.heavyOrBoss,
    skillDesc: '중갑·대형 변이체에게 묵직한 현철 강타탄을 쏘아 크게 뒷걸음질치게 함',
  ),
  yeonbi(
    id: 'yeonbi',
    name: '연비',
    title: '비연 곡선 명사수',
    portraitPrefix: 'yeonbi',
    unlockChapter: 1,
    unlockElixirs: 0,
    cooldownSec: 5.2,
    defaultCondition: AutoTriggerCondition.denseCluster,
    skillDesc: '굽은 산길 모퉁이 무리에게 회전 스핀탄을 날려 방패 뒤까지 연타',
  ),
  cheongmyeong(
    id: 'cheongmyeong',
    name: '청명',
    title: '청운 도관 수제자',
    portraitPrefix: 'cheongmyeong',
    unlockChapter: 1,
    unlockElixirs: 0,
    cooldownSec: 7.5,
    defaultCondition: AutoTriggerCondition.qiFullBurst,
    skillDesc: '출격 시 내공 +0.65칸 즉시 보충 및 정화 유도탄 발사',
  ),
  bandal(
    id: 'bandal',
    name: '반달',
    title: '통통 객잔 호위무사',
    portraitPrefix: 'banDal',
    unlockChapter: 2,
    unlockElixirs: 0,
    cooldownSec: 7.0,
    defaultCondition: AutoTriggerCondition.denseCluster,
    skillDesc: '길목 바닥에 객잔 기름통 탄을 터뜨려 적들을 미끄러뜨리고 도탄 반발 +25%',
  ),
  gurumi(
    id: 'gurumi',
    name: '구르미',
    title: '산채 바람 정찰대장',
    portraitPrefix: 'gurumi',
    unlockChapter: 4,
    unlockElixirs: 0,
    cooldownSec: 5.6,
    defaultCondition: AutoTriggerCondition.anyEnemyInRange,
    skillDesc: '담장·회전 기둥을 노리는 풍압 도탄 알 2발을 연속 발사해 어부지리 연쇄 유도',
  ),
  jeonggak(
    id: 'jeonggak',
    name: '정각',
    title: '로직 학당 기관사',
    portraitPrefix: 'jeonggak',
    unlockChapter: 5,
    unlockElixirs: 0,
    cooldownSec: 8.5,
    defaultCondition: AutoTriggerCondition.anyEnemyInRange,
    skillDesc: '5초 동안 마을 모든 길목 자동 발사대의 장전 속도를 1.45배 가속!',
  ),
  yonga(
    id: 'yonga',
    name: '용아',
    title: '무림맹 선봉 소장군',
    portraitPrefix: 'yonga',
    unlockChapter: 6,
    unlockElixirs: 0,
    cooldownSec: 6.8,
    defaultCondition: AutoTriggerCondition.qiFullBurst,
    skillDesc: '강력한 황금 용아 충격탄을 쏘아 직선 길목 변이체들을 관통 분쇄',
  ),
  chwiseon(
    id: 'chwiseon',
    name: '취선',
    title: '달밤의 호리병 도인',
    portraitPrefix: 'chwiseon',
    unlockChapter: 3,
    unlockElixirs: 5,
    cooldownSec: 8.0,
    defaultCondition: AutoTriggerCondition.qiFullBurst,
    skillDesc: '호리병 선기를 불어넣어 내공 +1.1칸 급속 충전 및 취권 지그재그 탄 발사',
  ),
  mukgaek(
    id: 'mukgaek',
    name: '묵객',
    title: '수묵 결계 서생',
    portraitPrefix: 'mukgaek',
    unlockChapter: 4,
    unlockElixirs: 6,
    cooldownSec: 7.4,
    defaultCondition: AutoTriggerCondition.denseCluster,
    skillDesc: '먹물 붓질 탄으로 변이체 이동속도를 40% 늦추고 절벽 추락 확률 증가',
  ),
  seolhwa(
    id: 'seolhwa',
    name: '설화',
    title: '북해 빙궁 여협',
    portraitPrefix: 'seolhwa',
    unlockChapter: 5,
    unlockElixirs: 7,
    cooldownSec: 7.8,
    defaultCondition: AutoTriggerCondition.denseCluster,
    skillDesc: '눈보라 파동탄으로 길목 적들을 1.6초 빙결시키고 방어막에 냉기 호신막 부여',
  ),
  magyo(
    id: 'magyo',
    name: '천마 화신',
    title: '환골탈태 흡성 고수',
    portraitPrefix: 'magyo',
    unlockChapter: 7,
    unlockElixirs: 12,
    cooldownSec: 8.2,
    defaultCondition: AutoTriggerCondition.heavyOrBoss,
    skillDesc: '흡성 중력탄으로 흩어진 변이체들을 한 지점으로 끌어모아 일망타진!',
  ),
  geomhwang(
    id: 'geomhwang',
    name: '검황',
    title: '이기어검 전설',
    portraitPrefix: 'geomhwang',
    unlockChapter: 8,
    unlockElixirs: 14,
    cooldownSec: 6.5,
    defaultCondition: AutoTriggerCondition.heavyOrBoss,
    skillDesc: '3자루의 어검 수호탄이 우두머리와 독안개 변이체를 끝까지 추적해 회심 타격!',
  ),
  sinseung(
    id: 'sinseung',
    name: '무량 신승',
    title: '금강불괴 방어 대사',
    portraitPrefix: 'sinseung',
    unlockChapter: 9,
    unlockElixirs: 16,
    cooldownSec: 9.0,
    defaultCondition: AutoTriggerCondition.shieldCrisis,
    skillDesc: '자비의 금빛 종소리로 외곽 방어막 22% 회복 및 논밭·가축 독기 즉시 정화!',
  ),
  mukhyeon(
    id: 'mukhyeon',
    name: '묵현',
    title: '참회한 정화 흑검 (6장 합류)',
    portraitPrefix: 'mukhyeon',
    unlockChapter: 6,
    unlockElixirs: 0,
    cooldownSec: 12.0,
    defaultCondition: AutoTriggerCondition.shieldCrisis,
    skillDesc: '6장 클리어 시 편성 칸과 별개로 방어막 붕괴 위기마다 자동 난입해 앞줄 일소!',
  );

  const CompanionHero({
    required this.id,
    required this.name,
    required this.title,
    required this.portraitPrefix,
    required this.unlockChapter,
    required this.unlockElixirs,
    required this.cooldownSec,
    required this.defaultCondition,
    required this.skillDesc,
  });

  final String id;
  final String name;
  final String title;
  final String portraitPrefix;
  final int unlockChapter;
  final int unlockElixirs;
  final double cooldownSec;
  final AutoTriggerCondition defaultCondition;
  final String skillDesc;

  String get faceAsset => 'assets/images/chars/${portraitPrefix}_face.webp';
  String get attackAsset => 'assets/images/chars/${portraitPrefix}_attack.webp';

  int upgradeElixirCost(int currentLevel) => 1 + currentLevel * 2;
}
