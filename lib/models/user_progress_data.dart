import 'package:json_annotation/json_annotation.dart';
import 'day_progress.dart';
import 'personalization_settings.dart';

part 'user_progress_data.g.dart';

/// Structured representation of all user progress data
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class UserProgressData {
  SynestheticPitchData synestheticPitch;

  UserProgressData({
    required this.synestheticPitch,
  });

  static Map<String, dynamic> preloadFixJson(Map<String, dynamic> json) {
    const badName = "synestetic_pitch";
    const correctName = "synesthetic_pitch";
    if (json.containsKey(badName) && !json.containsKey(correctName)) {
      json[correctName] = json[badName];
    }
    return json;
  }

  factory UserProgressData.fromJson(Map<String, dynamic> json) 
    => _$UserProgressDataFromJson(preloadFixJson(json));

  Map<String, dynamic> toJson() => _$UserProgressDataToJson(this);
}

/// Synesthetic pitch specific data
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class SynestheticPitchData {
  bool started;
  List<String> openedNotes;
  List<String> learnedNotes;
  Map<String, NoteStatistics> noteStatistics;
  int level;
  Map<String, int> noteScores;

  @JsonKey(defaultValue: {})
  Map<String, GuessStatistics> guessStatistics = {};

  PersonalizationSettings? personalization;
  DayProgress? dayProgress;

  @JsonKey(defaultValue: false)
  bool levelComplete;

  @JsonKey(defaultValue: 0)
  int notesToLearn;

  SynestheticPitchData({
    this.started = false,
    List<String>? openedNotes,
    List<String>? learnedNotes,
    Map<String, NoteStatistics>? noteStatistics,
    Map<String, int>? noteScores,
    Map<String, GuessStatistics>? guessStatistics,
    this.level = 1,
    this.personalization,
    this.dayProgress,
    this.levelComplete = false,
    this.notesToLearn = 0,
  }) : 
    openedNotes = openedNotes ?? [],
    learnedNotes = learnedNotes ?? [],
    noteStatistics = noteStatistics ?? {},
    noteScores = noteScores ?? {},
    guessStatistics = guessStatistics ?? {};

  GuessStatistics getStatisticsFor(String note) {
    return guessStatistics.putIfAbsent(note, () => GuessStatistics());
  }

  static Map<String, dynamic> preloadFixJson(Map<String, dynamic> json) {
    const badName = "leaned_notes";
    const correctName = "learned_notes";
    if (json.containsKey(badName) && !json.containsKey(correctName)) {
      json[correctName] = json[badName];
    }
    return json;
  }

  factory SynestheticPitchData.fromJson(Map<String, dynamic> json) =>
      _$SynestheticPitchDataFromJson(preloadFixJson(json));

  Map<String, dynamic> toJson() => _$SynestheticPitchDataToJson(this);
}

/// Statistics for a single note
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class NoteStatistics {
  Map<String, Map<String, int>> questions;

  NoteStatistics({
    required this.questions,
  });

  factory NoteStatistics.fromJson(Map<String, dynamic> json) =>
      _$NoteStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$NoteStatisticsToJson(this);
}

/// Statistics for a single guess
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class GuessStatistics {
  int correctGuesses;
  int incorrectGuesses;
  Map<String, int> missesTo;
  Map<String, int> missesFrom;

  void addMissFrom(String note) {
    missesFrom[note] = (missesFrom[note] ?? 0) + 1;
  }

  void addMissTo(String note) {
    missesTo[note] = (missesTo[note] ?? 0) + 1;
  }

  void addCorrectGuess() {  
    correctGuesses++;
  }

  void addIncorrectGuess() {
    incorrectGuesses++;
  }

  GuessStatistics({
    this.correctGuesses = 0,
    this.incorrectGuesses = 0,
    Map<String, int>? missesTo,
    Map<String, int>? missesFrom,
  }) :
    missesTo = missesTo ?? {},
    missesFrom = missesFrom ?? {};

  factory GuessStatistics.fromJson(Map<String, dynamic> json) =>
      _$GuessStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$GuessStatisticsToJson(this);
}