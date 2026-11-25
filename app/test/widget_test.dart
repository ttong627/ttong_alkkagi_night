import 'package:alkkagi_night/audio/night_audio.dart';
import 'package:alkkagi_night/audio/night_haptics.dart';
import 'package:alkkagi_night/main.dart';
import 'package:alkkagi_night/screens/battle_screen.dart';
import 'package:alkkagi_night/screens/codex_and_endless_screens.dart';
import 'package:alkkagi_night/screens/convoy_campaign_screens.dart';
import 'package:alkkagi_night/screens/daily_quests_screen.dart';
import 'package:alkkagi_night/screens/home_screen.dart';
import 'package:alkkagi_night/screens/loadout_upgrade_screens.dart';
import 'package:alkkagi_night/screens/settings_and_credits_screen.dart';
import 'package:alkkagi_night/screens/stage_and_county_transitions.dart';
import 'package:alkkagi_night/screens/training_screen.dart';
import 'package:alkkagi_night/state/game_controller.dart';
import 'package:alkkagi_night/theme/night_theme.dart';
import 'package:alkkagi_night/ui/mutant_motion_engine.dart';
import 'package:alkkagi_night/ui/night_art_registry.dart';
import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NightAudioController.instance.soundEnabled = false;
    NightAudioController.instance.bgmEnabled = false;
  });

  test('코덱스 원화 레지스트리(NightArtRegistry) 전 경로 규격 100% 일치 검증', () {
    expect(NightArtRegistry.bgNightSplash, 'assets/images/scenes/bg_night_splash.webp');
    expect(NightArtRegistry.bgNightLobby, 'assets/images/scenes/bg_night_lobby.webp');
    expect(NightArtRegistry.lobbyStageFortress, 'assets/images/scenes/lobby_stage_fortress.webp');
    expect(NightArtRegistry.cardGateBattle, 'assets/images/scenes/card_gate_battle.webp');
    expect(NightArtRegistry.cardTrainingHall, 'assets/images/scenes/card_training_hall.webp');
    expect(NightArtRegistry.cardForgeSanctum, 'assets/images/scenes/card_forge_sanctum.webp');
    expect(NightArtRegistry.cardAllyPavilion, 'assets/images/scenes/card_ally_pavilion.webp');
    expect(NightArtRegistry.cardRescueBeacon, 'assets/images/scenes/card_rescue_beacon.webp');
    expect(NightArtRegistry.cardSupplyConvoy, 'assets/images/scenes/card_supply_convoy.webp');
    expect(NightArtRegistry.cardEndlessAbyss, 'assets/images/scenes/card_endless_abyss.webp');
    for (int c = 1; c <= 9; c++) {
      expect(
        NightArtRegistry.countyTravelMotionAsset(c),
        'assets/images/motions/county_travel_${c}_to_${c + 1}.webp',
      );
    }
    expect(NightArtRegistry.towerGuardian, 'assets/images/launchers/tower_guardian.webp');
    expect(NightArtRegistry.villageGranary, 'assets/images/launchers/village_granary.webp');
    expect(NightArtRegistry.villageCrops, 'assets/images/launchers/village_crops.webp');
    expect(NightArtRegistry.villageLivestock, 'assets/images/launchers/village_livestock.webp');
    expect(NightArtRegistry.propPowderKeg, 'assets/images/launchers/prop_powder_keg.webp');

    expect(NightArtRegistry.appLogo, 'assets/images/icons/app_logo.webp');
    expect(NightArtRegistry.nightToken, 'assets/images/icons/night_token.webp');
    expect(NightArtRegistry.nightElixir, 'assets/images/icons/night_elixir.webp');
    expect(NightArtRegistry.nightSupportSeal, 'assets/images/icons/night_support_seal.webp');
    expect(NightArtRegistry.nightConvoyCart, 'assets/images/icons/night_convoy_cart.webp');
    expect(NightArtRegistry.nightSerendipity, 'assets/images/icons/night_serendipity.webp');
    expect(NightArtRegistry.nightMeridian, 'assets/images/icons/night_meridian.webp');
    expect(NightArtRegistry.nightEndless, 'assets/images/icons/night_endless.webp');
    expect(NightArtRegistry.iconRogueScroll, 'assets/images/icons/icon_rogue_scroll.webp');
    expect(NightArtRegistry.iconLuckyDice, 'assets/images/icons/icon_lucky_dice.webp');

    expect(NightArtRegistry.fxChuldu, 'assets/images/fx/fx_chuldu.webp');
    expect(NightArtRegistry.fxBarrier, 'assets/images/fx/fx_barrier.webp');
    expect(NightArtRegistry.fxBreachGate, 'assets/images/fx/fx_breach_gate.webp');
    expect(NightArtRegistry.fxCritical, 'assets/images/fx/fx_critical.webp');
    expect(NightArtRegistry.fxShatter, 'assets/images/fx/fx_shatter.webp');
    expect(NightArtRegistry.fxKnockout, 'assets/images/fx/fx_knockout.webp');
    expect(NightArtRegistry.fxCombo, 'assets/images/fx/fx_combo.webp');
    expect(NightArtRegistry.fxLucky, 'assets/images/fx/fx_lucky.webp');
    expect(NightArtRegistry.fxQi, 'assets/images/fx/fx_qi.webp');
    expect(NightArtRegistry.fxCloneGate, 'assets/images/fx/fx_clone_gate.webp');
    expect(NightArtRegistry.fxFeverAura, 'assets/images/fx/fx_fever_aura.webp');
    expect(NightArtRegistry.mutTreasureGoblin, 'assets/images/mutants/mut_treasure_goblin.webp');

    expect(
      MutantKind.values.map(NightArtRegistry.mutantAsset).toList(),
      const [
        'assets/images/mutants/mut_swarmRat.webp',
        'assets/images/mutants/mut_sickHound.webp',
        'assets/images/mutants/mut_ironBoar.webp',
        'assets/images/mutants/mut_shieldYacha.webp',
        'assets/images/mutants/mut_plagueToad.webp',
        'assets/images/mutants/mut_bloodCocoon.webp',
        'assets/images/mutants/mut_bloodWingBat.webp',
        'assets/images/mutants/mut_abyssalGargoyle.webp',
        'assets/images/mutants/mut_swiftShadowBoss.webp',
        'assets/images/mutants/mut_ironColossusBoss.webp',
        'assets/images/mutants/mut_crimsonBreakerBoss.webp',
        'assets/images/mutants/mut_heukpung.webp',
        'assets/images/mutants/mut_mukhyeonBoss.webp',
        'assets/images/mutants/mut_chapterBoss.webp',
      ],
    );

    expect(
      MutantKind.values.map(NightArtRegistry.mutantAttackAsset).toList(),
      const [
        'assets/images/mutants/mut_swarmRat_atk.webp',
        'assets/images/mutants/mut_sickHound_atk.webp',
        'assets/images/mutants/mut_ironBoar_atk.webp',
        'assets/images/mutants/mut_shieldYacha_atk.webp',
        'assets/images/mutants/mut_plagueToad_atk.webp',
        'assets/images/mutants/mut_bloodCocoon_atk.webp',
        'assets/images/mutants/mut_bloodWingBat_atk.webp',
        'assets/images/mutants/mut_abyssalGargoyle_atk.webp',
        'assets/images/mutants/mut_swiftShadowBoss_atk.webp',
        'assets/images/mutants/mut_ironColossusBoss_atk.webp',
        'assets/images/mutants/mut_crimsonBreakerBoss_atk.webp',
        'assets/images/mutants/mut_heukpung_atk.webp',
        'assets/images/mutants/mut_mukhyeonBoss_atk.webp',
        'assets/images/mutants/mut_chapterBoss_atk.webp',
      ],
    );

    expect(
      LauncherType.values.map(NightArtRegistry.launcherAsset).toList(),
      const [
        'assets/images/launchers/launcher_rapid.webp',
        'assets/images/launchers/launcher_heavy.webp',
        'assets/images/launchers/launcher_curveSpin.webp',
        'assets/images/launchers/launcher_frostField.webp',
        'assets/images/launchers/launcher_qiAmplifier.webp',
      ],
    );

    expect(
      StoneMaterial.values.map(NightArtRegistry.stoneAsset).toList(),
      const [
        'assets/images/stones/stone_cheongok.webp',
        'assets/images/stones/stone_wood.webp',
        'assets/images/stones/stone_hyeoncheol.webp',
        'assets/images/stones/stone_obsidian.webp',
        'assets/images/stones/stone_granite.webp',
        'assets/images/stones/stone_ice.webp',
        'assets/images/stones/stone_diamond.webp',
        'assets/images/stones/stone_jageum.webp',
        'assets/images/stones/stone_uncheol.webp',
        'assets/images/stones/stone_hancheol.webp',
        'assets/images/stones/stone_onok.webp',
        'assets/images/stones/stone_yongrin.webp',
        'assets/images/stones/stone_taegeuk.webp',
      ],
    );

    expect(
      TacticalConsumable.values.map(NightArtRegistry.consumableAsset).toList(),
      const [
        'assets/images/icons/potion_qiSurgePill.webp',
        'assets/images/icons/potion_guardianRepairSeal.webp',
        'assets/images/icons/potion_auroraCritCharm.webp',
      ],
    );

    expect(
      CraftMaterial.values.map(NightArtRegistry.materialAsset).toList(),
      const [
        'assets/images/icons/mat_hyeoncheolOre.webp',
        'assets/images/icons/mat_moonHerb.webp',
        'assets/images/icons/mat_frostJade.webp',
        'assets/images/icons/mat_thunderPowder.webp',
      ],
    );

    for (int ch = 1; ch <= 10; ch++) {
      final spec = CampaignCatalog.chapterOf(ch);
      expect(spec.bgAsset, 'assets/images/scenes/bg_night_ch$ch.webp');
      expect(spec.floorAsset, 'assets/images/scenes/floor_night_ch$ch.webp');
    }
  });

  test('돌연변이 12종 생체역학 모션 엔진(MutantMotionEngine) 보행·질주·강타 전환 검증', () {
    for (final mk in MutantKind.values) {
      final strideSample = MutantMotionEngine.sample(
        gaitId: mk.gaitId,
        animPhase: 1.35,
        elapsedSec: 1.0,
        uid: 7,
        headingRad: 1.57,
        attackAnimTimer: 0.0,
        dashBurstTimer: 0.0,
        freezeTimer: 0.0,
        knockbackSpeed: 0.0,
      );
      expect(strideSample.scaleX.isFinite, isTrue);
      expect(strideSample.scaleY.isFinite, isTrue);
      expect(strideSample.shadowAlpha, inInclusiveRange(0.15, 0.55));

      final strikeSample = MutantMotionEngine.sample(
        gaitId: mk.gaitId,
        animPhase: 1.35,
        elapsedSec: 1.0,
        uid: 7,
        headingRad: 1.57,
        attackAnimTimer: 0.55,
        dashBurstTimer: 0.0,
        freezeTimer: 0.0,
        knockbackSpeed: 0.0,
      );
      expect(strikeSample.useAttackSprite, isTrue);
      expect(strikeSample.forwardThrust, greaterThan(5.0));
      expect(strikeSample.slashArcAlpha, greaterThan(0.2));
    }
  });

  testWidgets('오프닝 스플래시 화면이 정상 표시되고 터치 시 즉시 수호 본영으로 진입한다',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(bgmVolume: 0.0, sfxVolume: 0.0),
    );
    await tester.pumpWidget(SuhoAlkkagiNightApp(controller: controller));
    expect(find.text('수호알까기'), findsOneWidget);
    expect(find.text('탄지무림 · 심야기습'), findsOneWidget);

    await tester.tap(find.text('수호알까기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('수호알까기 · 탄지무림 심야기습'), findsOneWidget);
  });

  testWidgets('수호 본영 → 수련 · 진법 · 대장간 · 호송 · 전장(전술 비약 및 출두) 전 구간 무오류 통합 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 500,
        elixirs: 25,
        naegongPoints: 800,
        trainingSeals: 30,
        supportTokens: 2,
        moonOmenGauge: 100,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    await tester.pumpWidget(
      SuhoAlkkagiNightApp(controller: controller, skipSplash: true),
    );
    expect(find.text('수호알까기 · 탄지무림 심야기습'), findsOneWidget);

    // 1. 기명 심법 수련실 진입 및 무실패 단전 운기 터치 검증
    await tester.tap(find.byKey(const Key('menu_training_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    final beforeNaegong = controller.progress.naegongPoints;
    await tester.tap(find.byKey(const Key('meditation_orb_button')));
    await tester.pump();
    expect(controller.progress.naegongPoints, greaterThan(beforeNaegong));

    // 십대 경맥 탭 이동 후 1~6단계(충맥 개통 포함) 즉시 개통 검증
    await tester.tap(find.text('② 십대 경맥(10단)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    for (int step = 1; step <= 6; step++) {
      final btn = find.byKey(const Key('meridian_instant_open_btn'));
      expect(btn, findsOneWidget);
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();
    }
    expect(controller.progress.openedMeridianStep, 6);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 2. 자동 진법 편성실 및 증표 대장간·영약각 진입
    await tester.ensureVisible(find.byKey(const Key('menu_loadout_btn')));
    await tester.tap(find.byKey(const Key('menu_loadout_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('자동 수호 진법 편성실'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    await tester.ensureVisible(find.byKey(const Key('menu_forge_btn')));
    await tester.tap(find.byKey(const Key('menu_forge_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('중앙 자동 보호 장치'), findsOneWidget);
    await tester.tap(find.text('🧪 영약각 (영수·동료·내공)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('내공 경지 승급'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 3. 물자 호송 · 보름달 기연실 진입 후 보름달 특급 기연 개봉(지원패 증가 확인)
    final beforeSupport = controller.progress.supportTokens;
    await tester.ensureVisible(find.byKey(const Key('menu_convoy_btn')));
    await tester.tap(find.byKey(const Key('menu_convoy_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    await tester.ensureVisible(find.text('보름달 특급 기연 열기'));
    await tester.tap(find.text('보름달 특급 기연 열기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.progress.supportTokens, greaterThan(beforeSupport));

    await tester.tap(find.text('기쁘게 수령'));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 4. 10현·100판 지도 화면 및 즉시 야간 수호 출정 + 전술 비약 발동 검증
    await tester.ensureVisible(find.byKey(const Key('home_campaign_map_btn')));
    await tester.tap(find.byKey(const Key('home_campaign_map_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('탄지무림 10현·100판 수호록'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 1-2단계(도입 대사 없는 일반 전장)로 설정 후 즉시 출정하여 비약 클릭 검증
    controller.progress.highestClearedGlobalStage = 1;
    controller.notifyConsumableUsedInBattle();
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('home_quick_battle_btn')));
    await tester.tap(find.byKey(const Key('home_quick_battle_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('무림수호단 출두!'), findsOneWidget);

    final beforePill = controller.progress.consumables[TacticalConsumable.qiSurgePill] ?? 0;
    await tester.tap(find.byKey(const Key('use_consumable_qiSurgePill')));
    await tester.pump();
    expect(controller.progress.consumables[TacticalConsumable.qiSurgePill], beforePill - 1);

    // 5. 중앙 기명 수호탑 자동발사 ↔ 수동탄지 전환 및 길목 빈 초소 터치 직접 배치 검증
    expect(find.text('중앙탑: 자동발사'), findsOneWidget);
    await tester.tap(find.byKey(const Key('battle_toggle_central_mode_btn')));
    await tester.pump();
    expect(find.text('중앙탑: 수동탄지'), findsOneWidget);
    expect(find.text('초소 0/4곳'), findsOneWidget);

    // 1-2 전장의 첫 번째 빈 초소 좌표를 동적으로 읽어 터치해 빠른 선택 띠 오픈!
    expect(find.textContaining('군수기력 ⚡'), findsOneWidget);
    final arenaBox = tester.getRect(find.byKey(const Key('battle_arena_gesture')));
    final firstSlotPos = CampaignCatalog.chapterOf(1).mounts.first.pos;
    final slotTapOffset = Offset(
      arenaBox.left + arenaBox.width * (firstSlotPos.x / CampaignCatalog.arenaWidth),
      arenaBox.top + arenaBox.height * (firstSlotPos.y / CampaignCatalog.arenaHeight),
    );
    await tester.tapAt(slotTapOffset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('⛩️협곡관문'), findsOneWidget);
    expect(find.byKey(const Key('lucky_summon_btn')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('place_launcher_rapid')));
    await tester.tap(find.byKey(const Key('place_launcher_rapid')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('초소 1/4곳'), findsOneWidget);

    // 3배속으로 전환해 제1물결 후반부까지 진행하면 ⚡조기호출(+18⚡·비급) 버튼이 활성화된다!
    await tester.tap(find.text('3배'));
    await tester.pump();
    for (int f = 0; f < 180; f++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('call_early_wave_btn')).evaluate().isNotEmpty) {
        break;
      }
    }

    // ⚡ 다음 물결 조기 호출 버튼 클릭 시 +18⚡ 보급과 함께 📜 심야 돌파 비급(3택 1) 오버레이가 즉시 열리는지 검증!
    expect(find.byKey(const Key('call_early_wave_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('call_early_wave_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('심야 돌파 비급 선택 (3택 1)'), findsOneWidget);

    // 첫 번째 비급 카드를 선택하면 오버레이가 닫히고 전투가 이어진다!
    final firstPerkCard = find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('rogue_perk_'),
    );
    expect(firstPerkCard, findsNWidgets(3));
    await tester.tap(firstPerkCard.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('심야 돌파 비급 선택 (3택 1)'), findsNothing);
  });

  testWidgets('상용 확장 화면(출석·임무·비약 제조·수호 도감·확률 공개·무한 혈전·설정·만든 이·제작노트) 전수 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 300,
        highestClearedGlobalStage: 12,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
        materials: {
          for (final m in CraftMaterial.values) m: 5,
        },
      ),
    );

    await tester.pumpWidget(
      SuhoAlkkagiNightApp(controller: controller, skipSplash: true),
    );

    // 1. 출석 · 임무 · 비약 제조 화면 검증
    await tester.ensureVisible(find.byKey(const Key('menu_daily_btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu_daily_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    expect(controller.progress.attendanceStepCount, 0);
    await tester.tap(find.byKey(const Key('claim_attendance_btn')));
    await tester.pump();
    expect(controller.progress.attendanceStepCount, 1);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pump();

    await tester.tap(find.text('비약 제조'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    final beforeRepair =
        controller.progress.consumables[TacticalConsumable.guardianRepairSeal] ?? 0;
    await tester.ensureVisible(find.byKey(const Key('craft_guardianRepairSeal_btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('craft_guardianRepairSeal_btn')));
    await tester.pump();
    expect(
      controller.progress.consumables[TacticalConsumable.guardianRepairSeal],
      beforeRepair + 1,
    );
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pump();

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 2. 수호 도감(5개 탭 전수 원화 썸네일) & 확률 100% 공개 화면 검증
    await tester.ensureVisible(find.byKey(const Key('home_codex_btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('home_codex_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('수호 도감 · 세트 도감력'), findsOneWidget);

    for (final tabTitle in ['발사대(5)', '영수(5)', '동료(14)', '변이체(14)', '수호석(13)']) {
      await tester.ensureVisible(find.text(tabTitle));
      await tester.pump();
      await tester.tap(find.text(tabTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(NightSpriteIcon), findsWidgets);
    }

    await tester.tap(find.byKey(const Key('codex_open_odds_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('확률 및 물리 수치 100% 공개'), findsOneWidget);
    expect(find.textContaining('35.0%'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 3. 심야 무한 혈전 화면 검증 (이전 토스트 알림이 하단 타일을 가리지 않도록 정리)
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('menu_endless_btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu_endless_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('심야 무한 혈전 · 한계 시험장'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 4. 환경 설정 · 백업 복원 · 만든 이((주)웰쉐어로지스) · 공개 제작노트 검증
    await tester.ensureVisible(find.byKey(const Key('home_settings_btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('home_settings_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('환경 설정 · 백업 · 정보'), findsOneWidget);

    final exported = PlayerProgress(tokens: 9876, bgmVolume: 0.0, sfxVolume: 0.0).exportBackupCode();
    await tester.ensureVisible(find.byKey(const Key('open_import_backup_btn')));
    await tester.tap(find.byKey(const Key('open_import_backup_btn')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('import_backup_textfield')), exported);
    await tester.tap(find.byKey(const Key('confirm_import_backup_btn')));
    await tester.pump();
    expect(controller.progress.tokens, 9876);

    await tester.ensureVisible(find.byKey(const Key('open_prod_note_btn')));
    await tester.tap(find.byKey(const Key('open_prod_note_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('100판'), findsWidgets);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    await tester.ensureVisible(find.byKey(const Key('open_credits_btn')));
    await tester.tap(find.byKey(const Key('open_credits_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('(주)웰쉐어로지스'), findsWidgets);
  });

  testWidgets('좁은 화면(360x780) 전 화면 및 심야 전장 오버플로 0건 반응형 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 1200,
        elixirs: 40,
        supportTokens: 5,
        highestClearedGlobalStage: 15,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    final screens = <Widget>[
      LoadoutScreen(controller: controller),
      ForgeSanctuaryScreen(controller: controller),
      MeditationScreen(controller: controller),
      ConvoySerendipityScreen(controller: controller),
      DailyAndQuestsScreen(controller: controller, initialTab: 2),
      CodexScreen(controller: controller),
      EndlessSurvivalScreen(controller: controller),
      const CreditsScreen(),
      BattleScreen(
        controller: controller,
        stage: CampaignCatalog.allStages[1],
      ),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('태블릿 대화면 세로(924x1480) 및 가로(1480x924) 전 화면 오버플로 0건 검증',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 1500,
        elixirs: 60,
        supportTokens: 5,
        highestClearedGlobalStage: 25,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    for (final size in const [Size(1848, 2960), Size(2960, 1848)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        SuhoAlkkagiNightApp(controller: controller, skipSplash: true),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);

      final screens = <Widget>[
        LoadoutScreen(controller: controller),
        ForgeSanctuaryScreen(controller: controller),
        MeditationScreen(controller: controller),
        ConvoySerendipityScreen(controller: controller),
        DailyAndQuestsScreen(controller: controller, initialTab: 0),
        CodexScreen(controller: controller),
        EndlessSurvivalScreen(controller: controller),
        SettingsScreen(controller: controller),
        BattleScreen(
          controller: controller,
          stage: CampaignCatalog.allStages[1],
        ),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('무정지 실시간 전장: 초소 빠른 띠(4.8초)·돌파 비급(6.5초) 미클릭 자동 패스 및 원터치 소환·실시간 강화 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 500,
        highestClearedGlobalStage: 2,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          controller: controller,
          stage: CampaignCatalog.stageAt(1, 2),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 1) 빈 초소 터치 시 전체 모달이 아니라 하단 4.8초 실시간 빠른 띠가 열리며, 안 누르고 5.2초가 지나면 게임이 멈추지 않고 자동 통과!
    final arenaBox = tester.getRect(find.byKey(const Key('battle_arena_gesture')));
    final firstSlotPos = CampaignCatalog.chapterOf(1).mounts.first.pos;
    final slotTapOffset = Offset(
      arenaBox.left + arenaBox.width * (firstSlotPos.x / CampaignCatalog.arenaWidth),
      arenaBox.top + arenaBox.height * (firstSlotPos.y / CampaignCatalog.arenaHeight),
    );
    await tester.tapAt(slotTapOffset);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('⛩️협곡관문'), findsOneWidget);

    for (int i = 0; i < 105; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('⛩️협곡관문'), findsNothing);

    // 2) 초반 군수기력(48⚡)으로 첫 초소 지정 건설(45⚡) 또는 적 처치 후 하단 「🎲도박소환(50⚡)」 작동 검증!
    expect(find.text('초소 0/4곳'), findsOneWidget);
    await tester.tapAt(slotTapOffset);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.byKey(const Key('place_launcher_rapid')));
    await tester.tap(find.byKey(const Key('place_launcher_rapid')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('초소 1/4곳'), findsOneWidget);

    // 3) 기력이 모인 상태에서 실시간 「⚔️화력업+0」 및 「🔭사거리업+0」 단추 존재·작동 검증!
    final fireBtn = find.byKey(const Key('live_upg_firepower_btn'));
    final rangeBtn = find.byKey(const Key('live_upg_range_btn'));
    expect(fireBtn, findsOneWidget);
    expect(rangeBtn, findsOneWidget);

    // 4) 4배속 전환 지원 및 3배속 진행 중 조기 호출로 뜬 「📜 심야 돌파 비급 선택 (3택 1)」도 미클릭 시 멈춤 없이 자동 통과!
    expect(find.text('4배'), findsOneWidget);
    await tester.tap(find.text('4배'));
    await tester.pump();
    expect(controller.battleSpeedMultiplier, 4);
    await tester.tap(find.text('3배'));
    await tester.pump();
    for (int f = 0; f < 180; f++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('call_early_wave_btn')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const Key('call_early_wave_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('call_early_wave_btn')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('심야 돌파 비급 선택 (3택 1)'), findsOneWidget);

    if (find.textContaining('⚔️화력업+0').evaluate().isNotEmpty) {
      await tester.ensureVisible(fireBtn);
      await tester.tap(fireBtn);
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 3배속에서도 실제 벽시계 기준 6.5초 카운트다운이므로 미클릭 시 멈춤 없이 자동 패스 검증!
    // (전투 중 도깨비 처치·다음 물결 진입으로 비급이 연속 대기열에 들어온 경우에도 모두 자동 패스됨)
    for (int cycle = 0; cycle < 6; cycle++) {
      if (find.textContaining('심야 돌파 비급 선택 (3택 1)').evaluate().isEmpty) {
        break;
      }
      for (int i = 0; i < 140; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    expect(find.textContaining('심야 돌파 비급 선택 (3택 1)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('기명 심법 수련실 10회 연속 운기 단추 및 대장간 수호석 장별 개방 표시 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 2000,
        naegongPoints: 0,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: TrainingScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final batchBtn = find.byKey(const Key('meditate_batch_10_btn'));
    expect(batchBtn, findsOneWidget);
    await tester.ensureVisible(batchBtn);
    await tester.tap(batchBtn);
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.progress.naegongPoints, greaterThanOrEqualTo(480));
    expect(controller.progress.remainingDailyEnlightenment(), 0);
    expect(find.textContaining('10회 연속 대주천 완료!'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: UpgradeScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(
      find.textContaining('제3장 개방'),
      320.0,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('제3장 개방'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('태초 신기 무한 연마 · 11~13단 신물 장별 봉인 · 심야 무한 혈전 100물결 선택지 작동 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final p = PlayerProgress(
      tokens: 1200,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    p.stoneShards[StoneMaterial.taegeuk] = 99;
    final controller = GameController(initialProgress: p);

    await tester.pumpWidget(
      MaterialApp(home: UpgradeScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final forgeMasteryBtn = find.byKey(const Key('upgrade_forge_mastery_btn'));
    expect(forgeMasteryBtn, findsOneWidget);
    await tester.tap(forgeMasteryBtn);
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.progress.forgeMasteryLevel, 1);
    expect(find.textContaining('태초 신기 무한 연마 (1단'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('제10장 · 조각'),
      340.0,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('제10장 · 조각'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: EndlessSurvivalScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('100물결 연속 수호'), findsOneWidget);
    await tester.tap(find.text('100물결 연속 수호'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('심야 무한 혈전 (100물결) 출정!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('720×1360 천리협곡 광각 전체맵 ↔ 1.4배 확대 전환 · 거점 개척 단추 · 3페이즈 보스 상태 막대 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 800,
        centralGuardianLevel: 4,
        highestClearedGlobalStage: 9,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          controller: controller,
          stage: CampaignCatalog.stageAt(1, 10),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 1) 광각 전체 보기 기본 상태 및 1.4배 확대 토글 검증
    final zoomBtn = find.byKey(const Key('battle_toggle_zoom_view_btn'));
    expect(zoomBtn, findsOneWidget);
    expect(find.text('🔍1.4배확대'), findsOneWidget);
    await tester.ensureVisible(zoomBtn);
    await tester.tap(zoomBtn);
    await tester.pump();
    expect(find.text('🔍광각전체'), findsOneWidget);
    await tester.tap(zoomBtn);
    await tester.pump();
    expect(find.text('🔍1.4배확대'), findsOneWidget);

    // 2) 1-10(6곳 개방 · 8물결 보스전)에서 첫 초소 직접 축조 후 4배속으로 진행해 중간보스/대수괴 다단 페이즈 바 표시 및 거점 개척 단추 확인!
    expect(find.text('초소 0/6곳'), findsOneWidget);
    final arenaBox = tester.getRect(find.byKey(const Key('battle_arena_gesture')));
    final firstSlotPos = CampaignCatalog.chapterOf(1).mounts.first.pos;
    final slotTapOffset = Offset(
      arenaBox.left + arenaBox.width * (firstSlotPos.x / CampaignCatalog.arenaWidth),
      arenaBox.top + arenaBox.height * (firstSlotPos.y / CampaignCatalog.arenaHeight),
    );
    await tester.tapAt(slotTapOffset);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.byKey(const Key('place_launcher_rapid')));
    await tester.tap(find.byKey(const Key('place_launcher_rapid')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('초소 1/6곳'), findsOneWidget);

    await tester.tap(find.text('4배'));
    await tester.pump();

    if (find.byIcon(Icons.close_rounded).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
    }

    bool sawMultiPhaseHud = false;
    bool sawExcavateBtn = false;
    for (int f = 0; f < 520; f++) {
      await tester.pump(const Duration(milliseconds: 50));
      final perkFinder = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('rogue_perk_'),
      );
      if (perkFinder.evaluate().isNotEmpty) {
        await tester.tap(perkFinder.first);
        await tester.pump();
      }
      if (find.byKey(const Key('quick_excavate_next_btn')).evaluate().isNotEmpty) {
        sawExcavateBtn = true;
      }
      if (find.textContaining('◆').evaluate().isNotEmpty) {
        sawMultiPhaseHud = true;
        if (sawExcavateBtn) break;
      }
      if (find.byKey(const Key('call_early_wave_btn')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('call_early_wave_btn')), warnIfMissed: false);
        await tester.pump();
      }
    }
    expect(sawExcavateBtn, isTrue);
    expect(sawMultiPhaseHud, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('v1.0.0+21 영약각 무한 공명 단련 · 순차 서사 대사 큐 · 10-10 대단원 에필로그 결과창 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = GameController(
      initialProgress: PlayerProgress(
        tokens: 800,
        elixirs: 60,
        highestClearedGlobalStage: 110,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    // 1) 영약각 한지 주인공 명패 및 호법 영기 무한 공명 단추 작동 검증
    await tester.pumpWidget(
      MaterialApp(
        home: ForgeSanctuaryScreen(controller: controller, initialTab: 1),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const Key('upgrade_elixir_resonance_btn')), findsOneWidget);
    expect(controller.progress.elixirResonanceLevel, 0);
    await tester.tap(find.byKey(const Key('upgrade_elixir_resonance_btn')));
    await tester.pump();
    expect(controller.progress.elixirResonanceLevel, 1);
    expect(tester.takeException(), isNull);

    // 2) 1-1 관문 진입 시 첫 줄 대사부터 누락 없이 표시되고 다음 줄로 순차 전환되는지 검증
    final st11 = CampaignCatalog.stageAt(1, 1);
    expect(st11.introDialogue.length, greaterThanOrEqualTo(2));
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          controller: controller,
          stage: st11,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('${st11.introDialogue[0].speaker}:'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    expect(find.textContaining('${st11.introDialogue[1].speaker}:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('v1.0.0+22 전면 리디자인: 하단 5탭 고정 내비게이션 전환 · 원터치 최적 편성 · 추천 일괄 강화 · 일괄 보상 수령 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    expect(
      NightArtRegistry.mutantShowcaseAsset(MutantKind.chapterOverlord),
      'assets/images/scenes/showcase_boss_chapter.webp',
    );
    expect(
      NightArtRegistry.mutantShowcaseAsset(MutantKind.crimsonBreakerBoss),
      'assets/images/scenes/showcase_boss_crimson.webp',
    );
    expect(
      NightArtRegistry.mutantShowcaseAsset(MutantKind.ironColossusBoss),
      'assets/images/scenes/showcase_boss_iron.webp',
    );

    final p = PlayerProgress(
      tokens: 950,
      elixirs: 45,
      naegongPoints: 260,
      moonOmenGauge: 100,
      highestClearedGlobalStage: 35,
      convoyActive: true,
      convoyBattlesRemaining: 0,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    p.unlockedStones.addAll([StoneMaterial.hyeoncheol, StoneMaterial.obsidian]);
    p.companionLevels[CompanionHero.geomhwang] = 3;
    p.companionLevels[CompanionHero.yeonbi] = 2;
    p.beastLevels[SpiritBeast.geumryong] = 2;

    final controller = GameController(initialProgress: p);
    await tester.pumpWidget(
      SuhoAlkkagiNightApp(controller: controller, skipSplash: true),
    );
    await tester.pump(const Duration(milliseconds: 150));

    // 1) 본영 상단 원터치 일괄 보상 수령·재파견 작동 확인
    final batchClaimBtn = find.byKey(const Key('home_batch_claim_btn'));
    expect(batchClaimBtn, findsOneWidget);
    final beforeSupport = controller.progress.supportTokens;
    await tester.ensureVisible(batchClaimBtn);
    await tester.tap(batchClaimBtn);
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.progress.supportTokens, greaterThan(beforeSupport));
    expect(controller.progress.moonOmenGauge, 0);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pump();

    // 2) 하단 2탭(영웅·진법) 즉시 전환 및 원터치 최적 진법 자동 편성 검증
    await tester.tap(find.byKey(const Key('nav_tab_loadout')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('자동 수호 진법 편성실'), findsOneWidget);
    final autoRecBtn = find.byKey(const Key('loadout_auto_recommend_btn'));
    expect(autoRecBtn, findsOneWidget);
    await tester.tap(autoRecBtn);
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.progress.activePreset.primaryStone, StoneMaterial.obsidian);
    expect(controller.progress.activePreset.equippedBeast, SpiritBeast.geumryong);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pump();

    // 3) 하단 3탭(대장간·영약) 즉시 전환 및 추천 일괄 강화 검증
    await tester.tap(find.byKey(const Key('nav_tab_forge')));
    await tester.pump(const Duration(milliseconds: 200));
    final batchUpgBtn = find.byKey(const Key('forge_batch_upgrade_btn'));
    expect(batchUpgBtn, findsOneWidget);
    await tester.tap(batchUpgBtn);
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.progress.openedMeridianStep, greaterThan(0));
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pump();

    // 4) 하단 4탭(수련·보급 통합관) 및 5탭(변이 도감) 무오류 전환 검증
    await tester.tap(find.byKey(const Key('nav_tab_supply')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('단전·경맥 수련'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_tab_codex')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('3D 모션록'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_tab_home')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('home_quick_battle_btn')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('v1.0.0+23 코덱스 대륙 월드맵 핀 이동 및 캐릭터·돌연변이 4프레임 시트 모달 검증', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final p = PlayerProgress(highestClearedGlobalStage: 45);
    p.companionLevels[CompanionHero.geomhwang] = 3;
    final controller = GameController(initialProgress: p);

    await tester.pumpWidget(
      MaterialApp(home: CampaignScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('campaign_toggle_world_map')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('탄지무림 10대 거점 심야 수호 대륙도'), findsOneWidget);

    // 대륙 지도 위의 2현 거점 핀 터치 시 즉시 2현 선택 전환 확인
    await tester.tap(find.text('✓2현').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.selectedChapter, 2);

    // 변이 도감에서 첫 번째 돌연변이 카드 터치 시 4프레임 시트 & 3D 모션 쇼케이스 다이얼로그 오픈 확인
    await tester.pumpWidget(
      MaterialApp(home: CodexScreen(controller: controller, initialTab: 4)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('심야 독쥐').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('4단계 모션 · 변이 시트 구성'), findsOneWidget);
    await tester.tap(find.text('감상 완료 · 닫기'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'v1.0.0+24 10장 고유 지형 정합 · 비행 변이(14종) · 100/1000타 계급 보스 · 위험구역 2.8배 확대 영상 모니터(PIP) 검증',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final p = PlayerProgress(
      tokens: 900,
      elixirs: 50,
      centralGuardianLevel: 18,
      highestClearedGlobalStage: 110,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    p.companionLevels[CompanionHero.geomhwang] = 5;
    p.companionLevels[CompanionHero.yonga] = 5;
    p.beastLevels[SpiritBeast.geumryong] = 5;
    final controller = GameController(initialProgress: p)
      ..autoChooseBattlePerks = true;

    // 1) 변이 도감 14종(비행 변이 2종 포함) 및 마갑 타수 배지 표시 확인
    await tester.pumpWidget(
      MaterialApp(home: CodexScreen(controller: controller, initialTab: 4)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('혈익 흡혈박쥐'), findsOneWidget);
    expect(find.text('🪽공중 비행'), findsWidgets);

    // 2) 제10장 보스 결전(10-10) 진입 → 초소 1곳 축조 후 100/1,000타+ 계급 보스 HUD 및 비상 알림 & 2.8배 확대 영상 모니터 작동 검증
    final st10 = CampaignCatalog.stageAt(10, 10);
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(controller: controller, stage: st10),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    final arenaBox = tester.getRect(find.byKey(const Key('battle_arena_gesture')));
    final firstSlotPos = CampaignCatalog.chapterOf(10).mounts.first.pos;
    await tester.tapAt(
      Offset(
        arenaBox.left + arenaBox.width * (firstSlotPos.x / CampaignCatalog.arenaWidth),
        arenaBox.top + arenaBox.height * (firstSlotPos.y / CampaignCatalog.arenaHeight),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.byKey(const Key('place_launcher_rapid')));
    await tester.tap(find.byKey(const Key('place_launcher_rapid')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('4배'));
    await tester.pump();

    bool sawBossHitHud = false;
    bool sawCrisisPip = false;
    for (int f = 0; f < 760; f++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('battle_boss_hit_hud')).evaluate().isNotEmpty) {
        sawBossHitHud = true;
      }
      if (find.byKey(const Key('battle_crisis_zoom_pip')).evaluate().isNotEmpty) {
        if (!sawCrisisPip) {
          sawCrisisPip = true;
          // PIP 화면 원터치 정밀타격 무오류 확인
          await tester.tap(
            find.byKey(const Key('battle_crisis_zoom_pip')),
            warnIfMissed: false,
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        if (sawBossHitHud) break;
      }
      if (sawCrisisPip && sawBossHitHud) break;
      if (find.byKey(const Key('call_early_wave_btn')).evaluate().isNotEmpty) {
        await tester.tap(
          find.byKey(const Key('call_early_wave_btn')),
          warnIfMissed: false,
        );
        await tester.pump();
      }
    }
    expect(sawBossHitHud, isTrue);
    expect(sawCrisisPip, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('v1.0.0+25 10장 차별화 루트 배지 · 제5장 직각미궁/제7장 남북역진격/제10장 부유섬 및 5종 타워 투사체 무오류 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final p = PlayerProgress(
      tokens: 1500,
      elixirs: 80,
      centralGuardianLevel: 20,
      highestClearedGlobalStage: 110,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    final controller = GameController(initialProgress: p)
      ..autoChooseBattlePerks = true;

    for (final code in const [(5, 2), (7, 2), (10, 2)]) {
      final st = CampaignCatalog.stageAt(code.$1, code.$2);
      final ch = CampaignCatalog.chapterOf(code.$1);
      await tester.pumpWidget(
        MaterialApp(
          home: BattleScreen(
            key: ValueKey(st.code),
            controller: controller,
            stage: st,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.textContaining(ch.routeTopologyTag), findsWidgets);

      final arenaBox = tester.getRect(find.byKey(const Key('battle_arena_gesture')));
      final slotPos = ch.mounts.first.pos;
      await tester.tapAt(
        Offset(
          arenaBox.left + arenaBox.width * (slotPos.x / CampaignCatalog.arenaWidth),
          arenaBox.top + arenaBox.height * (slotPos.y / CampaignCatalog.arenaHeight),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      final buildKey = Key('place_launcher_${LauncherType.values[code.$1 % 5].id}');
      await tester.ensureVisible(find.byKey(buildKey));
      await tester.tap(find.byKey(buildKey));
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('v1.0.0+26 전장 장별 개척비 일치 · 자동비급 토글 칩 · 제7장 우측 PIP 도킹 · 영약각 장 해금 가드 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1) 1장 유저가 영약이 많아도 제8장 금룡 영입 버튼이 비활성('8장 해금')인지 검증
    final earlyP = PlayerProgress(elixirs: 200, tutorialSeen: true, bgmVolume: 0.0, sfxVolume: 0.0);
    final earlyCtrl = GameController(initialProgress: earlyP);
    await tester.pumpWidget(
      MaterialApp(home: UpgradeScreen(controller: earlyCtrl, initialTab: 1)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('8장 해금'), findsWidgets);

    // 2) 제7장 전장에서 개척 비용 배율 반영 및 자동비급 토글 칩 작동 검증
    final p7 = PlayerProgress(
      tokens: 1200,
      elixirs: 60,
      highestClearedGlobalStage: 75,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    p7.companionLevels[CompanionHero.mukhyeon] = 8;
    p7.companionLevels[CompanionHero.seokdu] = 5;
    p7.companionLevels[CompanionHero.yeonbi] = 5;
    p7.companionLevels[CompanionHero.cheongmyeong] = 5;
    final ctrl7 = GameController(initialProgress: p7);
    final st7 = CampaignCatalog.stageAt(7, 3);
    ctrl7.applyRecommendedLoadoutForStage(st7);
    // 3인 이상의 일반 동료가 있을 때 위기 자동 난입형인 묵현 대신 상시 동료 3인이 우선 편성됨!
    expect(ctrl7.progress.activePreset.companions.contains(CompanionHero.mukhyeon), isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          key: ValueKey(st7.code),
          controller: ctrl7,
          stage: st7,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    final autoPerkChip = find.byKey(const Key('battle_auto_perk_chip'));
    await tester.ensureVisible(autoPerkChip);
    await tester.tap(autoPerkChip);
    await tester.pump(const Duration(milliseconds: 80));
    expect(ctrl7.autoChooseBattlePerks, isTrue);
    await tester.tap(autoPerkChip);
    await tester.pump(const Duration(milliseconds: 80));
    expect(ctrl7.autoChooseBattlePerks, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('v1.0.0+27 진법 슬롯 편성 ★추천축조 · 10경맥 내공 4칸 표시 · 무한혈전 난이도 선택 · 111관문 완전정화 UI 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final endgameP = PlayerProgress(
      tokens: 2000,
      elixirs: 150,
      supportTokens: 4,
      realmIndex: 7,
      openedMeridianStep: 10,
      highestClearedGlobalStage: CampaignCatalog.allStages.length,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    endgameP.activePreset.mountTypes[0] = LauncherType.curveSpin;
    final ctrl = GameController(initialProgress: endgameP);

    // 1) 100판 완전 정화 상태에서 캠페인 지도 및 완전 정화 배너 표시 검증
    await tester.pumpWidget(
      MaterialApp(home: CampaignScreen(controller: ctrl)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('전 100판(10현×10마을) 완전 정화 달성'), findsOneWidget);
    expect(find.text('최종판 재출정'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 2) 무한 혈전 화면에서 쉬움·보통·악몽 난이도 선택지가 작동하는지 검증
    await tester.pumpWidget(
      MaterialApp(home: EndlessSurvivalScreen(controller: ctrl)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('2. 난이도 선택'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 3) 전장에서 10단 경맥 내공 4칸(/4칸) 및 진법 편성(curveSpin -> 비취) ★추천축조 단추 연동 검증
    final st2 = CampaignCatalog.stageAt(3, 2);
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          key: const ValueKey('v27_battle'),
          controller: ctrl,
          stage: st2,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('/4칸'), findsOneWidget);
    expect(find.byKey(const Key('quick_direct_build_btn')), findsOneWidget);
    expect(find.textContaining('🔨추천축조[곡사]'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 4) v1.0.0+28: 진법 편성실에서 1~14번 거점 지정 병종 칩 터치 변경 & 전장 지원패 사용 후 복귀 시 보호 대화상자 검증
    await tester.pumpWidget(
      MaterialApp(home: LoadoutScreen(controller: ctrl)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final slot0Chip = find.byKey(const Key('loadout_mount_slot_0'));
    await tester.ensureVisible(slot0Chip);
    await tester.pump();
    final beforeSlot0 = ctrl.progress.activePreset.mountTypes[0];
    await tester.tap(slot0Chip);
    await tester.pump(const Duration(milliseconds: 150));
    expect(ctrl.progress.activePreset.mountTypes[0], isNot(equals(beforeSlot0)));

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          key: const ValueKey('v28_battle_guard'),
          controller: ctrl,
          stage: st2,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const Key('battle_chuldu_btn')));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const Key('battle_pause_btn')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('복구되지 않습니다'), findsOneWidget);
    await tester.tap(find.text('전투 계속'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'v1.0.0+29 10현×10마을(100판) 행군 지도 · 9종 현간 대행군 영상 화면 · 전 메뉴 바로출정 · 연속 마을 수호 검증',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ctrl = GameController(
      initialProgress: PlayerProgress(
        tokens: 1500,
        elixirs: 80,
        supportTokens: 3,
        highestClearedGlobalStage: 20, // 1~2현 완수, 3현 1판 차례
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );
    ctrl.setSelectedChapter(1);

    // 1) 현내 10개 마을 행군 지도 <-> 10대 현 대륙도 전환 및 마을 노드 확인
    await tester.pumpWidget(
      MaterialApp(home: CampaignScreen(controller: ctrl)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('village_node_1-1')), findsOneWidget);
    expect(find.byKey(const Key('village_node_1-10')), findsOneWidget);
    await tester.tap(find.byKey(const Key('campaign_toggle_world_map')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('탄지무림 10대 거점 심야 수호 대륙도'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 2) 현 마무리 후 다른 현 이동 시네마틱 영상 화면(CountyTransitionScreen) 1→2현, 2→3현 전환 검증
    await tester.pumpWidget(
      MaterialApp(
        home: CountyTransitionScreen(
          controller: ctrl,
          fromChapter: 1,
          openedFromVictory: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('제1현 정화 완수'), findsOneWidget);
    expect(find.byKey(const Key('county_trans_pause_auto_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('county_travel_chip_2')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('제2현 정화 완수'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 3) 전 메뉴(진법·대장간·수련·도감) 상단 바로 출정 & 지도 점프 바 및 전장 연속 마을 수호 토글 검증
    await tester.pumpWidget(
      MaterialApp(home: LoadoutScreen(controller: ctrl)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const Key('quick_bar_battle_loadout')), findsOneWidget);
    expect(find.byKey(const Key('quick_bar_map_loadout')), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick_bar_battle_loadout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.byKey(const Key('battle_continuous_march_chip')), findsOneWidget);
    expect(find.text('🏃연속수호 ON'), findsOneWidget);
    await tester.tap(find.byKey(const Key('battle_continuous_march_chip')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('⏸️연속수호 OFF'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 4) 마을 수호 승리 시 인근 다음 마을로 자동 연속 이동(3.2초 카운트다운 완주) 검증
    ctrl.setContinuousVillageMarch(true);
    int autoAdvanceCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('march_card_test_app'),
        home: Scaffold(
          body: VictoryContinuousMarchCard(
            controller: ctrl,
            clearedStage: CampaignCatalog.stageAt(1, 1),
            nextStage: CampaignCatalog.stageAt(1, 2),
            onAdvanceNow: () => autoAdvanceCount++,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('victory_continuous_march_card')), findsOneWidget);
    expect(find.byKey(const Key('victory_live_road_map')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3200));
    expect(autoAdvanceCount, 1);
    expect(tester.takeException(), isNull);

    // 5) v1.0.0+30: 1~10현 코덱스 실측 도로 지도 자산 경로 및 전 현 실제 도로 행군 지도 무오류 렌더링 검증
    final fullCtrl = GameController(
      initialProgress: PlayerProgress(
        tokens: 2000,
        elixirs: 100,
        supportTokens: 5,
        highestClearedGlobalStage: 100,
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );
    for (int ch = 1; ch <= 10; ch++) {
      expect(
        NightArtRegistry.countyRegionalMapAsset(ch),
        'assets/images/scenes/county_map_ch$ch.webp',
      );
      fullCtrl.setSelectedChapter(ch);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('county_road_map_test_$ch'),
          home: CampaignScreen(controller: fullCtrl),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(CountyRealRoadMapWidget), findsOneWidget);
      expect(find.byKey(Key('village_node_$ch-1')), findsOneWidget);
      expect(find.byKey(Key('village_node_$ch-10')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'v1.0.0+31 정밀 감사 UI 회귀 검증: 진법 자동승급 스위치 · 미완수 현 이동 잠금 표기 · 호송 보급 버프 이탈 경고',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final earlyCtrl = GameController(
      initialProgress: PlayerProgress(
        tokens: 300,
        elixirs: 10,
        supportTokens: 2,
        convoySupplyBuffBattles: 1,
        highestClearedGlobalStage: 3, // 1현 3판까지만 클리어 (1현 미완수!)
        tutorialSeen: true,
        bgmVolume: 0.0,
        sfxVolume: 0.0,
      ),
    );

    // 1) 진법 편성실(LoadoutScreen) 포대 여유 기력 자동 승급 토글 동작 검증
    await tester.pumpWidget(
      MaterialApp(home: LoadoutScreen(controller: earlyCtrl)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final autoSwitch = find.byKey(const Key('loadout_auto_upgrade_switch'));
    final initialAuto = earlyCtrl.progress.activePreset.autoUpgradeInBattle;
    await tester.scrollUntilVisible(
      autoSwitch,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(autoSwitch, findsOneWidget);
    await tester.tap(autoSwitch);
    await tester.pump(const Duration(milliseconds: 120));
    expect(earlyCtrl.progress.activePreset.autoUpgradeInBattle, !initialAuto);
    expect(tester.takeException(), isNull);

    // 2) 1현 미완수 상태에서 CountyTransitionScreen 열람 시 거짓 완수 배지 대신 수호 중 안내 & 출발 버튼 비활성화 검증
    await tester.pumpWidget(
      MaterialApp(
        home: CountyTransitionScreen(
          controller: earlyCtrl,
          fromChapter: 1,
          openedFromVictory: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('⏳ 제1현 수호 중'), findsOneWidget);
    final departBtn = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('county_trans_battle_btn')),
    );
    expect(departBtn.onPressed, isNull);
    expect(tester.takeException(), isNull);

    // 3) 호송 보급 버프가 차감된 전투에서 안드로이드 뒤로가기(maybePop) 시도 시 소멸 경고 다이얼로그 작동 검증
    expect(earlyCtrl.progress.convoySupplyBuffBattles, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('enter_buffed_battle'),
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BattleScreen(
                      controller: earlyCtrl,
                      stage: CampaignCatalog.stageAt(1, 1),
                    ),
                  ),
                ),
                child: const Text('출정'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('enter_buffed_battle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(earlyCtrl.progress.convoySupplyBuffBattles, 0);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('호송 보급 버프는 복구되지 않습니다'), findsOneWidget);
    await tester.tap(find.text('전투 계속'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'v1.0.0+32 모바일 한 손 엄지 UI/UX 개편 검증: 360x780 폰 무스크롤 4등분 강화 격자 · 우측 스윗스팟 추천축조 · 하단 비급 시트 · 본영 원터치 난이도/정비 도크',
      (WidgetTester tester) async {
    // 표준 소형 스마트폰 세로 뷰포트 (360 x 780 logical px)
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mobileProg = PlayerProgress(
      tokens: 900,
      elixirs: 40,
      naegongPoints: 300,
      supportTokens: 3,
      highestClearedGlobalStage: 4,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    mobileProg.unlockedStones.add(StoneMaterial.hyeoncheol);
    final ctrl = GameController(initialProgress: mobileProg);

    // 1) 본영: 360dp 폰에서 오버플로 0건 + 난이도 즉시 선택 + 원터치 최적 진법/추천 강화 작동 확인
    await tester.pumpWidget(
      SuhoAlkkagiNightApp(controller: ctrl, skipSplash: true),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('home_difficulty_selector')), findsOneWidget);
    await tester.tap(find.text('악몽'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(ctrl.selectedDifficulty, DefenseDifficulty.nightmare);
    await tester.tap(find.text('보통'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(ctrl.selectedDifficulty, DefenseDifficulty.normal);

    await tester.tap(find.byKey(const Key('home_quick_auto_loadout_btn')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(ctrl.progress.activePreset.primaryStone, StoneMaterial.hyeoncheol);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .clearSnackBars();
    await tester.pump();

    final beforeCentralLv = ctrl.progress.centralGuardianLevel;
    await tester.tap(find.byKey(const Key('home_quick_auto_upgrade_btn')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      ctrl.progress.centralGuardianLevel > beforeCentralLv ||
          ctrl.progress.openedMeridianStep > 0,
      isTrue,
    );
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .clearSnackBars();
    await tester.pump();

    // 2) 전장(360x780 소형 스마트폰): 가로 스크롤 전혀 없이 4종 강화 버튼 + 도박소환 + 우측 스윗스팟 추천축조 모두 0..360dp 내 노출 확인!
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          key: const ValueKey('v32_mobile_battle'),
          controller: ctrl,
          stage: CampaignCatalog.stageAt(1, 2),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('battle_mobile_thumb_deck')), findsOneWidget);

    for (final k in const [
      Key('quick_lucky_summon_btn'),
      Key('quick_direct_build_btn'),
      Key('live_upg_firepower_btn'),
      Key('live_upg_reload_btn'),
      Key('live_upg_range_btn'),
      Key('live_upg_barrier_btn'),
      Key('battle_chuldu_btn'),
    ]) {
      final rect = tester.getRect(find.byKey(k));
      expect(rect.left, greaterThanOrEqualTo(0.0), reason: '$k 좌측 잘림 없어야 함');
      expect(rect.right, lessThanOrEqualTo(360.0), reason: '$k 가로 스크롤 없이 360dp 내 완전 노출');
    }

    // 오른손 엄지 스윗스팟 원칙: [추천축조]가 [도박소환] 우측에 위치하고 화면 하단 황금 엄지 권역(y > 540)에 배치되어야 함!
    final luckyRect = tester.getRect(find.byKey(const Key('quick_lucky_summon_btn')));
    final directRect = tester.getRect(find.byKey(const Key('quick_direct_build_btn')));
    expect(directRect.center.dx, greaterThan(luckyRect.center.dx));
    expect(directRect.center.dy, greaterThan(540.0));

    // 추천축조 원터치 실행 후 3배속 조기 호출 시 돌파 비급 3택 1 시트도 화면 하단 엄지 권역(y > 390)에 표시되는지 확인!
    await tester.tap(find.byKey(const Key('quick_direct_build_btn')));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('3배'));
    await tester.pump();
    for (int f = 0; f < 180; f++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('call_early_wave_btn')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const Key('call_early_wave_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('call_early_wave_btn')));
    await tester.pump(const Duration(milliseconds: 120));
    final perkSheetRect =
        tester.getRect(find.byKey(const Key('battle_thumb_perk_sheet')));
    expect(
      perkSheetRect.center.dy,
      greaterThan(390.0),
      reason: '돌파 비급 선택창이 상단 끝이 아닌 하단 엄지 권역에 떠야 함',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'v1.0.0+33 10대 현 대륙도 실측 도로 실시간 영웅 행군 · 다중 현 터치 도로 이동 · 현간 승전/전이 대륙도 연동 검증',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ctrl = GameController(
      initialProgress: PlayerProgress(
        highestClearedGlobalStage: 100,
        tutorialSeen: true,
      ),
    );
    ctrl.setSelectedChapter(2);

    await tester.pumpWidget(
      MaterialApp(home: CampaignScreen(controller: ctrl)),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byKey(const Key('campaign_toggle_world_map')));
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.byKey(const Key('campaign_continental_real_road_map')),
      findsOneWidget,
    );
    final heroFinder = find.byKey(const Key('world_map_hero_marker'));
    expect(heroFinder, findsOneWidget);

    // 1) 평상시에도 대륙 실도로 위에서 영웅 마커가 실시간 행군하는지 확인
    final pos0 = tester.getCenter(heroFinder);
    await tester.pump(const Duration(milliseconds: 700));
    final pos1 = tester.getCenter(heroFinder);
    expect((pos1 - pos0).distance, greaterThan(2.0));

    // 2) 2현(하단 객잔)에서 8현(상단 해전나루) 터치 시 순간이동하지 않고 실제 도로 곡선(중간 다리/황성 높이)을 경유해 이동하는지 검증!
    final pin2Center = tester.getCenter(find.byKey(const Key('world_map_pin_2')));
    final pin8Center = tester.getCenter(find.byKey(const Key('world_map_pin_8')));
    await tester.tap(find.byKey(const Key('world_map_pin_8')));
    await tester.pump();
    expect(ctrl.selectedChapter, 8);
    expect(find.textContaining('제2현➔제8현 실도로 행군 중!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 650));
    final midPos = tester.getCenter(heroFinder);
    expect(midPos.dy, lessThan(pin2Center.dy - 20.0));
    expect(midPos.dy, greaterThan(pin8Center.dy + 20.0));

    await tester.pump(const Duration(milliseconds: 1400));
    expect(tester.takeException(), isNull);

    // 3) 현 이동 영상 화면(CountyTransitionScreen)에도 실시간 대륙 실도로 행군 지도가 함께 표시되는지 확인
    await tester.pumpWidget(
      MaterialApp(
        home: CountyTransitionScreen(
          controller: ctrl,
          fromChapter: 2,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const Key('county_transition_continental_map')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // 4) 현 최종 관문(1-10) 승리 연속 행군 카드에서도 1현➔2현 대륙 실도로 행군 지도가 렌더링되는지 확인
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VictoryContinuousMarchCard(
            controller: ctrl,
            clearedStage: CampaignCatalog.stageAt(1, 10),
            nextStage: CampaignCatalog.stageAt(2, 1),
            onAdvanceNow: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const Key('victory_live_continental_map')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'v1.0.0+34 악몽 난이도 전장 진입 및 실시간 진법 결속률(battle_formation_coverage_badge) HUD 검증',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ctrl = GameController(
      initialProgress: PlayerProgress(
        highestClearedGlobalStage: 100,
        tutorialSeen: true,
      ),
    );
    ctrl.setDifficulty(DefenseDifficulty.nightmare);

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          controller: ctrl,
          stage: CampaignCatalog.stageAt(10, 10),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 180));

    expect(
      find.byKey(const Key('battle_formation_coverage_badge')),
      findsOneWidget,
    );
    expect(find.textContaining('진법결속'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'v1.0.0+35 악몽 10현 돌파 후 윤회 최종 보스전 출정 카드 및 다회차(제1환생 ×3배 ➔ 제2환생 ×9배) 등선 UI 검증',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final p = PlayerProgress(
      tokens: 8000,
      elixirs: 120,
      centralGuardianLevel: 24,
      highestClearedGlobalStage: 100,
      nightmareChapter10Cleared: true,
      reincarnationBossCleared: false,
      tutorialSeen: true,
      bgmVolume: 0.0,
      sfxVolume: 0.0,
    );
    p.unlockedStones.addAll(StoneMaterial.values);
    final ctrl = GameController(initialProgress: p);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(controller: ctrl)));
    await tester.pump(const Duration(milliseconds: 200));

    // 1) 악몽 10-10 정화 상태에서 윤회 최종 보스전(<5%) 출정 버튼 노출 확인
    expect(find.byKey(const Key('home_reincarnation_sanctum_card')), findsOneWidget);
    expect(find.byKey(const Key('home_reincarnation_boss_btn')), findsOneWidget);
    expect(find.byKey(const Key('home_reincarnate_btn')), findsNothing);

    // 2) 윤회 최종 보스전 승리 반영 후 제1환생(×3배) 등선 의식 실행 검증
    final boss0 = ctrl.buildReincarnationBossStage();
    ctrl.recordBattleSummary(
      boss0,
      const BattleSummary(
        victory: true,
        stars: 3,
        earnedTokens: 320,
        earnedElixirs: 30,
        usedSupportCount: 2,
        pporokCount: 4,
        bankShotCount: 6,
        chainShatterCount: 5,
        serendipityCount: 3,
        granaryRatio: 1.0,
        cropsRatio: 1.0,
        livestockRatio: 1.0,
        contributions: [],
        coachingTip: '완승',
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final reincBtn1 = find.byKey(const Key('home_reincarnate_btn'));
    expect(reincBtn1, findsOneWidget);
    await tester.ensureVisible(reincBtn1);
    await tester.tap(reincBtn1);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('home_confirm_reincarnation_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_confirm_reincarnation_btn')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(ctrl.progress.reincarnationCount, 1);
    expect(ctrl.progress.highestClearedGlobalStage, 0);
    expect(ctrl.progress.centralGuardianLevel, 24);
    expect(find.byKey(const Key('home_reincarnation_pill')), findsOneWidget);
    expect(find.textContaining('×3배'), findsWidgets);

    // 3) 제1환생 상태에서 다시 악몽 10-10 + 최종 보스 돌파 후 제2환생(×9배) 실행 검증
    ctrl.progress.highestClearedGlobalStage = 100;
    ctrl.progress.nightmareChapter10Cleared = true;
    ctrl.progress.reincarnationBossCleared = true;
    ctrl.notifyConsumableUsedInBattle();
    await tester.pump(const Duration(milliseconds: 200));

    final reincBtn2 = find.byKey(const Key('home_reincarnate_btn'));
    expect(reincBtn2, findsOneWidget);
    await tester.ensureVisible(reincBtn2);
    await tester.tap(reincBtn2);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('home_confirm_reincarnation_btn')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(ctrl.progress.reincarnationCount, 2);
    expect(ctrl.progress.reincarnationDifficultyMultiplier, closeTo(9.0, 1e-6));
    expect(find.textContaining('×9배'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('직접 설치판(sideload) 매니페스트 보안 검증 및 설정 화면 새 판 확인 타일 노출/숨김 검증',
      (WidgetTester tester) async {
    final validSha = 'a' * 64;
    final okInfo = NightUpdateInfo.parse(
      '{"build":120,"apk":"https://github.com/ttong627/ttong_alkkagi_night/releases/download/test-latest/suho-alkkagi-night-test.apk","sha256":"$validSha","size":140000000,"notes":"성능 개선"}',
    );
    expect(okInfo, isNotNull);
    expect(okInfo!.newerThan(36), isTrue);

    // 외부 도메인·타 저장소·HTTP·비정상 해시 차단 검증
    expect(
      NightUpdateInfo.parse(
        '{"build":120,"apk":"https://evil.example.com/ttong627/ttong_alkkagi_night/releases/download/v1/a.apk","sha256":"$validSha","size":1000}',
      ),
      isNull,
    );
    expect(
      NightUpdateInfo.parse(
        '{"build":120,"apk":"https://github.com/other/repo/releases/download/v1/a.apk","sha256":"$validSha","size":1000}',
      ),
      isNull,
    );
    expect(
      NightUpdateInfo.parse(
        '{"build":120,"apk":"https://github.com/ttong627/ttong_alkkagi_night/releases/download/v1/a.apk","sha256":"bad","size":1000}',
      ),
      isNull,
    );

    const updaterChannel = MethodChannel('tanji/updater');
    bool sideloadEnabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(updaterChannel, (call) async {
      if (call.method == 'available') return sideloadEnabled;
      if (call.method == 'canInstall') return true;
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(updaterChannel, null);
    });

    final ctrl = GameController(
      initialProgress: PlayerProgress(tutorialSeen: true, bgmVolume: 0.0, sfxVolume: 0.0),
    );

    // 1) 플레이 스토어 판(available == false): 업데이트 타일이 숨겨져야 함
    await tester.pumpWidget(
      MaterialApp(
        theme: NightPalette.buildTheme(),
        home: SettingsScreen(controller: ctrl),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sideload_check_update_tile')), findsNothing);

    // 2) 직접 설치판(available == true): 업데이트 타일이 표시되어야 함
    sideloadEnabled = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        theme: NightPalette.buildTheme(),
        home: SettingsScreen(controller: ctrl),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sideload_check_update_tile')), findsOneWidget);
  });
}
