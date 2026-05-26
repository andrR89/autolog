import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Abstrai o acesso remoto a reminders — testável via fake, implementável
/// via Supabase (ou qualquer outro backend).
abstract class RemoteReminderSource {
  /// Envia o [reminder] ao remoto via upsert (por id).
  /// Preserva todos os campos, incluindo [deletedAt] e [updatedAt].
  Future<void> upsert(Reminder reminder);

  /// Busca do remoto os reminders do [userId] com `updated_at > since`.
  /// [since] == null → traz tudo. Ordenado por updated_at asc.
  /// Filtro de user é feito via RLS no servidor (reminders não tem user_id).
  Future<List<Reminder>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

/// Implementação real que fala com o Supabase.
/// Revisada por Haiku; não é unit-testada (requer rede).
class SupabaseRemoteReminderSource implements RemoteReminderSource {
  const SupabaseRemoteReminderSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(Reminder reminder) async {
    await _client.from('reminders').upsert(reminder.toJson());
  }

  @override
  Future<List<Reminder>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    // Sem eq('user_id', ...) — reminders não tem user_id; RLS faz o filtro.
    final query = _client.from('reminders').select();

    if (since != null) {
      final sinceIso = since.toUtc().toIso8601String();
      final rows = await query
          .gt('updated_at', sinceIso)
          .order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final rows = await query.order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteReminderSourceProvider = Provider<RemoteReminderSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteReminderSource(client);
});
