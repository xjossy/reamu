import 'package:reamu/screens/synesthetic_pitch/guessing_flow.dart';

import '../../services/logging_service.dart';
import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../models/active_session.dart';
import '../../models/session_settings.dart';

class SessionPage extends StatefulWidget {
  final SessionType sessionType;
  
  const SessionPage({
    super.key,
    required this.sessionType,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> with WidgetsBindingObserver {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  
  ActiveSession? _currentSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _loadSessionWithAutoStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh session when app becomes active
      _loadAndCheckSession();
    }
  }

  Future<void> _loadAndCheckSession() async {
    final session = await _memoryService.getOrCreateCurrentSession(widget.sessionType);
    
    Log.d('Session loaded: type=${session.type}, notes=${session.notesToGuess?.length}', tag: 'SessionPage');
    Log.d('Correct guesses: ${session.correctCount}, Incorrect: ${session.incorrectCount}', tag: 'SessionPage');
    
    if (!mounted) return;

    // Check if session is completed
    if (session.isCompletedSuccessfully) {
      await _completeSession(session);
      if (mounted) {
        Navigator.pop(context); // Close page after completion
      }
      return;
    } else if (session.isCompleted) {
      // Session completed but not successfully (timeout)
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      _currentSession = session;
      _isLoading = false;
    });
  }

  Future<void> _loadSessionWithAutoStart() async {
    try {
      final session = await _memoryService.getOrCreateCurrentSession(widget.sessionType);
      
      if (!mounted) return;

      setState(() {
        _currentSession = session;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Log.e('Error starting new session', error: e, stackTrace: stackTrace, tag: 'SessionPage');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startGuessing() async {
    if (_currentSession == null) return;
    
    final memoryServiceData = await _memoryService.ensureData();
    final currentNote = _currentSession!.getNextNote(memoryServiceData.synestheticPitch.learnedNotes);
    if (currentNote == null) {
      // Session completed, recheck it
      await _recheckSession();
      return;
    }

    Log.d('🎮 Starting guess for note: $currentNote', tag: 'SessionPage');
    Log.d('🎮 Correct: ${_currentSession!.correctCount}, Incorrect: ${_currentSession!.incorrectCount}', tag: 'SessionPage');

    // Run guessing flow
    final completed = await GuessingFlow.runGuessing(
      context: context,
      targetNote: currentNote,
      onNoteSelected: (guessedNote, isCorrect) async {
        await _recordGuess(currentNote, guessedNote, isCorrect);
      },
    );
    
    if (completed && mounted) {
      // Reload session to show updated progress
      await _recheckSession();
    }
  }

  Future<void> _recordGuess(String actualNote, String guessedNote, bool isCorrect) async {
    if (_currentSession == null) return;

    final now = DateTime.now();

    final score = _currentSession!.getScore(isCorrect, now);
    
    // Move to next note
    final nextIndex = _currentSession!.currentNoteIndex + 1;
    
    // Update last activity time
    // Update note scores
    await _memoryService.updateNoteScore(actualNote, score);
    if (!isCorrect) {
      await _memoryService.updateNoteScore(guessedNote, -_currentSession!.settings.penalty);
    }
    await _memoryService.updateGuessStatistics(actualNote, guessedNote);
    
    setState(() {
      _currentSession!.guesses.add(Guess(
        timestamp: now,
        note: actualNote,
        choosedNote: guessedNote,
        scores: score,
      ));
      _currentSession!.currentNoteIndex = nextIndex;
      _currentSession!.lastActivityTime = DateTime.now();
      _memoryService.save();
    });
  }

  Future<void> _recheckSession() async {
    if (_currentSession == null) return;
    
    // Check if session is now completed
    if (_currentSession!.isCompletedSuccessfully) {
      await _completeSession(_currentSession!);
    } else if (_currentSession!.isCompleted) {
      // Session timed out - just exit without dialog
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      // Session still active, reload to show progress
      await _loadAndCheckSession();
    }
  }

  Future<void> _completeSession(ActiveSession session) async {
    // Check if day is complete
    final dayCompletionScores = await _memoryService.checkDayComplete();
    
    // Calculate accuracy
    final totalGuesses = session.correctCount + session.incorrectCount;
    final accuracy = totalGuesses > 0 
        ? (session.correctCount / totalGuesses * 100)
        : 0.0;
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            dayCompletionScores != null 
                ? 'Day Complete! 🎉🎉' 
                : 'Session Complete! 🎉',
            style: TextStyle(
              color: dayCompletionScores != null ? Colors.purple[700] : Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dayCompletionScores != null) ...[
                Text(
                  'Congratulations! You\'ve completed ALL sessions for today!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Additional scores earned:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...dayCompletionScores.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '+${entry.value}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],
              Text(
                dayCompletionScores != null 
                    ? 'Final session results:'
                    : 'Congratulations on completing your synesthetic pitch session!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                'Total Score: ${session.totalScore}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Notes guessed: $totalGuesses${session.notesToGuess != null ? '/${session.notesToGuess!.length}' : ''}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Pop session page and return to menu
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
    final completedNotes = _currentSession!.correctCount + _currentSession!.incorrectCount;
    final totalNotes = _currentSession!.notesToGuess?.length;
    final progress = totalNotes != null && totalNotes > 0 ? completedNotes / totalNotes : 0.0;
    
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
                Text(
                  sessionTypeToString(_currentSession!.type),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            // Session description
            if (_currentSession!.settings.description != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Text(
                  _currentSession!.settings.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[800],
                    height: 1.4,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Score display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Score', '${_currentSession!.totalScore}', Colors.blue),
                _buildStatItem('Correct', '${_currentSession!.correctCount}', Colors.green),
                _buildStatItem('Wrong', '${_currentSession!.incorrectCount}', Colors.orange),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (totalNotes != null) ...[
              // Progress bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 12),
            
              Text(
                '$completedNotes/$totalNotes notes completed',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            
              const SizedBox(height: 24),
            ],
            
            // Start Guessing Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startGuessing,
                icon: const Icon(Icons.quiz, size: 24),
                label: Text(
                  !_currentSession!.isCompletedSuccessfully
                      ? 'Guess Next Note' 
                      : 'Session Complete',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_currentSession!.isCompletedSuccessfully
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }


  Widget _buildGuessHistoryCard() {
    // Build a list of all notes with their results
    final List<Widget> noteWidgets = [];
    
    for (final guess in _currentSession!.guesses) {
      noteWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                guess.isCorrect ? Icons.check_circle : Icons.cancel,
                color: guess.isCorrect ? Colors.green[600] : Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guess.isCorrect 
                          ? '${guess.note} - correct'
                          : '${guess.note} - you guessed ${guess.choosedNote}',
                      style: TextStyle(
                        fontSize: 15,
                        color: guess.isCorrect ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${guess.scores > 0 ? '+' : ''}${guess.scores} points',
                      style: TextStyle(
                        fontSize: 12,
                        color: guess.isCorrect ? Colors.green[600] : Colors.orange[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
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

