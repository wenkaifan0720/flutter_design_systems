import 'package:cupertino_ui/cupertino_ui.dart';

class SetReminder extends StatefulWidget {
  const SetReminder({super.key});
  @override
  State<SetReminder> createState() => _SetReminderState();
}

class _SetReminderState extends State<SetReminder> {
  var reminder = DateTime(2026, 11, 12, 9, 30);

  void showPicker(Widget picker) => showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => Container(
      height: 216,
      padding: const EdgeInsets.only(top: 6),
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(top: false, child: picker),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CupertinoButton(
        onPressed: () => showPicker(
          CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: true,
            initialDateTime: reminder,
            onDateTimeChanged: (next) => setState(() => reminder = next),
          ),
        ),
        child: const Text('Set reminder time'),
      ),
      const SizedBox(height: 12),
      Text(
        "Reminder: ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}",
      ),
    ],
  );
}
