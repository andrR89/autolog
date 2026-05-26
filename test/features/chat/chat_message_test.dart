import 'package:autolog/features/chat/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.T — modelo ChatMessage.
/// Spec: docs/specs/sprint-6.T-chat-history.md
void main() {
  group('ChatMessage.fromJson', () {
    test('completo user', () {
      final m = ChatMessage.fromJson({
        'id': 'm1',
        'vehicle_id': 'v1',
        'role': 'user',
        'content': 'Quanto gastei esse mês?',
        'created_at': '2026-05-26T15:00:00.000Z',
      });
      expect(m.id, 'm1');
      expect(m.role, ChatRole.user);
      expect(m.content, 'Quanto gastei esse mês?');
    });

    test('completo assistant', () {
      final m = ChatMessage.fromJson({
        'id': 'm2',
        'vehicle_id': 'v1',
        'role': 'assistant',
        'content': r'Você gastou R$ 1.250.',
        'created_at': '2026-05-26T15:01:00.000Z',
      });
      expect(m.role, ChatRole.assistant);
    });

    test('roundtrip toJson/fromJson', () {
      final original = ChatMessage(
        id: 'm1',
        vehicleId: 'v1',
        role: ChatRole.user,
        content: 'oi',
        createdAt: DateTime.utc(2026, 5, 26),
      );
      final back = ChatMessage.fromJson(original.toJson());
      expect(back, original);
    });
  });
}
