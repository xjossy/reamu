// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Guess _$GuessFromJson(Map<String, dynamic> json) => Guess(
  timestamp: DateTime.parse(json['timestamp'] as String),
  note: json['note'] as String,
  choosedNote: json['choosed_note'] as String,
);

Map<String, dynamic> _$GuessToJson(Guess instance) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'note': instance.note,
  'choosed_note': instance.choosedNote,
};

SessionData _$SessionDataFromJson(Map<String, dynamic> json) => SessionData(
  id: json['id'] as String,
  day: DateTime.parse(json['day'] as String),
  type: $enumDecode(
    _$SessionTypeEnumMap,
    json['type'],
    unknownValue: SessionType.practice,
  ),
  settings: SessionSettings.fromJson(json['settings'] as Map<String, dynamic>),
  notesToGuess: (json['notes_to_guess'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  startTime: DateTime.parse(json['start_time'] as String),
  lastActivityTime: json['last_activity_time'] == null
      ? null
      : DateTime.parse(json['last_activity_time'] as String),
  guesses: (json['guesses'] as List<dynamic>?)
      ?.map((e) => Guess.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentNoteIndex: (json['current_note_index'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SessionDataToJson(SessionData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day': instance.day.toIso8601String(),
      'type': _$SessionTypeEnumMap[instance.type]!,
      'settings': instance.settings.toJson(),
      'notes_to_guess': instance.notesToGuess,
      'start_time': instance.startTime.toIso8601String(),
      'last_activity_time': instance.lastActivityTime?.toIso8601String(),
      'guesses': instance.guesses.map((e) => e.toJson()).toList(),
      'current_note_index': instance.currentNoteIndex,
    };

const _$SessionTypeEnumMap = {
  SessionType.morning: 'morning',
  SessionType.instant: 'instant',
  SessionType.practice: 'practice',
};
