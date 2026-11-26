import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class PreviewOwner extends StatefulWidget {
  const PreviewOwner({super.key});
  @override
  State<PreviewOwner> createState() => _PreviewOwnerState();
}

class _PreviewOwnerState extends State<PreviewOwner> {
  bool showProfile = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      StudioHoverCard(
        content: (_) => const Text('Design lead in Toronto.'),
        child: StudioLink(
          'Mara Chen',
          onPressed: () => setState(() => showProfile = !showProfile),
        ),
      ),
      const SizedBox(height: 12),
      if (showProfile) const Text('Mara Chen · Design lead in Toronto.'),
    ],
  );
}
