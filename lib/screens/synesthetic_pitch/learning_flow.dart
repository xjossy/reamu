import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../utils/confirmation_dialog.dart';
import 'learning_intro_page.dart';
import 'describing_page.dart';
import 'statistics_page.dart';
import 'page_wrapper.dart';

/// Manages the learning flow: LearningIntroPage -> DescribingPage -> StatisticsPage
/// 
/// Returns:
/// - true if the flow completes successfully (reaches StatisticsPage)
/// - false if the flow is interrupted before StatisticsPage
class LearningFlow {
  /// Runs the complete learning flow for a note
  /// 
  /// Args:
  /// - [context]: BuildContext for navigation
  /// - [noteName]: The note to learn
  /// 
  /// Returns:
  /// - true if flow completed successfully
  /// - false if user exited early
  static Future<bool> runLearning(BuildContext context, String noteName) async {
    final result = await Navigator.push<bool>(
      context,
      createLearningFlowRoute(noteName),
    );
    
    return result ?? false;
  }

  static MaterialPageRoute<bool> createLearningFlowRoute(String noteName) {
    return MaterialPageRoute(
      builder: (context) => _LearningFlowNavigator(noteName: noteName),
    );
  }
  
  /// Shows exit confirmation dialog
  static Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showConfirmationDialog(
      context: context,
      title: 'Exit Learning?',
      content: 'Are you sure you want to exit? Your progress will not be saved.',
      confirmText: 'Exit',
    );
  }
}

/// Widget that contains its own Navigator for managing the learning flow
class _LearningFlowNavigator extends StatefulWidget {
  final String noteName;
  
  const _LearningFlowNavigator({required this.noteName});
  
  @override
  State<_LearningFlowNavigator> createState() => _LearningFlowNavigatorState();
}

class _LearningFlowNavigatorState extends State<_LearningFlowNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  
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
        
        final shouldPop = await LearningFlow._showExitConfirmation(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/intro':
              return MaterialPageRoute(
                builder: (context) => LearningIntroPage(
                  noteName: widget.noteName,
                  onStartLearning: () {
                    _navigatorKey.currentState!.pushNamed('/describing');
                  },
                ),
              );
            case '/describing':
              return MaterialPageRoute(
                builder: (context) => DescribingPage(
                  selectedNote: widget.noteName,
                  showNoteName: true,
                  doNext: (answers) async {
                    // Save statistics and mark note as learned before proceeding
                    await _memoryService.updateNotesStatistics(widget.noteName, answers);
                    await _memoryService.markNoteAsLearned(widget.noteName);
                    
                    // Navigate to statistics page
                    _navigatorKey.currentState!.pushNamed('/statistics', arguments: answers);
                  },
                ),
              );
            case '/statistics':
              final answers = settings.arguments as Map<String, String>;
              
              return MaterialPageRoute(
                builder: (context) => PageWrapper(
                  onPop: _onCompleteFlow,
                  child: StatisticsPage(
                    selectedNote: widget.noteName,
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
}

