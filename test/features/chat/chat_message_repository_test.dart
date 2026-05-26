import 'package:autolog/data/local/database.dart';
import 'package:autolog/features/chat/chat_message.dart';
import 'package:autolog/features/chat/chat_message_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.T — DriftChatMessageRepository.
/// Spec: docs/specs/sprint-6.T-chat-history.md

ChatMessage _msg({
  String id = 'm1',
  String vehicleId = 'v1',
  ChatRole role = ChatRole.user,
  String content = 'oi',
  DateTime? createdAt,
}) => ChatMessage(
  id: id,
  vehicleId: vehicleId,
  role: role,
  content: content,
  createdAt: createdAt ?? DateTime.utc(2026, 5, 26, 10),
);

void main() {
  late AppDatabase db;
  late DriftChatMessageRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftChatMessageRepository(db);
  });
  tearDown(() => db.close());

  test('append insere mensagem', () async {
    await repo.append(_msg());
    final list = await repo.listByVehicle('v1');
    expect(list.length, 1);
    expect(list.first.id, 'm1');
    expect(list.first.role, ChatRole.user);
  });

  test('listByVehicle ordena por createdAt ASC', () async {
    await repo.append(_msg(id: 'm2', createdAt: DateTime.utc(2026, 5, 26, 12)));
    await repo.append(_msg(id: 'm1', createdAt: DateTime.utc(2026, 5, 26, 10)));
    await repo.append(_msg(id: 'm3', createdAt: DateTime.utc(2026, 5, 26, 14)));

    final list = await repo.listByVehicle('v1');
    expect(list.map((m) => m.id).toList(), ['m1', 'm2', 'm3']);
  });

  test('watchByVehicle emite ao append', () async {
    final stream = repo.watchByVehicle('v1');
    final expectation = expectLater(
      stream,
      emitsInOrder([
        [],
        [isA<ChatMessage>().having((m) => m.id, 'id', 'm1')],
      ]),
    );
    // Pequena pausa para o stream emitir o estado inicial vazio
    await Future<void>.delayed(Duration.zero);
    await repo.append(_msg());
    await expectation;
  });

  test('clearVehicle apaga só do veículo informado', () async {
    await repo.append(_msg(vehicleId: 'v1'));
    await repo.append(_msg(id: 'm2', vehicleId: 'v2'));

    await repo.clearVehicle('v1');

    final v1 = await repo.listByVehicle('v1');
    final v2 = await repo.listByVehicle('v2');
    expect(v1, isEmpty);
    expect(v2.length, 1);
    expect(v2.first.vehicleId, 'v2');
  });
}
