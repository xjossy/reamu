import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import '../core/constants/app_constants.dart';

class MidiService {
  static final MidiService _instance = MidiService._internal();
  factory MidiService() => _instance;
  MidiService._internal();

  final MidiPro _midiPro = MidiPro();
  int? _soundfontId;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  int? get soundfontId => _soundfontId;

  // Initialize and load soundfont
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final sfId = await _midiPro.loadSoundfont(
        path: AppConstants.soundfontPath,
        bank: AppConstants.defaultBank,
        program: AppConstants.acousticGrandPiano,
      );

      _soundfontId = sfId;
      _isInitialized = true;
      
      print('✅ MIDI Service initialized with SF ID: $sfId');
      return true;
    } catch (e) {
      print('❌ Error initializing MIDI: $e');
      return false;
    }
  }

  // Play a note
  void playNote(int midiNote, {int velocity = AppConstants.defaultVelocity}) {
    if (!_isInitialized || _soundfontId == null) {
      print('❌ MIDI not initialized');
      return;
    }

    _midiPro.playNote(
      sfId: _soundfontId!,
      channel: 0,
      key: midiNote,
      velocity: velocity,
    );
  }

  // Stop a note
  void stopNote(int midiNote) {
    if (!_isInitialized || _soundfontId == null) return;

    _midiPro.stopNote(
      sfId: _soundfontId!,
      channel: 0,
      key: midiNote,
    );
  }

  // Stop all notes
  void stopAllNotes() {
    if (!_isInitialized || _soundfontId == null) return;
    
    // Send all notes off command
    for (int i = 0; i < 128; i++) {
      stopNote(i);
    }
  }
}

