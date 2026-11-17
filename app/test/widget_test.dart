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
    expect(NightArtRegistry.lobbyStageFortress, 'assets/images/scenes/lobby_stage_fortress.webp');
    expect(NightArtRegistry.cardGateBattle, 'assets/images/scenes/card_gate_battle.webp');
    expect(NightArtRegistry.cardTrainingHall, 'assets/images/scenes/card_training_hall.webp');
    expect(NightArtRegistry.cardForgeSanctum, 'assets/images/scenes/card_forge_sanctum.webp');
    expect(NightArtRegistry.cardAllyPavilion, 'assets/images/scenes/card_ally_pavilion.webp');
    expect(NightArtRegistry.cardRescueBeacon, 'assets/images/scenes/card_rescue_beacon.webp');
    expect(NightArtRegistry.cardSupplyConvoy, 'assets/images/scenes/card_supply_convoy.webp');
    expect(NightArtRegistry.cardEndlessAbyss, 'assets/images/scenes/card_endless_abyss.webp');
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

    // 5. 중앙 기명 수호탑 자동발사 ↔ 수동탄지 전환 및 길목 빈 초소 터치 직접 배치 검증
    expect(find.text('중앙탑: 자동발사'), findsOneWidget);
    await tester.tap(find.byKey(const Key('battle_toggle_central_mode_btn')));
    await tester.pump();
    expect(find.text('중앙탑: 수동탄지'), findsOneWidget);
    expect(find.text('초소 0/2곳'), findsOneWidget);

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
    expect(find.textContaining('빈 초소 · 발사대 직접 배치'), findsOneWidget);
    expect(find.byKey(const Key('lucky_summon_btn')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('place_launcher_rapid')));
    await tester.tap(find.byKey(const Key('place_launcher_rapid')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('초소 1/2곳'), findsOneWidget);

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
    expect(find.textContaining('빈 초소 · 발사대 직접 배치'), findsOneWidget);

    for (int i = 0; i < 105; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('빈 초소 · 발사대 직접 배치'), findsNothing);

    // 2) 하단 실시간 원터치 「🎲즉시운빨(35⚡)」 버튼으로 화면 가림 없이 즉시 소환 검증!
    expect(find.text('초소 0/2곳'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick_lucky_summon_btn')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('초소 1/2곳'), findsOneWidget);

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
    for (int cycle = 0; cycle < 3; cycle++) {
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
}
