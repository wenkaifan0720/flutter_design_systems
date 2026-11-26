import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class ChooseDay extends StatefulWidget {
  const ChooseDay({super.key});
  @override
  State<ChooseDay> createState() => _ChooseDayState();
}

class _ChooseDayState extends State<ChooseDay> {
  var day = DateTime(2026, 11, 12);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LedgerDatePicker(
            labelText: 'Day',
            presentation: LedgerDatePickerPresentation.wheel,
            firstDate: DateTime(2026, 11),
            lastDate: DateTime(2026, 11, 30),
            currentDate: DateTime(2026, 11, 12),
            value: day,
            onChanged: (next) => setState(() => day = next),
          ),
          const SizedBox(height: 12),
          Text('November ${day.day}'),
        ],
      ),
    ),
  );
}
