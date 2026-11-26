import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../models/favorite_verse.dart';
import '../../providers/favorite_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/memo_bottom_sheet.dart';

class FavoriteDetailScreen extends StatefulWidget {
  final FavoriteVerse favorite;
  // 본문에서 메모 버튼/화살표로 들어오면 메모 시트를 바로 연다
  final bool openMemoOnStart;

  const FavoriteDetailScreen({
    super.key,
    required this.favorite,
    this.openMemoOnStart = false,
  });

  @override
  State<FavoriteDetailScreen> createState() => _FavoriteDetailScreenState();
}

class _FavoriteDetailScreenState extends State<FavoriteDetailScreen> {
  final _scrollController = ScrollController();
  final _itemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.openMemoOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _toggleMemoSheet();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('yyyy-MM-dd HH:mm').format(localTime);
  }

  Map<int, String> _parseVerses() {
    final Map<int, String> verses = {};
    final lines = widget.favorite.text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final match = RegExp(r'^(\d+)절:\s*(.+)$').firstMatch(line);
      if (match != null) {
        final verseNum = int.parse(match.group(1)!);
        final text = match.group(2)!;
        verses[verseNum] = text;
      }
    }
    return verses;
  }

  void _copyToClipboard(BuildContext context) {
    final fullText = '${widget.favorite.reference}\n\n${widget.favorite.text}';
    Clipboard.setData(ClipboardData(text: fullText));
    toastification.show(
      context: context,
      title: const Text('클립보드에 복사되었습니다'),
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.bottomCenter,
      style: ToastificationStyle.flat,
      backgroundColor: Colors.black87,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      showProgressBar: false,
    );
  }

  Future<void> _removeFavorite(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('북마크 삭제'),
        content: Text('${widget.favorite.reference}북마크를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context
          .read<FavoriteProvider>()
          .removeFavorite(widget.favorite.key);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _toggleMemoSheet() {
    showMemoBottomSheet(context, widget.favorite.key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final verses = _parseVerses();
    final verseNums = verses.keys.toList()..sort();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final currentFavorite = favoriteProvider.favorites.firstWhere(
      (f) => f.key == widget.favorite.key,
      orElse: () => widget.favorite,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.favorite.reference,
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        centerTitle: theme.appBarTheme.centerTitle ?? true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context),
            tooltip: '복사',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _removeFavorite(context),
            tooltip: '삭제',
          ),
        ],
      ),
      body: Column(
        children: [
          // 즐겨찾기 정보 바
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: cs.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: QuizColors.star, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '북마크',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.captionFontSize(context),
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '추가일: ${_formatDateTime(currentFavorite.createdAt)}',
                          style: TextStyle(
                              fontSize:
                                  ResponsiveUtils.captionFontSize(context),
                              color: cs.onSurface.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 구절 리스트
          Expanded(
            child: verses.isEmpty
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '구절을 불러올 수 없습니다',
                        style: TextStyle(
                            fontSize: ResponsiveUtils.bodyFontSize(context),
                            color: cs.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: verseNums.length,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, idx) {
                      final verseNum = verseNums[idx];
                      final text = verses[verseNum] ?? '';
                      return Container(
                        key: idx == 0 ? _itemKey : null,
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$verseNum',
                                  style: TextStyle(
                                    fontFamily: 'ChosunCentennial',
                                    fontWeight: FontWeight.w600,
                                    fontSize:
                                        ResponsiveUtils.bodyFontSize(context),
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -10,
                                child: Icon(Icons.star,
                                    size: 12, color: QuizColors.star),
                              ),
                            ],
                          ),
                          title: Text(
                            text,
                            style: TextStyle(
                                fontFamily: 'ChosunCentennial',
                                fontWeight: FontWeight.normal,
                                fontSize: ResponsiveUtils.bodyFontSize(context),
                                color: cs.onSurface),
                          ),
                          dense: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: FloatingActionButton.extended(
          onPressed: _toggleMemoSheet,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.sticky_note_2),
              if (currentFavorite.memos.isNotEmpty)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      // 메모 개수 배지: 오류가 아니므로 강조색(버건디)
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '${currentFavorite.memos.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: const Text('메모하기'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
