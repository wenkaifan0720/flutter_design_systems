import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
      TermButton(
        label: 'Commands',
        onPressed: () => showTermCommandPalette(
          context: context,
          commands: [
            RawCommand(
              label: 'Review note',
              onPressed: () => setState(() => reviewed = true),
            ),
            RawCommand(
              label: 'Reset note',
              onPressed: () => setState(() => reviewed = false),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(reviewed ? 'Reviewed' : 'Draft'),
    ],
  );
}
