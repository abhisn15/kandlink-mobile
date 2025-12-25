import 'package:flutter/foundation.dart';
import '../services/offline_service.dart';
import '../services/sync_service.dart';
import '../services/local_storage_service.dart';

class OfflineProvider with ChangeNotifier {
  final OfflineService _offlineService = OfflineService();
  final SyncService _syncService = SyncService();
  final LocalStorageService _localStorage = LocalStorageService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isOnline => _offlineService.isOnline;
  Stream<bool> get connectionStream => _offlineService.connectionStream;
  int get offlineQueueLength => _offlineService.queueLength;
  bool get isSyncing => _syncService.isSyncing;

  // Initialize offline support
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _offlineService.initialize();
      await _syncService.initialize();
      await _localStorage.initialize();

      _isInitialized = true;
      notifyListeners();

      debugPrint('Offline provider initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize offline provider: $e');
    }
  }

  // Force sync all data
  Future<void> forceSync() async {
    try {
      await _syncService.forceFullSync();
      notifyListeners();
    } catch (e) {
      debugPrint('Force sync failed: $e');
      rethrow;
    }
  }

  // Manual connectivity check
  Future<void> checkConnectivity() async {
    await _offlineService.checkConnectivityNow();
    notifyListeners();
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _syncService.getCacheStats();
  }

  // Clear all cache
  Future<void> clearCache() async {
    await _syncService.clearCache();
    notifyListeners();
  }

  // Get cached data (for when offline)
  List getCachedConversations() {
    return _syncService.getCachedConversations();
  }

  List getCachedMessages(String chatId) {
    return _syncService.getCachedMessages(chatId);
  }

  getCachedCurrentAssignment() {
    return _syncService.getCachedCurrentAssignment();
  }

  // Dispose
  void dispose() {
    _offlineService.dispose();
    _syncService.dispose();
  }
}
