import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

import '../kit.dart';

/// Appliance against the shared component list: each row's live specimen,
/// or why a household device leaves it out.
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
    final theme = ApplianceTheme.of(context);
    final t = theme.textTheme;
    final route = ModalRoute.of(context);
    // The page bleeds full and the list pads itself, so the plates' shadows
    // stand inside the scroll view's edges rather than cut by them.
    final margin = ApplianceSpacing.pageMargin(
      MediaQuery.sizeOf(context).width,
    );
    return ApplianceScreen(
      scroll: false,
      fullBleed: true,
      topBar: ApplianceAppBar(
        title: 'Inventory',
        onBack: route?.canPop ?? false
            ? () => Navigator.of(context).maybePop()
            : null,
      ),
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720 + 2 * margin),
          child: RawInventoryGallery(
            inventory: applianceInventory,
            padding: EdgeInsets.fromLTRB(
              margin,
              ApplianceSpacing.large,
              margin,
              ApplianceSpacing.huge,
            ),
            groupBuilder: (context, group, present, total) => Padding(
              padding: const EdgeInsets.only(
                top: ApplianceSpacing.large,
                bottom: ApplianceSpacing.small,
              ),
              child: ApplianceSectionHeader('$group: $present of $total'),
            ),
            rowBuilder: (context, row, entry, specimen) {
              final height = applianceInventoryHeights[row.id];
              final reason = entry?.absentReason;
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: ApplianceSpacing.regular,
                ),
                child: AppliancePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(row.name, style: t.label),
                      const SizedBox(height: ApplianceSpacing.medium),
                      if (specimen != null)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(height: height, child: specimen),
                        )
                      else
                        Text(
                          RawInventory.absentLabel(reason ?? 'Missing'),
                          style: t.secondary,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
