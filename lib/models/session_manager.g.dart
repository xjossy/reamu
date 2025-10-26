// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_manager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionManager _$SessionManagerFromJson(Map<String, dynamic> json) =>
    SessionManager(
      sessions: (json['sessions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, SessionData.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$SessionManagerToJson(SessionManager instance) =>
    <String, dynamic>{
      'sessions': instance.sessions.map((k, e) => MapEntry(k, e.toJson())),
    };
