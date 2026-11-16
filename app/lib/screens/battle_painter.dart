import 'dart:math';
import 'dart:ui' as ui;

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../theme/night_theme.dart';
import '../ui/mutant_motion_engine.dart';
import '../ui/night_art_registry.dart';

/// 심야 수호 전장 60프레임 코덱스 원화 + 곡선 산길 + 직접 초소 배치 + 수동 도탄 조준선 + 6단계 체급 모션 페인터.
class NightBattlePainter extends CustomPainter {
  NightBattlePainter({
    required this.sim,
    required this.repaintTick,
    this.manualAimPreviewAngleRad,
    this.selectedSlotIndex,
    NightBattleSprites? sprites,
  })  : sprites = sprites ?? NightBattleSprites.instance,
        super(repaint: repaintTick);

  final DefenseBattleSim sim;
  final Listenable repaintTick;
  final double? manualAimPreviewAngleRad;
  final int? selectedSlotIndex;
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
    _drawFieldPinballGimmicks(canvas);
    _drawSynergyAndRangeRings(canvas);
    _drawVillageEcosystem(canvas);
    _drawOuterQiShield(canvas);
    _drawManualAimRay(canvas);
    _drawCentralGuardianTower(canvas);
    _drawPathLaunchers(canvas);
    _drawGoldenToad(canvas);
    _drawMutants(canvas);
    _drawProjectilesAndTrails(canvas);
    _drawLightningAndFlyingQiOrbs(canvas);
    _drawFxBursts(canvas);
    _drawChulduSweepWave(canvas);
    _drawDawnPurifyWave(canvas);
    _drawFeverFrameAura(canvas);
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
          ..color = const Color.fromRGBO(255, 255, 255, 0.48),
      );
    }

    // 위쪽 심야 침공 산악 협곡(어둡고 붉은 기운) → 아래쪽 마을 본진(따뜻한 등불 기운) 깊이감 그라데이션
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.62, 1.0],
        colors: [
          Color(0xAD070914),
          Color(0x52121B2E),
          Color(0x9A0D1824),
        ],
      ).createShader(arenaRect);
    canvas.drawRect(arenaRect, skyPaint);

    // 북쪽 상단 적월(붉은 달) 침공 광원
    final moonGlow = Paint()
      ..color = const Color(0x36E63946)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(const Offset(352, 34), 26, moonGlow);
    canvas.drawCircle(
      const Offset(352, 34),
      13,
      Paint()..color = const Color(0xCCFF6B6B),
    );

    // 남단 마을 본진 따뜻한 횃불 바닥 온기
    final villageWarmth = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x36FFD166),
          const Color(0x1672EFDD),
          const Color(0x00000000),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            CampaignCatalog.villageCenter.x,
            CampaignCatalog.villageCenter.y + 8,
          ),
          radius: 132,
        ),
      );
    canvas.drawCircle(
      Offset(
        CampaignCatalog.villageCenter.x,
        CampaignCatalog.villageCenter.y + 8,
      ),
      132,
      villageWarmth,
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
    final borderShadow = Paint()
      ..color = const Color(0x880B101D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 31;
    final outerRoad = Paint()
      ..color = const Color(0x7825324B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 25;
    final innerRoad = Paint()
      ..color = const Color(0x72526382)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 14.5;

    // 1단계: 모든 곡선 산길 바닥을 먼저 연결감 있게 렌더링
    for (int laneIdx = 0; laneIdx < sim.chapter.lanes.length; laneIdx++) {
      final smoothPts = sim.chapter.smoothedLane(laneIdx);
      if (smoothPts.length < 2) continue;

      final path = Path()..moveTo(smoothPts.first.x, smoothPts.first.y);
      for (int i = 1; i < smoothPts.length; i++) {
        path.lineTo(smoothPts[i].x, smoothPts[i].y);
      }
      canvas.drawPath(path, borderShadow);
      canvas.drawPath(path, outerRoad);
      canvas.drawPath(path, innerRoad);
    }

    // 2단계: 곡선 산길 위를 흐르는 침공 방향 화살표 & 최상단 독기 균열문(위→아래 침공 명시)
    for (int laneIdx = 0; laneIdx < sim.chapter.lanes.length; laneIdx++) {
      final smoothPts = sim.chapter.smoothedLane(laneIdx);
      if (smoothPts.length < 4) continue;

      final energy = laneIdx < sim.lanePortalEnergy.length
          ? sim.lanePortalEnergy[laneIdx].clamp(0.0, 1.0)
          : 0.35;

      final arrowAlpha = (0.18 + energy * 0.34).clamp(0.14, 0.54);
      final arrowPaint = Paint()
        ..color = const Color(0xFFFF5C77).withValues(alpha: arrowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.9;

      const stride = 9;
      final phaseOffset = ((sim.elapsedSec * 7.5) % stride).floor();
      for (int idx = 3 + phaseOffset; idx < smoothPts.length - 6; idx += stride) {
        final prev = smoothPts[idx - 1];
        final tip = smoothPts[idx + 1];
        final seg = tip - prev;
        if (seg.length < 1.0) continue;
        final dir = seg.normalized;
        final perp = Vec2(-dir.y, dir.x);
        final leftWing = tip - dir * 5.8 + perp * 4.4;
        final rightWing = tip - dir * 5.8 - perp * 4.4;
        final chev = Path()
          ..moveTo(leftWing.x, leftWing.y)
          ..lineTo(tip.x, tip.y)
          ..lineTo(rightWing.x, rightWing.y);
        canvas.drawPath(chev, arrowPaint);
      }

      // 북쪽 최상단 침공 입구: 심야 독기 침공 균열문(fx_breach_gate.webp)
      final gateCenter = Offset(
        smoothPts.first.x.clamp(26.0, CampaignCatalog.arenaWidth - 26.0),
        smoothPts.first.y.clamp(22.0, 68.0),
      );
      final gateRadius =
          19.5 + energy * 8.5 + sin(sim.elapsedSec * 4.2 + laneIdx) * 1.8;

      canvas.drawCircle(
        gateCenter,
        gateRadius * 1.15,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xCC9D4EDD)
                  .withValues(alpha: (0.28 + energy * 0.42).clamp(0.0, 0.82)),
              const Color(0x88E63946)
                  .withValues(alpha: (0.18 + energy * 0.30).clamp(0.0, 0.60)),
              const Color(0x00000000),
            ],
          ).createShader(
            Rect.fromCircle(center: gateCenter, radius: gateRadius * 1.15),
          ),
      );

      final gateImg = sprites.fxBreachGate;
      if (gateImg != null) {
        _drawSpriteCentered(
          canvas,
          gateImg,
          gateCenter,
          width: gateRadius * 2.25,
          height: gateRadius * 2.25,
          rotationRad: sim.elapsedSec *
              (0.85 + energy * 0.9) *
              (laneIdx.isEven ? 1.0 : -1.0),
          opacity: (0.65 + energy * 0.35).clamp(0.0, 1.0),
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
    // 남단 맨 아래 중앙 마을 본진 (위쪽에서 침공해 내려오는 변이들로부터 수호!)
    // 1) 좌하단: 식량 창고 (village_granary.webp)
    final granaryOk = sim.granaryHealth > 0.5;
    const gPos = Offset(78, 634);
    final granaryImg = sprites.granary;
    if (granaryImg != null) {
      canvas.drawCircle(
        gPos,
        22,
        Paint()
          ..color = granaryOk
              ? const Color(0x33FFD166)
              : const Color(0x55E63946),
      );
      _drawSpriteCentered(
        canvas,
        granaryImg,
        gPos,
        width: 50,
        height: 46,
        tintColor: granaryOk ? null : const Color(0x55E63946),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: gPos, width: 54, height: 32),
          const Radius.circular(6),
        ),
        Paint()
          ..color = granaryOk ? const Color(0xDD5C4033) : const Color(0xDD4A1C1C),
      );
    }
    _paintMiniText(
      canvas,
      '식량 ${(sim.granaryHealth * 100).round()}%',
      gPos + const Offset(0, 25),
      granaryOk ? NightPalette.accentGold : NightPalette.crimsonMoon,
      10.2,
    );

    // 2) 정중앙 최하단: 논밭 농산물 (village_crops.webp)
    final cropsOk = sim.cropsHealth > 0.5;
    const cPos = Offset(200, 646);
    final cropsImg = sprites.crops;
    if (cropsImg != null) {
      final swayRad = sin(sim.elapsedSec * 2.4) * 0.035;
      _drawSpriteCentered(
        canvas,
        cropsImg,
        cPos + const Offset(0, -2),
        width: 58,
        height: 38,
        rotationRad: swayRad,
        tintColor: cropsOk ? null : const Color(0x559D4EDD),
      );
    } else {
      for (int i = -3; i <= 3; i++) {
        final sway = sin(sim.elapsedSec * 3.0 + i) * 2.5;
        final stalkX = cPos.dx + i * 10.5;
        canvas.drawLine(
          Offset(stalkX, cPos.dy + 7),
          Offset(stalkX + sway, cPos.dy - 7 * (0.4 + 0.6 * sim.cropsHealth)),
          Paint()
            ..color = cropsOk ? const Color(0xFF80ED99) : const Color(0xFF9D4EDD)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    _paintMiniText(
      canvas,
      '논밭 ${(sim.cropsHealth * 100).round()}%',
      cPos + const Offset(0, 19),
      cropsOk ? const Color(0xFF80ED99) : const Color(0xFFC77DFF),
      10.2,
    );

    // 3) 우하단: 외양간 가축 (village_livestock.webp)
    final liveOk = sim.livestockHealth > 0.5;
    const lPos = Offset(322, 634);
    final livestockImg = sprites.livestock;
    if (livestockImg != null) {
      canvas.drawCircle(
        lPos,
        22,
        Paint()
          ..color = liveOk
              ? const Color(0x3372EFDD)
              : const Color(0x55E63946),
      );
      _drawSpriteCentered(
        canvas,
        livestockImg,
        lPos,
        width: 50,
        height: 46,
        tintColor: liveOk ? null : const Color(0x55E63946),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: lPos, width: 54, height: 32),
          const Radius.circular(6),
        ),
        Paint()
          ..color = liveOk ? const Color(0xDD3D5A45) : const Color(0xDD4A1C2A),
      );
    }
    _paintMiniText(
      canvas,
      '가축 ${(sim.livestockHealth * 100).round()}%',
      lPos + const Offset(0, 25),
      liveOk ? NightPalette.jadeGreen : NightPalette.crimsonMoon,
      10.2,
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

    final ratio = (sim.shieldHp / sim.shieldMaxHpDynamic).clamp(0.0, 1.0);
    final pulse = 1.0 + sin(sim.elapsedSec * 3.8) * 0.018;
    final r = CampaignCatalog.outerShieldRadius * pulse;
    final shieldColor =
        ratio > 0.45 ? const Color(0xFF4CC9F0) : const Color(0xFFFF9F1C);

    final barrierSprite = sprites.fxBarrier;
    if (barrierSprite != null) {
      _drawSpriteCentered(
        canvas,
        barrierSprite,
        center,
        width: r * 2.04,
        height: r * 2.04,
        rotationRad: sim.elapsedSec * 0.25,
        opacity: 0.12 + 0.15 * ratio,
      );
    }

    canvas.drawCircle(
      center,
      r,
      Paint()..color = shieldColor.withValues(alpha: 0.08 + 0.08 * ratio),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = shieldColor.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
  }

  /// 중앙 기명 수호탑 수동 탄지 조준선 및 담장·회전 기둥 도탄 반사 예측 궤적 렌더링!
  void _drawManualAimRay(Canvas canvas) {
    final bool showRay =
        manualAimPreviewAngleRad != null || sim.centralManualMode;
    if (!showRay || sim.isFinished) return;

    final rawAngle = manualAimPreviewAngleRad ?? sim.centralAimAngleRad;
    final rayPts = sim.previewCentralManualRay(rawAngle);
    if (rayPts.length < 2) return;

    final isDragging = manualAimPreviewAngleRad != null;
    final primaryColor = isDragging
        ? const Color(0xFFFFD166)
        : const Color(0xFF72EFDD);

    // 외곽 광채 선
    final glowPath = Path()..moveTo(rayPts.first.x, rayPts.first.y);
    for (int i = 1; i < rayPts.length; i++) {
      glowPath.lineTo(rayPts[i].x, rayPts[i].y);
    }
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = primaryColor.withValues(alpha: isDragging ? 0.30 : 0.18)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = isDragging ? 7.0 : 4.5,
    );

    // 점선 구슬 조준 궤적 (흐르는 애니메이션)
    final flowOffset = (sim.elapsedSec * 42.0) % 14.0;
    double accum = 0.0;
    for (int i = 0; i < rayPts.length - 1; i++) {
      final a = rayPts[i];
      final b = rayPts[i + 1];
      final seg = b - a;
      final segLen = seg.length;
      if (segLen < 1.0) continue;
      final dir = seg.normalized;

      double d = (14.0 - ((accum - flowOffset) % 14.0)) % 14.0;
      while (d <= segLen) {
        final p = a + dir * d;
        canvas.drawCircle(
          Offset(p.x, p.y),
          isDragging ? 2.5 : 1.9,
          Paint()
            ..color = primaryColor.withValues(alpha: isDragging ? 0.92 : 0.68),
        );
        d += 14.0;
      }
      accum += segLen;

      // 중간 꺾임점(도탄 반사 지점) 황금 파문 표시
      if (i > 0) {
        canvas.drawCircle(
          Offset(a.x, a.y),
          6.5,
          Paint()
            ..color = NightPalette.accentGold.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    }

    // 최종 탄착 조준 십자 원
    final endPt = Offset(rayPts.last.x, rayPts.last.y);
    canvas.drawCircle(
      endPt,
      isDragging ? 9.5 : 7.0,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _drawCentralGuardianTower(Canvas canvas) {
    final center = Offset(
      CampaignCatalog.centralTowerPos.x,
      CampaignCatalog.centralTowerPos.y,
    );
    const r = CampaignCatalog.centralTowerRadius;

    // 수동 탄지 모드일 때 장전 완료 맥동 고리 표시
    if (sim.centralManualMode) {
      final readyPulse = sim.isCentralReadyToFire
          ? (1.0 + sin(sim.elapsedSec * 7.5) * 0.08)
          : 0.94;
      canvas.drawCircle(
        center,
        (r + 9) * readyPulse,
        Paint()
          ..color = sim.isCentralReadyToFire
              ? const Color(0xAAFFD166)
              : const Color(0x4472EFDD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sim.isCentralReadyToFire ? 2.6 : 1.5,
      );
    }

    // 내공 1칸 이상 충전 시 단전 기운(fx_qi.webp) 소용돌이 광륜
    if (sim.qiBars >= 1.0 && sprites.fxQi != null) {
      _drawSpriteCentered(
        canvas,
        sprites.fxQi!,
        center,
        width: r * 2.85,
        height: r * 2.85,
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
          ..strokeWidth = 3.0,
      );
    }

    // 회전하는 8톱니 기어 테두리
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sim.centralGearAngle);
    final gearPaint = Paint()
      ..color = sim.centralManualMode
          ? NightPalette.accentGold
          : NightPalette.jadeShield;
    for (int i = 0; i < 8; i++) {
      canvas.save();
      canvas.rotate(i * pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, -r - 3), width: 7.5, height: 8.5),
          const Radius.circular(2),
        ),
        gearPaint,
      );
      canvas.restore();
    }
    canvas.restore();

    // 조준 방향 포구 화살촉 + 발사 반동 연출
    final aimAngle = manualAimPreviewAngleRad ?? sim.centralAimAngleRad;
    final recoilOffset = Offset(
      cos(aimAngle) * (-sim.centralRecoilAnim * 4.5),
      sin(aimAngle) * (-sim.centralRecoilAnim * 4.5),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(aimAngle);
    final muzzle = Path()
      ..moveTo(r + 10, 0)
      ..lineTo(r + 1, -5.5)
      ..lineTo(r + 1, 5.5)
      ..close();
    canvas.drawPath(
      muzzle,
      Paint()
        ..color = sim.centralManualMode
            ? NightPalette.accentGold
            : NightPalette.jadeGreen,
    );
    canvas.restore();

    final towerImg = sprites.towerGuardian;
    if (towerImg != null) {
      _drawSpriteCentered(
        canvas,
        towerImg,
        center + const Offset(0, -2) + recoilOffset,
        width: 58,
        height: 58,
      );
      final coreStoneImg = sprites.stoneOf(sim.preset.primaryStone);
      if (coreStoneImg != null) {
        _drawSpriteCentered(
          canvas,
          coreStoneImg,
          center + const Offset(0, 7) + recoilOffset,
          width: 17,
          height: 17,
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
        11,
        Paint()..color = Color(sim.preset.primaryStone.colorHex),
      );
    }

    // 동행 수호 영수(pet_*.webp) 호위 연출
    final beastImg = sprites.beastOf(sim.preset.equippedBeast);
    if (beastImg != null &&
        (sim.progress.beastLevels[sim.preset.equippedBeast] ?? 0) > 0) {
      final hoverY = sin(sim.elapsedSec * 3.2) * 2.8;
      _drawSpriteCentered(
        canvas,
        beastImg,
        center + Offset(-42, -10 + hoverY),
        width: 29,
        height: 29,
      );
    }

    // 중앙 탑 바로 아래 직관적인 자동/수동 상태 알약 배지
    _paintMiniText(
      canvas,
      sim.centralManualMode ? '🎯수동 저격(전장)' : '⚙️근접 방어(자동)',
      center + const Offset(0, 32),
      sim.centralManualMode ? NightPalette.accentGold : NightPalette.jadeGreen,
      10.2,
      withBg: true,
    );
  }

  /// 전장 핀볼 기물 3종(×2 쌍류 복제 마법진 · 심야 화약통 · 황금 보물 도깨비) 렌더링!
  void _drawFieldPinballGimmicks(Canvas canvas) {
    final gate = sim.cloneGate;
    final gateCenter = Offset(gate.center.x, gate.center.y);
    final gatePulse = 1.0 + gate.pulseAnim * 0.25 + sin(sim.elapsedSec * 4.5) * 0.05;
    final gateImg = sprites.fxCloneGate;
    if (gateImg != null) {
      _drawSpriteCentered(
        canvas,
        gateImg,
        gateCenter,
        width: gate.radius * 2.35 * gatePulse,
        height: gate.radius * 2.35 * gatePulse,
        rotationRad: sim.elapsedSec * 1.4,
        opacity: 0.92,
      );
    } else {
      canvas.drawCircle(
        gateCenter,
        gate.radius * gatePulse,
        Paint()
          ..color = const Color(0xAA72EFDD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }
    _paintMiniText(
      canvas,
      '×2 복제',
      gateCenter,
      NightPalette.accentGold,
      10.6,
      withBg: true,
    );

    for (final keg in sim.powderKegs) {
      final kc = Offset(keg.pos.x, keg.pos.y);
      if (keg.intact) {
        final wobble = sin(sim.elapsedSec * 7.0 + keg.pos.x) * 0.06;
        final kegImg = sprites.propPowderKeg;
        if (kegImg != null) {
          _drawSpriteCentered(
            canvas,
            kegImg,
            kc,
            width: 38,
            height: 38,
            rotationRad: wobble,
          );
        } else {
          canvas.drawCircle(kc, 15, Paint()..color = const Color(0xFF9E2A2B));
        }
        final sparkOffset = kc + Offset(4 + sin(sim.elapsedSec * 18) * 1.5, -16);
        canvas.drawCircle(
          sparkOffset,
          3.0 + sin(sim.elapsedSec * 24).abs() * 1.8,
          Paint()..color = const Color(0xFFFFD166),
        );
        _paintMiniText(
          canvas,
          '🧨폭약+16⚡',
          kc + const Offset(0, 22),
          const Color(0xFFFF9F1C),
          9.0,
          withBg: true,
        );
      } else {
        final ratio = (1.0 - keg.respawnTimer / 14.0).clamp(0.0, 1.0);
        canvas.drawArc(
          Rect.fromCircle(center: kc, radius: 13),
          -pi / 2,
          2 * pi * ratio,
          false,
          Paint()
            ..color = const Color(0xAAFF9F1C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }
    }

    final gob = sim.treasureGoblin;
    if (gob != null && gob.alive) {
      final gc = Offset(gob.pos.x, gob.pos.y);
      final hopY = -sin(gob.animPhase).abs() * 5.5;
      if (sprites.fxLucky != null) {
        _drawSpriteCentered(
          canvas,
          sprites.fxLucky!,
          gc,
          width: 48,
          height: 48,
          rotationRad: -sim.elapsedSec * 2.5,
          opacity: 0.72,
        );
      }
      final gobImg = sprites.mutTreasureGoblin;
      if (gobImg != null) {
        _drawSpriteCentered(
          canvas,
          gobImg,
          gc + Offset(0, hopY),
          width: 42,
          height: 42,
          tintColor: gob.hitFlashTimer > 0.1
              ? Colors.white.withValues(alpha: 0.65)
              : null,
        );
      } else {
        canvas.drawCircle(gc, 15, Paint()..color = NightPalette.accentGold);
      }
      final hpRatio = (gob.hp / gob.maxHp).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: gc + const Offset(0, -24), width: 38, height: 5),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.black87,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(gc.dx - 19, gc.dy - 26.5, 38 * hpRatio, 5),
          const Radius.circular(3),
        ),
        Paint()..color = NightPalette.accentGold,
      );
      _paintMiniText(
        canvas,
        '👹+55⚡·비급',
        gc + const Offset(0, 24),
        NightPalette.accentGold,
        9.4,
        withBg: true,
      );
    }
  }

  /// 초소 간 진법 시너지 광선 연결 & 선택된 초소의 실제 사거리 원(295px) 표시!
  void _drawSynergyAndRangeRings(Canvas canvas) {
    if (!sim.centralManualMode) {
      final tc = Offset(
        CampaignCatalog.centralTowerPos.x,
        CampaignCatalog.centralTowerPos.y,
      );
      canvas.drawCircle(
        tc,
        DefenseBattleSim.centralAutoMaxRange,
        Paint()
          ..color = NightPalette.jadeShield.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    if (selectedSlotIndex != null) {
      final slot = sim.mountSlotByIndex(selectedSlotIndex!);
      if (slot != null) {
        final sc = Offset(slot.pos.x, slot.pos.y);
        canvas.drawCircle(
          sc,
          295.0,
          Paint()..color = NightPalette.jadeGreen.withValues(alpha: 0.08),
        );
        canvas.drawCircle(
          sc,
          295.0,
          Paint()
            ..color = NightPalette.jadeGreen.withValues(alpha: 0.48)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }

    for (final link in sim.activeSynergyLinks) {
      final a = Offset(link.posA.x, link.posA.y);
      final b = Offset(link.posB.x, link.posB.y);
      final col = Color(link.colorHex);
      final pulseAlpha = 0.30 + 0.20 * (0.5 + 0.5 * sin(sim.elapsedSec * 5.0));
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = col.withValues(alpha: pulseAlpha * 0.55)
          ..strokeWidth = 5.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = col.withValues(alpha: pulseAlpha + 0.25)
          ..strokeWidth = 1.9,
      );
    }
  }

  /// 개방된 길목 초소(`2곳 → 10곳`) 렌더링:
  /// 빈 초소마다 실시간 원형 기력 충전 게이지 + 명확한 조건 배지(`🔒2물결 개방` / `⚡13/35` / `🎲운빨가능` / `🔨건설 가능!`) 표시!
  void _drawPathLaunchers(Canvas canvas) {
    final recSlotIndex = sim.nextRecommendedSlotIndex();

    for (final slot in sim.activeMounts) {
      final c = Offset(slot.pos.x, slot.pos.y);
      final built = sim.launcherAtSlot(slot.slotIndex);

      if (built == null) {
        final cond = sim.padConditionOf(slot.slotIndex);
        final isRecommended = slot.slotIndex == recSlotIndex;
        final isReady = cond.state == PadConditionState.readyFullBuild ||
            cond.state == PadConditionState.readyLuckyOnly;
        final isLocked = cond.state == PadConditionState.waveLocked;
        final pulse = 1.0 + sin(sim.elapsedSec * 5.6 + slot.slotIndex) * 0.07;

        final Color ringColor = switch (cond.state) {
          PadConditionState.readyFullBuild => const Color(0xFF80ED99),
          PadConditionState.readyLuckyOnly => NightPalette.accentGold,
          PadConditionState.chargingQi => NightPalette.jadeShield,
          PadConditionState.waveLocked => const Color(0xFF8D99AE),
          PadConditionState.built => NightPalette.jadeGreen,
        };

        if (isReady || isRecommended) {
          canvas.drawCircle(
            c,
            24.0 * pulse,
            Paint()
              ..color = ringColor.withValues(alpha: isReady ? 0.42 : 0.20)
              ..style = PaintingStyle.stroke
              ..strokeWidth = isReady ? 2.6 : 1.5,
          );
        }

        final padPath = Path();
        for (int k = 0; k < 8; k++) {
          final a = (pi / 8) + k * (pi / 4);
          final px = c.dx + cos(a) * 18.0;
          final py = c.dy + sin(a) * 18.0;
          if (k == 0) {
            padPath.moveTo(px, py);
          } else {
            padPath.lineTo(px, py);
          }
        }
        padPath.close();

        canvas.drawPath(
          padPath,
          Paint()..color = isLocked ? const Color(0xAA0A0F1A) : const Color(0xDD10192B),
        );
        canvas.drawPath(
          padPath,
          Paint()
            ..color = ringColor.withValues(alpha: isLocked ? 0.38 : 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isReady ? 2.1 : 1.3,
        );

        if (!isLocked) {
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: 21.0),
            -pi / 2,
            2 * pi * cond.chargeRatio.clamp(0.0, 1.0),
            false,
            Paint()
              ..color = ringColor
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = 2.8,
          );
        }

        if (isLocked) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c + const Offset(0, 2), width: 10, height: 8),
              const Radius.circular(2),
            ),
            Paint()..color = const Color(0xFFADB5BD),
          );
          canvas.drawArc(
            Rect.fromCenter(center: c + const Offset(0, -2), width: 7, height: 7),
            pi,
            pi,
            false,
            Paint()
              ..color = const Color(0xFFADB5BD)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        } else {
          final plusPaint = Paint()
            ..color = ringColor
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(c + const Offset(-5.5, 0), c + const Offset(5.5, 0), plusPaint);
          canvas.drawLine(c + const Offset(0, -5.5), c + const Offset(0, 5.5), plusPaint);
        }

        _paintMiniText(
          canvas,
          cond.shortBadge,
          c + const Offset(0, 25),
          ringColor,
          9.4,
          withBg: true,
        );
        continue;
      }

      final l = built;
      final baseColor = Color(l.type.colorHex);
      final canUpgrade =
          l.tier < 4 && sim.fieldTokens >= l.type.inBattleUpgradeCost(l.tier);
      final canMerge = sim.findMergePartnerSlot(l.slotIndex) != null;

      if (l.type == LauncherType.qiAmplifier && sprites.fxQi != null) {
        _drawSpriteCentered(
          canvas,
          sprites.fxQi!,
          c,
          width: 48,
          height: 48,
          rotationRad: sim.elapsedSec * 0.9,
          opacity: 0.28,
        );
      }

      canvas.drawCircle(c, 19.5, Paint()..color = const Color(0xCC141B2D));
      canvas.drawCircle(
        c,
        19.5,
        Paint()
          ..color = l.tier >= 4
              ? NightPalette.accentGold
              : (canMerge
                  ? NightPalette.accentGold
                  : (canUpgrade ? NightPalette.jadeGreen : baseColor))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + l.tier * 0.45,
      );

      final launcherImg = sprites.launcherOf(l.type);
      if (launcherImg != null) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(l.aimAngleRad);
        final aimTip = Path()
          ..moveTo(23.5, 0)
          ..lineTo(17.5, -4)
          ..lineTo(17.5, 4)
          ..close();
        canvas.drawPath(aimTip, Paint()..color = baseColor);
        canvas.restore();

        final recoilShift = Offset(
          cos(l.aimAngleRad) * (-l.recoilAnim * 4.0),
          sin(l.aimAngleRad) * (-l.recoilAnim * 4.0),
        );
        final scale = 1.0 + l.recoilAnim * 0.10;
        _drawSpriteCentered(
          canvas,
          launcherImg,
          c + recoilShift,
          width: 40 * scale,
          height: 40 * scale,
        );
      } else {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(l.aimAngleRad);
        final recoilOffset = -l.recoilAnim * 4.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(recoilOffset, -4.5, 19, 9),
            const Radius.circular(3),
          ),
          Paint()..color = baseColor,
        );
        canvas.restore();
        canvas.drawCircle(c, 8, Paint()..color = baseColor.withValues(alpha: 0.9));
      }

      if (canMerge) {
        _paintMiniText(
          canvas,
          '☯합치기!',
          c + const Offset(0, -24),
          NightPalette.accentGold,
          9.2,
          withBg: true,
        );
      }

      _paintMiniText(
        canvas,
        canUpgrade ? '${l.tier}형▲' : '${l.tier}형',
        c + const Offset(0, 24),
        canUpgrade ? NightPalette.jadeGreen : NightPalette.accentGold,
        10.0,
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

  /// 6단계 체급(`19px` 소형 독쥐 → `58px` 중갑 멧돼지 → `80px` 중간보스 → `108px` 대요마) & 연속 생체 모션 렌더링!
  void _drawMutants(Canvas canvas) {
    if (sim.mutants.isEmpty) return;

    // 원근 깊이감(Y좌표 오름차순 + 보스는 한 겹 위렷하게)으로 정렬
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

      final emergeScale = m.spawnPortalTimer > 0
          ? (1.0 - (m.spawnPortalTimer / 0.45) * 0.45).clamp(0.48, 1.0)
          : 1.0;

      // 종류별 고유 체급 지름(`visualDiameter`: 19px ~ 108px)과 체형 가로 비율(`bodyWidthRatio`) 적용!
      final visualH = m.kind.visualDiameter * emergeScale;
      final visualW = visualH * m.kind.bodyWidthRatio;
      final halfVisualH = visualH * 0.5;

      final headingDir = Offset(cos(m.headingRad), sin(m.headingRad));
      final perpDir = Offset(-headingDir.dy, headingDir.dx);
      final swayScale = (m.kind.visualDiameter / 36.0).clamp(0.58, 1.35);
      final groundCenter = c + perpDir * (motion.swayX * 0.48 * swayScale);
      final bodyCenter = c +
          perpDir * (motion.swayX * 0.88 * swayScale) +
          headingDir * (motion.forwardThrust * swayScale) +
          Offset(0, motion.liftY * swayScale);

      // 1) 체급에 비례하는 발밑 타원 접지 그림자
      final shadowW = visualW * 0.82 * motion.shadowScale;
      final shadowH = visualH * 0.30 * motion.shadowScale;
      canvas.drawOval(
        Rect.fromCenter(
          center: groundCenter + Offset(0, halfVisualH * 0.64),
          width: shadowW,
          height: shadowH,
        ),
        Paint()..color = Colors.black.withValues(alpha: motion.shadowAlpha),
      );

      // 2) 발구름 흙먼지 · 중장갑/우두머리 지면 충격파 파동
      if (motion.footImpact > 0.18 && m.freezeTimer <= 0) {
        final dustAlpha = (motion.footImpact * 0.44).clamp(0.0, 0.52);
        final isHeavy = m.kind.isBoss || m.kind.toughnessRating >= 4;
        if (isHeavy || m.kind.visualDiameter >= 26.0) {
          final dustColor = isHeavy
              ? const Color(0xFFFFD166).withValues(alpha: dustAlpha)
              : const Color(0xFFADB5BD).withValues(alpha: dustAlpha * 0.72);
          canvas.drawOval(
            Rect.fromCenter(
              center: groundCenter + Offset(0, halfVisualH * 0.62),
              width: visualW * (0.78 + motion.footImpact * (isHeavy ? 0.52 : 0.30)),
              height: visualH * (0.28 + motion.footImpact * 0.18),
            ),
            Paint()
              ..color = dustColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = isHeavy ? 2.2 : 1.3,
          );
        }
      }

      // 3) 독안개 오라 · 혈독 분열핵 맥동 · 빙결 결계
      if (m.kind.poisonAura) {
        final pPulse = 1.0 + sin(sim.elapsedSec * 4.2 + m.uid) * 0.08;
        canvas.drawCircle(
          groundCenter,
          (halfVisualH + 7) * pPulse,
          Paint()..color = const Color(0x3D52B788),
        );
      }
      if (m.kind == MutantKind.bloodCocoon) {
        final corePulse = 0.5 + 0.5 * sin(sim.elapsedSec * 7.2 + m.uid);
        canvas.drawCircle(
          groundCenter,
          halfVisualH * (0.62 + corePulse * 0.18),
          Paint()
            ..color = const Color(0xFFFF0054)
                .withValues(alpha: 0.16 + corePulse * 0.16),
        );
      }
      if (m.freezeTimer > 0) {
        canvas.drawCircle(
          bodyCenter,
          halfVisualH * 0.82,
          Paint()..color = const Color(0x8090E0EF),
        );
      }

      // 4) 중간보스·우두머리 전투력 특화 광륜
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
            center: groundCenter + Offset(0, halfVisualH * 0.52),
            width: visualW * 0.96,
            height: visualH * 0.40,
          ),
          Paint()
            ..color = bossAuraColor.withValues(alpha: 0.80)
            ..style = PaintingStyle.stroke
            ..strokeWidth = m.kind.isMidBoss ? 2.2 : 3.0,
        );
      }

      // 5) 코덱스 기본 행군 원화 ↔ 공격·돌진 원화 연속 크로스페이드 렌더링!
      final baseSprite = sprites.mutantOf(m.kind);
      final atkSprite = sprites.mutantAttackOf(m.kind);

      if (baseSprite != null || atkSprite != null) {
        final mainSprite = baseSprite ?? atkSprite!;

        if (motion.afterimageCount > 0 && m.freezeTimer <= 0) {
          final ghostSprite =
              (motion.useAttackSprite && atkSprite != null) ? atkSprite : mainSprite;
          for (int k = motion.afterimageCount; k >= 1; k--) {
            final ghostPos = bodyCenter - headingDir * (6.8 * k);
            _drawMutantFootPivotedSprite(
              canvas,
              ghostSprite,
              ghostPos,
              width: visualW * (1.0 - k * 0.05),
              height: visualH * (1.0 - k * 0.05),
              scaleX: motion.scaleX,
              scaleY: motion.scaleY,
              tiltRad: motion.tiltRad,
              opacity: (0.26 / k).clamp(0.06, 0.26),
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

        final blend = (atkSprite != null && baseSprite != null)
            ? motion.attackBlend
            : 0.0;

        if (blend <= 0.06 || atkSprite == null) {
          _drawMutantFootPivotedSprite(
            canvas,
            mainSprite,
            bodyCenter,
            width: visualW,
            height: visualH,
            scaleX: motion.scaleX,
            scaleY: motion.scaleY,
            tiltRad: motion.tiltRad,
            tintColor: hitOrFreezeTint,
          );
        } else if (blend >= 0.94) {
          _drawMutantFootPivotedSprite(
            canvas,
            atkSprite,
            bodyCenter,
            width: visualW,
            height: visualH,
            scaleX: motion.scaleX,
            scaleY: motion.scaleY,
            tiltRad: motion.tiltRad,
            tintColor: hitOrFreezeTint,
          );
        } else {
          // 연속 크로스페이드로 자세 전환 스냅 현상 완벽 제거
          _drawMutantFootPivotedSprite(
            canvas,
            mainSprite,
            bodyCenter,
            width: visualW,
            height: visualH,
            scaleX: motion.scaleX,
            scaleY: motion.scaleY,
            tiltRad: motion.tiltRad,
            opacity: 1.0 - blend * 0.75,
            tintColor: hitOrFreezeTint,
          );
          _drawMutantFootPivotedSprite(
            canvas,
            atkSprite,
            bodyCenter,
            width: visualW,
            height: visualH,
            scaleX: motion.scaleX,
            scaleY: motion.scaleY,
            tiltRad: motion.tiltRad,
            opacity: blend,
            tintColor: hitOrFreezeTint,
          );
        }
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: bodyCenter,
            width: visualW * 0.72,
            height: visualH * 0.72,
          ),
          Paint()
            ..color = m.hitFlashTimer > 0
                ? Colors.white
                : Color(m.kind.colorHex),
        );
      }

      // 6) 전방 공격 덮치기·파성 강타 발톱/검기 초승달 궤적
      if (motion.slashArcAlpha > 0.08) {
        final slashCenter = bodyCenter + headingDir * (r * 0.55);
        canvas.drawArc(
          Rect.fromCircle(center: slashCenter, radius: halfVisualH * 0.62 + 6),
          m.headingRad - 0.95,
          1.90,
          false,
          Paint()
            ..color =
                motion.slashColor.withValues(alpha: motion.slashArcAlpha * 0.88)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = m.kind.isBoss ? 4.2 : 2.6,
        );
      }

      // 7) 정면 방패 감쇄 변이체 진행 방향 방패 호 표시
      if (m.kind.frontShieldReduction >= 0.25) {
        canvas.drawArc(
          Rect.fromCircle(center: bodyCenter, radius: halfVisualH * 0.56 + 3),
          m.headingRad - 1.15,
          2.30,
          false,
          Paint()
            ..color = const Color(0xFFFFD166).withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = m.kind.isBoss ? 3.6 : 2.8,
        );
      }

      // 8) 체급별 맞춤 체력 막대 (다친 일반 소형 변이 또는 중대형/보스 위주 깔끔 표시)
      final hpRatio = (m.hp / m.maxHp).clamp(0.0, 1.0);
      final showBar =
          m.kind.isBoss || m.kind.visualDiameter >= 32.0 || hpRatio < 0.995;
      if (showBar) {
        final barW = (visualW * 0.74).clamp(16.0, 86.0);
        final barH = m.kind.isBoss ? 5.8 : (m.kind.visualDiameter >= 50 ? 4.8 : 3.6);
        final barCenter = bodyCenter + Offset(0, -halfVisualH * 0.86 - 5);
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
            ? (m.kind.isMidBoss
                ? const Color(0xFFFF9F1C)
                : const Color(0xFFFF0054))
            : (m.kind.visualDiameter >= 50
                ? const Color(0xFFFFB703)
                : const Color(0xFF80ED99));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              barRect.left,
              barRect.top,
              barW * hpRatio,
              barRect.height,
            ),
            const Radius.circular(2.5),
          ),
          Paint()..color = fillColor,
        );
        if (m.kind.isBoss) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(barRect, const Radius.circular(2.5)),
            Paint()
              ..color = NightPalette.accentGold.withValues(alpha: 0.85)
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

    final waveRect =
        Rect.fromLTWH(0, sweepY - 48, CampaignCatalog.arenaWidth, 96);
    canvas.drawRect(
      waveRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x00FFD166), Color(0xCCFFD166), Color(0x00FFFFFF)],
        ).createShader(waveRect),
    );

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

  /// 뇌전 연쇄탄(LightningArcFx) 및 상단 건설 기력 게이지로 날아가는 황금 기력 구슬(FlyingQiOrb) 연출!
  void _drawLightningAndFlyingQiOrbs(Canvas canvas) {
    for (final arc in sim.lightningArcs) {
      final a = Offset(arc.from.x, arc.from.y);
      final b = Offset(arc.to.x, arc.to.y);
      final mid = Offset(
        (a.dx + b.dx) * 0.5 + sin(sim.elapsedSec * 45 + a.dx) * 9.0,
        (a.dy + b.dy) * 0.5 - cos(sim.elapsedSec * 45 + b.dy) * 9.0,
      );
      final alpha = (arc.ttlSec / 0.24).clamp(0.0, 1.0);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(arc.colorHex).withValues(alpha: alpha * 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    for (final orb in sim.flyingQiOrbs) {
      final oc = Offset(orb.currentPos.x, orb.currentPos.y);
      final col = Color(orb.colorHex);
      canvas.drawCircle(
        oc,
        7.5,
        Paint()
          ..color = col.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(oc, 4.2, Paint()..color = col);
      canvas.drawCircle(oc, 2.0, Paint()..color = Colors.white);
      if (orb.amount >= 8 && orb.progress < 0.72) {
        _paintMiniText(
          canvas,
          '+${orb.amount}⚡',
          oc + const Offset(0, -10),
          col,
          8.8,
        );
      }
    }
  }

  /// 광폭 탄지 무쌍(피버 타임) 돌입 시 전장 황금 주작 오라 & 테두리 불꽃!
  void _drawFeverFrameAura(Canvas canvas) {
    if (sim.feverTimer <= 0) return;
    final pulse = 0.55 + 0.35 * sin(sim.elapsedSec * 9.0).abs();
    final feverImg = sprites.fxFeverAura;
    if (feverImg != null) {
      _drawSpriteCentered(
        canvas,
        feverImg,
        Offset(
          CampaignCatalog.centralTowerPos.x,
          CampaignCatalog.centralTowerPos.y - 4,
        ),
        width: 98,
        height: 98,
        rotationRad: sim.elapsedSec * 0.8,
        opacity: 0.52 * pulse,
      );
    }
    canvas.drawRect(
      const Rect.fromLTWH(2, 2, CampaignCatalog.arenaWidth - 4, CampaignCatalog.arenaHeight - 4),
      Paint()
        ..color = NightPalette.accentGold.withValues(alpha: 0.48 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8,
    );
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
        ..color =
            const Color(0x99FFD166).withValues(alpha: (1.0 - prog) * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0,
    );
  }

  void _drawFloatingCallouts(Canvas canvas) {
    for (final fc in sim.callouts) {
      final anchor = Offset(
        fc.pos.x.clamp(70.0, 330.0),
        fc.pos.y.clamp(35.0, 625.0),
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
        fc.isBigBanner ? 13.5 : 11.2,
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
          Rect.fromLTWH(
            offset.dx - 7,
            offset.dy - 3,
            tp.width + 14,
            tp.height + 6,
          ),
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
