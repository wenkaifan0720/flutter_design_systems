import 'package:material_ui/material_ui.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key});
  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  int notes = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(notes == 1 ? '1 note' : '$notes notes'),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Create a note',
      onPressed: () => setState(() => notes++),
      child: const Icon(Icons.add),
    ),
  );
}
