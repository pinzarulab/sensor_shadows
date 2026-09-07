import 'package:flutter/material.dart';
import 'package:sensor_shadows/sensor_shadows.dart';

void main() => runApp(const LightingStudio());

/// Complete interactive demo of shared sensor lighting and manual tilt.
class LightingStudio extends StatelessWidget {
  /// Creates the example application.
  const LightingStudio({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sensor Shadows · Lighting Studio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF365E4D)),
          scaffoldBackgroundColor: const Color(0xFFE9E8E2),
          fontFamily: 'sans-serif',
        ),
        home: const _Studio(),
      );
}

class _Studio extends StatefulWidget {
  const _Studio();
  @override
  State<_Studio> createState() => _StudioState();
}

class _StudioState extends State<_Studio> {
  late final SensorShadowController _controller;
  bool _manual = false;
  bool _motion = true;
  double _depth = 22;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = SensorShadowController(
        autoStart: false,
        onError: (error, stack) {
          if (mounted) {
            setState(() {
              _error = 'Sensor unavailable. Try manual tilt below.';
              _manual = true;
            });
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSampling();
  }

  void _syncSampling() {
    if (!_manual && _motion && !MediaQuery.of(context).disableAnimations) {
      _controller.start();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = SensorShadowStyle(maxOffset: _depth);
    return SensorShadowScope(
      controller: _controller,
      enabled: _motion,
      child: Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(padding: const EdgeInsets.all(28), children: [
            const Wrap(
                spacing: 10,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.blur_on, size: 28),
                  SizedBox(width: 10),
                  Text('SENSOR SHADOWS',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: 2)),
                  Text('EXAMPLE / 01'),
                ]),
            const SizedBox(height: 48),
            Text('A little tilt.\nA whole new dimension.',
                style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600, letterSpacing: -1.5)),
            const SizedBox(height: 16),
            Text(
                'Light that follows your hands. Tilt your phone to move the '
                'shadows, or explore with the manual controls.',
                style: text.bodyLarge),
            const SizedBox(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              final showcase = _showcase(style, text);
              final controls = _controls(text);
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Expanded(flex: 3, child: showcase),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: controls)
                        ])
                  : Column(children: [
                      showcase,
                      const SizedBox(height: 32),
                      controls
                    ]);
            }),
            const SizedBox(height: 40),
            Text('ONE SENSOR STREAM · SHARED LIGHT · BUILT WITH FLUTTER',
                style: text.labelSmall?.copyWith(letterSpacing: 1.3)),
          ]),
        ))),
      ),
    );
  }

  Widget _showcase(SensorShadowStyle style, TextTheme text) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SensorShadowCard(
              style: style,
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.landscape_outlined),
                      SizedBox(width: 12),
                      Flexible(child: Text('FIELD NOTES / 024'))
                    ]),
                    const SizedBox(height: 48),
                    Text('Feel the surface.', style: text.headlineMedium),
                    const SizedBox(height: 12),
                    const Text(
                        'A soft card. A moving shadow.\nSmall details that feel physical.'),
                    const SizedBox(height: 32),
                    const Row(children: [
                      Icon(Icons.circle, size: 8),
                      SizedBox(width: 8),
                      Flexible(child: Text('LIVE LIGHTING'))
                    ]),
                  ])),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: SensorShadowButton(
                    style: SensorShadowStyle(
                        color: const Color(0xFF365E4D),
                        maxOffset: _depth,
                        lightIntensity: 0.12,
                        borderRadius: BorderRadius.circular(16)),
                    foregroundColor: Colors.white,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('A small press. A tactile detail.'))),
                    child: const Text('Give it a press'))),
            const SizedBox(width: 20),
            const SensorShadowButton(onPressed: null, child: Text('Disabled')),
          ]),
          const SizedBox(height: 32),
          Row(children: [
            for (final color in [
              const Color(0xFFD5A77B),
              const Color(0xFF91A99B),
              const Color(0xFFAAA4BA)
            ]) ...[
              Expanded(
                  child: SensorShadow(
                      style: SensorShadowStyle(
                          color: color,
                          maxOffset: _depth,
                          borderRadius: BorderRadius.circular(20)),
                      child: const SizedBox(
                          height: 86,
                          child: Icon(Icons.wb_sunny_outlined,
                              color: Colors.white)))),
              if (color != const Color(0xFFAAA4BA)) const SizedBox(width: 18),
            ],
          ]),
        ],
      );

  Widget _controls(TextTheme text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCECEC5)),
            borderRadius: BorderRadius.circular(24)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Lighting desk', style: text.titleLarge),
          const SizedBox(height: 8),
          const Text('Portrait sensor axes. Calibrate while holding your phone '
              'in a comfortable position.'),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(_error!)),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Motion enabled'),
              value: _motion,
              onChanged: (value) {
                setState(() => _motion = value);
                _syncSampling();
              }),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manual tilt'),
              value: _manual,
              onChanged: (value) {
                setState(() => _manual = value);
                _syncSampling();
              }),
          ValueListenableBuilder<Offset>(
              valueListenable: _controller,
              builder: (context, tilt, _) => Column(children: [
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 90,
                        child: Center(
                            child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: const Color(0xFFB5B9AC))),
                          child: Align(
                              alignment: Alignment(tilt.dx, tilt.dy),
                              child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.circle,
                                      size: 16, color: Color(0xFF365E4D)))),
                        ))),
                    const SizedBox(height: 12),
                    Text(
                        'X ${tilt.dx.toStringAsFixed(2)}   /   Y ${tilt.dy.toStringAsFixed(2)}'),
                    if (_manual) ...[
                      const SizedBox(height: 12),
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Horizontal')),
                      Slider(
                          value: tilt.dx,
                          min: -1,
                          max: 1,
                          semanticFormatterCallback: (value) =>
                              'Horizontal tilt $value',
                          onChanged: (x) =>
                              _controller.setTilt(Offset(x, tilt.dy))),
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Vertical')),
                      Slider(
                          value: tilt.dy,
                          min: -1,
                          max: 1,
                          semanticFormatterCallback: (value) =>
                              'Vertical tilt $value',
                          onChanged: (y) =>
                              _controller.setTilt(Offset(tilt.dx, y))),
                    ],
                  ])),
          const SizedBox(height: 16),
          Text('Shadow travel · ${_depth.round()} px'),
          Slider(
              value: _depth,
              min: 0,
              max: 40,
              onChanged: (value) => setState(() => _depth = value)),
          OutlinedButton(
              onPressed: _manual
                  ? () => _controller.setTilt(Offset.zero)
                  : _controller.calibrate,
              child: Text(_manual ? 'Reset tilt' : 'Calibrate pose')),
          if (MediaQuery.of(context).disableAnimations)
            const Text('Reduced motion is enabled. Surfaces stay still.'),
        ]),
      );
}
