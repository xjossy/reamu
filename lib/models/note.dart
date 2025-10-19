import 'dart:math';

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

  // Helper to create a note from note name (e.g., "C4", "F#5")
  factory Note.fromName(String noteName) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'H'];
    
    // Parse note name and octave
    String name;
    int octave;
    
    if (noteName.contains('#')) {
      // Sharp note (e.g., "C#4")
      name = noteName.substring(0, 2);
      octave = int.parse(noteName.substring(2));
    } else {
      // Natural note (e.g., "C4")
      name = noteName.substring(0, 1);
      octave = int.parse(noteName.substring(1));
    }
    
    final noteIndex = noteNames.indexOf(name);
    final midiNumber = (octave + 1) * 12 + noteIndex;
    
    return Note(
      midiNumber: midiNumber,
      name: name,
      octave: octave,
    );
  }
}
