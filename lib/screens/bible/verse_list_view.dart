import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../models/favorite_verse.dart';
import '../../models/highlight_verse.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/highlight_provider.dart';
import '../../widgets/breadcrumb_bar.dart';

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
  late Animation<double> _fadeAnimation;

  // 하이라이트 애니메이션 컨트롤러
  late AnimationController _highlightPickerController;
  late AnimationController _highlightAppliedController;

  @override
  void initState() {
    super.initState();
    _selectedVerse = widget.selectedVerse;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // 하이라이트 픽커 애니메이션
    _highlightPickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 하이라이트 적용 애니메이션
    _highlightAppliedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

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
    _scrollController.dispose();
    super.dispose();
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
  }

  void _handleVerseTap(int verseNum) {
    if (_isSelectionMode) {
      HapticFeedback.lightImpact();
      setState(() {
        _rangeEnd = verseNum;
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
    final selectedVerses = _getSelectedVerseRange();
    if (selectedVerses.isEmpty) return '';
    if (selectedVerses.length == 1) {
      return '${widget.book.fullName} ${widget.chapter}:${selectedVerses.first}';
    } else {
      return '${widget.book.fullName} ${widget.chapter}:${selectedVerses.first}-${selectedVerses.last}';
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

            // clamp 추가하여 opacity 범위 보장
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
                    const Text(
                      '하이라이트',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

    // 하이라이트 적용 애니메이션
    _highlightAppliedController.forward(from: 0).then((_) {
      _highlightAppliedController.reset();
    });

    if (!mounted) return;

    _exitSelectionMode();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  bool _isVerseInRange(int verseNum) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    final start = _rangeStart! < _rangeEnd! ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart! > _rangeEnd! ? _rangeStart! : _rangeEnd!;
    return verseNum >= start && verseNum <= end;
  }

  @override
  void didUpdateWidget(covariant VerseListView oldWidget) {
    super.didUpdateWidget(oldWidget);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final verseNums = widget.verses.keys.toList()..sort();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final highlightProvider = context.watch<HighlightProvider>();

    const minChapter = 1;
    final maxChapter = widget.book.chapters;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? _getVerseReference()
              : '${widget.book.fullName} ${widget.chapter}장',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
                color: theme.appBarTheme.iconTheme?.color,
              )
            : BackButton(
                onPressed: widget.onBack,
                color: theme.appBarTheme.iconTheme?.color,
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyToClipboard,
                  tooltip: '복사',
                ),
                IconButton(
                  icon: const Icon(Icons.format_color_fill),
                  onPressed: _showHighlightColorPicker,
                  tooltip: '하이라이트',
                ),
                IconButton(
                  icon: const Icon(Icons.star_border),
                  onPressed: _addToFavorites,
                  tooltip: '북마크',
                ),
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
                  label: '홈',
                  onTap: widget.onGoHome,
                ),
                BreadcrumbItem(
                  label: widget.book.fullName,
                  onTap: widget.onGoToChapterSelector,
                ),
                BreadcrumbItem(
                  label: '${widget.chapter}장',
                  onTap: widget.onGoToVerseSelector,
                ),
                BreadcrumbItem(
                  label: '$_selectedVerse절',
                  onTap: () {},
                  isActive: true,
                ),
              ],
            ),
          Expanded(
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
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
                        // 범위 선택 시 - 부드러운 강조
                        backgroundColor = cs.primary.withOpacity(0.1);
                        borderColor = cs.primary;
                        textColor = cs.onSurface.withOpacity(1.0);
                      } else if (isHighlighted) {
                        // 하이라이트 적용 시 - 배경만 변경, 텍스트는 기본 유지
                        backgroundColor = highlight.color.color;
                        borderColor = highlight.color.darkColor;
                        textColor = cs.onSurface;
                      } else if (isSelected) {
                        // 단일 절 선택 시 - 매우 은은하게
                        backgroundColor = cs.primary.withOpacity(0.1);
                        textColor = cs.onSurface.withOpacity(0.7);
                      } else {
                        textColor = cs.onSurface;
                      }

                      return AnimatedBuilder(
                        animation: _highlightAppliedController,
                        builder: (context, child) {
                          final isJustHighlighted = isInRange &&
                              _highlightAppliedController.isAnimating;
                          final pulseValue = _highlightAppliedController.value;
                          final scale = isJustHighlighted
                              ? 1.0 + (0.03 * _sin(pulseValue * 3.14159 * 2))
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
                          key: idx == 0 ? _itemKey : null,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: isHighlighted
                                ? Border(
                                    left: BorderSide(
                                      color: borderColor ?? Colors.transparent,
                                      width: 4,
                                    ),
                                  )
                                : (isInRange
                                    ? Border(
                                        left: BorderSide(
                                          color:
                                              borderColor ?? Colors.transparent,
                                          width: 3,
                                        ),
                                      )
                                    : null),
                          ),
                          child: ListTile(
                            onTap: () => _handleVerseTap(verseNum),
                            onLongPress: () => _handleVerseLongPress(verseNum),
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontFamily: 'ChosunCentennial',
                                    fontWeight: isInRange || isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize:
                                        isInRange || isSelected ? 15.05 : 15,
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
                                fontSize: isInRange || isSelected ? 15.05 : 15,
                                color: textColor,
                              ),
                              child: Text(text),
                            ),
                            dense: true,
                            selected: isInRange || isSelected,
                            selectedTileColor: Colors.transparent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!_isSelectionMode)
                  Positioned(
                    left: 12,
                    right: 88,
                    bottom: 12,
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
                              label: const Text('이전 장',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
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
                              label: const Text('다음 장',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
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
      floatingActionButton: !_isSelectionMode
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
                tooltip: '책 선택으로',
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                child: const Icon(Icons.menu_book),
              ),
            )
          : null,
    );
  }
}
