import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plan_progress.dart';
import '../../providers/plan_progress_provider.dart';
import 'day60_screen.dart';
import 'day120_screen.dart';
import 'day180_screen.dart';

class PlanStartScreen extends StatefulWidget {
  final PlanType planType;

  const PlanStartScreen({
    super.key,
    required this.planType,
  });

  @override
  State<PlanStartScreen> createState() => _PlanStartScreenState();
}

class _PlanStartScreenState extends State<PlanStartScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _planNameController;
  TimeOfDay? _selectedTime;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _planNameController = TextEditingController(
      text: widget.planType.defaultName,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _startPlan() async {
    final planName = _planNameController.text.trim();
    if (planName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('플랜명을 입력해주세요.')),
      );
      return;
    }

    // 알림 시간을 DateTime으로 변환 (선택사항)
    DateTime? notificationTime;
    if (_selectedTime != null) {
      final now = DateTime.now();
      notificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    // 플랜 시작
    final provider = context.read<PlanProgressProvider>();
    await provider.startNewPlan(
      planType: widget.planType,
      customPlanName: planName,
      notificationTime: notificationTime,
    );

    if (!mounted) return;

    // 응원 메시지 팝업
    await _showEncouragementDialog();
  }

  Future<void> _showEncouragementDialog() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration,
                size: 64,
                color: cs.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '오늘부터 시작합니다!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.planType.totalDays}일 동안\n성경 통독을 응원하겠습니다!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    _navigateToDayScreen();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  void _navigateToDayScreen() {
    Widget screen;
    switch (widget.planType) {
      case PlanType.day60:
        screen = const Day60Screen();
        break;
      case PlanType.day120:
        screen = const Day120Screen();
        break;
      case PlanType.day180:
        screen = const Day180Screen();
        break;
    }

    // 플랜 시작 화면을 닫고 Day 화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: BackButton(
          color: theme.appBarTheme.iconTheme?.color,
        ),
        title: Text(
          '플랜 시작하기',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 플랜 타입 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary,
                        cs.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 48,
                        color: cs.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.planType.totalDays}일 통독 플랜',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '하루하루 성경을 읽으며\n말씀과 함께하는 ${widget.planType.totalDays}일',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onPrimary.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 플랜명 입력
                Text(
                  '플랜명',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _planNameController,
                  decoration: InputDecoration(
                    hintText: widget.planType.defaultName,
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurface,
                  ),
                ),

                const SizedBox(height: 32),

                // 알림 시간 설정
                Text(
                  '알림 시간 (선택사항)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alarm,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedTime != null
                                ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                : '알림 시간 선택',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _selectedTime != null
                                  ? cs.onSurface
                                  : cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // 시작하기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      shadowColor: cs.primary.withOpacity(0.4),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 안내 텍스트
                Center(
                  child: Text(
                    '시작하기 버튼을 누르면\n플랜이 시작됩니다',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
