import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../models/quiz_question.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/colors.dart';
import 'quiz_result_screen.dart';

/// 퀴즈 진행 화면
class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionAnimController;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  final ScrollController _scrollController = ScrollController();

  int? _selectedAnswer;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _questionAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _questionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _questionAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _questionAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _questionAnimController.forward();
  }

  @override
  void dispose() {
    _questionAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAnswer(BuildContext context, dynamic answer) {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = answer is bool ? (answer ? 1 : 0) : answer;
      _showFeedback = true;
    });

    final provider = context.read<QuizProvider>();
    provider.submitAnswer(answer);

    // 피드백 영역으로 자동 스크롤
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleNext(BuildContext context) {
    final provider = context.read<QuizProvider>();

    if (provider.currentQuestionIndex < provider.totalQuestions - 1) {
      // 다음 문제로
      provider.nextQuestion();

      setState(() {
        _selectedAnswer = null;
        _showFeedback = false;
      });

      // 애니메이션 리셋 및 재생
      _questionAnimController.reset();
      _questionAnimController.forward();
    } else {
      // 결과 화면으로
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const QuizResultScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        final question = provider.currentQuestion;
        if (question == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              '${provider.currentQuestionIndex + 1} / ${provider.totalQuestions}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _showQuitDialog(context),
            ),
          ),
          body: Column(
            children: [
              // 진행 바
              _buildProgressBar(provider.progress, cs),

              // 문제 영역
              Expanded(
                child: FadeTransition(
                  opacity: _questionFadeAnimation,
                  child: SlideTransition(
                    position: _questionSlideAnimation,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 난이도 뱃지
                                _buildDifficultyBadge(question.difficulty, cs),
                                const SizedBox(height: 12),

                                // 문제 카드
                                _buildQuestionCard(question, cs),
                                const SizedBox(height: 16),

                                // 선택지
                                if (question.isOX)
                                  _buildOXOptions(context, question, cs)
                                else
                                  _buildMultipleChoiceOptions(
                                      context, question, cs),

                                // 피드백
                                if (_showFeedback) ...[
                                  const SizedBox(height: 14),
                                  _buildFeedback(context, question, cs),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // 다음 버튼
                        if (_showFeedback)
                          _buildNextButton(context, provider, cs),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(double progress, ColorScheme cs) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(Difficulty difficulty, ColorScheme cs) {
    Color color;
    switch (difficulty) {
      case Difficulty.easy:
        color = QuizColors.difficultyEasy;
        break;
      case Difficulty.medium:
        color = QuizColors.difficultyMedium;
        break;
      case Difficulty.hard:
        color = QuizColors.difficultyHard;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                difficulty.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                difficulty.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'Q',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.5,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOXOptions(
    BuildContext context,
    QuizQuestion question,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Expanded(
          child: _OXButton(
            isTrue: true,
            isSelected: _selectedAnswer == 1,
            isCorrect: _showFeedback ? question.answer == true : null,
            onTap: _showFeedback ? null : () => _handleAnswer(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OXButton(
            isTrue: false,
            isSelected: _selectedAnswer == 0,
            isCorrect: _showFeedback ? question.answer == false : null,
            onTap: _showFeedback ? null : () => _handleAnswer(context, false),
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceOptions(
    BuildContext context,
    QuizQuestion question,
    ColorScheme cs,
  ) {
    final options = question.options ?? [];
    final labels = ['A', 'B', 'C', 'D'];

    return Column(
      children: List.generate(options.length, (index) {
        // 피드백 시 정답 여부 확인
        bool? isCorrect;
        if (_showFeedback && _selectedAnswer == index) {
          isCorrect = index == question.correctIndex;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: index < options.length - 1 ? 10 : 0),
          child: _AnswerButton(
            label: labels[index],
            subtitle: options[index],
            isSelected: _selectedAnswer == index,
            isCorrect: isCorrect,
            onTap: _showFeedback ? null : () => _handleAnswer(context, index),
          ),
        );
      }),
    );
  }

  Widget _buildFeedback(
    BuildContext context,
    QuizQuestion question,
    ColorScheme cs,
  ) {
    final provider = context.read<QuizProvider>();
    final lastAnswer =
        provider.answers.isNotEmpty ? provider.answers.last : null;
    final isCorrect = lastAnswer?.isCorrect ?? false;

    // 객관식의 경우 정답 텍스트 가져오기
    String? correctAnswerText;
    if (!question.isOX &&
        question.options != null &&
        question.correctIndex != null) {
      final labels = ['A', 'B', 'C', 'D'];
      correctAnswerText =
          '${labels[question.correctIndex!]}. ${question.options![question.correctIndex!]}';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Sparkle animation for correct answer
          if (isCorrect)
            Positioned(
              top: -25,
              child: Lottie.asset(
                'assets/lottie/sparkle.json',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCorrect
                  ? QuizColors.correct.withValues(alpha: 0.1)
                  : QuizColors.incorrect.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCorrect ? QuizColors.correct : QuizColors.incorrect,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color:
                          isCorrect ? QuizColors.correct : QuizColors.incorrect,
                      size: 26,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      isCorrect ? '정답이에요!' : '아쉬워요!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isCorrect
                            ? QuizColors.correct
                            : QuizColors.incorrect,
                      ),
                    ),
                  ],
                ),
                // 오답인 경우 정답 표시
                if (!isCorrect && correctAnswerText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          color: QuizColors.correct,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '정답',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: QuizColors.correct,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                correctAnswerText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (question.reference != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: cs.primary,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          question.reference!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (question.explanation != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    question.explanation!,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.75),
                      height: 1.4,
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

  Widget _buildNextButton(
    BuildContext context,
    QuizProvider provider,
    ColorScheme cs,
  ) {
    final isLastQuestion =
        provider.currentQuestionIndex >= provider.totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _handleNext(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              isLastQuestion ? '결과 보기' : '다음 문제',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
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
              '퀴즈 종료',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('퀴즈를 종료하시겠어요?\n진행 상황이 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '계속하기',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              '종료',
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
}

// OX 버튼
class _OXButton extends StatelessWidget {
  final bool isTrue;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback? onTap;

  const _OXButton({
    required this.isTrue,
    required this.isSelected,
    this.isCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected ? cs.primary : cs.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isTrue ? 'O' : 'X',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
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

// 답변 버튼
class _AnswerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback? onTap;

  const _AnswerButton({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    this.isCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 배경색: 정답일 때만 초록색, 나머지는 기본
    Color backgroundColor;
    if (isCorrect == true) {
      backgroundColor = QuizColors.correct.withValues(alpha: 0.15);
    } else {
      backgroundColor = cs.surface;
    }

    // Border 색상: 선택되었을 때만 표시
    Color borderColor;
    if (isCorrect == true) {
      borderColor = QuizColors.correct;
    } else if (isSelected) {
      borderColor = cs.primary;
    } else {
      borderColor = cs.outline.withValues(alpha: 0.15);
    }

    // 텍스트 색상
    Color textColor;
    textColor = cs.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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
