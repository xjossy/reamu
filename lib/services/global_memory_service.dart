import 'logging_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'settings_service.dart';
import '../models/day_progress.dart';
import '../models/personalization_settings.dart';

class GlobalMemoryService {
  static const String _fileName = 'user_progress.json';
  static GlobalMemoryService? _instance;
  
  GlobalMemoryService._();
  
  static GlobalMemoryService get instance {
    _instance ??= GlobalMemoryService._();
    return _instance!;
  }
  
  final SettingsService _settingsService = SettingsService.instance;

  Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return jsonDecode(jsonString);
      }
    } catch (e, stackTrace) {
      Log.e('Error reading user progress', error: e, stackTrace: stackTrace, tag: 'Memory');
    }
    
    // Return default progress if file doesn't exist or error
    return _getDefaultProgress();
  }

  Future<void> saveUserProgress(Map<String, dynamic> progress) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(progress));
    } catch (e, stackTrace) {
      Log.e('Error saving user progress', error: e, stackTrace: stackTrace, tag: 'Memory');
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
    
    // Get maximum score from settings
    final settings = await _settingsService.getSettings();
    final maxScore = settings['synestetic_pitch']['maximum_note_score'] as int;
    
    // Update score and clamp between 0 and max
    int newScore = (noteScores[noteName] as int) + scoreChange;
    newScore = max(0, min(maxScore, newScore));
    noteScores[noteName] = newScore;
    
    await saveUserProgress(progress);
    Log.i('Updated score for $noteName: ${noteScores[noteName]} (change: $scoreChange, clamped to 0-$maxScore)', tag: 'Memory');
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
    Log.d('=== USER PROGRESS DEBUG ===', tag: 'Memory');
    Log.d('Raw JSON: ${jsonEncode(progress)}', tag: 'Memory');
    Log.d('Synesthetic Pitch: ${progress['synestetic_pitch']}', tag: 'Memory');
    if (progress['synestetic_pitch'] != null) {
      final sp = progress['synestetic_pitch'] as Map<String, dynamic>;
      Log.d('Started: ${sp['started']}', tag: 'Memory');
      Log.d('Opened Notes: ${sp['opened_notes']}', tag: 'Memory');
      Log.d('Learned Notes: ${sp['leaned_notes']}', tag: 'Memory');
      Log.d('Level: ${sp['level']}', tag: 'Memory');
      Log.d('Note Scores: ${sp['note_scores']}', tag: 'Memory');
      Log.d('Note Statistics: ${sp['note_statistics']}', tag: 'Memory');
    }
    Log.d('========================', tag: 'Memory');
  }

  Future<void> resetUserProgress() async {
    final defaultProgress = _getDefaultProgress();
    await saveUserProgress(defaultProgress);
    Log.i('User progress reset to default', tag: 'Memory');
  }

  Future<void> resetNoteScores() async {
    final progress = await getUserProgress();
    if (progress.containsKey('synestetic_pitch')) {
      progress['synestetic_pitch']['note_scores'] = <String, dynamic>{};
      await saveUserProgress(progress);
      Log.i('Note scores reset', tag: 'Memory');
    }
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // ==================== DAY PROGRESS MANAGEMENT ====================

  /// Compute the morning session timestamp based on current time and personalization
  /// Principle: now() should be < morning_session_timestamp + daylightDurationHours - 30 minutes
  DateTime _computeMorningSessionTimestamp(PersonalizationSettings settings) {
    final now = DateTime.now();
    final morningTime = settings.morningTime;
    
    // Try today's date first
    DateTime candidateTimestamp = DateTime(
      now.year,
      now.month,
      now.day,
      morningTime.hour,
      morningTime.minute,
    ).subtract(const Duration(days: 1));

    // Calculate the deadline: morning_session_timestamp + daylightDuration - 30 minutes
    final daylightMinutes = (settings.daylightDurationHours * 60).round();
    final deadlineOffset = Duration(minutes: daylightMinutes - 30);

    while (now.isAfter(candidateTimestamp.add(deadlineOffset))) {
        candidateTimestamp = candidateTimestamp.add(const Duration(days: 1));
    }
    
    Log.d('Computed morning session timestamp: $candidateTimestamp (now: $now)', tag: 'Memory');
    return candidateTimestamp;
  }

  /// Compute instant session timestamps based on morning session and settings
  /// Only includes sessions that are after current moment
  List<DateTime> _computeInstantSessionTimestamps(
    DateTime morningSessionTimestamp,
    PersonalizationSettings settings,
    DateTime now,
  ) {
    final sessionOffsets = settings.getInstantSessionOffsets();

    List<DateTime> result = [];
    for (final offset in sessionOffsets) {
      final timestamp = morningSessionTimestamp.add(offset);
      if (timestamp.isAfter(now)) {
        result.add(timestamp);
      }
    }

    Log.d('Computed ${result.length} instant session timestamps', tag: 'Memory');
    return result;
  }

  /// Check if day_progress needs to be created or reset
  /// Returns true if day_progress was created/reset
  Future<bool> ensureDayProgressIsValid() async {
    try {
      final progress = await getUserProgress();
      final synestheticPitch = progress['synestetic_pitch'] as Map<String, dynamic>?;
      
      if (synestheticPitch == null) {
        Log.d('No synesthetic_pitch data, skipping day_progress', tag: 'Memory');
        return false;
      }

      // Check if user has completed learning and personalization
      final learnedNotes = List<String>.from(synestheticPitch['leaned_notes'] ?? []);
      final personalizationData = synestheticPitch['personalization'] as Map<String, dynamic>?;
      
      if (personalizationData == null) {
        Log.d('Personalization not completed, skipping day_progress', tag: 'Memory');
        return false;
      }

      final personalization = PersonalizationSettings.fromJson(personalizationData);
      if (!personalization.isCompleted) {
        Log.d('Personalization not marked as completed, skipping day_progress', tag: 'Memory');
        return false;
      }

      // Check if user has learned enough notes
      final settings = await _settingsService.getSettings();
      final startWithNotes = settings['synestetic_pitch']['start_with_notes'] as int;
      
      if (learnedNotes.length < startWithNotes) {
        Log.d('User has not learned enough notes (${learnedNotes.length}/$startWithNotes), skipping day_progress', tag: 'Memory');
        return false;
      }

      // Check if day_progress exists
      final existingDayProgress = synestheticPitch['day_progress'] as Map<String, dynamic>?;
      
      // Case 1: No previous day_progress
      if (existingDayProgress == null) {
        Log.i('No existing day_progress, creating initial one', tag: 'Memory');
        await _createInitialDayProgress(progress, personalization);
        return true;
      }

      // Case 2: Check if more than 20 hours since current day_progress.morning_session_timestamp
      final dayProgress = DayProgress.fromJson(existingDayProgress);
      final morningSessionTimestamp = dayProgress.dayPlan.morningSessionTimestamp;
      final now = DateTime.now();
      final hoursSinceMorning = now.difference(morningSessionTimestamp).inHours;
      
      if (hoursSinceMorning >= 20) {
        Log.i('More than 20 hours since morning session ($hoursSinceMorning hours), creating blank day_progress', tag: 'Memory');
        await _createBlankDayProgress(progress, personalization);
        return true;
      }

      Log.d('Day progress is valid, no changes needed', tag: 'Memory');
      return false;
    } catch (e, stackTrace) {
      Log.e('Error ensuring day_progress validity', error: e, stackTrace: stackTrace, tag: 'Memory');
      return false;
    }
  }

  /// Create initial day_progress when user completes learning and personalization
  /// Morning session is automatically marked as completed
  Future<void> _createInitialDayProgress(
    Map<String, dynamic> progress,
    PersonalizationSettings settings,
  ) async {
    final now = DateTime.now();
    final morningSessionTimestamp = _computeMorningSessionTimestamp(settings);
    final instantSessionTimestamps = _computeInstantSessionTimestamps(
      morningSessionTimestamp,
      settings,
      now
    );

    final morningSession = morningSessionTimestamp.isAfter(now) ? MorningSession(
      completed: true,
      completionTimestamp: now,
    ) : MorningSession(completed: false);

    final dayProgress = DayProgress(
      morningSession: morningSession,
      completedInstantSessions: [],
      dayPlan: DayPlan(
        morningSessionTimestamp: morningSessionTimestamp,
        instantSessionTimestamps: instantSessionTimestamps,
      ),
    );

    progress['synestetic_pitch']['day_progress'] = dayProgress.toJson();
    await saveUserProgress(progress);
    Log.i('Created initial day_progress with morning session completed', tag: 'Memory');
  }

  /// Create blank day_progress (reset)
  Future<void> _createBlankDayProgress(
    Map<String, dynamic> progress,
    PersonalizationSettings settings,
  ) async {
    final morningSessionTimestamp = _computeMorningSessionTimestamp(settings);
    final instantSessionTimestamps = _computeInstantSessionTimestamps(
      morningSessionTimestamp,
      settings,
      DateTime.now(),
    );

    final dayProgress = DayProgress(
      morningSession: MorningSession(
        completed: false,
        completionTimestamp: null,
      ),
      completedInstantSessions: [],
      dayPlan: DayPlan(
        morningSessionTimestamp: morningSessionTimestamp,
        instantSessionTimestamps: instantSessionTimestamps,
      ),
    );

    progress['synestetic_pitch']['day_progress'] = dayProgress.toJson();
    await saveUserProgress(progress);
    Log.i('Created blank day_progress', tag: 'Memory');
  }

  /// Get current day progress (if exists and valid)
  Future<DayProgress?> getDayProgress() async {
    try {
      await ensureDayProgressIsValid();
      final progress = await getUserProgress();
      final dayProgressData = progress['synestetic_pitch']?['day_progress'] as Map<String, dynamic>?;
      
      if (dayProgressData == null) {
        return null;
      }
      
      return DayProgress.fromJson(dayProgressData);
    } catch (e, stackTrace) {
      Log.e('Error getting day progress', error: e, stackTrace: stackTrace, tag: 'Memory');
      return null;
    }
  }
}
