// Mapper privado da camada de dados — não exportar fora de lib/data/repositories/.
// Converte entre FuelEntryRow (Drift) e FuelEntry (domínio).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:drift/drift.dart';

/// Converte uma linha do banco para o modelo de domínio.
///
/// Aplica [toUtc()] em todos os [DateTime] lidos do banco (Drift armazena
/// como unix timestamp e pode retornar hora local dependendo da plataforma).
/// Decimal flui direto do [DecimalConverter] — sem tocar em double.
FuelEntry fuelEntryToDomain(FuelEntryRow row) {
  return FuelEntry(
    id: row.id,
    vehicleId: row.vehicleId,
    date: row.date.toUtc(),
    odometer: row.odometer,
    // Decimal vem do DecimalConverter (TEXT → Decimal.parse); apenas repassa.
    liters: row.liters,
    pricePerLiter: row.pricePerLiter,
    totalCost: row.totalCost,
    fullTank: row.fullTank,
    fuelType: row.fuelType,
    source: row.source,
    receiptImageUrl: row.receiptImageUrl,
    stationName: row.stationName,
    stationBrand: row.stationBrand,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    syncStatus: row.syncStatus,
  );
}

/// Converte o modelo de domínio para o companion do Drift.
///
/// Todos os campos são embrulhados em [Value]. Decimal passa diretamente para
/// o [DecimalConverter] — sem conversão para double.
FuelEntriesCompanion fuelEntryToCompanion(FuelEntry e) {
  return FuelEntriesCompanion(
    id: Value(e.id),
    vehicleId: Value(e.vehicleId),
    date: Value(e.date),
    odometer: Value(e.odometer),
    liters: Value(e.liters),
    pricePerLiter: Value(e.pricePerLiter),
    totalCost: Value(e.totalCost),
    fullTank: Value(e.fullTank),
    fuelType: Value(e.fuelType),
    source: Value(e.source),
    receiptImageUrl: Value(e.receiptImageUrl),
    stationName: Value(e.stationName),
    stationBrand: Value(e.stationBrand),
    createdAt: Value(e.createdAt),
    updatedAt: Value(e.updatedAt),
    deletedAt: Value(e.deletedAt),
    syncStatus: Value(e.syncStatus),
  );
}
