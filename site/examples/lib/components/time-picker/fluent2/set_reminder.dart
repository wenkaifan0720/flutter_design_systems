import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class SetReminder extends StatefulWidget {
  const SetReminder({super.key});
  @override
  State<SetReminder> createState() => _SetReminderState();
}

class _SetReminderState extends State<SetReminder> {
  var reminder = const Fluent2Time(9, 30);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Fluent2TimePicker(
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
