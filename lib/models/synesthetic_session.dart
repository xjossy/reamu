import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'synesthetic_session.g.dart';

@JsonSerializable(explicitToJson: true)
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

  factory SynestheticSession.fromJson(Map<String, dynamic> json) =>
      _$SynestheticSessionFromJson(json);

  Map<String, dynamic> toJson() => _$SynestheticSessionToJson(this);

  String toJsonString() => jsonEncode(toJson());

  factory SynestheticSession.fromJsonString(String jsonString) {
    return SynestheticSession.fromJson(jsonDecode(jsonString));
  }
}

