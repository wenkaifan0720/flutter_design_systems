import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:gloss_ui/gloss_ui.dart';

class BookDates extends StatefulWidget {
  const BookDates({super.key});
  @override
  State<BookDates> createState() => _BookDatesState();
}

class _BookDatesState extends State<BookDates> {
  GlossDateRange? stay;

  String bookingSummary(BuildContext context) {
    final start = stay?.start;
    final end = stay?.end;
    if (start == null) return 'Choose an arrival date';
    final dates = MaterialLocalizations.of(context);
    if (end == null) return 'Arrival: ${dates.formatCompactDate(start)}';
    return 'Stay: ${dates.formatCompactDate(start)} – ${dates.formatCompactDate(end)}';
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlossDateRangePicker(
            labelText: 'Stay',
            firstDate: DateTime(2026, 11),
            lastDate: DateTime(2026, 12, 31),
            currentDate: DateTime(2026, 11, 12),
            value: stay,
            onChanged: (next) => setState(() => stay = next),
          ),
          const SizedBox(height: 12),
          Text(bookingSummary(context)),
        ],
      ),
    ),
  );
}
