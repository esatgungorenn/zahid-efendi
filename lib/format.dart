/// Turkish number and date formatting (decimal comma, dd.MM.yyyy).
library;

String fmt(double v, [int digits = 2]) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

String fmtDate(DateTime d) =>
    '${_pad2(d.day)}.${_pad2(d.month)}.${d.year}';

String _pad2(int n) => n.toString().padLeft(2, '0');

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String fmtLongDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Parses "470,25" or "470.25". Returns null for anything else.
double? parseDecimal(String s) =>
    double.tryParse(s.trim().replaceAll(',', '.'));
