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
  // ✅ onAddFavorite 콜백 제거 (Provider 사용)

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

class _VerseListViewState extends State<VerseListView> {
  final _scrollController = ScrollController();
  final _itemKey = GlobalKey();

  double? itemHeight;
  late int _selectedVerse;

  // ✅ 범위 선택 관련 상태
  int? _rangeStart;
  int? _rangeEnd;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _selectedVerse = widget.selectedVerse;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 60));
      _measureItemHeight();
      _scrollToSelected(center: true);
    });
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

  void _scrollToSelected({bool center = false}) async {
    final verseNums = widget.verses.keys.toList()..sort();
    final selectedIdx = verseNums.indexOf(_selectedVerse);
    if (selectedIdx == -1 || itemHeight == null) return;

    if (!_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected(center: center);
      });
      return;
    }

    final RenderBox? listBox = context.findRenderObject() as RenderBox?;
    final double listHeight = listBox?.size.height ?? 600;
    final int halfCount = (listHeight / (itemHeight ?? 30) / 2).floor();
    final double centerOffset =
        (selectedIdx * itemHeight!) - ((center ? halfCount : 0) * itemHeight!);

    double targetOffset = centerOffset < 0 ? 0 : centerOffset;
    final max = _scrollController.position.maxScrollExtent;
    if (targetOffset > max) targetOffset = max;

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  // ✅ 범위 선택 핸들러
  void _handleVerseLongPress(int verseNum) {
    setState(() {
      // 기존 선택 초기화하고 새로운 범위 선택 시작
      _selectedVerse = verseNum; // ✅ 기존 단일 선택 초기화
      _isSelectionMode = true;
      _rangeStart = verseNum;
      _rangeEnd = verseNum;
    });
  }

  void _handleVerseTap(int verseNum) {
    if (_isSelectionMode) {
      // 선택 모드일 때는 범위 끝 설정
      setState(() {
        _rangeEnd = verseNum;
      });
    } else {
      // 일반 모드일 때는 기존처럼 동작
      setState(() {
        _selectedVerse = verseNum;
      });
    }
  }

  // ✅ 선택된 범위의 절 번호들 반환
  List<int> _getSelectedVerseRange() {
    if (_rangeStart == null || _rangeEnd == null) return [];

    final start = _rangeStart! < _rangeEnd! ? _rangeStart! : _rangeEnd!;
    final end = _rangeStart! > _rangeEnd! ? _rangeStart! : _rangeEnd!;

    return List.generate(end - start + 1, (i) => start + i);
  }

  // ✅ 선택된 구절들의 텍스트 조합
  String _getSelectedVersesText() {
    final selectedVerses = _getSelectedVerseRange();
    return selectedVerses
        .map((v) => '$v절: ${widget.verses[v] ?? ''}')
        .join('\n');
  }

  // ✅ 참조 문자열 생성
  String _getVerseReference() {
    final selectedVerses = _getSelectedVerseRange();
    if (selectedVerses.isEmpty) return '';

    if (selectedVerses.length == 1) {
      return '${widget.book.fullName} ${widget.chapter}:${selectedVerses.first}';
    } else {
      return '${widget.book.fullName} ${widget.chapter}:${selectedVerses.first}-${selectedVerses.last}';
    }
  }

  // ✅ 복사 기능
  void _copyToClipboard() {
    final reference = _getVerseReference();
    final text = _getSelectedVersesText();
    final fullText = '$reference\n\n$text';

    Clipboard.setData(ClipboardData(text: fullText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$reference 복사됨'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _exitSelectionMode();
  }

  // ✅ 즐겨찾기 추가
  void _addToFavorites() async {
    final favoriteProvider = context.read<FavoriteProvider>();
    final selectedVerses = _getSelectedVerseRange();

    if (selectedVerses.isEmpty) return;

    final favorite = FavoriteVerse(
      bookName: widget.book.fullName,
      chapter: widget.chapter,
      startVerse: selectedVerses.first,
      endVerse: selectedVerses.last,
      reference: _getVerseReference(),
      text: _getSelectedVersesText(),
      createdAt: DateTime.now(),
    );

    await favoriteProvider.addFavorite(favorite);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getVerseReference()} 즐겨찾기에 추가됨'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _exitSelectionMode();
  }

  // ✅ 선택 모드 종료
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  // ✅ 해당 절이 선택 범위에 포함되는지 확인
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
        _exitSelectionMode(); // ✅ 장이 바뀌면 선택 모드 해제
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected(center: true);
      });
      return;
    }

    if (widget.selectedVerse != oldWidget.selectedVerse) {
      setState(() {
        _selectedVerse = widget.selectedVerse;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected(center: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final verseNums = widget.verses.keys.toList()..sort();
    final favoriteProvider = context.watch<FavoriteProvider>(); // ✅ Provider 감시

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
                  tooltip: '즐겨찾기',
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
                ListView.builder(
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
                    ); // ✅ 즐겨찾기 여부 확인

                    return Container(
                      key: idx == 0 ? _itemKey : null,
                      color: isInRange
                          ? cs.primary.withOpacity(0.25)
                          : (isSelected ? cs.primary.withOpacity(0.15) : null),
                      child: ListTile(
                        onTap: () => _handleVerseTap(verseNum),
                        onLongPress: () => _handleVerseLongPress(verseNum),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Text(
                              '$verseNum',
                              style: TextStyle(
                                fontWeight: isInRange || isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: isInRange || isSelected ? 19 : 15,
                                color: isInRange || isSelected
                                    ? cs.primary
                                    : cs.onSurface,
                              ),
                            ),
                            // ✅ 절 번호 우측 상단에 작은 별표
                            if (isFavorited)
                              Positioned(
                                top: -6,
                                right: -10,
                                child: Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber[700],
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          text,
                          style: TextStyle(
                            fontWeight: isInRange || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isInRange || isSelected ? 18 : 15,
                            color: isInRange || isSelected
                                ? cs.primary
                                : cs.onSurface,
                          ),
                        ),
                        dense: true,
                        selected: isInRange || isSelected,
                        selectedTileColor: cs.primary.withOpacity(0.08),
                      ),
                    );
                  },
                ),
                if (!_isSelectionMode)
                  Positioned(
                    left: 12,
                    right: 88,
                    bottom: 12,
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
                            icon:
                                const Icon(Icons.arrow_back_ios_new, size: 18),
                            label: const Text('이전 장',
                                style: TextStyle(fontWeight: FontWeight.w700)),
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
                            icon: const Icon(Icons.arrow_forward_ios, size: 18),
                            label: const Text('다음 장',
                                style: TextStyle(fontWeight: FontWeight.w700)),
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: widget.onGoHome,
              tooltip: '책 선택으로',
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              child: const Icon(Icons.menu_book),
            )
          : null,
    );
  }
}
