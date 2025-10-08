import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static void connect(String token) {
    if (_socket != null && _socket!.connected) {
      log("⚠️ Socket already connected");
      return;
    }

    _socket = IO.io(
      'http://10.10.12.54:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setQuery({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) => log("✅ Socket connected"));
    _socket!.onReconnect((_) => log("🔄 Socket reconnected"));
    _socket!.onConnectError((err) => log("🚨 Connect error: $err"));
    _socket!.onError((err) => log("🚨 Error: $err"));
    _socket!.onDisconnect((_) => log("❌ Socket disconnected"));
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    log("👋 Socket disconnected and disposed");
  }

  static bool get isConnected => _socket?.connected ?? false;

  /// Listen to messages for a specific chatId (dynamic)
  static void onChatMessage(String chatId, void Function(dynamic data) handler) {
    if (!isConnected) {
      log("⚠️ Cannot listen to chat, socket not connected");
      return;
    }

    final eventName = "receive-message:$chatId";
    _socket?.off(eventName); // avoid duplicates
    _socket?.on(eventName, (data) {
      log("📩 Message received on $eventName => $data");
      handler(data);
    });
    log("🟢 Subscribed to $eventName");
  }

  /// Optionally: global fallback for systems that emit plain "receive-message"
  static void onGlobalMessage(void Function(dynamic data) handler) {
    _socket?.off("receive-message");
    _socket?.on("receive-message", (data) {
      log("📩 Global message => $data");
      handler(data);
    });
  }

  /// Listen for typing indicator per chat
  static void onTyping(String chatId, void Function(dynamic data) handler) {
    final eventName = "typing:$chatId";
    _socket?.off(eventName);
    _socket?.on(eventName, (data) {
      log("✍️ Typing event on $eventName => $data");
      handler(data);
    });
    log("🟡 Subscribed to typing:$chatId");
  }

  /// Unsubscribe from a specific chat’s events
  static void clearChatListeners(String chatId) {
    _socket?.off("receive-message:$chatId");
    _socket?.off("typing:$chatId");
    log("🛑 Cleared listeners for chat: $chatId");
  }

  /// Remove all listeners (global cleanup)
  static void clearAllListeners() {
    _socket?.clearListeners();
    log("🧹 Cleared all socket listeners");
  }

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
    log("➡️ Sent text: $message to chat: $chatId");
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
    log("➡️ Sent image: $mediaUrl to chat: $chatId");
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
    log("➡️ Sent video: $mediaUrl to chat: $chatId");
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
    log("✍️ Typing [$isTyping] in chat: $chatId");
  }
}
