// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'describing_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionOption _$QuestionOptionFromJson(Map<String, dynamic> json) =>
    QuestionOption(
      key: json['key'] as String,
      nameEn: json['name_en'] as String,
    );

Map<String, dynamic> _$QuestionOptionToJson(QuestionOption instance) =>
    <String, dynamic>{'key': instance.key, 'name_en': instance.nameEn};

DescribingQuestion _$DescribingQuestionFromJson(Map<String, dynamic> json) =>
    DescribingQuestion(
      key: json['key'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DescribingQuestionToJson(DescribingQuestion instance) =>
    <String, dynamic>{
      'key': instance.key,
      'question': instance.question,
      'options': instance.options.map((e) => e.toJson()).toList(),
    };
