import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// Error Handler Service - Xử lý lỗi toàn cục
class ErrorHandler {
  // Singleton
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();
  ErrorHandler._();

  // Error callbacks
  final List<void Function(FlutterErrorDetails)> _flutterErrorCallbacks = [];
  final List<void Function(Object, StackTrace)> _asyncErrorCallbacks = [];

  /// Khởi tạo error handler
  void initialize() {
    // Override Flutter error handler
    FlutterError.onError = _handleFlutterError;
    
    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleAsyncError(error, stack);
      return true; // Đã xử lý
    };
    
    logger.info('ErrorHandler', 'Error handler initialized');
  }

  /// Xử lý Flutter errors
  void _handleFlutterError(FlutterErrorDetails details) {
    logger.critical(
      'FlutterError',
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    
    // Call registered callbacks
    for (final callback in _flutterErrorCallbacks) {
      try {
        callback(details);
      } catch (e) {
        debugPrint('ErrorHandler: Callback error: $e');
      }
    }
    
    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Xử lý async errors
  void _handleAsyncError(Object error, StackTrace stack) {
    logger.critical(
      'AsyncError',
      error.toString(),
      error: error,
      stackTrace: stack,
    );
    
    // Call registered callbacks
    for (final callback in _asyncErrorCallbacks) {
      try {
        callback(error, stack);
      } catch (e) {
        debugPrint('ErrorHandler: Async callback error: $e');
      }
    }
  }

  /// Đăng ký callback cho Flutter errors
  void addFlutterErrorCallback(void Function(FlutterErrorDetails) callback) {
    _flutterErrorCallbacks.add(callback);
  }

  /// Đăng ký callback cho async errors
  void addAsyncErrorCallback(void Function(Object, StackTrace) callback) {
    _asyncErrorCallbacks.add(callback);
  }

  /// Bọc async function với error handling
  Future<T?> runSafe<T>(
    Future<T> Function() action, {
    String? tag,
    T? defaultValue,
    void Function(Object, StackTrace)? onError,
  }) async {
    try {
      return await action();
    } catch (e, stack) {
      logger.error(
        tag ?? 'ErrorHandler',
        'runSafe caught error',
        error: e,
        stackTrace: stack,
      );
      onError?.call(e, stack);
      return defaultValue;
    }
  }

  /// Bọc sync function với error handling
  T? runSafeSync<T>(
    T Function() action, {
    String? tag,
    T? defaultValue,
    void Function(Object, StackTrace)? onError,
  }) {
    try {
      return action();
    } catch (e, stack) {
      logger.error(
        tag ?? 'ErrorHandler',
        'runSafeSync caught error',
        error: e,
        stackTrace: stack,
      );
      onError?.call(e, stack);
      return defaultValue;
    }
  }

  /// Hiển thị dialog lỗi
  void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRetry();
              },
              child: const Text('Thử lại'),
            ),
        ],
      ),
    );
  }

  /// Hiển thị snackbar lỗi
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Chi tiết',
          textColor: Colors.white,
          onPressed: () {
            // Show detailed error
          },
        ),
      ),
    );
  }
}

/// Global error handler instance
final errorHandler = ErrorHandler.instance;

/// Widget hiển thị khi có lỗi trong UI
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    // Register for errors
    ErrorWidget.builder = (details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _error = details);
        }
      });
      return const SizedBox.shrink();
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _buildDefaultError(_error!);
    }
    return widget.child;
  }

  Widget _buildDefaultError(FlutterErrorDetails details) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              details.exceptionAsString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _error = null),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
