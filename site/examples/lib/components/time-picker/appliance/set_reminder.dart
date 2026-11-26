import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class SetReminder extends StatefulWidget {
  const SetReminder({super.key});
  @override
  State<SetReminder> createState() => _SetReminderState();
}

class _SetReminderState extends State<SetReminder> {
  var reminder = const RawTimeOfDay(hour: 9, minute: 30);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ApplianceTimePicker(
            semanticLabel: 'Reminder',
            value: reminder,
            onChanged: (next) => setState(() => reminder = next),
          ),
          const SizedBox(height: 12),
          Text(
            "Reminder: ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}",
          ),
        ],
      ),
    ),
  );
}
