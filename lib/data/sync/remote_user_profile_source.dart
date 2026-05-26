import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Abstrai o acesso remoto a user_profile — testável via fake.
abstract class RemoteUserProfileSource {
  /// Envia o [profile] ao remoto via upsert (por userId).
  Future<void> upsert(UserProfile profile);

  /// Busca do remoto o profile do [userId] com `updated_at > since`.
  /// [since] == null → traz tudo.
  /// RLS garante que o user só vê o próprio perfil.
  Future<List<UserProfile>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

class SupabaseRemoteUserProfileSource implements RemoteUserProfileSource {
  const SupabaseRemoteUserProfileSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(UserProfile profile) async {
    await _client.from('user_profile').upsert(profile.toJson());
  }

  @override
  Future<List<UserProfile>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    // RLS filtra por user_id no servidor.
    final query = _client.from('user_profile').select();

    if (since != null) {
      final sinceIso = since.toUtc().toIso8601String();
      final rows = await query
          .gt('updated_at', sinceIso)
          .order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final rows = await query.order('updated_at', ascending: true);
      return (rows as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteUserProfileSourceProvider = Provider<RemoteUserProfileSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteUserProfileSource(client);
});
