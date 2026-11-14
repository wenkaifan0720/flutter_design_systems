// The frame's laws: one window is active on any page, whatever is asked of it; the columns of a desktop end on one line; an
// alert laid over a neighbour can't hide a word on other data. A model gets these for nothing and can't get them wrong.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

Widget _window(String title, {int lines = 1, List<String> status = const []}) =>
    RetroDesktopWindow(
      title: title,
      status: status,
      child: RetroDesktopColumn(
        gap: 6,
        children: [for (var i = 0; i < lines; i++) Text('$title line $i')],
      ),
    );

Future<void> _pump(WidgetTester tester, double width, Widget page) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    retroDesktopApp(
      RetroDesktopChromeScope(
        brand: 'Your name',
        nav: const [],
        active: 0,
        child: page,
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

/// The titles of the windows drawn active, by what each one's own title bar was told.
List<String> _activeTitles(WidgetTester tester) => [
  for (final e in find.byType(RetroDesktopWindow).evaluate())
    if (_barOf(e)) (e.widget as RetroDesktopWindow).title,
];

bool _barOf(Element window) {
  bool? active;
  void walk(Element e) {
    if (active != null) return;
    if (e.widget.runtimeType.toString() == '_TitleBar') {
      active = (e.widget as dynamic).active as bool;
      return;
    }
    e.visitChildren(walk);
  }

  window.visitChildren(walk);
  return active!;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  group('one window is active', () {
    test('a window has no way to say it is', () {
      final source = File('lib/src/retro_desktop/frames.dart')
          .readAsStringSync();
      final at = source.indexOf('class RetroDesktopWindow extends');
      final ctor = source.substring(at, source.indexOf('});', at));
      expect(ctor.contains('active'), isFalse);
    });

    for (final width in const [390.0, 1440.0]) {
      testWidgets('the one it names @$width', (tester) async {
        await _pump(
          tester,
          width,
          RetroDesktopDesktop(
            active: 'B',
            tiles: [
              RetroDesktopWindowColumn(span: 6, windows: [_window('A')]),
              RetroDesktopWindowColumn(
                span: 6,
                windows: [_window('B'), _window('C')],
              ),
            ],
          ),
        );
        expect(_activeTitles(tester), ['B']);
      });

      testWidgets('a title nothing has: the first @$width', (tester) async {
        await _pump(
          tester,
          width,
          RetroDesktopDesktop(
            active: 'Nobody',
            tiles: [
              RetroDesktopWindowColumn(span: 6, windows: [_window('A')]),
              RetroDesktopWindowColumn(span: 6, windows: [_window('B')]),
            ],
          ),
        );
        expect(_activeTitles(tester), ['A']);
      });

      testWidgets('no title at all: the first @$width', (tester) async {
        await _pump(
          tester,
          width,
          RetroDesktopDesktop(
            tiles: [
              RetroDesktopWindowColumn(
                span: 12,
                windows: [_window('A'), _window('B')],
              ),
            ],
          ),
        );
        expect(_activeTitles(tester), ['A']);
      });

      testWidgets('an alert first: still the first window @$width', (
        tester,
      ) async {
        await _pump(
          tester,
          width,
          RetroDesktopDesktop(
            tiles: [
              RetroDesktopWindowColumn(
                span: 12,
                windows: [
                  const RetroDesktopAlert(title: 'Careful'),
                  _window('A'),
                ],
              ),
            ],
          ),
        );
        expect(_activeTitles(tester), ['A']);
      });

      testWidgets('a window inside a window stays inactive @$width', (
        tester,
      ) async {
        await _pump(
          tester,
          width,
          RetroDesktopDesktop(
            active: 'Outer',
            tiles: [
              RetroDesktopWindowColumn(
                span: 12,
                windows: [
                  RetroDesktopWindow(title: 'Outer', child: _window('Inner')),
                ],
              ),
            ],
          ),
        );
        expect(_activeTitles(tester), ['Outer']);
      });

      testWidgets('a plain page gets one window, named by its bar @$width', (
        tester,
      ) async {
        await _pump(
          tester,
          width,
          const RetroDesktopScaffold(
            topBar: RetroDesktopAppBar(title: 'A page'),
            body: Text('Words'),
          ),
        );
        expect(_activeTitles(tester), ['A page']);
      });

      testWidgets('two desktops can\'t make two heroes by nesting @$width', (
        tester,
      ) async {
        await _pump(
          tester,
          width,
          RetroDesktopDesktop(
            active: 'Outer',
            tiles: [
              RetroDesktopWindowColumn(
                span: 12,
                windows: [
                  RetroDesktopWindow(
                    title: 'Outer',
                    child: RetroDesktopDesktop(
                      active: 'Inner',
                      tiles: [
                        RetroDesktopWindowColumn(
                          span: 12,
                          windows: [_window('Inner')],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        expect(_activeTitles(tester), ['Outer']);
      });
    }

    testWidgets('a phone draws the active star compact unless whole', (
      tester,
    ) async {
      Widget page(bool whole) => RetroDesktopDesktop(
        whole: whole,
        tiles: const [
          RetroDesktopWindowColumn(
            span: 12,
            windows: [
              RetroDesktopWindow(title: 'A', child: RetroDesktopBigFigure('8')),
            ],
          ),
        ],
      );
      double size() => tester.widget<Text>(find.text('8')).style!.fontSize!;
      await _pump(tester, 390, page(false));
      expect(size(), 64);
      await _pump(tester, 390, page(true));
      expect(size(), 128);
      await _pump(tester, 1440, page(false));
      expect(size(), 170);
    });
  });

  group('tiling', () {
    Rect rect(WidgetTester t, String title) => t.getRect(
      find.byWidgetPredicate(
        (w) => w is RetroDesktopWindow && w.title == title,
      ),
    );

    testWidgets('columns of any length end on one line', (tester) async {
      await _pump(
        tester,
        1440,
        RetroDesktopDesktop(
          tiles: [
            RetroDesktopWindowColumn(
              span: 3,
              windows: [_window('A', lines: 3)],
            ),
            RetroDesktopWindowColumn(
              span: 5,
              windows: [_window('B', lines: 40), _window('C', lines: 2)],
            ),
            RetroDesktopWindowColumn(
              span: 4,
              windows: [_window('D', lines: 8), _window('E', lines: 12)],
            ),
          ],
        ),
      );
      final a = rect(tester, 'A').bottom;
      expect(rect(tester, 'C').bottom, a);
      expect(rect(tester, 'E').bottom, a);
    });

    testWidgets(
      'a shade keeps its height, the window over it takes the slack',
      (tester) async {
        await _pump(
          tester,
          1440,
          const Center(child: RetroDesktopWindowShade(title: 'Folded')),
        );
        final naturalHeight = tester
            .getSize(find.byType(RetroDesktopWindowShade))
            .height;
        await _pump(
          tester,
          1440,
          RetroDesktopDesktop(
            tiles: [
              RetroDesktopWindowColumn(
                span: 6,
                windows: [_window('A', lines: 40)],
              ),
              RetroDesktopWindowColumn(
                span: 6,
                windows: [
                  _window('B'),
                  const RetroDesktopWindowShade(title: 'Folded'),
                ],
              ),
            ],
          ),
        );
        final shade = tester.getRect(find.byType(RetroDesktopWindowShade));
        expect(shade.height, naturalHeight);
        expect(shade.bottom, rect(tester, 'A').bottom);
      },
    );

    testWidgets('a row under a window shares its column and its line', (
      tester,
    ) async {
      await _pump(
        tester,
        1440,
        RetroDesktopDesktop(
          tiles: [
            RetroDesktopWindowColumn(
              span: 3,
              windows: [_window('A', lines: 40)],
            ),
            RetroDesktopWindowColumn(
              span: 9,
              windows: [_window('B')],
              under: [
                RetroDesktopWindowColumn(
                  span: 5,
                  windows: [_window('C', lines: 2)],
                ),
                RetroDesktopWindowColumn(
                  span: 4,
                  windows: [_window('D', lines: 9)],
                ),
              ],
            ),
          ],
        ),
      );
      final a = rect(tester, 'A').bottom;
      expect(rect(tester, 'C').bottom, a);
      expect(rect(tester, 'D').bottom, a);
      expect(rect(tester, 'C').left, rect(tester, 'B').left);
      expect(rect(tester, 'D').right, rect(tester, 'B').right);
    });
  });

  group('an overlay hides nothing', () {
    List<String> hidden(WidgetTester tester) {
      final alert = tester.getRect(find.byType(RetroDesktopAlert));
      final out = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final inAlert =
            e.findAncestorWidgetOfExactType<RetroDesktopAlert>() != null;
        if (inAlert) continue;
        final r = e.renderObject! as RenderParagraph;
        final o = r.localToGlobal(Offset.zero);
        final plain = (e.widget as RichText).text.toPlainText();
        if (plain.isEmpty) continue;
        final boxes = r.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: plain.length),
        );
        for (final b in boxes) {
          final at = b.toRect().shift(o);
          if (at.overlaps(alert)) {
            out.add('"$plain" at $at under $alert');
            break;
          }
        }
      }
      return out;
    }

    const alert = RetroDesktopAlert(
      title: 'A warning',
      body: 'Something to read',
      actions: [RetroDesktopChip('Later')],
    );

    Widget beside(String title, {List<String> status = const []}) =>
        RetroDesktopDesktop(
          active: title,
          tiles: [
            RetroDesktopWindowColumn(
              span: 7,
              windows: [_window(title, lines: 30, status: status)],
            ),
            RetroDesktopWindowColumn(
              span: 5,
              windows: [alert, _window('Next', lines: 12)],
            ),
          ],
        );

    Widget over(String title, List<String> status) => RetroDesktopDesktop(
      active: title,
      tiles: [
        RetroDesktopWindowColumn(
          span: 3,
          windows: [_window('Side', lines: 30)],
        ),
        RetroDesktopWindowColumn(
          span: 9,
          windows: [_window(title, lines: 3, status: status)],
          under: [
            RetroDesktopWindowColumn(
              span: 5,
              windows: [_window('Low', lines: 8)],
            ),
            RetroDesktopWindowColumn(
              span: 4,
              windows: [alert, _window('Other', lines: 4)],
            ),
          ],
        ),
      ],
    );

    testWidgets('beside a window on short words', (tester) async {
      await _pump(tester, 1440, beside('Short'));
      expect(hidden(tester), isEmpty);
    });

    testWidgets('beside a window whose words run under it', (tester) async {
      await _pump(
        tester,
        1440,
        RetroDesktopDesktop(
          active: 'Long',
          tiles: [
            const RetroDesktopWindowColumn(
              span: 7,
              windows: [
                RetroDesktopWindow(
                  title: 'Long',
                  child: Text('$longLine $longLine $longLine'),
                ),
              ],
            ),
            RetroDesktopWindowColumn(
              span: 5,
              windows: [alert, _window('Next', lines: 12)],
            ),
          ],
        ),
      );
      expect(hidden(tester), isEmpty);
    });

    testWidgets('over a window\'s foot with a short status', (tester) async {
      await _pump(tester, 1440, over('Short', const ['One', 'Two']));
      expect(hidden(tester), isEmpty);
    });

    testWidgets('over a window\'s foot with a long status', (tester) async {
      await _pump(tester, 1440, over('Long', const [longLine, longLine]));
      expect(hidden(tester), isEmpty);
    });

    testWidgets('on a phone it stands in the stack', (tester) async {
      await _pump(tester, 390, over('Phone', const [longLine]));
      expect(hidden(tester), isEmpty);
    });
  });
}
