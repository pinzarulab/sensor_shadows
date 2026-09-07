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

class _SensorShadowScopeState extends State<SensorShadowScope> {
  SensorShadowController? _owned;
  bool _enabled = true;
  SensorShadowController get _controller =>
      widget.controller ??
      (_owned ??= SensorShadowController(autoStart: false));

  void _sync() {
    final hasMediaQuery =
        context.getElementForInheritedWidgetOfExactType<MediaQuery>() != null;
    final disableAnimations =
        hasMediaQuery ? MediaQuery.disableAnimationsOf(context) : false;

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
  void dispose() {
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
