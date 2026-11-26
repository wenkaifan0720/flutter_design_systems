import 'package:material_ui/material_ui.dart';

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
    child: offline
        ? MaterialBanner(
            leading: const Icon(Icons.cloud_off_outlined),
            content: const Text(
              'Sync paused. Edits will sync when you reconnect.',
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => offline = false),
                child: const Text('Reconnect'),
              ),
            ],
          )
        : OutlinedButton(
            onPressed: () => setState(() => offline = true),
            child: const Text('Go offline'),
          ),
  );
}
