import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/onesignal_service.dart';
import 'services/supabase_service.dart';
import 'services/content_service.dart';
import 'services/sync_service.dart';
import 'services/widget_service.dart';
import 'services/deep_link_service.dart';
import 'data/storage_service.dart';
import 'app_observers.dart';
import 'l10n.dart';
import 'screens/break_screen.dart';

final ValueNotifier<double> textScaleNotifier = ValueNotifier(1.0);
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);
final ValueNotifier<String> pulseNotifier = ValueNotifier(
  'normal',
); // 'off' | 'slow' | 'normal' | 'fast'
// Web has a "Reduce Motion" setting (user_data.reduce_motion, already synced
// by sync_service.dart); this mirrors it on Flutter. When true: page-route
// slide transitions are dropped (pageTransitionsTheme below) and the card
// pulse is forced off regardless of pulse_enabled.
final ValueNotifier<bool> reduceMotionNotifier = ValueNotifier(false);
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// PageTransitionsBuilder that renders the incoming route with no animation —
/// used app-wide when Reduce Motion is on.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

const PageTransitionsTheme _noPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoTransitionsBuilder(),
    TargetPlatform.iOS: _NoTransitionsBuilder(),
    TargetPlatform.fuchsia: _NoTransitionsBuilder(),
    TargetPlatform.linux: _NoTransitionsBuilder(),
    TargetPlatform.macOS: _NoTransitionsBuilder(),
    TargetPlatform.windows: _NoTransitionsBuilder(),
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The whole startup sequence used to be one flat unguarded await chain —
  // any single failing step (Supabase, notifications, content loading, etc.)
  // threw out of main() before runApp() ever ran, leaving the user stuck on
  // a blank/native splash screen forever with no way to retry. Every step
  // below is best-effort: log and fall through to runApp() with whatever
  // defaults the ValueNotifiers already have, rather than never rendering
  // anything at all.
  try {
    await initSupabase();
    OneSignalService.initialize();
    OneSignalService.onNotificationClick((data) {
      final classId = data['class_id'] as String?;
      if (classId == null || classId.isEmpty) return;
      DeepLinkService.navigateToClass(
        classId: classId,
        className: data['class_name'] as String? ?? 'Class',
        isTeacher: data['is_teacher'] == true,
      );
    });
    await WidgetService.init();
    await DeepLinkService.init();
    await ContentService.initialize();
    await NotificationService.initialize();
    final prefs = await SharedPreferences.getInstance();
    final notifEnabled = prefs.getBool('notifications_enabled') ?? true;
    final notifTime = await NotificationService.getSavedTime();
    // Resolve this week's freeze grant once, explicitly, before anything
    // reads streak/freeze state — getStreak()'s missed-day forgiveness and
    // home.dart's freeze display both depend on it already being current.
    await StorageService.grantWeeklyFreezeIfDue();
    final streak = await StorageService.getStreak().catchError((_) => 0);
    final userName = prefs.getString('user_name') ?? '';
    await NotificationService.scheduleReminder(
      customTime: notifTime,
      streak: streak,
      userName: userName,
      enabled: notifEnabled,
    );
    appLangNotifier.value = prefs.getString('ui_language') ?? 'en';
    textScaleNotifier.value = prefs.getDouble('text_scale') ?? 1.0;
    final reduceMotion = prefs.getBool('reduce_motion') ?? false;
    reduceMotionNotifier.value = reduceMotion;
    final pulseEnabled = prefs.getBool('pulse_enabled') ?? true;
    final pulseSpeed = prefs.getString('pulse_speed') ?? 'normal';
    pulseNotifier.value = (pulseEnabled && !reduceMotion) ? pulseSpeed : 'off';
    final themeModeStr = prefs.getString('theme_mode') ?? 'system';
    themeModeNotifier.value = themeModeStr == 'dark'
        ? ThemeMode.dark
        : themeModeStr == 'light'
        ? ThemeMode.light
        : ThemeMode.system;
  } catch (e, st) {
    // ignore: avoid_print
    print('[main] startup init failed, continuing with defaults: $e\n$st');
  }

  runApp(const LexivoApp());
}

class LexivoApp extends StatelessWidget {
  const LexivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLangNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, themeMode, _) {
            return ValueListenableBuilder<double>(
              valueListenable: textScaleNotifier,
              builder: (context, scale, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: reduceMotionNotifier,
                  builder: (context, reduceMotion, _) {
                    final pageTransitions = reduceMotion
                        ? _noPageTransitions
                        : null;
                    return MaterialApp(
                      title: 'Lexivo',
                      debugShowCheckedModeBanner: false,
                      navigatorKey: navigatorKey,
                      theme: ThemeData(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: const Color(0xFF6C63FF),
                        ),
                        useMaterial3: true,
                        scaffoldBackgroundColor: const Color(0xFFF8F7FF),
                        pageTransitionsTheme: pageTransitions,
                      ),
                      darkTheme: ThemeData(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: const Color(0xFF8B85FF),
                          brightness: Brightness.dark,
                        ),
                        useMaterial3: true,
                        scaffoldBackgroundColor: const Color(0xFF0F0E1A),
                        pageTransitionsTheme: pageTransitions,
                      ),
                      themeMode: themeMode,
                      navigatorObservers: [routeObserver],
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: TextScaler.linear(scale)),
                          child: Stack(
                            children: [child!, const BreakOverlay()],
                          ),
                        );
                      },
                      home: const SplashRouter(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _relinkPushIfEnabled(String userId) async {
    try {
      final res = await supabase
          .from('profiles')
          .select('push_enabled')
          .eq('id', userId)
          .maybeSingle();
      if (res?['push_enabled'] == true) {
        OneSignalService.linkUser(userId);
      }
    } catch (_) {}
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // If not signed in, go to login (unless they've already chosen guest mode)
    if (currentUser == null) {
      final guestMode = prefs.getBool('guest_mode') ?? false;
      if (!guestMode) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
    } else {
      // Signed-in users go straight to the app regardless of local onboarding flag —
      // they already have an account so onboarding is irrelevant on a new device.
      // Awaited so no user action can push a stale pre-merge value (XP, learned
      // words, etc.) over newer cloud data before the initial pull lands.
      await SyncService.pullAll();
      if (!mounted) return;
      // Both write to the home-screen widget's saved data and both end
      // with HomeWidget.updateWidget() (which re-renders from whatever is
      // currently saved across every key) — firing them unawaited let
      // whichever happened to finish last win, with no guaranteed order.
      // Sequenced so the widget's first render after login reflects both
      // datasets instead of racing.
      await WidgetService.refreshFromSupabase();
      await WidgetService.pushStats();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(
            wordSource: prefs.getString('word_source') ?? 'prebuilt',
            exampleStyle: prefs.getString('example_style') ?? 'reallife',
            userProfile: prefs.getString('user_profile') ?? 'worker',
            languageLevel: prefs.getString('language_level') ?? 'intermediate',
            dailyWordGoal: StorageService.dailyWordGoalOf(prefs),
          ),
        ),
      );
      _relinkPushIfEnabled(currentUser!.id);
      return;
    }

    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (completed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(
            wordSource: prefs.getString('word_source') ?? 'prebuilt',
            exampleStyle: prefs.getString('example_style') ?? 'reallife',
            userProfile: prefs.getString('user_profile') ?? 'worker',
            languageLevel: prefs.getString('language_level') ?? 'intermediate',
            dailyWordGoal: StorageService.dailyWordGoalOf(prefs),
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF6C63FF),
      body: Center(
        child: Text(
          'Lexivo',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C63FF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Lexivo',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('learn_words_that_stick'),
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingFlow(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  tr('get_started'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
