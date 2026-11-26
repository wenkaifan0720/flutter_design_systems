import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class SaveNote extends StatefulWidget {
  const SaveNote({super.key});
  @override
  State<SaveNote> createState() => _SaveNoteState();
}

class _SaveNoteState extends State<SaveNote> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RetroDesktopAppBar(
        title: 'Notes',
        actions: [
          RetroDesktopButton(
            'Save',
            onPressed: () => setState(() => saved = true),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(saved ? 'Saved' : 'Unsaved'),
    ],
  );
}
