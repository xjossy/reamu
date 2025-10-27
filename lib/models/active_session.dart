import 'package:json_annotation/json_annotation.dart';
import 'session_settings.dart';
import 'dart:math';

part 'active_session.g.dart';

/// Represents a single guess made during a session
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Guess {
  final DateTime timestamp;
  
  final String note;
  
  final String choosedNote;

  @JsonKey(defaultValue: 0)
  final int scores;
  
  Guess({
    required this.timestamp,
    required this.note,
    required this.choosedNote,
    required this.scores,
  });

  factory Guess.fromJson(Map<String, dynamic> json) => _$GuessFromJson(json);

  Map<String, dynamic> toJson() => _$GuessToJson(this);

  /// Check if this guess is correct
  bool get isCorrect => note == choosedNote;
}

/// Represents session data stored persistently
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class SessionData {
  final String id; // Unique session identifier
  final DateTime day; // Day identifier from DayProgress
  @JsonKey(unknownEnumValue: SessionType.practice)
  final SessionType type;
  final SessionSettings settings;
  
  final List<String>? notesToGuess;
  
  final DateTime startTime;
  
  DateTime? lastActivityTime;
  
  final List<Guess> guesses;
  
  int currentNoteIndex;

  SessionData({
    required this.id,
    required this.day,
    required this.type,
    required this.settings,
    this.notesToGuess,
    required this.startTime,
    this.lastActivityTime,
    List<Guess>? guesses,
    this.currentNoteIndex = 0,
  }) : guesses = guesses ?? [];

  factory SessionData.fromJson(Map<String, dynamic> json) =>
      _$SessionDataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDataToJson(this);

  static int _getRandomIndex(int max, int? exclude) {
    if (exclude == null) return Random().nextInt(max);
    int index = Random().nextInt(max - 1);
    return index >= exclude ? index + 1 : index;
  }

  /// Get the current note to guess
  String? getNextNote(List<String> learnedNotes) {
    if (settings.notes == null) {
      if (learnedNotes.isEmpty) return null;
      final lastNote = guesses.lastOrNull?.note;
      final lastNoteIndex = lastNote != null ? learnedNotes.indexOf(lastNote) : null;
      return learnedNotes[_getRandomIndex(learnedNotes.length, lastNoteIndex)];
    }
    if (notesToGuess == null || currentNoteIndex >= notesToGuess!.length) {
      return null;
    }
    return notesToGuess![currentNoteIndex];
  }

  /// Get total score
  int get totalScore {
    int score = 0;
    for (final guess in guesses) {
      score += guess.scores;
    }
    return score;
  }

  /// Get number of correctly guessed notes
  int get correctCount {
    return guesses.where((g) => g.isCorrect).length;
  }

  /// Get number of incorrectly guessed notes
  int get incorrectCount {
    return guesses.where((g) => !g.isCorrect).length;
  }

  /// Check if session is completed successfully
  bool get isCompletedSuccessfully {
    // Session is completed if we've guessed all notes
    return notesToGuess != null && currentNoteIndex >= notesToGuess!.length;
  }

  /// Check if session is completed
  bool get isCompleted {
    return isCompletedSuccessfully || shouldEnd();
  }

  /// Check if session timed out due to inactivity
  bool isInactivityTimeout() {
    if (settings.maxInactivityMinutes == null || lastActivityTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final inactivityDuration = now.difference(lastActivityTime!);
    return inactivityDuration.inMinutes >= settings.maxInactivityMinutes!;
  }

  /// Check if session timed out due to lifetime
  bool isLifetimeTimeout() {
    if (settings.lifetimeMinutes == null) {
      return false;
    }
    
    final now = DateTime.now();
    final sessionDuration = now.difference(startTime);
    return sessionDuration.inMinutes >= settings.lifetimeMinutes!;
  }

  /// Check if session should be ended (timeout)
  bool shouldEnd() {
    return isInactivityTimeout() || isLifetimeTimeout();
  }

  int getScore(bool isCorrect, DateTime ts) {
    final score = isCorrect ? settings.scores : -settings.penalty;
    if (settings.scoredNotesGapMinutes == null) {
      return score;
    }
    final lastGuess = guesses.lastOrNull;
    if (lastGuess == null) {
      return score;
    }
    final lastGuessTime = lastGuess.timestamp;
    final timeDiff = ts.difference(lastGuessTime);
    return timeDiff.inMinutes >= settings.scoredNotesGapMinutes! ? score : 0;
  }

  /// Compute positive guesses for each note
  Map<String, int> computePositiveGuesses() {
    final Map<String, int> positiveGuesses = {};
    
    for (final guess in guesses) {
      if (guess.scores > 0) {
        positiveGuesses[guess.note] = (positiveGuesses[guess.note] ?? 0) + guess.scores;
      }
    }
    
    return positiveGuesses;
  }
}

// Keep ActiveSession as a compatibility alias
typedef ActiveSession = SessionData;

