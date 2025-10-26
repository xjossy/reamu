import 'package:json_annotation/json_annotation.dart';
import 'session_settings.dart';

part 'active_session.g.dart';

/// Represents a single guess made during a session
@JsonSerializable(explicitToJson: true)
class Guess {
  @JsonKey(name: 'timestamp')
  final DateTime timestamp;
  
  final String note;
  
  @JsonKey(name: 'choosed_note')
  final String choosedNote;
  
  Guess({
    required this.timestamp,
    required this.note,
    required this.choosedNote,
  });

  factory Guess.fromJson(Map<String, dynamic> json) => _$GuessFromJson(json);

  Map<String, dynamic> toJson() => _$GuessToJson(this);

  /// Check if this guess is correct
  bool get isCorrect => note == choosedNote;
}

/// Represents session data stored persistently
@JsonSerializable(explicitToJson: true)
class SessionData {
  final String id; // Unique session identifier
  final DateTime day; // Day identifier from DayProgress
  @JsonKey(unknownEnumValue: SessionType.practice)
  final SessionType type;
  final SessionSettings settings;
  
  @JsonKey(name: 'notes_to_guess')
  final List<String>? notesToGuess;
  
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  
  @JsonKey(name: 'last_activity_time')
  DateTime? lastActivityTime;
  
  final List<Guess> guesses;
  
  @JsonKey(name: 'current_note_index')
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

  /// Get the current note to guess
  String? get currentNote {
    if (notesToGuess == null || currentNoteIndex >= notesToGuess!.length) {
      return null;
    }
    return notesToGuess![currentNoteIndex];
  }

  /// Get total score
  int get totalScore {
    int score = 0;
    for (final guess in guesses) {
      if (guess.isCorrect) {
        score += settings.scores;
      } else {
        score -= settings.penalty;
      }
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
}

// Keep ActiveSession as a compatibility alias
typedef ActiveSession = SessionData;

