import 'package:flutter/material.dart';
import '../../models/bible_data.dart';
import '../../widgets/breadcrumb_bar.dart'; // ✅ 추가

class VerseListView extends StatefulWidget {
  final BibleData book;
  final int chapter;
  final Map<int, String> verses; // {1: "...", 2: "..."}
  final int selectedVerse;
  final VoidCallback onBack;
  final void Function(int newChapter)? onChapterChanged;
  final VoidCallback? onGoToChapterSelector; // ✅ 추가
  final VoidCallback? onGoToVerseSelector; // ✅ 추가
  final VoidCallback? onGoHome; // ✅ 추가

  const VerseListView({
    super.key,
    required this.book,
    required this.chapter,
    required this.verses,
    required this.selectedVerse,
    required this.onBack,
    this.onChapterChanged,
    this.onGoToChapterSelector, // ✅ 추가
    this.onGoToVerseSelector, // ✅ 추가
    this.onGoHome, // ✅ 추가
  });

  @override
  State<VerseListView> createState() => _VerseListViewState();
}

class _VerseListViewState extends State<VerseListView> {
  final _scrollController = ScrollController();
  final _itemKey = GlobalKey();

  double? itemHeight;
  late int _selectedVerse;

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

    // 렌더링이 아직 끝나지 않았으면 maxScrollExtent가 제대로 안 잡힘
    if (!_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent == 0) {
      // 한 번 더 프레임 이후에 재시도
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

  @override
  void didUpdateWidget(covariant VerseListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // "장"이 바뀐 경우에만 1절로 초기화
    if (widget.chapter != oldWidget.chapter) {
      setState(() {
        _selectedVerse = 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected(center: true);
      });
      return; // 절도 동시에 바뀌면 장을 우선시(중복 호출 방지)
    }

    // "selectedVerse"만 바뀌면, 그 절로
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

    const minChapter = 1;
    final maxChapter = widget.book.chapters;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.book.fullName} ${widget.chapter}장',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: BackButton(
          onPressed: widget.onBack,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        centerTitle: theme.appBarTheme.centerTitle ?? true,
      ),
      body: Column(
        children: [
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
                  padding: const EdgeInsets.only(bottom: 80), // ✅ 하단 여백
                  itemBuilder: (context, idx) {
                    final verseNum = verseNums[idx];
                    final text = widget.verses[verseNum] ?? '';
                    final isSelected = verseNum == _selectedVerse;
                    return Container(
                      key: idx == 0 ? _itemKey : null,
                      color: isSelected ? cs.primary.withOpacity(0.15) : null,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedVerse = verseNum;
                          });
                        },
                        leading: Text(
                          '$verseNum',
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: isSelected ? 19 : 15,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                        ),
                        title: Text(
                          text,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isSelected ? 18 : 15,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                        ),
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: cs.primary.withOpacity(0.08),
                      ),
                    );
                  },
                ),
                // ⬇️ 하단 네비게이션 버튼 (FAB 공간 확보)
                Positioned(
                  left: 12,
                  right: 88, // ✅ FAB 공간 확보 (56 + 16 + 16)
                  bottom: 12,
                  child: Row(
                    children: [
                      // 이전 장
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.chapter > minChapter
                              ? () {
                                  if (widget.onChapterChanged != null) {
                                    widget
                                        .onChapterChanged!(widget.chapter - 1);
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
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
                      // 다음 장
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.chapter < maxChapter
                              ? () {
                                  if (widget.onChapterChanged != null) {
                                    widget
                                        .onChapterChanged!(widget.chapter + 1);
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
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onGoHome,
        tooltip: '책 선택으로',
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.menu_book),
      ),
    );
  }
}
