import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

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
      CivicTopBar(
        title: 'Notes',
        actions: [
          CivicButton(
            expand: false,
            onPressed: () => setState(() => saved = true),
            child: Text('Save'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(saved ? 'Saved' : 'Unsaved'),
    ],
  );
}
