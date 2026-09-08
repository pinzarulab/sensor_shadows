## 0.1.2

- Add `SensorShadows`, an app-level wrapper for one shared controller across
  every route, dialog, and overlay.
- Respect platform reduced-motion settings when the scope sits above
  `MaterialApp` and no `MediaQuery` exists yet.
- Document Flutter's boundary for stock Material and arbitrary box shadows.

## 0.1.1

- Fix surface lighting gradient on widgets.

## 0.1.0

- Add `SensorShadow`, `SensorShadowCard`, and accessible `SensorShadowButton`.
- Share one accelerometer subscription with `SensorShadowScope`.
- Add configurable smoothing, sensitivity, axis rotation, and pose calibration.
- Render directional highlights opposite moving cast shadows.
- Pause sensor sampling in the background and respect reduced-motion settings.
- Support manual tilt, injectable sensor streams, and neutral hardware fallbacks.
- Include Android, iOS, and web example apps with interactive lighting controls.
- Add API documentation, tests, MIT license, and release validation workflow.
