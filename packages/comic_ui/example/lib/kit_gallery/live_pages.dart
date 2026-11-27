/// The live example's pages, under plain names in the order a person looks for them, each built from the gallery's
/// own specimens: every component the package exports is live on at least one of them, and every one responds.
library;

import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'design_review.dart';
import 'gate_screens.dart';
import 'kit.dart';
import 'demos/charts.dart';
import 'demos/chrome.dart';
import 'demos/complete.dart';
import 'demos/controls.dart';
import 'demos/cover.dart';
import 'demos/foundations.dart';
import 'demos/frames.dart';
import 'demos/inventory.dart';
import 'demos/panels.dart';
import 'demos/people.dart';
import 'demos/print.dart';
import 'demos/raised.dart';
import 'demos/rows.dart';
import 'demos/speech.dart';

/// One page of the live example: its address, its name in the navigation, its glyph, a line on what it holds, and
/// its labelled sections.
typedef LivePage = ({
  String id,
  String title,
  IconData icon,
  String summary,
  List<Widget> Function() sections,
});

/// Lets a page's own links move the example to another page.
class LiveNavigation extends InheritedWidget {
  /// Hands [go] to the pages under [child].
  const LiveNavigation({super.key, required this.go, required super.child});

  /// Shows the page with this id.
  final ValueChanged<String> go;

  /// The nearest navigation, if the page is inside the example.
  static LiveNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiveNavigation>();

  @override
  bool updateShouldNotify(LiveNavigation oldWidget) => go != oldWidget.go;
}

/// A live page's body: its sections in one column on a phone, in two at a desktop's width.
Widget livePageBody(LivePage page) => ComicScaffold(
  key: ValueKey('live/${page.id}'),
  body: _LiveSheet(sections: page.sections()),
);

class _LiveSheet extends StatelessWidget {
  const _LiveSheet({required this.sections});
  final List<Widget> sections;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (sections case [final _Across across]) return across;
      if (box.maxWidth < 960 || sections.length < 2) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ComicColumn(gap: 32, children: sections),
          ),
        );
      }
      // Two columns, filled in reading order: the first half on the left.
      final half = (sections.length + 1) ~/ 2;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ComicColumn(gap: 32, children: sections.sublist(0, half)),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: ComicColumn(gap: 32, children: sections.sublist(half)),
          ),
        ],
      );
    },
  );
}

/// The example's pages, in order.
final List<LivePage> livePages = [
  (
    id: 'overview',
    title: 'Overview',
    icon: LucideIcons.layoutDashboard,
    summary: 'What Comic is and where each part lives.',
    sections: _overview,
  ),
  (
    id: 'buttons',
    title: 'Buttons',
    icon: LucideIcons.mousePointerClick,
    summary: 'The act, the outlined button, quiet, danger, links and icons.',
    sections: () => [
      kitSection('The act, one a screen', children: [kitSpecimenActButton()]),
      kitSection('Any other action', children: [kitSpecimenLineButton()]),
      kitSection('Quiet', children: [kitSpecimenQuiet()]),
      kitSection('Danger', children: [kitSpecimenDanger()]),
      kitSection('A link', children: [kitSpecimenLink()]),
      // The plain button is "Any other action": two demos would promise a difference that isn't there.
      kitSection('An icon alone', children: [kitSpecimenIconButton()]),
      kitSection('Send', children: [kitSpecimenSendButton()]),
      kitSection('Sizes', children: [_sizes()]),
      kitSection('Busy and unavailable', children: [_busy()]),
      kitSection('A group of buttons', children: [kitSpecimenButtonGroup()]),
      kitSection('A toggle group', children: [kitSpecimenToggleGroup()]),
      kitSection('A split button', children: [kitSpecimenSplitButton()]),
      kitSection('Keys', children: [kitSpecimenKbd()]),
      kitSection('A tile of your own', children: [kitPressTile()]),
    ],
  ),
  (
    id: 'text-fields',
    title: 'Text fields',
    icon: LucideIcons.textCursorInput,
    summary: 'Fields with labels, help and errors, search, codes and notes.',
    sections: () => [
      kitSection('A field', children: [kitSpecimenField()]),
      kitSection('Label, help and error', children: [_fieldStates()]),
      kitSection('A password', children: [kitSpecimenPasswordField()]),
      kitSection('With add-ons', children: [kitSpecimenInputGroup()]),
      kitSection('Search', children: [kitSpecimenSearch()]),
      kitSection('A code', children: [kitSpecimenCode()]),
      kitSection('A longer answer', children: [kitSpecimenTextArea()]),
      kitSection('The plain input', children: [kitSpecimenInput()]),
    ],
  ),
  (
    id: 'selection',
    title: 'Selection',
    icon: LucideIcons.squareCheck,
    summary: 'Ticks, radios, switches, segments, chips, sliders and counts.',
    sections: () => [
      kitSection('A tick', children: [kitSpecimenCheck()]),
      kitSection('A tick on a row', children: [kitSpecimenCheckRow()]),
      kitSection('One of a few', children: [kitSpecimenRadio()]),
      kitSection('Choices', children: [kitSpecimenChoices()]),
      kitSection('A box of your own', children: [kitSpecimenChoiceBox()]),
      kitSection('On or off', children: [kitSpecimenSwitch()]),
      kitSection('A switch on a row', children: [kitSpecimenSwitchRow()]),
      kitSection('Segmented', children: [kitSpecimenSegmented()]),
      kitSection(
        'Chips',
        // Chips hug their words: side by side, wrapping, never stretched to the column.
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              kitSpecimenChip(),
              kitSpecimenFilter(),
              kitSpecimenRemove(),
            ],
          ),
        ],
      ),
      kitSection('A slider', children: [kitSpecimenSlider()]),
      kitSection('A range', children: [kitSpecimenRangeSlider()]),
      kitSection('A count', children: [kitSpecimenStepper()]),
      kitSection('A rating', children: [kitSpecimenRating()]),
      kitSection('Stars, read only', children: [kitSpecimenStars()]),
    ],
  ),
  (
    id: 'pickers',
    title: 'Pickers',
    icon: LucideIcons.calendarDays,
    summary: 'Select, date, range, time, autocomplete and files.',
    sections: () => [
      kitSection('Select', children: [kitSpecimenSelect()]),
      kitSection('A value to change', children: [kitSpecimenSelectField()]),
      kitSection('A date', children: [kitSpecimenDate()]),
      kitSection('A date in a form', children: [kitSpecimenDateField()]),
      kitSection('A time', children: [kitSpecimenTime()]),
      kitSection('Autocomplete', children: [kitSpecimenAutocomplete()]),
      kitSection('Several at once', children: [kitSpecimenMultiSelect()]),
      kitSection('A month', children: [kitSpecimenCalendar()]),
      kitSection('A stay', children: [kitSpecimenDateRange()]),
      kitSection('A wheel', children: [kitSpecimenWheelPicker()]),
      kitSection('Files', children: [kitSpecimenFileDrop()]),
    ],
  ),
  (
    id: 'navigation',
    title: 'Navigation',
    icon: LucideIcons.compass,
    summary: 'Bars, side nav, rail, tabs, breadcrumbs, pages and steps.',
    sections: () => [
      kitSection('The app bar', children: [kitSpecimenTopBar()]),
      kitSection('The masthead', children: [_masthead()]),
      kitSection('The app\'s frame', children: [kitSpecimenAppShell()]),
      kitSection('The bottom nav', children: [kitSpecimenTabBar()]),
      kitSection('The side nav', children: [kitSpecimenSideNav()]),
      kitSection('The rail', children: [kitSpecimenRail()]),
      kitSection('Tabs', children: [kitSpecimenTabs()]),
      kitSection('Breadcrumbs', children: [kitSpecimenBreadcrumbs()]),
      kitSection('Pagination', children: [kitSpecimenPagination()]),
      kitSection('A menu bar', children: [kitSpecimenMenuBar()]),
      kitSection('A command palette', children: [kitSpecimenCommand()]),
      kitSection('Page dots', children: [kitSpecimenDots()]),
      kitSection('Step progress', children: [kitSpecimenSteps()]),
      kitSection('The way back', children: [_back()]),
      kitSection('More of a list', children: [kitSpecimenMore()]),
      kitSection('The name', children: [kitSpecimenLogo()]),
      kitSection('A group', children: [kitSpecimenGroupChip()]),
    ],
  ),
  (
    id: 'lists',
    title: 'Lists and tables',
    icon: LucideIcons.list,
    summary: 'Rows, groups, facts, ledgers, tables, trees and reordering.',
    sections: () => [
      kitSection('A list', children: [kitSpecimenList()]),
      kitSection('Rows in a group', children: [kitSpecimenGrouped()]),
      kitSection('Rows that open', children: [kitOpenRows()]),
      kitSection('A row with an action', children: [kitSpecimenActionRow()]),
      kitSection('Facts', children: [kitSpecimenFacts(), kitSpecimenKvRow()]),
      kitSection('Times', children: [kitSpecimenTimedRow()]),
      kitSection('A form group', children: [kitSpecimenFormGroup()]),
      kitSection('Ruled', children: [kitSpecimenRuled()]),
      kitSection('A ledger', children: [kitSpecimenLedgerRow()]),
      kitSection('Amounts', children: [kitSpecimenAmountRow()]),
      kitSection('A table', children: [kitSpecimenTable()]),
      kitSection('A data table', children: [kitSpecimenDataTable()]),
      kitSection('A tree', children: [kitSpecimenTree()]),
      kitSection('Your own order', children: [kitSpecimenReorderable()]),
      kitSection('Slide for more', children: [kitSpecimenSwipeActions()]),
      kitSection('Pull to refresh', children: [kitRefresh()]),
      kitSection('A scroll area', children: [kitScrollArea()]),
      kitSection('Two panes', children: [kitResizable()]),
      kitSection('A timeline', children: [kitSpecimenTimeline()]),
      kitSection('Described', children: [kitSpecimenDescriptionList()]),
      kitSection('A divider', children: [kitSpecimenDivider()]),
      kitSection('More to read', children: [kitSpecimenDisclosure()]),
    ],
  ),
  (
    id: 'cards',
    title: 'Cards and media',
    icon: LucideIcons.image,
    summary: 'Cards, pictures, avatars, face piles, the cast and a carousel.',
    sections: () => [
      kitSection('A card', children: [kitSpecimenCard()]),
      kitSection('Picture cards', children: [kitSpecimenPictureCard()]),
      kitSection('A picture, in its fallback', children: [kitSpecimenPhoto()]),
      kitSection('Art', children: [kitSpecimenArtBand()]),
      kitSection('An avatar', children: [kitSpecimenAvatar()]),
      kitSection('A face pile', children: [kitSpecimenPile()]),
      kitSection('A person', children: [kitSpecimenPerson()]),
      kitSection('People', children: [kitSpecimenPeople()]),
      kitSection('A line-up', children: [kitSpecimenLineup()]),
      kitSection('A carousel', children: [kitSpecimenCarousel()]),
    ],
  ),
  (
    id: 'dialogs',
    title: 'Dialogs and sheets',
    icon: LucideIcons.panelTop,
    summary: 'Dialog, sheets, menu, drawer, popover, hover card and notices.',
    sections: () => [
      kitSection('Open them for real', children: [kitTryRaised()]),
      kitSection('A dialog', children: [kitSpecimenDialog()]),
      kitSection('A sheet', children: [kitSpecimenSheet()]),
      kitSection('A menu', children: [kitSpecimenMenu()]),
      kitSection('A drawer', children: [_drawer()]),
      kitSection('A tooltip', children: [kitSpecimenTooltip()]),
      kitSection('A snack bar', children: [kitSpecimenSnackBar()]),
      kitSection('A toast', children: [kitSpecimenToast()]),
      kitSection('Notices that stack', children: [kitToastStack()]),
      kitSection(
        'A side sheet',
        children: [kitOpenSideSheet(), kitSpecimenSideSheet()],
      ),
      kitSection('A popover', children: [kitPopover()]),
      kitSection('A hover card', children: [kitHoverCard()]),
      kitSection('Choices from below', children: [kitSpecimenActionSheet()]),
      kitSection('A decision on a real screen', children: [reviewDialogBody()]),
    ],
  ),
  (
    id: 'feedback',
    title: 'Feedback',
    icon: LucideIcons.bell,
    summary: 'Notices, progress, skeletons, empty, error and success.',
    sections: () => [
      kitSection('Notices', children: [kitSpecimenNotice()]),
      kitSection('Progress', children: [kitSpecimenProgress()]),
      kitSection('Waiting', children: [kitSpecimenSpinner()]),
      kitSection('A skeleton', children: [kitSpecimenSkeleton()]),
      kitSection('Loading', children: [kitSpecimenLoadingState()]),
      kitSection('Empty', children: [kitSpecimenEmpty()]),
      kitSection('An error', children: [kitSpecimenErrorState()]),
      kitSection('Done', children: [kitSpecimenSuccess()]),
      kitSection('Whatever the state', children: [kitSpecimenStatusView()]),
      kitSection('A count badge', children: [kitSpecimenBadge()]),
      kitSection('A tag', children: [kitSpecimenTag()]),
      kitSection('Tones', children: [_tones()]),
      kitSection('A meter', children: [kitSpecimenMeter()]),
    ],
  ),
  (
    id: 'charts',
    title: 'Charts',
    icon: LucideIcons.chartColumn,
    summary: 'Line, area, bar, donut and sparkline, with axes and readouts.',
    sections: () => [
      kitSection('A line', children: [kitSpecimenLineChart()]),
      kitSection('An area', children: [kitSpecimenAreaChart()]),
      kitSection('Bars', children: [kitSpecimenBarChart()]),
      kitSection('A donut', children: [kitSpecimenPie()]),
      kitSection('A sparkline', children: [kitSpecimenSparkline()]),
      kitSection('A gap in the data', children: [kitGapChart()]),
      kitSection(
        'A chart in a panel',
        children: [ComicPanel(child: kitSpecimenChart())],
      ),
      kitSection('No data yet', children: [kitEmptyChart()]),
      kitSection('On its way', children: [kitLoadingChart()]),
      kitSection('A bar', children: [kitSpecimenBar()]),
      kitSection('A tally', children: [kitSpecimenTally()]),
      kitSection('A list of bars', children: [kitSpecimenBarList()]),
      kitSection('A flow', children: [kitSpecimenFlow()]),
      kitSection('Shares', children: [kitSpecimenShares()]),
      kitSection('Units', children: [kitSpecimenUnits()]),
      kitSection('Segments', children: [kitSpecimenSegments()]),
      kitSection('Cells', children: [kitSpecimenCells()]),
    ],
  ),
  (
    id: 'type',
    title: 'Type and colour',
    icon: LucideIcons.palette,
    summary: 'The type roles, the colours, letters and the page frame.',
    sections: () => [
      kitSection('Type', children: [const KitTypeScale()]),
      kitSection('The colours', children: [const KitSwatches()]),
      kitSection('Lettering', children: [kitSpecimenLetters()]),
      kitSection('A label', children: [kitSpecimenLabel()]),
      kitSection('A section head', children: [kitSpecimenSectionHead()]),
      kitSection('The page frame', children: [_frame()]),
      kitSection('Day to night', children: [_easing()]),
      kitSection('An object beside its words', children: [kitSpecimenBeside()]),
      kitSection('Lines that keep together', children: [_lines()]),
    ],
  ),
  (
    id: 'form',
    title: 'Form',
    icon: LucideIcons.fileText,
    summary: 'Account: where the shop sends things, in a captioned panel.',
    sections: () => [
      _Across(children: [gateAccount()]),
    ],
  ),
  (
    id: 'settings',
    title: 'Settings',
    icon: LucideIcons.settings,
    summary: 'Two panels of switches, and a note in a caption.',
    sections: () => [
      _Across(children: [gateSettings()]),
    ],
  ),
  (
    id: 'list',
    title: 'List',
    icon: LucideIcons.users,
    summary: 'Library: your issues as a tier of covers.',
    sections: () => [
      _Across(children: [gateLibrary()]),
    ],
  ),
  (
    id: 'checkout',
    title: 'Checkout',
    icon: LucideIcons.shoppingBag,
    summary: 'Shop: the order beside delivery and payment.',
    sections: () => [
      _Across(children: [gateShop()]),
    ],
  ),
  (
    id: 'panels',
    title: 'Panels and captions',
    icon: LucideIcons.layoutPanelLeft,
    summary:
        "Comic's own: panels in tiers, captions and panels that carry things.",
    sections: () => [
      kitSection('A panel', children: [kitSpecimenPanel()]),
      kitSection('Panels in a tier', children: [kitSpecimenTier()]),
      kitSection('A stack', children: [kitSpecimenPanelStack()]),
      kitSection('A caption', children: [kitSpecimenCaption()]),
      kitSection('A well', children: [kitSpecimenWell()]),
      kitSection("A panel's head", children: [kitSpecimenPanelHead()]),
      kitSection('Indicia', children: [kitSpecimenIndicia()]),
      kitSection('An event', children: [kitSpecimenEventPanel()]),
      kitSection('A mark', children: [kitSpecimenMarkPanel()]),
      kitSection('A step', children: [kitSpecimenStepPanel()]),
      kitSection('A voice', children: [kitSpecimenVoicePanel()]),
      kitSection('A chapter', children: [kitSpecimenChapterPanel()]),
      kitSection('A claim', children: [kitSpecimenClaim()]),
      kitSection('Figures', children: [kitSpecimenFigures()]),
    ],
  ),
  (
    id: 'balloons',
    title: 'Balloons and bursts',
    icon: LucideIcons.messageCircle,
    summary: "Comic's own: speech, thought, the burst, a pop and a stamp.",
    sections: () => [
      kitSection('A balloon', children: [kitSpecimenBalloon()]),
      kitSection('A thought', children: [kitSpecimenThought()]),
      kitSection('Something said', children: [kitSpecimenSay()]),
      kitSection('A reply', children: [kitSpecimenReply()]),
      kitSection('The burst, one a screen', children: [kitSpecimenBurst()]),
      kitSection('A pop', children: [kitSpecimenPop()]),
      kitSection('A stamp', children: [kitSpecimenStamp()]),
    ],
  ),
  (
    id: 'print',
    title: 'Print',
    icon: LucideIcons.printer,
    summary: "Comic's own: dots, action lines, lettering, sound and marks.",
    sections: () => [
      kitSection('Ben-Day dots', children: [kitSpecimenBenDay()]),
      kitSection('Action lines', children: [kitSpecimenActionLines()]),
      kitSection('Cover print', children: [kitSpecimenCoverPrint()]),
      kitSection('Lettering', children: [kitSpecimenLettering()]),
      kitSection('A sound', children: [kitSpecimenSfx()]),
      kitSection('A mark', children: [kitSpecimenMark()]),
      kitSection('A portrait', children: [kitSpecimenPortrait()]),
    ],
  ),
  (
    id: 'cover',
    title: 'Cover and splash',
    icon: LucideIcons.bookOpen,
    summary: "Comic's own: the issue's cover and a splash page.",
    sections: () => [
      kitSection('The cover', children: [kitSpecimenCover()]),
      kitSection('A splash', children: [kitSpecimenSplash()]),
    ],
  ),
];

/// The Overview, across the whole sheet: the intro at a reading width on top, every page's card in a grid under it
/// (three or two columns on a desktop, one on a phone).
List<Widget> _overview() => [
  _Across(
    children: [
      Builder(
        builder: (context) {
          final t = ComicTheme.of(context);
          return Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ComicColumn(
                gap: 12,
                children: [
                  Text('COMIC', style: t.type.section),
                  ComicBalancedText(
                    kitSay(
                      context,
                      'A comic page for Flutter: inked panels in tiers, narration captions, speech balloons and one burst a screen. Every part below is live. Open a page from the navigation, or from its card here.',
                    ),
                    style: t.type.body,
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const _OwnCorners(),
      Builder(
        builder: (context) {
          final go = LiveNavigation.maybeOf(context)?.go;
          return LayoutBuilder(
            builder: (context, box) => ComicGridOf(
              columns: box.maxWidth >= 1100
                  ? 3
                  : box.maxWidth >= 640
                  ? 2
                  : 1,
              gap: 16,
              runGap: 16,
              children: [
                for (final page in livePages.skip(1))
                  ComicCard(
                    title: kitSay(context, page.title),
                    // The summary takes the row's slack, so each card's Open stands on its foot, on one line across
                    // the row, even where a summary wraps.
                    children: [
                      ComicGrow(child: Text(kitSay(context, page.summary))),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ComicButton.text(
                          KitWords.arabicOf(context)
                              ? 'افتح ${kitSay(context, page.title)}'
                              : 'Open ${page.title.toLowerCase()}',
                          style: const ComicStyle(
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          onPressed: go == null ? null : () => go(page.id),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    ],
  ),
];

/// A part's own corners: on a rounder scheme than Comic's square one, a card's style rounds two opposite corners and
/// a button's its top start only, the other corners square.
class _OwnCorners extends StatelessWidget {
  const _OwnCorners();

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final rounder = t.copyWith(
      shapeScheme: t.shapeScheme.copyWith(
        corners: t.shapeScheme.corners.copyWith(
          extraSmall: 6,
          small: 6,
          medium: 10,
          large: 14,
        ),
      ),
    );
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ComicTheme(
          data: rounder,
          child: ComicCard(
            title: kitSay(context, "A part's own corners"),
            style: const ComicStyle(
              corners: WidgetStatePropertyAll(
                RawCorners(
                  topStart: RawCorner.large,
                  topEnd: RawCorner.none,
                  bottomStart: RawCorner.none,
                  bottomEnd: RawCorner.large,
                ),
              ),
            ),
            children: [
              Text(
                kitSay(
                  context,
                  "A style's corners shape one part on its own: this card is rounded at two opposite corners, its button at the top start only.",
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ComicButton.filled(
                  kitSay(context, 'Send'),
                  style: const ComicStyle(
                    corners: WidgetStatePropertyAll(
                      RawCorners.only(topStart: RawCorner.medium),
                    ),
                  ),
                  onPressed: () =>
                      kitFeedback(context, kitSay(context, 'Sent.')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One section that runs across the whole sheet rather than taking a column of two.
class _Across extends StatelessWidget {
  const _Across({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      ComicColumn(gap: 32, children: children);
}

// One under another: three sizes side by side would be a row of three heights (ui_core's DesignRowCheck).
// One under another: large is a step taller than small and medium, so side by side their tops and bottoms would miss
// each other (the shared row check).
Widget _sizes() => Builder(
  builder: (context) => Column(
    spacing: 12,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final size in ComicButtonSize.values)
        ComicButton(
          kitSay(context, size.name[0].toUpperCase() + size.name.substring(1)),
          size: size,
          onPressed: () => kitFeedback(context, 'The ${size.name} one.'),
        ),
    ],
  ),
);

Widget _busy() => Builder(
  builder: (context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      ComicButton.filled(
        kitSay(context, 'Saving'),
        busy: true,
        onPressed: () {},
      ),
      ComicButton.filled(kitSay(context, 'Unavailable')),
      ComicButton(kitSay(context, 'Unavailable')),
      ComicButton.text(kitSay(context, 'Unavailable')),
    ],
  ),
);

Widget _fieldStates() => Builder(
  builder: (context) => ComicColumn(
    gap: 16,
    children: [
      ComicTextField(
        labelText: kitSay(context, 'Email address'),
        hintText: 'you@example.com',
        helperText: kitSay(context, 'We only write about your orders.'),
        keyboardType: TextInputType.emailAddress,
      ),
      ComicTextField(
        labelText: kitSay(context, 'Full name'),
        initialValue: kitSay(context, 'Alex'),
        errorText: kitSay(context, 'Write your whole name, as on your card.'),
      ),
      ComicTextField(
        labelText: kitSay(context, 'Member number'),
        initialValue: '0042 1187',
        // A number in groups reads left to right in a right-to-left app too.
        textDirection: TextDirection.ltr,
        enabled: false,
      ),
      ComicTextField(
        labelText: kitSay(context, 'Amount'),
        prefixText: '€',
        initialValue: '24',
        keyboardType: TextInputType.number,
      ),
    ],
  ),
);

Widget _back() => Builder(
  builder: (context) => Builder(
    builder: (context) => Row(
      children: [
        ComicBackButton(
          onPressed: () =>
              kitFeedback(context, kitSay(context, 'Back a page.')),
        ),
        const SizedBox(width: 12),
        ComicBackButton(
          close: true,
          onPressed: () => kitFeedback(context, kitSay(context, 'Closed.')),
        ),
      ],
    ),
  ),
);

Widget _drawer() => Builder(
  builder: (context) => kitState(
    0,
    (context, value, change) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: ComicButton(
        kitSay(context, 'Open the drawer'),
        icon: LucideIcons.menu,
        onPressed: () async {
          final chosen = await showComicNavigationDrawer<int>(
            context,
            builder: (context) => ComicNavigationDrawer(
              header: ComicLogo(kitSay(context, 'Huzzah!')),
              destinations: kitTabs(context),
              selectedIndex: value,
              onDestinationSelected: (i) => Navigator.of(context).pop(i),
            ),
          );
          if (chosen != null && context.mounted) {
            change(chosen);
            kitFeedback(context, '${kitTabs(context)[chosen].label} chosen.');
          }
        },
      ),
    ),
  ),
);

Widget _tones() => Wrap(
  spacing: 16,
  runSpacing: 12,
  children: [for (final tone in ComicTone.values) ComicToneMark(tone)],
);

/// The page frame: tiers of panels on twelve columns, and a head between them, one gutter apart.
Widget _frame() => Builder(
  builder: (context) => ComicSections(
    children: [
      ComicRow(
        spans: [7, 5],
        children: [
          ComicPanel(
            caption: kitSay(context, 'Seven'),
            child: ComicKvRow(
              kitSay(context, 'Spans'),
              kitSay(context, '7 of 12'),
              isFirst: true,
            ),
          ),
          ComicPanel(
            caption: kitSay(context, 'Five'),
            child: ComicKvRow(
              kitSay(context, 'Spans'),
              kitSay(context, '5 of 12'),
              isFirst: true,
            ),
          ),
        ],
      ),
      ComicSectionHeader(kitSay(context, 'Coming up')),
      // A third of the gallery's half-width column is about 110 wide: words
      // that wrap between themselves, not a label beside a value.
      ComicRow(
        spans: [4, 4, 4],
        children: [
          ComicPanel(
            caption: kitSay(context, 'Four'),
            child: Text(kitSay(context, 'Four of twelve')),
          ),
          ComicPanel(
            caption: kitSay(context, 'Four'),
            child: Text(kitSay(context, 'Four of twelve')),
          ),
          ComicPanel(
            caption: kitSay(context, 'Four'),
            child: Text(kitSay(context, 'Four of twelve')),
          ),
        ],
      ),
    ],
  ),
);

/// A desktop's app bar under the app's chrome scope: the name, then the app's places, the current one lit; each moves.
Widget _masthead() => kitState<int>(
  1,
  (context, active, change) => ComicChromeScope(
    brand: ComicBrand(name: kitSay(context, 'Huzzah!')),
    nav: [
      for (final (i, item) in kitTabs(context).indexed)
        ComicNavItem(
          label: item.label,
          short: item.short,
          icon: item.icon,
          onPressed: () => change(i),
        ),
    ],
    active: active,
    child: ComicAppBar(title: kitTabs(context)[active].label),
  ),
);

/// A theme that eases: the same panel moves between day and night over the motion's state duration.
Widget _easing() => kitState<bool>(
  false,
  (context, night, change) => ComicColumn(
    gap: 12,
    children: [
      ComicSwitch(
        value: night,
        semanticLabel: kitSay(context, 'Night'),
        onChanged: change,
      ),
      _eased(night, ComicTheme.of(context).colors.nightLine),
    ],
  ),
);

/// The eased page in small. Its frame is drawn in the line of the page it stands on (black by day, cream at night), so
/// it closes on either ground; the sample's own line would vanish into a night gutter.
Widget _eased(bool night, Color pageLine) => Builder(
  builder: (context) => AnimatedComicTheme(
    data: kitTheme(night ? Brightness.dark : Brightness.light),
    child: Builder(
      builder: (context) {
        final t = ComicTheme.of(context);
        // The eased ground is a page in small: by night under a day page and by day under a night one it reads as a
        // page, not as a slab of the other paper left on this one.
        return DecoratedBox(
          decoration: ShapeDecoration(
            color: t.colors.background,
            shape: t.shapes.medium.copyWith(
              side: BorderSide(color: pageLine, width: t.rim(2.5)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ComicPanel(
              caption: night
                  ? kitSay(context, 'Night')
                  : kitSay(context, 'Day'),
              child: Text(
                kitSay(
                  context,
                  'The ground, the panel and the words turn to the other issue together.',
                ),
                style: t.type.body,
              ),
            ),
          ),
        );
      },
    ),
  ),
);

Widget _lines() => Builder(
  builder: (context) {
    final t = ComicTheme.of(context);
    return ComicColumn(
      gap: 12,
      children: [
        ComicSplit(
          start: Text(kitSay(context, 'Your issue'), style: t.type.title),
          end: Text(kitSay(context, 'Out on Wednesday'), style: t.type.small),
        ),
        ComicAutoRow(
          children: [
            ComicTag(kitSay(context, 'Weekly')),
            ComicTag(kitSay(context, 'Twelve pages')),
            ComicTag(kitSay(context, 'In colour')),
          ],
        ),
        // The words stand on a dotted panel, as the scope says they do.
        ComicPanel(
          ground: ComicPanelFill.dots,
          shrinkWrap: true,
          child: ComicDotsScope(
            child: ComicLetteringScope(
              t.colors.text,
              child: Text(
                kitSay(context, 'WORDS ON THE TINT'),
                style: t.type.item,
              ),
            ),
          ),
        ),
      ],
    );
  },
);
