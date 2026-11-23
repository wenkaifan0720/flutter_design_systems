import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The app frame: the host, the screen, the page change.
Widget kitAppDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'App frame',
  sections: const [_Frame(), _States(), _Framed(), _Pages()],
);

class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) {
    final t = context.applianceTheme.textTheme;
    return KitSection(
      title: 'Host and screen',
      note: 'ApplianceHost once over the navigator; ApplianceScreen per page.',
      children: [
        Text(
          'A pushed page slides home along its track from the end side and '
          'seats at its detent; the page beneath slides back and dims.',
          style: t.body,
        ),
        ApplianceButton(
          'Push a page',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ApplianceScreen(
                topBar: ApplianceAppBar(
                  title: 'Pushed',
                  onBack: () => Navigator.of(context).pop(),
                ),
                body: AppliancePanel(
                  child: Text('A page on the housing.', style: t.body),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// What a page shows while its data comes, and when it cannot.
class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Loading and failing',
    note: 'ApplianceLoadingState, ApplianceErrorState, ApplianceInput.',
    children: [
      const AppliancePanel(
        child: ApplianceLoadingState(label: 'Loading the orders'),
      ),
      AppliancePanel(
        child: ApplianceErrorState(
          title: 'Could not load the orders',
          message: 'Check the connection, then try again.',
          onRetry: () => showApplianceToast(context, 'Trying again'),
        ),
      ),
      const ApplianceInput(labelText: 'Order number', hintText: 'Six figures'),
    ],
  );
}

/// A page as the app frames it, without the router.
class _Framed extends StatelessWidget {
  const _Framed();

  @override
  Widget build(BuildContext context) {
    final night = context.applianceTheme.colors.brightness == Brightness.dark;
    return KitSection(
      title: 'A page in its frame',
      note: 'AppliancePreview: the places and the act round a place\'s page.',
      children: [
        Center(
          child: SizedBox(
            width: 360,
            height: 520,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ApplianceMetrics.panelRadius),
              child: AppliancePreview(
                brightness: night ? Brightness.dark : Brightness.light,
                tabs: const [
                  ApplianceTab(LucideIcons.house, 'Home'),
                  ApplianceTab(LucideIcons.store, 'Shop'),
                  ApplianceTab(LucideIcons.package, 'Orders'),
                ],
                action: ApplianceShellAction(
                  icon: LucideIcons.plus,
                  label: 'New list',
                  accent: true,
                  onPressed: (_) {},
                ),
                child: ApplianceScreen(
                  topBar: const ApplianceAppBar(title: 'Home'),
                  body: AppliancePanel(
                    child: Text(
                      'A place with the key strip under it.',
                      style: context.applianceTheme.textTheme.body,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The router's pages in a small stack: a place, the page pushed off it and a
/// sheet raised over it, each closed by its bar's way out.
class _Pages extends StatefulWidget {
  const _Pages();

  @override
  State<_Pages> createState() => _PagesState();
}

class _PagesState extends State<_Pages> {
  String? _open;

  Widget _page(String title, List<Widget> children) => Builder(
    builder: (context) => ApplianceScreen(
      topBar: ApplianceAppBar(
        title: title,
        leading: ApplianceAppBar.autoLeading(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => KitSection(
    title: "The router's pages",
    note:
        'AppliancePage slides a page home along its track; '
        'ApplianceSheetPage raises a sheet. Each bar finds its own way out.',
    children: [
      Center(
        child: SizedBox(
          width: 360,
          height: 420,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ApplianceMetrics.panelRadius),
            // A router inside the page stands in a semantics container of its
            // own: its first page's modal barrier would otherwise hide from a
            // screen reader everything the gallery painted before it.
            child: Semantics(
              container: true,
              child: Navigator(
                pages: [
                  AppliancePage<void>(
                    key: const ValueKey<String>('orders'),
                    child: _page('Orders', [
                      ApplianceListGroup(
                        children: [
                          ApplianceListTile(
                            title: 'Order 2041',
                            subtitle: 'On its way',
                            showChevron: true,
                            onTap: () => setState(() => _open = 'order'),
                          ),
                        ],
                      ),
                      const SizedBox(height: ApplianceSpacing.large),
                      ApplianceButton(
                        'Filter',
                        onPressed: () => setState(() => _open = 'filter'),
                      ),
                    ]),
                  ),
                  if (_open == 'order')
                    AppliancePage<void>(
                      key: const ValueKey<String>('order'),
                      child: _page('Order 2041', const [
                        AppliancePanel(child: Text('Arrives Tuesday')),
                      ]),
                    ),
                  if (_open == 'filter')
                    ApplianceSheetPage<void>(
                      key: const ValueKey<String>('filter'),
                      size: ApplianceSheetSize.drawer,
                      child: _page('Filter', const [
                        ApplianceListGroup(
                          children: [
                            ApplianceListTile(title: 'Kitchen'),
                            ApplianceListTile(title: 'Laundry'),
                          ],
                        ),
                      ]),
                    ),
                ],
                onDidRemovePage: (_) {
                  if (mounted && _open != null) setState(() => _open = null);
                },
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
