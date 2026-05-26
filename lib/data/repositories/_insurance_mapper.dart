// Mapper privado da camada de dados — não exportar fora de lib/data/repositories/.
// Converte entre InsuranceRow (Drift) e Insurance (domínio).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:drift/drift.dart';

/// Converte uma linha do banco para o modelo de domínio.
Insurance insuranceToDomain(InsuranceRow row) {
  return Insurance(
    id: row.id,
    vehicleId: row.vehicleId,
    insurer: row.insurer,
    policyNumber: row.policyNumber,
    startsAt: row.startsAt.toUtc(),
    endsAt: row.endsAt.toUtc(),
    premiumPaid: row.premiumPaid,
    notes: row.notes,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    syncStatus: row.syncStatus,
  );
}

/// Converte o modelo de domínio para o companion do Drift.
InsurancesCompanion insuranceToCompanion(Insurance i) {
  return InsurancesCompanion(
    id: Value(i.id),
    vehicleId: Value(i.vehicleId),
    insurer: Value(i.insurer),
    policyNumber: Value(i.policyNumber),
    startsAt: Value(i.startsAt),
    endsAt: Value(i.endsAt),
    premiumPaid: Value(i.premiumPaid),
    notes: Value(i.notes),
    createdAt: Value(i.createdAt),
    updatedAt: Value(i.updatedAt),
    deletedAt: Value(i.deletedAt),
    syncStatus: Value(i.syncStatus),
  );
}
