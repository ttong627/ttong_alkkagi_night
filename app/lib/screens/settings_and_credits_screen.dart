import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/night_haptics.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'codex_and_endless_screens.dart';
import 'splash_and_tutorial.dart';

/// 환경 설정 · 음향/진동 · 오프라인 백업 이전 · 만든 이 · 독자용 공개 제작노트 열람 화면.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final GameController controller;

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final code = controller.exportBackupCode();
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NightPalette.bgPanel,
        title: const Text(
          '📦 오프라인 백업 부호 복사 완료',
          style: TextStyle(color: NightPalette.accentGold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '클립보드에 백업 부호가 복사되었습니다. 메모장이나 나와의 대화방에 보관해 두시면 '
                '새 휴대전화에서도 서버 연결 없이 그대로 이어서 플레이할 수 있습니다.',
                style: TextStyle(fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NightPalette.bgDeep,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NightPalette.borderGold),
                ),
                child: SelectableText(
                  code,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 11.5, color: NightPalette.jadeGreen),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final inputCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NightPalette.bgPanel,
        title: const Text(
          '📥 백업 부호로 진행도 복원',
          style: TextStyle(color: NightPalette.accentGold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보관해 둔 SUHO1:... 백업 부호를 붙여넣으세요. 위변조 검증 합산값이 일치할 때만 안전하게 복원됩니다.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('import_backup_textfield'),
              controller: inputCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'SUHO1:XXXXXXXX:...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('confirm_import_backup_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: NightPalette.accentGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final ok = controller.importBackupCode(inputCtrl.text);
              Navigator.of(ctx).pop();
              if (ok) {
                _toast(context, '✅ 백업 진행도가 완벽하게 복원되었습니다!');
              } else {
                _toast(context, '⚠️ 백업 부호 형식이 올바르지 않거나 손상되었습니다.');
              }
            },
            child: const Text('복원 실행'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCrashDiagDialog(BuildContext context) async {
    final report = await NightHaptics.instance.fetchLastCrashReport();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NightPalette.bgPanel,
        title: const Text(
          '🩺 단말기 구동 상태 진단 기록',
          style: TextStyle(color: NightPalette.jadeGreen, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            report,
            style: const TextStyle(fontSize: 12.5, height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) _toast(context, '진단 기록을 클립보드에 복사했습니다.');
            },
            child: const Text('복사'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        return Scaffold(
          appBar: AppBar(title: const Text('환경 설정 · 백업 · 정보')),
          body: NightSceneBackdrop(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. 음향 및 진동 설정
                MurimCard(
                  borderColor: NightPalette.accentGold,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: NightArtRegistry.iconSettings,
                            fallbackIcon: Icons.tune_rounded,
                            size: 36,
                            showFrame: true,
                            frameColor: NightPalette.accentGold,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '🎵 3층 국악 음향 및 손맛 진동 설정',
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 18,
                                color: NightPalette.accentGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const SizedBox(width: 88, child: Text('배경음악')),
                          Expanded(
                            child: Slider(
                              value: p.bgmVolume,
                              onChanged: controller.setBgmVolume,
                              activeColor: NightPalette.accentGold,
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${(p.bgmVolume * 100).round()}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 88, child: Text('효과음·모션음')),
                          Expanded(
                            child: Slider(
                              value: p.sfxVolume,
                              onChanged: controller.setSfxVolume,
                              activeColor: NightPalette.jadeGreen,
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${(p.sfxVolume * 100).round()}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('타격·출두 손맛 진동'),
                        subtitle: const Text('회심 박살, 절벽 뽀록, 무림수호단 출두 시 진동 전달'),
                        value: p.vibrationEnabled,
                        onChanged: (v) => controller.setVibration(enabled: v),
                      ),
                      if (p.vibrationEnabled)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('진동 세기:', style: TextStyle(fontSize: 13)),
                            ...[
                              (1, '약하게'),
                              (2, '보통(권장)'),
                              (3, '강하게'),
                            ].map((pair) {
                              return ChoiceChip(
                                selected: p.vibrationStrength == pair.$1,
                                label: Text(pair.$2),
                                onSelected: (_) => controller.setVibration(strength: pair.$1),
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. 오프라인 기기 이전 백업
                MurimCard(
                  borderColor: NightPalette.jadeShield,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📦 오프라인 진행도 백업 · 기기 이전',
                        style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 18,
                          color: NightPalette.jadeShield,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '회원가입이나 외부 서버 전송 없이 내 단말기 안에서 모든 기록이 저장됩니다. '
                        '기기를 바꾸실 때는 아래 백업 부호를 복사해 옮기실 수 있습니다.',
                        style: TextStyle(fontSize: 13, color: NightPalette.textMuted, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            key: const Key('export_backup_btn'),
                            onPressed: () => _showExportDialog(context),
                            icon: const Icon(Icons.copy_all_rounded, size: 18),
                            label: const Text('백업 부호 복사하기'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('open_import_backup_btn'),
                            onPressed: () => _showImportDialog(context),
                            icon: const Icon(Icons.restore_rounded, size: 18),
                            label: const Text('백업 부호 붙여넣어 복원'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. 교범 · 투명성 · 제작노트 · 만든 이
                MurimCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: NightSpriteIcon(
                          assetPath: NightArtRegistry.charFace('sabu'),
                          fallbackIcon: Icons.school_rounded,
                          size: 36,
                          borderRadius: 18,
                          fit: BoxFit.cover,
                        ),
                        title: const Text('입문 수호 교범 다시 보기'),
                        subtitle: const Text('자동 발사 진법 · 증표와 영약 · 출두 지원패 4단계 안내'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showTutorialGuideDialog(context, controller),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const NightSpriteIcon(
                          assetPath: NightArtRegistry.iconOdds,
                          fallbackIcon: Icons.fact_check_rounded,
                          size: 34,
                        ),
                        title: const Text('확률 및 물리 수치 100% 공개'),
                        subtitle: const Text('유료 상자 없음 · 절벽 뽀록 35% 및 기연 확률 전수 공개'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OddsScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('open_prod_note_btn'),
                        contentPadding: EdgeInsets.zero,
                        leading: const NightSpriteIcon(
                          assetPath: NightArtRegistry.iconCodex,
                          fallbackIcon: Icons.menu_book_rounded,
                          size: 34,
                        ),
                        title: const Text('독자용 공개 제작노트 및 검증 성적표'),
                        subtitle: const Text('전 10장(111단계) 순수 자동 구성 통과 기록 및 제작 내역'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProductionNoteScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.monitor_heart_rounded, color: Colors.orangeAccent),
                        title: const Text('단말기 비정상 종료 진단 기록 확인'),
                        subtitle: const Text('외부 전송 없이 내 휴대전화 상태 기록만 열람'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showCrashDiagDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('open_credits_btn'),
                        contentPadding: EdgeInsets.zero,
                        leading: const NightSpriteIcon(
                          assetPath: NightArtRegistry.appLogo,
                          fallbackIcon: Icons.verified_user_rounded,
                          size: 34,
                        ),
                        title: const Text('만든 이 · 개인정보처리방침 · 라이선스'),
                        subtitle: const Text('(주)웰쉐어로지스 · 광고·결제·개인정보 수집 없음'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreditsScreen()),
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

/// 만든 이((주)웰쉐어로지스 로고 포함) · 개인정보처리방침 · 오픈소스 라이선스 고지 화면.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('만든 이 · 개인정보 보호 · 저작권')),
      body: NightSceneBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MurimCard(
              borderColor: NightPalette.accentGold,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      const NightSpriteIcon(
                        assetPath: NightArtRegistry.appLogo,
                        fallbackIcon: Icons.shield_moon_rounded,
                        size: 64,
                        borderRadius: 14,
                        showFrame: true,
                        frameColor: NightPalette.accentGold,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Image.asset(
                            NightArtRegistry.wslogisLogo,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.apartment_rounded,
                              color: Colors.black87,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '수호알까기 · 탄지무림 심야기습',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 22,
                      color: NightPalette.accentGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '기획 · 제작 · 발행: (주)웰쉐어로지스 (TTong Studio)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: NightPalette.jadeGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '누구나 손목이나 손가락 부담 없이 느긋하게 진법을 짜고, '
                    '통쾌한 수호 알 도탄과 「무림수호단 출두야~~!!」의 카타르시스를 즐길 수 있도록 정성껏 빚었습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const MurimCard(
              borderColor: NightPalette.jadeGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔒 개인정보처리방침 핵심 요약 (수집 0건)',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 17,
                      color: NightPalette.jadeGreen,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• 개인정보 수집·전송 없음: 본 게임은 이름, 전화번호, 이메일, 위치, 단말 식별자 등 어떠한 개인정보도 수집하거나 외부 서버로 보내지 않습니다.\n'
                    '• 오프라인 단독 구동: 구글 플레이 배포판은 인터넷 연결 권한(INTERNET)조차 요구하지 않으며 비행기 모드에서도 100% 동일하게 작동합니다.\n'
                    '• 광고·결제 없음: 제3자 광고 추적 도구나 인앱 유료 결제가 일절 포함되어 있지 않습니다.\n'
                    '• 데이터 삭제: 기기 설정에서 앱 데이터를 지우거나 앱을 삭제하면 저장된 진행 기록이 즉시 완전히 파기됩니다.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            MurimCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎨 글꼴 · 음향 · 그림 자산 출처 고지',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 17,
                      color: NightPalette.accentGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '• 한글 글꼴: 검은고딕(Black Han Sans, ZESSTYPE) 및 고운바탕(Gowun Batang, 양희재) — SIL 오픈 폰트 라이선스 1.1 준수.\n'
                    '• 음향 자산: 탄지무림 세계관 정본 국악 배경음 계승 및 심야기습 전용 자체 파형 합성 효과음·출두 풍악 10종 수록.\n'
                    '• 시각 자산: 통통 스튜디오 코덱스 수묵 무협 원화(배경·변이체·발사대·수호석·비약·이펙트) 및 실시간 60프레임 물리 캔버스 합성 엔진.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showLicensePage(
                          context: context,
                          applicationName: '수호알까기 · 탄지무림 심야기습',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2026 (주)웰쉐어로지스 (TTong Studio)',
                        );
                      },
                      icon: const Icon(Icons.description_rounded, size: 18),
                      label: const Text('오픈소스 소프트웨어 라이선스 전문 보기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 독자용 공개 제작노트 및 111단계 자동 검증 성적표 열람 화면 (`production-provenance.md` 준수).
class ProductionNoteScreen extends StatelessWidget {
  const ProductionNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('독자용 공개 제작노트 · 검증 기록')),
      body: NightSceneBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            MurimCard(
              borderColor: NightPalette.accentGold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NightSpriteIcon(
                        assetPath: NightArtRegistry.appLogo,
                        fallbackIcon: Icons.shield_moon_rounded,
                        size: 38,
                        showFrame: true,
                        frameColor: NightPalette.accentGold,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '📜 왜 《수호알까기 · 탄지무림 심야기습》을 만들었나요?',
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 18,
                            color: NightPalette.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '원작 《알까기 · 탄지무림》의 정겨운 세계관과 10장 서사는 그대로 잇되, '
                    '직접 손가락으로 수백 번 돌을 튕기기 힘든 분들도 전략적인 구성 조정만으로 '
                    '끝까지 완주할 수 있는 「완전 자동 발사 마을 수호전」을 목표로 설계했습니다.',
                    style: TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            MurimCard(
              borderColor: NightPalette.jadeGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ 전 10장(111단계) 순수 자동 구성 검증 성적표',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 18,
                      color: NightPalette.jadeGreen,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• 검증 조건: 무개입 방치(초소 0곳·수동 0발) 전패 검증 + 1~10장(111단계)·무한 혈전 15물결 전 기능 완주 검증\n'
                    '• 무개입 방치 클리어 원천 차단: 가장 쉬운 1-1 쉬움 포함 전 111단계 방치 승리 0 / 111건 (0.0% 전패 완벽 입증)\n'
                    '• 1~4배속 미세 분할 물리 & 0초 무정지 전투: 탄알 관통 오차 없는 1~4배속 가속 + 6.5초 비급·4.8초 초소 띠 미클릭 자동 패스\n'
                    '• 내공 최고 경지 [생사경] & 전 능력 완주 입증: 10회 연속 단전 운기·전투 내공 수급·십대 경맥 10단·수호석 13종·영수 5종(만렙)·동료 14인·도감 49종·업적 12종 전수 달성\n'
                    '• 구곡양장 아홉 굽이길 & 전술 사거리 차등화: 전 10장 침공 경로 2.1배 연장(1,250px 이상) + 발사대별 제한된 사거리(108~162)·비거리 소멸 물리\n'
                    '• 실시간 군수 강화 4종 & 마기 포효·땅굴 기습: [⚔️화력·⚡연사·🔭사거리·🛡️결계] 즉시 강화 + ★5형 신기 합체 + 🕳️땅굴·🌲월담·대수괴 포효!',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            MurimCard(
              borderColor: NightPalette.jadeShield,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🛠️ 제작 설계 4대 핵심 원칙 및 투명 공개',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 18,
                      color: NightPalette.jadeShield,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. 실패 없는 기명 심법 수련: 까다로운 각도 튕기기 시험을 없애고 단전 호흡과 십대 경맥 점등만으로 누구나 100% 내공을 쌓습니다.\n'
                    '2. 증표와 영약 이원화 성장: 변이체가 떨어뜨리는 「증표」는 기계 장치(수호탑·발사대) 강화에, 「영약」은 생명체(영수·동료·내공) 강화에 명확히 분리했습니다.\n'
                    '3. 지원패 3대 수급과 출두 역전극: 물자 호송·심야 탐색·보름달 길조로 지원패를 모아 위기 순간 「무림수호단 출두야~~!!」로 전세를 뒤집습니다.\n'
                    '4. 직접 초소 배치 · 5대 도파민 전술 시스템 · 제작 도구 투명 공개: 북쪽 굽이길 빈 초소(2→10곳)에 군수기력(⚡)으로 발사대를 건설·합치기 진화하고, 물결마다 3택1 비급과 ×2 복제 핀볼 기물로 탄막을 완성합니다. 변이체·성채·전장 기물·비급 총 101종 원화는 코덱스로 제작하고 연속 곡선 생체역학 모션 코드로 완성했습니다.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
