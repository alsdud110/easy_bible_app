import 'package:flutter/material.dart';
import '../../models/quiz_history.dart';
import '../../utils/responsive_utils.dart';

/// 퀴즈 히스토리 상세 화면 - 각 문제별 정답/오답 보기
class QuizHistoryDetailScreen extends StatefulWidget {
  final QuizHistoryItem historyItem;

  const QuizHistoryDetailScreen({
    super.key,
    required this.historyItem,
  });

  @override
  State<QuizHistoryDetailScreen> createState() =>
      _QuizHistoryDetailScreenState();
}

class _QuizHistoryDetailScreenState extends State<QuizHistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            '퀴즈 상세 결과',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: ResponsiveUtils.appBarTitleFontSize(context),
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cs.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: cs.primary,
              width: 2.0,
            ),
          ),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.bodyFontSize(context),
          ),
          tabs: [
            Tab(
              text: '전체 (${widget.historyItem.totalQuestions})',
            ),
            Tab(
              text: '정답 (${widget.historyItem.correctCount})',
            ),
            Tab(
              text: '오답 (${widget.historyItem.incorrectCount})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 요약 카드
          _buildSummaryCard(cs),
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionList(widget.historyItem.answerRecords, cs),
                _buildQuestionList(widget.historyItem.correctAnswers, cs),
                _buildQuestionList(widget.historyItem.incorrectAnswers, cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs) {
    final item = widget.historyItem;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '점수',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.captionFontSize(context),
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${item.score}점',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: cs.outline.withValues(alpha: 0.2),
          ),
          // Stats
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(
                    '정답률',
                    '${(item.accuracy * 100).toStringAsFixed(1)}%',
                    cs,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '문제',
                    '${item.correctCount}/${item.totalQuestions}',
                    cs,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.captionFontSize(context),
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.bodyFontSize(context),
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionList(
      List<QuizAnswerRecord> records, ColorScheme cs) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: cs.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '문제가 없습니다',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.buttonFontSize(context),
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _QuestionCard(
            record: record,
            questionNumber: index + 1,
          ),
        );
      },
    );
  }
}

/// 문제 카드
class _QuestionCard extends StatelessWidget {
  final QuizAnswerRecord record;
  final int questionNumber;

  const _QuestionCard({
    required this.record,
    required this.questionNumber,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final question = record.question;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Question number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$questionNumber',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.bodyFontSize(context),
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Difficulty
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    question.difficulty.displayName,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.captionFontSize(context),
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const Spacer(),
                // Result indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: record.isCorrect
                        ? cs.surfaceContainerHighest
                        : cs.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        record.isCorrect
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 16,
                        color: record.isCorrect
                            ? cs.onSurface.withValues(alpha: 0.6)
                            : cs.error,
                      ),
                      const SizedBox(width: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          record.isCorrect ? '정답' : '오답',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.captionFontSize(context),
                            fontWeight: FontWeight.w700,
                            color: record.isCorrect
                                ? cs.onSurface.withValues(alpha: 0.6)
                                : cs.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outline.withValues(alpha: 0.08),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    question.question,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.bodyFontSize(context),
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // User answer
                _buildAnswerRow(
                  '내 답변',
                  record.userAnswerText,
                  record.isCorrect,
                  cs,
                  context,
                ),

                // Correct answer if wrong
                if (!record.isCorrect) ...[
                  const SizedBox(height: 10),
                  _buildAnswerRow(
                    '정답',
                    record.correctAnswerText,
                    true,
                    cs,
                    context,
                  ),
                ],

                // Reference
                if (question.reference != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          question.reference!,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.captionFontSize(context),
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Explanation
                if (question.explanation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: cs.onSurface.withValues(alpha: 0.4),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              question.explanation!,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.captionFontSize(context),
                                color: cs.onSurface.withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(
      String label, String answer, bool isCorrect, ColorScheme cs, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.only(top: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.captionFontSize(context),
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              answer,
              style: TextStyle(
                fontSize: ResponsiveUtils.bodyFontSize(context),
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
