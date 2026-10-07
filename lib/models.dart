/// Domain types. Everything here is plain data with JSON round-tripping.
library;

class Subject {
  final String key;
  final String name;
  final int questions;
  const Subject(this.key, this.name, this.questions);
}

const subjects = <Subject>[
  Subject('tr', 'Türkçe', 20),
  Subject('mat', 'Matematik', 20),
  Subject('fen', 'Fen', 20),
  Subject('ink', 'İnkılap', 10),
  Subject('din', 'Din', 10),
  Subject('ing', 'İngilizce', 10),
];

final int totalQuestions = subjects.fold(0, (s, x) => s + x.questions);

class Answer {
  final int correct;
  final int wrong;
  const Answer(this.correct, this.wrong);

  List<int> toJson() => [correct, wrong];
  factory Answer.fromJson(List<dynamic> j) =>
      Answer((j[0] as num).toInt(), (j[1] as num).toInt());
}

class Exam {
  final String id;
  final String name;
  final DateTime date;
  final int participants;
  final int rank;
  final double score;
  final Map<String, Answer> answers;

  const Exam({
    required this.id,
    required this.name,
    required this.date,
    required this.participants,
    required this.rank,
    required this.score,
    required this.answers,
  });

  Answer answer(String key) => answers[key] ?? const Answer(0, 0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String().substring(0, 10),
        'participants': participants,
        'rank': rank,
        'score': score,
        'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: j['id'] as String,
        name: j['name'] as String,
        date: DateTime.parse(j['date'] as String),
        participants: (j['participants'] as num).toInt(),
        rank: (j['rank'] as num).toInt(),
        score: (j['score'] as num).toDouble(),
        answers: (j['answers'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, Answer.fromJson(v as List<dynamic>))),
      );
}

enum SchoolType {
  fen('Fen'),
  sosyal('Sosyal Bilimler'),
  anadolu('Anadolu'),
  imamHatip('İmam Hatip'),
  mesleki('Mesleki');

  final String label;
  const SchoolType(this.label);

  static SchoolType byName(String n) => values.firstWhere((t) => t.name == n);
}

class School {
  final String name;
  final String province;
  final String district;
  final SchoolType type;

  /// Taban puanı (2026, MEB). Null when the school has no score-based cutoff.
  final double? score;

  /// Taban yüzdelik dilimi (most recent official year). Null when unknown.
  final double? percentile;

  const School({
    required this.name,
    required this.province,
    required this.district,
    required this.type,
    this.score,
    this.percentile,
  });

  factory School.fromJson(Map<String, dynamic> j) => School(
        name: j['name'] as String,
        province: j['province'] as String,
        district: j['district'] as String,
        type: SchoolType.byName(j['type'] as String),
        score: (j['score'] as num?)?.toDouble(),
        percentile: (j['percentile'] as num?)?.toDouble(),
      );
}

/// The embedded school table plus the years its two columns come from.
class SchoolTable {
  final int scoreYear;
  final int percentileYear;
  final List<School> schools;
  const SchoolTable(this.scoreYear, this.percentileYear, this.schools);

  factory SchoolTable.fromJson(Map<String, dynamic> j) => SchoolTable(
        (j['scoreYear'] as num).toInt(),
        (j['percentileYear'] as num).toInt(),
        (j['schools'] as List<dynamic>)
            .map((s) => School.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  static const empty = SchoolTable(0, 0, []);
}

enum MatchMode { percentile, score }

class Settings {
  final List<String> provinces;
  final Set<SchoolType> types;
  final MatchMode mode;

  const Settings({
    this.provinces = const [],
    this.types = const {
      SchoolType.fen,
      SchoolType.sosyal,
      SchoolType.anadolu,
      SchoolType.imamHatip,
      SchoolType.mesleki,
    },
    this.mode = MatchMode.percentile,
  });

  Settings copyWith({
    List<String>? provinces,
    Set<SchoolType>? types,
    MatchMode? mode,
  }) =>
      Settings(
        provinces: provinces ?? this.provinces,
        types: types ?? this.types,
        mode: mode ?? this.mode,
      );

  Map<String, dynamic> toJson() => {
        'provinces': provinces,
        'types': types.map((t) => t.name).toList(),
        'mode': mode.name,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        provinces: (j['provinces'] as List<dynamic>).cast<String>(),
        types: (j['types'] as List<dynamic>)
            .map((n) => SchoolType.byName(n as String))
            .toSet(),
        mode: MatchMode.values.byName(j['mode'] as String),
      );
}
