import 'dart:convert';
import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:test/test.dart';

String _forgeValidBackupCode(Map<String, dynamic> payloadMap) {
  final jsonStr = jsonEncode(payloadMap);
  final b64 = base64Url.encode(utf8.encode(jsonStr));
  int hash = 0x811c9dc5;
  for (final b in utf8.encode(b64)) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final checksum = hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  return 'SUHO1:$checksum:$b64';
}

void main() {
  group('캠페인 1~10장 및 재화 분리 검증', () {
    test('원작과 동일한 1~10장(10장 보스 10연전 포함 총 111단계)이 빈틈없이 구성되어 있다', () {
      expect(CampaignCatalog.chapters.length, 10);
      expect(CampaignCatalog.allStages.length, 111);
      final ch10 = CampaignCatalog.stagesOfChapter(10);
      expect(ch10.length, 10);
      expect(ch10.every((s) => s.isBossStage), isTrue);
      expect(ch10.last.outroDialogue, isNotEmpty);
    });

    test('증표는 발사대/중앙 장치 강화 전용이고 영약은 영수/동료/내공 승급 전용으로 완전히 분리된다', () {
      final p = PlayerProgress(tokens: 300, elixirs: 20, naegongPoints: 300);
      final beforeElixirs = p.elixirs;
      expect(p.upgradeCentralGuardian(), isTrue);
      expect(p.upgradeLauncherPermanent(LauncherType.rapid), isTrue);
      expect(p.elixirs, beforeElixirs);

      final beforeTokens = p.tokens;
      expect(p.breakthroughRealm(), isTrue);
      expect(p.unlockOrUpgradeBeast(SpiritBeast.nalssaendol), isTrue);
      expect(p.unlockOrUpgradeCompanion(CompanionHero.seokdu), isTrue);
      expect(p.tokens, beforeTokens);
    });
  });

  group('초간단 기명 심법 수련 (실패 0% · 알까기 없음) 검증', () {
    test('단전 운기 호흡은 황금 고리를 맞추든 안 맞추든 무효/실패가 0건이며 100% 내공과 인장이 적립된다', () {
      final p = PlayerProgress(naegongPoints: 0, trainingSeals: 0);
      final rng = Random(42);
      for (int i = 0; i < 15; i++) {
        final beforeNg = p.naegongPoints;
        final beforeSeal = p.trainingSeals;
        final res = p.meditateOnce(
          hitGoldenRing: i.isEven,
          rng: rng,
          todayKey: '2026-11-15',
        );
        expect(res.gainedNaegong, greaterThan(0));
        expect(res.gainedSeals, greaterThan(0));
        expect(p.naegongPoints, greaterThan(beforeNg));
        expect(p.trainingSeals, greaterThan(beforeSeal));
      }
      // 하루 첫 10회 깨달음 보너스 소진 확인
      expect(p.dailyEnlightenmentUsed, 10);
    });

    test('십대 경맥 개통(수련 1/10 ~ 10/10, 특히 6/10 충맥 개통 포함)이 혈자리 점등만으로 100% 돌파된다', () {
      final p = PlayerProgress(naegongPoints: 3000);
      for (int step = 1; step <= 10; step++) {
        expect(p.canOpenNextMeridian(), isTrue);
        final opened = p.openNextMeridian();
        expect(opened, isNotNull);
        expect(opened!.stepNumber, step);
        expect(opened.acupointCoords.length, inInclusiveRange(3, 5));
      }
      expect(p.openedMeridianStep, 10);
      expect(p.meridianCritBonus, greaterThan(0));
      expect(p.meridianLauncherDmgBonus, greaterThan(0.15));
    });
  });

  group('물자 호송 · 심야 탐색 · 암행어사 출두 지원패 및 직렬화 검증', () {
    test('호송·탐색·보름달 기연 3대 경로에서 지원패를 얻고, 출두 시 전장 돌연변이를 전멸시킨다', () {
      final p = PlayerProgress(
        highestClearedGlobalStage: 45,
        moonOmenGauge: 100,
        supportTokens: 1,
      );
      final rng = Random(77);

      expect(p.startSupplyConvoy(), isTrue);
      p.convoyBattlesRemaining = 0;
      final convoyRes = p.claimSupplyConvoy(rng);
      expect(convoyRes, isNotNull);
      expect(convoyRes!.gainedSupportTokens, greaterThanOrEqualTo(1));

      final moonRes = p.claimFullMoonSerendipity(rng);
      expect(moonRes, isNotNull);
      expect(moonRes!.gainedSupportTokens, greaterThanOrEqualTo(1));

      final stage = CampaignCatalog.stageAt(1, 1);
      final sim = DefenseBattleSim(
        stage: stage,
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 123,
      );
      for (int i = 0; i < 90; i++) {
        sim.step(1 / 30);
      }
      expect(sim.mutants, isNotEmpty);
      expect(sim.triggerSupportChuldu(), isTrue);
      expect(sim.mutants, isEmpty);
    });

    test('JSON 저장 및 복원이 손실 없이 정확히 일치한다', () {
      final p = PlayerProgress(tokens: 777, elixirs: 19, openedMeridianStep: 6);
      final raw = p.encodeJson();
      final decoded = PlayerProgress.decodeJson(raw);
      expect(decoded.tokens, 777);
      expect(decoded.elixirs, 19);
      expect(decoded.openedMeridianStep, 6);
    });
  });

  group('상용 완성형 7일 출석 · 수호 임무 · 전술 비약 · 도감 · 무한 혈전 · 백업 코드 검증', () {
    test('7일 순환 출석은 빠진 날이 있어도 초기화되지 않고 이어지며 시계 역행에 안전하다', () {
      final p = PlayerProgress(tokens: 0);
      expect(p.canClaimAttendance(todayKey: '2026-11-16'), isTrue);
      final day1 = p.claimAttendance(todayKey: '2026-11-16');
      expect(day1, isNotNull);
      expect(p.canClaimAttendance(todayKey: '2026-11-16'), isFalse);

      // 사흘 건너뛰어도 2일차 보상으로 이어짐
      final day2 = p.claimAttendance(todayKey: '2026-11-20');
      expect(day2, isNotNull);
      expect(p.attendanceStepCount, 2);

      // 기기 시계가 미래였다가 과거로 돌아온 경우 재수령 방지
      p.attendanceDayKey = '2026-12-31';
      expect(p.canClaimAttendance(todayKey: '2026-11-21'), isFalse);
    });

    test('일일·주간·월간 임무 달성 및 일일 올클리어 상자, 영구 업적 수령이 정상 작동한다', () {
      final p = PlayerProgress(highestClearedGlobalStage: 12, openedMeridianStep: 5);
      const day = '2026-11-16';
      final dailies = p.todayDailyMissions(todayKey: day);
      expect(dailies.length, 3);

      for (final d in NightDeed.values) {
        p.recordDeed(d, 50, todayKey: day);
      }
      for (final m in dailies) {
        expect(p.canClaimMission(m, todayKey: day), isTrue);
        expect(p.claimMission(m, todayKey: day), isNotNull);
      }
      expect(p.canClaimDailyAllClear(todayKey: day), isTrue);
      expect(p.claimDailyAllClear(todayKey: day), isNotNull);
      expect(p.canClaimDailyAllClear(todayKey: day), isFalse);

      final firstAch = NightAchievementSpec.all.first;
      expect(p.canClaimAchievement(firstAch), isTrue);
      expect(p.claimAchievement(firstAch), isNotNull);
      expect(p.canClaimAchievement(firstAch), isFalse);
    });

    test('전술 비약 3종 제조 및 전장 실시간 발동(내공 완충·방어막 수리·확정 회심)이 작동한다', () {
      final p = PlayerProgress(
        materials: {
          for (final m in CraftMaterial.values) m: 10,
        },
        consumables: {
          for (final c in TacticalConsumable.values) c: 0,
        },
      );
      for (final item in TacticalConsumable.values) {
        expect(p.canCraftConsumable(item), isTrue);
        expect(p.craftConsumable(item), isTrue);
        expect(p.consumables[item], 1);
      }

      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.normal,
        progress: p,
      );
      sim.qiBars = 0.0;
      sim.shieldHp = sim.centralSpec.shieldMaxHp * 0.4;
      expect(sim.activateConsumable(TacticalConsumable.qiSurgePill), isTrue);
      expect(sim.qiBars, 3.0);
      expect(sim.activateConsumable(TacticalConsumable.guardianRepairSeal), isTrue);
      expect(sim.shieldHp, greaterThan(sim.centralSpec.shieldMaxHp * 0.8));
      expect(sim.activateConsumable(TacticalConsumable.auroraCritCharm), isTrue);
      expect(sim.auroraCritTimer, closeTo(8.0, 0.01));
    });

    test('무한 혈전 생성기는 캠페인 진행도를 오염시키지 않으며 최고 물결 기록을 갱신한다', () {
      final p = PlayerProgress(highestClearedGlobalStage: 11);
      final endlessStage = EndlessWaveBuilder.buildEndlessStage(
        waveCount: 15,
        chapterTheme: 3,
      );
      expect(endlessStage.globalIndex, 999);
      expect(endlessStage.waves.length, 15);

      p.onBattleFinished(
        stage: endlessStage,
        victory: true,
        stars: 3,
        earnedTokens: 200,
        earnedElixirs: 6,
        usedSupportCount: 0,
        killCount: 120,
        endlessWavesCleared: 15,
        encounteredMutants: {MutantKind.swarmRat, MutantKind.plagueToad},
      );
      expect(p.highestClearedGlobalStage, 11);
      expect(p.bestEndlessWave, 15);
      expect(p.codexPowerBonus, greaterThan(0.02));
    });

    test('체크섬 백업 부호(SUHO1)는 정상 복원되며 1글자라도 위변조되면 거부한다', () {
      final p = PlayerProgress(
        tokens: 1234,
        elixirs: 56,
        bestEndlessWave: 20,
        bgmVolume: 0.55,
        vibrationStrength: 3,
      );
      final code = p.exportBackupCode();
      expect(code.startsWith('SUHO1:'), isTrue);

      final restored = PlayerProgress.tryDecodeBackupCode(code);
      expect(restored, isNotNull);
      expect(restored!.tokens, 1234);
      expect(restored.bestEndlessWave, 20);
      expect(restored.bgmVolume, closeTo(0.55, 0.001));
      expect(restored.vibrationStrength, 3);

      final tampered = '${code.substring(0, code.length - 2)}XX';
      expect(PlayerProgress.tryDecodeBackupCode(tampered), isNull);
    });
  });

  group('심층 보안 감사 1 · SUHO1 백업 코드 퍼징 및 음수/범위초과/열거형 방어 검증', () {
    test('캠페인 1~10장의 심야 배경(bg_night_ch1..10) 및 바닥(floor_night_ch1..10) 경로가 정확히 유지된다', () {
      for (int ch = 1; ch <= 10; ch++) {
        final spec = CampaignCatalog.chapterOf(ch);
        expect(spec.bgAsset, 'assets/images/scenes/bg_night_ch$ch.webp');
        expect(spec.floorAsset, 'assets/images/scenes/floor_night_ch$ch.webp');
      }
    });

    test('체크섬 1글자 변경, 잘린 Base64, 빈 문자열, 비정상 JSON 루트 및 무작위 퍼징 입력에 절대 죽지 않고 거부한다', () {
      final valid = PlayerProgress(tokens: 500, elixirs: 12).exportBackupCode();
      final parts = valid.split(':');
      expect(parts.length, 3);

      // 체크섬 1글자 위변조
      final origFirstChar = parts[1][0];
      final flippedChar = origFirstChar == 'A' ? 'B' : 'A';
      final checksumTampered = 'SUHO1:$flippedChar${parts[1].substring(1)}:${parts[2]}';
      expect(PlayerProgress.tryDecodeBackupCode(checksumTampered), isNull);

      // 페이로드 1글자 위변조
      final payloadOrig = parts[2];
      final mid = payloadOrig.length ~/ 2;
      final midFlipped = payloadOrig[mid] == 'a' ? 'b' : 'a';
      final payloadTampered =
          'SUHO1:${parts[1]}:${payloadOrig.substring(0, mid)}$midFlipped${payloadOrig.substring(mid + 1)}';
      expect(PlayerProgress.tryDecodeBackupCode(payloadTampered), isNull);

      // 잘린 Base64, 빈 문자열, 형식 오류
      expect(PlayerProgress.tryDecodeBackupCode(''), isNull);
      expect(PlayerProgress.tryDecodeBackupCode('   \n\t  '), isNull);
      expect(PlayerProgress.tryDecodeBackupCode('SUHO1:'), isNull);
      expect(PlayerProgress.tryDecodeBackupCode('SUHO1:12345678'), isNull);
      expect(PlayerProgress.tryDecodeBackupCode('SUHO1:12345678:a:b'), isNull);
      expect(
        PlayerProgress.tryDecodeBackupCode('SUHO1:${parts[1]}:${payloadOrig.substring(0, 5)}'),
        isNull,
      );

      // 유효한 체크섬을 가졌으나 JSON 루트가 배열/정수/깨진 문자열인 경우
      for (final badRaw in ['[]', '12345', '"hello"', 'null', '{broken_json']) {
        final b64 = base64Url.encode(utf8.encode(badRaw));
        int hash = 0x811c9dc5;
        for (final b in utf8.encode(b64)) {
          hash ^= b;
          hash = (hash * 0x01000193) & 0xffffffff;
        }
        final sum = hash.toRadixString(16).padLeft(8, '0').toUpperCase();
        expect(PlayerProgress.tryDecodeBackupCode('SUHO1:$sum:$b64'), isNull);
      }

      // 무작위 퍼징 200회 — 예외 발생 0건 보장
      final rng = Random(20261116);
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_:=!@#%^&*()[]{}';
      for (int i = 0; i < 200; i++) {
        final len = rng.nextInt(120);
        final fuzz = String.fromCharCodes(
          List.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
        );
        expect(() => PlayerProgress.tryDecodeBackupCode(fuzz), returnsNormally);
        expect(() => PlayerProgress.tryDecodeBackupCode('SUHO1:$fuzz'), returnsNormally);
      }
    });

    test('음수 재화·범위 초과·알 수 없는 열거형·타입 오염이 포함된 백업 복원 시 정상 범위로 안전 고정(clamp)된다', () {
      final maliciousCode = _forgeValidBackupCode({
        'tokens': -500,
        'elixirs': -100,
        'seals': -80,
        'naegong': -999,
        'realm': 999,
        'centralLv': -50,
        'support': -30,
        'moon': 9999,
        'highestClearedStage': 9999,
        'meridianStep': 999,
        'dailyUsed': 999,
        'convoyRem': -5,
        'convoyBuff': -9,
        'convoyCnt': -3,
        'exploreRem': 999,
        'presetIdx': 999,
        'attDay': 'ZZZZ-99-99_HACK',
        'attStep': -77,
        'totKills': -10,
        'totPporok': -20,
        'totBank': -30,
        'totChain': -40,
        'bestEndless': -5,
        'bgmVolume': 5.0,
        'sfxVolume': -3.5,
        'vibrationStrength': 99,
        'launcherLvs': {'rapid': -24, 'heavy': 99999, 'unknown_launcher': 50},
        'stones': ['unknown_stone_xyz', 'obsidian'],
        'shards': {'onok': -50, 'fake_shard': 999},
        'beasts': {'nalssaendol': -5, 'geumryong': 999, 'alien_beast': 7},
        'companions': {'seokdu': -10, 'yonga': 999, 'ghost_hero': 5},
        'coreStats': {'firepower': -100, 'unknown_stat': 99},
        'stars': {'1-1': 99, '1-2': -4},
        'materials': {'moonHerb': -55, 'fake_herb': 10},
        'consumables': {'qiSurgePill': -12, 'fake_pill': 8},
        'dDeeds': {'battleWin': -99, 'fake_deed': 12},
        'seenMutants': ['ghost_mutant', 'ironBoar'],
        'presets': [
          null,
          123,
          {
            'name': 99999,
            'stone': 'non_existent_stone',
            'shape': 'non_existent_shape',
            'sect': 'non_existent_sect',
            'mounts': ['unknown_mount'],
            'beast': 'unknown_beast',
            'beastCond': 'unknown_cond',
            'companions': ['unknown_comp1', 'unknown_comp2'],
            'compConds': {'unknown_hero': 'unknown_cond'},
            'supportSlots': 99,
            'supportRatio': 9.9,
            'autoUpg': 'not_a_bool',
          },
        ],
      });

      final restored = PlayerProgress.tryDecodeBackupCode(maliciousCode);
      expect(restored, isNotNull);
      final p = restored!;

      expect(p.tokens, 0);
      expect(p.elixirs, 0);
      expect(p.trainingSeals, 0);
      expect(p.naegongPoints, 0);
      expect(p.realmIndex, 7);
      expect(p.centralGuardianLevel, 1);
      expect(p.supportTokens, 0);
      expect(p.moonOmenGauge, 100);
      expect(p.highestClearedGlobalStage, CampaignCatalog.allStages.length);
      expect(p.openedMeridianStep, MeridianStepSpec.steps.length);
      expect(p.dailyEnlightenmentUsed, 10);
      expect(p.bgmVolume, 1.0);
      expect(p.sfxVolume, 0.0);
      expect(p.vibrationStrength, 3);
      expect(p.attendanceDayKey, isEmpty);
      expect(p.attendanceStepCount, 0);
      expect(p.activePresetIndex, 0);

      expect(p.launcherPermanentLevels[LauncherType.rapid], 1);
      expect(p.launcherPermanentLevels[LauncherType.heavy], 999);
      expect(p.unlockedStones.contains(StoneMaterial.cheongok), isTrue);
      expect(p.unlockedStones.contains(StoneMaterial.obsidian), isTrue);
      expect(p.stoneShards[StoneMaterial.onok], 0);
      expect(p.beastLevels[SpiritBeast.nalssaendol], 1);
      expect(p.beastLevels[SpiritBeast.geumryong], 10);
      expect(p.companionLevels[CompanionHero.seokdu], 0);
      expect(p.companionLevels[CompanionHero.yonga], 10);
      expect(p.coreStatLevels[CoreStatType.firepower], 0);
      expect(p.stageStars['1-1'], 3);
      expect(p.stageStars['1-2'], 0);
      expect(p.materials[CraftMaterial.moonHerb], 0);
      expect(p.consumables[TacticalConsumable.qiSurgePill], 0);
      expect(p.dailyDeeds[NightDeed.battleWin], 0);
      expect(p.seenMutants.contains(MutantKind.ironBoar), isTrue);
      expect(p.activePreset.supportSlotCount, 3);
      expect(p.activePreset.supportTriggerShieldRatio, closeTo(0.80, 1e-6));

      // 복원된 프로필로 즉시 전투 시뮬레이션 구동 시 NaN/오류 없음 확인
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 7,
      );
      for (int i = 0; i < 60; i++) {
        sim.step(1 / 60);
      }
      expect(sim.shieldHp.isFinite, isTrue);
      expect(sim.towerHp.isFinite, isTrue);
    });
  });

  group('심층 보안 감사 2 · 출석 순환 · 시계 역행 차단 · 비약 제조 · 업적 · 도감 무결성', () {
    test('기기 시계를 과거로 되돌려도 출석·일일 깨달음·주간/월간 임무 중복 수령이 완벽히 차단되며, 7일차 다음 날 1일차로 순환한다', () {
      final p = PlayerProgress(tokens: 0, elixirs: 0, supportTokens: 0);
      final rng = Random(101);

      // 1~7일차 순차 수령 검증
      final claimedRewards = <NightRewardBundle>[];
      for (int d = 1; d <= 7; d++) {
        final dayStr = '2026-11-0$d';
        expect(p.currentAttendanceDayIndex, d - 1);
        final r = p.claimAttendance(rng: rng, todayKey: dayStr);
        expect(r, isNotNull);
        claimedRewards.add(r!);
        // 같은 날 중복 수령 불가
        expect(p.claimAttendance(rng: rng, todayKey: dayStr), isNull);
      }
      expect(claimedRewards.last.tokens, NightAttendance.sevenDayRewards[6].tokens);
      expect(p.attendanceStepCount, 7);

      // 기기 시계를 과거(11월 5일, 10월 15일)로 되돌려 출석 시도 → 차단!
      expect(p.canClaimAttendance(todayKey: '2026-11-05'), isFalse);
      expect(p.claimAttendance(rng: rng, todayKey: '2026-11-05'), isNull);
      expect(p.claimAttendance(rng: rng, todayKey: '2026-10-15'), isNull);
      // 다시 원래 마지막 수령일(11월 7일)로 돌려도 중복 수령 차단!
      expect(p.claimAttendance(rng: rng, todayKey: '2026-11-07'), isNull);

      // 8번째 출석일(11월 8일)에는 정확히 1일차(index 0) 보상으로 순환!
      expect(p.currentAttendanceDayIndex, 0);
      final cycleDay1 = p.claimAttendance(rng: rng, todayKey: '2026-11-08');
      expect(cycleDay1, isNotNull);
      expect(cycleDay1!.tokens, NightAttendance.sevenDayRewards[0].tokens);
      expect(p.attendanceStepCount, 8);

      // 단전 운기 일일 깨달음 10회 소진 후 시계 역행 시 초기화 악용 차단 확인
      for (int i = 0; i < 10; i++) {
        final res = p.meditateOnce(hitGoldenRing: false, rng: rng, todayKey: '2026-11-08');
        expect(res.wasEnlightenmentBonus, isTrue);
      }
      expect(
        p.meditateOnce(hitGoldenRing: false, rng: rng, todayKey: '2026-11-07').wasEnlightenmentBonus,
        isFalse,
      );

      // 주간/월간 임무 달성 수령 후 과거 달로 시계 조작 시 재수령 차단 확인
      final weeklyMission = NightQuestCatalog.weeklyMissions.first;
      p.recordDeed(weeklyMission.deed, weeklyMission.goal, todayKey: '2026-11-16');
      expect(p.claimMission(weeklyMission, rng: rng, todayKey: '2026-11-16'), isNotNull);
      p.syncQuestPeriods(todayKey: '2026-10-01');
      p.syncQuestPeriods(todayKey: '2026-11-16');
      expect(p.isMissionClaimed(weeklyMission, todayKey: '2026-11-16'), isTrue);
      expect(p.claimMission(weeklyMission, rng: rng, todayKey: '2026-11-16'), isNull);
    });

    test('재료 부족 시 전술 비약 제조가 거부되고 재료가 음수가 되지 않으며, 업적 중복 수령이 차단된다', () {
      final p = PlayerProgress(
        tokens: 100,
        elixirs: 5,
        highestClearedGlobalStage: 1,
        materials: {
          CraftMaterial.moonHerb: 2, // 기공 급속단 재료 중 야광초(2)는 충족하지만
          CraftMaterial.frostJade: 0, // 한빙옥(1)이 부족한 경계 조건
          CraftMaterial.hyeoncheolOre: 0,
          CraftMaterial.thunderPowder: 0,
        },
        consumables: {
          for (final c in TacticalConsumable.values) c: 0,
        },
      );

      for (int i = 0; i < 10; i++) {
        expect(p.canCraftConsumable(TacticalConsumable.qiSurgePill), isFalse);
        expect(p.craftConsumable(TacticalConsumable.qiSurgePill), isFalse);
        expect(p.craftConsumable(TacticalConsumable.guardianRepairSeal), isFalse);
        expect(p.craftConsumable(TacticalConsumable.auroraCritCharm), isFalse);
      }
      // 부분 재료였던 야광초도 깎이지 않고 모든 재료가 0 이상 유지
      expect(p.materials[CraftMaterial.moonHerb], 2);
      for (final m in CraftMaterial.values) {
        expect(p.materials[m]! >= 0, isTrue);
      }
      for (final c in TacticalConsumable.values) {
        expect(p.consumables[c], 0);
      }

      // 업적: 달성된 첫 업적은 딱 1회만 수령되고 중복 수령은 차단, 미달성 업적은 즉시 거부
      final metAch = NightAchievementSpec.all.firstWhere((a) => a.id == 'ach_first_dawn');
      final unmetAch = NightAchievementSpec.all.firstWhere((a) => a.id == 'ach_ch10_clear');

      expect(p.claimAchievement(unmetAch), isNull);
      final tokensBefore = p.tokens;
      final firstClaim = p.claimAchievement(metAch);
      expect(firstClaim, isNotNull);
      expect(p.tokens, tokensBefore + metAch.reward.tokens);

      final tokensAfterFirst = p.tokens;
      expect(p.canClaimAchievement(metAch), isFalse);
      expect(p.claimAchievement(metAch), isNull);
      expect(p.tokens, tokensAfterFirst);

      // 도감 무결성: 전체 요소 수집 시에도 수집률 100%, 보너스 최대 0.12 고정
      p.unlockedStones.addAll(StoneMaterial.values);
      p.highestClearedGlobalStage = CampaignCatalog.allStages.length;
      for (final b in SpiritBeast.values) {
        p.beastLevels[b] = 5;
      }
      for (final h in CompanionHero.values) {
        p.companionLevels[h] = 5;
      }
      p.seenMutants.addAll(MutantKind.values);
      expect(p.codexCollectedCount, p.codexTotalCount);
      expect(p.codexPowerBonus, closeTo(0.12, 1e-9));
    });
  });

  group('심층 보안 감사 3 · 60프레임 물리 전투 및 기명 심법 수련 엣지케이스 검증', () {
    test('두 돌·기둥·변이체의 중심 좌표가 완전히 겹쳤을 때(dist == 0) NaN이나 무한대가 절대 발생하지 않는다', () {
      const samePos = Vec2(200.0, 290.0);
      expect(samePos.distanceTo(samePos), 0.0);
      final normZero = (samePos - samePos).normalized;
      expect(normZero.x.isFinite && normZero.y.isFinite, isTrue);

      final nanVec = const Vec2(double.nan, double.infinity);
      expect(nanVec.length, 0.0);
      expect(nanVec.normalized.x.isFinite && nanVec.normalized.y.isFinite, isTrue);

      final zeroBurst = FxBurst(pos: samePos, colorHex: 0xFFFFFFFF, maxRadius: 20, durationSec: 0, ttlSec: 0);
      expect(zeroBurst.progress.isFinite, isTrue);

      final p = PlayerProgress();
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 555,
      );

      // 회전 기둥 중심(200, 290) 및 마을 중심(200, 565)에 변이체·투사체를 정확히 겹쳐 배치(dist == 0)
      final pillarPos = sim.chapter.pillars.first.center;
      final lane = sim.chapter.lanes.first;
      sim.mutants.addAll([
        ActiveMutant(
          uid: 9001,
          kind: MutantKind.ironBoar,
          laneIndex: 0,
          waypoints: lane,
          pos: pillarPos,
          maxHp: 200,
          speed: 40,
        ),
        ActiveMutant(
          uid: 9002,
          kind: MutantKind.swarmRat,
          laneIndex: 0,
          waypoints: lane,
          pos: pillarPos,
          maxHp: 40,
          speed: 60,
        ),
        ActiveMutant(
          uid: 9003,
          kind: MutantKind.plagueToad,
          laneIndex: 0,
          waypoints: lane,
          pos: CampaignCatalog.villageCenter,
          maxHp: 120,
          speed: 35,
        ),
      ]);
      sim.projectiles.addAll([
        ActiveStoneProjectile(
          sourceKey: 'test_overlap_pillar',
          sourceLabel: '중첩 시험탄',
          pos: pillarPos,
          vel: const Vec2(0, 0),
          material: StoneMaterial.obsidian,
          shape: StoneShape.sphere,
          damage: 85,
          knockback: 90,
          critChance: 1.0,
          colorHex: 0xFFFFFFFF,
          aoeSplashRadius: 60,
          pullsEnemies: true,
        ),
        ActiveStoneProjectile(
          sourceKey: 'test_overlap_center',
          sourceLabel: '중심 시험탄',
          pos: CampaignCatalog.villageCenter,
          vel: const Vec2(0, 0),
          material: StoneMaterial.cheongok,
          shape: StoneShape.round,
          damage: 50,
          knockback: 60,
          critChance: 1.0,
          colorHex: 0xFFFFFFFF,
        ),
      ]);

      // 비정상 dt 방어 및 60프레임 연속 물리 스텝 검증
      sim.step(0.0);
      sim.step(-0.016);
      sim.step(double.nan);
      sim.step(double.infinity);

      for (int frame = 0; frame < 120; frame++) {
        sim.step(1.0 / 60.0);
        expect(sim.shieldHp.isFinite, isTrue);
        expect(sim.towerHp.isFinite, isTrue);
        expect(sim.qiBars.isFinite, isTrue);
        for (final m in sim.mutants) {
          expect(m.pos.x.isFinite && m.pos.y.isFinite, isTrue);
          expect(m.knockbackVel.x.isFinite && m.knockbackVel.y.isFinite, isTrue);
          expect(m.hp.isFinite, isTrue);
        }
        for (final proj in sim.projectiles) {
          expect(proj.pos.x.isFinite && proj.pos.y.isFinite, isTrue);
          expect(proj.vel.x.isFinite && proj.vel.y.isFinite, isTrue);
        }
      }
    });

    test('전술 비약(activateConsumable) 보유량이 0개일 때 연타해도 무효 처리되며 상태가 오염되지 않는다', () {
      final p = PlayerProgress(
        consumables: {
          for (final item in TacticalConsumable.values) item: 0,
        },
      );
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 99,
      );
      sim.qiBars = 0.5;
      sim.shieldHp = 100.0;
      sim.auroraCritTimer = 0.0;

      for (int i = 0; i < 50; i++) {
        for (final item in TacticalConsumable.values) {
          expect(sim.activateConsumable(item), isFalse);
          expect(p.consumables[item], 0);
        }
      }
      expect(sim.qiBars, 0.5);
      expect(sim.shieldHp, 100.0);
      expect(sim.auroraCritTimer, 0.0);

      // 보유량이 1개 있어도 전투 종료(isFinished) 상태에서는 발동 불가·차감 없음
      p.consumables[TacticalConsumable.qiSurgePill] = 1;
      sim.isFinished = true;
      expect(sim.activateConsumable(TacticalConsumable.qiSurgePill), isFalse);
      expect(p.consumables[TacticalConsumable.qiSurgePill], 1);
    });

    test('무림수호단 출두 발동 시 분열형 변이체(bloodCocoon, 2단 연쇄 경계 포함)까지 잔여 찌꺼기 0마리로 정화된다', () {
      final p = PlayerProgress(supportTokens: 3);
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(4, 5),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 2026,
      );
      sim.mutants.clear();
      final lane = sim.chapter.lanes.first;

      // 2단 연쇄 박살(chainDepth == 2) 경계에 걸리는 밀집 대형 + 혈독 분열충 다수 배치
      sim.mutants.addAll([
        ActiveMutant(
          uid: 1,
          kind: MutantKind.swarmRat,
          laneIndex: 0,
          waypoints: lane,
          pos: const Vec2(150, 250),
          maxHp: 40,
          speed: 50,
        ),
        ActiveMutant(
          uid: 2,
          kind: MutantKind.sickHound,
          laneIndex: 0,
          waypoints: lane,
          pos: const Vec2(162, 255),
          maxHp: 55,
          speed: 50,
        ),
        ActiveMutant(
          uid: 3,
          kind: MutantKind.bloodCocoon,
          laneIndex: 0,
          waypoints: lane,
          pos: const Vec2(174, 260),
          maxHp: 95,
          speed: 45,
        ),
        ActiveMutant(
          uid: 4,
          kind: MutantKind.bloodCocoon,
          laneIndex: 0,
          waypoints: lane,
          pos: const Vec2(230, 310),
          maxHp: 95,
          speed: 45,
        ),
        ActiveMutant(
          uid: 5,
          kind: MutantKind.shieldYacha,
          laneIndex: 0,
          waypoints: lane,
          pos: const Vec2(260, 340),
          maxHp: 120,
          speed: 45,
        ),
      ]);

      expect(sim.triggerSupportChuldu(), isTrue);
      // 분열 독쥐를 포함한 모든 일반·정예 변이체가 단 1마리도 남지 않고 정화됨
      expect(sim.mutants, isEmpty);
    });

    test('무한 혈전(10·20·30파) 생성 및 보상 정산에서 일반 캠페인 기록(highestClearedGlobalStage·별점·동료)이 절대 오염되지 않는다', () {
      final p = PlayerProgress(highestClearedGlobalStage: 15);
      p.stageStars['1-1'] = 3;
      final beforeCompanions = Map<CompanionHero, int>.from(p.companionLevels);

      for (final waveTarget in [10, 20, 30]) {
        // 스토리 동료 합류 장 번호(2, 4, 6장)를 테마로 넣어도 캠페인과 완전히 격리되어야 함
        final theme = waveTarget == 10 ? 2 : (waveTarget == 20 ? 4 : 6);
        final stage = EndlessWaveBuilder.buildEndlessStage(
          waveCount: waveTarget,
          chapterTheme: theme,
        );
        expect(stage.globalIndex, 999);
        expect(stage.waves.length, waveTarget);

        final beforeTokens = p.tokens;
        final beforeElixirs = p.elixirs;
        p.onBattleFinished(
          stage: stage,
          victory: true,
          stars: 3,
          earnedTokens: 150 + waveTarget * 5,
          earnedElixirs: stage.clearElixirBonus,
          usedSupportCount: 0,
          killCount: waveTarget * 12,
          endlessWavesCleared: waveTarget,
          todayKey: '2026-11-16',
        );

        expect(p.highestClearedGlobalStage, 15);
        expect(p.stageStars.length, 1);
        expect(p.stageStars['1-1'], 3);
        expect(p.companionLevels, equals(beforeCompanions));
        expect(p.bestEndlessWave, waveTarget);
        expect(p.tokens, greaterThan(beforeTokens));
        expect(p.elixirs, greaterThan(beforeElixirs));
      }
    });

    test('기명 심법 수련 1~10단계 전체가 초기 상태부터 단전 운기·혈자리 점등만으로 실패 0건으로 완주된다', () {
      final p = PlayerProgress(
        naegongPoints: 0,
        trainingSeals: 0,
        openedMeridianStep: 0,
        tokens: 0,
        elixirs: 0,
        supportTokens: 0,
      );
      final rng = Random(20261115);
      int meditationCount = 0;

      for (int targetStep = 1; targetStep <= 10; targetStep++) {
        final spec = MeridianStepSpec.steps[targetStep - 1];
        expect(spec.stepNumber, targetStep);
        expect(spec.acupointNames.length, spec.acupointCoords.length);
        for (final coord in spec.acupointCoords) {
          expect(coord.x, inInclusiveRange(0.0, 1.0));
          expect(coord.y, inInclusiveRange(0.0, 1.0));
        }

        // 필요 내공 도달까지 단전 터치·자동 운기 수행 — 매 회차 실패 0건 검증
        int dayOffset = 0;
        while (!p.canOpenNextMeridian()) {
          final dayKey = '2026-11-${(1 + (dayOffset ~/ 12)).toString().padLeft(2, '0')}';
          final res = p.meditateOnce(
            hitGoldenRing: meditationCount % 3 == 0,
            rng: rng,
            todayKey: dayKey,
          );
          expect(res.gainedNaegong, greaterThan(0));
          expect(res.gainedSeals, greaterThan(0));
          meditationCount++;
          dayOffset++;
        }

        // 혈자리 점등 완료 후 개통 — 실패 0건 즉시 돌파 검증
        final opened = p.openNextMeridian();
        expect(opened, isNotNull);
        expect(opened!.stepNumber, targetStep);
        expect(p.openedMeridianStep, targetStep);
      }

      expect(p.openedMeridianStep, 10);
      expect(p.canOpenNextMeridian(), isFalse);
      expect(p.openNextMeridian(), isNull);
      expect(p.tokens, greaterThan(1500));
      expect(p.elixirs, greaterThanOrEqualTo(38));
      expect(p.supportTokens, 4);
    });
  });

  group('돌연변이 12종 전투력 3대 분화 · 중간보스 동반 침공 · 실시간 모션 물리 검증', () {
    test('12종 변이체·중간보스·대수괴의 원화 식별자(id), 3대 등급(스피드·맷집·공격력), 전투력 지수(combatPower)가 정밀 분화된다', () {
      expect(MutantKind.values.length, 12);
      final expectedIds = [
        'swarmRat',
        'sickHound',
        'ironBoar',
        'shieldYacha',
        'plagueToad',
        'bloodCocoon',
        'swiftShadowBoss',
        'ironColossusBoss',
        'crimsonBreakerBoss',
        'heukpung',
        'mukhyeonBoss',
        'chapterBoss',
      ];
      expect(MutantKind.values.map((m) => m.id).toList(), expectedIds);

      for (final m in MutantKind.values) {
        expect(m.speedRating, inInclusiveRange(1, 5));
        expect(m.toughnessRating, inInclusiveRange(1, 5));
        expect(m.attackRating, inInclusiveRange(1, 5));
        expect(m.shieldDamage, m.attackPower);
        expect(m.roleTag, isNotEmpty);
        expect(m.gaitId, isNotEmpty);
        expect(m.traitDesc, isNotEmpty);
      }

      // 특화 중간보스 3종의 스피드·맷집·공격력 5성 특화 확인
      expect(MutantKind.swiftShadowBoss.speedRating, 5);
      expect(MutantKind.swiftShadowBoss.isMidBoss, isTrue);
      expect(MutantKind.swiftShadowBoss.isBoss, isTrue);

      expect(MutantKind.ironColossusBoss.toughnessRating, 5);
      expect(MutantKind.ironColossusBoss.armorReduction, closeTo(0.22, 1e-6));
      expect(MutantKind.ironColossusBoss.isMidBoss, isTrue);

      expect(MutantKind.crimsonBreakerBoss.attackRating, 5);
      expect(MutantKind.crimsonBreakerBoss.attackPower, closeTo(64.0, 1e-6));
      expect(MutantKind.crimsonBreakerBoss.isMidBoss, isTrue);

      // 전투력 지수 계층 분화 검증 (독쥐 ~115 < 들개 ~185 < 멧돼지 ~390 < 중간보스 780~1150 < 대수괴 ~1950)
      expect(MutantKind.swarmRat.combatPower, inInclusiveRange(100, 135));
      expect(MutantKind.sickHound.combatPower, inInclusiveRange(165, 205));
      expect(MutantKind.ironBoar.combatPower, inInclusiveRange(355, 420));
      expect(MutantKind.swiftShadowBoss.combatPower, inInclusiveRange(780, 1150));
      expect(MutantKind.crimsonBreakerBoss.combatPower, inInclusiveRange(780, 1150));
      expect(MutantKind.ironColossusBoss.combatPower, inInclusiveRange(780, 1150));
      expect(MutantKind.chapterOverlord.combatPower, inInclusiveRange(1850, 2050));
      expect(MutantKind.chapterOverlord.isMidBoss, isFalse);
      expect(MutantKind.chapterOverlord.isBoss, isTrue);
    });

    test('캠페인 제1~9장의 2단계 이상 모든 스테이지 중간 웨이브에 스피드·맷집·공격력 중간보스가 일반 무리와 동반 침략한다', () {
      final seenSpecialMidBosses = <MutantKind>{};

      for (int ch = 1; ch <= 9; ch++) {
        final stages = CampaignCatalog.stagesOfChapter(ch);
        for (final st in stages) {
          if (st.stageNumber < 2) continue;
          expect(st.waves.length, greaterThanOrEqualTo(3));
          final midWave = st.waves[1];

          // 일반 돌연변이 무리와 특화 중간보스가 같은 제2웨이브에 동시에 존재해야 함
          final normalGroups = midWave.where((g) => !g.kind.isBoss).toList();
          final midBossGroups = midWave.where((g) => g.kind.isMidBoss).toList();
          expect(normalGroups.length, greaterThanOrEqualTo(2), reason: '${st.code} 일반 호위 무리 누락');
          expect(midBossGroups.length, 1, reason: '${st.code} 중간보스 동반 침략 누락');

          final bossGroup = midBossGroups.first;
          expect(
            {
              MutantKind.swiftShadowBoss,
              MutantKind.ironColossusBoss,
              MutantKind.crimsonBreakerBoss,
            }.contains(bossGroup.kind),
            isTrue,
          );
          expect(bossGroup.customBossTitle, isNotNull);
          expect(bossGroup.customBossTitle, isNotEmpty);
          seenSpecialMidBosses.add(bossGroup.kind);
        }
      }

      // 3종 특화 중간보스 모두 골고루 출격함 확인
      expect(seenSpecialMidBosses.length, 3);
    });

    test('무한 혈전(EndlessCatalog)에서 3파도마다 스피드·맷집·공격력 중간보스가 교대로 일반 무리와 동반 침략한다', () {
      final endless = EndlessCatalog.buildEndlessStage(waveCount: 18, chapterTheme: 5);
      expect(endless.waves.length, 18);

      final expectedCycle = [
        MutantKind.swiftShadowBoss,
        MutantKind.ironColossusBoss,
        MutantKind.crimsonBreakerBoss,
        MutantKind.swiftShadowBoss,
        MutantKind.ironColossusBoss,
        MutantKind.crimsonBreakerBoss,
      ];

      for (int idx = 0; idx < expectedCycle.length; idx++) {
        final waveNum = (idx + 1) * 3;
        final groups = endless.waves[waveNum - 1];
        expect(groups.any((g) => !g.kind.isBoss), isTrue);
        expect(groups.any((g) => g.kind == expectedCycle[idx]), isTrue);
      }
    });

    test('실시간 모션 상태값(animPhase·dashBurstTimer·lanePortalEnergy·bossInvasionAlertText)이 갱신되고 빙결 시 정지하며 NaN이 0건이다', () {
      final p = PlayerProgress();
      // (1 + 2) % 3 == 0 이므로 1-2 스테이지 제2웨이브에는 혈영 질풍귀(swiftShadowBoss)가 동반 침략
      final stage = CampaignCatalog.stageAt(1, 2);
      final sim = DefenseBattleSim(
        stage: stage,
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 20261116,
      );

      expect(sim.lanePortalEnergy.length, sim.chapter.lanes.length);
      expect(sim.lanePortalEnergy.any((e) => e > 0.0), isTrue);

      bool sawBossAlert = false;
      bool sawShadowDash = false;

      // 제1웨이브를 빠르게 정리해 제2웨이브 중간보스 동반 침공을 유도
      for (int stepIdx = 0; stepIdx < 900 && !sim.isFinished; stepIdx++) {
        if (sim.currentWaveIndex == 0 && stepIdx > 30 && sim.mutants.isNotEmpty) {
          for (final m in List<ActiveMutant>.from(sim.mutants)) {
            sim.projectiles.add(
              ActiveStoneProjectile(
                sourceKey: 'test_fast_clear',
                sourceLabel: '신속 정리탄',
                pos: m.pos,
                vel: const Vec2(0, -200),
                material: StoneMaterial.hyeoncheol,
                shape: StoneShape.round,
                damage: 500,
                knockback: 20,
                critChance: 1.0,
                colorHex: 0xFFFFFFFF,
              ),
            );
          }
        }

        sim.step(1.0 / 30.0);

        for (final e in sim.lanePortalEnergy) {
          expect(e.isFinite && e >= 0.0 && e <= 1.0, isTrue);
        }
        expect(sim.screenShakeTimer.isFinite, isTrue);
        expect(sim.screenShakeIntensity.isFinite, isTrue);
        expect(sim.bossInvasionAlertTimer.isFinite, isTrue);

        if (!sawBossAlert &&
            sim.bossInvasionAlertText != null &&
            sim.bossInvasionAlertText!.contains('중간보스 동반 침략') &&
            sim.bossInvasionAlertText!.contains('혈영 질풍귀')) {
          sawBossAlert = true;
          expect(sim.screenShakeTimer, greaterThan(0.0));
          expect(sim.screenShakeIntensity, greaterThan(0.0));
        }

        for (final m in sim.mutants) {
          expect(m.animPhase.isFinite && m.animPhase >= 0.0, isTrue);
          expect(m.headingRad.isFinite, isTrue);
          expect(m.attackAnimTimer.isFinite, isTrue);
          expect(m.hitFlashTimer.isFinite, isTrue);
          expect(m.dashBurstTimer.isFinite, isTrue);
          expect(m.spawnPortalTimer.isFinite, isTrue);
          if (m.kind == MutantKind.swiftShadowBoss && m.dashBurstTimer > 0) {
            sawShadowDash = true;
            expect(m.attackAnimTimer, greaterThan(0.0));
          }
        }
      }

      expect(sawBossAlert, isTrue);
      expect(sawShadowDash, isTrue);

      // 빙결 시 animPhase 가 정확히 정지하는지 검증
      final frozenTestMutant = ActiveMutant(
        uid: 77777,
        kind: MutantKind.plagueToad,
        laneIndex: 0,
        waypoints: sim.chapter.lanes.first,
        pos: const Vec2(120, 220),
        maxHp: 500,
        speed: 40,
      )
        ..animPhase = 3.25
        ..freezeTimer = 1.5;
      sim.isFinished = false;
      sim.shieldHp = 100.0;
      sim.towerHp = 100.0;
      sim.mutants
        ..clear()
        ..add(frozenTestMutant);
      sim.projectiles.clear();
      sim.step(1.0 / 60.0);
      expect(frozenTestMutant.animPhase, closeTo(3.25, 1e-9));

      // 빙결 해제 후 이동 시 animPhase 증가 확인
      frozenTestMutant.freezeTimer = 0.0;
      sim.step(1.0 / 60.0);
      expect(frozenTestMutant.animPhase, greaterThan(3.25));
    });

    test('맷집 장갑(armorReduction) 감쇄 및 고밀도 수호석(density >= 1.35)·중포 탄지기·회심 50% 반관통과 hitFlashTimer 갱신이 정확히 작동한다', () {
      final lightProg = PlayerProgress();
      lightProg.activePreset.primaryStone = StoneMaterial.cheongok; // density 1.0
      final simLight = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.normal,
        progress: lightProg,
        allowSerendipity: false,
      );
      simLight.mutants.clear();
      simLight.projectiles.clear();

      final colossusLight = ActiveMutant(
        uid: 8001,
        kind: MutantKind.ironColossusBoss, // armorReduction 0.22, frontShieldReduction 0.30
        laneIndex: 0,
        waypoints: simLight.chapter.lanes.first,
        pos: const Vec2(200, 260),
        maxHp: 1000.0,
        speed: 0.0,
      );
      final colossusHeavy = ActiveMutant(
        uid: 8002,
        kind: MutantKind.ironColossusBoss,
        laneIndex: 0,
        waypoints: simLight.chapter.lanes.first,
        pos: const Vec2(120, 260),
        maxHp: 1000.0,
        speed: 0.0,
      );
      simLight.mutants.addAll([colossusLight, colossusHeavy]);

      // 1) 가벼운 청옥(density 1.0) 일반탄(방패 무시 설정으로 순수 armorReduction 검증): 22% 온전히 감쇄 → 100 * 0.78 = 78 피해
      simLight.projectiles.add(
        ActiveStoneProjectile(
          sourceKey: 'launcher_0',
          sourceLabel: '속사 탄지기(1거점)',
          pos: colossusLight.pos,
          vel: const Vec2(0, -250),
          material: StoneMaterial.cheongok,
          shape: StoneShape.round,
          damage: 100.0,
          knockback: 10.0,
          critChance: 0.0,
          colorHex: 0xFFFFFFFF,
          ignoresShield: true,
        ),
      );

      // 2) 고밀도 현철(density 2.35 >= 1.35) 탄: 장갑 50% 반관통(11%만 감쇄) → 100 * 0.89 = 89 피해
      simLight.projectiles.add(
        ActiveStoneProjectile(
          sourceKey: 'launcher_1',
          sourceLabel: '중포 탄지기(2거점)',
          pos: colossusHeavy.pos,
          vel: const Vec2(0, -250),
          material: StoneMaterial.hyeoncheol,
          shape: StoneShape.round,
          damage: 100.0,
          knockback: 10.0,
          critChance: 0.0,
          colorHex: 0xFFFFFFFF,
          ignoresShield: true,
        ),
      );

      simLight.step(1.0 / 60.0);

      expect(colossusLight.hp, closeTo(922.0, 1e-4));
      expect(colossusHeavy.hp, closeTo(911.0, 1e-4));
      expect(colossusLight.hitFlashTimer, closeTo(1.0, 1e-4));
      expect(colossusHeavy.hitFlashTimer, closeTo(1.0, 1e-4));
    });

    test('공격력 5성 보스(적염 파성귀)가 방어막 충돌 시 attackPower만큼 강타하고 화면 진동과 덮치기 모션을 구동한다', () {
      final p = PlayerProgress();
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        allowSerendipity: false,
      );
      sim.mutants.clear();
      sim.projectiles.clear();
      sim.bursts.clear();
      sim.screenShakeTimer = 0.0;

      final beforeShield = sim.shieldHp;
      final breaker = ActiveMutant(
        uid: 9901,
        kind: MutantKind.crimsonBreakerBoss, // attackPower 64.0, attackRating 5
        laneIndex: 0,
        waypoints: sim.chapter.lanes.first,
        pos: CampaignCatalog.villageCenter + const Vec2(0, -CampaignCatalog.outerShieldRadius),
        maxHp: 600.0,
        speed: 45.0,
      );
      sim.mutants.add(breaker);

      sim.step(1.0 / 60.0);

      // 방어막 미세 회복량 감안 시 약 64.0 만큼 묵직하게 깎이고 덮치기 모션·화면 진동·파쇄 입자가 발동됨
      expect(beforeShield - sim.shieldHp, closeTo(MutantKind.crimsonBreakerBoss.attackPower, 0.2));
      expect(breaker.attackAnimTimer, closeTo(1.0, 1e-4));
      expect(sim.screenShakeTimer, greaterThanOrEqualTo(0.30));
      expect(sim.bursts.any((b) => b.isTriangleShatter), isTrue);
    });
  });

  group('초기 무배치 직접 설치 · 점진 초소 확장(2→10) · 중앙 자동/수동 · 동료/영수 구출 · 30초 이상 지속 검증', () {
    test('실제 전투 시작 시 길목 발사대는 0개이며, 플레이어가 직접 배치·승급·교체·철거(80% 환급)한다', () {
      final p = PlayerProgress(tokens: 200);
      final stage = CampaignCatalog.stageAt(1, 1);
      final sim = DefenseBattleSim(
        stage: stage,
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 42,
      );

      expect(sim.launchers, isEmpty);
      expect(sim.activeMounts.length, 2);
      expect(sim.nextRecommendedSlotIndex(), 0);
      expect(CampaignCatalog.villageCenter.y, greaterThanOrEqualTo(600.0));
      expect(CampaignCatalog.centralTowerPos.y, greaterThanOrEqualTo(570.0));

      // 180프레임 진행해도 autoBuildForSimVerify == false 이면 빈 초소에 자동 설치되지 않음!
      for (int i = 0; i < 180; i++) {
        sim.step(1 / 60);
      }
      expect(sim.launchers, isEmpty);

      // 플레이어 직접 배치 → 승급 → 교체 → 철거 환급 검증
      sim.fieldTokens = 250;
      expect(sim.placeLauncherInBattle(0, LauncherType.rapid), isTrue);
      expect(sim.launchers.length, 1);
      expect(sim.nextRecommendedSlotIndex(), 1);
      expect(sim.placeLauncherInBattle(2, LauncherType.rapid), isFalse); // 1-1은 0,1번 2곳만 개방!

      expect(sim.upgradeLauncherAtSlot(0), isTrue);
      expect(sim.launcherAtSlot(0)!.tier, 2);

      expect(sim.replaceLauncherInBattle(0, LauncherType.heavy), isTrue);
      expect(sim.launcherAtSlot(0)!.type, LauncherType.heavy);

      final beforeTokens = sim.fieldTokens;
      final refunded = sim.dismantleLauncherInBattle(0);
      expect(refunded, greaterThan(0));
      expect(sim.fieldTokens, beforeTokens + refunded);
      expect(sim.launchers, isEmpty);
    });

    test('관문이 진행될수록 배치 가능한 초소 개수가 2곳(1-1)에서 최대 10곳(9~10장)까지 점진적으로 늘어난다', () {
      final s1 = CampaignCatalog.stageAt(1, 1);
      final s1End = CampaignCatalog.stageAt(1, 10);
      final s3 = CampaignCatalog.stageAt(3, 8);
      final s6 = CampaignCatalog.stageAt(6, 10);
      final s9 = CampaignCatalog.stageAt(9, 12);
      final s10 = CampaignCatalog.stageAt(10, 10);

      expect(s1.maxMountCount, 2);
      expect(s1End.maxMountCount, 4);
      expect(s3.maxMountCount, 6);
      expect(s6.maxMountCount, 8);
      expect(s9.maxMountCount, 10);
      expect(s10.maxMountCount, 10);

      for (final ch in CampaignCatalog.chapters) {
        expect(ch.mounts.length, greaterThanOrEqualTo(4));
        for (int l = 0; l < ch.lanes.length; l++) {
          final curve = ch.smoothedLane(l);
          expect(curve.length, greaterThan(40));
          expect(curve.first.y, lessThan(40.0));
          expect(curve.last.y, greaterThan(570.0));
        }
      }
    });

    test('중앙 기명 수호탑은 자동·수동 전환이 가능하며 수동 조준 탄지 및 도탄 예측선이 정상 작동한다', () {
      final p = PlayerProgress();
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        allowSerendipity: false,
      );

      expect(sim.centralManualMode, isFalse);
      sim.toggleCentralManualMode();
      expect(sim.centralManualMode, isTrue);

      // 수동 모드에서는 적이 있어도 자동 사격하지 않고 플레이어 조준을 대기함
      sim.centralFireTimer = 0.0;
      sim.mutants.add(
        ActiveMutant(
          uid: 501,
          kind: MutantKind.ironBoar,
          laneIndex: 0,
          waypoints: sim.chapter.smoothedLane(0),
          pos: const Vec2(200, 360),
          maxHp: 300,
          speed: 20,
        ),
      );
      sim.step(1 / 60);
      expect(sim.projectiles, isEmpty);

      // 도탄 궤적 예측선 및 수동 탄지 3갈래 파쇄 산탄 발사 검증
      final ray = sim.previewCentralManualRay(-1.15);
      expect(ray.length, greaterThanOrEqualTo(2));
      expect(sim.fireCentralManualAt(const Vec2(200, 320)), isTrue);
      expect(sim.projectiles.length, 3);
      expect(sim.muzzleFlashes, isNotEmpty);
      expect(sim.projectiles.first.pierceLeft, greaterThanOrEqualTo(3));
    });

    test('제1장~제9장에 걸쳐 동료 13인과 영수 4종이 지속 구출되어 전원(동료 14인·영수 5종) 합류한다', () {
      final p = PlayerProgress();
      expect(p.unlockedCompanionCount, 1); // 석두
      expect(p.unlockedBeastCount, 1); // 날쌘돌
      expect(p.nextRescueStage, isNotNull);
      expect(p.nextRescueStage!.code, '1-4');

      int rescueStageCount = 0;
      for (final st in CampaignCatalog.allStages) {
        if (st.hasRescueReward) rescueStageCount++;
        p.onBattleFinished(
          stage: st,
          victory: true,
          stars: 3,
          earnedTokens: 40,
          earnedElixirs: 2,
          usedSupportCount: 0,
        );
      }

      expect(rescueStageCount, 16);
      expect(p.unlockedCompanionCount, CompanionHero.values.length); // 14인 전원 합류!
      expect(p.unlockedBeastCount, SpiritBeast.values.length); // 5종 전원 합류!
      expect(p.activePreset.companions.length, 3); // 구출 동료 자동 슬롯 편성 확인!
    });

    test('변이체 6단계 시각 체급(19px~108px) 구분과 가장 쉬운 1-1 쉬움 판 32초 이상 지속을 보장한다', () {
      expect(MutantKind.swarmRat.visualDiameter, lessThan(22.0));
      expect(MutantKind.sickHound.visualDiameter, inInclusiveRange(25.0, 32.0));
      expect(MutantKind.ironBoar.visualDiameter, inInclusiveRange(52.0, 62.0));
      expect(MutantKind.swiftShadowBoss.visualDiameter, inInclusiveRange(58.0, 82.0));
      expect(MutantKind.chapterOverlord.visualDiameter, greaterThanOrEqualTo(100.0));

      final p = PlayerProgress(centralGuardianLevel: 3);
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.easy,
        progress: p,
        allowSupportTokens: false,
        allowSerendipity: false,
        autoBuildForSimVerify: true,
      );
      const dt = 1.0 / 30.0;
      for (int i = 0; i < 6000 && !sim.isFinished; i++) {
        sim.step(dt);
      }
      expect(sim.isFinished, isTrue);
      expect(sim.isVictory, isTrue);
      expect(sim.elapsedSec, greaterThanOrEqualTo(32.0));
    });

    test('1-1 쉬움 난이도라도 아무것도 배치하지 않고 방치하면 100% 패배(마을 함락)하며, 초소 배치 시 승리한다', () {
      final freshPlayer = PlayerProgress();
      final idleSim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 1),
        difficulty: DefenseDifficulty.easy,
        progress: freshPlayer,
        autoBuildForSimVerify: false,
      );
      const dt = 1.0 / 30.0;
      for (int i = 0; i < 6000 && !idleSim.isFinished; i++) {
        idleSim.step(dt);
      }
      expect(idleSim.isFinished, isTrue);
      expect(idleSim.isVictory, isFalse, reason: '무배치 방치 상태에서 1-1 쉬움이 자동 클리어되면 안 됨!');
      expect(idleSim.buildSummary().coachingTip, contains('군수 기력'));
    });

    test('초소 건설 조건(물결 봉인·기력 충전·운빨 소환 35⚡·합치기 진화·돌파 비급 3택1·핀볼 기물)이 정확히 작동한다', () {
      final p = PlayerProgress();
      final stage18 = CampaignCatalog.stageAt(1, 8); // 초소 4곳 개방 스테이지
      final sim = DefenseBattleSim(
        stage: stage18,
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 42,
      );

      // 초기 기력 48⚡: 0번 초소는 지정 건설 가능, 3번 초소(4번째 칸)는 2물결 잠금 상태!
      expect(sim.fieldTokens, 48);
      expect(sim.padConditionOf(0).state, PadConditionState.readyFullBuild);
      expect(sim.padConditionOf(3).state, PadConditionState.waveLocked);

      // 0번 초소에 35⚡ 운빨 무작위 소환 실행 → 남은 기력 13⚡ → 1번 초소는 기력 충전 중(13/35⚡)!
      final summoned = sim.summonLuckyLauncherInBattle(0);
      expect(summoned, isNotNull);
      expect(sim.fieldTokens, 13);
      expect(sim.padConditionOf(1).state, PadConditionState.chargingQi);

      // 기력 보충 후 같은 종류·같은 형 초소를 1번 칸에 강제 세팅해 0⚡ 합치기 진화 검증!
      sim.fieldTokens = 100;
      expect(sim.placeLauncherInBattle(1, LauncherType.rapid), isTrue);
      sim.launcherAtSlot(0)!
        ..type = LauncherType.rapid
        ..tier = 1;
      sim.launcherAtSlot(1)!
        ..type = LauncherType.rapid
        ..tier = 1;
      expect(sim.findMergePartnerSlot(0), 1);
      expect(sim.activeSynergyLinks, isNotEmpty);
      expect(sim.mergeLauncherAtSlot(0), isTrue);
      expect(sim.launcherAtSlot(0)!.tier, 2);
      expect(sim.launcherAtSlot(1), isNull); // 합쳐진 파트너 초소는 다시 빈 초소가 됨!

      // 물결 조기 호출 및 3택 1 돌파 비급 선택 검증!
      sim.elapsedSec = 5.0;
      sim.step(30.0); // 스폰 큐 소진 유도
      while (!sim.canCallNextWaveEarly && sim.elapsedSec < 25.0) {
        sim.step(0.5);
      }
      if (sim.canCallNextWaveEarly) {
        final beforeQi = sim.fieldTokens;
        expect(sim.callNextWaveEarly(), isTrue);
        expect(sim.fieldTokens, greaterThanOrEqualTo(beforeQi + 18));
        expect(sim.pendingPerkChoices.length, 3);
        final chosen = sim.pendingPerkChoices.first;
        expect(sim.chooseRoguePerk(chosen), isTrue);
        expect(sim.perkStacks(chosen), 1);
      }

      // ×2 쌍류 복제 마법진 통과 시 투사체가 2개로 복제되는지 검증!
      sim.projectiles.clear();
      sim.projectiles.add(
        ActiveStoneProjectile(
          sourceKey: 'test',
          sourceLabel: '시험탄',
          pos: sim.cloneGate.center,
          vel: const Vec2(0, -300),
          material: StoneMaterial.cheongok,
          shape: StoneShape.round,
          damage: 30,
          knockback: 40,
          critChance: 0.1,
          colorHex: 0xFF72EFDD,
        ),
      );
      sim.step(1 / 60);
      expect(sim.projectiles.length, 2);
      expect(sim.cloneSplitCount, greaterThanOrEqualTo(1));
    });

    test('초고속 다연발 탄막·포구 섬광·괴물 사망 랙돌 파편·타격 숫자 팝업·위기 심장박동 긴장감이 작동한다', () {
      final p = PlayerProgress();
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 2),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 77,
      );
      expect(LauncherType.rapid.projectilesPerShot(1), 2);
      expect(LauncherType.rapid.projectilesPerShot(4), 5);
      expect(LauncherType.rapid.baseCooldownSec, lessThan(0.45));

      expect(sim.placeLauncherInBattle(0, LauncherType.rapid), isTrue);
      sim.mutants.add(
        ActiveMutant(
          uid: 901,
          kind: MutantKind.swarmRat,
          laneIndex: 0,
          waypoints: sim.chapter.smoothedLane(0),
          pos: const Vec2(200, 480),
          maxHp: 5.0,
          speed: 20.0,
        ),
      );
      for (int f = 0; f < 35; f++) {
        sim.step(1 / 60);
      }
      expect(sim.dangerPulseLevel, greaterThan(0.0));
      expect(sim.killCount, greaterThanOrEqualTo(1));
      expect(sim.deathRagdolls, isNotEmpty);
      expect(sim.damagePopups, isNotEmpty);
    });

    test('무정지 실시간 돌파 비급 자동패스·전장 실시간 강화 3종·길 밖 침투 괴물·×3 각성문·화력 과녁·5형 신기·운명 돌림판이 작동한다', () {
      final p = PlayerProgress();
      final sim = DefenseBattleSim(
        stage: CampaignCatalog.stageAt(1, 8),
        difficulty: DefenseDifficulty.normal,
        progress: p,
        seed: 2026,
      );

      // 1) 실시간 돌파 비급 3택 1: 6.5초 동안 클릭하지 않아도 멈추지 않고 자동 스킵됨!
      sim.pendingPerkChoices
        ..clear()
        ..addAll([
          RoguePerk.rapidBarrage,
          RoguePerk.frostNova,
          RoguePerk.giantBoulder,
        ]);
      sim.perkChoiceTimer = DefenseBattleSim.perkWindowDurationSec;
      for (int i = 0; i < 220; i++) {
        sim.step(1 / 30); // 약 7.3초 실시간 경과
      }
      expect(sim.pendingPerkChoices, isEmpty, reason: '시간 내 미클릭 시 게임이 멈추지 않고 자동으로 넘어가야 함');

      // 2) 전장 실시간 군수 업그레이드 3종(화력·연사·결계) 작동 검증
      sim.fieldTokens = 300;
      sim.shieldHp = sim.shieldMaxHpDynamic * 0.4;
      expect(sim.upgradeLiveFirepower(), isTrue);
      expect(sim.liveFirepowerLv, 1);
      expect(sim.upgradeLiveReload(), isTrue);
      expect(sim.liveReloadLv, 1);
      final beforeMaxShield = sim.shieldMaxHpDynamic;
      expect(sim.upgradeLiveBarrier(), isTrue);
      expect(sim.liveBarrierLv, 1);
      expect(sim.shieldMaxHpDynamic, greaterThan(beforeMaxShield));

      // 3) 길이 아닌 숲·땅굴에서 침투하는 돌연변이(월담·땅굴 기습) 작동 검증
      final beforeCount = sim.mutants.length;
      final flanker = sim.spawnOffPathInfiltrator(isTunnel: false);
      final tunneler = sim.spawnOffPathInfiltrator(isTunnel: true);
      expect(sim.mutants.length, beforeCount + 2);
      expect(flanker.isInfiltrator, isTrue);
      expect(flanker.infiltratorStyle, 'flank');
      expect(tunneler.isInfiltrator, isTrue);
      expect(tunneler.infiltratorStyle, 'tunnel');
      final prevY = tunneler.pos.y;
      sim.step(0.5);
      expect(tunneler.pos.y, greaterThan(prevY));

      // 4) ×2 복제문 10회 통과 → 🔥×3 삼류 폭주 각성 & 이동형 화력 과녁(+10%~+60%) 검증
      sim.cloneGate.passCharge = 9;
      sim.projectiles
        ..clear()
        ..add(
          ActiveStoneProjectile(
            sourceKey: 'test_gate',
            sourceLabel: '각성시험탄',
            pos: sim.cloneGate.center,
            vel: const Vec2(0, -300),
            material: StoneMaterial.cheongok,
            shape: StoneShape.round,
            damage: 20,
            knockback: 30,
            critChance: 0.1,
            colorHex: 0xFF72EFDD,
          ),
        );
      sim.step(1 / 60);
      expect(sim.cloneGate.tripleOverdriveTimer, greaterThan(0.0));
      expect(sim.cloneGate.multiplier, 3);

      sim.powerTarget.powerStacks = 0;
      sim.projectiles
        ..clear()
        ..add(
          ActiveStoneProjectile(
            sourceKey: 'test_target',
            sourceLabel: '과녁시험탄',
            pos: sim.powerTarget.center,
            vel: const Vec2(0, -300),
            material: StoneMaterial.cheongok,
            shape: StoneShape.round,
            damage: 20,
            knockback: 30,
            critChance: 0.1,
            colorHex: 0xFF72EFDD,
          ),
        );
      sim.step(1 / 60);
      expect(sim.powerTarget.bonusPercent, 10);
      expect(sim.powerTarget.damageMultiplier, closeTo(1.10, 0.001));

      // 5) 4형 + 4형 합체 → ★5형 태초 신기 진화 & 🎰 운명의 돌림판 무꽝 당첨 검증
      sim.fieldTokens = 200;
      sim.launchers.clear();
      expect(sim.placeLauncherInBattle(0, LauncherType.rapid), isTrue);
      expect(sim.placeLauncherInBattle(1, LauncherType.rapid), isTrue);
      sim.launcherAtSlot(0)!.tier = 4;
      sim.launcherAtSlot(1)!.tier = 4;
      expect(sim.quickMergeAnyPair(), isTrue);
      expect(sim.launcherAtSlot(0)!.tier, 5);
      expect(LauncherType.rapid.projectilesPerShot(5), 7);

      sim.rouletteSpinsAvailable = 1;
      final prize = sim.spinDestinyRoulette();
      expect(prize, isNotNull);
      expect(sim.rouletteSpinsAvailable, 0);
    });
  });
}
