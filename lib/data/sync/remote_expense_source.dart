import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Abstrai o acesso remoto a expenses — testável via fake, implementável
/// via Supabase (ou qualquer outro backend).
abstract class RemoteExpenseSource {
  /// Envia o [expense] ao remoto via upsert (por id).
  /// Preserva todos os campos, incluindo [deletedAt] e [updatedAt].
  Future<void> upsert(Expense expense);

  /// Busca do remoto os expenses do [userId] com `updated_at > since`.
  /// [since] == null → traz tudo. Ordenado por updated_at asc.
  /// Filtro de user é feito via RLS no servidor (expenses não tem user_id).
  Future<List<Expense>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

/// Implementação real que fala com o Supabase.
/// Revisada por Haiku; não é unit-testada (requer rede).
class SupabaseRemoteExpenseSource implements RemoteExpenseSource {
  const SupabaseRemoteExpenseSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(Expense expense) async {
    await _client.from('expenses').upsert(expense.toJson());
  }

  @override
  Future<List<Expense>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    // Sem eq('user_id', ...) — expenses não tem user_id; RLS faz o filtro.
    final query = _client.from('expenses').select();

    if (since != null) {
      final sinceIso = since.toUtc().toIso8601String();
      final rows = await query
          .gt('updated_at', sinceIso)
          .order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final rows = await query.order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteExpenseSourceProvider = Provider<RemoteExpenseSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteExpenseSource(client);
});
