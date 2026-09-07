import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A gravity-inclusive acceleration sample, in meters per second squared.
@immutable
class TiltSample {
  /// Creates a sample in the device's native sensor coordinate system.
  const TiltSample(this.x, this.y, this.z);

  /// Acceleration along the device's horizontal axis.
  final double x;

  /// Acceleration along the device's vertical axis.
  final double y;

  /// Acceleration perpendicular to the screen.
  final double z;
}

/// Converts gravity-inclusive acceleration into smoothed, normalized tilt.
///
/// [value] is an [Offset] with each axis in -1…1. One controller can drive
/// many surfaces. Call [dispose] when no longer needed. Custom [samples] allow
/// deterministic tests or alternate sensor backends. Native readings use the
/// device's sensor axes; use [quarterTurns] for a known screen rotation.
class SensorShadowController extends ValueNotifier<Offset>
    with WidgetsBindingObserver {
  /// Creates a controller and optionally starts sampling immediately.
  ///
  /// [smoothing] is the fraction of each new reading applied (0 exclusive,
  /// 1 inclusive). [sensitivity] scales normalized acceleration. Background
  /// apps unsubscribe automatically and reconnect on resume.
  SensorShadowController({
    Stream<TiltSample>? samples,
    this.smoothing = 0.15,
    this.sensitivity = 1,
    this.quarterTurns = 0,
    this.samplingPeriod = const Duration(milliseconds: 20),
    this.onError,
    bool autoStart = true,
  })  : _samples = samples,
        super(Offset.zero) {
    if (!smoothing.isFinite || smoothing <= 0 || smoothing > 1) {
      throw ArgumentError.value(smoothing, 'smoothing', 'Must be in (0, 1].');
    }
    if (!sensitivity.isFinite || sensitivity <= 0) {
      throw ArgumentError.value(
          sensitivity, 'sensitivity', 'Must be positive.');
    }
    if (samplingPeriod <= Duration.zero) {
      throw ArgumentError.value(
          samplingPeriod, 'samplingPeriod', 'Must be positive.');
    }
    WidgetsBinding.instance.addObserver(this);
    if (autoStart) start();
  }

  /// Fraction of a new sensor reading applied to the current tilt.
  final double smoothing;

  /// Multiplier applied to normalized acceleration before clamping.
  final double sensitivity;

  /// Clockwise quarter turns used to remap native sensor axes.
  final int quarterTurns;

  /// Requested sensor interval; browsers may ignore this value.
  final Duration samplingPeriod;

  /// Receives sensor failures; the controller returns to neutral on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  final Stream<TiltSample>? _samples;
  StreamSubscription<TiltSample>? _subscription;
  Offset _neutral = Offset.zero;
  Offset _lastRaw = Offset.zero;
  bool _enabled = false;
  bool _disposed = false;
  int _generation = 0;

  /// Whether sampling has been requested, including while backgrounded.
  bool get isStarted => _enabled;

  /// Starts sampling. Repeated calls are safe; unsupported desktops stay still.
  void start() {
    if (_disposed) throw StateError('Controller has been disposed.');
    _enabled = true;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) _connect();
  }

  void _connect() {
    if (_subscription != null || _disposed) return;
    if (_samples == null &&
        !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    final generation = ++_generation;
    try {
      final stream = _samples ??
          accelerometerEventStream(
            samplingPeriod: samplingPeriod,
          ).map((event) => TiltSample(event.x, event.y, event.z));
      _subscription = stream.listen((sample) {
        if (!_disposed && generation == _generation) _accept(sample);
      }, onError: (Object error, StackTrace stack) {
        if (!_disposed && generation == _generation) {
          _disconnect();
          value = Offset.zero;
          onError?.call(error, stack);
        }
      }, onDone: () {
        if (generation == _generation) _subscription = null;
      });
    } catch (error, stack) {
      value = Offset.zero;
      onError?.call(error, stack);
    }
  }

  void _accept(TiltSample sample) {
    if (!sample.x.isFinite || !sample.y.isFinite || !sample.z.isFinite) return;
    final magnitude = math
        .sqrt(sample.x * sample.x + sample.y * sample.y + sample.z * sample.z);
    if (!magnitude.isFinite || magnitude < 0.001) return;
    var raw = Offset(-sample.x / magnitude, sample.y / magnitude);
    for (var i = 0; i < quarterTurns % 4; i++) {
      raw = Offset(-raw.dy, raw.dx);
    }
    _lastRaw = raw;
    final target = _clamp((raw - _neutral) * sensitivity);
    value = Offset.lerp(value, target, smoothing)!;
  }

  /// Makes the most recent device pose the neutral lighting position.
  void calibrate() {
    _neutral = _lastRaw;
    value = Offset.zero;
  }

  /// Clears calibration and returns the output to neutral.
  void reset() {
    _neutral = Offset.zero;
    value = Offset.zero;
  }

  /// Sets tilt directly for previews, pointer input, or deterministic tests.
  ///
  /// Stop sampling first to prevent subsequent sensor events overwriting this.
  void setTilt(Offset tilt) {
    if (!tilt.dx.isFinite || !tilt.dy.isFinite) {
      throw ArgumentError.value(tilt, 'tilt', 'Must contain finite values.');
    }
    value = _clamp(tilt);
  }

  static Offset _clamp(Offset offset) => Offset(
        offset.dx.clamp(-1.0, 1.0),
        offset.dy.clamp(-1.0, 1.0),
      );

  /// Stops sampling, retaining the current tilt unless [resetTilt] is true.
  void stop({bool resetTilt = false}) {
    _enabled = false;
    _disconnect();
    if (resetTilt) value = Offset.zero;
  }

  void _disconnect() {
    _generation++;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _enabled) {
      _connect();
    } else {
      _disconnect();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _enabled = false;
    _disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
