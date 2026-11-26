import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

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
      BrutalAppBar(
        title: 'Notes',
        actions: [
          BrutalButton('Save', onPressed: () => setState(() => saved = true)),
        ],
      ),
      const SizedBox(height: 12),
      Text(saved ? 'Saved' : 'Unsaved'),
    ],
  );
}
