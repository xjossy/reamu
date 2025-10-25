import 'session_settings.dart';

/// Represents session data stored persistently
class SessionData {
  final String id; // Unique session identifier
  final String day; // Day identifier from DayProgress
  final SessionType type;
  final SessionSettings settings;
  final List<String>? notesToGuess;
  final DateTime startTime;
  final DateTime? lastActivityTime;
  final Map<String, bool> guesses; // Map of note -> isCorrect
  final int currentNoteIndex;

  SessionData({
    required this.id,
    required this.day,
    required this.type,
    required this.settings,
    this.notesToGuess,
    required this.startTime,
    this.lastActivityTime,
    Map<String, bool>? guesses,
    this.currentNoteIndex = 0,
  }) : guesses = guesses ?? {};

  factory SessionData.fromJson(Map<String, dynamic> json) {
    // Handle guesses map with proper type conversion
    final guessesMap = <String, bool>{};
    if (json['guesses'] != null) {
      final guesses = json['guesses'] as Map;
      for (final entry in guesses.entries) {
        final key = entry.key as String;
        final value = entry.value;
        // Convert to bool (handles bool, int 0/1, string "true"/"false")
        if (value is bool) {
          guessesMap[key] = value;
        } else if (value is int) {
          guessesMap[key] = value != 0;
        } else if (value is String) {
          guessesMap[key] = value.toLowerCase() == 'true';
        } else {
          guessesMap[key] = false;
        }
      }
    }
    
    return SessionData(
      id: json['id'] as String,
      day: json['day'] as String,
      type: SessionType.values.firstWhere(
        (e) => e.name == json['type'] as String,
      ),
      settings: SessionSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map),
      ),
      notesToGuess: json['notes_to_guess'] != null ? List<String>.from(json['notes_to_guess'] as List) : null,
      startTime: DateTime.parse(json['start_time'] as String),
      lastActivityTime: json['last_activity_time'] != null
          ? DateTime.parse(json['last_activity_time'] as String)
          : null,
      guesses: guessesMap,
      currentNoteIndex: json['current_note_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'type': type.name,
      'settings': settings.toJson(),
      'notes_to_guess': notesToGuess,
      'start_time': startTime.toIso8601String(),
      'last_activity_time': lastActivityTime?.toIso8601String(),
      'guesses': guesses,
      'current_note_index': currentNoteIndex,
    };
  }

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
    for (final entry in guesses.entries) {
      if (entry.value) {
        score += settings.scores;
      } else {
        score -= settings.penalty;
      }
    }
    return score;
  }

  /// Get number of correctly guessed notes
  int get correctCount => guesses.values.where((v) => v).length;

  /// Get number of incorrectly guessed notes
  int get incorrectCount => guesses.values.where((v) => !v).length;

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

  /// Create a copy with updated values
  SessionData copyWith({
    String? id,
    String? day,
    SessionType? type,
    SessionSettings? settings,
    List<String>? notesToGuess,
    DateTime? startTime,
    DateTime? lastActivityTime,
    Map<String, bool>? guesses,
    int? currentNoteIndex,
  }) {
    return SessionData(
      id: id ?? this.id,
      day: day ?? this.day,
      type: type ?? this.type,
      settings: settings ?? this.settings,
      notesToGuess: notesToGuess ?? this.notesToGuess,
      startTime: startTime ?? this.startTime,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      guesses: guesses ?? this.guesses,
      currentNoteIndex: currentNoteIndex ?? this.currentNoteIndex,
    );
  }
}

// Keep ActiveSession as a compatibility alias
typedef ActiveSession = SessionData;

