import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Abstrai o acesso remoto a fuel_entries — testável via fake, implementável
/// via Supabase (ou qualquer outro backend).
abstract class RemoteFuelEntrySource {
  /// Envia o [entry] ao remoto via upsert (por id).
  /// Preserva todos os campos, incluindo [deletedAt] e [updatedAt].
  Future<void> upsert(FuelEntry entry);

  /// Busca do remoto os fuel_entries do [userId] com `updated_at > since`.
  /// [since] == null → traz tudo. Ordenado por updated_at asc.
  /// Filtro de user é feito via RLS no servidor (fuel_entries não tem user_id).
  Future<List<FuelEntry>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

/// Implementação real que fala com o Supabase.
/// Revisada por Haiku; não é unit-testada (requer rede).
class SupabaseRemoteFuelEntrySource implements RemoteFuelEntrySource {
  const SupabaseRemoteFuelEntrySource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(FuelEntry entry) async {
    await _client.from('fuel_entries').upsert(entry.toJson());
  }

  @override
  Future<List<FuelEntry>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    // Sem eq('user_id', ...) — fuel_entries não tem user_id; RLS faz o filtro.
    final query = _client.from('fuel_entries').select();

    if (since != null) {
      final sinceIso = since.toUtc().toIso8601String();
      final rows = await query
          .gt('updated_at', sinceIso)
          .order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => FuelEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final rows = await query.order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => FuelEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteFuelEntrySourceProvider = Provider<RemoteFuelEntrySource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteFuelEntrySource(client);
});
