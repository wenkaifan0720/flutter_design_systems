import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class SwitchReviewer extends StatefulWidget {
  const SwitchReviewer({super.key});
  @override
  State<SwitchReviewer> createState() => _SwitchReviewerState();
}

class _SwitchReviewerState extends State<SwitchReviewer> {
  bool ana = true;
  @override
  Widget build(BuildContext context) {
    final name = ana ? 'Ana Lee' : 'Jo Ray';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrutalAvatar(name: name),
          const SizedBox(height: 12),
          Text(name),
          const SizedBox(height: 12),
          BrutalButton(
            'Switch reviewer',
            onPressed: () => setState(() => ana = !ana),
          ),
        ],
      ),
    );
  }
}
