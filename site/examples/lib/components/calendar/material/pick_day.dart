import 'package:material_ui/material_ui.dart';

class PickDay extends StatefulWidget {
  const PickDay({super.key});
  @override
  State<PickDay> createState() => _PickDayState();
}

class _PickDayState extends State<PickDay> {
  var day = DateTime(2026, 11, 12);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarDatePicker(
            initialDate: day,
            firstDate: DateTime(2026, 11),
            lastDate: DateTime(2026, 12, 31),
            currentDate: DateTime(2026, 11, 12),
            onDateChanged: (next) => setState(() => day = next),
          ),
          const SizedBox(height: 12),
          Text(
            'Selected: ${MaterialLocalizations.of(context).formatCompactDate(day)}',
          ),
        ],
      ),
    ),
  );
}
