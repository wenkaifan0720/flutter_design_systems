import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
        TermNumberField(
          semanticLabel: 'Copies',
          min: 1,
          max: 9,
          value: copies,
          onChanged: (value) => setState(() => copies = value),
        ),
        const SizedBox(height: 12),
        Text('Copies: $copies'),
      ],
    ),
  );
}
