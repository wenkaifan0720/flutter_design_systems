import 'package:material_ui/material_ui.dart';

class SaveNote extends StatefulWidget {
  const SaveNote({super.key});
  @override
  State<SaveNote> createState() => _SaveNoteState();
}

class _SaveNoteState extends State<SaveNote> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Notes'),
          actions: [
            TextButton(
              onPressed: () => setState(() => saved = true),
              child: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(saved ? 'Saved' : 'Unsaved'),
      ],
    ),
  );
}
