import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../services/settings_service.dart';
import 'learn_page.dart';
import 'guess_page.dart';
import 'statistics_page.dart';
import 'learning_intro_page.dart';
import 'session_page.dart';

class SynestheticMenuPage extends StatefulWidget {
  const SynestheticMenuPage({super.key});

  @override
  State<SynestheticMenuPage> createState() => _SynestheticMenuPageState();
}

class _SynestheticMenuPageState extends State<SynestheticMenuPage> {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  Map<String, dynamic> _userProgress = {};
  List<String> _noteSequence = [];
  bool _isLoading = true;
  int _currentLevel = 1;
  Map<String, int> _noteScores = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await _memoryService.getUserProgress();
    final level = await _memoryService.getCurrentLevel();
    final noteScores = await _memoryService.getAllNoteScores();
    // Create keyboard order from C3 to C5
    final keyboardNotes = _generateKeyboardNotes();
    
    setState(() {
      _userProgress = progress;
      _noteSequence = keyboardNotes;
      _currentLevel = level;
      _noteScores = noteScores;
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

  bool _isNoteOpened(String noteName) {
    final openedNotes = List<String>.from(_userProgress['synestetic_pitch']['opened_notes']);
    return openedNotes.contains(noteName);
  }

  bool _canLearn() {
    final openedNotes = List<String>.from(_userProgress['synestetic_pitch']['opened_notes']);
    final learnedNotes = List<String>.from(_userProgress['synestetic_pitch']['leaned_notes']);
    return openedNotes.any((note) => !learnedNotes.contains(note));
  }

  @override
  Widget build(BuildContext context) {
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
        // Removed statistics action button - users can view stats by clicking learned notes
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Level Card
            _buildLevelCard(),
            const SizedBox(height: 16),
            
            // Main Action Buttons
            Column(
              children: [
                Row(
                  children: [
                    // Learn Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canLearn() ? () {
                          // Find the first unlearned note
                          final openedNotes = List<String>.from(_userProgress['synestetic_pitch']['opened_notes']);
                          final learnedNotes = List<String>.from(_userProgress['synestetic_pitch']['leaned_notes']);
                          final firstUnlearnedNote = openedNotes.firstWhere((note) => !learnedNotes.contains(note));
                          
                          // Navigate to learning intro page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LearningIntroPage(noteName: firstUnlearnedNote),
                            ),
                          ).then((_) => _loadData()); // Refresh when returning
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canLearn() ? Colors.teal : Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _canLearn() ? 4 : 0,
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.school, size: 32),
                            const SizedBox(height: 8),
                            const Text(
                              'Learn',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _canLearn() ? 'Practice opened notes' : 'No notes to learn',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Guess Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GuessPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.quiz, size: 32),
                            const SizedBox(height: 8),
                            const Text(
                              'Guess',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Test your knowledge',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Session Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SessionPage(),
                        ),
                      ).then((_) => _loadData()); // Refresh when returning
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.timeline, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Session',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Guided practice session',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
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
                        onTap: (isLearned || isOpened) ? () {
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LearningIntroPage(noteName: noteName),
                              ),
                            ).then((_) => _loadData()); // Refresh when returning
                          }
                        } : null,
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isLearned 
                                ? Colors.green[100] 
                                : isOpened 
                                    ? Colors.blue[100] 
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLearned 
                                  ? Colors.green[400]! 
                                  : isOpened 
                                      ? Colors.blue[400]! 
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
                                      : isOpened 
                                          ? Colors.blue[700] 
                                          : Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Icon(
                                isLearned 
                                    ? Icons.check_circle 
                                    : isOpened 
                                        ? Icons.play_circle_outline 
                                        : Icons.lock,
                                size: 12,
                                color: isLearned 
                                    ? Colors.green[600] 
                                    : isOpened 
                                        ? Colors.blue[600] 
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
            
            const SizedBox(height: 24),
            
            // Progress Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressItem(
                          'Opened',
                          _userProgress['synestetic_pitch']['opened_notes'].length,
                          _noteSequence.length,
                          Colors.blue,
                        ),
                        _buildProgressItem(
                          'Learned',
                          _userProgress['synestetic_pitch']['leaned_notes'].length,
                          _noteSequence.length,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int current, int total, Color color) {
    final percentage = total > 0 ? current / total : 0.0;
    
    // Get darker shade for text
    Color textColor = color;
    if (color == Colors.blue) {
      textColor = Colors.blue[700]!;
    } else if (color == Colors.green) {
      textColor = Colors.green[700]!;
    }
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current/$total',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
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
}
