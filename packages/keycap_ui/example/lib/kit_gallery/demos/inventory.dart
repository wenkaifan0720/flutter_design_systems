import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';

import '../kit.dart';

/// Keycap against the shared component list: each row's live specimen,
/// or why a keyboard leaves it out.
Widget kitInventoryDemo(Brightness brightness) => Builder(
  builder: (context) {
    const page = _Inventory();
    if (KitGalleryScope.of(context)) return page;
    return kitApp(brightness: brightness, home: page);
  },
);

class _Inventory extends StatelessWidget {
  const _Inventory();

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final t = theme.textTheme;
    final route = ModalRoute.of(context);
    // The page bleeds full and the list pads itself, so the caps' walls
    // stand inside the scroll view's edges rather than cut by them.
    final margin = KeycapSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    return KeycapScreen(
      scroll: false,
      fullBleed: true,
      topBar: KeycapAppBar(
        title: 'Inventory',
        onBack: route?.canPop ?? false
            ? () => Navigator.of(context).maybePop()
            : null,
      ),
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720 + 2 * margin),
          child: DesignInventoryGallery(
            inventory: keycapInventory,
            padding: EdgeInsets.fromLTRB(
              margin,
              KeycapSpacing.large,
              margin,
              KeycapSpacing.huge,
            ),
            groupBuilder: (context, group, present, total) => Padding(
              padding: const EdgeInsets.only(
                top: KeycapSpacing.large,
                bottom: KeycapSpacing.small,
              ),
              // Flush with the rows' names: no list card here to inset to.
              child: KeycapSectionHeader(
                '$group: $present of $total',
                style: const KeycapStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
              ),
            ),
            rowBuilder: (context, row, entry, specimen) {
              final height = keycapInventoryHeights[row.id];
              final reason = entry?.absentReason;
              return Padding(
                padding: const EdgeInsets.only(bottom: KeycapSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.name,
                      style: t.label.copyWith(color: theme.colors.inkMuted),
                    ),
                    const SizedBox(height: KeycapSpacing.small),
                    if (specimen != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(height: height, child: specimen),
                      )
                    else
                      Text(
                        DesignInventory.absentLabel(reason ?? 'Missing'),
                        style: t.secondary,
                      ),
                    const SizedBox(height: KeycapSpacing.large),
                    const KeycapDivider(),
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
