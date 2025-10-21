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
        print('Loaded ${sessions.length} sessions from disk');
        return sessions;
      }
    } catch (e) {
      print('Error loading sessions: $e');
    }
    return [];
  }

  Future<void> _saveSessions(List<SynestheticSession> sessions) async {
    try {
      final file = await _getFile();
      final sessionsJson = sessions.map((session) => session.toJson()).toList();
      await file.writeAsString(jsonEncode(sessionsJson));
      print('Sessions saved to disk: ${sessions.length} sessions');
    } catch (e) {
      print('Error saving sessions: $e');
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
    print('Recording correct guess: $noteName for session: $sessionId');
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
      
      print('Correct guess saved. Total correct: ${updatedSession.correctlyGuessed.length}');
      
      // Notify all subscribers that session was updated
      _notifySessionUpdated();
    } else {
      print('Session not found: $sessionId');
    }
  }

  Future<void> recordIncorrectGuess(String sessionId, String noteName, String guessedNote) async {
    print('Recording incorrect guess: $noteName -> $guessedNote for session: $sessionId');
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
      
      print('Incorrect guess saved. Total incorrect: ${updatedSession.incorrectlyGuessed.length}');
      
      // Notify all subscribers that session was updated
      _notifySessionUpdated();
    } else {
      print('Session not found: $sessionId');
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
    print('=== SESSION DEBUG ===');
    print('Total sessions: ${sessions.length}');
    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      print('Session $i:');
      print('  ID: ${session.id}');
      print('  Start: ${session.startTime}');
      print('  End: ${session.endTime}');
      print('  Completed: ${session.isCompleted}');
      print('  Notes: ${session.notesToGuess}');
      print('  Correct: ${session.correctlyGuessed}');
      print('  Incorrect: ${session.incorrectlyGuessed}');
      print('  Mistakes: ${session.mistakes}');
      print('  Progress: ${(session.progress * 100).toStringAsFixed(1)}%');
    }
    print('===================');
  }

  // Subscribe to session updates
  void addSessionUpdateListener(Function() callback) {
    print('📢 Subscriber added to session updates');
    _sessionUpdateListeners.add(callback);
  }

  // Unsubscribe from session updates
  void removeSessionUpdateListener(Function() callback) {
    print('📢 Subscriber removed from session updates');
    _sessionUpdateListeners.remove(callback);
  }

  // Notify all subscribers that session was updated
  void _notifySessionUpdated() {
    print('📢 Notifying ${_sessionUpdateListeners.length} subscribers of session update');
    for (var callback in _sessionUpdateListeners) {
      callback();
    }
  }
}

