import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
        StudioProgressBar(
          value: completed / 4,
          semanticLabel: 'Uploading files',
        ),
        const SizedBox(height: 12),
        Text('Uploaded $completed of 4 files'),
        const SizedBox(height: 12),
        StudioButton(
          completed == 4 ? 'Start over' : 'Complete next file',
          onPressed: () =>
              setState(() => completed = completed == 4 ? 1 : completed + 1),
        ),
      ],
    ),
  );
}
