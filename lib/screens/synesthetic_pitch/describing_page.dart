import '../../services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../../models/describing_question.dart';
import '../../services/midi_service.dart';
import '../../services/global_memory_service.dart';
import '../../services/settings_service.dart';
import '../../models/note.dart';
import 'statistics_page.dart';

class DescribingPage extends StatefulWidget {
  final String? selectedNote;
  
  const DescribingPage({super.key, this.selectedNote});

  @override
  State<DescribingPage> createState() => _DescribingPageState();
}

class _DescribingPageState extends State<DescribingPage> {
  final MidiService _midiService = MidiService();
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  bool _isLoaded = false;
  List<DescribingQuestion> _questions = [];
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
    await _setupCurrentNote();
  }

  void _autoPlayNote() {
    // Auto-play note when everything is ready
    if (_isLoaded && _questions.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _replayNote();
      });
    }
  }

  @override
  void didUpdateWidget(DescribingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _autoPlayNote();
  }

  Future<void> _initializeMidi() async {
    final success = await _midiService.initialize();
    setState(() {
      _isLoaded = success;
    });
  }

  Future<void> _loadUserProgress() async {
    _userProgress = await _memoryService.getUserProgress();
  }

  Future<void> _setupCurrentNote() async {
    if (widget.selectedNote != null) {
      // Use the selected note from Learn mode
      _currentNoteName = widget.selectedNote;
    } else {
      // Use the next note in sequence
      _currentNoteName = await _settingsService.getCurrentNote(_userProgress);
    }
    
    if (_currentNoteName != null) {
      // Convert note name to MIDI number
      final note = Note.fromName(_currentNoteName!);
      _currentNoteMidi = note.midiNumber;
      
      // Mark note as opened
      await _memoryService.markNoteAsOpened(_currentNoteName!);
      
      // Auto-play note after setup
      if (_isLoaded) {
        _autoPlayNote();
      }
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final yamlString = await rootBundle.loadString('assets/describing_questions.yaml');
      final yamlData = loadYaml(yamlString);
      final questionsData = yamlData['questions'] as List;
      
      setState(() {
        _questions = questionsData
            .map((q) => DescribingQuestion.fromJson(Map<String, dynamic>.from(q)))
            .toList();
      });
      // Auto-play note after questions are loaded
      _autoPlayNote();
    } catch (e, stackTrace) {
      Log.e('Error loading questions', error: e, stackTrace: stackTrace, tag: 'Describing');
      // Show error message if YAML fails
      setState(() {
        _questions = [];
      });
    }
  }

  void _replayNote() {
    if (_isLoaded) {
      _midiService.playNote(_currentNoteMidi);
    }
  }

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      // Save the answer if selected
      if (_selectedOption != null) {
        _answers[_questions[_currentQuestionIndex].key] = _selectedOption!;
      }
      
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
      });
      
      // Auto-play note for new question
      _autoPlayNote();
    } else {
      // Save the last answer if selected and finish
      if (_selectedOption != null) {
        _answers[_questions[_currentQuestionIndex].key] = _selectedOption!;
      }
      
      // Show summarization
      _showSummarization();
    }
  }

  void _skipQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
      });
      
      // Auto-play note for new question
      _autoPlayNote();
    } else {
      // Show summarization
      _showSummarization();
    }
  }

  void _showSummarization() async {
    if (_currentNoteName == null) return;
    
    // Save statistics for each answered question
    for (final entry in _answers.entries) {
      final question = _questions.firstWhere((q) => q.key == entry.key);
      await _memoryService.updateNoteStatistics(
        _currentNoteName!, 
        entry.key, 
        entry.value, 
        question.options
      );
    }
    
    // Mark note as learned if all questions answered
    if (_answers.length == _questions.length) {
      await _memoryService.markNoteAsLearned(_currentNoteName!);
    }
    
    // Navigate to statistics screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsPage(
          selectedNote: _currentNoteName!,
          sessionAnswers: _answers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

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
        shadowColor: Colors.grey[300],
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
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
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
                                activeColor: Colors.blue[700],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? Colors.blue[700]! : Colors.grey[400]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                tileColor: isSelected ? Colors.blue[50] : Colors.grey[50],
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
                              _currentQuestionIndex < _questions.length - 1 
                                  ? 'Skip' 
                                  : 'Skip & Finish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          
                          // Next Question Button
                          ElevatedButton(
                            onPressed: _selectedOption != null ? _nextQuestion : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedOption != null ? Colors.teal : Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _selectedOption != null ? 3 : 0,
                            ),
                            child: Text(
                              _currentQuestionIndex < _questions.length - 1 
                                  ? 'Next Question' 
                                  : 'Finish',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
