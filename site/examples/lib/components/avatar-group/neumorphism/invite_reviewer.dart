import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
          NeumorphicAvatarGroup(
            [
              const NeumorphicFace('AL', name: 'Ana Lee'),
              const NeumorphicFace('JR', name: 'Jo Ray'),
              if (invited) const NeumorphicFace('KY', name: 'Kim Yu'),
            ],
            most: 2,
            semanticLabel: 'Reviewers',
          ),
          const SizedBox(height: 12),
          Text(names.join(', ')),
          const SizedBox(height: 12),
          NeumorphicButton(
            invited ? 'Remove Kim' : 'Invite Kim',
            onPressed: () => setState(() => invited = !invited),
          ),
        ],
      ),
    );
  }
}
