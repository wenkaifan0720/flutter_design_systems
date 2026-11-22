// Fluent 2's colour tokens, from @fluentui/tokens 1.0.0-alpha.24 (MIT, npm) and the Fluent theme
// designer's palette code (MIT, microsoft/fluentui).
// The classes: one field per Fluent colour token, named as Fluent names it without its `color`.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color, ColorProperty;

/// Every Fluent 2 alias colour of one preset in one appearance: the neutral
/// layers (`neutralBackground1` to `8`, the subtle and transparent
/// fills), the inks (`neutralForeground1` to `4`, disabled, inverted,
/// on brand), the strokes, the brand fills and inks with their hover,
/// pressed and selected steps, the status colours (danger, success,
/// warning) and the shadow colours, each named as `@fluentui/tokens`
/// names it without its `color` prefix (`colorNeutralBackground1Hover`
/// is [neutralBackground1Hover]). A component reads the token its Fluent
/// counterpart's styles read. The values are generated
/// (`internal/presets.g.dart`); [Fluent2ThemeData] carries one.
final class Fluent2Colors {
  /// A set of Fluent's alias colours, one per token.
  const Fluent2Colors({
    required this.neutralForeground1,
    required this.neutralForeground1Hover,
    required this.neutralForeground1Pressed,
    required this.neutralForeground1Selected,
    required this.neutralForeground2,
    required this.neutralForeground2Hover,
    required this.neutralForeground2Pressed,
    required this.neutralForeground2Selected,
    required this.neutralForeground2BrandHover,
    required this.neutralForeground2BrandPressed,
    required this.neutralForeground2BrandSelected,
    required this.neutralForeground3,
    required this.neutralForeground3Hover,
    required this.neutralForeground3Pressed,
    required this.neutralForeground3Selected,
    required this.neutralForeground3BrandHover,
    required this.neutralForeground3BrandPressed,
    required this.neutralForeground3BrandSelected,
    required this.neutralForeground4,
    required this.neutralForeground5,
    required this.neutralForeground5Hover,
    required this.neutralForeground5Pressed,
    required this.neutralForeground5Selected,
    required this.neutralForegroundDisabled,
    required this.neutralForegroundInvertedDisabled,
    required this.brandForegroundLink,
    required this.brandForegroundLinkHover,
    required this.brandForegroundLinkPressed,
    required this.brandForegroundLinkSelected,
    required this.neutralForeground2Link,
    required this.neutralForeground2LinkHover,
    required this.neutralForeground2LinkPressed,
    required this.neutralForeground2LinkSelected,
    required this.compoundBrandForeground1,
    required this.compoundBrandForeground1Hover,
    required this.compoundBrandForeground1Pressed,
    required this.brandForeground1,
    required this.brandForeground2,
    required this.brandForeground2Hover,
    required this.brandForeground2Pressed,
    required this.neutralForeground1Static,
    required this.neutralForegroundStaticInverted,
    required this.neutralForegroundInverted,
    required this.neutralForegroundInvertedHover,
    required this.neutralForegroundInvertedPressed,
    required this.neutralForegroundInvertedSelected,
    required this.neutralForegroundInverted2,
    required this.neutralForegroundOnBrand,
    required this.neutralForegroundInvertedLink,
    required this.neutralForegroundInvertedLinkHover,
    required this.neutralForegroundInvertedLinkPressed,
    required this.neutralForegroundInvertedLinkSelected,
    required this.brandForegroundInverted,
    required this.brandForegroundInvertedHover,
    required this.brandForegroundInvertedPressed,
    required this.brandForegroundOnLight,
    required this.brandForegroundOnLightHover,
    required this.brandForegroundOnLightPressed,
    required this.brandForegroundOnLightSelected,
    required this.neutralBackground1,
    required this.neutralBackground1Hover,
    required this.neutralBackground1Pressed,
    required this.neutralBackground1Selected,
    required this.neutralBackground2,
    required this.neutralBackground2Hover,
    required this.neutralBackground2Pressed,
    required this.neutralBackground2Selected,
    required this.neutralBackground3,
    required this.neutralBackground3Hover,
    required this.neutralBackground3Pressed,
    required this.neutralBackground3Selected,
    required this.neutralBackground4,
    required this.neutralBackground4Hover,
    required this.neutralBackground4Pressed,
    required this.neutralBackground4Selected,
    required this.neutralBackground5,
    required this.neutralBackground5Hover,
    required this.neutralBackground5Pressed,
    required this.neutralBackground5Selected,
    required this.neutralBackground6,
    required this.neutralBackground7,
    required this.neutralBackground7Hover,
    required this.neutralBackground7Pressed,
    required this.neutralBackground7Selected,
    required this.neutralBackground8,
    required this.neutralBackgroundInverted,
    required this.neutralBackgroundInvertedHover,
    required this.neutralBackgroundInvertedPressed,
    required this.neutralBackgroundInvertedSelected,
    required this.neutralBackgroundStatic,
    required this.neutralBackgroundAlpha,
    required this.neutralBackgroundAlpha2,
    required this.subtleBackground,
    required this.subtleBackgroundHover,
    required this.subtleBackgroundPressed,
    required this.subtleBackgroundSelected,
    required this.subtleBackgroundLightAlphaHover,
    required this.subtleBackgroundLightAlphaPressed,
    required this.subtleBackgroundLightAlphaSelected,
    required this.subtleBackgroundInverted,
    required this.subtleBackgroundInvertedHover,
    required this.subtleBackgroundInvertedPressed,
    required this.subtleBackgroundInvertedSelected,
    required this.transparentBackground,
    required this.transparentBackgroundHover,
    required this.transparentBackgroundPressed,
    required this.transparentBackgroundSelected,
    required this.neutralBackgroundDisabled,
    required this.neutralBackgroundDisabled2,
    required this.neutralBackgroundInvertedDisabled,
    required this.neutralStencil1,
    required this.neutralStencil2,
    required this.neutralStencil1Alpha,
    required this.neutralStencil2Alpha,
    required this.backgroundOverlay,
    required this.scrollbarOverlay,
    required this.brandBackground,
    required this.brandBackgroundHover,
    required this.brandBackgroundPressed,
    required this.brandBackgroundSelected,
    required this.compoundBrandBackground,
    required this.compoundBrandBackgroundHover,
    required this.compoundBrandBackgroundPressed,
    required this.brandBackgroundStatic,
    required this.brandBackground2,
    required this.brandBackground2Hover,
    required this.brandBackground2Pressed,
    required this.brandBackground3Static,
    required this.brandBackground4Static,
    required this.brandBackgroundInverted,
    required this.brandBackgroundInvertedHover,
    required this.brandBackgroundInvertedPressed,
    required this.brandBackgroundInvertedSelected,
    required this.neutralCardBackground,
    required this.neutralCardBackgroundHover,
    required this.neutralCardBackgroundPressed,
    required this.neutralCardBackgroundSelected,
    required this.neutralCardBackgroundDisabled,
    required this.neutralStrokeAccessible,
    required this.neutralStrokeAccessibleHover,
    required this.neutralStrokeAccessiblePressed,
    required this.neutralStrokeAccessibleSelected,
    required this.neutralStroke1,
    required this.neutralStroke1Hover,
    required this.neutralStroke1Pressed,
    required this.neutralStroke1Selected,
    required this.neutralStroke2,
    required this.neutralStroke3,
    required this.neutralStroke4,
    required this.neutralStroke4Hover,
    required this.neutralStroke4Pressed,
    required this.neutralStroke4Selected,
    required this.neutralStrokeSubtle,
    required this.neutralStrokeOnBrand,
    required this.neutralStrokeOnBrand2,
    required this.neutralStrokeOnBrand2Hover,
    required this.neutralStrokeOnBrand2Pressed,
    required this.neutralStrokeOnBrand2Selected,
    required this.brandStroke1,
    required this.brandStroke2,
    required this.brandStroke2Hover,
    required this.brandStroke2Pressed,
    required this.brandStroke2Contrast,
    required this.compoundBrandStroke,
    required this.compoundBrandStrokeHover,
    required this.compoundBrandStrokePressed,
    required this.neutralStrokeDisabled,
    required this.neutralStrokeDisabled2,
    required this.neutralStrokeInvertedDisabled,
    required this.transparentStroke,
    required this.transparentStrokeInteractive,
    required this.transparentStrokeDisabled,
    required this.neutralStrokeAlpha,
    required this.neutralStrokeAlpha2,
    required this.strokeFocus1,
    required this.strokeFocus2,
    required this.neutralShadowAmbient,
    required this.neutralShadowKey,
    required this.neutralShadowAmbientLighter,
    required this.neutralShadowKeyLighter,
    required this.neutralShadowAmbientDarker,
    required this.neutralShadowKeyDarker,
    required this.brandShadowAmbient,
    required this.brandShadowKey,
    required this.statusSuccessBackground1,
    required this.statusSuccessBackground2,
    required this.statusSuccessBackground3,
    required this.statusSuccessForeground1,
    required this.statusSuccessForeground2,
    required this.statusSuccessForeground3,
    required this.statusSuccessForegroundInverted,
    required this.statusSuccessBorderActive,
    required this.statusSuccessBorder1,
    required this.statusSuccessBorder2,
    required this.statusWarningBackground1,
    required this.statusWarningBackground2,
    required this.statusWarningBackground3,
    required this.statusWarningForeground1,
    required this.statusWarningForeground2,
    required this.statusWarningForeground3,
    required this.statusWarningForegroundInverted,
    required this.statusWarningBorderActive,
    required this.statusWarningBorder1,
    required this.statusWarningBorder2,
    required this.statusDangerBackground1,
    required this.statusDangerBackground2,
    required this.statusDangerBackground3,
    required this.statusDangerForeground1,
    required this.statusDangerForeground2,
    required this.statusDangerForeground3,
    required this.statusDangerForegroundInverted,
    required this.statusDangerBorderActive,
    required this.statusDangerBorder1,
    required this.statusDangerBorder2,
    required this.statusDangerBackground3Hover,
    required this.statusDangerBackground3Pressed,
  });

  /// `colorNeutralForeground1`.
  final Color neutralForeground1;

  /// `colorNeutralForeground1Hover`.
  final Color neutralForeground1Hover;

  /// `colorNeutralForeground1Pressed`.
  final Color neutralForeground1Pressed;

  /// `colorNeutralForeground1Selected`.
  final Color neutralForeground1Selected;

  /// `colorNeutralForeground2`.
  final Color neutralForeground2;

  /// `colorNeutralForeground2Hover`.
  final Color neutralForeground2Hover;

  /// `colorNeutralForeground2Pressed`.
  final Color neutralForeground2Pressed;

  /// `colorNeutralForeground2Selected`.
  final Color neutralForeground2Selected;

  /// `colorNeutralForeground2BrandHover`.
  final Color neutralForeground2BrandHover;

  /// `colorNeutralForeground2BrandPressed`.
  final Color neutralForeground2BrandPressed;

  /// `colorNeutralForeground2BrandSelected`.
  final Color neutralForeground2BrandSelected;

  /// `colorNeutralForeground3`.
  final Color neutralForeground3;

  /// `colorNeutralForeground3Hover`.
  final Color neutralForeground3Hover;

  /// `colorNeutralForeground3Pressed`.
  final Color neutralForeground3Pressed;

  /// `colorNeutralForeground3Selected`.
  final Color neutralForeground3Selected;

  /// `colorNeutralForeground3BrandHover`.
  final Color neutralForeground3BrandHover;

  /// `colorNeutralForeground3BrandPressed`.
  final Color neutralForeground3BrandPressed;

  /// `colorNeutralForeground3BrandSelected`.
  final Color neutralForeground3BrandSelected;

  /// `colorNeutralForeground4`.
  final Color neutralForeground4;

  /// `colorNeutralForeground5`.
  final Color neutralForeground5;

  /// `colorNeutralForeground5Hover`.
  final Color neutralForeground5Hover;

  /// `colorNeutralForeground5Pressed`.
  final Color neutralForeground5Pressed;

  /// `colorNeutralForeground5Selected`.
  final Color neutralForeground5Selected;

  /// `colorNeutralForegroundDisabled`.
  final Color neutralForegroundDisabled;

  /// `colorNeutralForegroundInvertedDisabled`.
  final Color neutralForegroundInvertedDisabled;

  /// `colorBrandForegroundLink`.
  final Color brandForegroundLink;

  /// `colorBrandForegroundLinkHover`.
  final Color brandForegroundLinkHover;

  /// `colorBrandForegroundLinkPressed`.
  final Color brandForegroundLinkPressed;

  /// `colorBrandForegroundLinkSelected`.
  final Color brandForegroundLinkSelected;

  /// `colorNeutralForeground2Link`.
  final Color neutralForeground2Link;

  /// `colorNeutralForeground2LinkHover`.
  final Color neutralForeground2LinkHover;

  /// `colorNeutralForeground2LinkPressed`.
  final Color neutralForeground2LinkPressed;

  /// `colorNeutralForeground2LinkSelected`.
  final Color neutralForeground2LinkSelected;

  /// `colorCompoundBrandForeground1`.
  final Color compoundBrandForeground1;

  /// `colorCompoundBrandForeground1Hover`.
  final Color compoundBrandForeground1Hover;

  /// `colorCompoundBrandForeground1Pressed`.
  final Color compoundBrandForeground1Pressed;

  /// `colorBrandForeground1`.
  final Color brandForeground1;

  /// `colorBrandForeground2`.
  final Color brandForeground2;

  /// `colorBrandForeground2Hover`.
  final Color brandForeground2Hover;

  /// `colorBrandForeground2Pressed`.
  final Color brandForeground2Pressed;

  /// `colorNeutralForeground1Static`.
  final Color neutralForeground1Static;

  /// `colorNeutralForegroundStaticInverted`.
  final Color neutralForegroundStaticInverted;

  /// `colorNeutralForegroundInverted`.
  final Color neutralForegroundInverted;

  /// `colorNeutralForegroundInvertedHover`.
  final Color neutralForegroundInvertedHover;

  /// `colorNeutralForegroundInvertedPressed`.
  final Color neutralForegroundInvertedPressed;

  /// `colorNeutralForegroundInvertedSelected`.
  final Color neutralForegroundInvertedSelected;

  /// `colorNeutralForegroundInverted2`.
  final Color neutralForegroundInverted2;

  /// `colorNeutralForegroundOnBrand`.
  final Color neutralForegroundOnBrand;

  /// `colorNeutralForegroundInvertedLink`.
  final Color neutralForegroundInvertedLink;

  /// `colorNeutralForegroundInvertedLinkHover`.
  final Color neutralForegroundInvertedLinkHover;

  /// `colorNeutralForegroundInvertedLinkPressed`.
  final Color neutralForegroundInvertedLinkPressed;

  /// `colorNeutralForegroundInvertedLinkSelected`.
  final Color neutralForegroundInvertedLinkSelected;

  /// `colorBrandForegroundInverted`.
  final Color brandForegroundInverted;

  /// `colorBrandForegroundInvertedHover`.
  final Color brandForegroundInvertedHover;

  /// `colorBrandForegroundInvertedPressed`.
  final Color brandForegroundInvertedPressed;

  /// `colorBrandForegroundOnLight`.
  final Color brandForegroundOnLight;

  /// `colorBrandForegroundOnLightHover`.
  final Color brandForegroundOnLightHover;

  /// `colorBrandForegroundOnLightPressed`.
  final Color brandForegroundOnLightPressed;

  /// `colorBrandForegroundOnLightSelected`.
  final Color brandForegroundOnLightSelected;

  /// `colorNeutralBackground1`.
  final Color neutralBackground1;

  /// `colorNeutralBackground1Hover`.
  final Color neutralBackground1Hover;

  /// `colorNeutralBackground1Pressed`.
  final Color neutralBackground1Pressed;

  /// `colorNeutralBackground1Selected`.
  final Color neutralBackground1Selected;

  /// `colorNeutralBackground2`.
  final Color neutralBackground2;

  /// `colorNeutralBackground2Hover`.
  final Color neutralBackground2Hover;

  /// `colorNeutralBackground2Pressed`.
  final Color neutralBackground2Pressed;

  /// `colorNeutralBackground2Selected`.
  final Color neutralBackground2Selected;

  /// `colorNeutralBackground3`.
  final Color neutralBackground3;

  /// `colorNeutralBackground3Hover`.
  final Color neutralBackground3Hover;

  /// `colorNeutralBackground3Pressed`.
  final Color neutralBackground3Pressed;

  /// `colorNeutralBackground3Selected`.
  final Color neutralBackground3Selected;

  /// `colorNeutralBackground4`.
  final Color neutralBackground4;

  /// `colorNeutralBackground4Hover`.
  final Color neutralBackground4Hover;

  /// `colorNeutralBackground4Pressed`.
  final Color neutralBackground4Pressed;

  /// `colorNeutralBackground4Selected`.
  final Color neutralBackground4Selected;

  /// `colorNeutralBackground5`.
  final Color neutralBackground5;

  /// `colorNeutralBackground5Hover`.
  final Color neutralBackground5Hover;

  /// `colorNeutralBackground5Pressed`.
  final Color neutralBackground5Pressed;

  /// `colorNeutralBackground5Selected`.
  final Color neutralBackground5Selected;

  /// `colorNeutralBackground6`.
  final Color neutralBackground6;

  /// `colorNeutralBackground7`.
  final Color neutralBackground7;

  /// `colorNeutralBackground7Hover`.
  final Color neutralBackground7Hover;

  /// `colorNeutralBackground7Pressed`.
  final Color neutralBackground7Pressed;

  /// `colorNeutralBackground7Selected`.
  final Color neutralBackground7Selected;

  /// `colorNeutralBackground8`.
  final Color neutralBackground8;

  /// `colorNeutralBackgroundInverted`.
  final Color neutralBackgroundInverted;

  /// `colorNeutralBackgroundInvertedHover`.
  final Color neutralBackgroundInvertedHover;

  /// `colorNeutralBackgroundInvertedPressed`.
  final Color neutralBackgroundInvertedPressed;

  /// `colorNeutralBackgroundInvertedSelected`.
  final Color neutralBackgroundInvertedSelected;

  /// `colorNeutralBackgroundStatic`.
  final Color neutralBackgroundStatic;

  /// `colorNeutralBackgroundAlpha`.
  final Color neutralBackgroundAlpha;

  /// `colorNeutralBackgroundAlpha2`.
  final Color neutralBackgroundAlpha2;

  /// `colorSubtleBackground`.
  final Color subtleBackground;

  /// `colorSubtleBackgroundHover`.
  final Color subtleBackgroundHover;

  /// `colorSubtleBackgroundPressed`.
  final Color subtleBackgroundPressed;

  /// `colorSubtleBackgroundSelected`.
  final Color subtleBackgroundSelected;

  /// `colorSubtleBackgroundLightAlphaHover`.
  final Color subtleBackgroundLightAlphaHover;

  /// `colorSubtleBackgroundLightAlphaPressed`.
  final Color subtleBackgroundLightAlphaPressed;

  /// `colorSubtleBackgroundLightAlphaSelected`.
  final Color subtleBackgroundLightAlphaSelected;

  /// `colorSubtleBackgroundInverted`.
  final Color subtleBackgroundInverted;

  /// `colorSubtleBackgroundInvertedHover`.
  final Color subtleBackgroundInvertedHover;

  /// `colorSubtleBackgroundInvertedPressed`.
  final Color subtleBackgroundInvertedPressed;

  /// `colorSubtleBackgroundInvertedSelected`.
  final Color subtleBackgroundInvertedSelected;

  /// `colorTransparentBackground`.
  final Color transparentBackground;

  /// `colorTransparentBackgroundHover`.
  final Color transparentBackgroundHover;

  /// `colorTransparentBackgroundPressed`.
  final Color transparentBackgroundPressed;

  /// `colorTransparentBackgroundSelected`.
  final Color transparentBackgroundSelected;

  /// `colorNeutralBackgroundDisabled`.
  final Color neutralBackgroundDisabled;

  /// `colorNeutralBackgroundDisabled2`.
  final Color neutralBackgroundDisabled2;

  /// `colorNeutralBackgroundInvertedDisabled`.
  final Color neutralBackgroundInvertedDisabled;

  /// `colorNeutralStencil1`.
  final Color neutralStencil1;

  /// `colorNeutralStencil2`.
  final Color neutralStencil2;

  /// `colorNeutralStencil1Alpha`.
  final Color neutralStencil1Alpha;

  /// `colorNeutralStencil2Alpha`.
  final Color neutralStencil2Alpha;

  /// `colorBackgroundOverlay`.
  final Color backgroundOverlay;

  /// `colorScrollbarOverlay`.
  final Color scrollbarOverlay;

  /// `colorBrandBackground`.
  final Color brandBackground;

  /// `colorBrandBackgroundHover`.
  final Color brandBackgroundHover;

  /// `colorBrandBackgroundPressed`.
  final Color brandBackgroundPressed;

  /// `colorBrandBackgroundSelected`.
  final Color brandBackgroundSelected;

  /// `colorCompoundBrandBackground`.
  final Color compoundBrandBackground;

  /// `colorCompoundBrandBackgroundHover`.
  final Color compoundBrandBackgroundHover;

  /// `colorCompoundBrandBackgroundPressed`.
  final Color compoundBrandBackgroundPressed;

  /// `colorBrandBackgroundStatic`.
  final Color brandBackgroundStatic;

  /// `colorBrandBackground2`.
  final Color brandBackground2;

  /// `colorBrandBackground2Hover`.
  final Color brandBackground2Hover;

  /// `colorBrandBackground2Pressed`.
  final Color brandBackground2Pressed;

  /// `colorBrandBackground3Static`.
  final Color brandBackground3Static;

  /// `colorBrandBackground4Static`.
  final Color brandBackground4Static;

  /// `colorBrandBackgroundInverted`.
  final Color brandBackgroundInverted;

  /// `colorBrandBackgroundInvertedHover`.
  final Color brandBackgroundInvertedHover;

  /// `colorBrandBackgroundInvertedPressed`.
  final Color brandBackgroundInvertedPressed;

  /// `colorBrandBackgroundInvertedSelected`.
  final Color brandBackgroundInvertedSelected;

  /// `colorNeutralCardBackground`.
  final Color neutralCardBackground;

  /// `colorNeutralCardBackgroundHover`.
  final Color neutralCardBackgroundHover;

  /// `colorNeutralCardBackgroundPressed`.
  final Color neutralCardBackgroundPressed;

  /// `colorNeutralCardBackgroundSelected`.
  final Color neutralCardBackgroundSelected;

  /// `colorNeutralCardBackgroundDisabled`.
  final Color neutralCardBackgroundDisabled;

  /// `colorNeutralStrokeAccessible`.
  final Color neutralStrokeAccessible;

  /// `colorNeutralStrokeAccessibleHover`.
  final Color neutralStrokeAccessibleHover;

  /// `colorNeutralStrokeAccessiblePressed`.
  final Color neutralStrokeAccessiblePressed;

  /// `colorNeutralStrokeAccessibleSelected`.
  final Color neutralStrokeAccessibleSelected;

  /// `colorNeutralStroke1`.
  final Color neutralStroke1;

  /// `colorNeutralStroke1Hover`.
  final Color neutralStroke1Hover;

  /// `colorNeutralStroke1Pressed`.
  final Color neutralStroke1Pressed;

  /// `colorNeutralStroke1Selected`.
  final Color neutralStroke1Selected;

  /// `colorNeutralStroke2`.
  final Color neutralStroke2;

  /// `colorNeutralStroke3`.
  final Color neutralStroke3;

  /// `colorNeutralStroke4`.
  final Color neutralStroke4;

  /// `colorNeutralStroke4Hover`.
  final Color neutralStroke4Hover;

  /// `colorNeutralStroke4Pressed`.
  final Color neutralStroke4Pressed;

  /// `colorNeutralStroke4Selected`.
  final Color neutralStroke4Selected;

  /// `colorNeutralStrokeSubtle`.
  final Color neutralStrokeSubtle;

  /// `colorNeutralStrokeOnBrand`.
  final Color neutralStrokeOnBrand;

  /// `colorNeutralStrokeOnBrand2`.
  final Color neutralStrokeOnBrand2;

  /// `colorNeutralStrokeOnBrand2Hover`.
  final Color neutralStrokeOnBrand2Hover;

  /// `colorNeutralStrokeOnBrand2Pressed`.
  final Color neutralStrokeOnBrand2Pressed;

  /// `colorNeutralStrokeOnBrand2Selected`.
  final Color neutralStrokeOnBrand2Selected;

  /// `colorBrandStroke1`.
  final Color brandStroke1;

  /// `colorBrandStroke2`.
  final Color brandStroke2;

  /// `colorBrandStroke2Hover`.
  final Color brandStroke2Hover;

  /// `colorBrandStroke2Pressed`.
  final Color brandStroke2Pressed;

  /// `colorBrandStroke2Contrast`.
  final Color brandStroke2Contrast;

  /// `colorCompoundBrandStroke`.
  final Color compoundBrandStroke;

  /// `colorCompoundBrandStrokeHover`.
  final Color compoundBrandStrokeHover;

  /// `colorCompoundBrandStrokePressed`.
  final Color compoundBrandStrokePressed;

  /// `colorNeutralStrokeDisabled`.
  final Color neutralStrokeDisabled;

  /// `colorNeutralStrokeDisabled2`.
  final Color neutralStrokeDisabled2;

  /// `colorNeutralStrokeInvertedDisabled`.
  final Color neutralStrokeInvertedDisabled;

  /// `colorTransparentStroke`.
  final Color transparentStroke;

  /// `colorTransparentStrokeInteractive`.
  final Color transparentStrokeInteractive;

  /// `colorTransparentStrokeDisabled`.
  final Color transparentStrokeDisabled;

  /// `colorNeutralStrokeAlpha`.
  final Color neutralStrokeAlpha;

  /// `colorNeutralStrokeAlpha2`.
  final Color neutralStrokeAlpha2;

  /// `colorStrokeFocus1`.
  final Color strokeFocus1;

  /// `colorStrokeFocus2`.
  final Color strokeFocus2;

  /// `colorNeutralShadowAmbient`.
  final Color neutralShadowAmbient;

  /// `colorNeutralShadowKey`.
  final Color neutralShadowKey;

  /// `colorNeutralShadowAmbientLighter`.
  final Color neutralShadowAmbientLighter;

  /// `colorNeutralShadowKeyLighter`.
  final Color neutralShadowKeyLighter;

  /// `colorNeutralShadowAmbientDarker`.
  final Color neutralShadowAmbientDarker;

  /// `colorNeutralShadowKeyDarker`.
  final Color neutralShadowKeyDarker;

  /// `colorBrandShadowAmbient`.
  final Color brandShadowAmbient;

  /// `colorBrandShadowKey`.
  final Color brandShadowKey;

  /// `colorStatusSuccessBackground1`.
  final Color statusSuccessBackground1;

  /// `colorStatusSuccessBackground2`.
  final Color statusSuccessBackground2;

  /// `colorStatusSuccessBackground3`.
  final Color statusSuccessBackground3;

  /// `colorStatusSuccessForeground1`.
  final Color statusSuccessForeground1;

  /// `colorStatusSuccessForeground2`.
  final Color statusSuccessForeground2;

  /// `colorStatusSuccessForeground3`.
  final Color statusSuccessForeground3;

  /// `colorStatusSuccessForegroundInverted`.
  final Color statusSuccessForegroundInverted;

  /// `colorStatusSuccessBorderActive`.
  final Color statusSuccessBorderActive;

  /// `colorStatusSuccessBorder1`.
  final Color statusSuccessBorder1;

  /// `colorStatusSuccessBorder2`.
  final Color statusSuccessBorder2;

  /// `colorStatusWarningBackground1`.
  final Color statusWarningBackground1;

  /// `colorStatusWarningBackground2`.
  final Color statusWarningBackground2;

  /// `colorStatusWarningBackground3`.
  final Color statusWarningBackground3;

  /// `colorStatusWarningForeground1`.
  final Color statusWarningForeground1;

  /// `colorStatusWarningForeground2`.
  final Color statusWarningForeground2;

  /// `colorStatusWarningForeground3`.
  final Color statusWarningForeground3;

  /// `colorStatusWarningForegroundInverted`.
  final Color statusWarningForegroundInverted;

  /// `colorStatusWarningBorderActive`.
  final Color statusWarningBorderActive;

  /// `colorStatusWarningBorder1`.
  final Color statusWarningBorder1;

  /// `colorStatusWarningBorder2`.
  final Color statusWarningBorder2;

  /// `colorStatusDangerBackground1`.
  final Color statusDangerBackground1;

  /// `colorStatusDangerBackground2`.
  final Color statusDangerBackground2;

  /// `colorStatusDangerBackground3`.
  final Color statusDangerBackground3;

  /// `colorStatusDangerForeground1`.
  final Color statusDangerForeground1;

  /// `colorStatusDangerForeground2`.
  final Color statusDangerForeground2;

  /// `colorStatusDangerForeground3`.
  final Color statusDangerForeground3;

  /// `colorStatusDangerForegroundInverted`.
  final Color statusDangerForegroundInverted;

  /// `colorStatusDangerBorderActive`.
  final Color statusDangerBorderActive;

  /// `colorStatusDangerBorder1`.
  final Color statusDangerBorder1;

  /// `colorStatusDangerBorder2`.
  final Color statusDangerBorder2;

  /// `colorStatusDangerBackground3Hover`.
  final Color statusDangerBackground3Hover;

  /// `colorStatusDangerBackground3Pressed`.
  final Color statusDangerBackground3Pressed;

  /// Every colour by its field name, for a theme built from another
  /// record ([Fluent2Colors.fromMap]) and for the contrast tests.
  Map<String, Color> toMap() => {
    'neutralForeground1': neutralForeground1,
    'neutralForeground1Hover': neutralForeground1Hover,
    'neutralForeground1Pressed': neutralForeground1Pressed,
    'neutralForeground1Selected': neutralForeground1Selected,
    'neutralForeground2': neutralForeground2,
    'neutralForeground2Hover': neutralForeground2Hover,
    'neutralForeground2Pressed': neutralForeground2Pressed,
    'neutralForeground2Selected': neutralForeground2Selected,
    'neutralForeground2BrandHover': neutralForeground2BrandHover,
    'neutralForeground2BrandPressed': neutralForeground2BrandPressed,
    'neutralForeground2BrandSelected': neutralForeground2BrandSelected,
    'neutralForeground3': neutralForeground3,
    'neutralForeground3Hover': neutralForeground3Hover,
    'neutralForeground3Pressed': neutralForeground3Pressed,
    'neutralForeground3Selected': neutralForeground3Selected,
    'neutralForeground3BrandHover': neutralForeground3BrandHover,
    'neutralForeground3BrandPressed': neutralForeground3BrandPressed,
    'neutralForeground3BrandSelected': neutralForeground3BrandSelected,
    'neutralForeground4': neutralForeground4,
    'neutralForeground5': neutralForeground5,
    'neutralForeground5Hover': neutralForeground5Hover,
    'neutralForeground5Pressed': neutralForeground5Pressed,
    'neutralForeground5Selected': neutralForeground5Selected,
    'neutralForegroundDisabled': neutralForegroundDisabled,
    'neutralForegroundInvertedDisabled': neutralForegroundInvertedDisabled,
    'brandForegroundLink': brandForegroundLink,
    'brandForegroundLinkHover': brandForegroundLinkHover,
    'brandForegroundLinkPressed': brandForegroundLinkPressed,
    'brandForegroundLinkSelected': brandForegroundLinkSelected,
    'neutralForeground2Link': neutralForeground2Link,
    'neutralForeground2LinkHover': neutralForeground2LinkHover,
    'neutralForeground2LinkPressed': neutralForeground2LinkPressed,
    'neutralForeground2LinkSelected': neutralForeground2LinkSelected,
    'compoundBrandForeground1': compoundBrandForeground1,
    'compoundBrandForeground1Hover': compoundBrandForeground1Hover,
    'compoundBrandForeground1Pressed': compoundBrandForeground1Pressed,
    'brandForeground1': brandForeground1,
    'brandForeground2': brandForeground2,
    'brandForeground2Hover': brandForeground2Hover,
    'brandForeground2Pressed': brandForeground2Pressed,
    'neutralForeground1Static': neutralForeground1Static,
    'neutralForegroundStaticInverted': neutralForegroundStaticInverted,
    'neutralForegroundInverted': neutralForegroundInverted,
    'neutralForegroundInvertedHover': neutralForegroundInvertedHover,
    'neutralForegroundInvertedPressed': neutralForegroundInvertedPressed,
    'neutralForegroundInvertedSelected': neutralForegroundInvertedSelected,
    'neutralForegroundInverted2': neutralForegroundInverted2,
    'neutralForegroundOnBrand': neutralForegroundOnBrand,
    'neutralForegroundInvertedLink': neutralForegroundInvertedLink,
    'neutralForegroundInvertedLinkHover': neutralForegroundInvertedLinkHover,
    'neutralForegroundInvertedLinkPressed':
        neutralForegroundInvertedLinkPressed,
    'neutralForegroundInvertedLinkSelected':
        neutralForegroundInvertedLinkSelected,
    'brandForegroundInverted': brandForegroundInverted,
    'brandForegroundInvertedHover': brandForegroundInvertedHover,
    'brandForegroundInvertedPressed': brandForegroundInvertedPressed,
    'brandForegroundOnLight': brandForegroundOnLight,
    'brandForegroundOnLightHover': brandForegroundOnLightHover,
    'brandForegroundOnLightPressed': brandForegroundOnLightPressed,
    'brandForegroundOnLightSelected': brandForegroundOnLightSelected,
    'neutralBackground1': neutralBackground1,
    'neutralBackground1Hover': neutralBackground1Hover,
    'neutralBackground1Pressed': neutralBackground1Pressed,
    'neutralBackground1Selected': neutralBackground1Selected,
    'neutralBackground2': neutralBackground2,
    'neutralBackground2Hover': neutralBackground2Hover,
    'neutralBackground2Pressed': neutralBackground2Pressed,
    'neutralBackground2Selected': neutralBackground2Selected,
    'neutralBackground3': neutralBackground3,
    'neutralBackground3Hover': neutralBackground3Hover,
    'neutralBackground3Pressed': neutralBackground3Pressed,
    'neutralBackground3Selected': neutralBackground3Selected,
    'neutralBackground4': neutralBackground4,
    'neutralBackground4Hover': neutralBackground4Hover,
    'neutralBackground4Pressed': neutralBackground4Pressed,
    'neutralBackground4Selected': neutralBackground4Selected,
    'neutralBackground5': neutralBackground5,
    'neutralBackground5Hover': neutralBackground5Hover,
    'neutralBackground5Pressed': neutralBackground5Pressed,
    'neutralBackground5Selected': neutralBackground5Selected,
    'neutralBackground6': neutralBackground6,
    'neutralBackground7': neutralBackground7,
    'neutralBackground7Hover': neutralBackground7Hover,
    'neutralBackground7Pressed': neutralBackground7Pressed,
    'neutralBackground7Selected': neutralBackground7Selected,
    'neutralBackground8': neutralBackground8,
    'neutralBackgroundInverted': neutralBackgroundInverted,
    'neutralBackgroundInvertedHover': neutralBackgroundInvertedHover,
    'neutralBackgroundInvertedPressed': neutralBackgroundInvertedPressed,
    'neutralBackgroundInvertedSelected': neutralBackgroundInvertedSelected,
    'neutralBackgroundStatic': neutralBackgroundStatic,
    'neutralBackgroundAlpha': neutralBackgroundAlpha,
    'neutralBackgroundAlpha2': neutralBackgroundAlpha2,
    'subtleBackground': subtleBackground,
    'subtleBackgroundHover': subtleBackgroundHover,
    'subtleBackgroundPressed': subtleBackgroundPressed,
    'subtleBackgroundSelected': subtleBackgroundSelected,
    'subtleBackgroundLightAlphaHover': subtleBackgroundLightAlphaHover,
    'subtleBackgroundLightAlphaPressed': subtleBackgroundLightAlphaPressed,
    'subtleBackgroundLightAlphaSelected': subtleBackgroundLightAlphaSelected,
    'subtleBackgroundInverted': subtleBackgroundInverted,
    'subtleBackgroundInvertedHover': subtleBackgroundInvertedHover,
    'subtleBackgroundInvertedPressed': subtleBackgroundInvertedPressed,
    'subtleBackgroundInvertedSelected': subtleBackgroundInvertedSelected,
    'transparentBackground': transparentBackground,
    'transparentBackgroundHover': transparentBackgroundHover,
    'transparentBackgroundPressed': transparentBackgroundPressed,
    'transparentBackgroundSelected': transparentBackgroundSelected,
    'neutralBackgroundDisabled': neutralBackgroundDisabled,
    'neutralBackgroundDisabled2': neutralBackgroundDisabled2,
    'neutralBackgroundInvertedDisabled': neutralBackgroundInvertedDisabled,
    'neutralStencil1': neutralStencil1,
    'neutralStencil2': neutralStencil2,
    'neutralStencil1Alpha': neutralStencil1Alpha,
    'neutralStencil2Alpha': neutralStencil2Alpha,
    'backgroundOverlay': backgroundOverlay,
    'scrollbarOverlay': scrollbarOverlay,
    'brandBackground': brandBackground,
    'brandBackgroundHover': brandBackgroundHover,
    'brandBackgroundPressed': brandBackgroundPressed,
    'brandBackgroundSelected': brandBackgroundSelected,
    'compoundBrandBackground': compoundBrandBackground,
    'compoundBrandBackgroundHover': compoundBrandBackgroundHover,
    'compoundBrandBackgroundPressed': compoundBrandBackgroundPressed,
    'brandBackgroundStatic': brandBackgroundStatic,
    'brandBackground2': brandBackground2,
    'brandBackground2Hover': brandBackground2Hover,
    'brandBackground2Pressed': brandBackground2Pressed,
    'brandBackground3Static': brandBackground3Static,
    'brandBackground4Static': brandBackground4Static,
    'brandBackgroundInverted': brandBackgroundInverted,
    'brandBackgroundInvertedHover': brandBackgroundInvertedHover,
    'brandBackgroundInvertedPressed': brandBackgroundInvertedPressed,
    'brandBackgroundInvertedSelected': brandBackgroundInvertedSelected,
    'neutralCardBackground': neutralCardBackground,
    'neutralCardBackgroundHover': neutralCardBackgroundHover,
    'neutralCardBackgroundPressed': neutralCardBackgroundPressed,
    'neutralCardBackgroundSelected': neutralCardBackgroundSelected,
    'neutralCardBackgroundDisabled': neutralCardBackgroundDisabled,
    'neutralStrokeAccessible': neutralStrokeAccessible,
    'neutralStrokeAccessibleHover': neutralStrokeAccessibleHover,
    'neutralStrokeAccessiblePressed': neutralStrokeAccessiblePressed,
    'neutralStrokeAccessibleSelected': neutralStrokeAccessibleSelected,
    'neutralStroke1': neutralStroke1,
    'neutralStroke1Hover': neutralStroke1Hover,
    'neutralStroke1Pressed': neutralStroke1Pressed,
    'neutralStroke1Selected': neutralStroke1Selected,
    'neutralStroke2': neutralStroke2,
    'neutralStroke3': neutralStroke3,
    'neutralStroke4': neutralStroke4,
    'neutralStroke4Hover': neutralStroke4Hover,
    'neutralStroke4Pressed': neutralStroke4Pressed,
    'neutralStroke4Selected': neutralStroke4Selected,
    'neutralStrokeSubtle': neutralStrokeSubtle,
    'neutralStrokeOnBrand': neutralStrokeOnBrand,
    'neutralStrokeOnBrand2': neutralStrokeOnBrand2,
    'neutralStrokeOnBrand2Hover': neutralStrokeOnBrand2Hover,
    'neutralStrokeOnBrand2Pressed': neutralStrokeOnBrand2Pressed,
    'neutralStrokeOnBrand2Selected': neutralStrokeOnBrand2Selected,
    'brandStroke1': brandStroke1,
    'brandStroke2': brandStroke2,
    'brandStroke2Hover': brandStroke2Hover,
    'brandStroke2Pressed': brandStroke2Pressed,
    'brandStroke2Contrast': brandStroke2Contrast,
    'compoundBrandStroke': compoundBrandStroke,
    'compoundBrandStrokeHover': compoundBrandStrokeHover,
    'compoundBrandStrokePressed': compoundBrandStrokePressed,
    'neutralStrokeDisabled': neutralStrokeDisabled,
    'neutralStrokeDisabled2': neutralStrokeDisabled2,
    'neutralStrokeInvertedDisabled': neutralStrokeInvertedDisabled,
    'transparentStroke': transparentStroke,
    'transparentStrokeInteractive': transparentStrokeInteractive,
    'transparentStrokeDisabled': transparentStrokeDisabled,
    'neutralStrokeAlpha': neutralStrokeAlpha,
    'neutralStrokeAlpha2': neutralStrokeAlpha2,
    'strokeFocus1': strokeFocus1,
    'strokeFocus2': strokeFocus2,
    'neutralShadowAmbient': neutralShadowAmbient,
    'neutralShadowKey': neutralShadowKey,
    'neutralShadowAmbientLighter': neutralShadowAmbientLighter,
    'neutralShadowKeyLighter': neutralShadowKeyLighter,
    'neutralShadowAmbientDarker': neutralShadowAmbientDarker,
    'neutralShadowKeyDarker': neutralShadowKeyDarker,
    'brandShadowAmbient': brandShadowAmbient,
    'brandShadowKey': brandShadowKey,
    'statusSuccessBackground1': statusSuccessBackground1,
    'statusSuccessBackground2': statusSuccessBackground2,
    'statusSuccessBackground3': statusSuccessBackground3,
    'statusSuccessForeground1': statusSuccessForeground1,
    'statusSuccessForeground2': statusSuccessForeground2,
    'statusSuccessForeground3': statusSuccessForeground3,
    'statusSuccessForegroundInverted': statusSuccessForegroundInverted,
    'statusSuccessBorderActive': statusSuccessBorderActive,
    'statusSuccessBorder1': statusSuccessBorder1,
    'statusSuccessBorder2': statusSuccessBorder2,
    'statusWarningBackground1': statusWarningBackground1,
    'statusWarningBackground2': statusWarningBackground2,
    'statusWarningBackground3': statusWarningBackground3,
    'statusWarningForeground1': statusWarningForeground1,
    'statusWarningForeground2': statusWarningForeground2,
    'statusWarningForeground3': statusWarningForeground3,
    'statusWarningForegroundInverted': statusWarningForegroundInverted,
    'statusWarningBorderActive': statusWarningBorderActive,
    'statusWarningBorder1': statusWarningBorder1,
    'statusWarningBorder2': statusWarningBorder2,
    'statusDangerBackground1': statusDangerBackground1,
    'statusDangerBackground2': statusDangerBackground2,
    'statusDangerBackground3': statusDangerBackground3,
    'statusDangerForeground1': statusDangerForeground1,
    'statusDangerForeground2': statusDangerForeground2,
    'statusDangerForeground3': statusDangerForeground3,
    'statusDangerForegroundInverted': statusDangerForegroundInverted,
    'statusDangerBorderActive': statusDangerBorderActive,
    'statusDangerBorder1': statusDangerBorder1,
    'statusDangerBorder2': statusDangerBorder2,
    'statusDangerBackground3Hover': statusDangerBackground3Hover,
    'statusDangerBackground3Pressed': statusDangerBackground3Pressed,
  };

  /// The colours [map] names, every field required: an expert's escape that
  /// sets Fluent's alias tokens raw. It holds no contrast (an ink may fall
  /// below 4.5:1 on its ground, a stroke below 3:1) and keeps no brand ramp
  /// in step; `Fluent2ThemeData.from(brand:)` builds a brand's colours with
  /// contrast held, and is the way to rebrand.
  factory Fluent2Colors.fromMap(Map<String, Color> map) => Fluent2Colors(
    neutralForeground1: map['neutralForeground1']!,
    neutralForeground1Hover: map['neutralForeground1Hover']!,
    neutralForeground1Pressed: map['neutralForeground1Pressed']!,
    neutralForeground1Selected: map['neutralForeground1Selected']!,
    neutralForeground2: map['neutralForeground2']!,
    neutralForeground2Hover: map['neutralForeground2Hover']!,
    neutralForeground2Pressed: map['neutralForeground2Pressed']!,
    neutralForeground2Selected: map['neutralForeground2Selected']!,
    neutralForeground2BrandHover: map['neutralForeground2BrandHover']!,
    neutralForeground2BrandPressed: map['neutralForeground2BrandPressed']!,
    neutralForeground2BrandSelected: map['neutralForeground2BrandSelected']!,
    neutralForeground3: map['neutralForeground3']!,
    neutralForeground3Hover: map['neutralForeground3Hover']!,
    neutralForeground3Pressed: map['neutralForeground3Pressed']!,
    neutralForeground3Selected: map['neutralForeground3Selected']!,
    neutralForeground3BrandHover: map['neutralForeground3BrandHover']!,
    neutralForeground3BrandPressed: map['neutralForeground3BrandPressed']!,
    neutralForeground3BrandSelected: map['neutralForeground3BrandSelected']!,
    neutralForeground4: map['neutralForeground4']!,
    neutralForeground5: map['neutralForeground5']!,
    neutralForeground5Hover: map['neutralForeground5Hover']!,
    neutralForeground5Pressed: map['neutralForeground5Pressed']!,
    neutralForeground5Selected: map['neutralForeground5Selected']!,
    neutralForegroundDisabled: map['neutralForegroundDisabled']!,
    neutralForegroundInvertedDisabled:
        map['neutralForegroundInvertedDisabled']!,
    brandForegroundLink: map['brandForegroundLink']!,
    brandForegroundLinkHover: map['brandForegroundLinkHover']!,
    brandForegroundLinkPressed: map['brandForegroundLinkPressed']!,
    brandForegroundLinkSelected: map['brandForegroundLinkSelected']!,
    neutralForeground2Link: map['neutralForeground2Link']!,
    neutralForeground2LinkHover: map['neutralForeground2LinkHover']!,
    neutralForeground2LinkPressed: map['neutralForeground2LinkPressed']!,
    neutralForeground2LinkSelected: map['neutralForeground2LinkSelected']!,
    compoundBrandForeground1: map['compoundBrandForeground1']!,
    compoundBrandForeground1Hover: map['compoundBrandForeground1Hover']!,
    compoundBrandForeground1Pressed: map['compoundBrandForeground1Pressed']!,
    brandForeground1: map['brandForeground1']!,
    brandForeground2: map['brandForeground2']!,
    brandForeground2Hover: map['brandForeground2Hover']!,
    brandForeground2Pressed: map['brandForeground2Pressed']!,
    neutralForeground1Static: map['neutralForeground1Static']!,
    neutralForegroundStaticInverted: map['neutralForegroundStaticInverted']!,
    neutralForegroundInverted: map['neutralForegroundInverted']!,
    neutralForegroundInvertedHover: map['neutralForegroundInvertedHover']!,
    neutralForegroundInvertedPressed: map['neutralForegroundInvertedPressed']!,
    neutralForegroundInvertedSelected:
        map['neutralForegroundInvertedSelected']!,
    neutralForegroundInverted2: map['neutralForegroundInverted2']!,
    neutralForegroundOnBrand: map['neutralForegroundOnBrand']!,
    neutralForegroundInvertedLink: map['neutralForegroundInvertedLink']!,
    neutralForegroundInvertedLinkHover:
        map['neutralForegroundInvertedLinkHover']!,
    neutralForegroundInvertedLinkPressed:
        map['neutralForegroundInvertedLinkPressed']!,
    neutralForegroundInvertedLinkSelected:
        map['neutralForegroundInvertedLinkSelected']!,
    brandForegroundInverted: map['brandForegroundInverted']!,
    brandForegroundInvertedHover: map['brandForegroundInvertedHover']!,
    brandForegroundInvertedPressed: map['brandForegroundInvertedPressed']!,
    brandForegroundOnLight: map['brandForegroundOnLight']!,
    brandForegroundOnLightHover: map['brandForegroundOnLightHover']!,
    brandForegroundOnLightPressed: map['brandForegroundOnLightPressed']!,
    brandForegroundOnLightSelected: map['brandForegroundOnLightSelected']!,
    neutralBackground1: map['neutralBackground1']!,
    neutralBackground1Hover: map['neutralBackground1Hover']!,
    neutralBackground1Pressed: map['neutralBackground1Pressed']!,
    neutralBackground1Selected: map['neutralBackground1Selected']!,
    neutralBackground2: map['neutralBackground2']!,
    neutralBackground2Hover: map['neutralBackground2Hover']!,
    neutralBackground2Pressed: map['neutralBackground2Pressed']!,
    neutralBackground2Selected: map['neutralBackground2Selected']!,
    neutralBackground3: map['neutralBackground3']!,
    neutralBackground3Hover: map['neutralBackground3Hover']!,
    neutralBackground3Pressed: map['neutralBackground3Pressed']!,
    neutralBackground3Selected: map['neutralBackground3Selected']!,
    neutralBackground4: map['neutralBackground4']!,
    neutralBackground4Hover: map['neutralBackground4Hover']!,
    neutralBackground4Pressed: map['neutralBackground4Pressed']!,
    neutralBackground4Selected: map['neutralBackground4Selected']!,
    neutralBackground5: map['neutralBackground5']!,
    neutralBackground5Hover: map['neutralBackground5Hover']!,
    neutralBackground5Pressed: map['neutralBackground5Pressed']!,
    neutralBackground5Selected: map['neutralBackground5Selected']!,
    neutralBackground6: map['neutralBackground6']!,
    neutralBackground7: map['neutralBackground7']!,
    neutralBackground7Hover: map['neutralBackground7Hover']!,
    neutralBackground7Pressed: map['neutralBackground7Pressed']!,
    neutralBackground7Selected: map['neutralBackground7Selected']!,
    neutralBackground8: map['neutralBackground8']!,
    neutralBackgroundInverted: map['neutralBackgroundInverted']!,
    neutralBackgroundInvertedHover: map['neutralBackgroundInvertedHover']!,
    neutralBackgroundInvertedPressed: map['neutralBackgroundInvertedPressed']!,
    neutralBackgroundInvertedSelected:
        map['neutralBackgroundInvertedSelected']!,
    neutralBackgroundStatic: map['neutralBackgroundStatic']!,
    neutralBackgroundAlpha: map['neutralBackgroundAlpha']!,
    neutralBackgroundAlpha2: map['neutralBackgroundAlpha2']!,
    subtleBackground: map['subtleBackground']!,
    subtleBackgroundHover: map['subtleBackgroundHover']!,
    subtleBackgroundPressed: map['subtleBackgroundPressed']!,
    subtleBackgroundSelected: map['subtleBackgroundSelected']!,
    subtleBackgroundLightAlphaHover: map['subtleBackgroundLightAlphaHover']!,
    subtleBackgroundLightAlphaPressed:
        map['subtleBackgroundLightAlphaPressed']!,
    subtleBackgroundLightAlphaSelected:
        map['subtleBackgroundLightAlphaSelected']!,
    subtleBackgroundInverted: map['subtleBackgroundInverted']!,
    subtleBackgroundInvertedHover: map['subtleBackgroundInvertedHover']!,
    subtleBackgroundInvertedPressed: map['subtleBackgroundInvertedPressed']!,
    subtleBackgroundInvertedSelected: map['subtleBackgroundInvertedSelected']!,
    transparentBackground: map['transparentBackground']!,
    transparentBackgroundHover: map['transparentBackgroundHover']!,
    transparentBackgroundPressed: map['transparentBackgroundPressed']!,
    transparentBackgroundSelected: map['transparentBackgroundSelected']!,
    neutralBackgroundDisabled: map['neutralBackgroundDisabled']!,
    neutralBackgroundDisabled2: map['neutralBackgroundDisabled2']!,
    neutralBackgroundInvertedDisabled:
        map['neutralBackgroundInvertedDisabled']!,
    neutralStencil1: map['neutralStencil1']!,
    neutralStencil2: map['neutralStencil2']!,
    neutralStencil1Alpha: map['neutralStencil1Alpha']!,
    neutralStencil2Alpha: map['neutralStencil2Alpha']!,
    backgroundOverlay: map['backgroundOverlay']!,
    scrollbarOverlay: map['scrollbarOverlay']!,
    brandBackground: map['brandBackground']!,
    brandBackgroundHover: map['brandBackgroundHover']!,
    brandBackgroundPressed: map['brandBackgroundPressed']!,
    brandBackgroundSelected: map['brandBackgroundSelected']!,
    compoundBrandBackground: map['compoundBrandBackground']!,
    compoundBrandBackgroundHover: map['compoundBrandBackgroundHover']!,
    compoundBrandBackgroundPressed: map['compoundBrandBackgroundPressed']!,
    brandBackgroundStatic: map['brandBackgroundStatic']!,
    brandBackground2: map['brandBackground2']!,
    brandBackground2Hover: map['brandBackground2Hover']!,
    brandBackground2Pressed: map['brandBackground2Pressed']!,
    brandBackground3Static: map['brandBackground3Static']!,
    brandBackground4Static: map['brandBackground4Static']!,
    brandBackgroundInverted: map['brandBackgroundInverted']!,
    brandBackgroundInvertedHover: map['brandBackgroundInvertedHover']!,
    brandBackgroundInvertedPressed: map['brandBackgroundInvertedPressed']!,
    brandBackgroundInvertedSelected: map['brandBackgroundInvertedSelected']!,
    neutralCardBackground: map['neutralCardBackground']!,
    neutralCardBackgroundHover: map['neutralCardBackgroundHover']!,
    neutralCardBackgroundPressed: map['neutralCardBackgroundPressed']!,
    neutralCardBackgroundSelected: map['neutralCardBackgroundSelected']!,
    neutralCardBackgroundDisabled: map['neutralCardBackgroundDisabled']!,
    neutralStrokeAccessible: map['neutralStrokeAccessible']!,
    neutralStrokeAccessibleHover: map['neutralStrokeAccessibleHover']!,
    neutralStrokeAccessiblePressed: map['neutralStrokeAccessiblePressed']!,
    neutralStrokeAccessibleSelected: map['neutralStrokeAccessibleSelected']!,
    neutralStroke1: map['neutralStroke1']!,
    neutralStroke1Hover: map['neutralStroke1Hover']!,
    neutralStroke1Pressed: map['neutralStroke1Pressed']!,
    neutralStroke1Selected: map['neutralStroke1Selected']!,
    neutralStroke2: map['neutralStroke2']!,
    neutralStroke3: map['neutralStroke3']!,
    neutralStroke4: map['neutralStroke4']!,
    neutralStroke4Hover: map['neutralStroke4Hover']!,
    neutralStroke4Pressed: map['neutralStroke4Pressed']!,
    neutralStroke4Selected: map['neutralStroke4Selected']!,
    neutralStrokeSubtle: map['neutralStrokeSubtle']!,
    neutralStrokeOnBrand: map['neutralStrokeOnBrand']!,
    neutralStrokeOnBrand2: map['neutralStrokeOnBrand2']!,
    neutralStrokeOnBrand2Hover: map['neutralStrokeOnBrand2Hover']!,
    neutralStrokeOnBrand2Pressed: map['neutralStrokeOnBrand2Pressed']!,
    neutralStrokeOnBrand2Selected: map['neutralStrokeOnBrand2Selected']!,
    brandStroke1: map['brandStroke1']!,
    brandStroke2: map['brandStroke2']!,
    brandStroke2Hover: map['brandStroke2Hover']!,
    brandStroke2Pressed: map['brandStroke2Pressed']!,
    brandStroke2Contrast: map['brandStroke2Contrast']!,
    compoundBrandStroke: map['compoundBrandStroke']!,
    compoundBrandStrokeHover: map['compoundBrandStrokeHover']!,
    compoundBrandStrokePressed: map['compoundBrandStrokePressed']!,
    neutralStrokeDisabled: map['neutralStrokeDisabled']!,
    neutralStrokeDisabled2: map['neutralStrokeDisabled2']!,
    neutralStrokeInvertedDisabled: map['neutralStrokeInvertedDisabled']!,
    transparentStroke: map['transparentStroke']!,
    transparentStrokeInteractive: map['transparentStrokeInteractive']!,
    transparentStrokeDisabled: map['transparentStrokeDisabled']!,
    neutralStrokeAlpha: map['neutralStrokeAlpha']!,
    neutralStrokeAlpha2: map['neutralStrokeAlpha2']!,
    strokeFocus1: map['strokeFocus1']!,
    strokeFocus2: map['strokeFocus2']!,
    neutralShadowAmbient: map['neutralShadowAmbient']!,
    neutralShadowKey: map['neutralShadowKey']!,
    neutralShadowAmbientLighter: map['neutralShadowAmbientLighter']!,
    neutralShadowKeyLighter: map['neutralShadowKeyLighter']!,
    neutralShadowAmbientDarker: map['neutralShadowAmbientDarker']!,
    neutralShadowKeyDarker: map['neutralShadowKeyDarker']!,
    brandShadowAmbient: map['brandShadowAmbient']!,
    brandShadowKey: map['brandShadowKey']!,
    statusSuccessBackground1: map['statusSuccessBackground1']!,
    statusSuccessBackground2: map['statusSuccessBackground2']!,
    statusSuccessBackground3: map['statusSuccessBackground3']!,
    statusSuccessForeground1: map['statusSuccessForeground1']!,
    statusSuccessForeground2: map['statusSuccessForeground2']!,
    statusSuccessForeground3: map['statusSuccessForeground3']!,
    statusSuccessForegroundInverted: map['statusSuccessForegroundInverted']!,
    statusSuccessBorderActive: map['statusSuccessBorderActive']!,
    statusSuccessBorder1: map['statusSuccessBorder1']!,
    statusSuccessBorder2: map['statusSuccessBorder2']!,
    statusWarningBackground1: map['statusWarningBackground1']!,
    statusWarningBackground2: map['statusWarningBackground2']!,
    statusWarningBackground3: map['statusWarningBackground3']!,
    statusWarningForeground1: map['statusWarningForeground1']!,
    statusWarningForeground2: map['statusWarningForeground2']!,
    statusWarningForeground3: map['statusWarningForeground3']!,
    statusWarningForegroundInverted: map['statusWarningForegroundInverted']!,
    statusWarningBorderActive: map['statusWarningBorderActive']!,
    statusWarningBorder1: map['statusWarningBorder1']!,
    statusWarningBorder2: map['statusWarningBorder2']!,
    statusDangerBackground1: map['statusDangerBackground1']!,
    statusDangerBackground2: map['statusDangerBackground2']!,
    statusDangerBackground3: map['statusDangerBackground3']!,
    statusDangerForeground1: map['statusDangerForeground1']!,
    statusDangerForeground2: map['statusDangerForeground2']!,
    statusDangerForeground3: map['statusDangerForeground3']!,
    statusDangerForegroundInverted: map['statusDangerForegroundInverted']!,
    statusDangerBorderActive: map['statusDangerBorderActive']!,
    statusDangerBorder1: map['statusDangerBorder1']!,
    statusDangerBorder2: map['statusDangerBorder2']!,
    statusDangerBackground3Hover: map['statusDangerBackground3Hover']!,
    statusDangerBackground3Pressed: map['statusDangerBackground3Pressed']!,
  );

  /// Each colour of [a] blended toward [b]'s at [t], as `ColorScheme.lerp` blends
  /// Material's.
  static Fluent2Colors lerp(Fluent2Colors a, Fluent2Colors b, double t) {
    if (identical(a, b)) return a;
    return Fluent2Colors(
      neutralForeground1: Color.lerp(
        a.neutralForeground1,
        b.neutralForeground1,
        t,
      )!,
      neutralForeground1Hover: Color.lerp(
        a.neutralForeground1Hover,
        b.neutralForeground1Hover,
        t,
      )!,
      neutralForeground1Pressed: Color.lerp(
        a.neutralForeground1Pressed,
        b.neutralForeground1Pressed,
        t,
      )!,
      neutralForeground1Selected: Color.lerp(
        a.neutralForeground1Selected,
        b.neutralForeground1Selected,
        t,
      )!,
      neutralForeground2: Color.lerp(
        a.neutralForeground2,
        b.neutralForeground2,
        t,
      )!,
      neutralForeground2Hover: Color.lerp(
        a.neutralForeground2Hover,
        b.neutralForeground2Hover,
        t,
      )!,
      neutralForeground2Pressed: Color.lerp(
        a.neutralForeground2Pressed,
        b.neutralForeground2Pressed,
        t,
      )!,
      neutralForeground2Selected: Color.lerp(
        a.neutralForeground2Selected,
        b.neutralForeground2Selected,
        t,
      )!,
      neutralForeground2BrandHover: Color.lerp(
        a.neutralForeground2BrandHover,
        b.neutralForeground2BrandHover,
        t,
      )!,
      neutralForeground2BrandPressed: Color.lerp(
        a.neutralForeground2BrandPressed,
        b.neutralForeground2BrandPressed,
        t,
      )!,
      neutralForeground2BrandSelected: Color.lerp(
        a.neutralForeground2BrandSelected,
        b.neutralForeground2BrandSelected,
        t,
      )!,
      neutralForeground3: Color.lerp(
        a.neutralForeground3,
        b.neutralForeground3,
        t,
      )!,
      neutralForeground3Hover: Color.lerp(
        a.neutralForeground3Hover,
        b.neutralForeground3Hover,
        t,
      )!,
      neutralForeground3Pressed: Color.lerp(
        a.neutralForeground3Pressed,
        b.neutralForeground3Pressed,
        t,
      )!,
      neutralForeground3Selected: Color.lerp(
        a.neutralForeground3Selected,
        b.neutralForeground3Selected,
        t,
      )!,
      neutralForeground3BrandHover: Color.lerp(
        a.neutralForeground3BrandHover,
        b.neutralForeground3BrandHover,
        t,
      )!,
      neutralForeground3BrandPressed: Color.lerp(
        a.neutralForeground3BrandPressed,
        b.neutralForeground3BrandPressed,
        t,
      )!,
      neutralForeground3BrandSelected: Color.lerp(
        a.neutralForeground3BrandSelected,
        b.neutralForeground3BrandSelected,
        t,
      )!,
      neutralForeground4: Color.lerp(
        a.neutralForeground4,
        b.neutralForeground4,
        t,
      )!,
      neutralForeground5: Color.lerp(
        a.neutralForeground5,
        b.neutralForeground5,
        t,
      )!,
      neutralForeground5Hover: Color.lerp(
        a.neutralForeground5Hover,
        b.neutralForeground5Hover,
        t,
      )!,
      neutralForeground5Pressed: Color.lerp(
        a.neutralForeground5Pressed,
        b.neutralForeground5Pressed,
        t,
      )!,
      neutralForeground5Selected: Color.lerp(
        a.neutralForeground5Selected,
        b.neutralForeground5Selected,
        t,
      )!,
      neutralForegroundDisabled: Color.lerp(
        a.neutralForegroundDisabled,
        b.neutralForegroundDisabled,
        t,
      )!,
      neutralForegroundInvertedDisabled: Color.lerp(
        a.neutralForegroundInvertedDisabled,
        b.neutralForegroundInvertedDisabled,
        t,
      )!,
      brandForegroundLink: Color.lerp(
        a.brandForegroundLink,
        b.brandForegroundLink,
        t,
      )!,
      brandForegroundLinkHover: Color.lerp(
        a.brandForegroundLinkHover,
        b.brandForegroundLinkHover,
        t,
      )!,
      brandForegroundLinkPressed: Color.lerp(
        a.brandForegroundLinkPressed,
        b.brandForegroundLinkPressed,
        t,
      )!,
      brandForegroundLinkSelected: Color.lerp(
        a.brandForegroundLinkSelected,
        b.brandForegroundLinkSelected,
        t,
      )!,
      neutralForeground2Link: Color.lerp(
        a.neutralForeground2Link,
        b.neutralForeground2Link,
        t,
      )!,
      neutralForeground2LinkHover: Color.lerp(
        a.neutralForeground2LinkHover,
        b.neutralForeground2LinkHover,
        t,
      )!,
      neutralForeground2LinkPressed: Color.lerp(
        a.neutralForeground2LinkPressed,
        b.neutralForeground2LinkPressed,
        t,
      )!,
      neutralForeground2LinkSelected: Color.lerp(
        a.neutralForeground2LinkSelected,
        b.neutralForeground2LinkSelected,
        t,
      )!,
      compoundBrandForeground1: Color.lerp(
        a.compoundBrandForeground1,
        b.compoundBrandForeground1,
        t,
      )!,
      compoundBrandForeground1Hover: Color.lerp(
        a.compoundBrandForeground1Hover,
        b.compoundBrandForeground1Hover,
        t,
      )!,
      compoundBrandForeground1Pressed: Color.lerp(
        a.compoundBrandForeground1Pressed,
        b.compoundBrandForeground1Pressed,
        t,
      )!,
      brandForeground1: Color.lerp(a.brandForeground1, b.brandForeground1, t)!,
      brandForeground2: Color.lerp(a.brandForeground2, b.brandForeground2, t)!,
      brandForeground2Hover: Color.lerp(
        a.brandForeground2Hover,
        b.brandForeground2Hover,
        t,
      )!,
      brandForeground2Pressed: Color.lerp(
        a.brandForeground2Pressed,
        b.brandForeground2Pressed,
        t,
      )!,
      neutralForeground1Static: Color.lerp(
        a.neutralForeground1Static,
        b.neutralForeground1Static,
        t,
      )!,
      neutralForegroundStaticInverted: Color.lerp(
        a.neutralForegroundStaticInverted,
        b.neutralForegroundStaticInverted,
        t,
      )!,
      neutralForegroundInverted: Color.lerp(
        a.neutralForegroundInverted,
        b.neutralForegroundInverted,
        t,
      )!,
      neutralForegroundInvertedHover: Color.lerp(
        a.neutralForegroundInvertedHover,
        b.neutralForegroundInvertedHover,
        t,
      )!,
      neutralForegroundInvertedPressed: Color.lerp(
        a.neutralForegroundInvertedPressed,
        b.neutralForegroundInvertedPressed,
        t,
      )!,
      neutralForegroundInvertedSelected: Color.lerp(
        a.neutralForegroundInvertedSelected,
        b.neutralForegroundInvertedSelected,
        t,
      )!,
      neutralForegroundInverted2: Color.lerp(
        a.neutralForegroundInverted2,
        b.neutralForegroundInverted2,
        t,
      )!,
      neutralForegroundOnBrand: Color.lerp(
        a.neutralForegroundOnBrand,
        b.neutralForegroundOnBrand,
        t,
      )!,
      neutralForegroundInvertedLink: Color.lerp(
        a.neutralForegroundInvertedLink,
        b.neutralForegroundInvertedLink,
        t,
      )!,
      neutralForegroundInvertedLinkHover: Color.lerp(
        a.neutralForegroundInvertedLinkHover,
        b.neutralForegroundInvertedLinkHover,
        t,
      )!,
      neutralForegroundInvertedLinkPressed: Color.lerp(
        a.neutralForegroundInvertedLinkPressed,
        b.neutralForegroundInvertedLinkPressed,
        t,
      )!,
      neutralForegroundInvertedLinkSelected: Color.lerp(
        a.neutralForegroundInvertedLinkSelected,
        b.neutralForegroundInvertedLinkSelected,
        t,
      )!,
      brandForegroundInverted: Color.lerp(
        a.brandForegroundInverted,
        b.brandForegroundInverted,
        t,
      )!,
      brandForegroundInvertedHover: Color.lerp(
        a.brandForegroundInvertedHover,
        b.brandForegroundInvertedHover,
        t,
      )!,
      brandForegroundInvertedPressed: Color.lerp(
        a.brandForegroundInvertedPressed,
        b.brandForegroundInvertedPressed,
        t,
      )!,
      brandForegroundOnLight: Color.lerp(
        a.brandForegroundOnLight,
        b.brandForegroundOnLight,
        t,
      )!,
      brandForegroundOnLightHover: Color.lerp(
        a.brandForegroundOnLightHover,
        b.brandForegroundOnLightHover,
        t,
      )!,
      brandForegroundOnLightPressed: Color.lerp(
        a.brandForegroundOnLightPressed,
        b.brandForegroundOnLightPressed,
        t,
      )!,
      brandForegroundOnLightSelected: Color.lerp(
        a.brandForegroundOnLightSelected,
        b.brandForegroundOnLightSelected,
        t,
      )!,
      neutralBackground1: Color.lerp(
        a.neutralBackground1,
        b.neutralBackground1,
        t,
      )!,
      neutralBackground1Hover: Color.lerp(
        a.neutralBackground1Hover,
        b.neutralBackground1Hover,
        t,
      )!,
      neutralBackground1Pressed: Color.lerp(
        a.neutralBackground1Pressed,
        b.neutralBackground1Pressed,
        t,
      )!,
      neutralBackground1Selected: Color.lerp(
        a.neutralBackground1Selected,
        b.neutralBackground1Selected,
        t,
      )!,
      neutralBackground2: Color.lerp(
        a.neutralBackground2,
        b.neutralBackground2,
        t,
      )!,
      neutralBackground2Hover: Color.lerp(
        a.neutralBackground2Hover,
        b.neutralBackground2Hover,
        t,
      )!,
      neutralBackground2Pressed: Color.lerp(
        a.neutralBackground2Pressed,
        b.neutralBackground2Pressed,
        t,
      )!,
      neutralBackground2Selected: Color.lerp(
        a.neutralBackground2Selected,
        b.neutralBackground2Selected,
        t,
      )!,
      neutralBackground3: Color.lerp(
        a.neutralBackground3,
        b.neutralBackground3,
        t,
      )!,
      neutralBackground3Hover: Color.lerp(
        a.neutralBackground3Hover,
        b.neutralBackground3Hover,
        t,
      )!,
      neutralBackground3Pressed: Color.lerp(
        a.neutralBackground3Pressed,
        b.neutralBackground3Pressed,
        t,
      )!,
      neutralBackground3Selected: Color.lerp(
        a.neutralBackground3Selected,
        b.neutralBackground3Selected,
        t,
      )!,
      neutralBackground4: Color.lerp(
        a.neutralBackground4,
        b.neutralBackground4,
        t,
      )!,
      neutralBackground4Hover: Color.lerp(
        a.neutralBackground4Hover,
        b.neutralBackground4Hover,
        t,
      )!,
      neutralBackground4Pressed: Color.lerp(
        a.neutralBackground4Pressed,
        b.neutralBackground4Pressed,
        t,
      )!,
      neutralBackground4Selected: Color.lerp(
        a.neutralBackground4Selected,
        b.neutralBackground4Selected,
        t,
      )!,
      neutralBackground5: Color.lerp(
        a.neutralBackground5,
        b.neutralBackground5,
        t,
      )!,
      neutralBackground5Hover: Color.lerp(
        a.neutralBackground5Hover,
        b.neutralBackground5Hover,
        t,
      )!,
      neutralBackground5Pressed: Color.lerp(
        a.neutralBackground5Pressed,
        b.neutralBackground5Pressed,
        t,
      )!,
      neutralBackground5Selected: Color.lerp(
        a.neutralBackground5Selected,
        b.neutralBackground5Selected,
        t,
      )!,
      neutralBackground6: Color.lerp(
        a.neutralBackground6,
        b.neutralBackground6,
        t,
      )!,
      neutralBackground7: Color.lerp(
        a.neutralBackground7,
        b.neutralBackground7,
        t,
      )!,
      neutralBackground7Hover: Color.lerp(
        a.neutralBackground7Hover,
        b.neutralBackground7Hover,
        t,
      )!,
      neutralBackground7Pressed: Color.lerp(
        a.neutralBackground7Pressed,
        b.neutralBackground7Pressed,
        t,
      )!,
      neutralBackground7Selected: Color.lerp(
        a.neutralBackground7Selected,
        b.neutralBackground7Selected,
        t,
      )!,
      neutralBackground8: Color.lerp(
        a.neutralBackground8,
        b.neutralBackground8,
        t,
      )!,
      neutralBackgroundInverted: Color.lerp(
        a.neutralBackgroundInverted,
        b.neutralBackgroundInverted,
        t,
      )!,
      neutralBackgroundInvertedHover: Color.lerp(
        a.neutralBackgroundInvertedHover,
        b.neutralBackgroundInvertedHover,
        t,
      )!,
      neutralBackgroundInvertedPressed: Color.lerp(
        a.neutralBackgroundInvertedPressed,
        b.neutralBackgroundInvertedPressed,
        t,
      )!,
      neutralBackgroundInvertedSelected: Color.lerp(
        a.neutralBackgroundInvertedSelected,
        b.neutralBackgroundInvertedSelected,
        t,
      )!,
      neutralBackgroundStatic: Color.lerp(
        a.neutralBackgroundStatic,
        b.neutralBackgroundStatic,
        t,
      )!,
      neutralBackgroundAlpha: Color.lerp(
        a.neutralBackgroundAlpha,
        b.neutralBackgroundAlpha,
        t,
      )!,
      neutralBackgroundAlpha2: Color.lerp(
        a.neutralBackgroundAlpha2,
        b.neutralBackgroundAlpha2,
        t,
      )!,
      subtleBackground: Color.lerp(a.subtleBackground, b.subtleBackground, t)!,
      subtleBackgroundHover: Color.lerp(
        a.subtleBackgroundHover,
        b.subtleBackgroundHover,
        t,
      )!,
      subtleBackgroundPressed: Color.lerp(
        a.subtleBackgroundPressed,
        b.subtleBackgroundPressed,
        t,
      )!,
      subtleBackgroundSelected: Color.lerp(
        a.subtleBackgroundSelected,
        b.subtleBackgroundSelected,
        t,
      )!,
      subtleBackgroundLightAlphaHover: Color.lerp(
        a.subtleBackgroundLightAlphaHover,
        b.subtleBackgroundLightAlphaHover,
        t,
      )!,
      subtleBackgroundLightAlphaPressed: Color.lerp(
        a.subtleBackgroundLightAlphaPressed,
        b.subtleBackgroundLightAlphaPressed,
        t,
      )!,
      subtleBackgroundLightAlphaSelected: Color.lerp(
        a.subtleBackgroundLightAlphaSelected,
        b.subtleBackgroundLightAlphaSelected,
        t,
      )!,
      subtleBackgroundInverted: Color.lerp(
        a.subtleBackgroundInverted,
        b.subtleBackgroundInverted,
        t,
      )!,
      subtleBackgroundInvertedHover: Color.lerp(
        a.subtleBackgroundInvertedHover,
        b.subtleBackgroundInvertedHover,
        t,
      )!,
      subtleBackgroundInvertedPressed: Color.lerp(
        a.subtleBackgroundInvertedPressed,
        b.subtleBackgroundInvertedPressed,
        t,
      )!,
      subtleBackgroundInvertedSelected: Color.lerp(
        a.subtleBackgroundInvertedSelected,
        b.subtleBackgroundInvertedSelected,
        t,
      )!,
      transparentBackground: Color.lerp(
        a.transparentBackground,
        b.transparentBackground,
        t,
      )!,
      transparentBackgroundHover: Color.lerp(
        a.transparentBackgroundHover,
        b.transparentBackgroundHover,
        t,
      )!,
      transparentBackgroundPressed: Color.lerp(
        a.transparentBackgroundPressed,
        b.transparentBackgroundPressed,
        t,
      )!,
      transparentBackgroundSelected: Color.lerp(
        a.transparentBackgroundSelected,
        b.transparentBackgroundSelected,
        t,
      )!,
      neutralBackgroundDisabled: Color.lerp(
        a.neutralBackgroundDisabled,
        b.neutralBackgroundDisabled,
        t,
      )!,
      neutralBackgroundDisabled2: Color.lerp(
        a.neutralBackgroundDisabled2,
        b.neutralBackgroundDisabled2,
        t,
      )!,
      neutralBackgroundInvertedDisabled: Color.lerp(
        a.neutralBackgroundInvertedDisabled,
        b.neutralBackgroundInvertedDisabled,
        t,
      )!,
      neutralStencil1: Color.lerp(a.neutralStencil1, b.neutralStencil1, t)!,
      neutralStencil2: Color.lerp(a.neutralStencil2, b.neutralStencil2, t)!,
      neutralStencil1Alpha: Color.lerp(
        a.neutralStencil1Alpha,
        b.neutralStencil1Alpha,
        t,
      )!,
      neutralStencil2Alpha: Color.lerp(
        a.neutralStencil2Alpha,
        b.neutralStencil2Alpha,
        t,
      )!,
      backgroundOverlay: Color.lerp(
        a.backgroundOverlay,
        b.backgroundOverlay,
        t,
      )!,
      scrollbarOverlay: Color.lerp(a.scrollbarOverlay, b.scrollbarOverlay, t)!,
      brandBackground: Color.lerp(a.brandBackground, b.brandBackground, t)!,
      brandBackgroundHover: Color.lerp(
        a.brandBackgroundHover,
        b.brandBackgroundHover,
        t,
      )!,
      brandBackgroundPressed: Color.lerp(
        a.brandBackgroundPressed,
        b.brandBackgroundPressed,
        t,
      )!,
      brandBackgroundSelected: Color.lerp(
        a.brandBackgroundSelected,
        b.brandBackgroundSelected,
        t,
      )!,
      compoundBrandBackground: Color.lerp(
        a.compoundBrandBackground,
        b.compoundBrandBackground,
        t,
      )!,
      compoundBrandBackgroundHover: Color.lerp(
        a.compoundBrandBackgroundHover,
        b.compoundBrandBackgroundHover,
        t,
      )!,
      compoundBrandBackgroundPressed: Color.lerp(
        a.compoundBrandBackgroundPressed,
        b.compoundBrandBackgroundPressed,
        t,
      )!,
      brandBackgroundStatic: Color.lerp(
        a.brandBackgroundStatic,
        b.brandBackgroundStatic,
        t,
      )!,
      brandBackground2: Color.lerp(a.brandBackground2, b.brandBackground2, t)!,
      brandBackground2Hover: Color.lerp(
        a.brandBackground2Hover,
        b.brandBackground2Hover,
        t,
      )!,
      brandBackground2Pressed: Color.lerp(
        a.brandBackground2Pressed,
        b.brandBackground2Pressed,
        t,
      )!,
      brandBackground3Static: Color.lerp(
        a.brandBackground3Static,
        b.brandBackground3Static,
        t,
      )!,
      brandBackground4Static: Color.lerp(
        a.brandBackground4Static,
        b.brandBackground4Static,
        t,
      )!,
      brandBackgroundInverted: Color.lerp(
        a.brandBackgroundInverted,
        b.brandBackgroundInverted,
        t,
      )!,
      brandBackgroundInvertedHover: Color.lerp(
        a.brandBackgroundInvertedHover,
        b.brandBackgroundInvertedHover,
        t,
      )!,
      brandBackgroundInvertedPressed: Color.lerp(
        a.brandBackgroundInvertedPressed,
        b.brandBackgroundInvertedPressed,
        t,
      )!,
      brandBackgroundInvertedSelected: Color.lerp(
        a.brandBackgroundInvertedSelected,
        b.brandBackgroundInvertedSelected,
        t,
      )!,
      neutralCardBackground: Color.lerp(
        a.neutralCardBackground,
        b.neutralCardBackground,
        t,
      )!,
      neutralCardBackgroundHover: Color.lerp(
        a.neutralCardBackgroundHover,
        b.neutralCardBackgroundHover,
        t,
      )!,
      neutralCardBackgroundPressed: Color.lerp(
        a.neutralCardBackgroundPressed,
        b.neutralCardBackgroundPressed,
        t,
      )!,
      neutralCardBackgroundSelected: Color.lerp(
        a.neutralCardBackgroundSelected,
        b.neutralCardBackgroundSelected,
        t,
      )!,
      neutralCardBackgroundDisabled: Color.lerp(
        a.neutralCardBackgroundDisabled,
        b.neutralCardBackgroundDisabled,
        t,
      )!,
      neutralStrokeAccessible: Color.lerp(
        a.neutralStrokeAccessible,
        b.neutralStrokeAccessible,
        t,
      )!,
      neutralStrokeAccessibleHover: Color.lerp(
        a.neutralStrokeAccessibleHover,
        b.neutralStrokeAccessibleHover,
        t,
      )!,
      neutralStrokeAccessiblePressed: Color.lerp(
        a.neutralStrokeAccessiblePressed,
        b.neutralStrokeAccessiblePressed,
        t,
      )!,
      neutralStrokeAccessibleSelected: Color.lerp(
        a.neutralStrokeAccessibleSelected,
        b.neutralStrokeAccessibleSelected,
        t,
      )!,
      neutralStroke1: Color.lerp(a.neutralStroke1, b.neutralStroke1, t)!,
      neutralStroke1Hover: Color.lerp(
        a.neutralStroke1Hover,
        b.neutralStroke1Hover,
        t,
      )!,
      neutralStroke1Pressed: Color.lerp(
        a.neutralStroke1Pressed,
        b.neutralStroke1Pressed,
        t,
      )!,
      neutralStroke1Selected: Color.lerp(
        a.neutralStroke1Selected,
        b.neutralStroke1Selected,
        t,
      )!,
      neutralStroke2: Color.lerp(a.neutralStroke2, b.neutralStroke2, t)!,
      neutralStroke3: Color.lerp(a.neutralStroke3, b.neutralStroke3, t)!,
      neutralStroke4: Color.lerp(a.neutralStroke4, b.neutralStroke4, t)!,
      neutralStroke4Hover: Color.lerp(
        a.neutralStroke4Hover,
        b.neutralStroke4Hover,
        t,
      )!,
      neutralStroke4Pressed: Color.lerp(
        a.neutralStroke4Pressed,
        b.neutralStroke4Pressed,
        t,
      )!,
      neutralStroke4Selected: Color.lerp(
        a.neutralStroke4Selected,
        b.neutralStroke4Selected,
        t,
      )!,
      neutralStrokeSubtle: Color.lerp(
        a.neutralStrokeSubtle,
        b.neutralStrokeSubtle,
        t,
      )!,
      neutralStrokeOnBrand: Color.lerp(
        a.neutralStrokeOnBrand,
        b.neutralStrokeOnBrand,
        t,
      )!,
      neutralStrokeOnBrand2: Color.lerp(
        a.neutralStrokeOnBrand2,
        b.neutralStrokeOnBrand2,
        t,
      )!,
      neutralStrokeOnBrand2Hover: Color.lerp(
        a.neutralStrokeOnBrand2Hover,
        b.neutralStrokeOnBrand2Hover,
        t,
      )!,
      neutralStrokeOnBrand2Pressed: Color.lerp(
        a.neutralStrokeOnBrand2Pressed,
        b.neutralStrokeOnBrand2Pressed,
        t,
      )!,
      neutralStrokeOnBrand2Selected: Color.lerp(
        a.neutralStrokeOnBrand2Selected,
        b.neutralStrokeOnBrand2Selected,
        t,
      )!,
      brandStroke1: Color.lerp(a.brandStroke1, b.brandStroke1, t)!,
      brandStroke2: Color.lerp(a.brandStroke2, b.brandStroke2, t)!,
      brandStroke2Hover: Color.lerp(
        a.brandStroke2Hover,
        b.brandStroke2Hover,
        t,
      )!,
      brandStroke2Pressed: Color.lerp(
        a.brandStroke2Pressed,
        b.brandStroke2Pressed,
        t,
      )!,
      brandStroke2Contrast: Color.lerp(
        a.brandStroke2Contrast,
        b.brandStroke2Contrast,
        t,
      )!,
      compoundBrandStroke: Color.lerp(
        a.compoundBrandStroke,
        b.compoundBrandStroke,
        t,
      )!,
      compoundBrandStrokeHover: Color.lerp(
        a.compoundBrandStrokeHover,
        b.compoundBrandStrokeHover,
        t,
      )!,
      compoundBrandStrokePressed: Color.lerp(
        a.compoundBrandStrokePressed,
        b.compoundBrandStrokePressed,
        t,
      )!,
      neutralStrokeDisabled: Color.lerp(
        a.neutralStrokeDisabled,
        b.neutralStrokeDisabled,
        t,
      )!,
      neutralStrokeDisabled2: Color.lerp(
        a.neutralStrokeDisabled2,
        b.neutralStrokeDisabled2,
        t,
      )!,
      neutralStrokeInvertedDisabled: Color.lerp(
        a.neutralStrokeInvertedDisabled,
        b.neutralStrokeInvertedDisabled,
        t,
      )!,
      transparentStroke: Color.lerp(
        a.transparentStroke,
        b.transparentStroke,
        t,
      )!,
      transparentStrokeInteractive: Color.lerp(
        a.transparentStrokeInteractive,
        b.transparentStrokeInteractive,
        t,
      )!,
      transparentStrokeDisabled: Color.lerp(
        a.transparentStrokeDisabled,
        b.transparentStrokeDisabled,
        t,
      )!,
      neutralStrokeAlpha: Color.lerp(
        a.neutralStrokeAlpha,
        b.neutralStrokeAlpha,
        t,
      )!,
      neutralStrokeAlpha2: Color.lerp(
        a.neutralStrokeAlpha2,
        b.neutralStrokeAlpha2,
        t,
      )!,
      strokeFocus1: Color.lerp(a.strokeFocus1, b.strokeFocus1, t)!,
      strokeFocus2: Color.lerp(a.strokeFocus2, b.strokeFocus2, t)!,
      neutralShadowAmbient: Color.lerp(
        a.neutralShadowAmbient,
        b.neutralShadowAmbient,
        t,
      )!,
      neutralShadowKey: Color.lerp(a.neutralShadowKey, b.neutralShadowKey, t)!,
      neutralShadowAmbientLighter: Color.lerp(
        a.neutralShadowAmbientLighter,
        b.neutralShadowAmbientLighter,
        t,
      )!,
      neutralShadowKeyLighter: Color.lerp(
        a.neutralShadowKeyLighter,
        b.neutralShadowKeyLighter,
        t,
      )!,
      neutralShadowAmbientDarker: Color.lerp(
        a.neutralShadowAmbientDarker,
        b.neutralShadowAmbientDarker,
        t,
      )!,
      neutralShadowKeyDarker: Color.lerp(
        a.neutralShadowKeyDarker,
        b.neutralShadowKeyDarker,
        t,
      )!,
      brandShadowAmbient: Color.lerp(
        a.brandShadowAmbient,
        b.brandShadowAmbient,
        t,
      )!,
      brandShadowKey: Color.lerp(a.brandShadowKey, b.brandShadowKey, t)!,
      statusSuccessBackground1: Color.lerp(
        a.statusSuccessBackground1,
        b.statusSuccessBackground1,
        t,
      )!,
      statusSuccessBackground2: Color.lerp(
        a.statusSuccessBackground2,
        b.statusSuccessBackground2,
        t,
      )!,
      statusSuccessBackground3: Color.lerp(
        a.statusSuccessBackground3,
        b.statusSuccessBackground3,
        t,
      )!,
      statusSuccessForeground1: Color.lerp(
        a.statusSuccessForeground1,
        b.statusSuccessForeground1,
        t,
      )!,
      statusSuccessForeground2: Color.lerp(
        a.statusSuccessForeground2,
        b.statusSuccessForeground2,
        t,
      )!,
      statusSuccessForeground3: Color.lerp(
        a.statusSuccessForeground3,
        b.statusSuccessForeground3,
        t,
      )!,
      statusSuccessForegroundInverted: Color.lerp(
        a.statusSuccessForegroundInverted,
        b.statusSuccessForegroundInverted,
        t,
      )!,
      statusSuccessBorderActive: Color.lerp(
        a.statusSuccessBorderActive,
        b.statusSuccessBorderActive,
        t,
      )!,
      statusSuccessBorder1: Color.lerp(
        a.statusSuccessBorder1,
        b.statusSuccessBorder1,
        t,
      )!,
      statusSuccessBorder2: Color.lerp(
        a.statusSuccessBorder2,
        b.statusSuccessBorder2,
        t,
      )!,
      statusWarningBackground1: Color.lerp(
        a.statusWarningBackground1,
        b.statusWarningBackground1,
        t,
      )!,
      statusWarningBackground2: Color.lerp(
        a.statusWarningBackground2,
        b.statusWarningBackground2,
        t,
      )!,
      statusWarningBackground3: Color.lerp(
        a.statusWarningBackground3,
        b.statusWarningBackground3,
        t,
      )!,
      statusWarningForeground1: Color.lerp(
        a.statusWarningForeground1,
        b.statusWarningForeground1,
        t,
      )!,
      statusWarningForeground2: Color.lerp(
        a.statusWarningForeground2,
        b.statusWarningForeground2,
        t,
      )!,
      statusWarningForeground3: Color.lerp(
        a.statusWarningForeground3,
        b.statusWarningForeground3,
        t,
      )!,
      statusWarningForegroundInverted: Color.lerp(
        a.statusWarningForegroundInverted,
        b.statusWarningForegroundInverted,
        t,
      )!,
      statusWarningBorderActive: Color.lerp(
        a.statusWarningBorderActive,
        b.statusWarningBorderActive,
        t,
      )!,
      statusWarningBorder1: Color.lerp(
        a.statusWarningBorder1,
        b.statusWarningBorder1,
        t,
      )!,
      statusWarningBorder2: Color.lerp(
        a.statusWarningBorder2,
        b.statusWarningBorder2,
        t,
      )!,
      statusDangerBackground1: Color.lerp(
        a.statusDangerBackground1,
        b.statusDangerBackground1,
        t,
      )!,
      statusDangerBackground2: Color.lerp(
        a.statusDangerBackground2,
        b.statusDangerBackground2,
        t,
      )!,
      statusDangerBackground3: Color.lerp(
        a.statusDangerBackground3,
        b.statusDangerBackground3,
        t,
      )!,
      statusDangerForeground1: Color.lerp(
        a.statusDangerForeground1,
        b.statusDangerForeground1,
        t,
      )!,
      statusDangerForeground2: Color.lerp(
        a.statusDangerForeground2,
        b.statusDangerForeground2,
        t,
      )!,
      statusDangerForeground3: Color.lerp(
        a.statusDangerForeground3,
        b.statusDangerForeground3,
        t,
      )!,
      statusDangerForegroundInverted: Color.lerp(
        a.statusDangerForegroundInverted,
        b.statusDangerForegroundInverted,
        t,
      )!,
      statusDangerBorderActive: Color.lerp(
        a.statusDangerBorderActive,
        b.statusDangerBorderActive,
        t,
      )!,
      statusDangerBorder1: Color.lerp(
        a.statusDangerBorder1,
        b.statusDangerBorder1,
        t,
      )!,
      statusDangerBorder2: Color.lerp(
        a.statusDangerBorder2,
        b.statusDangerBorder2,
        t,
      )!,
      statusDangerBackground3Hover: Color.lerp(
        a.statusDangerBackground3Hover,
        b.statusDangerBackground3Hover,
        t,
      )!,
      statusDangerBackground3Pressed: Color.lerp(
        a.statusDangerBackground3Pressed,
        b.statusDangerBackground3Pressed,
        t,
      )!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fluent2Colors &&
          other.neutralForeground1 == neutralForeground1 &&
          other.neutralForeground1Hover == neutralForeground1Hover &&
          other.neutralForeground1Pressed == neutralForeground1Pressed &&
          other.neutralForeground1Selected == neutralForeground1Selected &&
          other.neutralForeground2 == neutralForeground2 &&
          other.neutralForeground2Hover == neutralForeground2Hover &&
          other.neutralForeground2Pressed == neutralForeground2Pressed &&
          other.neutralForeground2Selected == neutralForeground2Selected &&
          other.neutralForeground2BrandHover == neutralForeground2BrandHover &&
          other.neutralForeground2BrandPressed ==
              neutralForeground2BrandPressed &&
          other.neutralForeground2BrandSelected ==
              neutralForeground2BrandSelected &&
          other.neutralForeground3 == neutralForeground3 &&
          other.neutralForeground3Hover == neutralForeground3Hover &&
          other.neutralForeground3Pressed == neutralForeground3Pressed &&
          other.neutralForeground3Selected == neutralForeground3Selected &&
          other.neutralForeground3BrandHover == neutralForeground3BrandHover &&
          other.neutralForeground3BrandPressed ==
              neutralForeground3BrandPressed &&
          other.neutralForeground3BrandSelected ==
              neutralForeground3BrandSelected &&
          other.neutralForeground4 == neutralForeground4 &&
          other.neutralForeground5 == neutralForeground5 &&
          other.neutralForeground5Hover == neutralForeground5Hover &&
          other.neutralForeground5Pressed == neutralForeground5Pressed &&
          other.neutralForeground5Selected == neutralForeground5Selected &&
          other.neutralForegroundDisabled == neutralForegroundDisabled &&
          other.neutralForegroundInvertedDisabled ==
              neutralForegroundInvertedDisabled &&
          other.brandForegroundLink == brandForegroundLink &&
          other.brandForegroundLinkHover == brandForegroundLinkHover &&
          other.brandForegroundLinkPressed == brandForegroundLinkPressed &&
          other.brandForegroundLinkSelected == brandForegroundLinkSelected &&
          other.neutralForeground2Link == neutralForeground2Link &&
          other.neutralForeground2LinkHover == neutralForeground2LinkHover &&
          other.neutralForeground2LinkPressed ==
              neutralForeground2LinkPressed &&
          other.neutralForeground2LinkSelected ==
              neutralForeground2LinkSelected &&
          other.compoundBrandForeground1 == compoundBrandForeground1 &&
          other.compoundBrandForeground1Hover ==
              compoundBrandForeground1Hover &&
          other.compoundBrandForeground1Pressed ==
              compoundBrandForeground1Pressed &&
          other.brandForeground1 == brandForeground1 &&
          other.brandForeground2 == brandForeground2 &&
          other.brandForeground2Hover == brandForeground2Hover &&
          other.brandForeground2Pressed == brandForeground2Pressed &&
          other.neutralForeground1Static == neutralForeground1Static &&
          other.neutralForegroundStaticInverted ==
              neutralForegroundStaticInverted &&
          other.neutralForegroundInverted == neutralForegroundInverted &&
          other.neutralForegroundInvertedHover ==
              neutralForegroundInvertedHover &&
          other.neutralForegroundInvertedPressed ==
              neutralForegroundInvertedPressed &&
          other.neutralForegroundInvertedSelected ==
              neutralForegroundInvertedSelected &&
          other.neutralForegroundInverted2 == neutralForegroundInverted2 &&
          other.neutralForegroundOnBrand == neutralForegroundOnBrand &&
          other.neutralForegroundInvertedLink ==
              neutralForegroundInvertedLink &&
          other.neutralForegroundInvertedLinkHover ==
              neutralForegroundInvertedLinkHover &&
          other.neutralForegroundInvertedLinkPressed ==
              neutralForegroundInvertedLinkPressed &&
          other.neutralForegroundInvertedLinkSelected ==
              neutralForegroundInvertedLinkSelected &&
          other.brandForegroundInverted == brandForegroundInverted &&
          other.brandForegroundInvertedHover == brandForegroundInvertedHover &&
          other.brandForegroundInvertedPressed ==
              brandForegroundInvertedPressed &&
          other.brandForegroundOnLight == brandForegroundOnLight &&
          other.brandForegroundOnLightHover == brandForegroundOnLightHover &&
          other.brandForegroundOnLightPressed ==
              brandForegroundOnLightPressed &&
          other.brandForegroundOnLightSelected ==
              brandForegroundOnLightSelected &&
          other.neutralBackground1 == neutralBackground1 &&
          other.neutralBackground1Hover == neutralBackground1Hover &&
          other.neutralBackground1Pressed == neutralBackground1Pressed &&
          other.neutralBackground1Selected == neutralBackground1Selected &&
          other.neutralBackground2 == neutralBackground2 &&
          other.neutralBackground2Hover == neutralBackground2Hover &&
          other.neutralBackground2Pressed == neutralBackground2Pressed &&
          other.neutralBackground2Selected == neutralBackground2Selected &&
          other.neutralBackground3 == neutralBackground3 &&
          other.neutralBackground3Hover == neutralBackground3Hover &&
          other.neutralBackground3Pressed == neutralBackground3Pressed &&
          other.neutralBackground3Selected == neutralBackground3Selected &&
          other.neutralBackground4 == neutralBackground4 &&
          other.neutralBackground4Hover == neutralBackground4Hover &&
          other.neutralBackground4Pressed == neutralBackground4Pressed &&
          other.neutralBackground4Selected == neutralBackground4Selected &&
          other.neutralBackground5 == neutralBackground5 &&
          other.neutralBackground5Hover == neutralBackground5Hover &&
          other.neutralBackground5Pressed == neutralBackground5Pressed &&
          other.neutralBackground5Selected == neutralBackground5Selected &&
          other.neutralBackground6 == neutralBackground6 &&
          other.neutralBackground7 == neutralBackground7 &&
          other.neutralBackground7Hover == neutralBackground7Hover &&
          other.neutralBackground7Pressed == neutralBackground7Pressed &&
          other.neutralBackground7Selected == neutralBackground7Selected &&
          other.neutralBackground8 == neutralBackground8 &&
          other.neutralBackgroundInverted == neutralBackgroundInverted &&
          other.neutralBackgroundInvertedHover ==
              neutralBackgroundInvertedHover &&
          other.neutralBackgroundInvertedPressed ==
              neutralBackgroundInvertedPressed &&
          other.neutralBackgroundInvertedSelected ==
              neutralBackgroundInvertedSelected &&
          other.neutralBackgroundStatic == neutralBackgroundStatic &&
          other.neutralBackgroundAlpha == neutralBackgroundAlpha &&
          other.neutralBackgroundAlpha2 == neutralBackgroundAlpha2 &&
          other.subtleBackground == subtleBackground &&
          other.subtleBackgroundHover == subtleBackgroundHover &&
          other.subtleBackgroundPressed == subtleBackgroundPressed &&
          other.subtleBackgroundSelected == subtleBackgroundSelected &&
          other.subtleBackgroundLightAlphaHover ==
              subtleBackgroundLightAlphaHover &&
          other.subtleBackgroundLightAlphaPressed ==
              subtleBackgroundLightAlphaPressed &&
          other.subtleBackgroundLightAlphaSelected ==
              subtleBackgroundLightAlphaSelected &&
          other.subtleBackgroundInverted == subtleBackgroundInverted &&
          other.subtleBackgroundInvertedHover ==
              subtleBackgroundInvertedHover &&
          other.subtleBackgroundInvertedPressed ==
              subtleBackgroundInvertedPressed &&
          other.subtleBackgroundInvertedSelected ==
              subtleBackgroundInvertedSelected &&
          other.transparentBackground == transparentBackground &&
          other.transparentBackgroundHover == transparentBackgroundHover &&
          other.transparentBackgroundPressed == transparentBackgroundPressed &&
          other.transparentBackgroundSelected ==
              transparentBackgroundSelected &&
          other.neutralBackgroundDisabled == neutralBackgroundDisabled &&
          other.neutralBackgroundDisabled2 == neutralBackgroundDisabled2 &&
          other.neutralBackgroundInvertedDisabled ==
              neutralBackgroundInvertedDisabled &&
          other.neutralStencil1 == neutralStencil1 &&
          other.neutralStencil2 == neutralStencil2 &&
          other.neutralStencil1Alpha == neutralStencil1Alpha &&
          other.neutralStencil2Alpha == neutralStencil2Alpha &&
          other.backgroundOverlay == backgroundOverlay &&
          other.scrollbarOverlay == scrollbarOverlay &&
          other.brandBackground == brandBackground &&
          other.brandBackgroundHover == brandBackgroundHover &&
          other.brandBackgroundPressed == brandBackgroundPressed &&
          other.brandBackgroundSelected == brandBackgroundSelected &&
          other.compoundBrandBackground == compoundBrandBackground &&
          other.compoundBrandBackgroundHover == compoundBrandBackgroundHover &&
          other.compoundBrandBackgroundPressed ==
              compoundBrandBackgroundPressed &&
          other.brandBackgroundStatic == brandBackgroundStatic &&
          other.brandBackground2 == brandBackground2 &&
          other.brandBackground2Hover == brandBackground2Hover &&
          other.brandBackground2Pressed == brandBackground2Pressed &&
          other.brandBackground3Static == brandBackground3Static &&
          other.brandBackground4Static == brandBackground4Static &&
          other.brandBackgroundInverted == brandBackgroundInverted &&
          other.brandBackgroundInvertedHover == brandBackgroundInvertedHover &&
          other.brandBackgroundInvertedPressed ==
              brandBackgroundInvertedPressed &&
          other.brandBackgroundInvertedSelected ==
              brandBackgroundInvertedSelected &&
          other.neutralCardBackground == neutralCardBackground &&
          other.neutralCardBackgroundHover == neutralCardBackgroundHover &&
          other.neutralCardBackgroundPressed == neutralCardBackgroundPressed &&
          other.neutralCardBackgroundSelected ==
              neutralCardBackgroundSelected &&
          other.neutralCardBackgroundDisabled ==
              neutralCardBackgroundDisabled &&
          other.neutralStrokeAccessible == neutralStrokeAccessible &&
          other.neutralStrokeAccessibleHover == neutralStrokeAccessibleHover &&
          other.neutralStrokeAccessiblePressed ==
              neutralStrokeAccessiblePressed &&
          other.neutralStrokeAccessibleSelected ==
              neutralStrokeAccessibleSelected &&
          other.neutralStroke1 == neutralStroke1 &&
          other.neutralStroke1Hover == neutralStroke1Hover &&
          other.neutralStroke1Pressed == neutralStroke1Pressed &&
          other.neutralStroke1Selected == neutralStroke1Selected &&
          other.neutralStroke2 == neutralStroke2 &&
          other.neutralStroke3 == neutralStroke3 &&
          other.neutralStroke4 == neutralStroke4 &&
          other.neutralStroke4Hover == neutralStroke4Hover &&
          other.neutralStroke4Pressed == neutralStroke4Pressed &&
          other.neutralStroke4Selected == neutralStroke4Selected &&
          other.neutralStrokeSubtle == neutralStrokeSubtle &&
          other.neutralStrokeOnBrand == neutralStrokeOnBrand &&
          other.neutralStrokeOnBrand2 == neutralStrokeOnBrand2 &&
          other.neutralStrokeOnBrand2Hover == neutralStrokeOnBrand2Hover &&
          other.neutralStrokeOnBrand2Pressed == neutralStrokeOnBrand2Pressed &&
          other.neutralStrokeOnBrand2Selected ==
              neutralStrokeOnBrand2Selected &&
          other.brandStroke1 == brandStroke1 &&
          other.brandStroke2 == brandStroke2 &&
          other.brandStroke2Hover == brandStroke2Hover &&
          other.brandStroke2Pressed == brandStroke2Pressed &&
          other.brandStroke2Contrast == brandStroke2Contrast &&
          other.compoundBrandStroke == compoundBrandStroke &&
          other.compoundBrandStrokeHover == compoundBrandStrokeHover &&
          other.compoundBrandStrokePressed == compoundBrandStrokePressed &&
          other.neutralStrokeDisabled == neutralStrokeDisabled &&
          other.neutralStrokeDisabled2 == neutralStrokeDisabled2 &&
          other.neutralStrokeInvertedDisabled ==
              neutralStrokeInvertedDisabled &&
          other.transparentStroke == transparentStroke &&
          other.transparentStrokeInteractive == transparentStrokeInteractive &&
          other.transparentStrokeDisabled == transparentStrokeDisabled &&
          other.neutralStrokeAlpha == neutralStrokeAlpha &&
          other.neutralStrokeAlpha2 == neutralStrokeAlpha2 &&
          other.strokeFocus1 == strokeFocus1 &&
          other.strokeFocus2 == strokeFocus2 &&
          other.neutralShadowAmbient == neutralShadowAmbient &&
          other.neutralShadowKey == neutralShadowKey &&
          other.neutralShadowAmbientLighter == neutralShadowAmbientLighter &&
          other.neutralShadowKeyLighter == neutralShadowKeyLighter &&
          other.neutralShadowAmbientDarker == neutralShadowAmbientDarker &&
          other.neutralShadowKeyDarker == neutralShadowKeyDarker &&
          other.brandShadowAmbient == brandShadowAmbient &&
          other.brandShadowKey == brandShadowKey &&
          other.statusSuccessBackground1 == statusSuccessBackground1 &&
          other.statusSuccessBackground2 == statusSuccessBackground2 &&
          other.statusSuccessBackground3 == statusSuccessBackground3 &&
          other.statusSuccessForeground1 == statusSuccessForeground1 &&
          other.statusSuccessForeground2 == statusSuccessForeground2 &&
          other.statusSuccessForeground3 == statusSuccessForeground3 &&
          other.statusSuccessForegroundInverted ==
              statusSuccessForegroundInverted &&
          other.statusSuccessBorderActive == statusSuccessBorderActive &&
          other.statusSuccessBorder1 == statusSuccessBorder1 &&
          other.statusSuccessBorder2 == statusSuccessBorder2 &&
          other.statusWarningBackground1 == statusWarningBackground1 &&
          other.statusWarningBackground2 == statusWarningBackground2 &&
          other.statusWarningBackground3 == statusWarningBackground3 &&
          other.statusWarningForeground1 == statusWarningForeground1 &&
          other.statusWarningForeground2 == statusWarningForeground2 &&
          other.statusWarningForeground3 == statusWarningForeground3 &&
          other.statusWarningForegroundInverted ==
              statusWarningForegroundInverted &&
          other.statusWarningBorderActive == statusWarningBorderActive &&
          other.statusWarningBorder1 == statusWarningBorder1 &&
          other.statusWarningBorder2 == statusWarningBorder2 &&
          other.statusDangerBackground1 == statusDangerBackground1 &&
          other.statusDangerBackground2 == statusDangerBackground2 &&
          other.statusDangerBackground3 == statusDangerBackground3 &&
          other.statusDangerForeground1 == statusDangerForeground1 &&
          other.statusDangerForeground2 == statusDangerForeground2 &&
          other.statusDangerForeground3 == statusDangerForeground3 &&
          other.statusDangerForegroundInverted ==
              statusDangerForegroundInverted &&
          other.statusDangerBorderActive == statusDangerBorderActive &&
          other.statusDangerBorder1 == statusDangerBorder1 &&
          other.statusDangerBorder2 == statusDangerBorder2 &&
          other.statusDangerBackground3Hover == statusDangerBackground3Hover &&
          other.statusDangerBackground3Pressed ==
              statusDangerBackground3Pressed;

  @override
  int get hashCode => Object.hashAll([
    neutralForeground1,
    neutralForeground1Hover,
    neutralForeground1Pressed,
    neutralForeground1Selected,
    neutralForeground2,
    neutralForeground2Hover,
    neutralForeground2Pressed,
    neutralForeground2Selected,
    neutralForeground2BrandHover,
    neutralForeground2BrandPressed,
    neutralForeground2BrandSelected,
    neutralForeground3,
    neutralForeground3Hover,
    neutralForeground3Pressed,
    neutralForeground3Selected,
    neutralForeground3BrandHover,
    neutralForeground3BrandPressed,
    neutralForeground3BrandSelected,
    neutralForeground4,
    neutralForeground5,
    neutralForeground5Hover,
    neutralForeground5Pressed,
    neutralForeground5Selected,
    neutralForegroundDisabled,
    neutralForegroundInvertedDisabled,
    brandForegroundLink,
    brandForegroundLinkHover,
    brandForegroundLinkPressed,
    brandForegroundLinkSelected,
    neutralForeground2Link,
    neutralForeground2LinkHover,
    neutralForeground2LinkPressed,
    neutralForeground2LinkSelected,
    compoundBrandForeground1,
    compoundBrandForeground1Hover,
    compoundBrandForeground1Pressed,
    brandForeground1,
    brandForeground2,
    brandForeground2Hover,
    brandForeground2Pressed,
    neutralForeground1Static,
    neutralForegroundStaticInverted,
    neutralForegroundInverted,
    neutralForegroundInvertedHover,
    neutralForegroundInvertedPressed,
    neutralForegroundInvertedSelected,
    neutralForegroundInverted2,
    neutralForegroundOnBrand,
    neutralForegroundInvertedLink,
    neutralForegroundInvertedLinkHover,
    neutralForegroundInvertedLinkPressed,
    neutralForegroundInvertedLinkSelected,
    brandForegroundInverted,
    brandForegroundInvertedHover,
    brandForegroundInvertedPressed,
    brandForegroundOnLight,
    brandForegroundOnLightHover,
    brandForegroundOnLightPressed,
    brandForegroundOnLightSelected,
    neutralBackground1,
    neutralBackground1Hover,
    neutralBackground1Pressed,
    neutralBackground1Selected,
    neutralBackground2,
    neutralBackground2Hover,
    neutralBackground2Pressed,
    neutralBackground2Selected,
    neutralBackground3,
    neutralBackground3Hover,
    neutralBackground3Pressed,
    neutralBackground3Selected,
    neutralBackground4,
    neutralBackground4Hover,
    neutralBackground4Pressed,
    neutralBackground4Selected,
    neutralBackground5,
    neutralBackground5Hover,
    neutralBackground5Pressed,
    neutralBackground5Selected,
    neutralBackground6,
    neutralBackground7,
    neutralBackground7Hover,
    neutralBackground7Pressed,
    neutralBackground7Selected,
    neutralBackground8,
    neutralBackgroundInverted,
    neutralBackgroundInvertedHover,
    neutralBackgroundInvertedPressed,
    neutralBackgroundInvertedSelected,
    neutralBackgroundStatic,
    neutralBackgroundAlpha,
    neutralBackgroundAlpha2,
    subtleBackground,
    subtleBackgroundHover,
    subtleBackgroundPressed,
    subtleBackgroundSelected,
    subtleBackgroundLightAlphaHover,
    subtleBackgroundLightAlphaPressed,
    subtleBackgroundLightAlphaSelected,
    subtleBackgroundInverted,
    subtleBackgroundInvertedHover,
    subtleBackgroundInvertedPressed,
    subtleBackgroundInvertedSelected,
    transparentBackground,
    transparentBackgroundHover,
    transparentBackgroundPressed,
    transparentBackgroundSelected,
    neutralBackgroundDisabled,
    neutralBackgroundDisabled2,
    neutralBackgroundInvertedDisabled,
    neutralStencil1,
    neutralStencil2,
    neutralStencil1Alpha,
    neutralStencil2Alpha,
    backgroundOverlay,
    scrollbarOverlay,
    brandBackground,
    brandBackgroundHover,
    brandBackgroundPressed,
    brandBackgroundSelected,
    compoundBrandBackground,
    compoundBrandBackgroundHover,
    compoundBrandBackgroundPressed,
    brandBackgroundStatic,
    brandBackground2,
    brandBackground2Hover,
    brandBackground2Pressed,
    brandBackground3Static,
    brandBackground4Static,
    brandBackgroundInverted,
    brandBackgroundInvertedHover,
    brandBackgroundInvertedPressed,
    brandBackgroundInvertedSelected,
    neutralCardBackground,
    neutralCardBackgroundHover,
    neutralCardBackgroundPressed,
    neutralCardBackgroundSelected,
    neutralCardBackgroundDisabled,
    neutralStrokeAccessible,
    neutralStrokeAccessibleHover,
    neutralStrokeAccessiblePressed,
    neutralStrokeAccessibleSelected,
    neutralStroke1,
    neutralStroke1Hover,
    neutralStroke1Pressed,
    neutralStroke1Selected,
    neutralStroke2,
    neutralStroke3,
    neutralStroke4,
    neutralStroke4Hover,
    neutralStroke4Pressed,
    neutralStroke4Selected,
    neutralStrokeSubtle,
    neutralStrokeOnBrand,
    neutralStrokeOnBrand2,
    neutralStrokeOnBrand2Hover,
    neutralStrokeOnBrand2Pressed,
    neutralStrokeOnBrand2Selected,
    brandStroke1,
    brandStroke2,
    brandStroke2Hover,
    brandStroke2Pressed,
    brandStroke2Contrast,
    compoundBrandStroke,
    compoundBrandStrokeHover,
    compoundBrandStrokePressed,
    neutralStrokeDisabled,
    neutralStrokeDisabled2,
    neutralStrokeInvertedDisabled,
    transparentStroke,
    transparentStrokeInteractive,
    transparentStrokeDisabled,
    neutralStrokeAlpha,
    neutralStrokeAlpha2,
    strokeFocus1,
    strokeFocus2,
    neutralShadowAmbient,
    neutralShadowKey,
    neutralShadowAmbientLighter,
    neutralShadowKeyLighter,
    neutralShadowAmbientDarker,
    neutralShadowKeyDarker,
    brandShadowAmbient,
    brandShadowKey,
    statusSuccessBackground1,
    statusSuccessBackground2,
    statusSuccessBackground3,
    statusSuccessForeground1,
    statusSuccessForeground2,
    statusSuccessForeground3,
    statusSuccessForegroundInverted,
    statusSuccessBorderActive,
    statusSuccessBorder1,
    statusSuccessBorder2,
    statusWarningBackground1,
    statusWarningBackground2,
    statusWarningBackground3,
    statusWarningForeground1,
    statusWarningForeground2,
    statusWarningForeground3,
    statusWarningForegroundInverted,
    statusWarningBorderActive,
    statusWarningBorder1,
    statusWarningBorder2,
    statusDangerBackground1,
    statusDangerBackground2,
    statusDangerBackground3,
    statusDangerForeground1,
    statusDangerForeground2,
    statusDangerForeground3,
    statusDangerForegroundInverted,
    statusDangerBorderActive,
    statusDangerBorder1,
    statusDangerBorder2,
    statusDangerBackground3Hover,
    statusDangerBackground3Pressed,
  ]);
}

/// Fluent 2's shared colour palette in one appearance: thirty-odd named
/// hues (red, cranberry, pumpkin, marigold, forest, teal, steel, blue,
/// navy, lavender, purple, grape, berry, pink, magenta, plum, beige, mink,
/// platinum, anchor and the rest), each as backgrounds, a foreground and
/// borders, as `@fluentui/tokens` names them without `color`
/// (`colorPaletteRedBackground2` is [paletteRedBackground2]). The avatars'
/// colours, the badges' and the tags' read them; the same in every preset.
final class Fluent2SharedColors with Diagnosticable {
  /// A set of Fluent's shared palette colours, one per token.
  const Fluent2SharedColors({
    required this.paletteRedBackground1,
    required this.paletteRedBackground2,
    required this.paletteRedBackground3,
    required this.paletteRedForeground1,
    required this.paletteRedForeground2,
    required this.paletteRedForeground3,
    required this.paletteRedBorderActive,
    required this.paletteRedBorder1,
    required this.paletteRedBorder2,
    required this.paletteGreenBackground1,
    required this.paletteGreenBackground2,
    required this.paletteGreenBackground3,
    required this.paletteGreenForeground1,
    required this.paletteGreenForeground2,
    required this.paletteGreenForeground3,
    required this.paletteGreenBorderActive,
    required this.paletteGreenBorder1,
    required this.paletteGreenBorder2,
    required this.paletteDarkOrangeBackground1,
    required this.paletteDarkOrangeBackground2,
    required this.paletteDarkOrangeBackground3,
    required this.paletteDarkOrangeForeground1,
    required this.paletteDarkOrangeForeground2,
    required this.paletteDarkOrangeForeground3,
    required this.paletteDarkOrangeBorderActive,
    required this.paletteDarkOrangeBorder1,
    required this.paletteDarkOrangeBorder2,
    required this.paletteYellowBackground1,
    required this.paletteYellowBackground2,
    required this.paletteYellowBackground3,
    required this.paletteYellowForeground1,
    required this.paletteYellowForeground2,
    required this.paletteYellowForeground3,
    required this.paletteYellowBorderActive,
    required this.paletteYellowBorder1,
    required this.paletteYellowBorder2,
    required this.paletteBerryBackground1,
    required this.paletteBerryBackground2,
    required this.paletteBerryBackground3,
    required this.paletteBerryForeground1,
    required this.paletteBerryForeground2,
    required this.paletteBerryForeground3,
    required this.paletteBerryBorderActive,
    required this.paletteBerryBorder1,
    required this.paletteBerryBorder2,
    required this.paletteLightGreenBackground1,
    required this.paletteLightGreenBackground2,
    required this.paletteLightGreenBackground3,
    required this.paletteLightGreenForeground1,
    required this.paletteLightGreenForeground2,
    required this.paletteLightGreenForeground3,
    required this.paletteLightGreenBorderActive,
    required this.paletteLightGreenBorder1,
    required this.paletteLightGreenBorder2,
    required this.paletteMarigoldBackground1,
    required this.paletteMarigoldBackground2,
    required this.paletteMarigoldBackground3,
    required this.paletteMarigoldForeground1,
    required this.paletteMarigoldForeground2,
    required this.paletteMarigoldForeground3,
    required this.paletteMarigoldBorderActive,
    required this.paletteMarigoldBorder1,
    required this.paletteMarigoldBorder2,
    required this.paletteRedForegroundInverted,
    required this.paletteGreenForegroundInverted,
    required this.paletteYellowForegroundInverted,
    required this.paletteDarkRedBackground2,
    required this.paletteDarkRedForeground2,
    required this.paletteDarkRedBorderActive,
    required this.paletteCranberryBackground2,
    required this.paletteCranberryForeground2,
    required this.paletteCranberryBorderActive,
    required this.palettePumpkinBackground2,
    required this.palettePumpkinForeground2,
    required this.palettePumpkinBorderActive,
    required this.palettePeachBackground2,
    required this.palettePeachForeground2,
    required this.palettePeachBorderActive,
    required this.paletteGoldBackground2,
    required this.paletteGoldForeground2,
    required this.paletteGoldBorderActive,
    required this.paletteBrassBackground2,
    required this.paletteBrassForeground2,
    required this.paletteBrassBorderActive,
    required this.paletteBrownBackground2,
    required this.paletteBrownForeground2,
    required this.paletteBrownBorderActive,
    required this.paletteForestBackground2,
    required this.paletteForestForeground2,
    required this.paletteForestBorderActive,
    required this.paletteSeafoamBackground2,
    required this.paletteSeafoamForeground2,
    required this.paletteSeafoamBorderActive,
    required this.paletteDarkGreenBackground2,
    required this.paletteDarkGreenForeground2,
    required this.paletteDarkGreenBorderActive,
    required this.paletteLightTealBackground2,
    required this.paletteLightTealForeground2,
    required this.paletteLightTealBorderActive,
    required this.paletteTealBackground2,
    required this.paletteTealForeground2,
    required this.paletteTealBorderActive,
    required this.paletteSteelBackground2,
    required this.paletteSteelForeground2,
    required this.paletteSteelBorderActive,
    required this.paletteBlueBackground2,
    required this.paletteBlueForeground2,
    required this.paletteBlueBorderActive,
    required this.paletteRoyalBlueBackground2,
    required this.paletteRoyalBlueForeground2,
    required this.paletteRoyalBlueBorderActive,
    required this.paletteCornflowerBackground2,
    required this.paletteCornflowerForeground2,
    required this.paletteCornflowerBorderActive,
    required this.paletteNavyBackground2,
    required this.paletteNavyForeground2,
    required this.paletteNavyBorderActive,
    required this.paletteLavenderBackground2,
    required this.paletteLavenderForeground2,
    required this.paletteLavenderBorderActive,
    required this.palettePurpleBackground2,
    required this.palettePurpleForeground2,
    required this.palettePurpleBorderActive,
    required this.paletteGrapeBackground2,
    required this.paletteGrapeForeground2,
    required this.paletteGrapeBorderActive,
    required this.paletteLilacBackground2,
    required this.paletteLilacForeground2,
    required this.paletteLilacBorderActive,
    required this.palettePinkBackground2,
    required this.palettePinkForeground2,
    required this.palettePinkBorderActive,
    required this.paletteMagentaBackground2,
    required this.paletteMagentaForeground2,
    required this.paletteMagentaBorderActive,
    required this.palettePlumBackground2,
    required this.palettePlumForeground2,
    required this.palettePlumBorderActive,
    required this.paletteBeigeBackground2,
    required this.paletteBeigeForeground2,
    required this.paletteBeigeBorderActive,
    required this.paletteMinkBackground2,
    required this.paletteMinkForeground2,
    required this.paletteMinkBorderActive,
    required this.palettePlatinumBackground2,
    required this.palettePlatinumForeground2,
    required this.palettePlatinumBorderActive,
    required this.paletteAnchorBackground2,
    required this.paletteAnchorForeground2,
    required this.paletteAnchorBorderActive,
  });

  /// `colorPaletteRedBackground1`.
  final Color paletteRedBackground1;

  /// `colorPaletteRedBackground2`.
  final Color paletteRedBackground2;

  /// `colorPaletteRedBackground3`.
  final Color paletteRedBackground3;

  /// `colorPaletteRedForeground1`.
  final Color paletteRedForeground1;

  /// `colorPaletteRedForeground2`.
  final Color paletteRedForeground2;

  /// `colorPaletteRedForeground3`.
  final Color paletteRedForeground3;

  /// `colorPaletteRedBorderActive`.
  final Color paletteRedBorderActive;

  /// `colorPaletteRedBorder1`.
  final Color paletteRedBorder1;

  /// `colorPaletteRedBorder2`.
  final Color paletteRedBorder2;

  /// `colorPaletteGreenBackground1`.
  final Color paletteGreenBackground1;

  /// `colorPaletteGreenBackground2`.
  final Color paletteGreenBackground2;

  /// `colorPaletteGreenBackground3`.
  final Color paletteGreenBackground3;

  /// `colorPaletteGreenForeground1`.
  final Color paletteGreenForeground1;

  /// `colorPaletteGreenForeground2`.
  final Color paletteGreenForeground2;

  /// `colorPaletteGreenForeground3`.
  final Color paletteGreenForeground3;

  /// `colorPaletteGreenBorderActive`.
  final Color paletteGreenBorderActive;

  /// `colorPaletteGreenBorder1`.
  final Color paletteGreenBorder1;

  /// `colorPaletteGreenBorder2`.
  final Color paletteGreenBorder2;

  /// `colorPaletteDarkOrangeBackground1`.
  final Color paletteDarkOrangeBackground1;

  /// `colorPaletteDarkOrangeBackground2`.
  final Color paletteDarkOrangeBackground2;

  /// `colorPaletteDarkOrangeBackground3`.
  final Color paletteDarkOrangeBackground3;

  /// `colorPaletteDarkOrangeForeground1`.
  final Color paletteDarkOrangeForeground1;

  /// `colorPaletteDarkOrangeForeground2`.
  final Color paletteDarkOrangeForeground2;

  /// `colorPaletteDarkOrangeForeground3`.
  final Color paletteDarkOrangeForeground3;

  /// `colorPaletteDarkOrangeBorderActive`.
  final Color paletteDarkOrangeBorderActive;

  /// `colorPaletteDarkOrangeBorder1`.
  final Color paletteDarkOrangeBorder1;

  /// `colorPaletteDarkOrangeBorder2`.
  final Color paletteDarkOrangeBorder2;

  /// `colorPaletteYellowBackground1`.
  final Color paletteYellowBackground1;

  /// `colorPaletteYellowBackground2`.
  final Color paletteYellowBackground2;

  /// `colorPaletteYellowBackground3`.
  final Color paletteYellowBackground3;

  /// `colorPaletteYellowForeground1`.
  final Color paletteYellowForeground1;

  /// `colorPaletteYellowForeground2`.
  final Color paletteYellowForeground2;

  /// `colorPaletteYellowForeground3`.
  final Color paletteYellowForeground3;

  /// `colorPaletteYellowBorderActive`.
  final Color paletteYellowBorderActive;

  /// `colorPaletteYellowBorder1`.
  final Color paletteYellowBorder1;

  /// `colorPaletteYellowBorder2`.
  final Color paletteYellowBorder2;

  /// `colorPaletteBerryBackground1`.
  final Color paletteBerryBackground1;

  /// `colorPaletteBerryBackground2`.
  final Color paletteBerryBackground2;

  /// `colorPaletteBerryBackground3`.
  final Color paletteBerryBackground3;

  /// `colorPaletteBerryForeground1`.
  final Color paletteBerryForeground1;

  /// `colorPaletteBerryForeground2`.
  final Color paletteBerryForeground2;

  /// `colorPaletteBerryForeground3`.
  final Color paletteBerryForeground3;

  /// `colorPaletteBerryBorderActive`.
  final Color paletteBerryBorderActive;

  /// `colorPaletteBerryBorder1`.
  final Color paletteBerryBorder1;

  /// `colorPaletteBerryBorder2`.
  final Color paletteBerryBorder2;

  /// `colorPaletteLightGreenBackground1`.
  final Color paletteLightGreenBackground1;

  /// `colorPaletteLightGreenBackground2`.
  final Color paletteLightGreenBackground2;

  /// `colorPaletteLightGreenBackground3`.
  final Color paletteLightGreenBackground3;

  /// `colorPaletteLightGreenForeground1`.
  final Color paletteLightGreenForeground1;

  /// `colorPaletteLightGreenForeground2`.
  final Color paletteLightGreenForeground2;

  /// `colorPaletteLightGreenForeground3`.
  final Color paletteLightGreenForeground3;

  /// `colorPaletteLightGreenBorderActive`.
  final Color paletteLightGreenBorderActive;

  /// `colorPaletteLightGreenBorder1`.
  final Color paletteLightGreenBorder1;

  /// `colorPaletteLightGreenBorder2`.
  final Color paletteLightGreenBorder2;

  /// `colorPaletteMarigoldBackground1`.
  final Color paletteMarigoldBackground1;

  /// `colorPaletteMarigoldBackground2`.
  final Color paletteMarigoldBackground2;

  /// `colorPaletteMarigoldBackground3`.
  final Color paletteMarigoldBackground3;

  /// `colorPaletteMarigoldForeground1`.
  final Color paletteMarigoldForeground1;

  /// `colorPaletteMarigoldForeground2`.
  final Color paletteMarigoldForeground2;

  /// `colorPaletteMarigoldForeground3`.
  final Color paletteMarigoldForeground3;

  /// `colorPaletteMarigoldBorderActive`.
  final Color paletteMarigoldBorderActive;

  /// `colorPaletteMarigoldBorder1`.
  final Color paletteMarigoldBorder1;

  /// `colorPaletteMarigoldBorder2`.
  final Color paletteMarigoldBorder2;

  /// `colorPaletteRedForegroundInverted`.
  final Color paletteRedForegroundInverted;

  /// `colorPaletteGreenForegroundInverted`.
  final Color paletteGreenForegroundInverted;

  /// `colorPaletteYellowForegroundInverted`.
  final Color paletteYellowForegroundInverted;

  /// `colorPaletteDarkRedBackground2`.
  final Color paletteDarkRedBackground2;

  /// `colorPaletteDarkRedForeground2`.
  final Color paletteDarkRedForeground2;

  /// `colorPaletteDarkRedBorderActive`.
  final Color paletteDarkRedBorderActive;

  /// `colorPaletteCranberryBackground2`.
  final Color paletteCranberryBackground2;

  /// `colorPaletteCranberryForeground2`.
  final Color paletteCranberryForeground2;

  /// `colorPaletteCranberryBorderActive`.
  final Color paletteCranberryBorderActive;

  /// `colorPalettePumpkinBackground2`.
  final Color palettePumpkinBackground2;

  /// `colorPalettePumpkinForeground2`.
  final Color palettePumpkinForeground2;

  /// `colorPalettePumpkinBorderActive`.
  final Color palettePumpkinBorderActive;

  /// `colorPalettePeachBackground2`.
  final Color palettePeachBackground2;

  /// `colorPalettePeachForeground2`.
  final Color palettePeachForeground2;

  /// `colorPalettePeachBorderActive`.
  final Color palettePeachBorderActive;

  /// `colorPaletteGoldBackground2`.
  final Color paletteGoldBackground2;

  /// `colorPaletteGoldForeground2`.
  final Color paletteGoldForeground2;

  /// `colorPaletteGoldBorderActive`.
  final Color paletteGoldBorderActive;

  /// `colorPaletteBrassBackground2`.
  final Color paletteBrassBackground2;

  /// `colorPaletteBrassForeground2`.
  final Color paletteBrassForeground2;

  /// `colorPaletteBrassBorderActive`.
  final Color paletteBrassBorderActive;

  /// `colorPaletteBrownBackground2`.
  final Color paletteBrownBackground2;

  /// `colorPaletteBrownForeground2`.
  final Color paletteBrownForeground2;

  /// `colorPaletteBrownBorderActive`.
  final Color paletteBrownBorderActive;

  /// `colorPaletteForestBackground2`.
  final Color paletteForestBackground2;

  /// `colorPaletteForestForeground2`.
  final Color paletteForestForeground2;

  /// `colorPaletteForestBorderActive`.
  final Color paletteForestBorderActive;

  /// `colorPaletteSeafoamBackground2`.
  final Color paletteSeafoamBackground2;

  /// `colorPaletteSeafoamForeground2`.
  final Color paletteSeafoamForeground2;

  /// `colorPaletteSeafoamBorderActive`.
  final Color paletteSeafoamBorderActive;

  /// `colorPaletteDarkGreenBackground2`.
  final Color paletteDarkGreenBackground2;

  /// `colorPaletteDarkGreenForeground2`.
  final Color paletteDarkGreenForeground2;

  /// `colorPaletteDarkGreenBorderActive`.
  final Color paletteDarkGreenBorderActive;

  /// `colorPaletteLightTealBackground2`.
  final Color paletteLightTealBackground2;

  /// `colorPaletteLightTealForeground2`.
  final Color paletteLightTealForeground2;

  /// `colorPaletteLightTealBorderActive`.
  final Color paletteLightTealBorderActive;

  /// `colorPaletteTealBackground2`.
  final Color paletteTealBackground2;

  /// `colorPaletteTealForeground2`.
  final Color paletteTealForeground2;

  /// `colorPaletteTealBorderActive`.
  final Color paletteTealBorderActive;

  /// `colorPaletteSteelBackground2`.
  final Color paletteSteelBackground2;

  /// `colorPaletteSteelForeground2`.
  final Color paletteSteelForeground2;

  /// `colorPaletteSteelBorderActive`.
  final Color paletteSteelBorderActive;

  /// `colorPaletteBlueBackground2`.
  final Color paletteBlueBackground2;

  /// `colorPaletteBlueForeground2`.
  final Color paletteBlueForeground2;

  /// `colorPaletteBlueBorderActive`.
  final Color paletteBlueBorderActive;

  /// `colorPaletteRoyalBlueBackground2`.
  final Color paletteRoyalBlueBackground2;

  /// `colorPaletteRoyalBlueForeground2`.
  final Color paletteRoyalBlueForeground2;

  /// `colorPaletteRoyalBlueBorderActive`.
  final Color paletteRoyalBlueBorderActive;

  /// `colorPaletteCornflowerBackground2`.
  final Color paletteCornflowerBackground2;

  /// `colorPaletteCornflowerForeground2`.
  final Color paletteCornflowerForeground2;

  /// `colorPaletteCornflowerBorderActive`.
  final Color paletteCornflowerBorderActive;

  /// `colorPaletteNavyBackground2`.
  final Color paletteNavyBackground2;

  /// `colorPaletteNavyForeground2`.
  final Color paletteNavyForeground2;

  /// `colorPaletteNavyBorderActive`.
  final Color paletteNavyBorderActive;

  /// `colorPaletteLavenderBackground2`.
  final Color paletteLavenderBackground2;

  /// `colorPaletteLavenderForeground2`.
  final Color paletteLavenderForeground2;

  /// `colorPaletteLavenderBorderActive`.
  final Color paletteLavenderBorderActive;

  /// `colorPalettePurpleBackground2`.
  final Color palettePurpleBackground2;

  /// `colorPalettePurpleForeground2`.
  final Color palettePurpleForeground2;

  /// `colorPalettePurpleBorderActive`.
  final Color palettePurpleBorderActive;

  /// `colorPaletteGrapeBackground2`.
  final Color paletteGrapeBackground2;

  /// `colorPaletteGrapeForeground2`.
  final Color paletteGrapeForeground2;

  /// `colorPaletteGrapeBorderActive`.
  final Color paletteGrapeBorderActive;

  /// `colorPaletteLilacBackground2`.
  final Color paletteLilacBackground2;

  /// `colorPaletteLilacForeground2`.
  final Color paletteLilacForeground2;

  /// `colorPaletteLilacBorderActive`.
  final Color paletteLilacBorderActive;

  /// `colorPalettePinkBackground2`.
  final Color palettePinkBackground2;

  /// `colorPalettePinkForeground2`.
  final Color palettePinkForeground2;

  /// `colorPalettePinkBorderActive`.
  final Color palettePinkBorderActive;

  /// `colorPaletteMagentaBackground2`.
  final Color paletteMagentaBackground2;

  /// `colorPaletteMagentaForeground2`.
  final Color paletteMagentaForeground2;

  /// `colorPaletteMagentaBorderActive`.
  final Color paletteMagentaBorderActive;

  /// `colorPalettePlumBackground2`.
  final Color palettePlumBackground2;

  /// `colorPalettePlumForeground2`.
  final Color palettePlumForeground2;

  /// `colorPalettePlumBorderActive`.
  final Color palettePlumBorderActive;

  /// `colorPaletteBeigeBackground2`.
  final Color paletteBeigeBackground2;

  /// `colorPaletteBeigeForeground2`.
  final Color paletteBeigeForeground2;

  /// `colorPaletteBeigeBorderActive`.
  final Color paletteBeigeBorderActive;

  /// `colorPaletteMinkBackground2`.
  final Color paletteMinkBackground2;

  /// `colorPaletteMinkForeground2`.
  final Color paletteMinkForeground2;

  /// `colorPaletteMinkBorderActive`.
  final Color paletteMinkBorderActive;

  /// `colorPalettePlatinumBackground2`.
  final Color palettePlatinumBackground2;

  /// `colorPalettePlatinumForeground2`.
  final Color palettePlatinumForeground2;

  /// `colorPalettePlatinumBorderActive`.
  final Color palettePlatinumBorderActive;

  /// `colorPaletteAnchorBackground2`.
  final Color paletteAnchorBackground2;

  /// `colorPaletteAnchorForeground2`.
  final Color paletteAnchorForeground2;

  /// `colorPaletteAnchorBorderActive`.
  final Color paletteAnchorBorderActive;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('paletteRedBackground1', paletteRedBackground1))
      ..add(ColorProperty('paletteRedBackground2', paletteRedBackground2))
      ..add(ColorProperty('paletteRedBackground3', paletteRedBackground3))
      ..add(ColorProperty('paletteRedForeground1', paletteRedForeground1))
      ..add(ColorProperty('paletteRedForeground2', paletteRedForeground2))
      ..add(ColorProperty('paletteRedForeground3', paletteRedForeground3))
      ..add(ColorProperty('paletteRedBorderActive', paletteRedBorderActive))
      ..add(ColorProperty('paletteRedBorder1', paletteRedBorder1))
      ..add(ColorProperty('paletteRedBorder2', paletteRedBorder2))
      ..add(ColorProperty('paletteGreenBackground1', paletteGreenBackground1))
      ..add(ColorProperty('paletteGreenBackground2', paletteGreenBackground2))
      ..add(ColorProperty('paletteGreenBackground3', paletteGreenBackground3))
      ..add(ColorProperty('paletteGreenForeground1', paletteGreenForeground1))
      ..add(ColorProperty('paletteGreenForeground2', paletteGreenForeground2))
      ..add(ColorProperty('paletteGreenForeground3', paletteGreenForeground3))
      ..add(ColorProperty('paletteGreenBorderActive', paletteGreenBorderActive))
      ..add(ColorProperty('paletteGreenBorder1', paletteGreenBorder1))
      ..add(ColorProperty('paletteGreenBorder2', paletteGreenBorder2))
      ..add(
        ColorProperty(
          'paletteDarkOrangeBackground1',
          paletteDarkOrangeBackground1,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkOrangeBackground2',
          paletteDarkOrangeBackground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkOrangeBackground3',
          paletteDarkOrangeBackground3,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkOrangeForeground1',
          paletteDarkOrangeForeground1,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkOrangeForeground2',
          paletteDarkOrangeForeground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkOrangeForeground3',
          paletteDarkOrangeForeground3,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkOrangeBorderActive',
          paletteDarkOrangeBorderActive,
        ),
      )
      ..add(ColorProperty('paletteDarkOrangeBorder1', paletteDarkOrangeBorder1))
      ..add(ColorProperty('paletteDarkOrangeBorder2', paletteDarkOrangeBorder2))
      ..add(ColorProperty('paletteYellowBackground1', paletteYellowBackground1))
      ..add(ColorProperty('paletteYellowBackground2', paletteYellowBackground2))
      ..add(ColorProperty('paletteYellowBackground3', paletteYellowBackground3))
      ..add(ColorProperty('paletteYellowForeground1', paletteYellowForeground1))
      ..add(ColorProperty('paletteYellowForeground2', paletteYellowForeground2))
      ..add(ColorProperty('paletteYellowForeground3', paletteYellowForeground3))
      ..add(
        ColorProperty('paletteYellowBorderActive', paletteYellowBorderActive),
      )
      ..add(ColorProperty('paletteYellowBorder1', paletteYellowBorder1))
      ..add(ColorProperty('paletteYellowBorder2', paletteYellowBorder2))
      ..add(ColorProperty('paletteBerryBackground1', paletteBerryBackground1))
      ..add(ColorProperty('paletteBerryBackground2', paletteBerryBackground2))
      ..add(ColorProperty('paletteBerryBackground3', paletteBerryBackground3))
      ..add(ColorProperty('paletteBerryForeground1', paletteBerryForeground1))
      ..add(ColorProperty('paletteBerryForeground2', paletteBerryForeground2))
      ..add(ColorProperty('paletteBerryForeground3', paletteBerryForeground3))
      ..add(ColorProperty('paletteBerryBorderActive', paletteBerryBorderActive))
      ..add(ColorProperty('paletteBerryBorder1', paletteBerryBorder1))
      ..add(ColorProperty('paletteBerryBorder2', paletteBerryBorder2))
      ..add(
        ColorProperty(
          'paletteLightGreenBackground1',
          paletteLightGreenBackground1,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightGreenBackground2',
          paletteLightGreenBackground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightGreenBackground3',
          paletteLightGreenBackground3,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightGreenForeground1',
          paletteLightGreenForeground1,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightGreenForeground2',
          paletteLightGreenForeground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightGreenForeground3',
          paletteLightGreenForeground3,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightGreenBorderActive',
          paletteLightGreenBorderActive,
        ),
      )
      ..add(ColorProperty('paletteLightGreenBorder1', paletteLightGreenBorder1))
      ..add(ColorProperty('paletteLightGreenBorder2', paletteLightGreenBorder2))
      ..add(
        ColorProperty('paletteMarigoldBackground1', paletteMarigoldBackground1),
      )
      ..add(
        ColorProperty('paletteMarigoldBackground2', paletteMarigoldBackground2),
      )
      ..add(
        ColorProperty('paletteMarigoldBackground3', paletteMarigoldBackground3),
      )
      ..add(
        ColorProperty('paletteMarigoldForeground1', paletteMarigoldForeground1),
      )
      ..add(
        ColorProperty('paletteMarigoldForeground2', paletteMarigoldForeground2),
      )
      ..add(
        ColorProperty('paletteMarigoldForeground3', paletteMarigoldForeground3),
      )
      ..add(
        ColorProperty(
          'paletteMarigoldBorderActive',
          paletteMarigoldBorderActive,
        ),
      )
      ..add(ColorProperty('paletteMarigoldBorder1', paletteMarigoldBorder1))
      ..add(ColorProperty('paletteMarigoldBorder2', paletteMarigoldBorder2))
      ..add(
        ColorProperty(
          'paletteRedForegroundInverted',
          paletteRedForegroundInverted,
        ),
      )
      ..add(
        ColorProperty(
          'paletteGreenForegroundInverted',
          paletteGreenForegroundInverted,
        ),
      )
      ..add(
        ColorProperty(
          'paletteYellowForegroundInverted',
          paletteYellowForegroundInverted,
        ),
      )
      ..add(
        ColorProperty('paletteDarkRedBackground2', paletteDarkRedBackground2),
      )
      ..add(
        ColorProperty('paletteDarkRedForeground2', paletteDarkRedForeground2),
      )
      ..add(
        ColorProperty('paletteDarkRedBorderActive', paletteDarkRedBorderActive),
      )
      ..add(
        ColorProperty(
          'paletteCranberryBackground2',
          paletteCranberryBackground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteCranberryForeground2',
          paletteCranberryForeground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteCranberryBorderActive',
          paletteCranberryBorderActive,
        ),
      )
      ..add(
        ColorProperty('palettePumpkinBackground2', palettePumpkinBackground2),
      )
      ..add(
        ColorProperty('palettePumpkinForeground2', palettePumpkinForeground2),
      )
      ..add(
        ColorProperty('palettePumpkinBorderActive', palettePumpkinBorderActive),
      )
      ..add(ColorProperty('palettePeachBackground2', palettePeachBackground2))
      ..add(ColorProperty('palettePeachForeground2', palettePeachForeground2))
      ..add(ColorProperty('palettePeachBorderActive', palettePeachBorderActive))
      ..add(ColorProperty('paletteGoldBackground2', paletteGoldBackground2))
      ..add(ColorProperty('paletteGoldForeground2', paletteGoldForeground2))
      ..add(ColorProperty('paletteGoldBorderActive', paletteGoldBorderActive))
      ..add(ColorProperty('paletteBrassBackground2', paletteBrassBackground2))
      ..add(ColorProperty('paletteBrassForeground2', paletteBrassForeground2))
      ..add(ColorProperty('paletteBrassBorderActive', paletteBrassBorderActive))
      ..add(ColorProperty('paletteBrownBackground2', paletteBrownBackground2))
      ..add(ColorProperty('paletteBrownForeground2', paletteBrownForeground2))
      ..add(ColorProperty('paletteBrownBorderActive', paletteBrownBorderActive))
      ..add(ColorProperty('paletteForestBackground2', paletteForestBackground2))
      ..add(ColorProperty('paletteForestForeground2', paletteForestForeground2))
      ..add(
        ColorProperty('paletteForestBorderActive', paletteForestBorderActive),
      )
      ..add(
        ColorProperty('paletteSeafoamBackground2', paletteSeafoamBackground2),
      )
      ..add(
        ColorProperty('paletteSeafoamForeground2', paletteSeafoamForeground2),
      )
      ..add(
        ColorProperty('paletteSeafoamBorderActive', paletteSeafoamBorderActive),
      )
      ..add(
        ColorProperty(
          'paletteDarkGreenBackground2',
          paletteDarkGreenBackground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkGreenForeground2',
          paletteDarkGreenForeground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteDarkGreenBorderActive',
          paletteDarkGreenBorderActive,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightTealBackground2',
          paletteLightTealBackground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightTealForeground2',
          paletteLightTealForeground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteLightTealBorderActive',
          paletteLightTealBorderActive,
        ),
      )
      ..add(ColorProperty('paletteTealBackground2', paletteTealBackground2))
      ..add(ColorProperty('paletteTealForeground2', paletteTealForeground2))
      ..add(ColorProperty('paletteTealBorderActive', paletteTealBorderActive))
      ..add(ColorProperty('paletteSteelBackground2', paletteSteelBackground2))
      ..add(ColorProperty('paletteSteelForeground2', paletteSteelForeground2))
      ..add(ColorProperty('paletteSteelBorderActive', paletteSteelBorderActive))
      ..add(ColorProperty('paletteBlueBackground2', paletteBlueBackground2))
      ..add(ColorProperty('paletteBlueForeground2', paletteBlueForeground2))
      ..add(ColorProperty('paletteBlueBorderActive', paletteBlueBorderActive))
      ..add(
        ColorProperty(
          'paletteRoyalBlueBackground2',
          paletteRoyalBlueBackground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteRoyalBlueForeground2',
          paletteRoyalBlueForeground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteRoyalBlueBorderActive',
          paletteRoyalBlueBorderActive,
        ),
      )
      ..add(
        ColorProperty(
          'paletteCornflowerBackground2',
          paletteCornflowerBackground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteCornflowerForeground2',
          paletteCornflowerForeground2,
        ),
      )
      ..add(
        ColorProperty(
          'paletteCornflowerBorderActive',
          paletteCornflowerBorderActive,
        ),
      )
      ..add(ColorProperty('paletteNavyBackground2', paletteNavyBackground2))
      ..add(ColorProperty('paletteNavyForeground2', paletteNavyForeground2))
      ..add(ColorProperty('paletteNavyBorderActive', paletteNavyBorderActive))
      ..add(
        ColorProperty('paletteLavenderBackground2', paletteLavenderBackground2),
      )
      ..add(
        ColorProperty('paletteLavenderForeground2', paletteLavenderForeground2),
      )
      ..add(
        ColorProperty(
          'paletteLavenderBorderActive',
          paletteLavenderBorderActive,
        ),
      )
      ..add(ColorProperty('palettePurpleBackground2', palettePurpleBackground2))
      ..add(ColorProperty('palettePurpleForeground2', palettePurpleForeground2))
      ..add(
        ColorProperty('palettePurpleBorderActive', palettePurpleBorderActive),
      )
      ..add(ColorProperty('paletteGrapeBackground2', paletteGrapeBackground2))
      ..add(ColorProperty('paletteGrapeForeground2', paletteGrapeForeground2))
      ..add(ColorProperty('paletteGrapeBorderActive', paletteGrapeBorderActive))
      ..add(ColorProperty('paletteLilacBackground2', paletteLilacBackground2))
      ..add(ColorProperty('paletteLilacForeground2', paletteLilacForeground2))
      ..add(ColorProperty('paletteLilacBorderActive', paletteLilacBorderActive))
      ..add(ColorProperty('palettePinkBackground2', palettePinkBackground2))
      ..add(ColorProperty('palettePinkForeground2', palettePinkForeground2))
      ..add(ColorProperty('palettePinkBorderActive', palettePinkBorderActive))
      ..add(
        ColorProperty('paletteMagentaBackground2', paletteMagentaBackground2),
      )
      ..add(
        ColorProperty('paletteMagentaForeground2', paletteMagentaForeground2),
      )
      ..add(
        ColorProperty('paletteMagentaBorderActive', paletteMagentaBorderActive),
      )
      ..add(ColorProperty('palettePlumBackground2', palettePlumBackground2))
      ..add(ColorProperty('palettePlumForeground2', palettePlumForeground2))
      ..add(ColorProperty('palettePlumBorderActive', palettePlumBorderActive))
      ..add(ColorProperty('paletteBeigeBackground2', paletteBeigeBackground2))
      ..add(ColorProperty('paletteBeigeForeground2', paletteBeigeForeground2))
      ..add(ColorProperty('paletteBeigeBorderActive', paletteBeigeBorderActive))
      ..add(ColorProperty('paletteMinkBackground2', paletteMinkBackground2))
      ..add(ColorProperty('paletteMinkForeground2', paletteMinkForeground2))
      ..add(ColorProperty('paletteMinkBorderActive', paletteMinkBorderActive))
      ..add(
        ColorProperty('palettePlatinumBackground2', palettePlatinumBackground2),
      )
      ..add(
        ColorProperty('palettePlatinumForeground2', palettePlatinumForeground2),
      )
      ..add(
        ColorProperty(
          'palettePlatinumBorderActive',
          palettePlatinumBorderActive,
        ),
      )
      ..add(ColorProperty('paletteAnchorBackground2', paletteAnchorBackground2))
      ..add(ColorProperty('paletteAnchorForeground2', paletteAnchorForeground2))
      ..add(
        ColorProperty('paletteAnchorBorderActive', paletteAnchorBorderActive),
      );
  }

  /// Each colour of [a] blended toward [b]'s at [t], as `ColorScheme.lerp` blends
  /// Material's.
  static Fluent2SharedColors lerp(
    Fluent2SharedColors a,
    Fluent2SharedColors b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return Fluent2SharedColors(
      paletteRedBackground1: Color.lerp(
        a.paletteRedBackground1,
        b.paletteRedBackground1,
        t,
      )!,
      paletteRedBackground2: Color.lerp(
        a.paletteRedBackground2,
        b.paletteRedBackground2,
        t,
      )!,
      paletteRedBackground3: Color.lerp(
        a.paletteRedBackground3,
        b.paletteRedBackground3,
        t,
      )!,
      paletteRedForeground1: Color.lerp(
        a.paletteRedForeground1,
        b.paletteRedForeground1,
        t,
      )!,
      paletteRedForeground2: Color.lerp(
        a.paletteRedForeground2,
        b.paletteRedForeground2,
        t,
      )!,
      paletteRedForeground3: Color.lerp(
        a.paletteRedForeground3,
        b.paletteRedForeground3,
        t,
      )!,
      paletteRedBorderActive: Color.lerp(
        a.paletteRedBorderActive,
        b.paletteRedBorderActive,
        t,
      )!,
      paletteRedBorder1: Color.lerp(
        a.paletteRedBorder1,
        b.paletteRedBorder1,
        t,
      )!,
      paletteRedBorder2: Color.lerp(
        a.paletteRedBorder2,
        b.paletteRedBorder2,
        t,
      )!,
      paletteGreenBackground1: Color.lerp(
        a.paletteGreenBackground1,
        b.paletteGreenBackground1,
        t,
      )!,
      paletteGreenBackground2: Color.lerp(
        a.paletteGreenBackground2,
        b.paletteGreenBackground2,
        t,
      )!,
      paletteGreenBackground3: Color.lerp(
        a.paletteGreenBackground3,
        b.paletteGreenBackground3,
        t,
      )!,
      paletteGreenForeground1: Color.lerp(
        a.paletteGreenForeground1,
        b.paletteGreenForeground1,
        t,
      )!,
      paletteGreenForeground2: Color.lerp(
        a.paletteGreenForeground2,
        b.paletteGreenForeground2,
        t,
      )!,
      paletteGreenForeground3: Color.lerp(
        a.paletteGreenForeground3,
        b.paletteGreenForeground3,
        t,
      )!,
      paletteGreenBorderActive: Color.lerp(
        a.paletteGreenBorderActive,
        b.paletteGreenBorderActive,
        t,
      )!,
      paletteGreenBorder1: Color.lerp(
        a.paletteGreenBorder1,
        b.paletteGreenBorder1,
        t,
      )!,
      paletteGreenBorder2: Color.lerp(
        a.paletteGreenBorder2,
        b.paletteGreenBorder2,
        t,
      )!,
      paletteDarkOrangeBackground1: Color.lerp(
        a.paletteDarkOrangeBackground1,
        b.paletteDarkOrangeBackground1,
        t,
      )!,
      paletteDarkOrangeBackground2: Color.lerp(
        a.paletteDarkOrangeBackground2,
        b.paletteDarkOrangeBackground2,
        t,
      )!,
      paletteDarkOrangeBackground3: Color.lerp(
        a.paletteDarkOrangeBackground3,
        b.paletteDarkOrangeBackground3,
        t,
      )!,
      paletteDarkOrangeForeground1: Color.lerp(
        a.paletteDarkOrangeForeground1,
        b.paletteDarkOrangeForeground1,
        t,
      )!,
      paletteDarkOrangeForeground2: Color.lerp(
        a.paletteDarkOrangeForeground2,
        b.paletteDarkOrangeForeground2,
        t,
      )!,
      paletteDarkOrangeForeground3: Color.lerp(
        a.paletteDarkOrangeForeground3,
        b.paletteDarkOrangeForeground3,
        t,
      )!,
      paletteDarkOrangeBorderActive: Color.lerp(
        a.paletteDarkOrangeBorderActive,
        b.paletteDarkOrangeBorderActive,
        t,
      )!,
      paletteDarkOrangeBorder1: Color.lerp(
        a.paletteDarkOrangeBorder1,
        b.paletteDarkOrangeBorder1,
        t,
      )!,
      paletteDarkOrangeBorder2: Color.lerp(
        a.paletteDarkOrangeBorder2,
        b.paletteDarkOrangeBorder2,
        t,
      )!,
      paletteYellowBackground1: Color.lerp(
        a.paletteYellowBackground1,
        b.paletteYellowBackground1,
        t,
      )!,
      paletteYellowBackground2: Color.lerp(
        a.paletteYellowBackground2,
        b.paletteYellowBackground2,
        t,
      )!,
      paletteYellowBackground3: Color.lerp(
        a.paletteYellowBackground3,
        b.paletteYellowBackground3,
        t,
      )!,
      paletteYellowForeground1: Color.lerp(
        a.paletteYellowForeground1,
        b.paletteYellowForeground1,
        t,
      )!,
      paletteYellowForeground2: Color.lerp(
        a.paletteYellowForeground2,
        b.paletteYellowForeground2,
        t,
      )!,
      paletteYellowForeground3: Color.lerp(
        a.paletteYellowForeground3,
        b.paletteYellowForeground3,
        t,
      )!,
      paletteYellowBorderActive: Color.lerp(
        a.paletteYellowBorderActive,
        b.paletteYellowBorderActive,
        t,
      )!,
      paletteYellowBorder1: Color.lerp(
        a.paletteYellowBorder1,
        b.paletteYellowBorder1,
        t,
      )!,
      paletteYellowBorder2: Color.lerp(
        a.paletteYellowBorder2,
        b.paletteYellowBorder2,
        t,
      )!,
      paletteBerryBackground1: Color.lerp(
        a.paletteBerryBackground1,
        b.paletteBerryBackground1,
        t,
      )!,
      paletteBerryBackground2: Color.lerp(
        a.paletteBerryBackground2,
        b.paletteBerryBackground2,
        t,
      )!,
      paletteBerryBackground3: Color.lerp(
        a.paletteBerryBackground3,
        b.paletteBerryBackground3,
        t,
      )!,
      paletteBerryForeground1: Color.lerp(
        a.paletteBerryForeground1,
        b.paletteBerryForeground1,
        t,
      )!,
      paletteBerryForeground2: Color.lerp(
        a.paletteBerryForeground2,
        b.paletteBerryForeground2,
        t,
      )!,
      paletteBerryForeground3: Color.lerp(
        a.paletteBerryForeground3,
        b.paletteBerryForeground3,
        t,
      )!,
      paletteBerryBorderActive: Color.lerp(
        a.paletteBerryBorderActive,
        b.paletteBerryBorderActive,
        t,
      )!,
      paletteBerryBorder1: Color.lerp(
        a.paletteBerryBorder1,
        b.paletteBerryBorder1,
        t,
      )!,
      paletteBerryBorder2: Color.lerp(
        a.paletteBerryBorder2,
        b.paletteBerryBorder2,
        t,
      )!,
      paletteLightGreenBackground1: Color.lerp(
        a.paletteLightGreenBackground1,
        b.paletteLightGreenBackground1,
        t,
      )!,
      paletteLightGreenBackground2: Color.lerp(
        a.paletteLightGreenBackground2,
        b.paletteLightGreenBackground2,
        t,
      )!,
      paletteLightGreenBackground3: Color.lerp(
        a.paletteLightGreenBackground3,
        b.paletteLightGreenBackground3,
        t,
      )!,
      paletteLightGreenForeground1: Color.lerp(
        a.paletteLightGreenForeground1,
        b.paletteLightGreenForeground1,
        t,
      )!,
      paletteLightGreenForeground2: Color.lerp(
        a.paletteLightGreenForeground2,
        b.paletteLightGreenForeground2,
        t,
      )!,
      paletteLightGreenForeground3: Color.lerp(
        a.paletteLightGreenForeground3,
        b.paletteLightGreenForeground3,
        t,
      )!,
      paletteLightGreenBorderActive: Color.lerp(
        a.paletteLightGreenBorderActive,
        b.paletteLightGreenBorderActive,
        t,
      )!,
      paletteLightGreenBorder1: Color.lerp(
        a.paletteLightGreenBorder1,
        b.paletteLightGreenBorder1,
        t,
      )!,
      paletteLightGreenBorder2: Color.lerp(
        a.paletteLightGreenBorder2,
        b.paletteLightGreenBorder2,
        t,
      )!,
      paletteMarigoldBackground1: Color.lerp(
        a.paletteMarigoldBackground1,
        b.paletteMarigoldBackground1,
        t,
      )!,
      paletteMarigoldBackground2: Color.lerp(
        a.paletteMarigoldBackground2,
        b.paletteMarigoldBackground2,
        t,
      )!,
      paletteMarigoldBackground3: Color.lerp(
        a.paletteMarigoldBackground3,
        b.paletteMarigoldBackground3,
        t,
      )!,
      paletteMarigoldForeground1: Color.lerp(
        a.paletteMarigoldForeground1,
        b.paletteMarigoldForeground1,
        t,
      )!,
      paletteMarigoldForeground2: Color.lerp(
        a.paletteMarigoldForeground2,
        b.paletteMarigoldForeground2,
        t,
      )!,
      paletteMarigoldForeground3: Color.lerp(
        a.paletteMarigoldForeground3,
        b.paletteMarigoldForeground3,
        t,
      )!,
      paletteMarigoldBorderActive: Color.lerp(
        a.paletteMarigoldBorderActive,
        b.paletteMarigoldBorderActive,
        t,
      )!,
      paletteMarigoldBorder1: Color.lerp(
        a.paletteMarigoldBorder1,
        b.paletteMarigoldBorder1,
        t,
      )!,
      paletteMarigoldBorder2: Color.lerp(
        a.paletteMarigoldBorder2,
        b.paletteMarigoldBorder2,
        t,
      )!,
      paletteRedForegroundInverted: Color.lerp(
        a.paletteRedForegroundInverted,
        b.paletteRedForegroundInverted,
        t,
      )!,
      paletteGreenForegroundInverted: Color.lerp(
        a.paletteGreenForegroundInverted,
        b.paletteGreenForegroundInverted,
        t,
      )!,
      paletteYellowForegroundInverted: Color.lerp(
        a.paletteYellowForegroundInverted,
        b.paletteYellowForegroundInverted,
        t,
      )!,
      paletteDarkRedBackground2: Color.lerp(
        a.paletteDarkRedBackground2,
        b.paletteDarkRedBackground2,
        t,
      )!,
      paletteDarkRedForeground2: Color.lerp(
        a.paletteDarkRedForeground2,
        b.paletteDarkRedForeground2,
        t,
      )!,
      paletteDarkRedBorderActive: Color.lerp(
        a.paletteDarkRedBorderActive,
        b.paletteDarkRedBorderActive,
        t,
      )!,
      paletteCranberryBackground2: Color.lerp(
        a.paletteCranberryBackground2,
        b.paletteCranberryBackground2,
        t,
      )!,
      paletteCranberryForeground2: Color.lerp(
        a.paletteCranberryForeground2,
        b.paletteCranberryForeground2,
        t,
      )!,
      paletteCranberryBorderActive: Color.lerp(
        a.paletteCranberryBorderActive,
        b.paletteCranberryBorderActive,
        t,
      )!,
      palettePumpkinBackground2: Color.lerp(
        a.palettePumpkinBackground2,
        b.palettePumpkinBackground2,
        t,
      )!,
      palettePumpkinForeground2: Color.lerp(
        a.palettePumpkinForeground2,
        b.palettePumpkinForeground2,
        t,
      )!,
      palettePumpkinBorderActive: Color.lerp(
        a.palettePumpkinBorderActive,
        b.palettePumpkinBorderActive,
        t,
      )!,
      palettePeachBackground2: Color.lerp(
        a.palettePeachBackground2,
        b.palettePeachBackground2,
        t,
      )!,
      palettePeachForeground2: Color.lerp(
        a.palettePeachForeground2,
        b.palettePeachForeground2,
        t,
      )!,
      palettePeachBorderActive: Color.lerp(
        a.palettePeachBorderActive,
        b.palettePeachBorderActive,
        t,
      )!,
      paletteGoldBackground2: Color.lerp(
        a.paletteGoldBackground2,
        b.paletteGoldBackground2,
        t,
      )!,
      paletteGoldForeground2: Color.lerp(
        a.paletteGoldForeground2,
        b.paletteGoldForeground2,
        t,
      )!,
      paletteGoldBorderActive: Color.lerp(
        a.paletteGoldBorderActive,
        b.paletteGoldBorderActive,
        t,
      )!,
      paletteBrassBackground2: Color.lerp(
        a.paletteBrassBackground2,
        b.paletteBrassBackground2,
        t,
      )!,
      paletteBrassForeground2: Color.lerp(
        a.paletteBrassForeground2,
        b.paletteBrassForeground2,
        t,
      )!,
      paletteBrassBorderActive: Color.lerp(
        a.paletteBrassBorderActive,
        b.paletteBrassBorderActive,
        t,
      )!,
      paletteBrownBackground2: Color.lerp(
        a.paletteBrownBackground2,
        b.paletteBrownBackground2,
        t,
      )!,
      paletteBrownForeground2: Color.lerp(
        a.paletteBrownForeground2,
        b.paletteBrownForeground2,
        t,
      )!,
      paletteBrownBorderActive: Color.lerp(
        a.paletteBrownBorderActive,
        b.paletteBrownBorderActive,
        t,
      )!,
      paletteForestBackground2: Color.lerp(
        a.paletteForestBackground2,
        b.paletteForestBackground2,
        t,
      )!,
      paletteForestForeground2: Color.lerp(
        a.paletteForestForeground2,
        b.paletteForestForeground2,
        t,
      )!,
      paletteForestBorderActive: Color.lerp(
        a.paletteForestBorderActive,
        b.paletteForestBorderActive,
        t,
      )!,
      paletteSeafoamBackground2: Color.lerp(
        a.paletteSeafoamBackground2,
        b.paletteSeafoamBackground2,
        t,
      )!,
      paletteSeafoamForeground2: Color.lerp(
        a.paletteSeafoamForeground2,
        b.paletteSeafoamForeground2,
        t,
      )!,
      paletteSeafoamBorderActive: Color.lerp(
        a.paletteSeafoamBorderActive,
        b.paletteSeafoamBorderActive,
        t,
      )!,
      paletteDarkGreenBackground2: Color.lerp(
        a.paletteDarkGreenBackground2,
        b.paletteDarkGreenBackground2,
        t,
      )!,
      paletteDarkGreenForeground2: Color.lerp(
        a.paletteDarkGreenForeground2,
        b.paletteDarkGreenForeground2,
        t,
      )!,
      paletteDarkGreenBorderActive: Color.lerp(
        a.paletteDarkGreenBorderActive,
        b.paletteDarkGreenBorderActive,
        t,
      )!,
      paletteLightTealBackground2: Color.lerp(
        a.paletteLightTealBackground2,
        b.paletteLightTealBackground2,
        t,
      )!,
      paletteLightTealForeground2: Color.lerp(
        a.paletteLightTealForeground2,
        b.paletteLightTealForeground2,
        t,
      )!,
      paletteLightTealBorderActive: Color.lerp(
        a.paletteLightTealBorderActive,
        b.paletteLightTealBorderActive,
        t,
      )!,
      paletteTealBackground2: Color.lerp(
        a.paletteTealBackground2,
        b.paletteTealBackground2,
        t,
      )!,
      paletteTealForeground2: Color.lerp(
        a.paletteTealForeground2,
        b.paletteTealForeground2,
        t,
      )!,
      paletteTealBorderActive: Color.lerp(
        a.paletteTealBorderActive,
        b.paletteTealBorderActive,
        t,
      )!,
      paletteSteelBackground2: Color.lerp(
        a.paletteSteelBackground2,
        b.paletteSteelBackground2,
        t,
      )!,
      paletteSteelForeground2: Color.lerp(
        a.paletteSteelForeground2,
        b.paletteSteelForeground2,
        t,
      )!,
      paletteSteelBorderActive: Color.lerp(
        a.paletteSteelBorderActive,
        b.paletteSteelBorderActive,
        t,
      )!,
      paletteBlueBackground2: Color.lerp(
        a.paletteBlueBackground2,
        b.paletteBlueBackground2,
        t,
      )!,
      paletteBlueForeground2: Color.lerp(
        a.paletteBlueForeground2,
        b.paletteBlueForeground2,
        t,
      )!,
      paletteBlueBorderActive: Color.lerp(
        a.paletteBlueBorderActive,
        b.paletteBlueBorderActive,
        t,
      )!,
      paletteRoyalBlueBackground2: Color.lerp(
        a.paletteRoyalBlueBackground2,
        b.paletteRoyalBlueBackground2,
        t,
      )!,
      paletteRoyalBlueForeground2: Color.lerp(
        a.paletteRoyalBlueForeground2,
        b.paletteRoyalBlueForeground2,
        t,
      )!,
      paletteRoyalBlueBorderActive: Color.lerp(
        a.paletteRoyalBlueBorderActive,
        b.paletteRoyalBlueBorderActive,
        t,
      )!,
      paletteCornflowerBackground2: Color.lerp(
        a.paletteCornflowerBackground2,
        b.paletteCornflowerBackground2,
        t,
      )!,
      paletteCornflowerForeground2: Color.lerp(
        a.paletteCornflowerForeground2,
        b.paletteCornflowerForeground2,
        t,
      )!,
      paletteCornflowerBorderActive: Color.lerp(
        a.paletteCornflowerBorderActive,
        b.paletteCornflowerBorderActive,
        t,
      )!,
      paletteNavyBackground2: Color.lerp(
        a.paletteNavyBackground2,
        b.paletteNavyBackground2,
        t,
      )!,
      paletteNavyForeground2: Color.lerp(
        a.paletteNavyForeground2,
        b.paletteNavyForeground2,
        t,
      )!,
      paletteNavyBorderActive: Color.lerp(
        a.paletteNavyBorderActive,
        b.paletteNavyBorderActive,
        t,
      )!,
      paletteLavenderBackground2: Color.lerp(
        a.paletteLavenderBackground2,
        b.paletteLavenderBackground2,
        t,
      )!,
      paletteLavenderForeground2: Color.lerp(
        a.paletteLavenderForeground2,
        b.paletteLavenderForeground2,
        t,
      )!,
      paletteLavenderBorderActive: Color.lerp(
        a.paletteLavenderBorderActive,
        b.paletteLavenderBorderActive,
        t,
      )!,
      palettePurpleBackground2: Color.lerp(
        a.palettePurpleBackground2,
        b.palettePurpleBackground2,
        t,
      )!,
      palettePurpleForeground2: Color.lerp(
        a.palettePurpleForeground2,
        b.palettePurpleForeground2,
        t,
      )!,
      palettePurpleBorderActive: Color.lerp(
        a.palettePurpleBorderActive,
        b.palettePurpleBorderActive,
        t,
      )!,
      paletteGrapeBackground2: Color.lerp(
        a.paletteGrapeBackground2,
        b.paletteGrapeBackground2,
        t,
      )!,
      paletteGrapeForeground2: Color.lerp(
        a.paletteGrapeForeground2,
        b.paletteGrapeForeground2,
        t,
      )!,
      paletteGrapeBorderActive: Color.lerp(
        a.paletteGrapeBorderActive,
        b.paletteGrapeBorderActive,
        t,
      )!,
      paletteLilacBackground2: Color.lerp(
        a.paletteLilacBackground2,
        b.paletteLilacBackground2,
        t,
      )!,
      paletteLilacForeground2: Color.lerp(
        a.paletteLilacForeground2,
        b.paletteLilacForeground2,
        t,
      )!,
      paletteLilacBorderActive: Color.lerp(
        a.paletteLilacBorderActive,
        b.paletteLilacBorderActive,
        t,
      )!,
      palettePinkBackground2: Color.lerp(
        a.palettePinkBackground2,
        b.palettePinkBackground2,
        t,
      )!,
      palettePinkForeground2: Color.lerp(
        a.palettePinkForeground2,
        b.palettePinkForeground2,
        t,
      )!,
      palettePinkBorderActive: Color.lerp(
        a.palettePinkBorderActive,
        b.palettePinkBorderActive,
        t,
      )!,
      paletteMagentaBackground2: Color.lerp(
        a.paletteMagentaBackground2,
        b.paletteMagentaBackground2,
        t,
      )!,
      paletteMagentaForeground2: Color.lerp(
        a.paletteMagentaForeground2,
        b.paletteMagentaForeground2,
        t,
      )!,
      paletteMagentaBorderActive: Color.lerp(
        a.paletteMagentaBorderActive,
        b.paletteMagentaBorderActive,
        t,
      )!,
      palettePlumBackground2: Color.lerp(
        a.palettePlumBackground2,
        b.palettePlumBackground2,
        t,
      )!,
      palettePlumForeground2: Color.lerp(
        a.palettePlumForeground2,
        b.palettePlumForeground2,
        t,
      )!,
      palettePlumBorderActive: Color.lerp(
        a.palettePlumBorderActive,
        b.palettePlumBorderActive,
        t,
      )!,
      paletteBeigeBackground2: Color.lerp(
        a.paletteBeigeBackground2,
        b.paletteBeigeBackground2,
        t,
      )!,
      paletteBeigeForeground2: Color.lerp(
        a.paletteBeigeForeground2,
        b.paletteBeigeForeground2,
        t,
      )!,
      paletteBeigeBorderActive: Color.lerp(
        a.paletteBeigeBorderActive,
        b.paletteBeigeBorderActive,
        t,
      )!,
      paletteMinkBackground2: Color.lerp(
        a.paletteMinkBackground2,
        b.paletteMinkBackground2,
        t,
      )!,
      paletteMinkForeground2: Color.lerp(
        a.paletteMinkForeground2,
        b.paletteMinkForeground2,
        t,
      )!,
      paletteMinkBorderActive: Color.lerp(
        a.paletteMinkBorderActive,
        b.paletteMinkBorderActive,
        t,
      )!,
      palettePlatinumBackground2: Color.lerp(
        a.palettePlatinumBackground2,
        b.palettePlatinumBackground2,
        t,
      )!,
      palettePlatinumForeground2: Color.lerp(
        a.palettePlatinumForeground2,
        b.palettePlatinumForeground2,
        t,
      )!,
      palettePlatinumBorderActive: Color.lerp(
        a.palettePlatinumBorderActive,
        b.palettePlatinumBorderActive,
        t,
      )!,
      paletteAnchorBackground2: Color.lerp(
        a.paletteAnchorBackground2,
        b.paletteAnchorBackground2,
        t,
      )!,
      paletteAnchorForeground2: Color.lerp(
        a.paletteAnchorForeground2,
        b.paletteAnchorForeground2,
        t,
      )!,
      paletteAnchorBorderActive: Color.lerp(
        a.paletteAnchorBorderActive,
        b.paletteAnchorBorderActive,
        t,
      )!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fluent2SharedColors &&
          other.paletteRedBackground1 == paletteRedBackground1 &&
          other.paletteRedBackground2 == paletteRedBackground2 &&
          other.paletteRedBackground3 == paletteRedBackground3 &&
          other.paletteRedForeground1 == paletteRedForeground1 &&
          other.paletteRedForeground2 == paletteRedForeground2 &&
          other.paletteRedForeground3 == paletteRedForeground3 &&
          other.paletteRedBorderActive == paletteRedBorderActive &&
          other.paletteRedBorder1 == paletteRedBorder1 &&
          other.paletteRedBorder2 == paletteRedBorder2 &&
          other.paletteGreenBackground1 == paletteGreenBackground1 &&
          other.paletteGreenBackground2 == paletteGreenBackground2 &&
          other.paletteGreenBackground3 == paletteGreenBackground3 &&
          other.paletteGreenForeground1 == paletteGreenForeground1 &&
          other.paletteGreenForeground2 == paletteGreenForeground2 &&
          other.paletteGreenForeground3 == paletteGreenForeground3 &&
          other.paletteGreenBorderActive == paletteGreenBorderActive &&
          other.paletteGreenBorder1 == paletteGreenBorder1 &&
          other.paletteGreenBorder2 == paletteGreenBorder2 &&
          other.paletteDarkOrangeBackground1 == paletteDarkOrangeBackground1 &&
          other.paletteDarkOrangeBackground2 == paletteDarkOrangeBackground2 &&
          other.paletteDarkOrangeBackground3 == paletteDarkOrangeBackground3 &&
          other.paletteDarkOrangeForeground1 == paletteDarkOrangeForeground1 &&
          other.paletteDarkOrangeForeground2 == paletteDarkOrangeForeground2 &&
          other.paletteDarkOrangeForeground3 == paletteDarkOrangeForeground3 &&
          other.paletteDarkOrangeBorderActive ==
              paletteDarkOrangeBorderActive &&
          other.paletteDarkOrangeBorder1 == paletteDarkOrangeBorder1 &&
          other.paletteDarkOrangeBorder2 == paletteDarkOrangeBorder2 &&
          other.paletteYellowBackground1 == paletteYellowBackground1 &&
          other.paletteYellowBackground2 == paletteYellowBackground2 &&
          other.paletteYellowBackground3 == paletteYellowBackground3 &&
          other.paletteYellowForeground1 == paletteYellowForeground1 &&
          other.paletteYellowForeground2 == paletteYellowForeground2 &&
          other.paletteYellowForeground3 == paletteYellowForeground3 &&
          other.paletteYellowBorderActive == paletteYellowBorderActive &&
          other.paletteYellowBorder1 == paletteYellowBorder1 &&
          other.paletteYellowBorder2 == paletteYellowBorder2 &&
          other.paletteBerryBackground1 == paletteBerryBackground1 &&
          other.paletteBerryBackground2 == paletteBerryBackground2 &&
          other.paletteBerryBackground3 == paletteBerryBackground3 &&
          other.paletteBerryForeground1 == paletteBerryForeground1 &&
          other.paletteBerryForeground2 == paletteBerryForeground2 &&
          other.paletteBerryForeground3 == paletteBerryForeground3 &&
          other.paletteBerryBorderActive == paletteBerryBorderActive &&
          other.paletteBerryBorder1 == paletteBerryBorder1 &&
          other.paletteBerryBorder2 == paletteBerryBorder2 &&
          other.paletteLightGreenBackground1 == paletteLightGreenBackground1 &&
          other.paletteLightGreenBackground2 == paletteLightGreenBackground2 &&
          other.paletteLightGreenBackground3 == paletteLightGreenBackground3 &&
          other.paletteLightGreenForeground1 == paletteLightGreenForeground1 &&
          other.paletteLightGreenForeground2 == paletteLightGreenForeground2 &&
          other.paletteLightGreenForeground3 == paletteLightGreenForeground3 &&
          other.paletteLightGreenBorderActive ==
              paletteLightGreenBorderActive &&
          other.paletteLightGreenBorder1 == paletteLightGreenBorder1 &&
          other.paletteLightGreenBorder2 == paletteLightGreenBorder2 &&
          other.paletteMarigoldBackground1 == paletteMarigoldBackground1 &&
          other.paletteMarigoldBackground2 == paletteMarigoldBackground2 &&
          other.paletteMarigoldBackground3 == paletteMarigoldBackground3 &&
          other.paletteMarigoldForeground1 == paletteMarigoldForeground1 &&
          other.paletteMarigoldForeground2 == paletteMarigoldForeground2 &&
          other.paletteMarigoldForeground3 == paletteMarigoldForeground3 &&
          other.paletteMarigoldBorderActive == paletteMarigoldBorderActive &&
          other.paletteMarigoldBorder1 == paletteMarigoldBorder1 &&
          other.paletteMarigoldBorder2 == paletteMarigoldBorder2 &&
          other.paletteRedForegroundInverted == paletteRedForegroundInverted &&
          other.paletteGreenForegroundInverted ==
              paletteGreenForegroundInverted &&
          other.paletteYellowForegroundInverted ==
              paletteYellowForegroundInverted &&
          other.paletteDarkRedBackground2 == paletteDarkRedBackground2 &&
          other.paletteDarkRedForeground2 == paletteDarkRedForeground2 &&
          other.paletteDarkRedBorderActive == paletteDarkRedBorderActive &&
          other.paletteCranberryBackground2 == paletteCranberryBackground2 &&
          other.paletteCranberryForeground2 == paletteCranberryForeground2 &&
          other.paletteCranberryBorderActive == paletteCranberryBorderActive &&
          other.palettePumpkinBackground2 == palettePumpkinBackground2 &&
          other.palettePumpkinForeground2 == palettePumpkinForeground2 &&
          other.palettePumpkinBorderActive == palettePumpkinBorderActive &&
          other.palettePeachBackground2 == palettePeachBackground2 &&
          other.palettePeachForeground2 == palettePeachForeground2 &&
          other.palettePeachBorderActive == palettePeachBorderActive &&
          other.paletteGoldBackground2 == paletteGoldBackground2 &&
          other.paletteGoldForeground2 == paletteGoldForeground2 &&
          other.paletteGoldBorderActive == paletteGoldBorderActive &&
          other.paletteBrassBackground2 == paletteBrassBackground2 &&
          other.paletteBrassForeground2 == paletteBrassForeground2 &&
          other.paletteBrassBorderActive == paletteBrassBorderActive &&
          other.paletteBrownBackground2 == paletteBrownBackground2 &&
          other.paletteBrownForeground2 == paletteBrownForeground2 &&
          other.paletteBrownBorderActive == paletteBrownBorderActive &&
          other.paletteForestBackground2 == paletteForestBackground2 &&
          other.paletteForestForeground2 == paletteForestForeground2 &&
          other.paletteForestBorderActive == paletteForestBorderActive &&
          other.paletteSeafoamBackground2 == paletteSeafoamBackground2 &&
          other.paletteSeafoamForeground2 == paletteSeafoamForeground2 &&
          other.paletteSeafoamBorderActive == paletteSeafoamBorderActive &&
          other.paletteDarkGreenBackground2 == paletteDarkGreenBackground2 &&
          other.paletteDarkGreenForeground2 == paletteDarkGreenForeground2 &&
          other.paletteDarkGreenBorderActive == paletteDarkGreenBorderActive &&
          other.paletteLightTealBackground2 == paletteLightTealBackground2 &&
          other.paletteLightTealForeground2 == paletteLightTealForeground2 &&
          other.paletteLightTealBorderActive == paletteLightTealBorderActive &&
          other.paletteTealBackground2 == paletteTealBackground2 &&
          other.paletteTealForeground2 == paletteTealForeground2 &&
          other.paletteTealBorderActive == paletteTealBorderActive &&
          other.paletteSteelBackground2 == paletteSteelBackground2 &&
          other.paletteSteelForeground2 == paletteSteelForeground2 &&
          other.paletteSteelBorderActive == paletteSteelBorderActive &&
          other.paletteBlueBackground2 == paletteBlueBackground2 &&
          other.paletteBlueForeground2 == paletteBlueForeground2 &&
          other.paletteBlueBorderActive == paletteBlueBorderActive &&
          other.paletteRoyalBlueBackground2 == paletteRoyalBlueBackground2 &&
          other.paletteRoyalBlueForeground2 == paletteRoyalBlueForeground2 &&
          other.paletteRoyalBlueBorderActive == paletteRoyalBlueBorderActive &&
          other.paletteCornflowerBackground2 == paletteCornflowerBackground2 &&
          other.paletteCornflowerForeground2 == paletteCornflowerForeground2 &&
          other.paletteCornflowerBorderActive ==
              paletteCornflowerBorderActive &&
          other.paletteNavyBackground2 == paletteNavyBackground2 &&
          other.paletteNavyForeground2 == paletteNavyForeground2 &&
          other.paletteNavyBorderActive == paletteNavyBorderActive &&
          other.paletteLavenderBackground2 == paletteLavenderBackground2 &&
          other.paletteLavenderForeground2 == paletteLavenderForeground2 &&
          other.paletteLavenderBorderActive == paletteLavenderBorderActive &&
          other.palettePurpleBackground2 == palettePurpleBackground2 &&
          other.palettePurpleForeground2 == palettePurpleForeground2 &&
          other.palettePurpleBorderActive == palettePurpleBorderActive &&
          other.paletteGrapeBackground2 == paletteGrapeBackground2 &&
          other.paletteGrapeForeground2 == paletteGrapeForeground2 &&
          other.paletteGrapeBorderActive == paletteGrapeBorderActive &&
          other.paletteLilacBackground2 == paletteLilacBackground2 &&
          other.paletteLilacForeground2 == paletteLilacForeground2 &&
          other.paletteLilacBorderActive == paletteLilacBorderActive &&
          other.palettePinkBackground2 == palettePinkBackground2 &&
          other.palettePinkForeground2 == palettePinkForeground2 &&
          other.palettePinkBorderActive == palettePinkBorderActive &&
          other.paletteMagentaBackground2 == paletteMagentaBackground2 &&
          other.paletteMagentaForeground2 == paletteMagentaForeground2 &&
          other.paletteMagentaBorderActive == paletteMagentaBorderActive &&
          other.palettePlumBackground2 == palettePlumBackground2 &&
          other.palettePlumForeground2 == palettePlumForeground2 &&
          other.palettePlumBorderActive == palettePlumBorderActive &&
          other.paletteBeigeBackground2 == paletteBeigeBackground2 &&
          other.paletteBeigeForeground2 == paletteBeigeForeground2 &&
          other.paletteBeigeBorderActive == paletteBeigeBorderActive &&
          other.paletteMinkBackground2 == paletteMinkBackground2 &&
          other.paletteMinkForeground2 == paletteMinkForeground2 &&
          other.paletteMinkBorderActive == paletteMinkBorderActive &&
          other.palettePlatinumBackground2 == palettePlatinumBackground2 &&
          other.palettePlatinumForeground2 == palettePlatinumForeground2 &&
          other.palettePlatinumBorderActive == palettePlatinumBorderActive &&
          other.paletteAnchorBackground2 == paletteAnchorBackground2 &&
          other.paletteAnchorForeground2 == paletteAnchorForeground2 &&
          other.paletteAnchorBorderActive == paletteAnchorBorderActive;

  @override
  int get hashCode => Object.hashAll([
    paletteRedBackground1,
    paletteRedBackground2,
    paletteRedBackground3,
    paletteRedForeground1,
    paletteRedForeground2,
    paletteRedForeground3,
    paletteRedBorderActive,
    paletteRedBorder1,
    paletteRedBorder2,
    paletteGreenBackground1,
    paletteGreenBackground2,
    paletteGreenBackground3,
    paletteGreenForeground1,
    paletteGreenForeground2,
    paletteGreenForeground3,
    paletteGreenBorderActive,
    paletteGreenBorder1,
    paletteGreenBorder2,
    paletteDarkOrangeBackground1,
    paletteDarkOrangeBackground2,
    paletteDarkOrangeBackground3,
    paletteDarkOrangeForeground1,
    paletteDarkOrangeForeground2,
    paletteDarkOrangeForeground3,
    paletteDarkOrangeBorderActive,
    paletteDarkOrangeBorder1,
    paletteDarkOrangeBorder2,
    paletteYellowBackground1,
    paletteYellowBackground2,
    paletteYellowBackground3,
    paletteYellowForeground1,
    paletteYellowForeground2,
    paletteYellowForeground3,
    paletteYellowBorderActive,
    paletteYellowBorder1,
    paletteYellowBorder2,
    paletteBerryBackground1,
    paletteBerryBackground2,
    paletteBerryBackground3,
    paletteBerryForeground1,
    paletteBerryForeground2,
    paletteBerryForeground3,
    paletteBerryBorderActive,
    paletteBerryBorder1,
    paletteBerryBorder2,
    paletteLightGreenBackground1,
    paletteLightGreenBackground2,
    paletteLightGreenBackground3,
    paletteLightGreenForeground1,
    paletteLightGreenForeground2,
    paletteLightGreenForeground3,
    paletteLightGreenBorderActive,
    paletteLightGreenBorder1,
    paletteLightGreenBorder2,
    paletteMarigoldBackground1,
    paletteMarigoldBackground2,
    paletteMarigoldBackground3,
    paletteMarigoldForeground1,
    paletteMarigoldForeground2,
    paletteMarigoldForeground3,
    paletteMarigoldBorderActive,
    paletteMarigoldBorder1,
    paletteMarigoldBorder2,
    paletteRedForegroundInverted,
    paletteGreenForegroundInverted,
    paletteYellowForegroundInverted,
    paletteDarkRedBackground2,
    paletteDarkRedForeground2,
    paletteDarkRedBorderActive,
    paletteCranberryBackground2,
    paletteCranberryForeground2,
    paletteCranberryBorderActive,
    palettePumpkinBackground2,
    palettePumpkinForeground2,
    palettePumpkinBorderActive,
    palettePeachBackground2,
    palettePeachForeground2,
    palettePeachBorderActive,
    paletteGoldBackground2,
    paletteGoldForeground2,
    paletteGoldBorderActive,
    paletteBrassBackground2,
    paletteBrassForeground2,
    paletteBrassBorderActive,
    paletteBrownBackground2,
    paletteBrownForeground2,
    paletteBrownBorderActive,
    paletteForestBackground2,
    paletteForestForeground2,
    paletteForestBorderActive,
    paletteSeafoamBackground2,
    paletteSeafoamForeground2,
    paletteSeafoamBorderActive,
    paletteDarkGreenBackground2,
    paletteDarkGreenForeground2,
    paletteDarkGreenBorderActive,
    paletteLightTealBackground2,
    paletteLightTealForeground2,
    paletteLightTealBorderActive,
    paletteTealBackground2,
    paletteTealForeground2,
    paletteTealBorderActive,
    paletteSteelBackground2,
    paletteSteelForeground2,
    paletteSteelBorderActive,
    paletteBlueBackground2,
    paletteBlueForeground2,
    paletteBlueBorderActive,
    paletteRoyalBlueBackground2,
    paletteRoyalBlueForeground2,
    paletteRoyalBlueBorderActive,
    paletteCornflowerBackground2,
    paletteCornflowerForeground2,
    paletteCornflowerBorderActive,
    paletteNavyBackground2,
    paletteNavyForeground2,
    paletteNavyBorderActive,
    paletteLavenderBackground2,
    paletteLavenderForeground2,
    paletteLavenderBorderActive,
    palettePurpleBackground2,
    palettePurpleForeground2,
    palettePurpleBorderActive,
    paletteGrapeBackground2,
    paletteGrapeForeground2,
    paletteGrapeBorderActive,
    paletteLilacBackground2,
    paletteLilacForeground2,
    paletteLilacBorderActive,
    palettePinkBackground2,
    palettePinkForeground2,
    palettePinkBorderActive,
    paletteMagentaBackground2,
    paletteMagentaForeground2,
    paletteMagentaBorderActive,
    palettePlumBackground2,
    palettePlumForeground2,
    palettePlumBorderActive,
    paletteBeigeBackground2,
    paletteBeigeForeground2,
    paletteBeigeBorderActive,
    paletteMinkBackground2,
    paletteMinkForeground2,
    paletteMinkBorderActive,
    palettePlatinumBackground2,
    palettePlatinumForeground2,
    palettePlatinumBorderActive,
    paletteAnchorBackground2,
    paletteAnchorForeground2,
    paletteAnchorBorderActive,
  ]);
}
