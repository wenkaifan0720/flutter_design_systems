/// The split-button group's demo: the four styles with a live menu, the
/// size ladder (L and XL as the page's one hero moment), the open state,
/// and the disabled state.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The split-button group's demo, in [brightness].
Widget kitSplitButtonDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Split button',
  sections: const <Widget>[_Styles(), _Sizes(), _Hero(), _Open(), _Disabled()],
);

void _noop() {}

/// [children] in a row that wraps, 8dp apart.
Widget _wrap(List<Widget> children) => Wrap(
  spacing: kitGap,
  runSpacing: kitGap,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// A quiet caption line under a row.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Text(
      text,
      style: t.type.bodySmall.copyWith(color: t.colors.onSurfaceVariant),
    );
  }
}

/// The demo's stand-in menu until the menus family lands: [items] on a
/// lifted container, each closing the menu.
Widget Function(BuildContext, VoidCallback) _menu(List<String> items) =>
    (context, close) {
      final t = context.expressiveTheme;
      return IntrinsicWidth(
        child: ExpressiveSurface(
          shape: t.shapes.large,
          color: t.colors.surfaceContainer,
          contentColor: t.colors.onSurface,
          shadowElevation: ExpressiveElevationLevel.level2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final item in items) KitAction(item, onTap: close),
            ],
          ),
        ),
      );
    };

class _Styles extends StatelessWidget {
  const _Styles();

  @override
  Widget build(BuildContext context) => kitSection(
    'Four styles · tap the chevron',
    children: <Widget>[
      _wrap(<Widget>[
        ExpressiveSplitButton(
          'Send',
          icon: ExpressiveSymbols.send,
          onPressed: _noop,
          menu: _menu(const <String>['Schedule send', 'Send without sound']),
          menuLabel: 'Send options',
        ),
        ExpressiveSplitButton(
          'Save draft',
          kind: ExpressiveSplitButtonKind.tonal,
          onPressed: _noop,
          menu: _menu(const <String>['Save as template', 'Discard']),
          menuLabel: 'Draft options',
        ),
        ExpressiveSplitButton(
          'Export',
          icon: ExpressiveSymbols.download,
          kind: ExpressiveSplitButtonKind.outlined,
          onPressed: _noop,
          menu: _menu(const <String>['PDF', 'CSV', 'Image']),
          menuLabel: 'Export formats',
        ),
        ExpressiveSplitButton(
          'Reply',
          icon: ExpressiveSymbols.reply,
          kind: ExpressiveSplitButtonKind.elevated,
          onPressed: _noop,
          menu: _menu(const <String>['Reply all', 'Forward']),
          menuLabel: 'Reply options',
        ),
      ]),
      const _Caption(
        'The chevron turns and its button rounds fully while the menu is '
        'open.',
      ),
    ],
  );
}

class _Sizes extends StatelessWidget {
  const _Sizes();

  @override
  Widget build(BuildContext context) => kitSection(
    // A split button's halves keep the small height (Compose's rows), so
    // XS stands as tall as S.
    'Sizes · XS and S 40 · M 56',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveSplitButton(
          'Share',
          size: ExpressiveSplitButtonSize.extraSmall,
          kind: ExpressiveSplitButtonKind.tonal,
          onPressed: _noop,
        ),
        ExpressiveSplitButton(
          'Share',
          kind: ExpressiveSplitButtonKind.tonal,
          onPressed: _noop,
        ),
        ExpressiveSplitButton(
          'Share',
          size: ExpressiveSplitButtonSize.medium,
          kind: ExpressiveSplitButtonKind.tonal,
          onPressed: _noop,
        ),
      ]),
    ],
  );
}

/// L and XL are hero sizes: the page spends its one hero moment on them.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => kitSection(
    'Hero sizes · L 96 · XL 136',
    children: const <Widget>[
      ExpressiveHeroMoment(
        label: 'publish',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExpressiveSplitButton(
              'Post',
              size: ExpressiveSplitButtonSize.large,
              onPressed: _noop,
            ),
            SizedBox(height: kitGap),
            ExpressiveSplitButton(
              'Go',
              size: ExpressiveSplitButtonSize.extraLarge,
              onPressed: _noop,
            ),
          ],
        ),
      ),
    ],
  );
}

/// The trailing half checked, held open without a menu: the circle, the
/// veil and the turned chevron.
class _Open extends StatelessWidget {
  const _Open();

  @override
  Widget build(BuildContext context) => kitSection(
    'Open',
    children: <Widget>[
      _wrap(<Widget>[
        ExpressiveSplitButton(
          'Add to cart',
          icon: ExpressiveSymbols.addShoppingCart,
          menuOpen: true,
          onMenuOpenChanged: (_) {},
          onPressed: _noop,
        ),
        ExpressiveSplitButton(
          'Filters',
          kind: ExpressiveSplitButtonKind.outlined,
          menuOpen: true,
          onMenuOpenChanged: (_) {},
          onPressed: _noop,
        ),
      ]),
    ],
  );
}

class _Disabled extends StatelessWidget {
  const _Disabled();

  @override
  Widget build(BuildContext context) => kitSection(
    'Disabled',
    children: <Widget>[
      _wrap(const <Widget>[
        ExpressiveSplitButton('Send', onPressed: null),
        ExpressiveSplitButton(
          'Send',
          kind: ExpressiveSplitButtonKind.outlined,
          onPressed: null,
        ),
      ]),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// Send, with its options behind the chevron.
Widget kitSpecimenSplitButtonSend() => Center(
  child: ExpressiveSplitButton(
    'Send',
    icon: ExpressiveSymbols.send,
    onPressed: _noop,
    menu: _menu(const <String>['Schedule send', 'Send without sound']),
    menuLabel: 'Send options',
  ),
);
