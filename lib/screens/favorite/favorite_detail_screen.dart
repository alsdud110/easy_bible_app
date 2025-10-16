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
  final _memoController = TextEditingController();
  final _focusNode = FocusNode(); // ✅ FocusNode 추가
  String? _editingMemoId;

  @override
  void initState() {
    super.initState();
    // ✅ 텍스트 변경 감지하여 UI 업데이트
    _memoController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _scrollController.dispose();
    _focusNode.dispose(); // ✅ FocusNode dispose
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  String _formatMemoDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM월 dd일').format(dateTime);
    }
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
        title: const Text('즐겨찾기 삭제'),
        content: Text('${widget.favorite.reference}\n즐겨찾기를 삭제하시겠습니까?'),
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
        Navigator.pop(context);
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

  // ✅ 메모 추가/수정
  Future<void> _saveMemo() async {
    final content = _memoController.text.trim();
    if (content.isEmpty) return;

    if (_editingMemoId != null) {
      // 수정
      await context.read<FavoriteProvider>().updateMemo(
            widget.favorite.key,
            _editingMemoId!,
            content,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 수정되었습니다'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // 추가
      await context.read<FavoriteProvider>().addMemo(
            widget.favorite.key,
            content,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 추가되었습니다'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _memoController.clear();
        _editingMemoId = null;
      });
      // ✅ 포커스 다시 주기
      _focusNode.requestFocus();
    }
  }

  // ✅ 메모 삭제
  Future<void> _deleteMemo(String memoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제하시겠습니까?'),
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

    if (confirm == true && mounted) {
      await context.read<FavoriteProvider>().deleteMemo(
            widget.favorite.key,
            memoId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 삭제되었습니다'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ 메모 수정 모드
  void _startEditMemo(Memo memo) {
    setState(() {
      _editingMemoId = memo.id;
      _memoController.text = memo.content;
    });
    _focusNode.requestFocus();
  }

  // ✅ 수정 취소
  void _cancelEdit() {
    setState(() {
      _editingMemoId = null;
      _memoController.clear();
    });
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
      resizeToAvoidBottomInset: true, // ✅ 키보드에 맞춰 리사이즈
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
          // ✅ 즐겨찾기 정보 바
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
                        '즐겨찾기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '추가일: ${_formatDateTime(currentFavorite.createdAt)}',
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

          // ✅ 구절 목록
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

          // ✅ 메모 섹션 (맨 아래) - SingleChildScrollView 제거
          SafeArea(
            // ✅ SafeArea로 감싸기
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ 최소 크기만 사용
                children: [
                  // 메모 리스트
                  if (currentFavorite.memos.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.25,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: currentFavorite.memos.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final memo = currentFavorite.memos[index];
                          return _MemoItem(
                            memo: memo,
                            onEdit: () => _startEditMemo(memo),
                            onDelete: () => _deleteMemo(memo.id),
                            formatDateTime: _formatMemoDateTime,
                          );
                        },
                      ),
                    ),

                  // ✅ 메모 입력창 (수정됨)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // ✅ 패딩 축소
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.3),
                      border: Border(
                        top: BorderSide(
                          color: cs.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 100, // ✅ 최대 높이 줄임
                            ),
                            child: TextField(
                              controller: _memoController,
                              focusNode: _focusNode, // ✅ FocusNode 연결
                              maxLines: null,
                              minLines: 1,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: _editingMemoId != null
                                    ? '메모 수정 중...'
                                    : '메모를 입력하세요...',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(20), // ✅ 조금 작게
                                  borderSide: BorderSide(
                                    color: cs.outline.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: cs.outline.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: cs.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: cs.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                isDense: true, // ✅ 컴팩트하게
                                suffixIcon: _editingMemoId != null
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: _cancelEdit,
                                        tooltip: '취소',
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _memoController.text.trim().isEmpty
                              ? null
                              : _saveMemo,
                          icon: Icon(
                            _editingMemoId != null ? Icons.check : Icons.send,
                            size: 20, // ✅ 아이콘 크기 조정
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _memoController.text.trim().isEmpty
                                ? cs.surfaceContainerHighest.withOpacity(0.5)
                                : cs.primary,
                            foregroundColor: _memoController.text.trim().isEmpty
                                ? cs.onSurface.withOpacity(0.3)
                                : cs.onPrimary,
                            disabledBackgroundColor:
                                cs.surfaceContainerHighest.withOpacity(0.5),
                            disabledForegroundColor:
                                cs.onSurface.withOpacity(0.3),
                            padding: const EdgeInsets.all(10), // ✅ 패딩 조정
                          ),
                          tooltip: _editingMemoId != null ? '저장' : '전송',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ 메모 아이템 위젯
class _MemoItem extends StatelessWidget {
  final Memo memo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(DateTime) formatDateTime;

  const _MemoItem({
    required this.memo,
    required this.onEdit,
    required this.onDelete,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  memo.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: cs.onSurface.withOpacity(0.6),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        const Text('수정'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: cs.error),
                        const SizedBox(width: 8),
                        const Text('삭제'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatDateTime(memo.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              if (memo.updatedAt != null) ...[
                const SizedBox(width: 4),
                Text(
                  '(수정됨)',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
