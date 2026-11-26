import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class SetReminder extends StatefulWidget {
  const SetReminder({super.key});
  @override
  State<SetReminder> createState() => _SetReminderState();
}

class _SetReminderState extends State<SetReminder> {
  final reminder = ExpressiveTimePickerController(hour: 9, minute: 30);
  var mode = ExpressiveTimePickerMode.dial;

  @override
  void dispose() {
    reminder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpressiveTimePickerModeToggle(
            mode: mode,
            onChanged: (next) => setState(() => mode = next),
          ),
          if (mode == ExpressiveTimePickerMode.input)
            ExpressiveTimeInput(controller: reminder)
          else
            ExpressiveTimePicker(controller: reminder),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: reminder,
            builder: (context, _) => Text(
              "Reminder: ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}",
            ),
          ),
        ],
      ),
    ),
  );
}
