import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'package:brutal_ui/brutal_ui.dart';

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
      child: BrutalFileDrop(
        labelText: 'Attachment',
        onChoose: chooseFile,
        files: [
          if (attachment case final file?)
            BrutalFile(name: file.name, bytes: file.size),
        ],
        onRemove: (_) => setState(() => attachment = null),
      ),
    ),
  );
}
