import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

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
            child: BrutalFloatingButton(
              icon: const Icon(CupertinoIcons.plus),
              tooltip: 'Add note',
              label: 'Add note',
              onPressed: () => setState(() => notes++),
            ),
          ),
        ],
      ),
    ),
  );
}
