import 'package:alkkagi_night/audio/night_audio.dart';
import 'package:alkkagi_night/main.dart';
import 'package:alkkagi_night/state/game_controller.dart';
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

  testWidgets('수호 본영 → 초간단 기명 심법 수련(운기 및 1~6단계 경맥 개통) → 대장간 → 호송 → 전장 출정 통합 검증',
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
      ),
    );

    await tester.pumpWidget(SuhoAlkkagiNightApp(controller: controller));
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

    // 본영 복귀
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 2. 자동 진법 편성실 및 증표 대장간·영약각 진입(소형 화면 레이아웃 무결성 검증)
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

    await tester.tap(find.text('보름달 특급 기연 열기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.progress.supportTokens, greaterThan(beforeSupport));

    await tester.tap(find.text('기쁘게 수령'));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    // 4. 1~10장 지도 화면 및 즉시 야간 수호 출정 진입 검증
    await tester.ensureVisible(find.byKey(const Key('home_campaign_map_btn')));
    await tester.tap(find.byKey(const Key('home_campaign_map_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('탄지무림 10장 심야 수호록'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    await tester.ensureVisible(find.byKey(const Key('home_quick_battle_btn')));
    await tester.tap(find.byKey(const Key('home_quick_battle_btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('무림수호단 출두!'), findsOneWidget);
  });
}
