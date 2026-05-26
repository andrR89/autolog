import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_insights.freezed.dart';
part 'history_insights.g.dart';

/// Resultado da análise de histórico do veículo via IA.
///
/// Retornado pela Edge Function `analyze-history`.
/// Todos os campos de lista podem ser vazios — a UI lida com empty states.
@freezed
abstract class HistoryInsights with _$HistoryInsights {
  const factory HistoryInsights({
    required List<DetectedPattern> patterns,
    required List<ProposedReminder> proposedReminders,
  }) = _HistoryInsights;

  factory HistoryInsights.fromJson(Map<String, dynamic> json) =>
      _$HistoryInsightsFromJson(json);
}

/// Padrão detectado no histórico do veículo.
///
/// Representa uma regularidade observada (ex: IPVA pago todo janeiro).
@freezed
abstract class DetectedPattern with _$DetectedPattern {
  const factory DetectedPattern({
    /// Categoria do padrão (ex: "ipva", "manutencao_periodica").
    required String category,

    /// Cadência: 'yearly' | 'monthly' | 'every_N_km' | 'unknown'.
    required String cadence,

    /// Próxima ocorrência estimada (null se cadência for por km ou desconhecida).
    DateTime? nextDue,

    /// Confiança do modelo (0.0–1.0). Default 0.0.
    @Default(0.0) double confidence,

    /// Justificativa textual do modelo (opcional).
    String? rationale,
  }) = _DetectedPattern;

  factory DetectedPattern.fromJson(Map<String, dynamic> json) =>
      _$DetectedPatternFromJson(json);
}

/// Lembrete proposto pela IA com base no histórico.
@freezed
abstract class ProposedReminder with _$ProposedReminder {
  const factory ProposedReminder({
    /// Título do lembrete proposto.
    required String title,

    /// Data de vencimento estimada (null para lembretes por km).
    DateTime? dueDate,

    /// Quilometragem de vencimento estimada (null para lembretes por data).
    int? dueKm,

    /// Justificativa textual. Default string vazia.
    @Default('') String rationale,
  }) = _ProposedReminder;

  factory ProposedReminder.fromJson(Map<String, dynamic> json) =>
      _$ProposedReminderFromJson(json);
}
