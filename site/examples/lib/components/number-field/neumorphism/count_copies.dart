import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class CountCopies extends StatefulWidget {
  const CountCopies({super.key});

  @override
  State<CountCopies> createState() => _CountCopiesState();
}

class _CountCopiesState extends State<CountCopies> {
  double? copies = 2;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeumorphicNumberField(
          labelText: 'Copies',
          min: 1,
          max: 9,
          value: copies,
          onChanged: (value) => setState(() => copies = value),
        ),
        const SizedBox(height: 12),
        Text(
          copies == null ? 'Choose a quantity' : 'Copies: ${copies!.toInt()}',
        ),
      ],
    ),
  );
}
