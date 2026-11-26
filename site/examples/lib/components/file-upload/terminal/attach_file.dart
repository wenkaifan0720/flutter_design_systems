import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'package:terminal_ui/terminal_ui.dart';

class AttachFile extends StatefulWidget {
  const AttachFile({super.key});
  @override
  State<AttachFile> createState() => _AttachFileState();
}

class _AttachFileState extends State<AttachFile> {
  web.File? attachment;
  void chooseFile() {
    final input = web.HTMLInputElement()..type = 'file';
    input.onChange.first.then((_) {
      final file = input.files?.item(0);
      if (mounted && file != null) setState(() => attachment = file);
    });
    input.click();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: TermFileField(
        labelText: 'Attachment',
        onBrowse: chooseFile,
        files: [if (attachment case final file?) file.name],
        onRemoved: (_) => setState(() => attachment = null),
      ),
    ),
  );
}
