import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

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
        ? GlossStateView(
            state: GlossState.error,
            title: 'Files unavailable',
            message: 'The connection was interrupted.',
            actions: [
              GlossButton(
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
              GlossButton(
                'Reset example',
                onPressed: () => setState(() => failed = true),
              ),
            ],
          ),
  );
}
