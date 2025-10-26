import 'package:json_annotation/json_annotation.dart';

part 'session_settings.g.dart';

/// Represents settings for a session type
@JsonSerializable(explicitToJson: true)
class SessionSettings {
  final int scores;
  final int penalty;
  
  @JsonKey(name: 'scored_notes')
  final int? scoredNotes;
  
  final int? notes;
  
  @JsonKey(name: 'max_inactivity_minutes')
  final int? maxInactivityMinutes;
  
  @JsonKey(name: 'lifetime_minutes')
  final int? lifetimeMinutes;

  SessionSettings({
    required this.scores,
    required this.penalty,
    this.scoredNotes,
    this.notes,
    this.maxInactivityMinutes,
    this.lifetimeMinutes,
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
