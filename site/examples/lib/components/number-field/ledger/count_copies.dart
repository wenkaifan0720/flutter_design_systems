import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class CountCopies extends StatefulWidget {
  const CountCopies({super.key});

  @override
  State<CountCopies> createState() => _CountCopiesState();
}

class _CountCopiesState extends State<CountCopies> {
  num copies = 2;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LedgerStepper(
          labelText: 'Copies',
          min: 1,
          step: 1,
          value: copies,
          onChanged: (value) => setState(() => copies = value),
        ),
        const SizedBox(height: 12),
        Text('Copies: $copies'),
      ],
    ),
  );
}
