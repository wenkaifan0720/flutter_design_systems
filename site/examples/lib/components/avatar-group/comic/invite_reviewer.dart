import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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
          ComicAvatarGroup(
            [
              const ComicFace('AL', name: 'Ana Lee'),
              const ComicFace('JR', name: 'Jo Ray'),
              if (invited) const ComicFace('KY', name: 'Kim Yu'),
            ],
            max: 2,
            semanticLabel: 'Reviewers',
          ),
          const SizedBox(height: 12),
          Text(names.join(', ')),
          const SizedBox(height: 12),
          ComicButton(
            invited ? 'Remove Kim' : 'Invite Kim',
            onPressed: () => setState(() => invited = !invited),
          ),
        ],
      ),
    );
  }
}
