import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  group('Message JSON round-trip', () {
    test('fromJson(toJson()) preserves all fields', () {
      final msg = Message(
        id: 'msg_001',
        chatId: 'c_aarav_dk',
        senderId: 'mb_dk',
        receiverId: 'tr_aarav',
        text: 'Hi Coach 👋',
        createdAt: DateTime.utc(2026, 5, 22, 10, 30, 0),
        status: MessageStatus.sent,
        isSystem: false,
      );

      final restored = Message.fromJson(msg.toJson());

      expect(restored, equals(msg));
      expect(restored.id, msg.id);
      expect(restored.chatId, msg.chatId);
      expect(restored.senderId, msg.senderId);
      expect(restored.receiverId, msg.receiverId);
      expect(restored.text, msg.text);
      expect(restored.createdAt, msg.createdAt);
      expect(restored.status, msg.status);
      expect(restored.isSystem, msg.isSystem);
    });

    test('system message round-trip', () {
      final msg = Message(
        id: 'sys_001',
        chatId: 'c_aarav_dk',
        senderId: 'system',
        receiverId: 'mb_dk',
        text: 'Call approved for May 23 at 10:00.',
        createdAt: DateTime.utc(2026, 5, 22, 11, 0),
        status: MessageStatus.sent,
        isSystem: true,
      );

      final restored = Message.fromJson(msg.toJson());
      expect(restored, equals(msg));
      expect(restored.isSystem, isTrue);
    });

    test('status serialization covers all variants', () {
      for (final status in MessageStatus.values) {
        final msg = Message(
          id: 'id',
          chatId: 'c',
          senderId: 's',
          receiverId: 'r',
          text: 't',
          createdAt: DateTime.utc(2026),
          status: status,
        );
        expect(Message.fromJson(msg.toJson()).status, status);
      }
    });

    test('copyWith only changes specified fields', () {
      final original = Message(
        id: 'x',
        chatId: 'c_aarav_dk',
        senderId: 'mb_dk',
        receiverId: 'tr_aarav',
        text: 'original',
        createdAt: DateTime.utc(2026),
        status: MessageStatus.sending,
      );

      final updated = original.copyWith(status: MessageStatus.read, text: 'updated');
      expect(updated.id, original.id);
      expect(updated.status, MessageStatus.read);
      expect(updated.text, 'updated');
      expect(updated.senderId, original.senderId);
    });
  });
}
