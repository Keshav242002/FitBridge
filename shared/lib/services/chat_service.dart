import 'dart:async';
import 'api_client.dart';
import '../models/message.dart';
import '../utils/logger.dart';

const kChatId = 'c_aarav_dk';

class ChatService {
  ChatService({required this.api});

  final ApiClient api;

  StreamController<Message>? _ctrl;
  StreamController<bool>? _typingCtrl;
  Timer? _timer;
  String? _chatId;
  String? _peerId;
  DateTime _since = DateTime.now();

  Stream<Message> startPolling(String chatId, {String? peerId}) {
    _chatId = chatId;
    _peerId = peerId;
    _since = DateTime.now().subtract(const Duration(seconds: 2));
    _ctrl?.close();
    _typingCtrl?.close();
    _ctrl = StreamController<Message>.broadcast();
    _typingCtrl = StreamController<bool>.broadcast();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _poll());
    return _ctrl!.stream;
  }

  Stream<bool> get typingStream => _typingCtrl?.stream ?? const Stream.empty();

  Future<void> _poll() async {
    if (_chatId == null || _ctrl == null || _ctrl!.isClosed) return;

    final res = await api.get('/messages', query: {
      'chatId': _chatId!,
      'since': _since.toIso8601String(),
    });
    if (res case ApiSuccess(:final body) when body is List) {
      for (final item in body) {
        if (item is Map<String, dynamic>) {
          try {
            final msg = Message.fromJson(item);
            _since = msg.createdAt.add(const Duration(milliseconds: 1));
            if (!_ctrl!.isClosed) _ctrl!.add(msg);
          } catch (e) {
            Log.chat('poll parse error: $e');
          }
        }
      }
    }

    if (_peerId == null || _typingCtrl == null || _typingCtrl!.isClosed) return;
    final typingRes = await api.get('/messages/typing', query: {'chatId': _chatId!});
    if (typingRes case ApiSuccess(:final body) when body is List) {
      final isTyping = body.any(
        (t) => t is Map && t['userId'] == _peerId,
      );
      if (!_typingCtrl!.isClosed) _typingCtrl!.add(isTyping);
    }
  }

  Future<void> sendTyping(String chatId, String userId) async {
    await api.post('/messages/typing', body: {'chatId': chatId, 'userId': userId});
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _ctrl?.close();
    _ctrl = null;
    _typingCtrl?.close();
    _typingCtrl = null;
    _chatId = null;
    _peerId = null;
  }
}
