# Release checklist

1. Review `pubspec.yaml`, `CHANGELOG.md`, `README.md`, and `LICENSE`. Set the
   intended version and confirm the copyright holder. Add real `repository`
   and `issue_tracker` URLs when the package has a public repository.
2. Run all validation commands in the README. Review generated Dart API docs.
3. Test the example on physical Android and iOS devices: tilt in both axes,
   calibrate, background/resume, disable motion, and enable OS reduced motion.
   Automated tests and a web build cannot verify physical sensor behavior.
4. Review `dart pub publish --dry-run` output, including every archived path.
   Platform signing files, caches, and build output must not be included.
5. Confirm that `sensor_shadows` is available or owned by your pub.dev account.
   Authenticate through the Dart publisher flow, then run `dart pub publish`
   when ready to make the release public.
6. Tag the released version in your source repository and retain its changelog.

The GitHub Actions workflow validates pull requests and pushes. It deliberately
contains no automated publishing or signing credentials.
