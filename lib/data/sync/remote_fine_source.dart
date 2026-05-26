import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Abstrai o acesso remoto a fines — testável via fake.
abstract class RemoteFineSource {
  /// Envia a [fine] ao remoto via upsert (por id).
  Future<void> upsert(Fine fine);

  /// Busca do remoto as fines do [userId] com `updated_at > since`.
  /// [since] == null → traz tudo.
  /// RLS faz o filtro de user via vehicle.
  Future<List<Fine>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

class SupabaseRemoteFineSource implements RemoteFineSource {
  const SupabaseRemoteFineSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(Fine fine) async {
    await _client.from('fines').upsert(fine.toJson());
  }

  @override
  Future<List<Fine>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    // RLS faz o filtro de user via FK vehicle_id no servidor.
    final query = _client.from('fines').select();

    if (since != null) {
      final sinceIso = since.toUtc().toIso8601String();
      final rows = await query
          .gt('updated_at', sinceIso)
          .order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Fine.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final rows = await query.order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Fine.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteFineSourceProvider = Provider<RemoteFineSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteFineSource(client);
});
