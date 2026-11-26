import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 빌드 채널 및 판본 환경 변수 (`--dart-define` 미지정 시 기본값 사용).
const String kNightAppChannel = String.fromEnvironment('APP_CHANNEL', defaultValue: 'dev');
const String kNightAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
const int kNightAppBuild = int.fromEnvironment('APP_BUILD', defaultValue: 37);
const String kNightUpdateManifestUrl = String.fromEnvironment(
  'UPDATE_URL',
  defaultValue:
      'https://github.com/ttong627/ttong_alkkagi_night/releases/download/test-latest/version.json',
);

/// 직접 설치판(`sideload`) 릴리스 매니페스트(`version.json`) 검증 모델.
class NightUpdateInfo {
  const NightUpdateInfo({
    required this.build,
    required this.apkUrl,
    required this.sha256,
    required this.size,
    this.notes = '',
  });

  static const Set<String> allowedHosts = {'github.com'};
  static const String allowedPathPrefix = '/ttong627/ttong_alkkagi_night/releases/download/';

  final int build;
  final String apkUrl;
  final String sha256;
  final int size;
  final String notes;

  bool newerThan(int currentBuild) => build > currentBuild;

  static NightUpdateInfo? parse(String rawText) {
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is! Map) return null;
      final build = decoded['build'];
      final apk = decoded['apk'];
      final sha = decoded['sha256'];
      final size = decoded['size'];
      if (build is! int || apk is! String || sha is! String || size is! int) {
        return null;
      }
      final uri = Uri.tryParse(apk);
      if (uri == null ||
          uri.scheme != 'https' ||
          !allowedHosts.contains(uri.host.toLowerCase()) ||
          !uri.path.toLowerCase().startsWith(allowedPathPrefix)) {
        return null;
      }
      final normalizedSha = sha.trim().toLowerCase();
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalizedSha)) return null;
      if (size <= 0 || size > 350 * 1024 * 1024) return null;
      final notes = decoded['notes'];
      return NightUpdateInfo(
        build: build,
        apkUrl: apk,
        sha256: normalizedSha,
        size: size,
        notes: notes is String ? notes.trim() : '',
      );
    } catch (_) {
      return null;
    }
  }
}

enum NightUpdateStage {
  idle,
  checking,
  upToDate,
  available,
  needsPermission,
  downloading,
  installing,
  failed,
}

/// 안드로이드 네이티브 미디어 진동(`tanji/haptic`) · 비정상 종료 기록(`tanji/diag`) · 자체 갱신(`tanji/updater`) 브리지.
class NightHaptics {
  NightHaptics._() {
    _updaterChannel.setMethodCallHandler(_handleUpdaterCallback);
  }
  static final NightHaptics instance = NightHaptics._();

  static const MethodChannel _hapticChannel = MethodChannel('tanji/haptic');
  static const MethodChannel _diagChannel = MethodChannel('tanji/diag');
  static const MethodChannel _updaterChannel = MethodChannel('tanji/updater');

  bool enabled = true;
  int strength = 2; // 1=약, 2=보통, 3=강
  int _lastHapticMs = 0;

  final ValueNotifier<NightUpdateStage> updateStage =
      ValueNotifier<NightUpdateStage>(NightUpdateStage.idle);
  final ValueNotifier<int> updatePercent = ValueNotifier<int>(0);
  String updateMessage = '';
  NightUpdateInfo? latestUpdateInfo;

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

  Future<void> _handleUpdaterCallback(MethodCall call) async {
    switch (call.method) {
      case 'progress':
        final pct = (call.arguments is num) ? (call.arguments as num).toInt().clamp(0, 100) : 0;
        updatePercent.value = pct;
        updateMessage = '새 판 내려받는 중 ($pct%)';
        updateStage.value = NightUpdateStage.downloading;
        break;
      case 'installing':
        updateMessage = '무결성 검증 통과 · 패키지 설치 진행 중...';
        updateStage.value = NightUpdateStage.installing;
        break;
      case 'failed':
        updateMessage = '업데이트 실패: ${call.arguments ?? '알 수 없는 오류'}';
        updateStage.value = NightUpdateStage.failed;
        break;
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

  /// 이용자가 설정 화면에서 직접 '새 판 확인'을 눌렀을 때만 공개 저장소 `version.json`을 조회한다.
  Future<NightUpdateStage> checkSideloadUpdate({int currentBuild = kNightAppBuild}) async {
    if (kIsWeb) {
      updateMessage = '웹 환경에서는 자체 설치 기능을 사용하지 않습니다.';
      updateStage.value = NightUpdateStage.idle;
      return updateStage.value;
    }
    final supported = await isSideloadUpdaterAvailable();
    if (!supported) {
      updateMessage = '플레이 스토어 배포판은 구글 플레이에서 안전하게 업데이트됩니다.';
      updateStage.value = NightUpdateStage.idle;
      return updateStage.value;
    }
    if (updateStage.value == NightUpdateStage.downloading ||
        updateStage.value == NightUpdateStage.installing) {
      return updateStage.value;
    }

    updateStage.value = NightUpdateStage.checking;
    updateMessage = '공식 배포 저장소의 최신 판본을 확인하는 중...';
    try {
      final rawJson = await _fetchManifestText(kNightUpdateManifestUrl);
      final parsed = NightUpdateInfo.parse(rawJson);
      if (parsed == null) {
        latestUpdateInfo = null;
        updateMessage = '현재 게시된 시험판 업데이트 매니페스트가 없거나 최신 판본(+$currentBuild)입니다.';
        updateStage.value = NightUpdateStage.upToDate;
        return updateStage.value;
      }
      latestUpdateInfo = parsed;
      if (!parsed.newerThan(currentBuild)) {
        updateMessage = '이미 최신 판본(빌드 +$currentBuild)을 사용 중입니다.';
        updateStage.value = NightUpdateStage.upToDate;
        return updateStage.value;
      }
      updateMessage = parsed.notes.isNotEmpty
          ? '새 판(빌드 +${parsed.build}) 발견: ${parsed.notes}'
          : '새 판(빌드 +${parsed.build})을 내려받아 설치할 수 있습니다.';
      updateStage.value = NightUpdateStage.available;
      return updateStage.value;
    } on HttpException catch (e) {
      if (e.message.contains('404')) {
        latestUpdateInfo = null;
        updateMessage = '현재 사용하는 판본(빌드 +$currentBuild)이 최신입니다.';
        updateStage.value = NightUpdateStage.upToDate;
        return updateStage.value;
      }
      updateMessage = '새 판 조회 실패: ${e.message}';
      updateStage.value = NightUpdateStage.failed;
      return updateStage.value;
    } catch (e) {
      updateMessage = '네트워크 연결을 확인해 주세요 ($e)';
      updateStage.value = NightUpdateStage.failed;
      return updateStage.value;
    }
  }

  /// 확인된 새 판 APK를 SHA-256 지문 및 파일 크기 검증과 함께 내려받아 설치한다.
  Future<bool> startSideloadInstall() async {
    final info = latestUpdateInfo;
    if (kIsWeb || info == null) return false;
    final canInstall = await canInstallPackages();
    if (!canInstall) {
      updateMessage = '처음 한 번 「이 출처의 앱 설치 허용」을 켜 주셔야 업데이트가 진행됩니다.';
      updateStage.value = NightUpdateStage.needsPermission;
      await openUnknownSourcesSettings();
      return false;
    }
    try {
      updatePercent.value = 0;
      updateMessage = '새 판 내려받기 준비 중...';
      updateStage.value = NightUpdateStage.downloading;
      await _updaterChannel.invokeMethod<void>('install', {
        'url': info.apkUrl,
        'sha256': info.sha256,
        'size': info.size,
      });
      return true;
    } catch (e) {
      updateMessage = '설치 시작 실패: $e';
      updateStage.value = NightUpdateStage.failed;
      return false;
    }
  }

  static Future<String> _fetchManifestText(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse(url).replace(
        queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
      );
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
