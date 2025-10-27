// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayProgress _$DayProgressFromJson(Map<String, dynamic> json) => DayProgress(
  dayPlan: DayPlan.fromJson(json['day_plan'] as Map<String, dynamic>),
  morningSessionId: json['morning_session_id'] as String?,
  practiceSessionId: json['practice_session_id'] as String?,
  instantSessions: (json['instant_sessions'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(int.parse(k), e as String),
  ),
  activeInstantSessionId: json['active_instant_session_id'] as String?,
  sessionManager: json['session_manager'] == null
      ? null
      : SessionManager.fromJson(
          json['session_manager'] as Map<String, dynamic>,
        ),
  dayIsComplete: json['day_is_complete'] as bool? ?? false,
);

Map<String, dynamic> _$DayProgressToJson(DayProgress instance) =>
    <String, dynamic>{
      'day_plan': instance.dayPlan.toJson(),
      'morning_session_id': instance.morningSessionId,
      'practice_session_id': instance.practiceSessionId,
      'instant_sessions': instance.instantSessions.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'active_instant_session_id': instance.activeInstantSessionId,
      'session_manager': instance.sessionManager.toJson(),
      'day_is_complete': instance.dayIsComplete,
    };

DayPlan _$DayPlanFromJson(Map<String, dynamic> json) => DayPlan(
  morningSessionTimestamp: DateTime.parse(
    json['morning_session_timestamp'] as String,
  ),
  instantSessionTimestamps:
      (json['instant_session_timestamps'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
);

Map<String, dynamic> _$DayPlanToJson(DayPlan instance) => <String, dynamic>{
  'morning_session_timestamp': instance.morningSessionTimestamp
      .toIso8601String(),
  'instant_session_timestamps': instance.instantSessionTimestamps
      .map((e) => e.toIso8601String())
      .toList(),
};
