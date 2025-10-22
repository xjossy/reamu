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
}

