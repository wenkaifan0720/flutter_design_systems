import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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
        ComicSelect<String>(
          labelText: 'Paper size',
          value: paper,
          options: const [
            ComicSelectOption('A4', 'A4'),
            ComicSelectOption('A5', 'A5'),
            ComicSelectOption('Letter', 'Letter'),
          ],
          onChanged: (value) => setState(() => paper = value),
        ),
        const SizedBox(height: 12),
        Text('Print on $paper'),
      ],
    ),
  );
}
