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

  @override
  void initState() {
    super.initState();
    final keys = widget.verses.keys.toList();
    _selectedVerseKey = keys.isNotEmpty ? keys.first : "";
    // 자동 스크롤 완전 제거!
  }

  @override
  void didUpdateWidget(covariant PlanVerseListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.verses != oldWidget.verses) {
      final keys = widget.verses.keys.toList();
      setState(() {
        _selectedVerseKey = keys.isNotEmpty ? keys.first : "";
      });
      // 자동 스크롤 완전 제거!
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verseKeys = widget.verses.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
        itemCount: verseKeys.length,
        physics: const ClampingScrollPhysics(),
        itemBuilder: (context, idx) {
          final key = verseKeys[idx];
          final text = widget.verses[key] ?? '';
          final isSelected = key == _selectedVerseKey;

          // "창1:1" => "창 1:1"으로 보기 쉽게
          final prettyKey = _prettyVerseKey(key);

          return Container(
            color: isSelected ? Colors.yellow.shade100 : null,
            child: ListTile(
              onTap: () {
                setState(() {
                  _selectedVerseKey = key;
                });
              },
              leading: Text(
                prettyKey,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: isSelected ? 17 : 13,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              title: Text(
                text,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 17 : 15,
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
