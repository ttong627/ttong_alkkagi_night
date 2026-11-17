import 'dart:io';

import 'package:defense_core/defense_core.dart';

/// 해당 장(1~10장)까지 정상 플레이하며 증표·영약·쉬운 수련으로 성장한 표준 수호자 프로필 생성.
PlayerProgress buildExpectedProgressForChapter(int chapterNumber, {required bool tunedLoadout}) {
  final ch = chapterNumber;
  final p = PlayerProgress(
    tokens: 500,
    elixirs: 50,
    trainingSeals: 200,
    naegongPoints: (ch - 1) * 320 + 60,
    realmIndex: ((ch - 1) * 0.85).round().clamp(0, 7),
    centralGuardianLevel: 1 + ((ch - 1) * 2.2).round(),
    supportTokens: 3,
    highestClearedGlobalStage: CampaignCatalog.stagesOfChapter(ch).first.globalIndex - 1,
    openedMeridianStep: ((ch - 1) * 1.12).round().clamp(0, 10),
  );

  for (final lt in LauncherType.values) {
    p.launcherPermanentLevels[lt] = 1 + ((ch - 1) * 1.85).round();
  }
  for (final cs in CoreStatType.values) {
    p.coreStatLevels[cs] = ((ch - 1) * 1.15).round();
  }

  final stoneIdx = ch >= 10
      ? 12
      : (ch == 9 ? 11 : (ch == 8 ? 10 : (ch - 1).clamp(0, 7)));
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
    while (preset.mountTypes.length < 10) {
      preset.mountTypes.add(LauncherType.rapid);
    }
    preset.equippedBeast = beast;
    preset.beastCondition = beast.defaultCondition;
    preset.companions = ch >= 8
        ? [CompanionHero.geomhwang, CompanionHero.yonga, CompanionHero.jeonggak]
        : ch >= 6
            ? [CompanionHero.yonga, CompanionHero.jeonggak, CompanionHero.seolhwa]
            : ch >= 3
                ? [CompanionHero.chwiseon, CompanionHero.bandal, CompanionHero.seokdu]
                : ch >= 2
                    ? [CompanionHero.seokdu, CompanionHero.yeonbi, CompanionHero.cheongmyeong]
                    : [CompanionHero.seokdu];
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
    preset.mountTypes = List.filled(10, LauncherType.frostField);
    preset.companions = [CompanionHero.seokdu];
    p.companionLevels[CompanionHero.seokdu] = 1;
    preset.autoUpgradeInBattle = false;
  }

  return p;
}

({BattleSummary summary, double elapsedSec, int builtCount}) runSingleHeadlessSim({
  required StageSpec stage,
  required DefenseDifficulty difficulty,
  required PlayerProgress progress,
  required int seed,
  bool autoBuildPads = true,
}) {
  final sim = DefenseBattleSim(
    stage: stage,
    difficulty: difficulty,
    progress: progress,
    seed: seed,
    // 검증 절대 원칙: 지원패 0회 · 행운 기연 0% 순수 구성만으로 클리어 검증!
    allowSupportTokens: false,
    allowSerendipity: false,
    autoBuildForSimVerify: autoBuildPads,
  );

  const dt = 1.0 / 30.0; // 헤드리스 고속 물리 스텝 (최대 240초 전장)
  final maxSteps = (240.0 / dt).round();
  for (int i = 0; i < maxSteps && !sim.isFinished; i++) {
    sim.step(dt);
  }
  return (
    summary: sim.buildSummary(),
    elapsedSec: sim.elapsedSec,
    builtCount: sim.launchers.length,
  );
}

void main(List<String> args) {
  final trialsPerStage = args.contains('--full200') ? 200 : 30;
  final buf = StringBuffer();
  buf.writeln('====================================================================');
  buf.writeln('《수호알까기 · 탄지무림 심야기습》 전 10장(111단계) 순차 배치·지속시간·밸런스 검증 성적표');
  buf.writeln('조건: 초기 길목 무배치(0기) → 빈 초소(2~10곳) 순차 건설 · 지원패 0회 · 기연 0% · 단계당 $trialsPerStage판');
  buf.writeln('====================================================================');

  int passedStages = 0;
  final failedCodes = <String>[];
  double minWinDurationSec = 999999.0;
  String minWinDurationCode = '';

  for (final ch in CampaignCatalog.chapters) {
    final tunedProgress = buildExpectedProgressForChapter(ch.number, tunedLoadout: true);
    final stages = CampaignCatalog.stagesOfChapter(ch.number);
    double chEasySum = 0;
    double chNormalSum = 0;
    double chNightmareSum = 0;
    double chDurationSum = 0;

    for (final st in stages) {
      if (ch.number == 1 && st.stageNumber >= 5) {
        tunedProgress.companionLevels[CompanionHero.yeonbi] = 2;
        if (!tunedProgress.activePreset.companions.contains(CompanionHero.yeonbi)) {
          tunedProgress.activePreset.companions.add(CompanionHero.yeonbi);
        }
      }
      if (ch.number == 1 && st.stageNumber >= 9) {
        tunedProgress.companionLevels[CompanionHero.cheongmyeong] = 2;
        if (!tunedProgress.activePreset.companions.contains(CompanionHero.cheongmyeong)) {
          tunedProgress.activePreset.companions.add(CompanionHero.cheongmyeong);
        }
        for (final lt in LauncherType.values) {
          tunedProgress.launcherPermanentLevels[lt] = 2;
        }
      }

      int easyWins = 0;
      int normalWins = 0;
      int nightmareWins = 0;
      double stMinElapsed = 999999.0;
      double stAvgElapsed = 0.0;

      for (int t = 0; t < trialsPerStage; t++) {
        final seedBase = st.globalIndex * 1000 + t * 17 + 7;
        final easyRun = runSingleHeadlessSim(
          stage: st,
          difficulty: DefenseDifficulty.easy,
          progress: tunedProgress,
          seed: seedBase,
        );
        if (easyRun.summary.victory) {
          easyWins++;
          if (easyRun.elapsedSec < stMinElapsed) stMinElapsed = easyRun.elapsedSec;
          if (easyRun.elapsedSec < minWinDurationSec) {
            minWinDurationSec = easyRun.elapsedSec;
            minWinDurationCode = '${st.code}(쉬움)';
          }
        }
        final normalRun = runSingleHeadlessSim(
          stage: st,
          difficulty: DefenseDifficulty.normal,
          progress: tunedProgress,
          seed: seedBase + 3,
        );
        stAvgElapsed += normalRun.elapsedSec;
        if (normalRun.summary.victory) {
          normalWins++;
          if (normalRun.elapsedSec < stMinElapsed) stMinElapsed = normalRun.elapsedSec;
          if (normalRun.elapsedSec < minWinDurationSec) {
            minWinDurationSec = normalRun.elapsedSec;
            minWinDurationCode = '${st.code}(보통)';
          }
        }
        final nightmareRun = runSingleHeadlessSim(
          stage: st,
          difficulty: DefenseDifficulty.nightmare,
          progress: tunedProgress,
          seed: seedBase + 9,
        );
        if (nightmareRun.summary.victory) {
          nightmareWins++;
        }
      }

      final easyRate = easyWins / trialsPerStage * 100.0;
      final normalRate = normalWins / trialsPerStage * 100.0;
      final nightmareRate = nightmareWins / trialsPerStage * 100.0;
      chEasySum += easyRate;
      chNormalSum += normalRate;
      chNightmareSum += nightmareRate;
      chDurationSum += stAvgElapsed / trialsPerStage;

      final durationOk = stMinElapsed >= 32.0;
      final ok = easyRate >= 85.0 && normalRate >= 65.0 && durationOk;
      if (ok) {
        passedStages++;
      } else {
        failedCodes.add(
          '${st.code}(쉬움:${easyRate.toStringAsFixed(0)}%, 보통:${normalRate.toStringAsFixed(0)}%, 최단:${stMinElapsed.toStringAsFixed(1)}초)',
        );
      }
    }

    final n = stages.length;
    final padSpan = '${stages.first.maxMountCount}~${stages.last.maxMountCount}초소';
    buf.writeln(
      '제${ch.number.toString().padLeft(2)}장 [${ch.villageName}] ($n단계 · $padSpan · 평균 ${(chDurationSum / n).toStringAsFixed(1)}초) '
      '→ 승률 | 쉬움 ${(chEasySum / n).toStringAsFixed(1)}% · '
      '보통 ${(chNormalSum / n).toStringAsFixed(1)}% · '
      '악몽 ${(chNightmareSum / n).toStringAsFixed(1)}%',
    );
  }

  // 1) 무개입 방치(초소 0개 배치 · 수동 조작 0회) 전 구간 100% 패배(마을 함락) 하드게이트 검증!
  // 가장 쉬운 1-1(쉬움)을 포함해 전 111단계에서 아무것도 안 하고 가만히 두면 단 1판도 깨져서는 안 된다!
  int idleAccidentalWins = 0;
  final idleWinStages = <String>[];
  for (final st in CampaignCatalog.allStages) {
    final prog = buildExpectedProgressForChapter(st.chapterNumber, tunedLoadout: true);
    final easyIdle = runSingleHeadlessSim(
      stage: st,
      difficulty: DefenseDifficulty.easy,
      progress: prog,
      seed: 7000 + st.globalIndex,
      autoBuildPads: false,
    );
    final normalIdle = runSingleHeadlessSim(
      stage: st,
      difficulty: DefenseDifficulty.normal,
      progress: prog,
      seed: 8000 + st.globalIndex,
      autoBuildPads: false,
    );
    if (easyIdle.summary.victory || normalIdle.summary.victory) {
      idleAccidentalWins++;
      idleWinStages.add(st.code);
    }
  }

  // 2) 역상성/무배치 대조군 검증 (중반 5장 보스전: 무배치 패배 vs 맞춤 초소 배치·비급 선택 승리 비교)
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
      autoBuildPads: false,
    ).summary.victory) {
      badWins++;
    }
    if (runSingleHeadlessSim(
      stage: checkStage,
      difficulty: DefenseDifficulty.normal,
      progress: goodProg,
      seed: 9000 + t,
    ).summary.victory) {
      goodWins++;
    }
  }
  final badRate = badWins / trialsPerStage * 100.0;
  final goodRate = goodWins / trialsPerStage * 100.0;
  final delta = goodRate - badRate;

  buf.writeln('--------------------------------------------------------------------');
  buf.writeln(
    '무개입 방치 클리어 차단 검증(1-1 쉬움 포함 전 111단계 초소 0개 방치 시): '
    '방치 승리 $idleAccidentalWins / ${CampaignCatalog.allStages.length}건 '
    '(${idleAccidentalWins == 0 ? "무개입 시 0.0% 전패 완벽 입증!" : "방치 클리어 발생: ${idleWinStages.join(", ")}"})',
  );
  buf.writeln(
    '최단 전투 지속시간(쉬운 1-1 포함 전 구간 30초 이상 보장 검증): '
    '${minWinDurationSec.toStringAsFixed(1)}초 [$minWinDurationCode]',
  );
  buf.writeln(
    '직접 배치 & 돌파 비급 민감도 검증 (5-11 폭주 기관 거신): '
    '무배치·미성장 ${badRate.toStringAsFixed(1)}% → 맞춤 초소 배치 시 ${goodRate.toStringAsFixed(1)}% (승률 상승폭 +${delta.toStringAsFixed(1)}%p)',
  );
  buf.writeln(
    '전체 통과 스테이지: $passedStages / ${CampaignCatalog.allStages.length} '
    '(${failedCodes.isEmpty ? "전 단계 100% 통과!" : "미달: ${failedCodes.join(", ")}"})',
  );
  buf.writeln('====================================================================');

  final report = buf.toString();
  stdout.write(report);
  File('RESULTS_DEFENSE.txt').writeAsStringSync(report);

  if (failedCodes.isNotEmpty || idleAccidentalWins > 0 || delta < 35.0 || minWinDurationSec < 32.0) {
    exitCode = 1;
  }
}
