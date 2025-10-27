// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgressData _$UserProgressDataFromJson(Map<String, dynamic> json) =>
    UserProgressData(
      synestheticPitch: SynestheticPitchData.fromJson(
        json['synesthetic_pitch'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UserProgressDataToJson(UserProgressData instance) =>
    <String, dynamic>{'synesthetic_pitch': instance.synestheticPitch.toJson()};

SynestheticPitchData _$SynestheticPitchDataFromJson(
  Map<String, dynamic> json,
) => SynestheticPitchData(
  started: json['started'] as bool? ?? false,
  openedNotes: (json['opened_notes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  learnedNotes: (json['learned_notes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  noteStatistics: (json['note_statistics'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, NoteStatistics.fromJson(e as Map<String, dynamic>)),
  ),
  noteScores: (json['note_scores'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
  guessStatistics:
      (json['guess_statistics'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, GuessStatistics.fromJson(e as Map<String, dynamic>)),
      ) ??
      {},
  level: (json['level'] as num?)?.toInt() ?? 1,
  personalization: json['personalization'] == null
      ? null
      : PersonalizationSettings.fromJson(
          json['personalization'] as Map<String, dynamic>,
        ),
  dayProgress: json['day_progress'] == null
      ? null
      : DayProgress.fromJson(json['day_progress'] as Map<String, dynamic>),
  levelComplete: json['level_complete'] as bool? ?? false,
  notesToLearn: (json['notes_to_learn'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SynestheticPitchDataToJson(
  SynestheticPitchData instance,
) => <String, dynamic>{
  'started': instance.started,
  'opened_notes': instance.openedNotes,
  'learned_notes': instance.learnedNotes,
  'note_statistics': instance.noteStatistics.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'level': instance.level,
  'note_scores': instance.noteScores,
  'guess_statistics': instance.guessStatistics.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'personalization': instance.personalization?.toJson(),
  'day_progress': instance.dayProgress?.toJson(),
  'level_complete': instance.levelComplete,
  'notes_to_learn': instance.notesToLearn,
};

NoteStatistics _$NoteStatisticsFromJson(Map<String, dynamic> json) =>
    NoteStatistics(
      questions: (json['questions'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Map<String, int>.from(e as Map)),
      ),
    );

Map<String, dynamic> _$NoteStatisticsToJson(NoteStatistics instance) =>
    <String, dynamic>{'questions': instance.questions};

GuessStatistics _$GuessStatisticsFromJson(Map<String, dynamic> json) =>
    GuessStatistics(
      correctGuesses: (json['correct_guesses'] as num?)?.toInt() ?? 0,
      incorrectGuesses: (json['incorrect_guesses'] as num?)?.toInt() ?? 0,
      missesTo: (json['misses_to'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      missesFrom: (json['misses_from'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$GuessStatisticsToJson(GuessStatistics instance) =>
    <String, dynamic>{
      'correct_guesses': instance.correctGuesses,
      'incorrect_guesses': instance.incorrectGuesses,
      'misses_to': instance.missesTo,
      'misses_from': instance.missesFrom,
    };
