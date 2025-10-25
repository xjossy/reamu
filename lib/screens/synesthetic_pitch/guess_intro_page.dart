import 'package:flutter/material.dart';

class GuessIntroPage extends StatelessWidget {
  final int questionCount;
  final String targetNoteName;
  final VoidCallback? onStartGuessing;
  
  const GuessIntroPage({
    super.key, 
    required this.questionCount, 
    required this.targetNoteName, 
    this.onStartGuessing,
  });

  @override
  Widget build(BuildContext context) {
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
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.quiz,
                  size: 60,
                  color: Colors.purple[700],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Answer $questionCount questions',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Description
              Text(
                'A random note will be played. Describe your associations and guess which note it is!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Start Button
              ElevatedButton(
                onPressed: () {
                  onStartGuessing?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Start Guessing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

