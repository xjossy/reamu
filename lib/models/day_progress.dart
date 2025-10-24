/// Represents a user's daily progress for synesthetic pitch training
class DayProgress {
  final MorningSession morningSession;
  final List<InstantSession> completedInstantSessions;
  final DayPlan dayPlan;

  DayProgress({
    required this.morningSession,
    required this.completedInstantSessions,
    required this.dayPlan,
  });

  factory DayProgress.fromJson(Map<String, dynamic> json) {
    return DayProgress(
      morningSession: MorningSession.fromJson(
        Map<String, dynamic>.from(json['morning_session'] as Map),
      ),
      completedInstantSessions: (json['completed_instant_sessions'] as List?)
              ?.map((e) => InstantSession.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      dayPlan: DayPlan.fromJson(
        Map<String, dynamic>.from(json['day_plan'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning_session': morningSession.toJson(),
      'completed_instant_sessions':
          completedInstantSessions.map((s) => s.toJson()).toList(),
      'day_plan': dayPlan.toJson(),
    };
  }

  DayProgress copyWith({
    MorningSession? morningSession,
    List<InstantSession>? completedInstantSessions,
    DayPlan? dayPlan,
  }) {
    return DayProgress(
      morningSession: morningSession ?? this.morningSession,
      completedInstantSessions:
          completedInstantSessions ?? this.completedInstantSessions,
      dayPlan: dayPlan ?? this.dayPlan,
    );
  }

  /// Returns the current instant session number that should be active now,
  /// or null if the first instant session hasn't started yet.
  int? getCurrentInstantSession() {
    return dayPlan.getCurrentInstantSession();
  }

  /// Returns true if the specified instant session has been completed.
  bool isInstantSessionComplete(int sessionNumber) {
    return completedInstantSessions.any((s) => s.number == sessionNumber);
  }
}

/// Represents the morning session completion status
class MorningSession {
  final bool completed;
  final DateTime? completionTimestamp;

  MorningSession({
    required this.completed,
    this.completionTimestamp,
  });

  factory MorningSession.fromJson(Map<String, dynamic> json) {
    return MorningSession(
      completed: json['completed'] as bool? ?? false,
      completionTimestamp: json['completion_timestamp'] != null
          ? DateTime.parse(json['completion_timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'completion_timestamp': completionTimestamp?.toIso8601String(),
    };
  }

  MorningSession copyWith({
    bool? completed,
    DateTime? completionTimestamp,
  }) {
    return MorningSession(
      completed: completed ?? this.completed,
      completionTimestamp: completionTimestamp ?? this.completionTimestamp,
    );
  }
}

/// Represents a completed instant session
class InstantSession {
  final int number;
  final DateTime completionTimestamp;

  InstantSession({
    required this.number,
    required this.completionTimestamp,
  });

  factory InstantSession.fromJson(Map<String, dynamic> json) {
    return InstantSession(
      number: json['number'] as int,
      completionTimestamp: DateTime.parse(json['completion_timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'completion_timestamp': completionTimestamp.toIso8601String(),
    };
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

