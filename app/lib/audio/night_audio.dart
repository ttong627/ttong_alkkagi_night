import 'package:audioplayers/audioplayers.dart';
import 'package:defense_core/defense_core.dart';
import 'package:flutter/foundation.dart';

/// 3층 입체 음향 컨트롤러 (배경음악 + 타격 효과음 + 기계/결계/출두 모션음).
class NightAudioController {
  NightAudioController._();
  static final NightAudioController instance = NightAudioController._();

  bool soundEnabled = true;
  bool bgmEnabled = true;
  String? _currentBgm;

  AudioPlayer? _bgmPlayer;
  final List<AudioPlayer> _sfxPool = [];
  int _poolCursor = 0;
  final Map<String, int> _lastPlayedMs = {};

  Future<void> playBgm(String assetFileName) async {
    if (!bgmEnabled) return;
    if (_currentBgm == assetFileName) return;
    _currentBgm = assetFileName;
    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(0.36);
      await _bgmPlayer!.play(AssetSource('sounds/$assetFileName'));
    } catch (e) {
      debugPrint('배경음악 재생 생략: $e');
    }
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> playAsset(String fileName, {double volume = 0.65, int minGapMs = 75}) async {
    if (!soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final prev = _lastPlayedMs[fileName] ?? 0;
    if (now - prev < minGapMs) return;
    _lastPlayedMs[fileName] = now;

    try {
      if (_sfxPool.length < 6) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(p);
      }
      final player = _sfxPool[_poolCursor % _sfxPool.length];
      _poolCursor++;
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // 단위 시험 환경이나 오디오 장치 미연결 시 앱 멈춤 없이 안전 통과
    }
  }

  void flushBattleCues(List<SoundCue> cues) {
    if (cues.isEmpty) return;
    final copy = List<SoundCue>.from(cues);
    cues.clear();
    if (!soundEnabled) return;

    // 한 프레임 내 중복 큐 병합 재생
    final unique = copy.toSet();
    for (final cue in unique) {
      switch (cue) {
        case SoundCue.gearMotion:
          playAsset('motion_gear.wav', volume: 0.35, minGapMs: 320);
          break;
        case SoundCue.bowMotion:
          playAsset('motion_bow.wav', volume: 0.32, minGapMs: 220);
          break;
        case SoundCue.shieldWave:
          playAsset('motion_shield.wav', volume: 0.55, minGapMs: 260);
          break;
        case SoundCue.stoneHitCheongok:
          playAsset('hit_cheongok.ogg', volume: 0.50, minGapMs: 90);
          break;
        case SoundCue.stoneHitHeavy:
          playAsset('hit_hyeoncheol.ogg', volume: 0.56, minGapMs: 90);
          break;
        case SoundCue.stoneHitIce:
          playAsset('hit_ice.ogg', volume: 0.52, minGapMs: 90);
          break;
        case SoundCue.stoneHitWood:
          playAsset('hit_wood.ogg', volume: 0.48, minGapMs: 90);
          break;
        case SoundCue.criticalShatter:
          playAsset('critical.ogg', volume: 0.68, minGapMs: 140);
          break;
        case SoundCue.pporokFall:
          playAsset('pporok_fall.wav', volume: 0.72, minGapMs: 220);
          break;
        case SoundCue.serendipityJackpot:
          playAsset('serendipity_jackpot.wav', volume: 0.78, minGapMs: 250);
          break;
        case SoundCue.chulduFanfare:
          playAsset('chuldu_fanfare.wav', volume: 0.92, minGapMs: 600);
          break;
        case SoundCue.villageWarning:
          playAsset('village_warning.wav', volume: 0.68, minGapMs: 500);
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
