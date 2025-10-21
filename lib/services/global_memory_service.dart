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
    final noteStatistics = progress['synestetic_pitch']['note_statistics'];
    
    // Initialize note statistics if not exists
    if (!noteStatistics.containsKey(noteName)) {
      noteStatistics[noteName] = {
        'questions': {}
      };
    }

    final questions = noteStatistics[noteName]['questions'];
    
    // Initialize question if not exists
    if (!questions.containsKey(questionKey)) {
      questions[questionKey] = List.filled(allOptions.length, 0);
    }
    
    // Find answer index and increment
    final answerIndex = allOptions.indexOf(answer);
    if (answerIndex >= 0) {
      if (answerIndex >= questions[questionKey].length) {
        final missingCount = (answerIndex - questions[questionKey].length + 1).toInt();
        questions[questionKey].addAll(List.filled(missingCount, 0));
      }
      questions[questionKey][answerIndex]++;
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
        'note_statistics': {},
        'level': 1,
        'note_scores': {}
      }
    };
  }

  Future<void> updateNoteScore(String noteName, int scoreChange) async {
    final progress = await getUserProgress();
    
    // Ensure synestetic_pitch section exists
    if (!progress.containsKey('synestetic_pitch')) {
      progress['synestetic_pitch'] = {};
    }
    
    // Ensure note_scores exists and is properly initialized
    if (!progress['synestetic_pitch'].containsKey('note_scores') || 
        progress['synestetic_pitch']['note_scores'] == null) {
      progress['synestetic_pitch']['note_scores'] = <String, dynamic>{};
    }
    
    final noteScores = progress['synestetic_pitch']['note_scores'] as Map<String, dynamic>;
    
    // Initialize score if not exists
    if (!noteScores.containsKey(noteName)) {
      noteScores[noteName] = 0;
    }
    
    // Update score
    noteScores[noteName] = (noteScores[noteName] as int) + scoreChange;
    
    await saveUserProgress(progress);
    print('Updated score for $noteName: ${noteScores[noteName]} (change: $scoreChange)');
  }

  Future<int> getNoteScore(String noteName) async {
    final progress = await getUserProgress();
    
    // Ensure synestetic_pitch section exists
    if (!progress.containsKey('synestetic_pitch')) {
      return 0;
    }
    
    // Ensure note_scores exists
    if (!progress['synestetic_pitch'].containsKey('note_scores') || 
        progress['synestetic_pitch']['note_scores'] == null) {
      return 0;
    }
    
    final noteScores = progress['synestetic_pitch']['note_scores'] as Map<String, dynamic>;
    return noteScores[noteName] as int? ?? 0;
  }

  Future<int> getCurrentLevel() async {
    final progress = await getUserProgress();
    
    // Ensure synestetic_pitch section exists
    if (!progress.containsKey('synestetic_pitch')) {
      return 1;
    }
    
    return progress['synestetic_pitch']['level'] as int? ?? 1;
  }

  Future<Map<String, int>> getAllNoteScores() async {
    final progress = await getUserProgress();
    
    // Ensure synestetic_pitch section exists
    if (!progress.containsKey('synestetic_pitch')) {
      return {};
    }
    
    // Ensure note_scores exists
    if (!progress['synestetic_pitch'].containsKey('note_scores') || 
        progress['synestetic_pitch']['note_scores'] == null) {
      return {};
    }
    
    final noteScores = progress['synestetic_pitch']['note_scores'] as Map<String, dynamic>;
    return noteScores.map((key, value) => MapEntry(key, value as int));
  }

  // Debug methods
  Future<void> printUserProgress() async {
    final progress = await getUserProgress();
    print('=== USER PROGRESS DEBUG ===');
    print('Raw JSON: ${jsonEncode(progress)}');
    print('Synesthetic Pitch: ${progress['synestetic_pitch']}');
    if (progress['synestetic_pitch'] != null) {
      final sp = progress['synestetic_pitch'] as Map<String, dynamic>;
      print('Started: ${sp['started']}');
      print('Opened Notes: ${sp['opened_notes']}');
      print('Learned Notes: ${sp['leaned_notes']}');
      print('Level: ${sp['level']}');
      print('Note Scores: ${sp['note_scores']}');
      print('Note Statistics: ${sp['note_statistics']}');
    }
    print('========================');
  }

  Future<void> resetUserProgress() async {
    final defaultProgress = _getDefaultProgress();
    await saveUserProgress(defaultProgress);
    print('User progress reset to default');
  }

  Future<void> resetNoteScores() async {
    final progress = await getUserProgress();
    if (progress.containsKey('synestetic_pitch')) {
      progress['synestetic_pitch']['note_scores'] = <String, dynamic>{};
      await saveUserProgress(progress);
      print('Note scores reset');
    }
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
