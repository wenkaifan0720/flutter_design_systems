import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
          Fluent2AvatarGroup(
            max: 2,
            people: [for (final name in names) Fluent2AvatarPerson(name)],
          ),
          const SizedBox(height: 12),
          Text(names.join(', ')),
          const SizedBox(height: 12),
          Fluent2Button(
            invited ? 'Remove Kim' : 'Invite Kim',
            onPressed: () => setState(() => invited = !invited),
          ),
        ],
      ),
    );
  }
}
