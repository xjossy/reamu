# Flutter Debugging Guide for Cursor

## 🔧 Required Extensions

Install these extensions in Cursor:

1. **Dart** (by Dart Code)
   - Extension ID: `Dart-Code.dart-code`
   - Provides Dart language support

2. **Flutter** (by Dart Code)
   - Extension ID: `Dart-Code.flutter`
   - Provides Flutter framework support

## 📱 How to Debug

### Method 1: Run with Debugger (Recommended)

1. **Start your emulator** (if not already running):
   ```bash
   /Users/geo/Library/Android/sdk/emulator/emulator -avd reamu_dev -no-snapshot-load
   ```

2. **In Cursor**:
   - Press `F5` OR
   - Go to "Run and Debug" panel (Cmd+Shift+D)
   - Select "Flutter (Debug)" from dropdown
   - Click the green play button

3. **Set Breakpoints**:
   - Click in the gutter (left of line numbers) to add a red dot
   - When code hits that line, execution will pause
   - You can inspect variables in the left panel

4. **Debug Controls**:
   - **Continue (F5)**: Resume execution
   - **Step Over (F10)**: Execute current line, move to next
   - **Step Into (F11)**: Go into function call
   - **Step Out (Shift+F11)**: Exit current function
   - **Restart (Cmd+Shift+F5)**: Restart app
   - **Hot Reload (Cmd+S or Cmd+R)**: Apply code changes without restart

### Method 2: View Console Output

1. **Run app normally**:
   ```bash
   flutter run
   ```

2. **View logs**:
   - In Cursor: Open "Debug Console" panel
   - Or check terminal output
   - All `print()` statements will appear here

3. **I've added debug emojis for easy tracking**:
   - 🎮 = Before guessing
   - 🔄 = Returning from guess
   - ✅ = Action completed
   - 💾 = Saving data
   - 📖 = Loading data

### Method 3: Flutter DevTools

1. **Run app**:
   ```bash
   flutter run
   ```

2. **Open DevTools**:
   - Look for a line in console that says: "An Observatory debugger and profiler on..."
   - Or run: `flutter pub global activate devtools && flutter pub global run devtools`
   - DevTools provides:
     - Widget Inspector (see widget tree)
     - Performance profiler
     - Memory profiler
     - Network inspector

## 🐛 Debugging the Current Issue

### Problem: Session not updating after guess

**What I've added for debugging:**

1. **Enhanced logging in `session_page.dart`**:
   ```dart
   print('🎮 BEFORE GUESSING: Session ${_currentSession!.id}');
   print('🔄 RETURNED FROM GUESSING - Reloading session...');
   print('✅ SESSION RELOADED');
   ```

2. **To debug, watch the console for these logs:**
   - When you start guessing: Look for 🎮 emoji
   - When you return: Look for 🔄 emoji  
   - After reload: Look for ✅ emoji
   - Session details: Look for "Session loaded:" messages

### Steps to Debug:

1. Run the app with debugger (`F5`)
2. Open Debug Console in Cursor
3. Go to session page
4. Make a guess
5. Watch the console output
6. Look for:
   - "🎮 BEFORE GUESSING" - should show current state
   - "🔄 RETURNED FROM GUESSING" - confirms navigation returned
   - "Session loaded:" - should show updated counts
   - "✅ SESSION RELOADED" - confirms reload completed

### Expected vs Actual:

**Expected flow:**
1. User makes guess → `recordCorrectGuess`/`recordIncorrectGuess` called
2. Session saved to file
3. User returns → `_loadSession()` called
4. Session loaded from file
5. UI updates with new data

**If not working, check:**
- Is "🔄 RETURNED FROM GUESSING" printed?
- Is "Session loaded:" showing old or new counts?
- Are there any errors in the console?

## 🎯 Useful Commands

```bash
# Hot reload (while app is running)
r

# Hot restart (while app is running)  
R

# Clear console (while app is running)
c

# Quit (while app is running)
q

# View detailed logs
flutter logs

# Check for issues
flutter doctor

# Clean build (if things are weird)
flutter clean && flutter pub get
```

## 💡 Tips

1. **Use print() liberally** - Add print statements to track execution flow
2. **Hot reload** - Press `Cmd+S` to see changes instantly (no restart needed)
3. **Check file writes** - Debug prints show when files are saved/loaded
4. **Watch emojis** - I've added emojis to make logs easy to scan
5. **Breakpoints** - Set breakpoints in `_loadSession()` and `recordCorrectGuess()` to see exactly what's happening

## 🔍 Key Files to Watch

- `lib/screens/synesthetic_pitch/session_page.dart` - Session display
- `lib/screens/synesthetic_pitch/guess_note_selection_page.dart` - Recording guesses
- `lib/services/session_service.dart` - Session management
- `lib/services/global_memory_service.dart` - Score management

