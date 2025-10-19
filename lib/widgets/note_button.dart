import 'package:flutter/material.dart';
import '../services/midi_service.dart';

class NoteButton extends StatefulWidget {
  final int midiNote;
  final String noteName;
  final bool isBlackKey;
  final bool isGrayKey;

  const NoteButton({
    super.key,
    required this.midiNote,
    required this.noteName,
    this.isBlackKey = false,
    this.isGrayKey = false,
  });

  @override
  State<NoteButton> createState() => _NoteButtonState();
}

class _NoteButtonState extends State<NoteButton> {
  final MidiService _midiService = MidiService();
  bool _isPressed = false;

  void _onNotePressed() {
    setState(() => _isPressed = true);
    _midiService.playNote(widget.midiNote);
  }

  void _onNoteReleased() {
    setState(() => _isPressed = false);
    _midiService.stopNote(widget.midiNote);
  }

  @override
  Widget build(BuildContext context) {
    // Black keys vs white keys vs gray keys styling
    final bool isBlack = widget.isBlackKey;
    final bool isGray = widget.isGrayKey;
    
    return GestureDetector(
      onTapDown: (_) => _onNotePressed(),
      onTapUp: (_) => _onNoteReleased(),
      onTapCancel: () => _onNoteReleased(),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _isPressed 
              ? (isBlack ? Colors.blue[600] : isGray ? Colors.blue[400] : Colors.blue[300])
              : (isBlack ? Colors.grey[900] : isGray ? Colors.grey[600] : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isBlack ? Colors.grey[700]! : isGray ? Colors.grey[500]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.blue[300]!.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.noteName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isBlack 
                  ? (_isPressed ? Colors.white : Colors.white70)
                  : isGray
                      ? (_isPressed ? Colors.white : Colors.grey[300])
                      : (_isPressed ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

