/// Frosted's glyphs: every icon its parts draw, named for what it says, in
/// the one file that imports the icon set (Lucide). The barrel exports this
/// and never the icon set, so an app's icons are its own choice. The marks
/// that point along the reading direction (back, forward, a chevron, sign
/// out) mirror in a right-to-left language.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const String _family = 'Lucide';
const String _package = 'lucide_icons_flutter';

/// Every glyph Frosted draws.
///
/// ```dart
/// FrostedIconButton(FrostedGlyphs.back, label: 'Back', onPressed: pop)
/// ```
abstract final class FrostedGlyphs {
  /// Goes back a page; mirrors in a right-to-left language.
  static const IconData back = IconData(
    0xE048,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// Closes a raised surface.
  static const IconData close = LucideIcons.x;

  /// Goes into a row or on a step; mirrors in a right-to-left language.
  static const IconData forward = IconData(
    0xE06F,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// Opens more actions.
  static const IconData more = LucideIcons.ellipsis;

  /// Opens outside the app.
  static const IconData external = LucideIcons.externalLink;

  /// Shows a hidden word (a password).
  static const IconData show = LucideIcons.eye;

  /// Hides it again.
  static const IconData hide = LucideIcons.eyeOff;

  /// Searches.
  static const IconData search = LucideIcons.search;

  /// Clears a field.
  static const IconData clear = LucideIcons.circleX;

  /// Marks a note.
  static const IconData info = LucideIcons.info;

  /// Marks something done.
  static const IconData success = LucideIcons.circleCheck;

  /// Marks a warning.
  static const IconData warning = LucideIcons.triangleAlert;

  /// Marks an error.
  static const IconData danger = LucideIcons.circleAlert;

  /// A tick: chosen, done.
  static const IconData check = LucideIcons.check;

  /// Marks something waiting.
  static const IconData pending = LucideIcons.hourglass;

  /// Adds.
  static const IconData add = LucideIcons.plus;

  /// Takes away one.
  static const IconData remove = LucideIcons.minus;

  /// Deletes.
  static const IconData delete = LucideIcons.trash2;

  /// Uploads.
  static const IconData upload = LucideIcons.upload;

  /// Shares.
  static const IconData share = LucideIcons.share;

  /// Tries again, loads again.
  static const IconData refresh = LucideIcons.rotateCcw;

  /// Signs out; mirrors in a right-to-left language.
  static const IconData signOut = IconData(
    0xE10E,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// Email.
  static const IconData email = LucideIcons.mail;

  /// A phone.
  static const IconData phone = LucideIcons.phone;

  /// Locked, private.
  static const IconData lock = LucideIcons.lock;

  /// A key, a passcode.
  static const IconData key = LucideIcons.keyRound;

  /// A person, an account.
  static const IconData person = LucideIcons.user;

  /// Devices.
  static const IconData devices = LucideIcons.monitorSmartphone;

  /// Verified.
  static const IconData verified = LucideIcons.badgeCheck;

  /// A place.
  static const IconData location = LucideIcons.mapPin;

  /// Notifications.
  static const IconData notifications = LucideIcons.bell;

  /// A time.
  static const IconData time = LucideIcons.clock;

  /// A camera.
  static const IconData camera = LucideIcons.camera;

  /// Dictation, a voice.
  static const IconData microphone = LucideIcons.mic;

  /// Contacts.
  static const IconData contacts = LucideIcons.contact;

  /// A date.
  static const IconData calendar = LucideIcons.calendar;

  /// Photos.
  static const IconData photos = LucideIcons.images;

  /// An arrow down: money out, a fall.
  static const IconData arrowDown = LucideIcons.arrowDown;

  /// Two arrows: a swap.
  static const IconData arrowLeftRight = LucideIcons.arrowLeftRight;

  /// An arrow on to; mirrors in a right-to-left language.
  static const IconData arrowRight = IconData(
    0xE049,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// Two arrows: a move between accounts.
  static const IconData arrowRightLeft = LucideIcons.arrowRightLeft;

  /// An arrow up: money in, a rise.
  static const IconData arrowUp = LucideIcons.arrowUp;

  /// An arrow up and right: a payment out.
  static const IconData arrowUpRight = LucideIcons.arrowUpRight;

  /// A bell: notifications.
  static const IconData bell = LucideIcons.bell;

  /// A bicycle.
  static const IconData bike = LucideIcons.bike;

  /// A pie chart: a budget.
  static const IconData chartPie = LucideIcons.chartPie;

  /// Opens a list below.
  static const IconData chevronDown = LucideIcons.chevronDown;

  /// Closes a list above; a column sorted ascending.
  static const IconData chevronUp = LucideIcons.chevronUp;

  /// A column that can be sorted, not sorted yet.
  static const IconData sort = LucideIcons.chevronsUpDown;

  /// A handle to drag a row by.
  static const IconData grip = LucideIcons.gripVertical;

  /// A handle to drag a divider by, across a vertical split.
  static const IconData gripHorizontal = LucideIcons.gripHorizontal;

  /// Plays a carousel.
  static const IconData play = LucideIcons.play;

  /// Pauses a carousel.
  static const IconData pause = LucideIcons.pause;

  /// The command key, in a shortcut (⌘).
  static const IconData command = LucideIcons.command;

  /// The shift key, in a shortcut (⇧).
  static const IconData shift = LucideIcons.arrowBigUp;

  /// The option key, in a shortcut (⌥).
  static const IconData option = LucideIcons.option;

  /// The control key, in a shortcut (⌃).
  static const IconData control = LucideIcons.chevronUp;

  /// A step back; mirrors in a right-to-left language.
  static const IconData chevronLeft = IconData(
    0xE06E,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// A clock.
  static const IconData clock = LucideIcons.clock;

  /// A card.
  static const IconData creditCard = LucideIcons.creditCard;

  /// Home.
  static const IconData house = LucideIcons.house;

  /// A bank.
  static const IconData landmark = LucideIcons.landmark;

  /// Savings.
  static const IconData piggyBank = LucideIcons.piggyBank;

  /// A trip.
  static const IconData plane = LucideIcons.plane;

  /// A receipt, a bill.
  static const IconData receipt = LucideIcons.receipt;

  /// A file, an attachment.
  static const IconData file = LucideIcons.file;

  /// Again.
  static const IconData rotateCw = LucideIcons.rotateCw;

  /// Frozen.
  static const IconData snowflake = LucideIcons.snowflake;

  /// Something new, a suggestion.
  static const IconData sparkles = LucideIcons.sparkles;

  /// A split.
  static const IconData split = LucideIcons.split;

  /// A square.
  static const IconData square = LucideIcons.square;

  /// Growth.
  static const IconData trendingUp = LucideIcons.trendingUp;

  /// A triangle.
  static const IconData triangle = LucideIcons.triangle;

  /// Dining.
  static const IconData utensils = LucideIcons.utensils;

  /// A wallet.
  static const IconData wallet = LucideIcons.wallet;

  /// Quick, a bolt.
  static const IconData zap = LucideIcons.zap;
}
