import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
      Fluent2Popover(
        semanticLabel: 'Mara Chen',
        openOnHover: true,
        trigger: (_, toggle) => Fluent2Link(
          'Mara Chen',
          onPressed: () => setState(() => showProfile = !showProfile),
        ),
        content: const Text('Design lead in Toronto.'),
      ),
      const SizedBox(height: 12),
      if (showProfile) const Text('Mara Chen · Design lead in Toronto.'),
    ],
  );
}
