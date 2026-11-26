import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
        NeumorphicSelect<String>(
          labelText: 'Paper size',
          value: paper,
          options: const [
            NeumorphicMenuItem('A4', 'A4'),
            NeumorphicMenuItem('A5', 'A5'),
            NeumorphicMenuItem('Letter', 'Letter'),
          ],
          onChanged: (value) => setState(() => paper = value),
        ),
        const SizedBox(height: 12),
        Text('Print on $paper'),
      ],
    ),
  );
}
