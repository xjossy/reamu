import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'logging_service.dart';

/// Manages storage operations with automatic backups and thread-safe versioning
class StorageManager {
  final String fileName;
  int _version = 0;
  int? _savedVersion;
  final Completer<void> _mutex = Completer();

  StorageManager({required this.fileName}) {
    _mutex.complete(); // Initialize as unlocked
  }

  /// Acquire lock by waiting for mutex
  Future<void> _acquireLock() async {
    await _mutex.future;
  }

  /// Release lock by creating new completer
  void _releaseLock() {
    _mutex.complete();
  }

  /// Load data from file, falling back to backup if needed
  /// Returns parsed JSON object or throws exception if both fail
  Future<Map<String, dynamic>> loadData() async {
    // Try to load from primary file
    final primaryData = await _tryLoadFromFile(fileName);
    if (primaryData != null) {
      return primaryData;
    }

    // Try backup file
    Log.w('Primary file failed, trying backup', tag: 'StorageManager');
    final backupData = await _tryLoadFromFile(_getBackupFileName(fileName));
    if (backupData != null) {
      return backupData;
    }

    throw Exception('Failed to load data from both primary and backup files');
  }

  /// Try to load and parse JSON from a single file
  /// Returns null if file doesn't exist or JSON is invalid
  Future<Map<String, dynamic>?> _tryLoadFromFile(String fileName) async {
    try {
      final file = await _getFile(fileName);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      Log.d('Loaded and parsed data from $fileName', tag: 'StorageManager');
      return json;
    } catch (e) {
      Log.w('Failed to load/parse $fileName: $e', tag: 'StorageManager');
      return null;
    }
  }

  /// Save data asynchronously with automatic backup and thread-safety
  void saveData(Map<String, dynamic> data) {
    final jsonContent = jsonEncode(data);
    _saveDataAsync(jsonContent, ++_version);
  }

  /// Internal async save with backup and versioning
  Future<void> _saveDataAsync(String jsonContent, int version) async {
    // Run in background without waiting
    unawaited(
      () async {
        try {
          // Acquire lock
          await _acquireLock();
          
          // Check if this version is already saved
          if (_savedVersion != null && _savedVersion! >= version) {
            _releaseLock();
            return;
          }
          
          // Mark as saving
          _savedVersion = version;
          
          // Perform the actual save
          final file = await _getFile(fileName);
          final backupFileName = _getBackupFileName(fileName);
          final backupFile = await _getFile(backupFileName);

          // Create backup: remove old backup, rename current to backup, save new file
          if (await file.exists()) {
            if (await backupFile.exists()) {
              await backupFile.delete();
            }
            await file.rename(backupFile.path);
          }

          // Write new file
          await file.writeAsString(jsonContent, flush: true);
          Log.d('Saved data to $fileName with backup (version: $version)', tag: 'StorageManager');
          
          // Release lock
          _releaseLock();
        } catch (e, stackTrace) {
          Log.e('Error saving data', error: e, stackTrace: stackTrace, tag: 'StorageManager');
          _releaseLock();
        }
      }()
    );
  }

  /// Get backup filename for a given file
  String _getBackupFileName(String fileName) {
    return '$fileName.bak';
  }

  /// Get file reference
  Future<File> _getFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }
}
