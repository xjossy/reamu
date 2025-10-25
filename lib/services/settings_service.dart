import 'logging_service.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/session_settings.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }

  SettingsService._();

  Map<String, dynamic>? _settings;

  Future<Map<String, dynamic>> getSettings() async {
    if (_settings != null) return _settings!;

    try {
      final yamlString = await rootBundle.loadString('assets/global_settings.yaml');
      final yamlData = loadYaml(yamlString);
      _settings = Map<String, dynamic>.from(yamlData);
      return _settings!;
    } catch (e, stackTrace) {
      Log.e('Error loading settings', error: e, stackTrace: stackTrace, tag: 'Settings');
      return {};
    }
  }

  Future<int> getGuessQuestionsCount() async {
    final settings = await getSettings();
    final count = settings['synestetic_pitch']?['guess_questions'] as int?;
    return count ?? 5; // Default to 5 if not specified
  }

  Future<int> getSessionLengthMinutes() async {
    final settings = await getSettings();
    final minutes = settings['synestetic_pitch']?['session_length_minutes'] as int?;
    return minutes ?? 20; // Default to 20 minutes if not specified
  }

  /// Get morning session settings
  Future<SessionSettings> getMorningSessionSettings() async {
    final settings = await getSettings();
    final sessionSettings = settings['synestetic_pitch']?['morning_session_settings'] as Map?;
    
    if (sessionSettings != null) {
      return SessionSettings.fromJson(Map<String, dynamic>.from(sessionSettings));
    }
    
    // Fallback to default
    return SessionSettings(
      scores: 10,
      penalty: 5,
      notes: 6,
    );
  }

  /// Get instant session settings
  Future<SessionSettings> getInstantSessionSettings() async {
    final settings = await getSettings();
    final sessionSettings = settings['synestetic_pitch']?['instant_session_settings'] as Map?;
    
    if (sessionSettings != null) {
      return SessionSettings.fromJson(Map<String, dynamic>.from(sessionSettings));
    }
    
    // Fallback to default
    return SessionSettings(
      scores: 20,
      penalty: 5,
      maxInactivityMinutes: 15,
      notes: 2,
    );
  }

  /// Get practice session settings
  Future<SessionSettings> getPracticeSessionSettings() async {
    final settings = await getSettings();
    final sessionSettings = settings['synestetic_pitch']?['practice_session_settings'] as Map?;
    
    if (sessionSettings != null) {
      return SessionSettings.fromJson(Map<String, dynamic>.from(sessionSettings));
    }
    
    // Fallback to default
    return SessionSettings(
      scores: 3,
      penalty: 1,
      lifetimeMinutes: 10,
      scoredNotes: 1,
    );
  }
}
