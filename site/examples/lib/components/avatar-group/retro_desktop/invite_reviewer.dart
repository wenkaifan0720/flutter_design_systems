import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class InviteReviewer extends StatefulWidget {
  const InviteReviewer({super.key});
  @override
  State<InviteReviewer> createState() => _InviteReviewerState();
}

class _InviteReviewerState extends State<InviteReviewer> {
  bool invited = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RetroDesktopAvatarGroup(
          children: [
            const RetroDesktopAvatar('AL', name: 'Ana Lee'),
            const RetroDesktopAvatar('JR', name: 'Jo Ray'),
            if (invited) const RetroDesktopAvatar('KY', name: 'Kim Yu'),
          ],
        ),
        const SizedBox(height: 12),
        Text(invited ? 'Ana Lee, Jo Ray, Kim Yu' : 'Ana Lee, Jo Ray'),
        const SizedBox(height: 12),
        RetroDesktopButton(
          invited ? 'Remove Kim' : 'Invite Kim',
          onPressed: () => setState(() => invited = !invited),
        ),
      ],
    ),
  );
}
