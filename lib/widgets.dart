import 'package:flutter/material.dart';

import 'calc.dart';
import 'theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Trend trend;
  final String? note;
  final Color? noteColor;
  final bool highlighted;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend = Trend.none,
    this.note,
    this.noteColor,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? C.deep : C.ink;
    return Material(
      color: highlighted ? C.tint : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14, color: highlighted ? C.main : C.muted)),
              const SizedBox(height: 2),
              Row(children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: fg)),
                  ),
                ),
                const SizedBox(width: 6),
                TrendArrow(trend, size: 17),
              ]),
              if (note != null)
                Text(note!,
                    style: TextStyle(
                        fontSize: 13,
                        color: noteColor ?? (highlighted ? C.main : C.muted))),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Row(children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, color: C.muted, fontWeight: FontWeight.w500)),
          ),
          ?trailing,
        ]),
      );
}

class BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const BigButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: C.accent,
            foregroundColor: C.onAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.body,
      this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: C.line),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: C.muted)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}
