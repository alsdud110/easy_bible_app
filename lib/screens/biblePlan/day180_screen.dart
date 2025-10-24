import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final offset = (targetIndex * itemHeight) - (screenHeight / 2) + (itemHeight / 2);

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
              Icon(
                Icons.refresh_rounded,
                size: 44,
                color: cs.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
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
                isSame ? Icons.check_circle_outline : Icons.notifications_active,
                size: 48,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isSame ? '동일한 시간이에요' : '알림 시간이 변경되었어요',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
                isSame
                    ? '이미 이 시간으로 설정되어 있어요'
                    : '매일 이 시간에 알림을 받아요',
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
      initialTime = TimeOfDay(hour: currentTime.hour, minute: currentTime.minute);
    } else {
      initialTime = const TimeOfDay(hour: 7, minute: 0);
    }

    final selectedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _NotificationTimeDialog(
        initialTime: initialTime,
        currentPlanName: plan.planName,
      ),
    );

    if (selectedTime != null) {
      // 기존 시간과 비교
      final isSameTime = initialTime.hour == selectedTime.hour &&
                         initialTime.minute == selectedTime.minute;

      if (!mounted) return;

      if (isSameTime) {
        // 동일한 시간이면 알림만 표시
        await _showNotificationResultDialog(
          isSame: true,
          time: selectedTime,
        );
      } else {
        // 다른 시간이면 업데이트하고 알림 표시
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

        // 기존 알림 취소하고 새로 등록
        await NotificationService().cancelNotification(180);
        await NotificationService().scheduleDailyNotification(
          id: 180,
          title: '📖 성경 읽기 시간이에요!',
          body: '${plan.planName} - 오늘의 말씀을 읽어보세요',
          hour: selectedTime.hour,
          minute: selectedTime.minute,
          payload: 'day180',
        );

        if (!mounted) return;

        await _showNotificationResultDialog(
          isSame: false,
          time: selectedTime,
        );
      }
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
                      final isCompleted = planProvider.isDayCompleted(PlanType.day180, dayNum);
                      final canAccess = planProvider.canAccessDay(PlanType.day180, dayNum);

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
                                                    Colors.grey.withOpacity(0.7),
                                                  ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: canAccess
                                          ? [
                                              BoxShadow(
                                                color: isCompleted
                                                    ? Colors.green.withOpacity(0.3)
                                                    : cs.primary.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      dayLabel,
                                      style: theme.textTheme.bodyLarge?.copyWith(
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
                                      style: theme.textTheme.bodyMedium?.copyWith(
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
                                duration: Duration(milliseconds: 400 + (idx * 20)),
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => PlanVerseListView(
          title: '$dayLabel  $rangeLabel',
          verses: Map<String, String>.fromEntries(entries),
          dayNumber: dayNum,
          planType: PlanType.day180,
          onBack: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// 알림 시간 설정 다이얼로그
class _NotificationTimeDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String currentPlanName;

  const _NotificationTimeDialog({
    required this.initialTime,
    required this.currentPlanName,
  });

  @override
  State<_NotificationTimeDialog> createState() => _NotificationTimeDialogState();
}

class _NotificationTimeDialogState extends State<_NotificationTimeDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM;
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _isAM = _selectedHour < 12;

    final displayHour = _selectedHour == 0 ? 12 : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);
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

  void _updateMinute() {
    final minute = int.tryParse(_minuteController.text) ?? 0;
    if (minute >= 0 && minute <= 59) {
      setState(() {
        _selectedMinute = minute;
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
            Icon(
              Icons.notifications_outlined,
              size: 40,
              color: cs.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              '알림 시간 설정',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
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

            // 현재 설정된 시간 표시
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    '현재: ${widget.initialTime.format(context)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                        onChanged: (_) => _updateMinute(),
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

            // 버튼
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedTime = TimeOfDay(
                        hour: _selectedHour,
                        minute: _selectedMinute,
                      );
                      Navigator.of(context).pop(selectedTime);
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
