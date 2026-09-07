# Sensor Shadows — Lighting Studio

A complete Material 3 app showcasing shared tilt-driven cards, buttons, and
surfaces. Includes manual tilt sliders, live coordinates, calibration, shadow
travel, reduced-motion handling, and sensor-error feedback.

```sh
flutter pub get
flutter run -d chrome
```

Enable **Manual tilt** on desktop. To feel the accelerometer effect, run
`flutter run` with an Android or iOS device attached. The iOS motion usage string
is already configured. Select your own development team in Xcode for device
signing; no developer identity is included in this example.

Sensor coordinates assume portrait use. The UI remains responsive in landscape,
but native axes are not automatically remapped. See the package README for
`quarterTurns` and custom input.

```sh
flutter test
flutter build web --release
```
