import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

class RequestReceipt extends StatefulWidget {
  const RequestReceipt({super.key});

  @override
  State<RequestReceipt> createState() => _RequestReceiptState();
}

class _RequestReceiptState extends State<RequestReceipt> {
  bool receipt = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlossCheckbox(
          semanticLabel: 'Email receipt',
          value: receipt,
          onChanged: (next) => setState(() => receipt = next ?? false),
        ),
        const SizedBox(height: 12),
        Text(
          receipt ? 'Email receipt requested' : 'No email receipt requested',
        ),
      ],
    ),
  );
}
