import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'package:ledger_ui/ledger_ui.dart';

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
      child: LedgerFileUpload(
        labelText: 'Attachment',
        hintText: 'Choose a file',
        note: null,
        onPick: chooseFile,
        files: [
          if (attachment case final file?)
            LedgerFile(file.name, bytes: file.size),
        ],
        onRemove: (_) => setState(() => attachment = null),
      ),
    ),
  );
}
