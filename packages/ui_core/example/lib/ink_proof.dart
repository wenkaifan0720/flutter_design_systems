// A print proof made with Flutter's widgets and the design kit's controls.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ui_core/ui_core.dart';

void main() => runApp(const InkProofApp());

/// A proof sheet for comparing ink coverage on two paper stocks.
class InkProofApp extends StatelessWidget {
  const InkProofApp({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xff78314a),
    debugShowCheckedModeBanner: false,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      DesignLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    onGenerateTitle: (context) => _Words.of(context).title,
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    home: const InkProofPage(),
  );
}

class _Words {
  const _Words(
    this.title,
    this.stock,
    this.smooth,
    this.textured,
    this.coverage,
    this.reset,
  );

  final String title, stock, smooth, textured, coverage, reset;

  static _Words of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const _Words(
          'تجربة الطباعة',
          'نوع الورق',
          'ناعم',
          'خشن',
          'تغطية الحبر',
          'إعادة الضبط',
        )
      : const _Words(
          'Ink proof',
          'Paper stock',
          'Smooth',
          'Textured',
          'Ink coverage',
          'Reset proof',
        );
}

class _Palette {
  const _Palette(this.paper, this.ink, this.pigment, this.rule);

  final Color paper, ink, pigment, rule;

  static _Palette of(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
      ? const _Palette(
          Color(0xff211c20),
          Color(0xfff9eee3),
          Color(0xfff2b1c8),
          Color(0xffb5a7ae),
        )
      : const _Palette(
          Color(0xfff7f0e3),
          Color(0xff292026),
          Color(0xff782846),
          Color(0xff76666c),
        );
}

/// A paper selector, graduated proof strip and reset action.
class InkProofPage extends StatefulWidget {
  const InkProofPage({super.key});

  @override
  State<InkProofPage> createState() => _InkProofPageState();
}

class _InkProofPageState extends State<InkProofPage> {
  static const _initialCoverage = 40;
  bool _textured = false;
  int _coverage = _initialCoverage;

  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    final words = _Words.of(context);
    String stockLabel(bool textured) =>
        textured ? words.textured : words.smooth;
    return ColoredBox(
      color: colors.paper,
      child: DefaultTextStyle(
        style: TextStyle(color: colors.ink, fontSize: 17, height: 1.3),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (Navigator.canPop(context))
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _Button(
                          label: DesignLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    Semantics(
                      header: true,
                      child: Text(
                        words.title,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DesignField(
                      labelText: words.stock,
                      builder: (context, parts) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ?parts.label,
                          const SizedBox(height: 8),
                          parts.control,
                        ],
                      ),
                      child: DesignToggleGroup<bool>(
                        options: const [false, true],
                        selected: {_textured},
                        semanticLabel: words.stock,
                        labelOf: stockLabel,
                        onSelectionChanged: (next) =>
                            setState(() => _textured = next.single),
                        layoutBuilder: (_, items) =>
                            Wrap(spacing: 8, runSpacing: 4, children: items),
                        itemBuilder: (context, stock, states) => _ButtonFace(
                          label: stockLabel(stock),
                          states: states,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ExcludeSemantics(child: Text(words.coverage)),
                    const SizedBox(height: 8),
                    InkCoverage(
                      value: _coverage,
                      textured: _textured,
                      label: words.coverage,
                      onChanged: (value) => setState(() => _coverage = value),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _Button(
                        label: words.reset,
                        onPressed: _coverage == _initialCoverage && !_textured
                            ? null
                            : () => setState(() {
                                _coverage = _initialCoverage;
                                _textured = false;
                              }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DesignPressable(
    onPressed: onPressed,
    semanticLabel: label,
    excludeSemantics: true,
    minimumSize: const Size(48, 48),
    builder: (context, states, _) => _ButtonFace(label: label, states: states),
  );
}

class _ButtonFace extends StatelessWidget {
  const _ButtonFace({required this.label, required this.states});

  final String label;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    final solid =
        states.contains(WidgetState.selected) ||
        states.contains(WidgetState.pressed);
    final focused = states.contains(WidgetState.focused);
    final foreground = solid
        ? colors.paper
        : states.contains(WidgetState.disabled)
        ? colors.rule
        : colors.ink;
    return Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: solid ? colors.ink : colors.paper,
        border: Border.all(color: colors.rule),
      ),
      foregroundDecoration: focused
          ? BoxDecoration(
              border: Border.all(
                color: solid ? colors.paper : colors.pigment,
                width: 3,
              ),
            )
          : null,
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            decoration: focused || states.contains(WidgetState.hovered)
                ? TextDecoration.underline
                : null,
          ),
        ),
      ),
    );
  }
}

/// A wheel of eleven printed tints. The column owns dragging, arrow keys,
/// accessibility adjustments and the spring that settles on a tint.
class InkCoverage extends StatelessWidget {
  const InkCoverage({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.textured = false,
  }) : assert(value >= 0 && value <= 100 && value % 10 == 0);

  /// The selected percentage, from 0 to 100 in steps of 10.
  final int value;

  /// Called with the new percentage. A null callback disables the wheel.
  final ValueChanged<int>? onChanged;

  /// The accessible name of the wheel.
  final String label;

  /// Whether to draw the coarser paper screen.
  final bool textured;

  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    final words = DesignLocalizations.of(context);
    final extent = math.max(
      48.0,
      MediaQuery.textScalerOf(context).scale(24) + 16,
    );
    return DesignWheelPicker(
      selection: [value ~/ 10],
      onChanged: onChanged == null
          ? null
          : (selection) => onChanged!(selection.single * 10),
      columns: (_) => [
        DesignWheelColumn(
          semanticLabel: label,
          itemCount: 11,
          itemLabel: (index) => words.formatPercent(index / 10),
        ),
      ],
      itemExtent: extent,
      visibleItemCount: 3,
      squeeze: 1,
      diameterRatio: 12,
      columnBuilder: (context, column, wheel) => Stack(
        alignment: Alignment.center,
        children: [
          wheel,
          IgnorePointer(
            child: Container(
              height: column.itemExtent,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: column.states.contains(WidgetState.focused)
                        ? colors.pigment
                        : colors.ink,
                    width: column.states.contains(WidgetState.focused) ? 3 : 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      itemBuilder: (context, row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: _Halftone(
                    coverage: row.index / 10,
                    textured: textured,
                    paper: colors.paper,
                    ink: onChanged == null ? colors.rule : colors.pigment,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              row.label,
              style: TextStyle(
                color: onChanged == null ? colors.rule : colors.ink,
                fontWeight: row.selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halftone extends CustomPainter {
  const _Halftone({
    required this.coverage,
    required this.textured,
    required this.paper,
    required this.ink,
  });

  final double coverage;
  final bool textured;
  final Color paper, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    final reversed = coverage > .5;
    final paint = Paint()..color = reversed ? ink : paper;
    canvas.drawRect(area, paint);
    final pitch = textured ? 10.0 : 6.0;
    final fraction = reversed ? 1 - coverage : coverage;
    if (fraction == 0) return;
    final radius = pitch * math.sqrt(fraction / math.pi);
    paint.color = reversed ? paper : ink;
    canvas.save();
    canvas.clipRect(area);
    for (double y = pitch / 2; y < size.height + radius; y += pitch) {
      for (double x = pitch / 2; x < size.width + radius; x += pitch) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Halftone old) =>
      coverage != old.coverage ||
      textured != old.textured ||
      ink != old.ink ||
      paper != old.paper;
}
