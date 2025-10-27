import 'package:json_annotation/json_annotation.dart';
import 'session_settings.dart';

part 'app_settings.g.dart';

/// Global application settings
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class AppSettings {
  final SynestheticPitchSettings synestheticPitch;

  AppSettings({
    required this.synestheticPitch,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}

/// Synesthetic pitch specific settings
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class SynestheticPitchSettings {
  final int guessQuestions;

  final int sessionLengthMinutes;

  final int maximumNoteScore;

  final int sufficientNoteScore;

  final List<String> noteSequence;

  final int startWithNotes;

  final int notesPerLevel;

  final int minimumInstantSessions;

  final int maximumInstantSessions;

  final int defaultInstantSessions;

  final SessionSettings morningSessionSettings;

  final SessionSettings instantSessionSettings;

  final SessionSettings practiceSessionSettings;

  SynestheticPitchSettings({
    required this.guessQuestions,
    required this.sessionLengthMinutes,
    required this.maximumNoteScore,
    required this.sufficientNoteScore,
    required this.noteSequence,
    required this.startWithNotes,
    required this.notesPerLevel,
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
