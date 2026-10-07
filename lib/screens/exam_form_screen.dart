import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> openExamForm(BuildContext context, {Exam? exam}) =>
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExamFormScreen(exam: exam), fullscreenDialog: true));

class ExamFormScreen extends StatefulWidget {
  final Exam? exam;
  const ExamFormScreen({super.key, this.exam});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _participants;
  late final TextEditingController _rank;
  late final TextEditingController _score;
  late DateTime _date;
  late final Map<String, Answer> _answers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _name = TextEditingController(text: e?.name ?? '');
    _participants = TextEditingController(text: e?.participants.toString());
    _rank = TextEditingController(text: e?.rank.toString());
    _score = TextEditingController(text: e == null ? '' : fmt(e.score, 3));
    _date = e?.date ?? DateUtils.dateOnly(DateTime.now());
    _answers = {for (final s in subjects) s.key: e?.answer(s.key) ?? const Answer(0, 0)};
    for (final c in [_participants, _rank]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.exam == null && _name.text.isEmpty) {
      _name.text = suggestNextName(StoreScope.of(context).latest?.name);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _participants, _rank, _score]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _livePercentile {
    final p = int.tryParse(_participants.text);
    final r = int.tryParse(_rank.text);
    if (p == null || r == null || p < 1 || r < 1 || r > p) return null;
    return r / p * 100;
  }

  double get _liveTotal =>
      subjects.fold(0.0, (sum, s) => sum + net(_answers[s.key]!));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = StoreScope.of(context);
    await store.upsert(Exam(
      id: widget.exam?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      date: _date,
      participants: int.parse(_participants.text),
      rank: int.parse(_rank.text),
      score: parseDecimal(_score.text)!,
      answers: Map.of(_answers),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _livePercentile;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.exam == null ? 'Yeni deneme' : 'Denemeyi düzenle')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SectionLabel('Sınav bilgisi'),
            _card(Column(children: [
              _field('Sınav adı', _name,
                  keyboard: TextInputType.text,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Sınav adını yazın' : null),
              _row('Tarih',
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(fmtDate(_date),
                        style: const TextStyle(fontSize: 17)),
                  )),
              _field('Katılan kişi', _participants,
                  digitsOnly: true,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                      ? 'Katılan kişi sayısını yazın'
                      : null),
              _field('Sıralaması', _rank, digitsOnly: true, validator: (v) {
                final r = int.tryParse(v ?? '');
                final p = int.tryParse(_participants.text);
                if (r == null || r < 1) return 'Sıralamayı yazın';
                if (p != null && r > p) return 'Katılan kişiden büyük olamaz';
                return null;
              }),
              _field('LGS puanı', _score,
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                final s = parseDecimal(v ?? '');
                if (s == null) return 'Puanı yazın (ör. 470,25)';
                if (s < 0 || s > 500) return '0 ile 500 arasında olmalı';
                return null;
              }),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pct == null
                        ? 'Yüzdelik dilim: sıralama ve katılımdan hesaplanır'
                        : 'Yüzdelik dilim: %${fmt(pct)} (otomatik)',
                    style: const TextStyle(fontSize: 14, color: C.main),
                  ),
                ),
              ),
            ])),
            const SectionLabel('Dersler',
                trailing: Text('Doğru · Yanlış · Boş',
                    style: TextStyle(fontSize: 14, color: C.muted))),
            _card(Column(children: [
              for (final s in subjects)
                _SubjectInput(
                  subject: s,
                  answer: _answers[s.key]!,
                  onChanged: (a) => setState(() => _answers[s.key] = a),
                ),
            ])),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: C.tint, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Expanded(
                      child: Text('Toplam net',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: C.deep))),
                  Text('${fmt(_liveTotal)} / $totalQuestions',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, color: C.deep)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: BigButton(
                label: 'Kaydet',
                icon: Icons.check,
                onPressed: _saving ? () {} : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                child: child)),
      );

  Widget _row(String label, Widget trailing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: Text(label)), trailing]),
      );

  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.number,
    bool digitsOnly = false,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextFormField(
          controller: c,
          keyboardType: keyboard,
          inputFormatters:
              digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: C.bg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
          validator: validator,
        ),
      );
}

class _SubjectInput extends StatelessWidget {
  final Subject subject;
  final Answer answer;
  final ValueChanged<Answer> onChanged;
  const _SubjectInput(
      {required this.subject, required this.answer, required this.onChanged});

  void _set({int? correct, int? wrong}) {
    final a = Answer(correct ?? answer.correct, wrong ?? answer.wrong);
    if (isValidAnswer(subject, a)) onChanged(a);
  }

  @override
  Widget build(BuildContext context) {
    final maxCorrect = subject.questions - answer.wrong;
    final maxWrong = subject.questions - answer.correct;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Text(subject.name,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Text('net ${fmt(net(answer))}',
              style: const TextStyle(fontSize: 14, color: C.muted)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          CountStepper(
            key: Key('${subject.key}-correct'),
            value: answer.correct,
            max: maxCorrect,
            color: C.up,
            label: '${subject.name} doğru',
            onChanged: (v) => _set(correct: v),
          ),
          const SizedBox(width: 14),
          CountStepper(
            key: Key('${subject.key}-wrong'),
            value: answer.wrong,
            max: maxWrong,
            color: C.down,
            label: '${subject.name} yanlış',
            onChanged: (v) => _set(wrong: v),
          ),
          const Spacer(),
          Text('${blank(subject, answer)}',
              key: Key('${subject.key}-blank'),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500, color: C.blank)),
        ]),
      ]),
    );
  }
}

/// − value + ; tapping the value opens a number keyboard.
class CountStepper extends StatelessWidget {
  final int value;
  final int max;
  final Color color;
  final String label;
  final ValueChanged<int> onChanged;
  const CountStepper({
    super.key,
    required this.value,
    required this.max,
    required this.color,
    required this.label,
    required this.onChanged,
  });

  Future<void> _type(BuildContext context) async {
    final c = TextEditingController(text: '$value');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(helperText: 'En fazla $max'),
          onSubmitted: (t) => Navigator.pop(ctx, int.tryParse(t)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)),
              child: const Text('Tamam')),
        ],
      ),
    );
    c.dispose();
    if (v != null) onChanged(v.clamp(0, max));
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        _btn(Icons.remove, value > 0 ? () => onChanged(value - 1) : null,
            '$label azalt'),
        InkWell(
          onTap: () => _type(context),
          child: SizedBox(
            width: 38,
            height: 40,
            child: Center(
              child: Text('$value',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w500, color: color)),
            ),
          ),
        ),
        _btn(Icons.add, value < max ? () => onChanged(value + 1) : null,
            '$label artır'),
      ]);

  Widget _btn(IconData icon, VoidCallback? onTap, String tooltip) => SizedBox(
        width: 40,
        height: 40,
        child: IconButton.filledTonal(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
              backgroundColor: C.tint,
              foregroundColor: C.deep,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: onTap,
          icon: Icon(icon, size: 20),
        ),
      );
}
