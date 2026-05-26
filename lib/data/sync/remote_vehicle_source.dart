import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Abstrai o acesso remoto a veículos — testável via fake, implementável via
/// Supabase (ou qualquer outro backend).
abstract class RemoteVehicleSource {
  /// Envia o [vehicle] ao remoto via upsert (por id).
  /// Preserva todos os campos, incluindo [deletedAt] e [updatedAt].
  Future<void> upsert(Vehicle vehicle);

  /// Busca do remoto os veículos do [userId] com `updated_at > since`.
  /// [since] == null → traz tudo. Ordenado por updated_at asc.
  Future<List<Vehicle>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

/// Implementação real que fala com o Supabase.
/// Revisada por Haiku; não é unit-testada (requer rede).
class SupabaseRemoteVehicleSource implements RemoteVehicleSource {
  const SupabaseRemoteVehicleSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(Vehicle vehicle) async {
    await _client.from('vehicles').upsert(vehicle.toJson());
  }

  @override
  Future<List<Vehicle>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    final query = _client.from('vehicles').select().eq('user_id', userId);

    if (since != null) {
      // PostgREST gt() filter: updated_at > since (ISO-8601 string).
      final sinceIso = since.toUtc().toIso8601String();
      final rows = await query
          .gt('updated_at', sinceIso)
          .order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final rows = await query.order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteVehicleSourceProvider = Provider<RemoteVehicleSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteVehicleSource(client);
});
