import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => ComicButton(
    'Save draft',
    onPressed: () => showComicSnackBar(context, 'Revision ${++revision} saved'),
  );
}
