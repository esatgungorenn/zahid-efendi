import 'package:zahit_efendi/models.dart';

Exam exam(
  String id, {
  String name = 'D',
  DateTime? date,
  int participants = 348,
  int rank = 53,
  double score = 467.434,
  Map<String, Answer> answers = const {},
}) =>
    Exam(
      id: id,
      name: name,
      date: date ?? DateTime(2026, 9, 30),
      participants: participants,
      rank: rank,
      score: score,
      answers: answers,
    );

School school(String name,
        {String province = 'Ankara',
        SchoolType type = SchoolType.anadolu,
        double? score,
        double? percentile}) =>
    School(
        name: name,
        province: province,
        district: 'X',
        type: type,
        score: score,
        percentile: percentile);
