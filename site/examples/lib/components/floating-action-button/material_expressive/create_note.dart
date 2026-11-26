import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key});

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  int notes = 0;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: SizedBox(
      height: 184,
      child: Stack(
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Text('Notes: $notes'),
          ),
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: ExpressiveFloatingActionButton.extended(
              icon: ExpressiveSymbols.add,
              label: 'Add note',
              onPressed: () => setState(() => notes++),
            ),
          ),
        ],
      ),
    ),
  );
}
