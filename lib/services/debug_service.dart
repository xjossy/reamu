import 'logging_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/debug_config.dart';
import 'global_memory_service.dart';
import 'settings_service.dart';

class DebugService {
  static const String _userProgressFile = 'user_progress.json';
  static const String _sessionsFile = 'synesthetic_sessions.json';
  
  static DebugService? _instance;
  
  DebugService._();
  
  static DebugService get instance {
    _instance ??= DebugService._();
    return _instance!;
  }

  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;

  Future<Map<String, dynamic>> getAllUserData() async {
    if (!DebugConfig.debugMode) return {};

    final Map<String, dynamic> allData = {};

    try {
      // User Progress
      final userProgress = await _memoryService.ensureData();
      allData['user_progress'] = userProgress.toJson();

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
    Log.d('=== COMPLETE USER DATA DEBUG ===', tag: 'Debug');
    Log.d(jsonEncode(data), tag: 'Debug');
    Log.d('================================', tag: 'Debug');
  }

  Future<void> exportUserData() async {
    if (!DebugConfig.debugMode) return;

    final data = await getAllUserData();
    final jsonString = jsonEncode(data);
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/debug_export.json');
      await file.writeAsString(jsonString);
      Log.i('Debug data exported to: ${file.path}', tag: 'Debug');
    } catch (e, stackTrace) {
      Log.e('Error exporting debug data', error: e, stackTrace: stackTrace, tag: 'Debug');
    }
  }

  Future<void> resetAllData() async {
    if (!DebugConfig.enableDebugActions) return;

    try {
      // Use the memory service reset functionality
      await _memoryService.resetAllUserData();
      Log.i('All user data reset via debug service', tag: 'Debug');
    } catch (e, stackTrace) {
      Log.e('Error resetting data', error: e, stackTrace: stackTrace, tag: 'Debug');
    }
  }

  String formatJsonForDisplay(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
