import 'package:flutter/widgets.dart';

import 'controller.dart';

/// Shares one tilt controller among descendant surfaces.
///
/// An internally created controller is managed and disposed automatically.
/// An external [controller] remains owned by its caller. Owned controllers stop
/// sampling when disabled or when the platform requests reduced motion.
class SensorShadowScope extends StatefulWidget {
  /// Creates a scope, optionally using a caller-owned controller.
  const SensorShadowScope({
    super.key,
    required this.child,
    this.controller,
    this.enabled = true,
    this.respectReducedMotion = true,
  });

  /// Descendants that share the sensor subscription.
  final Widget child;

  /// Optional caller-owned controller; the caller manages its sampling lifetime.
  final SensorShadowController? controller;

  /// Whether descendants respond to tilt.
  final bool enabled;

  /// Whether the platform's disable-animations setting suppresses tilt.
  final bool respectReducedMotion;

  /// Returns the nearest scope's controller, or null when no scope exists.
  static SensorShadowController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShadowScope>()?.controller;

  /// Returns whether the nearest scope allows motion. Defaults to true.
  static bool motionEnabledOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShadowScope>()?.enabled ??
      true;

  @override
  State<SensorShadowScope> createState() => _SensorShadowScopeState();
}

/// App-level entry point for sensor-driven shadows.
///
/// Place this widget directly around a [WidgetsApp], `MaterialApp`, or
/// `CupertinoApp`:
///
/// ```dart
/// runApp(
///   SensorShadows(
///     child: MaterialApp(home: MyHomePage()),
///   ),
/// );
/// ```
///
/// It owns one [SensorShadowController] and makes it available to every
/// package surface in every route, dialog, and overlay. An external
/// [controller] remains caller-owned.
///
/// Flutter does not expose a global hook for changing the geometry of shadows
/// painted by arbitrary widgets. Consequently, this wrapper drives
/// `SensorShadow`, `SensorShadowCard`, and `SensorShadowButton`; it cannot
/// replace shadows painted internally by stock `Material` or `Card` widgets.
class SensorShadows extends StatelessWidget {
  /// Creates an app-level sensor shadow scope.
  const SensorShadows({
    super.key,
    required this.child,
    this.controller,
    this.enabled = true,
    this.respectReducedMotion = true,
  });

  /// App widget, normally a `MaterialApp` or `CupertinoApp`.
  final Widget child;

  /// Optional caller-owned controller shared by all package surfaces.
  final SensorShadowController? controller;

  /// Whether package surfaces respond to tilt.
  final bool enabled;

  /// Whether platform reduced-motion settings suppress tilt.
  final bool respectReducedMotion;

  @override
  Widget build(BuildContext context) => SensorShadowScope(
        controller: controller,
        enabled: enabled,
        respectReducedMotion: respectReducedMotion,
        child: child,
      );
}

class _SensorShadowScopeState extends State<SensorShadowScope>
    with WidgetsBindingObserver {
  SensorShadowController? _owned;
  bool _enabled = true;
  SensorShadowController get _controller =>
      widget.controller ??
      (_owned ??= SensorShadowController(autoStart: false));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final hasMediaQuery =
        context.getElementForInheritedWidgetOfExactType<MediaQuery>() != null;
    final disableAnimations = hasMediaQuery
        ? MediaQuery.disableAnimationsOf(context)
        : WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;

    _enabled =
        widget.enabled && !(widget.respectReducedMotion && disableAnimations);

    if (widget.controller != null) {
      _owned?.dispose();
      _owned = null;
    } else if (_enabled) {
      _controller.start();
    } else {
      _controller.stop(resetTilt: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SensorShadowScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (mounted) setState(_sync);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ShadowScope(
        controller: _controller,
        enabled: _enabled,
        child: widget.child,
      );
}

class _ShadowScope extends InheritedWidget {
  const _ShadowScope(
      {required this.controller, required this.enabled, required super.child});
  final SensorShadowController controller;
  final bool enabled;

  @override
  bool updateShouldNotify(_ShadowScope oldWidget) =>
      controller != oldWidget.controller || enabled != oldWidget.enabled;
}
