import 'dart:math';
import 'package:flutter/material.dart';

/// 영상 시제품(`render_mutant_motion_video.py`)에서 설계·검증된 12종 돌연변이·우두머리 생체역학 모션 결과값.
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

  /// 코덱스 공격 원화(`mut_*_atk.webp`) 전환 여부.
  final bool useAttackSprite;

  /// 기본 행군 원화 ↔ 공격 원화 전환 가중치(0.0 ~ 1.0).
  final double attackBlend;

  /// 초고속 기습형 잔상 개수(0 ~ 3).
  final int afterimageCount;

  /// 전방 발톱·철퇴·검기 궤적 투명도(0.0 ~ 1.0).
  final double slashArcAlpha;

  /// 전방 타격 궤적 색상.
  final Color slashColor;
}

/// 영상으로 먼저 합성해 자연스러움을 검증한 보행·돌진·강타 수식을 실시간 60프레임 캔버스로 1:1 변환하는 엔진.
class MutantMotionEngine {
  const MutantMotionEngine._();

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

    // 빙결 상태에서는 호흡을 멈추고 살짝 얼어붙은 자세 유지
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

    // 진행 방향 좌우 성분에 따른 자연스러운 전경사(달리는 쪽으로 몸을 숙임)
    final moveBank = cos(headingRad) * 0.09;

    switch (gaitId) {
      case 'scamper': // 심야 독쥐: 재빠른 종종걸음 + 좌우 갸우뚱
        final s = sin(safePhase * 2.1);
        final hop = s.abs();
        liftY = -hop * 3.8;
        swayX = sin(safePhase * 1.05 + uid) * 2.4;
        scaleY = 0.92 + hop * 0.14;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank + sin(safePhase * 1.05) * 0.13;
        footImpact = (1.0 - hop).clamp(0.0, 1.0);
        slashColor = const Color(0xFFC77DFF);
        break;

      case 'gallop': // 역병 들개: 네 발 짐승 탄력 도약 질주
        final g = sin(safePhase * 1.75);
        final leap = max(0.0, g);
        final land = max(0.0, -g);
        liftY = -leap * 7.2;
        swayX = cos(safePhase * 0.88 + uid) * 2.0;
        scaleY = 1.0 + leap * 0.14 - land * 0.11;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.35 + g * 0.11;
        footImpact = land > 0.72 ? ((land - 0.72) / 0.28) : 0.0;
        afterimages = dashBurstTimer > 0 ? 2 : 0;
        slashColor = const Color(0xFF9D4EDD);
        break;

      case 'heavyStomp': // 철피 멧돼지: 묵직한 어깨 들썩임 + 저돌적 발구름
        final w = sin(safePhase * 1.15);
        final stomp = pow(w.abs(), 2.2).toDouble();
        liftY = -(1.0 - stomp) * 3.0;
        swayX = w * 2.2;
        scaleX = 0.96 + stomp * 0.11;
        scaleY = 1.0 / scaleX;
        tiltRad = moveBank * 0.8 + w * 0.10;
        footImpact = stomp > 0.82 ? ((stomp - 0.82) / 0.18) : 0.0;
        slashColor = const Color(0xFFFF9F1C);
        break;

      case 'shieldMarch': // 뼈방패 야차: 낮은 무게중심 방패 전진 보법
        final m = sin(safePhase * 1.25);
        final step = m.abs();
        liftY = -step * 2.6;
        swayX = m * 1.4;
        scaleX = 1.04 - step * 0.06;
        scaleY = 1.0 / scaleX;
        tiltRad = moveBank * 0.6 + m * 0.06;
        footImpact = (1.0 - step) > 0.78 ? 0.7 : 0.0;
        slashColor = const Color(0xFFFFD166);
        break;

      case 'toxicHop': // 독안개 두꺼비: 웅크림 → 포물선 큰 점프 → 철퍼덕 착지!
        final cyc = (safePhase * 0.42) % (2 * pi);
        final norm = cyc / (2 * pi); // 0.0 ~ 1.0
        if (norm < 0.24) {
          // 도약 직전 넓적하게 웅크림
          final crouch = sin((norm / 0.24) * pi);
          liftY = 0.0;
          scaleX = 1.0 + crouch * 0.18;
          scaleY = 1.0 / scaleX;
          footImpact = 0.0;
        } else if (norm < 0.76) {
          // 공중 포물선 점프
          final airT = (norm - 0.24) / 0.52;
          final arc = sin(airT * pi);
          liftY = -arc * 11.5;
          scaleY = 1.0 + arc * 0.16;
          scaleX = 1.0 / scaleY;
          tiltRad = moveBank + cos(airT * pi) * 0.08;
        } else {
          // 착지 독구름 출렁임
          final splat = sin(((norm - 0.76) / 0.24) * pi);
          liftY = 0.0;
          scaleX = 1.0 + splat * 0.15;
          scaleY = 1.0 / scaleX;
          footImpact = splat;
        }
        slashColor = const Color(0xFFC77DFF);
        break;

      case 'carapaceScuttle': // 혈독 분열충: 촘촘한 다리 종종걸음 + 붉은 독핵 맥동
        final sc = sin(safePhase * 2.4);
        final pulse = sin(safeTime * 8.5 + uid) * 0.055;
        liftY = -sc.abs() * 2.4;
        swayX = cos(safePhase * 1.2) * 2.1;
        scaleX = 1.0 + pulse + sc.abs() * 0.04;
        scaleY = 1.0 + pulse - sc.abs() * 0.04;
        tiltRad = moveBank + sc * 0.09;
        footImpact = sc.abs() < 0.2 ? 0.5 : 0.0;
        slashColor = const Color(0xFFFF0054);
        break;

      case 'shadowDash': // 혈영 질풍귀(속도형 중간보스): 초고속 잔상 질주 + 쌍갈퀴 베기
        final d = sin(safePhase * 2.2);
        liftY = -3.5 - d.abs() * 4.5;
        swayX = sin(safePhase * 1.1 + uid) * (dashBurstTimer > 0 ? 4.5 : 2.6);
        scaleY = 1.05 + d.abs() * 0.08;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.6 + d * 0.12;
        afterimages = dashBurstTimer > 0 ? 3 : 2;
        footImpact = d.abs() < 0.22 ? 0.75 : 0.0;
        slashColor = const Color(0xFFE0AAFF);
        break;

      case 'colossusTread': // 현철 중갑거수(맷집형 중간보스): 대지를 울리는 거인 중보행
        final tr = sin(safePhase * 0.78);
        final heavyLand = pow(1.0 - tr.abs(), 3.0).toDouble();
        liftY = -tr.abs() * 4.2;
        swayX = tr * 3.0;
        scaleX = 1.0 + heavyLand * 0.12;
        scaleY = 1.0 / scaleX;
        tiltRad = tr * 0.08;
        footImpact = heavyLand > 0.65 ? heavyLand : 0.0;
        slashColor = const Color(0xFFFFD166);
        break;

      case 'breakerSlam': // 적염 파성귀(공격력형 중간보스): 파성 철퇴 어깨 스윙 행군
        final br = sin(safePhase * 1.08);
        liftY = -br.abs() * 4.6;
        swayX = br * 2.8;
        scaleY = 0.96 + br.abs() * 0.10;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank + br * 0.14;
        footImpact = br.abs() < 0.22 ? 0.85 : 0.0;
        slashColor = const Color(0xFFFF4D00);
        break;

      case 'dualCleaverRush': // 약탈 선봉 흑풍: 쌍식칼 호기로운 돌격 보법
        final hk = sin(safePhase * 1.45);
        liftY = -hk.abs() * 5.0;
        swayX = hk * 2.5;
        scaleY = 0.95 + hk.abs() * 0.11;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.2 + hk * 0.12;
        footImpact = hk.abs() < 0.25 ? 0.8 : 0.0;
        slashColor = const Color(0xFFE63946);
        break;

      case 'swordGlide': // 독기에 물든 묵현: 무협 경공 활공 + 흑화 검기 잔상
        liftY = -5.5 - sin(safeTime * 3.4 + uid) * 3.2;
        swayX = sin(safeTime * 2.2 + uid) * 3.6;
        scaleY = 1.02 + sin(safeTime * 3.4) * 0.04;
        scaleX = 1.0 / scaleY;
        tiltRad = moveBank * 1.3 + cos(safeTime * 2.2) * 0.08;
        afterimages = 2;
        slashColor = const Color(0xFF9D4EDD);
        break;

      case 'overlordFloat': // 심야 대요마: 천상 마왕 공중 부양 + 위압적 맥동
        liftY = -7.5 - sin(safeTime * 2.5) * 4.2;
        swayX = sin(safeTime * 1.4) * 2.8;
        final pulse = sin(safeTime * 4.2) * 0.05;
        scaleX = 1.0 + pulse;
        scaleY = 1.0 - pulse * 0.6;
        tiltRad = sin(safeTime * 1.4) * 0.06;
        afterimages = 2;
        slashColor = const Color(0xFFFF0054);
        break;

      default:
        final def = sin(safePhase * 1.6).abs();
        liftY = -def * 3.5;
        scaleY = 0.95 + def * 0.10;
        scaleX = 1.0 / scaleY;
    }

    // 주기적 위협 포효·입질 연출(길목 이동 중에도 살아 있는 괴수처럼 간헐적 공격 포즈 표출)
    final periodicSnarl = ((safeTime * 0.85 + uid * 0.37) % 3.6) < 0.42;

    // 실제 방어막·수호탑 강타 모션(attackAnimTimer: 1.0 → 0.0)
    double forwardThrust = 0.0;
    double slashArcAlpha = 0.0;
    double attackBlend = 0.0;

    if (attackAnimTimer > 0.01) {
      final t = (1.0 - attackAnimTimer).clamp(0.0, 1.0);
      if (t < 0.25) {
        // 1단계: 뒤로 몸을 젖히며 기를 모으는 예비 동작(Windup)
        final w = t / 0.25;
        forwardThrust = -5.5 * w;
        scaleX *= (1.0 + 0.10 * w);
        scaleY *= (1.0 - 0.08 * w);
        attackBlend = w * 0.7;
      } else if (t < 0.65) {
        // 2단계: 전방 덮치기 타격(Strike Lunge) + 발톱/무기 검기 호
        final s = (t - 0.25) / 0.40;
        final punch = sin(s * pi);
        forwardThrust = 13.5 * punch;
        liftY -= 4.5 * punch;
        scaleY *= (1.0 + 0.14 * punch);
        scaleX *= (1.0 - 0.09 * punch);
        slashArcAlpha = punch.clamp(0.0, 1.0);
        attackBlend = 1.0;
      } else {
        // 3단계: 타격 후 착지 회수(Follow-through)
        final r = (1.0 - t) / 0.35;
        forwardThrust = 4.0 * r;
        slashArcAlpha = 0.35 * r;
        attackBlend = r;
      }
    } else if (dashBurstTimer > 0.05) {
      forwardThrust = 6.0;
      attackBlend = 0.92;
      slashArcAlpha = 0.45;
    } else if (periodicSnarl) {
      forwardThrust = 2.5;
      attackBlend = 0.85;
    }

    // 넉백으로 크게 밀려날 때는 몸이 뒤로 휘청이며 회전
    if (knockbackSpeed > 35.0) {
      final kb = ((knockbackSpeed - 35.0) / 140.0).clamp(0.0, 1.0);
      tiltRad += sin(safeTime * 24.0 + uid) * 0.35 * kb;
      liftY -= 4.0 * kb;
    }

    final heightRatio = (-liftY / 14.0).clamp(0.0, 1.0);
    final shadowScale = (1.0 - heightRatio * 0.36) * scaleX.clamp(0.85, 1.20);
    final shadowAlpha = (0.46 - heightRatio * 0.20).clamp(0.16, 0.52);

    return MutantMotionSample(
      liftY: liftY,
      swayX: swayX,
      forwardThrust: forwardThrust,
      scaleX: scaleX.clamp(0.76, 1.32),
      scaleY: scaleY.clamp(0.76, 1.32),
      tiltRad: tiltRad.clamp(-0.65, 0.65),
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
