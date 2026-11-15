import 'dart:math';
import 'dart:ui' as ui;

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../theme/night_theme.dart';
import '../ui/mutant_motion_engine.dart';
import '../ui/night_art_registry.dart';

/// 심야 수호 전장 60프레임 코덱스 원화 + 물리 모션그래픽 통합 페인터.
class NightBattlePainter extends CustomPainter {
  NightBattlePainter({
    required this.sim,
    required this.repaintTick,
    NightBattleSprites? sprites,
  })  : sprites = sprites ?? NightBattleSprites.instance,
        super(repaint: repaintTick);

  final DefenseBattleSim sim;
  final Listenable repaintTick;
  final NightBattleSprites sprites;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / CampaignCatalog.arenaWidth;
    final sy = size.height / CampaignCatalog.arenaHeight;
    canvas.save();
    canvas.scale(sx, sy);

    // 우두머리 등장·파성 강타 시 전장 진동 연출
    if (sim.screenShakeTimer > 0) {
      final amp = (sim.screenShakeIntensity * 3.4).clamp(0.0, 5.5);
      final dx = sin(sim.elapsedSec * 52.0) * amp;
      final dy = cos(sim.elapsedSec * 41.0) * amp * 0.72;
      canvas.translate(dx, dy);
    }

    _drawFloorAndNightAtmosphere(canvas);
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

  void _drawSpriteCentered(
    Canvas canvas,
    ui.Image image,
    Offset center, {
    required double width,
    required double height,
    double rotationRad = 0.0,
    double opacity = 1.0,
    Color? tintColor,
    BlendMode tintBlendMode = BlendMode.srcATop,
  }) {
    final alpha = opacity.clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (rotationRad != 0.0) {
      canvas.rotate(rotationRad);
    }

    final paint = Paint()..filterQuality = FilterQuality.low;
    if (tintColor != null) {
      paint.colorFilter = ColorFilter.mode(tintColor, tintBlendMode);
    } else if (alpha < 0.999) {
      paint.color = Color.fromRGBO(255, 255, 255, alpha);
    }

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  void _drawFloorAndNightAtmosphere(Canvas canvas) {
    const arenaRect = Rect.fromLTWH(
      0,
      0,
      CampaignCatalog.arenaWidth,
      CampaignCatalog.arenaHeight,
    );

    // 장별 심야 바닥 텍스처 (floor_night_ch1~10.webp) 은은하게 합성
    final floorImg = sprites.floorOf(sim.chapter);
    if (floorImg != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        floorImg.width.toDouble(),
        floorImg.height.toDouble(),
      );
      canvas.drawImageRect(
        floorImg,
        src,
        arenaRect,
        Paint()
          ..filterQuality = FilterQuality.low
          ..color = const Color.fromRGBO(255, 255, 255, 0.46),
      );
    }

    // 심야 적월 그라데이션 안개
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x9E070B14),
          Color(0x58121B2E),
          Color(0x8E0B1320),
        ],
      ).createShader(arenaRect);
    canvas.drawRect(arenaRect, skyPaint);

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
        ..shader = const RadialGradient(
          colors: [Color(0xDD03050A), Color(0x88240046), Color(0x00000000)],
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
      ..color = const Color(0x661C2538)
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

    for (int laneIdx = 0; laneIdx < sim.chapter.lanes.length; laneIdx++) {
      final lane = sim.chapter.lanes[laneIdx];
      if (lane.length < 2) continue;
      final path = Path()..moveTo(lane.first.x, lane.first.y);
      for (int i = 1; i < lane.length; i++) {
        path.lineTo(lane[i].x, lane[i].y);
      }
      canvas.drawPath(path, outerRoad);
      canvas.drawPath(path, innerRoad);

      final energy = laneIdx < sim.lanePortalEnergy.length
          ? sim.lanePortalEnergy[laneIdx].clamp(0.0, 1.0)
          : 0.35;

      // 길목 침공 방향 흐름 화살표 (독기 활성화 시 더욱 선명하게 맥동)
      final arrowAlpha = (0.16 + energy * 0.34).clamp(0.12, 0.52);
      final arrowPaint = Paint()
        ..color = const Color(0xFFFF4D6D).withValues(alpha: arrowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.0;

      final shift = (sim.elapsedSec * 1.35) % 1.0;
      for (int seg = 0; seg < lane.length - 1; seg++) {
        final a = lane[seg];
        final b = lane[seg + 1];
        final segVec = b - a;
        final segLen = segVec.length;
        if (segLen < 28) continue;
        final dir = segVec.normalized;
        final perp = Vec2(-dir.y, dir.x);
        final pT = (0.25 + shift * 0.55).clamp(0.15, 0.85);
        final tip = a + segVec * pT;
        final leftWing = tip - dir * 6.5 + perp * 5.0;
        final rightWing = tip - dir * 6.5 - perp * 5.0;
        final chev = Path()
          ..moveTo(leftWing.x, leftWing.y)
          ..lineTo(tip.x, tip.y)
          ..lineTo(rightWing.x, rightWing.y);
        canvas.drawPath(chev, arrowPaint);
      }

      // 상단 침공 입구: 심야 독기 침공 균열문(fx_breach_gate.webp) 소용돌이 연출
      final gateCenter = Offset(
        lane.first.x.clamp(26.0, CampaignCatalog.arenaWidth - 26.0),
        lane.first.y.clamp(22.0, 96.0),
      );
      final gateRadius = 21.0 + energy * 10.0 + sin(sim.elapsedSec * 4.5 + laneIdx) * 2.0;

      canvas.drawCircle(
        gateCenter,
        gateRadius * 1.15,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xCC9D4EDD).withValues(alpha: (0.28 + energy * 0.42).clamp(0.0, 0.82)),
              const Color(0x88E63946).withValues(alpha: (0.18 + energy * 0.30).clamp(0.0, 0.60)),
              const Color(0x00000000),
            ],
          ).createShader(Rect.fromCircle(center: gateCenter, radius: gateRadius * 1.15)),
      );

      final gateImg = sprites.fxBreachGate;
      if (gateImg != null) {
        _drawSpriteCentered(
          canvas,
          gateImg,
          gateCenter,
          width: gateRadius * 2.35,
          height: gateRadius * 2.35,
          rotationRad: sim.elapsedSec * (0.85 + energy * 0.9) * (laneIdx.isEven ? 1.0 : -1.0),
          opacity: (0.62 + energy * 0.38).clamp(0.0, 1.0),
        );
      } else {
        canvas.drawCircle(
          gateCenter,
          gateRadius * 0.72,
          Paint()
            ..color = const Color(0xFFC77DFF).withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
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
      canvas.drawCircle(
        Offset(p.center.x, p.center.y),
        p.radius * 0.36,
        Paint()..color = const Color(0x884CC9F0),
      );
    }
  }

  void _drawVillageEcosystem(Canvas canvas) {
    // 1) 좌측: 식량 창고 (village_granary.webp)
    final granaryOk = sim.granaryHealth > 0.5;
    const gPos = Offset(82, 604);
    final granaryImg = sprites.granary;
    if (granaryImg != null) {
      canvas.drawCircle(
        gPos,
        24,
        Paint()
          ..color = granaryOk
              ? const Color(0x33FFD166)
              : const Color(0x55E63946),
      );
      _drawSpriteCentered(
        canvas,
        granaryImg,
        gPos,
        width: 54,
        height: 50,
        tintColor: granaryOk ? null : const Color(0x55E63946),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: gPos, width: 58, height: 34),
          const Radius.circular(6),
        ),
        Paint()..color = granaryOk ? const Color(0xDD5C4033) : const Color(0xDD4A1C1C),
      );
      canvas.drawCircle(
        gPos + const Offset(0, -4),
        6,
        Paint()..color = granaryOk ? const Color(0xFFFFD166) : const Color(0xFFFF4D6D),
      );
    }
    _paintMiniText(
      canvas,
      '식량 ${(sim.granaryHealth * 100).round()}%',
      gPos + const Offset(0, 27),
      granaryOk ? NightPalette.accentGold : NightPalette.crimsonMoon,
      10.5,
    );

    // 2) 중앙 하단: 논밭 농산물 (village_crops.webp)
    final cropsOk = sim.cropsHealth > 0.5;
    const cPos = Offset(200, 640);
    final cropsImg = sprites.crops;
    if (cropsImg != null) {
      final swayRad = sin(sim.elapsedSec * 2.5) * 0.04;
      _drawSpriteCentered(
        canvas,
        cropsImg,
        cPos + const Offset(0, -2),
        width: 60,
        height: 40,
        rotationRad: swayRad,
        tintColor: cropsOk ? null : const Color(0x559D4EDD),
      );
    } else {
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
    }
    _paintMiniText(
      canvas,
      '논밭 ${(sim.cropsHealth * 100).round()}%',
      cPos + const Offset(0, 20),
      cropsOk ? const Color(0xFF80ED99) : const Color(0xFFC77DFF),
      10.5,
    );

    // 3) 우측: 외양간 가축 (village_livestock.webp)
    final liveOk = sim.livestockHealth > 0.5;
    const lPos = Offset(318, 604);
    final livestockImg = sprites.livestock;
    if (livestockImg != null) {
      canvas.drawCircle(
        lPos,
        24,
        Paint()
          ..color = liveOk
              ? const Color(0x3372EFDD)
              : const Color(0x55E63946),
      );
      _drawSpriteCentered(
        canvas,
        livestockImg,
        lPos,
        width: 54,
        height: 50,
        tintColor: liveOk ? null : const Color(0x55E63946),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: lPos, width: 58, height: 34),
          const Radius.circular(6),
        ),
        Paint()..color = liveOk ? const Color(0xDD3D5A45) : const Color(0xDD4A1C2A),
      );
      canvas.drawCircle(
        lPos,
        7,
        Paint()..color = liveOk ? const Color(0xFFF8F9FA) : const Color(0xFF9E2A2B),
      );
    }
    _paintMiniText(
      canvas,
      '가축 ${(sim.livestockHealth * 100).round()}%',
      lPos + const Offset(0, 27),
      liveOk ? NightPalette.jadeGreen : NightPalette.crimsonMoon,
      10.5,
    );
  }

  void _drawOuterQiShield(Canvas canvas) {
    final center = Offset(
      CampaignCatalog.villageCenter.x,
      CampaignCatalog.villageCenter.y,
    );
    if (sim.shieldHp <= 0) {
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

    final barrierSprite = sprites.fxBarrier;
    if (barrierSprite != null) {
      _drawSpriteCentered(
        canvas,
        barrierSprite,
        center,
        width: r * 2.06,
        height: r * 2.06,
        rotationRad: sim.elapsedSec * 0.28,
        opacity: 0.14 + 0.16 * ratio,
      );
    }

    canvas.drawCircle(
      center,
      r,
      Paint()..color = shieldColor.withValues(alpha: 0.10 + 0.08 * ratio),
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
    final center = Offset(
      CampaignCatalog.villageCenter.x,
      CampaignCatalog.villageCenter.y,
    );
    const r = CampaignCatalog.centralTowerRadius;

    // 내공 1칸 이상 충전 시 단전 기운(fx_qi.webp) 소용돌이 광륜
    if (sim.qiBars >= 1.0 && sprites.fxQi != null) {
      _drawSpriteCentered(
        canvas,
        sprites.fxQi!,
        center,
        width: r * 2.95,
        height: r * 2.95,
        rotationRad: -sim.elapsedSec * 1.15,
        opacity: (0.20 + 0.14 * sim.qiBars).clamp(0.0, 0.65),
      );
    }

    // 10단계 생사현관 개통 시 황금 광륜 표시
    if (sim.progress.openedMeridianStep >= 10) {
      canvas.drawCircle(
        center,
        r + 13,
        Paint()
          ..color = const Color(0x66FFD166)
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
          Rect.fromCenter(center: const Offset(0, -r - 3), width: 8, height: 9),
          const Radius.circular(2),
        ),
        gearPaint,
      );
      canvas.restore();
    }
    canvas.restore();

    final towerImg = sprites.towerGuardian;
    if (towerImg != null) {
      _drawSpriteCentered(
        canvas,
        towerImg,
        center + const Offset(0, -2),
        width: 62,
        height: 62,
      );
      final coreStoneImg = sprites.stoneOf(sim.preset.primaryStone);
      if (coreStoneImg != null) {
        _drawSpriteCentered(
          canvas,
          coreStoneImg,
          center + const Offset(0, 8),
          width: 18,
          height: 18,
        );
      }
    } else {
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
    }

    // 동행 수호 영수(pet_*.webp) 호위 연출
    final beastImg = sprites.beastOf(sim.preset.equippedBeast);
    if (beastImg != null &&
        (sim.progress.beastLevels[sim.preset.equippedBeast] ?? 0) > 0) {
      final hoverY = sin(sim.elapsedSec * 3.4) * 2.8;
      _drawSpriteCentered(
        canvas,
        beastImg,
        center + Offset(-40, -14 + hoverY),
        width: 30,
        height: 30,
      );
    }

    _paintMiniText(
      canvas,
      '수호탑',
      center + const Offset(0, 35),
      NightPalette.accentGold,
      11,
    );
  }

  void _drawPathLaunchers(Canvas canvas) {
    for (final l in sim.launchers) {
      final c = Offset(l.pos.x, l.pos.y);
      final baseColor = Color(l.type.colorHex);

      // 내공 증폭기 주변 기운 공명 연출
      if (l.type == LauncherType.qiAmplifier && sprites.fxQi != null) {
        _drawSpriteCentered(
          canvas,
          sprites.fxQi!,
          c,
          width: 50,
          height: 50,
          rotationRad: sim.elapsedSec * 0.9,
          opacity: 0.28,
        );
      }

      // 거점 받침대 및 등급 테두리
      canvas.drawCircle(c, 20, Paint()..color = const Color(0xCC141B2D));
      canvas.drawCircle(
        c,
        20,
        Paint()
          ..color = l.tier >= 4 ? NightPalette.accentGold : baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + l.tier * 0.5,
      );

      final launcherImg = sprites.launcherOf(l.type);
      if (launcherImg != null) {
        // 조준 방향 화살촉 표시
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(l.aimAngleRad);
        final aimTip = Path()
          ..moveTo(24, 0)
          ..lineTo(18, -4)
          ..lineTo(18, 4)
          ..close();
        canvas.drawPath(aimTip, Paint()..color = baseColor);
        canvas.restore();

        // 발사 반동과 함께 원화 스프라이트 정방향 표시
        final recoilShift = Offset(
          cos(l.aimAngleRad) * (-l.recoilAnim * 4.2),
          sin(l.aimAngleRad) * (-l.recoilAnim * 4.2),
        );
        final scale = 1.0 + l.recoilAnim * 0.10;
        _drawSpriteCentered(
          canvas,
          launcherImg,
          c + recoilShift,
          width: 42 * scale,
          height: 42 * scale,
        );
      } else {
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
      }

      _paintMiniText(
        canvas,
        '${l.tier}형',
        c + const Offset(0, 25),
        NightPalette.accentGold,
        10.5,
      );
    }
  }

  void _drawGoldenToad(Canvas canvas) {
    final toad = sim.goldenToad;
    if (toad == null || !toad.alive) return;
    final c = Offset(toad.pos.x, toad.pos.y);

    if (sprites.fxLucky != null) {
      _drawSpriteCentered(
        canvas,
        sprites.fxLucky!,
        c,
        width: 44,
        height: 44,
        rotationRad: sim.elapsedSec * 2.0,
        opacity: 0.75,
      );
    } else {
      canvas.drawCircle(
        c,
        16,
        Paint()
          ..color = const Color(0x66FFD166)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    final toadImg = sprites.mutantOf(MutantKind.plagueToad);
    if (toadImg != null) {
      _drawSpriteCentered(
        canvas,
        toadImg,
        c,
        width: 34,
        height: 34,
        tintColor: const Color(0x88FFD166),
      );
    } else {
      canvas.drawCircle(c, 12, Paint()..color = const Color(0xFFFFD166));
    }
    _paintMiniText(
      canvas,
      '황금두꺼비',
      c + const Offset(0, -20),
      NightPalette.accentGold,
      10,
    );
  }

  void _drawMutantFootPivotedSprite(
    Canvas canvas,
    ui.Image image,
    Offset center, {
    required double width,
    required double height,
    required double scaleX,
    required double scaleY,
    required double tiltRad,
    double opacity = 1.0,
    Color? tintColor,
    BlendMode tintBlendMode = BlendMode.srcATop,
  }) {
    final alpha = opacity.clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    // 발바닥 접지점을 축으로 부피 보존 신축(Squash & Stretch) 및 보행 기울기를 적용
    final footAnchorY = height * 0.42;
    canvas.save();
    canvas.translate(center.dx, center.dy + footAnchorY);
    if (tiltRad != 0.0) {
      canvas.rotate(tiltRad);
    }
    canvas.scale(scaleX, scaleY);

    final paint = Paint()..filterQuality = FilterQuality.low;
    if (tintColor != null) {
      paint.colorFilter = ColorFilter.mode(tintColor, tintBlendMode);
    } else if (alpha < 0.999) {
      paint.color = Color.fromRGBO(255, 255, 255, alpha);
    }

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: Offset(0, -footAnchorY),
      width: width,
      height: height,
    );
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  void _drawMutants(Canvas canvas) {
    if (sim.mutants.isEmpty) return;

    // 원근 깊이감(Y좌표 오름차순)으로 정렬하여 무리 침공 입체감 확보
    final ordered = List<ActiveMutant>.of(sim.mutants)
      ..sort((a, b) => a.pos.y.compareTo(b.pos.y));

    for (final m in ordered) {
      final c = Offset(m.pos.x, m.pos.y);
      final r = m.kind.radius;

      final motion = MutantMotionEngine.sample(
        gaitId: m.kind.gaitId,
        animPhase: m.animPhase,
        elapsedSec: sim.elapsedSec,
        uid: m.uid,
        headingRad: m.headingRad,
        attackAnimTimer: m.attackAnimTimer,
        dashBurstTimer: m.dashBurstTimer,
        freezeTimer: m.freezeTimer,
        knockbackSpeed: m.knockbackVel.length,
      );

      // 균열문에서 솟구쳐 나오는 소환 연출 배율
      final emergeScale = m.spawnPortalTimer > 0
          ? (1.0 - (m.spawnPortalTimer / 0.45) * 0.45).clamp(0.48, 1.0)
          : 1.0;

      final headingDir = Offset(cos(m.headingRad), sin(m.headingRad));
      final perpDir = Offset(-headingDir.dy, headingDir.dx);
      final groundCenter = c + perpDir * (motion.swayX * 0.55);
      final bodyCenter = c +
          perpDir * motion.swayX +
          headingDir * motion.forwardThrust +
          Offset(0, motion.liftY);

      // 1) 발밑 타원 접지 그림자 (점프 시 작아지고 착지 시 넓어짐)
      final shadowW = r * 2.15 * motion.shadowScale * emergeScale;
      final shadowH = r * 0.82 * motion.shadowScale * emergeScale;
      canvas.drawOval(
        Rect.fromCenter(
          center: groundCenter + Offset(0, r * 0.78),
          width: shadowW,
          height: shadowH,
        ),
        Paint()..color = Colors.black.withValues(alpha: motion.shadowAlpha),
      );

      // 2) 발구름 흙먼지 · 중장갑/우두머리 지면 충격파 파동
      if (motion.footImpact > 0.16 && m.freezeTimer <= 0) {
        final dustAlpha = (motion.footImpact * 0.46).clamp(0.0, 0.55);
        final isHeavy = m.kind.isBoss || m.kind.toughnessRating >= 4;
        final dustColor = isHeavy
            ? const Color(0xFFFFD166).withValues(alpha: dustAlpha)
            : const Color(0xFFADB5BD).withValues(alpha: dustAlpha * 0.78);
        canvas.drawOval(
          Rect.fromCenter(
            center: groundCenter + Offset(0, r * 0.76),
            width: r * (2.0 + motion.footImpact * (isHeavy ? 1.5 : 0.9)),
            height: r * (0.75 + motion.footImpact * 0.55),
          ),
          Paint()
            ..color = dustColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHeavy ? 2.2 : 1.4,
        );
      }

      // 3) 독안개 오라 & 빙결 결계
      if (m.kind.poisonAura) {
        final pPulse = 1.0 + sin(sim.elapsedSec * 4.2 + m.uid) * 0.08;
        canvas.drawCircle(
          groundCenter,
          (r + 9) * pPulse,
          Paint()..color = const Color(0x3D52B788),
        );
      }
      if (m.freezeTimer > 0) {
        canvas.drawCircle(
          bodyCenter,
          r + 6,
          Paint()..color = const Color(0x8090E0EF),
        );
      }

      // 4) 중간보스·우두머리 전투력 특화 광륜 (속도=자색질풍 / 맷집=현철청금 / 공격력=적염화염)
      if (m.kind.isBoss) {
        final Color bossAuraColor;
        if (m.kind.speedRating >= 5) {
          bossAuraColor = const Color(0xFFE0AAFF);
        } else if (m.kind.attackRating >= 5) {
          bossAuraColor = const Color(0xFFFF4D00);
        } else if (m.kind.toughnessRating >= 5) {
          bossAuraColor = const Color(0xFF90E0EF);
        } else {
          bossAuraColor = NightPalette.accentGold;
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: groundCenter + Offset(0, r * 0.58),
            width: (r + 8) * 2.1,
            height: (r + 8) * 0.95,
          ),
          Paint()
            ..color = bossAuraColor.withValues(alpha: 0.78)
            ..style = PaintingStyle.stroke
            ..strokeWidth = m.kind.isMidBoss ? 2.2 : 2.8,
        );
      }

      // 5) 코덱스 기본 행군 원화 ↔ 공격·돌진 원화 실시간 전환 및 잔상·타격 플래시
      final baseSprite = sprites.mutantOf(m.kind);
      final atkSprite = sprites.mutantAttackOf(m.kind);
      final activeSprite =
          (motion.useAttackSprite && atkSprite != null) ? atkSprite : baseSprite;

      if (activeSprite != null) {
        final spriteDiameter =
            (m.kind.isBoss ? r * 2.92 : r * 2.62) * emergeScale;

        // 초고속 기습형·질풍보 발동 시 뒤따르는 환영 잔상
        if (motion.afterimageCount > 0 && m.freezeTimer <= 0) {
          for (int k = motion.afterimageCount; k >= 1; k--) {
            final ghostPos = bodyCenter - headingDir * (6.8 * k);
            _drawMutantFootPivotedSprite(
              canvas,
              activeSprite,
              ghostPos,
              width: spriteDiameter * (1.0 - k * 0.05),
              height: spriteDiameter * (1.0 - k * 0.05),
              scaleX: motion.scaleX,
              scaleY: motion.scaleY,
              tiltRad: motion.tiltRad,
              opacity: (0.28 / k).clamp(0.06, 0.28),
              tintColor: Color(m.kind.colorHex).withValues(alpha: 0.45),
            );
          }
        }

        Color? hitOrFreezeTint;
        if (m.hitFlashTimer > 0) {
          final flashA = (m.hitFlashTimer / 0.12).clamp(0.0, 0.72);
          hitOrFreezeTint = Colors.white.withValues(alpha: flashA);
        } else if (m.freezeTimer > 0) {
          hitOrFreezeTint = const Color(0x6690E0EF);
        }

        _drawMutantFootPivotedSprite(
          canvas,
          activeSprite,
          bodyCenter,
          width: spriteDiameter,
          height: spriteDiameter,
          scaleX: motion.scaleX,
          scaleY: motion.scaleY,
          tiltRad: motion.tiltRad,
          tintColor: hitOrFreezeTint,
        );
      } else {
        canvas.drawCircle(
          bodyCenter,
          r * emergeScale,
          Paint()
            ..color = m.hitFlashTimer > 0
                ? Colors.white
                : Color(m.kind.colorHex),
        );
        canvas.drawCircle(
          bodyCenter,
          r * emergeScale,
          Paint()
            ..color = m.kind.isBoss ? NightPalette.accentGold : const Color(0xCCFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = m.kind.isBoss ? 2.8 : 1.3,
        );
      }

      // 6) 전방 공격 덮치기·파성 강타 발톱/검기 초승달 궤적
      if (motion.slashArcAlpha > 0.08) {
        final slashCenter = bodyCenter + headingDir * (r * 0.55);
        canvas.drawArc(
          Rect.fromCircle(center: slashCenter, radius: r + 8),
          m.headingRad - 0.95,
          1.90,
          false,
          Paint()
            ..color = motion.slashColor.withValues(alpha: motion.slashArcAlpha * 0.88)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = m.kind.isBoss ? 4.2 : 2.8,
        );
      }

      // 7) 정면 방패 감쇄 변이체(뼈방패 야차 · 현철 중갑거수 등) 진행 방향 방패 호 표시
      if (m.kind.frontShieldReduction >= 0.25) {
        canvas.drawArc(
          Rect.fromCircle(center: bodyCenter, radius: r + 4),
          m.headingRad - 1.15,
          2.30,
          false,
          Paint()
            ..color = const Color(0xFFFFD166).withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = m.kind.isBoss ? 3.6 : 3.0,
        );
      }

      // 8) 체력 막대 및 우두머리·중간보스 특화 직함 표시
      final hpRatio = (m.hp / m.maxHp).clamp(0.0, 1.0);
      final barW = m.kind.isBoss ? r * 2.55 : r * 2.05;
      final barH = m.kind.isBoss ? 5.6 : 4.4;
      final barCenter = bodyCenter + Offset(0, -r * 1.18 - 8);
      final barRect = Rect.fromCenter(
        center: barCenter,
        width: barW,
        height: barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2.5)),
        Paint()..color = const Color(0xBB050811),
      );
      final fillColor = m.kind.isBoss
          ? (m.kind.isMidBoss ? const Color(0xFFFF9F1C) : const Color(0xFFFF0054))
          : const Color(0xFF80ED99);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barRect.left, barRect.top, barW * hpRatio, barRect.height),
          const Radius.circular(2.5),
        ),
        Paint()..color = fillColor,
      );
      if (m.kind.isBoss) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(2.5)),
          Paint()
            ..color = NightPalette.accentGold.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        _paintMiniText(
          canvas,
          m.displayName,
          barCenter + const Offset(0, -10.5),
          NightPalette.accentGold,
          10.8,
          withBg: true,
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
            ..color = col.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = p.radius * 0.9
            ..strokeCap = StrokeCap.round,
        );
      }

      final c = Offset(p.pos.x, p.pos.y);
      if (p.isGiantCritSerendipity) {
        if (sprites.fxLucky != null) {
          _drawSpriteCentered(
            canvas,
            sprites.fxLucky!,
            c,
            width: p.radius * 3.1,
            height: p.radius * 3.1,
            rotationRad: sim.elapsedSec * 4.0,
            opacity: 0.72,
          );
        } else {
          canvas.drawCircle(
            c,
            p.radius + 5,
            Paint()..color = const Color(0x66FFD166),
          );
        }
      }

      final stoneImg = sprites.stoneOf(p.material);
      if (stoneImg != null) {
        final spinAngle = sim.elapsedSec * 7.0 + (p.pos.x + p.pos.y) * 0.03;
        _drawSpriteCentered(
          canvas,
          stoneImg,
          c,
          width: p.radius * 2.45,
          height: p.radius * 2.45,
          rotationRad: spinAngle,
        );
      } else {
        canvas.drawCircle(c, p.radius, Paint()..color = col);
        canvas.drawCircle(
          c + Offset(-p.radius * 0.28, -p.radius * 0.28),
          p.radius * 0.32,
          Paint()..color = Colors.white.withValues(alpha: 0.65),
        );
      }
    }
  }

  void _drawFxBursts(Canvas canvas) {
    for (final fx in sim.bursts) {
      final prog = fx.progress;
      final alpha = (1.0 - prog).clamp(0.0, 1.0);
      final c = Offset(fx.pos.x, fx.pos.y);
      final col = Color(fx.colorHex).withValues(alpha: alpha);

      if (fx.isTriangleShatter) {
        // 3단 연쇄 회심 파쇄 원화(fx_shatter.webp + fx_critical.webp) 합성
        if (sprites.fxShatter != null) {
          _drawSpriteCentered(
            canvas,
            sprites.fxShatter!,
            c,
            width: fx.maxRadius * (0.9 + prog * 1.15),
            height: fx.maxRadius * (0.9 + prog * 1.15),
            rotationRad: prog * 0.6,
            opacity: alpha * 0.92,
          );
        }
        if (sprites.fxCritical != null) {
          _drawSpriteCentered(
            canvas,
            sprites.fxCritical!,
            c,
            width: fx.maxRadius * (0.75 + prog * 0.85),
            height: fx.maxRadius * (0.75 + prog * 0.85),
            opacity: alpha * 0.85,
          );
        }
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
        ui.Image? fxSprite;
        if (fx.colorHex == 0xFF4CC9F0 || fx.colorHex == 0xFF60A5FA) {
          fxSprite = sprites.fxBarrier;
        } else if (fx.colorHex == 0xFF34D399) {
          fxSprite = sprites.fxQi;
        } else if (fx.colorHex == 0xFFF59E0B || fx.colorHex == 0xFFFFD166) {
          fxSprite = sprites.fxCritical;
        }

        if (fxSprite != null) {
          _drawSpriteCentered(
            canvas,
            fxSprite,
            c,
            width: fx.maxRadius * (0.8 + prog * 1.2),
            height: fx.maxRadius * (0.8 + prog * 1.2),
            opacity: alpha * 0.82,
          );
        }

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

    final waveRect = Rect.fromLTWH(0, sweepY - 48, CampaignCatalog.arenaWidth, 96);
    canvas.drawRect(
      waveRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x00FFD166), Color(0xCCFFD166), Color(0x00FFFFFF)],
        ).createShader(waveRect),
    );

    // 돌격하는 황금 수호 알 편대 7기 (코덱스 수호석 원화 우선)
    final stoneImg = sprites.stoneOf(sim.preset.primaryStone);
    for (int i = 0; i < 7; i++) {
      final sx = 40.0 + i * 53.0;
      final pos = Offset(sx, sweepY);
      if (stoneImg != null) {
        _drawSpriteCentered(
          canvas,
          stoneImg,
          pos,
          width: 28,
          height: 28,
          rotationRad: prog * 8.0,
        );
      } else {
        canvas.drawCircle(
          pos,
          12,
          Paint()..color = const Color(0xFFFFD166),
        );
      }
    }

    // 무림수호단 출두 마패·기마 이펙트 원화(fx_chuldu.webp) 선봉 연출
    if (sprites.fxChuldu != null) {
      _drawSpriteCentered(
        canvas,
        sprites.fxChuldu!,
        Offset(CampaignCatalog.arenaWidth / 2, sweepY - 12),
        width: 96,
        height: 96,
        opacity: (1.15 - prog * 0.4).clamp(0.0, 1.0),
      );
    }
  }

  void _drawDawnPurifyWave(Canvas canvas) {
    if (sim.dawnPurifyAnimTimer <= 0) return;
    final prog = (1.0 - sim.dawnPurifyAnimTimer / 1.5).clamp(0.0, 1.0);
    final center = Offset(
      CampaignCatalog.villageCenter.x,
      CampaignCatalog.villageCenter.y,
    );
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
      final anchor = Offset(
        fc.pos.x.clamp(70.0, 330.0),
        fc.pos.y.clamp(35.0, 630.0),
      );

      ui.Image? badgeSprite;
      if (fc.text.contains('출두')) {
        badgeSprite = sprites.fxChuldu;
      } else if (fc.text.contains('뽀록 추락')) {
        badgeSprite = sprites.fxKnockout;
      } else if (fc.text.contains('도탄') || fc.text.contains('어기어석')) {
        badgeSprite = sprites.fxCombo;
      } else if (fc.text.contains('기연') || fc.text.contains('두꺼비')) {
        badgeSprite = sprites.fxLucky;
      }

      if (badgeSprite != null) {
        _drawSpriteCentered(
          canvas,
          badgeSprite,
          anchor + Offset(0, fc.isBigBanner ? -22 : -16),
          width: fc.isBigBanner ? 34 : 24,
          height: fc.isBigBanner ? 34 : 24,
          opacity: (fc.ttlSec / 0.4).clamp(0.0, 0.95),
        );
      }

      _paintMiniText(
        canvas,
        fc.text,
        anchor,
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
