import 'package:flutter_test/flutter_test.dart';
import 'package:metra_weather_intelligence/screens/operations_workspace.dart';

void main() {
  test('workspace catalogue exposes the core METRA operational modules', () {
    final modules = workspaceModules.map((item) => item.module).toSet();
    expect(modules, contains(WorkspaceModule.forecastCenter));
    expect(modules, contains(WorkspaceModule.forecastOffice));
    expect(modules, contains(WorkspaceModule.bulletins));
    expect(modules, contains(WorkspaceModule.electronicAudit));
    expect(modules, contains(WorkspaceModule.paperAudit));
    expect(modules, contains(WorkspaceModule.aiModelManagement));
    expect(modules, contains(WorkspaceModule.aftn));
    expect(modules, contains(WorkspaceModule.climatol));
    expect(modules, contains(WorkspaceModule.homogenization));
    expect(modules, contains(WorkspaceModule.reports));
    expect(modules, contains(WorkspaceModule.userAccess));
    expect(modules, contains(WorkspaceModule.stationReview));
    expect(modules, contains(WorkspaceModule.registrationApprovals));
  });

  test('AFTN address validation accepts only four Latin letters', () {
    expect(isValidAftnAddress('OSDI'), isTrue);
    expect(isValidAftnAddress('osdi'), isTrue);
    expect(isValidAftnAddress('OSD'), isFalse);
    expect(isValidAftnAddress('OSD1'), isFalse);
    expect(isValidAftnAddress(' دمشق'), isFalse);
  });

  test('AFTN priority validation uses the defined priority indicators', () {
    for (final value in ['SS', 'DD', 'FF', 'GG', 'KK']) {
      expect(isValidAftnPriority(value), isTrue);
    }
    expect(isValidAftnPriority('XX'), isFalse);
  });

  testWidgets('forecast center displays coordinate and altitude comparison controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForecastCenterPage()));
    expect(find.text('مراكز التنبؤ الجوي'), findsOneWidget);
    expect(find.text('نطاق الارتفاع'), findsOneWidget);
    expect(find.text('اتجاه الرياح'), findsOneWidget);
    expect(find.text('لا توجد قراءات لحظية متاحة'), findsOneWidget);
  });

  testWidgets('AFTN screen keeps transmission disabled without a gateway', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AftnWorkspacePage()));
    expect(find.text('مركز AFTN'), findsOneWidget);
    expect(find.text('إرسال AFTN'), findsOneWidget);
    expect(find.text('لا يوجد اتصال مع محطة الرسائل أو بوابة الإرسال. الإرسال معطل حتى اعتماد إعدادات الاتصال والمراقبة.'), findsOneWidget);
  });
}

  testWidgets('paper and mechanical audit screen exposes three-source review', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PaperAndRecorderAuditPage()));
    expect(find.text('تدقيق السجلات الورقية والآلية'), findsOneWidget);
    expect(find.text('مقارنة المصادر'), findsOneWidget);
    expect(find.text('لا يتم تعديل الصورة أو السجل الأصلي.'), findsNothing);
  });

  testWidgets('climate homogenization screen preserves raw series boundary', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClimateHomogenizationPage()));
    expect(find.text('تجانس السلاسل المناخية'), findsOneWidget);
    expect(find.textContaining('تبقى السلسلة الخام محفوظة'), findsOneWidget);
    expect(find.text('نقاط الانقطاع'), findsOneWidget);
  });
