import 'package:flutter_test/flutter_test.dart';
import 'package:metra_weather_intelligence/main.dart';

void main() {
  testWidgets('METRA fails closed when public authentication configuration is absent', (tester) async {
    await tester.pumpWidget(const MetraWeatherApp());

    expect(find.text('لم يتم إعداد اتصال METRA'), findsOneWidget);
    expect(find.text('الرئيسية'), findsNothing);
    expect(find.text('الرصد'), findsNothing);
    expect(find.text('محطة الرياض'), findsNothing);
  });

  testWidgets('configuration warning explains that protected data remains unavailable', (tester) async {
    await tester.pumpWidget(const MetraWeatherApp());

    expect(
      find.textContaining('لن تُعرض أي بيانات محمية دون اتصال موثوق'),
      findsOneWidget,
    );
  });
}
