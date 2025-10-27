import 'dart:math';
import 'package:reamu/services/global_config_service.dart';

import 'logging_service.dart';
import 'settings_service.dart';
import 'storage_manager.dart';
import '../models/day_progress.dart';
import '../models/personalization_settings.dart';
import '../models/active_session.dart';
import '../models/session_settings.dart';
import '../models/user_progress_data.dart';
import '../models/app_settings.dart';
import '../models/describing_question.dart';

class GlobalMemoryService {
  static const String _fileName = 'user_progress.json';
  static GlobalMemoryService? _instance;
  
  final StorageManager _storageManager = StorageManager(fileName: _fileName);
  final GlobalConfigService _configService = GlobalConfigService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  
  // Cached data in memory
  UserProgressData? _data;
  
  GlobalMemoryService._();
  
  static GlobalMemoryService get instance {
    _instance ??= GlobalMemoryService._();
    return _instance!;
  }
  
  /// Ensure data is loaded in memory, loading only once
  Future<Map<String, dynamic>> getRawData() async {
    if (_data != null) {
      return _data!.toJson();
    }

    return await _storageManager.loadData();
  }
  
  /// Ensure data is loaded in memory, loading only once
  Future<UserProgressData> ensureData() async {
    if (_data != null) {
      return _data!;
    }

    try {
      final json = await _storageManager.loadData();
      _data = UserProgressData.fromJson(json);
      Log.i('User progress data loaded', tag: 'Memory');
    } catch (e, stackTrace) {
      Log.e('Error loading user progress, using defaults', error: e, stackTrace: stackTrace, tag: 'Memory');
      _data = _createDefaultData();
    }

    return _data!;
  }

  /// Save data to storage (async, no need to await)
  void _saveData() {
    if (_data == null) return;
    _storageManager.saveData(_data!.toJson());
  }

  void save() => _saveData();

  /// Create default user progress data
  UserProgressData _createDefaultData() {
    return UserProgressData(
      synestheticPitch: SynestheticPitchData(),
    );
  }

  // ==================== NOTE MANAGEMENT ====================

  Future<void> markNoteAsOpened(String noteName) async {
    final data = await ensureData();
    if (!data.synestheticPitch.openedNotes.contains(noteName)) {
      data.synestheticPitch.openedNotes.add(noteName);
      _saveData();
    }
  }

  Future<void> markNoteAsLearned(String noteName) async {
    final data = await ensureData();
    if (!data.synestheticPitch.learnedNotes.contains(noteName)) {
      data.synestheticPitch.learnedNotes.add(noteName);
      _saveData();
    }
  }

  // ==================== NOTE STATISTICS ====================


  void _updateNoteStatisticsImpl(ConfigValue config, UserProgressData data, String noteName, String questionKey, String answer) async {
    // Initialize note statistics if not exists
    if (!data.synestheticPitch.noteStatistics.containsKey(noteName)) {
      data.synestheticPitch.noteStatistics[noteName] = NoteStatistics(questions: {});
    }

    final noteStats = data.synestheticPitch.noteStatistics[noteName]!;
    final question = config.getQuestion(questionKey);

    if (question == null) return;

    // Initialize question statistics map if not exists
    if (!noteStats.questions.containsKey(questionKey)) {
      noteStats.questions[questionKey] = {};
      // Initialize all option keys with 0 count
      for (final option in question.options) {
        noteStats.questions[questionKey]![option.key] = 0;
      }
    }

    // Find the option key for the given answer
    QuestionOption? foundOption;
    try {
      foundOption = question.options.firstWhere(
        (opt) => opt.key == answer,
      );
    } catch (e) {
      // Option not found
      foundOption = null;
    }

    if (foundOption != null) {
      // Increment the count for this option key
      noteStats.questions[questionKey]![foundOption.key] = 
          (noteStats.questions[questionKey]![foundOption.key] ?? 0) + 1;
    }
  }

  Future<void> updateNotesStatistics(String noteName, Map<String, String> answers) async {
    final data = await ensureData();
    final config = await _configService.value();
    
    for (final answer in answers.entries) {
      _updateNoteStatisticsImpl(config, data, noteName, answer.key, answer.value);
    }

    _saveData();
  }

  Future<void> updateNoteStatistics(String noteName, String questionKey, String answer) async {
    final data = await ensureData();
    final config = await _configService.value();

    _updateNoteStatisticsImpl(config, data, noteName, questionKey, answer);

    _saveData();
  }

  // ==================== NOTE SCORES ====================

  void _updateNoteScoreImpl(AppSettings settings, UserProgressData data, String noteName, int scoreChange) {
    final maxScore = settings.synestheticPitch.maximumNoteScore;

    int newScore = data.synestheticPitch.noteScores[noteName] ?? 0 + scoreChange;
    newScore = max(0, min(maxScore, newScore));
    data.synestheticPitch.noteScores[noteName] = newScore;
  }

  Future<void> updateNoteScore(String noteName, int scoreChange) async {
    final data = await ensureData();
    final settings = await _settingsService.getSettings();
    
    _updateNoteScoreImpl(settings, data, noteName, scoreChange);
    
    _saveData();
    Log.i('Updated score for $noteName: ${data.synestheticPitch.noteScores[noteName]} (change: $scoreChange)', tag: 'Memory');
  }

  Future<int> getNoteScore(String noteName) async {
    final data = await ensureData();
    return data.synestheticPitch.noteScores[noteName] ?? 0;
  }

  Future<Map<String, int>> getAllNoteScores() async {
    final data = await ensureData();
    return Map<String, int>.from(data.synestheticPitch.noteScores);
  }

  // ==================== LEVEL & PROGRESS ====================

  Future<int> getCurrentLevel() async {
    final data = await ensureData();
    return data.synestheticPitch.level;
  }

  // ==================== DAY PROGRESS ====================

  Future<DayProgress?> getDayProgress() async {
    await ensureDayProgressIsValid();
    final data = await ensureData();
    return data.synestheticPitch.dayProgress;
  }

  /// Check if day is complete and add scores to notes
  Future<Map<String, int>?> checkDayComplete() async {
    final dayProgress = await getDayProgress();
    if (dayProgress == null) {
      return null;
    }

    final positiveGuesses = dayProgress.checkDayComplete();
    if (positiveGuesses == null) {
      return null;
    }

    // Add scores to notes
    final data = await ensureData();
    final settings = await _settingsService.getSettings();
    for (final entry in positiveGuesses.entries) {
      _updateNoteScoreImpl(settings, data, entry.key, entry.value);
    }

    return positiveGuesses;
  }

  /// Check if level is complete and set up next level
  Future<void> checkLevelIsComplete() async {
    final data = await ensureData();
    final settings = await _settingsService.getSettings();
    
    // If level is already complete, do nothing
    if (data.synestheticPitch.levelComplete) {
      return;
    }
    
    // Check if all learned notes have sufficient scores
    final sufficientScore = settings.synestheticPitch.sufficientNoteScore;
    final learnedNotes = data.synestheticPitch.learnedNotes;
    
    for (final noteName in learnedNotes) {
      final score = data.synestheticPitch.noteScores[noteName] ?? 0;
      if (score < sufficientScore) {
        return; // Not all notes have sufficient scores
      }
    }
    
    // All learned notes have sufficient scores - level complete!
    data.synestheticPitch.levelComplete = true;
    data.synestheticPitch.notesToLearn = settings.synestheticPitch.notesPerLevel;
    
    _saveData();
    Log.i('Level ${data.synestheticPitch.level} completed! Added ${data.synestheticPitch.notesToLearn} notes to learn', tag: 'Memory');
  }

  /// Complete the current level and move to next level
  Future<void> completeLevel() async {
    final data = await ensureData();
    
    // Reset level completion status
    data.synestheticPitch.levelComplete = false;
    
    // Increase level
    data.synestheticPitch.level++;
    
    // Reset all note scores (but keep guess statistics)
    data.synestheticPitch.noteScores.clear();
    
    _saveData();
    Log.i('Level completed! Moved to level ${data.synestheticPitch.level}', tag: 'Memory');
  }

  Future<bool> ensureDayProgressIsValid() async {
    final data = await ensureData();
    final learnedNotes = data.synestheticPitch.learnedNotes;
    final personalization = data.synestheticPitch.personalization;

    if (personalization == null || !personalization.isCompleted) {
      Log.d('Personalization not completed, skipping day_progress', tag: 'Memory');
      return false;
    }

    final settings = await _settingsService.getSettings();
    final startWithNotes = settings.synestheticPitch.startWithNotes;

    if (learnedNotes.length < startWithNotes) {
      Log.d('User has not learned enough notes (${learnedNotes.length}/$startWithNotes)', tag: 'Memory');
      return false;
    }

    if (data.synestheticPitch.dayProgress != null) {
      final morningSessionTimestamp = data.synestheticPitch.dayProgress!.dayPlan.morningSessionTimestamp;
      final hoursSinceMorning = DateTime.now().difference(morningSessionTimestamp).inHours;

      if (hoursSinceMorning >= 20) {
        Log.i('More than 20 hours since morning session, creating blank day_progress', tag: 'Memory');
        await _createBlankDayProgress(personalization);
        return true;
      }

      return false;
    }

    Log.i('No existing day_progress, creating initial one', tag: 'Memory');
    await _createInitialDayProgress(personalization);
    return true;
  }

  Future<void> _createInitialDayProgress(PersonalizationSettings settings) async {
    final now = DateTime.now();
    final morningSessionTimestamp = _computeMorningSessionTimestamp(settings, now);
    final instantSessionTimestamps = _computeInstantSessionTimestamps(morningSessionTimestamp, settings, now);

    final dayProgress = DayProgress(
      dayPlan: DayPlan(
        morningSessionTimestamp: morningSessionTimestamp,
        instantSessionTimestamps: instantSessionTimestamps,
      ),
    );

    if (morningSessionTimestamp.isBefore(now)) {
      dayProgress.createAndSaveSession(
        SessionType.morning, 
        SessionSettings(scores: 0, penalty: 0, notes: 0), 
        []);
    }

    final data = await ensureData();
    data.synestheticPitch.dayProgress = dayProgress;
    _saveData();
    Log.i('Created initial day_progress', tag: 'Memory');
  }

  Future<void> _createBlankDayProgress(PersonalizationSettings settings) async {
    // Check if current day is complete before creating new day progress
    await checkDayComplete();
    
    final now = DateTime.now();
    final morningSessionTimestamp = _computeMorningSessionTimestamp(settings, now);
    final instantSessionTimestamps = _computeInstantSessionTimestamps(
      morningSessionTimestamp,
      settings,
      now,
    );

    final dayProgress = DayProgress(
      dayPlan: DayPlan(
        morningSessionTimestamp: morningSessionTimestamp,
        instantSessionTimestamps: instantSessionTimestamps,
      ),
    );

    final data = await ensureData();
    data.synestheticPitch.dayProgress = dayProgress;
    _saveData();
    Log.i('Created blank day_progress', tag: 'Memory');
  }

  DateTime _computeMorningSessionTimestamp(PersonalizationSettings settings, DateTime now) {
    final morningTime = settings.morningTime;
    
    DateTime candidateTimestamp = DateTime(
      now.year,
      now.month,
      now.day,
      morningTime.hour,
      morningTime.minute,
    ).subtract(const Duration(days: 1));

    final daylightMinutes = (settings.daylightDurationHours * 60).round();
    final deadlineOffset = Duration(minutes: daylightMinutes - 30);

    while (now.isAfter(candidateTimestamp.add(deadlineOffset))) {
        candidateTimestamp = candidateTimestamp.add(const Duration(days: 1));
    }
    
    return candidateTimestamp;
  }

  List<DateTime> _computeInstantSessionTimestamps(
    DateTime morningSessionTimestamp,
    PersonalizationSettings settings,
    DateTime now,
  ) {
    final sessionOffsets = settings.getInstantSessionOffsets();
    final result = <DateTime>[];

    for (final offset in sessionOffsets) {
      final timestamp = morningSessionTimestamp.add(offset);
      if (timestamp.isAfter(now)) {
        result.add(timestamp);
      }
    }

    return result;
  }

  // ==================== SESSIONS ====================

  Future<ActiveSession> getOrCreateCurrentSession(SessionType? requestedType) async {
    final dayProgress = await getDayProgress();
    if (dayProgress == null) {
      throw Exception('No day progress available');
    }

    final data = await ensureData();
    final learnedNotes = data.synestheticPitch.learnedNotes;

    if (learnedNotes.isEmpty) {
      throw Exception('No learned notes available for session');
    }

    final settings = await _settingsService.getSettings();

    // 1. Check morning session
    if (!dayProgress.isMorningSessionCompleted()) {
      if (dayProgress.morningSessionId != null) {
        final existingSession = dayProgress.getSessionById(dayProgress.morningSessionId!);
        if (existingSession != null && !existingSession.isCompleted) {
          return existingSession;
        }
      }

      return await _createSessionOfType(
        dayProgress,
        SessionType.morning,
        learnedNotes,
        settings,
      );
    }

    // 2. Check active instant session
    if (dayProgress.activeInstantSessionId != null) {
      final activeSession = dayProgress.getSessionById(dayProgress.activeInstantSessionId!);
      if (activeSession != null && !activeSession.isCompleted) {
        return activeSession;
      }
    }

    // 3. Check for current instant session time
    final currentInstantSessionNumber = dayProgress.getCurrentInstantSession();
    if (currentInstantSessionNumber != null && !dayProgress.isInstantSessionComplete(currentInstantSessionNumber)) {
      return await _createSessionOfType(
        dayProgress,
        SessionType.instant,
        learnedNotes,
        settings,
        instantSessionNumber: currentInstantSessionNumber,
      );
    }

    // 4. Return/create practice session
    if (dayProgress.practiceSessionId != null) {
      final practiceSession = dayProgress.getSessionById(dayProgress.practiceSessionId!);
      if (practiceSession != null && !practiceSession.isCompleted) {
        return practiceSession;
      }
    }

    return await _createSessionOfType(
      dayProgress,
      SessionType.practice,
      learnedNotes,
      settings,
    );
  }

  Future<ActiveSession> _createSessionOfType(
    DayProgress dayProgress,
    SessionType type,
    List<String> learnedNotes,
    AppSettings appSettings,
    {int? instantSessionNumber}
  ) async {
    final sessionSettings = _getSessionSettingsForType(type, appSettings);

    return dayProgress.createAndSaveSession(
      type,
      sessionSettings,
      learnedNotes,
      instantSessionNumber: instantSessionNumber,
    );
  }

  /// Get appropriate session settings based on session type
  SessionSettings _getSessionSettingsForType(SessionType type, AppSettings appSettings) {
    final pitchSettings = appSettings.synestheticPitch;
    return switch (type) {
      SessionType.morning => pitchSettings.morningSessionSettings,
      SessionType.instant => pitchSettings.instantSessionSettings,
      SessionType.practice => pitchSettings.practiceSessionSettings
    };
  }

  // ==================== PERSONALIZATION ====================

  Future<void> savePersonalization(PersonalizationSettings settings) async {
    final data = await ensureData();
    data.synestheticPitch.personalization = settings;
    data.synestheticPitch.started = true;
    _saveData();
  }

  // ==================== DEBUG & RESET ====================

  Future<void> resetUserProgress() async {
    _data = _createDefaultData();
    _saveData();
    Log.i('User progress reset to default', tag: 'Memory');
  }

  Future<void> resetAllUserData() async {
    await resetUserProgress();
    Log.i('All user data has been successfully reset', tag: 'Memory');
  }

  Future<void> updateGuessStatistics(String actualNote, String guessedNote) async {
    final data = await ensureData();
    final stats = data.synestheticPitch.getStatisticsFor(actualNote);
    final isCorrect = actualNote == guessedNote;
    if (isCorrect) {
      stats.addCorrectGuess();
    } else {
      stats.addIncorrectGuess();
      stats.addMissTo(guessedNote);
      data.synestheticPitch.getStatisticsFor(guessedNote).addMissFrom(actualNote);
    }
    _saveData();
  }
}
