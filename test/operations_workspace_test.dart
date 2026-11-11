import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metra_weather_intelligence/screens/operations_workspace.dart';
import 'package:metra_weather_intelligence/screens/observation_forms_catalogue_page.dart';

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

  testWidgets('AFTN screen keeps transmission disabled without a gateway', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AftnWorkspacePage()));
    expect(find.text('مركز AFTN'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('إرسال AFTN'), 350, scrollable: find.byType(ListView).first);
    await tester.pumpAndSettle();
    expect(find.text('إرسال AFTN'), findsOneWidget);
    expect(find.text('الصادر'), findsOneWidget);
    expect(find.text('الوارد'), findsOneWidget);
    expect(find.text('التسليم والتتبع'), findsOneWidget);
    expect(find.text('عنوان المرسل (8 أحرف AFTN)'), findsOneWidget);
    expect(find.text('لا يوجد اتصال مع محطة الرسائل أو بوابة الإرسال. الإرسال معطل حتى اعتماد إعدادات الاتصال والمراقبة.'), findsOneWidget);
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
    await tester.scrollUntilVisible(find.text('ضغط المحطة *'), 350, scrollable: find.byType(ListView).first);
    await tester.pumpAndSettle();
    expect(find.text('ضغط المحطة *'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('حفظ / إرسال — ينتظر عقد API المعتمد'), 350, scrollable: find.byType(ListView).first);
    await tester.pumpAndSettle();
    expect(find.text('حفظ / إرسال — ينتظر عقد API المعتمد'), findsOneWidget);
  });

  testWidgets('daily form switch exposes 24-hour humidity and phenomenon controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ObservationFormsCataloguePage()));
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('النشرة اليومية — 24 ساعة').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('أكبر رطوبة نسبية'), 350, scrollable: find.byType(ListView).first);
    await tester.pumpAndSettle();
    expect(find.text('أكبر رطوبة نسبية'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('أصغر رطوبة نسبية'), 350, scrollable: find.byType(ListView).first);
    await tester.pumpAndSettle();
    expect(find.text('أصغر رطوبة نسبية'), findsOneWidget);
    expect(find.text('عواصف رعدية'), findsOneWidget);
    expect(find.text('وقت أكبر نفحة UTC'), findsOneWidget);
  });

  testWidgets('bulletin workspace separates draft, review, approved and correction queues', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BulletinWorkspacePage()));
    await tester.scrollUntilVisible(find.text('معاينة فك الترميز'), 350, scrollable: find.byType(ListView).first);
    await tester.pumpAndSettle();
    expect(find.text('النشرات الجوية'), findsOneWidget);
    expect(find.text('إنشاء نشرة'), findsOneWidget);
    expect(find.text('بانتظار المراجعة'), findsOneWidget);
    expect(find.text('معتمدة'), findsOneWidget);
    expect(find.text('معادة للتصحيح'), findsOneWidget);
    expect(find.text('معاينة فك الترميز'), findsOneWidget);
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
