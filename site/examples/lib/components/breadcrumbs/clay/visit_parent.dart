import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
        ClayBreadcrumb(
          crumbs: [
            ClayCrumb(
              label: 'Files',
              onPressed: inDrafts
                  ? () => setState(() => inDrafts = false)
                  : null,
            ),
            if (inDrafts) const ClayCrumb(label: 'Drafts'),
          ],
        ),
        const SizedBox(height: 12),
        if (inDrafts)
          const Text('Drafts folder')
        else
          ClayButton(
            'Open Drafts',
            onPressed: () => setState(() => inDrafts = true),
          ),
      ],
    ),
  );
}
