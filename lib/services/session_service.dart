import 'logging_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import '../models/synesthetic_session.dart';
import 'global_memory_service.dart';
import 'settings_service.dart';

class SessionService {
  static const String _fileName = 'synesthetic_sessions.json';
  static SessionService? _instance;
  
  SessionService._();
  
  static SessionService get instance {
    _instance ??= SessionService._();
    return _instance!;
  }

  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  
  // Observer pattern: callbacks for session updates
  final List<Function()> _sessionUpdateListeners = [];

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<SynestheticSession>> _loadSessions() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> sessionsJson = jsonDecode(jsonString);
        final sessions = sessionsJson.map((json) => SynestheticSession.fromJson(json)).toList();
      Log.i('Loaded ${sessions.length} sessions from disk', tag: 'SessionService');
        return sessions;
      }
    } catch (e, stackTrace) {
      Log.e('Error loading sessions', error: e, stackTrace: stackTrace, tag: 'SessionService');
    }
    return [];
  }

  Future<void> _saveSessions(List<SynestheticSession> sessions) async {
    try {
      final file = await _getFile();
      final sessionsJson = sessions.map((session) => session.toJson()).toList();
      await file.writeAsString(jsonEncode(sessionsJson));
    Log.i('Sessions saved to disk: ${sessions.length} sessions', tag: 'SessionService');
    } catch (e, stackTrace) {
    Log.e('Error saving sessions', error: e, stackTrace: stackTrace, tag: 'SessionService');
    }
  }

  Future<SynestheticSession?> getCurrentSession() async {
    final sessions = await _loadSessions();
    final currentSession = sessions.where((s) => !s.isCompleted).firstOrNull;
    
    if (currentSession != null) {
      // Check if session is still valid (within time limit)
      final sessionLengthMinutes = await _settingsService.getSessionLengthMinutes();
      final sessionExpiryTime = currentSession.startTime.add(Duration(minutes: sessionLengthMinutes));
      
      if (DateTime.now().isAfter(sessionExpiryTime)) {
        // Session expired, mark as completed
        await completeSession(currentSession.id);
        return null;
      }
    }
    
    return currentSession;
  }

  Future<SynestheticSession> startNewSession() async {
    // Get learned notes
    final userProgress = await _memoryService.getUserProgress();
    final learnedNotes = List<String>.from(userProgress['synestetic_pitch']['leaned_notes']);
    
    if (learnedNotes.isEmpty) {
      throw Exception('No learned notes available for session');
    }

    // Create random order
    final random = Random();
    final shuffledNotes = List<String>.from(learnedNotes)..shuffle(random);

    final session = SynestheticSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      notesToGuess: shuffledNotes,
    );

    final sessions = await _loadSessions();
    sessions.add(session);
    await _saveSessions(sessions);

    return session;
  }

  Future<void> recordCorrectGuess(String sessionId, String noteName) async {
    Log.d('Recording correct guess: $noteName for session: $sessionId', tag: 'SessionService');
    final sessions = await _loadSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1) {
      final session = sessions[sessionIndex];
      final updatedSession = session.copyWith(
        correctlyGuessed: [...session.correctlyGuessed, noteName],
      );
      sessions[sessionIndex] = updatedSession;
      await _saveSessions(sessions);
      
      // Update score: +10 points for correct guess
      await _memoryService.updateNoteScore(noteName, 10);
      
      Log.i('Correct guess saved. Total correct: ${updatedSession.correctlyGuessed.length}', tag: 'SessionService');
      
      // Notify all subscribers that session was updated
      _notifySessionUpdated();
    } else {
      Log.w('Session not found: $sessionId', tag: 'SessionService');
    }
  }

  Future<void> recordIncorrectGuess(String sessionId, String noteName, String guessedNote) async {
    Log.d('Recording incorrect guess: $noteName -> $guessedNote for session: $sessionId', tag: 'SessionService');
    final sessions = await _loadSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1) {
      final session = sessions[sessionIndex];
      final updatedSession = session.copyWith(
        incorrectlyGuessed: [...session.incorrectlyGuessed, noteName],
        mistakes: {...session.mistakes, noteName: guessedNote},
      );
      sessions[sessionIndex] = updatedSession;
      await _saveSessions(sessions);
      
      // Update scores: -5 points for both the correct note and the guessed note
      await _memoryService.updateNoteScore(noteName, -5);
      await _memoryService.updateNoteScore(guessedNote, -5);
      
      Log.i('Incorrect guess saved. Total incorrect: ${updatedSession.incorrectlyGuessed.length}', tag: 'SessionService');
      
      // Notify all subscribers that session was updated
      _notifySessionUpdated();
    } else {
      Log.w('Session not found: $sessionId', tag: 'SessionService');
    }
  }

  Future<void> completeSession(String sessionId) async {
    final sessions = await _loadSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1) {
      final session = sessions[sessionIndex];
      final updatedSession = session.copyWith(endTime: DateTime.now());
      sessions[sessionIndex] = updatedSession;
      await _saveSessions(sessions);
    }
  }

  Future<List<SynestheticSession>> getSessionHistory() async {
    final sessions = await _loadSessions();
    return sessions.where((s) => s.isCompleted).toList();
  }

  Future<bool> shouldStartNewSession() async {
    final currentSession = await getCurrentSession();
    if (currentSession != null) return false;

    final sessions = await _loadSessions();
    if (sessions.isEmpty) return true;

    final lastSession = sessions.last;
    if (!lastSession.isCompleted) return false;

    final sessionLengthMinutes = await _settingsService.getSessionLengthMinutes();
    final timeSinceLastSession = DateTime.now().difference(lastSession.endTime!);
    
    return timeSinceLastSession.inMinutes >= sessionLengthMinutes;
  }

  // Debug methods
  Future<void> printAllSessions() async {
    final sessions = await _loadSessions();
    Log.d('=== SESSION DEBUG ===', tag: 'SessionService');
    Log.d('Total sessions: ${sessions.length}', tag: 'SessionService');
    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      Log.d('Session $i:', tag: 'SessionService');
      Log.d('  ID: ${session.id}', tag: 'SessionService');
      Log.d('  Start: ${session.startTime}', tag: 'SessionService');
      Log.d('  End: ${session.endTime}', tag: 'SessionService');
      Log.d('  Completed: ${session.isCompleted}', tag: 'SessionService');
      Log.d('  Notes: ${session.notesToGuess}', tag: 'SessionService');
      Log.d('  Correct: ${session.correctlyGuessed}', tag: 'SessionService');
      Log.d('  Incorrect: ${session.incorrectlyGuessed}', tag: 'SessionService');
      Log.d('  Mistakes: ${session.mistakes}', tag: 'SessionService');
      Log.d('  Progress: ${(session.progress * 100).toStringAsFixed(1)}%', tag: 'SessionService');
    }
    Log.d('===================', tag: 'SessionService');
  }

  // Subscribe to session updates
  void addSessionUpdateListener(Function() callback) {
    Log.d('📢 Subscriber added to session updates', tag: 'SessionService');
    _sessionUpdateListeners.add(callback);
  }

  // Unsubscribe from session updates
  void removeSessionUpdateListener(Function() callback) {
    Log.d('📢 Subscriber removed from session updates', tag: 'SessionService');
    _sessionUpdateListeners.remove(callback);
  }

  // Notify all subscribers that session was updated
  void _notifySessionUpdated() {
    Log.d('📢 Notifying ${_sessionUpdateListeners.length} subscribers of session update', tag: 'SessionService');
    for (var callback in _sessionUpdateListeners) {
      callback();
    }
  }
}

