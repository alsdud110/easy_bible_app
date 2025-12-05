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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              _buildHeader(cs),
              const SizedBox(height: 24),

              // 난이도 선택
              _buildSectionTitle('난이도 선택', Icons.trending_up_rounded, cs),
              const SizedBox(height: 12),
              _buildDifficultySelector(cs),
              const SizedBox(height: 24),

              // 퀴즈 유형 선택
              _buildSectionTitle('퀴즈 유형', Icons.quiz_rounded, cs),
              const SizedBox(height: 12),
              _buildQuizTypeSelector(cs),
              const SizedBox(height: 24),

              // 시작 버튼
              _buildStartButton(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.secondary,
          ],
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
          Icon(
            Icons.emoji_events_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 12),
          const Text(
            '성경 지식 테스트',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '난이도와 유형을 선택하고 퀴즈를 풀어보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
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
        const SizedBox(height: 12),
        _DifficultyCard(
          difficulty: Difficulty.medium,
          isSelected: _selectedDifficulty == Difficulty.medium,
          onTap: () {
            setState(() {
              _selectedDifficulty = Difficulty.medium;
            });
          },
        ),
        const SizedBox(height: 12),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 52,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                color: isEnabled ? Colors.white : cs.onSurface.withValues(alpha: 0.3),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
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

  Color _getColor() {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF10B981);
      case Difficulty.medium:
        return const Color(0xFF3B82F6);
      case Difficulty.hard:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _getColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : cs.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    difficulty.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  difficulty.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 24,
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
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primaryContainer
                : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                type.icon,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 8),
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
