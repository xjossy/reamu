import 'package:flutter/material.dart';

class PersonalizationSettings {
  final String morningSessionTime; // Format: "HH:mm" (24-hour)
  final double daylightDurationHours; // 8-16 hours (with 0.25 precision)
  final int instantSessionsPerDay; // From settings: minimum to maximum
  final bool isCompleted;
  final DateTime? completedAt; // Timestamp when personalization was first completed

  PersonalizationSettings({
    required this.morningSessionTime,
    required this.daylightDurationHours,
    required this.instantSessionsPerDay,
    this.isCompleted = false,
    this.completedAt,
  });

  factory PersonalizationSettings.fromJson(Map<String, dynamic> json) {
    return PersonalizationSettings(
      morningSessionTime: json['morning_session_time'] as String? ?? '08:00',
      daylightDurationHours: (json['daylight_duration_hours'] as num?)?.toDouble() ?? 12.0,
      instantSessionsPerDay: json['instant_sessions_per_day'] as int? ?? 7,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning_session_time': morningSessionTime,
      'daylight_duration_hours': daylightDurationHours,
      'instant_sessions_per_day': instantSessionsPerDay,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  PersonalizationSettings copyWith({
    String? morningSessionTime,
    double? daylightDurationHours,
    int? instantSessionsPerDay,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return PersonalizationSettings(
      morningSessionTime: morningSessionTime ?? this.morningSessionTime,
      daylightDurationHours: daylightDurationHours ?? this.daylightDurationHours,
      instantSessionsPerDay: instantSessionsPerDay ?? this.instantSessionsPerDay,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory PersonalizationSettings.defaultSettings(int defaultInstantSessions) {
    return PersonalizationSettings(
      morningSessionTime: '08:00',
      daylightDurationHours: 12.0,
      instantSessionsPerDay: defaultInstantSessions,
      isCompleted: false,
      completedAt: null,
    );
  }

  // Parse morning session time to TimeOfDay
  TimeOfDay get morningTime {
    final parts = morningSessionTime.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Calculate practice end time
  TimeOfDay get practiceEndTime {
    final startTime = morningTime;
    final durationMinutes = (daylightDurationHours * 60).round();
    final totalMinutes = startTime.hour * 60 + startTime.minute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;
    return TimeOfDay(hour: endHour, minute: endMinute);
  }

  List<Duration> getInstantSessionOffsets() {
    final totalSessions = instantSessionsPerDay + 1; // +1 for morning session
    final durationMinutes = (daylightDurationHours * 60).round();
    final sessionOffsets = <Duration>[];
    for (int i = 1; i < totalSessions; i++) {
      final sessionOffset = Duration(minutes: (durationMinutes * i / (totalSessions - 1)).round());
      sessionOffsets.add(sessionOffset);
    }
    return sessionOffsets;
  }


  // Calculate session times
  List<TimeOfDay> getSessionTimes() {
    final startTime = morningTime;
    final totalSessions = instantSessionsPerDay + 1; // +1 for morning session
    final sessionTimes = <TimeOfDay>[startTime];
    
    if (totalSessions <= 1) {
      return sessionTimes;
    }

    final offsets = getInstantSessionOffsets();

    final startMinutes = startTime.hour * 60 + startTime.minute;

    for (final offset in offsets) {
      final sessionMinutes = startMinutes + offset.inMinutes;
      final sessionHour = (sessionMinutes ~/ 60) % 24;
      final sessionMinute = sessionMinutes % 60;
      sessionTimes.add(TimeOfDay(hour: sessionHour, minute: sessionMinute));
    }
    return sessionTimes;
  }
}
