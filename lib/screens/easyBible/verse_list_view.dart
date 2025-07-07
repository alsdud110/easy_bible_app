import 'package:flutter/material.dart';
import '../../models/bible_data.dart';

class VerseListView extends StatefulWidget {
  final BibleData book;
  final int chapter;
  final Map<int, String> verses; // {1: "...", 2: "..."}
  final int selectedVerse;
  final VoidCallback onBack;

  const VerseListView({
    super.key,
    required this.book,
    required this.chapter,
    required this.verses,
    required this.selectedVerse,
    required this.onBack,
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
    // selectedVerse가 외부에서 바뀔 때만 중앙으로!
    if (widget.selectedVerse != oldWidget.selectedVerse) {
      _selectedVerse = widget.selectedVerse;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected(center: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verseNums = widget.verses.keys.toList()..sort();
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
      body: ListView.builder(
        controller: _scrollController,
        itemCount: verseNums.length,
        physics: const ClampingScrollPhysics(), // ← 탄성효과 제거!
        itemBuilder: (context, idx) {
          final verseNum = verseNums[idx];
          final text = widget.verses[verseNum] ?? '';
          final isSelected = verseNum == _selectedVerse;
          return Container(
            key: idx == 0 ? _itemKey : null,
            color: isSelected ? Colors.yellow.shade100 : null,
            child: ListTile(
              onTap: () {
                setState(() {
                  _selectedVerse = verseNum;
                  // 누를 때는 중앙으로 스크롤 안함! (초기 진입/절 변경만)
                });
              },
              leading: Text(
                '$verseNum',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: isSelected ? 19 : 15,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              title: Text(
                text,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 18 : 15,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              dense: true,
              selected: isSelected,
              selectedTileColor: Colors.yellow.shade50,
            ),
          );
        },
      ),
    );
  }
}
