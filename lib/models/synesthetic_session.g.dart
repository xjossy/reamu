// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synesthetic_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SynestheticSession _$SynestheticSessionFromJson(Map<String, dynamic> json) =>
    SynestheticSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      notesToGuess: (json['notesToGuess'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      correctlyGuessed:
          (json['correctlyGuessed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      incorrectlyGuessed:
          (json['incorrectlyGuessed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mistakes:
          (json['mistakes'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$SynestheticSessionToJson(SynestheticSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'notesToGuess': instance.notesToGuess,
      'correctlyGuessed': instance.correctlyGuessed,
      'incorrectlyGuessed': instance.incorrectlyGuessed,
      'mistakes': instance.mistakes,
    };
