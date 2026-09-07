import 'package:flutter/material.dart';

import 'controller.dart';
import 'scope.dart';

/// Visual settings shared by tilt-reactive surfaces.
@immutable
class SensorShadowStyle {
  /// Creates a style. [maxOffset] and [blurRadius] are logical pixels.
  const SensorShadowStyle({
    this.color = const Color(0xFFF0EEE9),
    this.shadowColor = const Color(0x40000000),
    this.highlightColor = const Color(0xFFFFFFFF),
    this.maxOffset = 18,
    this.blurRadius = 24,
    this.spreadRadius = 0,
    this.lightIntensity = 0.18,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.ambientOffset = const Offset(0, 4),
  })  : assert(maxOffset >= 0 && maxOffset < double.infinity),
        assert(blurRadius >= 0 && blurRadius < double.infinity),
        assert(spreadRadius > double.negativeInfinity &&
            spreadRadius < double.infinity),
        assert(lightIntensity >= 0 && lightIntensity <= 1);

  /// Base fill color.
  final Color color;

  /// Color of the moving cast shadow.
  final Color shadowColor;

  /// Color mixed into the illuminated side of the surface.
  final Color highlightColor;

  /// Maximum shadow displacement per tilt axis, in logical pixels.
  final double maxOffset;

  /// Shadow blur radius in logical pixels.
  final double blurRadius;

  /// Shadow spread radius in logical pixels.
  final double spreadRadius;

  /// Strength of the highlight, from zero to one.
  final double lightIntensity;

  /// Shape of the surface and its cast shadow.
  final BorderRadius borderRadius;

  /// Resting shadow displacement, present even at neutral tilt.
  final Offset ambientOffset;

  /// Resolves a normalized tilt into a surface decoration.
  ///
  /// Light appears opposite the cast shadow. The resting light comes from
  /// the upper left, ensuring surfaces retain depth without sensor hardware.
  BoxDecoration decorationFor(Offset tilt) {
    final offset = Offset(tilt.dx.clamp(-1.0, 1.0), tilt.dy.clamp(-1.0, 1.0));
    final light = Alignment(-0.6 - offset.dx, -0.8 - offset.dy);
    return BoxDecoration(
      borderRadius: borderRadius,
      gradient: LinearGradient(
        begin: light,
        end: Alignment(-light.x, -light.y),
        colors: [Color.lerp(color, highlightColor, lightIntensity)!, color],
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: ambientOffset + offset * maxOffset,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        )
      ],
    );
  }
}

/// A surface whose shadow and highlight follow device tilt.
///
/// Uses [controller], or the nearest [SensorShadowScope]. Without either it
/// renders a neutral surface. Wrap many surfaces in one scope to share sampling.
/// Shadows paint outside layout bounds; leave space around the widget.
class SensorShadow extends StatelessWidget {
  /// Creates a tilt-reactive surface.
  const SensorShadow(
      {super.key,
      required this.child,
      this.controller,
      this.style = const SensorShadowStyle(),
      this.padding = EdgeInsets.zero,
      this.enabled = true,
      this.respectReducedMotion = true,
      this.clipBehavior = Clip.none});

  /// Content retained across sensor-driven decoration updates.
  final Widget child;

  /// Optional controller overriding the nearest scope.
  final SensorShadowController? controller;

  /// Surface appearance and shadow range.
  final SensorShadowStyle style;

  /// Space between the surface edge and its content.
  final EdgeInsetsGeometry padding;

  /// Whether this surface responds to tilt.
  final bool enabled;

  /// Whether platform reduced-motion settings suppress this surface's motion.
  final bool respectReducedMotion;

  /// Content clipping; the shadow is never clipped by this widget itself.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final source = controller ?? SensorShadowScope.maybeOf(context);
    final hasMediaQuery =
        context.getElementForInheritedWidgetOfExactType<MediaQuery>() != null;
    final disableAnimations =
        hasMediaQuery ? MediaQuery.disableAnimationsOf(context) : false;

    final active = enabled &&
        SensorShadowScope.motionEnabledOf(context) &&
        !(respectReducedMotion && disableAnimations);
    final content = Padding(padding: padding, child: child);
    Widget surface(Offset tilt, Widget? content) => DecoratedBox(
          decoration: style.decorationFor(tilt),
          child: clipBehavior == Clip.none
              ? content
              : ClipRRect(
                  borderRadius: style.borderRadius,
                  clipBehavior: clipBehavior,
                  child: content,
                ),
        );
    if (source == null || !active) return surface(Offset.zero, content);
    return ValueListenableBuilder<Offset>(
      valueListenable: source,
      child: content,
      builder: (context, tilt, child) => surface(tilt, child),
    );
  }
}

/// A padded card with tilt-driven shadows and lighting.
class SensorShadowCard extends StatelessWidget {
  /// Creates a card. Surround it with enough space for its moving shadow.
  const SensorShadowCard(
      {super.key,
      required this.child,
      this.controller,
      this.style = const SensorShadowStyle(),
      this.padding = const EdgeInsets.all(24),
      this.margin = const EdgeInsets.all(12)});

  /// Card contents.
  final Widget child;

  /// Optional controller overriding the enclosing scope.
  final SensorShadowController? controller;

  /// Card fill, shape, and lighting.
  final SensorShadowStyle style;

  /// Internal spacing.
  final EdgeInsetsGeometry padding;

  /// External space reserved for the shadow.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: SensorShadow(
            controller: controller,
            style: style,
            padding: padding,
            child: child),
      );
}

/// A keyboard-accessible Material button on a tilt-reactive surface.
///
/// A null [onPressed] disables activation and tilt. Material handles focus,
/// keyboard activation, semantics, and press feedback.
class SensorShadowButton extends StatelessWidget {
  /// Creates a button with a minimum 48 logical pixel touch target.
  const SensorShadowButton(
      {super.key,
      required this.onPressed,
      required this.child,
      this.controller,
      this.style = const SensorShadowStyle(
          borderRadius: BorderRadius.all(Radius.circular(16))),
      this.foregroundColor,
      this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      this.autofocus = false,
      this.focusNode});

  /// Callback invoked on activation; null disables the button.
  final VoidCallback? onPressed;

  /// Button label, icon, or other content.
  final Widget child;

  /// Optional controller overriding the enclosing scope.
  final SensorShadowController? controller;

  /// Surface shape and lighting.
  final SensorShadowStyle style;

  /// Optional text and icon color; defaults to the theme's primary color.
  final Color? foregroundColor;

  /// Internal button spacing.
  final EdgeInsetsGeometry padding;

  /// Whether this button requests initial focus.
  final bool autofocus;

  /// Optional externally managed focus node.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => SensorShadow(
        controller: controller,
        style: style,
        enabled: onPressed != null,
        child: TextButton(
          onPressed: onPressed,
          autofocus: autofocus,
          focusNode: focusNode,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            minimumSize: const Size(48, 48),
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: style.borderRadius),
          ),
          child: child,
        ),
      );
}
