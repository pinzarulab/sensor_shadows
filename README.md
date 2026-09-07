# sensor_shadows

**Light that follows your hands.** Tactile Flutter cards, buttons, and custom
surfaces with shadows and highlights driven by your phone's accelerometer.

One shared sensor stream powers an entire screen. Smooth noisy readings,
calibrate a comfortable resting pose, or supply manual tilt for previews.
Reduced-motion preferences are respected by default.

## Install

```yaml
dependencies:
  sensor_shadows: ^0.1.0
```

Requires Dart 3.5+ and Flutter 3.24+. Native builds also need the toolchain
required by `sensors_plus` 7.1.0: its Android plugin uses Java 17, Kotlin 2.2.0,
and Android Gradle Plugin 8.12.1. Use a current Flutter-generated Android
project or align an older host project's build tooling. The bundled example
was generated with Flutter 3.47.

### iOS setup

Add this entry inside the root `<dict>` in `ios/Runner/Info.plist`:

```xml
<key>NSMotionUsageDescription</key>
<string>Motion data moves shadows and lighting as you tilt your phone.</string>
```

The sensor dependency requires this key. Its minimum iOS version is 12;
your Flutter SDK may require a newer deployment target. The example includes
this configuration.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:sensor_shadows/sensor_shadows.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFFE9E8E2),
      body: SensorShadowScope(
        child: Center(
          child: SensorShadowCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tilt your phone'),
                const SizedBox(height: 24),
                SensorShadowButton(
                  onPressed: () {},
                  child: const Text('Feel the light'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
}
```

Place the scope beneath `MaterialApp` or another `MediaQuery`. It owns its
controller, subscribes once for all descendant surfaces, and disposes it when
removed. A surface without a scope or explicit controller renders static lighting.

## Customize a surface

```dart
const SensorShadow(
  style: SensorShadowStyle(
    color: Color(0xFF365E4D),
    shadowColor: Color(0x50000000),
    highlightColor: Color(0xFFFFFFFF),
    maxOffset: 24,
    blurRadius: 30,
    spreadRadius: 0,
    lightIntensity: 0.15,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    ambientOffset: Offset(0, 4),
  ),
  padding: EdgeInsets.all(24),
  child: Text('A tactile surface', style: TextStyle(color: Colors.white)),
)
```

Use transparent content backgrounds to keep the surface lighting visible.
Shadows paint outside the widget's layout bounds: reserve surrounding space and
avoid ancestor clipping. Set `clipBehavior` to clip content to the surface shape.
Clipping content does not clip the shadow itself.

## Control tilt and calibration

Create a controller in `State.initState`, pass it to a scope or directly to a
surface, and dispose it in `State.dispose`:

```dart
final controller = SensorShadowController(
  smoothing: 0.15, // Fraction of each new reading applied: (0, 1].
  sensitivity: 1.2,
  samplingPeriod: const Duration(milliseconds: 20),
  onError: (error, stackTrace) {
    debugPrint('Motion unavailable: $error');
  },
);

// In build:
SensorShadowScope(controller: controller, child: const MyContent());

// A user-triggered calibration action:
controller.calibrate();

// Manual preview (each axis is clamped to -1…1):
controller.stop();
controller.setTilt(const Offset(0.6, -0.4));

// Resume sensors, or clear calibration:
controller.start();
controller.reset();

// In State.dispose:
controller.dispose();
```

`MyContent` above represents your own widget. The runnable example shows the
complete lifecycle. Externally supplied controllers remain caller-owned: scopes
never stop or dispose them. For battery-sensitive reduced-motion handling with an
external controller, call `stop()` when `MediaQuery.disableAnimations` is true
(as the example does). Controllers always unsubscribe while the app is inactive,
paused, hidden, or detached, and reconnect on resume if sampling was enabled.

`value` is a listenable normalized `Offset`. The controller normalizes the
three-axis gravity vector, maps it to `(-x, y)`, subtracts the calibrated pose,
applies sensitivity, clamps both axes, and smooths the result. This is a visual
effect, not an angle measurement: rapid linear acceleration can influence it.
Smaller smoothing values are calmer but lag more; smoothing is per sample.
Invalid and near-zero samples are ignored. A sensor error resets the output to
neutral and invokes `onError`; call `start()` to retry.

### Orientation

The default mapping uses the device's **native sensor axes**. It does not infer
screen rotation. For a known rotated layout, supply `quarterTurns` (clockwise,
modulo four) when creating the controller. Recreate the controller when the
screen rotation changes, or remap samples in a custom stream. The example's
sensor instructions assume portrait orientation; manual mode works in any layout.

### Custom sensor input

```dart
final samples = Stream<TiltSample>.periodic(
  const Duration(milliseconds: 20),
  (_) => const TiltSample(-3, 2, 9),
).asBroadcastStream();
final controller = SensorShadowController(samples: samples);
```

Samples include gravity, in m/s². Use a broadcast stream that supports
re-listening after cancellation for background/resume and stop/start. The caller
owns the input stream; the controller owns only its subscription. Custom streams
also work on desktop and in deterministic tests.

## Platforms and accessibility

| Platform | Behavior |
| --- | --- |
| Android | Accelerometer input when available; no runtime motion permission needed for the default rate. |
| iOS | Accelerometer input; configure `NSMotionUsageDescription`. Test on real hardware. |
| Web | Browser-dependent sensor support; permission policies and secure-context requirements may apply. Sampling interval may be ignored. Use manual input when unavailable. |
| macOS, Windows, Linux | Static neutral lighting by default; manual or custom stream input supported. |

`SensorShadowScope` and `SensorShadow` respect
`MediaQuery.disableAnimations` by default. Disabling a scope renders neutral
lighting and stops its internally owned sensor controller. Explicitly setting
`respectReducedMotion: false` opts a widget out of its own check; an enclosing
disabled scope still wins.

Buttons use Flutter's `TextButton` for touch, focus, keyboard activation, disabled
semantics, and press feedback, with a minimum 48×48 logical pixel target. Choose
foreground and surface colors with appropriate contrast. Cards and generic
surfaces preserve their children's semantics.

## Run the full example

```sh
cd example
flutter pub get
flutter run                  # Connected Android or iOS device
flutter run -d chrome        # Turn on “Manual tilt” to explore on desktop
```

The lighting studio includes cards, enabled and disabled buttons, color swatches,
live tilt coordinates, manual X/Y controls, calibration, shadow travel, and a
motion toggle. Physical sensor availability varies by device and browser;
simulators may produce no readings.

## API overview

| Type | Purpose |
| --- | --- |
| `SensorShadowScope` | Share a sensor controller across descendants. |
| `SensorShadowController` | Sampling, lifecycle, smoothing, calibration, and manual input. |
| `TiltSample` | Injectable gravity-inclusive acceleration reading. |
| `SensorShadowStyle` | Surface colors, shadow geometry, and highlight strength. |
| `SensorShadow` | General-purpose decorated surface. |
| `SensorShadowCard` | Surface with card padding and margins. |
| `SensorShadowButton` | Material button with dynamic lighting. |

Public APIs include Dart documentation comments. Generate HTML API docs with
`dart doc`; output is written to `doc/api/`.

## Development and publishing

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test --coverage
cd example
flutter test
flutter build web --release
cd ..
dart doc
dart pub publish --dry-run
```

See [PUBLISHING.md](PUBLISHING.md) for the release checklist. This repository
contains no fabricated repository URLs; add your public repository and issue
tracker to `pubspec.yaml` before release if available. Publishing requires your
pub.dev account and ownership of the package name.

## License

[MIT](LICENSE).

Sensor integration uses [`sensors_plus`](https://pub.dev/packages/sensors_plus),
maintained by Flutter Community and licensed under BSD-3-Clause.
