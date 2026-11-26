import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
      KeycapAppBar(
        title: 'Notes',
        actions: [
          KeycapButton(
            onPressed: () => setState(() => saved = true),
            child: const Text('Save'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(saved ? 'Saved' : 'Unsaved'),
    ],
  );
}
