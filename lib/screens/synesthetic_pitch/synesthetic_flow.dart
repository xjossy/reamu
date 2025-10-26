import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../services/settings_service.dart';
import '../../services/logging_service.dart';
import '../../models/user_progress_data.dart';
import 'synesthetic_menu_page.dart';
import 'learning_flow.dart';
import 'personalization_wizard_page.dart';
import '../../models/app_settings.dart';

/// Manages the synesthetic pitch flow: checks state and shows appropriate page
/// 
/// Flow logic:
/// 1. If user hasn't learned enough notes -> show LearningFlow
/// 2. If user hasn't completed personalization -> show PersonalizationWizardPage
/// 3. Otherwise -> show SynestheticMenuPage
class SynestheticFlow {
  static final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  static final SettingsService _settingsService = SettingsService.instance;
  
  /// Runs the synesthetic flow
  static Future<void> run(BuildContext context) async {
    final settings = await _settingsService.getSettings();
    
    while (context.mounted) {
      final progress = await _memoryService.ensureData();
      
      // Step 1: Check if user needs to learn notes
      final nextNote = _getNextNoteToLearn(progress, settings);
      if (nextNote != null) {
        Log.i('📚 User needs to learn note: $nextNote');
        final completed = await LearningFlow.runLearning(context, nextNote);
        if (!completed) {
          // User exited early from learning, exit the whole flow
          break;
        }
        // Continue to check next state
        continue;
      }
      
      // Step 2: Check if user needs to complete personalization
      final needsPersonalization = _needsPersonalization(progress);
      if (needsPersonalization) {
        Log.i('⚙️ User needs to complete personalization');
        final completed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const PersonalizationWizardPage(),
          ),
        );
        
        if (completed == true) {
          // Reload data after completing personalization
          continue;
        } else {
          // User cancelled personalization, exit the flow
          break;
        }
      }
      
      // Step 3: All setup complete - show menu
      Log.i('✅ User setup complete, showing menu');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SynestheticMenuPage(),
        ),
      );
      
      // If user navigated back from menu, exit the flow
      break;
    }
  }
  
  /// Gets the next note that user needs to learn
  static String? _getNextNoteToLearn(UserProgressData userProgress, AppSettings settings) {
    final synestheticSettings = settings.synestheticPitch;
    final startWithNotes = synestheticSettings.startWithNotes ?? 4;
    
    final learnedNotes = userProgress.synestheticPitch.learnedNotes;
    
    // Check if user needs to learn more notes
    if (learnedNotes.length >= startWithNotes) {
      return null;
    }
    
    // Get the next note to learn
    final noteSequence = synestheticSettings.noteSequence ?? [];
    
    // Find first unopened note or first unlearned note
    for (final note in noteSequence) {
      final noteName = note;
      if (!learnedNotes.contains(noteName)) {
        return noteName;
      }
    }
    
    return null;
  }
  
  /// Checks if user needs to complete personalization
  static bool _needsPersonalization(UserProgressData userProgress) {
    final personalization = userProgress.synestheticPitch.personalization;
    return personalization == null || !personalization.isCompleted;
  }
}

