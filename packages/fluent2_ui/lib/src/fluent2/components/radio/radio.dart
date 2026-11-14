import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';

/// How a radio group lays out, Fluent's RadioGroup `layout`: [vertical]
/// one radio a line, [horizontal] side by side (wrapping on a narrow
/// window), [horizontalStacked] side by side with each label under its
/// circle.
enum Fluent2RadioLayout {
  /// One radio under another.
  vertical,

  /// Side by side, each label after its radio.
  horizontal,

  /// Side by side, each label under its radio.
  horizontalStacked,
}

class _RadioScope extends InheritedWidget {
  const _RadioScope({
    required this.value,
    required this.select,
    required this.stacked,
    required this.nodes,
    required this.values,
    required this.live,
    required super.child,
  });

  final Object? value;
  final void Function(Object? value)? select;
  final bool stacked;
  final List<FocusNode> nodes;
  final List<Object?> values;

  /// Whether each radio takes a choice ([Fluent2Radio.enabled]).
  final List<bool> live;

  static _RadioScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioScope>();
    assert(scope != null, 'a Fluent2Radio stands in a Fluent2RadioGroup');
    return scope!;
  }

  @override
  bool updateShouldNotify(_RadioScope old) =>
      value != old.value ||
      select != old.select ||
      stacked != old.stacked ||
      nodes != old.nodes;
}

/// One choice of a [Fluent2RadioGroup], Fluent's Radio: the 16 circle 8 in
/// from its edges, its [label] 4 after it in body1 (under it in a
/// stacked group). Unchosen, the accessible stroke with the label in the
/// third ink; chosen, the brand stroke round the brand dot (10) with the
/// label in the first. [enabled] false draws this one inert.
///
/// [style] restyles the circle over `Fluent2ThemeData.radioTheme`, in its
/// states (selected while chosen, hovered, pressed, disabled): `edge` or
/// `side` (the ring), `foreground` (the dot), `fill` (inside the ring),
/// `shape` (else a circle),
/// `minimumSize` (the ring's side) and `textStyle` (the label's).
///
/// ```dart
/// Fluent2Radio('weekly', 'Weekly digest')
/// ```
class Fluent2Radio<T> extends StatelessWidget {
  /// A radio for [value], labelled [label].
  const Fluent2Radio(
    this.value,
    this.label, {
    this.enabled = true,
    this.style,
    super.key,
  });

  /// What choosing it sets the group's value to.
  final T value;

  /// Its words.
  final String label;

  /// False draws it inert in the disabled inks.
  final bool enabled;

  /// This radio's own look, slot by slot, over the radio theme.
  final Fluent2Style? style;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final layers = [style, t.radioTheme];
    final scope = _RadioScope.of(context);
    final chosen = scope.value == value;
    final select = scope.select;
    final index = scope.values.indexOf(value);
    final tap = !enabled || select == null ? null : () => select(value);
    // An arrow moves the choice and the focus to the next live radio,
    // round the group's ends.
    void step(int by) {
      final n = scope.values.length;
      for (var i = 1; i < n; i++) {
        final next = (index + by * i) % n;
        if (!scope.live[next]) continue;
        select?.call(scope.values[next]);
        scope.nodes[next].requestFocus();
        return;
      }
    }

    // Right is forward in a left-to-right page and back in a right-to-left one.
    final ahead = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final keys = tap == null
        ? null
        : {
            LogicalKeyboardKey.arrowDown: () => step(1),
            LogicalKeyboardKey.arrowRight: () => step(ahead),
            LogicalKeyboardKey.arrowUp: () => step(-1),
            LogicalKeyboardKey.arrowLeft: () => step(-ahead),
          };
    // The press's node stands at the radio's root, its one node.
    return MergeSemantics(
      child: Fluent2HitSlop(
        child: Fluent2Pressable(
          onPressed: tap,
          radius: Fluent2Radius.medium,
          label: label,
          checked: chosen,
          inGroup: true,
          keys: keys,
          focusNode: index < 0 ? null : scope.nodes[index],
          builder: (context, states) {
            final press = states.press;
            final off = press == Fluent2Press.disabled;
            final stroke = chosen
                ? press.pick(
                    c.compoundBrandStroke,
                    c.compoundBrandStrokeHover,
                    c.compoundBrandStrokePressed,
                    fluent2Step(t, c.neutralStrokeDisabled),
                  )
                : press.pick(
                    c.neutralStrokeAccessible,
                    c.neutralStrokeAccessibleHover,
                    c.neutralStrokeAccessiblePressed,
                    fluent2Step(t, c.neutralStrokeDisabled),
                  );
            final dot = press.pick(
              c.compoundBrandForeground1,
              c.compoundBrandForeground1Hover,
              c.compoundBrandForeground1Pressed,
              c.neutralForegroundDisabled,
            );
            final ink = off
                ? c.neutralForegroundDisabled
                : chosen
                ? c.neutralForeground1
                : press.pick(
                    c.neutralForeground3,
                    c.neutralForeground2,
                    c.neutralForeground1,
                  );
            return fluent2EasedInks([stroke, dot, ink], (context, inks) {
              final [stroke, dot, ink] = inks;
              final look = Fluent2StyleOf(layers, states);
              final ring =
                  look.side ??
                  BorderSide(
                    color: look.edge ?? stroke,
                    width: Fluent2Stroke.thin,
                  );
              final outline = look.shape;
              final side = look.minimumSize?.shortestSide ?? 16.0;
              final fill = look.fill;
              final mark = look.foreground ?? dot;
              // The dot: the disc scaled to .625, in the ring's outline.
              final inner = side * .625;
              final circle = Padding(
                padding: const EdgeInsets.all(Fluent2Spacing.s),
                child: Container(
                  width: side,
                  height: side,
                  alignment: Alignment.center,
                  decoration: outline == null
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: fill,
                          border: Border.all(
                            color: ring.color,
                            width: ring.width,
                          ),
                        )
                      : ShapeDecoration(
                          color: fill,
                          shape: outline.copyWith(side: ring),
                        ),
                  child: chosen
                      ? Container(
                          width: inner,
                          height: inner,
                          decoration: outline == null
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: mark,
                                )
                              : ShapeDecoration(color: mark, shape: outline),
                        )
                      : null,
                ),
              );
              final type = t.body1.merge(look.textStyle);
              if (scope.stacked) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    circle,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Fluent2Spacing.s,
                        0,
                        Fluent2Spacing.s,
                        Fluent2Spacing.s,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: type.c(ink),
                      ),
                    ),
                  ],
                );
              }
              // The circle's ink on the keyline, its room hanging outside.
              return Fluent2HangRoom(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fluent2OnFirstLine(context, type, circle),
                    Flexible(
                      child: Padding(
                        // 4 after the circle, 8 at the end; the 20 line drawn
                        // 2 into the circle's room above and under.
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          Fluent2Spacing.xs,
                          Fluent2Spacing.sNudge,
                          Fluent2Spacing.s,
                          Fluent2Spacing.sNudge,
                        ),
                        child: Text(label, style: type.c(ink)),
                      ),
                    ),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

/// Fluent 2's RadioGroup: one choice among its [items] ([Fluent2Radio]s),
/// laid out by [layout]; a press, Space or an arrow key chooses (the
/// arrows move the choice and the focus along the group). [value] is the
/// chosen one's value; null [onChanged] draws every radio disabled. Read
/// as a group named [label] (an enclosing field's label when null).
///
/// ```dart
/// Fluent2RadioGroup<String>(label: 'Digest', value: digest, onChanged: (v) => setState(() => digest = v), options: const [Fluent2Radio('daily', 'Daily'), Fluent2Radio('weekly', 'Weekly')])
/// ```
class Fluent2RadioGroup<T> extends StatefulWidget {
  /// A group of [options], one chosen.
  const Fluent2RadioGroup({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.layout = Fluent2RadioLayout.vertical,
    super.key,
  });

  /// The radios, in order.
  final List<Fluent2Radio<T>> options;

  /// The chosen radio's value; null chooses none.
  final T? value;

  /// Called with the value of the radio chosen; null puts the group out of use.
  final ValueChanged<T>? onChanged;

  /// The group's label, shown over it and spoken; null shows none.
  final String? label;

  /// Fluent's `layout`: the radios under one another or side by side.
  final Fluent2RadioLayout layout;

  @override
  State<Fluent2RadioGroup<T>> createState() => _Fluent2RadioGroupState<T>();
}

class _Fluent2RadioGroupState<T> extends State<Fluent2RadioGroup<T>> {
  List<FocusNode> _nodes = const [];

  void _fit() {
    final n = widget.options.length;
    if (_nodes.length == n) return;
    for (final node in _nodes.skip(n)) {
      node.dispose();
    }
    _nodes = [
      for (var i = 0; i < n; i++)
        i < _nodes.length ? _nodes[i] : FocusNode(debugLabel: 'radio $i'),
    ];
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _fit();
    final change = widget.onChanged;
    final items = widget.options;
    final Widget body = switch (widget.layout) {
      Fluent2RadioLayout.vertical => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
      _ => Wrap(crossAxisAlignment: WrapCrossAlignment.start, children: items),
    };
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.label ?? Fluent2FieldScope.maybeOf(context)?.label,
      child: _RadioScope(
        value: widget.value,
        select: change == null ? null : (v) => change(v as T),
        stacked: widget.layout == Fluent2RadioLayout.horizontalStacked,
        nodes: _nodes,
        values: [for (final item in items) item.value],
        live: [for (final item in items) item.enabled],
        child: body,
      ),
    );
  }
}
