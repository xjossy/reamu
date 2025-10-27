import 'package:json_annotation/json_annotation.dart';
import 'active_session.dart';
import 'session_manager.dart';
import 'session_settings.dart';

part 'day_progress.g.dart';

/// Represents a user's daily progress for synesthetic pitch training
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class DayProgress {
  final DayPlan dayPlan;
  
  // Session ID mappings - now mutable
  String? morningSessionId;
  
  String? practiceSessionId;
  
  Map<int, String> instantSessions; // instant session number -> session ID
  
  String? activeInstantSessionId;
  
  // Session management via SessionManager
  final SessionManager sessionManager;

  @JsonKey(defaultValue: false)
  bool dayIsComplete;

  DayProgress({
    required this.dayPlan,
    this.morningSessionId,
    this.practiceSessionId,
    Map<int, String>? instantSessions,
    this.activeInstantSessionId,
    SessionManager? sessionManager,
    this.dayIsComplete = false,
  })  : instantSessions = instantSessions ?? {},
        sessionManager = sessionManager ?? SessionManager();

  factory DayProgress.fromJson(Map<String, dynamic> json) =>
      _$DayProgressFromJson(json);

  Map<String, dynamic> toJson() => _$DayProgressToJson(this);

  /// Get session by ID
  SessionData? getSessionById(String sessionId) {
    return sessionManager.getSessionById(sessionId);
  }

  /// Save/update session in this day progress
  void saveSession(SessionData session) {
    sessionManager.saveSession(session);
  }

  /// Check if morning session is completed
  bool isMorningSessionCompleted() {
    if (morningSessionId == null) return false;
    final session = getSessionById(morningSessionId!);
    return session?.isCompleted ?? false;
  }

  /// Check if the specified instant session has been completed
  bool isInstantSessionComplete(int sessionNumber) {
    return instantSessions.containsKey(sessionNumber) && 
      (getSessionById(instantSessions[sessionNumber]!)?.isCompleted ?? false);
  }

  /// Returns the current instant session number that should be active now,
  /// or null if the first instant session hasn't started yet.
  int? getCurrentInstantSession() {
    return dayPlan.getCurrentInstantSession();
  }

  /// Create a new session and save it, updating day progress state directly
  SessionData createAndSaveSession(
    SessionType type,
    SessionSettings settings,
    List<String> learnedNotes,
    {int? instantSessionNumber}
  ) {
    // Create the session via SessionManager
    final session = sessionManager.createSession(
      day: dayPlan.morningSessionTimestamp,
      type: type,
      settings: settings,
      learnedNotes: learnedNotes,
    );

    // Update session ID mappings directly
    switch (type) {
      case SessionType.morning:
        morningSessionId = session.id;
        break;
      case SessionType.practice:
        practiceSessionId = session.id;
        break;
      case SessionType.instant:
        if (instantSessionNumber != null) {
          instantSessions[instantSessionNumber] = session.id;
          activeInstantSessionId = session.id;
        }
        break;
    }

    return session;
  }

  /// Check if day is complete and compute positive guesses
  Map<String, int>? checkDayComplete() {
    // If day is already complete, do nothing
    if (dayIsComplete) {
      return null;
    }

    // Check if morning session is completed
    if (!isMorningSessionCompleted()) {
      return null;
    }

    // Check if all instant sessions are completed
    for (int i = 1; i <= dayPlan.instantSessionTimestamps.length; i++) {
      if (!isInstantSessionComplete(i)) {
        return null;
      }
    }

    // All sessions completed - compute positive guesses
    final Map<String, int> totalPositiveGuesses = {};

    // Collect all relevant session IDs: morning + instant sessions
    final List<String> sessionIds = [
      if (morningSessionId != null) morningSessionId!,
      ...instantSessions.values,
    ];

    for (final sessionId in sessionIds) {
      final session = getSessionById(sessionId);
      if (session != null) {
        final guesses = session.computePositiveGuesses();
        for (final entry in guesses.entries) {
          totalPositiveGuesses[entry.key] = (totalPositiveGuesses[entry.key] ?? 0) + entry.value;
        }
      }
    }

    dayIsComplete = true;

    return totalPositiveGuesses;
  }
}

/// Daily plan for sessions
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class DayPlan {
  final DateTime morningSessionTimestamp;
  
  final List<DateTime> instantSessionTimestamps;

  DayPlan({
    required this.morningSessionTimestamp,
    required this.instantSessionTimestamps,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) =>
      _$DayPlanFromJson(json);

  Map<String, dynamic> toJson() => _$DayPlanToJson(this);


  /// Returns the current instant session number that should be active now,
  /// or null if the first instant session hasn't started yet.
  int? getCurrentInstantSession() {
    final now = DateTime.now();
    
    // Check if we have any instant sessions planned
    if (instantSessionTimestamps.isEmpty) {
      return null;
    }
    
    // Find the current session that should be active
    // This is the last session that has started (now >= sessionTime)
    for (int i = instantSessionTimestamps.length - 1; i >= 0; i--) {
      final sessionTime = instantSessionTimestamps[i];
      if (now.isAfter(sessionTime) || now.isAtSameMomentAs(sessionTime)) {
        return i + 1; // Session numbers are 1-based
      }
    }
    
    // No session should be active yet
    return null;
  }
}

