import 'package:cupertino_ui/cupertino_ui.dart';

class SortFiles extends StatefulWidget {
  const SortFiles({super.key});
  @override
  State<SortFiles> createState() => _SortFilesState();
}

class _SortFilesState extends State<SortFiles> {
  String order = 'Name';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CupertinoMenuAnchor(
        builder: (context, controller, child) => CupertinoButton(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: const Text('Sort files'),
        ),
        menuChildren: [
          for (final sort in ['Name', 'Date'])
            CupertinoMenuItem(
              leading: order == sort
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onPressed: () => setState(() => order = sort),
              child: Text(sort),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}
