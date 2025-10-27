// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synesthetic_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SynestheticSession _$SynestheticSessionFromJson(Map<String, dynamic> json) =>
    SynestheticSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      notesToGuess: (json['notes_to_guess'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      correctlyGuessed: (json['correctly_guessed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      incorrectlyGuessed: (json['incorrectly_guessed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mistakes: (json['mistakes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$SynestheticSessionToJson(SynestheticSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'notes_to_guess': instance.notesToGuess,
      'correctly_guessed': instance.correctlyGuessed,
      'incorrectly_guessed': instance.incorrectlyGuessed,
      'mistakes': instance.mistakes,
    };
