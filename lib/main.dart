import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/resume_editor_screen.dart';
import 'screens/career_tools_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_drawer.dart';
import 'models/app_state.dart';
import 'services/download_notification_service.dart';
import 'services/interview_speech_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await appState.load();
  } catch (error) {
    debugPrint('Could not load saved CV Helper data: $error');
  }
  try {
    await DownloadNotificationService.initialize();
  } catch (error) {
    debugPrint('Could not initialize download notifications: $error');
  }
  runApp(const CVHelperApp());
}

class CVHelperApp extends StatelessWidget {
  const CVHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CV Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _showResumeEditor = false;
  bool _showCareerTools = false;
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStartupPermissions();
    });
  }

  Future<void> _requestStartupPermissions() async {
    try {
      await DownloadNotificationService.requestPermission();
    } catch (error) {
      debugPrint('Could not request notification permission: $error');
    }
    try {
      await interviewSpeechService.initialize();
    } catch (error) {
      debugPrint('Could not request microphone permission: $error');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _showResumeEditor = false;
      _showCareerTools = false;
      _showNotifications = false;
    });
  }

  void _navigateToResumeEditor() {
    setState(() {
      _showResumeEditor = true;
      _showCareerTools = false;
      _showNotifications = false;
    });
  }

  void _navigateToCareerTools() {
    setState(() {
      _showResumeEditor = false;
      _showCareerTools = true;
      _showNotifications = false;
    });
  }

  void _navigateToProfile() {
    setState(() {
      _currentIndex = 3;
      _showResumeEditor = false;
      _showCareerTools = false;
      _showNotifications = false;
    });
  }

  void _navigateToHome() {
    setState(() {
      _currentIndex = 0;
      _showResumeEditor = false;
      _showCareerTools = false;
      _showNotifications = false;
    });
  }

  void _navigateToNotifications() {
    setState(() {
      _currentIndex = 0;
      _showResumeEditor = false;
      _showCareerTools = false;
      _showNotifications = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    if (_showNotifications) {
      currentScreen = NotificationsScreen(onBack: _navigateToHome);
    } else if (_showResumeEditor) {
      currentScreen = ResumeEditorScreen(
        onBack: () => setState(() => _showResumeEditor = false),
      );
    } else if (_showCareerTools) {
      currentScreen = CareerToolsScreen(
        onBack: () => setState(() => _showCareerTools = false),
      );
    } else {
      switch (_currentIndex) {
        case 0:
          currentScreen = HomeScreen(
            onNavigateToResumeEditor: _navigateToResumeEditor,
            onNavigateToTools: _navigateToCareerTools,
            onNavigateToNotifications: _navigateToNotifications,
          );
          break;
        case 1:
          currentScreen = ResumeEditorScreen(
            onBack: () => setState(() => _currentIndex = 0),
          );
          break;
        case 2:
          currentScreen = CareerToolsScreen(
            onBack: () => setState(() => _currentIndex = 0),
          );
          break;
        case 3:
          currentScreen = ProfileScreen(
            onNavigateToResumeEditor: _navigateToResumeEditor,
            onNavigateToTools: _navigateToCareerTools,
          );
          break;
        default:
          currentScreen = HomeScreen(
            onNavigateToResumeEditor: _navigateToResumeEditor,
            onNavigateToTools: _navigateToCareerTools,
            onNavigateToNotifications: _navigateToNotifications,
          );
      }
    }

    return Scaffold(
      drawer: AppDrawer(
        onNavigateHome: _navigateToHome,
        onNavigateResumeEditor: _navigateToResumeEditor,
        onNavigateTools: _navigateToCareerTools,
        onNavigateProfile: _navigateToProfile,
      ),
      body: Stack(
        children: [
          currentScreen,
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Center(
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home'),
                    const SizedBox(width: 8),
                    _buildNavItem(1, Icons.description_rounded, null),
                    const SizedBox(width: 8),
                    _buildNavItem(2, Icons.handyman_rounded, 'Tools'),
                    const SizedBox(width: 8),
                    _buildNavItem(3, Icons.person_rounded, null),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String? label) {
    bool isSelected =
        (!_showResumeEditor && !_showCareerTools && _currentIndex == index) ||
        (_showResumeEditor && index == 1) ||
        (_showCareerTools && index == 2);

    return GestureDetector(
      onTap: () {
        if (index == 1) {
          _navigateToResumeEditor();
        } else if (index == 2) {
          _navigateToCareerTools();
        } else {
          _onTabTapped(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 18 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBE8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1A1A1E) : Colors.grey[400],
              size: 22,
            ),
            if (label != null && isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A1A1E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
