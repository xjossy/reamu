import 'package:flutter/material.dart';
import '../../services/global_memory_service.dart';
import '../../services/logging_service.dart';
import '../../services/settings_service.dart';
import '../../models/personalization_settings.dart';

class PersonalizationWizardPage extends StatefulWidget {
  const PersonalizationWizardPage({super.key});

  @override
  State<PersonalizationWizardPage> createState() => _PersonalizationWizardPageState();
}

class _PersonalizationWizardPageState extends State<PersonalizationWizardPage> {
  final GlobalMemoryService _memoryService = GlobalMemoryService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  
  double _morningTimeSlider = 32.0; // 8:00 AM = 32 (8 * 4 intervals)
  double _daylightDuration = 12.0; // 12 hours
  double _instantSessions = 7.0;
  
  int _minInstantSessions = 3;
  int _maxInstantSessions = 15;
  int _defaultInstantSessions = 7;
  
  bool _isLoading = true;
  bool _isPersonalizationAlreadyCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Convert slider value (0-95) to TimeOfDay
  TimeOfDay _sliderToTime(double sliderValue) {
    final totalMinutes = (sliderValue * 15).round();
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Convert TimeOfDay to slider value (0-95)
  double _timeToSlider(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;
    return totalMinutes / 15.0;
  }

  // Format time for display
  String _formatTime(TimeOfDay time) {
    return time.format(context);
  }

  // Format daylight duration for display
  String _formatDaylightDuration() {
    final wholeHours = _daylightDuration.floor();
    final minutes = ((_daylightDuration - wholeHours) * 60).round();
    
    if (minutes == 0) {
      return '${wholeHours}h 00m';
    } else {
      return '${wholeHours}h ${minutes}m';
    }
  }


  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      final synestheticSettings = Map<String, dynamic>.from(settings['synestetic_pitch'] as Map);
      
      // Load saved personalization if exists
      final progress = await _memoryService.ensureData();
      final personalizationData = progress.synestheticPitch.personalization;
      
      setState(() {
        _minInstantSessions = synestheticSettings['minumum_instant_sessions'] as int? ?? 3;
        _maxInstantSessions = synestheticSettings['maximum_instant_sessions'] as int? ?? 15;
        _defaultInstantSessions = synestheticSettings['default_instant_sessions'] as int? ?? 7;
        
        if (personalizationData != null) {
          final personalization = personalizationData;
          _morningTimeSlider = _timeToSlider(personalization.morningTime);
          _daylightDuration = personalization.daylightDurationHours;
          _instantSessions = personalization.instantSessionsPerDay.toDouble();
          _isPersonalizationAlreadyCompleted = personalization.completedAt != null;
          Log.i('Loaded saved personalization: morning=${personalization.morningSessionTime}, duration=${personalization.daylightDurationHours}, sessions=${personalization.instantSessionsPerDay}', tag: 'Personalization');
        } else {
          // Set default values
          _morningTimeSlider = 32.0; // 8:00 AM
          _daylightDuration = 12.0; // 12 hours
          _instantSessions = _defaultInstantSessions.toDouble();
          Log.i('No saved personalization found, using defaults', tag: 'Personalization');
        }
        
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Log.e('Error loading settings', error: e, stackTrace: stackTrace, tag: 'Personalization');
      setState(() {
        _isLoading = false;
      });
    }
  }


  PersonalizationSettings getStateAsPersonalizationSettings() {
    final morningTime = _sliderToTime(_morningTimeSlider);
    return PersonalizationSettings(
      morningSessionTime: '${morningTime.hour.toString().padLeft(2, '0')}:${morningTime.minute.toString().padLeft(2, '0')}',
      daylightDurationHours: _daylightDuration,
      instantSessionsPerDay: _instantSessions.round(),
      isCompleted: true,
    );
  }

  Future<void> _saveAndComplete() async {
    // Check if this is the first time completing personalization
    final progress = await _memoryService.ensureData();
    final existingPersonalization = progress.synestheticPitch.personalization;
    
    final isFirstCompletion = existingPersonalization == null 
        || !existingPersonalization.isCompleted 
        || existingPersonalization.completedAt == null;
    
    final personalization = getStateAsPersonalizationSettings().copyWith(
      completedAt: isFirstCompletion ? DateTime.now() : existingPersonalization.completedAt,
    );

    await _memoryService.savePersonalization(personalization);
    
    if (isFirstCompletion) {
      Log.i('🎉 Personalization completed for the first time at ${personalization.completedAt}', tag: 'Personalization');
    } else {
      Log.i('⚙️ Personalization updated (originally completed at ${personalization.completedAt})', tag: 'Personalization');
    }
    
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate completion
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Personalization'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Personalize Your Training'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.star, size: 48, color: Colors.amber[600]),
                    const SizedBox(height: 12),
                    Text(
                      'Customize Your Learning',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your daily practice schedule to maximize learning efficiency. Complete all sessions daily for 2x score bonus!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Morning Session Time
            _buildSettingCard(
              title: 'Morning Session Time',
              subtitle: 'Daily 5-minute practice reminder',
              icon: Icons.wb_sunny,
              iconColor: Colors.orange,
              child: Column(
                children: [
                  Text(
                    _formatTime(_sliderToTime(_morningTimeSlider)),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _morningTimeSlider,
                    min: 0,
                    max: 95, // 24 hours * 4 (15-min intervals) - 1
                    activeColor: Colors.orange[400],
                    inactiveColor: Colors.grey[200],
                    label: _formatTime(_sliderToTime(_morningTimeSlider)),
                    onChanged: (value) {
                      setState(() {
                        _morningTimeSlider = value.round().toDouble();
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('12:00 AM', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        Text('11:45 PM', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daylight Duration
            _buildSettingCard(
              title: 'Daylight Duration',
              subtitle: 'Practice window: ${_formatDaylightDuration()} (ends at ${_formatTime(getStateAsPersonalizationSettings().practiceEndTime)})',
              icon: Icons.brightness_6,
              iconColor: Colors.blue,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDaylightDuration(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        'Ends: ${_formatTime(getStateAsPersonalizationSettings().practiceEndTime)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _daylightDuration,
                    min: 8.0,
                    max: 16.0,
                    activeColor: Colors.blue[400],
                    inactiveColor: Colors.grey[200],
                    label: _formatDaylightDuration(),
                    onChanged: (value) {
                      setState(() {
                        // Round to nearest 0.25 (15 minutes)
                        _daylightDuration = (value * 4).round() / 4.0;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('8h', style: TextStyle(color: Colors.grey[600])),
                        Text('16h', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instant Sessions
            _buildSettingCard(
              title: 'Daily Instant Sessions',
              subtitle: '${_instantSessions.round()} quick sessions per day (30s-1min each)',
              icon: Icons.flash_on,
              iconColor: Colors.purple,
              child: Column(
                children: [
                  Slider(
                    value: _instantSessions,
                    min: _minInstantSessions.toDouble(),
                    max: _maxInstantSessions.toDouble(),
                    activeColor: Colors.purple[400],
                    inactiveColor: Colors.grey[200],
                    label: '${_instantSessions.round()}',
                    onChanged: (value) {
                      setState(() {
                        _instantSessions = value.round().toDouble();
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_minInstantSessions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Relaxed',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$_maxInstantSessions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Intensive',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Session Times
            _buildSettingCard(
              title: 'Session Schedule',
              subtitle: 'Your daily practice times',
              icon: Icons.schedule,
              iconColor: Colors.green,
              child: Column(
                children: [
                  Text(
                    '${_instantSessions.round() + 1} sessions throughout the day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: getStateAsPersonalizationSettings().getSessionTimes().asMap().entries.map((entry) {
                        final index = entry.key;
                        final time = entry.value;
                        final isMorning = index == 0;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isMorning ? Colors.orange[400] : Colors.green[400],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isMorning ? Icons.wb_sunny : Icons.music_note,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatTime(time),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isMorning ? 'Morning Session' : 'Instant Session',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bonus Info
            Card(
              elevation: 2,
              color: Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green[700], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2x Score Bonus!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            'Complete morning session and all instant sessions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Changes will be applied next day label
            if (_isPersonalizationAlreadyCompleted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Changes will be applied starting tomorrow',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAndComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Complete Setup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

