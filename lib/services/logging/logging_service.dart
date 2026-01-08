import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Log levels for the application
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Extension for LogLevel
extension LogLevelExtension on LogLevel {
  String get name {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
    }
  }

  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }

  int get priority {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
      case LogLevel.critical:
        return 4;
    }
  }
}

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String format() {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final buffer = StringBuffer();
    buffer.write('[$timeStr] ');
    buffer.write('[${level.name}] ');
    buffer.write('[$tag] ');
    buffer.write(message);
    
    if (error != null) {
      buffer.write('\nError: $error');
    }
    if (stackTrace != null) {
      buffer.write('\nStackTrace:\n$stackTrace');
    }
    
    return buffer.toString();
  }

  @override
  String toString() => format();
}

/// Professional Logging Service
class LoggingService {
  // Singleton
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();
  LoggingService._();

  // Configuration
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _writeToFile = true;
  bool _printToConsole = true;
  int _maxLogFiles = 7; // Keep 7 days of logs
  
  // File handling
  File? _currentLogFile;
  IOSink? _fileSink;
  final List<LogEntry> _recentLogs = [];
  static const int _maxRecentLogs = 100;
  
  // Stream for UI updates
  final StreamController<LogEntry> _logController = 
      StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get logStream => _logController.stream;

  /// Initialize logging service
  Future<void> initialize() async {
    if (_writeToFile) {
      await _initLogFile();
      await _cleanOldLogs();
    }
    
    info('LoggingService', 'Logging service initialized');
  }

  /// Configure logging
  void configure({
    LogLevel? minLevel,
    bool? writeToFile,
    bool? printToConsole,
    int? maxLogFiles,
  }) {
    if (minLevel != null) _minLevel = minLevel;
    if (writeToFile != null) _writeToFile = writeToFile;
    if (printToConsole != null) _printToConsole = printToConsole;
    if (maxLogFiles != null) _maxLogFiles = maxLogFiles;
  }

  Future<void> _initLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/canoto/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _currentLogFile = File('${logDir.path}/canoto_$today.log');
      _fileSink = _currentLogFile!.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('LoggingService: Failed to initialize log file: $e');
    }
  }

  Future<void> _cleanOldLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/canoto/logs');
      
      if (!await logDir.exists()) return;
      
      final files = await logDir.list().toList();
      final logFiles = files.whereType<File>().where((f) => f.path.endsWith('.log')).toList();
      
      // Sort by modification date
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Delete old files
      if (logFiles.length > _maxLogFiles) {
        for (var i = _maxLogFiles; i < logFiles.length; i++) {
          await logFiles[i].delete();
        }
      }
    } catch (e) {
      debugPrint('LoggingService: Failed to clean old logs: $e');
    }
  }

  /// Log a message
  void log(LogLevel level, String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    if (level.priority < _minLevel.priority) return;
    
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    
    // Add to recent logs
    _recentLogs.add(entry);
    if (_recentLogs.length > _maxRecentLogs) {
      _recentLogs.removeAt(0);
    }
    
    // Stream
    _logController.add(entry);
    
    // Console
    if (_printToConsole) {
      _printToConsolePretty(entry);
    }
    
    // File
    if (_writeToFile && _fileSink != null) {
      _fileSink!.writeln(entry.format());
    }
  }

  void _printToConsolePretty(LogEntry entry) {
    final color = _getAnsiColor(entry.level);
    final reset = '\x1B[0m';
    
    if (kDebugMode) {
      debugPrint('$color${entry.level.emoji} [${entry.tag}] ${entry.message}$reset');
      if (entry.error != null) {
        debugPrint('$color   Error: ${entry.error}$reset');
      }
      if (entry.stackTrace != null) {
        debugPrint('$color   Stack: ${entry.stackTrace.toString().split('\n').take(5).join('\n   ')}$reset');
      }
    }
  }

  String _getAnsiColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[37m'; // White
      case LogLevel.info:
        return '\x1B[36m'; // Cyan
      case LogLevel.warning:
        return '\x1B[33m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m'; // Red
      case LogLevel.critical:
        return '\x1B[35m'; // Magenta
    }
  }

  /// Convenience methods
  void debug(String tag, String message) => log(LogLevel.debug, tag, message);
  void info(String tag, String message) => log(LogLevel.info, tag, message);
  void warning(String tag, String message, {dynamic error}) => 
      log(LogLevel.warning, tag, message, error: error);
  void error(String tag, String message, {dynamic error, StackTrace? stackTrace}) => 
      log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  void critical(String tag, String message, {dynamic error, StackTrace? stackTrace}) => 
      log(LogLevel.critical, tag, message, error: error, stackTrace: stackTrace);

  /// Get recent logs
  List<LogEntry> getRecentLogs({LogLevel? minLevel}) {
    if (minLevel == null) return List.from(_recentLogs);
    return _recentLogs.where((e) => e.level.priority >= minLevel.priority).toList();
  }

  /// Export logs to string
  String exportLogs() {
    return _recentLogs.map((e) => e.format()).join('\n');
  }

  /// Get log file path
  Future<String?> getLogFilePath() async {
    return _currentLogFile?.path;
  }

  /// Dispose
  void dispose() {
    _fileSink?.close();
    _logController.close();
  }
}

/// Global logger instance for convenience
final logger = LoggingService.instance;
