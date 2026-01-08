import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:canoto/core/theme/app_theme.dart';
import 'package:canoto/presentation/screens/home/home_screen.dart';
import 'package:canoto/providers/notification_provider.dart';
import 'package:canoto/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize media_kit for video playback
  MediaKit.ensureInitialized();
  
  // Initialize settings provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();
  
  // Initialize notification provider
  final notificationProvider = NotificationProvider();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const CanotoApp(),
    ),
  );
}

/// Ứng dụng Cân Ô Tô
class CanotoApp extends StatefulWidget {
  const CanotoApp({super.key});

  @override
  State<CanotoApp> createState() => _CanotoAppState();
}

class _CanotoAppState extends State<CanotoApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = context.read<NotificationProvider>();
      notificationProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Cân Ô Tô',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}

