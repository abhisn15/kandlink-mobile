import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool _isOnline = false; // Start as offline, will be checked during init
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  // Queue for offline requests
  final List<Map<String, dynamic>> _offlineQueue = [];
  final String _queueKey = 'offline_queue';

  // Internet connectivity check
  Timer? _connectivityTimer;
  static const String _testUrl = 'api-kandlink.tpmgroup.id';

  // Getters
  bool get isOnline => _isOnline;
  Stream<bool> get connectionStream => _connectionController.stream;
  int get queueLength => _offlineQueue.length;

  // Initialize offline service
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );

    // Load offline queue from storage
    await _loadOfflineQueue();

    // Start periodic connectivity check
    _startPeriodicConnectivityCheck();

    debugPrint('Offline service initialized. Online: $_isOnline');
  }

  // Update connection status
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final wasOnline = _isOnline;

    // First check basic connectivity
    final hasBasicConnectivity = result != ConnectivityResult.none;

    if (hasBasicConnectivity) {
      // If connected, do actual internet connectivity check
      _isOnline = await _checkInternetConnectivity();
    } else {
      _isOnline = false;
    }

    if (wasOnline != _isOnline) {
      debugPrint('Connection status changed: $_isOnline (connectivity: $result)');
      _connectionController.add(_isOnline);

      // If back online, process offline queue
      if (_isOnline && _offlineQueue.isNotEmpty) {
        _processOfflineQueue();
      }
    }
  }

  // Check actual internet connectivity by pinging server
  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup(_testUrl);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Check if connectivity result means basic connection exists
  bool _hasBasicConnectivity(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  // Add request to offline queue
  Future<void> queueOfflineRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    required String requestId,
  }) async {
    final request = {
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
      'requestId': requestId,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    _offlineQueue.add(request);
    await _saveOfflineQueue();

    debugPrint('Queued offline request: $method $url');
  }

  // Process offline queue when back online
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    debugPrint('Processing ${_offlineQueue.length} offline requests');

    // Process requests in order
    final requestsToProcess = List.from(_offlineQueue);

    for (final request in requestsToProcess) {
      try {
        // Here you would make the actual HTTP request
        // For now, we'll just simulate success
        debugPrint('Processing queued request: ${request['method']} ${request['url']}');

        // Remove from queue after successful processing
        _offlineQueue.remove(request);

      } catch (e) {
        debugPrint('Failed to process queued request: $e');
        // Increment retry count
        request['retryCount'] = (request['retryCount'] ?? 0) + 1;

        // Remove if too many retries
        if (request['retryCount'] >= 3) {
          _offlineQueue.remove(request);
        }
      }
    }

    await _saveOfflineQueue();
  }

  // Save offline queue to local storage
  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = json.encode(_offlineQueue);
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      debugPrint('Failed to save offline queue: $e');
    }
  }

  // Load offline queue from local storage
  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson != null) {
        final queue = json.decode(queueJson) as List;
        _offlineQueue.clear();
        _offlineQueue.addAll(queue.map((item) => item as Map<String, dynamic>));
        debugPrint('Loaded ${_offlineQueue.length} offline requests');
      }
    } catch (e) {
      debugPrint('Failed to load offline queue: $e');
    }
  }

  // Clear offline queue
  Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    await _saveOfflineQueue();
  }

  // Get offline queue (for debugging)
  List<Map<String, dynamic>> getOfflineQueue() {
    return List.from(_offlineQueue);
  }

  // Start periodic connectivity check
  void _startPeriodicConnectivityCheck() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
    });
  }

  // Manual connectivity check
  Future<void> checkConnectivityNow() async {
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);
  }

  // Dispose
  void dispose() {
    _connectivitySubscription.cancel();
    _connectivityTimer?.cancel();
    _connectionController.close();
  }
}
