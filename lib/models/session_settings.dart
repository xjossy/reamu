/// Represents settings for a session type
class SessionSettings {
  final int scores;
  final int penalty;
  final int? scoredNotes;
  final int? notes;
  final int? maxInactivityMinutes;
  final int? lifetimeMinutes;

  SessionSettings({
    required this.scores,
    required this.penalty,
    this.scoredNotes,
    this.notes,
    this.maxInactivityMinutes,
    this.lifetimeMinutes,
  });

  factory SessionSettings.fromJson(Map<String, dynamic> json) {
    return SessionSettings(
      scores: json['scores'] as int,
      penalty: json['penalty'] as int,
      scoredNotes: json['scored_notes'] as int?,
      notes: json['notes'] as int?,
      maxInactivityMinutes: json['max_inactivity_minutes'] as int?,
      lifetimeMinutes: json['lifetime_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scores': scores,
      'penalty': penalty,
      if (scoredNotes != null) 'scored_notes': scoredNotes,
      if (notes != null) 'notes': notes,
      if (maxInactivityMinutes != null) 'max_inactivity_minutes': maxInactivityMinutes,
      if (lifetimeMinutes != null) 'lifetime_minutes': lifetimeMinutes,
    };
  }
}

/// Session type enum
enum SessionType {
  morning,
  instant,
  practice,
}

