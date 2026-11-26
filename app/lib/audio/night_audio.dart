import 'package:audioplayers/audioplayers.dart';
import 'package:defense_core/defense_core.dart';
import 'package:flutter/widgets.dart';

import 'night_haptics.dart';

/// 3층 입체 음향 컨트롤러 (배경음악 + 타격 효과음 + 기계/결계/출두 모션음 + 손맛 진동 연동).
class NightAudioController with WidgetsBindingObserver {
  NightAudioController._();
  static final NightAudioController instance = NightAudioController._();

  /// 앱이 뒤로 가 있는 동안(홈 단추·화면 끔)에는 아무 소리도 내지 않는다.
  bool _backgrounded = false;

  /// 앱 시작 때 한 번(플레이어를 만들기 전).
  /// 기본값은 플레이어마다 오디오 초점을 가져가서, 첫 효과음이 배경음악을 멈춘다 → 섞어 틀기.
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (e) {
      debugPrint('소리 설정 생략: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final away = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (away && !_backgrounded) {
      _backgrounded = true;
      _pauseAll();
    } else if (state == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      final bgm = _currentBgm;
      if (bgm != null) playBgm(bgm);
    }
  }

  Future<void> _pauseAll() async {
    ++_bgmOpSeq;
    try {
      await _bgmPlayer?.pause();
      for (final p in _sfxPool) {
        await p.stop();
      }
    } catch (_) {}
  }

  bool soundEnabled = true;
  bool bgmEnabled = true;
  double bgmVolume = 0.38;
  double sfxVolume = 0.72;
  String? _currentBgm;
  String? _loadedBgmSource;
  int _bgmOpSeq = 0;

  AudioPlayer? _bgmPlayer;
  final List<AudioPlayer> _sfxPool = [];
  int _poolCursor = 0;
  final Map<String, int> _lastPlayedMs = {};

  Future<void> applySettings({
    required double bgmVol,
    required double sfxVol,
    required bool vibOn,
    required int vibStrength,
  }) async {
    final opSeq = ++_bgmOpSeq;
    bgmVolume = bgmVol.clamp(0.0, 1.0);
    sfxVolume = sfxVol.clamp(0.0, 1.0);
    bgmEnabled = bgmVolume > 0.01;
    soundEnabled = sfxVolume > 0.01;
    NightHaptics.instance
      ..enabled = vibOn
      ..strength = vibStrength.clamp(1, 3);

    try {
      if (!bgmEnabled) {
        await _bgmPlayer?.pause();
      } else if (_currentBgm != null && !_backgrounded) {
        if (_bgmPlayer == null || _loadedBgmSource != _currentBgm) {
          await _playBgmInternal(_currentBgm!, opSeq);
        } else {
          if (opSeq != _bgmOpSeq || !bgmEnabled) return;
          await _bgmPlayer!.setVolume(bgmVolume);
          if (opSeq != _bgmOpSeq || !bgmEnabled) return;
          await _bgmPlayer!.resume();
        }
      }
    } catch (_) {}
  }

  Future<void> playBgm(String assetFileName) async {
    final opSeq = ++_bgmOpSeq;
    await _playBgmInternal(assetFileName, opSeq);
  }

  Future<void> _playBgmInternal(String assetFileName, int opSeq) async {
    if (!bgmEnabled || _backgrounded) {
      _currentBgm = assetFileName;
      return;
    }
    if (_currentBgm == assetFileName &&
        _loadedBgmSource == assetFileName &&
        _bgmPlayer != null) {
      try {
        if (opSeq != _bgmOpSeq || !bgmEnabled) return;
        await _bgmPlayer!.setVolume(bgmVolume);
        if (opSeq != _bgmOpSeq || !bgmEnabled) return;
        await _bgmPlayer!.resume();
      } catch (_) {}
      return;
    }
    _currentBgm = assetFileName;
    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      if (opSeq != _bgmOpSeq || !bgmEnabled || _currentBgm != assetFileName) return;
      await _bgmPlayer!.setVolume(bgmVolume);
      if (opSeq != _bgmOpSeq || !bgmEnabled || _currentBgm != assetFileName) return;
      await _bgmPlayer!.play(AssetSource('sounds/$assetFileName'));
      if (opSeq == _bgmOpSeq && _currentBgm == assetFileName) {
        _loadedBgmSource = assetFileName;
      } else if (!bgmEnabled) {
        await _bgmPlayer?.pause();
      }
    } catch (e) {
      debugPrint('배경음악 재생 생략: $e');
    }
  }

  Future<void> stopBgm() async {
    ++_bgmOpSeq;
    _currentBgm = null;
    _loadedBgmSource = null;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> playAsset(String fileName, {double volume = 0.65, int minGapMs = 75}) async {
    if (!soundEnabled || _backgrounded) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final prev = _lastPlayedMs[fileName] ?? 0;
    if (now - prev < minGapMs) return;
    _lastPlayedMs[fileName] = now;

    final scaledVol = (volume * (sfxVolume / 0.72)).clamp(0.0, 1.0);
    if (scaledVol <= 0.01) return;

    try {
      if (_sfxPool.length < 8) {
        final p = AudioPlayer();
        _sfxPool.add(p);
        await p.setReleaseMode(ReleaseMode.stop);
      }
      final player = _sfxPool[_poolCursor % _sfxPool.length];
      _poolCursor++;
      await player.setVolume(scaledVol);
      await player.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // 단위 시험 환경이나 오디오 장치 미연결 시 앱 멈춤 없이 안전 통과
    }
  }

  void flushBattleCues(List<SoundCue> cues) {
    if (cues.isEmpty) return;
    final copy = List<SoundCue>.from(cues);
    cues.clear();

    // 한 프레임 내 중복 큐 병합 재생
    final unique = copy.toSet();
    for (final cue in unique) {
      switch (cue) {
        case SoundCue.gearMotion:
          playAsset('motion_gear.wav', volume: 0.35, minGapMs: 320);
          break;
        case SoundCue.bowMotion:
          playAsset('motion_bow.wav', volume: 0.36, minGapMs: 125);
          break;
        case SoundCue.shieldWave:
          playAsset('motion_shield.wav', volume: 0.55, minGapMs: 260);
          NightHaptics.instance.lightTap();
          break;
        case SoundCue.stoneHitCheongok:
          playAsset('hit_cheongok.ogg', volume: 0.56, minGapMs: 65);
          break;
        case SoundCue.stoneHitHeavy:
          playAsset('hit_hyeoncheol.ogg', volume: 0.62, minGapMs: 65);
          break;
        case SoundCue.stoneHitIce:
          playAsset('hit_ice.ogg', volume: 0.56, minGapMs: 65);
          break;
        case SoundCue.stoneHitWood:
          playAsset('hit_wood.ogg', volume: 0.52, minGapMs: 65);
          break;
        case SoundCue.criticalShatter:
          playAsset('critical.ogg', volume: 0.74, minGapMs: 115);
          NightHaptics.instance.heavyImpact();
          break;
        case SoundCue.pporokFall:
          playAsset('pporok_fall.wav', volume: 0.72, minGapMs: 220);
          NightHaptics.instance.pporokDrop();
          break;
        case SoundCue.serendipityJackpot:
          playAsset('serendipity_jackpot.wav', volume: 0.78, minGapMs: 250);
          NightHaptics.instance.meridianOpen();
          break;
        case SoundCue.chulduFanfare:
          playAsset('chuldu_fanfare.wav', volume: 0.92, minGapMs: 600);
          NightHaptics.instance.chulduRumble();
          break;
        case SoundCue.villageWarning:
          playAsset('village_warning.wav', volume: 0.68, minGapMs: 500);
          NightHaptics.instance.heavyImpact();
          break;
        case SoundCue.dawnPurify:
          playAsset('dawn_purify.wav', volume: 0.85, minGapMs: 600);
          break;
        case SoundCue.loseBell:
          playAsset('jingle_lose.ogg', volume: 0.75, minGapMs: 600);
          break;
      }
    }
  }
}
