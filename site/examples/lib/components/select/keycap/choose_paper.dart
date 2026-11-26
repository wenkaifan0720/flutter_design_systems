import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
        KeycapSelect<String>(
          labelText: 'Paper size',
          value: paper,
          items: const [
            KeycapSelectItem(value: 'A4', label: 'A4'),
            KeycapSelectItem(value: 'A5', label: 'A5'),
            KeycapSelectItem(value: 'Letter', label: 'Letter'),
          ],
          onChanged: (value) => setState(() => paper = value),
        ),
        const SizedBox(height: 12),
        Text('Print on $paper'),
      ],
    ),
  );
}
