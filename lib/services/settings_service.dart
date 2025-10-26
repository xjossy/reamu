import 'logging_service.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/session_settings.dart';
import '../models/app_settings.dart';
import '../utils/common.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }

  SettingsService._();

  AppSettings? _settings;

  Future<AppSettings> getSettings() async {
    if (_settings != null) return _settings!;

    try {
      final yamlString = await rootBundle.loadString('assets/global_settings.yaml');
      final yamlData = loadYaml(yamlString);
      final jsonMap = convertYamlToJson(yamlData);
      _settings = AppSettings.fromJson(jsonMap);
      return _settings!;
    } catch (e, stackTrace) {
      Log.e('Error loading settings', error: e, stackTrace: stackTrace, tag: 'Settings');
      rethrow;
    }
  }

  Future<int> getGuessQuestionsCount() async {
    final settings = await getSettings();
    return settings.synestheticPitch.guessQuestions; // Default to 5
  }

  Future<int> getSessionLengthMinutes() async {
    final settings = await getSettings();
    return settings.synestheticPitch.sessionLengthMinutes; // Default to 20
  }

  /// Get morning session settings
  Future<SessionSettings> getMorningSessionSettings() async {
    final settings = await getSettings();
    
    return settings.synestheticPitch.morningSessionSettings;
  }

  /// Get instant session settings
  Future<SessionSettings> getInstantSessionSettings() async {
    final settings = await getSettings();
    
    return settings.synestheticPitch.instantSessionSettings;
  }

  /// Get practice session settings
  Future<SessionSettings> getPracticeSessionSettings() async {
    final settings = await getSettings();
    
    return settings.synestheticPitch.practiceSessionSettings;
  }
}
