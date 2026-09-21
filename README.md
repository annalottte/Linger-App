# Linger App

Cross-platform Flutter scaffold for the Linger motion-session experiment.

## Current boundary

The app currently uses a deterministic demo sensor, so it can be developed on Windows without a Mac or device sensors. The state machine already models the important product behavior:

- A session is healthy when the app is active, the phone is face down, and the device is still.
- An unhealthy active sample starts a 10-second warning period.
- An inactive, background, or detached app enters `paused` and cancels the warning timer rather than falsely extinguishing the session.
- Extinguished sessions remain terminal until the user starts a new session.

Raw motion samples stay local. The `MotionSensor` interface is the seam for a future native iOS/Android implementation.

## Project layout

```text
lib/
	main.dart                         App lifecycle bridge and Material app
	models/linger_models.dart         Shared state and sensor data types
	services/motion_sensor.dart       Sensor interface and deterministic demo source
	services/linger_controller.dart   Local session state machine
	screens/linger_home_page.dart     Scaffold UI and demo controls
test/linger_controller_test.dart    Warning and lifecycle tests
```

## Run on Windows

Install the Flutter stable SDK and verify it with `flutter doctor`. From this directory:

```powershell
flutter create . --platforms=android,windows,web
flutter pub get
flutter test
flutter run -d windows
```

You can also use `flutter run -d chrome` for a quick UI check.

## Test on iPhone from Windows

For the current UI and demo state machine, build the web version and serve it on your local network:

```powershell
flutter build web --release
python -m http.server 8081 --directory build/web --bind 0.0.0.0
```

Find the PC's Wi-Fi IPv4 address with `ipconfig`, then open `http://<PC-IP>:8081` in Safari on an iPhone connected to the same Wi-Fi. This tests the interface and demo controls, not physical motion. Stop the server with `Ctrl+C`.

## Native iPhone deployment

Native iOS builds require macOS and Xcode. The practical options are:

1. On a Mac, clone this repository, run `flutter create . --platforms=ios`, connect the iPhone, trust the computer, and run `flutter run -d <device-id>`.
2. Push the repository to GitHub and use a cloud macOS builder such as Codemagic or Bitrise. Connect an Apple Developer account, configure iOS signing, build an `.ipa`, and distribute it through TestFlight.

The current app will install as a native iOS app once built, but it still uses `DemoMotionSensor`. Physical pick-up and orientation detection requires a native iOS `MotionSensor` adapter using Core Motion; that adapter should be added before treating an iPhone build as sensor validation.

## Demo flow

1. Start a session.
2. Select `Picked up` under `Demo sensor` to enter the warning state.
3. Select `Still and face down` before the countdown reaches zero to recover.
4. Minimize the app while a session is running to exercise the lifecycle pause path.

## Next implementation step

Add native `MotionSensor` adapters for iOS and Android. They should translate platform samples into `MotionSample` values and leave `LingerController` unchanged. Sensor permissions, sampling rates, background restrictions, and device-specific tuning should be handled inside those adapters.