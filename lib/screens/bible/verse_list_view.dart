import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../models/favorite_verse.dart';
import '../../providers/favorite_provider.dart';
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
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _itemKey = GlobalKey();

  double? itemHeight;
  late int _selectedVerse;

  int? _rangeStart;
  int? _rangeEnd;
  bool _isSelectionMode = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1));
      _measureItemHeight();
      _scrollToSelectedOnce();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    setState(() {
      _selectedVerse = verseNum;
      _isSelectionMode = true;
      _rangeStart = verseNum;
      _rangeEnd = verseNum;
    });
  }

  void _handleVerseTap(int verseNum) {
    if (_isSelectionMode) {
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
      // ✅ 장 변경 시 애니메이션 리셋
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
                // ✅ 절 목록 페이드인 애니메이션
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

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        key: idx == 0 ? _itemKey : null,
                        color: isInRange
                            ? cs.primary.withOpacity(0.25)
                            : (isSelected
                                ? cs.primary.withOpacity(0.15)
                                : null),
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
                                  fontSize: isInRange || isSelected ? 19 : 15,
                                  color: isInRange || isSelected
                                      ? cs.primary
                                      : cs.onSurface,
                                ),
                                child: Text('$verseNum'),
                              ),
                              if (isFavorited)
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 300),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: child,
                                    );
                                  },
                                  child: Positioned(
                                    top: -4,
                                    right: -10,
                                    child: Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.amber[700],
                                    ),
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
                              fontSize: isInRange || isSelected ? 18 : 15,
                              color: isInRange || isSelected
                                  ? cs.primary
                                  : cs.onSurface,
                            ),
                            child: Text(text),
                          ),
                          dense: true,
                          selected: isInRange || isSelected,
                          selectedTileColor: cs.primary.withOpacity(0.08),
                        ),
                      );
                    },
                  ),
                ),
                // ✅ 하단 버튼 슬라이드 업 애니메이션
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
