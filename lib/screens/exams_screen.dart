import 'package:flutter/material.dart';

import '../backup.dart';
import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'exam_form_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final newestFirst = store.exams.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denemeler'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'export'
                ? exportBackup(context)
                : importBackup(context),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Yedekle (paylaş)')),
              PopupMenuItem(value: 'import', child: Text('Yedekten geri yükle')),
            ],
          ),
        ],
      ),
      body: newestFirst.isEmpty
          ? const EmptyState(
              icon: Icons.list_alt,
              title: 'Henüz deneme yok',
              body: 'Ana sayfadaki "Yeni deneme ekle" ile başlayın.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: newestFirst.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ExamCard(
                key: ValueKey(newestFirst[i].id),
                exam: newestFirst[i],
                previous: store.previousOf(newestFirst[i]),
                initiallyOpen: i == 0,
              ),
            ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final Exam? previous;
  final bool initiallyOpen;
  const _ExamCard(
      {super.key,
      required this.exam,
      required this.previous,
      required this.initiallyOpen});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Denemeyi sil'),
        content: Text('"${exam.name}" silinsin mi? Bu geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.down),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await StoreScope.of(context).delete(exam.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = previous;
    final pct = percentile(exam);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyOpen,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Row(children: [
          Expanded(
              child: Text(exam.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500))),
          Text(fmtDate(exam.date),
              style: const TextStyle(fontSize: 14, color: C.muted)),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _mini('LGS puanı', fmt(exam.score),
                  trend(exam.score, p?.score)),
              const SizedBox(width: 6),
              _mini('Yüzdelik', '%${fmt(pct)}',
                  trend(pct, p == null ? null : percentile(p),
                      lowerIsBetter: true)),
              const SizedBox(width: 6),
              _mini('Net', fmt(totalNet(exam)),
                  trend(totalNet(exam), p == null ? null : totalNet(p))),
            ]),
            const SizedBox(height: 6),
            Text('Sıralama ${exam.rank} / ${exam.participants}',
                style: const TextStyle(fontSize: 13, color: C.muted)),
          ]),
        ),
        children: [
          const Divider(color: C.tint),
          _table(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                    backgroundColor: C.tint, foregroundColor: C.deep),
                onPressed: () => openExamForm(context, exam: exam),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Düzenle'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFCEBEB),
                    foregroundColor: const Color(0xFFA32D2D)),
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Sil'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _mini(String label, String value, Trend t) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
              color: C.bg, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: C.muted)),
            Row(children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: C.ink)),
                ),
              ),
              const SizedBox(width: 4),
              TrendArrow(t, size: 13),
            ]),
          ]),
        ),
      );

  Widget _table() {
    const head = TextStyle(fontSize: 13, color: C.muted);
    TableRow row(List<Widget> cells) => TableRow(
        children: cells
            .map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4), child: c))
            .toList());
    Widget cell(String t, Color c, {bool bold = false}) => Text(t,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: c,
            fontSize: 15,
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400));
    return Table(
      columnWidths: const {0: FlexColumnWidth(2.2)},
      children: [
        row(const [
          Text('Ders', style: head),
          Text('D', style: head, textAlign: TextAlign.center),
          Text('Y', style: head, textAlign: TextAlign.center),
          Text('B', style: head, textAlign: TextAlign.center),
          Text('Net', style: head, textAlign: TextAlign.center),
        ]),
        for (final s in subjects)
          row([
            Text(s.name, style: const TextStyle(fontSize: 15)),
            cell('${exam.answer(s.key).correct}', C.up),
            cell('${exam.answer(s.key).wrong}', C.down),
            cell('${blank(s, exam.answer(s.key))}', C.blank),
            cell(fmt(net(exam.answer(s.key))), C.ink, bold: true),
          ]),
      ],
    );
  }
}
