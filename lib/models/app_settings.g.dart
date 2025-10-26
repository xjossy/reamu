// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  synestheticPitch: SynestheticPitchSettings.fromJson(
    json['synestetic_pitch'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{'synestetic_pitch': instance.synestheticPitch.toJson()};

SynestheticPitchSettings _$SynestheticPitchSettingsFromJson(
  Map<String, dynamic> json,
) => SynestheticPitchSettings(
  guessQuestions: (json['guess_questions'] as num).toInt(),
  sessionLengthMinutes: (json['session_length_minutes'] as num).toInt(),
  maximumNoteScore: (json['maximum_note_score'] as num).toInt(),
  noteSequence: (json['note_sequence'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  startWithNotes: (json['start_with_notes'] as num).toInt(),
  minimumInstantSessions: (json['minumum_instant_sessions'] as num).toInt(),
  maximumInstantSessions: (json['maximum_instant_sessions'] as num).toInt(),
  defaultInstantSessions: (json['default_instant_sessions'] as num).toInt(),
  morningSessionSettings: SessionSettings.fromJson(
    json['morning_session_settings'] as Map<String, dynamic>,
  ),
  instantSessionSettings: SessionSettings.fromJson(
    json['instant_session_settings'] as Map<String, dynamic>,
  ),
  practiceSessionSettings: SessionSettings.fromJson(
    json['practice_session_settings'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SynestheticPitchSettingsToJson(
  SynestheticPitchSettings instance,
) => <String, dynamic>{
  'guess_questions': instance.guessQuestions,
  'session_length_minutes': instance.sessionLengthMinutes,
  'maximum_note_score': instance.maximumNoteScore,
  'note_sequence': instance.noteSequence,
  'start_with_notes': instance.startWithNotes,
  'minumum_instant_sessions': instance.minimumInstantSessions,
  'maximum_instant_sessions': instance.maximumInstantSessions,
  'default_instant_sessions': instance.defaultInstantSessions,
  'morning_session_settings': instance.morningSessionSettings.toJson(),
  'instant_session_settings': instance.instantSessionSettings.toJson(),
  'practice_session_settings': instance.practiceSessionSettings.toJson(),
};
