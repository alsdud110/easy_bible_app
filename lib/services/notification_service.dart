import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionRequested = false;

  // 알림 탭 콜백
  Function(String?)? onNotificationTap;

  // 앱 종료 상태에서 알림 탭으로 시작한 경우의 payload 저장
  String? _launchPayload;
  bool _launchPayloadProcessed = false;

  Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_initialized) return;

    this.onNotificationTap = onNotificationTap;

    // timezone 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // 앱이 종료된 상태에서 알림을 탭해서 시작된 경우 먼저 확인
    final notificationAppLaunchDetails =
        await _notifications.getNotificationAppLaunchDetails();

    print('=== Notification Launch Details ===');
    print('didNotificationLaunchApp: ${notificationAppLaunchDetails?.didNotificationLaunchApp}');
    print('payload: ${notificationAppLaunchDetails?.notificationResponse?.payload}');

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null) {
        _launchPayload = payload;
        print('✅ 앱이 알림으로 시작됨: $_launchPayload');
        // 즉시 SharedPreferences에도 저장 (백업용)
        await _saveLaunchPayload(payload);
      }
    }

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // 초기화 시점에는 요청하지 않음
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('=== Notification Tapped ===');
    print('payload: ${response.payload}');
    print('actionId: ${response.actionId}');

    // 앱이 실행 중일 때만 여기서 처리
    if (response.payload != null) {
      print('📱 앱 실행 중 알림 탭 감지');

      // 콜백 실행 (UI가 준비되어 있음)
      if (onNotificationTap != null) {
        onNotificationTap!(response.payload);
      }
    }
  }

  // SharedPreferences에 payload 저장 (백업용)
  Future<void> _saveLaunchPayload(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_launch_payload', payload);
      await prefs.setBool('notification_launch_flag', true);
      print('💾 Launch payload 저장: $payload');
    } catch (e) {
      print('❌ Launch payload 저장 실패: $e');
    }
  }

  // 앱 시작 시 저장된 launch payload 가져오기
  Future<String?> getLaunchPayload() async {
    if (_launchPayloadProcessed) return null;

    // 먼저 메모리에서 확인 (getNotificationAppLaunchDetails로 가져온 값)
    if (_launchPayload != null) {
      _launchPayloadProcessed = true;
      print('✅ Launch payload 반환: $_launchPayload');
      return _launchPayload;
    }

    // SharedPreferences에서 확인 (백업 - 혹시 위에서 못 가져왔을 경우)
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLaunchFlag = prefs.getBool('notification_launch_flag') ?? false;

      if (hasLaunchFlag) {
        final payload = prefs.getString('notification_launch_payload');
        if (payload != null) {
          _launchPayloadProcessed = true;
          // 플래그 제거
          await prefs.remove('notification_launch_flag');
          await prefs.remove('notification_launch_payload');
          print('✅ Launch payload 반환 (백업): $payload');
          return payload;
        }
      }
    } catch (e) {
      print('❌ Launch payload 로드 실패: $e');
    }

    return null;
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    if (_permissionRequested) {
      return true; // 이미 요청했으면 true 반환
    }

    if (Platform.isAndroid) {
      // Android 13+ (API 33+)에서만 권한 요청
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        _permissionRequested = true;
        return granted ?? true;
      }
      return true; // Android 12 이하는 권한 불필요
    } else if (Platform.isIOS) {
      // iOS는 앱 초기화 시점에 권한 요청
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionRequested = true;
        return granted ?? false;
      }
      return false;
    }

    return true;
  }

  /// 매일 반복되는 알림 스케줄링
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    // 권한 확인
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      print('알림 권한이 없습니다.');
      return;
    }

    // 알림 시간 설정
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 만약 오늘의 설정 시간이 이미 지났다면 내일로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Android 알림 상세 설정
    const androidDetails = AndroidNotificationDetails(
      'daily_bible_reading',
      '성경 읽기 알림',
      channelDescription: '매일 성경 읽기 시간을 알려드립니다',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // iOS 알림 상세 설정
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 매일 반복 알림 예약
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간에 반복
      payload: payload,
    );

    print('알림 설정 완료: ${scheduledDate.hour}:${scheduledDate.minute}');
  }

  /// 특정 요일에만 반복되는 알림 스케줄링
  /// selectedDays: [일, 월, 화, 수, 목, 금, 토] 순서로 true/false
  Future<void> scheduleWeeklyNotification({
    required int baseId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<bool> selectedDays,
    String? payload,
  }) async {
    // 권한 확인
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      print('알림 권한이 없습니다.');
      return;
    }

    // 기존 알림들 취소 (baseId ~ baseId+6)
    for (int i = 0; i < 7; i++) {
      await _notifications.cancel(baseId + i);
    }

    // 선택된 요일에만 알림 스케줄링
    final now = tz.TZDateTime.now(tz.local);

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      if (!selectedDays[dayIndex]) continue; // 선택되지 않은 요일은 스킵

      // Flutter의 weekday: 1(월) ~ 7(일)
      // 우리 배열: 0(일) ~ 6(토)
      // 변환: dayIndex 0(일) -> weekday 7, dayIndex 1(월) -> weekday 1
      final targetWeekday = dayIndex == 0 ? 7 : dayIndex;

      // 다음 해당 요일 찾기
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // 현재 요일부터 목표 요일까지의 차이 계산
      int daysUntilTarget = (targetWeekday - scheduledDate.weekday + 7) % 7;

      // 오늘이 목표 요일이고 시간이 이미 지났다면 다음 주로
      if (daysUntilTarget == 0 && scheduledDate.isBefore(now)) {
        daysUntilTarget = 7;
      }

      scheduledDate = scheduledDate.add(Duration(days: daysUntilTarget));

      // Android 알림 상세 설정
      const androidDetails = AndroidNotificationDetails(
        'daily_bible_reading',
        '성경 읽기 알림',
        channelDescription: '매일 성경 읽기 시간을 알려드립니다',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      // iOS 알림 상세 설정
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 주간 반복 알림 예약
      await _notifications.zonedSchedule(
        baseId + dayIndex, // 각 요일마다 고유 ID
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // 매주 같은 요일, 같은 시간에 반복
        payload: payload,
      );

      final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
      print('알림 설정 완료: ${dayNames[dayIndex]}요일 ${scheduledDate.hour}:${scheduledDate.minute}');
    }
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 예약된 알림 목록 확인
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
