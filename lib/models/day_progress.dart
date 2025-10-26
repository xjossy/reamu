import 'package:json_annotation/json_annotation.dart';
import 'active_session.dart';
import 'session_manager.dart';
import 'session_settings.dart';

part 'day_progress.g.dart';

/// Represents a user's daily progress for synesthetic pitch training
@JsonSerializable(explicitToJson: true)
class DayProgress {
  @JsonKey(name: 'day_plan')
  final DayPlan dayPlan;
  
  // Session ID mappings - now mutable
  @JsonKey(name: 'morning_session_id')
  String? morningSessionId;
  
  @JsonKey(name: 'practice_session_id')
  String? practiceSessionId;
  
  @JsonKey(name: 'instant_sessions')
  Map<int, String> instantSessions; // instant session number -> session ID
  
  @JsonKey(name: 'active_instant_session_id')
  String? activeInstantSessionId;
  
  @JsonKey(name: 'completed_instant_session_numbers')
  List<int> completedInstantSessionNumbers; // numbers of completed instant sessions
  
  // Session management via SessionManager
  @JsonKey(name: 'sessions')
  final SessionManager sessionManager;

  DayProgress({
    required this.dayPlan,
    this.morningSessionId,
    this.practiceSessionId,
    Map<int, String>? instantSessions,
    this.activeInstantSessionId,
    List<int>? completedInstantSessionNumbers,
    SessionManager? sessionManager,
  })  : instantSessions = instantSessions ?? {},
        completedInstantSessionNumbers = completedInstantSessionNumbers ?? [],
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

  /// Remove session by ID
  void removeSession(String sessionId) {
    sessionManager.removeSession(sessionId);
  }

  /// Check if morning session is completed
  bool isMorningSessionCompleted() {
    if (morningSessionId == null) return false;
    final session = getSessionById(morningSessionId!);
    return session?.isCompleted ?? false;
  }

  /// Check if practice session is completed
  bool isPracticeSessionCompleted() {
    if (practiceSessionId == null) return false;
    final session = getSessionById(practiceSessionId!);
    return session?.isCompletedSuccessfully ?? false;
  }

  /// Check if the specified instant session has been completed
  bool isInstantSessionComplete(int sessionNumber) {
    return completedInstantSessionNumbers.contains(sessionNumber);
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
}

/// Daily plan for sessions
@JsonSerializable(explicitToJson: true)
class DayPlan {
  @JsonKey(name: 'morning_session_timestamp')
  final DateTime morningSessionTimestamp;
  
  @JsonKey(name: 'instant_session_timestamps')
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

