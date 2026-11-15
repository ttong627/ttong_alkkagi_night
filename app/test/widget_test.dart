import 'package:alkkagi_night/audio/night_audio.dart';
import 'package:alkkagi_night/main.dart';
import 'package:alkkagi_night/screens/battle_screen.dart';
import 'package:alkkagi_night/screens/codex_and_endless_screens.dart';
import 'package:alkkagi_night/screens/convoy_campaign_screens.dart';
import 'package:alkkagi_night/screens/daily_quests_screen.dart';
import 'package:alkkagi_night/screens/loadout_upgrade_screens.dart';
import 'package:alkkagi_night/screens/settings_and_credits_screen.dart';
import 'package:alkkagi_night/screens/training_screen.dart';
import 'package:alkkagi_night/state/game_controller.dart';
import 'package:alkkagi_night/ui/mutant_motion_engine.dart';
import 'package:alkkagi_night/ui/night_art_registry.dart';
import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';
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
    expect(NightArtRegistry.towerGuardian, 'assets/images/launchers/tower_guardian.webp');
    expect(NightArtRegistry.villageGranary, 'assets/images/launchers/village_granary.webp');
    expect(NightArtRegistry.villageCrops, 'assets/images/launchers/village_crops.webp');
    expect(NightArtRegistry.villageLivestock, 'assets/images/launchers/village_livestock.webp');

    expect(NightArtRegistry.appLogo, 'assets/images/icons/app_logo.webp');
    expect(NightArtRegistry.nightToken, 'assets/images/icons/night_token.webp');
    expect(NightArtRegistry.nightElixir, 'assets/images/icons/night_elixir.webp');
    expect(NightArtRegistry.nightSupportSeal, 'assets/images/icons/night_support_seal.webp');
    expect(NightArtRegistry.nightConvoyCart, 'assets/images/icons/night_convoy_cart.webp');
    expect(NightArtRegistry.nightSerendipity, 'assets/images/icons/night_serendipity.webp');
    expect(NightArtRegistry.nightMeridian, 'assets/images/icons/night_meridian.webp');
    expect(NightArtRegistry.nightEndless, 'assets/images/icons/night_endless.webp');

    expect(NightArtRegistry.fxChuldu, 'assets/images/fx/fx_chuldu.webp');
    expect(NightArtRegistry.fxBarrier, 'assets/images/fx/fx_barrier.webp');
    expect(NightArtRegistry.fxBreachGate, 'assets/images/fx/fx_breach_gate.webp');
    expect(NightArtRegistry.fxCritical, 'assets/images/fx/fx_critical.webp');
    expect(NightArtRegistry.fxShatter, 'assets/images/fx/fx_shatter.webp');
    expect(NightArtRegistry.fxKnockout, 'assets/images/fx/fx_knockout.webp');
    expect(NightArtRegistry.fxCombo, 'assets/images/fx/fx_combo.webp');
    expect(NightArtRegistry.fxLucky, 'assets/images/fx/fx_lucky.webp');
    expect(NightArtRegistry.fxQi, 'assets/images/fx/fx_qi.webp');

    expect(
      MutantKind.values.map(NightArtRegistry.mutantAsset).toList(),
      const [
        'assets/images/mutants/mut_swarmRat.webp',
        'assets/images/mutants/mut_sickHound.webp',
        'assets/images/mutants/mut_ironBoar.webp',
        'assets/images/mutants/mut_shieldYacha.webp',
        'assets/images/mutants/mut_plagueToad.webp',
        'assets/images/mutants/mut_bloodCocoon.webp',
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

    // 4. 1~10장 지도 화면 및 즉시 야간 수호 출정 + 전술 비약 발동 검증
    await tester.ensureVisible(find.byKey(const Key('home_campaign_map_btn')));
    await tester.tap(find.byKey(const Key('home_campaign_map_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('탄지무림 10장 심야 수호록'), findsOneWidget);
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

    for (final tabTitle in ['발사대(5)', '영수(5)', '동료(14)', '변이체(12)', '수호석(13)']) {
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
    expect(find.textContaining('111단계'), findsWidgets);

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
}
