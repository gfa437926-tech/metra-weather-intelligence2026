import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metra_weather_intelligence/screens/operations_workspace.dart';
import 'package:metra_weather_intelligence/screens/observation_forms_catalogue_page.dart';
import 'package:metra_weather_intelligence/domain/station_record.dart';

void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('workspace catalogue exposes the core METRA operational modules', () {
    final modules = workspaceModules.map((item) => item.module).toSet();
    expect(modules, contains(WorkspaceModule.observationForms));
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

  test('AFTN address validation accepts only eight Latin letters', () {
    expect(isValidAftnAddress('ABCDWXYZ'), isTrue);
    expect(isValidAftnAddress('abcdwxyz'), isTrue);
    expect(isValidAftnAddress('ABCD'), isFalse);
    expect(isValidAftnAddress('ABCD1234'), isFalse);
    expect(isValidAftnAddress(' دمشق'), isFalse);
  });

  test('AFTN priority validation uses the defined priority indicators', () {
    for (final value in ['SS', 'DD', 'FF', 'GG', 'KK']) {
      expect(isValidAftnPriority(value), isTrue);
    }
    expect(isValidAftnPriority('XX'), isFalse);
  });

  test('forecast-centre coordinate and elevation validators reject invalid bounds', () {
    expect(isValidLatitude('90'), isTrue);
    expect(isValidLatitude('-90'), isTrue);
    expect(isValidLatitude('90.01'), isFalse);
    expect(isValidLatitude('north'), isFalse);
    expect(isValidLongitude('180'), isTrue);
    expect(isValidLongitude('-180'), isTrue);
    expect(isValidLongitude('180.1'), isFalse);
    expect(isValidLatitudeRange('-30', '60'), isTrue);
    expect(isValidLatitudeRange('60', '-30'), isFalse);
    expect(isValidLongitudeRange('-180', '180'), isTrue);
    expect(isValidLongitudeRange('10', '181'), isFalse);
    expect(isValidElevationRange('10', '100'), isTrue);
    expect(isValidElevationRange('100', '10'), isFalse);
    expect(isValidElevationRange('low', '100'), isFalse);
    expect(isValidElevationRange('10', ''), isFalse);
    expect(isValidElevationRange('-500', '9000'), isTrue);
    expect(isValidElevationRange('-501', '100'), isFalse);
    expect(isValidElevationRange('10', '9001'), isFalse);
  });

  testWidgets('forecast centre displays coordinate and altitude comparison controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForecastCenterPage()));
    expect(find.text('مراكز التنبؤ الجوي'), findsOneWidget);
    expect(find.text('نطاق الارتفاع'), findsOneWidget);
    expect(find.text('خط العرض من'), findsOneWidget);
    expect(find.text('خط الطول إلى'), findsOneWidget);
    expect(find.text('نافذة المقارنة الزمنية'), findsOneWidget);
    expect(find.text('الارتفاع من (م)'), findsOneWidget);
    expect(find.text('التحقق من حدود المقارنة'), findsOneWidget);
    expect(find.text('دليل المحطات غير مهيأ'), findsOneWidget);
    expect(find.text('تحديد المنطقة عبر نطاق الإحداثيات الجغرافية (درجات عشرية)'), findsOneWidget);
  });

  testWidgets('forecast centre filters real station metadata and opens a detailed station card', (tester) async {
    useTallViewport(tester);
    final stations = [
      const StationRecord(id: 'station-1', code: 'STN001', name: 'محطة دمشق', type: 'classic', operationalStatus: 'active', approvalStatus: 'approved', latitude: 33.5, longitude: 36.3, elevationM: 545.5),
      const StationRecord(id: 'station-2', code: 'STN002', name: 'محطة جبلية', type: 'automatic', operationalStatus: 'active', approvalStatus: 'approved', latitude: 35.0, longitude: 38.0, elevationM: 1200),
    ];
    await tester.pumpWidget(MaterialApp(home: ForecastCenterPage(stationRecordsOverride: stations)));
    await tester.pumpAndSettle();
    expect(find.text('محطة دمشق'), findsOneWidget);
    expect(find.text('محطة جبلية'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('forecast-lat-from')), '34');
    await tester.enterText(find.byKey(const Key('forecast-lat-to')), '36');
    await tester.enterText(find.byKey(const Key('forecast-lon-from')), '37');
    await tester.enterText(find.byKey(const Key('forecast-lon-to')), '39');
    await tester.pumpAndSettle();
    expect(find.text('محطة جبلية'), findsOneWidget);
    expect(find.text('محطة دمشق'), findsNothing);
    for (final key in ['forecast-lat-from', 'forecast-lat-to', 'forecast-lon-from', 'forecast-lon-to']) {
      await tester.enterText(find.byKey(Key(key)), '');
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forecast-altitude-band')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('500 إلى أقل من 1000 م').last);
    await tester.pumpAndSettle();
    expect(find.text('محطة دمشق'), findsOneWidget);
    expect(find.text('محطة جبلية'), findsNothing);
    await tester.tap(find.text('محطة دمشق'));
    await tester.pumpAndSettle();
    expect(find.text('545.5 م'), findsOneWidget);
    expect(find.text('33.50000, 36.30000'), findsOneWidget);
    expect(find.text('لا توجد قراءة محملة'), findsWidgets);
  });

  testWidgets('forecaster workspace exposes UTC validity and core forecast elements', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForecastOfficePage()));
    expect(find.text('مكتب المتنبئ'), findsOneWidget);
    expect(find.text('وقت إصدار التوقع UTC'), findsOneWidget);
    expect(find.text('بداية الصلاحية UTC'), findsOneWidget);
    expect(find.text('نهاية الصلاحية UTC'), findsOneWidget);
    expect(find.text('الهطول المتوقع مم'), findsOneWidget);
    expect(find.text('اتجاه الرياح'), findsOneWidget);
    expect(find.text('الظواهر الجوية المتوقعة'), findsOneWidget);
  });

  testWidgets('forecaster rejects invalid UTC order and inconsistent forecast values', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: ForecastOfficePage()));
    await tester.enterText(find.byKey(const Key('forecast-issued-at')), '2026-11-11 10:00 UTC');
    await tester.enterText(find.byKey(const Key('forecast-valid-from')), '2026-11-11 12:00 UTC');
    await tester.enterText(find.byKey(const Key('forecast-valid-to')), '2026-11-11 11:00 UTC');
    await tester.enterText(find.byKey(const Key('forecast-min-temp')), '12');
    await tester.enterText(find.byKey(const Key('forecast-max-temp')), '5');
    await tester.enterText(find.byKey(const Key('forecast-rain-probability')), '101');
    await tester.enterText(find.byType(TextFormField).first, 'دمشق ومحيطها');
    await tester.pumpAndSettle();
    await tester.tap(find.text('التحقق من اكتمال المسودة'));
    await tester.pumpAndSettle();
    expect(find.text('بداية الصلاحية يجب أن تسبق نهايتها.'), findsWidgets);
    expect(find.text('الحرارة الصغرى يجب ألا تتجاوز العظمى.'), findsWidgets);
    expect(find.text('احتمال الهطول يجب أن يكون بين 0 و100%.'), findsOneWidget);
  });

  testWidgets('AFTN screen exposes queues while keeping transmission disconnected', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AftnWorkspacePage()));
    expect(find.text('مركز AFTN'), findsOneWidget);
    expect(find.text('الصادر'), findsOneWidget);
    expect(find.text('الوارد'), findsOneWidget);
    expect(find.text('التسليم والتتبع'), findsOneWidget);
    expect(find.textContaining('الإرسال معطل'), findsOneWidget);
  });

  test('AFTN local preview keeps the supplied header fields and explicit terminator', () {
    final preview = buildAftnLocalPreview(
      transmissionId: 'abc123', additionalService: '', priority: 'GG',
      destination: 'abcdefgh', dateTimeGroup: '111200', origin: 'ijklmnop',
      optionalHeading: 'TEST', body: 'Weather report body',
    );
    expect(preview.startsWith('ZCZC ABC123'), isTrue);
    expect(preview, contains('GG ABCDEFGH 111200 IJKLMNOP TEST'));
    expect(preview.endsWith('NNNN'), isTrue);
  });

  testWidgets('electronic audit exposes advanced read-only filters and event details', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ElectronicAuditPage()));
    expect(find.text('التدقيق الإلكتروني'), findsOneWidget);
    expect(find.text('معرّف الارتباط'), findsWidgets);
    expect(find.text('من UTC'), findsOneWidget);
    expect(find.text('نتيجة العملية'), findsWidgets);
    expect(find.text('تفاصيل الحدث المحدد'), findsOneWidget);
    await tester.tap(find.text('تطبيق المرشحات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('المعايير المحددة:'), findsOneWidget);
  });

  testWidgets('reports workspace exposes station period element and output filters', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportsWorkspacePage()));
    expect(find.text('التقارير والإحصاء'), findsOneWidget);
    expect(find.text('معايير إعداد التقرير'), findsOneWidget);
    expect(find.text('رمز المحطة (اختياري)'), findsOneWidget);
    expect(find.text('العنصر المناخي / التشغيلي'), findsOneWidget);
    expect(find.text('صيغة التصدير'), findsOneWidget);
    expect(find.text('إنشاء التقرير — بانتظار مصدر البيانات المعتمد'), findsOneWidget);
    await tester.tap(find.text('معاينة معايير التقرير'));
    await tester.pumpAndSettle();
    expect(find.textContaining('المحطة: الكل'), findsOneWidget);
  });

  testWidgets('user access separates accounts roles and permission domains without grants', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UserAccessWorkspacePage()));
    expect(find.text('المستخدمون والصلاحيات'), findsOneWidget);
    expect(find.text('المستخدمون'), findsOneWidget);
    expect(find.text('الأدوار'), findsOneWidget);
    expect(find.text('مجالات الصلاحيات'), findsOneWidget);
    expect(find.text('لا توجد حسابات محملة'), findsOneWidget);
    await tester.tap(find.text('الأدوار').last);
    await tester.pumpAndSettle();
    expect(find.text('مدير النظام'), findsOneWidget);
    await tester.tap(find.text('مجالات الصلاحيات').last);
    await tester.pumpAndSettle();
    expect(find.text('المحطات'), findsOneWidget);
  });

  testWidgets('alerts workspace exposes official alert filters and lifecycle tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlertsWorkspacePage()));
    expect(find.text('التنبيهات الجوية'), findsOneWidget);
    expect(find.text('مصدر التحذيرات الرسمية'), findsOneWidget);
    expect(find.text('درجة التأثير'), findsOneWidget);
    expect(find.text('سارية'), findsOneWidget);
    expect(find.text('منتهية'), findsOneWidget);
    expect(find.text('الأرشيف'), findsOneWidget);
    await tester.tap(find.text('تطبيق المرشحات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('بحث:'), findsOneWidget);
  });

  testWidgets('quality control and climate archive expose filters and raw-data boundaries', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QualityControlWorkspacePage()));
    expect(find.text('ضبط جودة البيانات'), findsOneWidget);
    expect(find.text('مجموعة القواعد'), findsOneWidget);
    expect(find.text('بانتظار التصحيح'), findsOneWidget);
    await tester.tap(find.text('تطبيق المرشحات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('محطة:'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: ClimateArchivePage()));
    expect(find.text('الأرشيف المناخي'), findsOneWidget);
    expect(find.text('نوع السجل'), findsOneWidget);
    expect(find.textContaining('تظل السجلات الخام غير قابلة للتعديل'), findsOneWidget);
    await tester.tap(find.text('تطبيق المرشحات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('بحث:'), findsOneWidget);
  });

  testWidgets('paper and mechanical audit screen exposes three-source review', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PaperAndRecorderAuditPage()));
    expect(find.text('تدقيق السجلات الورقية والآلية'), findsOneWidget);
    expect(find.text('مقارنة المصادر'), findsOneWidget);
    expect(find.textContaining('لا يتم تعديل الصورة أو السجل الأصلي'), findsOneWidget);
  });

  testWidgets('climate homogenization screen preserves raw series boundary', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClimateHomogenizationPage()));
    expect(find.text('تجانس السلاسل المناخية'), findsOneWidget);
    expect(find.textContaining('تبقى السلسلة الخام محفوظة'), findsOneWidget);
    expect(find.text('نقاط الانقطاع'), findsOneWidget);
  });

  test('detailed observation catalogue contains distinct hourly, daily and synoptic forms', () {
    expect(observationFormDefinitions.length, 12);
    final hourly = observationFormDefinitions.singleWhere((item) => item.id == 'hourly');
    expect(hourly.fields.map((field) => field.key), containsAll([
      'dryTemp', 'wetTemp', 'stationPressure', 'seaLevelPressure',
      'windDirection', 'windSpeed', 'visibility', 'currentWeather',
      'pastWeather', 'cloud1Amount', 'cloud4Amount',
    ]));
    final daily = observationFormDefinitions.singleWhere((item) => item.id == 'daily');
    expect(daily.fields.map((field) => field.key), containsAll([
      'minTemp', 'maxTemp', 'precipitation', 'snowThickness',
      'maxHumidity', 'minHumidity', 'maxGustSpeed', 'sunshineDuration',
    ]));
    expect(daily.fields.singleWhere((field) => field.key == 'maxHumidity').label, 'أكبر رطوبة نسبية');
    expect(daily.fields.singleWhere((field) => field.key == 'minHumidity').label, 'أصغر رطوبة نسبية');
    expect(observationFormDefinitions.singleWhere((item) => item.id == 'synoptic06').title, contains('06:00 UTC'));
    expect(observationFormDefinitions.singleWhere((item) => item.id == 'synoptic18').title, contains('18:00 UTC'));
    final soil = observationFormDefinitions.singleWhere((item) => item.id == 'soil');
    expect(soil.notes, contains('23، 02، 05، 08'));
  });

  testWidgets('detailed observation form exposes source-required hourly fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ObservationFormsCataloguePage()));
    expect(find.text('نماذج الرصد التفصيلية'), findsOneWidget);
    expect(find.text('درجة الحرارة الجافة *'), findsOneWidget);
    expect(find.text('درجة الحرارة الرطبة *'), findsOneWidget);
  });

  testWidgets('bulletin workspace separates draft, review, approved and correction queues', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: BulletinWorkspacePage()));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.text('النشرات الجوية'), findsOneWidget);
    expect(find.text('إنشاء نشرة'), findsOneWidget);
    expect(find.text('بانتظار المراجعة'), findsOneWidget);
    expect(find.text('معتمدة'), findsOneWidget);
    expect(find.text('معادة للتصحيح'), findsOneWidget);
  });

  testWidgets('CLIMATOL workspace exposes CLIMAT, CLIMAT TEMP and statistics', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClimatolWorkspacePage()));
    expect(find.text('المناخ وCLIMATOL'), findsOneWidget);
    expect(find.text('CLIMAT'), findsOneWidget);
    expect(find.text('CLIMAT TEMP'), findsOneWidget);
    expect(find.text('الإحصاءات والتقارير'), findsOneWidget);
    expect(find.text('السنة'), findsOneWidget);
  });
}
