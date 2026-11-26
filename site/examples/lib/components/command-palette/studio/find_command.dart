import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
      StudioButton(
        'Commands',
        onPressed: () => showStudioCommandPalette(
          context,
          commands: [
            StudioCommand(
              label: 'Review note',
              onPressed: () => setState(() => reviewed = true),
            ),
            StudioCommand(
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
