import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
        ? KeycapStatusView(
            status: KeycapStatus.error,
            title: 'Files unavailable',
            message: 'The connection was interrupted.',
            action: KeycapButton(
              onPressed: () => setState(() => failed = false),
              child: const Text('Retry'),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Planning notes'),
              const SizedBox(height: 12),
              KeycapButton(
                onPressed: () => setState(() => failed = true),
                child: const Text('Reset example'),
              ),
            ],
          ),
  );
}
