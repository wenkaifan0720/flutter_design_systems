// Civic against the shared component list: each row's live specimen, or
// why a public service leaves it out and what it uses instead.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitInventoryDemo(Brightness brightness) =>
    kitApp(brightness: brightness, home: const _Inventory());

class _Inventory extends StatelessWidget {
  const _Inventory();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final margin = CivicLayout.marginFor(MediaQuery.sizeOf(context).width);
    return CivicScaffold(
      topBar: const CivicTopBar(title: 'Civic', emblem: KitEmblem()),
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CivicLayout.readingWidth + 2 * CivicSpacing.s40,
          ),
          child: DesignInventoryGallery(
            inventory: civicInventory,
            padding: EdgeInsets.symmetric(
              horizontal: margin,
              vertical: CivicSpacing.s32,
            ),
            groupBuilder: (context, group, present, total) => Padding(
              padding: const EdgeInsets.only(
                top: CivicSpacing.s32,
                bottom: CivicSpacing.s16,
              ),
              child: Text('$group: $present of $total', style: text.headingL),
            ),
            rowBuilder: (context, row, entry, specimen) {
              final height = civicInventoryHeights[row.id];
              final reason = entry?.absentReason;
              return Padding(
                padding: const EdgeInsets.only(bottom: CivicSpacing.s32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(row.name, style: text.headingS),
                    const SizedBox(height: CivicSpacing.s12),
                    if (specimen != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(height: height, child: specimen),
                      )
                    else
                      CivicInset(
                        child: Text(
                          reason == null
                              ? 'Missing'
                              : DesignInventory.absentLabel(reason),
                          style: text.body.copyWith(color: t.textSecondary),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
