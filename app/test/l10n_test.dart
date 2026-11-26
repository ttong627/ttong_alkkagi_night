import 'dart:convert';
import 'dart:io';

import 'package:alkkagi_night/i18n/l10n.dart';
import 'package:alkkagi_night/i18n/tr_text.dart' as t;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => L10n.use('ko'));

  test('한국어면 그대로 · 표에 있으면 바꾸고 틀은 자리값까지 번역', () {
    expect(L10n.tr('악몽'), '악몽');
    L10n.installForTest('en', {
      '악몽': 'Nightmare',
      '석두': 'Seokdu',
      '🐾 영수 「{0}」 영기 각성 (+1단계 승급)!': '🐾 Spirit Beast "{0}" awakens (+1 tier)!',
      '이번 수호 차례 ({0}/{1}) · 초소 {2}곳 · {3}물결': 'Stage {0}/{1} · {2} outposts · {3} waves',
      '보통': 'Normal',
    });
    expect(L10n.tr('악몽'), 'Nightmare');
    expect(L10n.tr('🐾 영수 「석두」 영기 각성 (+1단계 승급)!'), '🐾 Spirit Beast "Seokdu" awakens (+1 tier)!');
    expect(L10n.tr('이번 수호 차례 (46/100) · 초소 10곳 · 6물결'), 'Stage 46/100 · 10 outposts · 6 waves');
    expect(L10n.tr('악몽\n보통'), 'Nightmare\nNormal');
    expect(L10n.tr('표에 없는 말'), '표에 없는 말');
    expect(L10n.tr('Already English'), 'Already English');
    expect(L10n.tr('보통(3)'), 'Normal(3)');
  });

  test('짧은 틀이 먼저 걸려도 자리값이 번역되는 나눔을 고른다', () {
    L10n.installForTest('en', {
      '{0}현': '{0} County',
      '{0} · {1}/10번째 마을 [{2}]': '{0} · {1}/10 [{2}]',
      '제5현 · 황동 기관학당현': 'County 5 · Brass Academy',
      '청동 종루 마을': 'Bronze Bell Village',
    });
    expect(L10n.tr('제5현 · 황동 기관학당현 · 6/10번째 마을 [청동 종루 마을]'),
        'County 5 · Brass Academy · 6/10 [Bronze Bell Village]');
  });

  test('기기 언어 고르기', () {
    expect(L10n.pickFor(const Locale('fr', 'FR')), 'fr');
    expect(L10n.pickFor(const Locale('zh', 'TW')), 'zh_TW');
    expect(L10n.pickFor(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')), 'zh_TW');
    expect(L10n.pickFor(const Locale('zh', 'CN')), 'zh');
    expect(L10n.pickFor(const Locale('ko', 'KR')), 'ko');
    expect(L10n.pickFor(const Locale('sw')), 'en');
  });

  test('번역 파일마다 모든 원문이 있고 자리표가 맞다', () {
    final src = (jsonDecode(File('tool/i18n/source_ko.json').readAsStringSync()) as List).cast<String>();
    final hole = RegExp(r'\{\d+\}');
    for (final (code, _) in kNightLanguages.skip(1)) {
      final table = Map<String, dynamic>.from(
        jsonDecode(File('assets/i18n/$code.json').readAsStringSync()) as Map,
      );
      for (final ko in src) {
        final out = table[ko];
        expect(out, isA<String>(), reason: '$code 빠짐: $ko');
        final a = hole.allMatches(ko).map((m) => m[0]).toList()..sort();
        final b = hole.allMatches(out as String).map((m) => m[0]).toList()..sort();
        expect(b, a, reason: '$code 자리표: $ko');
      }
    }
  });

  testWidgets('const Text 도 그릴 때 번역된다', (tester) async {
    L10n.installForTest('en', {'즉시 야간 수호 출정': 'Defend Tonight'});
    await tester.pumpWidget(const MaterialApp(home: t.Text('즉시 야간 수호 출정')));
    expect(find.text('Defend Tonight'), findsOneWidget);
  });
}
