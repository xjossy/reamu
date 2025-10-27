import 'package:json_annotation/json_annotation.dart';

part 'session_settings.g.dart';

/// Represents settings for a session type
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class SessionSettings {
  final int scores;
  final int penalty;
  
  final int? scoredNotes;
  
  final int? notes;
  
  final int? maxInactivityMinutes;
  
  final int? lifetimeMinutes;

  final int? scoredNotesGapMinutes;

  final String? description;

  SessionSettings({
    required this.scores,
    required this.penalty,
    this.scoredNotes,
    this.notes,
    this.maxInactivityMinutes,
    this.lifetimeMinutes,
    this.scoredNotesGapMinutes,
    this.description,
  });

  factory SessionSettings.fromJson(Map<String, dynamic> json) =>
      _$SessionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SessionSettingsToJson(this);
}

/// Session type enum
enum SessionType {
  morning,
  instant,
  practice,
}

String sessionTypeToString(SessionType sessionType) => switch (sessionType) {
  SessionType.morning => 'Morning Session',
  SessionType.instant => 'Instant Session',
  SessionType.practice => 'Practice Session',
};
