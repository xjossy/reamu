import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/midi_service.dart';

/// A widget that displays a piano keyboard for one octave
/// 
/// Shows white and black keys and highlights the target note
/// Keys are interactive and play sounds when pressed
class PianoKeyboard extends StatefulWidget {
  final String targetNote;
  final double? width;
  final double keyHeight;
  
  const PianoKeyboard({
    super.key,
    required this.targetNote,
    this.width,
    this.keyHeight = 100,
  });
  
  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final MidiService _midiService = MidiService();
  final Map<String, PlayingNote> _playingNotes = {};
  
  @override
  void initState() {
    super.initState();
    _initializeMidi();
  }
  
  Future<void> _initializeMidi() async {
    await _midiService.initialize();
  }
  
  @override
  void dispose() {
    _midiService.stopAllNotes();
    super.dispose();
  }
  
  void _playNote(String noteName, int octave) {
    final fullNoteName = '$noteName$octave';
    final note = Note.fromName(fullNoteName);
    
    // Stop any existing note
    _stopNote(fullNoteName);
    
    // Play the note
    final playingNote = _midiService.playNoteManual(note.midiNumber);
    setState(() {
      _playingNotes[fullNoteName] = playingNote;
    });
  }
  
  void _stopNote(String noteName) {
    final playingNote = _playingNotes[noteName];
    if (playingNote != null) {
      playingNote.stop();
      setState(() {
        _playingNotes.remove(noteName);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final note = Note.fromName(widget.targetNote);
    final isSharp = note.name.contains('#');
    final totalWidth = widget.width ?? 300;
    final whiteKeyWidth = totalWidth / 7;
    
    return Column(
      children: [
        // Octave label
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Octave ${note.octave}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        
        // Keyboard
        SizedBox(
          width: totalWidth,
          height: widget.keyHeight,
          child: Stack(
            children: [
              // White keys - positioned absolutely
              _buildWhiteKey(context, 'C', 0, whiteKeyWidth, note.name == 'C' && !isSharp),
              _buildWhiteKey(context, 'D', whiteKeyWidth, whiteKeyWidth, note.name == 'D' && !isSharp),
              _buildWhiteKey(context, 'E', whiteKeyWidth * 2, whiteKeyWidth, note.name == 'E' && !isSharp),
              _buildWhiteKey(context, 'F', whiteKeyWidth * 3, whiteKeyWidth, note.name == 'F' && !isSharp),
              _buildWhiteKey(context, 'G', whiteKeyWidth * 4, whiteKeyWidth, note.name == 'G' && !isSharp),
              _buildWhiteKey(context, 'A', whiteKeyWidth * 5, whiteKeyWidth, note.name == 'A' && !isSharp),
              _buildWhiteKey(context, 'H', whiteKeyWidth * 6, whiteKeyWidth, note.name == 'H' && !isSharp),
              
              // Black keys - positioned between white keys
              _buildBlackKey(context, 'C#', whiteKeyWidth - 15, note.name == 'C#', totalWidth),
              _buildBlackKey(context, 'D#', whiteKeyWidth * 2 - 15, note.name == 'D#', totalWidth),
              _buildBlackKey(context, 'F#', whiteKeyWidth * 4 - 15, note.name == 'F#', totalWidth),
              _buildBlackKey(context, 'G#', whiteKeyWidth * 5 - 15, note.name == 'G#', totalWidth),
              _buildBlackKey(context, 'A#', whiteKeyWidth * 6 - 15, note.name == 'A#', totalWidth),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWhiteKey(BuildContext context, String noteName, double left, double width, bool isTarget) {
    final note = Note.fromName(widget.targetNote);
    final isPlaying = _playingNotes.containsKey('$noteName${note.octave}');
    
    return Positioned(
      left: left,
      width: width,
      height: widget.keyHeight,
      child: GestureDetector(
        onTapDown: (_) => _playNote(noteName, note.octave),
        onTapUp: (_) => _stopNote('$noteName${note.octave}'),
        onLongPressEnd: (_) => _stopNote('$noteName${note.octave}'),
        onLongPressCancel: () => _stopNote('$noteName${note.octave}'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isPlaying 
                ? Colors.teal[200] 
                : isTarget 
                    ? Colors.teal[100] 
                    : Colors.white,
            border: Border.all(
              color: isTarget ? Colors.teal[300]! : Colors.grey[300]!,
              width: isTarget ? 2 : 1,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                noteName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                  color: isTarget ? Colors.teal[700] : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBlackKey(BuildContext context, String noteName, double left, bool isTarget, double totalWidth) {
    final note = Note.fromName(widget.targetNote);
    final isPlaying = _playingNotes.containsKey('$noteName${note.octave}');
    
    return Positioned(
      left: left,
      top: 0,
      child: GestureDetector(
        onTapDown: (_) => _playNote(noteName, note.octave),
        onTapUp: (_) => _stopNote('$noteName${note.octave}'),
        onLongPressEnd: (_) => _stopNote('$noteName${note.octave}'),
        onLongPressCancel: () => _stopNote('$noteName${note.octave}'),
        child: Container(
          width: 30,
          height: widget.keyHeight * 0.6,
          decoration: BoxDecoration(
            color: isPlaying 
                ? Colors.teal[900] 
                : isTarget 
                    ? Colors.teal[700] 
                    : Colors.grey[900],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              noteName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                color: isTarget ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
