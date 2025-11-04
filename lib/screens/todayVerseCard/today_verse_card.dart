import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // ← RenderRepaintBoundary 타입
import 'package:gal/gal.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';

import '../../models/bible_card_theme.dart';
import '../../models/today_verse_model.dart';
import '../../services/rewarded_ad_manager.dart';
import '../../widgets/beautiful_bible_card.dart';

class TodayVerseCard extends StatefulWidget {
  const TodayVerseCard({super.key});

  @override
  State<TodayVerseCard> createState() => _TodayVerseCardState();
}

class _TodayVerseCardState extends State<TodayVerseCard>
    with TickerProviderStateMixin {
  String? verse;
  String? ref;
  int? pendingIdx;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _sizeCtrl;
  late AnimationController _shineCtrl;

  final ScreenshotController _screenshotController = ScreenshotController();
  final RewardedAdManager _adManager = RewardedAdManager();
  bool _hasWatchedAdForCurrentVerse = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 270),
    )..value = 1.0;
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _sizeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadTodayVerse();
    _adManager.loadAd();
  }

  Future<void> _loadTodayVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastPickDate = prefs.getString('lastVerseDate');
    final verseIdx = prefs.getInt('todayVerseIdx');

    if (lastPickDate == '${today.year}-${today.month}-${today.day}' &&
        verseIdx != null) {
      setState(() {
        verse = todayVerses[verseIdx].text;
        ref = todayVerses[verseIdx].ref;
      });
    } else {
      setState(() {
        verse = null;
        ref = null;
      });
    }
  }

  Future<void> _pickVerse() async {
    final idx = Random().nextInt(todayVerses.length);
    setState(() {
      pendingIdx = idx;
    });

    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierLabel: "오늘의 구절",
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: 0.97 + curved.value * 0.03,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/lottie/pray.json',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "오늘의 구절",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 21,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.93),
                            ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 13),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          todayVerses[idx].ref,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 15.2,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'ChosunCentennial',
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        todayVerses[idx].text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16.7,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'ChosunCentennial',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.98),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _fadeCtrl.reverse();
                            final prefs = await SharedPreferences.getInstance();
                            final today = DateTime.now();
                            await prefs.setString('lastVerseDate',
                                '${today.year}-${today.month}-${today.day}');
                            await prefs.setInt('todayVerseIdx', idx);
                            setState(() {
                              verse = todayVerses[idx].text;
                              ref = todayVerses[idx].ref;
                              pendingIdx = null;
                              _hasWatchedAdForCurrentVerse = false; // 새 말씀을 받으면 광고 시청 상태 초기화
                            });
                            await _fadeCtrl.forward();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 11, horizontal: 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              const Text('확인', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _resetVerse() async {
    await _fadeCtrl.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('todayVerseIdx');
    await prefs.remove('lastVerseDate');
    setState(() {
      verse = null;
      ref = null;
      _hasWatchedAdForCurrentVerse = false;
    });
    await _fadeCtrl.forward();
  }

  Future<void> _handleShareButton() async {
    // 이미 광고를 본 경우 바로 미리보기 열기
    if (_hasWatchedAdForCurrentVerse) {
      if (!mounted) return;
      debugPrint('✅ 광고 이미 시청함 - 바로 미리보기 열기');
      await _openPreviewSaveShareDialog();
      return;
    }

    debugPrint('🎬 광고 시청 필요 - 광고 로드 상태: ${_adManager.isAdLoaded}');

    // 광고가 로드되지 않았으면 로딩 팝업 표시하며 기다림
    if (!_adManager.isAdLoaded) {
      _showAdLoadingDialog();

      // 광고 로드 시도 (최대 10초 대기)
      final loadStartTime = DateTime.now();
      while (!_adManager.isAdLoaded &&
          DateTime.now().difference(loadStartTime).inSeconds < 10) {
        await _adManager.loadAd();
        if (!_adManager.isAdLoaded) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (mounted) Navigator.of(context).pop();

      // 10초 후에도 로드 실패시 에러 표시
      if (!_adManager.isAdLoaded) {
        debugPrint('❌ 광고 로드 실패');
        if (mounted) _showErrorDialog('광고를 불러올 수 없습니다.\n잠시 후 다시 시도해주세요.');
        return;
      }
    }

    debugPrint('📺 광고 표시 시작');
    final rewarded = await _adManager.showAd();
    debugPrint('🎁 광고 시청 완료: $rewarded');

    if (rewarded) {
      if (!mounted) return;
      setState(() => _hasWatchedAdForCurrentVerse = true);

      // 말씀카드 생성중 다이얼로그 표시
      debugPrint('🎨 말씀카드 생성중 다이얼로그 표시');
      _showCardGeneratingDialog();
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;
      debugPrint('✅ 로딩 다이얼로그 닫기');
      Navigator.of(context).pop(); // 로딩 닫기

      // 다이얼로그가 완전히 닫힐 때까지 충분히 대기
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      debugPrint('🖼️ 미리보기 다이얼로그 열기');
      await _openPreviewSaveShareDialog();
      debugPrint('✅ 미리보기 다이얼로그 열림');
    } else {
      debugPrint('⚠️ 광고 시청 실패 또는 취소됨');
    }
  }

  void _showAdLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/loading.json',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                repeat: true,
              ),
              const SizedBox(height: 16),
              Text(
                '로딩 중',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardGeneratingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/loading.json',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                repeat: true,
              ),
              const SizedBox(height: 16),
              Text(
                '말씀카드 생성중',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: message,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // 1.5초 후 자동으로 닫기
    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (e) {
        debugPrint('⚠️ 저장 완료 다이얼로그 닫기 오류: $e');
      }
    });
  }

  /// ====== 미리보기/색상/저장/공유 통합 팝업 (미리보기 == 내보내기) ======
  Future<void> _openPreviewSaveShareDialog() async {
    if (verse == null || ref == null) {
      debugPrint('⚠️ verse 또는 ref가 null');
      return;
    }
    if (!mounted) {
      debugPrint('⚠️ Widget이 mounted 상태가 아님');
      return;
    }

    debugPrint('🎨 미리보기 다이얼로그 준비 중...');

    const Size exportSize = Size(1080, 1350);
    final GlobalKey previewKey = GlobalKey();
    int selectedThemeIndex = 0;
    bool useWhiteText = true; // 텍스트 색상 토글 (true: 흰색, false: 검정)

    // 짧은 딜레이로 이전 다이얼로그가 완전히 닫힐 때까지 대기
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) {
      debugPrint('⚠️ 대기 후 Widget이 mounted 상태가 아님');
      return;
    }

    debugPrint('📱 showGeneralDialog 호출');

    try {
      await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "오늘의 말씀 카드",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
            child: StatefulBuilder(builder: (context, setStateSB) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Text('오늘의 말씀 카드',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        // 텍스트 색상 토글 버튼
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setStateSB(() {
                                  useWhiteText = true;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: useWhiteText
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.brightness_5,
                                    size: 18,
                                    color: useWhiteText
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setStateSB(() {
                                  useWhiteText = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !useWhiteText
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.brightness_2,
                                    size: 18,
                                    color: !useWhiteText
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 360,
                          minHeight: 200,
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: RepaintBoundary(
                            key: previewKey,
                            child: SizedBox(
                              width: exportSize.width,
                              height: exportSize.height,
                              child: Material(
                                color: Colors.transparent,
                                child: BeautifulBibleCard(
                                  verse: verse!,
                                  reference: ref!,
                                  theme: BibleCardTheme
                                      .presets[selectedThemeIndex],
                                  forceWhiteText: useWhiteText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: BibleCardTheme.presets.length,
                      itemBuilder: (context, index) {
                        final th = BibleCardTheme.presets[index];
                        final isSelected = selectedThemeIndex == index;
                        return GestureDetector(
                          onTap: () => setStateSB(() {
                            selectedThemeIndex = index;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: isSelected ? 54 : 48,
                            height: isSelected ? 54 : 48,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: th.gradientColors,
                                stops: th.gradientStops,
                              ),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 24)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      children: [
                        Row(
                          children: {
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // 로딩 표시
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Lottie.asset(
                                              'assets/lottie/loading.json',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.contain,
                                              repeat: true,
                                            ),
                                            const SizedBox(height: 16),
                                            Text('이미지 생성 중...',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  final file = await _exportPreviewToTempFile(
                                      previewKey, exportSize);

                                  if (context.mounted) {
                                    Navigator.of(context).pop(); // 로딩 닫기
                                  }

                                  if (file == null) return;

                                  if (context.mounted) {
                                    Navigator.of(context).pop(); // 미리보기 팝업 닫기
                                    await _saveToGallery(file);
                                  }
                                },
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('저장'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Builder(
                                builder: (btnContext) => ElevatedButton.icon(
                                  onPressed: () async {
                                    // 로딩 표시
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Lottie.asset(
                                                'assets/lottie/loading.json',
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.contain,
                                                repeat: true,
                                              ),
                                              const SizedBox(height: 16),
                                              Text('이미지 생성 중...',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );

                                    final file = await _exportPreviewToTempFile(
                                        previewKey, exportSize);

                                    if (context.mounted) {
                                      Navigator.of(context).pop(); // 로딩 닫기
                                    }

                                    if (file == null) return;

                                    final box = btnContext.findRenderObject()
                                        as RenderBox?;
                                    await Share.shareXFiles(
                                      [XFile(file.path)],
                                      sharePositionOrigin: box != null
                                          ? box.localToGlobal(Offset.zero) &
                                              box.size
                                          : null,
                                    );
                                  },
                                  icon: const Icon(Icons.share_rounded),
                                  label: const Text('공유'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                          }.toList(),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
              );
            }),
          ),
        );
      },
    );
    } catch (e, stackTrace) {
      debugPrint('❌ 미리보기 다이얼로그 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (mounted) {
        _showErrorDialog('미리보기를 여는 중 오류가 발생했습니다.');
      }
    }
  }

  /// ───────── 핵심 수정: 안전하게 Boundary를 얻고, 페인트 완료까지 기다린 뒤 캡처 ─────────
  Future<File?> _exportPreviewToTempFile(
      GlobalKey previewKey, Size exportSize) async {
    try {
      // 렌더링 완료 대기
      await Future.delayed(const Duration(milliseconds: 300));

      final ctx = previewKey.currentContext;
      if (ctx == null) {
        if (mounted) _showErrorDialog('렌더 준비 중 문제가 발생했습니다.');
        return null;
      }

      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) _showErrorDialog('렌더링 객체를 찾을 수 없습니다.');
        return null;
      }

      // 크기 체크
      if (!boundary.hasSize || boundary.size.isEmpty) {
        if (mounted) _showErrorDialog('위젯 크기가 올바르지 않습니다.');
        return null;
      }

      // 이미지 캡처
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) _showErrorDialog('이미지 변환 중 오류가 발생했습니다.');
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/bible_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      return file;
    } catch (e, stackTrace) {
      debugPrint('❌ 이미지 생성 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (mounted) _showErrorDialog('이미지를 생성하는 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// 갤러리에 저장
  Future<void> _saveToGallery(File imageFile) async {
    try {
      // gal 패키지가 자동으로 권한을 처리하므로 별도 권한 요청 불필요
      // Android 10 이하: WRITE_EXTERNAL_STORAGE 권한 자동 요청
      // Android 11+: Scoped Storage로 자동 처리
      // iOS: NSPhotoLibraryAddUsageDescription 권한 자동 요청
      await Gal.putImage(imageFile.path);

      if (mounted) {
        _showSuccessDialog('저장 완료');
      }
    } catch (e) {
      debugPrint('❌ 갤러리 저장 오류: $e');
      if (mounted) {
        _showErrorDialog('이미지를 저장하는 중 오류가 발생했습니다.\n설정에서 사진 라이브러리 권한을 허용해주세요.');
      }
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _sizeCtrl.dispose();
    _shineCtrl.dispose();
    _adManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: cs.surface,
              child: Stack(
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: verse == null
                          ? _TodayVerseEmptyCard(onTap: _pickVerse)
                          : _TodayVerseShowCard(ref: ref, verse: verse),
                    ),
                  ),
                  if (verse != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: Icon(Icons.refresh_rounded, color: cs.primary),
                        tooltip: '오늘의 구절 다시 뽑기',
                        onPressed: _resetVerse,
                        splashRadius: 22,
                      ),
                    ),
                  if (verse != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: IconButton(
                        icon: Icon(Icons.share_rounded, color: cs.primary),
                        tooltip: '성경 카드 공유하기',
                        onPressed: _handleShareButton,
                        splashRadius: 22,
                      ),
                    ),
                ],
              ),
            ),
            if (verse != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _shineCtrl,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _SimpleGlowPainter(
                              progress: _shineCtrl.value,
                              primaryColor: cs.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 오늘의 구절 뽑기 카드
class _TodayVerseEmptyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayVerseEmptyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        key: const ValueKey("pick"),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.035),
              cs.surface.withValues(alpha: 0.98)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.43),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: 3.0,
                  child: Lottie.asset(
                    'assets/lottie/loading.json',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '오늘의 구절 뽑기',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.2,
                  color: cs.primary),
            ),
            const SizedBox(height: 7),
            Text(
              '하루에 한 번, 하나님이 주시는 말씀을 받아보세요!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.75)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 오늘의 구절 보여주는 카드
class _TodayVerseShowCard extends StatelessWidget {
  final String? ref;
  final String? verse;
  const _TodayVerseShowCard({this.ref, this.verse});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey("verse"),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 11),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                ref ?? "",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ChosunCentennial',
                    ),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              verse ?? "",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'ChosunCentennial',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    height: 1.7,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 13),
            Text(
              '내일이 되면 새롭게 받을 수 있어요!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// 은은한 빛 효과 Painter
class _SimpleGlowPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _SimpleGlowPainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final offset = size.width * 1.5 * progress - size.width * 0.4;

    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        primaryColor.withValues(alpha: 0.03),
        primaryColor.withValues(alpha: 0.06),
        primaryColor.withValues(alpha: 0.12),
        primaryColor.withValues(alpha: 0.13),
        primaryColor.withValues(alpha: 0.12),
        primaryColor.withValues(alpha: 0.06),
        primaryColor.withValues(alpha: 0.03),
        Colors.transparent,
      ],
      stops: const [0.0, 0.1, 0.2, 0.35, 0.4, 0.5, 0.65, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(offset - 100, 0, 200, size.height),
      )
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SimpleGlowPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primaryColor != primaryColor;
}
