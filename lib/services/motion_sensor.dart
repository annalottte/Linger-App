import 'dart:async';

import '../models/linger_models.dart';

enum DemoSensorCondition {
  steady,
  pickedUp,
}

extension DemoSensorConditionPresentation on DemoSensorCondition {
  String get label {
    switch (this) {
      case DemoSensorCondition.steady:
        return 'Still and face down';
      case DemoSensorCondition.pickedUp:
        return 'Picked up';
    }
  }
}

abstract interface class MotionSensor {
  Stream<MotionSample> get samples;

  void start();

  void stop();

  void dispose();
}

class DemoMotionSensor implements MotionSensor {
  final Duration sampleInterval;
  final StreamController<MotionSample> _sampleController =
      StreamController<MotionSample>.broadcast();

  Timer? _timer;
  DemoSensorCondition _condition = DemoSensorCondition.steady;
  bool _isRunning = false;
  bool _isDisposed = false;

  DemoMotionSensor({
    this.sampleInterval = const Duration(milliseconds: 200),
  });

  DemoSensorCondition get condition => _condition;

  @override
  Stream<MotionSample> get samples => _sampleController.stream;

  void setCondition(DemoSensorCondition condition) {
    if (_isDisposed) {
      return;
    }

    _condition = condition;
    if (_isRunning) {
      _emitSample();
    }
  }

  @override
  void start() {
    if (_isDisposed || _isRunning) {
      return;
    }

    _isRunning = true;
    _emitSample();
    _timer = Timer.periodic(sampleInterval, (_) => _emitSample());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void _emitSample() {
    final isPickedUp = _condition == DemoSensorCondition.pickedUp;
    _sampleController.add(
      MotionSample(
        timestamp: DateTime.now(),
        orientation:
            isPickedUp ? FaceOrientation.vertical : FaceOrientation.faceDown,
        motionMagnitude: isPickedUp ? 0.42 : 0.04,
        isMoving: isPickedUp,
      ),
    );
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    stop();
    _isDisposed = true;
    _sampleController.close();
  }
}
