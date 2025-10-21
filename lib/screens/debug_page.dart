import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/debug_service.dart';
import '../core/debug_config.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final DebugService _debugService = DebugService.instance;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _debugService.getAllUserData();
    
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!DebugConfig.debugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug Mode Disabled')),
        body: const Center(
          child: Text('Debug mode is disabled in this build'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Debug Information'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _printToConsole,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.print, color: Colors.white),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[800],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab('Overview', 'overview'),
            _buildTab('Raw Data', 'raw'),
            _buildTab('Sessions', 'sessions'),
            _buildTab('Scores', 'scores'),
            _buildTab('Files', 'files'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, String tabId) {
    final isSelected = _selectedTab == tabId;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 'overview':
        return _buildOverview();
      case 'raw':
        return _buildRawData();
      case 'sessions':
        return _buildSessions();
      case 'scores':
        return _buildScores();
      case 'files':
        return _buildFiles();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('User Progress', [
            'Started: ${_userData['user_progress']?['synestetic_pitch']?['started'] ?? 'N/A'}',
            'Opened Notes: ${_userData['user_progress']?['synestetic_pitch']?['opened_notes']?.length ?? 0}',
            'Learned Notes: ${_userData['user_progress']?['synestetic_pitch']?['leaned_notes']?.length ?? 0}',
            'Level: ${_userData['current_level'] ?? 'N/A'}',
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Current Session', [
            'Session ID: ${_userData['current_session']?['id'] ?? 'None'}',
            'Total Notes: ${_userData['current_session']?['notesToGuess']?.length ?? 0}',
            'Completed: ${_userData['current_session']?['completedNotes'] ?? 0}',
            'Correct: ${_userData['current_session']?['correctlyGuessed']?.length ?? 0}',
            'Incorrect: ${_userData['current_session']?['incorrectlyGuessed']?.length ?? 0}',
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Sessions History', [
            'Total Sessions: ${_userData['sessions']?.length ?? 0}',
            'Session Length: ${_userData['session_length'] ?? 'N/A'} minutes',
          ]),
        ],
      ),
    );
  }

  Widget _buildRawData() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: _copyToClipboard,
                child: const Text('Copy to Clipboard'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _printToConsole,
                child: const Text('Print to Console'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: SelectableText(
              _debugService.formatJsonForDisplay(_userData),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessions() {
    final sessions = _userData['sessions'] as List<dynamic>? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text('ID: ${session['id']}', style: const TextStyle(color: Colors.white)),
                Text('Start: ${session['startTime']}', style: const TextStyle(color: Colors.white)),
                Text('End: ${session['endTime'] ?? 'Not completed'}', style: const TextStyle(color: Colors.white)),
                Text('Notes: ${session['notesToGuess']?.length ?? 0}', style: const TextStyle(color: Colors.white)),
                Text('Correct: ${session['correctlyGuessed']?.length ?? 0}', style: const TextStyle(color: Colors.white)),
                Text('Incorrect: ${session['incorrectlyGuessed']?.length ?? 0}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScores() {
    final noteScores = _userData['note_scores'] as Map<String, dynamic>? ?? {};
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: noteScores.length,
      itemBuilder: (context, index) {
        final entry = noteScores.entries.elementAt(index);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              (entry.value as int) >= 0 ? Icons.trending_up : Icons.trending_down,
              color: (entry.value as int) >= 0 ? Colors.green : Colors.red,
            ),
            title: Text(entry.key),
            subtitle: Text('${entry.value} points'),
            trailing: Text(
              (entry.value as int) >= 0 ? '+${entry.value}' : '${entry.value}',
              style: TextStyle(
                color: (entry.value as int) >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiles() {
    final files = _userData['raw_files'] as Map<String, dynamic>? ?? {};
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final entry = files.entries.elementAt(index);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(entry.key),
            subtitle: Text('${entry.value.toString().length} characters'),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard() {
    final jsonString = _debugService.formatJsonForDisplay(_userData);
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data copied to clipboard')),
    );
  }

  void _printToConsole() {
    _debugService.printAllData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data printed to console')),
    );
  }

  void _exportData() {
    _debugService.exportUserData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data exported to debug_export.json')),
    );
  }
}
