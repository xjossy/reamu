class Note {
  final int midiNumber;
  final String name;
  final int octave;
  
  Note({
    required this.midiNumber,
    required this.name,
    required this.octave,
  });
  
  // Get note name with octave (e.g., "C4", "F#5")
  String get fullName => '$name$octave';
  
  // Get frequency in Hz
  double get frequency {
    // A4 = 440 Hz, MIDI 69
    return 440.0 * pow(2.0, (midiNumber - 69) / 12.0);
  }
  
  // Helper to create a note from MIDI number
  factory Note.fromMidi(int midiNumber) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'H'];
    final octave = (midiNumber ~/ 12) - 1;
    final noteName = noteNames[midiNumber % 12];
    
    return Note(
      midiNumber: midiNumber,
      name: noteName,
      octave: octave,
    );
  }
}

// Import for pow function
import 'dart:math';

