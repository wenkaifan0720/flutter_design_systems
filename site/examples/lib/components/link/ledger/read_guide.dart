import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class ReadGuide extends StatelessWidget {
  const ReadGuide({super.key});

  @override
  Widget build(BuildContext context) => LedgerMoreLink(
    'Reading guide',
    onTap: () => Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Borrow a book for up to three weeks.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                LedgerMoreLink(
                  'Back to library',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
