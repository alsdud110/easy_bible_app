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

// 알림 탭 핸들러
void _handleNotificationTap(String payload) {
  print('알림 탭됨: $payload');

  // payload 형식: "day60" | "day120" | "day180"
  final context = navigatorKey.currentContext;
  if (context == null) return;

  Widget targetScreen;
  switch (payload) {
    case 'day60':
      targetScreen = const Day60Screen();
      break;
    case 'day120':
      targetScreen = const Day120Screen();
      break;
    case 'day180':
      targetScreen = const Day180Screen();
      break;
    default:
      return;
  }

  // 모든 스택을 제거하고 홈으로 이동한 후, Day 화면을 푸시
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const HomeScreen()),
    (route) => false,
  ).then((_) {
    // 홈으로 이동 후 Day 화면 푸시
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => targetScreen),
    );
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
        _handleNotificationTap(payload);
      }
    },
  );

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

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initDark ? ThemeMode.dark : ThemeMode.light;
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
