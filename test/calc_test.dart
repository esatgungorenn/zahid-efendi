import 'package:flutter_test/flutter_test.dart';
import 'package:zahit_efendi/calc.dart';
import 'package:zahit_efendi/models.dart';

import 'helpers.dart';

void main() {
  final tr = subjects.first;
  final ink = subjects.firstWhere((s) => s.key == 'ink');

  group('net / blank', () {
    test('net = D − Y/3 (AGİS-2 Türkçe 15/5)', () {
      expect(net(const Answer(15, 5)), closeTo(13.3333, 1e-4));
    });
    test('blank fills the rest', () {
      expect(blank(tr, const Answer(15, 5)), 0);
      expect(blank(ink, const Answer(7, 1)), 2);
    });
    test('validity bounds', () {
      expect(isValidAnswer(tr, const Answer(20, 0)), isTrue);
      expect(isValidAnswer(tr, const Answer(15, 6)), isFalse);
      expect(isValidAnswer(ink, const Answer(11, 0)), isFalse);
      expect(isValidAnswer(tr, const Answer(-1, 0)), isFalse);
    });
    test('total net over 6 subjects; missing subjects count as 0', () {
      final e = exam('a', answers: {
        'tr': const Answer(15, 5),
        'mat': const Answer(20, 0),
        'fen': const Answer(19, 1),
      });
      expect(totalNet(e), closeTo(13.3333 + 20 + 18.6667, 1e-3));
      expect(totalQuestions, 90);
    });
    test('weak below 75%', () {
      expect(isWeak(tr, const Answer(15, 5)), isTrue); // 13.33 < 15
      expect(isWeak(tr, const Answer(16, 0)), isFalse);
    });
  });

  group('percentile', () {
    test('rank / participants × 100', () {
      expect(percentile(exam('a', rank: 53, participants: 348)),
          closeTo(15.2299, 1e-4));
      expect(percentile(exam('a', rank: 4, participants: 348)),
          closeTo(1.1494, 1e-4));
    });
  });

  group('trend', () {
    test('higher is better by default', () {
      expect(trend(467.4, 460.8), Trend.better);
      expect(trend(15, 17), Trend.worse);
      expect(trend(10, 10), Trend.same);
      expect(trend(10, null), Trend.none);
    });
    test('percentile: lower is better', () {
      expect(trend(15.23, 15.49, lowerIsBetter: true), Trend.better);
      expect(trend(20, 15, lowerIsBetter: true), Trend.worse);
    });
  });

  test('chronological sorts by date then id', () {
    final a = exam('2', date: DateTime(2026, 9, 23));
    final b = exam('1', date: DateTime(2026, 9, 30));
    final c = exam('3', date: DateTime(2026, 9, 23));
    expect(chronological([b, c, a]).map((e) => e.id), ['2', '3', '1']);
  });

  test('suggestNextName', () {
    expect(suggestNextName('AGİS-2'), 'AGİS-3');
    expect(suggestNextName('Deneme 9'), 'Deneme 10');
    expect(suggestNextName('Sene başı'), '');
    expect(suggestNextName(null), '');
  });

  group('matchSchools', () {
    final schools = [
      school('Fen A', type: SchoolType.fen, score: 490, percentile: 0.9),
      school('Anadolu B', score: 470, percentile: 13.4), // near (pct)
      school('Anadolu C', score: 466, percentile: 16.1), // eligible, border
      school('Anadolu D', score: 440, percentile: 27.6), // eligible, rahat
      school('Konya E', province: 'Konya', score: 450, percentile: 20),
      school('Mesleki F', type: SchoolType.mesleki, score: 400, percentile: 40),
      school('No pct', score: 300),
    ];
    const settings = Settings(provinces: ['Ankara']);

    MatchResult run(Settings s) => matchSchools(
        schools: schools,
        settings: s,
        studentPercentile: 15.23,
        studentScore: 467.43);

    test('percentile mode: eligible ascending, near within 20%', () {
      final r = run(settings);
      expect(r.eligible.map((m) => m.school.name),
          ['Anadolu C', 'Anadolu D', 'Mesleki F']);
      expect(r.eligible.first.borderline, isTrue);
      expect(r.eligible[1].borderline, isFalse);
      expect(r.near.map((m) => m.school.name), ['Anadolu B']);
      expect(r.near.single.gap, closeTo(1.83, 1e-9));
    });

    test('score mode: eligible descending, near within 15 points', () {
      final r = run(settings.copyWith(mode: MatchMode.score));
      expect(r.eligible.map((m) => m.school.name),
          ['Anadolu C', 'Anadolu D', 'Mesleki F', 'No pct']);
      expect(r.eligible.first.borderline, isTrue); // 1.43 < 5
      expect(r.near.map((m) => m.school.name), ['Anadolu B']);
      expect(r.near.single.gap, closeTo(2.57, 1e-9));
    });

    test('province and type filters', () {
      final r = run(const Settings(
          provinces: ['Ankara', 'Konya'],
          types: {SchoolType.anadolu, SchoolType.fen}));
      expect(r.eligible.map((m) => m.school.name),
          ['Anadolu C', 'Konya E', 'Anadolu D']);
    });

    test('no province selected → nothing', () {
      final r = run(const Settings());
      expect(r.eligible, isEmpty);
      expect(r.near, isEmpty);
    });

    test('exact tie counts as eligible', () {
      final r = matchSchools(
          schools: [school('T', score: 467.43, percentile: 15.23)],
          settings: settings,
          studentPercentile: 15.23,
          studentScore: 467.43);
      expect(r.eligible, hasLength(1));
      final s = matchSchools(
          schools: [school('T', score: 467.43, percentile: 15.23)],
          settings: settings.copyWith(mode: MatchMode.score),
          studentPercentile: 15.23,
          studentScore: 467.43);
      expect(s.eligible, hasLength(1));
    });
  });
}
