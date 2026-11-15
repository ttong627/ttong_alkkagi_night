import 'dart:async';
import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';

typedef MeditationScreen = TrainingScreen;

/// 초간단 「기명 심법 수련실」 — 알까기 조작 없음 · 실패 판정 0% 보장!
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathAnim;
  bool _autoMeditate = false;
  Timer? _autoTimer;
  String _lastLog = '단전 구슬을 아무 때나 가볍게 누르세요! (실패 없이 100% 내공이 오릅니다)';
  final Set<int> _litAcupoints = {};

  @override
  void initState() {
    super.initState();
    _breathAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _breathAnim.dispose();
    super.dispose();
  }

  void _toggleAutoMeditate(bool value) {
    setState(() => _autoMeditate = value);
    _autoTimer?.cancel();
    if (value) {
      _autoTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
        if (!mounted) return;
        _performMeditationTap();
      });
    }
  }

  void _performMeditationTap() {
    final inGoldenZone = _breathAnim.value >= 0.68;
    final res = widget.controller.meditate(hitGoldenRing: inGoldenZone);
    final tags = <String>[];
    if (res.wasEnlightenmentBonus) tags.add('오늘의 깨달음 ×6');
    if (res.wasCriticalSerendipity) tags.add('⚡대오각성 크리티컬!');
    if (res.wasOneMoreSerendipity) tags.add('🔁기연 · 한 번 더 운기!');

    setState(() {
      _lastLog =
          '내공 +${res.gainedNaegong} · 수련 인장 +${res.gainedSeals} ${tags.isEmpty ? "(평온 운기 완료)" : "[${tags.join(" · ")}]"}';
    });
  }

  void _tapAcupoint(int idx, MeridianStepSpec spec) {
    setState(() {
      _litAcupoints.add(idx);
    });
    if (_litAcupoints.length >= spec.acupointCoords.length) {
      final opened = widget.controller.openMeridian();
      setState(() {
        _litAcupoints.clear();
        if (opened != null) {
          _lastLog =
              '🎉 수련 ${opened.stepNumber}/10 「${opened.name}」 개통 완료! (${opened.effectSummary})';
        }
      });
      if (opened != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: NightPalette.bgCard,
            content: Text(
              '✨ ${opened.name} 대개통! ${opened.effectSummary} · 증표 +${opened.rewardTokens} · 영약 +${opened.rewardElixirs}',
              style: const TextStyle(color: NightPalette.accentGold),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = widget.controller.progress;
        final nextRealm = p.realm.nextRealm;
        final remainBonus = (10 - p.dailyEnlightenmentUsed).clamp(0, 10);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('기명 심법 수련실 (실패 0%)'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: '① 단전 운기'),
                  Tab(text: '② 십대 경맥(10단)'),
                  Tab(text: '③ 능력치 단련'),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: Column(
                children: [
                  // 상단 내공 경지 및 자동 운기 표시줄
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    color: NightPalette.bgPanel.withValues(alpha: 0.92),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ResourcePill(
                              iconAsset: NightArtRegistry.fxQi,
                              icon: Icons.local_fire_department_rounded,
                              label: '경지 ${p.realm.name} · 내공',
                              value: '${p.naegongPoints}',
                              color: NightPalette.jadeGreen,
                            ),
                            ResourcePill(
                              iconAsset: NightArtRegistry.iconTrainingSeal,
                              icon: Icons.verified_rounded,
                              label: '수련 인장',
                              value: '${p.trainingSeals}',
                              color: NightPalette.accentGold,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '자동 운기',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Switch(
                                  value: _autoMeditate,
                                  onChanged: _toggleAutoMeditate,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nextRealm != null
                              ? '다음 경지 [${nextRealm.name}] 목표 내공: ${p.naegongPoints} / ${nextRealm.reqNaegong} · 오늘 깨달음(6배) 남은 횟수: $remainBonus/10회'
                              : '최고 경지 [생사경] 도달 완료! · 오늘 깨달음 남은 횟수: $remainBonus/10회',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: NightPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastLog,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: NightPalette.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMeditationTab(p),
                        _buildMeridianTab(p),
                        _buildCoreStatTab(p),
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

  Widget _buildMeditationTab(PlayerProgress p) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const NightSpriteIcon(
                  assetPath: NightArtRegistry.nightMeridian,
                  fallbackIcon: Icons.self_improvement_rounded,
                  size: 32,
                  color: NightPalette.jadeGreen,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    '알을 튕길 필요 없이 구슬만 톡 누르세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: NightPalette.accentGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '언제 눌러도 100% 성공하며, 황금 숨결 고리가 안쪽으로 모일 때 누르면\n⚡대오각성 크리티컬(2배)과 🔁한 번 더 기연이 터집니다!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: NightPalette.textMuted),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              key: const Key('meditation_orb_button'),
              onTap: _performMeditationTap,
              child: AnimatedBuilder(
                animation: _breathAnim,
                builder: (context, _) {
                  final ringRadius = 124.0 - 52.0 * _breathAnim.value;
                  final inGolden = _breathAnim.value >= 0.68;
                  return SizedBox(
                    width: 256,
                    height: 256,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 단전 내공 기운(fx_qi.webp) 회전 광륜
                        Transform.rotate(
                          angle: _breathAnim.value * pi * 0.6,
                          child: Opacity(
                            opacity: 0.36 + 0.32 * _breathAnim.value,
                            child: Image.asset(
                              NightArtRegistry.fxQi,
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // 외곽 대오각성 황금 구간 표시
                        Container(
                          width: 152,
                          height: 152,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NightPalette.accentGold.withValues(alpha: 0.35),
                              width: 10,
                            ),
                          ),
                        ),
                        // 수축하는 숨결 고리
                        Container(
                          width: ringRadius * 2,
                          height: ringRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: inGolden
                                  ? NightPalette.accentGold
                                  : NightPalette.jadeShield,
                              width: inGolden ? 4.5 : 2.5,
                            ),
                          ),
                        ),
                        // 중앙 기명 단전 구슬
                        Container(
                          width: 122,
                          height: 122,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: inGolden
                                  ? const [
                                      Color(0xFFFFF3B0),
                                      Color(0xFFFFB703),
                                      Color(0xFF9A031E),
                                    ]
                                  : const [
                                      Color(0xFF90E0EF),
                                      Color(0xFF0077B6),
                                      Color(0xFF03045E),
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (inGolden
                                        ? NightPalette.accentGold
                                        : NightPalette.jadeShield)
                                    .withValues(alpha: 0.55),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '단전 운기\n(터치)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '1회 운기마다 휴대폰에 즉시 자동 저장됩니다',
              style: TextStyle(fontSize: 12.5, color: NightPalette.jadeGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeridianTab(PlayerProgress p) {
    final allDone = p.openedMeridianStep >= MeridianStepSpec.steps.length;
    final currentSpec = allDone
        ? MeridianStepSpec.steps.last
        : MeridianStepSpec.steps[p.openedMeridianStep];
    final enoughNaegong = p.naegongPoints >= currentSpec.reqNaegong;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MurimCard(
            borderColor: NightPalette.accentGold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const NightSpriteIcon(
                      assetPath: NightArtRegistry.nightMeridian,
                      fallbackIcon: Icons.hub_rounded,
                      size: 46,
                      color: NightPalette.accentGold,
                      showFrame: true,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        allDone
                            ? '🌟 십대 경맥 10/10 전 단계 대개통 완료!'
                            : '수련 ${currentSpec.stepNumber}/10 · ${currentSpec.name}',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 18.5,
                          color: NightPalette.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  allDone
                      ? '생사현관까지 모든 혈자리가 열려 최강의 수호 기운이 흐릅니다!'
                      : '효과: ${currentSpec.effectSummary} · 필요 내공: ${p.naegongPoints}/${currentSpec.reqNaegong}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                if (!allDone)
                  Text(
                    enoughNaegong
                        ? '👇 아래 빛나는 혈자리 구슬 ${currentSpec.acupointCoords.length}개를 톡톡 누르면 실패 없이 즉시 개통됩니다!'
                        : '먼저 ①단전 운기 탭에서 내공을 ${currentSpec.reqNaegong}까지 모아주세요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: enoughNaegong
                          ? NightPalette.jadeGreen
                          : NightPalette.crimsonMoon,
                    ),
                  ),
                if (!allDone && enoughNaegong) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('meridian_instant_open_btn'),
                      onPressed: () {
                        for (int i = 0;
                            i < currentSpec.acupointCoords.length;
                            i++) {
                          _tapAcupoint(i, currentSpec);
                        }
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text('한 번에 ${currentSpec.name} 즉시 개통하기'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!allDone)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 310),
                child: AspectRatio(
                  aspectRatio: 310 / 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: NightPalette.bgPanel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: NightPalette.jadeShield.withValues(alpha: 0.5),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (ctx, box) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // 경맥 수련도 원화(night_meridian.webp) 은은한 배경 도해
                            Opacity(
                              opacity: 0.24,
                              child: Image.asset(
                                NightArtRegistry.nightMeridian,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            // 기맥 연결 선 표시
                            CustomPaint(
                              size: Size(box.maxWidth, box.maxHeight),
                              painter: _MeridianLinePainter(
                                coords: currentSpec.acupointCoords,
                                litSet: _litAcupoints,
                              ),
                            ),
                            // 혈자리 구슬 버튼들
                            for (int i = 0;
                                i < currentSpec.acupointCoords.length;
                                i++)
                              Positioned(
                                left: currentSpec.acupointCoords[i].x *
                                        box.maxWidth -
                                    28,
                                top: currentSpec.acupointCoords[i].y *
                                        box.maxHeight -
                                    28,
                                child: GestureDetector(
                                  onTap: enoughNaegong
                                      ? () => _tapAcupoint(i, currentSpec)
                                      : null,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _litAcupoints.contains(i)
                                          ? NightPalette.accentGold
                                          : (enoughNaegong
                                              ? const Color(0xFF00B4D8)
                                              : Colors.grey.shade800),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        if (enoughNaegong)
                                          BoxShadow(
                                            color: NightPalette.accentGold
                                                .withValues(alpha: 0.6),
                                            blurRadius: 12,
                                          ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${i + 1}\n${currentSpec.acupointNames[i]}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _litAcupoints.contains(i)
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            '개통 완료 경맥 목록',
            style: TextStyle(color: NightPalette.textMuted),
          ),
          const SizedBox(height: 6),
          ...MeridianStepSpec.steps.map((s) {
            final cleared = p.openedMeridianStep >= s.stepNumber;
            return ListTile(
              dense: true,
              leading: Icon(
                cleared
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: cleared ? NightPalette.jadeGreen : NightPalette.textMuted,
              ),
              title: Text('수련 ${s.stepNumber}/10 · ${s.name}'),
              subtitle: Text(s.effectSummary),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCoreStatTab(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: CoreStatType.values.map((stat) {
        final lv = p.coreStatLevels[stat] ?? 0;
        final cost = p.coreStatUpgradeCost(stat);
        final canBuy = p.trainingSeals >= cost;
        final statIcon = switch (stat.index % 4) {
          0 => NightArtRegistry.fxCritical,
          1 => NightArtRegistry.fxBarrier,
          2 => NightArtRegistry.fxQi,
          _ => NightArtRegistry.nightSerendipity,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MurimCard(
            child: Row(
              children: [
                NightSpriteIcon(
                  assetPath: statIcon,
                  fallbackIcon: Icons.fitness_center_rounded,
                  size: 44,
                  showFrame: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stat.label} (현재 $lv단)',
                        style: const TextStyle(
                          fontSize: 16.5,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: NightPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed:
                      canBuy ? () => widget.controller.upgradeCoreStat(stat) : null,
                  child: Text('인장 $cost 단련'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MeridianLinePainter extends CustomPainter {
  _MeridianLinePainter({required this.coords, required this.litSet});
  final List<Vec2> coords;
  final Set<int> litSet;

  @override
  void paint(Canvas canvas, Size size) {
    if (coords.length < 2) return;
    for (int i = 0; i + 1 < coords.length; i++) {
      final p1 = Offset(coords[i].x * size.width, coords[i].y * size.height);
      final p2 =
          Offset(coords[i + 1].x * size.width, coords[i + 1].y * size.height);
      final bothLit = litSet.contains(i) && litSet.contains(i + 1);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = bothLit ? NightPalette.accentGold : const Color(0x554CC9F0)
          ..strokeWidth = bothLit ? 4.5 : 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeridianLinePainter oldDelegate) => true;
}
