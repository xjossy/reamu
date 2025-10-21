import 'package:flutter/material.dart';
import '../services/midi_service.dart';

/// A reusable button that plays a MIDI note while pressed
/// Usage:
/// ```dart
/// HoldToPlayButton(
///   midiNote: 60,
///   child: Text('Play C4'),
/// )
/// ```
class HoldToPlayButton extends StatefulWidget {
  final int midiNote;
  final Widget child;
  final VoidCallback? onTap; // Optional tap action (for buttons that also select)

  const HoldToPlayButton({
    super.key,
    required this.midiNote,
    required this.child,
    this.onTap,
  });

  @override
  State<HoldToPlayButton> createState() => _HoldToPlayButtonState();
}

class _HoldToPlayButtonState extends State<HoldToPlayButton> {
  final MidiService _midiService = MidiService();
  PlayingNote? _playingNote;
  bool _isPressed = false;

  void _startPlaying() {
    setState(() => _isPressed = true);
    _playingNote = _midiService.playNoteManual(widget.midiNote);
  }

  void _stopPlaying() {
    setState(() => _isPressed = false);
    _playingNote?.stop();
    _playingNote = null;
  }

  @override
  void dispose() {
    // Safety: ensure note is stopped when widget is disposed
    _playingNote?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _startPlaying(),
      onTapUp: (_) => _stopPlaying(),
      onTapCancel: () => _stopPlaying(),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

/// A reusable button for long-press to play (with separate tap action)
/// Usage:
/// ```dart
/// LongPressToPlayButton(
///   midiNote: 60,
///   onTap: () => selectNote('C4'),
///   child: Text('C4'),
/// )
/// ```
class LongPressToPlayButton extends StatefulWidget {
  final int midiNote;
  final Widget child;
  final VoidCallback? onTap;

  const LongPressToPlayButton({
    super.key,
    required this.midiNote,
    required this.child,
    this.onTap,
  });

  @override
  State<LongPressToPlayButton> createState() => _LongPressToPlayButtonState();
}

class _LongPressToPlayButtonState extends State<LongPressToPlayButton> {
  final MidiService _midiService = MidiService();
  PlayingNote? _playingNote;
  bool _isLongPressing = false;

  void _startPlaying() {
    setState(() => _isLongPressing = true);
    _playingNote = _midiService.playNoteManual(widget.midiNote);
  }

  void _stopPlaying() {
    setState(() => _isLongPressing = false);
    _playingNote?.stop();
    _playingNote = null;
  }

  @override
  void dispose() {
    // Safety: ensure note is stopped when widget is disposed
    _playingNote?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) => _startPlaying(),
      onLongPressEnd: (_) => _stopPlaying(),
      onLongPressCancel: () => _stopPlaying(),
      child: AnimatedOpacity(
        opacity: _isLongPressing ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

/// Helper function to wrap any widget with hold-to-play behavior
/// Usage:
/// ```dart
/// wrapWithHoldToPlay(
///   midiNote: 60,
///   child: ElevatedButton(...)
/// )
/// ```
Widget wrapWithHoldToPlay({
  required int midiNote,
  required Widget child,
  VoidCallback? onTap,
}) {
  return HoldToPlayButton(
    midiNote: midiNote,
    onTap: onTap,
    child: child,
  );
}

/// Helper function to wrap any widget with long-press-to-play behavior
/// Usage:
/// ```dart
/// wrapWithLongPressToPlay(
///   midiNote: 60,
///   onTap: () => select(),
///   child: Container(...)
/// )
/// ```
Widget wrapWithLongPressToPlay({
  required int midiNote,
  required Widget child,
  VoidCallback? onTap,
}) {
  return LongPressToPlayButton(
    midiNote: midiNote,
    onTap: onTap,
    child: child,
  );
}

