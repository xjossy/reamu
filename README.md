# Reamu 🎵

A Flutter-based music training application with real MIDI synthesis using FluidSynth and SF2 soundfonts.

## Features

- 🎹 **Absolute Pitch Training** - Train your ear to recognize notes
- 🎼 **Simple Playing** - Full piano keyboard with all 12 notes
- 🎵 **Real MIDI Synthesis** - Using FluidSynth with SF2 soundfonts
- ⚡ **ADSR Support** - Professional sound envelope control
- 🎨 **Modern UI** - Beautiful dark theme with smooth animations

## Project Structure

```
lib/
├── main.dart                              # App entry point
├── core/                                  # Core app functionality
│   ├── theme/
│   │   └── app_theme.dart                # App colors, styles, theme
│   └── constants/
│       └── app_constants.dart            # App-wide constants
│
├── services/                              # Business logic & utilities
│   ├── midi_service.dart                 # MIDI playback service (FluidSynth)
│   ├── note_player.dart                  # Note playing utilities (future)
│   ├── chord_player.dart                 # Chord playing utilities (future)
│   └── melody_player.dart                # Melody playing utilities (future)
│
├── models/                                # Data models
│   ├── note.dart                         # Note model (MIDI, name, frequency)
│   ├── chord.dart                        # Chord model (future)
│   └── melody.dart                       # Melody model (future)
│
├── screens/                               # App screens/pages
│   ├── main_menu/
│   │   └── main_menu_page.dart           # Main menu with tiles
│   ├── absolute_pitch/
│   │   └── absolute_pitch_page.dart      # Absolute pitch training mode
│   ├── simple_playing/
│   │   └── simple_playing_page.dart      # Piano keyboard for testing
│   └── settings/
│       └── settings_page.dart            # Settings screen (future)
│
└── widgets/                               # Reusable UI components
    ├── menu_tile.dart                    # Menu tile widget
    ├── note_button.dart                  # Piano key button widget
    └── keyboard.dart                     # Full keyboard widget (future)

assets/
└── Piano.sf2                              # Roland SC-55 SoundFont file
```

## Architecture

### Core Layer
- **Theme**: Centralized app styling and colors
- **Constants**: App-wide configuration values

### Service Layer
- **MidiService**: Singleton service managing FluidSynth MIDI synthesis
  - Loads SF2 soundfont on initialization
  - Provides `playNote()` and `stopNote()` methods
  - Shared across all screens for consistent audio

### Model Layer
- **Note**: Represents musical notes with MIDI number, name, octave, and frequency
- **Chord** (future): Will represent multiple notes played together
- **Melody** (future): Will represent sequences of notes

### Screen Layer
- Each mode has its own screen directory
- Screens are independent and can be added/removed easily
- Navigation handled via MaterialPageRoute

### Widget Layer
- Reusable UI components shared across screens
- Custom widgets for menu tiles, piano keys, etc.

## Technologies

- **Flutter**: 3.35.6 (stable)
- **Dart**: 3.9.2
- **flutter_midi_pro**: 3.1.4 (FluidSynth wrapper)
- **SF2 SoundFont**: Roland SC-55 by StrikingUAC

## Current Modes

### 1. Absolute Pitch Training
- Train your ear to recognize notes without reference
- Single note playback with press & hold
- Future: Quiz mode, difficulty levels, progress tracking

### 2. Simple Playing
- Full chromatic keyboard (12 notes: C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
- Octave selector (octaves 1-7)
- Press & hold to play notes
- Visual feedback on key press
- Perfect for testing the soundfont

## How It Works

1. **App Launch**: `main.dart` loads the app with dark theme
2. **Main Menu**: Displays tile grid with available modes
3. **Mode Selection**: Tap a tile to navigate to that mode
4. **MIDI Initialization**: Each screen initializes `MidiService` (singleton)
5. **Soundfont Loading**: Roland SC-55 SF2 loaded via FluidSynth
6. **Note Playing**: Press & hold buttons send MIDI Note On/Off messages
7. **Real-time Synthesis**: FluidSynth synthesizes audio with ADSR envelope

## Development Commands

```bash
# Run on Android emulator
flutter run -d emulator-5554

# Run on Chrome (web)
flutter run -d chrome

# Hot reload (when app is running)
Press 'r' in terminal

# Hot restart (for plugin changes)
Press 'R' in terminal

# Clean build
flutter clean
flutter pub get
flutter run

# Check available devices
flutter devices
```

## Future Features

- [ ] More training modes (intervals, chords, scales)
- [ ] Progress tracking and statistics
- [ ] Multiple instrument support
- [ ] Chord player with chord diagrams
- [ ] Melody playback and recording
- [ ] MIDI file import/export
- [ ] Custom soundfont selection
- [ ] Velocity sensitivity settings
- [ ] Metronome and tempo control

## Installation

1. **Clone repository**:
   ```bash
   git clone git@github.com:xjossy/reamu.git
   cd reamu
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Add your SF2 soundfont**:
   - Place your `.sf2` file in `assets/Piano.sf2`
   - Or use the included Roland SC-55 soundfont

4. **Run app**:
   ```bash
   flutter run
   ```

## Requirements

- Flutter SDK 3.35.6 or later
- Dart 3.9.2 or later
- Android SDK (for Android)
- Xcode (for iOS)
- SF2 soundfont file

## License

Private project - not for public distribution

## Credits

- **FluidSynth**: Software synthesizer
- **flutter_midi_pro**: Flutter wrapper for FluidSynth
- **Roland SC-55 SF2**: SoundFont by StrikingUAC

---

**Made with ❤️ for music education**
