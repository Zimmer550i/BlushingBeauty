import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  /// Connect to socket with auth token
  static void connect(String token) {
    if (_socket != null && _socket!.connected) {
      log("⚠️ Socket already connected");
      return;
    }

    _socket = IO.io(
      'http://10.10.12.54:3000', // TODO: make configurable (env/constant)
      IO.OptionBuilder()
          .setTransports(['websocket']) // use WebSocket only
          .enableForceNew()
          .disableAutoConnect()
          .setQuery({'token': token}) // pass token in query
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) => log("✅ Socket connected"));
    _socket!.onDisconnect((_) => log("❌ Socket disconnected"));
    _socket!.onReconnect((_) => log("🔄 Socket reconnected"));
    _socket!.onConnectError((err) => log("🚨 Connect error: $err"));
    _socket!.onError((err) => log("🚨 Error: $err"));
  }

  /// Disconnect cleanly
  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    log("👋 Socket disposed");
  }

  /// =====================
  /// CHAT EVENTS
  /// =====================

  /// Subscribe to new messages
  static void onMessage(void Function(dynamic data) handler) {
    _socket?.off("receive-message"); // prevent duplicate listeners
    _socket?.on("receive-message", handler);
  }

  /// Subscribe to typing events
  static void onTyping(void Function(dynamic data) handler) {
    _socket?.off("typing");
    _socket?.on("typing", handler);
  }

  /// Unsubscribe from all events (when leaving chat)
  static void clearListeners() {
    _socket?.off("receive-message");
    _socket?.off("typing");
  }

  /// =====================
  /// MESSAGE EMITS
  /// =====================

  static void sendText({
    required String chatId,
    required String senderId,
    required String message,
  }) {
    if (!isConnected) {
      log("⚠️ Cannot send text, socket not connected");
      return;
    }
    _socket!.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "message": message,
      "contentType": "text",
    });
    log("➡️ Sent text: $message");
  }

  static void sendImage({
    required String chatId,
    required String senderId,
    required String mediaUrl,
  }) {
    if (!isConnected) return;
    _socket!.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "media": mediaUrl,
      "contentType": "image",
    });
    log("➡️ Sent image: $mediaUrl");
  }

  static void sendVideo({
    required String chatId,
    required String senderId,
    required String mediaUrl,
  }) {
    if (!isConnected) return;
    _socket!.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "media": mediaUrl,
      "contentType": "video",
    });
    log("➡️ Sent video: $mediaUrl");
  }

  static void sendTyping({
    required String chatId,
    required String senderId,
    required bool isTyping,
  }) {
    if (!isConnected) return;
    _socket!.emit("typing", {
      "chat": chatId,
      "sender": senderId,
      "isTyping": isTyping,
    });
    log("✍️ Typing: $isTyping");
  }

  /// =====================
  /// HELPERS
  /// =====================
  static bool get isConnected => _socket?.connected ?? false;
}
