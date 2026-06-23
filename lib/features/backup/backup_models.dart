// Modelo de bundle de backup — schema versionado pra evolução futura.
//
// Versão atual: 1.
// Conteúdo: snapshot completo dos dados do user logado em um device. Inclui
// vehicles (não-deletados), fuel_entries, expenses, reminders, fines,
// insurances, user_profile, fipe_history.
//
// O QUE NÃO ENTRA:
//   - usage_quota (servidor controla)
//   - vehicle_members (apenas o owner faz backup)
//   - vehicle_member_invitations (estado transitório)
//   - trips (debt do MVP — adicionar quando estabilizar)
//   - fipe_history (snapshot value object sem id próprio — reconstruível
//     consultando FIPE de novo)
//   - imagens de scan (Phase 2 — bundle vira ZIP)
//
// Compatibilidade: leitor checa `version` e rejeita schemas != 1 com
// mensagem amigável (sugerir update do app).

import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/models/vehicle.dart';

/// Versão atual do schema. Bump quando o formato mudar de forma
/// incompatível.
const int kBackupSchemaVersion = 1;

class BackupBundle {
  BackupBundle({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required this.userId,
    required this.vehicles,
    required this.fuelEntries,
    required this.expenses,
    required this.reminders,
    required this.fines,
    required this.insurances,
    required this.userProfile,
  });

  /// Constrói o bundle a partir do JSON. Lança [FormatException] se o
  /// schema for incompatível ou se algum campo essencial faltar.
  factory BackupBundle.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int?;
    if (version == null) {
      throw const FormatException('Backup inválido: sem campo "version".');
    }
    if (version != kBackupSchemaVersion) {
      throw FormatException(
        'Versão $version do backup não suportada. Atualize o app.',
      );
    }
    return BackupBundle(
      version: version,
      exportedAt: DateTime.parse(json['exported_at'] as String),
      appVersion: json['app_version'] as String? ?? 'unknown',
      userId: json['user_id'] as String,
      vehicles: _decodeList(json['vehicles'], Vehicle.fromJson),
      fuelEntries: _decodeList(json['fuel_entries'], FuelEntry.fromJson),
      expenses: _decodeList(json['expenses'], Expense.fromJson),
      reminders: _decodeList(json['reminders'], Reminder.fromJson),
      fines: _decodeList(json['fines'], Fine.fromJson),
      insurances: _decodeList(json['insurances'], Insurance.fromJson),
      userProfile: json['user_profile'] == null
          ? null
          : UserProfile.fromJson(
              Map<String, dynamic>.from(json['user_profile'] as Map),
            ),
    );
  }

  final int version;
  final DateTime exportedAt;
  final String appVersion;
  final String userId;

  final List<Vehicle> vehicles;
  final List<FuelEntry> fuelEntries;
  final List<Expense> expenses;
  final List<Reminder> reminders;
  final List<Fine> fines;
  final List<Insurance> insurances;
  final UserProfile? userProfile;

  /// Serializa o bundle pra JSON pronto pra `jsonEncode`.
  Map<String, dynamic> toJson() => {
        'version': version,
        'exported_at': exportedAt.toUtc().toIso8601String(),
        'app_version': appVersion,
        'user_id': userId,
        'vehicles': vehicles.map((e) => e.toJson()).toList(),
        'fuel_entries': fuelEntries.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toJson()).toList(),
        'fines': fines.map((e) => e.toJson()).toList(),
        'insurances': insurances.map((e) => e.toJson()).toList(),
        'user_profile': userProfile?.toJson(),
      };

}

List<T> _decodeList<T>(
  Object? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw == null) return <T>[];
  return (raw as List)
      .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Estatísticas do que um restore vai fazer — apresentadas em diálogo de
/// confirmação antes de aplicar.
class RestoreStats {
  const RestoreStats({
    required this.totalIncoming,
    required this.toInsert,
    required this.toUpdate,
    required this.toSkip,
  });

  final int totalIncoming;
  final int toInsert;
  final int toUpdate;
  final int toSkip;

  int get totalAffected => toInsert + toUpdate;
}
