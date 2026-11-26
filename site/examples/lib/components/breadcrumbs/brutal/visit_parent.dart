import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

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
        BrutalBreadcrumb(
          crumbs: [
            BrutalCrumb(
              'Files',
              onPressed: inDrafts
                  ? () => setState(() => inDrafts = false)
                  : null,
            ),
            if (inDrafts) const BrutalCrumb('Drafts'),
          ],
        ),
        const SizedBox(height: 12),
        if (inDrafts)
          const Text('Drafts folder')
        else
          BrutalButton(
            'Open Drafts',
            onPressed: () => setState(() => inDrafts = true),
          ),
      ],
    ),
  );
}
