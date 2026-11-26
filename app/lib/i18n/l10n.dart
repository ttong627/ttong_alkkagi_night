import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 지원 언어(코드 · 그 언어로 쓴 이름). 한국어가 원문이다.
const List<(String, String)> kNightLanguages = [
  ('ko', '한국어'),
  ('en', 'English'),
  ('ja', '日本語'),
  ('zh', '简体中文'),
  ('zh_TW', '繁體中文'),
  ('es', 'Español'),
  ('pt', 'Português'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('ru', 'Русский'),
  ('id', 'Bahasa Indonesia'),
  ('vi', 'Tiếng Việt'),
  ('th', 'ไทย'),
  ('tr', 'Türkçe'),
  ('it', 'Italiano'),
];

class _Template {
  _Template(this.ko, this.out, this.lits, this.holes, this.anchor);
  final String ko;
  final String out;

  /// 고정 글 조각(자리 수 + 1개)과 자리 번호.
  final List<String> lits;
  final List<String> holes;
  final String anchor;
}

/// 「한국어 원문 → 번역」 표. 한국어면 아무것도 하지 않는다.
///
/// 원문에 숫자·이름이 끼는 문장은 `{0}` 자리가 있는 틀로 맞춘 뒤, 끼운 값도 표에서 다시 찾아 바꾼다.
class L10n {
  L10n._();

  static final ValueNotifier<String> lang = ValueNotifier<String>('ko');
  static Map<String, String> _exact = const {};
  static List<_Template> _templates = const [];
  static final Map<String, String> _cache = {};
  static final RegExp _hole = RegExp(r'\{(\d+)\}');
  static final RegExp _hangul = RegExp('[가-힣]');
  static final RegExp _tailNumber = RegExp(r'^(.*?)(\s*\(\d+\)|\s*[\d.,%+×⚡/]+)$', dotAll: true);
  static final RegExp _leadSymbols = RegExp(r'^([^\p{L}\p{N}\[(「『"]+)(.*)$', unicode: true, dotAll: true);

  static bool get isKorean => lang.value == 'ko';

  /// 기기 언어에서 지원 언어 코드를 고른다(없으면 영어 · 한국어 기기는 한국어).
  static String pickFor(Locale locale) {
    final l = locale.languageCode;
    if (l == 'zh') {
      final traditional = locale.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(locale.countryCode);
      return traditional ? 'zh_TW' : 'zh';
    }
    for (final (code, _) in kNightLanguages) {
      if (code == l) return code;
    }
    return 'en';
  }

  static Locale localeOf(String code) {
    final parts = code.split('_');
    return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  static Future<void> use(String code) async {
    if (code == 'ko') {
      _exact = const {};
      _templates = const [];
      _cache.clear();
      lang.value = 'ko';
      return;
    }
    try {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      _install(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      lang.value = code;
    } catch (e) {
      debugPrint('언어 $code 불러오기 실패: $e');
    }
  }

  /// 시험용: 표를 바로 넣는다.
  @visibleForTesting
  static void installForTest(String code, Map<String, String> table) {
    _install(table);
    lang.value = code;
  }

  static void _install(Map<String, dynamic> table) {
    final exact = <String, String>{};
    final templates = <_Template>[];
    table.forEach((ko, value) {
      if (value is! String || value.isEmpty) return;
      if (!_hole.hasMatch(ko)) {
        exact[ko] = value;
        return;
      }
      final lits = <String>[];
      final holes = <String>[];
      var last = 0;
      var anchor = '';
      for (final m in _hole.allMatches(ko)) {
        final lit = ko.substring(last, m.start);
        if (lit.length > anchor.length) anchor = lit;
        lits.add(lit);
        holes.add(m.group(1)!);
        last = m.end;
      }
      final tail = ko.substring(last);
      if (tail.length > anchor.length) anchor = tail;
      lits.add(tail);
      templates.add(_Template(ko, value, lits, holes, anchor));
    });
    // 「제1현 · 청산 흙먼지현」처럼 · 로 이은 이름은 조각 번역도 만든다(코드가 뒤 조각만 잘라 쓰는 곳이 있다).
    final dot = RegExp(r'\s*[·・]\s*');
    for (final e in exact.entries.toList()) {
      final koParts = e.key.split(' · ');
      if (koParts.length < 2) continue;
      final outParts = e.value.split(dot);
      if (outParts.length != koParts.length) continue;
      for (var i = 0; i < koParts.length; i++) {
        exact.putIfAbsent(koParts[i], () => outParts[i]);
      }
    }
    // 글자가 많이 고정된 틀부터(더 구체적인 것이 먼저 맞도록).
    templates.sort((a, b) =>
        b.ko.replaceAll(_hole, '').length.compareTo(a.ko.replaceAll(_hole, '').length));
    _exact = exact;
    _templates = templates;
    _cache.clear();
  }

  /// 화면에 낼 글을 지금 언어로.
  static String tr(String s) {
    if (isKorean || s.isEmpty || !_hangul.hasMatch(s)) return s;
    return _translate(s, 0);
  }

  static String _translate(String s, int depth) {
    // 같은 깊이의 같은 글은 결과가 같다 — 깊이를 열쇠에 넣어 한 번만 계산한다.
    final key = '$depth\u0000$s';
    final hit = _cache[key];
    if (hit != null) return hit;
    final out = _translateRaw(s, depth);
    if (_cache.length > 20000) _cache.clear();
    _cache[key] = out;
    return out;
  }

  static String _translateRaw(String s, int depth) {
    final exact = _exact[s];
    if (exact != null) return exact;
    if (depth > 6 || !_hangul.hasMatch(s)) return s;
    final trimmed = s.trim();
    if (trimmed != s && trimmed.isNotEmpty) {
      final t = _exact[trimmed];
      if (t != null) return s.replaceFirst(trimmed, t);
    }
    String? best;
    var bestLeft = _hangulCount(s);
    for (final t in _templates) {
      if (t.anchor.isNotEmpty && !s.contains(t.anchor)) continue;
      final caps = _bestSplit(t, s, depth);
      if (caps == null) continue;
      final out = t.out.replaceAllMapped(_hole, (h) {
        final i = t.holes.indexOf(h.group(1)!);
        return i < 0 ? h.group(0)! : caps[i];
      });
      final left = _hangulCount(out);
      if (left == 0) return out;
      if (left < bestLeft) {
        best = out;
        bestLeft = left;
      }
    }
    // 앞에 붙은 기호(★ ✦ 🔥 …)는 떼고 번역해 다시 붙인다.
    final lead = _leadSymbols.firstMatch(s);
    if (lead != null && lead.group(2)!.isNotEmpty) {
      final out = lead.group(1)! + _translate(lead.group(2)!, depth + 1);
      if (_hangulCount(out) < bestLeft) {
        best = out;
        bestLeft = _hangulCount(out);
        if (bestLeft == 0) return out;
      }
    }
    // 끝에 붙은 개수·숫자(「기공단(1)」)는 떼고 번역해 다시 붙인다.
    final tail = _tailNumber.firstMatch(s);
    if (tail != null && tail.group(1)!.isNotEmpty) {
      final out = _translate(tail.group(1)!, depth + 1) + tail.group(2)!;
      if (_hangulCount(out) < bestLeft) {
        best = out;
        bestLeft = _hangulCount(out);
        if (bestLeft == 0) return out;
      }
    }
    // 여러 줄·구분점으로 이어 붙인 글은 조각마다.
    for (final sep in const ['\n', ' · ', ' — ', ' | ', ' / ', '·']) {
      if (s.contains(sep)) {
        final out = s.split(sep).map((p) => _translate(p, depth + 1)).join(sep);
        if (_hangulCount(out) < bestLeft) return out;
        break;
      }
    }
    if (best != null) return best;
    return s;
  }

  static int _hangulCount(String s) => _hangul.allMatches(s).length;

  /// 틀의 고정 조각이 s 에 들어맞는 나눔을 모두 따져, 자리값이 가장 잘 번역되는 것을 돌려준다(번역된 자리값들).
  static List<String>? _bestSplit(_Template t, String s, int depth) {
    final lits = t.lits;
    final n = t.holes.length;
    if (!s.startsWith(lits.first) || !s.endsWith(lits.last)) return null;
    if (lits.first.length + lits.last.length > s.length) return null;
    List<String>? best;
    var bestLeft = 1 << 30;
    var tries = 0;
    void walk(int pos, int k, List<String> raw) {
      if (tries > 48 || bestLeft == 0 || pos >= s.length) return;
      final next = lits[k + 1];
      final isLast = k + 1 == n;
      final ends = <int>[];
      if (isLast) {
        final i = s.length - next.length;
        if (i > pos) ends.add(i);
      } else if (next.isEmpty) {
        for (var i = pos + 1; i < s.length; i++) {
          ends.add(i);
        }
      } else {
        var i = s.indexOf(next, pos + 1);
        while (i >= 0) {
          ends.add(i);
          i = s.indexOf(next, i + 1);
        }
      }
      for (final i in ends) {
        final value = s.substring(pos, i);
        final nextRaw = [...raw, value];
        if (isLast) {
          tries++;
          final done = [for (final v in nextRaw) _translate(v, depth + 1)];
          final left = done.fold<int>(0, (a, v) => a + _hangulCount(v));
          if (left < bestLeft) {
            bestLeft = left;
            best = done;
          }
        } else {
          walk(i + next.length, k + 1, nextRaw);
        }
      }
    }

    walk(lits.first.length, 0, const []);
    return best;
  }
}


/// 고른 언어를 기기에 기억한다(''= 휴대폰 언어 따라가기).
class NightLanguage {
  NightLanguage._();
  static const String _key = 'night_lang';

  static Future<String> chosen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 저장된 선택 → 실제로 쓸 언어 코드.
  static Future<String> resolve() async {
    final c = await chosen();
    if (c.isNotEmpty && kNightLanguages.any((l) => l.$1 == c)) return c;
    return L10n.pickFor(PlatformDispatcher.instance.locale);
  }

  static Future<void> choose(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
    await L10n.use(await resolve());
  }
}

/// 화면 코드에서 바로 쓰는 짧은 이름.
String tr(String s) => L10n.tr(s);
