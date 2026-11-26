import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class SetDueDate extends StatelessWidget {
  const SetDueDate({super.key});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: const CivicDateInput(
        labelText: 'Due date',
        helperText: 'For example, 12 11 2026',
        dayLabel: 'Day',
        monthLabel: 'Month',
        yearLabel: 'Year',
      ),
    ),
  );
}
