import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quiz_history.dart';
import '../../services/quiz_history_service.dart';
import '../../utils/responsive_utils.dart';
import 'quiz_history_detail_screen.dart';

/// 퀴즈 히스토리 화면
class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final QuizHistoryService _historyService = QuizHistoryService();
  List<QuizHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _historyService.getHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '퀴즈 기록',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: ResponsiveUtils.appBarTitleFontSize(context),
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cs.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState(cs)
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuizHistoryCard(
                          item: item,
                          onTap: () => _navigateToDetail(item),
                          onDelete: () => _deleteHistoryItem(item.id),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 80,
              color: cs.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '퀴즈 기록이 없습니다',
                style: TextStyle(
                  fontSize: ResponsiveUtils.buttonFontSize(context),
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '퀴즈를 완료하면 여기에 기록이 표시됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveUtils.bodyFontSize(context),
                  color: cs.onSurface.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToDetail(QuizHistoryItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizHistoryDetailScreen(historyItem: item),
      ),
    );
  }

  Future<void> _deleteHistoryItem(String id) async {
    await _historyService.deleteHistory(id);
    await _loadHistory();
  }
}

/// 퀴즈 히스토리 카드
class _QuizHistoryCard extends StatelessWidget {
  final QuizHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuizHistoryCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  void _showDeleteMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: cs.error),
              title: Text(
                '이 기록 삭제',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.close_rounded, color: cs.onSurface),
              title: const Text(
                '취소',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: cs.error),
            const SizedBox(width: 12),
            const Text(
              '기록 삭제',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('이 퀴즈 기록을 삭제하시겠어요?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: Text(
              '삭제',
              style: TextStyle(
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${item.score}',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.appBarTitleFontSize(context),
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quiz type and difficulty
                        Row(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.quizType.displayName,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.captionFontSize(context),
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.difficulty.displayName,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.captionFontSize(context),
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Results
                        Row(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '정답 ',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.bodyFontSize(context),
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${item.correctCount}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.bodyFontSize(context),
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                ' / ${item.totalQuestions}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.bodyFontSize(context),
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Date
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            dateFormat.format(item.completedAt),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.captionFontSize(context),
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu button
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                    onPressed: () => _showDeleteMenu(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
