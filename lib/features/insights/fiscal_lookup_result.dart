import 'package:freezed_annotation/freezed_annotation.dart';

part 'fiscal_lookup_result.freezed.dart';
part 'fiscal_lookup_result.g.dart';

// ---------------------------------------------------------------------------
// Enum de origem do resultado
// ---------------------------------------------------------------------------

/// Origem do [FiscalLookupResult].
///
/// - [ai]: resultado veio da edge function (Haiku 4.5).
/// - [localFallback]: edge fn falhou / quota / offline → `brFiscalCalendar`.
/// - [cache]: hit no cache local (Drift, TTL 90 dias).
///
/// Não serializado para JSON — é metadata client-side.
enum FiscalLookupSource { ai, localFallback, cache }

// ---------------------------------------------------------------------------
// Modelo de entrada fiscal (IPVA ou Licenciamento)
// ---------------------------------------------------------------------------

@freezed
abstract class FiscalEntry with _$FiscalEntry {
  const factory FiscalEntry({
    required int month, // 1..12
    int? day, // null se desconhecido
    // ignore: invalid_annotation_target
    @JsonKey(name: 'source') String? sourceCitation, // ex: "SEFAZ-SP 2026"
  }) = _FiscalEntry;

  factory FiscalEntry.fromJson(Map<String, dynamic> json) =>
      _$FiscalEntryFromJson(json);
}

// ---------------------------------------------------------------------------
// Resultado completo do lookup fiscal
// ---------------------------------------------------------------------------

@freezed
abstract class FiscalLookupResult with _$FiscalLookupResult {
  const factory FiscalLookupResult({
    required FiscalEntry ipva,
    required FiscalEntry licensing,
    @Default(FiscalLookupSource.localFallback) FiscalLookupSource source,
  }) = _FiscalLookupResult;

  factory FiscalLookupResult.fromJson(Map<String, dynamic> json) =>
      _$FiscalLookupResultFromJson(json);
}
