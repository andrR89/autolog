// Mapper privado da camada de dados — não exportar fora de lib/data/repositories/.
// Converte entre FineRow (Drift) e Fine (domínio).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:drift/drift.dart';

/// Converte uma linha do banco para o modelo de domínio.
Fine fineToDomain(FineRow row) {
  return Fine(
    id: row.id,
    vehicleId: row.vehicleId,
    autoNumber: row.autoNumber,
    issuedAt: row.issuedAt.toUtc(),
    description: row.description,
    amount: row.amount,
    dueDate: row.dueDate?.toUtc(),
    paid: row.paid,
    points: row.points,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    syncStatus: row.syncStatus,
  );
}

/// Converte o modelo de domínio para o companion do Drift.
FinesCompanion fineToCompanion(Fine f) {
  return FinesCompanion(
    id: Value(f.id),
    vehicleId: Value(f.vehicleId),
    autoNumber: Value(f.autoNumber),
    issuedAt: Value(f.issuedAt),
    description: Value(f.description),
    amount: Value(f.amount),
    dueDate: Value(f.dueDate),
    paid: Value(f.paid),
    points: Value(f.points),
    createdAt: Value(f.createdAt),
    updatedAt: Value(f.updatedAt),
    deletedAt: Value(f.deletedAt),
    syncStatus: Value(f.syncStatus),
  );
}
