import 'package:cupertino_ui/cupertino_ui.dart';

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
        Semantics(
          label: 'Uploading files',
          value: '${completed * 25}%',
          child: CupertinoLinearActivityIndicator(progress: completed / 4),
        ),
        const SizedBox(height: 12),
        Text('Uploaded $completed of 4 files'),
        CupertinoButton(
          onPressed: () =>
              setState(() => completed = completed == 4 ? 1 : completed + 1),
          child: Text(completed == 4 ? 'Start over' : 'Complete next file'),
        ),
      ],
    ),
  );
}
