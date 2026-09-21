enum LingerState {
  burning,
  warning,
  paused,
  extinguished,
}

extension LingerStatePresentation on LingerState {
  String get label {
    switch (this) {
      case LingerState.burning:
        return 'Burning';
      case LingerState.warning:
        return 'Needs attention';
      case LingerState.paused:
        return 'Paused';
      case LingerState.extinguished:
        return 'Extinguished';
    }
  }

  String get description {
    switch (this) {
      case LingerState.burning:
        return 'The phone is still and face down.';
      case LingerState.warning:
        return 'Put the phone back before the grace period ends.';
      case LingerState.paused:
        return 'Monitoring is paused while the app is inactive.';
      case LingerState.extinguished:
        return 'Start a session to light the fire.';
    }
  }
}

enum FaceOrientation {
  faceUp,
  faceDown,
  vertical,
  unknown,
}

extension FaceOrientationPresentation on FaceOrientation {
  String get label {
    switch (this) {
      case FaceOrientation.faceUp:
        return 'Face up';
      case FaceOrientation.faceDown:
        return 'Face down';
      case FaceOrientation.vertical:
        return 'Vertical';
      case FaceOrientation.unknown:
        return 'Unknown';
    }
  }
}

enum LingerLifecycle {
  active,
  inactive,
  background,
  detached,
}

extension LingerLifecyclePresentation on LingerLifecycle {
  String get label {
    switch (this) {
      case LingerLifecycle.active:
        return 'Active';
      case LingerLifecycle.inactive:
        return 'Inactive';
      case LingerLifecycle.background:
        return 'Background';
      case LingerLifecycle.detached:
        return 'Detached';
    }
  }
}

class MotionSample {
  final DateTime timestamp;
  final FaceOrientation orientation;
  final double motionMagnitude;
  final bool isMoving;

  const MotionSample({
    required this.timestamp,
    required this.orientation,
    required this.motionMagnitude,
    required this.isMoving,
  });
}

class LingerEvent {
  final DateTime timestamp;
  final String message;

  const LingerEvent({
    required this.timestamp,
    required this.message,
  });
}
