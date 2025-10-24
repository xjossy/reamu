import 'logging_service.dart';
import 'dart:async';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:synchronized/synchronized.dart';
import '../core/constants/app_constants.dart';

/// Represents a playing note with automatic cleanup
class PlayingNote {
  final int midiNote;
  final MidiService _service;
  Timer? _timeoutTimer;
  bool _isStopped = false;
  final Lock _stopLock = Lock();

  PlayingNote(this.midiNote, this._service);

  /// Stop the note manually
  void stop() {
    bool shouldStop = false;
    _stopLock.synchronized(() {
      if (_isStopped) return;
      _isStopped = true;
      shouldStop = true;
    });

    if (shouldStop) {
      _timeoutTimer?.cancel();
      _service._stopNoteInternal(midiNote);
    }
  }

  /// Set a timeout for automatic stop
  void setTimeout(Duration duration) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(duration, () {
      Log.w('⏰ Note $midiNote timed out, auto-stopping', tag: 'MIDI');
      stop();
    });
  }
}

class MidiService {
  static final MidiService _instance = MidiService._internal();
  factory MidiService() => _instance;
  MidiService._internal();

  final MidiPro _midiPro = MidiPro();
  int? _soundfontId;
  bool _isInitialized = false;

  // Track all currently playing notes
  final Map<int, PlayingNote> _activeNotes = {};
  
  // Mutex locks for thread safety
  final Lock _midiLock = Lock();
  final Lock _activeNotesLock = Lock();

  // Default timeout for background notes (safety measure)
  static const Duration defaultTimeout = Duration(seconds: 10);

  bool get isInitialized => _isInitialized;
  int? get soundfontId => _soundfontId;

  // Initialize and load soundfont
  Future<bool> initialize() async {
    return await _midiLock.synchronized(() async {
      if (_isInitialized) return true;

      try {
        final sfId = await _midiPro.loadSoundfont(
          path: AppConstants.soundfontPath,
          bank: AppConstants.defaultBank,
          program: AppConstants.acousticGrandPiano,
        );

        _soundfontId = sfId;
        _isInitialized = true;
        
        Log.i('✅ MIDI Service initialized with SF ID: $sfId', tag: 'MIDI');
        return true;
      } catch (e, stackTrace) {
        Log.e('❌ Error initializing MIDI', error: e, stackTrace: stackTrace, tag: 'MIDI');
        return false;
      }
    });
  }

  /// Play a note and return a PlayingNote handle for manual control
  /// Use this for button-controlled notes where user controls start/stop
  PlayingNote playNoteManual(int midiNote, {int velocity = AppConstants.defaultVelocity}) {
    // Stop any existing note at this pitch first
    stopNote(midiNote);

    if (!_isInitialized || _soundfontId == null) {
      Log.w('❌ MIDI not initialized', tag: 'MIDI');
      return PlayingNote(midiNote, this); // Return dummy handle
    }

    Log.d('🎹 Playing note (manual): $midiNote, sfId: $_soundfontId', tag: 'MIDI');

    // Synchronize MIDI operations
    _midiLock.synchronized(() {
      _midiPro.playNote(
        sfId: _soundfontId!,
        channel: 0,
        key: midiNote,
        velocity: velocity,
      );
    });

    final playingNote = PlayingNote(midiNote, this);
    
    // Synchronize active notes map access
    _activeNotesLock.synchronized(() {
      _activeNotes[midiNote] = playingNote;
    });

    return playingNote;
  }

  /// Play a note with automatic timeout (for background/auto-play)
  /// The note will automatically stop after the specified duration
  PlayingNote playNoteWithTimeout(
    int midiNote, {
    int velocity = AppConstants.defaultVelocity,
    Duration timeout = defaultTimeout,
  }) {
    final playingNote = playNoteManual(midiNote, velocity: velocity);
    playingNote.setTimeout(timeout);
    return playingNote;
  }

  /// Legacy method for backward compatibility - uses timeout for safety
  void playNote(int midiNote, {int velocity = AppConstants.defaultVelocity}) {
    playNoteWithTimeout(midiNote, velocity: velocity, timeout: defaultTimeout);
  }

  /// Internal method to actually stop the MIDI note
  void _stopNoteInternal(int midiNote) {
    if (!_isInitialized || _soundfontId == null) return;

    Log.d('🎹 Stopping note: $midiNote, sfId: $_soundfontId', tag: 'MIDI');

    // Synchronize MIDI operations
    _midiLock.synchronized(() {
      _midiPro.stopNote(
        sfId: _soundfontId!,
        channel: 0,
        key: midiNote,
      );
    });

    // Synchronize active notes map access
    _activeNotesLock.synchronized(() {
      _activeNotes.remove(midiNote);
    });
  }

  /// Stop a specific note
  void stopNote(int midiNote) {
    PlayingNote? playingNote;
    
    // Synchronize access to active notes map
    _activeNotesLock.synchronized(() {
      playingNote = _activeNotes[midiNote];
    });
    
    if (playingNote != null) {
      playingNote!.stop();
    }
  }

  /// Stop all currently playing notes
  void stopAllNotes() {
    if (!_isInitialized || _soundfontId == null) return;
    
    List<PlayingNote> notesToStop = [];
    
    // Synchronize access to active notes map
    _activeNotesLock.synchronized(() {
      Log.i('🛑 Stopping all notes (${_activeNotes.length} active)', tag: 'MIDI');
      notesToStop = [..._activeNotes.values];
      _activeNotes.clear();
    });

    notesToStop.forEach((note) => note.stop());
  }

  /// Get list of currently playing notes (for debugging)
  List<int> getActiveNotes() {
    List<int> activeNotes = [];
    
    // Synchronize access to active notes map
    _activeNotesLock.synchronized(() {
      activeNotes = List<int>.from(_activeNotes.keys);
    });
    
    return activeNotes;
  }

  /// Dispose and cleanup
  void dispose() {
    Log.i('🛑 Disposing MIDI service', tag: 'MIDI');
    stopAllNotes();
  }
}
