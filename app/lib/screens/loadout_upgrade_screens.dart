import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart' hide Text;

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'stage_and_county_transitions.dart';
import '../i18n/tr_text.dart';
import '../i18n/l10n.dart';

typedef ForgeSanctuaryScreen = UpgradeScreen;

/// 영웅 · 자동 수호 진법 편성실
/// - 영웅단 전신 공격 일러스트 대 3페이즈 돌연변이 쇼케이스 무대
/// - 원터치 최적 진법 자동 편성 + 3슬롯 프리셋 + 발사대별 상성 변이체 직관 안내.
class LoadoutScreen extends StatelessWidget {
  const LoadoutScreen({
    super.key,
    required this.controller,
    this.embeddedInShell = false,
    this.onSwitchShellTab,
  });

  final GameController controller;
  final bool embeddedInShell;
  final ValueChanged<int>? onSwitchShellTab;

  static InputDecoration _darkFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: tr(labelText),
      labelStyle: const TextStyle(fontSize: 12.8, color: NightPalette.textMuted),
      filled: true,
      fillColor: NightPalette.bgDeep.withValues(alpha: 0.84),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: NightPalette.borderGold.withValues(alpha: 0.30),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NightPalette.accentGold, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        final preset = p.activePreset;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: !embeddedInShell,
              title: const Text('자동 수호 진법 편성실'),
              bottom: TabBar(
                indicatorColor: NightPalette.accentGold,
                labelColor: NightPalette.accentGold,
                unselectedLabelColor: NightPalette.textMuted,
                tabs: [
                  Tab(text: tr('☯️ 수호 알 · 내공 · 거점 발사대')),
                  Tab(text: tr('🐾 영수 · 동료 · 출두 조건')),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: Column(
                children: [
                  QuickPlayAndMenuBar(
                    controller: controller,
                    currentSection: 'loadout',
                    embeddedInShell: embeddedInShell,
                    onSwitchShellTab: onSwitchShellTab,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCoreArsenalTab(context, p, preset),
                        _buildCompanionTacticsTab(context, p, preset),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoreArsenalTab(
    BuildContext context,
    PlayerProgress p,
    LoadoutPreset preset,
  ) {
    final leadHero = preset.companions.isNotEmpty
        ? preset.companions.first
        : CompanionHero.seokdu;
    final nextIdx = (p.highestClearedGlobalStage + 1)
        .clamp(1, CampaignCatalog.allStages.length);
    final nextStage = CampaignCatalog.allStages[nextIdx - 1];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        // 1) 상단 제1주인공: 영웅단 실전 집결 원화 + 원터치 최적 진법 편성 + 3슬롯 프리셋
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: HeroVsMutantShowcaseBanner(
              sceneAsset: NightArtRegistry.homeCommandLoop,
              badgeText:
                  '현재 편성: ${preset.name} · 출전 동료 ${preset.companions.length}/3인',
              title:
                  '${preset.primaryStone.grade}단 ${preset.primaryStone.name} · ${preset.sectTechnique.skillName}',
              subtitle:
                  '${preset.primaryShape.name} · 동행 영수 [${preset.equippedBeast.name}] · 목표 관문 ${nextStage.code}',
              leftHeroAsset: NightArtRegistry.heroMotionAsset(leadHero),
              leftHeroLabel: '${leadHero.name} 3D모션',
              rightMutantAsset:
                  NightArtRegistry.mutantMotionAsset(MutantKind.chapterOverlord),
              rightMutantLabel: '3페이즈 진화',
              artHeight: 176,
              actionRow: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: List.generate(p.presets.length, (i) {
                      final sel = p.activePresetIndex == i;
                      return ChoiceChip(
                        selected: sel,
                        backgroundColor: const Color(0xFFE4D5B4),
                        selectedColor: NightPalette.hanjiInk,
                        checkmarkColor: NightPalette.accentGold,
                        side: BorderSide(
                          color: sel
                              ? NightPalette.hanjiInk
                              : const Color(0xFFB5A178),
                        ),
                        labelStyle: TextStyle(
                          color: sel
                              ? NightPalette.accentGold
                              : NightPalette.hanjiInk,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.8,
                        ),
                        label: Text(p.presets[i].name),
                        onSelected: (_) => controller.selectPreset(i),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      key: const Key('loadout_auto_recommend_btn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: NightPalette.hanjiInk,
                        foregroundColor: NightPalette.accentGold,
                      ),
                      onPressed: () {
                        final st = controller.applyRecommendedForNextStage();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: NightPalette.bgCard,
                            content: Text(
                              '${st.code} 관문 맞춤 최강 수호석·영웅·영수·초소 진법을 자동 편성했습니다.',
                              style: const TextStyle(
                                color: NightPalette.accentGold,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 19),
                      label: Text(
                        '현재 차례(${nextStage.code}) 최적 진법 원터치 자동 편성',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2) 주력 수호 알 · 문파 내공 · 5종 지형 초소 발사대 상성 통합 석판 (게슈탈트 제2덩어리)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MurimCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수호 알(1~13단) · 모양 · 문파 내공 장치 설정',
                    style: TextStyle(
                      fontSize: 16,
                      color: NightPalette.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StoneMaterial>(
                    key: ValueKey(
                      'stone_${p.activePresetIndex}_${preset.primaryStone.name}',
                    ),
                    isExpanded: true,
                    initialValue: preset.primaryStone,
                    dropdownColor: NightPalette.bgPanel,
                    decoration: _darkFieldDecoration('장착 수호 알 (해금된 재질)'),
                    items: StoneMaterial.values
                        .where((s) => p.unlockedStones.contains(s))
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                NightSpriteIcon(
                                  assetPath: NightArtRegistry.stoneAsset(s),
                                  fallbackIcon: Icons.circle,
                                  size: 24,
                                  color: Color(s.colorHex),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${s.grade}단 ${s.name} — ${s.specialDesc}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        controller.updatePreset((pr) => pr.primaryStone = v);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StoneShape>(
                    key: ValueKey(
                      'shape_${p.activePresetIndex}_${preset.primaryShape.name}',
                    ),
                    isExpanded: true,
                    initialValue: preset.primaryShape,
                    dropdownColor: NightPalette.bgPanel,
                    decoration: _darkFieldDecoration('수호 알 모양 (3종)'),
                    items: StoneShape.values
                        .map(
                          (sh) => DropdownMenuItem(
                            value: sh,
                            child: Text(
                              '${sh.name} · ${sh.summary}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        controller.updatePreset((pr) => pr.primaryShape = v);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SectTechnique>(
                    key: ValueKey(
                      'sect_${p.activePresetIndex}_${preset.sectTechnique.name}',
                    ),
                    isExpanded: true,
                    initialValue: preset.sectTechnique,
                    dropdownColor: NightPalette.bgPanel,
                    decoration: _darkFieldDecoration('문파 내공 장치 (완충 시 자동 발동)'),
                    items: SectTechnique.values
                        .map(
                          (st) => DropdownMenuItem(
                            value: st,
                            child: Row(
                              children: [
                                NightSpriteIcon(
                                  assetPath: NightArtRegistry.fxQi,
                                  fallbackIcon: Icons.auto_awesome_rounded,
                                  size: 20,
                                  color: Color(st.colorHex),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${st.sectName} [${st.skillName}]',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        controller.updatePreset((pr) => pr.sectTechnique = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('loadout_auto_upgrade_switch'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeThumbColor: NightPalette.accentGold,
                    title: const Text(
                      '전투 중 여유 기력(95⚡+) 포대 자동 승급',
                      style: TextStyle(
                        fontSize: 13.2,
                        fontWeight: FontWeight.bold,
                        color: NightPalette.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      '켜 두면 기력이 95⚡ 이상 모일 때 설치된 발사대를 자동으로 1단계씩 승급합니다.',
                      style: TextStyle(
                        fontSize: 11.4,
                        color: NightPalette.textMuted,
                      ),
                    ),
                    value: preset.autoUpgradeInBattle,
                    onChanged: (val) {
                      controller.updatePreset(
                        (pr) => pr.autoUpgradeInBattle = val,
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Colors.white12),
                  ),
                  const Text(
                    '초소 거점별 지정 병종 편성 (1~14번 거점 · 터치하여 병종 순환)',
                    style: TextStyle(
                      fontSize: 15.2,
                      color: NightPalette.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '전투 중 [🔨추천축조] 및 거점 선택창에서 우선 제안할 병종을 미리 지정합니다.',
                    style: TextStyle(
                      fontSize: 11.8,
                      color: NightPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(preset.mountTypes.length, (slotIdx) {
                      final curType = preset.mountTypes[slotIdx];
                      final unlockedTypes = LauncherType.values
                          .where((t) => t.unlockChapter <= p.effectiveArsenalChapter)
                          .toList();
                      return ActionChip(
                        key: Key('loadout_mount_slot_$slotIdx'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: NightPalette.bgDeep,
                        side: BorderSide(
                          color: Color(curType.colorHex).withValues(alpha: 0.65),
                        ),
                        avatar: NightSpriteIcon(
                          assetPath: NightArtRegistry.launcherAsset(curType),
                          fallbackIcon: Icons.gps_fixed_rounded,
                          size: 16,
                          color: Color(curType.colorHex),
                        ),
                        label: Text(
                          '${slotIdx + 1}거점: ${curType.name.split(" ").first}',
                          style: TextStyle(
                            fontSize: 11.2,
                            fontWeight: FontWeight.bold,
                            color: Color(curType.colorHex),
                          ),
                        ),
                        onPressed: unlockedTypes.length <= 1
                            ? null
                            : () {
                                final curIdx = unlockedTypes.indexOf(curType);
                                final nextType = unlockedTypes[
                                    (curIdx + 1) % unlockedTypes.length];
                                controller.updatePreset(
                                  (pr) => pr.mountTypes[slotIdx] = nextType,
                                );
                              },
                      );
                    }),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Colors.white12),
                  ),
                  const Text(
                    '10장 고유 지형 발사대 5종 대 돌연변이 상성 일람',
                    style: TextStyle(
                      fontSize: 15.5,
                      color: NightPalette.jadeGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...LauncherType.values.map((lt) {
                    final unlocked =
                        lt.unlockChapter <= p.effectiveArsenalChapter;
                    final permLv = p.launcherPermanentLevels[lt] ?? 1;
                    final targetMutant =
                        NightArtRegistry.counterTargetOfLauncher(lt);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: NightArtRegistry.launcherAsset(lt),
                            fallbackIcon: Icons.gps_fixed_rounded,
                            size: 42,
                            color: Color(lt.colorHex),
                            dimmed: !unlocked,
                            showFrame: true,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${lt.name} (영구 $permLv단 · 기본 ${lt.buildCostTokens}⚡)',
                                  style: TextStyle(
                                    fontSize: 13.8,
                                    fontWeight: FontWeight.bold,
                                    color: unlocked
                                        ? Color(lt.colorHex)
                                        : NightPalette.textMuted,
                                  ),
                                ),
                                Text(
                                  unlocked
                                      ? lt.roleSummary
                                      : '제${lt.unlockChapter}장 진군 시 개방',
                                  style: const TextStyle(
                                    fontSize: 11.8,
                                    color: NightPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: NightPalette.bgDeep.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: NightPalette.crimsonMoon
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NightSpriteIcon(
                                  assetPath: NightArtRegistry.mutantAttackAsset(
                                    targetMutant,
                                  ),
                                  fallbackAssetPath:
                                      NightArtRegistry.mutantAsset(targetMutant),
                                  fallbackIcon: Icons.pest_control_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '표적 ${targetMutant.name.split(' ').last}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanionTacticsTab(
    BuildContext context,
    PlayerProgress p,
    LoadoutPreset preset,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        // 1) 출전 영웅 3인 + 수호 영수 전신 공격 진형 무대
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              height: 176,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NightPalette.accentGold, width: 1.6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    NightArtRegistry.cardAllyPavilion,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: NightPalette.bgPanel),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55141F33),
                          Color(0xDC162238),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '출전 영웅 분대 (${preset.companions.length}/3인) & ${preset.equippedBeast.name}',
                              style: const TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 15.5,
                                color: NightPalette.accentGold,
                              ),
                            ),
                            if (p.nextRescueStage != null)
                              Text(
                                '다음 구출: ${p.nextRescueStage!.code}',
                                style: const TextStyle(
                                  fontSize: 11.8,
                                  color: NightPalette.jadeGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final hero in preset.companions)
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: Image.asset(
                                          NightArtRegistry.heroAttackAsset(hero),
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) =>
                                              Image.asset(
                                            NightArtRegistry.heroIdleAsset(hero),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(Icons.person),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xE0141F33),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: NightPalette.accentGold
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        child: Text(
                                          '${hero.name} Lv.${p.companionLevels[hero] ?? 1}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.8,
                                            color: NightPalette.accentGold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  NightSpriteIcon(
                                    assetPath: NightArtRegistry.beastAsset(
                                      preset.equippedBeast,
                                    ),
                                    fallbackIcon: Icons.pets_rounded,
                                    size: 56,
                                    borderRadius: 14,
                                    showFrame: true,
                                    frameColor: NightPalette.jadeGreen,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    preset.equippedBeast.name.split(' ').last,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: NightPalette.jadeGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MurimCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수호 영수 동행 & 자동 발동 조건',
                    style: TextStyle(
                      fontSize: 16,
                      color: NightPalette.jadeGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SpiritBeast>(
                    key: ValueKey(
                      'beast_${p.activePresetIndex}_${preset.equippedBeast.name}',
                    ),
                    isExpanded: true,
                    initialValue: preset.equippedBeast,
                    dropdownColor: NightPalette.bgPanel,
                    decoration: _darkFieldDecoration('출전 영수'),
                    items: SpiritBeast.values
                        .where((b) => (p.beastLevels[b] ?? 0) > 0)
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Row(
                              children: [
                                NightSpriteIcon(
                                  assetPath: NightArtRegistry.beastAsset(b),
                                  fallbackIcon: Icons.pets_rounded,
                                  size: 24,
                                  borderRadius: 6,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${b.name} (Lv.${p.beastLevels[b]}) — ${b.skillSummary}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        controller.updatePreset((pr) => pr.equippedBeast = v);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AutoTriggerCondition>(
                    key: ValueKey(
                      'beastCond_${p.activePresetIndex}_${preset.beastCondition.name}',
                    ),
                    isExpanded: true,
                    initialValue: preset.beastCondition,
                    dropdownColor: NightPalette.bgPanel,
                    decoration: _darkFieldDecoration('영수 자동 활동 조건'),
                    items: AutoTriggerCondition.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        controller.updatePreset((pr) => pr.beastCondition = v);
                      }
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Colors.white12),
                  ),
                  const Text(
                    '방어 초소 동료 편성 (최대 3인 · 조건부 자동 개입)',
                    style: TextStyle(
                      fontSize: 16,
                      color: NightPalette.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: CompanionHero.values
                        .where((h) => (p.companionLevels[h] ?? 0) > 0)
                        .map((hero) {
                      final selected = preset.companions.contains(hero);
                      return FilterChip(
                        selected: selected,
                        backgroundColor: NightPalette.bgDeep,
                        selectedColor: const Color(0xFF1E3A54),
                        checkmarkColor: NightPalette.accentGold,
                        side: BorderSide(
                          color: selected
                              ? NightPalette.accentGold
                              : Colors.white24,
                        ),
                        avatar: NightSpriteIcon(
                          assetPath: NightArtRegistry.heroFaceAsset(hero),
                          fallbackIcon: Icons.person_rounded,
                          size: 22,
                          borderRadius: 11,
                          fit: BoxFit.cover,
                        ),
                        label: Text(
                          '${hero.name} Lv.${p.companionLevels[hero]}',
                        ),
                        onSelected: (on) {
                          controller.updatePreset((pr) {
                            if (on) {
                              if (pr.companions.length >= 3) {
                                pr.companions.removeAt(0);
                              }
                              pr.companions.add(hero);
                            } else if (pr.companions.length > 1) {
                              pr.companions.remove(hero);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  ...preset.companions.map((hero) {
                    final curCond =
                        preset.companionConditions[hero] ??
                        hero.defaultCondition;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: NightArtRegistry.heroAttackAsset(hero),
                            fallbackAssetPath:
                                NightArtRegistry.heroIdleAsset(hero),
                            fallbackIcon: Icons.person_rounded,
                            size: 52,
                            borderRadius: 10,
                            showFrame: true,
                            frameColor: NightPalette.accentGold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<AutoTriggerCondition>(
                              key: ValueKey(
                                'heroCond_${p.activePresetIndex}_${hero.name}_${curCond.name}',
                              ),
                              isExpanded: true,
                              initialValue: curCond,
                              dropdownColor: NightPalette.bgPanel,
                              decoration: _darkFieldDecoration(
                                '${hero.name} 자동 개입 (${hero.skillDesc})',
                              ),
                              items: AutoTriggerCondition.values
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  controller.updatePreset(
                                    (pr) => pr.companionConditions[hero] = v,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Colors.white12),
                  ),
                  Row(
                    children: [
                      const NightSpriteIcon(
                        assetPath: NightArtRegistry.nightSupportSeal,
                        fallbackAssetPath: NightArtRegistry.fxChuldu,
                        fallbackIcon: Icons.campaign_rounded,
                        size: 36,
                        showFrame: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '지원패 「무림수호단 출두」 자동 발동 기준 (방어막 ${(preset.supportTriggerShieldRatio * 100).round()}% 이하)',
                          style: const TextStyle(
                            fontSize: 15,
                            color: NightPalette.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: preset.supportTriggerShieldRatio,
                    min: 0.20,
                    max: 0.80,
                    divisions: 6,
                    activeColor: NightPalette.accentGold,
                    label:
                        '방어막 ${(preset.supportTriggerShieldRatio * 100).round()}% 이하',
                    onChanged: (v) {
                      controller.updatePreset(
                        (pr) => pr.supportTriggerShieldRatio = v,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 증표 대장간(발사대·수호탑·알 해금) & 영약각(내공 경지·영수·동료 강화) 통합 성장 화면.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({
    super.key,
    required this.controller,
    this.initialTab = 0,
    this.embeddedInShell = false,
    this.onSwitchShellTab,
  });

  final GameController controller;
  final int initialTab;
  final bool embeddedInShell;
  final ValueChanged<int>? onSwitchShellTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        return DefaultTabController(
          initialIndex: initialTab,
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: !embeddedInShell,
              title: const Text('대장간(증표) · 영약각(영약)'),
              bottom: TabBar(
                indicatorColor: NightPalette.accentGold,
                labelColor: NightPalette.accentGold,
                unselectedLabelColor: NightPalette.textMuted,
                tabs: [
                  Tab(text: tr('🪙 증표 대장간 (발사대·알)')),
                  Tab(text: tr('🧪 영약각 (영수·동료·내공)')),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: Column(
                children: [
                  QuickPlayAndMenuBar(
                    controller: controller,
                    currentSection: 'forge',
                    embeddedInShell: embeddedInShell,
                    onSwitchShellTab: onSwitchShellTab,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    color: NightPalette.bgPanel.withValues(alpha: 0.94),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ResourcePill(
                              iconAsset: NightArtRegistry.nightToken,
                              icon: Icons.toll_rounded,
                              label: '변이 토벌 증표',
                              value: '${p.tokens}',
                              color: NightPalette.accentGold,
                            ),
                            ResourcePill(
                              iconAsset: NightArtRegistry.nightElixir,
                              icon: Icons.science_rounded,
                              label: '신비 영약',
                              value: '${p.elixirs}',
                              color: NightPalette.jadeShield,
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          key: const Key('forge_batch_upgrade_btn'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(136, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            backgroundColor: NightPalette.accentGold,
                            foregroundColor: NightPalette.hanjiInk,
                          ),
                          onPressed: () {
                            final logs =
                                controller.upgradeRecommendedBatch(maxSteps: 5);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: NightPalette.bgCard,
                                content: Text(
                                  logs.isEmpty
                                      ? '현재 보유 재화로 즉시 강화 가능한 항목이 없습니다.'
                                      : '추천 일괄 강화 완료: ${logs.join(" · ")}',
                                  style: const TextStyle(
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('추천 일괄 강화'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTokenForgeTab(p),
                        _buildElixirPavilionTab(p),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTokenForgeTab(PlayerProgress p) {
    final centralCost = CentralGuardianSpec.permanentUpgradeCost(
      p.centralGuardianLevel,
    );
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        // 1) 상단 주인공: 대장간 연노포 대 강철 거괴 격돌 원화 + 핵심 본진 제련 한지판
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              decoration: BoxDecoration(
                color: NightPalette.hanjiLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NightPalette.accentGold, width: 2.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 224,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          NightArtRegistry.cardForgeSanctum,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: NightPalette.bgPanel),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x22141F33), Color(0xD4162238)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 12,
                          right: 14,
                          child: Row(
                            children: [
                              NightSpriteIcon(
                                assetPath:
                                    NightArtRegistry.charMotion('jeonggak'),
                                fallbackAssetPath:
                                    NightArtRegistry.charAttack('jeonggak'),
                                fallbackIcon: Icons.build_circle_rounded,
                                size: 64,
                                borderRadius: 14,
                                fit: BoxFit.cover,
                                showFrame: true,
                                frameColor: NightPalette.accentGold,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  '명장 정각의 신기 화포 대장간 · 중갑 변이 파쇄 제련소',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 18.0,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                              ),
                              NightSpriteIcon(
                                assetPath: NightArtRegistry.mutantMotionAsset(
                                  MutantKind.ironColossusBoss,
                                ),
                                fallbackAssetPath:
                                    NightArtRegistry.showcaseBossIron,
                                fallbackIcon: Icons.shield_rounded,
                                size: 64,
                                borderRadius: 14,
                                fit: BoxFit.cover,
                                showFrame: true,
                                frameColor: NightPalette.crimsonMoon,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const NightSpriteIcon(
                              assetPath: NightArtRegistry.towerGuardian,
                              fallbackIcon: Icons.fort_rounded,
                              size: 56,
                              showFrame: true,
                              frameColor: NightPalette.hanjiInk,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '중앙 자동 보호 장치 · 기명 수호탑 (${p.centralGuardianLevel}단)',
                                    style: const TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 19.5,
                                      color: NightPalette.hanjiInk,
                                    ),
                                  ),
                                  const Text(
                                    '외곽 기공 방어막 · 본체 내구도 · 360도 자동 연사력 동시 상승',
                                    style: TextStyle(
                                      fontSize: 12.4,
                                      color: NightPalette.hanjiSubInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: NightPalette.hanjiInk,
                                foregroundColor: NightPalette.accentGold,
                                disabledBackgroundColor: const Color(0x241F2B42),
                                disabledForegroundColor: const Color(0x9E1F2B42),
                              ),
                              onPressed: p.centralGuardianLevel < 999 &&
                                      p.tokens >= centralCost
                                  ? controller.upgradeCentralGuardian
                                  : null,
                              child: Text(
                                p.centralGuardianLevel >= 999
                                    ? '최고 단수'
                                    : '증표 $centralCost 강화',
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0x331B2538)),
                        ),
                        Row(
                          children: [
                            const NightSpriteIcon(
                              assetPath: NightArtRegistry.fxCritical,
                              fallbackIcon: Icons.auto_fix_high_rounded,
                              size: 44,
                              showFrame: true,
                              frameColor: NightPalette.hanjiInk,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '태초 신기 무한 연마 (${p.forgeMasteryLevel}단 · 공방 +${(p.forgeMasteryPowerBonus * 100).toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.2,
                                      color: NightPalette.hanjiInk,
                                    ),
                                  ),
                                  const Text(
                                    '남는 증표를 무한 주입해 전 발사대 화력·중앙 탑·결계를 끝없이 연마',
                                    style: TextStyle(
                                      fontSize: 12.2,
                                      color: NightPalette.hanjiSubInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              key: const Key('upgrade_forge_mastery_btn'),
                              style: FilledButton.styleFrom(
                                backgroundColor: NightPalette.hanjiInk,
                                foregroundColor: NightPalette.jadeGreen,
                                disabledBackgroundColor: const Color(0x241F2B42),
                                disabledForegroundColor: const Color(0x9E1F2B42),
                              ),
                              onPressed: p.forgeMasteryLevel < 9999 &&
                                      p.tokens >= p.forgeMasteryCost
                                  ? controller.upgradeForgeMastery
                                  : null,
                              child: Text(
                                p.forgeMasteryLevel >= 9999
                                    ? '최고 단수'
                                    : '증표 ${p.forgeMasteryCost}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2) 길목 자동 발사대 5종 통합 제련반 (게슈탈트 제2덩어리)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MurimCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '길목 자동 발사대 5종 영구 제련반',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 18,
                      color: NightPalette.accentGold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int idx = 0; idx < LauncherType.values.length; idx++) ...[
                    if (idx > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Colors.white12),
                      ),
                    Builder(
                      builder: (_) {
                        final lt = LauncherType.values[idx];
                        final lv = p.launcherPermanentLevels[lt] ?? 1;
                        final cost = lt.permanentUpgradeCost(lv);
                        final ltUnlocked =
                            lt.unlockChapter <= p.effectiveArsenalChapter;
                        return Row(
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.launcherAsset(lt),
                              fallbackIcon: Icons.gps_fixed_rounded,
                              size: 46,
                              color: Color(lt.colorHex),
                              dimmed: !ltUnlocked,
                              showFrame: true,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${lt.name} (영구 $lv단)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.2,
                                      color: ltUnlocked
                                          ? Color(lt.colorHex)
                                          : NightPalette.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ltUnlocked
                                        ? lt.roleSummary
                                        : '제${lt.unlockChapter}장 진군 시 제련 및 배치 개방',
                                    style: const TextStyle(
                                      fontSize: 12.3,
                                      color: NightPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: ltUnlocked &&
                                      lv < 999 &&
                                      p.tokens >= cost
                                  ? () => controller.upgradeLauncherPermanent(lt)
                                  : null,
                              child: Text(
                                !ltUnlocked
                                    ? '제${lt.unlockChapter}장 개방'
                                    : (lv >= 999 ? '최고 단수' : '증표 $cost'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3) 수호 알 1~13단 통합 합성반 (게슈탈트 제3덩어리)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MurimCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수호 알 1~13단 제련 및 신물 조각 합성',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 18,
                      color: NightPalette.jadeGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int idx = 0; idx < StoneMaterial.values.length; idx++) ...[
                    if (idx > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Divider(height: 1, color: Colors.white12),
                      ),
                    Builder(
                      builder: (_) {
                        final s = StoneMaterial.values[idx];
                        final owned = p.unlockedStones.contains(s);
                        final shards = p.stoneShards[s] ?? 0;
                        final chapterLocked =
                            p.effectiveArsenalChapter < s.minChapter;
                        final canCraft = p.canUnlockStone(s);
                        return Row(
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.stoneAsset(s),
                              fallbackIcon: Icons.circle,
                              size: 42,
                              color: Color(s.colorHex),
                              dimmed: !owned,
                              showFrame: true,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${s.grade}단 ${s.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.8,
                                    ),
                                  ),
                                  Text(
                                    s.specialDesc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: NightPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (owned)
                              const Chip(label: Text('보유중'))
                            else
                              FilledButton(
                                onPressed: canCraft
                                    ? () => controller.unlockStone(s)
                                    : null,
                                child: Text(
                                  chapterLocked
                                      ? (s.isShardStone
                                          ? '제${s.minChapter}장 · 조각 $shards/${s.shardRequired}'
                                          : '제${s.minChapter}장 개방')
                                      : s.isShardStone
                                          ? '조각 $shards/${s.shardRequired}'
                                          : '증표 ${s.unlockTokens}',
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElixirPavilionTab(PlayerProgress p) {
    final nextRealm = p.realm.nextRealm;
    final canRealmUp = nextRealm != null &&
        p.naegongPoints >= nextRealm.reqNaegong &&
        p.elixirs >= nextRealm.reqElixir;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        // 1) 상단 한지 주인공: 황금 경맥 각성 원화 + 내공 8경지 승급 & 호법 영기 공명
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              decoration: BoxDecoration(
                color: NightPalette.hanjiLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NightPalette.accentGold, width: 2.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 136,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          NightArtRegistry.cardTrainingHall,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: NightPalette.bgPanel),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x22141F33), Color(0xCC162238)],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 14,
                          bottom: 10,
                          right: 14,
                          child: Text(
                            '천년 영약각 · 내공 8경지 등극 및 영웅·신수 각성',
                            style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 16.5,
                              color: NightPalette.accentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const NightSpriteIcon(
                              assetPath: NightArtRegistry.nightMeridian,
                              fallbackAssetPath: NightArtRegistry.fxQi,
                              fallbackIcon: Icons.self_improvement_rounded,
                              size: 54,
                              color: NightPalette.hanjiInk,
                              showFrame: true,
                              frameColor: NightPalette.hanjiInk,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '내공 경지 승급 · 현재 [${p.realm.name}]',
                                    style: const TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 20.0,
                                      color: NightPalette.hanjiInk,
                                    ),
                                  ),
                                  Text(
                                    nextRealm != null
                                        ? '다음 [${nextRealm.name}] 조건: 내공 ${p.naegongPoints}/${nextRealm.reqNaegong} · 영약 ${nextRealm.reqElixir}개'
                                        : '최고 경지 [생사경] 완성! 남는 영약은 무한 공명에 주입하세요.',
                                    style: const TextStyle(
                                      fontSize: 12.4,
                                      color: NightPalette.hanjiSubInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (nextRealm != null) ...[
                              const SizedBox(width: 8),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: NightPalette.hanjiInk,
                                  foregroundColor: NightPalette.accentGold,
                                  disabledBackgroundColor:
                                      const Color(0x241F2B42),
                                  disabledForegroundColor:
                                      const Color(0x9E1F2B42),
                                ),
                                onPressed: canRealmUp
                                    ? controller.breakthroughRealm
                                    : null,
                                child: Text('영약 ${nextRealm.reqElixir} 승급'),
                              ),
                            ],
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0x331B2538)),
                        ),
                        Row(
                          children: [
                            const NightSpriteIcon(
                              assetPath: NightArtRegistry.nightElixir,
                              fallbackAssetPath: NightArtRegistry.fxQi,
                              fallbackIcon: Icons.auto_awesome_rounded,
                              size: 44,
                              showFrame: true,
                              frameColor: NightPalette.hanjiInk,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '☯️ 호법 영기 무한 공명 (${p.elixirResonanceLevel}단 · 영수/동료 화력 +${(p.elixirResonanceBonus * 100).toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: NightPalette.hanjiInk,
                                    ),
                                  ),
                                  const Text(
                                    '남는 영약을 주입해 영수 5종·동료 14인 화력과 결계 재생력을 무한 증폭',
                                    style: TextStyle(
                                      fontSize: 12.2,
                                      color: NightPalette.hanjiSubInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              key: const Key('upgrade_elixir_resonance_btn'),
                              style: FilledButton.styleFrom(
                                backgroundColor: NightPalette.hanjiInk,
                                foregroundColor: NightPalette.jadeGreen,
                                disabledBackgroundColor: const Color(0x241F2B42),
                                disabledForegroundColor: const Color(0x9E1F2B42),
                              ),
                              onPressed: p.elixirResonanceLevel < 9999 &&
                                      p.elixirs >= p.elixirResonanceCost
                                  ? controller.upgradeElixirResonance
                                  : null,
                              child: Text(
                                p.elixirResonanceLevel >= 9999
                                    ? '최고 단수'
                                    : '영약 ${p.elixirResonanceCost}',
                              ),
                            ),
                          ],
                        ),
                        if (p.reincarnationCount > 0) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0x331B2538)),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.autorenew_rounded,
                                size: 40,
                                color: Color(0xFF7B2CBF),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🌟 윤회 초월 단련 (${p.transcendenceLevel}단 · 총 화력/결계 ×${p.transcendenceMultiplier.toStringAsFixed(2)}배)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.0,
                                        color: NightPalette.hanjiInk,
                                      ),
                                    ),
                                    Text(
                                      '제${p.reincarnationCount}환생(난이도 ×${p.reincarnationDifficultyMultiplier.round()}배) 마기를 제압하기 위한 초월 승수 단련',
                                      style: const TextStyle(
                                        fontSize: 12.2,
                                        color: NightPalette.hanjiSubInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                key: const Key('upgrade_transcendence_btn'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF3C096C),
                                  foregroundColor: NightPalette.accentGold,
                                  disabledBackgroundColor:
                                      const Color(0x241F2B42),
                                  disabledForegroundColor:
                                      const Color(0x9E1F2B42),
                                ),
                                onPressed: p.tokens >=
                                            p.transcendenceTokenCost &&
                                        p.elixirs >= p.transcendenceElixirCost
                                    ? controller.upgradeTranscendence
                                    : null,
                                child: Text(
                                  '증표${p.transcendenceTokenCost}·영약${p.transcendenceElixirCost}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2) 수호 영수 5종 통합 단련반
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MurimCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수호 영수 5종 강화',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 18,
                      color: NightPalette.jadeGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int idx = 0; idx < SpiritBeast.values.length; idx++) ...[
                    if (idx > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Divider(height: 1, color: Colors.white12),
                      ),
                    Builder(
                      builder: (_) {
                        final b = SpiritBeast.values[idx];
                        final lv = p.beastLevels[b] ?? 0;
                        final cost =
                            lv == 0 ? b.unlockElixirs : b.upgradeElixirCost(lv);
                        return Row(
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.beastAsset(b),
                              fallbackIcon: Icons.pets_rounded,
                              size: 48,
                              color: Color(b.colorHex),
                              dimmed: lv == 0,
                              showFrame: true,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${b.name} ${lv == 0 ? "(미영입)" : "(Lv.$lv)"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.2,
                                      color: Color(b.colorHex),
                                    ),
                                  ),
                                  Text(
                                    b.skillSummary,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: NightPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (_) {
                                final chOpen =
                                    p.effectiveArsenalChapter >= b.unlockChapter;
                                final canBuy = lv < p.maxAllyLevel &&
                                    p.elixirs >= cost &&
                                    (lv > 0 || chOpen);
                                return FilledButton(
                                  onPressed: canBuy
                                      ? () => controller.upgradeBeast(b)
                                      : null,
                                  child: Text(
                                    lv >= p.maxAllyLevel
                                        ? '최고단계'
                                        : (lv == 0
                                            ? (chOpen
                                                ? '영약 $cost 영입'
                                                : '${b.unlockChapter}장 해금')
                                            : '영약 $cost 강화'),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3) 방어 초소 동료 14인 전신 원화 단련반
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MurimCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '방어 초소 영웅 14인 강화',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 18,
                      color: NightPalette.accentGold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int idx = 0; idx < CompanionHero.values.length; idx++) ...[
                    if (idx > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Divider(height: 1, color: Colors.white12),
                      ),
                    Builder(
                      builder: (_) {
                        final h = CompanionHero.values[idx];
                        final lv = p.companionLevels[h] ?? 0;
                        final cost =
                            lv == 0 ? h.unlockElixirs : h.upgradeElixirCost(lv);
                        final canAcquire = lv > 0 ||
                            (h.unlockElixirs > 0 &&
                                p.effectiveArsenalChapter >= h.unlockChapter);
                        return Row(
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.heroAttackAsset(h),
                              fallbackAssetPath:
                                  NightArtRegistry.heroIdleAsset(h),
                              fallbackIcon: Icons.person_rounded,
                              size: 54,
                              borderRadius: 12,
                              dimmed: lv == 0,
                              showFrame: true,
                              frameColor: lv > 0
                                  ? NightPalette.accentGold
                                  : NightPalette.borderGold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${h.name} · ${h.title} ${lv > 0 ? "(Lv.$lv)" : "(${h.unlockChapter}장 합류)"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.8,
                                    ),
                                  ),
                                  Text(
                                    h.skillDesc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: NightPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: (canAcquire &&
                                      lv < p.maxAllyLevel &&
                                      p.elixirs >= cost)
                                  ? () => controller.upgradeCompanion(h)
                                  : null,
                              child: Text(
                                !canAcquire
                                    ? '${h.unlockChapter}장 개방'
                                    : (lv >= p.maxAllyLevel
                                        ? '최고'
                                        : '영약 $cost'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
