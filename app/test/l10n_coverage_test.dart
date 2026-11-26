import 'dart:convert';
import 'dart:io';

import 'package:alkkagi_night/i18n/l10n.dart';
import 'package:defense_core/defense_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 게임 데이터(100판·동료·영수·변이체)를 실제 번역 표로 바꿔 한국어가 얼마나 남는지 잰다.
void main() {
  tearDown(() => L10n.use('ko'));

  List<String> gameTexts() {
    final out = <String>[];
    for (final st in CampaignCatalog.allStages) {
      final ch = CampaignCatalog.chapterOf(st.chapterNumber);
      out
        ..add(st.title)
        ..add(st.subtitle)
        ..add(st.tacticalHint)
        ..add(st.villageNodeName)
        ..add('${ch.countyName} · ${st.stageNumber}/10번째 마을 [${st.villageNodeName}]');
    }
    for (final h in CompanionHero.values) {
      out
        ..add(h.name)
        ..add(h.skillDesc);
    }
    for (final b in SpiritBeast.values) {
      out
        ..add(b.name)
        ..add(b.skillSummary);
    }
    for (final m in MutantKind.values) {
      out
        ..add(m.name)
        ..add(m.traitDesc);
    }
    return out.where((s) => RegExp('[가-힣]').hasMatch(s)).toList();
  }

  for (final code in ['en', 'ja', 'fr']) {
    test('$code: 게임 데이터 번역률 95% 이상 · 빠르게', () {
      final table = Map<String, String>.from(
        jsonDecode(File('assets/i18n/$code.json').readAsStringSync()) as Map,
      );
      L10n.installForTest(code, table);
      final texts = gameTexts();
      final sw = Stopwatch()..start();
      final left = <String>[];
      for (final s in texts) {
        final t = L10n.tr(s);
        if (RegExp('[가-힣]').hasMatch(t)) left.add('$s → $t');
      }
      sw.stop();
      final rate = 1 - left.length / texts.length;
      // ignore: avoid_print
      print('$code ${texts.length}개 중 남음 ${left.length} (${(rate * 100).toStringAsFixed(1)}%) · ${sw.elapsedMilliseconds}ms');
      for (final l in left.take(8)) {
        // ignore: avoid_print
        print('  $l');
      }
      expect(rate, greaterThanOrEqualTo(0.95));
      expect(sw.elapsedMilliseconds, lessThan(4000));
    });
  }
}
