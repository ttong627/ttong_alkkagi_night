import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'battle_screen.dart';

/// 수호 도감(세트 능력치 가산) · 확률 100% 공개 · 심야 무한 혈전 화면 모음.
class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final p = controller.progress;
          final bonusPct = (p.codexPowerBonus * 100).toStringAsFixed(1);

          return Scaffold(
            appBar: AppBar(
              title: const Text('수호 도감 · 세트 도감력'),
              actions: [
                TextButton.icon(
                  key: const Key('codex_open_odds_btn'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OddsScreen()),
                    );
                  },
                  icon: const NightSpriteIcon(
                    assetPath: NightArtRegistry.iconOdds,
                    fallbackIcon: Icons.fact_check_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    '확률 공개',
                    style: TextStyle(color: NightPalette.jadeGreen),
                  ),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: NightPalette.accentGold,
                labelColor: NightPalette.accentGold,
                unselectedLabelColor: NightPalette.textMuted,
                tabs: [
                  Tab(text: '수호석(13)'),
                  Tab(text: '발사대(5)'),
                  Tab(text: '영수(5)'),
                  Tab(text: '동료(14)'),
                  Tab(text: '변이체(12)'),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: NightPalette.bgPanel.withValues(alpha: 0.92),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const NightSpriteIcon(
                              assetPath: NightArtRegistry.iconCodex,
                              fallbackIcon: Icons.menu_book_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '도감 수집: ${p.codexCollectedCount} / ${p.codexTotalCount}종',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: NightPalette.accentGold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '✨ 영구 화력·방어막 도감 보너스: +$bonusPct% (최대 +12.0%)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: NightPalette.jadeGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStoneList(p),
                        _buildLauncherList(p),
                        _buildBeastList(p),
                        _buildCompanionList(p),
                        _buildMutantList(p),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoneList(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: StoneMaterial.values.map((s) {
        final owned = p.unlockedStones.contains(s);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MurimCard(
            borderColor: owned ? Color(s.colorHex) : NightPalette.borderGold,
            child: Row(
              children: [
                NightSpriteIcon(
                  assetPath: NightArtRegistry.stoneAsset(s),
                  fallbackIcon: Icons.circle_rounded,
                  size: 52,
                  dimmed: !owned,
                  showFrame: true,
                  frameColor: Color(s.colorHex),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.grade}단 ${s.name} ${owned ? "· 해금 완료" : "· 미해금"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: owned ? NightPalette.accentGold : NightPalette.textMuted,
                        ),
                      ),
                      Text(
                        s.specialDesc,
                        style: const TextStyle(fontSize: 12.5, color: NightPalette.textPrimary),
                      ),
                      Text(
                        '밀도 ${s.density.toStringAsFixed(2)} · 반발계수 ${s.restitution.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11.5, color: NightPalette.jadeShield),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLauncherList(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MurimCard(
            borderColor: NightPalette.jadeShield,
            child: Row(
              children: [
                const NightSpriteIcon(
                  assetPath: NightArtRegistry.towerGuardian,
                  fallbackIcon: Icons.account_balance_rounded,
                  size: 54,
                  showFrame: true,
                  frameColor: NightPalette.jadeShield,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '중앙 기명 수호탑 (현재 ${p.centralGuardianLevel}단)',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 16.5,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const Text(
                        '마을 3요소(식량·논밭·가축)의 심장부. 전방위로 회전 조준하며 변이 대군에 자동 응사합니다.',
                        style: TextStyle(fontSize: 12.5, color: NightPalette.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ...LauncherType.values.map((t) {
          final unlocked = t.unlockChapter <= p.highestUnlockedChapter + 1;
          final permLv = p.launcherPermanentLevels[t] ?? 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MurimCard(
              borderColor: Color(t.colorHex),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NightSpriteIcon(
                    assetPath: NightArtRegistry.launcherAsset(t),
                    fallbackIcon: Icons.gps_fixed_rounded,
                    size: 54,
                    dimmed: !unlocked,
                    showFrame: true,
                    frameColor: Color(t.colorHex),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${t.name} (영구 $permLv단)',
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 16.5,
                                color: Color(t.colorHex),
                              ),
                            ),
                            Text(
                              unlocked ? '운용 가능' : '제${t.unlockChapter}장 해금',
                              style: const TextStyle(fontSize: 12, color: NightPalette.jadeGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(t.roleSummary, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '전장 승급 계보: ${t.tierNames.join(" → ")}',
                          style: const TextStyle(fontSize: 12, color: NightPalette.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBeastList(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: SpiritBeast.values.map((b) {
        final lv = p.beastLevels[b] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MurimCard(
            borderColor: lv > 0 ? Color(b.colorHex) : NightPalette.borderGold,
            child: Row(
              children: [
                NightSpriteIcon(
                  assetPath: NightArtRegistry.beastAsset(b),
                  fallbackIcon: Icons.pets_rounded,
                  size: 54,
                  borderRadius: 12,
                  fit: BoxFit.cover,
                  dimmed: lv == 0,
                  showFrame: true,
                  frameColor: Color(b.colorHex),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b.name} ${lv > 0 ? "(영약 강화 $lv단)" : "(미영입 · 제${b.unlockChapter}장)"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: lv > 0 ? NightPalette.accentGold : NightPalette.textMuted,
                        ),
                      ),
                      Text(b.skillSummary, style: const TextStyle(fontSize: 12.5)),
                      Text(
                        '"${b.battleCry}"',
                        style: const TextStyle(fontSize: 11.5, color: NightPalette.jadeGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompanionList(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: CompanionHero.values.map((h) {
        final lv = p.companionLevels[h] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MurimCard(
            borderColor: lv > 0 ? NightPalette.accentGold : NightPalette.borderGold,
            child: Row(
              children: [
                NightSpriteIcon(
                  assetPath: NightArtRegistry.heroFaceAsset(h),
                  fallbackIcon: Icons.person_rounded,
                  size: 54,
                  borderRadius: 27,
                  fit: BoxFit.cover,
                  dimmed: lv == 0,
                  showFrame: true,
                  frameColor: NightPalette.accentGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${h.name} · ${h.title} ${lv > 0 ? "(동행 $lv단)" : "(미합류)"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: lv > 0 ? NightPalette.accentGold : NightPalette.textMuted,
                        ),
                      ),
                      Text(h.skillDesc, style: const TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatRatingBadge({
    required String label,
    required int rating,
    required Color activeColor,
  }) {
    final stars = List.generate(5, (i) => i < rating ? '★' : '☆').join();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: NightPalette.bgDeep.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: activeColor.withValues(alpha: 0.52)),
      ),
      child: Text(
        '$label $stars',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: activeColor,
        ),
      ),
    );
  }

  Widget _buildMutantList(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: MutantKind.values.map((m) {
        final seen = p.seenMutants.contains(m);
        final accent = Color(m.colorHex);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MurimCard(
            borderColor: seen ? accent : NightPalette.borderGold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기본 행군 원화 + 돌격·강타 원화 2종 나란히 전시
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.mutantAsset(m),
                              fallbackIcon: m.isBoss
                                  ? Icons.whatshot_rounded
                                  : Icons.pest_control_rounded,
                              size: 46,
                              dimmed: !seen,
                              showFrame: true,
                              frameColor: accent,
                            ),
                            const SizedBox(width: 4),
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.mutantAttackAsset(m),
                              fallbackAssetPath: NightArtRegistry.mutantAsset(m),
                              fallbackIcon: Icons.flash_on_rounded,
                              size: 46,
                              dimmed: !seen,
                              showFrame: true,
                              frameColor: NightPalette.accentGold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '행군 · 돌격 자세',
                          style: TextStyle(fontSize: 10, color: NightPalette.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 16,
                                  color: seen
                                      ? NightPalette.accentGold
                                      : NightPalette.textMuted,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: accent.withValues(alpha: 0.65)),
                                ),
                                child: Text(
                                  m.roleTag,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: NightPalette.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '전투력 ${m.combatPower}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: NightPalette.jadeGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '체력 ${m.baseHp.round()} · 속도 ${m.speed.round()} · 공격력 ${m.attackPower.round()} · 처치 증표 +${m.dropTokens} ${seen ? "(조우 완료)" : "(미조우)"}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: NightPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildStatRatingBadge(
                                label: '스피드',
                                rating: m.speedRating,
                                activeColor: const Color(0xFFE0AAFF),
                              ),
                              _buildStatRatingBadge(
                                label: '맷집',
                                rating: m.toughnessRating,
                                activeColor: NightPalette.jadeShield,
                              ),
                              _buildStatRatingBadge(
                                label: '공격력',
                                rating: m.attackRating,
                                activeColor: const Color(0xFFFF6B6B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  m.traitDesc,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.38,
                    color: NightPalette.jadeShield,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 게임 내 확률 및 물리 수치 100% 투명 공개 화면.
class OddsScreen extends StatelessWidget {
  const OddsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('확률 및 물리 수치 100% 공개')),
      body: NightSceneBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MurimCard(
              borderColor: NightPalette.jadeGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NightSpriteIcon(
                        assetPath: NightArtRegistry.iconOdds,
                        fallbackIcon: Icons.fact_check_rounded,
                        size: 40,
                        showFrame: true,
                        frameColor: NightPalette.jadeGreen,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '🛡️ 유료 무작위 상자 0건 · 결제 0건 · 광고 0건',
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 18,
                            color: NightPalette.jadeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '《수호알까기 · 탄지무림 심야기습》에는 유료 확률형 아이템이 전혀 존재하지 않습니다. '
                    '전장의 즐거움을 더하는 절벽 뽀록, 어부지리 도탄, 설렘 기연의 실제 작동 수치를 코드 그대로 투명하게 공개합니다.',
                    style: TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...OddsDisclosureRow.all.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            '[${row.category}] ${row.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: NightPalette.accentGold,
                            ),
                          ),
                          Text(
                            row.rateText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: NightPalette.jadeGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.detail,
                        style: const TextStyle(fontSize: 13, color: NightPalette.textPrimary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 심야 무한 혈전(생존 투기장) 출정 준비 화면.
class EndlessSurvivalScreen extends StatefulWidget {
  const EndlessSurvivalScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<EndlessSurvivalScreen> createState() => _EndlessSurvivalScreenState();
}

class _EndlessSurvivalScreenState extends State<EndlessSurvivalScreen> {
  int _selectedWaves = 10;
  int _selectedThemeChapter = 1;

  @override
  void initState() {
    super.initState();
    _selectedThemeChapter = widget.controller.progress.highestUnlockedChapter;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = widget.controller.progress;
        final maxCh = p.highestUnlockedChapter.clamp(1, 10);
        final selectedChapter = CampaignCatalog.chapterOf(_selectedThemeChapter.clamp(1, maxCh));

        return Scaffold(
          appBar: AppBar(title: const Text('심야 무한 혈전 · 한계 시험장')),
          body: NightSceneBackdrop(
            assetPath: selectedChapter.bgAsset,
            fallbackAssetPath: NightArtRegistry.bgNightLobby,
            overlayOpacity: 0.84,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MurimCard(
                  borderColor: NightPalette.crimsonMoon,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NightSpriteIcon(
                            assetPath: NightArtRegistry.nightEndless,
                            fallbackAssetPath: 'assets/images/icons/arena.webp',
                            fallbackIcon: Icons.local_fire_department_rounded,
                            size: 56,
                            showFrame: true,
                            frameColor: NightPalette.crimsonMoon,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '끝없는 심야 변이 대군을 막아라!',
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 20,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                                Text(
                                  '최고 돌파 기록: ${p.bestEndlessWave}물결 · 누적 토벌: ${p.totalMutantKills}마리',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: NightPalette.jadeGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '3물결마다 스피드·맷집·공격력 특화 중간보스가 변이 무리와 동반 침략하며, 5물결마다 대수괴가 난입합니다! '
                        '내가 조합한 자동 발사 진법과 전술 비약의 한계를 시험하고 대량의 증표·영약을 획득하세요!',
                        style: TextStyle(fontSize: 13.5, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. 도전 목표 물결 선택',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [10, 20, 30].map((w) {
                          return ChoiceChip(
                            selected: _selectedWaves == w,
                            label: Text('$w물결 연속 수호'),
                            onSelected: (_) => setState(() => _selectedWaves = w),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '2. 전장 지형 선택 (해금된 장 기준)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _selectedThemeChapter.clamp(1, maxCh),
                        items: List.generate(maxCh, (idx) {
                          final ch = CampaignCatalog.chapterOf(idx + 1);
                          return DropdownMenuItem<int>(
                            value: ch.number,
                            child: Text(
                              '제${ch.number}장 · ${ch.villageName} (${ch.title})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedThemeChapter = v);
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('start_endless_battle_btn'),
                          style: FilledButton.styleFrom(
                            backgroundColor: NightPalette.accentGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final stage = EndlessWaveBuilder.buildEndlessStage(
                              waveCount: _selectedWaves,
                              chapterTheme: _selectedThemeChapter,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BattleScreen(
                                  controller: widget.controller,
                                  stage: stage,
                                ),
                              ),
                            );
                          },
                          icon: const NightSpriteIcon(
                            assetPath: NightArtRegistry.nightEndless,
                            fallbackIcon: Icons.bolt_rounded,
                            size: 20,
                          ),
                          label: Text('심야 무한 혈전 ($_selectedWaves물결) 출정!'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
