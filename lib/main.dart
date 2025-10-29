import 'package:easy_bible_app/screens/easyBible/easy_bible_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_screen.dart';
import 'screens/bible/bible_home_screen.dart';
import 'screens/biblePlan/day60_screen.dart';
import 'screens/biblePlan/day120_screen.dart';
import 'screens/biblePlan/day180_screen.dart';
import 'theme/app_theme.dart';
import 'providers/favorite_provider.dart';
import 'providers/highlight_provider.dart';
import 'providers/language_provider.dart'; // ✅ 이미 import되어 있음
import 'providers/plan_progress_provider.dart';
import 'services/notification_service.dart';
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
  if (navigator == null) {
    print('⚠️ Navigator가 아직 준비되지 않음 - 500ms 후 재시도');
    // Navigator가 준비되지 않았다면 다시 시도
    Future.delayed(const Duration(milliseconds: 500), () {
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
    navigator.popUntil((route) => route.isFirst);
    print('✅ 홈 화면으로 이동 완료');
  } catch (e) {
    print('⚠️ popUntil 오류: $e');
  }

  // 약간의 딜레이 후 Day 화면으로 이동 (부드러운 전환)
  Future.delayed(const Duration(milliseconds: 500), () {
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

  await MobileAds.instance.initialize();

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

  // PlanProgressProvider 초기화
  final planProgressProvider = PlanProgressProvider();
  await planProgressProvider.loadPlan();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: favoriteProvider),
        ChangeNotifierProvider.value(value: highlightProvider),
        ChangeNotifierProvider.value(value: languageProvider), // ✅ 추가!
        ChangeNotifierProvider.value(value: planProgressProvider),
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

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initDark ? ThemeMode.dark : ThemeMode.light;
    WidgetsBinding.instance.addObserver(this);

    // 앱이 알림으로 시작된 경우 해당 화면으로 이동
    _handleInitialNotification();
  }

  Future<void> _handleInitialNotification() async {
    if (_navigationHandled) return;

    // main()에서 가져온 payload 확인
    if (_initialNotificationPayload != null) {
      _navigationHandled = true;
      print('🔔 initState에서 launch payload 감지 (main): $_initialNotificationPayload');
      _scheduleNavigation(_initialNotificationPayload!);
      return;
    }

    // 만약 main()에서 못 가져왔다면 다시 한번 시도
    final payload = await NotificationService().getLaunchPayload();
    if (payload != null) {
      _navigationHandled = true;
      print('🔔 initState에서 launch payload 감지 (재확인): $payload');
      _scheduleNavigation(payload);
    }
  }

  void _scheduleNavigation(String payload) {
    // 충분한 딜레이를 주어 모든 Provider와 UI가 준비되도록 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 첫 프레임 후에도 약간의 딜레이
      Future.delayed(const Duration(milliseconds: 1000), () {
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
      home: HomeScreen(
        onThemeToggle: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
