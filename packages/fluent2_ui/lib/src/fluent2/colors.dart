// Generated from @fluentui/tokens 1.0.0-alpha.24 (MIT, npm) and the Fluent theme
// designer's palette code (MIT, microsoft/fluentui) by the Fluent 2 token script
// (looks/fluent/tools, gen_dart.ts over data/presets.json); never edit by hand.
// The classes: one field per Fluent colour token, named as Fluent names it without its `color`.

import 'package:flutter/painting.dart' show Color;

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

  /// The colours [map] names, every field required.
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
}

/// Fluent 2's shared colour palette in one appearance: thirty-odd named
/// hues (red, cranberry, pumpkin, marigold, forest, teal, steel, blue,
/// navy, lavender, purple, grape, berry, pink, magenta, plum, beige, mink,
/// platinum, anchor and the rest), each as backgrounds, a foreground and
/// borders, as `@fluentui/tokens` names them without `color`
/// (`colorPaletteRedBackground2` is [paletteRedBackground2]). The avatars'
/// colours, the badges' and the tags' read them; the same in every preset.
final class Fluent2SharedColors {
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
}
