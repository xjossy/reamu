class DescribingQuestion {
  final String key;
  final String question;
  final List<String> options;

  const DescribingQuestion({
    required this.key,
    required this.question,
    required this.options,
  });

  factory DescribingQuestion.fromJson(Map<String, dynamic> json) {
    return DescribingQuestion(
      key: json['key'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'question': question,
      'options': options,
    };
  }
}
