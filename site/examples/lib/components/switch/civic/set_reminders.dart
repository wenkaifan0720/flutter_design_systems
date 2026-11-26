import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class SetReminders extends StatefulWidget {
  const SetReminders({super.key});

  @override
  State<SetReminders> createState() => _SetRemindersState();
}

class _SetRemindersState extends State<SetReminders> {
  bool reminders = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CivicSwitch(
          labelText: 'Reminders',
          value: reminders,
          onChanged: (next) => setState(() => reminders = next),
        ),
        const SizedBox(height: 12),
        Text(reminders ? 'Reminders on' : 'Reminders off'),
      ],
    ),
  );
}
