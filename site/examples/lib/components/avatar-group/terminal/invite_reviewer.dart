import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class InviteReviewer extends StatefulWidget {
  const InviteReviewer({super.key});
  @override
  State<InviteReviewer> createState() => _InviteReviewerState();
}

class _InviteReviewerState extends State<InviteReviewer> {
  bool invited = false;
  @override
  Widget build(BuildContext context) {
    final names = ['Ana Lee', 'Jo Ray', if (invited) 'Kim Yu'];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TermAvatarGroup(names: names, max: 2),
          const SizedBox(height: 12),
          Text(names.join(', ')),
          const SizedBox(height: 12),
          TermButton(
            label: invited ? 'Remove Kim' : 'Invite Kim',
            onPressed: () => setState(() => invited = !invited),
          ),
        ],
      ),
    );
  }
}
