import 'dart:math';
import 'package:flutter/material.dart';

/// 영상 시제품(`render_mutant_motion_video.py`)에서 설계·검증된 12종 돌연변이·우두머리 연속 생체역학 모션 결과값.
class MutantMotionSample {
  const MutantMotionSample({
    required this.liftY,
    required this.swayX,
    required this.forwardThrust,
    required this.scaleX,
    required this.scaleY,
    required this.tiltRad,
    required this.shadowScale,
    required this.shadowAlpha,
    required this.footImpact,
    required this.useAttackSprite,
    required this.attackBlend,
    required this.afterimageCount,
    required this.slashArcAlpha,
    required this.slashColor,
  });

  /// 발바닥 기준 수직 도약 높이(음수 = 공중 부양·점프).
  final double liftY;

  /// 진행 방향 수직 좌우 편대·어깨 흔들림.
  final double swayX;

  /// 공격 덮치기 또는 돌진 시 전방 돌출 거리.
  final double forwardThrust;

  /// 부피 보존 가로 신축 배율.
  final double scaleX;

  /// 부피 보존 세로 신축 배율.
  final double scaleY;

  /// 발목 축 기준 회전 기울기(라디안).
  final double tiltRad;

  /// 지면 그림자 크기 배율(높이 뛸수록 작아짐).
  final double shadowScale;

  /// 지면 그림자 불투명도.
  final double shadowAlpha;

  /// 착지 발구름 강도(0.0 ~ 1.0, 흙먼지·진동 파동 생성 기준).
  final double footImpact;

  /// 코덱스 공격 원화(`mut_*_atk.webp`) 주력 사용 여부.
  final bool useAttackSprite;

  /// 기본 행군 원화 ↔ 공격 원화 연속 크로스페이드 가중치(0.0 ~ 1.0).
  final double attackBlend;

  /// 초고속 기습형 잔상 개수(0 ~ 3).
  final int afterimageCount;

  /// 전방 발톱·철퇴·검기 궤적 투명도(0.0 ~ 1.0).
  final double slashArcAlpha;

  /// 전방 타격 궤적 색상.
  final Color slashColor;
}

/// 60프레임 연속 미분 가능 곡선(코사인 종형 파형 · 스무스스텝) 기반 생체역학 모션 엔진.
class MutantMotionEngine {
  const MutantMotionEngine._();

  static double _smoothStep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /// 첨점(|sin|) 없이 매끄럽게 솟구쳤다 내려앉는 연속 보행 호(0.0 ~ 1.0).
  static double _smoothHop(double phase) => 0.5 - 0.5 * cos(phase * 2.0);

  static MutantMotionSample sample({
    required String gaitId,
    required double animPhase,
    required double elapsedSec,
    required int uid,
    required double headingRad,
    required double attackAnimTimer,
    required double dashBurstTimer,
    required double freezeTimer,
    required double knockbackSpeed,
  }) {
    final safePhase = animPhase.isFinite ? animPhase : 0.0;
    final safeTime = elapsedSec.isFinite ? elapsedSec : 0.0;

    // 빙결 상태에서는 미세한 냉기 떨림 외에 자세 고정
    if (freezeTimer > 0.01) {
      return const MutantMotionSample(
        liftY: 0.0,
        swayX: 0.0,
        forwardThrust: 0.0,
        scaleX: 1.02,
        scaleY: 0.98,
        tiltRad: 0.0,
        shadowScale: 1.0,
        shadowAlpha: 0.42,
        footImpact: 0.0,
        useAttackSprite: false,
        attackBlend: 0.0,
        afterimageCount: 0,
        slashArcAlpha: 0.0,
        slashColor: Color(0xFF90E0EF),
      );
    }

    double liftY = 0.0;
    double swayX = 0.0;
    double scaleX = 1.0;
    double scaleY = 1.0;
    double tiltRad = 0.0;
    double footImpact = 0.0;
    int afterimages = 0;
    Color slashColor = const Color(0xFFFF4D6D);

    // 곡선 산길을 돌아 내려올 때 진행 방향 좌우 성분에 맞춰 부드럽게 몸을 기울임
    final moveBank = cos(headingRad) * 0.095;

    switch (gaitId) {
      case 'scamper': // 심야 독쥐: 재빠르고 매끄러운 종종걸음 + 좌우 갸우뚱
        final p = safePhase * 1.85 + uid * 0.47;
        final hop = _smoothHop(p);
        liftY = -hop * 3.4;
        swayX = sin(p) * 2.1;
        scaleY = 0.94 + hop * 0.12;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank + sin(p) * 0.11;
        footImpact = _smoothStep(0.72, 1.0, 1.0 - hop) * 0.65;
        slashColor = const Color(0xFFC77DFF);
        break;

      case 'gallop': // 역병 들개: 네 발 짐승 탄력 도약 질주
        final p = safePhase * 1.55 + uid * 0.31;
        final g = sin(p);
        final leap = _smoothStep(0.0, 1.0, max(0.0, g));
        final land = _smoothStep(0.0, 1.0, max(0.0, -g));
        liftY = -leap * 6.8;
        swayX = cos(p * 0.5 + uid) * 1.9;
        scaleY = 1.0 + leap * 0.13 - land * 0.09;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.3 + g * 0.10;
        footImpact = _smoothStep(0.55, 1.0, land);
        afterimages = dashBurstTimer > 0.05 ? 2 : 0;
        slashColor = const Color(0xFF9D4EDD);
        break;

      case 'heavyStomp': // 철피 멧돼지: 묵직한 어깨 롤링 + 육중한 발구름
        final p = safePhase * 1.05 + uid * 0.23;
        final w = sin(p);
        final hop = _smoothHop(p);
        final stomp = _smoothStep(0.52, 1.0, 1.0 - hop);
        liftY = -hop * 3.2;
        swayX = w * 2.4;
        scaleX = 0.97 + stomp * 0.09;
        scaleY = 1.0 / scaleX;
        tiltRad = moveBank * 0.85 + w * 0.09;
        footImpact = stomp;
        slashColor = const Color(0xFFFF9F1C);
        break;

      case 'shieldMarch': // 뼈방패 야차: 낮은 무게중심 방패 전진 보법
        final p = safePhase * 1.15 + uid * 0.29;
        final m = sin(p);
        final step = _smoothHop(p);
        liftY = -step * 2.5;
        swayX = m * 1.4;
        scaleX = 1.03 - step * 0.05;
        scaleY = 1.0 / scaleX;
        tiltRad = moveBank * 0.65 + m * 0.055;
        footImpact = _smoothStep(0.68, 1.0, 1.0 - step) * 0.72;
        slashColor = const Color(0xFFFFD166);
        break;

      case 'toxicHop': // 독안개 두꺼비: 부드러운 웅크림 → 매끈한 포물선 점프 → 착지 탄성!
        final cyc = ((safePhase * 0.40 + uid * 0.61) % (2 * pi) + 2 * pi) % (2 * pi);
        final norm = cyc / (2 * pi);
        if (norm < 0.24) {
          final crouch = 0.5 - 0.5 * cos((norm / 0.24) * 2 * pi);
          liftY = 0.0;
          scaleX = 1.0 + crouch * 0.16;
          scaleY = 1.0 / scaleX;
          footImpact = 0.0;
        } else if (norm < 0.76) {
          final airT = (norm - 0.24) / 0.52;
          final arc = sin(airT * pi);
          liftY = -arc * 10.8;
          scaleY = 1.0 + arc * 0.14;
          scaleX = 1.0 / scaleY;
          tiltRad = moveBank + cos(airT * pi) * 0.075;
        } else {
          final splat = 0.5 - 0.5 * cos(((norm - 0.76) / 0.24) * 2 * pi);
          liftY = 0.0;
          scaleX = 1.0 + splat * 0.14;
          scaleY = 1.0 / scaleX;
          footImpact = splat;
        }
        slashColor = const Color(0xFFC77DFF);
        break;

      case 'carapaceScuttle': // 혈독 분열충: 촘촘한 다리 파동 + 붉은 독핵 심장박동
        final p = safePhase * 2.1 + uid * 0.37;
        final hop = _smoothHop(p);
        final pulse = sin(safeTime * 6.8 + uid) * 0.05;
        liftY = -hop * 2.2;
        swayX = sin(p) * 1.9;
        scaleX = 1.0 + pulse + hop * 0.035;
        scaleY = 1.0 + pulse - hop * 0.035;
        tiltRad = moveBank + sin(p) * 0.08;
        footImpact = _smoothStep(0.75, 1.0, 1.0 - hop) * 0.52;
        slashColor = const Color(0xFFFF0054);
        break;

      case 'wingFlap': // 혈익 흡혈박쥐: 지면 위 높은 고도에서 빠른 날개짓 + 상공 선회 급강하!
        final p = safePhase * 2.45 + uid * 0.53;
        final flap = sin(p);
        liftY = -20.5 - flap * 4.8;
        swayX = cos(p * 0.55 + uid) * 4.2;
        scaleX = 1.04 + flap * 0.14;
        scaleY = 0.96 - flap * 0.09;
        tiltRad = moveBank * 1.65 + sin(p * 0.55) * 0.14;
        footImpact = 0.0;
        afterimages = 1;
        slashColor = const Color(0xFFFF4D6D);
        break;

      case 'skyDiveBoss': // 심연 철익귀(공중 행동대장): 육중한 강철 날개 체공 + 폭격 급강하!
        final p = safePhase * 1.45 + uid * 0.27;
        final beat = sin(p);
        liftY = -24.0 - beat * 5.6;
        swayX = sin(safeTime * 2.1 + uid) * 3.6;
        scaleX = 1.03 + beat * 0.11;
        scaleY = 0.98 - beat * 0.07;
        tiltRad = moveBank * 1.25 + cos(p * 0.5) * 0.09;
        footImpact = 0.0;
        afterimages = 2;
        slashColor = const Color(0xFFC77DFF);
        break;

      case 'shadowDash': // 혈영 질풍귀(속도형 중간보스): 잔상 경공 질주 + 쌍갈퀴 베기
        final p = safePhase * 1.95 + uid * 0.19;
        final hop = _smoothHop(p);
        final dashRatio = _smoothStep(0.0, 0.25, dashBurstTimer);
        liftY = -3.2 - hop * 4.2 - dashRatio * 1.8;
        swayX = sin(p) * (2.5 + dashRatio * 1.8);
        scaleY = 1.04 + hop * 0.07;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.55 + sin(p) * 0.11;
        afterimages = dashBurstTimer > 0.05 ? 3 : 2;
        footImpact = _smoothStep(0.76, 1.0, 1.0 - hop) * 0.72;
        slashColor = const Color(0xFFE0AAFF);
        break;

      case 'colossusTread': // 현철 중갑거수(맷집형 중간보스): 대지를 울리는 육중한 거인 보행
        final p = safePhase * 0.74;
        final tr = sin(p);
        final hop = _smoothHop(p);
        final heavyLand = pow(1.0 - hop, 2.4).toDouble();
        liftY = -hop * 4.0;
        swayX = tr * 2.9;
        scaleX = 1.0 + heavyLand * 0.10;
        scaleY = 1.0 / scaleX;
        tiltRad = moveBank * 0.5 + tr * 0.075;
        footImpact = _smoothStep(0.58, 1.0, heavyLand);
        slashColor = const Color(0xFFFFD166);
        break;

      case 'breakerSlam': // 적염 파성귀(공격력형 중간보스): 파성 철퇴 어깨 스윙 행군
        final p = safePhase * 0.98;
        final br = sin(p);
        final hop = _smoothHop(p);
        liftY = -hop * 4.4;
        swayX = br * 2.7;
        scaleY = 0.96 + hop * 0.095;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank + br * 0.125;
        footImpact = _smoothStep(0.72, 1.0, 1.0 - hop) * 0.85;
        slashColor = const Color(0xFFFF4D00);
        break;

      case 'dualCleaverRush': // 약탈 선봉 흑풍: 쌍식칼 호기로운 돌격 보법
        final p = safePhase * 1.32;
        final hk = sin(p);
        final hop = _smoothHop(p);
        liftY = -hop * 4.8;
        swayX = hk * 2.4;
        scaleY = 0.96 + hop * 0.10;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.15 + hk * 0.11;
        footImpact = _smoothStep(0.70, 1.0, 1.0 - hop) * 0.80;
        slashColor = const Color(0xFFE63946);
        break;

      case 'swordGlide': // 독기에 물든 묵현: 무협 경공 활공 + 흑화 검기 잔상
        liftY = -5.5 - sin(safeTime * 3.1 + uid) * 3.0;
        swayX = sin(safeTime * 2.0 + uid) * 3.4;
        scaleY = 1.02 + sin(safeTime * 3.1) * 0.038;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.25 + cos(safeTime * 2.0) * 0.075;
        afterimages = 2;
        slashColor = const Color(0xFF9D4EDD);
        break;

      case 'overlordFloat': // 심야 대요마: 천상 마왕 공중 부양 + 위압적 맥동
        liftY = -7.2 - sin(safeTime * 2.3) * 4.0;
        swayX = sin(safeTime * 1.35) * 2.7;
        final pulse = sin(safeTime * 3.8) * 0.045;
        scaleX = 1.0 + pulse;
        scaleY = 1.0 - pulse * 0.6;
        tiltRad = moveBank * 0.7 + sin(safeTime * 1.35) * 0.055;
        afterimages = 2;
        slashColor = const Color(0xFFFF0054);
        break;

      default:
        final hop = _smoothHop(safePhase * 1.5);
        liftY = -hop * 3.4;
        scaleY = 0.95 + hop * 0.09;
        scaleX = 1.0 / scaleY;
    }

    // 주기적 위협 포효·입질 연출도 스냅 없이 연속 벨 곡선으로 매끄럽게 가감!
    final snarlCycle = ((safeTime * 0.78 + uid * 0.41) % 3.8 + 3.8) % 3.8;
    final snarlCurve = snarlCycle < 0.68
        ? (0.5 - 0.5 * cos((snarlCycle / 0.68) * 2 * pi))
        : 0.0;

    // 실제 방어막·수호탑 강타 모션(attackAnimTimer: 1.0+ → 0.0)
    double forwardThrust = 0.0;
    double slashArcAlpha = 0.0;
    double attackBlend = 0.0;

    if (attackAnimTimer > 0.01) {
      final normTimer = attackAnimTimer.clamp(0.0, 1.0);
      final t = (1.0 - normTimer).clamp(0.0, 1.0);
      if (t < 0.25) {
        final w = _smoothStep(0.0, 0.25, t);
        forwardThrust = -5.2 * w;
        scaleX *= (1.0 + 0.09 * w);
        scaleY *= (1.0 - 0.07 * w);
        attackBlend = w * 0.72;
      } else if (t < 0.68) {
        final s = (t - 0.25) / 0.43;
        final punch = sin(s * pi);
        forwardThrust = 13.0 * punch;
        liftY -= 4.2 * punch;
        scaleY *= (1.0 + 0.13 * punch);
        scaleX *= (1.0 - 0.08 * punch);
        slashArcAlpha = punch.clamp(0.0, 1.0);
        attackBlend = 1.0;
      } else {
        final r = _smoothStep(0.0, 0.32, 1.0 - t);
        forwardThrust = 3.8 * r;
        slashArcAlpha = 0.32 * r;
        attackBlend = r;
      }
    } else if (dashBurstTimer > 0.02) {
      final dBlend = _smoothStep(0.0, 0.22, dashBurstTimer);
      forwardThrust = 5.8 * dBlend;
      attackBlend = 0.92 * dBlend;
      slashArcAlpha = 0.42 * dBlend;
    } else if (snarlCurve > 0.02) {
      forwardThrust = 2.4 * snarlCurve;
      attackBlend = 0.82 * snarlCurve;
    }

    // 넉백으로 밀려날 때도 연속 감쇠 회전
    if (knockbackSpeed > 25.0) {
      final kb = ((knockbackSpeed - 25.0) / 145.0).clamp(0.0, 1.0);
      tiltRad += sin(safeTime * 20.0 + uid) * 0.30 * kb;
      liftY -= 3.6 * kb;
    }

    final heightRatio = (-liftY / 14.0).clamp(0.0, 1.0);
    final shadowScale = (1.0 - heightRatio * 0.34) * scaleX.clamp(0.86, 1.18);
    final shadowAlpha = (0.45 - heightRatio * 0.19).clamp(0.16, 0.52);

    return MutantMotionSample(
      liftY: liftY,
      swayX: swayX,
      forwardThrust: forwardThrust,
      scaleX: scaleX.clamp(0.76, 1.30),
      scaleY: scaleY.clamp(0.76, 1.30),
      tiltRad: tiltRad.clamp(-0.62, 0.62),
      shadowScale: shadowScale,
      shadowAlpha: shadowAlpha,
      footImpact: footImpact.clamp(0.0, 1.0),
      useAttackSprite: attackBlend >= 0.45,
      attackBlend: attackBlend.clamp(0.0, 1.0),
      afterimageCount: afterimages,
      slashArcAlpha: slashArcAlpha.clamp(0.0, 1.0),
      slashColor: slashColor,
    );
  }
}
