import 'package:cupertino_ui/cupertino_ui.dart';

class SetDueDate extends StatefulWidget {
  const SetDueDate({super.key});
  @override
  State<SetDueDate> createState() => _SetDueDateState();
}

class _SetDueDateState extends State<SetDueDate> {
  var due = DateTime(2026, 11, 12);

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
            mode: CupertinoDatePickerMode.date,
            initialDateTime: due,
            minimumDate: DateTime(2026, 11),
            maximumDate: DateTime(2026, 12, 31),
            onDateTimeChanged: (next) => setState(() => due = next),
          ),
        ),
        child: const Text('Set due date'),
      ),
      const SizedBox(height: 12),
      Text(
        'Due: ${CupertinoLocalizations.of(context).datePickerMonth(due.month)} ${due.day}, ${due.year}',
      ),
    ],
  );
}
