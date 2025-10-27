import 'package:json_annotation/json_annotation.dart';

part 'describing_question.g.dart';

/// Represents a single option in a describing question
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class QuestionOption {
  final String key;
  final String nameEn;

  const QuestionOption({
    required this.key,
    required this.nameEn,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionOptionToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class DescribingQuestion {
  final String key;
  final String question;
  final List<QuestionOption> options;

  const DescribingQuestion({
    required this.key,
    required this.question,
    required this.options,
  });

  factory DescribingQuestion.fromJson(Map<String, dynamic> json) =>
      _$DescribingQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$DescribingQuestionToJson(this);
}
