/// App state persisted as one JSON file in the app's private directory.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'calc.dart';
import 'models.dart';

const backupFormat = 'zahit-efendi';
const backupVersion = 1;

class AppStore extends ChangeNotifier {
  final File file;
  final SchoolTable schoolTable;

  List<Exam> _exams = [];
  Settings _settings = const Settings();

  AppStore(this.file, this.schoolTable);

  /// Oldest → newest.
  List<Exam> get exams => List.unmodifiable(_exams);
  Settings get settings => _settings;

  Exam? get latest => _exams.isEmpty ? null : _exams.last;
  Exam? get previousOfLatest =>
      _exams.length < 2 ? null : _exams[_exams.length - 2];

  /// The exam right before [e] in time, or null.
  Exam? previousOf(Exam e) {
    final i = _exams.indexWhere((x) => x.id == e.id);
    return i > 0 ? _exams[i - 1] : null;
  }

  Future<void> load() async {
    if (await file.exists()) {
      _apply(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> upsert(Exam e) async {
    _exams = chronological([..._exams.where((x) => x.id != e.id), e]);
    await _save();
  }

  Future<void> delete(String id) async {
    _exams = _exams.where((x) => x.id != id).toList();
    await _save();
  }

  Future<void> updateSettings(Settings s) async {
    _settings = s;
    await _save();
  }

  String exportJson() => const JsonEncoder.withIndent(' ').convert(_toJson());

  /// Replaces everything with a backup. Throws [FormatException] if the
  /// content is not a valid backup; in that case nothing changes.
  Future<void> importJson(String content) async {
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(content) as Map<String, dynamic>;
      if (j['format'] != backupFormat) throw const FormatException();
      _validate(j);
    } catch (_) {
      throw const FormatException('Bu dosya bir Zahit Efendi yedeği değil.');
    }
    _apply(j);
    await _save();
  }

  Map<String, dynamic> _toJson() => {
        'format': backupFormat,
        'version': backupVersion,
        'exams': _exams.map((e) => e.toJson()).toList(),
        'settings': _settings.toJson(),
      };

  void _validate(Map<String, dynamic> j) {
    for (final e in j['exams'] as List<dynamic>) {
      Exam.fromJson(e as Map<String, dynamic>);
    }
    Settings.fromJson(j['settings'] as Map<String, dynamic>);
  }

  void _apply(Map<String, dynamic> j) {
    _exams = chronological((j['exams'] as List<dynamic>)
        .map((e) => Exam.fromJson(e as Map<String, dynamic>)));
    _settings = Settings.fromJson(j['settings'] as Map<String, dynamic>);
  }

  Future<void> _save() async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(_toJson()), flush: true);
    await tmp.rename(file.path);
    notifyListeners();
  }

  // ------------------------------------------------ derived, used by screens

  MatchResult? matchesForLatest() {
    final e = latest;
    if (e == null) return null;
    return matchSchools(
      schools: schoolTable.schools,
      settings: _settings,
      studentPercentile: percentile(e),
      studentScore: e.score,
    );
  }
}

/// Makes the store reachable from any widget below it.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
