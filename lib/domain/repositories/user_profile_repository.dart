import 'package:autolog/domain/models/user_profile.dart';

/// Interface de repositório de perfil de usuário — fala só na linguagem de domínio.
/// Implementação Drift: [DriftUserProfileRepository] em lib/data/repositories/.
abstract class UserProfileRepository {
  /// Busca o perfil do [userId]. Retorna null se não existir.
  Future<UserProfile?> getById(String userId);

  /// Busca ou cria o perfil do [userId].
  /// Se não existir, insere registro vazio (syncStatus=pending) e retorna.
  Future<UserProfile> getOrCreate(String userId);

  /// Atualiza o perfil. Bumpa updated_at (UTC now), marca pending.
  Future<void> update(UserProfile profile);

  /// Stream reativo do perfil do [userId]. Emite a cada mudança.
  Stream<UserProfile?> watch(String userId);
}
