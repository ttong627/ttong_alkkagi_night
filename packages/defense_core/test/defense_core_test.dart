import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:test/test.dart';

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
}
