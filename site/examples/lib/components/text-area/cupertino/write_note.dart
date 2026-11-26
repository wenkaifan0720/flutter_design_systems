import 'package:cupertino_ui/cupertino_ui.dart';

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
        CupertinoTextField(
          placeholder: 'Delivery note',
          minLines: 2,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
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
