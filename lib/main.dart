import 'package:easy_bible_app/screens/easyBible/easy_bible_home_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/bible/bible_home_screen.dart';
import 'theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 모든 스크롤의 바운스/Glow(쭉쭉) 완전 제거
class NoBounceScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;
  runApp(MyApp(initDark: isDark));
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
      title: '어! 성경이 읽어지네',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: appThemeDark,
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
