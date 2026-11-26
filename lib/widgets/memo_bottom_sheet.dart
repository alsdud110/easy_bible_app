import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/favorite_verse.dart';
import '../providers/favorite_provider.dart';
import '../utils/responsive_utils.dart';

/// 북마크에 달린 메모를 보고 쓰는 바텀시트.
/// 본문(verse_list_view)과 북마크 상세 화면이 같이 쓴다.
Future<void> showMemoBottomSheet(BuildContext context, String favoriteKey) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (sheetContext) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(sheetContext),
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          // 키보드가 올라오면 시트도 같이 올라가 입력창이 가려지지 않게
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: MemoBottomSheet(favoriteKey: favoriteKey),
        ),
      ),
    ),
  );
}

class MemoBottomSheet extends StatefulWidget {
  final String favoriteKey;

  const MemoBottomSheet({super.key, required this.favoriteKey});

  @override
  State<MemoBottomSheet> createState() => _MemoBottomSheetState();
}

class _MemoBottomSheetState extends State<MemoBottomSheet> {
  final _memoController = TextEditingController();
  final _focusNode = FocusNode();
  String? _editingMemoId;

  @override
  void initState() {
    super.initState();
    _memoController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _memoController.removeListener(_onTextChanged);
    _memoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  String _formatMemoDateTime(DateTime dateTime) {
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    return DateFormat('MM월 dd일').format(localTime);
  }

  Future<void> _saveMemo() async {
    final content = _memoController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<FavoriteProvider>();
    if (_editingMemoId != null) {
      await provider.updateMemo(widget.favoriteKey, _editingMemoId!, content);
    } else {
      await provider.addMemo(widget.favoriteKey, content);
    }

    if (!mounted) return;
    setState(() {
      _memoController.clear();
      _editingMemoId = null;
    });
    _focusNode.unfocus();
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
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context
          .read<FavoriteProvider>()
          .deleteMemo(widget.favoriteKey, memoId);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final currentFavorite = favoriteProvider.favorites
        .where((f) => f.key == widget.favoriteKey)
        .firstOrNull;
    // 시트가 열린 채로 북마크가 지워진 경우
    if (currentFavorite == null) return const SizedBox.shrink();

    final isEditing = _editingMemoId != null;
    final isEmptyInput = _memoController.text.trim().isEmpty;

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

              // 헤더: 어느 구절의 메모인지 같이 보여 줌
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
                        fontSize: ResponsiveUtils.titleFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentFavorite.reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.captionFontSize(context),
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    if (isEditing)
                      TextButton.icon(
                        onPressed: _cancelEdit,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('취소'),
                      ),
                  ],
                ),
              ),

              // 메모할 구절: 시트가 본문을 가리므로 시트 안에 다시 보여 준다
              _VerseQuote(text: currentFavorite.text),

              const Divider(height: 1),

              // 메모 입력창
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memoController,
                        focusNode: _focusNode,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _saveMemo(),
                        decoration: InputDecoration(
                          hintText:
                              isEditing ? '메모 수정 중...' : '메모를 입력하세요...',
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
                      onPressed: isEmptyInput ? null : _saveMemo,
                      icon: Icon(isEditing ? Icons.check : Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: isEmptyInput
                            ? cs.surfaceContainerHighest
                            : cs.primary,
                        foregroundColor: isEmptyInput
                            ? cs.onSurface.withOpacity(0.3)
                            : cs.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 메모 리스트 (최신순)
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
                                  fontSize:
                                      ResponsiveUtils.bodyFontSize(context),
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
                          final memo = currentFavorite
                              .memos[currentFavorite.memos.length - 1 - index];
                          return _MemoCard(
                            memo: memo,
                            timeLabel: _formatMemoDateTime(memo.createdAt),
                            onEdit: () => _startEditMemo(memo),
                            onDelete: () => _deleteMemo(memo.id),
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

/// 북마크 본문('3절: ...' 줄들)을 인용 블록으로 보여 준다.
/// 범위가 길어도 입력창을 밀어내지 않게 높이를 제한하고 안에서 스크롤.
class _VerseQuote extends StatelessWidget {
  final String text;

  const _VerseQuote({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lines = text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.replaceFirstMapped(
            RegExp(r'^(\d+)절:\s*'), (m) => '${m.group(1)}  '))
        .join('\n');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: cs.primary, width: 3)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Text(
          lines,
          style: TextStyle(
            fontFamily: 'ChosunCentennial',
            fontSize: ResponsiveUtils.bodyFontSize(context),
            color: cs.onSurface.withOpacity(0.85),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _MemoCard extends StatelessWidget {
  final Memo memo;
  final String timeLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemoCard({
    required this.memo,
    required this.timeLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final captionSize = ResponsiveUtils.captionFontSize(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 긴 메모도 글자를 줄이지 않고 여러 줄로 보여 줌
                Expanded(
                  child: Text(
                    memo.content,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.bodyFontSize(context),
                      color: cs.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: cs.onSurface.withOpacity(0.6)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => Future.delayed(Duration.zero, onEdit),
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: cs.primary),
                          const SizedBox(width: 12),
                          const Text('수정'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => Future.delayed(Duration.zero, onDelete),
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: cs.error),
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
                    size: 12, color: cs.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style: TextStyle(
                      fontSize: captionSize,
                      color: cs.onSurface.withOpacity(0.5)),
                ),
                if (memo.updatedAt != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(수정됨)',
                    style: TextStyle(
                      fontSize: captionSize,
                      color: cs.onSurface.withOpacity(0.4),
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
  }
}
