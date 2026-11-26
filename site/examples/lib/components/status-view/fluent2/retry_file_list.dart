import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
        ? Fluent2StatusView.error(
            title: 'Files unavailable',
            message: 'The connection was interrupted.',
            onAction: () => setState(() => failed = false),
            actionLabel: 'Retry',
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Planning notes'),
              const SizedBox(height: 12),
              Fluent2Button(
                'Reset example',
                onPressed: () => setState(() => failed = true),
              ),
            ],
          ),
  );
}
