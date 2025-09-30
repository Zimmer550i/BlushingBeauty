// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/foundation.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
//
// class SocketApi {
//   static WebSocketChannel? _channel;
//   static bool _connected = false;
//   static bool _authorized = false;
//   static int? _roomId;
//   static String? _token;
//   static String authScheme = 'Bearer';
//   static String? _cookie;
//
//   static int _retries = 0;
//   static Timer? _reconnectTimer;
//   static final List<String> _outbox = [];
//
//   static final _messageController = StreamController<String>.broadcast();
//   static Stream<String> get messageStream => _messageController.stream;
//
//   static final _typingController = StreamController<Map<String, dynamic>>.broadcast();
//   static Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
//
//   static void setCookie(String cookie) => _cookie = cookie;
//   static void setToken(String token) => _token = token;
//
//   static void init(int roomId, {String? token}) {
//     _roomId = roomId;
//     if (token != null && token.isNotEmpty) _token = token;
//     _connect();
//   }
//
//   static void _connect() {
//     final roomId = _roomId;
//     if (roomId == null) return;
//
//     // Put token in query
//     final qp = <String, String>{};
//     if ((_token ?? '').isNotEmpty) qp['token'] = _token!;
//
//     final uri = Uri(
//       scheme: 'ws',
//       host: '10.10.12.111',
//       port: 8000,
//       path: '/ws/chat/$roomId/',
//       queryParameters: qp.isEmpty ? null : qp,
//     );
//
//     // Headers + cookie
//     final headers = <String, String>{};
//     if ((_token ?? '').isNotEmpty) headers['Authorization'] = '$authScheme ${_token!}';
//     if ((_cookie ?? '').isNotEmpty) headers['Cookie'] = _cookie!;
//
//     // Subprotocols (some Channels JWT middlewares use this)
//     final protocols = (_token != null && _token!.isNotEmpty) ? ['jwt', _token!] : null;
//
//     debugPrint('🔌 WS connect → $uri');
//     if ((_token ?? '').isEmpty) debugPrint('⚠️ WS: token missing; backend may reject.');
//
//     try {
//       _channel = IOWebSocketChannel.connect(
//         uri,
//         headers: headers,
//         protocols: protocols,
//         pingInterval: const Duration(seconds: 20),
//       );
//       _connected = true;
//       _authorized = (_token?.isNotEmpty ?? false);
//       _retries = 0;
//       _outbox.clear();
//
//       _channel!.stream.listen(
//             (data) => _messageController.add(data is String ? data : data.toString()),
//         onError: (err, _) {
//           debugPrint('❌ WS error: $err');
//           _handleDisconnect(err);
//         },
//         onDone: () {
//           debugPrint('⚠️ WS closed (room $roomId)');
//           _handleDisconnect(null);
//         },
//       );
//
//       // if you DO have a custom auth frame server-side, you can still send it:
//       // _channel!.sink.add(jsonEncode({"type":"auth","token":_token}));
//       // and optionally flip _authorized on 'auth_ok'
//     } catch (e) {
//       debugPrint('❗ WS connect failed: $e');
//       _handleDisconnect(e);
//     }
//   }
//
//   static void _handleDisconnect(Object? error) {
//     _connected = false;
//     _authorized = false;
//     try { _channel?.sink.close(); } catch (_) {}
//     _channel = null;
//
//     _reconnectTimer?.cancel();
//     final secs = min(30, (1 << _retries));
//     _retries = (_retries + 1).clamp(0, 6);
//     debugPrint('⏳ WS reconnect in ${secs}s');
//     _reconnectTimer = Timer(Duration(seconds: secs), _connect);
//   }
//
//   static void emit(Map<String, dynamic> message) {
//     final jsonStr = jsonEncode(message);
//     if (!_connected || _channel == null) {
//       debugPrint('⚠️ emit() while socket not connected → dropped');
//       return;
//     }
//     if (!_authorized) {
//       _outbox.add(jsonStr);
//       debugPrint('🕒 queued (auth pending): $jsonStr');
//       return;
//     }
//     debugPrint('➡️ WS send: $jsonStr');
//     _channel!.sink.add(jsonStr);
//   }
//
//   static void sendTyping({required bool isTyping}) {
//     emit({'type': 'typing', 'is_typing': isTyping, 'ts': DateTime.now().toIso8601String()});
//   }
//
//   static void sendLike({required int messageId}) {
//     emit({'type': 'reaction', 'reaction': 'like', 'message_id': messageId});
//   }
//
//   static void disconnect() {
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;
//     try { _channel?.sink.close(); } catch (_) {}
//     _channel = null;
//     _connected = false;
//     _authorized = false;
//     _outbox.clear();
//   }
// }
