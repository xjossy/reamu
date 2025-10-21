import 'dart:convert';

class SynestheticSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> notesToGuess; // Random order of learned notes
  final List<String> correctlyGuessed;
  final List<String> incorrectlyGuessed;
  final Map<String, String> mistakes; // note -> guessed note

  SynestheticSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.notesToGuess,
    this.correctlyGuessed = const [],
    this.incorrectlyGuessed = const [],
    this.mistakes = const {},
  });

  bool get isCompleted => endTime != null;
  int get totalNotes => notesToGuess.length;
  int get completedNotes => correctlyGuessed.length + incorrectlyGuessed.length;
  int get remainingNotes => totalNotes - completedNotes;
  double get progress => totalNotes > 0 ? completedNotes / totalNotes : 0.0;
  double get accuracy => completedNotes > 0 ? correctlyGuessed.length / completedNotes : 0.0;

  List<String> get remainingNotesList {
    final completed = [...correctlyGuessed, ...incorrectlyGuessed];
    return notesToGuess.where((note) => !completed.contains(note)).toList();
  }

  String? get currentNote {
    final remaining = remainingNotesList;
    return remaining.isNotEmpty ? remaining.first : null;
  }

  SynestheticSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? notesToGuess,
    List<String>? correctlyGuessed,
    List<String>? incorrectlyGuessed,
    Map<String, String>? mistakes,
  }) {
    return SynestheticSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notesToGuess: notesToGuess ?? this.notesToGuess,
      correctlyGuessed: correctlyGuessed ?? this.correctlyGuessed,
      incorrectlyGuessed: incorrectlyGuessed ?? this.incorrectlyGuessed,
      mistakes: mistakes ?? this.mistakes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notesToGuess': notesToGuess,
      'correctlyGuessed': correctlyGuessed,
      'incorrectlyGuessed': incorrectlyGuessed,
      'mistakes': mistakes,
    };
  }

  factory SynestheticSession.fromJson(Map<String, dynamic> json) {
    return SynestheticSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      notesToGuess: List<String>.from(json['notesToGuess'] as List),
      correctlyGuessed: List<String>.from(json['correctlyGuessed'] as List? ?? []),
      incorrectlyGuessed: List<String>.from(json['incorrectlyGuessed'] as List? ?? []),
      mistakes: Map<String, String>.from(json['mistakes'] as Map? ?? {}),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SynestheticSession.fromJsonString(String jsonString) {
    return SynestheticSession.fromJson(jsonDecode(jsonString));
  }
}

