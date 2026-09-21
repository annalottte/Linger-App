import 'package:flutter/material.dart';

import 'models/linger_models.dart';
import 'screens/linger_home_page.dart';
import 'services/linger_controller.dart';
import 'services/motion_sensor.dart';

void main() {
  final demoSensor = DemoMotionSensor();
  final controller = LingerController(sensor: demoSensor);
  runApp(
    LingerApp(
      controller: controller,
      demoSensor: demoSensor,
    ),
  );
}

class LingerApp extends StatefulWidget {
  final LingerController controller;
  final DemoMotionSensor demoSensor;

  const LingerApp({
    super.key,
    required this.controller,
    required this.demoSensor,
  });

  @override
  State<LingerApp> createState() => _LingerAppState();
}

class _LingerAppState extends State<LingerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.controller.setLifecycle(_mapLifecycle(state));
  }

  LingerLifecycle _mapLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        return LingerLifecycle.active;
      case AppLifecycleState.inactive:
        return LingerLifecycle.inactive;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        return LingerLifecycle.background;
      case AppLifecycleState.detached:
        return LingerLifecycle.detached;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ember = Color(0xFFD95F39);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ember,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Linger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F5F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F5F0),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: LingerHomePage(
        controller: widget.controller,
        demoSensor: widget.demoSensor,
      ),
    );
  }
}
