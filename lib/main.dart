import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/glassy.dart';
import 'theme_mode.dart';

// Import the pages you want to navigate between
import 'dashboardpage.dart';
import 'data_monitoring_page.dart';
import 'alertreminder.dart';
import 'habit_tracker_page.dart';
import 'learnprevent.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT_ID.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxcWtnb3d6bmd3eWZjZ2J2cWppIiwicm9zZSI6ImFub24iLCJpYXQiOjE3NjIwNjY5MDMsImV4cCI6MjA3NzY0MjkwM30.W1hKdMml6wW2jC7mVh3hxoEyHXFIZ3vieQD3EfQTT64',
  );
  runApp(const GasGuardApp());
}

class GasGuardApp extends StatelessWidget {
  const GasGuardApp({super.key});

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A), brightness: Brightness.light),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: TextTheme(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.82)),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.78)),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.72)),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.10),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.12),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white.withOpacity(0.10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.22))),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B2C63), brightness: Brightness.dark),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: TextTheme(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.88)),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.84)),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.78)),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.08),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.30),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.18))),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'GasGuard App',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: mode,
          builder: (context, child) => GlassyBackground(child: child ?? const SizedBox.shrink()),
          home: const MainNavigator(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  // List of all the pages corresponding to the tabs
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    DataMonitoringPage(),
    AlertReminderPage(),
    HabitTrackerPage(),
    LearnPreventPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: GlassyContainer(
          borderRadius: BorderRadius.zero,
          padding: EdgeInsets.zero,
          child: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 8),
                const Text('GasGuard'),
              ],
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages.elementAt(_selectedIndex),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: GlassyContainer(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        padding: EdgeInsets.zero,
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Home',
              ),
              _buildNavItem(
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights,
                label: 'Monitor',
              ),
              _buildNavItem(
                icon: Icons.notifications_none_outlined,
                activeIcon: Icons.notifications,
                label: 'Alerts',
              ),
              _buildNavItem(
                icon: Icons.local_fire_department_outlined,
                activeIcon: Icons.local_fire_department,
                label: 'Habits',
              ),
              _buildNavItem(
                icon: Icons.book_outlined,
                activeIcon: Icons.book,
                label: 'Learn',
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFDEF7FF),
          unselectedItemColor: Colors.white.withOpacity(0.7),
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF38BDF8).withOpacity(0.55), // light sky blue
              const Color(0xFF06B6D4).withOpacity(0.55), // cyan
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withOpacity(0.45),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon, size: 24),
      ),
      label: label,
    );
  }
}