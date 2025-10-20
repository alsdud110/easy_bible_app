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
  bool _showMemoSheet = false;

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
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('yyyy-MM-dd HH:mm').format(localTime);
  }

  String _formatMemoDateTime(DateTime dateTime) {
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    return DateFormat('MM월 dd일').format(localTime);
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
      _focusNode.unfocus();
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
      await context
          .read<FavoriteProvider>()
          .deleteMemo(widget.favorite.key, memoId);
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
    _focusNode.unfocus();
  }

  void _toggleMemoSheet() {
    setState(() {
      _showMemoSheet = !_showMemoSheet;
    });
    if (_showMemoSheet) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: GestureDetector(
            onTap: () {},
            child: _MemoBottomSheet(
              favoriteKey: widget.favorite.key,
              memoController: _memoController,
              focusNode: _focusNode,
              editingMemoId: _editingMemoId,
              onSave: _saveMemo,
              onEdit: _startEditMemo,
              onDelete: _deleteMemo,
              onCancelEdit: _cancelEdit,
              formatDateTime: _formatMemoDateTime,
            ),
          ),
        ),
      ).then((_) {
        setState(() {
          _showMemoSheet = false;
        });
      });
    }
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
                Icon(Icons.star, color: Colors.amber[700], size: 20),
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
                        '추가일: ${_formatDateTime(currentFavorite.createdAt)}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withOpacity(0.6)),
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
                          fontSize: 14, color: cs.onSurface.withOpacity(0.5)),
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
                              Text(
                                '$verseNum',
                                style: TextStyle(
                                  fontFamily: 'ChosunCentennial',
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
                                fontFamily: 'ChosunCentennial',
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
      floatingActionButton: FloatingActionButton.extended(
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
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '${currentFavorite.memos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: const Text('메모'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// 메모 바텀시트
class _MemoBottomSheet extends StatefulWidget {
  final String favoriteKey;
  final TextEditingController memoController;
  final FocusNode focusNode;
  final String? editingMemoId;
  final VoidCallback onSave;
  final Function(Memo) onEdit;
  final Function(String) onDelete;
  final VoidCallback onCancelEdit;
  final String Function(DateTime) formatDateTime;

  const _MemoBottomSheet({
    required this.favoriteKey,
    required this.memoController,
    required this.focusNode,
    required this.editingMemoId,
    required this.onSave,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelEdit,
    required this.formatDateTime,
  });

  @override
  State<_MemoBottomSheet> createState() => _MemoBottomSheetState();
}

class _MemoBottomSheetState extends State<_MemoBottomSheet> {
  @override
  void initState() {
    super.initState();
    widget.memoController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.memoController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final currentFavorite = favoriteProvider.favorites.firstWhere(
      (f) => f.key == widget.favoriteKey,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 헤더
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.sticky_note_2, size: 24, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (widget.editingMemoId != null)
                      TextButton.icon(
                        onPressed: widget.onCancelEdit,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('취소'),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 메모 입력창
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.memoController,
                        focusNode: widget.focusNode,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => widget.onSave(),
                        decoration: InputDecoration(
                          hintText: widget.editingMemoId != null
                              ? '메모 수정 중...'
                              : '메모를 입력하세요...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: widget.memoController.text.trim().isEmpty
                          ? null
                          : widget.onSave,
                      icon: Icon(widget.editingMemoId != null
                          ? Icons.check
                          : Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            widget.memoController.text.trim().isEmpty
                                ? cs.surfaceContainerHighest
                                : cs.primary,
                        foregroundColor:
                            widget.memoController.text.trim().isEmpty
                                ? cs.onSurface.withOpacity(0.3)
                                : cs.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 메모 리스트
              Expanded(
                child: currentFavorite.memos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 64, color: cs.onSurface.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              '작성된 메모가 없습니다',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: cs.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: currentFavorite.memos.length,
                        itemBuilder: (context, index) {
                          final reversedIndex =
                              currentFavorite.memos.length - 1 - index;
                          final memo = currentFavorite.memos[reversedIndex];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          memo.content,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: cs.onSurface,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton(
                                        icon: Icon(Icons.more_vert,
                                            size: 20,
                                            color:
                                                cs.onSurface.withOpacity(0.6)),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            onTap: () => Future.delayed(
                                                Duration.zero,
                                                () => widget.onEdit(memo)),
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit,
                                                    size: 18,
                                                    color: cs.primary),
                                                const SizedBox(width: 12),
                                                const Text('수정'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            onTap: () => Future.delayed(
                                                Duration.zero,
                                                () => widget.onDelete(memo.id)),
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 18, color: cs.error),
                                                const SizedBox(width: 12),
                                                const Text('삭제'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 12,
                                          color: cs.onSurface.withOpacity(0.5)),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.formatDateTime(memo.createdAt),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                cs.onSurface.withOpacity(0.5)),
                                      ),
                                      if (memo.updatedAt != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(수정됨)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                cs.onSurface.withOpacity(0.4),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
