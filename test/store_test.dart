import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zahit_efendi/models.dart';
import 'package:zahit_efendi/store.dart';

import 'helpers.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ze_store');
    file = File('${dir.path}/data.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  AppStore newStore() => AppStore(file, SchoolTable.empty);

  test('starts empty when no file', () async {
    final s = newStore();
    await s.load();
    expect(s.exams, isEmpty);
    expect(s.latest, isNull);
  });

  test('upsert keeps chronological order and persists', () async {
    final s = newStore();
    await s.upsert(exam('b', date: DateTime(2026, 9, 30), name: 'AGİS-2'));
    await s.upsert(exam('a', date: DateTime(2026, 9, 23), name: 'AGİS-1',
        answers: {'tr': const Answer(17, 3)}));
    await s.updateSettings(const Settings(
        provinces: ['Konya'], mode: MatchMode.score));

    final r = newStore();
    await r.load();
    expect(r.exams.map((e) => e.name), ['AGİS-1', 'AGİS-2']);
    expect(r.latest!.name, 'AGİS-2');
    expect(r.previousOfLatest!.name, 'AGİS-1');
    expect(r.exams.first.answer('tr').wrong, 3);
    expect(r.settings.provinces, ['Konya']);
    expect(r.settings.mode, MatchMode.score);
  });

  test('edit replaces by id, delete removes', () async {
    final s = newStore();
    await s.upsert(exam('a', score: 400));
    await s.upsert(exam('a', score: 410));
    expect(s.exams.single.score, 410);
    await s.delete('a');
    expect(s.exams, isEmpty);
  });

  test('export → import round-trips', () async {
    final s = newStore();
    await s.upsert(exam('a', name: 'X'));
    final json = s.exportJson();

    final other = AppStore(File('${dir.path}/other.json'), SchoolTable.empty);
    await other.importJson(json);
    expect(other.exams.single.name, 'X');
  });

  test('import rejects foreign files and leaves data intact', () async {
    final s = newStore();
    await s.upsert(exam('a'));
    for (final bad in ['nope', '{}', '{"format":"zahit-efendi","exams":[{}]}']) {
      await expectLater(s.importJson(bad), throwsFormatException);
    }
    expect(s.exams, hasLength(1));
  });
}
