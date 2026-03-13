import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../models/favorite_verse.dart';
import '../../models/highlight_verse.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/highlight_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/font_size_provider.dart';
import '../../services/bible_subtitle_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/breadcrumb_bar.dart';
import '../bible_card_preview_screen.dart';

class VerseListView extends StatefulWidget {
  final BibleData book;
  final int chapter;
  final Map<int, String> verses;
  final int selectedVerse;
  final VoidCallback onBack;
  final void Function(int newChapter)? onChapterChanged;
  final VoidCallback? onGoToChapterSelector;
  final VoidCallback? onGoToVerseSelector;
  final VoidCallback? onGoHome;
  final bool hideLanguageToggle; // 언어 전환 버튼 숨김 여부 (단어 검색으로 들어온 경우)

  const VerseListView({
    super.key,
    required this.book,
    required this.chapter,
    required this.verses,
    required this.selectedVerse,
    required this.onBack,
    this.onChapterChanged,
    this.onGoToChapterSelector,
    this.onGoToVerseSelector,
    this.onGoHome,
    this.hideLanguageToggle = false,
  });

  @override
  State<VerseListView> createState() => _VerseListViewState();
}

class _VerseListViewState extends State<VerseListView>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _itemKey = GlobalKey();

  double? itemHeight;
  late int _selectedVerse;

  int? _rangeStart;
  int? _rangeEnd;
  bool _isSelectionMode = false;

  late AnimationController _animationController;

  late AnimationController _highlightPickerController;
  late AnimationController _highlightAppliedController;

  late AnimationController _languageChangeController;
  late Animation<double> _languageFadeAnimation;
  late Animation<Offset> _languageSlideAnimation;

  // ⭐ 플로팅 액션 바 애니메이션
  late AnimationController _floatingActionBarController;
  late Animation<double> _floatingActionBarScale;
  late Animation<double> _floatingActionBarOpacity;

  @override
  void initState() {
    super.initState();
    _selectedVerse = widget.selectedVerse;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();

    _highlightPickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _highlightAppliedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _languageChangeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _languageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _languageChangeController,
      curve: Curves.easeInOut,
    ));

    _languageSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _languageChangeController,
      curve: Curves.easeOutCubic,
    ));

    _languageChangeController.forward();

    // ⭐ 플로팅 액션 바 애니메이션
    _floatingActionBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _floatingActionBarScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingActionBarController,
      curve: Curves.easeOutBack,
    ));

    _floatingActionBarOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingActionBarController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1));
      _measureItemHeight();
      _scrollToSelectedOnce();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _highlightPickerController.dispose();
    _highlightAppliedController.dispose();
    _languageChangeController.dispose();
    _floatingActionBarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VerseListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.verses != oldWidget.verses &&
        widget.chapter == oldWidget.chapter) {
      _languageChangeController.reset();
      _languageChangeController.forward();
      return;
    }

    if (widget.chapter != oldWidget.chapter) {
      setState(() {
        _selectedVerse = 1;
        _exitSelectionMode();
      });
      _animationController.reset();
      _animationController.forward();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected();
      });
      return;
    }

    if (widget.selectedVerse != oldWidget.selectedVerse) {
      setState(() {
        _selectedVerse = widget.selectedVerse;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected();
      });
    }
  }

  void _scrollToSelectedOnce() {
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedOnce();
      });
      return;
    }

    final verseNums = widget.verses.keys.toList()..sort();
    final selectedIdx = verseNums.indexOf(_selectedVerse);
    if (selectedIdx == -1) return;

    final RenderBox? listBox = context.findRenderObject() as RenderBox?;
    final double viewportHeight = listBox?.size.height ?? 600;
    final int totalVerses = verseNums.length;
    final double maxOffset = _scrollController.position.maxScrollExtent;

    final double ratio = selectedIdx / totalVerses;
    final double estimatedPosition = (maxOffset + viewportHeight) * ratio;
    double targetOffset = estimatedPosition - (viewportHeight * 0.3);

    if (targetOffset < 0) targetOffset = 0;
    if (targetOffset > maxOffset) targetOffset = maxOffset;

    _scrollController.jumpTo(targetOffset);
  }

  void _measureItemHeight() {
    if (itemHeight != null) return;
    final ctx = _itemKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox;
      setState(() {
        itemHeight = box.size.height;
      });
    }
  }

  void _scrollToSelected() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToSelectedOnce();
  }

  void _handleVerseLongPress(int verseNum) {
    HapticFeedback.mediumImpact();

    setState(() {
      _selectedVerse = verseNum;
      _isSelectionMode = true;
      _rangeStart = verseNum;
      _rangeEnd = verseNum;
    });

    // ⭐ 애니메이션 시작
    _floatingActionBarController.forward(from: 0);
  }

  void _handleVerseTap(int verseNum) {
    if (_isSelectionMode) {
      HapticFeedback.lightImpact();
      setState(() {
        // ⭐ 스마트 범위 선택 로직
        // 현재 범위가 있는 경우
        if (_rangeStart != null && _rangeEnd != null) {
          final currentStart =
              _rangeStart! < _rangeEnd! ? _rangeStart! : _rangeEnd!;
          final currentEnd =
              _rangeStart! > _rangeEnd! ? _rangeStart! : _rangeEnd!;

          // 클릭한 절이 현재 범위보다 앞에 있으면 앞으로 확장
          if (verseNum < currentStart) {
            _rangeStart = verseNum;
            _rangeEnd = currentEnd;
          }
          // 클릭한 절이 현재 범위보다 뒤에 있으면 뒤로 확장
          else if (verseNum > currentEnd) {
            _rangeStart = currentStart;
            _rangeEnd = verseNum;
          }
          // 클릭한 절이 범위 내에 있으면 그 절만 선택
          else {
            _rangeStart = verseNum;
            _rangeEnd = verseNum;
          }
        } else {
          // 범위가 없으면 기존 로직
          _rangeEnd = verseNum;
        }
      });
    } else {
      setState(() {
        _selectedVerse = verseNum;
      });
    }
  }

  List<int> _getSelectedVerseRange() {
    if (_rangeStart == null || _rangeEnd == null) return [];
    final start = _rangeStart! < _rangeEnd! ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart! > _rangeEnd! ? _rangeStart! : _rangeEnd!;
    return List.generate(end - start + 1, (i) => start + i);
  }

  String _getSelectedVersesText() {
    final selectedVerses = _getSelectedVerseRange();
    return selectedVerses
        .map((v) => '$v절: ${widget.verses[v] ?? ''}')
        .join('\n');
  }

  String _getVerseReference() {
    final languageProvider = context.read<LanguageProvider>();
    final selectedVerses = _getSelectedVerseRange();
    if (selectedVerses.isEmpty) return '';

    final bookName =
        widget.book.getLocalizedFullName(languageProvider.isKorean);

    if (selectedVerses.length == 1) {
      return '$bookName ${widget.chapter}:${selectedVerses.first}';
    } else {
      return '$bookName ${widget.chapter}:${selectedVerses.first}-${selectedVerses.last}';
    }
  }

  void _copyToClipboard() {
    final reference = _getVerseReference();
    final text = _getSelectedVersesText();
    final fullText = '$reference\n\n$text';
    Clipboard.setData(ClipboardData(text: fullText));
    _exitSelectionMode();
  }

  void _addToFavorites() async {
    final favoriteProvider = context.read<FavoriteProvider>();
    final selectedVerses = _getSelectedVerseRange();
    if (selectedVerses.isEmpty) return;

    final now = DateTime.now().toLocal();

    final favorite = FavoriteVerse(
      bookName: widget.book.fullName,
      chapter: widget.chapter,
      startVerse: selectedVerses.first,
      endVerse: selectedVerses.last,
      reference: _getVerseReference(),
      text: _getSelectedVersesText(),
      createdAt: now,
    );

    await favoriteProvider.addFavorite(favorite);
    if (!mounted) return;

    _exitSelectionMode();
  }

  void _showHighlightColorPicker() {
    _highlightPickerController.forward(from: 0);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedBuilder(
          animation: _highlightPickerController,
          builder: (context, child) {
            final slideAnimation = CurvedAnimation(
              parent: _highlightPickerController,
              curve: Curves.easeOutCubic,
            );

            final scaleValue = Curves.easeOutBack
                .transform(slideAnimation.value)
                .clamp(0.0, 1.0);
            final opacityValue = slideAnimation.value.clamp(0.0, 1.0);

            return Transform.scale(
              scale: scaleValue,
              child: Opacity(
                opacity: opacityValue,
                child: child,
              ),
            );
          },
          child: Container(
            width: 280,
            height: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.palette,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '하이라이트',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.titleFontSize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(7, (index) {
                        final color = HighlightColor.values
                            .where((c) => c != HighlightColor.clear)
                            .toList()[index];
                        final angle = (index * 360 / 7) * (3.14159 / 180);
                        final radius = 80.0;
                        final x = radius * _cos(angle);
                        final y = radius * _sin(angle);

                        return AnimatedBuilder(
                          animation: _highlightPickerController,
                          builder: (context, child) {
                            final delay = index * 0.05;
                            final rawValue =
                                _highlightPickerController.value - delay;
                            final normalizedValue = rawValue.clamp(0.0, 1.0);
                            final curvedValue = Curves.easeOutBack
                                .transform(normalizedValue)
                                .clamp(0.0, 1.0);

                            return Positioned(
                              left: 110 + x * curvedValue - 28,
                              top: 110 + y * curvedValue - 28,
                              child: Transform.scale(
                                scale: curvedValue,
                                child: Opacity(
                                  opacity: curvedValue,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              _addHighlight(color);
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.darkColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      AnimatedBuilder(
                        animation: _highlightPickerController,
                        builder: (context, child) {
                          final value =
                              _highlightPickerController.value.clamp(0.0, 1.0);
                          final curvedValue = Curves.easeOutBack
                              .transform(value)
                              .clamp(0.0, 1.0);

                          return Transform.scale(
                            scale: curvedValue,
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            _addHighlight(HighlightColor.clear);
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.format_color_reset,
                              color: Colors.grey.shade700,
                              size: 28,
                            ),
                          ),
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
    );
  }

  double _cos(double radians) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -radians * radians / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double radians) {
    double result = radians;
    double term = radians;
    for (int i = 1; i <= 10; i++) {
      term *= -radians * radians / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  void _addHighlight(HighlightColor color) async {
    final highlightProvider = context.read<HighlightProvider>();
    final selectedVerses = _getSelectedVerseRange();
    if (selectedVerses.isEmpty) return;

    final now = DateTime.now().toLocal();

    final highlight = HighlightVerse(
      bookName: widget.book.fullName,
      chapter: widget.chapter,
      startVerse: selectedVerses.first,
      endVerse: selectedVerses.last,
      color: color,
      createdAt: now,
    );

    await highlightProvider.addHighlight(highlight);

    _highlightAppliedController.forward(from: 0).then((_) {
      _highlightAppliedController.reset();
    });

    if (!mounted) return;

    _exitSelectionMode();
  }

  void _showSharePreview() {
    final reference = _getVerseReference();
    final text = _getSelectedVersesText();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BibleCardPreviewScreen(
          verse: text,
          reference: reference,
          shareTitle: '성경 말씀', // verse_list_view에서는 "성경 말씀"
        ),
      ),
    );
  }

  void _exitSelectionMode() {
    _floatingActionBarController.reverse(); // ⭐ 애니메이션 역재생

    setState(() {
      _isSelectionMode = false;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _showVersionBottomSheet(BuildContext context, LanguageProvider languageProvider) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final versions = [
      (BibleLanguage.korean, '개역개정', '대한성서공회, 1998'),
      (BibleLanguage.snb, '표준새번역개정판', '대한성서공회, 2001'),
      (BibleLanguage.english, 'KJV', 'King James Version, 1769'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ...versions.map((v) {
                  final (lang, name, desc) = v;
                  final isSelected = languageProvider.currentLanguage == lang;
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await languageProvider.setLanguage(lang);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? cs.primary : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? cs.primary : cs.onSurface,
                                ),
                              ),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isVerseInRange(int verseNum) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    final start = _rangeStart! < _rangeEnd! ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart! > _rangeEnd! ? _rangeStart! : _rangeEnd!;
    return verseNum >= start && verseNum <= end;
  }

  // ⭐ 플로팅 액션 바 위젯
  Widget _buildFloatingActionBar() {
    if (!_isSelectionMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    // iOS는 제스처 바 영역이 크므로 절반만 사용, Android는 전체 사용
    final bottomPadding =
        Platform.isIOS ? systemBottomPadding * 0.5 : systemBottomPadding;

    return Positioned(
      left: 16,
      right: 16,
      bottom:
          16 + bottomPadding, // 시스템 네비게이션 바 고려 (iOS 제스처 바 + Android 바텀 네비게이션)
      child: AnimatedBuilder(
        animation: _floatingActionBarController,
        builder: (context, child) {
          return Transform.scale(
            scale: _floatingActionBarScale.value,
            child: Opacity(
              opacity: _floatingActionBarOpacity.value,
              child: child,
            ),
          );
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(30),
          shadowColor: Colors.black.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: cs.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 복사 버튼
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.copy,
                    label: '복사',
                    onPressed: _copyToClipboard,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 4),
                // 하이라이트 버튼
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.format_color_fill,
                    label: '하이라이트',
                    onPressed: _showHighlightColorPicker,
                    color: const Color.fromARGB(255, 134, 209, 13),
                  ),
                ),
                const SizedBox(width: 4),
                // 북마크 버튼
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.bookmark_add_outlined,
                    label: '북마크',
                    onPressed: _addToFavorites,
                    color: const Color.fromARGB(255, 241, 146, 20),
                  ),
                ),
                const SizedBox(width: 4),
                // 성경 공유 버튼 (맨 오른쪽)
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: '성경 공유',
                    onPressed: _showSharePreview,
                    color: const Color.fromARGB(255, 142, 70, 209),
                  ),
                ),
                const SizedBox(width: 4),
                // 닫기 버튼
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: cs.onSurface),
                  onPressed: _exitSelectionMode,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final verseNums = widget.verses.keys.toList()..sort();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final highlightProvider = context.watch<HighlightProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final fontSizeProvider = context.watch<BibleFontSizeProvider>();
    final fontSize = fontSizeProvider.currentSize;
    final subtitles = languageProvider.currentLanguage == BibleLanguage.snb
        ? BibleSubtitleService()
            .getSnbSubtitlesForChapter(widget.book.fullName, widget.chapter)
        : BibleSubtitleService()
            .getSubtitlesForChapter(widget.book.fullName, widget.chapter);

    const minChapter = 1;
    final maxChapter = widget.book.chapters;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? _getVerseReference()
              : '${widget.book.getLocalizedFullName(languageProvider.isKorean)} ${widget.chapter}${languageProvider.isKorean ? '장' : ''}',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: BackButton(
          onPressed: _isSelectionMode ? _exitSelectionMode : widget.onBack,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        // ⭐ 선택 모드에서는 AppBar actions 숨김
        actions: !_isSelectionMode
            ? [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      languageProvider.isKorean
                          ? fontSize.nextKoreanLabel
                          : fontSize.nextEnglishLabel,
                      key: ValueKey(fontSize),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.buttonFontSize(context),
                        fontWeight: FontWeight.bold,
                        color:
                            theme.appBarTheme.iconTheme?.color ?? cs.onSurface,
                      ),
                    ),
                  ),
                  tooltip: '글자 크기: ${fontSize.displayName}',
                  onPressed: () {
                    fontSizeProvider.cycleFontSize();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 2),
              ]
            : null,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        centerTitle: theme.appBarTheme.centerTitle ?? true,
      ),
      body: Column(
        children: [
          if (!_isSelectionMode)
            BreadcrumbBar(
              items: [
                BreadcrumbItem(
                  label: languageProvider.isKorean ? '홈' : 'Home',
                  onTap: widget.onGoHome,
                ),
                BreadcrumbItem(
                  label: widget.book
                      .getLocalizedFullName(languageProvider.isKorean),
                  onTap: widget.onGoToChapterSelector,
                ),
                BreadcrumbItem(
                  label: languageProvider.isKorean
                      ? '${widget.chapter}장'
                      : 'Ch ${widget.chapter}',
                  onTap: widget.onGoToVerseSelector,
                ),
                BreadcrumbItem(
                  label: languageProvider.isKorean
                      ? '$_selectedVerse절'
                      : 'V $_selectedVerse',
                  onTap: () {},
                  isActive: true,
                ),
              ],
              versionLabel: languageProvider.currentLanguage.displayName,
              onVersionTap: () => _showVersionBottomSheet(context, languageProvider),
            ),
          Expanded(
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _languageFadeAnimation,
                  child: SlideTransition(
                    position: _languageSlideAnimation,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: verseNums.length,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, idx) {
                        final verseNum = verseNums[idx];
                        final text = widget.verses[verseNum] ?? '';
                        final isSelected =
                            !_isSelectionMode && verseNum == _selectedVerse;
                        final isInRange = _isVerseInRange(verseNum);
                        final isFavorited = favoriteProvider.isVerseFavorited(
                          widget.book.fullName,
                          widget.chapter,
                          verseNum,
                        );
                        final subtitle = subtitles[verseNum];

                        final highlight = highlightProvider.getVerseHighlight(
                          widget.book.fullName,
                          widget.chapter,
                          verseNum,
                        );
                        final isHighlighted = highlight != null;

                        Color? backgroundColor;
                        Color? borderColor;
                        Color? textColor;

                        if (isInRange) {
                          backgroundColor = cs.primary.withOpacity(0.1);
                          borderColor = cs.primary;
                          textColor = cs.onSurface.withOpacity(1.0);
                        } else if (isHighlighted) {
                          backgroundColor = highlight.color.color;
                          borderColor = highlight.color.darkColor;
                          textColor = cs.onSurface;
                        } else if (isSelected) {
                          backgroundColor = cs.primary.withOpacity(0.1);
                          textColor = cs.onSurface.withOpacity(0.7);
                        } else {
                          textColor = cs.onSurface;
                        }

                        return Column(
                          key: idx == 0 ? _itemKey : null,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 소제목이 있으면 표시 (한글/SNB 모드일 때)
                            if (subtitle != null && !languageProvider.isEnglish)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 20, 16, 12),
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontFamily: 'ChosunCentennial',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            // 본문 절
                            AnimatedBuilder(
                              animation: _highlightAppliedController,
                              builder: (context, child) {
                                final isJustHighlighted = isInRange &&
                                    _highlightAppliedController.isAnimating;
                                final pulseValue =
                                    _highlightAppliedController.value;
                                final scale = isJustHighlighted
                                    ? 1.0 +
                                        (0.03 * _sin(pulseValue * 3.14159 * 2))
                                    : 1.0;

                                return Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.centerLeft,
                                  child: child,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  border: isHighlighted
                                      ? Border(
                                          left: BorderSide(
                                            color: borderColor ??
                                                Colors.transparent,
                                            width: 4,
                                          ),
                                        )
                                      : (isInRange
                                          ? Border(
                                              left: BorderSide(
                                                color: borderColor ??
                                                    Colors.transparent,
                                                width: 3,
                                              ),
                                            )
                                          : null),
                                ),
                                child: ListTile(
                                  onTap: () => _handleVerseTap(verseNum),
                                  onLongPress: () =>
                                      _handleVerseLongPress(verseNum),
                                  leading: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontFamily: 'ChosunCentennial',
                                          fontWeight: isInRange || isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: isInRange || isSelected
                                              ? fontSize.verseNumberSelectedSize
                                              : fontSize.verseNumberSize,
                                          color: textColor,
                                        ),
                                        child: Text('$verseNum'),
                                      ),
                                      if (isFavorited)
                                        Positioned(
                                          top: -4,
                                          right: -10,
                                          child: Icon(
                                            Icons.star,
                                            size: 12,
                                            color: Colors.amber[700],
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontFamily: 'ChosunCentennial',
                                      fontWeight: isInRange || isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: isInRange || isSelected
                                          ? fontSize.verseTextSelectedSize
                                          : fontSize.verseTextSize,
                                      color: textColor,
                                    ),
                                    child: Text(text),
                                  ),
                                  dense: true,
                                  selected: isInRange || isSelected,
                                  selectedTileColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ⭐ 플로팅 액션 바
                _buildFloatingActionBar(),

                // 단어 검색으로 들어온 경우 이전/다음장 버튼 숨김
                if (!_isSelectionMode && !widget.hideLanguageToggle)
                  Positioned(
                    left: 12,
                    right: 88,
                    bottom: 12 +
                        (Platform.isIOS
                            ? MediaQuery.of(context).padding.bottom * 0.5
                            : MediaQuery.of(context).padding.bottom),
                    child: TweenAnimationBuilder<Offset>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(
                        begin: const Offset(0, 1.5),
                        end: Offset.zero,
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return Transform.translate(
                          offset: Offset(0, offset.dy * 50),
                          child: child,
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.chapter > minChapter
                                  ? () {
                                      if (widget.onChapterChanged != null) {
                                        widget.onChapterChanged!(
                                            widget.chapter - 1);
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  size: 18),
                              label: Text(
                                  languageProvider.isKorean
                                      ? '이전 장'
                                      : 'Previous',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                backgroundColor: Colors.white,
                                elevation: 1.5,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.chapter < maxChapter
                                  ? () {
                                      if (widget.onChapterChanged != null) {
                                        widget.onChapterChanged!(
                                            widget.chapter + 1);
                                      }
                                    }
                                  : null,
                              icon:
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                              label: Text(
                                  languageProvider.isKorean ? '다음 장' : 'Next',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                backgroundColor: Colors.white,
                                elevation: 1.5,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // 단어 검색으로 들어온 경우 플로팅 액션 버튼 숨김
      floatingActionButton: !_isSelectionMode && !widget.hideLanguageToggle
          ? TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: FloatingActionButton(
                onPressed: widget.onGoHome,
                tooltip: languageProvider.isKorean ? '책 선택으로' : 'Select Book',
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                child: const Icon(Icons.menu_book),
              ),
            )
          : null,
    );
  }
}
