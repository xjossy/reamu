import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../../services/global_memory_service.dart';
import '../../models/describing_question.dart';
import '../../models/note.dart';
import '../../mixins/midi_cleanup_mixin.dart';
import '../../widgets/hold_to_play_button.dart';

class ComparativeStatsPage extends StatefulWidget {
  final String guessedNoteName;
  final String actualNoteName;
  final Map<String, String> sessionAnswers;
  final String? sessionId;

  const ComparativeStatsPage({
    super.key,
    required this.guessedNoteName,
    required this.actualNoteName,
    required this.sessionAnswers,
    this.sessionId,
  });

  @override
  State<ComparativeStatsPage> createState() => _ComparativeStatsPageState();
}

class _ComparativeStatsPageState extends State<ComparativeStatsPage> with MidiCleanupMixin {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  Map<String, dynamic> _userProgress = {};
  List<DescribingQuestion> _questions = [];
  bool _isLoading = true;
  int? _guessedNoteMidi;
  int? _actualNoteMidi;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadQuestions();
    
    final progress = await _memoryService.getUserProgress();
    final guessedNote = Note.fromName(widget.guessedNoteName);
    final actualNote = Note.fromName(widget.actualNoteName);
    
    setState(() {
      _userProgress = progress;
      _guessedNoteMidi = guessedNote.midiNumber;
      _actualNoteMidi = actualNote.midiNumber;
      _isLoading = false;
    });
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
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _questions = [];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Comparison',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Answer Comparison',
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
            // Header with note comparison
            Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Your Answer
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Your Answer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.guessedNoteName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          HoldToPlayButton(
                            midiNote: _guessedNoteMidi!,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[600],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.volume_up, size: 18, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Listen (Hold)',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Divider
                    Container(
                      width: 2,
                      height: 100,
                      color: Colors.grey[300],
                    ),
                    
                    // Correct Answer
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Correct',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.actualNoteName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          HoldToPlayButton(
                            midiNote: _actualNoteMidi!,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.volume_up, size: 18, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Listen (Hold)',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Questions comparison
            ..._buildQuestionComparisons(),
            
            const SizedBox(height: 32),
            
            // Back to Menu Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.sessionId != null) {
                    // Return to session page
                    Navigator.of(context).popUntil((route) {
                      return route.settings.name == '/session' ||
                             (route is MaterialPageRoute && route.builder.toString().contains('SessionPage')) ||
                             route.isFirst;
                    });
                  } else {
                    // Pop all pages to go back to synesthetic menu
                    Navigator.of(context).popUntil((route) {
                      return route.settings.name == '/synesthetic_menu' || 
                             (route is MaterialPageRoute && route.builder.toString().contains('SynestheticMenuPage')) ||
                             route.isFirst;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.sessionId != null ? 'Back to Session' : 'Back to Menu',
                  style: const TextStyle(
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

  List<Widget> _buildQuestionComparisons() {
    // Filter questions that were answered in this session
    final answeredQuestions = _questions.where((q) => widget.sessionAnswers.containsKey(q.key)).toList();
    
    return answeredQuestions.map((question) {
      return _buildQuestionComparison(question);
    }).toList();
  }

  Widget _buildQuestionComparison(DescribingQuestion question) {
    final guessedNoteStats = _userProgress['synestetic_pitch']['note_statistics'][widget.guessedNoteName];
    final actualNoteStats = _userProgress['synestetic_pitch']['note_statistics'][widget.actualNoteName];
    
    final guessedQuestionStatsRaw = guessedNoteStats?['questions']?[question.key];
    final actualQuestionStatsRaw = actualNoteStats?['questions']?[question.key];
    
    final guessedQuestionStats = guessedQuestionStatsRaw != null ? List<int>.from(guessedQuestionStatsRaw) : null;
    final actualQuestionStats = actualQuestionStatsRaw != null ? List<int>.from(actualQuestionStatsRaw) : null;
    
    final currentAnswer = widget.sessionAnswers[question.key];

    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            
            // Options comparison
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              
              final guessedCount = guessedQuestionStats != null && index < guessedQuestionStats.length 
                  ? guessedQuestionStats[index] 
                  : 0;
              final actualCount = actualQuestionStats != null && index < actualQuestionStats.length 
                  ? actualQuestionStats[index] 
                  : 0;

              final total = guessedCount + actualCount;
              
              final guessedPercentage = total > 0 ? guessedCount / total : 0.0;
              final actualPercentage = total > 0 ? actualCount / total : 0.0;
              
              final isCurrentAnswer = option == currentAnswer;
              
              // Only show if at least one note has this option selected
              if (guessedCount == 0 && actualCount == 0) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Option name
                    Row(
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentAnswer ? FontWeight.bold : FontWeight.w600,
                            color: isCurrentAnswer ? Colors.purple[700] : Colors.black87,
                          ),
                        ),
                        if (isCurrentAnswer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Your choice',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Comparative bars
                    Container(
                      height: 24,
                      width: double.infinity,
                      child: Row(
                        children: [
                          // Orange bar (guessed note)
                          if (guessedCount > 0)
                            Expanded(
                              flex: (guessedPercentage * 100).round(),
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.orange[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '$guessedCount time${guessedCount != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          
                          // Green bar (actual note)
                          if (actualCount > 0)
                            Expanded(
                              flex: (actualPercentage * 100).round(),
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.green[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '$actualCount time${actualCount != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

