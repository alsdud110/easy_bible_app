import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/pretty_range_label.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/highlight_provider.dart';
import '../../providers/plan_progress_provider.dart';
import '../../models/favorite_verse.dart';
import '../../models/highlight_verse.dart';
import '../../models/const/book_full_name.dart';
import '../../models/plan_progress.dart';
import 'package:marquee/marquee.dart';

class PlanVerseListView extends StatefulWidget {
  final String title;
  final Map<String, String> verses;
  final int? dayNumber; // Day 번호 (1, 2, 3, ...)
  final PlanType? planType; // 플랜 타입 (day60, day120, day180)
  final VoidCallback onBack;
  final VoidCallback? onPrevDay;
  final VoidCallback? onNextDay;
  final bool hasPrevDay;
  final bool hasNextDay;

  const PlanVerseListView({
    super.key,
    required this.title,
    required this.verses,
    this.dayNumber,
    this.planType,
    required this.onBack,
    this.onPrevDay,
    this.onNextDay,
    this.hasPrevDay = false,
    this.hasNextDay = false,
  });

  @override
  State<PlanVerseListView> createState() => _PlanVerseListViewState();
}

class _PlanVerseListViewState extends State<PlanVerseListView>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  late String _selectedVerseKey;
  bool _showFAB = false;

  String? _rangeStart;
  String? _rangeEnd;
  bool _isSelectionMode = false;

  // ⭐ 플로팅 액션 바 애니메이션
  late AnimationController _floatingActionBarController;
  late Animation<double> _floatingActionBarScale;
  late Animation<double> _floatingActionBarOpacity;

  // ⭐ 하이라이트 관련 애니메이션
  late AnimationController _highlightPickerController;
  late AnimationController _highlightAppliedController;

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

    _highlightPickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _highlightAppliedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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
    _floatingActionBarController.dispose();
    _highlightPickerController.dispose();
    _highlightAppliedController.dispose();
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
    HapticFeedback.mediumImpact();

    setState(() {
      _selectedVerseKey = verseKey;
      _isSelectionMode = true;
      _rangeStart = verseKey;
      _rangeEnd = verseKey;
    });

    // ⭐ 애니메이션 시작
    _floatingActionBarController.forward(from: 0);
  }

  void _handleVerseTap(String verseKey) {
    if (_isSelectionMode) {
      HapticFeedback.lightImpact();
      setState(() {
        // ⭐ 스마트 범위 선택 로직
        // 현재 범위가 있는 경우
        if (_rangeStart != null && _rangeEnd != null) {
          final keys = widget.verses.keys.toList();
          final startIdx = keys.indexOf(_rangeStart!);
          final endIdx = keys.indexOf(_rangeEnd!);
          final clickedIdx = keys.indexOf(verseKey);

          if (startIdx != -1 && endIdx != -1 && clickedIdx != -1) {
            final currentStart = startIdx < endIdx ? startIdx : endIdx;
            final currentEnd = startIdx > endIdx ? startIdx : endIdx;

            // 클릭한 절이 현재 범위보다 앞에 있으면 앞으로 확장
            if (clickedIdx < currentStart) {
              _rangeStart = verseKey;
              _rangeEnd = keys[currentEnd];
            }
            // 클릭한 절이 현재 범위보다 뒤에 있으면 뒤로 확장
            else if (clickedIdx > currentEnd) {
              _rangeStart = keys[currentStart];
              _rangeEnd = verseKey;
            }
            // 클릭한 절이 범위 내에 있으면 그 절만 선택
            else {
              _rangeStart = verseKey;
              _rangeEnd = verseKey;
            }
          } else {
            // 인덱스를 찾을 수 없으면 기존 로직
            _rangeEnd = verseKey;
          }
        } else {
          // 범위가 없으면 기존 로직
          _rangeEnd = verseKey;
        }
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

    // 각 구절에 대해 하이라이트 추가
    for (final key in selectedVerses) {
      final match = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(key);
      if (match == null) continue;

      final shortName = match.group(1)!;
      final bookName = bookFullName[shortName] ?? shortName;
      final chapter = int.parse(match.group(2)!);
      final verse = int.parse(match.group(3)!);

      final highlight = HighlightVerse(
        bookName: bookName,
        chapter: chapter,
        startVerse: verse,
        endVerse: verse,
        color: color,
        createdAt: now,
      );

      await highlightProvider.addHighlight(highlight);
    }

    _highlightAppliedController.forward(from: 0).then((_) {
      _highlightAppliedController.reset();
    });

    if (!mounted) return;

    _exitSelectionMode();
  }

  void _exitSelectionMode() {
    _floatingActionBarController.reverse(); // ⭐ 애니메이션 역재생

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

  // ⭐ 플로팅 액션 바 위젯
  Widget _buildFloatingActionBar() {
    if (!_isSelectionMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16, // 화면 하단에서 16px 위
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
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
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
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                // 북마크 버튼
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.star_border,
                    label: '북마크',
                    onPressed: _addToFavorites,
                    color: Colors.amber.shade700,
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
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
    final verseKeys = widget.verses.keys.toList();
    final titleArr = widget.title.split('  ');
    final dayTitle = titleArr.isNotEmpty ? titleArr[0] : '';
    final rangeTitle = titleArr.length > 1 ? titleArr[1] : '';
    final favoriteProvider = context.watch<FavoriteProvider>();
    final highlightProvider = context.watch<HighlightProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        leading: _isSelectionMode
            ? BackButton(
                onPressed: _exitSelectionMode,
                color: theme.appBarTheme.iconTheme?.color,
              )
            : BackButton(
                onPressed: widget.onBack,
                color: theme.appBarTheme.iconTheme?.color,
              ),
        actions: const [SizedBox(width: 48)],
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
              HighlightVerse? highlight;
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
                highlight = highlightProvider.getVerseHighlight(
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
                highlight: highlight,
                onTap: () => _handleVerseTap(key),
                onLongPress: () => _handleVerseLongPress(key),
              );
            },
          ),
          // ⭐ 플로팅 액션 바
          _buildFloatingActionBar(),
          if (!_isSelectionMode)
            Positioned(
              right: 18,
              bottom: widget.dayNumber != null ? 88 : 24,
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
          if (!_isSelectionMode && widget.dayNumber != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Consumer<PlanProgressProvider>(
                builder: (context, planProvider, _) {
                  final isCompleted = widget.planType != null && widget.dayNumber != null
                      ? planProvider.isDayCompleted(widget.planType!, widget.dayNumber!)
                      : false;

                  return AnimatedOpacity(
                    opacity: isCompleted ? 0.6 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton.icon(
                      onPressed: isCompleted
                          ? null
                          : () async {
                              if (widget.planType != null && widget.dayNumber != null) {
                                await planProvider
                                    .markDayAsCompleted(widget.planType!, widget.dayNumber!);

                                if (!mounted) return;

                                // 완주 체크
                                if (planProvider.isPlanCompleted(widget.planType!)) {
                                  _showCompletionDialog();
                                } else {
                                  _showDayCompletionDialog();
                                }
                              }
                            },
                      icon: Icon(
                        isCompleted ? Icons.check_circle : Icons.check,
                        size: 20,
                      ),
                      label: Text(
                        isCompleted ? '일독 완료' : '일독 완료',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            isCompleted ? cs.onSurface : Colors.white,
                        backgroundColor: isCompleted ? cs.surface : Colors.green,
                        elevation: isCompleted ? 0 : 2,
                        shadowColor:
                            isCompleted ? null : Colors.green.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  );
                },
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
    HighlightVerse? highlight,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isHighlighted = highlight != null;

    Color? backgroundColor;
    Color? borderColor;

    if (isInRange) {
      backgroundColor = cs.primary.withOpacity(0.25);
    } else if (isHighlighted) {
      backgroundColor = highlight.color.color;
      borderColor = highlight.color.darkColor;
    } else if (selected) {
      backgroundColor = cs.primary.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isHighlighted
              ? Border(
                  left: BorderSide(
                    color: borderColor ?? Colors.transparent,
                    width: 4,
                  ),
                )
              : null,
        ),
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
                    fontSize: isInRange || selected ? 13.01 : 13,
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
                  fontSize: isInRange || selected ? 15.01 : 15,
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

  // 완주 축하 다이얼로그
  void _showCompletionDialog() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final planProvider = context.read<PlanProgressProvider>();
    final elapsedDays = widget.planType != null
        ? planProvider.getElapsedDays(widget.planType!)
        : 0;
    final totalDays = widget.planType != null
        ? planProvider.getTotalDays(widget.planType!)
        : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 애니메이션 아이콘
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '축하합니다!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$elapsedDays일 만에\n성경 ${totalDays}일 통독을 완주하셨네요!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                  height: 1.6,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '정말 대단합니다! 👏',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Day 완료 작은 팝업
  void _showDayCompletionDialog() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 체크 아이콘 애니메이션
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 36,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DAY ${widget.dayNumber} 일독!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '축하합니다! 🎉',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
