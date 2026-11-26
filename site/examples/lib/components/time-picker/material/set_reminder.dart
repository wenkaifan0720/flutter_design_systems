import 'package:material_ui/material_ui.dart';

class SetReminder extends StatefulWidget {
  const SetReminder({super.key});
  @override
  State<SetReminder> createState() => _SetReminderState();
}

class _SetReminderState extends State<SetReminder> {
  var reminder = const TimeOfDay(hour: 9, minute: 30);

  Future<void> pick() async {
    final next = await showTimePicker(
      context: context,
      initialTime: reminder,
      helpText: 'Reminder',
    );
    if (next != null && mounted) setState(() => reminder = next);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      OutlinedButton.icon(
        onPressed: pick,
        icon: const Icon(Icons.schedule),
        label: Text(reminder.format(context)),
      ),
      const SizedBox(height: 12),
      Text(
        "Reminder: ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}",
      ),
    ],
  );
}
