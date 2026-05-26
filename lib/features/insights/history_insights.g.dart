// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_insights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HistoryInsights _$HistoryInsightsFromJson(Map<String, dynamic> json) =>
    _HistoryInsights(
      patterns: (json['patterns'] as List<dynamic>)
          .map((e) => DetectedPattern.fromJson(e as Map<String, dynamic>))
          .toList(),
      proposedReminders: (json['proposed_reminders'] as List<dynamic>)
          .map((e) => ProposedReminder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HistoryInsightsToJson(_HistoryInsights instance) =>
    <String, dynamic>{
      'patterns': instance.patterns.map((e) => e.toJson()).toList(),
      'proposed_reminders': instance.proposedReminders
          .map((e) => e.toJson())
          .toList(),
    };

_DetectedPattern _$DetectedPatternFromJson(Map<String, dynamic> json) =>
    _DetectedPattern(
      category: json['category'] as String,
      cadence: json['cadence'] as String,
      nextDue: json['next_due'] == null
          ? null
          : DateTime.parse(json['next_due'] as String),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rationale: json['rationale'] as String?,
    );

Map<String, dynamic> _$DetectedPatternToJson(_DetectedPattern instance) =>
    <String, dynamic>{
      'category': instance.category,
      'cadence': instance.cadence,
      'next_due': instance.nextDue?.toIso8601String(),
      'confidence': instance.confidence,
      'rationale': instance.rationale,
    };

_ProposedReminder _$ProposedReminderFromJson(Map<String, dynamic> json) =>
    _ProposedReminder(
      title: json['title'] as String,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      dueKm: (json['due_km'] as num?)?.toInt(),
      rationale: json['rationale'] as String? ?? '',
    );

Map<String, dynamic> _$ProposedReminderToJson(_ProposedReminder instance) =>
    <String, dynamic>{
      'title': instance.title,
      'due_date': instance.dueDate?.toIso8601String(),
      'due_km': instance.dueKm,
      'rationale': instance.rationale,
    };
