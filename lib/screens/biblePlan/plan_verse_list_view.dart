import 'package:flutter/material.dart';
import '../../utils/pretty_range_label.dart';
import 'package:marquee/marquee.dart';

class PlanVerseListView extends StatefulWidget {
  final String title;
  final Map<String, String> verses;
  final VoidCallback onBack;
  final VoidCallback? onPrevDay;
  final VoidCallback? onNextDay;
  final bool hasPrevDay;
  final bool hasNextDay;

  const PlanVerseListView({
    super.key,
    required this.title,
    required this.verses,
    required this.onBack,
    this.onPrevDay,
    this.onNextDay,
    this.hasPrevDay = false,
    this.hasNextDay = false,
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme; // ✅ ColorScheme 가져오기
    final verseKeys = widget.verses.keys.toList();
    final titleArr = widget.title.split('  ');
    final dayTitle = titleArr.isNotEmpty ? titleArr[0] : '';
    final rangeTitle = titleArr.length > 1 ? titleArr[1] : '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ 테마 적용
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        leading: BackButton(
          onPressed: widget.onBack,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        actions: const [SizedBox(width: 48)],
        centerTitle: true,
        titleSpacing: 0,
        title: SizedBox(
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    dayTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'ChosunCentennial',
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface, // ✅ 테마 적용
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 22,
                  child: (rangeTitle.length < 23)
                      ? Center(
                          child: Text(
                            fullNameRangeLabel(rangeTitle),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface, // ✅ 테마 적용
                            ),
                          ),
                        )
                      : Marquee(
                          text: fullNameRangeLabel(rangeTitle),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface, // ✅ 테마 적용
                          ),
                          velocity: 24.0,
                          blankSpace: 40,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 76),
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
          // Scroll Up/Down FABs (위로, 아래로)
          Positioned(
            right: 18,
            bottom: 94,
            child: AnimatedOpacity(
              opacity: _showFAB ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: "scrollToTop",
                    onPressed: _scrollToTop,
                    backgroundColor: cs.surface, // ✅ 테마 적용
                    foregroundColor: cs.primary, // ✅ 테마 적용
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
                    backgroundColor: cs.surface, // ✅ 테마 적용
                    foregroundColor: cs.primary, // ✅ 테마 적용
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
          // ====== 하단 DAY 이동 버튼 ======
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 이전 DAY
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: widget.hasPrevDay ? widget.onPrevDay : null,
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    label: const Text(
                      '이전 DAY',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: cs.primary, // ✅ 테마 적용
                      backgroundColor: cs.surface, // ✅ 테마 적용
                      elevation: 1.5,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      textStyle: const TextStyle(fontSize: 15),
                      disabledForegroundColor:
                          cs.onSurface.withOpacity(0.38), // ✅ 테마 적용
                      disabledBackgroundColor:
                          cs.surface.withOpacity(0.5), // ✅ 테마 적용
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 다음 DAY
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: widget.hasNextDay ? widget.onNextDay : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    label: const Text(
                      '다음 DAY',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: cs.primary, // ✅ 테마 적용
                      backgroundColor: cs.surface, // ✅ 테마 적용
                      elevation: 1.5,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      textStyle: const TextStyle(fontSize: 15),
                      disabledForegroundColor:
                          cs.onSurface.withOpacity(0.38), // ✅ 테마 적용
                      disabledBackgroundColor:
                          cs.surface.withOpacity(0.5), // ✅ 테마 적용
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _superLightTile({
    required String verse,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme; // ✅ ColorScheme 가져오기
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: selected
            ? cs.primary.withOpacity(0.15)
            : null, // ✅ 테마 적용 (투명도 약간 증가)
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verse,
              style: TextStyle(
                fontFamily: 'ChosunCentennial',
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                fontSize: selected ? 17 : 13,
                color: selected
                    ? cs.primary // ✅ 테마 적용
                    : cs.onSurface, // ✅ 테마 적용
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'ChosunCentennial',
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: selected ? 17 : 15,
                  color: selected
                      ? cs.primary // ✅ 테마 적용
                      : cs.onSurface, // ✅ 테마 적용
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
    final match = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(key);
    if (match == null) return key;
    final book = match.group(1)!;
    final ch = match.group(2)!;
    final verse = match.group(3)!;
    return '$book $ch:$verse';
  }
}
