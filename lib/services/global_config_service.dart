import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/describing_question.dart';
import 'logging_service.dart';

class ConfigValue {
  final List<DescribingQuestion> questions;
  final Map<String, int> questionMap;
  
  const ConfigValue({
    required this.questions,
    required this.questionMap,
  });
  
  /// Get a specific question by its key
  DescribingQuestion? getQuestion(String key) {
    if (!questionMap.containsKey(key)) {
      Log.w('Question with key "$key" not found', tag: 'Config');
      return null;
    }
    return questions[questionMap[key]!];
  }
  
  /// Get all questions as a list
  List<DescribingQuestion> getAllQuestions() {
    return List.unmodifiable(questions);
  }
}

class GlobalConfigService {
  static GlobalConfigService? _instance;
  ConfigValue? _value;
  
  GlobalConfigService._();
  
  static GlobalConfigService get instance {
    _instance ??= GlobalConfigService._();
    return _instance!;
  }
  
  /// Get the config value - loads if not already loaded
  Future<ConfigValue> value() async {
    if (_value != null) return _value!;
    
    try {
      final yamlString = await rootBundle.loadString('assets/describing_questions.yaml');
      final yamlData = loadYaml(yamlString);
      final questionsData = yamlData['questions'] as List;
      
      final questions = questionsData
          .map((q) => DescribingQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList();

      final questionMap = <String, int>{
        for (int i = 0; i < questions.length; i++)
          questions[i].key: i
      };
      
      _value = ConfigValue(questions: questions, questionMap: questionMap);
      Log.d('Loaded ${questions.length} describing questions', tag: 'Config');
      
      return _value!;
    } catch (e, stackTrace) {
      Log.e('Error loading describing questions', error: e, stackTrace: stackTrace, tag: 'Config');
      _value = const ConfigValue(questions: [], questionMap: {});
      return _value!;
    }
  }
}
