import 'dart:io';
import 'dart:isolate';

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
    while (preset.mountTypes.length < 14) {
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
    preset.mountTypes = List.filled(14, LauncherType.frostField);
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
  bool autoPrecision = true,
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
  )..autoPrecisionForVerify = autoPrecision;

  const dt = 1.0 / 30.0; // 헤드리스 고속 물리 스텝 (720×1360 12굽이 6~8물결 대장정 최대 420초)
  final maxSteps = (420.0 / dt).round();
  for (int i = 0; i < maxSteps && !sim.isFinished; i++) {
    sim.step(dt);
  }
  return (
    summary: sim.buildSummary(),
    elapsedSec: sim.elapsedSec,
    builtCount: sim.launchers.length,
  );
}

Future<void> main(List<String> args) async {
  final trialsPerStage = args.contains('--full200') ? 200 : 20;
  final buf = StringBuffer();
  buf.writeln('====================================================================');
  buf.writeln('《수호알까기 · 탄지무림 심야기습》 전 10현 · 100판(10장×10판) 10대 고유 지형 루트 · 거점개척 · 6~8물결 진검 검증 성적표');
  buf.writeln('조건: 720×1360 10장 고유 루트(2,860~7,250px) · 마기암석 개척 & 체증건설비 · 6~8물결 · 두목 2단 & 대수괴 3페이즈 · 지원패 0회 · 기연 0% · 단계당 $trialsPerStage판');
  buf.writeln('====================================================================');

  final chapterFutures = CampaignCatalog.chapters.map((chSpec) {
    final chNum = chSpec.number;
    return Isolate.run(() {
      final ch = CampaignCatalog.chapterOf(chNum);
      final tunedProgress = buildExpectedProgressForChapter(ch.number, tunedLoadout: true);
      final stages = CampaignCatalog.stagesOfChapter(ch.number);
      double chEasySum = 0;
      double chNormalSum = 0;
      double chNightmareSum = 0;
      double chDurationSum = 0;
      int chPassed = 0;
      final chFailed = <String>[];
      double chMinWinDur = 999999.0;
      String chMinWinCode = '';

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
            if (easyRun.elapsedSec < chMinWinDur) {
              chMinWinDur = easyRun.elapsedSec;
              chMinWinCode = '${st.code}(쉬움)';
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
            if (normalRun.elapsedSec < chMinWinDur) {
              chMinWinDur = normalRun.elapsedSec;
              chMinWinCode = '${st.code}(보통)';
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

        final durationOk = stMinElapsed >= 70.0;
        final ok = easyRate >= 80.0 && normalRate >= 60.0 && durationOk;
        if (ok) {
          chPassed++;
        } else {
          chFailed.add(
            '${st.code}(쉬움:${easyRate.toStringAsFixed(0)}%, 보통:${normalRate.toStringAsFixed(0)}%, 최단:${stMinElapsed.toStringAsFixed(1)}초)',
          );
        }
      }

      final n = stages.length;
      final padSpan = '${stages.first.maxMountCount}~${stages.last.maxMountCount}초소';
      final line =
          '제${ch.number.toString().padLeft(2)}장 [${ch.villageName}] ($n단계 · $padSpan · 평균 ${(chDurationSum / n).toStringAsFixed(1)}초) '
          '→ 승률 | 쉬움 ${(chEasySum / n).toStringAsFixed(1)}% · '
          '보통 ${(chNormalSum / n).toStringAsFixed(1)}% · '
          '악몽 ${(chNightmareSum / n).toStringAsFixed(1)}%';
      return (
        line: line,
        passed: chPassed,
        failed: chFailed,
        minDur: chMinWinDur,
        minCode: chMinWinCode,
      );
    });
  }).toList();

  final idleFuture = Isolate.run(() {
    int idleWins = 0;
    final idleStages = <String>[];
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
        idleWins++;
        idleStages.add(st.code);
      }
    }
    return (idleWins: idleWins, idleStages: idleStages);
  });

  final chapterResults = await Future.wait(chapterFutures);
  final idleResult = await idleFuture;

  int passedStages = 0;
  final failedCodes = <String>[];
  double minWinDurationSec = 999999.0;
  String minWinDurationCode = '';

  for (final r in chapterResults) {
    buf.writeln(r.line);
    passedStages += r.passed;
    failedCodes.addAll(r.failed);
    if (r.minDur < minWinDurationSec) {
      minWinDurationSec = r.minDur;
      minWinDurationCode = r.minCode;
    }
  }

  final idleAccidentalWins = idleResult.idleWins;
  final idleWinStages = idleResult.idleStages;

  // 2) 역상성/무배치 대조군 검증 (중반 5현 결전 5-10: 무배치 패배 vs 맞춤 초소 배치·비급 선택 승리 비교)
  final checkStage = CampaignCatalog.stageAt(5, 10);
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

  // 2-B) 초반 1-1(보통) 대충 플레이(포탑 1기만 세우고 추가 개척·승급 방치) 대조군 검증!
  int lazyOneTowerWins = 0;
  for (int t = 0; t < trialsPerStage; t++) {
    final lazySim = DefenseBattleSim(
      stage: CampaignCatalog.stageAt(1, 1),
      difficulty: DefenseDifficulty.normal,
      progress: PlayerProgress(),
      seed: 5500 + t,
      allowSupportTokens: false,
      allowSerendipity: false,
    )..autoPrecisionForVerify = false;
    lazySim.placeLauncherInBattle(0, LauncherType.rapid);
    const dt = 1.0 / 30.0;
    for (int i = 0; i < (420.0 / dt).round() && !lazySim.isFinished; i++) {
      lazySim.step(dt);
    }
    if (lazySim.isVictory) lazyOneTowerWins++;
  }
  final lazyOneTowerRate = lazyOneTowerWins / trialsPerStage * 100.0;

  buf.writeln('--------------------------------------------------------------------');
  buf.writeln(
    '무개입 방치 클리어 차단 검증(1-1 쉬움 포함 전 100판 초소 0개 방치 시): '
    '방치 승리 $idleAccidentalWins / ${CampaignCatalog.allStages.length}건 '
    '(${idleAccidentalWins == 0 ? "무개입 시 0.0% 전패 완벽 입증!" : "방치 클리어 발생: ${idleWinStages.join(", ")}"})',
  );
  buf.writeln(
    '초반 1-1(보통) 포탑 1기만 짓고 방치 시 승률(싱거운 프리패스 차단 검증): '
    '${lazyOneTowerRate.toStringAsFixed(1)}% (${lazyOneTowerRate <= 15.0 ? "대충 1기만 지으면 함락됨 입증!" : "난이도 추가 상향 필요"})',
  );
  buf.writeln(
    '최단 전투 지속시간(전 구간 70초 이상 진득한 6~8물결 호흡 검증): '
    '${minWinDurationSec.toStringAsFixed(1)}초 [$minWinDurationCode]',
  );
  buf.writeln(
    '직접 배치 & 돌파 비급 민감도 검증 (5-10 폭주 기관 거신): '
    '무배치·미성장 ${badRate.toStringAsFixed(1)}% → 맞춤 초소 배치 시 ${goodRate.toStringAsFixed(1)}% (승률 상승폭 +${delta.toStringAsFixed(1)}%p)',
  );
  buf.writeln(
    '전체 통과 스테이지: $passedStages / ${CampaignCatalog.allStages.length} '
    '(${failedCodes.isEmpty ? "전 단계 100% 통과!" : "미달: ${failedCodes.join(", ")}"})',
  );
  buf.writeln('====================================================================');

  final report = buf.toString();
  stdout.write(report);
  try {
    File('RESULTS_DEFENSE.txt').writeAsStringSync(report);
  } on FileSystemException {
    // 읽기 전용 샌드박스 실행 시 파일 기록 생략
  }

  if (failedCodes.isNotEmpty ||
      idleAccidentalWins > 0 ||
      lazyOneTowerRate > 15.0 ||
      delta < 35.0 ||
      minWinDurationSec < 70.0) {
    exitCode = 1;
  }
}
