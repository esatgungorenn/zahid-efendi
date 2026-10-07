import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

enum _Kind { score, percentile, net, subject }

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  _Kind _kind = _Kind.score;
  Subject _subject = subjects.first;

  @override
  Widget build(BuildContext context) {
    final exams = StoreScope.of(context).exams;
    return Scaffold(
      appBar: AppBar(title: const Text('Grafikler')),
      body: exams.isEmpty
          ? const EmptyState(
              icon: Icons.show_chart,
              title: 'Grafik için deneme gerekli',
              body: 'Deneme ekledikçe ilerleme grafikleri burada çizilecek.',
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip('LGS puanı', _Kind.score),
                  _chip('Yüzdelik', _Kind.percentile),
                  _chip('Toplam net', _Kind.net),
                  _chip('Dersler', _Kind.subject),
                ]),
                if (_kind == _Kind.subject) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final s in subjects)
                      ChoiceChip(
                        label: Text(s.name),
                        selected: s == _subject,
                        selectedColor: C.accent,
                        labelStyle: TextStyle(
                            color: s == _subject ? C.onAccent : C.deep),
                        onSelected: (_) => setState(() => _subject = s),
                      ),
                  ]),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 16, 8),
                    child: SizedBox(height: 260, child: _chart(exams)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: C.tint, borderRadius: BorderRadius.circular(12)),
                  child: Text(_summary(exams),
                      style: const TextStyle(color: C.deep, fontSize: 16)),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, _Kind k) => ChoiceChip(
        label: Text(label),
        selected: _kind == k,
        selectedColor: C.deep,
        showCheckmark: false,
        labelStyle: TextStyle(color: _kind == k ? Colors.white : C.main),
        onSelected: (_) => setState(() => _kind = k),
      );

  List<double> _values(List<Exam> exams) => switch (_kind) {
        _Kind.score => exams.map((e) => e.score).toList(),
        _Kind.percentile => exams.map(percentile).toList(),
        _Kind.net => exams.map(totalNet).toList(),
        _Kind.subject => exams.map((e) => net(e.answer(_subject.key))).toList(),
      };

  String _summary(List<Exam> exams) {
    final v = _values(exams);
    final last = v.last;
    if (v.length == 1) return 'İlk deneme: ${fmt(last)}. Yeni denemelerle karşılaştırma burada görünecek.';
    final first = v.first;
    final prev = v[v.length - 2];
    String signed(double d) => '${d >= 0 ? '+' : ''}${fmt(d)}';
    return switch (_kind) {
      _Kind.score => 'İlk denemeden bu yana ${signed(last - first)} puan.',
      _Kind.percentile =>
        'Yüzdelik %${fmt(first)} → %${fmt(last)}. Grafik ters: yukarı çıkmak daha iyi demek.',
      _Kind.net =>
        '$totalQuestions sorudan ${fmt(last)} net. İlk denemeye göre ${signed(last - first)}.',
      _Kind.subject =>
        '${_subject.name}: son deneme ${fmt(last)} / ${_subject.questions} net (önceki denemeye göre ${signed(last - prev)}).',
    };
  }

  Widget _chart(List<Exam> exams) {
    final values = _values(exams);
    final inverted = _kind == _Kind.percentile;
    final color = switch (_kind) {
      _Kind.percentile => const Color(0xFF1D9E75),
      _Kind.subject => C.accent,
      _ => C.main,
    };
    // Percentile is drawn as negative values so "up" means "better".
    final ys = inverted ? values.map((v) => -v).toList() : values;

    final (double minY, double maxY) = switch (_kind) {
      _Kind.score => (
          ((values.reduce((a, b) => a < b ? a : b) - 20) / 50).floor() * 50.0,
          500.0
        ),
      _Kind.percentile => (
          -((values.reduce((a, b) => a > b ? a : b) * 1.15) / 5).ceil() * 5.0,
          0.0
        ),
      _Kind.net => (0.0, totalQuestions.toDouble()),
      _Kind.subject => (0.0, _subject.questions.toDouble()),
    };
    final range = maxY - minY;
    final step = range <= 10 ? 2.0 : range <= 25 ? 5.0 : range <= 100 ? 10.0 : 50.0;

    String label(double y) => inverted ? '%${fmt(-y, 0)}' : fmt(y, 0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: exams.length < 2 ? 1 : (exams.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: C.tint, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: step,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(label(v),
                    style: const TextStyle(fontSize: 12, color: C.muted)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i != v || i < 0 || i >= exams.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(exams[i].name,
                      style: const TextStyle(fontSize: 11, color: C.muted)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => C.ink,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${exams[s.x.toInt()].name}\n${inverted ? '%${fmt(-s.y)}' : fmt(s.y)}',
                      const TextStyle(color: Colors.white, fontSize: 14),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])
            ],
            color: color,
            barWidth: 3,
            isCurved: true,
            preventCurveOverShooting: true,
            dotData: FlDotData(
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 5, color: color, strokeWidth: 2,
                  strokeColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
