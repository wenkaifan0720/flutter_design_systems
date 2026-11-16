// Every doc example in civic_ui's lib, compiled and run (ui_core's template,
// doc_examples.dart beside it). Each fenced dart block and `Example:` line is
// written out below as the body of an entry, so an example that stops
// compiling fails analysis; the first test fails when lib has an example
// this file lacks; the rest build each widget example (push each route, run
// each call) in a bare app on CivicHost.
//
// An example names what its caller has (an index and its setState, a
// controller, a callback): _Caller holds them, as a page's state would, and
// what it makes is disposed once its tree is gone. Routes' examples stand a
// navigator or an app of their own, so routes.dart is left out.
import 'dart:io';

import 'package:civic_ui/civic_parts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'doc_examples.dart';

/// civic_parts.dart's example: what an app's own copy of a part imports
/// (this file imports the same library).
// Indented, so the exporter's import pass leaves the lines alone (an import
// at a line's start is taken for one of this file's own).
const _partsImports = '''
  // lib/ui/my_card.dart, copied from package:civic_ui/src/civic/... and renamed.
  import 'package:flutter/widgets.dart';
  import 'package:civic_ui/civic_parts.dart';
''';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

/// An app's router, as `routerConfig` takes it and `router.go` calls it.
class _Router extends RouterConfig<Object> {
  _Router() : super(routerDelegate: _Pages());

  void go(String location) {}
}

/// A router delegate showing one page, with nothing to listen to.
class _Pages extends RouterDelegate<Object> {
  @override
  Widget build(BuildContext context) => const PermitPage();

  @override
  Future<bool> popRoute() async => false;

  @override
  Future<void> setNewRoutePath(Object configuration) async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// A page of the caller's app.
class PermitPage extends StatelessWidget {
  /// The page.
  const PermitPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Your permit');
}

/// The caller's own question page.
class ApplyPage extends StatelessWidget {
  /// The page.
  const ApplyPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Apply for a permit');
}

/// The caller's app.
class MyApp extends StatelessWidget {
  /// The app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const ApplyPage();
}

/// A permit, as the caller's data holds it.
class Permit {
  /// A permit.
  const Permit(this.registration, this.ends);

  /// Its vehicle's registration.
  final String registration;

  /// When it ends, in words.
  final String ends;
}

/// What a caller's provider gives: loading, failed or the data.
class _Loaded<T> {
  const _Loaded(this.value);

  final T value;

  Widget when({
    required Widget Function() loading,
    required Widget Function(Object error, StackTrace? stack) error,
    required Widget Function(T value) data,
  }) => data(value);
}

/// The file the caller's picker chose.
class _Picked {
  const _Picked(this.name);

  final String name;
}

/// What a page of the caller's app has to hand when it uses a part: its
/// state, its callbacks, its controllers.
class _Caller {
  int index = 0;
  final pages = const [Text('Home'), Text('Applications')];
  String? emailError = 'Enter an email address';
  String email = '';
  final data = const _Loaded([Permit('CU57 ABC', '3 November 2026')]);
  bool textMessages = false;
  final streets = const ['Mill Lane', 'Northgate', 'Old Town Road'];
  String? street;
  late final day = _own(TextEditingController());
  late final month = _own(TextEditingController());
  late final year = _own(TextEditingController());
  final errors = const ['Enter your full name'];
  late final nameFocus = _own(FocusNode());
  _Picked? proof = const _Picked('council-tax-bill.pdf');
  final destinations = const [
    CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
    CivicNavigationDestination(
      icon: LucideIcons.fileText,
      label: 'Applications',
    ),
  ];
  int page = 0;
  String? passwordError;
  String password = '';
  String? vehicle;
  final rows = const [Text('Resident permit, Zone B')];
  final question = const Text('What is your vehicle registration number?');
  final continueButton = CivicButton(
    onPressed: () {},
    child: const Text('Continue'),
  );
  String query = '';
  String? zone = 'a';
  bool largerText = false;
  late final permits = _own(
    DesignTableController<Map<String, String>>(
      rows: const [
        {'vehicle': 'CU57 ABC', 'ends': '3 November 2026'},
      ],
      columns: [
        const DesignTableColumn(id: 'vehicle', label: 'Vehicle'),
        const DesignTableColumn(id: 'ends', label: 'Ends'),
      ],
    ),
  );
  int tab = 0;
  String? postcodeError;
  String postcode = '';
  bool pressed = false;
  bool focused = false;
  bool night = false;
  final router = _Router();

  void setState(VoidCallback change) => change();
  void retry() {}
  void goHome() {}
  void goBack() {}
  void save() {}
  void later() {}
  void apply() {}
  void pickProof() {}
  void openGuidance() {}
  void openApplication(String reference) {}
  void openAll() {}
  void remove() {}
  void openAccount() {}

  Map<String, DocExample> get examples => {
    // app/frame.dart
    'CivicNavItem': (context) {
      const item = CivicNavItem(
        LucideIcons.fileText,
        'Applications',
        ValueKey('applications'),
      );
      return CivicShellFrame(
        places: const [CivicNavItem(LucideIcons.house, 'Home'), item],
        selectedIndex: 1,
        onSelected: (_) {},
        child: const CivicScreen(body: Text('Applications')),
      );
    },
    'CivicShellAction': (context) => CivicShellFrame(
      places: const [CivicNavItem(LucideIcons.house, 'Home')],
      selectedIndex: 0,
      onSelected: (_) {},
      action: CivicShellAction(
        icon: LucideIcons.plus,
        label: 'Apply for a permit',
        onPressed: (context) => Navigator.of(context).pushNamed('/apply'),
      ),
      child: const CivicScreen(body: Text('Home')),
    ),
    'CivicShellFrame': (context) => CivicShellFrame(
      places: const [
        CivicNavItem(LucideIcons.house, 'Home'),
        CivicNavItem(LucideIcons.fileText, 'Applications'),
      ],
      selectedIndex: index,
      onSelected: (i) => setState(() => index = i),
      child: pages[index],
    ),
    // app/host.dart
    'CivicHost': (context) => MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => CivicHost(child: child!),
    ),
    // app/input.dart
    'CivicInput': (context) => CivicInput(
      label: 'Email address',
      error: emailError,
      onChanged: (value) => email = value,
    ),
    // app/preview.dart
    'CivicPreview': (context) => const CivicPreview(
      presentation: CivicPresentation.pushed,
      child: PermitPage(),
    ),
    // app/screen.dart
    'CivicScreen': (context) => CivicScreen(
      topBar: CivicTopBar(
        title: 'Your permit',
        leading: CivicTopBar.autoLeading(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text('Your permit', style: context.civicText.headingXL)],
      ),
    ),
    // app/states.dart
    'CivicLoadingState': (context) => data.when(
      loading: () => const CivicLoadingState(),
      error: (error, _) => CivicErrorState(
        title: 'Sorry, there is a problem',
        message: '$error',
      ),
      data: (permits) => Column(
        children: [for (final permit in permits) Text(permit.registration)],
      ),
    ),
    'CivicErrorState': (context) => CivicErrorState(
      title: 'Sorry, the service is unavailable',
      message: 'Check your connection, then try again.',
      onRetry: retry,
    ),
    'CivicBreadcrumbs': (context) => CivicBreadcrumbs(
      items: [
        CivicBreadcrumb(label: 'Home', onPressed: goHome),
        CivicBreadcrumb(label: 'Your applications', onPressed: goBack),
      ],
    ),
    'CivicButton': (context) => CivicButton(
      onPressed: () => Navigator.of(context).pushNamed('/check'),
      child: const Text('Continue'),
    ),
    'CivicButtonGroup': (context) => CivicButtonGroup(
      children: [
        CivicButton(onPressed: save, child: const Text('Save and continue')),
        CivicLink(
          onPressed: later,
          child: const Text('Save and come back later'),
        ),
      ],
    ),
    'CivicCheckbox': (context) => CivicCheckbox(
      value: textMessages,
      onChanged: (value) => setState(() => textMessages = value!),
      labelText: 'Text message',
      helperText: 'We will send a text when your permit is ready.',
    ),
    'CivicCombobox': (context) => CivicCombobox<String>(
      labelText: 'Street',
      options: streets,
      onSelected: (value) => setState(() => street = value),
    ),
    'CivicDateInput': (context) => CivicDateInput(
      labelText: 'What is your date of birth?',
      helperText: 'For example, 27 3 1987',
      dayLabel: 'Day',
      monthLabel: 'Month',
      yearLabel: 'Year',
      dayController: day,
      monthController: month,
      yearController: year,
    ),
    'CivicDetails': (context) => const CivicDetails(
      title: 'Help with proof of address',
      child: Text(
        'A council tax bill or a tenancy agreement from the last '
        'three months.',
      ),
    ),
    'showCivicDialog': (context) {
      Future<bool?> ask() async {
        final cancel = await showCivicDialog<bool>(
          context: context,
          builder: (context) => CivicDialog(
            title: 'Cancel your application?',
            content: const Text('You will lose the answers you have given.'),
            actions: [
              CivicButton(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel application'),
              ),
              CivicButton.secondary(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep it'),
              ),
            ],
          ),
        );
        return cancel;
      }

      // A dialog opens from a press, never while a page builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) ask().ignore();
      });
      return null;
    },
    'CivicEmptyState': (context) => CivicEmptyState(
      title: 'No applications yet',
      actions: [
        CivicButton(onPressed: apply, child: const Text('Apply for a permit')),
      ],
      children: [const Text('When you apply for a permit it will show here.')],
    ),
    'CivicErrorSummary': (context) => Column(
      children: [
        if (errors.isNotEmpty)
          CivicErrorSummary(
            title: 'There is a problem',
            errors: [
              CivicErrorSummaryItem(
                text: 'Enter your full name',
                onPressed: nameFocus.requestFocus,
              ),
            ],
          ),
      ],
    ),
    'CivicFieldset': (context) {
      bool? email = true;
      bool? post = false;
      void setEmail(bool? value) => email = value;
      void setPost(bool? value) => post = value;
      return CivicFieldset(
        labelText: 'How would you like to be contacted?',
        helperText: 'Select all that apply.',
        children: [
          CivicCheckbox(value: email, onChanged: setEmail, labelText: 'Email'),
          CivicCheckbox(value: post, onChanged: setPost, labelText: 'Post'),
        ],
      );
    },
    'CivicFileUpload': (context) => CivicFileUpload(
      labelText: 'Upload proof of address',
      helperText:
          'A council tax bill or a tenancy agreement, as a PDF or a photo.',
      chooseLabel: 'Choose file',
      emptyLabel: 'No file chosen',
      removeLabel: 'Remove',
      fileName: proof?.name,
      onChoose: pickProof,
      onRemoved: () => setState(() => proof = null),
    ),
    'CivicIconButton': (context) => CivicIconButton(
      icon: LucideIcons.x,
      semanticLabel: 'Close',
      onPressed: () => Navigator.of(context).pop(),
    ),
    'CivicInset': (context) => const CivicInset(
      child: Text('It can take up to 5 working days to decide.'),
    ),
    'CivicWarning': (context) => const CivicWarning(
      assistiveLabel: 'Warning',
      child: Text(
        'You can be fined up to 80 crowns if you park without a permit.',
      ),
    ),
    'CivicLink': (context) => CivicLink(
      onPressed: () => openGuidance(),
      child: const Text('Read the guidance on permit zones'),
    ),
    'CivicBackLink': (context) =>
        CivicBackLink(onPressed: () => Navigator.of(context).maybePop()),
    'CivicListRow': (context) => CivicListGroup(
      children: [
        CivicListRow(
          title: const Text('Resident permit, Zone B'),
          subtitle: const Text('BRM-4821-K · Sent 3 November'),
          trailing: const CivicTag(label: 'In review', tone: CivicTone.info),
          onTap: () => openApplication('BRM-4821-K'),
        ),
      ],
    ),
    'CivicListGroup': (context) => CivicListGroup(
      title: 'Your applications',
      children: [
        CivicListRow(
          title: const Text('Visitor permits, 10 days'),
          onTap: () => openApplication('BRM-3307-A'),
        ),
      ],
    ),
    'CivicNavigationBar': (context) => CivicNavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
        CivicNavigationDestination(
          icon: LucideIcons.fileText,
          label: 'Applications',
        ),
      ],
    ),
    'CivicSideNavigation': (context) => CivicSideNavigation(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: destinations,
    ),
    'CivicPagination': (context) => CivicPagination(
      pageCount: 12,
      selectedIndex: page,
      onPageChanged: (index) => setState(() => page = index),
    ),
    'CivicConfirmationPanel': (context) => CivicConfirmationPanel(
      title: 'Application sent',
      child: Column(
        children: [
          const Text('Your reference number'),
          Text('BRM-4821-K', style: context.civicText.code),
        ],
      ),
    ),
    'CivicNotificationBanner': (context) => const CivicNotificationBanner(
      title: 'Important',
      child: Text('Permits for Zone C are paused until 1 December.'),
    ),
    'CivicPasswordField': (context) => CivicPasswordField(
      labelText: 'Password',
      helperText: 'At least 10 characters',
      errorText: passwordError,
      onChanged: (value) => password = value,
    ),
    'CivicRadioGroup': (context) => CivicRadioGroup<String>(
      labelText: 'What kind of vehicle is the permit for?',
      isPageHeading: true,
      groupValue: vehicle,
      onChanged: (value) => setState(() => vehicle = value),
      children: const [
        CivicRadio(value: 'car', labelText: 'Car or van'),
        CivicRadio(
          value: 'motorcycle',
          labelText: 'Motorcycle',
          helperText: 'Includes mopeds and scooters.',
        ),
      ],
    ),
    'CivicScaffold': (context) => CivicScaffold(
      topBar: const CivicTopBar(title: 'Brindlemere parking permits'),
      skipLinkLabel: 'Skip to main content',
      body: CivicPageBody(title: 'Your applications', children: rows),
    ),
    'CivicPageBody': (context) => CivicPageBody(
      backLink: CivicBackLink(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      caption: 'Question 2 of 5',
      action: CivicButton(onPressed: apply, child: const Text('Continue')),
      children: [question],
    ),
    'CivicSearchField': (context) => CivicSearchField(
      labelText: 'Search applications',
      helperText: 'A reference, a registration or a street',
      onSubmitted: (words) => setState(() => query = words),
    ),
    'CivicSectionBreak': (context) =>
        const CivicSectionBreak(size: CivicSectionBreakSize.large),
    'CivicSectionHeader': (context) => CivicSectionHeader(
      title: 'Your permits',
      action: CivicLink(onPressed: openAll, child: const Text('View all')),
    ),
    'CivicSelect': (context) => CivicSelect<String>(
      labelText: 'Permit zone',
      value: zone,
      onChanged: (value) => setState(() => zone = value),
      items: const [
        CivicSelectItem(value: 'a', label: 'Zone A: Old Town'),
        CivicSelectItem(value: 'b', label: 'Zone B: Harbourside'),
      ],
    ),
    'CivicSummaryList': (context) => CivicSummaryList(
      rows: [
        CivicSummaryRow(
          label: 'Name',
          value: const Text('Amara Okafor'),
          actionLabel: 'Change',
          actionSemanticLabel: 'Change name',
          onActionPressed: () => router.go('/apply/name'),
        ),
      ],
    ),
    'CivicSummaryCard': (context) {
      final rows = [
        const CivicSummaryRow(label: 'Registration', value: Text('CU57 ABC')),
      ];
      return CivicSummaryCard(
        title: 'Vehicle 1',
        actions: [CivicLink(onPressed: remove, child: const Text('Remove'))],
        child: CivicSummaryList(rows: rows),
      );
    },
    'CivicSwitch': (context) => CivicSwitch(
      value: largerText,
      onChanged: (value) => setState(() => largerText = value),
      labelText: 'Larger text',
      helperText: 'Makes the words on every page bigger.',
    ),
    'CivicTable': (context) => CivicTable<Map<String, String>>(
      caption: 'Permits in your household',
      controller: permits,
      cellBuilder: (context, permit, column) => Text(permit[column.id] ?? ''),
    ),
    'CivicTabBar': (context) => CivicTabBar(
      tabs: const ['Details', 'Documents', 'History'],
      selectedIndex: tab,
      onTap: (i) => setState(() => tab = i),
    ),
    'CivicTag': (context) =>
        const CivicTag(label: 'In progress', tone: CivicTone.info),
    'CivicTextField': (context) => CivicTextField(
      labelText: 'Postcode',
      widthInCharacters: 10,
      autofillHints: const [AutofillHints.postalCode],
      errorText: postcodeError,
      onChanged: (value) => postcode = value,
    ),
    'CivicTimeline': (context) => const CivicTimeline(
      entries: [
        CivicTimelineEntry(
          title: 'Proof of address checked',
          date: '5 November 2026',
        ),
        CivicTimelineEntry(
          title: 'Application received',
          date: '3 November 2026',
          child: Text('We will check it within 10 working days.'),
        ),
      ],
    ),
    'CivicToast': (context) {
      // A toast is shown from a press, never while a page builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        CivicToast.show(context, 'Your answers have been saved');
      });
      return null;
    },
    'CivicTopBar': (context) => CivicTopBar(
      title: 'Brindlemere parking permits',
      onTitlePressed: () => router.go('/'),
      actions: [
        CivicIconButton(
          icon: LucideIcons.user,
          semanticLabel: 'Your account',
          onPressed: openAccount,
        ),
      ],
    ),
    'CivicTopBar.backButton': (context) => CivicTopBar(
      title: 'Apply for a permit',
      leading: CivicTopBar.backButton(context, onPressed: goBack),
    ),
    'CivicTopBar.autoLeading': (context) => CivicTopBar(
      title: 'Your permit',
      leading: CivicTopBar.autoLeading(context),
    ),
    // fonts.dart
    'civicFontFamily': (context) async {
      final bytes = Future.value(
        ByteData.sublistView(
          File('assets/fonts/AtkinsonNext-400.ttf').readAsBytesSync(),
        ),
      );
      final loader = FontLoader(civicFontFamily('AtkinsonNext'))
        ..addFont(bytes);
      await loader.load();
      return null;
    },
    'civicLoadFonts': (context) {
      // An app's main, compiled here, not run: it would replace the test's
      // tree.
      Future<void> main() async {
        WidgetsFlutterBinding.ensureInitialized();
        await civicLoadFonts();
        runApp(const MyApp());
      }

      return main;
    },
    // material.dart
    'CivicFace': (context) => CivicFace(
      fill: context.civicTheme.action,
      edgeColor: context.civicTheme.actionEdge,
      edgeHeight: CivicMetrics.bar,
      pressed: pressed,
      focused: focused,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + CivicMetrics.bar),
        child: Text('Continue'),
      ),
    ),
    'CivicWell': (context) => CivicWell(
      focused: focused,
      child: const Padding(
        padding: EdgeInsets.all(CivicMetrics.edge + 12),
        child: Text('42'),
      ),
    ),
    // theme.dart
    'CivicStyle': (context) => CivicButton(
      style: const CivicStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)),
      ),
      onPressed: () {},
      child: const Text('Continue'),
    ),
    'CivicThemeData': (context) {
      final theme = CivicThemeData.light();
      final mine = CivicThemeData.from(
        brightness: Brightness.light,
        action: const Color(0xFF00594C),
      );
      return Column(
        children: [
          CivicTheme(data: theme, child: const Text('Light')),
          CivicTheme(data: mine, child: const Text('Mine')),
        ],
      );
    },
    'CivicTheme': (context) => MaterialApp(
      builder: (context, child) => CivicTheme(
        data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? CivicThemeData.dark()
            : CivicThemeData.light(),
        child: child!,
      ),
      home: const ApplyPage(),
    ),
    'AnimatedCivicTheme': (context) {
      const page = Text('Your permit');
      return AnimatedCivicTheme(
        data: night ? CivicThemeData.dark() : CivicThemeData.light(),
        child: page,
      );
    },
    // format.dart
    'CivicFormat': (context) {
      final permit = (ends: DateTime(2026, 11, 3));
      return Text('Your permit ends on ${CivicFormat.date(permit.ends)}');
    },
  };
}

Widget _harness(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => CivicHost(child: app ?? const SizedBox.shrink()),
  home: child,
);

void main() {
  tearDown(() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  });

  test("civic_parts.dart's example imports what this file imports", () {
    expect(
      _partsImports,
      contains("import 'package:civic_ui/civic_parts.dart';"),
    );
  });

  testDocExamples(
    self: 'test/doc_examples_test.dart',
    examples: _Caller().examples,
    wrap: _harness,
    skip: const {'routes.dart'},
  );
}
