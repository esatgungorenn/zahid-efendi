import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zahit_efendi/models.dart';
import 'package:zahit_efendi/provinces.dart';

void main() {
  test('assets/schools.json parses and is consistent', () {
    final table = SchoolTable.fromJson(
        jsonDecode(File('assets/schools.json').readAsStringSync())
            as Map<String, dynamic>);
    expect(table.scoreYear, greaterThanOrEqualTo(2025));
    expect(table.percentileYear, greaterThanOrEqualTo(2025));
    for (final s in table.schools) {
      expect(provinces, contains(s.province), reason: s.name);
      expect(s.score != null || s.percentile != null, isTrue, reason: s.name);
      if (s.score != null) expect(s.score, inInclusiveRange(100, 500));
      if (s.percentile != null) expect(s.percentile, inInclusiveRange(0, 100));
    }
  });

  test('81 provinces, unique', () {
    expect(provinces.toSet(), hasLength(81));
  });

  test('Turkish search folding', () {
    expect(foldTr('İSTANBUL'), 'istanbul');
    expect(foldTr('Iğdır'), 'igdir');
    expect(foldTr('Şanlıurfa').contains(foldTr('sanli')), isTrue);
  });
}
