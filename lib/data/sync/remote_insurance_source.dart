import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Abstrai o acesso remoto a insurances — testável via fake.
abstract class RemoteInsuranceSource {
  /// Envia a [insurance] ao remoto via upsert (por id).
  Future<void> upsert(Insurance insurance);

  /// Busca do remoto as insurances do [userId] com `updated_at > since`.
  /// [since] == null → traz tudo.
  /// RLS faz o filtro de user via vehicle.
  Future<List<Insurance>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

class SupabaseRemoteInsuranceSource implements RemoteInsuranceSource {
  const SupabaseRemoteInsuranceSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(Insurance insurance) async {
    await _client.from('insurances').upsert(insurance.toJson());
  }

  @override
  Future<List<Insurance>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    // RLS faz o filtro de user via FK vehicle_id no servidor.
    final query = _client.from('insurances').select();

    if (since != null) {
      final sinceIso = since.toUtc().toIso8601String();
      final rows = await query
          .gt('updated_at', sinceIso)
          .order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Insurance.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final rows = await query.order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Insurance.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteInsuranceSourceProvider = Provider<RemoteInsuranceSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteInsuranceSource(client);
});
