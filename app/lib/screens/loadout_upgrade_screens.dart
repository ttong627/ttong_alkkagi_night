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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        final preset = p.activePreset;

        return Scaffold(
          appBar: AppBar(title: const Text('자동 수호 진법 편성실')),
          body: NightSceneBackdrop(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // 1) 진법 슬롯 3칸 선택
                MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '진법 저장 슬롯 (상황에 맞춰 즉시 교체)',
                        style: TextStyle(
                          fontSize: 16,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: List.generate(p.presets.length, (i) {
                          return ChoiceChip(
                            selected: p.activePresetIndex == i,
                            label: Text(p.presets[i].name),
                            onSelected: (_) => controller.selectPreset(i),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2) 주력 수호 알(1~13단 stone_*.webp) · 모양(3종) · 문파 내공(4종)
                MurimCard(
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
                            size: 42,
                            color: Color(preset.primaryStone.colorHex),
                            showFrame: true,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '수호 알 종류(1~13단) · 모양 · 문파 내공 장치',
                              style: TextStyle(
                                fontSize: 16,
                                color: NightPalette.accentGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<StoneMaterial>(
                        isExpanded: true,
                        initialValue: preset.primaryStone,
                        decoration: const InputDecoration(
                          labelText: '장착 수호 알 (해금된 재질)',
                        ),
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
                      const SizedBox(height: 8),
                      DropdownButtonFormField<StoneShape>(
                        isExpanded: true,
                        initialValue: preset.primaryShape,
                        decoration: const InputDecoration(
                          labelText: '수호 알 모양 (3종)',
                        ),
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
                      const SizedBox(height: 8),
                      DropdownButtonFormField<SectTechnique>(
                        isExpanded: true,
                        initialValue: preset.sectTechnique,
                        decoration: const InputDecoration(
                          labelText: '문파 내공 장치 (1칸 완충 시 자동 발동)',
                        ),
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
                            controller.updatePreset(
                              (pr) => pr.sectTechnique = v,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3) 산·들 길목 거점 1~5번 자동 발사대 배치 (launcher_*.webp)
                MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '길목 거점별 자동 알 발사대 편성 (전투 중 1형→4형 승급)',
                        style: TextStyle(
                          fontSize: 16,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (int idx = 0; idx < 5; idx++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              NightSpriteIcon(
                                assetPath: NightArtRegistry.launcherAsset(
                                  preset.mountTypes[idx],
                                ),
                                fallbackIcon: Icons.gps_fixed_rounded,
                                size: 42,
                                color: Color(preset.mountTypes[idx].colorHex),
                                showFrame: true,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<LauncherType>(
                                  isExpanded: true,
                                  initialValue: preset.mountTypes[idx],
                                  decoration: InputDecoration(
                                    labelText: '${idx + 1}번 길목 거점 발사대',
                                  ),
                                  items: LauncherType.values
                                      .map(
                                        (lt) => DropdownMenuItem(
                                          value: lt,
                                          child: Row(
                                            children: [
                                              NightSpriteIcon(
                                                assetPath: NightArtRegistry
                                                    .launcherAsset(lt),
                                                fallbackIcon:
                                                    Icons.gps_fixed_rounded,
                                                size: 22,
                                                color: Color(lt.colorHex),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${lt.name} (강화 ${p.launcherPermanentLevels[lt] ?? 1}단) — ${lt.roleSummary}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      controller.updatePreset(
                                        (pr) => pr.mountTypes[idx] = v,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4) 영수 동행 및 자동 발동 조건 (pet_*.webp)
                MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: NightArtRegistry.beastAsset(
                              preset.equippedBeast,
                            ),
                            fallbackIcon: Icons.pets_rounded,
                            size: 44,
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<SpiritBeast>(
                        isExpanded: true,
                        initialValue: preset.equippedBeast,
                        decoration: const InputDecoration(labelText: '출전 영수'),
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
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AutoTriggerCondition>(
                        isExpanded: true,
                        initialValue: preset.beastCondition,
                        decoration: const InputDecoration(
                          labelText: '영수 자동 활동 조건',
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
                              (pr) => pr.beastCondition = v,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 5) 동료 최대 3인 편성 (*_face.webp & *_idle.webp 원화 표시)
                MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '방어 초소 동료 편성 (최대 3인 · 조건부 자동 발사)',
                        style: TextStyle(
                          fontSize: 16,
                          color: NightPalette.elixirPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: CompanionHero.values
                            .where(
                              (h) =>
                                  h != CompanionHero.mukhyeon &&
                                  (p.companionLevels[h] ?? 0) > 0,
                            )
                            .map((hero) {
                          final selected = preset.companions.contains(hero);
                          return FilterChip(
                            selected: selected,
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
                                size: 48,
                                borderRadius: 10,
                                showFrame: true,
                                frameColor: NightPalette.elixirPurple,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<
                                    AutoTriggerCondition>(
                                  isExpanded: true,
                                  initialValue: curCond,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${hero.name} 자동 개입 조건 (${hero.skillDesc})',
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
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 6) 암행어사 출두 지원패 자동 발동 위기 기준
                MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              ],
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          '돌연변이가 떨어뜨린 「증표」로 중앙 보호 장치와 길목 자동 발사대를 영구 강화합니다.',
          style: TextStyle(fontSize: 13, color: NightPalette.textMuted),
        ),
        const SizedBox(height: 10),
        MurimCard(
          borderColor: NightPalette.accentGold,
          child: Row(
            children: [
              const NightSpriteIcon(
                assetPath: NightArtRegistry.towerGuardian,
                fallbackIcon: Icons.fort_rounded,
                size: 54,
                showFrame: true,
                frameColor: NightPalette.accentGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '중앙 자동 보호 장치 · 기명 수호탑 (${p.centralGuardianLevel}단)',
                      style: const TextStyle(
                        fontSize: 16,
                        color: NightPalette.accentGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '외곽 기공 방어막 내구도 · 본체 내구도 · 360도 자동 연사력 동시 상승!',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: NightPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: p.tokens >= centralCost
                    ? controller.upgradeCentralGuardian
                    : null,
                child: Text('증표 $centralCost 강화'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...LauncherType.values.map((lt) {
          final lv = p.launcherPermanentLevels[lt] ?? 1;
          final cost = lt.permanentUpgradeCost(lv);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MurimCard(
              borderColor: Color(lt.colorHex).withValues(alpha: 0.55),
              child: Row(
                children: [
                  NightSpriteIcon(
                    assetPath: NightArtRegistry.launcherAsset(lt),
                    fallbackIcon: Icons.gps_fixed_rounded,
                    size: 48,
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
                            fontSize: 15.5,
                            color: Color(lt.colorHex),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lt.roleSummary,
                          style: const TextStyle(
                            fontSize: 12.5,
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
              ),
            ),
          );
        }),
        const Divider(height: 24),
        const Text(
          '수호 알 1~13단 제련 및 신물 조각 합성',
          style: TextStyle(fontSize: 16, color: NightPalette.jadeGreen),
        ),
        const SizedBox(height: 8),
        ...StoneMaterial.values.map((s) {
          final owned = p.unlockedStones.contains(s);
          final shards = p.stoneShards[s] ?? 0;
          final canCraft = !owned &&
              (s.isShardStone
                  ? shards >= s.shardRequired
                  : p.tokens >= s.unlockTokens);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MurimCard(
              borderColor: owned
                  ? Color(s.colorHex).withValues(alpha: 0.7)
                  : NightPalette.borderGold.withValues(alpha: 0.35),
              child: Row(
                children: [
                  NightSpriteIcon(
                    assetPath: NightArtRegistry.stoneAsset(s),
                    fallbackIcon: Icons.circle,
                    size: 44,
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
                          style: const TextStyle(fontSize: 15),
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
                      onPressed:
                          canCraft ? () => controller.unlockStone(s) : null,
                      child: Text(
                        s.isShardStone
                            ? '조각 $shards/${s.shardRequired}'
                            : '증표 ${s.unlockTokens}',
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
