import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reamu - Music Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MusicNotePage(),
    );
  }
}

class MusicNotePage extends StatefulWidget {
  const MusicNotePage({super.key});

  @override
  State<MusicNotePage> createState() => _MusicNotePageState();
}

class _MusicNotePageState extends State<MusicNotePage> {
  final MidiPro _midiPro = MidiPro();
  bool _isPlaying = false;
  bool _isLoaded = false;
  int? _soundfontId;

  // Middle C note (C4) = MIDI note 60
  final int _cNote = 60;
  final int _velocity = 127; // Maximum velocity (volume) 0-127

  @override
  void initState() {
    super.initState();
    _loadSoundFont();
  }

  Future<void> _loadSoundFont() async {
    try {
      // Load the Roland SC-55 SF2 soundfont file
      final sfId = await _midiPro.loadSoundfont(
        path: 'assets/Piano.sf2',
        bank: 0,
        program: 0,  // Acoustic Grand Piano
      );
      
      setState(() {
        _soundfontId = sfId;
        _isLoaded = true;
      });
      
      print('✅ Roland SC-55 Soundfont loaded! ID: $sfId');
    } catch (e) {
      print('❌ Error loading soundfont: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Play the C note
  void _playNote() {
    if (_isLoaded && !_isPlaying && _soundfontId != null) {
      setState(() {
        _isPlaying = true;
      });
      
      // Play MIDI note with FluidSynth
      _midiPro.playNote(
        sfId: _soundfontId!,
        channel: 0,
        key: _cNote,
        velocity: _velocity,
      );
      
      print('🎵 Playing C note (MIDI $_cNote) with velocity $_velocity');
    }
  }

  // Stop the note
  void _stopNote() {
    if (_isLoaded && _isPlaying && _soundfontId != null) {
      // Stop MIDI note
      _midiPro.stopNote(
        sfId: _soundfontId!,
        channel: 0,
        key: _cNote,
      );
      
      setState(() {
        _isPlaying = false;
      });
      
      print('🔇 Stopped C note');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Reamu - FluidSynth MIDI 🎹',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status indicator
            if (!_isLoaded)
              Column(
                children: [
                  const CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Roland SC-55 SF2...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            
            if (_isLoaded)
              Text(
                'Press and hold to play',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w300,
                ),
              ),
            const SizedBox(height: 60),
            
            // The main button that responds to press/release
            GestureDetector(
              onTapDown: _isLoaded ? (_) => _playNote() : null,
              onTapUp: _isLoaded ? (_) => _stopNote() : null,
              onTapCancel: _isLoaded ? () => _stopNote() : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying 
                      ? Colors.blue[400] 
                      : (_isLoaded ? Colors.blue[700] : Colors.grey[700]),
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: Colors.blue[300]!.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: (_isLoaded ? Colors.blue[900]! : Colors.grey[800]!)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPlaying ? Icons.music_note : Icons.music_note_outlined,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'C',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Middle C',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            Text(
              _isPlaying 
                  ? '🎵 Playing...' 
                  : (_isLoaded ? 'Touch to play' : 'Loading...'),
              style: TextStyle(
                fontSize: 18,
                color: _isPlaying 
                    ? Colors.blue[300] 
                    : (_isLoaded ? Colors.grey[600] : Colors.grey[700]),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Technical info
            if (_isLoaded)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'FluidSynth + Roland SC-55',
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MIDI Note: $_cNote (Middle C)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Velocity: $_velocity',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✅ Real MIDI Synthesis with ADSR',
                      style: TextStyle(
                        color: Colors.green[400],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
