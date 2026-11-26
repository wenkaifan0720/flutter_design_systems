import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

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
        ? BrutalStateView(
            state: BrutalState.error,
            title: 'Files unavailable',
            message: 'The connection was interrupted.',
            actions: [
              BrutalButton(
                'Retry',
                onPressed: () => setState(() => failed = false),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Planning notes'),
              const SizedBox(height: 12),
              BrutalButton(
                'Reset example',
                onPressed: () => setState(() => failed = true),
              ),
            ],
          ),
  );
}
