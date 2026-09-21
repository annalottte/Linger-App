import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/linger_models.dart';
import 'motion_sensor.dart';

class LingerController extends ChangeNotifier {
  final MotionSensor sensor;
  final int graceSeconds;

  final List<LingerEvent> _events = <LingerEvent>[];
  late final StreamSubscription<MotionSample> _sampleSubscription;

  Timer? _graceTimer;
  bool _hasWarnedThisIncident = false;
  bool _isDisposed = false;

  bool isSessionRunning = false;
  LingerState state = LingerState.extinguished;
  int graceRemaining = 0;
  LingerLifecycle lifecycle = LingerLifecycle.active;
  MotionSample latestSample = MotionSample(
    timestamp: DateTime(2026, 1, 1),
    orientation: FaceOrientation.faceDown,
    motionMagnitude: 0,
    isMoving: false,
  );

  LingerController({
    required this.sensor,
    this.graceSeconds = 10,
  })  : assert(graceSeconds > 0),
        super() {
    _sampleSubscription = sensor.samples.listen(updateSample);
  }

  List<LingerEvent> get events => List<LingerEvent>.unmodifiable(_events);

  void toggleSession() {
    if (isSessionRunning) {
      stopSession();
    } else {
      startSession();
    }
  }

  void startSession() {
    if (isSessionRunning) {
      return;
    }

    isSessionRunning = true;
    state = LingerState.burning;
    graceRemaining = 0;
    _hasWarnedThisIncident = false;
    _log('Session started. Fire is burning.');
    sensor.start();
    _notifyListeners();
  }

  void stopSession() {
    if (!isSessionRunning) {
      return;
    }

    isSessionRunning = false;
    sensor.stop();
    _cancelGraceTimer();
    state = LingerState.extinguished;
    graceRemaining = 0;
    _hasWarnedThisIncident = false;
    _log('Session stopped. Fire extinguished.');
    _notifyListeners();
  }

  void setLifecycle(LingerLifecycle nextLifecycle) {
    if (lifecycle == nextLifecycle) {
      return;
    }

    lifecycle = nextLifecycle;
    _log('Lifecycle changed to ${nextLifecycle.label.toLowerCase()}.');
    _evaluateSignals();
    _notifyListeners();
  }

  void updateSample(MotionSample sample) {
    if (_isDisposed) {
      return;
    }

    latestSample = sample;
    _evaluateSignals();
    _notifyListeners();
  }

  void _evaluateSignals() {
    if (!isSessionRunning) {
      return;
    }

    if (lifecycle != LingerLifecycle.active) {
      _pauseForLifecycle();
      return;
    }

    if (state == LingerState.extinguished) {
      return;
    }

    final isHealthy =
        latestSample.orientation == FaceOrientation.faceDown &&
            !latestSample.isMoving;

    if (isHealthy) {
      _recoverIfNeeded();
    } else {
      _beginWarningIfNeeded();
    }
  }

  void _pauseForLifecycle() {
    if (state == LingerState.extinguished) {
      return;
    }

    _cancelGraceTimer();
    graceRemaining = 0;
    if (state != LingerState.paused) {
      state = LingerState.paused;
      _log('Monitoring paused until the app is active again.');
    }
  }

  void _beginWarningIfNeeded() {
    if (state == LingerState.extinguished || state == LingerState.warning) {
      return;
    }

    state = LingerState.warning;
    graceRemaining = graceSeconds;
    if (!_hasWarnedThisIncident) {
      _log('Fire warning: flickering ($graceSeconds seconds grace).');
      _hasWarnedThisIncident = true;
    }
    _startGraceTimer();
  }

  void _recoverIfNeeded() {
    if (state == LingerState.warning) {
      _cancelGraceTimer();
      state = LingerState.burning;
      graceRemaining = 0;
      _hasWarnedThisIncident = false;
      _log('Fire saved. Back to burning.');
    } else if (state == LingerState.paused) {
      state = LingerState.burning;
      graceRemaining = 0;
      _hasWarnedThisIncident = false;
      _log('Monitoring resumed. Fire is burning.');
    }
  }

  void _startGraceTimer() {
    _cancelGraceTimer();
    _graceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isSessionRunning ||
          lifecycle != LingerLifecycle.active ||
          state != LingerState.warning) {
        _cancelGraceTimer();
        return;
      }

      graceRemaining -= 1;
      if (graceRemaining <= 0) {
        _cancelGraceTimer();
        state = LingerState.extinguished;
        _log('Fire extinguished.');
      }
      _notifyListeners();
    });
  }

  void _cancelGraceTimer() {
    _graceTimer?.cancel();
    _graceTimer = null;
  }

  void _log(String message) {
    _events.insert(
      0,
      LingerEvent(
        timestamp: DateTime.now(),
        message: message,
      ),
    );
    if (_events.length > 250) {
      _events.removeRange(250, _events.length);
    }
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _cancelGraceTimer();
    sensor.stop();
    _sampleSubscription.cancel();
    sensor.dispose();
    super.dispose();
  }
}
