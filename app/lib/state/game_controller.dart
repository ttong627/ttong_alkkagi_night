import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/night_audio.dart';
import '../audio/night_haptics.dart';

/// 앱 전역 상태 및 즉시 자동 저장 컨트롤러.
class GameController extends ChangeNotifier {
  GameController({PlayerProgress? initialProgress})
      : _progress = initialProgress ?? PlayerProgress() {
    _syncDeviceSettings();
  }

  static const String _prefsKey = 'suho_alkkagi_night_save_v1';

  PlayerProgress _progress;
  DefenseDifficulty selectedDifficulty = DefenseDifficulty.normal;
  int selectedChapter = 1;
  int battleSpeedMultiplier = 1;
  bool autoChooseBattlePerks = false;
  final Random _rng = Random();

  PlayerProgress get progress => _progress;

  void _syncDeviceSettings() {
    NightAudioController.instance.applySettings(
      bgmVol: _progress.bgmVolume,
      sfxVol: _progress.sfxVolume,
      vibOn: _progress.vibrationEnabled,
      vibStrength: _progress.vibrationStrength,
    );
  }

  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        _progress = PlayerProgress.decodeJson(raw);
        selectedChapter = _progress.highestUnlockedChapter;
        _syncDeviceSettings();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('저장 불러오기 예외 복구: $e');
    }
  }

  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _progress.encodeJson());
    } catch (e) {
      debugPrint('자동 저장 예외 무시: $e');
    }
  }

  void setDifficulty(DefenseDifficulty diff) {
    selectedDifficulty = diff;
    NightAudioController.instance.playAsset('ui_tap.ogg');
    NightHaptics.instance.lightTap();
    notifyListeners();
  }

  void setSelectedChapter(int chapterNumber) {
    selectedChapter = chapterNumber.clamp(1, 10);
    NightAudioController.instance.playAsset('ui_tap.ogg');
    NightHaptics.instance.lightTap();
    notifyListeners();
  }

  void selectPreset(int index) {
    _progress.activePresetIndex = index.clamp(0, _progress.presets.length - 1);
    NightAudioController.instance.playAsset('ui_tap.ogg');
    NightHaptics.instance.lightTap();
    saveToDisk();
    notifyListeners();
  }

  /// 해당 스테이지의 추천 진법(알·발사대·동료·영수)을 원터치로 자동 맞춤 편성!
  void applyRecommendedLoadoutForStage(StageSpec stage) {
    final preset = _progress.activePreset;
    final bestStone = _progress.unlockedStones.toList()
      ..sort((a, b) => b.grade.compareTo(a.grade));
    if (bestStone.isNotEmpty) {
      preset.primaryStone = bestStone.first;
    }
    preset.primaryShape = stage.chapterNumber >= 4 ? StoneShape.sphere : StoneShape.round;

    final chSpec = CampaignCatalog.chapterOf(stage.chapterNumber);
    for (int i = 0; i < chSpec.mounts.length && i < preset.mountTypes.length; i++) {
      final rec = chSpec.mounts[i].recommendedType;
      if (rec.unlockChapter <= _progress.highestUnlockedChapter) {
        preset.mountTypes[i] = rec;
      }
    }

    final unlockedBeasts = SpiritBeast.values
        .where((b) => (_progress.beastLevels[b] ?? 0) > 0)
        .toList();
    if (unlockedBeasts.isNotEmpty) {
      preset.equippedBeast = unlockedBeasts.last;
      preset.beastCondition = unlockedBeasts.last.defaultCondition;
    }

    final unlockedHeroes = CompanionHero.values
        .where((h) => h != CompanionHero.mukhyeon && (_progress.companionLevels[h] ?? 0) > 0)
        .toList();
    if (unlockedHeroes.length >= 3) {
      preset.companions = unlockedHeroes.reversed.take(3).toList();
    }
    preset.autoUpgradeInBattle = true;

    NightAudioController.instance.playAsset('unlock.ogg');
    NightHaptics.instance.lightTap();
    saveToDisk();
    notifyListeners();
  }

  void updatePreset(void Function(LoadoutPreset preset) updater) {
    updater(_progress.activePreset);
    NightAudioController.instance.playAsset('ui_tap.ogg');
    saveToDisk();
    notifyListeners();
  }

  /// 초간단 단전 운기 1회 (실패 0% · 즉시 저장).
  MeditationResult meditate({required bool hitGoldenRing}) {
    final res = _progress.meditateOnce(hitGoldenRing: hitGoldenRing, rng: _rng);
    if (res.wasCriticalSerendipity || res.wasOneMoreSerendipity) {
      NightAudioController.instance.playAsset('serendipity_jackpot.wav');
      NightHaptics.instance.meridianOpen();
    } else {
      NightAudioController.instance.playAsset('motion_meridian.wav');
      NightHaptics.instance.lightTap();
    }
    saveToDisk();
    notifyListeners();
    return res;
  }

  /// 손목 부담 없는 연속 단전 운기 일괄 수행 (기본 10회 · 오늘의 깨달음 6배 포함 · 즉시 저장).
  MeditationResult meditateBatch(int count, {bool hitGoldenRing = true}) {
    final res = _progress.meditateBatch(
      count: count,
      hitGoldenRing: hitGoldenRing,
      rng: _rng,
    );
    if (res.wasCriticalSerendipity || res.wasOneMoreSerendipity) {
      NightAudioController.instance.playAsset('serendipity_jackpot.wav');
      NightHaptics.instance.meridianOpen();
    } else {
      NightAudioController.instance.playAsset('motion_meridian.wav');
      NightHaptics.instance.lightTap();
    }
    saveToDisk();
    notifyListeners();
    return res;
  }

  /// 십대 경맥 개통 (혈자리 점등 완료 시 실패 0% 개통!).
  MeridianStepSpec? openMeridian() {
    final opened = _progress.openNextMeridian();
    if (opened != null) {
      NightAudioController.instance.playAsset('motion_meridian.wav');
      NightAudioController.instance.playAsset('jingle_levelup.ogg');
      NightHaptics.instance.meridianOpen();
      saveToDisk();
      notifyListeners();
    }
    return opened;
  }

  bool upgradeCoreStat(CoreStatType type) {
    final ok = _progress.upgradeCoreStat(type);
    if (ok) {
      NightAudioController.instance.playAsset('tutorial_ok.ogg');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  // --- 증표 대장간 ---
  bool upgradeCentralGuardian() {
    final ok = _progress.upgradeCentralGuardian();
    if (ok) {
      NightAudioController.instance.playAsset('motion_gear.wav');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  bool upgradeLauncherPermanent(LauncherType type) {
    final ok = _progress.upgradeLauncherPermanent(type);
    if (ok) {
      NightAudioController.instance.playAsset('motion_gear.wav');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  bool unlockStone(StoneMaterial stone) {
    final ok = _progress.unlockStoneWithTokens(stone);
    if (ok) {
      _progress.activePreset.primaryStone = stone;
      NightAudioController.instance.playAsset('unlock.ogg');
      NightHaptics.instance.heavyImpact();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  // --- 영약각 ---
  bool breakthroughRealm() {
    final ok = _progress.breakthroughRealm();
    if (ok) {
      NightAudioController.instance.playAsset('jingle_levelup.ogg');
      NightHaptics.instance.meridianOpen();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  bool upgradeBeast(SpiritBeast beast) {
    final ok = _progress.unlockOrUpgradeBeast(beast);
    if (ok) {
      NightAudioController.instance.playAsset('reward.ogg');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  bool upgradeCompanion(CompanionHero hero) {
    final ok = _progress.unlockOrUpgradeCompanion(hero);
    if (ok) {
      NightAudioController.instance.playAsset('reward.ogg');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  // --- 물자 호송 · 심야 탐색 · 보름달 기연 ---
  bool startConvoy() {
    final ok = _progress.startSupplyConvoy();
    if (ok) {
      NightAudioController.instance.playAsset('motion_convoy.wav');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  DispatchClaimResult? claimConvoy() {
    final res = _progress.claimSupplyConvoy(_rng);
    if (res != null) {
      NightAudioController.instance.playAsset(
        res.wasCritical || res.wasEncoreOneMore ? 'serendipity_jackpot.wav' : 'motion_convoy.wav',
      );
      NightHaptics.instance.meridianOpen();
      saveToDisk();
      notifyListeners();
    }
    return res;
  }

  bool startExplore() {
    final ok = _progress.startNightExplore();
    if (ok) {
      NightAudioController.instance.playAsset('ui_open.ogg');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  DispatchClaimResult? claimExplore() {
    final res = _progress.claimNightExplore(_rng);
    if (res != null) {
      NightAudioController.instance.playAsset(
        res.wasCritical || res.wasEncoreOneMore ? 'serendipity_jackpot.wav' : 'jingle_reward.ogg',
      );
      NightHaptics.instance.meridianOpen();
      saveToDisk();
      notifyListeners();
    }
    return res;
  }

  DispatchClaimResult? claimFullMoon() {
    final res = _progress.claimFullMoonSerendipity(_rng);
    if (res != null) {
      NightAudioController.instance.playAsset('serendipity_jackpot.wav');
      NightHaptics.instance.chulduRumble();
      saveToDisk();
      notifyListeners();
    }
    return res;
  }

  // --- 출석부 · 일일/주간/월간 임무 · 비약 제조 · 영구 업적 ---
  NightRewardBundle? claimAttendance() {
    final bundle = _progress.claimAttendance(rng: _rng);
    if (bundle != null) {
      NightAudioController.instance.playAsset('jingle_reward.ogg');
      NightHaptics.instance.meridianOpen();
      saveToDisk();
      notifyListeners();
    }
    return bundle;
  }

  NightRewardBundle? claimMission(NightMissionSpec mission) {
    final bundle = _progress.claimMission(mission, rng: _rng);
    if (bundle != null) {
      NightAudioController.instance.playAsset('reward.ogg');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return bundle;
  }

  NightRewardBundle? claimDailyAllClear() {
    final bundle = _progress.claimDailyAllClear(rng: _rng);
    if (bundle != null) {
      NightAudioController.instance.playAsset('serendipity_jackpot.wav');
      NightHaptics.instance.chulduRumble();
      saveToDisk();
      notifyListeners();
    }
    return bundle;
  }

  bool craftConsumable(TacticalConsumable item) {
    final ok = _progress.craftConsumable(item);
    if (ok) {
      NightAudioController.instance.playAsset('unlock.ogg');
      NightHaptics.instance.lightTap();
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  NightRewardBundle? claimAchievement(NightAchievementSpec spec) {
    final bundle = _progress.claimAchievement(spec, rng: _rng);
    if (bundle != null) {
      NightAudioController.instance.playAsset('jingle_levelup.ogg');
      NightHaptics.instance.meridianOpen();
      saveToDisk();
      notifyListeners();
    }
    return bundle;
  }

  // --- 환경 설정 · 입문 교범 · 백업 복원 ---
  void markTutorialSeen() {
    if (!_progress.tutorialSeen) {
      _progress.tutorialSeen = true;
      saveToDisk();
      notifyListeners();
    }
  }

  void setBgmVolume(double vol) {
    _progress.bgmVolume = vol.clamp(0.0, 1.0);
    _syncDeviceSettings();
    saveToDisk();
    notifyListeners();
  }

  void setSfxVolume(double vol) {
    _progress.sfxVolume = vol.clamp(0.0, 1.0);
    _syncDeviceSettings();
    saveToDisk();
    notifyListeners();
  }

  void setVibration({bool? enabled, int? strength}) {
    if (enabled != null) _progress.vibrationEnabled = enabled;
    if (strength != null) _progress.vibrationStrength = strength.clamp(1, 3);
    _syncDeviceSettings();
    if (_progress.vibrationEnabled) {
      NightHaptics.instance.heavyImpact();
    }
    saveToDisk();
    notifyListeners();
  }

  String exportBackupCode() => _progress.exportBackupCode();

  bool importBackupCode(String rawCode) {
    final decoded = PlayerProgress.tryDecodeBackupCode(rawCode);
    if (decoded == null) return false;
    _progress = decoded;
    selectedChapter = _progress.highestUnlockedChapter;
    _syncDeviceSettings();
    NightAudioController.instance.playAsset('jingle_levelup.ogg');
    NightHaptics.instance.meridianOpen();
    saveToDisk();
    notifyListeners();
    return true;
  }

  void notifyConsumableUsedInBattle() {
    saveToDisk();
    notifyListeners();
  }

  void recordBattleSummary(StageSpec stage, BattleSummary summary) {
    _progress.onBattleFinished(
      stage: stage,
      victory: summary.victory,
      stars: summary.stars,
      earnedTokens: summary.earnedTokens,
      earnedElixirs: summary.earnedElixirs,
      usedSupportCount: summary.usedSupportCount,
      killCount: summary.killCount,
      pporokCount: summary.pporokCount,
      bankShotCount: summary.bankShotCount,
      chainShatterCount: summary.chainShatterCount,
      serendipityCount: summary.serendipityCount,
      encounteredMutants: summary.encounteredMutants,
      endlessWavesCleared: stage.globalIndex >= 900 ? summary.wavesClearedCount : 0,
    );
    saveToDisk();
    notifyListeners();
  }
}
