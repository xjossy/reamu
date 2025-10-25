import 'dart:math';
import 'active_session.dart';
import 'session_settings.dart';

/// Manages session creation, storage, and retrieval
class SessionManager {
  final Map<String, SessionData> _sessions = {};
  
  /// Generate a unique session ID
  String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'sess_' + List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }
  
  /// Create a new session
  SessionData createSession({
    required String day,
    required SessionType type,
    required SessionSettings settings,
    required List<String> learnedNotes,
  }) {
    final id = _generateSessionId();
    final notesToGuess = settings.notes != null 
        ? _chooseNotesToGuess(learnedNotes, settings.notes!)
        : null;
    
    final session = SessionData(
      id: id,
      day: day,
      type: type,
      settings: settings,
      notesToGuess: notesToGuess,
      startTime: DateTime.now(),
      lastActivityTime: DateTime.now(),
    );
    
    _sessions[id] = session;
    return session;
  }
  
  /// Get session by ID
  SessionData? getSessionById(String id) {
    return _sessions[id];
  }
  
  /// Save session
  void saveSession(SessionData session) {
    _sessions[session.id] = session;
  }
  
  /// Remove session by ID
  void removeSession(String id) {
    _sessions.remove(id);
  }
  
  /// Get all sessions for a specific day
  List<SessionData> getSessionsForDay(String day) {
    return _sessions.values.where((s) => s.day == day).toList();
  }
  
  /// Get internal sessions map (for serialization)
  Map<String, SessionData> getSessions() {
    return _sessions;
  }
  
  /// Choose notes to guess from learned notes
  static List<String> _chooseNotesToGuess(
    List<String> learnedNotes,
    int totalNotes,
  ) {
    // Сколько раз нужно повторить изученные ноты
    final repeats = (totalNotes / learnedNotes.length).ceil();

    // Повторяем список, чтобы достичь нужного размера
    var notes = <String>[];
    for (int i = 0; i < repeats; i++) {
      notes.addAll(learnedNotes);
    }

    // Обрезаем, если список стал длиннее нужного
    if (notes.length > totalNotes) {
      notes = notes.sublist(0, totalNotes);
    }

    // Перемешиваем до 15 раз, пока не будет без соседних повторов
    for (int i = 0; i < 15; i++) {
      notes.shuffle(Random());
      if (!_hasAdjacentSameNotes(notes)) {
        break;
      }
    }

    return notes;
  }
  
  /// Check for adjacent same notes
  static bool _hasAdjacentSameNotes<T>(List<T> notes) {
    for (int i = 0; i < notes.length - 1; i++) {
      if (notes[i] == notes[i + 1]) {
        return true;
      }
    }
    return false;
  }
}
