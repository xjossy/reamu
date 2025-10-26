import 'package:json_annotation/json_annotation.dart';
import 'session_settings.dart';

part 'app_settings.g.dart';

/// Global application settings
@JsonSerializable(explicitToJson: true)
class AppSettings {
  @JsonKey(name: 'synestetic_pitch')
  final SynestheticPitchSettings synestheticPitch;

  AppSettings({
    required this.synestheticPitch,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}

/// Synesthetic pitch specific settings
@JsonSerializable(explicitToJson: true)
class SynestheticPitchSettings {
  @JsonKey(name: 'guess_questions')
  final int guessQuestions;

  @JsonKey(name: 'session_length_minutes')
  final int sessionLengthMinutes;

  @JsonKey(name: 'maximum_note_score')
  final int maximumNoteScore;

  @JsonKey(name: 'note_sequence')
  final List<String> noteSequence;

  @JsonKey(name: 'start_with_notes')
  final int startWithNotes;

  @JsonKey(name: 'minumum_instant_sessions')
  final int minimumInstantSessions;

  @JsonKey(name: 'maximum_instant_sessions')
  final int maximumInstantSessions;

  @JsonKey(name: 'default_instant_sessions')
  final int defaultInstantSessions;

  @JsonKey(name: 'morning_session_settings')
  final SessionSettings morningSessionSettings;

  @JsonKey(name: 'instant_session_settings')
  final SessionSettings instantSessionSettings;

  @JsonKey(name: 'practice_session_settings')
  final SessionSettings practiceSessionSettings;

  SynestheticPitchSettings({
    required this.guessQuestions,
    required this.sessionLengthMinutes,
    required this.maximumNoteScore,
    required this.noteSequence,
    required this.startWithNotes,
    required this.minimumInstantSessions,
    required this.maximumInstantSessions,
    required this.defaultInstantSessions,
    required this.morningSessionSettings,
    required this.instantSessionSettings,
    required this.practiceSessionSettings,
  });

  factory SynestheticPitchSettings.fromJson(Map<String, dynamic> json) =>
      _$SynestheticPitchSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SynestheticPitchSettingsToJson(this);
}
