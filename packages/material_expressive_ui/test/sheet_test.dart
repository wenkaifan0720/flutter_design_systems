/// Sheets: the modal bottom sheet (Compose `ModalBottomSheet` over
/// `BottomSheet`), its anchors, drag, nested scroll, scrim and back; the
/// action sheet; and the full-screen dialog — each held to the values the
/// pinned Compose states (material3 1.5.0-alpha29: `SheetBottomTokens`,
/// `ScrimTokens`, `SheetDefaults.kt`, `BottomSheet.kt`), restated here so
/// the test holds the code to the source rather than to itself. The pages
/// stand on a plain navigator (`support/page_stack.dart`), so these travel
/// with the package; the host app's go_router path is
/// `sheet_routing_test.dart`'s.
///
/// Cody test ledger (F14), from Cody's `foundation_sheet_test.dart`:
/// - "show(floating: false) is the drawer register: top-only rounding,
///   where the default keeps the floating card" → "the modal sheet rounds
///   only its top corners; the full-screen dialog covers the screen
///   square";
/// - "pageRoute mounts one inset card for both registers, sized to the
///   task, standing clear of the bottom edge" → "a short sheet is sized to
///   its content and stands on the bottom edge, at most 640dp wide";
/// - "the floating card wears the measured geometry: the sheet margin, one
///   radius on four corners, the platform grabber" → "the sheet wears
///   SheetBottomTokens: the container and the 32×4 drag handle";
/// - "detents open the card at the medium height and a drag up snaps it to
///   the cap, edge to edge" → "a tall sheet rises on its spring to half the
///   screen, a drag settles it between its anchors, a fling down dismisses
///   it";
/// - "without detents the card is still governed by its content" → "a
///   short sheet's height is its handle, its content and the bottom
///   inset";
/// - "the header band stands the platform capsules beside the title, at
///   the measured height" → not ported: a sheet's header is the screen's
///   (ExpressiveScaffold, w2-appbar); its nearest Expressive claim, the
///   action sheet's rows, is "an action sheet lists its actions in the
///   one-line list geometry and closes with the chosen value";
/// - "a header action with no callback dismisses the sheet" → "an action
///   with no callback still closes the sheet; a disabled one does not";
/// - "the floating card is the sheet material — blur under the measured
///   translucent fill — over a LIGHT dim of the page" → "the scrim is the
///   scrim role at 32 %, fading in on its spring, and a tap on it
///   dismisses the sheet";
/// - "a declared sheet page rests at the large detent, under the platform
///   header" → "a sheet page stands on the root navigator in the sheet
///   register, at its first anchor, and follows its page";
/// - "the shell action disc carries the walkthrough key and performs its
///   declared step" → not ported here: the shell action is w2-shell's and
///   w2-fab's.
///
/// A menu held open in a sheet or the full-screen dialog (a split button's)
/// takes the system back before the route does.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'support/page_stack.dart';
import 'support/pressable.dart';

// The pinned Compose values, restated.

/// `SheetBottomTokens.DockedContainerShape` = CornerExtraLargeTop: 28dp.
const double _corner = 28;

/// `SheetBottomTokens.DockedDragHandleWidth` / `…Height`.
const Size _handle = Size(32, 4);

/// `SheetDefaults.kt` `DragHandleVerticalPadding`.
const double _handlePadding = 22;

/// `ScrimTokens.ContainerOpacity`.
const double _scrimOpacity = 0.32;

/// `BottomSheetDefaults.SheetMaxWidth`.
const double _maxWidth = 640;

/// `BottomSheet.kt` `PredictiveBackMaxScaleXDistance` / `…YDistance`.
const double _backX = 48;
const double _backY = 24;

/// `PredictiveBack.transform`: `CubicBezierEasing(0.1f, 0.1f, 0f, 1f)`.
const Cubic _backEasing = Cubic(0.1, 0.1, 0, 1);

/// `ListTokens`: one-line item height.
const double _rowHeight = 56;

const Size _screen = Size(412, 892);
const EdgeInsets _insets = EdgeInsets.only(top: 24, bottom: 24);

/// Half the screen: the partial anchor of a tall sheet.
double get _partialTop => _screen.height / 2;

const Key _rootKey = ValueKey<String>('root');
const Key _tallKey = ValueKey<String>('tall');
const Key _shortKey = ValueKey<String>('short');
const Key _coverKey = ValueKey<String>('cover');
const Key _formKey = ValueKey<String>('form');
const double _shortHeight = 120;

/// The pops the guarded sheet's PopScope refused.
int _vetoes = 0;

/// The tinted sheet's colours (an artwork's scheme, as a player wears it).
final ValueNotifier<ExpressiveColorScheme> _tint = ValueNotifier(
  ExpressiveThemeData.preset('bloom', Brightness.light).colors,
);

/// A split button whose menu an app holds open over the sheet.
Widget _saveButton() => Center(
  child: ExpressiveSplitButton(
    'Save',
    onPressed: () {},
    menu: (context, close) => const Text('Save with note'),
  ),
);

final Finder _saveMenu = find.text('Save with note');

/// The page [location] stands for: the root, and the sheets and dialogs
/// raised one level off it.
Page<void> _page(String location, LocalKey key) {
  final item = RegExp(r'^/item/(\w+)$').firstMatch(location);
  if (item != null) {
    // One key for every item: a new item is the same page, new state.
    return ExpressiveSheetPage<void>(
      key: const ValueKey<String>('item-sheet'),
      child: SizedBox(height: _shortHeight, child: Text('item ${item[1]}')),
    );
  }
  return switch (location) {
    '/tall' => ExpressiveSheetPage<void>(
      key: key,
      child: ListView.builder(
        key: _tallKey,
        itemCount: 60,
        itemBuilder: (context, i) =>
            SizedBox(height: _rowHeight, child: Text('row $i')),
      ),
    ),
    '/short' => ExpressiveSheetPage<void>(
      key: key,
      child: const SizedBox(key: _shortKey, height: _shortHeight),
    ),
    '/tinted' => ExpressiveSheetPage<void>(
      key: key,
      theme: (context) => context.expressiveTheme.copyWith(colors: _tint.value),
      themeListenable: _tint,
      child: const SizedBox(key: _shortKey, height: _shortHeight),
    ),
    '/guarded' => ExpressiveSheetPage<void>(
      key: key,
      child: PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _vetoes += 1;
        },
        child: const SizedBox(key: _shortKey, height: _shortHeight),
      ),
    ),
    '/menu' => ExpressiveSheetPage<void>(
      key: key,
      child: ListView(
        children: <Widget>[
          _saveButton(),
          for (var i = 0; i < 40; i++)
            SizedBox(height: _rowHeight, child: Text('row $i')),
        ],
      ),
    ),
    '/form' => ExpressiveFullScreenDialogPage<void>(
      key: key,
      child: SizedBox.expand(key: _formKey, child: _saveButton()),
    ),
    '/cover' => ExpressiveFullScreenDialogPage<void>(
      key: key,
      child: const SizedBox.expand(key: _coverKey),
    ),
    _ => ExpressivePage<void>(
      key: key,
      child: const SizedBox.expand(key: _rootKey),
    ),
  };
}

/// Mounts the pages on a plain navigator, on a phone with a status bar and
/// a navigation bar ([_insets]), [size] wide and tall.
Future<PageStack> _mount(WidgetTester tester, {Size size = _screen}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = PageStack();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    PageStackApp(
      stack: router,
      page: _page,
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(padding: _insets, viewPadding: _insets),
        child: ExpressiveHost(child: navigator),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

final Finder _container = find.byKey(ExpressiveBottomSheet.containerKey);
final Finder _handleBox = find.byKey(ExpressiveSheetDragHandle.boxKey);

Rect _sheetRect(WidgetTester tester) => tester.getRect(_container);

ExpressiveThemeData _themeOf(WidgetTester tester) =>
    tester.element(_container).expressiveTheme;

Future<void> _backGesture(
  WidgetTester tester,
  String method, [
  Map<String, Object?>? arguments,
]) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    (_) {},
  );
  await tester.pump();
}

Map<String, Object?> _backEvent(double progress) => <String, Object?>{
  'touchOffset': <double>[4, 400],
  'progress': progress,
  'swipeEdge': 0,
};

void main() {
  testWidgets('the modal sheet rounds only its top corners; the full-screen '
      'dialog covers the screen square', (tester) async {
    final router = await _mount(tester);
    router.go('/short');
    await tester.pumpAndSettle();

    final surface = tester.widget<ExpressiveSurface>(_container);
    final corners = (surface.shape as ExpressiveCornerBorder).radiiOn(
      _sheetRect(tester),
      TextDirection.ltr,
    );
    expect(corners.topLeft, const Radius.circular(_corner));
    expect(corners.topRight, const Radius.circular(_corner));
    expect(corners.bottomLeft, Radius.zero);
    expect(corners.bottomRight, Radius.zero);

    router.go('/cover');
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
    expect(tester.getRect(find.byKey(_coverKey)), Offset.zero & _screen);
    final ground = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.byKey(_coverKey),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(
      ground.color,
      tester.element(find.byKey(_coverKey)).expressiveTheme.colors.surface,
    );
    expect(
      RoutePresentation.of(tester.element(find.byKey(_coverKey))),
      RoutePresentation.sheet,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short sheet is sized to its content and stands on the '
      'bottom edge, at most 640dp wide', (tester) async {
    final router = await _mount(tester);
    router.go('/short');
    await tester.pumpAndSettle();
    var sheet = _sheetRect(tester);
    expect(sheet.left, 0);
    expect(sheet.width, _screen.width);
    expect(sheet.bottom, _screen.height);

    // A wide window: the sheet stands centred at the maximum width.
    final wide = Size(1000, _screen.height);
    final wideRouter = await _mount(tester, size: wide);
    wideRouter.go('/short');
    await tester.pumpAndSettle();
    sheet = _sheetRect(tester);
    expect(sheet.width, _maxWidth);
    expect(sheet.left, (wide.width - _maxWidth) / 2);
    expect(sheet.bottom, wide.height);
  });

  testWidgets("a short sheet's height is its handle, its content and the "
      'bottom inset', (tester) async {
    final router = await _mount(tester);
    router.go('/short');
    await tester.pumpAndSettle();
    final sheet = _sheetRect(tester);
    expect(
      sheet.height,
      _handlePadding * 2 + _handle.height + _shortHeight + _insets.bottom,
    );
    // The content stands under the handle, clear of the navigation bar.
    final content = tester.getRect(find.byKey(_shortKey));
    expect(content.top, sheet.top + _handlePadding * 2 + _handle.height);
    expect(content.bottom, _screen.height - _insets.bottom);
    // Deterministic partial anchor: a sheet shorter than half the screen
    // has its partial anchor at its own height.
    expect(sheet.height, lessThan(_screen.height / 2));
  });

  testWidgets('the sheet wears SheetBottomTokens: the container and the '
      '32×4 drag handle', (tester) async {
    final router = await _mount(tester);
    router.go('/short');
    await tester.pumpAndSettle();
    final t = _themeOf(tester);
    final sheet = _sheetRect(tester);
    final surface = tester.widget<ExpressiveSurface>(_container);
    expect(surface.color, t.colors.surfaceContainerLow);
    expect(surface.contentColor, t.colors.onSurface);

    final box = tester.getRect(_handleBox);
    expect(box.size, Size(_handle.width, _handle.height + 2 * _handlePadding));
    expect(box.top, sheet.top);
    expect(box.center.dx, sheet.center.dx);
    final bar = tester.widget<DecoratedBox>(
      find.descendant(of: _handleBox, matching: find.byType(DecoratedBox)),
    );
    final decoration = bar.decoration as ShapeDecoration;
    expect(decoration.color, t.colors.onSurfaceVariant);
    expect(
      tester.getSize(
        find.descendant(of: _handleBox, matching: find.byType(DecoratedBox)),
      ),
      _handle,
    );
    expect(find.bySemanticsLabel('Drag handle'), findsOneWidget);
  });

  testWidgets("a sheet page's theme reaches the container and the handle, "
      'and a change repaints them', (tester) async {
    final bloom = ExpressiveThemeData.preset('bloom', Brightness.light).colors;
    final slate = ExpressiveThemeData.preset('slate', Brightness.light).colors;
    _tint.value = bloom;
    final router = await _mount(tester);
    router.go('/short');
    await tester.pumpAndSettle();
    final ambient = _themeOf(tester).colors;
    expect(ambient.surfaceContainerLow, isNot(bloom.surfaceContainerLow));

    router.go('/tinted');
    await tester.pumpAndSettle();
    Color handle() =>
        (tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: _handleBox,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as ShapeDecoration)
            .color!;
    expect(
      tester.widget<ExpressiveSurface>(_container).color,
      bloom.surfaceContainerLow,
    );
    expect(handle(), bloom.onSurfaceVariant);
    expect(
      tester.element(find.byKey(_shortKey)).expressiveTheme.colors,
      bloom,
      reason: 'the page wears it too',
    );

    // The scheme springs to another artwork's: the container follows.
    _tint.value = slate;
    await tester.pump();
    expect(
      tester.widget<ExpressiveSurface>(_container).color,
      slate.surfaceContainerLow,
    );
    expect(handle(), slate.onSurfaceVariant);
    _tint.value = bloom;
  });

  testWidgets('a tall sheet rises on its spring to half the screen, a drag '
      'settles it between its anchors, a fling down dismisses it', (
    tester,
  ) async {
    final router = await _mount(tester);
    router.go('/tall');
    // The sheet starts below the edge and springs up, past its anchor
    // (the expressive default spatial spring overshoots) and back.
    await tester.pump();
    await tester.pump();
    var highest = _screen.height;
    var sawBetween = false;
    for (var frame = 0; frame < 120; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
      final top = _sheetRect(tester).top;
      if (top > _partialTop + 1 && top < _screen.height - 1) {
        sawBetween = true;
      }
      highest = math.min(highest, top);
    }
    await tester.pumpAndSettle();
    expect(sawBetween, isTrue);
    expect(highest, lessThan(_partialTop - 1));
    expect(_sheetRect(tester).top, _partialTop);
    expect(_sheetRect(tester).height, _screen.height);

    // A slow drag up past the positional threshold settles expanded, the
    // content padded clear of the status bar.
    await tester.timedDrag(
      pressableOf(_handleBox),
      const Offset(0, -300),
      const Duration(seconds: 3),
    );
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, 0);
    expect(tester.getRect(_handleBox).top, _insets.top);

    // A slow drag down, short of half way, settles back at half height.
    await tester.timedDrag(
      pressableOf(_handleBox),
      const Offset(0, 250),
      const Duration(seconds: 3),
    );
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, _partialTop);

    // A drag inside the positional threshold springs back.
    await tester.timedDrag(
      pressableOf(_handleBox),
      const Offset(0, 40),
      const Duration(seconds: 2),
    );
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, _partialTop);

    // A fling down, faster than the velocity threshold, dismisses.
    await tester.fling(pressableOf(_handleBox), const Offset(0, 120), 1000);
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
    expect(router.path, '/');
    expect(find.byKey(_rootKey), findsOneWidget);
  });

  testWidgets('a scrollable inside the sheet raises it before it scrolls, '
      'and lowers it once it is at its top', (tester) async {
    final router = await _mount(tester);
    router.go('/tall');
    await tester.pumpAndSettle();
    final list = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(_tallKey),
        matching: find.byType(Scrollable),
      ),
    );

    // Up: the sheet rises to its top anchor, then the list scrolls.
    await tester.timedDrag(
      find.text('row 3'),
      const Offset(0, -600),
      const Duration(seconds: 4),
    );
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, 0);
    expect(list.position.pixels, greaterThan(0));

    // Down: the list returns to its top, then the sheet falls.
    final scrolled = list.position.pixels;
    await tester.timedDrag(
      find.byKey(_tallKey),
      Offset(0, scrolled + 200),
      const Duration(seconds: 4),
    );
    await tester.pumpAndSettle();
    expect(list.position.pixels, 0);
    expect(_sheetRect(tester).top, _partialTop);
  });

  testWidgets('the scrim is the scrim role at 32 %, fading in on its spring, '
      'and a tap on it dismisses the sheet', (tester) async {
    final router = await _mount(tester);
    router.go('/short');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    Color scrim() => tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(IgnorePointer),
            matching: find.byType(ColoredBox),
          ),
        )
        .map((box) => box.color)
        .firstWhere((color) => color.a < 1);

    expect(scrim().a, lessThan(_scrimOpacity));
    await tester.pumpAndSettle();
    final t = _themeOf(tester);
    expect(scrim().a, closeTo(_scrimOpacity, 1e-6));
    expect(scrim().withValues(alpha: 1), t.colors.scrim.withValues(alpha: 1));

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
    expect(router.path, '/');
  });

  testWidgets('a sheet page stands on the root navigator in the sheet '
      'register, at its first anchor, and follows its page', (tester) async {
    final router = await _mount(tester);
    router.go('/item/1');
    await tester.pumpAndSettle();
    expect(find.text('item 1'), findsOneWidget);
    expect(
      RoutePresentation.of(tester.element(find.text('item 1'))),
      RoutePresentation.sheet,
    );
    // The page beneath stays where it stood.
    expect(tester.getRect(find.byKey(_rootKey)), Offset.zero & _screen);
    final top = _sheetRect(tester).top;

    // Same page key, new state: the sheet shows the new page in place.
    router.go('/item/2');
    await tester.pump();
    expect(find.text('item 2'), findsOneWidget);
    expect(find.text('item 1'), findsNothing);
    expect(_sheetRect(tester).top, top);

    // Its own pop closes it.
    await Navigator.of(tester.element(find.text('item 2'))).maybePop();
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
  });

  testWidgets('the system back settles an expanded sheet at its partial '
      'anchor, then dismisses it', (tester) async {
    final router = await _mount(tester);
    router.go('/tall');
    await tester.pumpAndSettle();
    await tester.tap(pressableOf(_handleBox));
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, _partialTop);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
    expect(router.path, '/');
  });

  testWidgets('a PopScope(canPop: false) in the sheet survives a scrim tap, '
      'a fling down and the system back', (tester) async {
    _vetoes = 0;
    final router = await _mount(tester);
    router.go('/guarded');
    await tester.pumpAndSettle();
    final rest = _sheetRect(tester);

    await tester.tapAt(Offset(_screen.width / 2, 100));
    await tester.pumpAndSettle();
    expect(_sheetRect(tester), rest);
    expect(_vetoes, 1);

    await tester.fling(pressableOf(_handleBox), const Offset(0, 120), 1000);
    await tester.pumpAndSettle();
    expect(_sheetRect(tester), rest);
    expect(_vetoes, 2);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_sheetRect(tester), rest);
    expect(_vetoes, 3);
    expect(router.path, '/guarded');

    // Android predictive back: the vetoed dismissal is not previewed, and
    // the commit is refused through the pop entries.
    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.7));
    expect(_sheetRect(tester), rest);
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(_sheetRect(tester), rest);
    expect(_vetoes, 4);
    expect(router.path, '/guarded');
  });

  testWidgets('a menu open in the sheet takes the first back: the sheet '
      'neither settles nor leaves, nor previews either', (tester) async {
    final router = await _mount(tester);
    router.go('/menu');
    await tester.pumpAndSettle();
    final rest = _sheetRect(tester);
    Future<void> open() async {
      await tester.tap(find.byType(ExpressiveSplitTrailingButton));
      await tester.pumpAndSettle();
      expect(_saveMenu, findsOneWidget);
    }

    // Expanded, the back would settle the sheet at its partial anchor.
    await tester.tap(pressableOf(_handleBox));
    await tester.pumpAndSettle();
    final expanded = _sheetRect(tester);
    expect(expanded.top, 0);
    await open();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_saveMenu, findsNothing);
    expect(_sheetRect(tester), expanded);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_sheetRect(tester), rest);

    // At its partial anchor, the back would dismiss it.
    await open();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_saveMenu, findsNothing);
    expect(_sheetRect(tester), rest);
    expect(router.path, '/menu');

    // Android predictive back: no preview; the commit closes the menu.
    await open();
    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.7));
    expect(_sheetRect(tester), rest);
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(_saveMenu, findsNothing);
    expect(_sheetRect(tester), rest);
    expect(router.path, '/menu');

    // A fling down still dismisses the sheet, the menu with it.
    await open();
    await tester.fling(pressableOf(_handleBox), const Offset(0, 300), 2000);
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
    expect(_saveMenu, findsNothing);
    expect(router.path, '/');
  });

  testWidgets('a menu open in the full-screen dialog takes the first back; '
      'the dialog stays and previews no dismissal', (tester) async {
    final router = await _mount(tester);
    router.go('/form');
    await tester.pumpAndSettle();
    final page = tester.getRect(find.byKey(_formKey));
    await tester.tap(find.byType(ExpressiveSplitTrailingButton));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_saveMenu, findsNothing);
    expect(tester.getRect(find.byKey(_formKey)), page);
    expect(router.path, '/form');

    await tester.tap(find.byType(ExpressiveSplitTrailingButton));
    await tester.pumpAndSettle();
    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.5));
    expect(tester.getRect(find.byKey(_formKey)), page);
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(_saveMenu, findsNothing);
    expect(tester.getRect(find.byKey(_formKey)), page);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.path, '/');
  });

  testWidgets('the drag handle expands a partial sheet and dismisses an '
      'expanded one', (tester) async {
    final router = await _mount(tester);
    router.go('/tall');
    await tester.pumpAndSettle();
    await tester.tap(pressableOf(_handleBox));
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, 0);
    await tester.tap(pressableOf(_handleBox));
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
    expect(router.path, '/');
  });

  testWidgets('the drag handle draws no state layer: hover and a press '
      'leave it as it was, the pointer is the grab hand, and keyboard '
      'focus rings the bar alone', (tester) async {
    // The user's 11-09 capture: a hover painted a grey square over the
    // handle's whole 48dp target round its 32×4 bar.
    final router = await _mount(tester);
    router.go('/tall');
    await tester.pumpAndSettle();
    final pressable = pressableOf(_handleBox);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(of: pressable, matching: find.byType(RepaintBoundary))
          .first,
    );
    Future<ByteData> shot() async => (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      image.dispose();
      return data!;
    }))!;
    final width = boundary.size.width.round();
    // The box round every pixel that differs from [base], in global
    // coordinates; null when none does.
    Rect? changed(ByteData base, ByteData now) {
      Rect? box;
      for (var i = 0; i < base.lengthInBytes; i += 4) {
        if (base.getUint32(i) == now.getUint32(i)) continue;
        final p = i ~/ 4;
        final pixel = Rect.fromLTWH(
          (p % width).toDouble(),
          (p ~/ width).toDouble(),
          1,
          1,
        ).shift(boundary.localToGlobal(Offset.zero));
        box = box?.expandToInclude(pixel) ?? pixel;
      }
      return box;
    }

    final idle = await shot();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_handleBox));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.grab,
    );
    expect(changed(idle, await shot()), isNull, reason: 'hovered');
    await mouse.down(tester.getCenter(_handleBox));
    await tester.pump(const Duration(milliseconds: 300));
    expect(changed(idle, await shot()), isNull, reason: 'pressed');
    await mouse.cancel();
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(_sheetRect(tester).top, greaterThan(0), reason: 'still partial');

    // Keyboard focus: the ring round the bar, and nothing beyond it.
    // The node its ink focuses, read from just inside the ink's own Focus
    // (the first under the InkResponse; one above it is not the ink's).
    FocusNode? node;
    tester
        .element(
          find
              .descendant(
                of: find
                    .descendant(
                      of: pressable,
                      matching: find.byWidgetPredicate((w) => w is InkResponse),
                    )
                    .first,
                matching: find.byType(Focus),
              )
              .first,
        )
        .visitChildren(
          (child) => node ??= Focus.maybeOf(child, createDependency: false),
        );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    node!.requestFocus();
    // As the state matrix and focus_ring_test pump a focused part: focus
    // may land after the first frame, a second builds the ring.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      node!.hasPrimaryFocus,
      isTrue,
      reason: 'focus went to ${FocusManager.instance.primaryFocus}',
    );
    // The mouse connected after the handle was built, turning the mode
    // traditional unheard: the ring reads the mode when focus arrives.
    expect(
      find.descendant(
        of: pressable,
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.foregroundPainter.runtimeType.toString() == '_FocusRingPainter',
        ),
      ),
      findsOneWidget,
      reason: 'keyboard focus builds the ring',
    );
    final bar = tester.getRect(
      find.descendant(of: _handleBox, matching: find.byType(DecoratedBox)),
    );
    final ring = changed(idle, await shot());
    expect(ring, isNotNull, reason: 'keyboard focus shows a ring');
    const reach = ExpressiveFocusRing.offset + ExpressiveFocusRing.thickness;
    expect(bar.inflate(reach + 1).contains(ring!.topLeft), isTrue);
    expect(bar.inflate(reach + 1).contains(ring.bottomRight), isTrue);
    expect(ring.width, greaterThan(bar.width + 2 * ExpressiveFocusRing.offset));
    // Drawn pixels are the rasterizer's, as a golden's: macOS runs it.
  }, tags: const ['goldens']);

  testWidgets('Android: predictive back scales the sheet by the Compose '
      'formula, a cancel springs it home, a commit settles or dismisses', (
    tester,
  ) async {
    final router = await _mount(tester);
    router.go('/tall');
    await tester.pumpAndSettle();
    final rest = _sheetRect(tester);

    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.5));
    final progress = _backEasing.transform(0.5);
    final scaleX = 1 - _backX * progress / rest.width;
    final scaleY = 1 - _backY * progress / rest.height;
    // TransformOrigin(0.5, (offset + height) / height), in the sheet's own
    // frame.
    final pivot = rest.top + rest.height;
    final scaled = _sheetRect(tester);
    expect(scaled.width, closeTo(rest.width * scaleX, 1e-6));
    expect(scaled.center.dx, closeTo(rest.center.dx, 1e-6));
    expect(scaled.height, closeTo(rest.height * scaleY, 1e-6));
    expect(scaled.top, closeTo(rest.top + pivot * (1 - scaleY), 1e-6));

    await _backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(_sheetRect(tester), rest);
    expect(router.path, '/tall');

    // Expanded: a commit settles at the partial anchor.
    await tester.tap(pressableOf(_handleBox));
    await tester.pumpAndSettle();
    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(1));
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(_sheetRect(tester), rest);

    // Partial: a commit dismisses.
    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.7));
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(_container, findsNothing);
    expect(router.path, '/');
  });

  testWidgets('iOS: the sheet leaves the back gesture alone and is swiped '
      'down', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final router = await _mount(tester);
      router.go('/short');
      await tester.pumpAndSettle();
      final rest = _sheetRect(tester);
      await _backGesture(tester, 'startBackGesture', _backEvent(0));
      await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.5));
      expect(_sheetRect(tester), rest);
      await _backGesture(tester, 'cancelBackGesture');

      await tester.fling(pressableOf(_handleBox), const Offset(0, 100), 1000);
      await tester.pumpAndSettle();
      expect(_container, findsNothing);
      expect(router.path, '/');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a sheet raised from code keeps the theme it was raised in '
      '(InheritedTheme.capture)', (tester) async {
    await _mount(tester);
    final bloom = ExpressiveThemeData.preset('bloom', Brightness.dark);
    final rootTheme = tester.element(find.byKey(_rootKey)).expressiveTheme;
    expect(rootTheme.id, isNot(bloom.id));

    final inner = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => ExpressiveHost(child: app!),
        home: ExpressiveTheme(
          data: bloom,
          child: SizedBox.expand(key: inner),
        ),
      ),
    );
    showExpressiveBottomSheet<void>(
      inner.currentContext!,
      builder: (context) => const SizedBox(height: _shortHeight),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<ExpressiveSurface>(_container).color,
      bloom.colors.surfaceContainerLow,
    );
    expect(_themeOf(tester), bloom);
  });

  testWidgets('the full-screen dialog rises from the bottom edge and closes '
      'by its pop and by the system back', (tester) async {
    final router = await _mount(tester);
    router.go('/cover');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final rising = tester.getRect(find.byKey(_coverKey));
    expect(rising.top, greaterThan(0));
    expect(rising.top, lessThan(_screen.height));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_coverKey)).top, 0);

    await Navigator.of(tester.element(find.byKey(_coverKey))).maybePop();
    await tester.pumpAndSettle();
    expect(find.byKey(_coverKey), findsNothing);

    router.go('/cover');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_coverKey), findsNothing);
    expect(router.path, '/');
  });

  testWidgets('Android: the full-screen dialog takes the predictive back '
      "the page takes: a cancel springs it home, a commit closes it", (
    tester,
  ) async {
    final router = await _mount(tester);
    router.go('/cover');
    await tester.pumpAndSettle();
    final cover = find.byKey(_coverKey);
    expect(tester.getRect(cover), Offset.zero & _screen);

    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.5));
    // The page's predictive back frame (Android's motion spec, as
    // page_test states it): scale to 90 %, shift width / 20 - 8dp, over
    // `PredictiveBack.transform`.
    final eased = _backEasing.transform(0.5);
    final scale = 1 - 0.1 * eased;
    final size = _screen * scale;
    final frame = Rect.fromLTWH(
      (_screen.width - size.width) / 2 + (_screen.width / 20 - 8) * eased,
      (_screen.height - size.height) / 2,
      size.width,
      size.height,
    );
    final moved = tester.getRect(cover);
    expect(moved.left, closeTo(frame.left, 1e-6));
    expect(moved.top, closeTo(frame.top, 1e-6));
    expect(moved.width, closeTo(frame.width, 1e-6));
    expect(moved.height, closeTo(frame.height, 1e-6));

    await _backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(tester.getRect(cover), Offset.zero & _screen);
    expect(router.path, '/cover');

    await _backGesture(tester, 'startBackGesture', _backEvent(0));
    await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.7));
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(cover, findsNothing);
    expect(router.path, '/');
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS: the full-screen dialog leaves the back gesture alone and '
      'is swiped down: a short swipe springs home, a long one closes it', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final router = await _mount(tester);
      router.go('/cover');
      await tester.pumpAndSettle();
      final cover = find.byKey(_coverKey);
      await _backGesture(tester, 'startBackGesture', _backEvent(0));
      await _backGesture(tester, 'updateBackGestureProgress', _backEvent(0.5));
      expect(tester.getRect(cover), Offset.zero & _screen);
      await _backGesture(tester, 'cancelBackGesture');

      // The page follows the finger down.
      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      final followed = tester.getRect(cover).top;
      expect(followed, greaterThan(0));
      expect(followed, lessThanOrEqualTo(120));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(cover, findsNothing);
      expect(router.path, '/');

      // A slow swipe short of the sheet's 56dp positional threshold springs
      // home.
      router.go('/cover');
      await tester.pumpAndSettle();
      await tester.timedDragFrom(
        tester.getCenter(cover),
        const Offset(0, 40),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(cover), Offset.zero & _screen);
      expect(router.path, '/cover');
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('the controller of an unbuilt sheet waits to show it', () {
    final controller = ExpressiveSheetController();
    addTearDown(controller.dispose);
    expect(controller.currentValue, ExpressiveSheetValue.hidden);
    expect(controller.isVisible, isFalse);
    expect(controller.offset, isNull);
  });
}
