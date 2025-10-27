import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<bool> _selectedDays = List.filled(7, true); // 기본값: 모든 요일 선택
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CustomTimePickerDialog(
        initialTime: _selectedTime ?? const TimeOfDay(hour: 7, minute: 0),
        initialSelectedDays: _selectedDays,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTime = result['time'] as TimeOfDay;
        _selectedDays = result['selectedDays'] as List<bool>;
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

      // 선택한 요일 저장
      final prefs = await SharedPreferences.getInstance();
      final daysKey = 'notification_days_${widget.planType.totalDays}';
      await prefs.setString(daysKey, _selectedDays.map((e) => e ? '1' : '0').join(','));

      // 요일별 알림 스케줄링 (baseId는 플랜 타입 * 10으로 설정하여 7개 ID 확보)
      await NotificationService().scheduleWeeklyNotification(
        baseId: widget.planType.totalDays * 10, // 600, 1200, 1800
        title: '📖 성경일독 Day${widget.planType.totalDays} - 읽기 시간!',
        body: '$planName - 오늘의 말씀을 읽어보세요 🙏',
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        selectedDays: _selectedDays,
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
      final selectedDayNames = [];
      final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
      for (int i = 0; i < 7; i++) {
        if (_selectedDays[i]) selectedDayNames.add(dayNames[i]);
      }
      print('선택한 요일: ${selectedDayNames.join(', ')}');
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
  final List<bool>? initialSelectedDays;

  const _CustomTimePickerDialog({
    required this.initialTime,
    this.initialSelectedDays,
  });

  @override
  State<_CustomTimePickerDialog> createState() =>
      _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<_CustomTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM; // true = 오전, false = 오후
  late FixedExtentScrollController _amPmController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  // 요일 선택 (일~토)
  late List<bool> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _isAM = _selectedHour < 12;
    _selectedDays = widget.initialSelectedDays != null
        ? List<bool>.from(widget.initialSelectedDays!)
        : List.filled(7, true); // 기본값: 모든 요일 선택

    // 12시간 형식으로 표시 (1~12)
    final displayHour = _selectedHour == 0
        ? 12
        : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);

    // 스크롤 컨트롤러 초기화 (0-based index이므로 -1)
    _amPmController = FixedExtentScrollController(initialItem: _isAM ? 0 : 1);
    _hourController = FixedExtentScrollController(initialItem: displayHour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  void _onAmPmChanged(int index) {
    setState(() {
      final newIsAM = index == 0;
      if (_isAM != newIsAM) {
        _isAM = newIsAM;
        // 현재 _selectedHour를 기준으로 AM/PM 전환
        if (_isAM) {
          // 오후 -> 오전
          if (_selectedHour >= 12) {
            _selectedHour = _selectedHour == 12 ? 0 : _selectedHour - 12;
          }
        } else {
          // 오전 -> 오후
          if (_selectedHour < 12) {
            _selectedHour = _selectedHour == 0 ? 12 : _selectedHour + 12;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _amPmController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 선택된 시간을 12시간 형식으로 표시
    final displayHour = _selectedHour == 0
        ? 12
        : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);
    final timeString = '${_isAM ? '오전' : '오후'} ${displayHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀과 아이콘
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.alarm,
                    color: cs.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '알림 시간 설정',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '매일 이 시간에 알림을 받아요',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 요일 선택
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    '반복 요일',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _DayButton(
                      label: '일',
                      isSelected: _selectedDays[0],
                      isSunday: true,
                      onTap: () => setState(() => _selectedDays[0] = !_selectedDays[0]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: _DayButton(
                      label: '월',
                      isSelected: _selectedDays[1],
                      isSunday: false,
                      onTap: () => setState(() => _selectedDays[1] = !_selectedDays[1]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: _DayButton(
                      label: '화',
                      isSelected: _selectedDays[2],
                      isSunday: false,
                      onTap: () => setState(() => _selectedDays[2] = !_selectedDays[2]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: _DayButton(
                      label: '수',
                      isSelected: _selectedDays[3],
                      isSunday: false,
                      onTap: () => setState(() => _selectedDays[3] = !_selectedDays[3]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: _DayButton(
                      label: '목',
                      isSelected: _selectedDays[4],
                      isSunday: false,
                      onTap: () => setState(() => _selectedDays[4] = !_selectedDays[4]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: _DayButton(
                      label: '금',
                      isSelected: _selectedDays[5],
                      isSunday: false,
                      onTap: () => setState(() => _selectedDays[5] = !_selectedDays[5]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: _DayButton(
                      label: '토',
                      isSelected: _selectedDays[6],
                      isSunday: false,
                      onTap: () => setState(() => _selectedDays[6] = !_selectedDays[6]),
                    )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 선택된 시간 미리보기
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.1),
                    cs.primaryContainer.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '선택한 시간',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeString,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 시간 선택 섹션
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    '알림 시간',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // 오전/오후
                    Expanded(
                      flex: 2,
                      child: _TimePickerColumn(
                        label: '오전/오후',
                        controller: _amPmController,
                        itemCount: 2,
                        onSelectedItemChanged: _onAmPmChanged,
                        itemBuilder: (index) => index == 0 ? '오전' : '오후',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 시
                    Expanded(
                      flex: 2,
                      child: _TimePickerColumn(
                        label: '시',
                        controller: _hourController,
                        itemCount: 12,
                        onSelectedItemChanged: (index) {
                          final displayHour = index + 1;
                          setState(() {
                            if (displayHour == 12) {
                              _selectedHour = _isAM ? 0 : 12;
                            } else {
                              _selectedHour = _isAM ? displayHour : displayHour + 12;
                            }
                          });
                        },
                        itemBuilder: (index) => '${index + 1}'.padLeft(2, '0'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 분
                    Expanded(
                      flex: 2,
                      child: _TimePickerColumn(
                        label: '분',
                        controller: _minuteController,
                        itemCount: 60,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedMinute = index;
                          });
                        },
                        itemBuilder: (index) => index.toString().padLeft(2, '0'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'time': TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                    'selectedDays': List<bool>.from(_selectedDays),
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  '저장',
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? cs.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 스크롤 휠 위젯
class _ScrollWheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final ValueChanged<int> onSelectedItemChanged;
  final Widget Function(int index) itemBuilder;

  const _ScrollWheel({
    required this.controller,
    required this.itemCount,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.5,
      perspective: 0.002,
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) => itemBuilder(index),
        childCount: itemCount,
      ),
    );
  }
}

// 시간 조정 버튼
class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AdjustButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: cs.primary,
        ),
      ),
    );
  }
}

// 요일 선택 버튼
class _DayButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isSunday;
  final VoidCallback onTap;

  const _DayButton({
    required this.label,
    required this.isSelected,
    required this.isSunday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? cs.onPrimary
                    : (isSunday ? Colors.red : cs.onSurface.withOpacity(0.6)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 오전/오후 선택 버튼
class _TimeSelectButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSelectButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// 시/분 선택 컬럼
class _TimePickerColumn extends StatelessWidget {
  final String label;
  final FixedExtentScrollController controller;
  final int itemCount;
  final ValueChanged<int> onSelectedItemChanged;
  final String Function(int) itemBuilder;

  const _TimePickerColumn({
    required this.label,
    required this.controller,
    required this.itemCount,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.5,
            perspective: 0.003,
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final isSelected = controller.selectedItem == index;
                return Center(
                  child: Text(
                    itemBuilder(index),
                    style: TextStyle(
                      fontSize: isSelected ? 20 : 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}
