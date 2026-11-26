import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class ShowConnectionStatus extends StatefulWidget {
  const ShowConnectionStatus({super.key});
  @override
  State<ShowConnectionStatus> createState() => _ShowConnectionStatusState();
}

class _ShowConnectionStatusState extends State<ShowConnectionStatus> {
  bool offline = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (offline) ...[
          const ComicBanner(
            'Edits will sync when you reconnect.',
            title: 'Sync paused',
          ),
          const SizedBox(height: 12),
        ],
        ComicButton(
          offline ? 'Reconnect' : 'Go offline',
          onPressed: () => setState(() => offline = !offline),
        ),
      ],
    ),
  );
}
