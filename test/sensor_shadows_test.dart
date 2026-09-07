import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_shadows/sensor_shadows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SensorShadowController', () {
    late StreamController<TiltSample> samples;
    late SensorShadowController controller;

    setUp(() {
      samples = StreamController<TiltSample>.broadcast(sync: true);
      controller =
          SensorShadowController(samples: samples.stream, smoothing: 1);
    });
    tearDown(() async {
      controller.dispose();
      await samples.close();
    });

    test('normalizes gravity, rejects invalid readings, clamps manual input',
        () {
      samples.add(const TiltSample(-3, 4, 0));
      expect(controller.value, const Offset(0.6, 0.8));
      samples.add(const TiltSample(double.nan, 0, 0));
      samples.add(const TiltSample(0, 0, 0));
      samples.add(const TiltSample(double.maxFinite, double.maxFinite, 0));
      expect(controller.value, const Offset(0.6, 0.8));
      controller.setTilt(const Offset(3, -2));
      expect(controller.value, const Offset(1, -1));
      expect(() => controller.setTilt(const Offset(double.infinity, 0)),
          throwsArgumentError);
    });

    test('calibration centers current pose, reset clears calibration', () {
      samples.add(const TiltSample(-3, 4, 0));
      controller.calibrate();
      expect(controller.value, Offset.zero);
      samples.add(const TiltSample(-3, 4, 0));
      expect(controller.value, Offset.zero);
      controller.reset();
      samples.add(const TiltSample(-3, 4, 0));
      expect(controller.value, const Offset(0.6, 0.8));
    });

    test('start is idempotent; stop and background cancel subscription', () {
      controller.start();
      expect(samples.hasListener, isTrue);
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(samples.hasListener, isFalse);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(samples.hasListener, isTrue);
      controller.stop(resetTilt: true);
      expect(samples.hasListener, isFalse);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(samples.hasListener, isFalse);
      expect(controller.value, Offset.zero);
    });

    test('smooths readings and rotates axes', () {
      final smoothed = SensorShadowController(
          samples: samples.stream, smoothing: 0.5, quarterTurns: 1);
      addTearDown(smoothed.dispose);
      samples.add(const TiltSample(-10, 0, 0));
      expect(smoothed.value, const Offset(0, 0.5));
      samples.add(const TiltSample(-10, 0, 0));
      expect(smoothed.value, const Offset(0, 0.75));
    });

    test('reports errors, returns neutral, permits explicit restart', () {
      Object? reported;
      final failing = SensorShadowController(
          samples: samples.stream, onError: (error, _) => reported = error);
      addTearDown(failing.dispose);
      failing.setTilt(const Offset(1, 1));
      final error = StateError('sensor unavailable');
      // Stop the other listener so its independent error handler stays irrelevant.
      controller.stop();
      samples.addError(error, StackTrace.current);
      expect(reported, same(error));
      expect(failing.value, Offset.zero);
      expect(samples.hasListener, isFalse);
      failing.start();
      expect(samples.hasListener, isTrue);
    });

    test('validates configuration', () {
      expect(() => SensorShadowController(smoothing: 0), throwsArgumentError);
      expect(() => SensorShadowController(sensitivity: double.nan),
          throwsArgumentError);
      expect(() => SensorShadowController(samplingPeriod: Duration.zero),
          throwsArgumentError);
    });
  });

  BoxDecoration decoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((widget) => widget.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((decoration) => decoration.boxShadow != null);

  testWidgets('shared controller moves shadow without rebuilding content',
      (tester) async {
    final controller = SensorShadowController(autoStart: false);
    addTearDown(controller.dispose);
    var builds = 0;
    await tester.pumpWidget(MaterialApp(
        home: SensorShadowScope(
      controller: controller,
      child: SensorShadow(child: Builder(builder: (_) {
        builds++;
        return const SizedBox(width: 100, height: 100);
      })),
    )));
    final initialBuilds = builds;
    controller.setTilt(const Offset(1, -1));
    await tester.pump();
    expect(decoration(tester).boxShadow!.single.offset, const Offset(18, -14));
    expect(builds, initialBuilds);
  });

  testWidgets('reduced motion suppresses tilt', (tester) async {
    final controller = SensorShadowController(autoStart: false);
    addTearDown(controller.dispose);
    controller.setTilt(const Offset(1, 1));
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: SensorShadowScope(
          controller: controller,
          child: const SensorShadow(child: Text('Still'))),
    )));
    expect(decoration(tester).boxShadow!.single.offset, const Offset(0, 4));
  });

  testWidgets('scope replacement does not dispose external controllers',
      (tester) async {
    final first = SensorShadowController(autoStart: false);
    final second = SensorShadowController(autoStart: false);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget tree(SensorShadowController controller) => MaterialApp(
        home: SensorShadowScope(
            controller: controller,
            child: const SensorShadow(child: Text('Surface'))));
    await tester.pumpWidget(tree(first));
    await tester.pumpWidget(tree(second));
    first.setTilt(const Offset(-1, -1));
    second.setTilt(const Offset(1, 1));
    await tester.pump();
    expect(decoration(tester).boxShadow!.single.offset, const Offset(18, 22));
    await tester.pumpWidget(const SizedBox());
    second.setTilt(Offset.zero);
    expect(second.value, Offset.zero);
  });

  testWidgets('missing scope renders neutral', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: SensorShadow(child: Text('Fallback'))));
    expect(decoration(tester).boxShadow!.single.offset, const Offset(0, 4));
  });

  testWidgets('button supports keyboard, taps, and disabled semantics',
      (tester) async {
    var presses = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      SensorShadowButton(
          focusNode: focus,
          onPressed: () => presses++,
          child: const Text('Press')),
      const SensorShadowButton(onPressed: null, child: Text('Disabled')),
    ]))));
    await tester.tap(find.text('Press'));
    expect(presses, 1);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(presses, 2);
    await tester.tap(find.text('Disabled'));
    expect(presses, 2);
    expect(
        tester.getSemantics(find.widgetWithText(TextButton, 'Disabled')),
        matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isFocusable: false,
            label: 'Disabled',
            textDirection: TextDirection.ltr));
    semantics.dispose();
  });

  test('lighting direction is opposite shadow travel', () {
    const style = SensorShadowStyle();
    final decoration = style.decorationFor(const Offset(1, 1));
    final gradient = decoration.gradient! as LinearGradient;
    expect((gradient.begin as Alignment).x, lessThan(0));
    expect((gradient.begin as Alignment).y, lessThan(0));
    expect(decoration.boxShadow!.single.offset.dx, greaterThan(0));
  });
}
