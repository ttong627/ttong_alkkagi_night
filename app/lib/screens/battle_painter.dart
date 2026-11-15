import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../theme/night_theme.dart';

/// 심야 수호 전장 60프레임 모션그래픽 커스텀 페인터.
class NightBattlePainter extends CustomPainter {
  NightBattlePainter({required this.sim, required this.repaintTick})
      : super(repaint: repaintTick);

  final DefenseBattleSim sim;
  final Listenable repaintTick;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / CampaignCatalog.arenaWidth;
    final sy = size.height / CampaignCatalog.arenaHeight;
    canvas.save();
    canvas.scale(sx, sy);

    _drawNightAtmosphere(canvas);
    _drawCliffZones(canvas);
    _drawInvasionLanes(canvas);
    _drawRotatingPillars(canvas);
    _drawVillageEcosystem(canvas);
    _drawOuterQiShield(canvas);
    _drawCentralGuardianTower(canvas);
    _drawPathLaunchers(canvas);
    _drawGoldenToad(canvas);
    _drawMutants(canvas);
    _drawProjectilesAndTrails(canvas);
    _drawFxBursts(canvas);
    _drawChulduSweepWave(canvas);
    _drawDawnPurifyWave(canvas);
    _drawFloatingCallouts(canvas);

    canvas.restore();
  }

  void _drawNightAtmosphere(Canvas canvas) {
    // 심야 적월 그라데이션 안개
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xAA070B14),
          Color(0x66121B2E),
          Color(0x990B1320),
        ],
      ).createShader(
        const Rect.fromLTWH(0, 0, CampaignCatalog.arenaWidth, CampaignCatalog.arenaHeight),
      );
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, CampaignCatalog.arenaWidth, CampaignCatalog.arenaHeight),
      skyPaint,
    );

    // 상단 심야 적월(붉은 달) 광원 연출
    final moonGlow = Paint()
      ..color = const Color(0x33E63946)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(const Offset(342, 42), 28, moonGlow);
    canvas.drawCircle(
      const Offset(342, 42),
      15,
      Paint()..color = const Color(0xCCFF6B6B),
    );
  }

  void _drawCliffZones(Canvas canvas) {
    for (final cliff in sim.chapter.cliffs) {
      final c = Offset(cliff.center.x, cliff.center.y);
      final swirlPaint = Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xDD03050A), Color(0x88240046), Color(0x00000000)],
        ).createShader(Rect.fromCircle(center: c, radius: cliff.radius));
      canvas.drawCircle(c, cliff.radius, swirlPaint);

      final ringPaint = Paint()
        ..color = const Color(0x779D4EDD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(c, cliff.radius * 0.72, ringPaint);
    }
  }

  void _drawInvasionLanes(Canvas canvas) {
    final outerRoad = Paint()
      ..color = const Color(0x552B3346)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 30;
    final innerRoad = Paint()
      ..color = const Color(0x66495874)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 18;

    for (final lane in sim.chapter.lanes) {
      if (lane.length < 2) continue;
      final path = Path()..moveTo(lane.first.x, lane.first.y);
      for (int i = 1; i < lane.length; i++) {
        path.lineTo(lane[i].x, lane[i].y);
      }
      canvas.drawPath(path, outerRoad);
      canvas.drawPath(path, innerRoad);
    }
  }

  void _drawRotatingPillars(Canvas canvas) {
    for (int i = 0; i < sim.chapter.pillars.length; i++) {
      final p = sim.chapter.pillars[i];
      final angle = sim.pillarAngles[i];
      final path = Path();
      for (int k = 0; k < p.sides; k++) {
        final theta = angle + (2 * pi * k / p.sides);
        final px = p.center.x + cos(theta) * p.radius;
        final py = p.center.y + sin(theta) * p.radius;
        if (k == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()..color = const Color(0xEE2B3A55),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = NightPalette.accentGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  void _drawVillageEcosystem(Canvas canvas) {
    // 1) 좌측: 식량 창고 (92, 608)
    final granaryOk = sim.granaryHealth > 0.5;
    final gPos = const Offset(82, 606);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: gPos, width: 58, height: 34), const Radius.circular(6)),
      Paint()..color = granaryOk ? const Color(0xDD5C4033) : const Color(0xDD4A1C1C),
    );
    canvas.drawCircle(
      gPos + const Offset(0, -4),
      6,
      Paint()..color = granaryOk ? const Color(0xFFFFD166) : const Color(0xFFFF4D6D),
    );
    _paintMiniText(
      canvas,
      '식량 ${(sim.granaryHealth * 100).round()}%',
      gPos + const Offset(0, 24),
      granaryOk ? NightPalette.accentGold : NightPalette.crimsonMoon,
      10.5,
    );

    // 2) 중앙 하단: 논밭 농산물 (200, 644)
    final cropsOk = sim.cropsHealth > 0.5;
    final cPos = const Offset(200, 642);
    for (int i = -3; i <= 3; i++) {
      final sway = sin(sim.elapsedSec * 3.0 + i) * 2.5;
      final stalkX = cPos.dx + i * 11.0;
      canvas.drawLine(
        Offset(stalkX, cPos.dy + 8),
        Offset(stalkX + sway, cPos.dy - 8 * (0.4 + 0.6 * sim.cropsHealth)),
        Paint()
          ..color = cropsOk ? const Color(0xFF80ED99) : const Color(0xFF9D4EDD)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }
    _paintMiniText(
      canvas,
      '논밭 ${(sim.cropsHealth * 100).round()}%',
      cPos + const Offset(0, 18),
      cropsOk ? const Color(0xFF80ED99) : const Color(0xFFC77DFF),
      10.5,
    );

    // 3) 우측: 외양간 가축 (318, 606)
    final liveOk = sim.livestockHealth > 0.5;
    final lPos = const Offset(318, 606);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: lPos, width: 58, height: 34), const Radius.circular(6)),
      Paint()..color = liveOk ? const Color(0xDD3D5A45) : const Color(0xDD4A1C2A),
    );
    canvas.drawCircle(
      lPos,
      7,
      Paint()..color = liveOk ? const Color(0xFFF8F9FA) : const Color(0xFF9E2A2B),
    );
    _paintMiniText(
      canvas,
      '가축 ${(sim.livestockHealth * 100).round()}%',
      lPos + const Offset(0, 24),
      liveOk ? NightPalette.jadeGreen : NightPalette.crimsonMoon,
      10.5,
    );
  }

  void _drawOuterQiShield(Canvas canvas) {
    final center = Offset(CampaignCatalog.villageCenter.x, CampaignCatalog.villageCenter.y);
    if (sim.shieldHp <= 0) {
      // 파괴된 결계 흔적 점선
      canvas.drawCircle(
        center,
        CampaignCatalog.outerShieldRadius,
        Paint()
          ..color = const Color(0x44FF595E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }

    final ratio = (sim.shieldHp / sim.centralSpec.shieldMaxHp).clamp(0.0, 1.0);
    final pulse = 1.0 + sin(sim.elapsedSec * 4.0) * 0.02;
    final r = CampaignCatalog.outerShieldRadius * pulse;
    final shieldColor = ratio > 0.45 ? const Color(0xFF4CC9F0) : const Color(0xFFFF9F1C);

    canvas.drawCircle(
      center,
      r,
      Paint()..color = shieldColor.withValues(alpha: 0.11 + 0.08 * ratio),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = shieldColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }

  void _drawCentralGuardianTower(Canvas canvas) {
    final center = Offset(CampaignCatalog.villageCenter.x, CampaignCatalog.villageCenter.y);
    final r = CampaignCatalog.centralTowerRadius;

    // 10단계 생사현관 개통 시 황금 광륜 표시!
    if (sim.progress.openedMeridianStep >= 10) {
      canvas.drawCircle(
        center,
        r + 12,
        Paint()
          ..color = const Color(0x55FFD166)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }

    // 회전하는 8톱니 기어 테두리
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sim.centralGearAngle);
    final gearPaint = Paint()..color = NightPalette.borderGold;
    for (int i = 0; i < 8; i++) {
      canvas.save();
      canvas.rotate(i * pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, -r - 2), width: 8, height: 9),
          const Radius.circular(2),
        ),
        gearPaint,
      );
      canvas.restore();
    }
    canvas.restore();

    // 기명 수호탑 본체 및 장착 수호석 코어
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF1B263B));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = NightPalette.accentGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    canvas.drawCircle(
      center,
      12,
      Paint()..color = Color(sim.preset.primaryStone.colorHex),
    );
    _paintMiniText(
      canvas,
      '수호탑',
      center + const Offset(0, 34),
      NightPalette.accentGold,
      11,
    );
  }

  void _drawPathLaunchers(Canvas canvas) {
    for (final l in sim.launchers) {
      final c = Offset(l.pos.x, l.pos.y);
      final baseColor = Color(l.type.colorHex);

      // 거점 받침대
      canvas.drawCircle(c, 19, Paint()..color = const Color(0xDD141B2D));
      canvas.drawCircle(
        c,
        19,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 + l.tier * 0.5,
      );

      // 조준 회전 포신
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(l.aimAngleRad);
      final recoilOffset = -l.recoilAnim * 4.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(recoilOffset, -4.5, 20, 9),
          const Radius.circular(3),
        ),
        Paint()..color = baseColor,
      );
      canvas.restore();

      canvas.drawCircle(c, 8, Paint()..color = baseColor.withValues(alpha: 0.9));
      _paintMiniText(
        canvas,
        '${l.tier}형',
        c + const Offset(0, 24),
        NightPalette.accentGold,
        10.5,
      );
    }
  }

  void _drawGoldenToad(Canvas canvas) {
    final toad = sim.goldenToad;
    if (toad == null || !toad.alive) return;
    final c = Offset(toad.pos.x, toad.pos.y);
    canvas.drawCircle(
      c,
      16,
      Paint()
        ..color = const Color(0x66FFD166)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(c, 12, Paint()..color = const Color(0xFFFFD166));
    _paintMiniText(canvas, '황금두꺼비', c + const Offset(0, -18), NightPalette.accentGold, 10);
  }

  void _drawMutants(Canvas canvas) {
    for (final m in sim.mutants) {
      final c = Offset(m.pos.x, m.pos.y);
      final r = m.kind.radius;

      // 독안개 오라
      if (m.kind.poisonAura) {
        canvas.drawCircle(
          c,
          r + 9,
          Paint()..color = const Color(0x4452B788),
        );
      }

      // 빙결 이펙트
      if (m.freezeTimer > 0) {
        canvas.drawCircle(
          c,
          r + 5,
          Paint()..color = const Color(0x8890E0EF),
        );
      }

      // 몸체
      canvas.drawCircle(c, r, Paint()..color = Color(m.kind.colorHex));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = m.kind.isBoss ? NightPalette.accentGold : const Color(0xCCFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = m.kind.isBoss ? 2.8 : 1.3,
      );

      // 뼈방패 야차 전면 방패 호 표시
      if (m.kind.frontShieldReduction > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r + 3),
          0.25,
          pi - 0.5,
          false,
          Paint()
            ..color = const Color(0xFFFFD166)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2,
        );
      }

      // 익살스러운 눈 표정
      final eyePaint = Paint()..color = Colors.white;
      canvas.drawCircle(c + Offset(-r * 0.32, -r * 0.15), 2.5, eyePaint);
      canvas.drawCircle(c + Offset(r * 0.32, -r * 0.15), 2.5, eyePaint);

      // 체력 막대
      final hpRatio = (m.hp / m.maxHp).clamp(0.0, 1.0);
      final barW = r * 2.0;
      final barRect = Rect.fromCenter(center: c + Offset(0, -r - 7), width: barW, height: 4.5);
      canvas.drawRect(barRect, Paint()..color = const Color(0xAA000000));
      canvas.drawRect(
        Rect.fromLTWH(barRect.left, barRect.top, barW * hpRatio, barRect.height),
        Paint()..color = m.kind.isBoss ? const Color(0xFFFF0054) : const Color(0xFF80ED99),
      );

      if (m.kind.isBoss) {
        _paintMiniText(
          canvas,
          m.displayName,
          c + Offset(0, -r - 17),
          NightPalette.accentGold,
          11,
        );
      }
    }
  }

  void _drawProjectilesAndTrails(Canvas canvas) {
    for (final p in sim.projectiles) {
      final col = Color(p.colorHex);
      if (p.trail.length >= 2) {
        final path = Path()..moveTo(p.trail.first.x, p.trail.first.y);
        for (int i = 1; i < p.trail.length; i++) {
          path.lineTo(p.trail[i].x, p.trail[i].y);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = col.withValues(alpha: 0.42)
            ..style = PaintingStyle.stroke
            ..strokeWidth = p.radius * 0.9
            ..strokeCap = StrokeCap.round,
        );
      }

      final c = Offset(p.pos.x, p.pos.y);
      if (p.isGiantCritSerendipity) {
        canvas.drawCircle(
          c,
          p.radius + 5,
          Paint()..color = const Color(0x66FFD166),
        );
      }
      canvas.drawCircle(c, p.radius, Paint()..color = col);
      canvas.drawCircle(
        c + Offset(-p.radius * 0.28, -p.radius * 0.28),
        p.radius * 0.32,
        Paint()..color = Colors.white.withValues(alpha: 0.65),
      );
    }
  }

  void _drawFxBursts(Canvas canvas) {
    for (final fx in sim.bursts) {
      final prog = fx.progress;
      final alpha = (1.0 - prog).clamp(0.0, 1.0);
      final c = Offset(fx.pos.x, fx.pos.y);
      final col = Color(fx.colorHex).withValues(alpha: alpha);

      if (fx.isTriangleShatter) {
        // 3단 연쇄 박살 세모 파편 8개 비산 모션그래픽!
        for (int k = 0; k < 8; k++) {
          final a = k * pi / 4 + prog * 0.8;
          final d = fx.maxRadius * prog;
          final tc = c + Offset(cos(a) * d, sin(a) * d);
          final tri = Path()
            ..moveTo(tc.dx, tc.dy - 5)
            ..lineTo(tc.dx - 4.5, tc.dy + 4)
            ..lineTo(tc.dx + 4.5, tc.dy + 4)
            ..close();
          canvas.drawPath(tri, Paint()..color = col);
        }
      } else {
        canvas.drawCircle(
          c,
          fx.maxRadius * prog,
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
      }
    }
  }

  void _drawChulduSweepWave(Canvas canvas) {
    if (sim.chulduSweepAnimTimer <= 0) return;
    final prog = (1.0 - sim.chulduSweepAnimTimer / 1.35).clamp(0.0, 1.0);
    final sweepY = CampaignCatalog.arenaHeight * (1.0 - prog);

    final waveRect = Rect.fromLTWH(0, sweepY - 45, CampaignCatalog.arenaWidth, 90);
    canvas.drawRect(
      waveRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x00FFD166), Color(0xCCFFD166), Color(0x00FFFFFF)],
        ).createShader(waveRect),
    );

    // 돌격하는 황금 수호 알 편대 실루엣 7기
    for (int i = 0; i < 7; i++) {
      final sx = 40.0 + i * 53.0;
      canvas.drawCircle(
        Offset(sx, sweepY),
        12,
        Paint()..color = const Color(0xFFFFD166),
      );
    }
  }

  void _drawDawnPurifyWave(Canvas canvas) {
    if (sim.dawnPurifyAnimTimer <= 0) return;
    final prog = (1.0 - sim.dawnPurifyAnimTimer / 1.5).clamp(0.0, 1.0);
    final center = Offset(CampaignCatalog.villageCenter.x, CampaignCatalog.villageCenter.y);
    canvas.drawCircle(
      center,
      prog * 680.0,
      Paint()
        ..color = const Color(0x99FFD166).withValues(alpha: (1.0 - prog) * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0,
    );
  }

  void _drawFloatingCallouts(Canvas canvas) {
    for (final fc in sim.callouts) {
      _paintMiniText(
        canvas,
        fc.text,
        Offset(fc.pos.x.clamp(70.0, 330.0), fc.pos.y.clamp(35.0, 630.0)),
        Color(fc.colorHex),
        fc.isBigBanner ? 14.0 : 11.5,
        withBg: fc.isBigBanner,
      );
    }
  }

  void _paintMiniText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize, {
    bool withBg = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'DoHyeon',
          fontFamilyFallback: const ['NotoKRFallback'],
          fontSize: fontSize,
          color: color,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 360);

    final offset = center - Offset(tp.width / 2, tp.height / 2);
    if (withBg) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx - 8, offset.dy - 4, tp.width + 16, tp.height + 8),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xDD0B0F19),
      );
    }
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant NightBattlePainter oldDelegate) => true;
}
