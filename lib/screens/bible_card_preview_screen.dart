import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../models/bible_card_layout.dart';
import '../models/bible_card_theme.dart';
import '../widgets/multi_layout_bible_card.dart';
import '../services/interstitial_ad_manager.dart';

class BibleCardPreviewScreen extends StatefulWidget {
  final String verse;
  final String reference;
  final bool skipAds;
  final String shareTitle; // 공유 시 사용할 제목 (기본: "성경 말씀")
  final String screenTitle; // AppBar 제목 (기본: "성경 말씀 카드 미리보기")

  const BibleCardPreviewScreen({
    super.key,
    required this.verse,
    required this.reference,
    this.skipAds = false,
    this.shareTitle = '성경 말씀',
    this.screenTitle = '성경 말씀 카드 미리보기',
  });

  @override
  State<BibleCardPreviewScreen> createState() => _BibleCardPreviewScreenState();
}

class _BibleCardPreviewScreenState extends State<BibleCardPreviewScreen> {
  final GlobalKey _previewKey = GlobalKey();
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();

  int _currentIndex = 0;
  CardLayoutType selectedLayout = CardLayoutType.minimal;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _interstitialAdManager.loadAd();
  }

  @override
  void dispose() {
    _interstitialAdManager.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLayoutIndex = prefs.getInt('selectedLayoutIndex') ?? 0;
    setState(() {
      if (savedLayoutIndex >= 0 &&
          savedLayoutIndex < CardLayoutType.values.length) {
        selectedLayout = CardLayoutType.values[savedLayoutIndex];
        _currentIndex = savedLayoutIndex;
      } else {
        selectedLayout = CardLayoutType.minimal;
        _currentIndex = 0;
      }
    });
  }

  Future<void> _saveToGallery() async {
    // skipAds가 false일 때만 전면광고 표시
    if (!widget.skipAds) {
      await _interstitialAdManager.showAd();
    }

    _showLoadingDialog('이미지 생성 중...');

    final file = await _exportToTempFile();

    if (mounted) Navigator.of(context).pop();

    if (file == null) return;

    try {
      await Gal.putImage(file.path);
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

  Future<void> _shareCard() async {
    // skipAds가 false일 때만 전면광고 표시
    if (!widget.skipAds) {
      await _interstitialAdManager.showAd();
    }

    _showLoadingDialog('이미지 생성 중...');

    final file = await _exportToTempFile();

    if (mounted) Navigator.of(context).pop();

    if (file == null) return;

    const appStoreLink =
        'https://apps.apple.com/us/app/%EC%98%AC%EC%9D%B8%EB%B0%94%EC%9D%B4%EB%B8%94-all-in-bible/id6754250799';
    const playStoreLink =
        'https://play.google.com/store/apps/details?id=easy.bible.app.easy_bible_app';

    final isIOS = Platform.isIOS;
    final appLink = isIOS ? appStoreLink : playStoreLink;
    final storeName = isIOS ? 'App Store' : 'Play 스토어';

    final shareMessage = '''
${widget.shareTitle}을 공유합니다 📖✨

올인바이블(All in Bible) 앱에서 매일 새로운 말씀을 받아보세요!

📱 $storeName에서 다운로드:
$appLink''';

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${widget.shareTitle} - 올인바이블(All in Bible)',
      text: shareMessage,
    );
  }

  Future<File?> _exportToTempFile() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final ctx = _previewKey.currentContext;
      if (ctx == null) {
        if (mounted) _showErrorDialog('렌더 준비 중 문제가 발생했습니다.');
        return null;
      }

      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) _showErrorDialog('렌더링 객체를 찾을 수 없습니다.');
        return null;
      }

      if (!boundary.hasSize || boundary.size.isEmpty) {
        if (mounted) _showErrorDialog('위젯 크기가 올바르지 않습니다.');
        return null;
      }

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

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
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
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
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
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
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

  void _previousLayout() {
    _carouselController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextLayout() {
    _carouselController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) async {
    setState(() {
      _currentIndex = index;
      selectedLayout = CardLayoutType.values[index];
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedLayoutIndex', index);
  }

  @override
  Widget build(BuildContext context) {
    const exportSize = Size(1080, 1350);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight =
        AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // 버튼 높이(16*2 padding + 약간의 여유) + 하단 패딩(40) + bottom safe area
    final buttonAreaHeight = 32 + 40 + bottomPadding + 20;
    final availableHeight = screenHeight - appBarHeight - buttonAreaHeight;
    final layoutName = BibleCardLayout.layouts
        .firstWhere((l) => l.type == selectedLayout)
        .name;

    return Scaffold(
      // verse_list_view처럼 연한 회색 배경 적용
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('성경 구절 카드 미리보기'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 카드 캐러셀
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 캐러셀 슬라이더
                    CarouselSlider.builder(
                      carouselController: _carouselController,
                      itemCount: CardLayoutType.values.length,
                      itemBuilder: (context, index, realIndex) {
                        final layoutType = CardLayoutType.values[index];
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: RepaintBoundary(
                              key: _currentIndex == index ? _previewKey : null,
                              child: AspectRatio(
                                aspectRatio:
                                    exportSize.width / exportSize.height,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: availableHeight,
                                    maxWidth: screenWidth - 40,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: SizedBox(
                                      width: exportSize.width,
                                      height: exportSize.height,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: MultiLayoutBibleCard(
                                            verse: widget.verse,
                                            reference: widget.reference,
                                            layoutType: layoutType,
                                            theme: BibleCardTheme.presets[0],
                                            shareTitle: widget.shareTitle),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: availableHeight,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: true,
                        initialPage: _currentIndex,
                        onPageChanged: (index, reason) => _onPageChanged(index),
                        scrollPhysics: const BouncingScrollPhysics(),
                      ),
                    ),

                    // 왼쪽 화살표
                    Positioned(
                      left: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _previousLayout,
                          icon: const Icon(Icons.chevron_left, size: 36),
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),

                    // 오른쪽 화살표
                    Positioned(
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _nextLayout,
                          icon: const Icon(Icons.chevron_right, size: 36),
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 페이지 인디케이터
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: CardLayoutType.values.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // 하단 버튼들
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveToGallery,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('저장'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareCard,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('공유'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
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
