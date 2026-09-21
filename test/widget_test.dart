import 'package:flutter_test/flutter_test.dart';

import 'package:linger_app/main.dart';
import 'package:linger_app/services/linger_controller.dart';
import 'package:linger_app/services/motion_sensor.dart';

void main() {
  testWidgets('starts a demo session from the home page',
      (WidgetTester tester) async {
    final demoSensor = DemoMotionSensor();
    final controller = LingerController(sensor: demoSensor);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LingerApp(
        controller: controller,
        demoSensor: demoSensor,
      ),
    );

    expect(find.text('Linger'), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);

    await tester.tap(find.text('Start session'));
    await tester.pump();

    expect(find.text('Stop session'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });
}
