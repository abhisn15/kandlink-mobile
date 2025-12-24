import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_endpoints.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  Function(String)? _onMessageReceived;
  Function(String)? _onGroupMessageReceived;
  Function(Map<String, dynamic>)? _onTypingStart;
  Function(Map<String, dynamic>)? _onTypingStop;
  Function(String)? _onUserOnline;
  Function(String)? _onUserOffline;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  Future<void> connect(String userId, String token) async {
    if (_socket != null) {
      disconnect();
    }

    _socket = IO.io(
      ApiEndpoints.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(5)
          .build(),
    );

    _setupSocketListeners();
    _socket!.connect();
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      // Join user room
      _socket!.emit('join', {'userId': 'current_user_id'});
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
    });

    _socket!.on('receive_message', (data) {
      if (_onMessageReceived != null) {
        _onMessageReceived!(data.toString());
      }
    });

    _socket!.on('receive_group_message', (data) {
      if (_onGroupMessageReceived != null) {
        _onGroupMessageReceived!(data.toString());
      }
    });

    _socket!.on('typing_start', (data) {
      if (_onTypingStart != null) {
        _onTypingStart!(data);
      }
    });

    _socket!.on('typing_stop', (data) {
      if (_onTypingStop != null) {
        _onTypingStop!(data);
      }
    });

    _socket!.on('user_online', (data) {
      if (_onUserOnline != null) {
        _onUserOnline!(data['userId']);
      }
    });

    _socket!.on('user_offline', (data) {
      if (_onUserOffline != null) {
        _onUserOffline!(data['userId']);
      }
    });
  }

  // Send message
  void sendMessage(String receiverId, String message, {String type = 'text'}) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_message', {
        'receiverId': receiverId,
        'message': message,
        'type': type,
      });
    }
  }

  // Send group message
  void sendGroupMessage(String groupId, String message, {String type = 'text'}) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_group_message', {
        'groupId': groupId,
        'message': message,
        'type': type,
      });
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

  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _clearListeners();
  }

  void _clearListeners() {
    _onMessageReceived = null;
    _onGroupMessageReceived = null;
    _onTypingStart = null;
    _onTypingStop = null;
    _onUserOnline = null;
    _onUserOffline = null;
  }

  // Get connection status
  String getConnectionStatus() {
    if (_socket == null) return 'disconnected';
    if (_isConnected) return 'connected';
    return 'connecting';
  }
}
