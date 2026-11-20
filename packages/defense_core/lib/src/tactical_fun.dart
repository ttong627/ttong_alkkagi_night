import 'campaign.dart';
import 'mutants.dart';

/// 물결 돌파 비급 카드 희귀도 등급.
enum RoguePerkRarity {
  common('일반 비급', 0xFF72EFDD),
  rare('희귀 비급', 0xFF4EA8DE),
  legendary('전설 비급', 0xFFFFD166);

  const RoguePerkRarity(this.label, this.colorHex);
  final String label;
  final int colorHex;
}

/// 《탕탕특공대 · 페글린 · 펀볼》 스타일 물결 돌파 3택 1 전술 비급 12종.
enum RoguePerk {
  splitShot(
    id: 'splitShot',
    title: '쌍탄 분열비급',
    badge: '🔥 탄환 2분열',
    description: '초소와 수호탑의 알이 첫 적 적중 시 2갈래 분열탄으로 쪼개져 주변 무리를 추가 타격합니다! (중첩 시 분열 위력 +40%)',
    rarity: RoguePerkRarity.legendary,
    colorHex: 0xFFFF6B35,
  ),
  chainLightning(
    id: 'chainLightning',
    title: '뇌전 연쇄탄',
    badge: '⚡ 번개 3연쇄',
    description: '알이 적이나 기둥에 부딪힐 때마다 주변 변이 최대 3체에게 푸른 뇌전 사슬 피해를 입힙니다!',
    rarity: RoguePerkRarity.rare,
    colorHex: 0xFF4CC9F0,
  ),
  corpseExplosion(
    id: 'corpseExplosion',
    title: '홍련 폭렬파',
    badge: '💥 처치 유폭',
    description: '변이체를 처치할 때마다 진홍 화염 대폭발(반경 62)이 일어나 뒤따르는 무리를 연쇄 폭사시킵니다!',
    rarity: RoguePerkRarity.legendary,
    colorHex: 0xFFE63946,
  ),
  luckyAscension(
    id: 'luckyAscension',
    title: '운명의 신화 승급',
    badge: '🎲 초소 무료 각성',
    description: '설치된 초소 중 1곳이 즉시 +1~2형 무료 각성 승급합니다! (설치 초소가 없으면 군수 기력 +75⚡ 즉시 지급)',
    rarity: RoguePerkRarity.legendary,
    colorHex: 0xFFFFD166,
  ),
  giantBoulder(
    id: 'giantBoulder',
    title: '태산 거대석',
    badge: '🪨 거대화·밀침↑',
    description: '발사되는 모든 수호석 크기 +38% 거대화 및 밀침 충격력 +55% 상승! 절벽 뽀록 추락이 대폭 늘어납니다.',
    rarity: RoguePerkRarity.rare,
    colorHex: 0xFFF4A261,
  ),
  frostNova(
    id: 'frostNova',
    title: '만년 빙옥진',
    badge: '❄️ 냉기·쇄빙폭발',
    description: '모든 탄환에 한기 감속을 부여하고, 얼거나 느려진 변이 처치 시 얼음 파편 범위 폭발을 일으킵니다!',
    rarity: RoguePerkRarity.rare,
    colorHex: 0xFF90E0EF,
  ),
  ricochetMaster(
    id: 'ricochetMaster',
    title: '신궁 도탄결',
    badge: '🎱 도탄 +2·증폭',
    description: '벽면·기둥 반사 도탄 횟수 +2회 증가 및 도탄 적중 시 피해량이 +55% 대폭 증폭됩니다!',
    rarity: RoguePerkRarity.common,
    colorHex: 0xFF72EFDD,
  ),
  warChest(
    id: 'warChest',
    title: '군수 기력 대보급',
    badge: '⚡ 즉시 +42기력',
    description: '즉시 초소 건설 기력 +42⚡을 지급받고, 이후 변이 처치 시 기력 구슬 획득량이 +25% 증가합니다!',
    rarity: RoguePerkRarity.common,
    colorHex: 0xFFFFD166,
  ),
  rapidBarrage(
    id: 'rapidBarrage',
    title: '질풍 폭사결',
    badge: '🏹 전 초소 가속',
    description: '배치된 모든 길목 초소의 연사 속도가 영구히 +30% 빨라집니다! (중첩 가능)',
    rarity: RoguePerkRarity.common,
    colorHex: 0xFF38BDF8,
  ),
  ironBastion(
    id: 'ironBastion',
    title: '금강 수호결계',
    badge: '🛡️ 방어막 대수복',
    description: '외곽 방어막과 마을 피해를 즉시 50% 수복하고 방어막 최대 내구도를 +30% 확장합니다!',
    rarity: RoguePerkRarity.common,
    colorHex: 0xFF34D399,
  ),
  allyAwakening(
    id: 'allyAwakening',
    title: '영수·동료 각성령',
    badge: '🐉 협공 주기 단축',
    description: '구출 동료와 신비 영수의 지원 출격 대기시간 -32% 단축 및 스킬 화력 +45% 강화!',
    rarity: RoguePerkRarity.rare,
    colorHex: 0xFFC77DFF,
  ),
  armorBreaker(
    id: 'armorBreaker',
    title: '파갑 멸마송',
    badge: '☠️ 장갑 완전관통',
    description: '뼈방패와 중갑 외피를 100% 관통 무시하며 중간보스·대수괴에게 주는 피해가 +40% 증가합니다!',
    rarity: RoguePerkRarity.rare,
    colorHex: 0xFFF72585,
  );

  const RoguePerk({
    required this.id,
    required this.title,
    required this.badge,
    required this.description,
    required this.rarity,
    required this.colorHex,
  });

  final String id;
  final String title;
  final String badge;
  final String description;
  final RoguePerkRarity rarity;
  final int colorHex;
}

/// 변이 처치·화약통 유폭·조기 호출 시 상단 건설 기력 게이지로 날아가는 황금 기력 구슬 연출 객체.
class FlyingQiOrb {
  FlyingQiOrb({
    required this.startPos,
    required this.targetPos,
    required this.amount,
    this.colorHex = 0xFFFFD166,
  }) : currentPos = startPos;

  final Vec2 startPos;
  final Vec2 targetPos;
  Vec2 currentPos;
  final int amount;
  final int colorHex;
  double progress = 0.0;
}

/// 전장 한가운데를 유영하며 통과하는 수호석 알을 2배(폭주 시 ×3배!)로 복제 증식시키는 배율 마법진!
class CloneGateZone {
  CloneGateZone({
    required this.baseCenter,
    this.radius = 24.0,
    this.swayAmplitude = 48.0,
    this.phase = 0.0,
  }) : center = baseCenter;

  final Vec2 baseCenter;
  Vec2 center;
  final double radius;
  final double swayAmplitude;
  double phase;
  double pulseAnim = 0.0;

  /// 탄알이 통과할 때마다 충전(0~10)되며, 10회 달성 시 8초간 🔥×3 삼류 폭주진으로 진화!
  int passCharge = 0;
  double tripleOverdriveTimer = 0.0;

  int get multiplier => tripleOverdriveTimer > 0 ? 3 : 2;
  double get chargeRatio =>
      tripleOverdriveTimer > 0 ? (tripleOverdriveTimer / 8.0).clamp(0.0, 1.0) : (passCharge / 10.0).clamp(0.0, 1.0);
}

/// 《라스트워 · 바운스 디펜스》 광고처럼 맞힐수록 전군 화력 배율(+10% → +60%)이 치솟는 이동식 숫자 과녁패!
class PowerTargetProp {
  PowerTargetProp({
    required this.baseCenter,
    this.radius = 19.0,
    this.swayAmplitude = 58.0,
    this.phase = 1.6,
  }) : center = baseCenter;

  final Vec2 baseCenter;
  Vec2 center;
  final double radius;
  final double swayAmplitude;
  double phase;
  int powerStacks = 0; // 0 ~ 6단 (+0% ~ +60% 전군 공격력 가산!)
  double decayTimer = 0.0;
  double pulseAnim = 0.0;

  int get bonusPercent => powerStacks * 10;
  double get damageMultiplier => 1.0 + powerStacks * 0.10;
}

/// 전투 중 실시간 단기 목표와 즉각적인 기력 대박을 주는 긴급 현상수배 미션!
class BattleBountyQuest {
  const BattleBountyQuest({
    required this.stepIndex,
    required this.title,
    required this.current,
    required this.goal,
    required this.rewardQi,
    required this.bonusLabel,
    required this.allCleared,
  });

  final int stepIndex;
  final String title;
  final int current;
  final int goal;
  final int rewardQi;
  final String bonusLabel;
  final bool allCleared;

  double get ratio => goal <= 0 ? 1.0 : (current / goal).clamp(0.0, 1.0);
}

/// 보스 강림·현상수배 달성 시 돌리는 꽝 없는 5칸 「운명의 태극 기연 돌림판」 보상!
enum DestinyRoulettePrize {
  hyperBarrage(
    title: '🌟 천뢰 무한 폭사',
    subtitle: '9초간 전 초소 연사 ×2.2배 & 확정 치명타 발동!',
    colorHex: 0xFFFFD166,
  ),
  qiJackpot(
    title: '💎 군수 기력 보급',
    subtitle: '즉시 초소 건설 기력 +48⚡ 황금 구슬 보급 지급!',
    colorHex: 0xFF72EFDD,
  ),
  mythicAwakening(
    title: '☯️ 태초 신기 각성',
    subtitle: '초소 1곳 즉시 +1형 무료 초월 진화(최대 ★5형 태초 신기)!',
    colorHex: 0xFFC77DFF,
  ),
  tripleGateFrenzy(
    title: '🔥 ×3 배율 & 화력 +60%',
    subtitle: '10초간 복제진이 ×3 삼류진으로 진화 + 화력 과녁 최대치 점화!',
    colorHex: 0xFFFF6B35,
  ),
  freeChulduSweep(
    title: '🎺 무림수호단 무료 출두',
    subtitle: '지원패 소모 없이 전장 변이 일소 & 방어막 50% 즉시 수복!',
    colorHex: 0xFF80ED99,
  );

  const DestinyRoulettePrize({
    required this.title,
    required this.subtitle,
    required this.colorHex,
  });

  final String title;
  final String subtitle;
  final int colorHex;
}

/// 산길 굽이 옆에 놓여 알로 맞히면 대폭발하며 주변 변이를 쓸어버리고 건설 기력을 주는 화약통 기물!
class PowderKegProp {
  PowderKegProp({
    required this.pos,
    this.intact = true,
    this.respawnTimer = 0.0,
  });

  final Vec2 pos;
  bool intact;
  double respawnTimer;
}

/// 전투 중 긴급 출몰하여 도주 전 저격 시 대량 건설 기력과 돌파 비급을 떨어뜨리는 황금 보물 도깨비!
class TreasureGoblinEntity {
  TreasureGoblinEntity({
    required this.pos,
    required this.vel,
    required this.maxHp,
  }) : hp = maxHp;

  Vec2 pos;
  final Vec2 vel;
  final double maxHp;
  double hp;
  bool alive = true;
  double animPhase = 0.0;
  double hitFlashTimer = 0.0;
}

/// 길목 빈 초소의 건설 조건 상태 (유저가 왜 지을 수 있는지/없는지 한눈에 인지).
enum PadConditionState {
  waveLocked,
  rubbleBlocked,
  chargingQi,
  readyLuckyOnly,
  readyFullBuild,
  built,
}

/// 각 초소의 실시간 건설 조건 안내 데이터.
class PadConditionInfo {
  const PadConditionInfo({
    required this.slotIndex,
    required this.state,
    required this.unlockWaveNumber,
    required this.currentQi,
    required this.luckySummonCost,
    required this.directBuildCost,
    required this.chargeRatio,
    required this.shortBadge,
    required this.detailReason,
    this.excavationCost = 0,
  });

  final int slotIndex;
  final PadConditionState state;
  final int unlockWaveNumber;
  final int currentQi;
  final int luckySummonCost;
  final int directBuildCost;
  final int excavationCost;
  final double chargeRatio;
  final String shortBadge;
  final String detailReason;
}

/// 배치된 초소들 사이에 발동되는 무림 진법 시너지 광선 연결 정보.
class ActiveSynergyLink {
  const ActiveSynergyLink({
    required this.slotA,
    required this.slotB,
    required this.posA,
    required this.posB,
    required this.synergyName,
    required this.bonusSummary,
    required this.colorHex,
  });

  final int slotA;
  final int slotB;
  final Vec2 posA;
  final Vec2 posB;
  final String synergyName;
  final String bonusSummary;
  final int colorHex;
}

/// 두 점 사이 뇌전 사슬 시각 연출 선분.
class LightningArcFx {
  LightningArcFx({
    required this.from,
    required this.to,
    this.ttlSec = 0.24,
    this.colorHex = 0xFF4CC9F0,
  });

  final Vec2 from;
  final Vec2 to;
  double ttlSec;
  final int colorHex;
}

/// 돌연변이·괴물 처치 순간 뒤로 튕겨 날아가며 산산조각 폭발하는 랙돌·파편 연출 객체!
class MutantDeathRagdoll {
  MutantDeathRagdoll({
    required this.kind,
    required this.pos,
    required this.vel,
    required this.spinVel,
    required this.visualDiameter,
    required this.bodyWidthRatio,
    required this.colorHex,
    required this.isCriticalKill,
    this.rotationRad = 0.0,
    this.durationSec = 0.44,
  }) : ttlSec = durationSec;

  final MutantKind kind;
  Vec2 pos;
  Vec2 vel;
  double rotationRad;
  final double spinVel;
  final double visualDiameter;
  final double bodyWidthRatio;
  final int colorHex;
  final bool isCriticalKill;
  final double durationSec;
  double ttlSec;

  double get progress => (1.0 - (ttlSec / durationSec)).clamp(0.0, 1.0);
}

/// 발사대·중앙 수호탑 포구 화염 섬광 충격파 객체 (시원한 발사 타격감 연출).
class MuzzleFlashFx {
  MuzzleFlashFx({
    required this.pos,
    required this.angleRad,
    required this.colorHex,
    this.scale = 1.0,
    this.durationSec = 0.14,
  }) : ttlSec = durationSec;

  final Vec2 pos;
  final double angleRad;
  final int colorHex;
  final double scale;
  final double durationSec;
  double ttlSec;

  double get progress => (1.0 - (ttlSec / durationSec)).clamp(0.0, 1.0);
}

/// 괴물 타격·치명타·격살 순간 머리 위로 튀어 오르는 타격 숫자 팝업 객체.
class DamagePopupFx {
  DamagePopupFx({
    required this.pos,
    required this.vel,
    required this.damage,
    required this.isCrit,
    required this.isKill,
    required this.colorHex,
    this.durationSec = 0.56,
  }) : ttlSec = durationSec;

  Vec2 pos;
  Vec2 vel;
  final int damage;
  final bool isCrit;
  final bool isKill;
  final int colorHex;
  final double durationSec;
  double ttlSec;

  double get progress => (1.0 - (ttlSec / durationSec)).clamp(0.0, 1.0);
}
