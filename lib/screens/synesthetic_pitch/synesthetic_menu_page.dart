import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../services/logging_service.dart';
import '../../services/settings_service.dart';
import 'statistics_page.dart';
import 'learning_flow.dart';
import 'personalization_wizard_page.dart';
import '../../models/day_progress.dart';
import '../../models/session_settings.dart';
import '../../models/user_progress_data.dart';
import 'session_page.dart';

class SynestheticMenuPage extends StatefulWidget {
  const SynestheticMenuPage({super.key});

  @override
  State<SynestheticMenuPage> createState() => _SynestheticMenuPageState();
}

class _SynestheticMenuPageState extends State<SynestheticMenuPage> {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  UserProgressData? _userProgress;
  List<String> _noteSequence = [];
  bool _isLoading = true;
  int _currentLevel = 1;
  Map<String, int> _noteScores = {};
  DayProgress? _dayProgress;
  int _maximumNoteScore = 0;
  int _sufficientNoteScore = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    Log.i('🔄 Synesthetic Pitch: Loading data...');
    final noteScores = await _memoryService.getAllNoteScores();
    
    // Check if level is complete
    await _memoryService.checkLevelIsComplete();
    
    // Reload data after potential level completion
    var updatedProgress = await _memoryService.ensureData();
    
    // Auto-advance if level is complete and all notes are learned
    if (updatedProgress.synestheticPitch.levelComplete && updatedProgress.synestheticPitch.notesToLearn == 0) {
      await _memoryService.completeLevel();
      updatedProgress = await _memoryService.ensureData();
    }
    
    // Load settings
    final settings = await _settingsService.getSettings();
    final maximumNoteScore = settings.synestheticPitch.maximumNoteScore;
    final sufficientNoteScore = settings.synestheticPitch.sufficientNoteScore;
    
    // Create keyboard order from C3 to C5
    final keyboardNotes = _generateKeyboardNotes();
    
    // Load day progress before setting loading to false
    DayProgress? dayProgress;
    try {
      dayProgress = await _memoryService.getDayProgress();
      Log.d('Day progress loaded: ${dayProgress != null}', tag: 'SynestheticMenu');
    } catch (e, stackTrace) {
      Log.e('Error loading day progress', error: e, stackTrace: stackTrace, tag: 'SynestheticMenu');
    }

    setState(() {
      _userProgress = updatedProgress;
      _noteSequence = keyboardNotes;
      _currentLevel = updatedProgress.synestheticPitch.level;
      _noteScores = noteScores;
      _dayProgress = dayProgress;
      _maximumNoteScore = maximumNoteScore;
      _sufficientNoteScore = sufficientNoteScore;
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
    final learnedNotes = List<String>.from(_userProgress?.synestheticPitch.learnedNotes ?? []);
    return learnedNotes.contains(noteName);
  }

  bool _isNoteOpened(String noteName) {
    final openedNotes = List<String>.from(_userProgress?.synestheticPitch.openedNotes ?? []);
    return openedNotes.contains(noteName);
  }

  @override
  Widget build(BuildContext context) {
    Log.d('Building Synesthetic Menu Page', tag: 'SynestheticMenu');
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Synesthetic Pitch',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Synesthetic Pitch',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final completed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonalizationWizardPage(),
                ),
              );
              
              // Reload data after completing personalization
              if (completed == true) {
                await _loadData();
              }
            },
            tooltip: 'Personalization Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Level Card
            _buildLevelCard(),
            const SizedBox(height: 16),
            
            // Day Progress Section
            if (_dayProgress != null) ...[
              _buildDayProgressSection(),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 32),
            
            // Progress Header
            const Text(
              'Note Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Note Buttons Grid - 12 notes per row
            ...List.generate((_noteSequence.length / 12).ceil(), (rowIndex) {
              final startIndex = rowIndex * 12;
              final endIndex = (startIndex + 12).clamp(0, _noteSequence.length);
              final rowNotes = _noteSequence.sublist(startIndex, endIndex);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rowNotes.map((noteName) {
                    final isLearned = _isNoteLearned(noteName);
                    final isOpened = _isNoteOpened(noteName);
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: (isLearned || isOpened) ? () async {
                          if (isLearned) {
                            // Learned note: Show statistics
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StatisticsPage(selectedNote: noteName),
                              ),
                            ).then((_) => _loadData()); // Refresh when returning
                          } else if (isOpened) {
                            // Opened but not learned: Start learning process
                            final completed = await LearningFlow.runLearning(context, noteName);
                            if (completed) {
                              await _loadData(); // Refresh when returning successfully
                            }
                          }
                        } : null,
                        child: _buildNoteButton(noteName, isLearned, isOpened),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayProgressSection() {
    if (_dayProgress == null) return const SizedBox.shrink();
    
    // Determine button text and next session info
    final buttonInfo = _getSessionButtonInfo();
    
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Session icons layout
            _buildSessionIconsLayout(),
            
            const SizedBox(height: 20),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Handle level completion
                  if (_userProgress?.synestheticPitch.levelComplete == true && _userProgress!.synestheticPitch.notesToLearn > 0) {
                    // Learn next note
                    await _learnNextNote();
                    return;
                  }
                  
                  // Regular session flow
                  final sessionType = _getSessionType();
                  if (sessionType != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionPage(sessionType: sessionType),
                      ),
                    ).then((_) async {
                      // Reload data when returning from session
                      await _loadData();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  buttonInfo['buttonText'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Status message
            Center(
              child: Text(
                buttonInfo['statusMessage'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionIconsLayout() {
    final morningCompleted = _dayProgress!.isMorningSessionCompleted();
    final instantSessions = _dayProgress!.dayPlan.instantSessionTimestamps;
    
    // Calculate row capacity based on available width for instant sessions
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = 32.0; // Card horizontal padding
    final morningIconWidth = 80.0; // Morning session icon width
    final spacing = 20.0; // Space between morning and instant sessions
    final availableWidth = screenWidth - cardPadding - morningIconWidth - spacing;
    final int rowCapacity = (availableWidth / 35).floor(); // 35px per icon, min 5, max 15
    Log.d('Screen width: $screenWidth, Available width: $availableWidth, Row capacity: $rowCapacity', tag: 'SynestheticMenu');
    final int totalRows = (instantSessions.length / rowCapacity).ceil();
    final int sessionsPerRow = (instantSessions.length / totalRows).ceil();
    
    // Build instant session icons organized by rows
    final instantSessionRows = <Widget>[];
    for (int row = 0; row < totalRows; row++) {
      final startIndex = row * sessionsPerRow;
      final endIndex = (startIndex + sessionsPerRow).clamp(0, instantSessions.length);
      final rowSessions = instantSessions.sublist(startIndex, endIndex);
      final currentSessionNumber = _dayProgress!.getCurrentInstantSession();
      
      final rowIcons = <Widget>[];
      for (int i = 0; i < rowSessions.length; i++) {
        final sessionIndex = startIndex + i + 1;
        final sessionTime = rowSessions[i];
        final isCompleted = _dayProgress!.isInstantSessionComplete(sessionIndex);
        final isMissed = _isSessionMissed(sessionIndex, sessionTime);
        final isCurrent = currentSessionNumber == sessionIndex;
        
        rowIcons.add(_buildInstantSessionIconWithTime(
          isCompleted, 
          isMissed, 
          isCurrent,
          sessionTime,
        ));
        
        if (i < rowSessions.length - 1) {
          rowIcons.add(const SizedBox(width: 6));
        }
      }
      
      instantSessionRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowIcons,
        ),
      );
      
      if (row < totalRows - 1) {
        instantSessionRows.add(const SizedBox(height: 12));
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big morning session icon
        _buildMorningSessionIcon(morningCompleted),
        
        const SizedBox(width: 20),
        
        // Instant session icons (organized in rows)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: instantSessionRows,
          ),
        ),
      ],
    );
  }

  Widget _buildMorningSessionIcon(bool completed) {
    final morningTime = _dayProgress!.dayPlan.morningSessionTimestamp;
    final morningColor = completed ? const Color.fromARGB(255, 0, 183, 61) : const Color.fromARGB(255, 226, 211, 2);
    
    return Container(
      width: 80,
      height: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            completed ? Icons.wb_sunny : Icons.wb_sunny_outlined,
            size: 40,
            color: morningColor,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(morningTime),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: morningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstantSessionIconWithTime(bool completed, bool missed, bool current, DateTime sessionTime) {
    IconData icon;
    Color iconColor;
    
    icon = Icons.music_note; // Music note icon (quarter note)
    if (completed) {
      iconColor = Colors.green[700]!;
    } else if (missed) {
      iconColor = const Color.fromARGB(255, 85, 85, 85);
    } else if (current) {
      iconColor = Colors.orange[700]!;
    } else {
      iconColor = const Color.fromARGB(255, 118, 164, 210);
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16, // Even smaller lightning icons
          color: iconColor,
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(sessionTime),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: iconColor,
          ),
        ),
        // Removed session number labels
      ],
    );
  }

  bool _isSessionMissed(int sessionIndex, DateTime sessionTime) {
    final instantSessions = _dayProgress!.dayPlan.instantSessionTimestamps;
    
    // User never misses morning session or last instant session
    if (sessionIndex == instantSessions.length) {
      return false;
    }
    
    // Check if this session is completed
    final isCompleted = _dayProgress!.isInstantSessionComplete(sessionIndex);
    if (isCompleted) {
      return false;
    }
    
    // Get current session that should be active
    final currentSessionNumber = _dayProgress!.getCurrentInstantSession();
    
    // If current session is ahead of this session, this session is missed
    if (currentSessionNumber != null && currentSessionNumber > sessionIndex) {
      return true;
    }
    
    return false;
  }

  Map<String, String> _getSessionButtonInfo() {
    // Check if level is complete and needs learning
    if (_userProgress?.synestheticPitch.levelComplete == true) {
      if (_userProgress!.synestheticPitch.notesToLearn > 0) {
        return {
          'buttonText': 'Complete Level!',
          'statusMessage': 'Learn ${_userProgress!.synestheticPitch.notesToLearn} more notes to advance to next level'
        };
      }
      // This case should not happen as we auto-advance when notesToLearn == 0
    }
    
    final morningCompleted = _dayProgress!.isMorningSessionCompleted();
    final instantSessions = _dayProgress!.dayPlan.instantSessionTimestamps;
    final morningTime = _dayProgress!.dayPlan.morningSessionTimestamp;
    
    // If morning session not completed
    if (!morningCompleted) {
      return {
        'buttonText': 'Start Morning Session',
        'statusMessage': 'Complete your morning session to unlock instant sessions'
      };
    }
    
    // Get current instant session that should be active
    final currentSessionNumber = _dayProgress!.getCurrentInstantSession();
    
    if (currentSessionNumber != null && !_dayProgress!.isInstantSessionComplete(currentSessionNumber)) {
        return {
          'buttonText': 'Start Instant Session',
          'statusMessage': 'Pass the instant session'
        };
    }
    
    // Practice mode - either no current session or current session is completed
    final tomorrowMorning = morningTime.add(const Duration(days: 1));
    String statusMessage;
    
    // Practice mode - find next upcoming session
    final isLastSession = currentSessionNumber != null && currentSessionNumber == instantSessions.length;
    
    if (isLastSession || instantSessions.isEmpty) {
      statusMessage = 'All complete today! Next morning session at ${_formatTime(tomorrowMorning)}';
    } else {
      statusMessage = 'Next session at ${_formatTime(instantSessions[currentSessionNumber ?? 0])}';
    }

    return {
      'buttonText': 'Practice Mode',
      'statusMessage': statusMessage
    };
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _learnNextNote() async {
    // Get the first note from note_sequence that is not in learned notes
    final learnedNotes = _userProgress!.synestheticPitch.learnedNotes;
    final settings = (await _settingsService.getSettings()).synestheticPitch;
    
    String? noteToLearn;
    for (final note in settings.noteSequence) {
      if (!learnedNotes.contains(note)) {
        noteToLearn = note;
        break;
      }
    }
    
    if (noteToLearn == null) {
      Log.e('No more notes to learn!', tag: 'SynestheticMenu');
      return;
    }
    
    // Start learning flow
    final completed = await LearningFlow.runLearning(context, noteToLearn);
    if (completed) {
      // Decrease notesToLearn
      final data = await _memoryService.ensureData();
      data.synestheticPitch.notesToLearn--;
      
      // If there are more notes to learn, start learning the next one
      if (data.synestheticPitch.notesToLearn > 0) {
        await _learnNextNote();
      } else {
        // All notes learned - automatically advance to next level
        await _memoryService.completeLevel();
      }
      
      // Reload data
      await _loadData();
    }
  }

  Widget _buildLevelCard() {
    return Card(
      elevation: 3,
      color: Colors.purple[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.purple[600], size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $_currentLevel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                Text(
                  'Synesthetic Pitch Training',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple[600],
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_noteScores.isNotEmpty) ...[
              Text(
                'Total: ${_noteScores.values.fold(0, (sum, score) => sum + score)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SessionType? _getSessionType() {
    if (_dayProgress == null) return null;
    
    final morningCompleted = _dayProgress!.isMorningSessionCompleted();
    
    // If morning session not completed, start morning session
    if (!morningCompleted) {
      return SessionType.morning;
    }
    
    // Get current instant session that should be active
    final currentSessionNumber = _dayProgress!.getCurrentInstantSession();
    
    // If there's a current instant session and it's not completed, start instant session
    if (currentSessionNumber != null && !_dayProgress!.isInstantSessionComplete(currentSessionNumber)) {
      return SessionType.instant;
    }
    
    // Otherwise, start practice session
    return SessionType.practice;
  }

  Widget _buildNoteButton(String noteName, bool isLearned, bool isOpened) {
    final score = _noteScores[noteName] ?? 0;
    final percentage = _maximumNoteScore > 0 ? (score / _maximumNoteScore).clamp(0.0, 1.0) : 0.0;
    final isReadyNote = isLearned && score >= _sufficientNoteScore;
    
    // Determine colors based on status and progress
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isLearned) {
      // Lerp from light green to darker green based on progress
      backgroundColor = Color.lerp(
        Colors.green[50]!,
        Colors.green[300]!,
        percentage,
      ) ?? Colors.green[50]!;
      borderColor = Color.lerp(
        Colors.green[400]!,
        Colors.green[700]!,
        percentage,
      ) ?? Colors.green[400]!;
      textColor = Colors.green[800]!;
    } else if (isOpened) {
      // Lerp from light blue to darker blue based on progress
      backgroundColor = Color.lerp(
        Colors.blue[50]!,
        Colors.blue[300]!,
        percentage,
      ) ?? Colors.blue[50]!;
      borderColor = Color.lerp(
        Colors.blue[400]!,
        Colors.blue[700]!,
        percentage,
      ) ?? Colors.blue[400]!;
      textColor = Colors.blue[800]!;
    } else {
      backgroundColor = Colors.grey[200]!;
      borderColor = Colors.grey[400]!;
      textColor = Colors.grey[500]!;
    }
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Note name for unopened notes, score for learned notes
          if (isLearned || isOpened)
            Text(
              noteName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            )
          else
            Text(
              noteName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          const SizedBox(height: 2),
          // Show score for learned notes or icon
          if (isReadyNote)
            Icon(Icons.check_circle, size: 12, color: Colors.green[600])
          else if (isLearned)
            Text(
              '${((score / _sufficientNoteScore) * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 8,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (isOpened)
            Icon(Icons.play_circle_outline, size: 12, color: Colors.blue[600])
          else
            Icon(Icons.lock, size: 12, color: Colors.grey[500]),
        ],
      ),
    );
  }
}
