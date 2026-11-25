import 'dart:async';
import 'dart:ui' as ui;

import 'package:defense_core/defense_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/night_theme.dart';

/// 《수호알까기 · 탄지무림 심야기습》 코덱스 대륙 지도 · 10대 전장 맵 · 디테일 캐릭터/돌연변이 4프레임 시트 · 3D 모션 루프 정본 레지스트리.
class NightArtRegistry {
  NightArtRegistry._();

  // 1. 코덱스 대륙 월드맵 · 라이브 3D 모션 루프 · 전각별 영웅 대 변이 실전 원화
  static const String worldMapMurimNight =
      'assets/images/scenes/world_map_murim_night.webp';
  static const String worldMapLiveMotion =
      'assets/images/motions/world_map_live.webp';
  static const String splashClashLoop =
      'assets/images/motions/splash_clash_loop.webp';
  static const String homeCommandLoop =
      'assets/images/motions/home_command_loop.webp';

  /// 현(縣) 정화 완료 후 다음 현으로 대행군할 때 재생되는 9종 완전 고유 모션 영상 경로 (`1→2현` ~ `9→10현`).
  static String countyTravelMotionAsset(int fromChapter) {
    final safeFrom = fromChapter.clamp(1, 9);
    return 'assets/images/motions/county_travel_${safeFrom}_to_${safeFrom + 1}.webp';
  }

  /// 제1현~제10현 각 현 전용 실측 지형 · 도로 · 10개 마을 조감도 지도 원화 경로 (`county_map_ch1..10.webp`).
  static String countyRegionalMapAsset(int chapterNumber) {
    final safeCh = chapterNumber.clamp(1, 10);
    return 'assets/images/scenes/county_map_ch$safeCh.webp';
  }

  static const String bgNightSplash = 'assets/images/scenes/bg_night_splash.webp';
  static const String bgNightLobby = 'assets/images/scenes/bg_night_lobby.webp';
  static const String bgLobbyFallback = 'assets/images/scenes/bg_lobby.webp';
  static const String lobbyStageFortress =
      'assets/images/scenes/lobby_stage_fortress.webp';
  static const String cardGateBattle =
      'assets/images/scenes/card_gate_battle.webp';
  static const String cardTrainingHall =
      'assets/images/scenes/card_training_hall.webp';
  static const String cardForgeSanctum =
      'assets/images/scenes/card_forge_sanctum.webp';
  static const String cardAllyPavilion =
      'assets/images/scenes/card_ally_pavilion.webp';
  static const String cardRescueBeacon =
      'assets/images/scenes/card_rescue_beacon.webp';
  static const String cardSupplyConvoy =
      'assets/images/scenes/card_supply_convoy.webp';
  static const String cardEndlessAbyss =
      'assets/images/scenes/card_endless_abyss.webp';

  // 영웅 대 변이 와이드 결전 배너 & 초정밀 돌연변이 보스 해부 쇼케이스 원화
  static const String heroClashBanner =
      'assets/images/scenes/hero_clash_banner.webp';
  static const String mutantPackBanner =
      'assets/images/scenes/mutant_pack_banner.webp';
  static const String showcaseBossChapter =
      'assets/images/scenes/showcase_boss_chapter.webp';
  static const String showcaseBossCrimson =
      'assets/images/scenes/showcase_boss_crimson.webp';
  static const String showcaseBossIron =
      'assets/images/scenes/showcase_boss_iron.webp';
  static const String showcaseBossSwift =
      'assets/images/scenes/showcase_boss_swift.webp';
  static const String showcaseBossMukhyeon =
      'assets/images/scenes/showcase_boss_mukhyeon.webp';

  // 2. 중앙 수호탑 · 마을 생태 3종 · 전장 화약통 기물
  static const String towerGuardian =
      'assets/images/launchers/tower_guardian.webp';
  static const String villageGranary =
      'assets/images/launchers/village_granary.webp';
  static const String villageCrops =
      'assets/images/launchers/village_crops.webp';
  static const String villageLivestock =
      'assets/images/launchers/village_livestock.webp';
  static const String propPowderKeg =
      'assets/images/launchers/prop_powder_keg.webp';

  // 3. 전용 코덱스 아이콘 · 돌파 비급 · 운빨 소환패
  static const String appLogo = 'assets/images/icons/app_logo.webp';
  static const String wslogisLogo = 'assets/images/icons/wslogis.webp';
  static const String nightToken = 'assets/images/icons/night_token.webp';
  static const String nightElixir = 'assets/images/icons/night_elixir.webp';
  static const String nightSupportSeal =
      'assets/images/icons/night_support_seal.webp';
  static const String nightConvoyCart =
      'assets/images/icons/night_convoy_cart.webp';
  static const String nightSerendipity =
      'assets/images/icons/night_serendipity.webp';
  static const String nightMeridian = 'assets/images/icons/night_meridian.webp';
  static const String nightEndless = 'assets/images/icons/night_endless.webp';
  static const String iconRogueScroll =
      'assets/images/icons/icon_rogue_scroll.webp';
  static const String iconLuckyDice =
      'assets/images/icons/icon_lucky_dice.webp';

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

  // 4. 전장 타격 · 출두 · 침공 균열문 · 복제진 · 피버 이펙트 11종 + 보물 도깨비
  static const String fxChuldu = 'assets/images/fx/fx_chuldu.webp';
  static const String fxBarrier = 'assets/images/fx/fx_barrier.webp';
  static const String fxBreachGate = 'assets/images/fx/fx_breach_gate.webp';
  static const String fxCritical = 'assets/images/fx/fx_critical.webp';
  static const String fxShatter = 'assets/images/fx/fx_shatter.webp';
  static const String fxKnockout = 'assets/images/fx/fx_knockout.webp';
  static const String fxCombo = 'assets/images/fx/fx_combo.webp';
  static const String fxLucky = 'assets/images/fx/fx_lucky.webp';
  static const String fxQi = 'assets/images/fx/fx_qi.webp';
  static const String fxCloneGate = 'assets/images/fx/fx_clone_gate.webp';
  static const String fxFeverAura = 'assets/images/fx/fx_fever_aura.webp';
  static const String mutTreasureGoblin =
      'assets/images/mutants/mut_treasure_goblin.webp';
  static const String mutTreasureGoblinStrip =
      'assets/images/sheets/mut_treasure_goblin_strip.webp';

  /// 심야 돌연변이·중간보스·대수괴 12종 기본 행군 원화 경로.
  static String mutantAsset(MutantKind kind) =>
      'assets/images/mutants/mut_${kind.id}.webp';

  /// 심야 돌연변이·중간보스·대수괴 12종 돌격·강타 원화 경로.
  static String mutantAttackAsset(MutantKind kind) =>
      'assets/images/mutants/mut_${kind.id}_atk.webp';

  /// 코덱스 2x2 디테일 해부·3페이즈 진화 캐릭터 시트 경로 (`768x768`).
  static String mutantSheetAsset(MutantKind kind) =>
      'assets/images/sheets/mut_${kind.id}_sheet.webp';

  /// 전장 60fps 4프레임 알파 투명 스프라이트 스트립 경로 (`1024x256`).
  static String mutantStripAsset(MutantKind kind) =>
      'assets/images/sheets/mut_${kind.id}_strip.webp';

  /// 12프레임 3D 시네마틱 루프 모션 영상(`Animated WebP`) 경로.
  static String mutantMotionAsset(MutantKind kind) =>
      'assets/images/motions/mut_${kind.id}_anim.webp';

  /// 보스 및 주요 변이체용 초고밀도 단독 쇼케이스 일러스트 경로.
  static String mutantShowcaseAsset(MutantKind kind) {
    switch (kind) {
      case MutantKind.chapterOverlord:
        return showcaseBossChapter;
      case MutantKind.crimsonBreakerBoss:
        return showcaseBossCrimson;
      case MutantKind.ironColossusBoss:
        return showcaseBossIron;
      case MutantKind.swiftShadowBoss:
        return showcaseBossSwift;
      case MutantKind.rivalMukhyeon:
      case MutantKind.raiderHeukpung:
        return showcaseBossMukhyeon;
      default:
        return mutantAttackAsset(kind);
    }
  }

  /// 발사대 종류별 주력 상성 표적 변이체 반환.
  static MutantKind counterTargetOfLauncher(LauncherType type) {
    switch (type) {
      case LauncherType.rapid:
        return MutantKind.swarmRat;
      case LauncherType.heavy:
        return MutantKind.ironColossusBoss;
      case LauncherType.curveSpin:
        return MutantKind.shieldYacha;
      case LauncherType.frostField:
        return MutantKind.swiftShadowBoss;
      case LauncherType.qiAmplifier:
        return MutantKind.chapterOverlord;
    }
  }

  /// 길목 자동 발사대 5종 원화 경로.
  static String launcherAsset(LauncherType type) =>
      'assets/images/launchers/launcher_${type.id}.webp';

  /// 수호석 13종 원화 경로.
  static String stoneAsset(StoneMaterial stone) =>
      'assets/images/stones/stone_${stone.id}.webp';

  /// 전술 비약 3종 원화 경로.
  static String consumableAsset(TacticalConsumable consumable) =>
      'assets/images/icons/potion_${consumable.name}.webp';

  /// 제조 재료 4종 원화 경로.
  static String materialAsset(CraftMaterial material) =>
      'assets/images/icons/mat_${material.name}.webp';

  /// 수호 영수 5종 원화 · 디테일 시트 · 4프레임 스트립 · 3D 모션 루프 경로.
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

  static String beastSheetAsset(SpiritBeast beast) =>
      'assets/images/sheets/beast_${beast.id}_sheet.webp';

  static String beastStripAsset(SpiritBeast beast) =>
      'assets/images/sheets/beast_${beast.id}_strip.webp';

  static String beastMotionAsset(SpiritBeast beast) =>
      'assets/images/motions/beast_${beast.id}_anim.webp';

  /// 동료/인물 초상화 · 전신 원화 · 디테일 캐릭터 시트 · 4프레임 스트립 · 3D 모션 루프 경로.
  static String heroFaceAsset(CompanionHero hero) =>
      'assets/images/chars/${hero.portraitPrefix}_face.webp';

  static String heroIdleAsset(CompanionHero hero) =>
      'assets/images/chars/${hero.portraitPrefix}_idle.webp';

  static String heroAttackAsset(CompanionHero hero) =>
      'assets/images/chars/${hero.portraitPrefix}_attack.webp';

  static String heroSheetAsset(CompanionHero hero) =>
      'assets/images/sheets/hero_${hero.portraitPrefix}_sheet.webp';

  static String heroStripAsset(CompanionHero hero) =>
      'assets/images/sheets/hero_${hero.portraitPrefix}_strip.webp';

  static String heroMotionAsset(CompanionHero hero) =>
      'assets/images/motions/hero_${hero.portraitPrefix}_anim.webp';

  static String charFace(String portraitPrefix) =>
      'assets/images/chars/${portraitPrefix}_face.webp';

  static String charIdle(String portraitPrefix) =>
      'assets/images/chars/${portraitPrefix}_idle.webp';

  static String charAttack(String portraitPrefix) =>
      'assets/images/chars/${portraitPrefix}_attack.webp';

  static String charSheet(String portraitPrefix) =>
      'assets/images/sheets/hero_${portraitPrefix}_sheet.webp';

  static String charStrip(String portraitPrefix) =>
      'assets/images/sheets/hero_${portraitPrefix}_strip.webp';

  static String charMotion(String portraitPrefix) =>
      'assets/images/motions/hero_${portraitPrefix}_anim.webp';
}

/// 코덱스 디테일 2×2 캐릭터·돌연변이 시트 & 3D 모션 영상 루프를 한눈에 감상하는 프리미엄 쇼케이스 다이얼로그.
Future<void> showCodexCharacterSheetDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String motionAssetPath,
  required String sheetAssetPath,
  required String fallbackAssetPath,
  required List<String> frameLabels,
  Color accentColor = NightPalette.accentGold,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: NightPalette.hanjiLight,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: NightPalette.accentGold, width: 2.0),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    NightSpriteIcon(
                      assetPath: motionAssetPath,
                      fallbackAssetPath: fallbackAssetPath,
                      fallbackIcon: Icons.auto_awesome_motion_rounded,
                      size: 64,
                      borderRadius: 14,
                      fit: BoxFit.cover,
                      showFrame: true,
                      frameColor: NightPalette.hanjiInk,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 19,
                              color: NightPalette.hanjiInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12.6,
                              color: NightPalette.hanjiSubInk,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: NightPalette.hanjiInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: NightPalette.hanjiInk,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '4단계 모션 · 변이 시트 구성: ${frameLabels.join("  ▶  ")}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: NightPalette.accentGold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: const Color(0xFF0E1626),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 3.0,
                      child: Image.asset(
                        sheetAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          fallbackAssetPath,
                          height: 280,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '두 손가락으로 확대하여 코덱스 원화의 갑주·근육·무기·변이 외피 디테일을 감상할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: NightPalette.hanjiSubInk,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: NightPalette.hanjiInk,
                    foregroundColor: NightPalette.accentGold,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('감상 완료 · 닫기'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 손그림 원화 및 다중 프레임 Animated WebP 모션 클립을 표시하고 미존재 시 폴백하는 안전 위젯.
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
          color: NightPalette.bgDeep.withValues(alpha: 0.78),
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
      gaplessPlayback: true,
      errorBuilder: (_, _, _) {
        if (fallbackAssetPath != null && fallbackAssetPath!.isNotEmpty) {
          return Image.asset(
            fallbackAssetPath!,
            width: size,
            height: size,
            fit: fit,
            gaplessPlayback: true,
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
      imageWidget = Opacity(opacity: 0.52, child: imageWidget);
    }

    if (!showFrame) {
      return SizedBox(width: size, height: size, child: imageWidget);
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: NightPalette.bgDeep.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(borderRadius + 2),
        border: Border.all(
          color: (frameColor ?? effectiveColor)
              .withValues(alpha: dimmed ? 0.32 : 0.72),
          width: 1.2,
        ),
      ),
      child: imageWidget,
    );
  }
}

/// 수호 본영 및 보조 화면 공통 심야 배경 래퍼.
class NightSceneBackdrop extends StatelessWidget {
  const NightSceneBackdrop({
    super.key,
    required this.child,
    this.assetPath = NightArtRegistry.bgNightLobby,
    this.fallbackAssetPath = NightArtRegistry.bgLobbyFallback,
    this.overlayOpacity = 0.72,
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
          gaplessPlayback: true,
          errorBuilder: (_, _, _) {
            if (fallbackAssetPath != null) {
              return Image.asset(
                fallbackAssetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: NightPalette.bgDeep),
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
                NightPalette.bgDeep
                    .withValues(alpha: (overlayOpacity * 0.86).clamp(0.0, 0.92)),
                NightPalette.bgPanel
                    .withValues(alpha: (overlayOpacity * 0.82).clamp(0.0, 0.92)),
                NightPalette.bgDeep
                    .withValues(alpha: (overlayOpacity * 0.94).clamp(0.0, 0.95)),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// 60프레임 `NightBattlePainter` 전용 비동기 `dart:ui.Image` 스프라이트 & 코덱스 4프레임 시트 스트립 캐시.
class NightBattleSprites {
  NightBattleSprites._();

  static final NightBattleSprites instance = NightBattleSprites._();

  final Map<String, ui.Image> _cache = <String, ui.Image>{};
  final Set<String> _inFlight = <String>{};
  final Set<String> _missingOnce = <String>{};

  ui.Image? operator [](String assetPath) => _cache[assetPath];
  int get cachedCount => _cache.length;

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
  ui.Image? get fxCloneGate => _cache[NightArtRegistry.fxCloneGate];
  ui.Image? get fxFeverAura => _cache[NightArtRegistry.fxFeverAura];
  ui.Image? get propPowderKeg => _cache[NightArtRegistry.propPowderKeg];
  ui.Image? get mutTreasureGoblin => _cache[NightArtRegistry.mutTreasureGoblin];
  ui.Image? get mutTreasureGoblinStrip =>
      _cache[NightArtRegistry.mutTreasureGoblinStrip];
  ui.Image? get sabuStrip => _cache[NightArtRegistry.charStrip('sabu')];

  ui.Image? floorOf(ChapterSpec chapter) => _cache[chapter.floorAsset];
  ui.Image? mutantOf(MutantKind kind) =>
      _cache[NightArtRegistry.mutantAsset(kind)];
  ui.Image? mutantAttackOf(MutantKind kind) =>
      _cache[NightArtRegistry.mutantAttackAsset(kind)];
  ui.Image? mutantStripOf(MutantKind kind) =>
      _cache[NightArtRegistry.mutantStripAsset(kind)];

  ui.Image? launcherOf(LauncherType type) =>
      _cache[NightArtRegistry.launcherAsset(type)];
  ui.Image? stoneOf(StoneMaterial stone) =>
      _cache[NightArtRegistry.stoneAsset(stone)];

  ui.Image? beastOf(SpiritBeast beast) =>
      _cache[NightArtRegistry.beastAsset(beast)];
  ui.Image? beastStripOf(SpiritBeast beast) =>
      _cache[NightArtRegistry.beastStripAsset(beast)];

  ui.Image? heroIdleOf(CompanionHero hero) =>
      _cache[NightArtRegistry.heroIdleAsset(hero)];
  ui.Image? heroAttackOf(CompanionHero hero) =>
      _cache[NightArtRegistry.heroAttackAsset(hero)];
  ui.Image? heroStripOf(CompanionHero hero) =>
      _cache[NightArtRegistry.heroStripAsset(hero)];

  /// 해당 장(Chapter) 전장에 필요한 코덱스 지형 맵 · 4프레임 시트 스트립 · 발사대/이펙트를 비동기 디코딩합니다.
  Future<void> warmUpForChapter(
    ChapterSpec chapter, {
    List<CompanionHero> activeHeroes = const <CompanionHero>[],
    VoidCallback? onSpritesUpdated,
  }) async {
    final corePaths = <String>[
      chapter.floorAsset,
      NightArtRegistry.towerGuardian,
      NightArtRegistry.charStrip('sabu'),
      NightArtRegistry.villageGranary,
      NightArtRegistry.villageCrops,
      NightArtRegistry.villageLivestock,
      NightArtRegistry.propPowderKeg,
      NightArtRegistry.fxCloneGate,
      NightArtRegistry.fxFeverAura,
      NightArtRegistry.mutTreasureGoblin,
      NightArtRegistry.mutTreasureGoblinStrip,
      NightArtRegistry.fxChuldu,
      NightArtRegistry.fxBarrier,
      NightArtRegistry.fxBreachGate,
      NightArtRegistry.fxCritical,
      NightArtRegistry.fxShatter,
      NightArtRegistry.fxKnockout,
      NightArtRegistry.fxCombo,
      NightArtRegistry.fxLucky,
      NightArtRegistry.fxQi,
    ];
    final unitPaths = <String>[
      for (final lt in LauncherType.values) NightArtRegistry.launcherAsset(lt),
      for (final st in StoneMaterial.values) NightArtRegistry.stoneAsset(st),
      for (final mk in MutantKind.values) ...[
        NightArtRegistry.mutantStripAsset(mk),
        NightArtRegistry.mutantAsset(mk),
        NightArtRegistry.mutantAttackAsset(mk),
      ],
      for (final sb in SpiritBeast.values) ...[
        NightArtRegistry.beastStripAsset(sb),
        NightArtRegistry.beastAsset(sb),
      ],
      for (final ch in <CompanionHero>{
        ...(activeHeroes.isEmpty ? CompanionHero.values.take(4) : activeHeroes),
        CompanionHero.mukhyeon,
      }) ...[
        NightArtRegistry.heroStripAsset(ch),
        NightArtRegistry.heroIdleAsset(ch),
        NightArtRegistry.heroAttackAsset(ch),
      ],
    ];

    final coreResults = await Future.wait(corePaths.map(_decodeSingleAsset));
    if (coreResults.any((ok) => ok)) {
      onSpritesUpdated?.call();
    }

    final unitResults = await Future.wait(unitPaths.map(_decodeSingleAsset));
    if (unitResults.any((ok) => ok)) {
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
      if (kIsWeb) {
        final ok = await _resolveViaImageProvider(assetPath);
        if (ok) return true;
      }
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
      try {
        final ui.FrameInfo frame = await codec.getNextFrame();
        _cache[assetPath] = frame.image;
      } finally {
        codec.dispose();
      }
      return true;
    } catch (_) {
      if (kIsWeb) {
        final ok = await _resolveViaImageProvider(assetPath);
        if (ok) return true;
      }
      _missingOnce.add(assetPath);
      return false;
    } finally {
      _inFlight.remove(assetPath);
    }
  }

  Future<bool> _resolveViaImageProvider(String assetPath) async {
    final completer = Completer<bool>();
    final stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        _cache[assetPath] = info.image;
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (Object _, StackTrace? _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        stream.removeListener(listener);
        return false;
      },
    );
  }
}
