import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => TermToaster(
    child: Center(
      child: Builder(
        builder: (context) => TermButton(
          label: 'Save draft',
          onPressed: () => TermToaster.show(
            context,
            message: 'Revision ${++revision} saved',
            tone: TermTone.success,
          ),
        ),
      ),
    ),
  );
}
