import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class ChoosePaper extends StatefulWidget {
  const ChoosePaper({super.key});

  @override
  State<ChoosePaper> createState() => _ChoosePaperState();
}

class _ChoosePaperState extends State<ChoosePaper> {
  String paper = 'A4';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Fluent2Select<String>(
          semanticLabel: 'Paper size',
          value: paper,
          options: const [
            Fluent2Option('A4', 'A4'),
            Fluent2Option('A5', 'A5'),
            Fluent2Option('Letter', 'Letter'),
          ],
          onChanged: (value) => setState(() => paper = value),
        ),
        const SizedBox(height: 12),
        Text('Print on $paper'),
      ],
    ),
  );
}
