import 'active_session.dart';
import 'session_manager.dart';
import 'session_settings.dart';

/// Represents a user's daily progress for synesthetic pitch training
class DayProgress {
  final DayPlan dayPlan;
  
  // Session ID mappings - now mutable
  String? morningSessionId;
  String? practiceSessionId;
  Map<int, String> instantSessions; // instant session number -> session ID
  String? activeInstantSessionId;
  List<int> completedInstantSessionNumbers; // numbers of completed instant sessions
  
  // Session management via SessionManager
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

  factory DayProgress.fromJson(Map<String, dynamic> json) {
    // Create session manager and populate it
    final sessionManager = SessionManager();
    
    if (json['sessions'] != null) {
      final sessionsJson = Map<String, dynamic>.from(json['sessions'] as Map);
      for (final entry in sessionsJson.entries) {
        try {
          final sessionData = SessionData.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
          sessionManager.saveSession(sessionData);
        } catch (e) {
          // Skip invalid session data
        }
      }
    }

    // Parse instant sessions mapping
    final instantSessionsMap = <int, String>{};
    if (json['instant_sessions'] != null) {
      final instantJson = Map<String, dynamic>.from(json['instant_sessions'] as Map);
      for (final entry in instantJson.entries) {
        instantSessionsMap[int.parse(entry.key)] = entry.value as String;
      }
    }

    // Parse completed instant session numbers
    final completedNumbers = <int>[];
    if (json['completed_instant_session_numbers'] != null) {
      completedNumbers.addAll(List<int>.from(json['completed_instant_session_numbers'] as List));
    }

    return DayProgress(
      dayPlan: DayPlan.fromJson(
        Map<String, dynamic>.from(json['day_plan'] as Map),
      ),
      morningSessionId: json['morning_session_id'] as String?,
      practiceSessionId: json['practice_session_id'] as String?,
      instantSessions: instantSessionsMap,
      activeInstantSessionId: json['active_instant_session_id'] as String?,
      completedInstantSessionNumbers: completedNumbers,
      sessionManager: sessionManager,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert all sessions from SessionManager to JSON
    final sessionsJson = <String, dynamic>{};
    for (final session in sessionManager.getSessions().values) {
      sessionsJson[session.id] = session.toJson();
    }

    return {
      'day_plan': dayPlan.toJson(),
      'morning_session_id': morningSessionId,
      'practice_session_id': practiceSessionId,
      'instant_sessions': instantSessions.map((key, value) => MapEntry(key.toString(), value)),
      'active_instant_session_id': activeInstantSessionId,
      'completed_instant_session_numbers': completedInstantSessionNumbers,
      'sessions': sessionsJson,
    };
  }

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
      day: DateTime.now().toString().split(' ')[0],
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

/// Represents the planned schedule for the day
class DayPlan {
  final DateTime morningSessionTimestamp;
  final List<DateTime> instantSessionTimestamps;

  DayPlan({
    required this.morningSessionTimestamp,
    required this.instantSessionTimestamps,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      morningSessionTimestamp:
          DateTime.parse(json['morning_session_timestamp'] as String),
      instantSessionTimestamps: (json['instant_session_timestamps'] as List?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning_session_timestamp': morningSessionTimestamp.toIso8601String(),
      'instant_session_timestamps':
          instantSessionTimestamps.map((t) => t.toIso8601String()).toList(),
    };
  }

  DayPlan copyWith({
    DateTime? morningSessionTimestamp,
    List<DateTime>? instantSessionTimestamps,
  }) {
    return DayPlan(
      morningSessionTimestamp:
          morningSessionTimestamp ?? this.morningSessionTimestamp,
      instantSessionTimestamps:
          instantSessionTimestamps ?? this.instantSessionTimestamps,
    );
  }

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

