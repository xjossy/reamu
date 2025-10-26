// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personalization_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalizationSettings _$PersonalizationSettingsFromJson(
  Map<String, dynamic> json,
) => PersonalizationSettings(
  morningSessionTime: json['morning_session_time'] as String,
  daylightDurationHours: (json['daylight_duration_hours'] as num).toDouble(),
  instantSessionsPerDay: (json['instant_sessions_per_day'] as num).toInt(),
  isCompleted: json['is_completed'] as bool? ?? false,
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
);

Map<String, dynamic> _$PersonalizationSettingsToJson(
  PersonalizationSettings instance,
) => <String, dynamic>{
  'morning_session_time': instance.morningSessionTime,
  'daylight_duration_hours': instance.daylightDurationHours,
  'instant_sessions_per_day': instance.instantSessionsPerDay,
  'is_completed': instance.isCompleted,
  'completed_at': instance.completedAt?.toIso8601String(),
};
