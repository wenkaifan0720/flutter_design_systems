/// A multi-line field, and a drop zone with files on their way up.
library;

import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

Widget kitTextAreaDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Text area & file upload',
  sections: [
    kitSection(
      'Text area',
      children: [
        kitSpecimenTextAreaNotes(),
        // At the box's own three lines, as the notes box above rests.
        const MinimalTextArea(
          labelText: 'Reason',
          errorText: 'Say a few words about why.',
        ),
      ],
    ),
    kitSection(
      'File upload',
      children: [
        _LiveUpload(),
        kitNote(
          'A tap opens the app\'s picker; dropping is the app\'s, which '
          'passes dragOver while a drag hovers.',
        ),
        kitSpecimenFileUploadDragOver(),
      ],
    ),
  ],
);

class _LiveUpload extends StatefulWidget {
  @override
  State<_LiveUpload> createState() => _LiveUploadState();
}

class _LiveUploadState extends State<_LiveUpload> {
  final List<MinimalUploadFile> _files = [
    const MinimalUploadFile(name: 'q3-report.pdf', bytes: 2411520),
    const MinimalUploadFile(name: 'roster.csv', bytes: 18200, progress: 0.4),
  ];
  var _picked = 0;

  @override
  Widget build(BuildContext context) => MinimalFileUpload(
    title: 'Drop files here, or browse',
    link: 'browse',
    hint: 'PDF, CSV or PNG, up to 10 MB',
    files: _files,
    onBrowse: () => setState(
      () => _files.add(
        MinimalUploadFile(name: 'scan-${++_picked}.png', bytes: 482000),
      ),
    ),
    onRemove: (f) => setState(() => _files.remove(f)),
  );
}

// --- specimens ---------------------------------------------------------------

/// A notes box with a line of help.
Widget kitSpecimenTextAreaNotes() => const MinimalTextArea(
  labelText: 'Notes',
  hintText: 'Anything the team should know',
  helperText: 'Visible to everyone on the project.',
);

/// The zone, idle, with two files.
Widget kitSpecimenFileUploadFiles() => MinimalFileUpload(
  title: 'Drop files here, or browse',
  link: 'browse',
  hint: 'PDF, CSV or PNG, up to 10 MB',
  onBrowse: () {},
  onRemove: (_) {},
  files: const [
    MinimalUploadFile(name: 'q3-report.pdf', bytes: 2411520),
    MinimalUploadFile(name: 'roster.csv', bytes: 18200, progress: 0.4),
  ],
);

/// The zone while a drag hovers.
Widget kitSpecimenFileUploadDragOver() => MinimalFileUpload(
  title: 'Drop to upload',
  hint: 'PDF, CSV or PNG, up to 10 MB',
  dragOver: true,
  onBrowse: () {},
);
