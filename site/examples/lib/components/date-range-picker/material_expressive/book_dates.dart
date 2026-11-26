import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:material_expressive_ui/material_expressive_ui.dart';

class BookDates extends StatefulWidget {
  const BookDates({super.key});
  @override
  State<BookDates> createState() => _BookDatesState();
}

class _BookDatesState extends State<BookDates> {
  DateTime? arrival;
  DateTime? departure;

  String bookingSummary(BuildContext context) {
    final start = arrival;
    final end = departure;
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
          ExpressiveDateRangePicker(
            title: 'Stay dates',
            firstDate: DateTime(2026, 11),
            lastDate: DateTime(2026, 12, 31),
            currentDate: DateTime(2026, 11, 12),
            start: arrival,
            end: departure,
            onChanged: (start, end) => setState(() {
              arrival = start;
              departure = end;
            }),
          ),
          const SizedBox(height: 12),
          Text(bookingSummary(context)),
        ],
      ),
    ),
  );
}
