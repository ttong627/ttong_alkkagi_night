import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/night_audio.dart';

/// 앱 전역 상태 및 즉시 자동 저장 컨트롤러.
class GameController extends ChangeNotifier {
  GameController({PlayerProgress? initialProgress})
      : _progress = initialProgress ?? PlayerProgress();

  static const String _prefsKey = 'suho_alkkagi_night_save_v1';

  PlayerProgress _progress;
  DefenseDifficulty selectedDifficulty = DefenseDifficulty.normal;
  int selectedChapter = 1;
  final Random _rng = Random();

  PlayerProgress get progress => _progress;

  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        _progress = PlayerProgress.decodeJson(raw);
        selectedChapter = _progress.highestUnlockedChapter;
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
    notifyListeners();
  }

  void setSelectedChapter(int chapterNumber) {
    selectedChapter = chapterNumber.clamp(1, 10);
    NightAudioController.instance.playAsset('ui_tap.ogg');
    notifyListeners();
  }

  void selectPreset(int index) {
    _progress.activePresetIndex = index.clamp(0, _progress.presets.length - 1);
    NightAudioController.instance.playAsset('ui_tap.ogg');
    saveToDisk();
    notifyListeners();
  }

  /// 해당 스테이지의 추천 진법(알·발사대·동료·영수)을 원터치로 자동 맞춤 편성!
  void applyRecommendedLoadoutForStage(StageSpec stage) {
    final preset = _progress.activePreset;
    // 보유한 가장 높은 단수의 수호석 자동 장착
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

    // 보유 영수 중 최고 단계 자동 장착
    final unlockedBeasts = SpiritBeast.values
        .where((b) => (_progress.beastLevels[b] ?? 0) > 0)
        .toList();
    if (unlockedBeasts.isNotEmpty) {
      preset.equippedBeast = unlockedBeasts.last;
      preset.beastCondition = unlockedBeasts.last.defaultCondition;
    }

    // 보유 동료 중 상위 3인 자동 편성
    final unlockedHeroes = CompanionHero.values
        .where((h) => h != CompanionHero.mukhyeon && (_progress.companionLevels[h] ?? 0) > 0)
        .toList();
    if (unlockedHeroes.length >= 3) {
      preset.companions = unlockedHeroes.reversed.take(3).toList();
    }
    preset.autoUpgradeInBattle = true;

    NightAudioController.instance.playAsset('unlock.ogg');
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
    } else {
      NightAudioController.instance.playAsset('motion_meridian.wav');
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
      saveToDisk();
      notifyListeners();
    }
    return opened;
  }

  bool upgradeCoreStat(CoreStatType type) {
    final ok = _progress.upgradeCoreStat(type);
    if (ok) {
      NightAudioController.instance.playAsset('tutorial_ok.ogg');
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
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  bool upgradeLauncherPermanent(LauncherType type) {
    final ok = _progress.upgradeLauncherPermanent(type);
    if (ok) {
      NightAudioController.instance.playAsset('motion_gear.wav');
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
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  bool upgradeBeast(SpiritBeast beast) {
    final ok = _progress.unlockOrUpgradeBeast(beast);
    if (ok) {
      NightAudioController.instance.playAsset('reward.ogg');
      saveToDisk();
      notifyListeners();
    }
    return ok;
  }

  bool upgradeCompanion(CompanionHero hero) {
    final ok = _progress.unlockOrUpgradeCompanion(hero);
    if (ok) {
      NightAudioController.instance.playAsset('reward.ogg');
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
      saveToDisk();
      notifyListeners();
    }
    return res;
  }

  bool startExplore() {
    final ok = _progress.startNightExplore();
    if (ok) {
      NightAudioController.instance.playAsset('ui_open.ogg');
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
      saveToDisk();
      notifyListeners();
    }
    return res;
  }

  DispatchClaimResult? claimFullMoon() {
    final res = _progress.claimFullMoonSerendipity(_rng);
    if (res != null) {
      NightAudioController.instance.playAsset('serendipity_jackpot.wav');
      saveToDisk();
      notifyListeners();
    }
    return res;
  }

  void recordBattleSummary(StageSpec stage, BattleSummary summary) {
    _progress.onBattleFinished(
      stage: stage,
      victory: summary.victory,
      stars: summary.stars,
      earnedTokens: summary.earnedTokens,
      earnedElixirs: summary.earnedElixirs,
      usedSupportCount: summary.usedSupportCount,
    );
    saveToDisk();
    notifyListeners();
  }
}
