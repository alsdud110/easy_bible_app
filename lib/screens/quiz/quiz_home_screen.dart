import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../models/quiz_question.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_play_screen.dart';

/// 퀴즈 홈 화면 - 난이도 및 유형 선택
class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  Difficulty? _selectedDifficulty;
  QuizType? _selectedType;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '성경 퀴즈',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cs.surface,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              _buildHeader(cs),
              const SizedBox(height: 16),

              // 난이도 선택
              _buildSectionTitle('난이도 선택', Icons.trending_up_rounded, cs),
              const SizedBox(height: 10),
              _buildDifficultySelector(cs),
              const SizedBox(height: 16),

              // 퀴즈 유형 선택
              _buildSectionTitle('퀴즈 유형', Icons.quiz_rounded, cs),
              const SizedBox(height: 10),
              _buildQuizTypeSelector(cs),
              const SizedBox(height: 20),

              // 시작 버튼
              _buildStartButton(context, cs),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, -16),
          child: Lottie.asset(
            'assets/lottie/bible_book.json',
            width: 130,
            height: 130,
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Column(
            children: [
              Text(
                '성경 퀴즈',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '당신의 성경 지식을 확인해보세요',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: cs.primary, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector(ColorScheme cs) {
    return Column(
      children: [
        _DifficultyCard(
          difficulty: Difficulty.easy,
          isSelected: _selectedDifficulty == Difficulty.easy,
          onTap: () {
            setState(() {
              _selectedDifficulty = Difficulty.easy;
            });
          },
        ),
        const SizedBox(height: 8),
        _DifficultyCard(
          difficulty: Difficulty.medium,
          isSelected: _selectedDifficulty == Difficulty.medium,
          onTap: () {
            setState(() {
              _selectedDifficulty = Difficulty.medium;
            });
          },
        ),
        const SizedBox(height: 8),
        _DifficultyCard(
          difficulty: Difficulty.hard,
          isSelected: _selectedDifficulty == Difficulty.hard,
          onTap: () {
            setState(() {
              _selectedDifficulty = Difficulty.hard;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuizTypeSelector(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _QuizTypeCard(
            type: QuizType.ox,
            isSelected: _selectedType == QuizType.ox,
            onTap: () {
              setState(() {
                _selectedType = QuizType.ox;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _QuizTypeCard(
            type: QuizType.multipleChoice,
            isSelected: _selectedType == QuizType.multipleChoice,
            onTap: () {
              setState(() {
                _selectedType = QuizType.multipleChoice;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, ColorScheme cs) {
    final isEnabled = _selectedDifficulty != null && _selectedType != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isEnabled ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        // 색상 전환을 위한 부드러운 보간
        final backgroundColor = Color.lerp(
          cs.surfaceContainerHighest,
          cs.primary,
          value,
        )!;

        final gradientEndColor = Color.lerp(
          cs.surfaceContainerHighest,
          cs.secondary,
          value,
        )!;

        return Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundColor, gradientEndColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: value > 0
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3 * value),
                      blurRadius: 16 * value,
                      offset: Offset(0, 8 * value),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? () => _startQuiz(context) : null,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  '퀴즈 시작하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isEnabled
                        ? Colors.white
                        : cs.onSurface.withValues(alpha: 0.35),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startQuiz(BuildContext context) async {
    if (_selectedDifficulty == null || _selectedType == null) return;

    final provider = context.read<QuizProvider>();

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/loading.json',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  '문제를 준비하고 있어요...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 퀴즈 시작
      await provider.startQuiz(
        type: _selectedType!,
        difficulty: _selectedDifficulty!,
      );

      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      // 퀴즈 화면으로 이동
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const QuizPlayScreen(),
          ),
        );
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      // 에러 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퀴즈 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// 난이도 카드
class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    difficulty.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  difficulty.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 22,
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.3),
                      width: 2,
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

// 퀴즈 유형 카드
class _QuizTypeCard extends StatelessWidget {
  final QuizType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuizTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                type.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 6),
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
