import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:canoto/core/theme/app_theme.dart';
import 'package:canoto/presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize media_kit for video playback
  MediaKit.ensureInitialized();
  
  // TODO: Initialize services
  // await initializeDependencies();
  
  runApp(const CanotoApp());
}

/// Ứng dụng Cân Ô Tô
class CanotoApp extends StatelessWidget {
  const CanotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cân Ô Tô',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
