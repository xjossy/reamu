import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/debug_config.dart';
import 'global_memory_service.dart';
import 'session_service.dart';
import 'settings_service.dart';

class DebugService {
  static const String _userProgressFile = 'user_progress.json';
  static const String _sessionsFile = 'synesthetic_sessions.json';
  static const String _settingsFile = 'global_settings.yaml';
  
  static DebugService? _instance;
  
  DebugService._();
  
  static DebugService get instance {
    _instance ??= DebugService._();
    return _instance!;
  }

  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SessionService _sessionService = SessionService.instance;
  final SettingsService _settingsService = SettingsService.instance;

  Future<Map<String, dynamic>> getAllUserData() async {
    if (!DebugConfig.debugMode) return {};

    final Map<String, dynamic> allData = {};

    try {
      // User Progress
      final userProgress = await _memoryService.getUserProgress();
      allData['user_progress'] = userProgress;

      // Sessions
      final sessions = await _sessionService.getSessionHistory();
      allData['sessions'] = sessions.map((s) => s.toJson()).toList();

      // Current Session
      final currentSession = await _sessionService.getCurrentSession();
      allData['current_session'] = currentSession?.toJson();

      // Level and Scores
      allData['current_level'] = await _memoryService.getCurrentLevel();
      allData['note_scores'] = await _memoryService.getAllNoteScores();

      // Settings
      allData['session_length'] = await _settingsService.getSessionLengthMinutes();

      // Raw file contents
      allData['raw_files'] = await _getRawFileContents();

    } catch (e) {
      allData['error'] = e.toString();
    }

    return allData;
  }

  Future<Map<String, String>> _getRawFileContents() async {
    final Map<String, String> files = {};
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // User progress file
      final userProgressFile = File('${directory.path}/$_userProgressFile');
      if (await userProgressFile.exists()) {
        files['user_progress.json'] = await userProgressFile.readAsString();
      }

      // Sessions file
      final sessionsFile = File('${directory.path}/$_sessionsFile');
      if (await sessionsFile.exists()) {
        files['sessions.json'] = await sessionsFile.readAsString();
      }

      // Settings file (from assets)
      // Note: This would need to be read from assets, but for now we'll skip it
      
    } catch (e) {
      files['error'] = e.toString();
    }
    
    return files;
  }

  Future<void> printAllData() async {
    if (!DebugConfig.debugLogs) return;

    final data = await getAllUserData();
    print('=== COMPLETE USER DATA DEBUG ===');
    print(jsonEncode(data));
    print('================================');
  }

  Future<void> exportUserData() async {
    if (!DebugConfig.debugMode) return;

    final data = await getAllUserData();
    final jsonString = jsonEncode(data);
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/debug_export.json');
      await file.writeAsString(jsonString);
      print('Debug data exported to: ${file.path}');
    } catch (e) {
      print('Error exporting debug data: $e');
    }
  }

  Future<void> resetAllData() async {
    if (!DebugConfig.enableDebugActions) return;

    try {
      // Reset user progress
      await _memoryService.resetUserProgress();
      
      // Clear sessions (we'd need to add this method to SessionService)
      print('All user data reset');
    } catch (e) {
      print('Error resetting data: $e');
    }
  }

  String formatJsonForDisplay(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
