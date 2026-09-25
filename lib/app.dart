import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/repository.dart';
import 'domain/local_date.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/people_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/today_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets/common.dart';

enum HomeTab { today, people, settings }

/// Lets non-widget code (e.g. a notification tap) switch the visible tab.
final homeTabRequest = ValueNotifier<HomeTab?>(null);

class KeepCloseApp extends StatelessWidget {
  const KeepCloseApp({super.key, required this.deps, this.navigatorKey});

  final AppDependencies deps;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      deps: deps,
      child: MaterialApp(
        title: 'KeepClose',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const _RootGate(),
      ),
    );
  }
}

/// Shows onboarding until it has been completed once.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return Watch<AppSettings>(
      stream: (deps) => deps.repository.watchSettings(),
      loading: const Scaffold(body: SizedBox.shrink()),
      builder: (context, settings) => settings.onboardingDone
          ? const HomeShell()
          : const OnboardingScreen(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  HomeTab _tab = HomeTab.today;
  LocalDate? _day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    homeTabRequest.addListener(_onTabRequest);
    _onTabRequest();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final deps = AppScope.of(context);
      try {
        if (await deps.notifications.launchedFromNotification()) {
          homeTabRequest.value = HomeTab.today;
        }
      } catch (_) {
        // Not available on this platform/test; nothing to do.
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    homeTabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final requested = homeTabRequest.value;
    if (requested == null) return;
    homeTabRequest.value = null;
    if (mounted) setState(() => _tab = requested);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The date or timezone may have changed while we were away.
      final deps = AppScope.of(context);
      deps.scheduler.sync();
      if (deps.today != _day) setState(() => _day = deps.today);
    }
  }

  @override
  Widget build(BuildContext context) {
    _day ??= AppScope.of(context).today;
    return Scaffold(
      // Keyed by day so date-dependent screens rebuild after midnight.
      body: IndexedStack(
        key: ValueKey(_day),
        index: _tab.index,
        children: const [TodayScreen(), PeopleScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (i) => setState(() => _tab = HomeTab.values[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class StartupLoadingApp extends StatelessWidget {
  const StartupLoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong opening your data.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your information is still on this phone. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
