import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/pretty_range_label.dart';
import '../../providers/favorite_provider.dart';
import '../../models/favorite_verse.dart';
import '../../models/const/book_full_name.dart';
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

  String? _rangeStart;
  String? _rangeEnd;
  bool _isSelectionMode = false;

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
        _exitSelectionMode();
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

  void _handleVerseLongPress(String verseKey) {
    setState(() {
      _selectedVerseKey = verseKey;
      _isSelectionMode = true;
      _rangeStart = verseKey;
      _rangeEnd = verseKey;
    });
  }

  void _handleVerseTap(String verseKey) {
    if (_isSelectionMode) {
      setState(() {
        _rangeEnd = verseKey;
      });
    } else {
      setState(() {
        _selectedVerseKey = verseKey;
      });
    }
  }

  List<String> _getSelectedVerseRange() {
    if (_rangeStart == null || _rangeEnd == null) return [];

    final keys = widget.verses.keys.toList();
    final startIdx = keys.indexOf(_rangeStart!);
    final endIdx = keys.indexOf(_rangeEnd!);

    if (startIdx == -1 || endIdx == -1) return [];

    final start = startIdx < endIdx ? startIdx : endIdx;
    final end = startIdx > endIdx ? startIdx : endIdx;

    return keys.sublist(start, end + 1);
  }

  String _getSelectedVersesText() {
    final selectedVerses = _getSelectedVerseRange();
    return selectedVerses.map((key) {
      // key 형식: "창41:9"
      final match = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(key);
      if (match != null) {
        final verseNum = match.group(3)!; // 절 번호만 추출
        return '$verseNum절: ${widget.verses[key] ?? ''}';
      }
      return widget.verses[key] ?? '';
    }).join('\n');
  }

  String _getVerseReference() {
    final selectedVerses = _getSelectedVerseRange();
    if (selectedVerses.isEmpty) return '';

    final firstMatch =
        RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(selectedVerses.first);
    if (firstMatch == null) return _prettyVerseKey(selectedVerses.first);

    final shortName = firstMatch.group(1)!;
    final bookName = bookFullName[shortName] ?? shortName;
    final chapter = firstMatch.group(2)!;
    final startVerse = firstMatch.group(3)!;

    if (selectedVerses.length == 1) {
      return '$bookName $chapter:$startVerse';
    } else {
      final lastMatch =
          RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(selectedVerses.last);
      if (lastMatch == null) return _prettyVerseKey(selectedVerses.first);

      final endVerse = lastMatch.group(3)!;
      return '$bookName $chapter:$startVerse-$endVerse';
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

    final firstKey = selectedVerses.first;
    final match = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(firstKey);

    if (match == null) {
      _exitSelectionMode();
      return;
    }

    final shortName = match.group(1)!;
    final bookName = bookFullName[shortName] ?? shortName;
    final chapter = int.parse(match.group(2)!);
    final startVerse = int.parse(match.group(3)!);

    final lastKey = selectedVerses.last;
    final lastMatch = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(lastKey);
    final endVerse =
        lastMatch != null ? int.parse(lastMatch.group(3)!) : startVerse;

    final favorite = FavoriteVerse(
      bookName: bookName,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
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

  bool _isVerseInRange(String verseKey) {
    if (_rangeStart == null || _rangeEnd == null) return false;

    final keys = widget.verses.keys.toList();
    final startIdx = keys.indexOf(_rangeStart!);
    final endIdx = keys.indexOf(_rangeEnd!);
    final currentIdx = keys.indexOf(verseKey);

    if (startIdx == -1 || endIdx == -1 || currentIdx == -1) return false;

    final start = startIdx < endIdx ? startIdx : endIdx;
    final end = startIdx > endIdx ? startIdx : endIdx;

    return currentIdx >= start && currentIdx <= end;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final verseKeys = widget.verses.keys.toList();
    final titleArr = widget.title.split('  ');
    final dayTitle = titleArr.isNotEmpty ? titleArr[0] : '';
    final rangeTitle = titleArr.length > 1 ? titleArr[1] : '';
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
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
            : const [SizedBox(width: 48)],
        centerTitle: true,
        titleSpacing: 0,
        title: _isSelectionMode
            ? Text(
                _getVerseReference(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              )
            : SizedBox(
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
                            color: cs.onSurface,
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
                                    color: cs.onSurface,
                                  ),
                                ),
                              )
                            : Marquee(
                                text: fullNameRangeLabel(rangeTitle),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface,
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
              final isSelected = !_isSelectionMode && key == _selectedVerseKey;
              final isInRange = _isVerseInRange(key);
              final prettyKey = _prettyVerseKey(key);

              final match = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(key);
              bool isFavorited = false;
              if (match != null) {
                final shortName = match.group(1)!;
                final bookName = bookFullName[shortName] ?? shortName;
                final chapter = int.parse(match.group(2)!);
                final verse = int.parse(match.group(3)!);
                isFavorited = favoriteProvider.isVerseFavorited(
                  bookName,
                  chapter,
                  verse,
                );
              }

              return _superLightTile(
                verse: prettyKey,
                text: text,
                selected: isSelected,
                isInRange: isInRange,
                isFavorited: isFavorited,
                onTap: () => _handleVerseTap(key),
                onLongPress: () => _handleVerseLongPress(key),
              );
            },
          ),
          if (!_isSelectionMode)
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
                      backgroundColor: cs.surface,
                      foregroundColor: cs.primary,
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
                      backgroundColor: cs.surface,
                      foregroundColor: cs.primary,
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
          if (!_isSelectionMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: widget.hasPrevDay ? widget.onPrevDay : null,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                      label: const Text(
                        '이전 DAY',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: cs.primary,
                        backgroundColor: cs.surface,
                        elevation: 1.5,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        textStyle: const TextStyle(fontSize: 15),
                        disabledForegroundColor: cs.onSurface.withOpacity(0.38),
                        disabledBackgroundColor: cs.surface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: widget.hasNextDay ? widget.onNextDay : null,
                      icon:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      label: const Text(
                        '다음 DAY',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: cs.primary,
                        backgroundColor: cs.surface,
                        elevation: 1.5,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        textStyle: const TextStyle(fontSize: 15),
                        disabledForegroundColor: cs.onSurface.withOpacity(0.38),
                        disabledBackgroundColor: cs.surface.withOpacity(0.5),
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
    required bool isInRange,
    required bool isFavorited,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isInRange
            ? cs.primary.withOpacity(0.25)
            : (selected ? cs.primary.withOpacity(0.15) : null),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  verse,
                  style: TextStyle(
                    fontFamily: 'ChosunCentennial',
                    fontWeight: isInRange || selected
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: isInRange || selected ? 17 : 13,
                    color: isInRange || selected ? cs.primary : cs.onSurface,
                  ),
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
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'ChosunCentennial',
                  fontWeight: isInRange || selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: isInRange || selected ? 16 : 15,
                  color: isInRange || selected ? cs.primary : cs.onSurface,
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
