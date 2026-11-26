import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

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
        CivicBreadcrumbs(
          items: [
            CivicBreadcrumb(
              label: 'Files',
              onPressed: inDrafts
                  ? () => setState(() => inDrafts = false)
                  : null,
            ),
            if (inDrafts) const CivicBreadcrumb(label: 'Drafts'),
          ],
        ),
        const SizedBox(height: 12),
        if (inDrafts)
          const Text('Drafts folder')
        else
          CivicButton(
            expand: false,
            onPressed: () => setState(() => inDrafts = true),
            child: Text('Open Drafts'),
          ),
      ],
    ),
  );
}
