import 'dart:ui' as ui;

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/night_theme.dart';

/// 《수호알까기 · 탄지무림 심야기습》 코덱스 원화 경로 정본 레지스트리 및 안전 렌더러.
class NightArtRegistry {
  NightArtRegistry._();

  // 1. 심야 배경 및 바닥 · 게임 로비 원화 (assets/images/scenes/)
  static const String bgNightSplash = 'assets/images/scenes/bg_night_splash.webp';
  static const String bgNightLobby = 'assets/images/scenes/bg_night_lobby.webp';
  static const String bgLobbyFallback = 'assets/images/scenes/bg_lobby.webp';
  static const String lobbyStageFortress = 'assets/images/scenes/lobby_stage_fortress.webp';
  static const String cardGateBattle = 'assets/images/scenes/card_gate_battle.webp';
  static const String cardTrainingHall = 'assets/images/scenes/card_training_hall.webp';
  static const String cardForgeSanctum = 'assets/images/scenes/card_forge_sanctum.webp';
  static const String cardAllyPavilion = 'assets/images/scenes/card_ally_pavilion.webp';
  static const String cardRescueBeacon = 'assets/images/scenes/card_rescue_beacon.webp';
  static const String cardSupplyConvoy = 'assets/images/scenes/card_supply_convoy.webp';
  static const String cardEndlessAbyss = 'assets/images/scenes/card_endless_abyss.webp';

  // 2. 중앙 수호탑 · 마을 생태 3종 (assets/images/launchers/)
  static const String towerGuardian = 'assets/images/launchers/tower_guardian.webp';
  static const String villageGranary = 'assets/images/launchers/village_granary.webp';
  static const String villageCrops = 'assets/images/launchers/village_crops.webp';
  static const String villageLivestock = 'assets/images/launchers/village_livestock.webp';

  // 3. 전용 코덱스 아이콘 (assets/images/icons/)
  static const String appLogo = 'assets/images/icons/app_logo.webp';
  static const String wslogisLogo = 'assets/images/icons/wslogis.webp';
  static const String nightToken = 'assets/images/icons/night_token.webp';
  static const String nightElixir = 'assets/images/icons/night_elixir.webp';
  static const String nightSupportSeal = 'assets/images/icons/night_support_seal.webp';
  static const String nightConvoyCart = 'assets/images/icons/night_convoy_cart.webp';
  static const String nightSerendipity = 'assets/images/icons/night_serendipity.webp';
  static const String nightMeridian = 'assets/images/icons/night_meridian.webp';
  static const String nightEndless = 'assets/images/icons/night_endless.webp';

  // 보조 공용 아이콘
  static const String iconAttendance = 'assets/images/icons/attendance.webp';
  static const String iconCampaign = 'assets/images/icons/campaign.webp';
  static const String iconChest = 'assets/images/icons/chest.webp';
  static const String iconCodex = 'assets/images/icons/codex.webp';
  static const String iconMedal = 'assets/images/icons/medal.webp';
  static const String iconMission = 'assets/images/icons/mission.webp';
  static const String iconNaegong = 'assets/images/icons/naegong.webp';
  static const String iconOdds = 'assets/images/icons/odds.webp';
  static const String iconSettings = 'assets/images/icons/settings.webp';
  static const String iconTrainingSeal = 'assets/images/icons/tp.webp';

  // 4. 전장 타격 · 출두 · 침공 균열문 이펙트 9종 (assets/images/fx/)
  static const String fxChuldu = 'assets/images/fx/fx_chuldu.webp';
  static const String fxBarrier = 'assets/images/fx/fx_barrier.webp';
  static const String fxBreachGate = 'assets/images/fx/fx_breach_gate.webp';
  static const String fxCritical = 'assets/images/fx/fx_critical.webp';
  static const String fxShatter = 'assets/images/fx/fx_shatter.webp';
  static const String fxKnockout = 'assets/images/fx/fx_knockout.webp';
  static const String fxCombo = 'assets/images/fx/fx_combo.webp';
  static const String fxLucky = 'assets/images/fx/fx_lucky.webp';
  static const String fxQi = 'assets/images/fx/fx_qi.webp';

  /// 심야 돌연변이·중간보스·대수괴 12종 기본 행군 원화 경로 (`assets/images/mutants/mut_${kind.id}.webp`).
  static String mutantAsset(MutantKind kind) =>
      'assets/images/mutants/mut_${kind.id}.webp';

  /// 심야 돌연변이·중간보스·대수괴 12종 돌격·강타 원화 경로 (`assets/images/mutants/mut_${kind.id}_atk.webp`).
  static String mutantAttackAsset(MutantKind kind) =>
      'assets/images/mutants/mut_${kind.id}_atk.webp';

  /// 길목 자동 발사대 5종 원화 경로 (`assets/images/launchers/launcher_${type.id}.webp`).
  static String launcherAsset(LauncherType type) =>
      'assets/images/launchers/launcher_${type.id}.webp';

  /// 수호석 13종 원화 경로 (`assets/images/stones/stone_${stone.id}.webp`).
  static String stoneAsset(StoneMaterial stone) =>
      'assets/images/stones/stone_${stone.id}.webp';

  /// 전술 비약 3종 원화 경로 (`assets/images/icons/potion_${consumable.name}.webp`).
  static String consumableAsset(TacticalConsumable consumable) =>
      'assets/images/icons/potion_${consumable.name}.webp';

  /// 제조 재료 4종 원화 경로 (`assets/images/icons/mat_${material.name}.webp`).
  static String materialAsset(CraftMaterial material) =>
      'assets/images/icons/mat_${material.name}.webp';

  /// 수호 영수 5종 원화 경로 (`assets/images/icons/pet_*.webp`).
  static String beastAsset(SpiritBeast beast) {
    switch (beast) {
      case SpiritBeast.nalssaendol:
        return 'assets/images/icons/pet_squirrel.webp';
      case SpiritBeast.geumgangTurtle:
        return 'assets/images/icons/pet_turtle.webp';
      case SpiritBeast.cheonghak:
        return 'assets/images/icons/pet_crane.webp';
      case SpiritBeast.baekho:
        return 'assets/images/icons/pet_tiger.webp';
      case SpiritBeast.geumryong:
        return 'assets/images/icons/pet_dragon.webp';
    }
  }

  /// 동료/인물 초상화 원화 경로.
  static String heroFaceAsset(CompanionHero hero) =>
      'assets/images/chars/${hero.portraitPrefix}_face.webp';

  static String heroIdleAsset(CompanionHero hero) =>
      'assets/images/chars/${hero.portraitPrefix}_idle.webp';

  static String heroAttackAsset(CompanionHero hero) =>
      'assets/images/chars/${hero.portraitPrefix}_attack.webp';

  static String charFace(String portraitPrefix) =>
      'assets/images/chars/${portraitPrefix}_face.webp';

  static String charIdle(String portraitPrefix) =>
      'assets/images/chars/${portraitPrefix}_idle.webp';
}

/// 코덱스 손그림 원화를 우선 표시하고 미존재/로딩 실패 시 깔끔한 아이콘으로 폴백하는 안전 위젯.
class NightSpriteIcon extends StatelessWidget {
  const NightSpriteIcon({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.fallbackAssetPath,
    this.size = 36,
    this.color,
    this.borderRadius = 8,
    this.fit = BoxFit.contain,
    this.dimmed = false,
    this.showFrame = false,
    this.frameColor,
  });

  final String assetPath;
  final String? fallbackAssetPath;
  final IconData fallbackIcon;
  final double size;
  final Color? color;
  final double borderRadius;
  final BoxFit fit;
  final bool dimmed;
  final bool showFrame;
  final Color? frameColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? NightPalette.accentGold;
    Widget fallbackWidget() {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: NightPalette.bgDeep.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: (frameColor ?? effectiveColor).withValues(alpha: 0.45),
          ),
        ),
        child: Icon(
          fallbackIcon,
          size: (size * 0.62).clamp(12.0, 48.0),
          color: dimmed ? NightPalette.textMuted : effectiveColor,
        ),
      );
    }

    Widget imageWidget = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, _, _) {
        if (fallbackAssetPath != null && fallbackAssetPath!.isNotEmpty) {
          return Image.asset(
            fallbackAssetPath!,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (_, _, _) => fallbackWidget(),
          );
        }
        return fallbackWidget();
      },
    );

    if (borderRadius > 0) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    if (dimmed) {
      imageWidget = Opacity(
        opacity: 0.52,
        child: imageWidget,
      );
    }

    if (!showFrame) {
      return SizedBox(width: size, height: size, child: imageWidget);
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: NightPalette.bgDeep.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(borderRadius + 2),
        border: Border.all(
          color: (frameColor ?? effectiveColor).withValues(alpha: dimmed ? 0.32 : 0.72),
          width: 1.2,
        ),
      ),
      child: imageWidget,
    );
  }
}

/// 수호 본영 및 보조 화면 공통 심야 배경 래퍼 (`bg_night_lobby.webp` + 수묵 암막 오버레이).
class NightSceneBackdrop extends StatelessWidget {
  const NightSceneBackdrop({
    super.key,
    required this.child,
    this.assetPath = NightArtRegistry.bgNightLobby,
    this.fallbackAssetPath = NightArtRegistry.bgLobbyFallback,
    this.overlayOpacity = 0.82,
  });

  final Widget child;
  final String assetPath;
  final String? fallbackAssetPath;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            if (fallbackAssetPath != null) {
              return Image.asset(
                fallbackAssetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: NightPalette.bgDeep),
              );
            }
            return const ColoredBox(color: NightPalette.bgDeep);
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                NightPalette.bgDeep.withValues(alpha: (overlayOpacity * 0.92).clamp(0.0, 0.96)),
                NightPalette.bgPanel.withValues(alpha: (overlayOpacity * 0.86).clamp(0.0, 0.96)),
                NightPalette.bgDeep.withValues(alpha: (overlayOpacity * 1.04).clamp(0.0, 0.97)),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// 60프레임 `NightBattlePainter` 전용 비동기 `dart:ui.Image` 스프라이트 캐시.
/// 로드 전이거나 단위 위젯 시험 환경에서 자산 파일이 아직 없더라도 예외 없이 안전하게 `null`을 반환해
/// 기존 벡터 모션그래픽 도형 렌더링과 자연스럽게 합성/폴백됩니다.
class NightBattleSprites {
  NightBattleSprites._();

  static final NightBattleSprites instance = NightBattleSprites._();

  final Map<String, ui.Image> _cache = <String, ui.Image>{};
  final Set<String> _inFlight = <String>{};
  final Set<String> _missingOnce = <String>{};

  ui.Image? operator [](String assetPath) => _cache[assetPath];

  ui.Image? get towerGuardian => _cache[NightArtRegistry.towerGuardian];
  ui.Image? get granary => _cache[NightArtRegistry.villageGranary];
  ui.Image? get crops => _cache[NightArtRegistry.villageCrops];
  ui.Image? get livestock => _cache[NightArtRegistry.villageLivestock];

  ui.Image? get fxChuldu => _cache[NightArtRegistry.fxChuldu];
  ui.Image? get fxBarrier => _cache[NightArtRegistry.fxBarrier];
  ui.Image? get fxBreachGate => _cache[NightArtRegistry.fxBreachGate];
  ui.Image? get fxCritical => _cache[NightArtRegistry.fxCritical];
  ui.Image? get fxShatter => _cache[NightArtRegistry.fxShatter];
  ui.Image? get fxKnockout => _cache[NightArtRegistry.fxKnockout];
  ui.Image? get fxCombo => _cache[NightArtRegistry.fxCombo];
  ui.Image? get fxLucky => _cache[NightArtRegistry.fxLucky];
  ui.Image? get fxQi => _cache[NightArtRegistry.fxQi];

  ui.Image? floorOf(ChapterSpec chapter) => _cache[chapter.floorAsset];
  ui.Image? mutantOf(MutantKind kind) => _cache[NightArtRegistry.mutantAsset(kind)];
  ui.Image? mutantAttackOf(MutantKind kind) =>
      _cache[NightArtRegistry.mutantAttackAsset(kind)];
  ui.Image? launcherOf(LauncherType type) => _cache[NightArtRegistry.launcherAsset(type)];
  ui.Image? stoneOf(StoneMaterial stone) => _cache[NightArtRegistry.stoneAsset(stone)];
  ui.Image? beastOf(SpiritBeast beast) => _cache[NightArtRegistry.beastAsset(beast)];

  /// 해당 장(Chapter) 전장에 필요한 모든 코덱스 스프라이트를 비동기로 미리 디코딩합니다.
  Future<void> warmUpForChapter(
    ChapterSpec chapter, {
    VoidCallback? onSpritesUpdated,
  }) async {
    final paths = <String>[
      chapter.floorAsset,
      NightArtRegistry.towerGuardian,
      NightArtRegistry.villageGranary,
      NightArtRegistry.villageCrops,
      NightArtRegistry.villageLivestock,
      NightArtRegistry.fxChuldu,
      NightArtRegistry.fxBarrier,
      NightArtRegistry.fxBreachGate,
      NightArtRegistry.fxCritical,
      NightArtRegistry.fxShatter,
      NightArtRegistry.fxKnockout,
      NightArtRegistry.fxCombo,
      NightArtRegistry.fxLucky,
      NightArtRegistry.fxQi,
      for (final lt in LauncherType.values) NightArtRegistry.launcherAsset(lt),
      for (final st in StoneMaterial.values) NightArtRegistry.stoneAsset(st),
      for (final mk in MutantKind.values) NightArtRegistry.mutantAsset(mk),
      for (final mk in MutantKind.values) NightArtRegistry.mutantAttackAsset(mk),
      for (final sb in SpiritBeast.values) NightArtRegistry.beastAsset(sb),
    ];

    bool newlyDecoded = false;
    for (final path in paths) {
      final ok = await _decodeSingleAsset(path);
      if (ok) {
        newlyDecoded = true;
      }
    }
    if (newlyDecoded) {
      onSpritesUpdated?.call();
    }
  }

  Future<bool> _decodeSingleAsset(String assetPath) async {
    if (_cache.containsKey(assetPath)) return false;
    if (_inFlight.contains(assetPath) || _missingOnce.contains(assetPath)) {
      return false;
    }
    _inFlight.add(assetPath);
    try {
      final ByteData raw = await rootBundle.load(assetPath);
      if (raw.lengthInBytes == 0) {
        _missingOnce.add(assetPath);
        return false;
      }
      final Uint8List bytes = raw.buffer.asUint8List(
        raw.offsetInBytes,
        raw.lengthInBytes,
      );
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      _cache[assetPath] = frame.image;
      return true;
    } catch (_) {
      _missingOnce.add(assetPath);
      return false;
    } finally {
      _inFlight.remove(assetPath);
    }
  }
}
