import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
      KeycapHoverCard(
        card: (_) => const Text('Design lead in Toronto.'),
        child: KeycapLink(
          onPressed: () => setState(() => showProfile = !showProfile),
          child: const Text('Mara Chen'),
        ),
      ),
      const SizedBox(height: 12),
      if (showProfile) const Text('Mara Chen · Design lead in Toronto.'),
    ],
  );
}
