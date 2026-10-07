import 'package:flutter/material.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../provinces.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final e = store.latest;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Liseler')),
        body: const EmptyState(
          icon: Icons.school_outlined,
          title: 'Önce bir deneme ekleyin',
          body: 'Liseler son denemenin sonucuna göre listelenir.',
        ),
      );
    }
    final st = store.settings;
    final table = store.schoolTable;
    final byScore = st.mode == MatchMode.score;
    final match = store.matchesForLatest()!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Liseler'),
          Text(
            byScore
                ? '${e.name} puanı: ${fmt(e.score)}'
                : '${e.name} yüzdeliği: %${fmt(percentile(e))}',
            style: const TextStyle(fontSize: 14, color: C.line),
          ),
        ]),
      ),
      // Lazily built: a large province can list well over a thousand schools.
      body: Builder(builder: (context) {
        final rows = <Widget Function()>[
          () => _Filters(settings: st, onChanged: store.updateSettings),
          () => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  byScore
                      ? '${table.scoreYear} taban puanlarına göre'
                      : '${table.percentileYear} yüzdelik dilimlerine göre',
                  style: const TextStyle(fontSize: 13, color: C.muted),
                ),
              ),
          if (st.provinces.isEmpty)
            () => const EmptyState(
                  icon: Icons.location_on_outlined,
                  title: 'İl seçin',
                  body:
                      'Yukarıdaki "+ İl ekle" ile bir veya birden fazla il seçin.',
                )
          else ...[
            if (match.near.isNotEmpty) ...[
              () => const _GroupTitle(
                  Icons.trending_up, 'Biraz daha çalışırsa', C.accentInk),
              for (final m in match.near) () => _SchoolTile.near(m, byScore),
            ],
            () => _GroupTitle(Icons.check_circle_outline,
                'Girebildiği liseler (${match.eligible.length})', C.okInk),
            if (match.eligible.isEmpty)
              () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Seçili illerde uygun lise yok. İl ekleyin.',
                        style: TextStyle(color: C.muted)),
                  ),
            for (final (i, m) in match.eligible.indexed)
              () => _SchoolTile.eligible(m, byScore, i + 1),
          ],
        ];
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: rows.length,
          itemBuilder: (_, i) => rows[i](),
        );
      }),
    );
  }
}

class _Filters extends StatelessWidget {
  final Settings settings;
  final ValueChanged<Settings> onChanged;
  const _Filters({required this.settings, required this.onChanged});

  Future<void> _addProvince(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProvincePicker(exclude: settings.provinces),
    );
    if (picked != null) {
      onChanged(settings.copyWith(provinces: [...settings.provinces, picked]));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<MatchMode>(
              segments: const [
                ButtonSegment(
                    value: MatchMode.percentile,
                    label: Text('Yüzdeliğe göre')),
                ButtonSegment(
                    value: MatchMode.score, label: Text('Puana göre')),
              ],
              selected: {settings.mode},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: C.deep,
                selectedForegroundColor: Colors.white,
                foregroundColor: C.main,
                textStyle: const TextStyle(fontSize: 16),
              ),
              onSelectionChanged: (s) =>
                  onChanged(settings.copyWith(mode: s.first)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('İller', style: TextStyle(fontSize: 13, color: C.muted)),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final p in settings.provinces)
              InputChip(
                label: Text(p),
                backgroundColor: C.deep,
                labelStyle: const TextStyle(color: Colors.white),
                deleteIconColor: Colors.white,
                onDeleted: () => onChanged(settings.copyWith(
                    provinces:
                        settings.provinces.where((x) => x != p).toList())),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18, color: C.main),
              label: const Text('İl ekle'),
              labelStyle: const TextStyle(color: C.main),
              onPressed: () => _addProvince(context),
            ),
          ]),
          const SizedBox(height: 6),
          const Text('Okul türü',
              style: TextStyle(fontSize: 13, color: C.muted)),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final t in SchoolType.values)
              FilterChip(
                label: Text(t.label),
                selected: settings.types.contains(t),
                selectedColor: C.tint,
                checkmarkColor: C.deep,
                onSelected: (on) => onChanged(settings.copyWith(
                    types: on
                        ? {...settings.types, t}
                        : ({...settings.types}..remove(t)))),
              ),
          ]),
        ]),
      );
}

class _ProvincePicker extends StatefulWidget {
  final List<String> exclude;
  const _ProvincePicker({required this.exclude});

  @override
  State<_ProvincePicker> createState() => _ProvincePickerState();
}

class _ProvincePickerState extends State<_ProvincePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = provinces
        .where((p) => !widget.exclude.contains(p))
        .where((p) => foldTr(p).contains(foldTr(_q)))
        .toList();
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Konya',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(items[i], style: const TextStyle(fontSize: 18)),
                  onTap: () => Navigator.pop(context, items[i]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _GroupTitle(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}

class _SchoolTile extends StatelessWidget {
  final SchoolMatch m;
  final bool byScore;
  final int? rank;
  final bool isNear;

  const _SchoolTile.eligible(this.m, this.byScore, int this.rank)
      : isNear = false;
  const _SchoolTile.near(this.m, this.byScore)
      : rank = null,
        isNear = true;

  @override
  Widget build(BuildContext context) {
    final s = m.school;
    final value = byScore ? fmt(s.score!) : '%${fmt(s.percentile!)}';
    final String note;
    final Color noteColor;
    if (isNear) {
      note = byScore ? '${fmt(m.gap)} puan daha' : '%${fmt(m.gap)} daha iyi olmalı';
      noteColor = C.accentInk;
    } else {
      note = m.borderline ? 'Sınırda' : 'Rahat';
      noteColor = m.borderline ? C.accentInk : C.okInk;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: isNear ? C.accentTint : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isNear ? const Color(0xFFFAC775) : C.tint,
              child: isNear
                  ? const Icon(Icons.arrow_upward, size: 16, color: C.accentInk)
                  : Text('$rank',
                      style: const TextStyle(fontSize: 12, color: C.deep)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                Text('${s.province} / ${s.district} · ${s.type.label}',
                    style: TextStyle(
                        fontSize: 13,
                        color: isNear ? C.accentInk : C.muted)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              Text(note, style: TextStyle(fontSize: 12, color: noteColor)),
            ]),
          ]),
        ),
      ),
    );
  }
}
