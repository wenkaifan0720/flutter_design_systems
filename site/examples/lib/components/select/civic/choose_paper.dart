import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

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
        CivicSelect<String>(
          labelText: 'Paper size',
          value: paper,
          items: const [
            CivicSelectItem(value: 'A4', label: 'A4'),
            CivicSelectItem(value: 'A5', label: 'A5'),
            CivicSelectItem(value: 'Letter', label: 'Letter'),
          ],
          onChanged: (value) => setState(() => paper = value),
        ),
        const SizedBox(height: 12),
        Text('Print on $paper'),
      ],
    ),
  );
}
