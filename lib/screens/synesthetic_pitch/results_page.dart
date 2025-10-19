import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../services/settings_service.dart';
import '../../models/describing_question.dart';

class ResultsPage extends StatefulWidget {
  final String noteName;
  final Map<String, String> sessionAnswers;
  final List<DescribingQuestion> questions;

  const ResultsPage({
    super.key,
    required this.noteName,
    required this.sessionAnswers,
    required this.questions,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  Map<String, dynamic> _userProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    final progress = await _memoryService.getUserProgress();
    setState(() {
      _userProgress = progress;
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
            'Session Results',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Session Results',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.blue[50],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Session Complete!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Note: ${widget.noteName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics for each question
            ...widget.questions.map((question) => _buildQuestionStats(question)).toList(),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStats(DescribingQuestion question) {
    final noteStats = _userProgress['synestetic_pitch']['note_statistics'][widget.noteName];
    final questionStatsRaw = noteStats?['questions']?[question.key];
    final questionStats = questionStatsRaw != null ? List<int>.from(questionStatsRaw) : null;
    final currentAnswer = widget.sessionAnswers[question.key];
    final currentAnswerIndex = currentAnswer != null ? question.options.indexOf(currentAnswer) : -1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress bars for each option
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final count = questionStats?[index] ?? 0;
              final total = questionStats?.reduce((a, b) => a + b) ?? 0;
              final percentage = total > 0 ? count / total : 0.0;
              final isCurrentAnswer = index == currentAnswerIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentAnswer ? FontWeight.bold : FontWeight.w500,
                            color: isCurrentAnswer ? Colors.blue[700] : Colors.black87,
                          ),
                        ),
                        Text(
                          '$count time${count != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrentAnswer ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentAnswer ? Colors.blue[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentAnswer ? Colors.blue[600]! : Colors.grey[600]!,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Check if there are more notes
        FutureBuilder<bool>(
          future: _settingsService.hasMoreNotes(_userProgress),
          builder: (context, snapshot) {
            final hasMoreNotes = snapshot.data ?? false;
            
            return Column(
              children: [
                if (hasMoreNotes) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Move to next note
                        Navigator.of(context).pop(); // Go back to describing page
                        // The describing page will handle moving to next note
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Next Note',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Go back to describing page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Repeat Note',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Go back to describing page
                      Navigator.of(context).pop(); // Go back to main menu
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                    child: Text(
                      'Back to Menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
