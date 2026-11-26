import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class TrackUploads extends StatefulWidget {
  const TrackUploads({super.key});
  @override
  State<TrackUploads> createState() => _TrackUploadsState();
}

class _TrackUploadsState extends State<TrackUploads> {
  int completed = 1;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: KeycapProgressBar(
            value: completed / 4,
            semanticLabel: 'Uploading files',
          ),
        ),
        const SizedBox(height: 12),
        Text('Uploaded $completed of 4 files'),
        const SizedBox(height: 12),
        KeycapButton(
          onPressed: () =>
              setState(() => completed = completed == 4 ? 1 : completed + 1),
          child: Text(completed == 4 ? 'Start over' : 'Complete next file'),
        ),
      ],
    ),
  );
}
