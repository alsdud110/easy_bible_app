import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/favorite_verse.dart';
import '../../providers/favorite_provider.dart';

class FavoriteDetailScreen extends StatefulWidget {
  final FavoriteVerse favorite;

  const FavoriteDetailScreen({
    super.key,
    required this.favorite,
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
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // ✅ 구절 텍스트를 파싱해서 Map으로 변환
  Map<int, String> _parseVerses() {
    final Map<int, String> verses = {};
    final lines = widget.favorite.text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      // "3절: 하나님이..." 형식 파싱
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.favorite.reference} 복사됨'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeFavorite(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('북마크 삭제'),
        content: Text('${widget.favorite.reference}\n북마크를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
        Navigator.pop(context); // 상세 페이지 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.favorite.reference} 삭제됨'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final verses = _parseVerses();
    final verseNums = verses.keys.toList()..sort();

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
          // ✅ 북마크 정보 바 (BreadcrumbBar 스타일과 유사)
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
                Icon(
                  Icons.star,
                  color: Colors.amber[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '북마크',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '추가일: ${_formatDateTime(widget.favorite.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ✅ 구절 목록 (verse_list_view와 동일한 스타일)
          Expanded(
            child: verses.isEmpty
                ? Center(
                    child: Text(
                      '구절을 불러올 수 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: verseNums.length,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, idx) {
                      final verseNum = verseNums[idx];
                      final text = verses[verseNum] ?? '';

                      return Container(
                        key: idx == 0 ? _itemKey : null,
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Text(
                                '$verseNum',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                              ),
                              // ✅ 모든 절에 별표 표시 (북마크된 구절이므로)
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
                              fontWeight: FontWeight.normal,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          dense: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _copyToClipboard(context),
        tooltip: '복사',
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.copy),
      ),
    );
  }
}
