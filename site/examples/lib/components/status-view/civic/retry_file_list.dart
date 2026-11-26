import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class RetryFileList extends StatefulWidget {
  const RetryFileList({super.key});
  @override
  State<RetryFileList> createState() => _RetryFileListState();
}

class _RetryFileListState extends State<RetryFileList> {
  bool failed = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: failed
        ? CivicEmptyState(
            title: 'Files unavailable',
            actions: [
              CivicButton(
                onPressed: () => setState(() => failed = false),
                child: const Text('Retry'),
              ),
            ],
            announce: true,
            children: const [Text('The connection was interrupted.')],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Planning notes'),
              const SizedBox(height: 12),
              CivicButton(
                onPressed: () => setState(() => failed = true),
                child: const Text('Reset example'),
              ),
            ],
          ),
  );
}
