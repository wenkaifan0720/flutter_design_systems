import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class CountCopies extends StatefulWidget {
  const CountCopies({super.key});

  @override
  State<CountCopies> createState() => _CountCopiesState();
}

class _CountCopiesState extends State<CountCopies> {
  int copies = 2;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClayNumberField(
          semanticLabel: 'Copies',
          min: 1,
          max: 9,
          value: copies.toDouble(),
          onChanged: (value) {
            if (value != null) setState(() => copies = value.round());
          },
        ),
        const SizedBox(height: 12),
        Text('Copies: $copies'),
      ],
    ),
  );
}
