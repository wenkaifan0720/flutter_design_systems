import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
        ApplianceSelect<String>(
          labelText: 'Paper size',
          value: paper,
          items: const [
            ApplianceSelectItem(value: 'A4', label: 'A4'),
            ApplianceSelectItem(value: 'A5', label: 'A5'),
            ApplianceSelectItem(value: 'Letter', label: 'Letter'),
          ],
          onChanged: (value) => setState(() => paper = value),
        ),
        const SizedBox(height: 12),
        Text('Print on $paper'),
      ],
    ),
  );
}
