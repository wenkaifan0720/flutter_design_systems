import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => TermButton(
    label: 'File details',
    onPressed: () => showTermSideSheet<void>(
      context: context,
      builder: (sheet) => TermSideSheet(
        title: 'File details',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Owner: Mara Chen\nLast edited: 14 June'),
            const SizedBox(height: 12),
            TermButton(label: 'Done', onPressed: () => Navigator.pop(sheet)),
          ],
        ),
      ),
    ),
  );
}
