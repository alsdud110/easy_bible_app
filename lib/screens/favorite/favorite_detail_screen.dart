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
  final _focusNode = FocusNode();
  String? _editingMemoId;

  @override
  void initState() {
    super.initState();
    _memoController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  String _formatMemoDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    return DateFormat('MM월 dd일').format(dateTime);
  }

  Map<int, String> _parseVerses() {
    final Map<int, String> verses = {};
    final lines = widget.favorite.text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      // ✅ 끝 앵커는 \$ 가 아니라 $ 여야 함
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  Future<void> _saveMemo() async {
    final content = _memoController.text.trim();
    if (content.isEmpty) return;

    if (_editingMemoId != null) {
      await context.read<FavoriteProvider>().updateMemo(
            widget.favorite.key,
            _editingMemoId!,
            content,
          );
    } else {
      await context.read<FavoriteProvider>().addMemo(
            widget.favorite.key,
            content,
          );
    }

    if (mounted) {
      setState(() {
        _memoController.clear();
        _editingMemoId = null;
      });
      _focusNode.requestFocus();
    }
  }

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    }
  }

  void _startEditMemo(Memo memo) {
    setState(() {
      _editingMemoId = memo.id;
      _memoController.text = memo.content;
    });
    _focusNode.requestFocus();
  }

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
      resizeToAvoidBottomInset: false, // 바텀시트가 자체적으로 처리
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
      body: Stack(
        children: [
          // 상단 본문(구절 리스트)
          Column(
            children: [
              // 즐겨찾기 정보 바
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Icon(Icons.star, color: Colors.amber[700], size: 20),
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
                                color: cs.onSurface.withOpacity(0.6)),
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
                        child: Text(
                          '구절을 불러올 수 없습니다',
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withOpacity(0.5)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                            bottom: 140), // 바텀시트와 겹침 방지 여유
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
                                    child: Icon(Icons.star,
                                        size: 12, color: Colors.amber[700]),
                                  ),
                                ],
                              ),
                              title: Text(
                                text,
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15,
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

          // 하단 드래그 가능한 메모 시트
          DraggableScrollableSheet(
            // 입력창이 항상 살짝 보이도록 초기/최소 높이 설정
            initialChildSize: 0.16,
            minChildSize: 0.16,
            maxChildSize: 0.9,
            snap: true,
            builder: (context, sheetScrollController) {
              final cs = Theme.of(context).colorScheme;

              return Material(
                elevation: 12,
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    controller: sheetScrollController, // ✅ 시트 드래그 연동
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 손잡이
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: cs.onSurface.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),

                        // 타이틀 바
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.sticky_note_2_outlined,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Text('메모',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface)),
                              const Spacer(),
                              if (_editingMemoId != null)
                                TextButton.icon(
                                  onPressed: _cancelEdit,
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('수정 취소'),
                                ),
                            ],
                          ),
                        ),

                        // ✅ 입력창 — 시트를 다 올렸을 때 타이틀 바로 아래에 위치
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 120),
                                  child: TextField(
                                    controller: _memoController,
                                    focusNode: _focusNode,
                                    maxLines: null,
                                    minLines: 1,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    decoration: InputDecoration(
                                      hintText: _editingMemoId != null
                                          ? '메모 수정 중...'
                                          : '메모를 입력하세요...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: cs.outline.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: cs.outline.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: cs.primary, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: cs.surface,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      suffixIcon: _editingMemoId != null
                                          ? IconButton(
                                              icon: const Icon(Icons.close,
                                                  size: 18),
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
                                    _editingMemoId != null
                                        ? Icons.check
                                        : Icons.send,
                                    size: 20),
                                tooltip: _editingMemoId != null ? '저장' : '전송',
                              ),
                            ],
                          ),
                        ),

                        if (currentFavorite.memos.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 20),
                          ),

                        // 메모 리스트 — 입력창 아래로 배치
                        if (currentFavorite.memos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 24),
                            child: Text(
                              '작성된 메모가 없습니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.5)),
                            ),
                          )
                        else
                          ...List.generate(currentFavorite.memos.length,
                              (index) {
                            final reversedIndex =
                                currentFavorite.memos.length - 1 - index;
                            final memo = currentFavorite.memos[reversedIndex];
                            print(
                                'reversed: $reversedIndex (orig index: $index)');
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: _MemoItem(
                                memo: memo,
                                onEdit: () => _startEditMemo(memo),
                                onDelete: () => _deleteMemo(memo.id),
                                formatDateTime: _formatMemoDateTime,
                              ),
                            );
                          }),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  memo.content,
                  style:
                      TextStyle(fontSize: 14, color: cs.onSurface, height: 1.4),
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert,
                    size: 18, color: cs.onSurface.withOpacity(0.6)),
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
                    fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
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
