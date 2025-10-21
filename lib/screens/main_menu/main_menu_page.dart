import 'package:flutter/material.dart';
import '../../widgets/menu_tile.dart';
import '../absolute_pitch/absolute_pitch_page.dart';
import '../simple_playing/simple_playing_page.dart';
import '../synesthetic_pitch/synesthetic_menu_page.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Reamu 🎵',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // Absolute Pitch Training Tile
            MenuTile(
              title: 'Absolute Pitch',
              icon: Icons.music_note,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbsolutePitchPage(),
                  ),
                );
              },
            ),
            
            // Simple Playing / Piano Tile
            MenuTile(
              title: 'Simple Playing',
              icon: Icons.piano,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimplePlayingPage(),
                  ),
                );
              },
            ),
            
            // Synesthetic Pitch - Describing Tile
            MenuTile(
              title: 'Synesthetic Pitch',
              icon: Icons.psychology,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SynestheticMenuPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}