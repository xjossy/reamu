import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../../models/describing_question.dart';
import '../../services/midi_service.dart';
import '../../services/global_memory_service.dart';
import '../../services/settings_service.dart';
import '../../models/note.dart';
import '../../utils/weighted_random.dart';
import 'guess_note_selection_page.dart';
import '../../services/session_service.dart';

class GuessingPage extends StatefulWidget {
  final int questionCount;
  final String? sessionId;
  final String? targetNote; // If provided, use this specific note instead of random
  
  const GuessingPage({
    super.key, 
    required this.questionCount,
    this.sessionId,
    this.targetNote,
  });

  @override
  State<GuessingPage> createState() => _GuessingPageState();
}

class _GuessingPageState extends State<GuessingPage> {
  final MidiService _midiService = MidiService();
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  final SessionService _sessionService = SessionService.instance;
  bool _isLoaded = false;
  List<DescribingQuestion> _allQuestions = [];
  List<DescribingQuestion> _selectedQuestions = [];
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  Map<String, String> _answers = {};
  String? _currentNoteName;
  int _currentNoteMidi = 60;
  Map<String, dynamic> _userProgress = {};

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeMidi();
    await _loadUserProgress();
    await _loadQuestions();
    await _setupNote();
  }

  void _autoPlayNote() {
    if (_isLoaded && _selectedQuestions.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _replayNote();
      });
    }
  }

  @override
  void didUpdateWidget(GuessingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _autoPlayNote();
  }

  Future<void> _initializeMidi() async {
    final success = await _midiService.initialize();
    setState(() {
      _isLoaded = success;
    });
    if (success) {
      _autoPlayNote();
    }
  }

  Future<void> _loadUserProgress() async {
    final progress = await _memoryService.getUserProgress();
    setState(() {
      _userProgress = progress;
    });
  }

  Future<void> _loadQuestions() async {
    try {
      final yamlString = await rootBundle.loadString('assets/describing_questions.yaml');
      final yamlData = loadYaml(yamlString);
      final questionsData = yamlData['questions'] as List;
      
      _allQuestions = questionsData
          .map((q) => DescribingQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList();
      
      // Select random questions
      _selectRandomQuestions();
      _autoPlayNote();
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _allQuestions = [];
        _selectedQuestions = [];
      });
    }
  }

  void _selectRandomQuestions() {
    final random = Random();
    final questionCount = widget.questionCount.clamp(1, _allQuestions.length);
    
    // Shuffle and take first N questions
    final shuffled = List<DescribingQuestion>.from(_allQuestions)..shuffle(random);
    setState(() {
      _selectedQuestions = shuffled.take(questionCount).toList();
    });
  }

  Future<void> _setupNote() async {
    String selectedNote;
    
    // Use target note if provided (from session), otherwise select random
    if (widget.targetNote != null) {
      selectedNote = widget.targetNote!;
    } else {
      final learnedNotes = List<String>.from(_userProgress['synestetic_pitch']['leaned_notes']);
      
      if (learnedNotes.isEmpty) {
        // No learned notes, can't play guess mode
        return;
      }
      
      // For now, all notes have weight 1
      final weights = List<double>.filled(learnedNotes.length, 1.0);
      selectedNote = weightedRandomChoice(learnedNotes, weights);
    }
    
    final note = Note.fromName(selectedNote);
    setState(() {
      _currentNoteName = selectedNote;
      _currentNoteMidi = note.midiNumber;
    });
    
    if (_isLoaded) {
      _autoPlayNote();
    }
  }

  void _replayNote() {
    _midiService.playNote(_currentNoteMidi);
  }

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _nextQuestion() async {
    if (_selectedOption == null) return;
    
    // Save answer
    final currentQuestion = _selectedQuestions[_currentQuestionIndex];
    _answers[currentQuestion.key] = _selectedOption!;
    
    if (_currentQuestionIndex < _selectedQuestions.length - 1) {
      // Move to next question
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
      });
      _autoPlayNote();
    } else {
      // All questions answered - update statistics and show note selection
      await _updateStatistics();
      
      // Navigate to note selection page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GuessNoteSelectionPage(
            actualNoteName: _currentNoteName!,
            sessionAnswers: _answers,
            sessionId: widget.sessionId,
          ),
        ),
      );
    }
  }

  Future<void> _updateStatistics() async {
    // Update statistics for the guessed note
    for (final entry in _answers.entries) {
      final questionKey = entry.key;
      final selectedOption = entry.value;
      
      // Find the question to get all options
      final question = _selectedQuestions.firstWhere((q) => q.key == questionKey);
      
      await _memoryService.updateNoteStatistics(
        _currentNoteName!,
        questionKey,
        selectedOption,
        question.options
      );
    }
  }

  void _skipQuestion() {
    if (_currentQuestionIndex < _selectedQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
      });
      _autoPlayNote();
    } else {
      // Skip last question and go to note selection
      _updateStatistics().then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GuessNoteSelectionPage(
              actualNoteName: _currentNoteName!,
              sessionAnswers: _answers,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _selectedQuestions.isEmpty || _currentNoteName == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _selectedQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _selectedQuestions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Guess Mode',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        shadowColor: Colors.grey[300],
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Replay Note Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton.icon(
                onPressed: _replayNote,
                icon: const Icon(Icons.volume_up, color: Colors.black87),
                label: const Text(
                  'Replay Note',
                  style: TextStyle(
                    color: Colors.black87, 
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            
            // Main Content Card
            Expanded(
              child: Card(
                elevation: 4,
                shadowColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Describe the Note',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Progress Bar
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${_selectedQuestions.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Question
                      Text(
                        currentQuestion.question,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Options
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentQuestion.options.length,
                          itemBuilder: (context, index) {
                            final option = currentQuestion.options[index];
                            final isSelected = _selectedOption == option;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: RadioListTile<String>(
                                value: option,
                                groupValue: _selectedOption,
                                onChanged: (value) => _selectOption(value!),
                                title: Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                activeColor: Colors.purple[700],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? Colors.purple[700]! : Colors.grey[400]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                tileColor: isSelected ? Colors.purple[50] : Colors.grey[50],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Skip Button
                          TextButton(
                            onPressed: _skipQuestion,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                            ),
                            child: Text(
                              _currentQuestionIndex < _selectedQuestions.length - 1 
                                  ? 'Skip' 
                                  : 'Skip & Finish',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          
                          // Next Button
                          ElevatedButton(
                            onPressed: _selectedOption != null ? _nextQuestion : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[400],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _currentQuestionIndex < _selectedQuestions.length - 1 
                                  ? 'Next Question' 
                                  : 'Finish',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

