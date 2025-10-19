import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GlobalMemoryService {
  static const String _fileName = 'user_progress.json';
  static GlobalMemoryService? _instance;
  
  GlobalMemoryService._();
  
  static GlobalMemoryService get instance {
    _instance ??= GlobalMemoryService._();
    return _instance!;
  }

  Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return jsonDecode(jsonString);
      }
    } catch (e) {
      print('Error reading user progress: $e');
    }
    
    // Return default progress if file doesn't exist or error
    return _getDefaultProgress();
  }

  Future<void> saveUserProgress(Map<String, dynamic> progress) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(progress));
    } catch (e) {
      print('Error saving user progress: $e');
    }
  }

  Future<void> updateNoteStatistics(String noteName, String questionKey, String answer, List<String> allOptions) async {
    final progress = await getUserProgress();
    
    // Initialize note statistics if not exists
    if (!progress['synestetic_pitch']['note_statistics'].containsKey(noteName)) {
      progress['synestetic_pitch']['note_statistics'][noteName] = {
        'questions': {}
      };
    }
    
    // Initialize question if not exists
    if (!progress['synestetic_pitch']['note_statistics'][noteName]['questions'].containsKey(questionKey)) {
      progress['synestetic_pitch']['note_statistics'][noteName]['questions'][questionKey] = 
          List.filled(allOptions.length, 0);
    }
    
    // Find answer index and increment
    final answerIndex = allOptions.indexOf(answer);
    if (answerIndex >= 0) {
      progress['synestetic_pitch']['note_statistics'][noteName]['questions'][questionKey][answerIndex]++;
    }
    
    await saveUserProgress(progress);
  }

  Future<void> markNoteAsOpened(String noteName) async {
    final progress = await getUserProgress();
    final openedNotes = List<String>.from(progress['synestetic_pitch']['opened_notes']);
    
    if (!openedNotes.contains(noteName)) {
      openedNotes.add(noteName);
      progress['synestetic_pitch']['opened_notes'] = openedNotes;
      await saveUserProgress(progress);
    }
  }

  Future<void> markNoteAsLearned(String noteName) async {
    final progress = await getUserProgress();
    final learnedNotes = List<String>.from(progress['synestetic_pitch']['leaned_notes']);
    
    if (!learnedNotes.contains(noteName)) {
      learnedNotes.add(noteName);
      progress['synestetic_pitch']['leaned_notes'] = learnedNotes;
      await saveUserProgress(progress);
    }
  }

  Map<String, dynamic> _getDefaultProgress() {
    return {
      'synestetic_pitch': {
        'started': false,
        'opened_notes': [],
        'leaned_notes': [],
        'note_statistics': {}
      }
    };
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
