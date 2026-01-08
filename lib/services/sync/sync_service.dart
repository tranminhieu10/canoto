import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:canoto/services/api/api_service.dart';
import 'package:canoto/data/models/weighing_ticket.dart';

/// Sync Service for background data synchronization
/// Implements the sync workflow:
/// 1. Query Local DB for records with isSynced == false
/// 2. Convert to JSON
/// 3. POST to Azure API
/// 4. On success (200 OK): Update local records with isSynced = true
/// 5. On failure: Retry later
class SyncService {
  // Singleton pattern
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();

  final ApiService _apiService = ApiService.instance;
  
  // Sync state
  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  
  // Callbacks
  final List<Function(SyncStatus)> _listeners = [];
  
  // Sync configuration
  static const Duration autoSyncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 30);

  /// Current sync status
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  bool get isSyncing => _isSyncing;

  /// Reset sync state (use when sync is stuck)
  void resetSyncState() {
    _isSyncing = false;
    _updateStatus(SyncStatus.idle);
    debugPrint('SyncService: State reset to idle');
  }

  /// Initialize sync service with Azure settings
  void initialize({String? apiKey, String? baseUrl}) {
    resetSyncState(); // Reset sync state on init
    _apiService.initialize(apiKey: apiKey, baseUrl: baseUrl);
    debugPrint('SyncService: Initialized with Azure settings - apiKey=${apiKey != null && apiKey.isNotEmpty}, baseUrl=$baseUrl');
  }

  /// Update configuration
  void configure({String? apiKey, String? baseUrl}) {
    _apiService.configure(apiKey: apiKey, baseUrl: baseUrl);
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _listeners.clear();
    _apiService.dispose();
  }

  /// Add listener for sync status changes
  void addListener(Function(SyncStatus) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(Function(SyncStatus) listener) {
    _listeners.remove(listener);
  }

  /// Notify listeners of status change
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_status);
    }
  }

  /// Update status and notify
  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    _notifyListeners();
    debugPrint('SyncService: Status changed to $newStatus');
  }

  /// Start automatic background sync
  void startAutoSync() {
    stopAutoSync();
    _autoSyncTimer = Timer.periodic(autoSyncInterval, (_) {
      syncData();
    });
    debugPrint('SyncService: Auto-sync started (interval: ${autoSyncInterval.inMinutes} minutes)');
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    debugPrint('SyncService: Auto-sync stopped');
  }

  /// Main sync function - syncData()
  /// Returns SyncResult with details
  Future<SyncResult> syncData({
    Future<List<WeighingTicket>> Function()? getUnsyncedTickets,
    Future<void> Function(List<int> ids, List<int?> azureIds)? markAsSynced,
  }) async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress, skipping');
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedCount: 0,
      );
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);
    debugPrint('SyncService: Starting sync...');

    try {
      // Step 1: Check network availability
      debugPrint('SyncService: Checking network...');
      final isOnline = await _apiService.isNetworkAvailable();
      if (!isOnline) {
        debugPrint('SyncService: No network connection');
        _isSyncing = false; // Reset sync flag
        _updateStatus(SyncStatus.offline);
        return SyncResult(
          success: false,
          message: 'No network connection',
          syncedCount: 0,
        );
      }
      debugPrint('SyncService: Network OK');

      // Step 2: Get unsynced records from local DB
      debugPrint('SyncService: Getting unsynced tickets...');
      List<WeighingTicket> unsyncedTickets = [];
      if (getUnsyncedTickets != null) {
        unsyncedTickets = await getUnsyncedTickets();
      } else {
        debugPrint('SyncService: WARNING - getUnsyncedTickets callback is null!');
      }

      debugPrint('SyncService: Found ${unsyncedTickets.length} unsynced tickets');
      
      if (unsyncedTickets.isEmpty) {
        _updateStatus(SyncStatus.synced);
        return SyncResult(
          success: true,
          message: 'No records to sync',
          syncedCount: 0,
        );
      }

      // Step 3: Convert to JSON
      debugPrint('SyncService: Converting ${unsyncedTickets.length} tickets to JSON...');
      final jsonData = unsyncedTickets.map((t) => t.toJson()).toList();
      debugPrint('SyncService: JSON data ready, uploading...');

      // Step 4: POST to Azure API with retry
      ApiResponse? response;
      int attempts = 0;
      
      while (attempts < maxRetryAttempts) {
        attempts++;
        debugPrint('SyncService: Upload attempt $attempts/$maxRetryAttempts');
        
        response = await _apiService.uploadWeighingTicketsData(jsonData);
        debugPrint('SyncService: Response: ${response.success} - ${response.message}');
        
        if (response.success) {
          break;
        }
        
        // Wait before retry
        if (attempts < maxRetryAttempts) {
          await Future.delayed(retryDelay);
        }
      }

      // Step 5: Handle response
      if (response != null && response.success) {
        // Success - update local records
        final localIds = unsyncedTickets.map((t) => t.id!).toList();
        final azureIds = response.azureIds;

        if (markAsSynced != null) {
          final List<int?> azureIdsList = azureIds?.cast<int?>() ?? [];
          await markAsSynced(localIds, azureIdsList);
        }

        _updateStatus(SyncStatus.synced);
        return SyncResult(
          success: true,
          message: 'Sync completed successfully',
          syncedCount: unsyncedTickets.length,
          azureIds: azureIds,
        );
      } else {
        // Failure - will retry on next sync
        _updateStatus(SyncStatus.error);
        return SyncResult(
          success: false,
          message: response?.error ?? 'Unknown error',
          syncedCount: 0,
        );
      }
    } catch (e) {
      debugPrint('SyncService: Error during sync: $e');
      _updateStatus(SyncStatus.error);
      return SyncResult(
        success: false,
        message: e.toString(),
        syncedCount: 0,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Force sync immediately
  Future<SyncResult> forceSync({
    Future<List<WeighingTicket>> Function()? getUnsyncedTickets,
    Future<void> Function(List<int> ids, List<int?> azureIds)? markAsSynced,
  }) async {
    return syncData(
      getUnsyncedTickets: getUnsyncedTickets,
      markAsSynced: markAsSynced,
    );
  }

  /// Get sync statistics
  Future<SyncStats> getSyncStats({
    Future<int> Function()? getTotalCount,
    Future<int> Function()? getSyncedCount,
    Future<int> Function()? getUnsyncedCount,
  }) async {
    final total = getTotalCount != null ? await getTotalCount() : 0;
    final synced = getSyncedCount != null ? await getSyncedCount() : 0;
    final unsynced = getUnsyncedCount != null ? await getUnsyncedCount() : 0;

    return SyncStats(
      totalRecords: total,
      syncedRecords: synced,
      unsyncedRecords: unsynced,
      lastSyncTime: DateTime.now(),
    );
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

/// Sync result
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final List<int>? azureIds;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    this.azureIds,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, syncedCount: $syncedCount, message: $message)';
  }
}

/// Sync statistics
class SyncStats {
  final int totalRecords;
  final int syncedRecords;
  final int unsyncedRecords;
  final DateTime lastSyncTime;

  SyncStats({
    required this.totalRecords,
    required this.syncedRecords,
    required this.unsyncedRecords,
    required this.lastSyncTime,
  });

  double get syncPercentage {
    if (totalRecords == 0) return 100.0;
    return (syncedRecords / totalRecords) * 100;
  }

  @override
  String toString() {
    return 'SyncStats(total: $totalRecords, synced: $syncedRecords, unsynced: $unsyncedRecords)';
  }
}
