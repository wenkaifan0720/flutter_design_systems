import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class SetReminder extends StatefulWidget {
  const SetReminder({super.key});
  @override
  State<SetReminder> createState() => _SetReminderState();
}

class _SetReminderState extends State<SetReminder> {
  TermTime? reminder = const TermTime(hour: 9, minute: 30);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TermTimeField(
          labelText: 'Reminder',
          value: reminder,
          onChanged: (next) => setState(() => reminder = next),
        ),
        const SizedBox(height: 12),
        Text(
          reminder == null
              ? 'Set a time'
              : "Reminder: ${reminder!.hour.toString().padLeft(2, '0')}:${reminder!.minute.toString().padLeft(2, '0')}",
        ),
      ],
    ),
  );
}
