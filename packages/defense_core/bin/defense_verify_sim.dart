import 'dart:io';

import 'package:defense_core/defense_core.dart';

/// 해당 장(1~10장)까지 정상 플레이하며 증표·영약·쉬운 수련으로 성장한 표준 수호자 프로필 생성.
PlayerProgress buildExpectedProgressForChapter(int chapterNumber, {required bool tunedLoadout}) {
  final ch = chapterNumber;
  final p = PlayerProgress(
    tokens: 500,
    elixirs: 50,
    trainingSeals: 200,
    naegongPoints: (ch - 1) * 280 + 40,
    realmIndex: ((ch - 1) * 0.78).floor().clamp(0, 7),
    centralGuardianLevel: 1 + (ch - 1) * 2,
    supportTokens: 3,
    highestClearedGlobalStage: CampaignCatalog.stagesOfChapter(ch).first.globalIndex - 1,
    openedMeridianStep: (ch - 1).clamp(0, 10),
  );

  for (final lt in LauncherType.values) {
    p.launcherPermanentLevels[lt] = 1 + ((ch - 1) * 1.45).round();
  }
  for (final cs in CoreStatType.values) {
    p.coreStatLevels[cs] = (ch - 1);
  }

  final stoneIdx = (ch - 1).clamp(0, 9);
  final chosenStone = StoneMaterial.values[stoneIdx];
  p.unlockedStones.add(chosenStone);

  final beast = ch >= 8
      ? SpiritBeast.geumryong
      : ch >= 6
          ? SpiritBeast.baekho
          : ch >= 4
              ? SpiritBeast.cheonghak
              : ch >= 3
                  ? SpiritBeast.geumgangTurtle
                  : SpiritBeast.nalssaendol;
  p.beastLevels[beast] = (1 + (ch * 0.85).round()).clamp(1, 10);

  final chapterSpec = CampaignCatalog.chapterOf(ch);
  final preset = p.activePreset;

  if (tunedLoadout) {
    preset.primaryStone = chosenStone;
    preset.primaryShape = ch >= 4 ? StoneShape.sphere : StoneShape.round;
    preset.sectTechnique = ch % 2 == 0 ? SectTechnique.ironFist : SectTechnique.swordQi;
    preset.mountTypes = chapterSpec.mounts.map((m) => m.recommendedType).toList();
    while (preset.mountTypes.length < 5) {
      preset.mountTypes.add(LauncherType.rapid);
    }
    preset.equippedBeast = beast;
    preset.beastCondition = beast.defaultCondition;
    preset.companions = ch >= 6
        ? [CompanionHero.yonga, CompanionHero.jeonggak, CompanionHero.seolhwa]
        : ch >= 4
            ? [CompanionHero.gurumi, CompanionHero.bandal, CompanionHero.seokdu]
            : [CompanionHero.seokdu, CompanionHero.yeonbi, CompanionHero.cheongmyeong];
    for (final h in preset.companions) {
      p.companionLevels[h] = (1 + (ch * 0.85).round()).clamp(1, 10);
    }
    if (ch >= 6) {
      p.companionLevels[CompanionHero.mukhyeon] = (ch - 4).clamp(1, 10);
    }
    preset.autoUpgradeInBattle = true;
  } else {
    // 역상성·미성장 부실 구성(검증 대조군: 1단 청옥 + 미강화 단발만 도배 + 자동 승급 끔)
    p.centralGuardianLevel = 1;
    p.realmIndex = 0;
    p.openedMeridianStep = 0;
    for (final lt in LauncherType.values) {
      p.launcherPermanentLevels[lt] = 1;
    }
    for (final cs in CoreStatType.values) {
      p.coreStatLevels[cs] = 0;
    }
    preset.primaryStone = StoneMaterial.cheongok;
    preset.mountTypes = List.filled(5, LauncherType.frostField);
    preset.companions = [CompanionHero.seokdu];
    p.companionLevels[CompanionHero.seokdu] = 1;
    preset.autoUpgradeInBattle = false;
  }

  return p;
}

BattleSummary runSingleHeadlessSim({
  required StageSpec stage,
  required DefenseDifficulty difficulty,
  required PlayerProgress progress,
  required int seed,
}) {
  final sim = DefenseBattleSim(
    stage: stage,
    difficulty: difficulty,
    progress: progress,
    seed: seed,
    // 검증 절대 원칙: 지원패 0회 · 행운 기연 0% 순수 구성만으로 클리어 검증!
    allowSupportTokens: false,
    allowSerendipity: false,
  );

  const dt = 1.0 / 30.0; // 헤드리스 고속 물리 스텝 (최대 180초 전장)
  int maxSteps = (180.0 / dt).round();
  for (int i = 0; i < maxSteps && !sim.isFinished; i++) {
    sim.step(dt);
  }
  return sim.buildSummary();
}

void main(List<String> args) {
  final trialsPerStage = args.contains('--full200') ? 200 : 30;
  final buf = StringBuffer();
  buf.writeln('====================================================================');
  buf.writeln('《수호알까기 · 탄지무림 심야기습》 전 10장(111단계) 순수 자동 구성 검증 성적표');
  buf.writeln('조건: 손 조작 0회 · 지원패 0회 · 행운 기연 0% · 단계당 모의실험 $trialsPerStage판');
  buf.writeln('====================================================================');

  int passedStages = 0;
  final failedCodes = <String>[];

  for (final ch in CampaignCatalog.chapters) {
    final tunedProgress = buildExpectedProgressForChapter(ch.number, tunedLoadout: true);
    final stages = CampaignCatalog.stagesOfChapter(ch.number);
    double chEasySum = 0;
    double chNormalSum = 0;
    double chNightmareSum = 0;

    for (final st in stages) {
      int easyWins = 0;
      int normalWins = 0;
      int nightmareWins = 0;

      for (int t = 0; t < trialsPerStage; t++) {
        final seedBase = st.globalIndex * 1000 + t * 17 + 7;
        if (runSingleHeadlessSim(
          stage: st,
          difficulty: DefenseDifficulty.easy,
          progress: tunedProgress,
          seed: seedBase,
        ).victory) {
          easyWins++;
        }
        if (runSingleHeadlessSim(
          stage: st,
          difficulty: DefenseDifficulty.normal,
          progress: tunedProgress,
          seed: seedBase + 3,
        ).victory) {
          normalWins++;
        }
        if (runSingleHeadlessSim(
          stage: st,
          difficulty: DefenseDifficulty.nightmare,
          progress: tunedProgress,
          seed: seedBase + 9,
        ).victory) {
          nightmareWins++;
        }
      }

      final easyRate = easyWins / trialsPerStage * 100.0;
      final normalRate = normalWins / trialsPerStage * 100.0;
      final nightmareRate = nightmareWins / trialsPerStage * 100.0;
      chEasySum += easyRate;
      chNormalSum += normalRate;
      chNightmareSum += nightmareRate;

      final ok = easyRate >= 85.0 && normalRate >= 65.0;
      if (ok) {
        passedStages++;
      } else {
        failedCodes.add(
          '${st.code}(쉬움:${easyRate.toStringAsFixed(0)}%, 보통:${normalRate.toStringAsFixed(0)}%, 악몽:${nightmareRate.toStringAsFixed(0)}%)',
        );
      }
    }

    final n = stages.length;
    buf.writeln(
      '제${ch.number.toString().padLeft(2)}장 [${ch.villageName}] ($n단계) '
      '→ 평균 승률 | 쉬움 ${(chEasySum / n).toStringAsFixed(1)}% · '
      '보통 ${(chNormalSum / n).toStringAsFixed(1)}% · '
      '악몽 ${(chNightmareSum / n).toStringAsFixed(1)}%',
    );
  }

  // 역상성/무성장 대조군 검증 (중반 5장 보스전: 부실 구성 패배 vs 추천 구성 승리 차이 검증)
  final checkStage = CampaignCatalog.stageAt(5, 11);
  final badProg = buildExpectedProgressForChapter(5, tunedLoadout: false);
  final goodProg = buildExpectedProgressForChapter(5, tunedLoadout: true);
  int badWins = 0;
  int goodWins = 0;
  for (int t = 0; t < trialsPerStage; t++) {
    if (runSingleHeadlessSim(
      stage: checkStage,
      difficulty: DefenseDifficulty.normal,
      progress: badProg,
      seed: 9000 + t,
    ).victory) {
      badWins++;
    }
    if (runSingleHeadlessSim(
      stage: checkStage,
      difficulty: DefenseDifficulty.normal,
      progress: goodProg,
      seed: 9000 + t,
    ).victory) {
      goodWins++;
    }
  }
  final badRate = badWins / trialsPerStage * 100.0;
  final goodRate = goodWins / trialsPerStage * 100.0;
  final delta = goodRate - badRate;

  buf.writeln('--------------------------------------------------------------------');
  buf.writeln(
    '구성 조정 민감도 검증 (5-11 폭주 기관 거신): '
    '부실 역상성 구성 ${badRate.toStringAsFixed(1)}% → 맞춤 구성 조정 시 ${goodRate.toStringAsFixed(1)}% (승률 상승폭 +${delta.toStringAsFixed(1)}%p)',
  );
  buf.writeln(
    '전체 통과 스테이지: $passedStages / ${CampaignCatalog.allStages.length} '
    '(${failedCodes.isEmpty ? "전 단계 100% 통과!" : "미달: ${failedCodes.join(", ")}"})',
  );
  buf.writeln('====================================================================');

  final report = buf.toString();
  stdout.write(report);
  File('RESULTS_DEFENSE.txt').writeAsStringSync(report);

  if (failedCodes.isNotEmpty || delta < 35.0) {
    exitCode = 1;
  }
}
