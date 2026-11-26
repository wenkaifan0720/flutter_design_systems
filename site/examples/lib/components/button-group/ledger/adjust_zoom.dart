import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class AdjustZoom extends StatefulWidget {
  const AdjustZoom({super.key});

  @override
  State<AdjustZoom> createState() => _AdjustZoomState();
}

class _AdjustZoomState extends State<AdjustZoom> {
  int zoom = 100;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LedgerButtonRow(
        children: [
          LedgerButton(
            'Out',
            onPressed: zoom > 10 ? () => setState(() => zoom -= 10) : null,
          ),
          LedgerButton('In', onPressed: () => setState(() => zoom += 10)),
        ],
      ),
      const SizedBox(height: 12),
      Text('Zoom: $zoom%'),
    ],
  );
}
