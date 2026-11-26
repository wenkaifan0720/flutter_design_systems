import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => LedgerToaster(
    child: Center(
      child: Builder(
        builder: (context) => LedgerButton(
          'Save draft',
          onPressed: () =>
              LedgerToast.show(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
