import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';

String fmtDateTime(DateTime d) =>
    DateFormat('d MMM, HH:mm', 'fr').format(d.toLocal());
String fmtDate(DateTime d) =>
    DateFormat('d MMM yyyy', 'fr').format(d.toLocal());
String fmtDay(DateTime d) => DateFormat('EEE d MMM', 'fr').format(d.toLocal());
String fmtTime(DateTime d) => DateFormat('HH:mm').format(d.toLocal());
String fmtValue(double v) => v.toStringAsFixed(2);

String timeAgo(BuildContext c, DateTime d) {
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return c.t('ago_now');
  if (diff.inMinutes < 60) return c.t('ago_min', {'n': '${diff.inMinutes}'});
  if (diff.inHours < 24) return c.t('ago_h', {'n': '${diff.inHours}'});
  return c.t('ago_d', {'n': '${diff.inDays}'});
}

/// Format attendu par le backend pour un LocalDateTime (sans fuseau).
String toLocalIso(DateTime d) => DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);
