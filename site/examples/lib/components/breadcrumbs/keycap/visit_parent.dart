import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class VisitParent extends StatefulWidget {
  const VisitParent({super.key});
  @override
  State<VisitParent> createState() => _VisitParentState();
}

class _VisitParentState extends State<VisitParent> {
  bool inDrafts = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 460),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeycapBreadcrumb(
          crumbs: [
            KeycapCrumb(
              'Files',
              onPressed: inDrafts
                  ? () => setState(() => inDrafts = false)
                  : null,
            ),
            if (inDrafts) const KeycapCrumb('Drafts'),
          ],
        ),
        const SizedBox(height: 12),
        if (inDrafts)
          const Text('Drafts folder')
        else
          KeycapButton(
            onPressed: () => setState(() => inDrafts = true),
            child: const Text('Open Drafts'),
          ),
      ],
    ),
  );
}
