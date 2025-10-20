import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../services/global_memory_service.dart';
import 'guess_intro_page.dart';

class GuessPage extends StatefulWidget {
  const GuessPage({super.key});

  @override
  State<GuessPage> createState() => _GuessPageState();
}

class _GuessPageState extends State<GuessPage> {
  final SettingsService _settingsService = SettingsService.instance;
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  bool _isLoading = true;
  int _questionCount = 5;
  bool _hasLearnedNotes = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final count = await _settingsService.getGuessQuestionsCount();
    final progress = await _memoryService.getUserProgress();
    final learnedNotes = List<String>.from(progress['synestetic_pitch']['leaned_notes']);
    
    setState(() {
      _questionCount = count;
      _hasLearnedNotes = learnedNotes.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Guess Mode',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasLearnedNotes) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Guess Mode',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          shadowColor: Colors.grey[300],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'No Learned Notes Yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Complete learning sessions first to unlock Guess Mode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navigate to intro page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GuessIntroPage(questionCount: _questionCount),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
