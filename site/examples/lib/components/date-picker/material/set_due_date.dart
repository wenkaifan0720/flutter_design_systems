import 'package:material_ui/material_ui.dart';

class SetDueDate extends StatefulWidget {
  const SetDueDate({super.key});
  @override
  State<SetDueDate> createState() => _SetDueDateState();
}

class _SetDueDateState extends State<SetDueDate> {
  var due = DateTime(2026, 11, 12);

  Future<void> pick() async {
    final next = await showDatePicker(
      context: context,
      initialDate: due,
      firstDate: DateTime(2026, 11),
      lastDate: DateTime(2026, 12, 31),
      currentDate: DateTime(2026, 11, 12),
      helpText: 'Due date',
    );
    if (next != null && mounted) setState(() => due = next);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      OutlinedButton.icon(
        onPressed: pick,
        icon: const Icon(Icons.calendar_today_outlined),
        label: const Text('Set due date'),
      ),
      const SizedBox(height: 12),
      Text('Due: ${MaterialLocalizations.of(context).formatCompactDate(due)}'),
    ],
  );
}
