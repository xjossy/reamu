import 'package:flutter/material.dart';
import '../../services/midi_service.dart';
import '../../widgets/note_button.dart';
import '../../core/constants/app_constants.dart';

class SimplePlayingPage extends StatefulWidget {
  const SimplePlayingPage({super.key});

  @override
  State<SimplePlayingPage> createState() => _SimplePlayingPageState();
}

class _SimplePlayingPageState extends State<SimplePlayingPage> {
  final MidiService _midiService = MidiService();
  bool _isLoaded = false;

  // Define the range of notes to display (full MIDI range 0-127)
  static const int startMidiNote = 0;  // MIDI 0
  static const int endMidiNote = 127;  // MIDI 127
  static const int notesPerOctave = 12;

  @override
  void initState() {
    super.initState();
    _initializeMidi();
  }

  Future<void> _initializeMidi() async {
    final success = await _midiService.initialize();
    setState(() {
      _isLoaded = success;
    });
  }

  // Check if a note is a black key
  bool _isBlackKey(int noteIndex) {
    final position = noteIndex % 12;
    return [1, 3, 6, 8, 10].contains(position); // C#, D#, F#, G#, A#
  }

  // Check if a note should be gray (outside piano range A0-C8)
  bool _isGrayKey(int midiNote) {
    return midiNote < 21 || midiNote > 108; // Outside A0-C8 range
  }

  // Build a row of 12 notes (one octave)
  Widget _buildOctaveRow(int startNote) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(12, (index) {
          final midiNote = startNote + index;
          final noteIndex = midiNote % 12;
          final octave = (midiNote ~/ 12) - 1;
          final noteName = AppConstants.noteNames[noteIndex];
          final isBlack = _isBlackKey(noteIndex);
          final isGray = _isGrayKey(midiNote);
          
          return Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: NoteButton(
                midiNote: midiNote,
                noteName: '$noteName$octave',
                isBlackKey: isBlack,
                isGrayKey: isGray,
              ),
            ),
          );
        }),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Simple Playing 🎹',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !_isLoaded
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.purple),
                  const SizedBox(height: 16),
                  Text(
                    'Loading soundfont...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Press and hold any note to play',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // All octaves from 0 to 10 (MIDI 0-127)
                        ...List.generate(11, (octaveIndex) {
                          final startNote = octaveIndex * 12; // C0=0, C1=12, C2=24, etc.
                          return _buildOctaveRow(startNote);
                        }),
                      ],
                    ),
                  ),
                ),
                // Info panel
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[850],
                  child: Text(
                    'Roland SC-55 SoundFont | FluidSynth MIDI',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

}

