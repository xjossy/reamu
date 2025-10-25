import 'day_progress.dart';
import 'personalization_settings.dart';

/// Structured representation of all user progress data
class UserProgressData {
  SynestheticPitchData synestheticPitch;

  UserProgressData({
    required this.synestheticPitch,
  });

  factory UserProgressData.fromJson(Map<String, dynamic> json) {
    return UserProgressData(
      synestheticPitch: SynestheticPitchData.fromJson(
        Map<String, dynamic>.from(json['synestetic_pitch'] as Map? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'synestetic_pitch': synestheticPitch.toJson(),
    };
  }
}

/// Synesthetic pitch specific data
class SynestheticPitchData {
  bool started;
  List<String> openedNotes;
  List<String> learnedNotes;
  Map<String, NoteStatistics> noteStatistics;
  int level;
  Map<String, int> noteScores;
  PersonalizationSettings? personalization;
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

  factory SynestheticPitchData.fromJson(Map<String, dynamic> json) {
    final noteStatsJson = json['note_statistics'] as Map? ?? {};
    final noteStats = <String, NoteStatistics>{};
    for (final entry in noteStatsJson.entries) {
      try {
        noteStats[entry.key] = NoteStatistics.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      } catch (e) {
        // Skip invalid entries
      }
    }

    return SynestheticPitchData(
      started: json['started'] as bool? ?? false,
      openedNotes: List<String>.from(json['opened_notes'] as List? ?? []),
      learnedNotes: List<String>.from(json['leaned_notes'] as List? ?? []),
      noteStatistics: noteStats,
      level: json['level'] as int? ?? 1,
      noteScores: Map<String, int>.from(
        ((json['note_scores'] as Map? ?? {}).cast<String, dynamic>())
            .map((k, v) => MapEntry(k, v as int)),
      ),
      personalization: json['personalization'] != null
          ? PersonalizationSettings.fromJson(
              Map<String, dynamic>.from(json['personalization'] as Map),
            )
          : null,
      dayProgress: json['day_progress'] != null
          ? DayProgress.fromJson(
              Map<String, dynamic>.from(json['day_progress'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final noteStatsJson = <String, dynamic>{};
    for (final entry in noteStatistics.entries) {
      noteStatsJson[entry.key] = entry.value.toJson();
    }

    return {
      'started': started,
      'opened_notes': openedNotes,
      'leaned_notes': learnedNotes,
      'note_statistics': noteStatsJson,
      'level': level,
      'note_scores': noteScores,
      'personalization': personalization?.toJson(),
      'day_progress': dayProgress?.toJson(),
    };
  }
}

/// Statistics for a single note
class NoteStatistics {
  Map<String, List<int>> questions;

  NoteStatistics({
    required this.questions,
  });

  factory NoteStatistics.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as Map? ?? {};
    final questions = <String, List<int>>{};
    for (final entry in questionsJson.entries) {
      questions[entry.key] = List<int>.from(entry.value as List);
    }
    return NoteStatistics(questions: questions);
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions,
    };
  }
}
