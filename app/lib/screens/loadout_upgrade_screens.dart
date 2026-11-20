import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';

typedef ForgeSanctuaryScreen = UpgradeScreen;

/// 진법 편성실 (슬롯 3칸 · 알/모양/무공 · 거점 발사대 · 영수/동료 조건부 자동 발동 설정).
class LoadoutScreen extends StatelessWidget {
  const LoadoutScreen({super.key, required this.controller});
  final GameController controller;

  static InputDecoration _darkFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(fontSize: 12.8, color: NightPalette.textMuted),
      filled: true,
      fillColor: NightPalette.bgDeep.withValues(alpha: 0.78),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: NightPalette.borderGold.withValues(alpha: 0.28),
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
            appBar: AppBar(
              title: const Text('자동 수호 진법 편성실'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: '☯️ 수호 알 · 내공 · 거점 발사대'),
                  Tab(text: '🐾 영수 · 동료 · 출두 조건'),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: TabBarView(
                children: [
                  _buildCoreArsenalTab(p, preset),
                  _buildCompanionTacticsTab(p, preset),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoreArsenalTab(PlayerProgress p, LoadoutPreset preset) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1) 상단 한지 명패 + 진법 저장 슬롯 3칸 통합반 (게슈탈트 제1덩어리 · 확실한 시각 주인공 강조)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EED5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NightPalette.accentGold, width: 2.4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NightSpriteIcon(
                        assetPath: NightArtRegistry.stoneAsset(
                          preset.primaryStone,
                        ),
                        fallbackIcon: Icons.circle,
                        size: 78,
                        color: Color(preset.primaryStone.colorHex),
                        showFrame: true,
                        frameColor: const Color(0xFF1B2538),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '상황별 즉시 전환 · 3대 수호 진법 저장소',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF394B6D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${preset.name} (${preset.primaryStone.grade}단 ${preset.primaryStone.name})',
                              style: const TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 25,
                                color: Color(0xFF162033),
                              ),
                            ),
                            Text(
                              '${preset.primaryShape.name} · ${preset.sectTechnique.sectName} [${preset.sectTechnique.skillName}]',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E3D59),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: List.generate(p.presets.length, (i) {
                      final sel = p.activePresetIndex == i;
                      return ChoiceChip(
                        selected: sel,
                        backgroundColor: const Color(0xFFE3D4B3),
                        selectedColor: const Color(0xFF233048),
                        checkmarkColor: NightPalette.accentGold,
                        side: BorderSide(
                          color: sel
                              ? const Color(0xFF1B2538)
                              : const Color(0xFFB5A178),
                        ),
                        labelStyle: TextStyle(
                          color: sel
                              ? NightPalette.accentGold
                              : const Color(0xFF233048),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        label: Text(p.presets[i].name),
                        onSelected: (_) => controller.selectPreset(i),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2) 주력 수호 알 · 문파 내공 · 12굽이 천리협곡 거점 발사대 5종 통합 석판 (게슈탈트 제2덩어리)
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  const Text(
                    '12굽이 천리협곡(720×1360) 5종 지형 초소 발사대 도감',
                    style: TextStyle(
                      fontSize: 15.5,
                      color: NightPalette.jadeGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• 전방 초소(3번 이후)는 🪨마기 암석을 개척한 뒤 건설하며, 포탑 수가 늘수록 체증 군수비(+14⚡)와 2.2초 축조 시간이 적용됩니다.\n'
                    '• 두목은 2차 재변이하며 포탑에 🕸️마기 침식을 걸고(터치 시 즉시 정화!), 3페이즈 대수괴는 회전 약점(🎯)을 정밀 다격해야 파쇄됩니다.',
                    style: TextStyle(
                      fontSize: 12.2,
                      color: NightPalette.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...LauncherType.values.map((lt) {
                    final unlocked =
                        lt.unlockChapter <= p.highestUnlockedChapter + 1;
                    final permLv = p.launcherPermanentLevels[lt] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: NightArtRegistry.launcherAsset(lt),
                            fallbackIcon: Icons.gps_fixed_rounded,
                            size: 38,
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
                                  '${lt.name} (영구 $permLv단 · 기본 ${lt.buildCostTokens}⚡ + 체증)',
                                  style: TextStyle(
                                    fontSize: 13.5,
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

  Widget _buildCompanionTacticsTab(PlayerProgress p, LoadoutPreset preset) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MurimCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.nextRescueStage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NightPalette.bgDeep.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NightPalette.jadeGreen.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.volunteer_activism_rounded,
                            color: NightPalette.jadeGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '🆘 구출 현황: 동료 ${p.unlockedCompanionCount}/14인 · 영수 ${p.unlockedBeastCount}/5종\n'
                              '다음 구출 관문: [${p.nextRescueStage!.code}] ${p.nextRescueStage!.rescueBadgeText}',
                              style: const TextStyle(
                                fontSize: 12.4,
                                color: NightPalette.jadeGreen,
                                height: 1.38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      NightSpriteIcon(
                        assetPath: NightArtRegistry.beastAsset(
                          preset.equippedBeast,
                        ),
                        fallbackIcon: Icons.pets_rounded,
                        size: 42,
                        color: Color(preset.equippedBeast.colorHex),
                        showFrame: true,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '수호 영수 동행 & 자동 발동 조건',
                          style: TextStyle(
                            fontSize: 16,
                            color: NightPalette.jadeGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SpiritBeast>(
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
                                    '${b.name} (Lv.${p.beastLevels[b]})',
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
                    child: Divider(height: 1),
                  ),
                  const Text(
                    '방어 초소 동료 편성 (최대 3인 · 조건부 자동 개입)',
                    style: TextStyle(
                      fontSize: 16,
                      color: NightPalette.elixirPurple,
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
                        selectedColor: const Color(0xFF3E295E),
                        checkmarkColor: NightPalette.accentGold,
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
                            assetPath: NightArtRegistry.heroIdleAsset(hero),
                            fallbackAssetPath:
                                NightArtRegistry.heroFaceAsset(hero),
                            fallbackIcon: Icons.person_rounded,
                            size: 46,
                            borderRadius: 10,
                            showFrame: true,
                            frameColor: NightPalette.elixirPurple,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<AutoTriggerCondition>(
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
                    child: Divider(height: 1),
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
                          '지원패 「무림수호단 출두야~~!!」 자동 발동 기준 (방어막 ${(preset.supportTriggerShieldRatio * 100).round()}% 이하)',
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
  });
  final GameController controller;
  final int initialTab;

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
            appBar: AppBar(
              title: const Text('대장간(증표) · 영약각(영약)'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: '🪙 증표 대장간 (발사대·알)'),
                  Tab(text: '🧪 영약각 (영수·동료·내공)'),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    color: NightPalette.bgPanel.withValues(alpha: 0.92),
                    child: Wrap(
                      spacing: 10,
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
                          color: NightPalette.elixirPurple,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1) 상단 한지 명패 + 핵심 본진 제련 통합반 (게슈탈트 제1덩어리 · 시각 주인공)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E7CC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NightPalette.accentGold, width: 1.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const NightSpriteIcon(
                        assetPath: NightArtRegistry.towerGuardian,
                        fallbackIcon: Icons.fort_rounded,
                        size: 62,
                        showFrame: true,
                        frameColor: Color(0xFF233048),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '수호 본진 중추 제련 · 무한 신기 연마',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF394B6D),
                              ),
                            ),
                            Text(
                              '중앙 자동 보호 장치 · 기명 수호탑 (${p.centralGuardianLevel}단)',
                              style: const TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 21,
                                color: Color(0xFF1B2538),
                              ),
                            ),
                            const Text(
                              '외곽 기공 방어막 내구도 · 본체 내구도 · 360도 자동 연사력 동시 상승',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF3B4A66),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F2B42),
                          foregroundColor: NightPalette.accentGold,
                          disabledBackgroundColor: const Color(0x241F2B42),
                          disabledForegroundColor: const Color(0x9E1F2B42),
                        ),
                        onPressed: p.tokens >= centralCost
                            ? controller.upgradeCentralGuardian
                            : null,
                        child: Text('증표 $centralCost 강화'),
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
                        assetPath: NightArtRegistry.cardForgeSanctum,
                        fallbackAssetPath: NightArtRegistry.fxCritical,
                        fallbackIcon: Icons.auto_fix_high_rounded,
                        size: 46,
                        showFrame: true,
                        frameColor: Color(0xFF233048),
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
                                fontSize: 15.5,
                                color: Color(0xFF1B2538),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '남는 수호 증표를 무한 주입해 전 발사대 화력·중앙 탑·외곽 결계를 끝없이 연마',
                              style: TextStyle(
                                fontSize: 12.2,
                                color: Color(0xFF3B4A66),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('upgrade_forge_mastery_btn'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F2B42),
                          foregroundColor: NightPalette.jadeGreen,
                          disabledBackgroundColor: const Color(0x241F2B42),
                          disabledForegroundColor: const Color(0x9E1F2B42),
                        ),
                        onPressed: p.tokens >= p.forgeMasteryCost
                            ? controller.upgradeForgeMastery
                            : null,
                        child: Text('증표 ${p.forgeMasteryCost}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2) 길목 자동 발사대 5종 통합 제련반 (게슈탈트 제2덩어리 · 같은 정보 한 상자)
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
                        return Row(
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.launcherAsset(lt),
                              fallbackIcon: Icons.gps_fixed_rounded,
                              size: 46,
                              color: Color(lt.colorHex),
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
                                      color: Color(lt.colorHex),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lt.roleSummary,
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
                              onPressed: p.tokens >= cost
                                  ? () => controller.upgradeLauncherPermanent(lt)
                                  : null,
                              child: Text('증표 $cost'),
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

        // 3) 수호 알 1~13단 통합 합성반 (게슈탈트 제3덩어리 · 같은 정보 한 상자)
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
                        final chapterLocked = p.highestUnlockedChapter < s.minChapter;
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
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          '기연·호송·탐색·보스 토벌로 얻은 「영약」으로 내공 경지와 영수·동료를 강화합니다.',
          style: TextStyle(fontSize: 13, color: NightPalette.textMuted),
        ),
        const SizedBox(height: 10),
        MurimCard(
          borderColor: NightPalette.elixirPurple,
          child: Row(
            children: [
              const NightSpriteIcon(
                assetPath: NightArtRegistry.nightMeridian,
                fallbackAssetPath: NightArtRegistry.fxQi,
                fallbackIcon: Icons.self_improvement_rounded,
                size: 50,
                color: NightPalette.elixirPurple,
                showFrame: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내공 경지 승급 · 현재 [${p.realm.name}]',
                      style: const TextStyle(
                        fontSize: 16.5,
                        color: NightPalette.elixirPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextRealm != null
                          ? '다음 [${nextRealm.name}] 조건: 내공 ${p.naegongPoints}/${nextRealm.reqNaegong} · 영약 ${nextRealm.reqElixir}개\n(자동 어기어석 동행 알 ${nextRealm.eogieoseokCount}기 · 공방 대폭 상승!)'
                          : '최고 경지 [생사경] 완성!',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: NightPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (nextRealm != null) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canRealmUp ? controller.breakthroughRealm : null,
                  child: Text('영약 ${nextRealm.reqElixir} 승급'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '수호 영수 5종 강화',
          style: TextStyle(fontSize: 16, color: NightPalette.jadeGreen),
        ),
        const SizedBox(height: 8),
        ...SpiritBeast.values.map((b) {
          final lv = p.beastLevels[b] ?? 0;
          final cost = lv == 0 ? b.unlockElixirs : b.upgradeElixirCost(lv);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MurimCard(
              borderColor: lv > 0
                  ? Color(b.colorHex).withValues(alpha: 0.65)
                  : NightPalette.borderGold.withValues(alpha: 0.35),
              child: Row(
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
                            fontSize: 15.5,
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
                  FilledButton(
                    onPressed: (lv < 10 && p.elixirs >= cost)
                        ? () => controller.upgradeBeast(b)
                        : null,
                    child: Text(
                      lv >= 10
                          ? '최고단계'
                          : (lv == 0 ? '영약 $cost 영입' : '영약 $cost 강화'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        const Text(
          '방어 초소 동료 강화',
          style: TextStyle(fontSize: 16, color: NightPalette.accentGold),
        ),
        const SizedBox(height: 8),
        ...CompanionHero.values.map((h) {
          final lv = p.companionLevels[h] ?? 0;
          final cost = lv == 0 ? h.unlockElixirs : h.upgradeElixirCost(lv);
          final canAcquire = lv > 0 ||
              (h.unlockElixirs > 0 &&
                  p.highestUnlockedChapter >= h.unlockChapter);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MurimCard(
              child: Row(
                children: [
                  NightSpriteIcon(
                    assetPath: NightArtRegistry.heroIdleAsset(h),
                    fallbackAssetPath: NightArtRegistry.heroFaceAsset(h),
                    fallbackIcon: Icons.person_rounded,
                    size: 50,
                    borderRadius: 12,
                    dimmed: lv == 0,
                    showFrame: true,
                    frameColor: lv > 0
                        ? NightPalette.accentGold
                        : NightPalette.borderGold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${h.name} · ${h.title} ${lv > 0 ? "(Lv.$lv)" : "(${h.unlockChapter}장 합류)"}',
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
                    onPressed: (canAcquire && lv < 10 && p.elixirs >= cost)
                        ? () => controller.upgradeCompanion(h)
                        : null,
                    child: Text(
                      !canAcquire
                          ? '${h.unlockChapter}장 개방'
                          : (lv >= 10 ? '최고' : '영약 $cost'),
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
}
