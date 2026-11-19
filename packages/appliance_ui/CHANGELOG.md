## 0.1.2

- A field holding a group of controls (a row, column or wrap of them, a selector, a stepper, a toggle group, a range slider, a tag input) keeps each control's own node and tap, and its label names the group. Before, with semantics on (a screen reader, or a browser that turned them on), a tap on any of them went to the first. `ApplianceField.mergeSemantics` is now null by default and decides by the child; true and false still force it.
- `ApplianceStepper` takes a `step` (one by default): each press moves the number by it, a step past a bound stops at the bound, and a key at its bound stands disabled.
- By day the display windows (charts, readouts, the time picker, the stepper's figure, code cells, badges, toasts and tooltips) are a pale LCD with dark figures, as on a clock radio; by night they stay smoked glass with lit figures. Chart traces on the LCD are inks that read at 3:1 or more, and the scale's figures at 4.5:1.
- Keyboard focus lights the part's own rim from inside, as a backlit key's edge glows, in place of a ring drawn around it. It reads at 3:1 or more against the part at rest, day and night; on the signal key the rim takes the legend's ink, and on a lit switch the ink by day and white by night. A text button or a link, with no face of its own, lights a plate just beyond its words (`ApplianceFace.focusReach`), so the light crosses no letter. `ApplianceMetrics.focusWidth` is the lit rim's width (2.5); `focusGap` and `focusRadius` are deprecated. `applianceFocusLight` gives a part that paints its own focus the same light.
- A stepper's window is as tall as its keys and wide enough for the longest number it can show, at any text size.
- Each position of a slide selector has its lamp just before its glyph and words, as a chip does (stacked in a narrow space, beside its glyph or over its words); the chosen one's is lit.
- A switch's slot lights in the signal when it is on, so on and off read at a glance; the cap's place and the bar and ring marks still say it without colour.
- On the day's LCD a toast's action reads at 4.5:1, and a tooltip stands off the panel in a dark bezel with a soft shadow.
- Large text, as Material copes with it: a time picker's figures and a calendar's days grow with the text up to twice their size, as Material's time picker's and calendar's do, their cells and keys with them, so the figures show whole and the keys stand clear; a calendar's weekdays keep apart. A date field and a chip grow with their words, so a date or a chip's descenders are never cut. A strip's and a rail's key names and badges grow up to 1.3x, as Material's navigation bar labels do. Stacked over its words in a narrow space, a selector position's lamp stands just above them.

## 0.1.1

- A selected radio keeps its lamp centred. Toolbar keys and tag-input keys fit the corners of their recesses.
- The light inside a fader or progress bar now stops the same distance from the end as from the sides.
- The toast glass follows its bezel. Toast keys and the banner close key sit evenly inside their frame and animate when pressed or focused.
- Confirmation buttons, navigation keys, delivery stages and timeline timestamps make room for larger text.
- Chart axes follow the system text size. Range sliders accept a `semanticFormatterCallback` for values such as prices.
- Empty-state messages are shown on a smooth panel, and their number display grows with the text. Product cards wrap availability badges below the price when space is limited.
- Appearance selectors keep their full labels at large text sizes. Disabled key labels have stronger light- and dark-theme contrast.
- Larder's account settings edit the name, address and saved card. Help opens delivery information and a local message form. Signing out hides the account and purchase history.
- Shop prices and filters respect the tax display preference. Checkout itemizes tax, and payment retries and receipts use the submitted delivery details and masked card number.

## 0.1.0

- Initial release with light and dark themes, form controls, responsive navigation, dialogs, sheets and interactive charts.
- Includes the Larder example app.
