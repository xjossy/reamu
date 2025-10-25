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

  /// Create default user progress data
  UserProgressData _createDefaultData() {
    return UserProgressData(
      synestheticPitch: SynestheticPitchData(
        started: false,
        openedNotes: [],
        learnedNotes: [],
        noteStatistics: {},
        level: 1,
        noteScores: {},
        personalization: null,
        dayProgress: null,
      ),
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

  Future<void> updateNotesStatistics(String noteName, Map<String, String> answers) async {
    final data = await ensureData();
    final config = await _configService.value();

    // Initialize note statistics if not exists
    if (!data.synestheticPitch.noteStatistics.containsKey(noteName)) {
      data.synestheticPitch.noteStatistics[noteName] = NoteStatistics(questions: {});
    }

    final noteStats = data.synestheticPitch.noteStatistics[noteName]!;
    
    for (final answer in answers.entries) {
      final question = config.getQuestion(answer.key);
      if (question == null) continue;

      if (!noteStats.questions.containsKey(answer.key)) {
        noteStats.questions[answer.key] = List.filled(question.options.length, 0);
      }

      final answerIndex = question.options.indexOf(answer.value);
      if (answerIndex >= 0) {
        if (answerIndex >= noteStats.questions[answer.key]!.length) {
          final missingCount = answerIndex - noteStats.questions[answer.key]!.length + 1;
          noteStats.questions[answer.key]!.addAll(List.filled(missingCount, 0));
        }
        noteStats.questions[answer.key]![answerIndex]++;
      }
    }

    _saveData();
  }

  Future<void> updateNoteStatistics(String noteName, String questionKey, String answer) async {
    final data = await ensureData();
    final config = await _configService.value();

    // Initialize note statistics if not exists
    if (!data.synestheticPitch.noteStatistics.containsKey(noteName)) {
      data.synestheticPitch.noteStatistics[noteName] = NoteStatistics(questions: {});
    }

    final noteStats = data.synestheticPitch.noteStatistics[noteName]!;
    final question = config.getQuestion(questionKey);

    if (question == null) return;

    if (!noteStats.questions.containsKey(questionKey)) {
      noteStats.questions[questionKey] = List.filled(question.options.length, 0);
    }

    final answerIndex = question.options.indexOf(answer);
    if (answerIndex >= 0) {
      if (answerIndex >= noteStats.questions[questionKey]!.length) {
        final missingCount = answerIndex - noteStats.questions[questionKey]!.length + 1;
        noteStats.questions[questionKey]!.addAll(List.filled(missingCount, 0));
      }
      noteStats.questions[questionKey]![answerIndex]++;
    }

    _saveData();
  }

  // ==================== NOTE SCORES ====================

  Future<void> updateNoteScore(String noteName, int scoreChange) async {
    final data = await ensureData();
    final settings = await _settingsService.getSettings();
    final maxScore = settings['synestetic_pitch']['maximum_note_score'] as int;
    
    if (!data.synestheticPitch.noteScores.containsKey(noteName)) {
      data.synestheticPitch.noteScores[noteName] = 0;
    }

    int newScore = data.synestheticPitch.noteScores[noteName]! + scoreChange;
    newScore = max(0, min(maxScore, newScore));
    data.synestheticPitch.noteScores[noteName] = newScore;
    
    _saveData();
    Log.i('Updated score for $noteName: ${data.synestheticPitch.noteScores[noteName]} (change: $scoreChange, clamped to 0-$maxScore)', tag: 'Memory');
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

  Future<void> saveDayProgress(DayProgress dayProgress) async {
    final data = await ensureData();
    data.synestheticPitch.dayProgress = dayProgress;
    _saveData();
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
    final startWithNotes = settings['synestetic_pitch']['start_with_notes'] as int;

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
    final morningSessionTimestamp = _computeMorningSessionTimestamp(settings);
    final instantSessionTimestamps = _computeInstantSessionTimestamps(morningSessionTimestamp, settings, now);

    final dayProgress = DayProgress(
      dayPlan: DayPlan(
        morningSessionTimestamp: morningSessionTimestamp,
        instantSessionTimestamps: instantSessionTimestamps,
      ),
    );

    final data = await ensureData();
    data.synestheticPitch.dayProgress = dayProgress;
    _saveData();
    Log.i('Created initial day_progress', tag: 'Memory');
  }

  Future<void> _createBlankDayProgress(PersonalizationSettings settings) async {
    final morningSessionTimestamp = _computeMorningSessionTimestamp(settings);
    final instantSessionTimestamps = _computeInstantSessionTimestamps(
      morningSessionTimestamp,
      settings,
      DateTime.now(),
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

  DateTime _computeMorningSessionTimestamp(PersonalizationSettings settings) {
    final now = DateTime.now();
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
    Map<String, dynamic> settings,
    {int? instantSessionNumber}
  ) async {
    final settingsKey = '${type.name}_session_settings';
    final sessionSettings = SessionSettings.fromJson(
      Map<String, dynamic>.from(settings['synestetic_pitch'][settingsKey] as Map)
    );

    return dayProgress.createAndSaveSession(
      type,
      sessionSettings,
      learnedNotes,
      instantSessionNumber: instantSessionNumber,
    );
  }

  Future<void> completeSessionSuccessfully(ActiveSession session) async {
    final dayProgress = await getDayProgress();
    if (dayProgress == null) {
      return;
    }
    
    if (session.type == SessionType.morning) {
      dayProgress.morningSessionId = session.id;
    } else if (session.type == SessionType.instant) {
      final currentSessionNumber = dayProgress.getCurrentInstantSession() ?? 1;
      if (!dayProgress.completedInstantSessionNumbers.contains(currentSessionNumber)) {
        dayProgress.completedInstantSessionNumbers.add(currentSessionNumber);
      }
      dayProgress.activeInstantSessionId = null;
    }

    await saveDayProgress(dayProgress);
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
}
