import 'package:flutter/material.dart';
import '../services/midi_service.dart';
import '../services/logging_service.dart';

/// Mixin to automatically stop all MIDI notes when a page is disposed
/// Usage: class MyPageState extends State<MyPage> with MidiCleanupMixin
mixin MidiCleanupMixin<T extends StatefulWidget> on State<T> {
  final MidiService _midiService = MidiService();

  @override
  void dispose() {
    // Stop all notes when page is disposed
    Log.d('🧹 Page disposing - stopping all MIDI notes', tag: 'MidiCleanup');
    _midiService.stopAllNotes();
    super.dispose();
  }

  @override
  void deactivate() {
    // Also stop notes when page is deactivated (navigating away)
    Log.d('🧹 Page deactivating - stopping all MIDI notes', tag: 'MidiCleanup');
    _midiService.stopAllNotes();
    super.deactivate();
  }
}

