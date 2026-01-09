import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:canoto/services/api/api_service.dart';
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sync Service for background data synchronization
/// Implements the sync workflow:
/// 1. Query Local DB for records with isSynced == false
/// 2. Convert to JSON
/// 3. POST to Azure API
/// 4. On success (200 OK): Update local records with isSynced = true
/// 5. On failure: Retry with exponential backoff
class SyncService {
  // Singleton pattern
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();

  final ApiService _apiService = ApiService.instance;
  
  // Sync state
  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  Timer? _retryTimer;
  int _consecutiveFailures = 0;
  DateTime? _lastSyncAttempt;
  DateTime? _lastSuccessfulSync;
  
  // Callbacks
  final List<Function(SyncStatus)> _listeners = [];
  
  // Sync configuration
  static const Duration autoSyncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 5);
  static const Duration maxRetryDelay = Duration(minutes: 5);
  static const int batchSize = 50; // Sync in batches to avoid timeout

  // Preference keys
  static const String _prefLastSyncKey = 'sync_last_successful';
  static const String _prefConsecutiveFailuresKey = 'sync_consecutive_failures';

  /// Current sync status
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  bool get isSyncing => _isSyncing;
  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  /// Reset sync state (use when sync is stuck)
  void resetSyncState() {
    _isSyncing = false;
    _consecutiveFailures = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
    _updateStatus(SyncStatus.idle);
    debugPrint('SyncService: State reset to idle');
  }

  /// Initialize sync service with Azure settings
  Future<void> initialize({String? apiKey, String? baseUrl}) async {
    resetSyncState();
    _apiService.initialize(apiKey: apiKey, baseUrl: baseUrl);
    
    // Load last sync time from preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_prefLastSyncKey);
      if (lastSyncStr != null) {
        _lastSuccessfulSync = DateTime.tryParse(lastSyncStr);
      }
      _consecutiveFailures = prefs.getInt(_prefConsecutiveFailuresKey) ?? 0;
    } catch (e) {
      debugPrint('SyncService: Failed to load preferences: $e');
    }
    
    debugPrint('SyncService: Initialized with Azure settings - apiKey=${apiKey != null && apiKey.isNotEmpty}, baseUrl=$baseUrl');
    debugPrint('SyncService: Last successful sync: $_lastSuccessfulSync, consecutive failures: $_consecutiveFailures');
  }

  /// Update configuration
  void configure({String? apiKey, String? baseUrl}) {
    _apiService.configure(apiKey: apiKey, baseUrl: baseUrl);
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _retryTimer?.cancel();
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

  /// Save sync state to preferences
  Future<void> _saveSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSuccessfulSync != null) {
        await prefs.setString(_prefLastSyncKey, _lastSuccessfulSync!.toIso8601String());
      }
      await prefs.setInt(_prefConsecutiveFailuresKey, _consecutiveFailures);
    } catch (e) {
      debugPrint('SyncService: Failed to save preferences: $e');
    }
  }

  /// Calculate retry delay with exponential backoff
  Duration _getRetryDelay() {
    // Exponential backoff: 5s, 10s, 20s, 40s, 80s, up to 5 minutes
    final delaySeconds = initialRetryDelay.inSeconds * (1 << _consecutiveFailures.clamp(0, 6));
    final delay = Duration(seconds: delaySeconds);
    return delay > maxRetryDelay ? maxRetryDelay : delay;
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
    _lastSyncAttempt = DateTime.now();
    _updateStatus(SyncStatus.syncing);
    debugPrint('SyncService: Starting sync...');

    try {
      // Step 1: Check network availability
      debugPrint('SyncService: Checking network...');
      final isOnline = await _apiService.isNetworkAvailable();
      if (!isOnline) {
        debugPrint('SyncService: No network connection');
        _isSyncing = false;
        _updateStatus(SyncStatus.offline);
        _scheduleRetry(getUnsyncedTickets: getUnsyncedTickets, markAsSynced: markAsSynced);
        return SyncResult(
          success: false,
          message: 'Không có kết nối mạng',
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
        _consecutiveFailures = 0;
        _lastSuccessfulSync = DateTime.now();
        await _saveSyncState();
        _updateStatus(SyncStatus.synced);
        return SyncResult(
          success: true,
          message: 'Không có dữ liệu cần đồng bộ',
          syncedCount: 0,
        );
      }

      // Step 3: Sync in batches for better reliability
      int totalSynced = 0;
      List<int> allAzureIds = [];
      final batches = _splitIntoBatches(unsyncedTickets, batchSize);
      
      debugPrint('SyncService: Syncing ${unsyncedTickets.length} tickets in ${batches.length} batches...');

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];
        debugPrint('SyncService: Processing batch ${batchIndex + 1}/${batches.length} (${batch.length} tickets)');
        
        final jsonData = batch.map((t) => t.toJson()).toList();
        
        // Step 4: POST to Azure API with retry
        ApiResponse? response;
        int attempts = 0;
        
        while (attempts < maxRetryAttempts) {
          attempts++;
          debugPrint('SyncService: Upload attempt $attempts/$maxRetryAttempts for batch ${batchIndex + 1}');
          
          response = await _apiService.uploadWeighingTicketsData(jsonData);
          debugPrint('SyncService: Response: ${response.success} - ${response.message}');
          
          if (response.success) {
            break;
          }
          
          // Exponential backoff between retries
          if (attempts < maxRetryAttempts) {
            final delay = Duration(seconds: initialRetryDelay.inSeconds * attempts);
            debugPrint('SyncService: Retry after ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        }

        // Step 5: Handle batch response
        if (response != null && response.success) {
          final localIds = batch.map((t) => t.id!).toList();
          final azureIds = response.azureIds;

          if (markAsSynced != null) {
            final List<int?> azureIdsList = azureIds?.cast<int?>() ?? [];
            await markAsSynced(localIds, azureIdsList);
          }

          totalSynced += batch.length;
          if (azureIds != null) {
            allAzureIds.addAll(azureIds);
          }
          
          debugPrint('SyncService: Batch ${batchIndex + 1} synced successfully');
        } else {
          // Batch failed - continue with remaining batches
          debugPrint('SyncService: Batch ${batchIndex + 1} failed: ${response?.error ?? "Unknown error"}');
          _consecutiveFailures++;
          await _saveSyncState();
        }
      }

      // Final result
      if (totalSynced > 0) {
        _consecutiveFailures = 0;
        _lastSuccessfulSync = DateTime.now();
        await _saveSyncState();
        _updateStatus(SyncStatus.synced);
        
        debugPrint('SyncService: Sync completed - $totalSynced/${unsyncedTickets.length} tickets synced');
        
        return SyncResult(
          success: true,
          message: 'Đồng bộ thành công $totalSynced/${unsyncedTickets.length} phiếu cân',
          syncedCount: totalSynced,
          azureIds: allAzureIds.isNotEmpty ? allAzureIds : null,
        );
      } else {
        _consecutiveFailures++;
        await _saveSyncState();
        _updateStatus(SyncStatus.error);
        _scheduleRetry(getUnsyncedTickets: getUnsyncedTickets, markAsSynced: markAsSynced);
        
        return SyncResult(
          success: false,
          message: 'Đồng bộ thất bại sau $maxRetryAttempts lần thử',
          syncedCount: 0,
        );
      }
    } catch (e) {
      debugPrint('SyncService: Error during sync: $e');
      _consecutiveFailures++;
      await _saveSyncState();
      _updateStatus(SyncStatus.error);
      _scheduleRetry(getUnsyncedTickets: getUnsyncedTickets, markAsSynced: markAsSynced);
      
      return SyncResult(
        success: false,
        message: 'Lỗi đồng bộ: ${e.toString()}',
        syncedCount: 0,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Split list into batches
  List<List<T>> _splitIntoBatches<T>(List<T> list, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize < list.length) ? i + batchSize : list.length;
      batches.add(list.sublist(i, end));
    }
    return batches;
  }

  /// Schedule retry with exponential backoff
  void _scheduleRetry({
    Future<List<WeighingTicket>> Function()? getUnsyncedTickets,
    Future<void> Function(List<int> ids, List<int?> azureIds)? markAsSynced,
  }) {
    if (_consecutiveFailures > 10) {
      debugPrint('SyncService: Too many failures, not scheduling retry');
      return;
    }
    
    _retryTimer?.cancel();
    final delay = _getRetryDelay();
    debugPrint('SyncService: Scheduling retry in ${delay.inSeconds}s (failure #$_consecutiveFailures)');
    
    _retryTimer = Timer(delay, () {
      syncData(getUnsyncedTickets: getUnsyncedTickets, markAsSynced: markAsSynced);
    });
  }

  /// Force sync immediately
  Future<SyncResult> forceSync({
    Future<List<WeighingTicket>> Function()? getUnsyncedTickets,
    Future<void> Function(List<int> ids, List<int?> azureIds)? markAsSynced,
  }) async {
    _consecutiveFailures = 0; // Reset failures on manual sync
    _retryTimer?.cancel();
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
      lastSyncTime: _lastSuccessfulSync ?? DateTime.now(),
    );
  }

  /// Download data from Azure Cloud
  Future<Map<String, dynamic>> downloadFromCloud() async {
    debugPrint('SyncService: Starting download from cloud...');
    
    try {
      // Check network
      final isOnline = await _apiService.isNetworkAvailable();
      if (!isOnline) {
        return {'success': false, 'error': 'Không có kết nối mạng'};
      }
      
      // Call API to get all tickets from Azure
      final response = await _apiService.getWeighingTickets();
      
      if (response.success) {
        final data = response.data;
        if (data is List) {
          debugPrint('SyncService: Downloaded ${data.length} tickets from cloud');
          // TODO: Save to local database
          // This would require WeighingTicketSqliteRepository access
          return {
            'success': true,
            'count': data.length,
            'data': data,
          };
        }
        return {'success': true, 'count': 0, 'data': []};
      } else {
        return {'success': false, 'error': response.error ?? 'Lỗi không xác định'};
      }
    } catch (e) {
      debugPrint('SyncService: Error downloading from cloud: $e');
      return {'success': false, 'error': e.toString()};
    }
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
