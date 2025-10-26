// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionSettings _$SessionSettingsFromJson(Map<String, dynamic> json) =>
    SessionSettings(
      scores: (json['scores'] as num).toInt(),
      penalty: (json['penalty'] as num).toInt(),
      scoredNotes: (json['scored_notes'] as num?)?.toInt(),
      notes: (json['notes'] as num?)?.toInt(),
      maxInactivityMinutes: (json['max_inactivity_minutes'] as num?)?.toInt(),
      lifetimeMinutes: (json['lifetime_minutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SessionSettingsToJson(SessionSettings instance) =>
    <String, dynamic>{
      'scores': instance.scores,
      'penalty': instance.penalty,
      'scored_notes': instance.scoredNotes,
      'notes': instance.notes,
      'max_inactivity_minutes': instance.maxInactivityMinutes,
      'lifetime_minutes': instance.lifetimeMinutes,
    };
