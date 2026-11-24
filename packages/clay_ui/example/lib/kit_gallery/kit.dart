/// The Clay gallery's frame: the theme every demo shows in, the app round
/// a demo shown on its own, and the page, section and row every demo is
/// laid out with.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:clay_ui/clay_ui.dart';

import 'theme.dart';

/// The preset the gallery shows; its picker changes it.
String kitShownPreset = kitPreset;

/// A theme the gallery shows instead of a preset (a brand's), when set.
ClayThemeData Function(Brightness brightness)? kitShownTheme;

/// The theme a demo shows in.
ClayThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    ClayThemeData.preset(kitShownPreset, brightness);

/// Marks a demo shown inside the gallery's own app, which brings its theme.
class KitGalleryScope extends InheritedWidget {
  /// The scope over [child].
  const KitGalleryScope({super.key, required super.child});

  /// Whether [context] is inside the gallery's app.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitGalleryScope>() != null;

  @override
  bool updateShouldNotify(KitGalleryScope oldWidget) => false;
}

/// An app round [home], in Clay at [brightness].
Widget kitApp({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: clayPageTransitions,
        ),
      ),
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      builder: (context, child) => ClayTheme(
        data: kitTheme(brightness),
        child: ClayToaster(child: child ?? const SizedBox.shrink()),
      ),
      home: home,
    );

/// A demo page titled [title] holding [sections].
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
}) => Builder(
  builder: (context) {
    final page = _KitPage(title: title, sections: sections);
    if (KitGalleryScope.of(context)) return page;
    return kitApp(brightness: brightness, home: page);
  },
);

class _KitPage extends StatelessWidget {
  const _KitPage({required this.title, required this.sections});

  final String title;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = ClaySpacing.pageMargin(width);
    final route = ModalRoute.of(context);
    // The bar spans the content column and its margins, so the page's title
    // starts where the sections do at every width.
    const column = 720.0;
    return ClayScaffold(
      topBar: ColoredBox(
        color: context.clayTheme.colors.ground,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: column + 2 * margin),
            child: ClayTopBar(
              title: title,
              onBack: route?.canPop ?? false
                  ? () => Navigator.of(context).maybePop()
                  : null,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          ClaySpacing.regular,
          margin,
          ClaySpacing.huge,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: column),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in sections.indexed) ...[
                    if (i > 0) const SizedBox(height: ClaySpacing.extraLarge),
                    s,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A demo's section: a [title], a [note] under it, then [children] [gap]
/// apart.
class KitSection extends StatelessWidget {
  /// A section titled [title].
  const KitSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
    this.gap = ClaySpacing.regular,
    this.maxWidth = double.infinity,
  });

  /// The widest its [children] stand (a form's fields, near their words).
  final double maxWidth;

  /// Its head.
  final String title;

  /// A line under the head.
  final String? note;

  /// What it shows.
  final List<Widget> children;

  /// The room between [children].
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return RawKeylineRegion(
      label: title,
      startAligned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: ClaySpacing.small,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.title.copyWith(color: theme.colors.ink),
              ),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: ClaySpacing.regular,
              ),
              child: Text(note!, style: theme.textTheme.secondary),
            ),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            if (maxWidth.isFinite)
              Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              )
            else
              child,
          ],
        ],
      ),
    );
  }
}

/// Parts side by side, wrapping.
class KitRow extends StatelessWidget {
  /// A row of [children], [spacing] apart.
  const KitRow({
    super.key,
    required this.children,
    this.spacing = ClaySpacing.regular,
  });

  /// The parts.
  final List<Widget> children;

  /// The room between two parts on a line.
  final double spacing;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: spacing,
    runSpacing: ClaySpacing.regular,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// A value a demo keeps, so its part answers as it will in an app.
class KitLive<T> extends StatefulWidget {
  /// [builder] over a value that starts at [initial].
  const KitLive(this.initial, this.builder, {super.key});

  /// The value it starts at.
  final T initial;

  /// The part, given the value and a way to change it.
  final Widget Function(BuildContext context, T value, ValueChanged<T> set)
  builder;

  @override
  State<KitLive<T>> createState() => _KitLiveState<T>();
}

class _KitLiveState<T> extends State<KitLive<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, (next) => setState(() => _value = next));
}

/// [lead] and [end] beside [words] when every line of [words] fits whole
/// between them; where it does not (large text on a phone), [lead] and [end]
/// share a line above the words, at its start and its end, and the words
/// take the whole width.
class KitBeside extends MultiChildRenderObjectWidget {
  /// [words] with [lead] [gap] before them and [end] [endGap] after them.
  KitBeside({
    super.key,
    required Widget lead,
    required Widget words,
    Widget? end,
    this.gap = ClaySpacing.regular,
    this.endGap = ClaySpacing.regular,
  }) : _hasEnd = end != null,
       super(children: [lead, words, ?end]);

  /// The room between [lead] and the words beside them.
  final double gap;

  /// The room between the words and [end] beside them.
  final double endGap;

  final bool _hasEnd;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderKitBeside(_hasEnd, gap, endGap, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderKitBeside)
      ..hasEnd = _hasEnd
      ..gap = gap
      ..endGap = endGap
      ..textDirection = Directionality.of(context);
  }
}

class _KitBesideData extends ContainerBoxParentData<RenderBox> {}

class _RenderKitBeside extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _KitBesideData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _KitBesideData> {
  _RenderKitBeside(this._hasEnd, this._gap, this._endGap, this._textDirection);

  // Between the line above and the words under it.
  static const double _runGap = ClaySpacing.medium;

  bool _hasEnd;
  set hasEnd(bool value) {
    if (value == _hasEnd) return;
    _hasEnd = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _endGap;
  set endGap(double value) {
    if (value == _endGap) return;
    _endGap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _KitBesideData) {
      child.parentData = _KitBesideData();
    }
  }

  RenderBox get _lead => firstChild!;
  RenderBox get _words => childAfter(firstChild!)!;
  RenderBox? get _end => _hasEnd ? lastChild : null;
  List<RenderBox> get _children => [_lead, _words, ?_end];

  // Lays the three out (or measures them dry) and says where each goes.
  (Size, List<Offset>) _arrange(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints constraints) size,
  ) {
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final lead = size(_lead, loose);
    final end = _end == null ? Size.zero : size(_end!, loose);
    final sides = lead.width + _gap + (_end == null ? 0 : end.width + _endGap);
    final wordsWidth = _words.getMaxIntrinsicWidth(double.infinity);
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : sides + wordsWidth;
    final rtl = _textDirection == TextDirection.rtl;
    double x(double start, double w) => rtl ? width - start - w : start;
    if (sides + wordsWidth <= width) {
      final words = size(
        _words,
        BoxConstraints.tightFor(width: math.max(0, width - sides)),
      );
      final height = math.max(words.height, math.max(lead.height, end.height));
      return (
        constraints.constrain(Size(width, height)),
        [
          Offset(x(0, lead.width), (height - lead.height) / 2),
          Offset(
            x(lead.width + _gap, words.width),
            (height - words.height) / 2,
          ),
          if (_end != null)
            Offset(x(width - end.width, end.width), (height - end.height) / 2),
        ],
      );
    }
    final words = size(_words, BoxConstraints.tightFor(width: width));
    final line = math.max(lead.height, end.height);
    return (
      constraints.constrain(Size(width, line + _runGap + words.height)),
      [
        Offset(x(0, lead.width), (line - lead.height) / 2),
        Offset(x(0, words.width), line + _runGap),
        if (_end != null)
          Offset(x(width - end.width, end.width), (line - end.height) / 2),
      ],
    );
  }

  @override
  void performLayout() {
    final (box, offsets) = _arrange(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    size = box;
    for (final (i, child) in _children.indexed) {
      (child.parentData! as _KitBesideData).offset = offsets[i];
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints, (child, c) => child.getDryLayout(c)).$1;

  @override
  double computeMinIntrinsicWidth(double height) =>
      [for (final child in _children) child.getMinIntrinsicWidth(height)]
          .reduce(math.max);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _children.fold(
        0.0,
        (sum, child) => sum + child.getMaxIntrinsicWidth(height),
      ) +
      _gap +
      (_end == null ? 0 : _endGap);

  @override
  double computeMinIntrinsicHeight(double width) => _arrange(
    BoxConstraints(maxWidth: width),
    (child, c) => child.getDryLayout(c),
  ).$1.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
