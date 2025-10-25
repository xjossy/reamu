import 'package:reamu/screens/synesthetic_pitch/guess_intro_page.dart';

import '../../services/logging_service.dart';
import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../models/synesthetic_session.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> with WidgetsBindingObserver {
  final SessionService _sessionService = SessionService.instance;
  
  SynestheticSession? _currentSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Subscribe to session updates
    _sessionService.addSessionUpdateListener(_onSessionUpdated);
    
    _loadSessionWithAutoStart();
  }
  
  void _onSessionUpdated() {
    Log.d('🔔 Session update notification received!', tag: 'SessionPage');
    if (mounted) {
      _loadSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Unsubscribe from session updates
    _sessionService.removeSessionUpdateListener(_onSessionUpdated);
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh session when app becomes active
      _loadSession();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Note: Session updates are now handled via observer pattern subscription
    // No need to reload here as we get notified immediately when data changes
  }

  Future<void> _loadSession() async {
    final session = await _sessionService.getCurrentSession();
    
    Log.d('Session loaded: ${session?.id}, completed: ${session?.isCompleted}, notes: ${session?.notesToGuess.length}', tag: 'SessionPage');
    Log.d('Correct guesses: ${session?.correctlyGuessed.length}, Incorrect: ${session?.incorrectlyGuessed.length}', tag: 'SessionPage');
    Log.d('Mistakes: ${session?.mistakes}', tag: 'SessionPage');
    
    setState(() {
      _currentSession = session;
      _isLoading = false;
    });
  }


  Future<void> _loadSessionWithAutoStart() async {
    var session = await _sessionService.getCurrentSession();
    
    // If no session exists, automatically start one
    if (session == null) {
      try {
        session = await _sessionService.startNewSession();
      } catch (e) {
        // Handle error silently for now
      }
    }
    
    setState(() {
      _currentSession = session;
      _isLoading = false;
    });
  }

  Future<void> _startGuessing() async {
    if (_currentSession == null) return;
    
    final currentNote = _currentSession!.currentNote;
    if (currentNote == null) {
      // Session completed
      await _completeSession();
      return;
    }

    Log.d('🎮 BEFORE GUESSING: Session ${_currentSession!.id}', tag: 'SessionPage');
    Log.d('🎮 Correct: ${_currentSession!.correctlyGuessed.length}, Incorrect: ${_currentSession!.incorrectlyGuessed.length}', tag: 'SessionPage');

    // Navigate to guessing page with session context
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuessIntroPage(
          questionCount: 5, // Default question count
          targetNoteName: currentNote,
        ),
      ),
    );
  }

  Future<void> _completeSession() async {
    if (_currentSession != null) {
      await _sessionService.completeSession(_currentSession!.id);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Session Complete! 🎉',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Congratulations on completing your synesthetic pitch session!',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Accuracy: ${(_currentSession!.accuracy * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'Notes guessed: ${_currentSession!.completedNotes}/${_currentSession!.totalNotes}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadSession();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Session',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Synesthetic Pitch Session',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        shadowColor: Colors.grey[300],
        // Debug button is now handled globally by DebugOverlay
      ),
      body: _isLoading || _currentSession == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionProgressCard(),
                  const SizedBox(height: 24),
                  _buildGuessHistoryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionProgressCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Session Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress bar
            LinearProgressIndicator(
              value: _currentSession!.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 12),
            
            Text(
              '${_currentSession!.completedNotes}/${_currentSession!.totalNotes} notes completed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Start Guessing Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _currentSession!.currentNote != null ? _startGuessing : null,
                icon: const Icon(Icons.quiz, size: 24),
                label: Text(
                  _currentSession!.currentNote != null 
                      ? 'Guess Next Note' 
                      : 'Session Complete',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentSession!.currentNote != null 
                      ? Colors.purple 
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildGuessHistoryCard() {
    // Build a list of all notes with their results
    final List<Widget> noteWidgets = [];
    
    for (final note in _currentSession!.notesToGuess) {
      // Check if this note has been guessed
      final isCorrect = _currentSession!.correctlyGuessed.contains(note);
      final incorrectGuess = _currentSession!.mistakes[note];
      
      // Only show notes that have been guessed
      if (isCorrect || incorrectGuess != null) {
        noteWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green[600] : Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect 
                            ? '$note - correct'
                            : '$note - you guessed $incorrectGuess',
                        style: TextStyle(
                          fontSize: 15,
                          color: isCorrect ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isCorrect) ...[
                        Text(
                          '+10 points',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '-5 points (both notes)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guess History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            if (noteWidgets.isEmpty) ...[
              Text(
                'No guesses yet. Start guessing!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              ...noteWidgets,
            ],
          ],
        ),
      ),
    );
  }

  // Debug functionality is now handled globally by DebugOverlay
}

