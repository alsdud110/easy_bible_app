import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_result.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/colors.dart';
import 'quiz_home_screen.dart';
import 'quiz_play_screen.dart';

/// 퀴즈 결과 화면
class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        final result = provider.getResult();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              '퀴즈 완료',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () {
                provider.resetQuiz();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 점수 카드
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildScoreCard(result, cs),
                  ),
                  const SizedBox(height: 32),

                  // 별점
                  _buildStarRating(result.stars, cs),
                  const SizedBox(height: 16),

                  // 피드백 메시지
                  _buildFeedbackMessage(result, cs),
                  const SizedBox(height: 32),

                  // 상세 결과
                  _buildDetailedStats(result, cs),
                  const SizedBox(height: 32),

                  // 난이도별 통계
                  _buildDifficultyStats(result, cs),
                  const SizedBox(height: 32),

                  // 버튼들
                  _buildButtons(context, provider, cs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(QuizResult result, ColorScheme cs) {
    // Determine which animation to show based on score
    String lottieAsset;
    if (result.score == 100) {
      lottieAsset = 'assets/lottie/trophy.json'; // Perfect score
    } else if (result.score >= 80) {
      lottieAsset = 'assets/lottie/success.json'; // High score
    } else {
      lottieAsset = 'assets/lottie/celebration.json'; // Completion
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Lottie animation based on score with glowing background
          Stack(
            alignment: Alignment.center,
            children: [
              // Glowing background
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Container(
                    width: 100 * value,
                    height: 100 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3 * value),
                          Colors.white.withValues(alpha: 0.1 * value),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
              // Lottie animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Lottie.asset(
                  lottieAsset,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '최종 점수',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: result.score),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '$value점',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '${result.correctCount}개 정답 / ${result.totalQuestions}문제',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double stars, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        // 각 별의 채움 정도 계산 (0.0 ~ 1.0)
        double fillAmount;
        if (stars >= index + 1) {
          fillAmount = 1.0; // 완전히 채움
        } else if (stars > index) {
          fillAmount = stars - index; // 부분적으로 채움 (예: 0.5)
        } else {
          fillAmount = 0.0; // 채우지 않음
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: fillAmount),
            duration: Duration(milliseconds: 800 + (index * 200)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (value * 0.5), // 크기도 함께 애니메이션
                child: Stack(
                  children: [
                    // 배경 별 (회색)
                    Icon(
                      Icons.star_rounded,
                      size: 48,
                      color: cs.outline.withValues(alpha: 0.2),
                    ),
                    // 채워지는 별 (노란색) - ShaderMask로 왼쪽부터 채움
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            QuizColors.star,
                            QuizColors.star,
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: [0.0, value, value, 1.0],
                        ).createShader(bounds);
                      },
                      child: const Icon(
                        Icons.star_rounded,
                        size: 48,
                        color: QuizColors.star,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackMessage(QuizResult result, ColorScheme cs) {
    return Text(
      result.feedbackMessage,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: cs.onSurface.withValues(alpha: 0.7),
        height: 1.5,
      ),
    );
  }

  Widget _buildDetailedStats(QuizResult result, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '상세 결과',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatRow(
            icon: Icons.check_circle_rounded,
            label: '정답',
            value: '${result.correctCount}개',
            color: QuizColors.correct,
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.cancel_rounded,
            label: '오답',
            value: '${result.incorrectCount}개',
            color: QuizColors.incorrect,
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.percent_rounded,
            label: '정답률',
            value: '${(result.accuracy * 100).toStringAsFixed(1)}%',
            color: cs.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyStats(QuizResult result, ColorScheme cs) {
    final stats = result.difficultyStats;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '난이도별 통계',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...Difficulty.values.map((difficulty) {
            final stat = stats[difficulty] ?? {'total': 0, 'correct': 0};
            final total = stat['total']!;
            final correct = stat['correct']!;

            if (total == 0) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DifficultyStatRow(
                difficulty: difficulty,
                correct: correct,
                total: total,
                cs: cs,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    QuizProvider provider,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        // 다시 하기
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await provider.restartQuiz();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const QuizPlayScreen(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              '다시 하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 홈으로
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              provider.resetQuiz();
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const QuizHomeScreen(),
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 250),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
                (route) => route.isFirst,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(
                color: cs.outline.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              '퀴즈 홈으로',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 통계 행
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// 난이도별 통계 행
class _DifficultyStatRow extends StatelessWidget {
  final Difficulty difficulty;
  final int correct;
  final int total;
  final ColorScheme cs;

  const _DifficultyStatRow({
    required this.difficulty,
    required this.correct,
    required this.total,
    required this.cs,
  });

  Color _getColor() {
    switch (difficulty) {
      case Difficulty.easy:
        return QuizColors.difficultyEasy;
      case Difficulty.medium:
        return QuizColors.difficultyMedium;
      case Difficulty.hard:
        return QuizColors.difficultyHard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final percentage = total == 0 ? 0.0 : (correct / total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              difficulty.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                difficulty.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              '$correct / $total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: percentage),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

