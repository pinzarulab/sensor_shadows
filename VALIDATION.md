# Validation record

Validated on 2026-09-08 with Flutter 3.47.0 / Dart 3.13.0, macOS arm64.

| Check | Result |
| --- | --- |
| Dart formatting | Passed; no changes required. |
| `flutter analyze` | Passed; no issues. |
| Package tests | 14 passed; 185/209 lines covered (88.5%). |
| Example widget tests | 2 passed, including 360 px layout at 150% text scale. |
| `dart doc` | Generated HTML API docs; zero warnings or errors. |
| Web release build | Passed, including compiler Wasm compatibility dry run. |
| Android debug APK | Built successfully. |
| iOS simulator app | Built successfully without code signing. |
| Browser interaction | Manual X tilt changed from 0.00 to 0.66; highlights and shadows moved. |
| Publication dry run | Previous archive validated; its repository metadata warning is addressed. Final 0.1.2 dry run awaits explicit authorization for the tool's pub.dev connection. |

The web compiler emitted a non-fatal missing CupertinoIcons font notice from
framework icon discovery; this Material-only example renders its icons correctly.

Physical-device accelerometer behavior and actual publication were not performed.
The declared minimum SDK versions were not tested with separate SDK installations.
