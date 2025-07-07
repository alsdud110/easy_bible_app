import 'package:flutter/material.dart';

class PlanVerseListView extends StatefulWidget {
  final String title;
  final Map<String, String> verses; // ex: "창1:1": "...", "창1:2": "...", ...
  final VoidCallback onBack;

  const PlanVerseListView({
    super.key,
    required this.title,
    required this.verses,
    required this.onBack,
  });

  @override
  State<PlanVerseListView> createState() => _PlanVerseListViewState();
}

class _PlanVerseListViewState extends State<PlanVerseListView> {
  final _scrollController = ScrollController();
  late String _selectedVerseKey;
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    final keys = widget.verses.keys.toList();
    _selectedVerseKey = keys.isNotEmpty ? keys.first : "";

    _scrollController.addListener(() {
      // 일정 스크롤 이상이면 버튼 보여줌
      const threshold = 350.0;
      if (_scrollController.offset > threshold && !_showFAB) {
        setState(() {
          _showFAB = true;
        });
      } else if (_scrollController.offset <= threshold && _showFAB) {
        setState(() {
          _showFAB = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant PlanVerseListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.verses != oldWidget.verses) {
      final keys = widget.verses.keys.toList();
      setState(() {
        _selectedVerseKey = keys.isNotEmpty ? keys.first : "";
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verseKeys = widget.verses.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "DAY2" → "DAY 2" 자동 변환
            Text(
              widget.title
                  .replaceFirstMapped(
                    RegExp(r'(DAY)(\d+)'),
                    (m) => '${m.group(1)} ${m.group(2)}',
                  )
                  .split('  ')[0],
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              widget.title.split('  ').length > 1
                  ? widget.title.split('  ')[1]
                  : "",
              style: theme.textTheme.bodyMedium,
            ),
          ],
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
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: verseKeys.length,
            itemBuilder: (context, idx) {
              final key = verseKeys[idx];
              final text = widget.verses[key] ?? '';
              final isSelected = key == _selectedVerseKey;

              final prettyKey = _prettyVerseKey(key);

              return _superLightTile(
                verse: prettyKey,
                text: text,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedVerseKey = key;
                  });
                },
              );
            },
          ),
          // 스크롤 끝/시작 이동 버튼 (요즘 스타일!)
          Positioned(
            right: 18,
            bottom: 22,
            child: AnimatedOpacity(
              opacity: _showFAB ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: "scrollToTop",
                    onPressed: _scrollToTop,
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 1.8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 23),
                  ),
                  const SizedBox(height: 14),
                  FloatingActionButton.small(
                    heroTag: "scrollToBottom",
                    onPressed: _scrollToBottom,
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 1.8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, size: 23),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 초경량 커스텀 verse tile
  Widget _superLightTile({
    required String verse,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: selected ? Colors.yellow.shade100 : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verse,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                fontSize: selected ? 17 : 13,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: selected ? 17 : 15,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyVerseKey(String key) {
    // ex: 창1:1 → 창 1:1
    final match = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(key);
    if (match == null) return key;
    final book = match.group(1)!;
    final ch = match.group(2)!;
    final verse = match.group(3)!;
    return '$book $ch:$verse';
  }
}
