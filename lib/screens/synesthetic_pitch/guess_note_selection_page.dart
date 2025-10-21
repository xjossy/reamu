import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../services/settings_service.dart';
import '../../models/note.dart';
import 'statistics_page.dart';
import 'comparative_stats_page.dart';
import '../../services/session_service.dart';
import '../../mixins/midi_cleanup_mixin.dart';
import '../../widgets/hold_to_play_button.dart';

class GuessNoteSelectionPage extends StatefulWidget {
  final String actualNoteName;
  final Map<String, String> sessionAnswers;
  final String? sessionId;
  
  const GuessNoteSelectionPage({
    super.key,
    required this.actualNoteName,
    required this.sessionAnswers,
    this.sessionId,
  });

  @override
  State<GuessNoteSelectionPage> createState() => _GuessNoteSelectionPageState();
}

class _GuessNoteSelectionPageState extends State<GuessNoteSelectionPage> with MidiCleanupMixin {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  final SessionService _sessionService = SessionService.instance;
  Map<String, dynamic> _userProgress = {};
  List<String> _noteSequence = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await _memoryService.getUserProgress();
    final noteSequence = await _settingsService.getSynestheticNoteSequence();
    
    setState(() {
      _userProgress = progress;
      _noteSequence = noteSequence;
      _isLoading = false;
    });
  }

  List<String> _generateKeyboardNotes() {
    final notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'H'];
    final keyboardNotes = <String>[];
    
    // C3 to C5 range
    for (int octave = 3; octave <= 5; octave++) {
      for (final note in notes) {
        keyboardNotes.add('$note$octave');
      }
    }
    
    return keyboardNotes;
  }

  bool _isNoteLearned(String noteName) {
    final learnedNotes = List<String>.from(_userProgress['synestetic_pitch']['leaned_notes']);
    return learnedNotes.contains(noteName);
  }


  void _selectNote(String guessedNoteName) async {
    final isCorrect = guessedNoteName == widget.actualNoteName;
    
    // Record session result if in a session
    if (widget.sessionId != null) {
      print('💾 Recording guess for session ${widget.sessionId}...');
      if (isCorrect) {
        await _sessionService.recordCorrectGuess(widget.sessionId!, widget.actualNoteName);
      } else {
        await _sessionService.recordIncorrectGuess(widget.sessionId!, widget.actualNoteName, guessedNoteName);
      }
      print('✅ Guess recorded successfully');
    }
    
    if (isCorrect) {
      // Correct answer - show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            'Correct! 🎉',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The note was: ${widget.actualNoteName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                
                if (widget.sessionId != null) {
                  // Return to session page
                  Navigator.of(context).popUntil((route) {
                    return route.settings.name == '/session' ||
                           (route is MaterialPageRoute && route.builder.toString().contains('SessionPage')) ||
                           route.isFirst;
                  });
                } else {
                  // Navigate to statistics page (regular guess mode)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatisticsPage(
                        selectedNote: widget.actualNoteName,
                        sessionAnswers: widget.sessionAnswers,
                      ),
                    ),
                  );
                }
              },
              child: Text(widget.sessionId != null ? 'Continue Session' : 'View Statistics'),
            ),
          ],
        ),
      );
    } else {
      // Wrong answer - show comparison page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ComparativeStatsPage(
            guessedNoteName: guessedNoteName,
            actualNoteName: widget.actualNoteName,
            sessionAnswers: widget.sessionAnswers,
            sessionId: widget.sessionId,
          ),
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
            'Guess the Note',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final keyboardNotes = _generateKeyboardNotes();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Which note was it?',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Instruction
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple[700], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select the note you think was played. Only learned notes are active.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Note Buttons Grid - 12 notes per row
            ...List.generate((keyboardNotes.length / 12).ceil(), (rowIndex) {
              final startIndex = rowIndex * 12;
              final endIndex = (startIndex + 12).clamp(0, keyboardNotes.length);
              final rowNotes = keyboardNotes.sublist(startIndex, endIndex);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rowNotes.map((noteName) {
                    final isLearned = _isNoteLearned(noteName);
                    final isActualNote = noteName == widget.actualNoteName;
                    
                    final note = Note.fromName(noteName);
                    return Expanded(
                      child: LongPressToPlayButton(
                        midiNote: note.midiNumber,
                        onTap: isLearned ? () => _selectNote(noteName) : null,
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isLearned
                                ? Colors.green[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLearned
                                  ? Colors.green[400]!
                                  : Colors.grey[400]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                noteName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isLearned
                                      ? Colors.green[700]
                                      : Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Icon(
                                isLearned
                                    ? Icons.check_circle
                                    : Icons.lock,
                                size: 12,
                                color: isLearned
                                    ? Colors.green[600]
                                    : Colors.grey[500],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            
            const SizedBox(height: 16),
            
            // Hint
            Text(
              'Long press a note to hear it',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

