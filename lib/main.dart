import 'package:easy_bible_app/screens/easyBible/easy_bible_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/bible/bible_home_screen.dart';
import 'screens/biblePlan/day60_screen.dart';
import 'screens/biblePlan/day120_screen.dart';
import 'screens/biblePlan/day180_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'theme/app_theme.dart';
import 'providers/favorite_provider.dart';
import 'providers/highlight_provider.dart';
import 'providers/language_provider.dart'; // ✅ 이미 import되어 있음
import 'providers/plan_progress_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/quiz_provider.dart';
import 'services/notification_service.dart';
import 'services/bible_subtitle_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// GlobalKey for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 알림으로 앱이 시작된 경우의 초기 라우트
String? _initialNotificationPayload;

// 알림 탭 핸들러 (앱 실행 중일 때)
void _handleNotificationTap(String payload) {
  print('알림 탭됨 (앱 실행 중): $payload');

  // 네비게이터가 준비될 때까지 대기
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _navigateToScreen(payload);
  });
}

// 화면 이동 로직 (홈을 거쳐서 Day 화면으로)
void _navigateToScreen(String payload) {
  print('📍 _navigateToScreen 호출됨: $payload');

  final navigator = navigatorKey.currentState;
  if (navigator == null || !navigator.mounted) {
    print('⚠️ Navigator가 아직 준비되지 않음 - 700ms 후 재시도');
    // Navigator가 준비되지 않았다면 다시 시도
    Future.delayed(const Duration(milliseconds: 700), () {
      _navigateToScreen(payload);
    });
    return;
  }

  print('✅ Navigator 준비 완료');

  Widget targetScreen;
  String screenName;
  switch (payload) {
    case 'day60':
      targetScreen = const Day60Screen();
      screenName = '60일 플랜';
      break;
    case 'day120':
      targetScreen = const Day120Screen();
      screenName = '120일 플랜';
      break;
    case 'day180':
      targetScreen = const Day180Screen();
      screenName = '180일 플랜';
      break;
    default:
      print('❌ 알 수 없는 payload: $payload');
      return;
  }

  print('🎯 목표 화면: $screenName ($payload)');

  // 현재 경로가 홈이 아니면 홈으로 먼저 이동
  try {
    // 홈 화면으로 리셋
    while (navigator.canPop()) {
      navigator.pop();
    }
    print('✅ 홈 화면으로 이동 완료');
  } catch (e) {
    print('⚠️ pop 오류: $e');
  }

  // Day 화면으로 이동 (딜레이를 더 길게 설정)
  Future.delayed(const Duration(milliseconds: 800), () {
    final currentNavigator = navigatorKey.currentState;
    if (currentNavigator != null && currentNavigator.mounted) {
      print('🚀 $screenName 화면으로 이동 중...');
      currentNavigator.push(
        MaterialPageRoute(builder: (context) => targetScreen),
      );
      print('✅ 화면 이동 완료!');
    } else {
      print('❌ Navigator가 사용 불가능한 상태');
    }
  });
}

/// 모든 스크롤의 바운스/Glow(쭉쭉) 완전 제거
class NoBounceScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // 모든 Glow/바운스 효과 제거!
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ AdMob 초기화 및 상태 확인
  final initializationStatus = await MobileAds.instance.initialize();
  print('🎯 AdMob 초기화 완료: ${initializationStatus.adapterStatuses}');

  // 알림 서비스 초기화 (알림 탭 핸들러 포함)
  await NotificationService().initialize(
    onNotificationTap: (payload) {
      if (payload != null) {
        print('📱 알림 탭 핸들러 호출: $payload');
        _handleNotificationTap(payload);
      }
    },
  );

  // 앱이 종료된 상태에서 알림으로 시작된 경우 확인
  _initialNotificationPayload = await NotificationService().getLaunchPayload();
  if (_initialNotificationPayload != null) {
    print('🚀 앱이 알림으로 시작됨: $_initialNotificationPayload');
  }

  final favoriteProvider = FavoriteProvider();
  await favoriteProvider.loadFavorites();

  final highlightProvider = HighlightProvider();
  // HighlightProvider는 생성자에서 자동으로 _loadHighlights() 호출

  // ✅ LanguageProvider 초기화 추가
  final languageProvider = LanguageProvider();
  // LanguageProvider는 생성자에서 자동으로 _loadLanguage() 호출

  // ✅ FontSizeProvider 초기화 추가
  final bibleFontSizeProvider = BibleFontSizeProvider();
  final planFontSizeProvider = PlanFontSizeProvider();
  // FontSizeProvider는 생성자에서 자동으로 _loadFontSize() 호출

  // PlanProgressProvider 초기화
  final planProgressProvider = PlanProgressProvider();
  await planProgressProvider.loadPlan();

  // BibleSubtitleService 초기화
  await BibleSubtitleService().loadSubtitles();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: favoriteProvider),
        ChangeNotifierProvider.value(value: highlightProvider),
        ChangeNotifierProvider.value(value: languageProvider), // ✅ 추가!
        ChangeNotifierProvider.value(
            value: bibleFontSizeProvider), // ✅ Bible FontSize 추가!
        ChangeNotifierProvider.value(
            value: planFontSizeProvider), // ✅ Plan FontSize 추가!
        ChangeNotifierProvider.value(value: planProgressProvider),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MyApp(initDark: isDark),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool initDark;
  const MyApp({super.key, this.initDark = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ThemeMode _themeMode;
  bool _navigationHandled = false;
  DateTime? _lastPausedTime;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initDark ? ThemeMode.dark : ThemeMode.light;
    WidgetsBinding.instance.addObserver(this);

    // iOS에서 광고 추적 권한 요청 (앱이 완전히 시작된 후)
    _requestTrackingPermission();

    // 앱이 알림으로 시작된 경우 해당 화면으로 이동
    _handleInitialNotification();

    // 마지막 paused 시간 확인
    _checkLastPausedTime();
  }

  Future<void> _checkLastPausedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final pausedTimestamp = prefs.getInt('last_paused_time');
    if (pausedTimestamp != null) {
      _lastPausedTime = DateTime.fromMillisecondsSinceEpoch(pausedTimestamp);
      print('📅 마지막 paused 시간: $_lastPausedTime');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 앱 상태 변경: $state');

    if (state == AppLifecycleState.paused) {
      // 백그라운드로 갈 때 시간 저장
      _lastPausedTime = DateTime.now();
      _saveLastPausedTime();
      print('⏸️ 앱이 백그라운드로 이동: $_lastPausedTime');
    } else if (state == AppLifecycleState.resumed) {
      // 포그라운드로 돌아올 때
      print('▶️ 앱이 포그라운드로 복귀');
      if (_lastPausedTime != null) {
        final duration = DateTime.now().difference(_lastPausedTime!);
        print('⏱️ 백그라운드 시간: ${duration.inMinutes}분');

        // 120분 이상 지났으면 상태 초기화 (너무 오래 백그라운드에 있었음)
        if (duration.inMinutes >= 120) {
          print('🏠 2시간 이상 지나서 홈으로 이동');
          _resetToHome();
        }
      }
    } else if (state == AppLifecycleState.detached) {
      // 앱이 완전히 종료될 때
      print('🔴 앱 종료');
    }
  }

  Future<void> _saveLastPausedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_paused_time', _lastPausedTime!.millisecondsSinceEpoch);
      print('💾 paused 시간 저장: $_lastPausedTime');
    } catch (e) {
      print('❌ paused 시간 저장 실패: $e');
    }
  }

  void _resetToHome() {
    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      try {
        while (navigator.canPop()) {
          navigator.pop();
        }
        print('✅ 홈으로 초기화 완료');
      } catch (e) {
        print('❌ 홈으로 초기화 실패: $e');
      }
    }
  }

  /// iOS 광고 추적 권한 요청
  Future<void> _requestTrackingPermission() async {
    if (!Platform.isIOS) return;

    // 앱이 완전히 활성화될 때까지 대기
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      print('📍 ATT 현재 상태: $status');

      // 아직 권한을 요청하지 않았다면 요청
      if (status == TrackingStatus.notDetermined) {
        print('🔔 ATT 권한 팝업 표시 중...');
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        print('✅ ATT 권한 결과: $result');
      }
    } catch (e) {
      print('⚠️ ATT 권한 요청 오류: $e');
    }
  }

  Future<void> _handleInitialNotification() async {
    if (_navigationHandled) return;

    // main()에서 가져온 payload 확인
    if (_initialNotificationPayload != null) {
      _navigationHandled = true;
      print(
          '🔔 initState에서 launch payload 감지 (main): $_initialNotificationPayload');
      _scheduleNavigation(_initialNotificationPayload!);
      return;
    }

    // 만약 main()에서 못 가져왔다면 다시 한번 시도
    final payload = await NotificationService().getLaunchPayload();
    if (payload != null) {
      _navigationHandled = true;
      print('🔔 initState에서 launch payload 감지 (재확인): $payload');
      _scheduleNavigation(payload);
      return;
    }

    // iOS에서 백업용 SharedPreferences 확인 (2차 백업)
    final prefs = await SharedPreferences.getInstance();
    final backupPayload = prefs.getString('notification_launch_payload');
    if (backupPayload != null &&
        prefs.getBool('notification_launch_flag') == true) {
      _navigationHandled = true;
      print('🔔 initState에서 launch payload 감지 (백업): $backupPayload');
      await prefs.remove('notification_launch_flag');
      await prefs.remove('notification_launch_payload');
      _scheduleNavigation(backupPayload);
    }
  }

  void _scheduleNavigation(String payload) {
    // iOS에서는 더 긴 딜레이가 필요할 수 있음
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 첫 프레임 후에도 충분한 딜레이
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          print('🚀 이제 화면 이동 시작: $payload');
          _navigateToScreen(payload);
          _initialNotificationPayload = null; // 처리 후 초기화
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'All in Bible',
      debugShowCheckedModeBanner: false,
      theme: appTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: appThemeDark.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: _themeMode,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoBounceScrollBehavior(),
          child: child!,
        );
      },
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/bible':
            builder = (context) => const BibleHomeScreen();
            break;
          case '/easyBible':
            builder = (context) => const EasyBibleHomeScreen();
            break;
          case '/quiz':
            builder = (context) => const QuizHomeScreen();
            break;
          // 추가 route는 여기에서 처리
          default:
            builder = (context) => HomeScreen(
                  onThemeToggle: _toggleTheme,
                  isDark: _themeMode == ThemeMode.dark,
                );
        }
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade =
                CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            final scale =
                Tween<double>(begin: 0.98, end: 1.0).animate(animation);
            final offset =
                Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(animation);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: offset,
                child: ScaleTransition(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 290),
          reverseTransitionDuration: const Duration(milliseconds: 230),
          settings: settings,
        );
      },
      home: _OnboardingWrapper(
        onThemeToggle: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

/// 온보딩 체크를 하는 래퍼 위젯
class _OnboardingWrapper extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDark;

  const _OnboardingWrapper({
    required this.onThemeToggle,
    required this.isDark,
  });

  @override
  State<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<_OnboardingWrapper> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (mounted) {
      setState(() {
        _showOnboarding = !onboardingCompleted; // 완료되지 않았을 때만 온보딩 표시
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        // 페이드 + 스케일 효과
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
      child: _showOnboarding
          ? OnboardingScreen(
              key: const ValueKey('onboarding'),
              onComplete: _completeOnboarding,
            )
          : HomeScreen(
              key: const ValueKey('home'),
              onThemeToggle: widget.onThemeToggle,
              isDark: widget.isDark,
            ),
    );
  }
}
