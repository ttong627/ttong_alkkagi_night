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
    this.zoomFocusPos,
    this.zoomScale = 1.0,
    NightBattleSprites? sprites,
  })  : sprites = sprites ?? NightBattleSprites.instance,
        super(repaint: repaintTick);

  final DefenseBattleSim sim;
  final Listenable repaintTick;
  final double? manualAimPreviewAngleRad;
  final int? selectedSlotIndex;
  final Vec2? zoomFocusPos;
  final double zoomScale;
  final NightBattleSprites sprites;

  bool get _isPipZoom => zoomFocusPos != null && zoomScale > 1.01;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (_isPipZoom) {
      final focus = zoomFocusPos!;
      final aspect = size.height / max(1.0, size.width);
      final viewW = (CampaignCatalog.arenaWidth / zoomScale).clamp(160.0, CampaignCatalog.arenaWidth);
      final viewH = (viewW * aspect).clamp(120.0, CampaignCatalog.arenaHeight);
      final left = (focus.x - viewW * 0.5).clamp(0.0, CampaignCatalog.arenaWidth - viewW);
      final top = (focus.y - viewH * 0.5).clamp(0.0, CampaignCatalog.arenaHeight - viewH);
      canvas.scale(size.width / viewW, size.height / viewH);
      canvas.translate(-left, -top);
    } else {
      final sx = size.width / CampaignCatalog.arenaWidth;
      final sy = size.height / CampaignCatalog.arenaHeight;
      canvas.scale(sx, sy);
    }

    // 우두머리 등장·파성 강타·중포 포격 시 전장 진동 연출
    if (sim.screenShakeTimer > 0) {
      final amp = (sim.screenShakeIntensity * (_isPipZoom ? 0.55 : 1.15)).clamp(0.0, 6.8);
      final dx = sin(sim.elapsedSec * 58.0) * amp;
      final dy = cos(sim.elapsedSec * 47.0) * amp * 0.75;
      canvas.translate(dx, dy);
    }

    _drawFloorAndNightAtmosphere(canvas);
    _drawCliffZones(canvas);
    _drawInvasionLanes(canvas);
    _drawRotatingPillars(canvas);
    _drawFieldPinballGimmicks(canvas);
    if (!_isPipZoom) {
      _drawSynergyAndRangeRings(canvas);
    }
    _drawVillageEcosystem(canvas);
    _drawOuterQiShield(canvas);
    if (!_isPipZoom) {
      _drawManualAimRay(canvas);
    }
    _drawCentralGuardianTower(canvas);
    _drawPathLaunchers(canvas);
    _drawMuzzleFlashes(canvas);
    _drawGoldenToad(canvas);
    _drawDeathRagdollsAndShards(canvas);
    _drawCrisisTargetBeacon(canvas);
    _drawMutants(canvas);
    _drawProjectilesAndTrails(canvas);
    _drawLightningAndFlyingQiOrbs(canvas);
    _drawFxBursts(canvas);
    _drawShockwaveRingsAndCritImpacts(canvas);
    _drawChulduSweepWave(canvas);
    _drawDawnPurifyWave(canvas);
    if (!_isPipZoom) {
      _drawDangerTensionPulse(canvas);
      _drawFeverFrameAura(canvas);
    }
    _drawDamagePopups(canvas);
    if (!_isPipZoom) {
      _drawFloatingCallouts(canvas);
    }

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

  /// 코덱스 4프레임 알파 투명 스트립(`1024x256`)에서 지정 프레임(`0..3`)을 중심 기준으로 렌더링.
  void _drawStripFrameCentered(
    Canvas canvas,
    ui.Image stripImage,
    int frameIndex,
    Offset center, {
    required double width,
    required double height,
    int totalFrames = 4,
    double rotationRad = 0.0,
    double opacity = 1.0,
    Color? tintColor,
    BlendMode tintBlendMode = BlendMode.srcATop,
  }) {
    final alpha = opacity.clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    final safeIdx = ((frameIndex % totalFrames) + totalFrames) % totalFrames;
    final cellW = stripImage.width.toDouble() / totalFrames;
    final cellH = stripImage.height.toDouble();

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

    final src = Rect.fromLTWH(safeIdx * cellW, 0, cellW, cellH);
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    canvas.drawImageRect(stripImage, src, dst, paint);
    canvas.restore();
  }

  void _drawFloorAndNightAtmosphere(Canvas canvas) {
    const arenaRect = Rect.fromLTWH(
      0,
      0,
      CampaignCatalog.arenaWidth,
      CampaignCatalog.arenaHeight,
    );

    // 1) 코덱스 3D 탑다운 전장 맵 원화(floor_night_ch1~10.webp)를 100% 무손실 선명도로 풀렌더링!
    canvas.drawRect(arenaRect, Paint()..color = const Color(0xFF1E2D46));
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
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    // 북쪽 상단 적월(붉은 달) 침공 광원
    final moonGlow = Paint()
      ..color = const Color(0x28E63946)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(const Offset(360, 38), 32, moonGlow);

    // 각 장의 실제 원형 수호 제단(sim.towerPos) 따뜻한 등불 광원
    final altarCenter = Offset(sim.towerPos.x, sim.towerPos.y);
    final villageWarmth = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x28FFD166),
          Color(0x1272EFDD),
          Color(0x00000000),
        ],
      ).createShader(
        Rect.fromCircle(center: altarCenter, radius: 138),
      );
    canvas.drawCircle(altarCenter, 138, villageWarmth);
  }

  void _drawCliffZones(Canvas canvas) {
    // 코덱스 맵 외곽 벼랑·해자 위에는 가짜 빈 초소처럼 오인될 수 있는 하늘색 원 테두리를 그리지 않고 은은한 심연 그림자만 드리운다!
    for (final cliff in sim.chapter.cliffs) {
      final c = Offset(cliff.center.x, cliff.center.y);
      final swirlPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55060B16), Color(0x220E1B30), Color(0x00000000)],
        ).createShader(Rect.fromCircle(center: c, radius: cliff.radius));
      canvas.drawCircle(c, cliff.radius, swirlPaint);
    }
  }

  void _drawInvasionLanes(Canvas canvas) {
    // 1단계: 불투명 파이프를 100% 제거하고, 각 장의 고유 다중 침공로(smoothedVisualGuides)마다 은은한 기맥 유도선과 진행 화살표만 표시!
    final guideLanes = sim.chapter.smoothedVisualGuides;
    final avgEnergy = sim.lanePortalEnergy.isEmpty
        ? 0.38
        : (sim.lanePortalEnergy.fold<double>(0.0, (a, b) => a + b) /
                sim.lanePortalEnergy.length)
            .clamp(0.0, 1.0);
    final arrowAlpha = (0.22 + avgEnergy * 0.36).clamp(0.18, 0.58);

    for (int gIdx = 0; gIdx < guideLanes.length; gIdx++) {
      final spinePts = guideLanes[gIdx];
      if (spinePts.length < 2) continue;

      final glowColor = gIdx == 0
          ? const Color(0x22F4CC6A)
          : (gIdx == 1 ? const Color(0x2072EFDD) : const Color(0x20FF758F));
      final coreColor = gIdx == 0
          ? const Color(0x36FFE599)
          : (gIdx == 1 ? const Color(0x3490E0EF) : const Color(0x34FFB3C1));

      final subtleGlow = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4.6;
      final subtleCore = Paint()
        ..color = coreColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.5;

      final path = Path()..moveTo(spinePts.first.x, spinePts.first.y);
      for (int i = 1; i < spinePts.length; i++) {
        path.lineTo(spinePts[i].x, spinePts[i].y);
      }
      canvas.drawPath(path, subtleGlow);
      canvas.drawPath(path, subtleCore);

      final arrowPaint = Paint()
        ..color = const Color(0xFFFF5C77).withValues(alpha: arrowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.0;

      const stride = 7;
      final phaseOffset = ((sim.elapsedSec * 6.5 + gIdx * 2) % stride).floor();
      for (int idx = 2 + phaseOffset; idx < spinePts.length - 3; idx += stride) {
        final prev = spinePts[idx - 1];
        final tip = spinePts[idx + 1];
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
    }

    // 2단계: 각 장의 실제 침공 관문(북문·측면 X자 성문·남쪽 빙하/사막 성문·해적 현측 도교) 정위치에 독기 균열문 표시!
    final drawnGates = <Offset>[];
    for (int laneIdx = 0; laneIdx < sim.chapter.lanes.length; laneIdx++) {
      final smoothPts = sim.chapter.smoothedLane(laneIdx);
      if (smoothPts.isEmpty) continue;
      final gateCenter = Offset(
        smoothPts.first.x.clamp(28.0, CampaignCatalog.arenaWidth - 28.0),
        smoothPts.first.y.clamp(28.0, CampaignCatalog.arenaHeight - 28.0),
      );
      if (drawnGates.any((g) => (g - gateCenter).distance < 44.0)) {
        continue;
      }
      drawnGates.add(gateCenter);

      final energy = laneIdx < sim.lanePortalEnergy.length
          ? sim.lanePortalEnergy[laneIdx].clamp(0.0, 1.0)
          : 0.35;
      final gateRadius =
          18.5 + energy * 7.5 + sin(sim.elapsedSec * 4.2 + laneIdx) * 1.6;

      canvas.drawCircle(
        gateCenter,
        gateRadius * 1.12,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xCCE05248)
                  .withValues(alpha: (0.26 + energy * 0.40).clamp(0.0, 0.80)),
              const Color(0x88F4CC6A)
                  .withValues(alpha: (0.16 + energy * 0.28).clamp(0.0, 0.56)),
              const Color(0x00000000),
            ],
          ).createShader(
            Rect.fromCircle(center: gateCenter, radius: gateRadius * 1.12),
          ),
      );

      final gateImg = sprites.fxBreachGate;
      if (gateImg != null) {
        _drawSpriteCentered(
          canvas,
          gateImg,
          gateCenter,
          width: gateRadius * 2.15,
          height: gateRadius * 2.15,
          rotationRad: sim.elapsedSec *
              (0.85 + energy * 0.9) *
              (laneIdx.isEven ? 1.0 : -1.0),
          opacity: (0.62 + energy * 0.35).clamp(0.0, 1.0),
        );
      } else {
        canvas.drawCircle(
          gateCenter,
          gateRadius * 0.72,
          Paint()
            ..color = const Color(0xFFE05248).withValues(alpha: 0.65)
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
    // 각 장 코덱스 맵 원화에 직접 그려진 식량창고·황금논밭·외양간 건물 위에 결계 상태 고리와 내구도 배지만 깔끔하게 표시!
    void drawLandmarkStatus({
      required Vec2 anchor,
      required String title,
      required double health,
      required Color okColor,
    }) {
      final ok = health > 0.5;
      final c = Offset(anchor.x, anchor.y);
      final ringCol = ok ? okColor : NightPalette.crimsonMoon;
      canvas.drawCircle(
        c,
        30,
        Paint()
          ..color = ringCol.withValues(alpha: ok ? 0.24 : 0.48)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ok ? 1.8 : 2.6,
      );
      if (!ok) {
        canvas.drawCircle(
          c,
          28,
          Paint()..color = const Color(0x38E63946),
        );
      }
      _paintMiniText(
        canvas,
        '$title ${(health * 100).round()}%',
        c + const Offset(0, 34),
        ringCol,
        11.2,
        withBg: true,
      );
    }

    drawLandmarkStatus(
      anchor: sim.chapter.granaryPos,
      title: '🌾식량',
      health: sim.granaryHealth,
      okColor: NightPalette.accentGold,
    );
    drawLandmarkStatus(
      anchor: sim.chapter.cropsPos,
      title: '🌱논밭',
      health: sim.cropsHealth,
      okColor: const Color(0xFF80ED99),
    );
    drawLandmarkStatus(
      anchor: sim.chapter.livestockPos,
      title: '🐄가축',
      health: sim.livestockHealth,
      okColor: NightPalette.jadeGreen,
    );
  }

  void _drawOuterQiShield(Canvas canvas) {
    final center = Offset(sim.shieldCenter.x, sim.shieldCenter.y);
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
    final center = Offset(sim.towerPos.x, sim.towerPos.y);
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

    // 내공 1칸 이상 충전 시 단전 기운(fx_qi.webp) 소용돌이 광륜 (생사경 4칸까지 부드럽게 증폭!)
    if (sim.qiBars >= 1.0 && sprites.fxQi != null) {
      _drawSpriteCentered(
        canvas,
        sprites.fxQi!,
        center,
        width: r * 2.85,
        height: r * 2.85,
        rotationRad: -sim.elapsedSec * 1.15,
        opacity: (0.18 + 0.12 * sim.qiBars).clamp(0.0, 0.72),
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
      canvas.drawCircle(
        center,
        30.0 + sin(sim.elapsedSec * 4.2) * 2.5,
        Paint()
          ..color = const Color(0x38FFD166)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      _drawSpriteCentered(
        canvas,
        towerImg,
        center + const Offset(0, -4) + recoilOffset,
        width: 68,
        height: 68,
      );
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

    // 동행 수호 영수 & 사부 기명 & 출전 무협 영웅단(최대 3인) 코덱스 4프레임 연속 3D 모션 렌더링!
    final isFiringBurst = sim.centralRecoilAnim > 0.15 || sim.feverTimer > 0;
    final beastStrip = sprites.beastStripOf(sim.preset.equippedBeast);
    final beastImg = sprites.beastOf(sim.preset.equippedBeast);
    if ((beastStrip != null || beastImg != null) &&
        (sim.progress.beastLevels[sim.preset.equippedBeast] ?? 0) > 0) {
      final hoverY = sin(sim.elapsedSec * 3.4) * 3.2;
      final bFrame = isFiringBurst
          ? (sim.centralRecoilAnim > 0.45 ? 2 : 3)
          : ((sim.elapsedSec * 5.0).floor() % 2);
      if (beastStrip != null) {
        _drawStripFrameCentered(
          canvas,
          beastStrip,
          bFrame,
          center + Offset(-50, -24 + hoverY),
          width: 44,
          height: 44,
        );
      } else if (beastImg != null) {
        _drawSpriteCentered(
          canvas,
          beastImg,
          center + Offset(-50, -24 + hoverY),
          width: 38,
          height: 38,
        );
      }
    }

    // 중앙 수호탑 바로 옆 지휘 단상의 사부 기명 4프레임 탄지 신공 액션!
    final sabuStrip = sprites.sabuStrip;
    if (sabuStrip != null) {
      final sabuFrame = sim.centralRecoilAnim > 0.42
          ? 2
          : (sim.centralRecoilAnim > 0.12
              ? 3
              : ((sim.elapsedSec * 3.8).floor() % 2));
      final sabuBob = sin(sim.elapsedSec * 3.2) * 1.8 -
          (sim.centralRecoilAnim > 0.12 ? 3.2 : 0.0);
      _drawStripFrameCentered(
        canvas,
        sabuStrip,
        sabuFrame,
        center + Offset(0, -34 + sabuBob),
        width: 48,
        height: 48,
      );
    }

    final heroOffsets = const <Offset>[
      Offset(-82, 4),
      Offset(82, 4),
      Offset(50, -24),
    ];
    for (int hi = 0;
        hi < sim.preset.companions.length && hi < heroOffsets.length;
        hi++) {
      final hero = sim.preset.companions[hi];
      final hStrip = sprites.heroStripOf(hero);
      final bobY = sin(sim.elapsedSec * 4.0 + hi * 1.4) * 2.4 -
          (isFiringBurst ? 3.8 : 0.0);
      if (hStrip != null) {
        final cycleIdx =
            ((sim.elapsedSec * 4.8 + hi * 1.3).floor()) % 4;
        final hFrame = isFiringBurst
            ? (cycleIdx.isEven ? 2 : 3)
            : (cycleIdx % 2);
        _drawStripFrameCentered(
          canvas,
          hStrip,
          hFrame,
          center + heroOffsets[hi] + Offset(0, bobY),
          width: 56,
          height: 56,
        );
      } else {
        final heroImg = isFiringBurst
            ? (sprites.heroAttackOf(hero) ?? sprites.heroIdleOf(hero))
            : (sprites.heroIdleOf(hero) ?? sprites.heroAttackOf(hero));
        if (heroImg != null) {
          _drawSpriteCentered(
            canvas,
            heroImg,
            center + heroOffsets[hi] + Offset(0, bobY),
            width: 50,
            height: 54,
          );
        }
      }
    }

    // 중앙 탑 바로 아래 직관적인 자동/수동 상태 알약 배지
    _paintMiniText(
      canvas,
      sim.centralManualMode ? '🎯수동 탄지(제한 사거리)' : '⚙️근접 방어(자동)',
      center + const Offset(0, 32),
      sim.centralManualMode ? NightPalette.accentGold : NightPalette.jadeGreen,
      10.2,
      withBg: true,
    );
  }

  /// 전장 핀볼·배율 기물 4종(×2→×3 진화 복제진 · 🎯화력 과녁패 · 심야 화약통 · 황금 보물 도깨비) 렌더링!
  void _drawFieldPinballGimmicks(Canvas canvas) {
    final gate = sim.cloneGate;
    final gateCenter = Offset(gate.center.x, gate.center.y);
    final isTriple = gate.multiplier >= 3;
    final gatePulse = 1.0 + gate.pulseAnim * 0.28 + sin(sim.elapsedSec * (isTriple ? 8.5 : 4.5)) * 0.06;
    final gateCol = isTriple ? const Color(0xFFFF6B35) : const Color(0xFF72EFDD);
    final gateImg = sprites.fxCloneGate;
    if (gateImg != null) {
      _drawSpriteCentered(
        canvas,
        gateImg,
        gateCenter,
        width: gate.radius * (isTriple ? 2.65 : 2.35) * gatePulse,
        height: gate.radius * (isTriple ? 2.65 : 2.35) * gatePulse,
        rotationRad: sim.elapsedSec * (isTriple ? 3.2 : 1.4),
        opacity: 0.95,
        tintColor: isTriple ? const Color(0x66FF6B35) : null,
      );
    } else {
      canvas.drawCircle(
        gateCenter,
        gate.radius * gatePulse,
        Paint()
          ..color = gateCol.withValues(alpha: 0.78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: gateCenter, radius: gate.radius + 4.5),
      -pi / 2,
      2 * pi * gate.chargeRatio,
      false,
      Paint()
        ..color = isTriple ? NightPalette.accentGold : gateCol
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.8,
    );
    _paintMiniText(
      canvas,
      isTriple ? '🔥×3 폭주!' : '×2복제(${gate.passCharge}/10)',
      gateCenter,
      isTriple ? const Color(0xFFFFD166) : NightPalette.accentGold,
      isTriple ? 11.2 : 9.6,
      withBg: true,
    );

    // 🎯 라스트워·핀볼 광고식 이동형 화력 증폭 숫자 과녁패 (+10% ~ +60%)!
    final pt = sim.powerTarget;
    final ptc = Offset(pt.center.x, pt.center.y);
    final ptPulse = 1.0 + pt.pulseAnim * 0.30 + sin(sim.elapsedSec * 5.2) * 0.05;
    final ptActive = pt.powerStacks > 0;
    final ptCol = pt.powerStacks >= 4
        ? const Color(0xFFFF6B35)
        : (ptActive ? NightPalette.accentGold : const Color(0xFF4EA8DE));
    final bannerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ptc, width: 78 * ptPulse, height: 26 * ptPulse),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      bannerRect,
      Paint()..color = const Color(0xDD101B32),
    );
    canvas.drawRRect(
      bannerRect,
      Paint()
        ..color = ptCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = ptActive ? 2.2 : 1.5,
    );
    _paintMiniText(
      canvas,
      ptActive ? '🎯화력 +${pt.bonusPercent}%!' : '🎯과녁 +화력%',
      ptc,
      ptCol,
      10.2,
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
        '👹+34⚡·비급',
        gc + const Offset(0, 24),
        NightPalette.accentGold,
        9.4,
        withBg: true,
      );
    }
  }

  /// 초소 간 진법 시너지 광선 연결 & 각 초소·중앙탑의 실제 제한된 전술 사거리 원 표시!
  void _drawSynergyAndRangeRings(Canvas canvas) {
    final tc = Offset(sim.towerPos.x, sim.towerPos.y);
    if (!sim.centralManualMode) {
      final autoR = sim.effectiveCentralAutoRange;
      canvas.drawCircle(
        tc,
        autoR,
        Paint()
          ..color = NightPalette.jadeShield.withValues(alpha: 0.17)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    } else {
      final manualR = sim.effectiveCentralManualRange;
      if (sim.towerPos.y < 820.0) {
        canvas.drawCircle(
          tc,
          manualR,
          Paint()
            ..color = NightPalette.accentGold.withValues(alpha: 0.34)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: tc, radius: manualR),
          pi * 1.04,
          pi * 0.92,
          false,
          Paint()
            ..color = NightPalette.accentGold.withValues(alpha: 0.34)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
      _paintMiniText(
        canvas,
        sim.towerPos.y < 820.0 ? '🎯360° 수동 유효 사거리' : '🎯수동 유효 사거리 한계',
        tc + Offset(0, sim.towerPos.y < 420.0 ? manualR + 10 : -manualR - 8),
        NightPalette.accentGold,
        9.0,
        withBg: true,
      );
    }

    // 설치된 모든 길목 초소의 실제 유효 사거리 고리 표시 (적이 사거리 안 굽이로 들어오면 밝게 점등!)
    for (final l in sim.launchers) {
      final lc = Offset(l.pos.x, l.pos.y);
      final r = sim.effectiveLauncherRange(l);
      final minR = l.type.minRangePx;
      final col = Color(l.type.colorHex);
      final engaged = sim.mutants.any((m) {
        final d = m.pos.distanceTo(l.pos);
        return d <= r && d >= minR;
      });

      if (engaged) {
        canvas.drawCircle(
          lc,
          r,
          Paint()..color = col.withValues(alpha: 0.045),
        );
      }
      canvas.drawCircle(
        lc,
        r,
        Paint()
          ..color = col.withValues(alpha: engaged ? 0.36 : 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = engaged ? 1.4 : 1.0,
      );
      if (minR > 0) {
        canvas.drawCircle(
          lc,
          minR,
          Paint()
            ..color = const Color(0x55E63946)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }

    if (selectedSlotIndex != null) {
      final slot = sim.mountSlotByIndex(selectedSlotIndex!);
      if (slot != null) {
        final sc = Offset(slot.pos.x, slot.pos.y);
        final built = sim.launcherAtSlot(slot.slotIndex);
        final selR = built != null
            ? sim.effectiveLauncherRange(built)
            : sim.previewSlotRange(slot);
        canvas.drawCircle(
          sc,
          selR,
          Paint()..color = NightPalette.jadeGreen.withValues(alpha: 0.09),
        );
        canvas.drawCircle(
          sc,
          selR,
          Paint()
            ..color = NightPalette.jadeGreen.withValues(alpha: 0.58)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
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

  /// 5종 전략 지형 초소(`🏔️고지망루 · ⛩️협곡관문 · 🏯성루포대 · ☯️기맥영천 · 🗡️측면매복암`) 고유 건축 기단 렌더링!
  void _drawTerrainFoundation(
    Canvas canvas,
    Offset c,
    MountTerrainType terrain, {
    required Color accentColor,
    required bool isLocked,
    required bool isBuilt,
  }) {
    final tCol = isLocked
        ? const Color(0xFF8D99AE)
        : Color(terrain.colorHex);
    // 코덱스 원화에 그려진 실제 원형 석조 포대 좌대가 그대로 비쳐 보이도록 반투명 음각 진법 고리로 일체감 있게 렌더링!
    final fillCol = isLocked ? const Color(0x520A0F1A) : const Color(0x6210192B);

    switch (terrain) {
      case MountTerrainType.highWatchtower:
        // 🏔️ 고지 망루: 원형 석조 좌대에 꼭 맞는 팔각 각인 테두리 + 4귀퉁이 봉화 점
        final outerOct = Path();
        for (int k = 0; k < 8; k++) {
          final a = (pi / 8) + k * (pi / 4);
          final p = c + Offset(cos(a) * 20.5, sin(a) * 20.5);
          if (k == 0) {
            outerOct.moveTo(p.dx, p.dy);
          } else {
            outerOct.lineTo(p.dx, p.dy);
          }
        }
        outerOct.close();
        canvas.drawPath(outerOct, Paint()..color = fillCol);
        canvas.drawPath(
          outerOct,
          Paint()
            ..color = tCol.withValues(alpha: isLocked ? 0.42 : 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.9,
        );
        for (final corner in const [
          Offset(-14, -14),
          Offset(14, -14),
          Offset(-14, 14),
          Offset(14, 14),
        ]) {
          canvas.drawCircle(c + corner, 2.5, Paint()..color = tCol);
        }
        break;

      case MountTerrainType.chokeGate:
        // ⛩️ 협곡 관문: 원형 좌대 위에 꼭 맞게 얹히는 청옥 관문 링 + 좌우 석주 포인트
        canvas.drawCircle(c, 19.5, Paint()..color = fillCol);
        canvas.drawCircle(
          c,
          19.5,
          Paint()
            ..color = tCol.withValues(alpha: isLocked ? 0.42 : 0.86)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.9,
        );
        for (final sideX in const [-18.5, 18.5]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c + Offset(sideX, 0), width: 5.2, height: 18),
              const Radius.circular(2.5),
            ),
            Paint()..color = tCol.withValues(alpha: isLocked ? 0.45 : 0.90),
          );
        }
        break;

      case MountTerrainType.fortressBastion:
        // 🏯 성루 포대: 석조 좌대 반경에 딱 맞춘 치성 원형 보루
        canvas.drawCircle(c, 19.5, Paint()..color = fillCol);
        canvas.drawCircle(
          c,
          19.5,
          Paint()
            ..color = tCol.withValues(alpha: isLocked ? 0.42 : 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        for (final merlon in const [
          Offset(-14.5, -14.5),
          Offset(14.5, -14.5),
          Offset(-14.5, 14.5),
          Offset(14.5, 14.5),
        ]) {
          canvas.drawRect(
            Rect.fromCenter(center: c + merlon, width: 5.8, height: 5.8),
            Paint()..color = tCol.withValues(alpha: isLocked ? 0.42 : 0.88),
          );
        }
        break;

      case MountTerrainType.spiritSpring:
        // ☯️ 기맥 영천: 소용돌이치는 자수정 영천 원형 진법진
        canvas.drawCircle(c, 19.0, Paint()..color = fillCol);
        canvas.drawCircle(
          c,
          19.5,
          Paint()
            ..color = tCol.withValues(alpha: isLocked ? 0.42 : 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.9,
        );
        if (!isLocked) {
          for (int k = 0; k < 3; k++) {
            final a = sim.elapsedSec * 2.1 + k * (2 * pi / 3);
            canvas.drawCircle(
              c + Offset(cos(a) * 19.5, sin(a) * 19.5),
              2.5,
              Paint()..color = tCol,
            );
          }
        }
        break;

      case MountTerrainType.ambushRidge:
        // 🗡️ 측면 매복암: 원형 석조 좌대 안에 꼭 들어맞는 비취 진법 문양
        canvas.drawCircle(c, 19.0, Paint()..color = fillCol);
        final diamond = Path()
          ..moveTo(c.dx, c.dy - 20.5)
          ..lineTo(c.dx + 20.5, c.dy)
          ..lineTo(c.dx, c.dy + 20.5)
          ..lineTo(c.dx - 20.5, c.dy)
          ..close();
        canvas.drawPath(
          diamond,
          Paint()
            ..color = tCol.withValues(alpha: isLocked ? 0.42 : 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.9,
        );
        break;
    }

    if (isBuilt) {
      canvas.drawCircle(
        c,
        18.5,
        Paint()
          ..color = accentColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  /// 개방된 전략 지형 초소(`4곳 → 14곳`) 렌더링:
  /// 5종 지형 고유 건축 기단 + 실시간 기력 게이지 + 지형 배지 표시!
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
        final isRubble = cond.state == PadConditionState.rubbleBlocked;
        final canExcavateNow = isRubble && sim.fieldTokens >= cond.excavationCost;
        final pulse = 1.0 + sin(sim.elapsedSec * 5.6 + slot.slotIndex) * 0.07;

        final Color ringColor = switch (cond.state) {
          PadConditionState.readyFullBuild => const Color(0xFF80ED99),
          PadConditionState.readyLuckyOnly => NightPalette.accentGold,
          PadConditionState.rubbleBlocked =>
            canExcavateNow ? const Color(0xFFFFD166) : const Color(0xFFC77DFF),
          PadConditionState.chargingQi => NightPalette.jadeShield,
          PadConditionState.waveLocked => const Color(0xFF8D99AE),
          PadConditionState.built => NightPalette.jadeGreen,
        };

        if (isReady || canExcavateNow || isRecommended) {
          canvas.drawCircle(
            c,
            28.5 * pulse,
            Paint()
              ..color = ringColor.withValues(alpha: (isReady || canExcavateNow) ? 0.44 : 0.22)
              ..style = PaintingStyle.stroke
              ..strokeWidth = (isReady || canExcavateNow) ? 2.8 : 1.6,
          );
        }

        _drawTerrainFoundation(
          canvas,
          c,
          slot.terrainType,
          accentColor: ringColor,
          isLocked: isLocked,
          isBuilt: false,
        );

        if (!isLocked) {
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: 25.5),
            -pi / 2,
            2 * pi * cond.chargeRatio.clamp(0.0, 1.0),
            false,
            Paint()
              ..color = ringColor
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = 3.0,
          );
        }

        if (isLocked) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c + const Offset(0, 2), width: 11, height: 9),
              const Radius.circular(2),
            ),
            Paint()..color = const Color(0xFFADB5BD),
          );
          canvas.drawArc(
            Rect.fromCenter(center: c + const Offset(0, -2), width: 8, height: 8),
            pi,
            pi,
            false,
            Paint()
              ..color = const Color(0xFFADB5BD)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        } else if (isRubble) {
          // 🪨 마기 암석 잔해 봉인 시각 연출 (자수정 마기 결정 바위 덩어리!)
          final rockPath = Path()
            ..moveTo(c.dx - 11, c.dy + 7)
            ..lineTo(c.dx - 8, c.dy - 6)
            ..lineTo(c.dx - 1, c.dy - 11)
            ..lineTo(c.dx + 8, c.dy - 5)
            ..lineTo(c.dx + 11, c.dy + 7)
            ..close();
          canvas.drawPath(rockPath, Paint()..color = const Color(0xEE2B193D));
          canvas.drawPath(
            rockPath,
            Paint()
              ..color = ringColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
          canvas.drawLine(
            c + const Offset(-4, -3),
            c + const Offset(3, 4),
            Paint()
              ..color = const Color(0xFFFFD166)
              ..strokeWidth = 1.5,
          );
        } else {
          final plusPaint = Paint()
            ..color = ringColor
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(c + const Offset(-6.5, 0), c + const Offset(6.5, 0), plusPaint);
          canvas.drawLine(c + const Offset(0, -6.5), c + const Offset(0, 6.5), plusPaint);
        }

        _paintMiniText(
          canvas,
          slot.terrainType.shortBadge,
          c + const Offset(0, -25.5),
          isLocked ? const Color(0xFFADB5BD) : Color(slot.terrainType.colorHex),
          9.2,
          withBg: true,
        );
        _paintMiniText(
          canvas,
          cond.shortBadge,
          c + const Offset(0, 25.5),
          ringColor,
          9.4,
          withBg: true,
        );
        continue;
      }

      final l = built;
      final baseColor = Color(l.type.colorHex);
      final canUpgrade = !l.isConstructing &&
          l.tier < 4 &&
          sim.fieldTokens >= l.type.inBattleUpgradeCost(l.tier);
      final canMerge = sim.findMergePartnerSlot(l.slotIndex) != null &&
          sim.fieldTokens >= sim.mergeCostForSlot(l.slotIndex);

      _drawTerrainFoundation(
        canvas,
        c,
        l.terrainType,
        accentColor: l.isCorrupted
            ? const Color(0xFFC77DFF)
            : (l.tier >= 4
                ? NightPalette.accentGold
                : (canMerge
                    ? NightPalette.accentGold
                    : (canUpgrade ? NightPalette.jadeGreen : baseColor))),
        isLocked: false,
        isBuilt: true,
      );

      // 🔨 실시간 축조·단조 공정 원형 게이지!
      if (l.isConstructing) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: 26.5),
          -pi / 2,
          2 * pi * l.constructProgress,
          false,
          Paint()
            ..color = NightPalette.accentGold
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3.4,
        );
      }

      // 🕸️ 마기 침식 거미줄 사슬 / ✨ 정화 각성 광륜!
      if (l.isCorrupted) {
        final webPulse = 1.0 + sin(sim.elapsedSec * 9.0) * 0.09;
        canvas.drawCircle(
          c,
          27.0 * webPulse,
          Paint()
            ..color = const Color(0xAAC77DFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
        for (int w = 0; w < 4; w++) {
          final a = w * pi / 4 + sim.elapsedSec * 0.8;
          canvas.drawLine(
            c + Offset(cos(a) * -22, sin(a) * -22),
            c + Offset(cos(a) * 22, sin(a) * 22),
            Paint()
              ..color = const Color(0x99C77DFF)
              ..strokeWidth = 1.4,
          );
        }
      } else if (l.purifiedBoostTimer > 0) {
        canvas.drawCircle(
          c,
          26.5,
          Paint()
            ..color = const Color(0xAA72EFDD)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }

      if (l.tier >= 5 && sprites.fxFeverAura != null) {
        _drawSpriteCentered(
          canvas,
          sprites.fxFeverAura!,
          c,
          width: 66,
          height: 66,
          rotationRad: -sim.elapsedSec * 1.6,
          opacity: 0.65,
        );
      } else if (l.type == LauncherType.qiAmplifier && sprites.fxQi != null) {
        _drawSpriteCentered(
          canvas,
          sprites.fxQi!,
          c,
          width: 54,
          height: 54,
          rotationRad: sim.elapsedSec * 0.9,
          opacity: 0.30,
        );
      }

      // 발사대 5계통 고유 내공 오라 연출 (청옥 연노·흑철 용두화포·비취 쌍륜·만년빙 수정·팔괘 뇌전루)
      switch (l.type) {
        case LauncherType.rapid:
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: 22.5),
            sim.elapsedSec * 4.5,
            pi * 1.25,
            false,
            Paint()
              ..color = const Color(0x884EA8DE)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
          break;
        case LauncherType.heavy:
          canvas.drawCircle(
            c,
            23.0 + sin(sim.elapsedSec * 6.0) * 1.6,
            Paint()
              ..color = const Color(0x44FF6B35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          break;
        case LauncherType.curveSpin:
          for (int k = 0; k < 2; k++) {
            canvas.drawArc(
              Rect.fromCircle(center: c, radius: 23.5),
              sim.elapsedSec * 5.6 + k * pi,
              pi * 0.65,
              false,
              Paint()
                ..color = const Color(0xAA72EFDD)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.2,
            );
          }
          break;
        case LauncherType.frostField:
          for (int k = 0; k < 6; k++) {
            final a = sim.elapsedSec * 1.4 + k * (pi / 3);
            canvas.drawCircle(
              c + Offset(cos(a) * 22.0, sin(a) * 22.0),
              2.2,
              Paint()..color = const Color(0xCCCAF0F8),
            );
          }
          break;
        case LauncherType.qiAmplifier:
          canvas.drawCircle(
            c,
            24.0 + sin(sim.elapsedSec * 5.0) * 1.8,
            Paint()
              ..color = const Color(0x99C77DFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.9,
          );
          break;
      }

      final launcherImg = sprites.launcherOf(l.type);
      if (launcherImg != null) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(l.aimAngleRad);
        final aimTip = Path()
          ..moveTo(28.5, 0)
          ..lineTo(20.5, -5.0)
          ..lineTo(20.5, 5.0)
          ..close();
        canvas.drawPath(aimTip, Paint()..color = baseColor);
        canvas.restore();

        final recoilShift = Offset(
          cos(l.aimAngleRad) * (-l.recoilAnim * 5.2),
          sin(l.aimAngleRad) * (-l.recoilAnim * 5.2),
        );
        final scale = (1.0 + (l.tier - 1) * 0.04) + l.recoilAnim * 0.12;
        _drawSpriteCentered(
          canvas,
          launcherImg,
          c + const Offset(0, -3.0) + recoilShift,
          width: 54 * scale,
          height: 54 * scale,
        );
      } else {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(l.aimAngleRad);
        final recoilOffset = -l.recoilAnim * 4.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(recoilOffset, -4.5, 21, 9.5),
            const Radius.circular(3),
          ),
          Paint()..color = baseColor,
        );
        canvas.restore();
        canvas.drawCircle(c, 9, Paint()..color = baseColor.withValues(alpha: 0.9));
      }

      if (l.isCorrupted) {
        _paintMiniText(
          canvas,
          '🕸️터치정화!',
          c + const Offset(0, -29),
          const Color(0xFFE0AAFF),
          10.2,
          withBg: true,
        );
      } else if (l.isConstructing) {
        _paintMiniText(
          canvas,
          '🔨축조 ${(l.constructProgress * 100).round()}%',
          c + const Offset(0, -29),
          NightPalette.accentGold,
          9.6,
          withBg: true,
        );
      } else if (canMerge) {
        _paintMiniText(
          canvas,
          '☯연성(${sim.mergeCostForSlot(l.slotIndex)}⚡)',
          c + const Offset(0, -29),
          NightPalette.accentGold,
          9.6,
          withBg: true,
        );
      } else {
        _paintMiniText(
          canvas,
          l.terrainType.shortBadge,
          c + const Offset(0, -29),
          Color(l.terrainType.colorHex),
          9.0,
          withBg: true,
        );
      }

      _paintMiniText(
        canvas,
        l.tier >= 5 ? '★5신기' : (canUpgrade ? '${l.tier}형▲' : '${l.tier}형'),
        c + const Offset(0, 28),
        l.tier >= 5
            ? const Color(0xFFFF6B35)
            : (canUpgrade ? NightPalette.jadeGreen : NightPalette.accentGold),
        l.tier >= 5 ? 11.2 : 10.4,
        withBg: true,
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

  void _drawMutantFootPivotedStripFrame(
    Canvas canvas,
    ui.Image stripImage,
    int frameIndex,
    Offset center, {
    required double width,
    required double height,
    required double scaleX,
    required double scaleY,
    required double tiltRad,
    int totalFrames = 4,
    double opacity = 1.0,
    Color? tintColor,
    BlendMode tintBlendMode = BlendMode.srcATop,
  }) {
    final alpha = opacity.clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    final safeIdx = ((frameIndex % totalFrames) + totalFrames) % totalFrames;
    final cellW = stripImage.width.toDouble() / totalFrames;
    final cellH = stripImage.height.toDouble();
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

    final src = Rect.fromLTWH(safeIdx * cellW, 0, cellW, cellH);
    final dst = Rect.fromCenter(
      center: Offset(0, -footAnchorY),
      width: width,
      height: height,
    );
    canvas.drawImageRect(stripImage, src, dst, paint);
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

      // 640×1080 광각 전장 시인성 비율(×1.16) + 재변이 체급 팽창(×1.18~×1.32) 적용!
      final visualH = m.kind.visualDiameter * emergeScale * m.mutationScale * 1.16;
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

      // 1) 체급에 비례하는 발밑 타원 접지 그림자 (비행 변이는 지상 아래 멀찍이 고도차 그림자로 표현!)
      final shadowDropY = m.kind.isFlying ? halfVisualH * 0.96 + 18.0 : halfVisualH * 0.64;
      final shadowW = visualW * (m.kind.isFlying ? 0.62 : 0.82) * motion.shadowScale;
      final shadowH = visualH * (m.kind.isFlying ? 0.22 : 0.30) * motion.shadowScale;
      canvas.drawOval(
        Rect.fromCenter(
          center: groundCenter + Offset(0, shadowDropY),
          width: shadowW,
          height: shadowH,
        ),
        Paint()
          ..color = Colors.black.withValues(
            alpha: m.kind.isFlying ? motion.shadowAlpha * 0.68 : motion.shadowAlpha,
          ),
      );

      // 1-B) 길 밖 비정규 침투 괴물(월담·땅굴·공중강습) 전용 붉은 침투 경보 점선 & 분출 파문!
      if (m.isInfiltrator) {
        if (m.emergeAnimTimer > 0 && !m.kind.isFlying) {
          final ep = (1.0 - m.emergeAnimTimer / 0.85).clamp(0.0, 1.0);
          canvas.drawOval(
            Rect.fromCenter(
              center: groundCenter,
              width: (18.0 + ep * 26.0),
              height: (9.0 + ep * 13.0),
            ),
            Paint()
              ..color = const Color(0xFFFF6B35).withValues(alpha: (1.0 - ep) * 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
        }
        final targetVillage = Offset(
          sim.towerPos.x,
          sim.towerPos.y,
        );
        final vec = targetVillage - c;
        final distV = vec.distance;
        if (distV > 28.0) {
          final dirV = vec / distV;
          final maxDash = min(75.0, distV - 18.0);
          for (double d = 10.0; d < maxDash; d += 12.0) {
            final p1 = c + dirV * d;
            final p2 = c + dirV * min(d + 6.0, maxDash);
            canvas.drawLine(
              p1,
              p2,
              Paint()
                ..color = const Color(0xCCFF4D6D)
                ..strokeWidth = 1.6
                ..strokeCap = StrokeCap.round,
            );
          }
        }
        final raidLabel = m.infiltratorStyle == 'air'
            ? '🪽공중강습'
            : (m.infiltratorStyle == 'tunnel' ? '🕳️땅굴기습' : '🌲월담기습');
        _paintMiniText(
          canvas,
          raidLabel,
          bodyCenter + Offset(0, -halfVisualH * 0.92 - 12),
          const Color(0xFFFF4D6D),
          8.6,
          withBg: true,
        );
      } else if (m.kind.isFlying && !m.kind.isBoss) {
        _paintMiniText(
          canvas,
          '🪽공중비행',
          bodyCenter + Offset(0, -halfVisualH * 0.90 - 9),
          const Color(0xFF90E0EF),
          8.2,
          withBg: true,
        );
      }

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

      // 5) 코덱스 4프레임 캐릭터·돌연변이 시트 & 3페이즈 보스 실시간 외형 변이 렌더링!
      final mutStrip = sprites.mutantStripOf(m.kind);
      final baseSprite = sprites.mutantOf(m.kind);
      final atkSprite = sprites.mutantAttackOf(m.kind);

      Color? hitOrFreezeTint;
      if (m.hitFlashTimer > 0) {
        final flashA = (m.hitFlashTimer / 0.12).clamp(0.0, 0.72);
        hitOrFreezeTint = Colors.white.withValues(alpha: flashA);
      } else if (m.freezeTimer > 0) {
        hitOrFreezeTint = const Color(0x6690E0EF);
      } else if (m.phaseTransitionTimer > 0) {
        // 보스 페이즈 변이 탈피 중 황금·진홍 번쩍임 연출!
        final blink = (sin(sim.elapsedSec * 28.0) * 0.5 + 0.5) * 0.65;
        hitOrFreezeTint = const Color(0xFFFF6B35).withValues(alpha: blink);
      }

      if (mutStrip != null) {
        int primaryFrame;
        if (m.kind.isBoss) {
          // 보스 4프레임 시트: 0=1페이즈 강림, 1=2페이즈 변이 각성, 2=3페이즈 심연 폭주, 3=파성 필살 강타!
          final phaseFrame = (m.currentPhase - 1).clamp(0, 2);
          primaryFrame = motion.attackBlend >= 0.52 ? 3 : phaseFrame;
        } else {
          // 일반 변이 4프레임 연속 보행·도약·강타 사이클(0 -> 1 -> 2 -> 1, 공격 시 3)
          const walkCycle = <int>[0, 1, 2, 1];
          final stepIdx =
              (((m.animPhase * 1.45 + m.uid * 0.7).abs()).floor()) % 4;
          primaryFrame = motion.attackBlend >= 0.55 ? 3 : walkCycle[stepIdx];
        }

        if (motion.afterimageCount > 0 && m.freezeTimer <= 0) {
          for (int k = motion.afterimageCount; k >= 1; k--) {
            final ghostPos = bodyCenter - headingDir * (6.8 * k);
            _drawMutantFootPivotedStripFrame(
              canvas,
              mutStrip,
              primaryFrame,
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

        _drawMutantFootPivotedStripFrame(
          canvas,
          mutStrip,
          primaryFrame,
          bodyCenter,
          width: visualW,
          height: visualH,
          scaleX: motion.scaleX,
          scaleY: motion.scaleY,
          tiltRad: motion.tiltRad,
          tintColor: hitOrFreezeTint,
        );
      } else if (baseSprite != null || atkSprite != null) {
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

      // 7-B) ★ 두목 2차 재변이 & 대수괴 3페이즈 외각 장갑판(🛡️) · 무방비(💥) · 회전 약점 과녁(🎯) 렌더링!
      if (m.totalPhases > 1) {
        if (m.phaseTransitionTimer > 0) {
          final pulseR = halfVisualH * (0.75 + sin(sim.elapsedSec * 24).abs() * 0.35);
          canvas.drawCircle(
            bodyCenter,
            pulseR,
            Paint()
              ..color = const Color(0xAAFF006E)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.2,
          );
          _paintMiniText(
            canvas,
            '⚡재변이 각성 중!!',
            bodyCenter + Offset(0, -halfVisualH - 28),
            const Color(0xFFFFD166),
            12.2,
            withBg: true,
          );
        } else {
          if (m.carapacePlatesLeft > 0 && m.maxCarapacePlates > 0) {
            final armorR = halfVisualH * 0.64 + 8.0;
            final segSweep = (2 * pi / m.maxCarapacePlates) - 0.24;
            for (int s = 0; s < m.maxCarapacePlates; s++) {
              final intact = s < m.carapacePlatesLeft;
              final startA = sim.elapsedSec * 0.85 + s * (2 * pi / m.maxCarapacePlates);
              canvas.drawArc(
                Rect.fromCircle(center: bodyCenter, radius: armorR),
                startA,
                segSweep,
                false,
                Paint()
                  ..color = intact
                      ? (m.currentPhase >= 3
                          ? const Color(0xEEFF006E)
                          : const Color(0xEEC77DFF))
                      : const Color(0x33ADB5BD)
                  ..style = PaintingStyle.stroke
                  ..strokeCap = StrokeCap.round
                  ..strokeWidth = intact ? 4.6 : 1.6,
              );
            }
          }

          if (m.hasActiveWeakPoint) {
            // 빛나는 회전 정밀 타격 과녁(🎯 약점 — 장갑판 또는 타수 마갑 활성 시 상시 표시!)
            final wp = Offset(m.weakSpotWorldPos.x, m.weakSpotWorldPos.y);
            final wpPulse = 1.0 + sin(sim.elapsedSec * 10.5) * 0.16;
            final retR = 14.5 * wpPulse;
            canvas.drawCircle(
              wp,
              retR + 4,
              Paint()..color = const Color(0x44FFD166),
            );
            canvas.drawCircle(
              wp,
              retR,
              Paint()
                ..color = const Color(0xFFFFD166)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.6,
            );
            canvas.drawCircle(
              wp,
              4.5,
              Paint()..color = const Color(0xFFFF0054),
            );
            for (int k = 0; k < 4; k++) {
              final a = k * (pi / 2);
              canvas.drawLine(
                wp + Offset(cos(a) * (retR - 4), sin(a) * (retR - 4)),
                wp + Offset(cos(a) * (retR + 5), sin(a) * (retR + 5)),
                Paint()
                  ..color = const Color(0xFFFFD166)
                  ..strokeWidth = 2.2
                  ..strokeCap = StrokeCap.round,
              );
            }
            _paintMiniText(
              canvas,
              '🎯약점',
              wp + const Offset(0, -20),
              const Color(0xFFFFD166),
              9.8,
              withBg: true,
            );
          }

          if (m.groggyExposeTimer > 0) {
            canvas.drawCircle(
              bodyCenter,
              halfVisualH * 0.68 + 6,
              Paint()
                ..color = const Color(0xAAFFD166)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.8,
            );
            _paintMiniText(
              canvas,
              '💥무방비 ×1.85!',
              bodyCenter + Offset(0, halfVisualH * 0.68 + 14),
              const Color(0xFFFFD166),
              10.4,
              withBg: true,
            );
          }
        }
      }

      // 8) 체급별 맞춤 체력 막대 + 다단 페이즈 보석(◆◆◆) 표시!
      final denomHp = m.totalPhases > 1 ? m.currentMaxHp : m.maxHp;
      final hpRatio = denomHp > 0 ? (m.hp / denomHp).clamp(0.0, 1.0) : 0.0;
      final showBar =
          m.kind.isBoss || m.kind.visualDiameter >= 32.0 || hpRatio < 0.995;
      if (showBar) {
        final barW = (visualW * 0.78).clamp(20.0, 104.0);
        final barH = m.kind.isBoss ? 7.0 : (m.kind.visualDiameter >= 50 ? 5.2 : 4.0);
        final barCenter = bodyCenter + Offset(0, -halfVisualH * 0.88 - 7);
        final barRect = Rect.fromCenter(
          center: barCenter,
          width: barW,
          height: barH,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(3.0)),
          Paint()..color = const Color(0xCC050811),
        );
        final fillColor = m.kind.isBoss
            ? (m.currentPhase >= 3
                ? const Color(0xFFFF006E)
                : (m.currentPhase == 2
                    ? const Color(0xFFC77DFF)
                    : (m.kind.isMidBoss
                        ? const Color(0xFFFF9F1C)
                        : const Color(0xFFFF4D6D))))
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
            const Radius.circular(3.0),
          ),
          Paint()..color = fillColor,
        );
        if (m.kind.isBoss) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(barRect, const Radius.circular(3.0)),
            Paint()
              ..color = NightPalette.accentGold.withValues(alpha: 0.90)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
          final remPhases = (m.totalPhases - m.currentPhase + 1).clamp(1, 3);
          final gems = m.totalPhases > 1
              ? ' ${'◆' * remPhases}${'◇' * (m.totalPhases - remPhases)}'
              : '';
          double labelOffsetY = -12.5;
          if (m.maxHitShield > 0) {
            final shieldRatio =
                (m.hitShieldLeft / m.maxHitShield).clamp(0.0, 1.0);
            final shieldRect = Rect.fromCenter(
              center: barCenter + const Offset(0, -7.2),
              width: barW,
              height: 4.4,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(shieldRect, const Radius.circular(2.2)),
              Paint()..color = const Color(0xDD0B1324),
            );
            if (shieldRatio > 0) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(
                    shieldRect.left,
                    shieldRect.top,
                    barW * shieldRatio,
                    shieldRect.height,
                  ),
                  const Radius.circular(2.2),
                ),
                Paint()..color = const Color(0xFF48CAE4),
              );
            }
            final hitBadge = m.hitShieldLeft > 0
                ? '🛡️${m.hitShieldLeft}/${m.maxHitShield}타 · 🔥${m.totalHitsTaken}HIT'
                : '💥마갑파쇄 완료 · 🔥${m.totalHitsTaken}HIT!';
            _paintMiniText(
              canvas,
              hitBadge,
              barCenter + const Offset(0, -17.5),
              m.hitShieldLeft > 0
                  ? const Color(0xFF90E0EF)
                  : const Color(0xFFFFD166),
              9.0,
              withBg: true,
            );
            labelOffsetY = -30.5;
          }
          final flyPrefix = m.kind.isFlying ? '🪽' : '';
          _paintMiniText(
            canvas,
            '$flyPrefix[${m.hierarchyRank}] ${m.displayName}$gems',
            barCenter + Offset(0, labelOffsetY),
            m.currentPhase >= 2 ? const Color(0xFFFFD166) : NightPalette.accentGold,
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
      final style = p.projectileStyle;
      final heading = atan2(p.vel.y, p.vel.x);

      // 1) 발사대 계통별 완전히 다른 내공 궤적(Trail) 렌더링!
      if (p.trail.length >= 2) {
        for (int i = 1; i < p.trail.length; i++) {
          final tRatio = i / p.trail.length;
          final aPt = Offset(p.trail[i - 1].x, p.trail[i - 1].y);
          final bPt = Offset(p.trail[i].x, p.trail[i].y);
          final isHeavy = style == 'heavyMeteor' || style == 'sectFist';
          final isBlade = style == 'curveChakram' || style == 'sectSword';
          final trailW = p.radius *
              (p.isPrecisionShot
                  ? (0.85 + 1.35 * tRatio)
                  : (isHeavy
                      ? (0.75 + 1.25 * tRatio)
                      : (isBlade ? (0.65 + 1.15 * tRatio) : (0.45 + 0.92 * tRatio))));
          canvas.drawLine(
            aPt,
            bPt,
            Paint()
              ..color = col.withValues(alpha: (p.isPrecisionShot ? 0.90 : 0.66) * tRatio)
              ..strokeWidth = trailW
              ..strokeCap = StrokeCap.round,
          );
          if (p.isPrecisionShot || i >= p.trail.length - 3) {
            canvas.drawLine(
              aPt,
              bPt,
              Paint()
                ..color = Colors.white.withValues(alpha: (p.isPrecisionShot ? 0.95 : 0.72) * tRatio)
                ..strokeWidth = trailW * 0.42
                ..strokeCap = StrokeCap.round,
            );
          }
          // 중포 운석 불티 · 한빙 설화 눈꽃 입자 잔상!
          if (style == 'heavyMeteor' && i.isEven) {
            canvas.drawCircle(
              bPt,
              p.radius * 0.34 * tRatio,
              Paint()..color = const Color(0xAAFFD166).withValues(alpha: 0.55 * tRatio),
            );
          } else if (style == 'frostCrystal' && i.isOdd) {
            canvas.drawCircle(
              bPt,
              2.2 * tRatio,
              Paint()..color = const Color(0xDDCAF0F8).withValues(alpha: 0.75 * tRatio),
            );
          }
        }
      }

      final c = Offset(p.pos.x, p.pos.y);
      if (p.isPrecisionShot || style == 'eogiUltimate') {
        canvas.drawCircle(
          c,
          p.radius * 2.0,
          Paint()
            ..color = const Color(0x99FFD166)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      } else if (p.isGiantCritSerendipity) {
        if (sprites.fxLucky != null) {
          _drawSpriteCentered(
            canvas,
            sprites.fxLucky!,
            c,
            width: p.radius * 3.2,
            height: p.radius * 3.2,
            rotationRad: sim.elapsedSec * 4.5,
            opacity: 0.78,
          );
        }
      }

      // 2) 발사대·비기 종류별 완전히 차별화된 투사체(돌·화살·화염철환·비취쌍륜·만년빙·팔괘뇌구·검기) 외형 렌더링!
      switch (style) {
        case 'rapidBolt':
        case 'precisionLance':
          // 청옥 연노 천기탑 / 정밀 신궁탄: 초음속 파공 비전창 + 마하 충격파 날개!
          final isGoldLance = style == 'precisionLance';
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(heading);
          final len = p.radius * (isGoldLance ? 2.7 : 2.25);
          final wid = p.radius * (isGoldLance ? 0.92 : 0.74);
          final spear = Path()
            ..moveTo(len, 0)
            ..lineTo(-len * 0.55, -wid)
            ..lineTo(-len * 0.25, 0)
            ..lineTo(-len * 0.55, wid)
            ..close();
          canvas.drawPath(
            spear,
            Paint()..color = isGoldLance ? const Color(0xFFFFD166) : const Color(0xFF4CC9F0),
          );
          canvas.drawLine(
            Offset(-len * 0.35, 0),
            Offset(len * 0.88, 0),
            Paint()
              ..color = Colors.white
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round,
          );
          canvas.restore();
          break;

        case 'heavyMeteor':
        case 'sectFist':
          // 흑철 용두 파성루 / 금강 철권: 용암 화염 오라를 두른 거대 파성 운석 철환!
          canvas.drawCircle(
            c,
            p.radius * 1.55,
            Paint()
              ..color = const Color(0x88FF4D00)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          final stoneImg = sprites.stoneOf(p.material);
          if (stoneImg != null) {
            _drawSpriteCentered(
              canvas,
              stoneImg,
              c,
              width: p.radius * 2.65,
              height: p.radius * 2.65,
              rotationRad: sim.elapsedSec * 6.0,
            );
          } else {
            canvas.drawCircle(c, p.radius * 1.15, Paint()..color = const Color(0xFF3D1E10));
          }
          canvas.drawCircle(
            c,
            p.radius * 0.98,
            Paint()
              ..color = const Color(0xDDFF9F1C)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2,
          );
          break;

        case 'curveChakram':
        case 'sectSword':
          // 비취 쌍륜 진법대 / 화산 검기: 고속 자전하는 초승달 비취 풍륜도 & 반월 검기파!
          final spin = style == 'sectSword' ? heading : sim.elapsedSec * 16.0 + p.pos.x * 0.05;
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(spin);
          final bladeR = p.radius * (style == 'sectSword' ? 1.85 : 1.52);
          for (int b = 0; b < (style == 'sectSword' ? 1 : 2); b++) {
            canvas.save();
            canvas.rotate(b * pi);
            canvas.drawArc(
              Rect.fromCircle(center: Offset.zero, radius: bladeR),
              -pi * 0.42,
              pi * 0.84,
              false,
              Paint()
                ..color = style == 'sectSword' ? const Color(0xFF4CC9F0) : const Color(0xFF72EFDD)
                ..style = PaintingStyle.stroke
                ..strokeCap = StrokeCap.round
                ..strokeWidth = 3.8,
            );
            canvas.drawArc(
              Rect.fromCircle(center: Offset.zero, radius: bladeR * 0.88),
              -pi * 0.34,
              pi * 0.68,
              false,
              Paint()
                ..color = Colors.white
                ..style = PaintingStyle.stroke
                ..strokeCap = StrokeCap.round
                ..strokeWidth = 1.6,
            );
            canvas.restore();
          }
          canvas.drawCircle(Offset.zero, p.radius * 0.48, Paint()..color = const Color(0xFF80ED99));
          canvas.restore();
          break;

        case 'frostCrystal':
          // 만년빙 수정탑: 반투명 육각 설화 프리즘 결정탄!
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(sim.elapsedSec * 5.0);
          final rIce = p.radius * 1.48;
          for (int k = 0; k < 3; k++) {
            final a = k * (pi / 3);
            canvas.drawLine(
              Offset(cos(a) * -rIce, sin(a) * -rIce),
              Offset(cos(a) * rIce, sin(a) * rIce),
              Paint()
                ..color = const Color(0xFF90E0EF)
                ..strokeWidth = 2.6
                ..strokeCap = StrokeCap.round,
            );
          }
          canvas.drawCircle(Offset.zero, p.radius * 0.62, Paint()..color = Colors.white);
          canvas.restore();
          break;

        case 'qiBagua':
        case 'sectTaiji':
        case 'eogiUltimate':
          // 팔괘 증폭루 / 태극 유수 / 어기어석: 번개가 감기는 황금·자색 음양 내공구!
          final orbCol = style == 'eogiUltimate'
              ? const Color(0xFFFFD166)
              : const Color(0xFFC77DFF);
          canvas.drawCircle(
            c,
            p.radius * 1.55,
            Paint()
              ..color = orbCol.withValues(alpha: 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
          canvas.drawCircle(c, p.radius * 0.96, Paint()..color = orbCol);
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: p.radius * 1.28),
            sim.elapsedSec * 10.0,
            pi * 1.3,
            false,
            Paint()
              ..color = const Color(0xFFFFD166)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
          canvas.drawCircle(c, p.radius * 0.42, Paint()..color = Colors.white);
          break;

        default:
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
          break;
      }
    }
  }

  /// 치명타(회심)·중포 운석·한빙 설화·팔괘 공명·문파 절기 발동 시 강렬한 다중 충격파 & 십자 스타버스트 연출!
  void _drawShockwaveRingsAndCritImpacts(Canvas canvas) {
    for (final sw in sim.shockwaveRings) {
      final prog = sw.progress;
      final alpha = (1.0 - prog).clamp(0.0, 1.0);
      final c = Offset(sw.pos.x, sw.pos.y);
      final curR = sw.maxRadius * (0.18 + prog * 0.82);
      final mainCol = Color(sw.colorHex).withValues(alpha: alpha);
      final subCol = Color(sw.secondaryColorHex).withValues(alpha: alpha * 0.92);

      // 외곽 주 충격파 고리 + 내부 공명 고리
      canvas.drawCircle(
        c,
        curR,
        Paint()
          ..color = mainCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = (sw.style == 'skillUltimate' ? 5.2 : 3.6) * (1.0 - prog * 0.45),
      );
      canvas.drawCircle(
        c,
        curR * 0.66,
        Paint()
          ..color = subCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - prog * 0.4),
      );

      if (sw.style == 'critStar' || sw.style == 'skillUltimate') {
        // 8방향 예리한 황금·진홍 회심 십자 스타버스트 섬광!
        final spikes = sw.style == 'skillUltimate' ? 12 : 8;
        for (int k = 0; k < spikes; k++) {
          final a = k * (2 * pi / spikes) + prog * 0.35;
          final innerD = curR * 0.16;
          final outerD = curR * (k.isEven ? 1.24 : 0.84);
          canvas.drawLine(
            c + Offset(cos(a) * innerD, sin(a) * innerD),
            c + Offset(cos(a) * outerD, sin(a) * outerD),
            Paint()
              ..color = k.isEven ? mainCol : Colors.white.withValues(alpha: alpha)
              ..strokeWidth = k.isEven ? 2.8 : 1.7
              ..strokeCap = StrokeCap.round,
          );
        }
      } else if (sw.style == 'heavyCrater') {
        // 중포·화구 용암 방사형 균열!
        for (int k = 0; k < 6; k++) {
          final a = k * (pi / 3) + 0.25;
          canvas.drawLine(
            c + Offset(cos(a) * (curR * 0.25), sin(a) * (curR * 0.25)),
            c + Offset(cos(a) * (curR * 1.05), sin(a) * (curR * 1.05)),
            Paint()
              ..color = subCol
              ..strokeWidth = 2.6
              ..strokeCap = StrokeCap.round,
          );
        }
      } else if (sw.style == 'frostNova') {
        // 육각 얼음꽃 결정 파열!
        for (int k = 0; k < 6; k++) {
          final a = k * (pi / 3);
          final tip = c + Offset(cos(a) * curR, sin(a) * curR);
          canvas.drawCircle(tip, 3.0 * alpha, Paint()..color = Colors.white.withValues(alpha: alpha));
        }
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
    for (int i = 0; i < 9; i++) {
      final sx = 48.0 + i * 68.0;
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

  /// 포탑·중앙 수호탑 발사 순간 시원하게 뿜어지는 포구 화염 섬광(MuzzleFlashFx) 연출!
  void _drawMuzzleFlashes(Canvas canvas) {
    for (final mf in sim.muzzleFlashes) {
      final prog = mf.progress;
      final alpha = (1.0 - prog).clamp(0.0, 1.0);
      final col = Color(mf.colorHex);
      canvas.save();
      canvas.translate(mf.pos.x, mf.pos.y);
      canvas.rotate(mf.angleRad);

      final len = (20.0 + prog * 14.0) * mf.scale;
      final wid = (9.5 - prog * 3.0) * mf.scale;
      final cone = Path()
        ..moveTo(-2, -wid * 0.45)
        ..lineTo(len, 0)
        ..lineTo(-2, wid * 0.45)
        ..close();
      canvas.drawPath(
        cone,
        Paint()..color = col.withValues(alpha: alpha * 0.72),
      );
      final inner = Path()
        ..moveTo(0, -wid * 0.22)
        ..lineTo(len * 0.68, 0)
        ..lineTo(0, wid * 0.22)
        ..close();
      canvas.drawPath(
        inner,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.88),
      );
      for (final sparkA in const [-0.42, -0.18, 0.18, 0.42]) {
        final d = len * (0.55 + prog * 0.45);
        canvas.drawLine(
          Offset.zero,
          Offset(cos(sparkA) * d, sin(sparkA) * d),
          Paint()
            ..color = NightPalette.accentGold.withValues(alpha: alpha * 0.85)
            ..strokeWidth = 1.6 * mf.scale
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }
  }

  /// 돌연변이·괴물이 총탄과 포격에 맞아 죽을 때 회전하며 뒤로 튕겨 나가 산산조각 터지는 랙돌 연출!
  void _drawDeathRagdollsAndShards(Canvas canvas) {
    for (final r in sim.deathRagdolls) {
      final prog = r.progress;
      final alpha = (1.0 - prog * 0.92).clamp(0.0, 1.0);
      final c = Offset(r.pos.x, r.pos.y);
      final shrink = (1.08 - prog * 0.52).clamp(0.35, 1.15);
      final w = r.visualDiameter * r.bodyWidthRatio * shrink;
      final h = r.visualDiameter * shrink;

      final sprite = sprites.mutantAttackOf(r.kind) ?? sprites.mutantOf(r.kind);
      if (sprite != null) {
        final flashTint = prog < 0.28
            ? Colors.white.withValues(alpha: (1.0 - prog / 0.28) * 0.80)
            : Color(r.colorHex).withValues(alpha: 0.55);
        _drawSpriteCentered(
          canvas,
          sprite,
          c,
          width: w,
          height: h,
          rotationRad: r.rotationRad,
          opacity: alpha,
          tintColor: flashTint,
        );
      } else {
        canvas.drawCircle(
          c,
          w * 0.42,
          Paint()..color = Color(r.colorHex).withValues(alpha: alpha),
        );
      }

      // 사방으로 튀는 수묵·독기·불꽃 파편 조각 (일반 8조각, 치명·보스 12조각)
      final shardCount = r.isCriticalKill ? 12 : 8;
      final burstDist = (14.0 + r.visualDiameter * 0.55) * prog;
      final shardCol = r.isCriticalKill ? const Color(0xFFFF6B35) : Color(r.colorHex);
      for (int k = 0; k < shardCount; k++) {
        final a = (k * 2 * pi / shardCount) + r.spinVel * 0.08;
        final dist = burstDist * (0.72 + (k % 3) * 0.22);
        final sc = c + Offset(cos(a) * dist, sin(a) * dist);
        final sz = (r.isCriticalKill ? 4.4 : 3.1) * (1.0 - prog * 0.65);
        canvas.drawCircle(
          sc,
          sz,
          Paint()..color = (k.isEven ? shardCol : NightPalette.accentGold).withValues(alpha: alpha * 0.9),
        );
      }
    }
  }

  /// 본진 위기 긴장감(dangerPulseLevel) 심장박동 적색 비네팅 테두리!
  void _drawDangerTensionPulse(Canvas canvas) {
    if (sim.dangerPulseLevel <= 0.05) return;
    final beat = 0.45 + 0.55 * sin(sim.elapsedSec * 9.5).abs();
    final intensity = (sim.dangerPulseLevel * beat).clamp(0.0, 1.0);
    final borderColor = const Color(0xFFE63946).withValues(alpha: 0.55 * intensity);

    canvas.drawRect(
      const Rect.fromLTWH(3, 3, CampaignCatalog.arenaWidth - 6, CampaignCatalog.arenaHeight - 6),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRect(
      const Rect.fromLTWH(1.5, 1.5, CampaignCatalog.arenaWidth - 3, CampaignCatalog.arenaHeight - 3),
      Paint()
        ..color = const Color(0xFFFF4D6D).withValues(alpha: 0.72 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  /// 괴물 머리 위로 톡톡 튀어 오르는 시원한 타격 데미지 숫자 팝업!
  void _drawDamagePopups(Canvas canvas) {
    for (final dp in sim.damagePopups) {
      final prog = dp.progress;
      final alpha = prog < 0.70 ? 1.0 : ((1.0 - prog) / 0.30).clamp(0.0, 1.0);
      final popScale = prog < 0.18 ? (0.88 + (prog / 0.18) * 0.45) : 1.0;
      final fontSize = (dp.isCrit ? 15.2 : (dp.isKill ? 12.6 : 10.6)) * popScale;
      final label = dp.isCrit ? '⚡치명 ${dp.damage}!!' : '${dp.damage}';
      _paintMiniText(
        canvas,
        label,
        Offset(
          dp.pos.x.clamp(28.0, CampaignCatalog.arenaWidth - 28.0),
          dp.pos.y.clamp(28.0, CampaignCatalog.arenaHeight - 28.0),
        ),
        Color(dp.colorHex).withValues(alpha: alpha),
        fontSize,
        withBg: dp.isCrit,
      );
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
        Offset(sim.towerPos.x, sim.towerPos.y - 4),
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

  void _drawCrisisTargetBeacon(Canvas canvas) {
    final crisis = sim.activeCrisis;
    if (crisis == null) return;
    final target = Offset(crisis.rawTargetPos.x, crisis.rawTargetPos.y);
    final pulse = 0.5 + 0.5 * sin(sim.elapsedSec * 9.5);
    final outerR = 30.0 + pulse * 14.0;
    final innerR = 20.0 + (1.0 - pulse) * 6.0;

    canvas.drawCircle(
      target,
      outerR,
      Paint()
        ..color = const Color(0xFFFF1E56).withValues(alpha: 0.28 + pulse * 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _isPipZoom ? 2.8 : 2.2,
    );
    canvas.drawCircle(
      target,
      innerR,
      Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    for (int k = 0; k < 4; k++) {
      final a = sim.elapsedSec * 1.4 + k * (pi / 2);
      canvas.drawLine(
        target + Offset(cos(a) * (innerR - 5), sin(a) * (innerR - 5)),
        target + Offset(cos(a) * (outerR + 4), sin(a) * (outerR + 4)),
        Paint()
          ..color = const Color(0xFFFF4D6D)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
    if (!_isPipZoom) {
      _paintMiniText(
        canvas,
        '🚨위험구역 [${crisis.zoneName}]',
        target + Offset(0, outerR + 12),
        const Color(0xFFFF4D6D),
        9.4,
        withBg: true,
      );
    }
  }

  void _drawDawnPurifyWave(Canvas canvas) {
    if (sim.dawnPurifyAnimTimer <= 0) return;
    final prog = (1.0 - sim.dawnPurifyAnimTimer / 1.5).clamp(0.0, 1.0);
    final center = Offset(sim.shieldCenter.x, sim.shieldCenter.y);
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
        fc.pos.x.clamp(86.0, CampaignCatalog.arenaWidth - 86.0),
        fc.pos.y.clamp(42.0, CampaignCatalog.arenaHeight - 48.0),
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
