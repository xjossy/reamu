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
    // Parse options - can be either List<String> or List<Map> with 'name' field
    final optionsRaw = json['options'] as List;
    final List<String> parsedOptions;
    
    if (optionsRaw.isNotEmpty && optionsRaw.first is Map) {
      // New format: List of dictionaries with 'name' field
      parsedOptions = optionsRaw
          .map((option) => (option as Map)['name'] as String)
          .toList();
    } else {
      // Old format: List of strings (backward compatibility)
      parsedOptions = List<String>.from(optionsRaw);
    }
    
    return DescribingQuestion(
      key: json['key'] as String,
      question: json['question'] as String,
      options: parsedOptions,
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
