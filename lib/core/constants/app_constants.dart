class AppConstants {
  // Soundfont path
  static const String soundfontPath = 'assets/Piano.sf2';
  
  // MIDI constants
  static const int defaultVelocity = 127;
  static const int defaultBank = 0;
  static const int acousticGrandPiano = 0; // Program number
  
  // Note names (scientific notation with H instead of B)
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'H'
  ];
  
  // MIDI note for Middle C (C4)
  static const int middleC = 60;
}

