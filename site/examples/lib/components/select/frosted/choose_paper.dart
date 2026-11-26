import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
        FrostedSelect<String>(
          labelText: 'Paper size',
          value: paper,
          options: const [
            FrostedSelectOption('A4', 'A4'),
            FrostedSelectOption('A5', 'A5'),
            FrostedSelectOption('Letter', 'Letter'),
          ],
          onChanged: (value) => setState(() => paper = value),
        ),
        const SizedBox(height: 12),
        Text('Print on $paper'),
      ],
    ),
  );
}
