import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:canoto/core/theme/app_theme.dart';
import 'package:canoto/presentation/screens/home/home_screen.dart';
import 'package:canoto/providers/notification_provider.dart';
import 'package:canoto/providers/settings_provider.dart';
import 'package:canoto/services/logging/logging_service.dart';
import 'package:canoto/services/database/database_service.dart';
import 'package:canoto/data/repositories/customer_sqlite_repository.dart';
import 'package:canoto/data/repositories/vehicle_sqlite_repository.dart';
import 'package:canoto/data/repositories/product_sqlite_repository.dart';
import 'package:canoto/data/repositories/weighing_ticket_sqlite_repository.dart';
import 'package:canoto/services/audio/audio_service.dart';

void main() async {
  // Run the app in a zone to catch all errors
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize logging service first
      final loggingService = LoggingService.instance;
      await loggingService.initialize();
      loggingService.info('App', 'Application starting...');

      // Initialize SQLite database
      await DatabaseService.instance.initialize();
      loggingService.info('App', 'Database initialized');

      // Insert sample data if tables are empty
      await CustomerSqliteRepository.instance.insertSampleData();
      await VehicleSqliteRepository.instance.insertSampleData();
      await ProductSqliteRepository.instance.insertSampleData();
      await WeighingTicketSqliteRepository.instance.insertSampleData();
      loggingService.info('App', 'Sample data checked/inserted');

      // Initialize media_kit for video playback
      MediaKit.ensureInitialized();
      loggingService.debug('App', 'MediaKit initialized');

      // Initialize audio service for TTS and sound effects
      await AudioService.instance.initialize();
      loggingService.info('App', 'Audio service initialized');

      // Initialize settings provider
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      loggingService.info('App', 'Settings loaded');

      // Initialize notification provider
      final notificationProvider = NotificationProvider();

      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        loggingService.critical(
          'Flutter',
          'Flutter Error: ${details.exception}',
          error: details.exception,
          stackTrace: details.stack,
        );
        // In debug mode, also print to console
        if (kDebugMode) {
          FlutterError.presentError(details);
        }
      };

      // Handle platform dispatcher errors
      PlatformDispatcher.instance.onError = (error, stack) {
        loggingService.critical(
          'Platform',
          'Platform Error: $error',
          error: error,
          stackTrace: stack,
        );
        return true;
      };

      loggingService.info('App', 'Application initialized successfully');

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: notificationProvider),
          ],
          child: const CanotoApp(),
        ),
      );
    },
    (error, stackTrace) {
      // This catches errors outside of Flutter framework
      LoggingService.instance.critical(
        'Zone',
        'Unhandled Error: $error',
        error: error,
        stackTrace: stackTrace,
      );
    },
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
