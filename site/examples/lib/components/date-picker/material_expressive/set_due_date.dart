import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:material_expressive_ui/material_expressive_ui.dart';

class SetDueDate extends StatefulWidget {
  const SetDueDate({super.key});
  @override
  State<SetDueDate> createState() => _SetDueDateState();
}

class _SetDueDateState extends State<SetDueDate> {
  var due = DateTime(2026, 11, 12);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpressiveDatePicker(
            firstDate: DateTime(2026, 11),
            lastDate: DateTime(2026, 12, 31),
            selected: due,
            onChanged: (next) => setState(() => due = next),
            currentDate: DateTime(2026, 11, 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Due: ${MaterialLocalizations.of(context).formatCompactDate(due)}',
          ),
        ],
      ),
    ),
  );
}
