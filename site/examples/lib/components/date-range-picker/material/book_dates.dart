import 'package:material_ui/material_ui.dart';

class BookDates extends StatefulWidget {
  const BookDates({super.key});
  @override
  State<BookDates> createState() => _BookDatesState();
}

class _BookDatesState extends State<BookDates> {
  DateTimeRange? stay;

  Future<void> pick() async {
    final next = await showDateRangePicker(
      context: context,
      initialDateRange: stay,
      firstDate: DateTime(2026, 11),
      lastDate: DateTime(2026, 12, 31),
      currentDate: DateTime(2026, 11, 12),
      helpText: 'Stay',
    );
    if (next != null && mounted) setState(() => stay = next);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      OutlinedButton.icon(
        onPressed: pick,
        icon: const Icon(Icons.date_range_outlined),
        label: const Text('Choose dates'),
      ),
      const SizedBox(height: 12),
      Builder(
        builder: (context) {
          final range = stay;
          if (range == null) return const Text('Choose an arrival date');
          final dates = MaterialLocalizations.of(context);
          return Text(
            'Stay: ${dates.formatCompactDate(range.start)} – ${dates.formatCompactDate(range.end)}',
          );
        },
      ),
    ],
  );
}
