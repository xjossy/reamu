import 'package:json_annotation/json_annotation.dart';
import 'day_progress.dart';
import 'personalization_settings.dart';

part 'user_progress_data.g.dart';

/// Structured representation of all user progress data
@JsonSerializable(explicitToJson: true)
class UserProgressData {
  @JsonKey(name: 'synestetic_pitch')
  SynestheticPitchData synestheticPitch;

  UserProgressData({
    required this.synestheticPitch,
  });

  factory UserProgressData.fromJson(Map<String, dynamic> json) =>
      _$UserProgressDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserProgressDataToJson(this);
}

/// Synesthetic pitch specific data
@JsonSerializable(explicitToJson: true)
class SynestheticPitchData {
  bool started;
  
  @JsonKey(name: 'opened_notes')
  List<String> openedNotes;
  
  @JsonKey(name: 'leaned_notes')
  List<String> learnedNotes;
  
  @JsonKey(name: 'note_statistics')
  Map<String, NoteStatistics> noteStatistics;
  
  int level;
  
  @JsonKey(name: 'note_scores')
  Map<String, int> noteScores;
  
  PersonalizationSettings? personalization;
  
  @JsonKey(name: 'day_progress')
  DayProgress? dayProgress;

  SynestheticPitchData({
    required this.started,
    required this.openedNotes,
    required this.learnedNotes,
    required this.noteStatistics,
    required this.level,
    required this.noteScores,
    this.personalization,
    this.dayProgress,
  });

  factory SynestheticPitchData.fromJson(Map<String, dynamic> json) =>
      _$SynestheticPitchDataFromJson(json);

  Map<String, dynamic> toJson() => _$SynestheticPitchDataToJson(this);
}

/// Statistics for a single note
@JsonSerializable(explicitToJson: true)
class NoteStatistics {
  Map<String, Map<String, int>> questions;

  NoteStatistics({
    required this.questions,
  });

  factory NoteStatistics.fromJson(Map<String, dynamic> json) =>
      _$NoteStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$NoteStatisticsToJson(this);
}
