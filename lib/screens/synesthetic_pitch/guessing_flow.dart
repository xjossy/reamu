import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/global_config_service.dart';
import '../../services/settings_service.dart';
import 'guess_intro_page.dart';
import 'describing_page.dart';
import 'guess_note_selection_page.dart';
import 'statistics_page.dart';
import 'comparative_stats_page.dart';
import 'page_wrapper.dart';

/// Manages the guessing flow: GuessIntroPage -> DescribingPage -> GuessNoteSelectionPage -> Statistics
/// 
/// Flow logic:
/// 1. Show guess intro page
/// 2. Show describing page for target note (without showing note name)
/// 3. Show note selection page
/// 4. Show result dialog and navigate to appropriate stats page
class GuessingFlow {
  
  /// Runs the guessing flow for a note
  /// 
  /// Args:
  /// - [context]: BuildContext for navigation
  /// - [targetNote]: The note that user should guess
  /// - [questionCount]: Number of questions to ask (defaults to guess_questions from settings)
  /// - [onNoteSelected]: Callback when note is selected (receives guessedNote and isCorrect)
  /// 
  /// Returns:
  /// - true if flow completed successfully
  /// - false if user exited early
  static Future<bool> runGuessing({
    required BuildContext context,
    required String targetNote,
    int? questionCount,
    Function(String selectedNote, bool isCorrect)? onNoteSelected,
  }) async {
    // Get question count from settings if not provided
    final settingsService = SettingsService.instance;
    final finalQuestionCount = questionCount ?? await settingsService.getGuessQuestionsCount();
    
    final result = await Navigator.push<bool>(
      context,
      _createGuessingFlowRoute(
        targetNote: targetNote,
        questionCount: finalQuestionCount,
        onNoteSelected: onNoteSelected,
      ),
    );
    
    return result ?? false;
  }
  
  static MaterialPageRoute<bool> _createGuessingFlowRoute({
    required String targetNote,
    required int questionCount,
    Function(String selectedNote, bool isCorrect)? onNoteSelected,
  }) {
    return MaterialPageRoute(
      builder: (context) => _GuessingFlowNavigator(
        targetNote: targetNote,
        questionCount: questionCount,
        onNoteSelected: onNoteSelected,
      ),
    );
  }
}

/// Widget that contains its own Navigator for managing the guessing flow
class _GuessingFlowNavigator extends StatefulWidget {
  final String targetNote;
  final int questionCount;
  final Function(String selectedNote, bool isCorrect)? onNoteSelected;
  
  const _GuessingFlowNavigator({
    required this.targetNote,
    required this.questionCount,
    this.onNoteSelected,
  });
  
  @override
  State<_GuessingFlowNavigator> createState() => _GuessingFlowNavigatorState();
}

class _GuessingFlowNavigatorState extends State<_GuessingFlowNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  List<String>? _selectedQuestions;
  
  void _onCompleteFlow() {
    // Notify parent that flow completed successfully
    Navigator.of(context).pop(true);
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Allow exit without confirmation for guessing flow
        if (context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/intro':
              return MaterialPageRoute(
                builder: (context) => GuessIntroPage(
                  questionCount: widget.questionCount,
                  targetNoteName: widget.targetNote,
                  onStartGuessing: () async {
                    // Get random questions and navigate to describing page
                    final questions = await _getRandomQuestions();
                    _navigatorKey.currentState!.pushNamed('/describing', arguments: questions);
                  },
                ),
              );
            case '/describing':
              final questions = settings.arguments as List<String>;
              return MaterialPageRoute(
                builder: (context) => DescribingPage(
                  selectedNote: widget.targetNote,
                  questionsList: questions,
                  showNoteName: false,
                  doNext: (answers) async {
                    // Navigate to note selection page
                    _navigatorKey.currentState!.pushNamed('/selection', arguments: answers);
                  },
                ),
              );
            case '/selection':
              final answers = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (context) => GuessNoteSelectionPage(
                  actualNoteName: widget.targetNote,
                  sessionAnswers: answers,
                  onNoteSelected: (guessedNote, isCorrect) async {
                    // Show result dialog
                    await _showResultDialog(context, isCorrect, widget.targetNote);
                    
                    // Navigate to appropriate stats page
                    if (isCorrect) {
                      _navigatorKey.currentState!.pushNamed('/correct', arguments: answers);
                    } else {
                      _navigatorKey.currentState!.pushNamed('/incorrect', arguments: {
                        'guessedNote': guessedNote,
                        'answers': answers,
                      });
                    }
                    
                    // Call parent callback if provided
                    widget.onNoteSelected?.call(guessedNote, isCorrect);
                  },
                ),
              );
            case '/correct':
              final answers = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (context) => PageWrapper(
                  onPop: _onCompleteFlow,
                  child: StatisticsPage(
                    selectedNote: widget.targetNote,
                    sessionAnswers: answers,
                  ),
                ),
              );
            case '/incorrect':
              final args = settings.arguments as Map<String, dynamic>;
              final guessedNote = args['guessedNote'] as String;
              final answers = args['answers'] as Map<String, String>;
              return MaterialPageRoute(
                builder: (context) => PageWrapper(
                  onPop: _onCompleteFlow,
                  child: ComparativeStatsPage(
                    guessedNoteName: guessedNote,
                    actualNoteName: widget.targetNote,
                    sessionAnswers: answers,
                  ),
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Unknown route')),
                ),
              );
          }
        },
        initialRoute: '/intro',
      ),
    );
  }
  
  Future<List<String>> _getRandomQuestions() async {
    if (_selectedQuestions != null) {
      return _selectedQuestions!;
    }
    
    final configService = GlobalConfigService.instance;
    final config = await configService.value();
    final random = Random();
    final questions = config.getAllQuestions().map((question) => question.key).toList();
    final questionCount = widget.questionCount.clamp(1, questions.length);
    
    // Shuffle and take first N questions
    questions.shuffle(random);
    _selectedQuestions = questions.take(questionCount).toList();
    
    return _selectedQuestions!;
  }
  
  Future<void> _showResultDialog(BuildContext context, bool isCorrect, String actualNote) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isCorrect ? 'Correct! 🎉' : 'Incorrect',
          style: TextStyle(
            color: isCorrect ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The note was: $actualNote',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

