import 'package:autolog/data/local/database.dart';
import 'package:autolog/features/chat/chat_message.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repositório de mensagens de chat (local-only).
///
/// `chat_messages` é persitida localmente e nunca sincronizada com Supabase.
abstract class ChatMessageRepository {
  /// Insere ou substitui a mensagem (upsert por id).
  Future<void> append(ChatMessage message);

  /// Lista todas as mensagens de [vehicleId] ordenadas por [createdAt] ASC.
  Future<List<ChatMessage>> listByVehicle(String vehicleId);

  /// Stream das mensagens de [vehicleId], atualizado em tempo real.
  Stream<List<ChatMessage>> watchByVehicle(String vehicleId);

  /// Remove todas as mensagens de [vehicleId] (limpar conversa).
  Future<void> clearVehicle(String vehicleId);
}

/// Implementação Drift do [ChatMessageRepository].
class DriftChatMessageRepository implements ChatMessageRepository {
  DriftChatMessageRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> append(ChatMessage message) async {
    await _db.into(_db.chatMessages).insertOnConflictUpdate(
      ChatMessagesCompanion.insert(
        id: message.id,
        vehicleId: message.vehicleId,
        role: message.role.name,
        content: message.content,
        createdAt: message.createdAt,
      ),
    );
  }

  @override
  Future<List<ChatMessage>> listByVehicle(String vehicleId) async {
    final q = _db.select(_db.chatMessages)
      ..where((t) => t.vehicleId.equals(vehicleId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return (await q.get()).map(_toDomain).toList();
  }

  @override
  Stream<List<ChatMessage>> watchByVehicle(String vehicleId) {
    final q = _db.select(_db.chatMessages)
      ..where((t) => t.vehicleId.equals(vehicleId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> clearVehicle(String vehicleId) async {
    await (_db.delete(_db.chatMessages)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .go();
  }

  ChatMessage _toDomain(ChatMessageRow row) => ChatMessage(
    id: row.id,
    vehicleId: row.vehicleId,
    role: row.role == 'assistant' ? ChatRole.assistant : ChatRole.user,
    content: row.content,
    createdAt: row.createdAt,
  );
}

/// Provider do repositório de mensagens de chat.
final chatMessageRepositoryProvider = Provider<ChatMessageRepository>((ref) {
  return DriftChatMessageRepository(ref.watch(appDatabaseProvider));
});

/// Provider de stream das mensagens de um veículo específico.
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, vehicleId) =>
        ref.watch(chatMessageRepositoryProvider).watchByVehicle(vehicleId));
