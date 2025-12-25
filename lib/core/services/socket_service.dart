import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_endpoints.dart';
import 'logger_service.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  final LoggerService _logger = LoggerService();

  // Event listeners
  Function(String)? _onMessageReceived;
  Function(String)? _onGroupMessageReceived;
  Function(Map<String, dynamic>)? _onTypingStart;
  Function(Map<String, dynamic>)? _onTypingStop;
  Function(String)? _onUserOnline;
  Function(String)? _onUserOffline;
  Function()? _onConnected;
  Function()? _onDisconnected;
  Function(String)? _onError;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;
  String? get currentUserId => _currentUserId;

  // Minimal events based on socket-test.html analysis:
  // - connect (auth via token)
  // - join (personal chat room)
  // - send_message (payload: receiverId, message, type)
  // - receive_message (payload: message data)
  // - disconnect

  Future<void> connect(String userId, String token) async {
    if (_socket != null) {
      disconnect();
    }

    _currentUserId = userId;
    _logger.i('Connecting to socket with userId: $userId');

    _socket = IO.io(
      ApiEndpoints.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token}) // Auth token sent via auth header
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(5)
          .setTimeout(20000)
          .build(),
    );

    _setupSocketListeners();
    _socket!.connect();
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      _logger.i('Socket connected successfully');

      // Auto-join personal room after connection
      if (_currentUserId != null) {
        joinPersonalRoom(_currentUserId!);
      }

      if (_onConnected != null) {
        _onConnected!();
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _logger.w('Socket disconnected');
      if (_onDisconnected != null) {
        _onDisconnected!();
      }
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      _logger.e('Socket connection error: $error');
      if (_onError != null) {
        _onError!('Connection failed: $error');
      }
    });

    _socket!.onError((error) {
      _logger.e('Socket error: $error');
      if (_onError != null) {
        _onError!('Socket error: $error');
      }
    });

    // Message events
    _socket!.on('receive_message', (data) {
      _logger.d('Received personal message: $data');
      if (_onMessageReceived != null) {
        _onMessageReceived!(data.toString());
      }
    });

    _socket!.on('receive_group_message', (data) {
      _logger.d('Received group message: $data');
      if (_onGroupMessageReceived != null) {
        _onGroupMessageReceived!(data.toString());
      }
    });

    // Typing events
    _socket!.on('typing_start', (data) {
      if (_onTypingStart != null) {
        _onTypingStart!(data as Map<String, dynamic>);
      }
    });

    _socket!.on('typing_stop', (data) {
      if (_onTypingStop != null) {
        _onTypingStop!(data as Map<String, dynamic>);
      }
    });

    // User presence events
    _socket!.on('user_online', (data) {
      if (_onUserOnline != null && data['userId'] != null) {
        _onUserOnline!(data['userId']);
      }
    });

    _socket!.on('user_offline', (data) {
      if (_onUserOffline != null && data['userId'] != null) {
        _onUserOffline!(data['userId']);
      }
    });
  }

  // Join personal chat room (minimal implementation)
  void joinPersonalRoom(String userId) {
    if (_socket != null && _isConnected) {
      _logger.d('Joining personal room for user: $userId');
      _socket!.emit('join', {'userId': userId});
    }
  }

  // Send personal message (minimal implementation)
  void sendMessage(String receiverId, String message, {String type = 'text'}) {
    if (_socket != null && _isConnected) {
      final payload = {
        'receiverId': receiverId,
        'message': message,
        'type': type,
      };
      _logger.d('Sending personal message: $payload');
      _socket!.emit('send_message', payload);
    } else {
      _logger.w('Cannot send message: socket not connected');
    }
  }

  // Send group message
  void sendGroupMessage(String groupId, String message, {String type = 'text'}) {
    if (_socket != null && _isConnected) {
      final payload = {
        'groupId': groupId,
        'message': message,
        'type': type,
      };
      _logger.d('Sending group message: $payload');
      _socket!.emit('send_group_message', payload);
    } else {
      _logger.w('Cannot send group message: socket not connected');
    }
  }

  // Mark messages as read
  void markMessagesAsRead(List<String> messageIds) {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark_read', {'messageIds': messageIds});
    }
  }

  // Typing indicators
  void startTyping(String chatId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_start', {'chatId': chatId});
    }
  }

  void stopTyping(String chatId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_stop', {'chatId': chatId});
    }
  }

  // Join room
  void joinRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', {'roomId': roomId});
    }
  }

  // Leave room
  void leaveRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_room', {'roomId': roomId});
    }
  }

  // Set event listeners
  void setMessageListener(Function(String) listener) {
    _onMessageReceived = listener;
  }

  void setGroupMessageListener(Function(String) listener) {
    _onGroupMessageReceived = listener;
  }

  void setTypingStartListener(Function(Map<String, dynamic>) listener) {
    _onTypingStart = listener;
  }

  void setTypingStopListener(Function(Map<String, dynamic>) listener) {
    _onTypingStop = listener;
  }

  void setUserOnlineListener(Function(String) listener) {
    _onUserOnline = listener;
  }

  void setUserOfflineListener(Function(String) listener) {
    _onUserOffline = listener;
  }

  void setConnectedListener(Function() listener) {
    _onConnected = listener;
  }

  void setDisconnectedListener(Function() listener) {
    _onDisconnected = listener;
  }

  void setErrorListener(Function(String) listener) {
    _onError = listener;
  }

  // Disconnect
  void disconnect() {
    _logger.i('Disconnecting socket');
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _currentUserId = null;
    _clearListeners();
  }

  void _clearListeners() {
    _onMessageReceived = null;
    _onGroupMessageReceived = null;
    _onTypingStart = null;
    _onTypingStop = null;
    _onUserOnline = null;
    _onUserOffline = null;
    _onConnected = null;
    _onDisconnected = null;
    _onError = null;
  }

  // Get connection status
  String getConnectionStatus() {
    if (_socket == null) return 'disconnected';
    if (_isConnected) return 'connected';
    return 'connecting';
  }
}
