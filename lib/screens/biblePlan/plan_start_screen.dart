import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plan_progress.dart';
import '../../providers/plan_progress_provider.dart';
import '../../services/notification_service.dart';
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
    _planNameController = TextEditingController();

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
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _CustomTimePickerDialog(
        initialTime: _selectedTime ?? const TimeOfDay(hour: 7, minute: 0),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTime = result;
      });
    }
  }

  Future<void> _showInputErrorDialog() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 36,
                color: cs.primary.withOpacity(0.8),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '플랜명을 입력해주세요!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: cs.primaryContainer.withOpacity(0.5),
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Future<void> _startPlan() async {
    final planName = _planNameController.text.trim();
    if (planName.isEmpty) {
      _showInputErrorDialog();
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

    // 알림 스케줄링
    if (_selectedTime != null) {
      // payload 설정 (알림 탭 시 어느 화면으로 이동할지)
      String payload = 'day${widget.planType.totalDays}';

      await NotificationService().scheduleDailyNotification(
        id: widget.planType.totalDays, // 플랜 타입별로 고유 ID
        title: '📖 성경 읽기 시간이에요!',
        body: '$planName - 오늘의 말씀을 읽어보세요',
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        payload: payload, // day60, day120, day180
      );

      // 예약된 알림 확인 (디버깅용)
      final pending = await NotificationService().getPendingNotifications();
      print('========== 알림 예약 확인 ==========');
      print('예약된 알림 개수: ${pending.length}');
      for (var p in pending) {
        print('알림 ID: ${p.id}, 제목: ${p.title}, 내용: ${p.body}');
      }
      print('설정한 시간: ${_selectedTime!.hour}:${_selectedTime!.minute}');
      print('===================================');
    }

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
                  '플랜명 (필수사항)',
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
                      borderSide:
                          BorderSide(color: cs.outline.withOpacity(0.5)),
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

class _CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _CustomTimePickerDialog({
    required this.initialTime,
  });

  @override
  State<_CustomTimePickerDialog> createState() =>
      _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<_CustomTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM; // true = 오전, false = 오후
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _isAM = _selectedHour < 12;

    // 12시간 형식으로 표시
    final displayHour = _selectedHour == 0
        ? 12
        : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);
    _hourController.text = displayHour.toString().padLeft(2, '0');
    _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
  }

  void _updateHour() {
    final displayHour = int.tryParse(_hourController.text) ?? 7;
    if (displayHour >= 1 && displayHour <= 12) {
      setState(() {
        if (displayHour == 12) {
          _selectedHour = _isAM ? 0 : 12;
        } else {
          _selectedHour = _isAM ? displayHour : displayHour + 12;
        }
      });
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              '알림 받을 시간을 선택하세요',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // 오전/오후 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AMPMButton(
                  label: '오전',
                  isSelected: _isAM,
                  onTap: () {
                    setState(() {
                      if (!_isAM) {
                        _isAM = true;
                        if (_selectedHour >= 12) {
                          _selectedHour = _selectedHour == 12 ? 0 : _selectedHour - 12;
                        }
                        _updateHour();
                      }
                    });
                  },
                ),
                const SizedBox(width: 12),
                _AMPMButton(
                  label: '오후',
                  isSelected: !_isAM,
                  onTap: () {
                    setState(() {
                      if (_isAM) {
                        _isAM = false;
                        if (_selectedHour < 12) {
                          _selectedHour = _selectedHour == 0 ? 12 : _selectedHour + 12;
                        }
                        _updateHour();
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 시간 입력
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _hourController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 2,
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (_) => _updateHour(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '시',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28, left: 12, right: 12),
                  child: Text(
                    ':',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _minuteController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 2,
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final minute = int.tryParse(value);
                            if (minute != null && minute >= 0 && minute <= 59) {
                              setState(() {
                                _selectedMinute = minute;
                              });
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '분',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.onSurface.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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

// AM/PM 버튼
class _AMPMButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AMPMButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
