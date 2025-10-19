import 'package:flutter/material.dart';
import '../../services/midi_service.dart';
import '../../widgets/note_button.dart';
import '../../core/constants/app_constants.dart';

class AbsolutePitchPage extends StatefulWidget {
  const AbsolutePitchPage({super.key});

  @override
  State<AbsolutePitchPage> createState() => _AbsolutePitchPageState();
}

class _AbsolutePitchPageState extends State<AbsolutePitchPage> {
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

  // Build first row: A0, A#0, H0 + 9 empty slots (moved to right)
  Widget _buildFirstRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 9 empty slots on the left
          ...List.generate(9, (index) => const Expanded(child: SizedBox())),
          // A0, A#0, H0 on the right
          ...List.generate(3, (index) {
            final midiNote = 21 + index; // A0=21, A#0=22, H0=23
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
        ],
      ),
    );
  }

  // Build last row: C8 + 11 empty slots
  Widget _buildLastRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // C8
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: NoteButton(
                midiNote: 108, // C8
                noteName: 'C8',
                isBlackKey: false,
                isGrayKey: false,
              ),
            ),
          ),
          // 11 empty slots
          ...List.generate(11, (index) => const Expanded(child: SizedBox())),
        ],
      ),
    );
  }

  // Build partial octave row (for C9-G#9, MIDI 120-127)
  Widget _buildPartialOctaveRow(int startNote, int noteCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The actual notes
          ...List.generate(noteCount, (index) {
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
          // Empty slots to fill the row
          ...List.generate(12 - noteCount, (index) => const Expanded(child: SizedBox())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Absolute Pitch Training 🎹',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !_isLoaded
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blue),
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
              ],
            ),
    );
  }
}

