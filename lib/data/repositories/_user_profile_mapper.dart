// Mapper privado da camada de dados — não exportar fora de lib/data/repositories/.
// Converte entre UserProfileRow (Drift) e UserProfile (domínio).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:drift/drift.dart';

/// Converte uma linha do banco para o modelo de domínio.
UserProfile userProfileToDomain(UserProfileRow row) {
  return UserProfile(
    userId: row.userId,
    cnhNumber: row.cnhNumber,
    cnhCategory: row.cnhCategory,
    cnhExpiresAt: row.cnhExpiresAt?.toUtc(),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    syncStatus: row.syncStatus,
  );
}

/// Converte o modelo de domínio para o companion do Drift.
UserProfileCompanion userProfileToCompanion(UserProfile p) {
  return UserProfileCompanion(
    userId: Value(p.userId),
    cnhNumber: Value(p.cnhNumber),
    cnhCategory: Value(p.cnhCategory),
    cnhExpiresAt: Value(p.cnhExpiresAt),
    createdAt: Value(p.createdAt),
    updatedAt: Value(p.updatedAt),
    syncStatus: Value(p.syncStatus),
  );
}
