// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgressData _$UserProgressDataFromJson(Map<String, dynamic> json) =>
    UserProgressData(
      synestheticPitch: SynestheticPitchData.fromJson(
        json['synestetic_pitch'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UserProgressDataToJson(UserProgressData instance) =>
    <String, dynamic>{'synestetic_pitch': instance.synestheticPitch.toJson()};

SynestheticPitchData _$SynestheticPitchDataFromJson(
  Map<String, dynamic> json,
) => SynestheticPitchData(
  started: json['started'] as bool,
  openedNotes: (json['opened_notes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  learnedNotes: (json['leaned_notes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  noteStatistics: (json['note_statistics'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, NoteStatistics.fromJson(e as Map<String, dynamic>)),
  ),
  level: (json['level'] as num).toInt(),
  noteScores: Map<String, int>.from(json['note_scores'] as Map),
  personalization: json['personalization'] == null
      ? null
      : PersonalizationSettings.fromJson(
          json['personalization'] as Map<String, dynamic>,
        ),
  dayProgress: json['day_progress'] == null
      ? null
      : DayProgress.fromJson(json['day_progress'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SynestheticPitchDataToJson(
  SynestheticPitchData instance,
) => <String, dynamic>{
  'started': instance.started,
  'opened_notes': instance.openedNotes,
  'leaned_notes': instance.learnedNotes,
  'note_statistics': instance.noteStatistics.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'level': instance.level,
  'note_scores': instance.noteScores,
  'personalization': instance.personalization?.toJson(),
  'day_progress': instance.dayProgress?.toJson(),
};

NoteStatistics _$NoteStatisticsFromJson(Map<String, dynamic> json) =>
    NoteStatistics(
      questions: (json['questions'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Map<String, int>.from(e as Map)),
      ),
    );

Map<String, dynamic> _$NoteStatisticsToJson(NoteStatistics instance) =>
    <String, dynamic>{'questions': instance.questions};
