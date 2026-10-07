import 'package:flutter/material.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'exam_form_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenSchools;
  const HomeScreen({super.key, required this.onOpenSchools});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final e = store.latest;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zahit Efendi')),
        body: EmptyState(
          icon: Icons.assignment_outlined,
          title: 'İlk denemeyi ekleyin',
          body: 'Deneme sonuçlarını girdikçe ilerleme burada görünecek.',
          action: BigButton(
            label: 'Yeni deneme ekle',
            icon: Icons.add,
            onPressed: () => openExamForm(context),
          ),
        ),
      );
    }
    final prev = store.previousOfLatest;
    final match = store.matchesForLatest()!;
    final noProvince = store.settings.provinces.isEmpty;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(exam: e),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
              children: [
                _scoreCard(e, prev),
                _percentileCard(e, prev),
                _netCard(e, prev),
                StatCard(
                  label: 'Girebildiği lise',
                  value: noProvince ? '—' : '${match.eligible.length}',
                  note: noProvince ? 'İl seçin ›' : 'Listeyi gör ›',
                  highlighted: true,
                  onTap: onOpenSchools,
                ),
              ],
            ),
          ),
          const SectionLabel('Ders netleri'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  for (final s in subjects) _SubjectRow(s, e, prev),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: BigButton(
              label: 'Yeni deneme ekle',
              icon: Icons.add,
              onPressed: () => openExamForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(Exam e, Exam? prev) {
    final d = prev == null ? null : e.score - prev.score;
    return StatCard(
      label: 'LGS puanı',
      value: fmt(e.score),
      trend: trend(e.score, prev?.score),
      note: d == null ? null : '${d >= 0 ? '+' : ''}${fmt(d)}',
      noteColor: d == null ? null : (d >= 0 ? C.up : C.down),
    );
  }

  Widget _percentileCard(Exam e, Exam? prev) => StatCard(
        label: 'Yüzdelik dilim',
        value: '%${fmt(percentile(e))}',
        trend: trend(percentile(e), prev == null ? null : percentile(prev),
            lowerIsBetter: true),
        note: '${e.rank}. / ${e.participants} kişi',
      );

  Widget _netCard(Exam e, Exam? prev) => StatCard(
        label: 'Toplam net',
        value: fmt(totalNet(e)),
        trend: trend(totalNet(e), prev == null ? null : totalNet(prev)),
        note: '$totalQuestions sorudan',
      );
}

class _Header extends StatelessWidget {
  final Exam exam;
  const _Header({required this.exam});

  @override
  Widget build(BuildContext context) => Container(
        color: C.deep,
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.paddingOf(context).top + 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Son deneme',
                style: TextStyle(fontSize: 14, color: C.line)),
            Text('${exam.name} · ${fmtLongDate(exam.date)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ],
        ),
      );
}

class _SubjectRow extends StatelessWidget {
  final Subject s;
  final Exam e;
  final Exam? prev;
  const _SubjectRow(this.s, this.e, this.prev);

  @override
  Widget build(BuildContext context) {
    final a = e.answer(s.key);
    final n = net(a);
    final ratio = (n / s.questions).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 96, child: Text(s.name)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 11,
              backgroundColor: C.tint,
              color: isWeak(s, a) ? C.accent : C.main,
            ),
          ),
        ),
        SizedBox(
            width: 58,
            child: Text(fmt(n),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        SizedBox(
          width: 22,
          child: Align(
            alignment: Alignment.centerRight,
            child: TrendArrow(trend(n,
                prev == null ? null : net(prev!.answer(s.key)))),
          ),
        ),
      ]),
    );
  }
}
