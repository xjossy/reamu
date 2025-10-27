import 'package:flutter/material.dart';
import 'package:reamu/services/global_config_service.dart';
import '../../services/global_memory_service.dart';
import '../../models/user_progress_data.dart';
import '../../models/describing_question.dart';
import '../../models/note.dart';
import '../../mixins/midi_cleanup_mixin.dart';
import '../../widgets/hold_to_play_button.dart';
import '../../widgets/piano_keyboard.dart';
import '../../services/settings_service.dart';

class StatisticsPage extends StatefulWidget {
  final String selectedNote;
  final Map<String, String>? sessionAnswers; // Optional - only when coming from learning session
  
  const StatisticsPage({
    super.key, 
    required this.selectedNote,
    this.sessionAnswers,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with MidiCleanupMixin {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  UserProgressData? _userProgress;
  late List<DescribingQuestion> _questions;
  bool _isLoading = true;
  int? _currentNoteMidi;
  int _sufficientNoteScore = 100;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await _memoryService.ensureData();
    
    final note = Note.fromName(widget.selectedNote);
    final config = await GlobalConfigService.instance.value();
    final settings = await SettingsService.instance.getSettings();
    
    setState(() {
      _userProgress = progress;
      _currentNoteMidi = note.midiNumber;
      _questions = config.questions;
      _isLoading = false;
      _sufficientNoteScore = settings.synestheticPitch.sufficientNoteScore;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Statistics',
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

    final noteStats = _userProgress?.synestheticPitch.noteStatistics[widget.selectedNote];
    final hasStatistics = noteStats != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Note Statistics',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_currentNoteMidi != null)
            HoldToPlayButton(
              midiNote: _currentNoteMidi!,
              child: IconButton(
                icon: const Icon(Icons.music_note),
                onPressed: () {}, // Required but not used (gesture handled by wrapper)
                tooltip: 'Play Note (Hold)',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.teal[50]!, Colors.teal[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    if (widget.sessionAnswers != null) ...[
                      const Text(
                        'Session Complete!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Note: ${widget.selectedNote}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_currentNoteMidi != null)
                          HoldToPlayButton(
                            midiNote: _currentNoteMidi!,
                            child: Icon(Icons.play_circle, color: Colors.teal[700], size: 40),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Overall Statistics Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score and Guess Statistics
                    if (hasStatistics) ...[
                      _buildStatisticsOverview(noteStats),
                      const SizedBox(height: 24),
                    ],
                    
                    // Piano Keyboard
                    Center(
                      child: PianoKeyboard(
                        targetNote: widget.selectedNote,
                        width: 300,
                        keyHeight: 80,
                      ),
                    ),
                    
                    // Misses To Statistics
                    if (hasStatistics) ...[
                      const SizedBox(height: 24),
                      _buildMissesStatistics(noteStats),
                    ],
                  ],
                ),
              ),
            ),

            if (hasStatistics) ...[
              // Statistics for each question (filter out unanswered questions)
              ...(_questions.where((question) {
                final noteStats = _userProgress?.synestheticPitch.noteStatistics[widget.selectedNote];
                final questionStatsRaw = noteStats?.questions[question.key];
                return questionStatsRaw != null; // Only show questions that have been answered
              }).map((question) => _buildQuestionStats(question))),
            ] else ...[
              // No statistics yet
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Statistics Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete learning sessions to see statistics here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Back to Menu Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop back to synesthetic menu (mode menu)
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStats(DescribingQuestion question) {
    final noteStats = _userProgress?.synestheticPitch.noteStatistics[widget.selectedNote];
    final questionStatsRaw = noteStats?.questions[question.key];
    final questionStats = questionStatsRaw != null ? Map<String, int>.from(questionStatsRaw) : null;
    
    // Get current session answer if this is from a learning session
    final currentAnswer = widget.sessionAnswers?[question.key];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress bars for each option (filter out options with 0 count)
            ...question.options.where((option) {
              final count = questionStats?[option.key] ?? 0;
              return count > 0; // Only show options that have been selected at least once
            }).map((option) {
              final count = questionStats?[option.key] ?? 0;
              final total = questionStats?.values.fold<int>(0, (sum, val) => sum + val) ?? 0;
              final percentage = total > 0 ? count / total : 0.0;
              final isCurrentAnswer = option.key == currentAnswer;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option.nameEn,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentAnswer ? FontWeight.bold : FontWeight.w500,
                            color: isCurrentAnswer ? Colors.teal[700] : Colors.black87,
                          ),
                        ),
                        Text(
                          '$count time${count != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrentAnswer ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentAnswer ? Colors.teal[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentAnswer ? Colors.teal[600]! : Colors.grey[600]!,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsOverview(NoteStatistics? noteStats) {
    if (noteStats == null) return const SizedBox.shrink();
    
    final score = _userProgress?.synestheticPitch.noteScores[widget.selectedNote] ?? 0;
    final guessStats = _userProgress?.synestheticPitch.getStatisticsFor(widget.selectedNote);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score display
        Card(
          elevation: 0,
          color: Colors.teal[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.teal[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.teal[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Score: $score/$_sufficientNoteScore',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissesStatistics(NoteStatistics? noteStats) {
    if (noteStats == null) return const SizedBox.shrink();
    
    final guessStats = _userProgress?.synestheticPitch.getStatisticsFor(widget.selectedNote);
    
    if (guessStats == null || (guessStats.missesTo.isEmpty && guessStats.correctGuesses == 0)) {
      return Center(
        child: Text(
          'No guess statistics yet',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    // Sort misses by frequency (descending)
    final sortedMisses = guessStats.missesTo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final totalGuesses = guessStats.correctGuesses + guessStats.incorrectGuesses;
    final correctPercentage = totalGuesses > 0 ? guessStats.correctGuesses / totalGuesses : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guess statistics header
        Text(
          'Guess statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        if (guessStats.correctGuesses > 0) ...[
          // Correct guesses progress bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Correct',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${guessStats.correctGuesses} time${guessStats.correctGuesses != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: correctPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green[600]!,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (totalGuesses > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${(correctPercentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Progress bars for each confused note
        ...sortedMisses.map((entry) {
          final noteName = entry.key;
          final count = entry.value;
          final percentage = totalGuesses > 0 ? count / totalGuesses : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      noteName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '$count time${count != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey[600]!,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (totalGuesses > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
