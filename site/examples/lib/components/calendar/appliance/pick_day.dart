import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:appliance_ui/appliance_ui.dart';

class PickDay extends StatefulWidget {
  const PickDay({super.key});
  @override
  State<PickDay> createState() => _PickDayState();
}

class _PickDayState extends State<PickDay> {
  final schedule = RawCalendarController(
    firstDate: DateTime(2026, 11),
    lastDate: DateTime(2026, 12, 31),
    currentDate: DateTime(2026, 11, 12),
    selectedDate: DateTime(2026, 11, 12),
  );
  @override
  void dispose() {
    schedule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ApplianceCalendar(controller: schedule),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: schedule,
            builder: (context, _) {
              final day = schedule.selectedDate;
              return Text(
                day == null
                    ? 'Choose a day'
                    : 'Selected: ${MaterialLocalizations.of(context).formatCompactDate(day)}',
              );
            },
          ),
        ],
      ),
    ),
  );
}
