import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class FindCommand extends StatefulWidget {
  const FindCommand({super.key});
  @override
  State<FindCommand> createState() => _FindCommandState();
}

class _FindCommandState extends State<FindCommand> {
  bool reviewed = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MinimalButton(
        'Commands',
        onPressed: () => MinimalCommand.show(
          context,
          actions: [
            MinimalCommandItem(
              'Review note',
              onSelected: () => setState(() => reviewed = true),
            ),
            MinimalCommandItem(
              'Reset note',
              onSelected: () => setState(() => reviewed = false),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(reviewed ? 'Reviewed' : 'Draft'),
    ],
  );
}
