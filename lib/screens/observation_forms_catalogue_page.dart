import 'package:flutter/material.dart';

enum ObservationInputKind { text, number, date, time, choice, boolean, multiline }

class ObservationInputField {
  const ObservationInputField(this.key, this.label, this.kind,
      {this.unit, this.required = false, this.choices = const [], this.group = 'البيانات'});
  final String key, label, group;
  final ObservationInputKind kind;
  final String? unit;
  final bool required;
  final List<String> choices;
}

class ObservationFormDefinition {
  const ObservationFormDefinition(this.id, this.title, this.fields, this.notes,
      {this.submitSupported = false});
  final String id, title, notes;
  final List<ObservationInputField> fields;
  final bool submitSupported;
}

const observationFormDefinitions = <ObservationFormDefinition>[
  ObservationFormDefinition('hourly', 'النشرة الساعية', [
    ObservationInputField('utcTime', 'ساعة الرصد UTC', ObservationInputKind.time, required: true, group: 'الوقت'),
    ObservationInputField('dryTemp', 'درجة الحرارة الجافة', ObservationInputKind.number, unit: '°س', required: true, group: 'الحرارة والرطوبة'),
    ObservationInputField('wetTemp', 'درجة الحرارة الرطبة', ObservationInputKind.number, unit: '°س', required: true, group: 'الحرارة والرطوبة'),
    ObservationInputField('stationPressure', 'ضغط المحطة', ObservationInputKind.number, unit: 'hPa', required: true, group: 'الضغط'),
    ObservationInputField('seaLevelPressure', 'الضغط المحول إلى سطح البحر', ObservationInputKind.number, unit: 'hPa', required: true, group: 'الضغط'),
    ObservationInputField('pressureSlope', 'ميل الضغط', ObservationInputKind.choice, group: 'الضغط'),
    ObservationInputField('pressureShape', 'شكل تغير الضغط', ObservationInputKind.choice, group: 'الضغط'),
    ObservationInputField('relativeHumidity', 'الرطوبة النسبية', ObservationInputKind.number, unit: '%', group: 'الحرارة والرطوبة'),
    ObservationInputField('vaporPressure', 'ضغط بخار الماء', ObservationInputKind.number, unit: 'hPa', group: 'الحرارة والرطوبة'),
    ObservationInputField('dewPoint', 'درجة الندى', ObservationInputKind.number, unit: '°س', group: 'الحرارة والرطوبة'),
    ObservationInputField('vaporPressureDiff', 'فرق ضغط بخار الماء عن الإشباع', ObservationInputKind.number, group: 'الحرارة والرطوبة'),
    ObservationInputField('windDirection', 'اتجاه الرياح السطحية', ObservationInputKind.number, group: 'الرياح'),
    ObservationInputField('windSpeed', 'سرعة الرياح السطحية', ObservationInputKind.number, unit: 'م/ث', group: 'الرياح'),
    ObservationInputField('avgWindDirection', 'اتجاه المتوسط الساعي للرياح', ObservationInputKind.number, group: 'الرياح'),
    ObservationInputField('avgWindSpeed', 'سرعة المتوسط الساعي للرياح', ObservationInputKind.number, unit: 'م/ث', group: 'الرياح'),
    ObservationInputField('visibility', 'الرؤية الأفقية', ObservationInputKind.number, group: 'الطقس والرؤية'),
    ObservationInputField('waveHeight', 'ارتفاع الموج', ObservationInputKind.number, unit: 'م', group: 'الطقس والرؤية'),
    ObservationInputField('currentWeather', 'الطقس الحالي', ObservationInputKind.choice, group: 'الطقس والرؤية'),
    ObservationInputField('pastWeather', 'الطقس السابق', ObservationInputKind.choice, group: 'الطقس والرؤية'),
    ObservationInputField('precipitationAmount', 'كمية الهطول', ObservationInputKind.number, unit: 'مم', group: 'الهطول والغيوم'),
    ObservationInputField('totalCloudCover', 'التغطية الكلية للغيوم', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cloud1Amount', 'كمية الغيوم في الطبقة الأولى', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cloud1Type', 'نوع الغيوم في الطبقة الأولى', ObservationInputKind.choice, group: 'الهطول والغيوم'),
    ObservationInputField('cloud1Height', 'ارتفاع قاعدة الطبقة الأولى', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cloud2Amount', 'كمية الغيوم في الطبقة الثانية', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cloud2Type', 'نوع الغيوم في الطبقة الثانية', ObservationInputKind.choice, group: 'الهطول والغيوم'),
    ObservationInputField('cloud2Height', 'ارتفاع قاعدة الطبقة الثانية', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cloud3Amount', 'كمية الغيوم في الطبقة الثالثة', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cloud3Type', 'نوع الغيوم في الطبقة الثالثة', ObservationInputKind.choice, group: 'الهطول والغيوم'),
    ObservationInputField('cloud3Height', 'ارتفاع قاعدة الطبقة الثالثة', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cloud4Amount', 'كمية الغيوم في الطبقة الرابعة', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cover12', 'مجموع تغطية الطبقتين الأولى والثانية', ObservationInputKind.number, group: 'الهطول والغيوم'),
    ObservationInputField('cover123', 'مجموع تغطية الطبقات الثلاث الأولى', ObservationInputKind.number, group: 'الهطول والغيوم'),
  ], 'الهطول مطلوب عند 00 و06 و12 و18 UTC. ميل الضغط وشكله مطلوبان عند 00 و03 و06 و09 و12 و15 و18 و21 UTC. لم تُعتمد بعد دلالات القيم الخاصة مثل #.'),
  ObservationFormDefinition('synoptic06', 'تقرير ساعي 06:00 UTC', [
    ObservationInputField('minTemp', 'درجة الحرارة الصغرى', ObservationInputKind.number, unit: '°س', required: true),
    ObservationInputField('maxTemp', 'درجة الحرارة العظمى', ObservationInputKind.number, unit: '°س', required: true),
    ObservationInputField('precipitation', 'كمية الهطول', ObservationInputKind.number, unit: 'مم', required: true),
    ObservationInputField('snowThickness', 'أكبر سماكة للثلج', ObservationInputKind.number, unit: 'سم', required: true),
  ], 'نموذج مستقل ضمن قسم الساعي، ووقت التقرير ثابت 06:00 UTC. الإرسال غير مدعوم حتى اعتماد عقد API والتحقق المستقل.'),
  ObservationFormDefinition('synoptic18', 'تقرير ساعي 18:00 UTC', [
    ObservationInputField('minTemp', 'درجة الحرارة الصغرى', ObservationInputKind.number, unit: '°س', required: true),
    ObservationInputField('maxTemp', 'درجة الحرارة العظمى', ObservationInputKind.number, unit: '°س', required: true),
    ObservationInputField('precipitation', 'كمية الهطول', ObservationInputKind.number, unit: 'مم', required: true),
    ObservationInputField('snowThickness', 'أكبر سماكة للثلج', ObservationInputKind.number, unit: 'سم', required: true),
  ], 'نموذج مستقل ضمن قسم الساعي، ووقت التقرير ثابت 18:00 UTC. لا يعرض أو يحسب أي توقيت محلي.'),
  ObservationFormDefinition('daily', 'النشرة اليومية — 24 ساعة', [
    ObservationInputField('currentDate', 'تاريخ التقرير UTC', ObservationInputKind.date, required: true, group: 'التاريخ والحرارة'),
    ObservationInputField('minTemp', 'درجة الحرارة الصغرى', ObservationInputKind.number, unit: '°س', required: true, group: 'التاريخ والحرارة'),
    ObservationInputField('maxTemp', 'درجة الحرارة العظمى', ObservationInputKind.number, unit: '°س', required: true, group: 'التاريخ والحرارة'),
    ObservationInputField('precipitation', 'كمية الهطول', ObservationInputKind.number, unit: 'مم', required: true, group: 'الهطول والظواهر'),
    ObservationInputField('snowThickness', 'أكبر سماكة للثلج', ObservationInputKind.number, unit: 'سم', required: true, group: 'الهطول والظواهر'),
    ObservationInputField('precipitationTrace', 'أثر الهطول', ObservationInputKind.choice, choices: ['T'], group: 'الهطول والظواهر'),
    ObservationInputField('thunderstorm', 'عواصف رعدية', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('hail', 'برد', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('snow', 'ثلج', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('rain', 'مطر', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('frost', 'صقيع', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('fog', 'ضباب', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('mist', 'شابورة', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('dustStorm', 'عواصف ترابية أو رملية', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('blowingDust', 'غبار متصاعد', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('haze', 'سديم', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('stormyWind', 'رياح عاصفة', ObservationInputKind.boolean, group: 'الهطول والظواهر'),
    ObservationInputField('evaporation', 'التبخر اليومي', ObservationInputKind.number, unit: 'مم', group: 'عناصر إضافية'),
    ObservationInputField('sunshineDuration', 'مدة سطوع الشمس', ObservationInputKind.number, unit: 'ساعة', group: 'عناصر إضافية'),
    ObservationInputField('sunshinePercentage', 'النسبة المئوية لسطوع الشمس', ObservationInputKind.number, unit: '%', group: 'عناصر إضافية'),
    ObservationInputField('maxGustSpeed', 'أكبر نفحة للرياح', ObservationInputKind.number, unit: 'م/ث', group: 'الرياح والرطوبة'),
    ObservationInputField('maxGustDirection', 'اتجاه أكبر نفحة', ObservationInputKind.number, group: 'الرياح والرطوبة'),
    ObservationInputField('maxGustTime', 'وقت أكبر نفحة UTC', ObservationInputKind.time, group: 'الرياح والرطوبة'),
    ObservationInputField('maxHumidity', 'أكبر رطوبة نسبية', ObservationInputKind.number, unit: '%', group: 'الرياح والرطوبة'),
    ObservationInputField('maxHumidityTime', 'وقت أكبر رطوبة UTC', ObservationInputKind.time, group: 'الرياح والرطوبة'),
    ObservationInputField('minHumidity', 'أصغر رطوبة نسبية', ObservationInputKind.number, unit: '%', group: 'الرياح والرطوبة'),
    ObservationInputField('minHumidityTime', 'وقت أصغر رطوبة UTC', ObservationInputKind.time, group: 'الرياح والرطوبة'),
  ], 'هذا النموذج مخصص لتقرير 24 ساعة فقط. تقريري 06:00 و18:00 UTC منفصلان ضمن قسم الساعي.'),
  ObservationFormDefinition('agricultural', 'النشرة الزراعية', [
    ObservationInputField('reportDate', 'تاريخ التقرير UTC', ObservationInputKind.date, group: 'الحرارة'),
    ObservationInputField('avgAirTemp', 'معدل درجة حرارة الهواء', ObservationInputKind.number, unit: '°س', group: 'الحرارة'),
    ObservationInputField('maxAirTemp', 'درجة حرارة الهواء العظمى', ObservationInputKind.number, unit: '°س', group: 'الحرارة'),
    ObservationInputField('minAirTemp', 'درجة حرارة الهواء الصغرى', ObservationInputKind.number, unit: '°س', group: 'الحرارة'),
    ObservationInputField('minTemp2m', 'درجة الحرارة الصغرى على ارتفاع مترين', ObservationInputKind.number, unit: '°س', group: 'الحرارة'),
    ObservationInputField('maxSoilSurfaceTemp', 'عظمى حرارة سطح التربة', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('minSoilSurfaceTemp', 'صغرى حرارة سطح التربة', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('avgSoilTemp5cm', 'متوسط حرارة التربة على عمق 5 سم', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('avgSoilTemp10cm', 'متوسط حرارة التربة على عمق 10 سم', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('avgSoilTemp20cm', 'متوسط حرارة التربة على عمق 20 سم', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('avgSoilTemp50cm', 'متوسط حرارة التربة على عمق 50 سم', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('fieldSoilTemp5cm', 'حرارة تربة الحقل على عمق 5 سم', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('fieldSoilTemp10cm', 'حرارة تربة الحقل على عمق 10 سم', ObservationInputKind.number, unit: '°س', group: 'التربة'),
    ObservationInputField('avgHumidity', 'معدل الرطوبة النسبية', ObservationInputKind.number, unit: '%', group: 'الرطوبة والغيوم'),
    ObservationInputField('minHumidity', 'أدنى رطوبة نسبية', ObservationInputKind.number, unit: '%', group: 'الرطوبة والغيوم'),
    ObservationInputField('avgEsE', 'معدل ES-E', ObservationInputKind.number, group: 'الرطوبة والغيوم'),
    ObservationInputField('minEsE', 'أدنى ES-E', ObservationInputKind.number, group: 'الرطوبة والغيوم'),
    ObservationInputField('totalCloudCover', 'معدل التغطية الكلية للغيوم', ObservationInputKind.number, group: 'الرطوبة والغيوم'),
    ObservationInputField('lowCloudCover', 'معدل تغطية الغيوم المنخفضة', ObservationInputKind.number, group: 'الرطوبة والغيوم'),
    ObservationInputField('sunshineHours', 'مدة سطوع الشمس', ObservationInputKind.number, unit: 'ساعة', group: 'عناصر إضافية'),
    ObservationInputField('precipitation', 'الهطول', ObservationInputKind.number, unit: 'مم', group: 'عناصر إضافية'),
    ObservationInputField('maxWindSpeed', 'أكبر سرعة رياح من المخطط', ObservationInputKind.number, unit: 'م/ث', group: 'عناصر إضافية'),
    ObservationInputField('classAEvaporation', 'تبخر حوض Class A', ObservationInputKind.number, unit: 'مم', group: 'عناصر إضافية'),
    ObservationInputField('avgWindSpeed2m', 'معدل سرعة الرياح على ارتفاع مترين', ObservationInputKind.number, unit: 'م/ث', group: 'عناصر إضافية'),
    ObservationInputField('logEvaporation', 'التبخر من السجل', ObservationInputKind.number, unit: 'مم', group: 'عناصر إضافية'),
    ObservationInputField('dew', 'ندى', ObservationInputKind.boolean, group: 'الظواهر'),
    ObservationInputField('fog', 'ضباب', ObservationInputKind.boolean, group: 'الظواهر'),
    ObservationInputField('hail', 'برد', ObservationInputKind.boolean, group: 'الظواهر'),
    ObservationInputField('sandstorm', 'عواصف رملية أو ترابية', ObservationInputKind.boolean, group: 'الظواهر'),
  ], 'قواعد required/range والمفقودات الزراعية لم تُستخلص بالكامل؛ لا تُفعّل الإرسال قبل اعتمادها.'),
  ObservationFormDefinition('rainfall', 'النشرة المطرية', [
    ObservationInputField('currentDate', 'تاريخ التقرير UTC', ObservationInputKind.date),
    ObservationInputField('utcTime', 'وقت الرصد UTC', ObservationInputKind.time),
    ObservationInputField('rainAmount', 'كمية الهطول المطري', ObservationInputKind.number, unit: 'مم'),
    ObservationInputField('snowDepth', 'سماكة الثلج', ObservationInputKind.number, unit: 'سم'),
    ObservationInputField('observationDate', 'تاريخ الرصد UTC', ObservationInputKind.date),
  ], 'يعتمد النموذج UTC حصراً. يجب اعتماد قواعد الفترة الزمنية قبل تفعيل الإرسال.'),
  ObservationFormDefinition('phenomenon', 'بلاغ ظاهرة جوية', [
    ObservationInputField('phenomenonType', 'نوع الظاهرة الجوية', ObservationInputKind.choice),
    ObservationInputField('startTime', 'وقت بدء الظاهرة UTC', ObservationInputKind.time),
    ObservationInputField('endTime', 'وقت انتهاء الظاهرة UTC', ObservationInputKind.time),
    ObservationInputField('notes', 'ملاحظات إضافية', ObservationInputKind.multiline),
  ], 'قائمة أنواع الظواهر تحتاج مطابقة مع مدقق WeatherPhenomenon قبل الإرسال.'),
  ObservationFormDefinition('agriPhenomenon', 'الظواهر الزراعية', [
    ObservationInputField('dew', 'ندى', ObservationInputKind.boolean),
    ObservationInputField('fog', 'ضباب', ObservationInputKind.boolean),
    ObservationInputField('hail', 'برد', ObservationInputKind.boolean),
    ObservationInputField('sandstorm', 'عواصف رملية أو ترابية', ObservationInputKind.boolean),
  ], 'حقول واجهة محلية؛ لا يوجد عقد API معتمد لهذا النوع.'),
  ObservationFormDefinition('soil', 'حرارة التربة', [
    ObservationInputField('utcTime', 'ساعة الرصد UTC', ObservationInputKind.time),
    ObservationInputField('soilTemp5cm', 'حرارة التربة على عمق 5 سم', ObservationInputKind.number, unit: '°س'),
    ObservationInputField('soilTemp10cm', 'حرارة التربة على عمق 10 سم', ObservationInputKind.number, unit: '°س'),
    ObservationInputField('soilTemp20cm', 'حرارة التربة على عمق 20 سم', ObservationInputKind.number, unit: '°س'),
    ObservationInputField('soilTemp50cm', 'حرارة التربة على عمق 50 سم', ObservationInputKind.number, unit: '°س'),
  ], 'يسمح مصدر النموذج بالقيمة # لدرجة الحرارة، ويحدد ساعات UTC: 23، 02، 05، 08، 11، 14، 17، 20. يلزم اعتماد معنى # قبل تفعيله.'),
  ObservationFormDefinition('equipmentFault', 'أعطال أجهزة الرصد', [
    ObservationInputField('failureDescription', 'وصف العطل', ObservationInputKind.multiline),
    ObservationInputField('failureDate', 'تاريخ ووقت حدوث العطل UTC', ObservationInputKind.date),
    ObservationInputField('failureSeverity', 'شدة العطل', ObservationInputKind.choice, choices: ['منخفض', 'متوسط', 'مرتفع', 'حرج']),
    ObservationInputField('failureImage', 'مرجع صورة العطل', ObservationInputKind.text),
    ObservationInputField('urgentRepair', 'العطل عاجل ويحتاج إلى تدخل سريع', ObservationInputKind.boolean),
    ObservationInputField('manualMeasurementType', 'نوع المقياس', ObservationInputKind.choice),
    ObservationInputField('manualMeasurementProblem', 'نوع مشكلة المقياس', ObservationInputKind.choice, choices: ['كسر في الجهاز', 'تلف في الأجزاء', 'عدم دقة في القياس', 'عدم استجابة الجهاز', 'تآكل الأجزاء', 'مشكلة أخرى']),
    ObservationInputField('manualMeasurementDescription', 'وصف عطل المقياس', ObservationInputKind.multiline),
    ObservationInputField('manualMeasurementDate', 'تاريخ ووقت عطل المقياس UTC', ObservationInputKind.date),
    ObservationInputField('manualMeasurementSeverity', 'شدة عطل المقياس', ObservationInputKind.choice, choices: ['منخفض', 'متوسط', 'مرتفع', 'حرج']),
    ObservationInputField('manualMeasurementImage', 'مرجع صورة العطل', ObservationInputKind.text),
    ObservationInputField('manualMeasurementUrgent', 'عطل المقياس عاجل', ObservationInputKind.boolean),
  ], 'رفع الصور غير متاح حتى تصميم Storage آمن وصلاحياته. لا تحفظ الصور كقيم نصية.'),
  ObservationFormDefinition('telecomFault', 'أعطال الاتصالات', [
    ObservationInputField('phoneType', 'نوع الهاتف', ObservationInputKind.choice), ObservationInputField('phoneBrand', 'ماركة الهاتف', ObservationInputKind.text),
    ObservationInputField('problemType', 'نوع المشكلة', ObservationInputKind.choice), ObservationInputField('description', 'وصف المشكلة', ObservationInputKind.multiline),
    ObservationInputField('urgent', 'بلاغ عاجل', ObservationInputKind.boolean), ObservationInputField('towerType', 'نوع البرج', ObservationInputKind.choice),
    ObservationInputField('towerHeight', 'ارتفاع البرج', ObservationInputKind.number, unit: 'م'), ObservationInputField('satelliteType', 'نوع جهاز الأقمار الصناعية', ObservationInputKind.choice),
    ObservationInputField('satelliteBrand', 'ماركة جهاز الأقمار الصناعية', ObservationInputKind.text), ObservationInputField('faxType', 'نوع جهاز الفاكس', ObservationInputKind.choice),
    ObservationInputField('faxBrand', 'ماركة الفاكس', ObservationInputKind.text), ObservationInputField('computerType', 'نوع الحاسوب', ObservationInputKind.choice),
    ObservationInputField('computerBrand', 'ماركة الحاسوب', ObservationInputKind.text), ObservationInputField('laptopType', 'نوع الحاسوب المحمول', ObservationInputKind.choice),
    ObservationInputField('laptopBrand', 'ماركة الحاسوب المحمول', ObservationInputKind.text), ObservationInputField('printerType', 'نوع الطابعة', ObservationInputKind.choice),
    ObservationInputField('printerBrand', 'ماركة الطابعة', ObservationInputKind.text), ObservationInputField('networkType', 'نوع الشبكة', ObservationInputKind.choice),
    ObservationInputField('networkBrand', 'اسم/ماركة الشبكة', ObservationInputKind.text), ObservationInputField('wifiType', 'نوع شبكة Wi-Fi', ObservationInputKind.choice),
    ObservationInputField('wifiBrand', 'اسم/ماركة Wi-Fi', ObservationInputKind.text),
  ], 'تظهر الحقول الشرطية بحسب نوع الجهاز بعد استكمال مطابقة قواعد الظهور الأصلية.'),
  ObservationFormDefinition('itIncident', 'بلاغات أعطال تقنية المعلومات', [
    ObservationInputField('reporterName', 'اسم مقدم البلاغ', ObservationInputKind.text), ObservationInputField('reporterPosition', 'الصفة الوظيفية', ObservationInputKind.text),
    ObservationInputField('reporterPhone', 'رقم الهاتف', ObservationInputKind.text), ObservationInputField('bulletinType', 'نوع النشرة المتأثرة', ObservationInputKind.choice),
    ObservationInputField('problemField', 'الحقل الذي به المشكلة', ObservationInputKind.choice), ObservationInputField('problemType', 'نوع المشكلة', ObservationInputKind.choice),
    ObservationInputField('problemDescription', 'وصف المشكلة', ObservationInputKind.multiline), ObservationInputField('problemUrgency', 'درجة الأهمية', ObservationInputKind.choice, choices: ['منخفضة', 'متوسطة', 'عالية', 'حرجة']),
    ObservationInputField('fieldName', 'اسم الحقل الحالي', ObservationInputKind.text), ObservationInputField('suggestedName', 'الاسم المقترح للحقل', ObservationInputKind.text),
    ObservationInputField('currentValue', 'القيمة الحالية', ObservationInputKind.text), ObservationInputField('expectedValue', 'القيمة المتوقعة', ObservationInputKind.text),
    ObservationInputField('currentUnit', 'الوحدة الحالية', ObservationInputKind.text), ObservationInputField('correctUnit', 'الوحدة الصحيحة', ObservationInputKind.text),
    ObservationInputField('currentMask', 'قناع الإدخال الحالي', ObservationInputKind.text), ObservationInputField('suggestedMask', 'قناع الإدخال المقترح', ObservationInputKind.text),
    ObservationInputField('fieldConditions', 'شروط الحقل الحالية', ObservationInputKind.text), ObservationInputField('conditionIssue', 'مشكلة شروط الحقل', ObservationInputKind.text),
    ObservationInputField('extraFieldName', 'اسم الحقل الزائد', ObservationInputKind.text), ObservationInputField('whyExtra', 'سبب اعتبار الحقل زائداً', ObservationInputKind.text),
    ObservationInputField('missingFieldName', 'اسم الحقل الناقص', ObservationInputKind.text), ObservationInputField('fieldImportance', 'أهمية الحقل الناقص', ObservationInputKind.text),
    ObservationInputField('extraDetails', 'تفاصيل إضافية', ObservationInputKind.text),
  ], 'تتغير الحقول التفصيلية حسب نوع المشكلة؛ يجب مطابقة شروط الظهور قبل اعتماد التحقق.'),
];

class ObservationFormsCataloguePage extends StatefulWidget {
  const ObservationFormsCataloguePage({super.key});
  @override
  State<ObservationFormsCataloguePage> createState() => _ObservationFormsCataloguePageState();
}
class _ObservationFormsCataloguePageState extends State<ObservationFormsCataloguePage> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final choices = <String, String>{};
  final toggles = <String, bool>{};
  String selectedId = 'hourly';
  ObservationFormDefinition get selected => observationFormDefinitions.firstWhere((item) => item.id == selectedId);
  @override
  void dispose() { for (final controller in controllers.values) { controller.dispose(); } super.dispose(); }
  TextEditingController controllerFor(String key) => controllers.putIfAbsent(key, TextEditingController.new);

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<ObservationInputField>>{};
    for (final field in selected.fields) { groups.putIfAbsent(field.group, () => []).add(field); }
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(title: const Text('نماذج الرصد التفصيلية')),
      body: SafeArea(child: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        const _CatalogueNotice(),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: selectedId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'نوع النشرة / النموذج', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
          items: observationFormDefinitions.map((item) => DropdownMenuItem(value: item.id, child: Text(item.title))).toList(),
          onChanged: (value) { for (final controller in controllers.values) { controller.clear(); } choices.clear(); toggles.clear(); setState(() => selectedId = value ?? selectedId); },
        ),
        const SizedBox(height: 12),
        for (final entry in groups.entries) ...[
          _FieldGroupCard(title: entry.key, fields: entry.value, controllers: controllers, choices: choices, toggles: toggles),
          const SizedBox(height: 12),
        ],
        _FieldGroupCard(
          title: 'بيانات وصفية منفصلة عن حمولة الرصد',
          fields: const [
            ObservationInputField('observerNotes', 'ملاحظات الراصد', ObservationInputKind.multiline),
            ObservationInputField('responsibilityAgreement', 'إقرار صحة البيانات وتحمل المسؤولية', ObservationInputKind.boolean),
          ],
          controllers: controllers, choices: choices, toggles: toggles,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: const Color(0xFFFFF4DF), borderRadius: BorderRadius.circular(14)),
          child: Text(selected.notes, style: const TextStyle(color: Color(0xFF76520B), fontSize: 12, height: 1.5)),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتمل فحص الحقول المطلوبة حسب المصدر فقط؛ لم تُحفظ البيانات أو تُرسل.')));
            }
          },
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('فحص اكتمال النموذج'),
        )),
        const SizedBox(height: 8),
        const SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: null,
          icon: Icon(Icons.save_outlined),
          label: Text('حفظ / إرسال — ينتظر عقد API المعتمد'),
        )),
        const SizedBox(height: 20),
      ]))),
    ));
  }
}

class _CatalogueNotice extends StatelessWidget {
  const _CatalogueNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(14)),
    child: const Text('النماذج مبنية على كتالوج الحقول الموثق للمشروع. الحقول الإلزامية هنا تعكس requiredness في المصدر ولا تمثل وحدها حدود التحقق العلمي أو موافقة الخادم. الإرسال يبقى معطلاً حتى مطابقة كل نموذج مع عقد API.', style: TextStyle(color: Color(0xFF234A7C), fontSize: 12, height: 1.5)),
  );
}

class _FieldGroupCard extends StatelessWidget {
  const _FieldGroupCard({required this.title, required this.fields, required this.controllers, required this.choices, required this.toggles});
  final String title;
  final List<ObservationInputField> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, String> choices;
  final Map<String, bool> toggles;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5EAF2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Color(0xFF102448), fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 12),
      for (final field in fields) ...[
        _field(context, field),
        const SizedBox(height: 10),
      ],
    ]),
  );
  Widget _field(BuildContext context, ObservationInputField field) {
    switch (field.kind) {
      case ObservationInputKind.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.label, style: const TextStyle(fontSize: 12)),
          value: toggles[field.key] ?? false,
          onChanged: (value) { toggles[field.key] = value; (context as Element).markNeedsBuild(); },
        );
      case ObservationInputKind.choice:
        if (field.choices.isNotEmpty) {
          return DropdownButtonFormField<String>(
            value: choices[field.key],
            decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
            items: field.choices.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) { if (value != null) choices[field.key] = value; },
          );
        }
        return TextFormField(
          controller: controllers.putIfAbsent(field.key, TextEditingController.new),
          decoration: InputDecoration(labelText: field.label, helperText: 'خيارات المصدر قيد المطابقة', border: const OutlineInputBorder()),
        );
      default:
        final isNumber = field.kind == ObservationInputKind.number;
        final isMultiline = field.kind == ObservationInputKind.multiline;
        return TextFormField(
          controller: controllers.putIfAbsent(field.key, TextEditingController.new),
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
          minLines: isMultiline ? 2 : 1,
          maxLines: isMultiline ? 4 : 1,
          validator: field.required ? (value) => (value == null || value.trim().isEmpty) ? 'هذا الحقل مطلوب في النموذج المصدر' : null : null,
          decoration: InputDecoration(
            labelText: field.required ? field.label + ' *' : field.label,
            suffixText: field.unit,
            hintText: field.kind == ObservationInputKind.date ? 'YYYY-MM-DD UTC' : field.kind == ObservationInputKind.time ? 'HH:MM UTC' : null,
            border: const OutlineInputBorder(),
          ),
        );
    }
  }
}
