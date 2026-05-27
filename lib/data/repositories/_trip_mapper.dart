// Mapper privado da camada de dados — não exportar fora de lib/data/repositories/.
// Converte entre TripRow (Drift) e Trip (domínio).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/trip.dart';
import 'package:drift/drift.dart';

/// Converte uma linha do banco para o modelo de domínio.
///
/// Aplica [toUtc()] em todos os [DateTime] lidos do banco.
Trip tripToDomain(TripRow row) {
  return Trip(
    id: row.id,
    vehicleId: row.vehicleId,
    name: row.name,
    startDate: row.startDate.toUtc(),
    endDate: row.endDate.toUtc(),
    notes: row.notes,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
  );
}

/// Converte o modelo de domínio para o companion do Drift.
TripsCompanion tripToCompanion(Trip t) {
  return TripsCompanion(
    id: Value(t.id),
    vehicleId: Value(t.vehicleId),
    name: Value(t.name),
    startDate: Value(t.startDate),
    endDate: Value(t.endDate),
    notes: Value(t.notes),
    createdAt: Value(t.createdAt),
    updatedAt: Value(t.updatedAt),
    deletedAt: Value(t.deletedAt),
  );
}
