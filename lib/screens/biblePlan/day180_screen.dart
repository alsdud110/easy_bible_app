import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../../models/bible_180.dart';
import '../../models/bible_json_loader.dart';
import '../../models/plan_progress.dart';
import '../../utils/extract_verses.dart';
import '../../utils/pretty_range_label.dart';
import '../../providers/plan_progress_provider.dart';
import '../../services/notification_service.dart';
import 'plan_verse_list_view.dart';

class Day180Screen extends StatefulWidget {
  const Day180Screen({super.key});

  @override
  State<Day180Screen> createState() => _Day180ScreenState();
}

class _Day180ScreenState extends State<Day180Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentDay();
    });
  }

  void _scrollToCurrentDay() async {
    final planProvider = context.read<PlanProgressProvider>();
    if (!planProvider.hasPlan(PlanType.day180)) return;

    final nextDay = planProvider.getNextDay(PlanType.day180);
    if (nextDay <= 1) return;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted || !_scrollController.hasClients) return;

    const itemHeight = 80.0;
    final targetIndex = nextDay - 1;
    final screenHeight = MediaQuery.of(context).size.height;
    final offset =
        (targetIndex * itemHeight) - (screenHeight / 2) + (itemHeight / 2);

    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetOffset = offset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showResetConfirmDialog() async {
    final planProvider = context.read<PlanProgressProvider>();
    if (!planProvider.hasPlan(PlanType.day180)) return;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final progressPercent = planProvider.getProgressPercent(PlanType.day180);
    final completedDays = planProvider.getCompletedDaysCount(PlanType.day180);
    final totalDays = planProvider.getTotalDays(PlanType.day180);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/reload.json',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                repeat: true,
              ),
              const SizedBox(height: 8),
              Text(
                '플랜 초기화',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '현재 진행률',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progressPercent%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedDays / $totalDays 일 완료',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '처음부터 다시 시작하시겠어요?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '진행 기록과 알림 설정이 삭제돼요',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurface.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '초기화',
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

    if (confirmed == true) {
      await _resetPlan();
    }
  }

  Future<void> _resetPlan() async {
    final planProvider = context.read<PlanProgressProvider>();

    // 알림 취소 (Day180 플랜의 알림 ID는 180)
    await NotificationService().cancelNotification(180);

    // 플랜 삭제
    await planProvider.deletePlan(PlanType.day180);

    if (!mounted) return;

    // 홈으로 돌아가기
    Navigator.of(context).pop();
  }

  Future<void> _showNotificationResultDialog({
    required bool isSame,
    required TimeOfDay time,
  }) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSame
                    ? Icons.check_circle_outline
                    : Icons.notifications_active,
                size: 48,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isSame ? '동일한 시간이에요' : '알림 일정이 변경되었어요',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  time.format(context),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSame ? '이미 이 시간으로 설정되어 있어요' : '매일 이 시간에 알림을 받아요',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
        ),
      ),
    );
  }

  Future<void> _showNotificationSettingDialog() async {
    final planProvider = context.read<PlanProgressProvider>();
    final plan = planProvider.getPlan(PlanType.day180);

    if (plan == null) return;

    // 현재 알림 시간 (없으면 기본값 오전 7시)
    final currentTime = plan.notificationTime;
    TimeOfDay initialTime;

    if (currentTime != null) {
      initialTime =
          TimeOfDay(hour: currentTime.hour, minute: currentTime.minute);
    } else {
      initialTime = const TimeOfDay(hour: 7, minute: 0);
    }

    // 저장된 요일 정보 불러오기
    final prefs = await SharedPreferences.getInstance();
    final daysKey = 'notification_days_180';
    final savedDays = prefs.getString(daysKey);
    List<bool> initialSelectedDays = List.filled(7, true);

    if (savedDays != null) {
      final daysList = savedDays.split(',');
      if (daysList.length == 7) {
        initialSelectedDays = daysList.map((e) => e == '1').toList();
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _NotificationTimeDialog(
        initialTime: initialTime,
        currentPlanName: plan.planName,
        initialSelectedDays: initialSelectedDays,
      ),
    );

    if (result != null) {
      final selectedTime = result['time'] as TimeOfDay;
      final selectedDays = result['selectedDays'] as List<bool>;

      if (!mounted) return;

      // 시간 업데이트
      final now = DateTime.now();
      final newNotificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await planProvider.updateNotificationTime(
        PlanType.day180,
        newNotificationTime,
      );

      // 선택한 요일 저장
      await prefs.setString(
          daysKey, selectedDays.map((e) => e ? '1' : '0').join(','));

      // 기존 알림 취소하고 새로 등록 (요일별)
      await NotificationService().scheduleWeeklyNotification(
        baseId: 1800, // 180 * 10
        title: '📖 성경일독 Day180 - 읽기 시간!',
        body: '${plan.planName} - 오늘의 말씀을 읽어보세요 🙏',
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        selectedDays: selectedDays,
        payload: 'day180',
      );

      if (!mounted) return;

      await _showNotificationResultDialog(
        isSame: false,
        time: selectedTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<Map<String, String>>(
      future: loadBibleJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 4,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '성경 데이터 로딩 중...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Text(
                '성경 데이터를 불러오지 못했습니다.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
          );
        }
        final bibleData = snapshot.data!;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('성경일독 DAY180'),
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: theme.appBarTheme.elevation ?? 0,
            scrolledUnderElevation:
                theme.appBarTheme.scrolledUnderElevation ?? 0,
            centerTitle: theme.appBarTheme.centerTitle ?? true,
            iconTheme: theme.appBarTheme.iconTheme,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _showNotificationSettingDialog,
                tooltip: '알림 설정',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _showResetConfirmDialog,
                tooltip: '초기화',
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Consumer<PlanProgressProvider>(
                builder: (context, planProvider, _) {
                  return ListView.separated(
                    controller: _scrollController,
                    itemCount: bible180.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outline.withOpacity(0.2),
                    ),
                    itemBuilder: (_, idx) {
                      final dayRanges = bible180[idx];
                      final dayNum = idx + 1;
                      final dayLabel = 'DAY $dayNum';
                      final rangeLabel = dayRanges.join(', ');

                      // 읽음 처리 및 접근 가능 여부 확인
                      final isCompleted =
                          planProvider.isDayCompleted(PlanType.day180, dayNum);
                      final canAccess =
                          planProvider.canAccessDay(PlanType.day180, dayNum);

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (idx * 20)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          child: Opacity(
                            opacity: canAccess ? 1.0 : 0.4,
                            child: ListTile(
                              tileColor: cs.surface,
                              enabled: canAccess,
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isCompleted
                                            ? [
                                                Colors.green,
                                                Colors.green.withOpacity(0.7),
                                              ]
                                            : canAccess
                                                ? [
                                                    cs.primary,
                                                    cs.primary.withOpacity(0.7),
                                                  ]
                                                : [
                                                    Colors.grey,
                                                    Colors.grey
                                                        .withOpacity(0.7),
                                                  ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: canAccess
                                          ? [
                                              BoxShadow(
                                                color: isCompleted
                                                    ? Colors.green
                                                        .withOpacity(0.3)
                                                    : cs.primary
                                                        .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      dayLabel,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: cs.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      prettyRangeLabel(rangeLabel),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 15,
                                        color: canAccess
                                            ? cs.onSurface
                                            : cs.onSurface.withOpacity(0.5),
                                      ),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCompleted)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                ],
                              ),
                              trailing: TweenAnimationBuilder<double>(
                                duration:
                                    Duration(milliseconds: 400 + (idx * 20)),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  canAccess
                                      ? Icons.arrow_forward_ios_rounded
                                      : Icons.lock,
                                  size: 18,
                                  color: canAccess ? cs.primary : Colors.grey,
                                ),
                              ),
                              onTap: canAccess
                                  ? () {
                                      _openPlanVerse(context, bibleData, idx);
                                    }
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPlanVerse(
      BuildContext context, Map<String, String> bibleData, int idx) {
    final dayRanges = bible180[idx];
    final dayNum = idx + 1;
    final dayLabel = 'DAY $dayNum';
    final rangeLabel = dayRanges.join(', ');

    final entries = extractVersesForDay(bibleData, dayRanges);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanVerseListView(
          title: '$dayLabel  $rangeLabel',
          verses: Map<String, String>.fromEntries(entries),
          dayNumber: dayNum,
          planType: PlanType.day180,
          onBack: () => Navigator.pop(context),
          hasPrevDay: idx > 0,
          hasNextDay: idx < bible180.length - 1,
          onPrevDay: idx > 0
              ? () {
                  Navigator.pop(context);
                  _openPlanVerse(context, bibleData, idx - 1);
                }
              : null,
          onNextDay: idx < bible180.length - 1
              ? () {
                  Navigator.pop(context);
                  _openPlanVerse(context, bibleData, idx + 1);
                }
              : null,
        ),
      ),
    );
  }
}

// 알림 시간 설정 다이얼로그
class _NotificationTimeDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String currentPlanName;
  final List<bool>? initialSelectedDays;

  const _NotificationTimeDialog({
    required this.initialTime,
    required this.currentPlanName,
    this.initialSelectedDays,
  });

  @override
  State<_NotificationTimeDialog> createState() =>
      _NotificationTimeDialogState();
}

class _NotificationTimeDialogState extends State<_NotificationTimeDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM;
  late FixedExtentScrollController _amPmController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late List<bool> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _isAM = _selectedHour < 12;
    _selectedDays = widget.initialSelectedDays != null
        ? List<bool>.from(widget.initialSelectedDays!)
        : List.filled(7, true);

    // 12시간 형식으로 표시 (1~12)
    final displayHour = _selectedHour == 0
        ? 12
        : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);

    // 스크롤 컨트롤러 초기화 (0-based index이므로 -1)
    _amPmController = FixedExtentScrollController(initialItem: _isAM ? 0 : 1);
    _hourController = FixedExtentScrollController(initialItem: displayHour - 1);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinute);
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
    final timeString =
        '${_isAM ? '오전' : '오후'} ${displayHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

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
            // 타이틀
            Text(
              '알림 시간 설정',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.currentPlanName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // 반복 요일 선택
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '반복 요일',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _DayButton(
                      label: '일',
                      isSelected: _selectedDays[0],
                      isSunday: true,
                      onTap: () =>
                          setState(() => _selectedDays[0] = !_selectedDays[0]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _DayButton(
                      label: '월',
                      isSelected: _selectedDays[1],
                      isSunday: false,
                      onTap: () =>
                          setState(() => _selectedDays[1] = !_selectedDays[1]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _DayButton(
                      label: '화',
                      isSelected: _selectedDays[2],
                      isSunday: false,
                      onTap: () =>
                          setState(() => _selectedDays[2] = !_selectedDays[2]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _DayButton(
                      label: '수',
                      isSelected: _selectedDays[3],
                      isSunday: false,
                      onTap: () =>
                          setState(() => _selectedDays[3] = !_selectedDays[3]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _DayButton(
                      label: '목',
                      isSelected: _selectedDays[4],
                      isSunday: false,
                      onTap: () =>
                          setState(() => _selectedDays[4] = !_selectedDays[4]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _DayButton(
                      label: '금',
                      isSelected: _selectedDays[5],
                      isSunday: false,
                      onTap: () =>
                          setState(() => _selectedDays[5] = !_selectedDays[5]),
                    )),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _DayButton(
                      label: '토',
                      isSelected: _selectedDays[6],
                      isSunday: false,
                      onTap: () =>
                          setState(() => _selectedDays[6] = !_selectedDays[6]),
                    )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 선택한 시간 미리보기
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
            const SizedBox(height: 24),

            // 알림 시간 선택 (오전/오후 | 시 | 분)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림 시간',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
                        itemBuilder: (index) => '${index + 1}'.padLeft(2, '0'),
                        onSelectedItemChanged: (index) {
                          final displayHour = index + 1; // 1~12
                          setState(() {
                            if (displayHour == 12) {
                              _selectedHour = _isAM ? 0 : 12;
                            } else {
                              _selectedHour =
                                  _isAM ? displayHour : displayHour + 12;
                            }
                          });
                        },
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
                        itemBuilder: (index) =>
                            index.toString().padLeft(2, '0'),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedMinute = index;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'time':
                        TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? cs.onPrimary
                  : (isSunday ? Colors.red : cs.onSurface.withOpacity(0.6)),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// 시간/분 선택 컬럼
class _TimePickerColumn extends StatelessWidget {
  final String label;
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int) itemBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  const _TimePickerColumn({
    required this.label,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onSelectedItemChanged,
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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 선택 영역 하이라이트
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.5,
                perspective: 0.002,
                onSelectedItemChanged: onSelectedItemChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    return Center(
                      child: Text(
                        itemBuilder(index),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                  childCount: itemCount,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
