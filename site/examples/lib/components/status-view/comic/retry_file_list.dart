import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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
        ? ComicStatusView.error(
            title: 'Files unavailable',
            message: 'The connection was interrupted.',
            onRetry: () => setState(() => failed = false),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Planning notes'),
              const SizedBox(height: 12),
              ComicButton(
                'Reset example',
                onPressed: () => setState(() => failed = true),
              ),
            ],
          ),
  );
}
