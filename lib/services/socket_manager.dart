import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? socket;

  /// Connect to socket with auth token
  static void connect(String token) {
    if (socket != null && socket!.connected) {
      log("⚠️ Socket already connected");
      return;
    }

    socket = IO.io(
      'http://10.10.12.54:3000',
      IO.OptionBuilder()
          .setTransports(['websocket']) // use WebSocket only
          .enableForceNew()
          .disableAutoConnect()
          .setQuery({'token': token}) // pass token in query
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      log("✅ Socket connected");
    });

    socket!.onDisconnect((_) {
      log("❌ Socket disconnected");
    });

    socket!.onConnectError((err) {
      log("🚨 Connect error: $err");
    });

    socket!.onError((err) {
      log("🚨 Error: $err");
    });

    /// Listen for incoming messages
    socket!.on("receive-message", (data) {
      log("📥 Message received: $data");
    });
  }

  /// Disconnect cleanly
  static void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }

  /// Emit a text message
  static void sendText({
    required String chatId,
    required String senderId,
    required String message,
  }) {
    if (socket == null || !socket!.connected) {
      log("⚠️ Cannot send, socket not connected");
      return;
    }

    socket!.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "message": message,
      "contentType": "text",
    });
    log("➡️ Sent text: $message");
  }

  /// Emit an image message
  static void sendImage({
    required String chatId,
    required String senderId,
    required String mediaUrl,
  }) {
    socket?.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "media": mediaUrl,
      "contentType": "image",
    });
    log("➡️ Sent image: $mediaUrl");
  }

  /// Emit a video message
  static void sendVideo({
    required String chatId,
    required String senderId,
    required String mediaUrl,
  }) {
    socket?.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "media": mediaUrl,
      "contentType": "video",
    });
    log("➡️ Sent video: $mediaUrl");
  }

  /// Typing event
  static void sendTyping({
    required String chatId,
    required String senderId,
    required bool isTyping,
  }) {
    socket?.emit("typing", {
      "chat": chatId,
      "sender": senderId,
      "isTyping": isTyping,
    });
    log("✍️ Typing: $isTyping");
  }
}
