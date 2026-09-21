import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linger_app/models/linger_models.dart';
import 'package:linger_app/services/linger_controller.dart';
import 'package:linger_app/services/motion_sensor.dart';

void main() {
  test('an unhealthy active sample starts the warning grace period', () {
    final sensor = FakeMotionSensor();
    final controller = LingerController(sensor: sensor);
    addTearDown(controller.dispose);

    controller.startSession();
    sensor.emit(_sample(FaceOrientation.faceUp, moving: true));

    expect(controller.state, LingerState.warning);
    expect(controller.graceRemaining, 10);
    expect(controller.events.first.message, contains('warning'));
  });

  test('a lifecycle gap pauses monitoring instead of extinguishing it', () {
    final sensor = FakeMotionSensor();
    final controller = LingerController(sensor: sensor);
    addTearDown(controller.dispose);

    controller.startSession();
    sensor.emit(_sample(FaceOrientation.faceUp, moving: true));
    controller.setLifecycle(LingerLifecycle.background);

    expect(controller.state, LingerState.paused);
    expect(controller.graceRemaining, 0);

    sensor.emit(_sample(FaceOrientation.faceDown, moving: false));
    expect(controller.state, LingerState.paused);

    controller.setLifecycle(LingerLifecycle.active);

    expect(controller.state, LingerState.burning);
  });
}

MotionSample _sample(FaceOrientation orientation, {required bool moving}) {
  return MotionSample(
    timestamp: DateTime(2026, 1, 1),
    orientation: orientation,
    motionMagnitude: moving ? 0.5 : 0.02,
    isMoving: moving,
  );
}

class FakeMotionSensor implements MotionSensor {
  final StreamController<MotionSample> _controller =
  StreamController<MotionSample>.broadcast(sync: true);

  bool isStarted = false;

  @override
  Stream<MotionSample> get samples => _controller.stream;

  @override
  void start() {
    isStarted = true;
  }

  @override
  void stop() {
    isStarted = false;
  }

  void emit(MotionSample sample) {
    _controller.add(sample);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
