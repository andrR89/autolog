// Enumerações de domínio compartilhadas entre Drift e modelos freezed.
// Cada enum carrega o valor canônico de string ("wire") que será gravado no banco
// e espelhado no Supabase, garantindo consistência entre client e backend.

enum FuelType {
  gasolina,
  etanol,
  diesel,
  flex,
  gnv;

  /// Valor canônico armazenado no banco / enviado ao backend.
  /// Para FuelType o wire coincide com o nome do enum (snake_case já sem underscore).
  String get wire => name;

  static FuelType fromWire(String value) {
    return FuelType.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('FuelType desconhecido: $value'),
    );
  }
}

enum FuelSource {
  aiScan('ai_scan'),
  ocr('ocr'),
  manual('manual');

  const FuelSource(this.wire);

  final String wire;

  static FuelSource fromWire(String value) {
    return FuelSource.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('FuelSource desconhecido: $value'),
    );
  }
}

enum ExpenseCategory {
  manutencao('manutencao'),
  lavagem('lavagem'),
  estacionamento('estacionamento'),
  multa('multa'),
  seguro('seguro'),
  ipva('ipva'),
  licenciamento('licenciamento'),
  outro('outro');

  const ExpenseCategory(this.wire);

  final String wire;

  static ExpenseCategory fromWire(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('ExpenseCategory desconhecida: $value'),
    );
  }
}

enum ReminderType {
  porKm('por_km'),
  porData('por_data');

  const ReminderType(this.wire);

  final String wire;

  static ReminderType fromWire(String value) {
    return ReminderType.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('ReminderType desconhecido: $value'),
    );
  }
}

enum SyncStatus {
  pending('pending'),
  synced('synced');

  const SyncStatus(this.wire);

  final String wire;

  static SyncStatus fromWire(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('SyncStatus desconhecido: $value'),
    );
  }
}

enum VehicleType {
  carro('carro'),
  moto('moto');

  const VehicleType(this.wire);
  final String wire;

  static VehicleType fromWire(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('VehicleType desconhecido: $value'),
    );
  }
}
