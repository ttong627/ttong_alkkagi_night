import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 안드로이드 네이티브 미디어 진동(`tanji/haptic`) · 비정상 종료 기록(`tanji/diag`) · 자체 갱신(`tanji/updater`) 브리지.
class NightHaptics {
  NightHaptics._();
  static final NightHaptics instance = NightHaptics._();

  static const MethodChannel _hapticChannel = MethodChannel('tanji/haptic');
  static const MethodChannel _diagChannel = MethodChannel('tanji/diag');
  static const MethodChannel _updaterChannel = MethodChannel('tanji/updater');

  bool enabled = true;
  int strength = 2; // 1=약, 2=보통, 3=강
  int _lastHapticMs = 0;

  double get _ampScale {
    switch (strength.clamp(1, 3)) {
      case 1:
        return 0.52;
      case 3:
        return 1.0;
      case 2:
      default:
        return 0.78;
    }
  }

  Future<void> pulse({required int ms, required int amp, int minGapMs = 45}) async {
    if (!enabled || kIsWeb) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticMs < minGapMs) return;
    _lastHapticMs = now;
    final scaledAmp = (amp * _ampScale).round().clamp(1, 255);
    try {
      await _hapticChannel.invokeMethod('pulse', {'ms': ms, 'amp': scaledAmp});
    } catch (_) {
      // 단위 시험이나 진동 미지원 환경에서 예외 무시
    }
  }

  Future<void> pattern({
    required List<int> ms,
    required List<int> amp,
    int minGapMs = 120,
  }) async {
    if (!enabled || kIsWeb) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticMs < minGapMs) return;
    _lastHapticMs = now;
    final scaledAmp = amp
        .map((a) => a <= 0 ? 0 : (a * _ampScale).round().clamp(1, 255))
        .toList();
    try {
      await _hapticChannel.invokeMethod('pattern', {'ms': ms, 'amp': scaledAmp});
    } catch (_) {}
  }

  void lightTap() {
    pulse(ms: 15, amp: 135, minGapMs: 35);
  }

  void heavyImpact() {
    pulse(ms: 32, amp: 225, minGapMs: 85);
  }

  void pporokDrop() {
    pattern(ms: const [18, 28, 42], amp: const [185, 0, 245], minGapMs: 160);
  }

  void meridianOpen() {
    pattern(
      ms: const [20, 22, 28, 22, 50],
      amp: const [165, 0, 215, 0, 255],
      minGapMs: 200,
    );
  }

  void chulduRumble() {
    pattern(
      ms: const [45, 24, 55, 24, 88],
      amp: const [220, 0, 245, 0, 255],
      minGapMs: 350,
    );
  }

  /// 안드로이드 11+ 비정상 종료 및 자바 예외 기록 조회 (외부 전송 없음 · 기기 내 열람/복사용).
  Future<String> fetchLastCrashReport() async {
    if (kIsWeb) {
      return '웹 미리보기 환경입니다. 안드로이드 단말기에서는 직전 종료 상태와 기기 진단 정보가 이 창에 표시됩니다.';
    }
    try {
      final raw = await _diagChannel.invokeMethod<Map<dynamic, dynamic>>('lastExit');
      if (raw == null) return '저장된 비정상 종료 기록이 없습니다.';
      final text = (raw['text'] ?? '').toString().trim();
      final abnormal = raw['abnormal'] == true;
      if (text.isEmpty) return '저장된 비정상 종료 기록이 없습니다.';
      final badge = abnormal ? '[주의 · 비정상 종료 감지됨]\n' : '[정상 구동 상태]\n';
      return '$badge$text';
    } catch (_) {
      return '현재 실행 환경에서는 네이티브 종료 진단 기록이 비어 있습니다 (정상 상태).';
    }
  }

  /// 직접 설치판(`sideload`) 자동 갱신 지원 여부 확인 (플레이 스토어 판은 항상 `false`).
  Future<bool> isSideloadUpdaterAvailable() async {
    if (kIsWeb) return false;
    try {
      final ok = await _updaterChannel.invokeMethod<bool>('available');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canInstallPackages() async {
    if (kIsWeb) return false;
    try {
      final ok = await _updaterChannel.invokeMethod<bool>('canInstall');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openUnknownSourcesSettings() async {
    if (kIsWeb) return;
    try {
      await _updaterChannel.invokeMethod<void>('openPermission');
    } catch (_) {}
  }
}
