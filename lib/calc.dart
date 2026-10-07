/// Pure scoring and matching logic. No Flutter imports, fully unit-tested.
library;

import 'models.dart';

double net(Answer a) => a.correct - a.wrong / 3;

int blank(Subject s, Answer a) => s.questions - a.correct - a.wrong;

bool isValidAnswer(Subject s, Answer a) =>
    a.correct >= 0 && a.wrong >= 0 && a.correct + a.wrong <= s.questions;

double totalNet(Exam e) =>
    subjects.fold(0.0, (sum, s) => sum + net(e.answer(s.key)));

/// Deneme yüzdeliği: sıralama / katılım × 100.
double percentile(Exam e) => e.rank / e.participants * 100;

enum Trend { better, worse, same, none }

const _eps = 1e-9;

/// Compares [current] with [previous]. [lowerIsBetter] is true for percentile.
Trend trend(double current, double? previous, {bool lowerIsBetter = false}) {
  if (previous == null) return Trend.none;
  final d = current - previous;
  if (d.abs() < _eps) return Trend.same;
  return (d > 0) != lowerIsBetter ? Trend.better : Trend.worse;
}

/// Exams sorted oldest → newest (stable on equal dates by id).
List<Exam> chronological(Iterable<Exam> exams) => exams.toList()
  ..sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.id.compareTo(b.id);
  });

/// "AGİS-2" → "AGİS-3"; anything without a trailing number → "".
String suggestNextName(String? last) {
  if (last == null) return '';
  final m = RegExp(r'^(.*?)(\d+)$').firstMatch(last.trim());
  if (m == null) return '';
  return '${m.group(1)}${int.parse(m.group(2)!) + 1}';
}

/// A subject is weak when its net is under 75% of its questions.
bool isWeak(Subject s, Answer a) => net(a) < s.questions * 0.75;

// ---------------------------------------------------------------- matching

const nearPercentileRatio = 0.8; // tabanı öğrencinin en fazla %20 daha iyisi
const nearScoreGap = 15.0; // en fazla 15 puan yukarısı
const borderPercentileGap = 2.0;
const borderScoreGap = 5.0;

class SchoolMatch {
  final School school;

  /// Distance to the student, always ≥ 0, in the mode's unit
  /// (percentage points or score points).
  final double gap;

  /// True for "Sınırda"; only meaningful for eligible schools.
  final bool borderline;

  const SchoolMatch(this.school, this.gap, this.borderline);
}

class MatchResult {
  /// Girebildiği liseler, en yüksekten aşağı.
  final List<SchoolMatch> eligible;

  /// "Biraz daha çalışırsa": just out of reach, en yüksekten aşağı.
  final List<SchoolMatch> near;

  const MatchResult(this.eligible, this.near);
}

MatchResult matchSchools({
  required List<School> schools,
  required Settings settings,
  required double studentPercentile,
  required double studentScore,
}) {
  final pool = schools.where((s) =>
      settings.provinces.contains(s.province) &&
      settings.types.contains(s.type));
  final eligible = <SchoolMatch>[];
  final near = <SchoolMatch>[];

  switch (settings.mode) {
    case MatchMode.percentile:
      for (final s in pool) {
        final p = s.percentile;
        if (p == null) continue;
        if (p >= studentPercentile - _eps) {
          final gap = p - studentPercentile;
          eligible.add(SchoolMatch(s, gap, gap < borderPercentileGap));
        } else if (p >= studentPercentile * nearPercentileRatio) {
          near.add(SchoolMatch(s, studentPercentile - p, false));
        }
      }
      int byPct(SchoolMatch a, SchoolMatch b) =>
          a.school.percentile!.compareTo(b.school.percentile!);
      eligible.sort(byPct);
      near.sort(byPct);
    case MatchMode.score:
      for (final s in pool) {
        final t = s.score;
        if (t == null) continue;
        if (t <= studentScore + _eps) {
          final gap = studentScore - t;
          eligible.add(SchoolMatch(s, gap, gap < borderScoreGap));
        } else if (t <= studentScore + nearScoreGap) {
          near.add(SchoolMatch(s, t - studentScore, false));
        }
      }
      int byScore(SchoolMatch a, SchoolMatch b) =>
          b.school.score!.compareTo(a.school.score!);
      eligible.sort(byScore);
      near.sort(byScore);
  }
  return MatchResult(eligible, near);
}
