import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

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
    } catch (e) {
      print('Error loading settings: $e');
      return {};
    }
  }

  Future<List<String>> getSynestheticNoteSequence() async {
    final settings = await getSettings();
    final noteSequence = settings['synestetic_pitch']?['note_sequence'] as List?;
    return noteSequence?.map((note) => note.toString()).toList() ?? [];
  }

  Future<int> getCurrentNoteIndex(Map<String, dynamic> userProgress) async {
    final noteSequence = await getSynestheticNoteSequence();
    final openedNotes = List<String>.from(userProgress['synestetic_pitch']['opened_notes']);
    return openedNotes.length;
  }

  Future<String?> getCurrentNote(Map<String, dynamic> userProgress) async {
    final noteSequence = await getSynestheticNoteSequence();
    final currentIndex = await getCurrentNoteIndex(userProgress);
    
    if (currentIndex < noteSequence.length) {
      return noteSequence[currentIndex];
    }
    return null;
  }

  Future<bool> hasMoreNotes(Map<String, dynamic> userProgress) async {
    final noteSequence = await getSynestheticNoteSequence();
    final currentIndex = await getCurrentNoteIndex(userProgress);
    return currentIndex < noteSequence.length;
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
}
