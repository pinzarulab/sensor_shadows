import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_shadows_example/main.dart';

void main() {
  testWidgets('studio supports manual tilt and reset', (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const LightingStudio());
    expect(find.text('Lighting desk'), findsOneWidget);
    await tester.tap(find.text('Manual tilt'));
    await tester.pumpAndSettle();
    expect(find.text('Horizontal'), findsOneWidget);
    final slider = find.byType(Slider).first;
    await tester.drag(slider, const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(find.text('X 0.00   /   Y 0.00'), findsNothing);
    await tester.ensureVisible(find.text('Reset tilt'));
    await tester.tap(find.text('Reset tilt'));
    await tester.pumpAndSettle();
    expect(find.text('X 0.00   /   Y 0.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('studio fits a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const LightingStudio());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
