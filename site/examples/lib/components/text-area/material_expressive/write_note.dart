import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class WriteNote extends StatefulWidget {
  const WriteNote({super.key});

  @override
  State<WriteNote> createState() => _WriteNoteState();
}

class _WriteNoteState extends State<WriteNote> {
  int lines = 0;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpressiveTextArea(
          labelText: 'Delivery note',
          minLines: 2,
          maxLines: 3,
          onChanged: (note) => setState(
            () => lines = note.isEmpty ? 0 : note.split('\n').length,
          ),
        ),
        const SizedBox(height: 12),
        Text('Lines: $lines'),
      ],
    ),
  );
}
