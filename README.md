# METRA Weather Intelligence

منصة طقس مبنية بواجهة Flutter/Dart عربية RTL، وقاعدة PostgreSQL على Supabase. المستودع يعمل على فرع التطوير:

`work/database-architecture-fresh-design-2026-11-14`

## حالة إعادة تأسيس قاعدة البيانات — 2026-11-14

تمت إعادة إنشاء مخطط تطبيق METRA في مشروع Supabase الجديد:

- Project ref: `tbdnklyxjvbrilvnwgmq`
- PostgreSQL 17.11، منطقة `eu-west-2`
- 46 جدولاً موزعة على `iam`, `catalog`, `ref`, `observations`, `weather`, `alerts`, `operations`, `files`, `integration`, `audit`.
- RLS مفعّل على جميع الجداول، ومخططات المجال غير متاحة مباشرة لـ `anon` أو `authenticated`.
- لا توجد محطات أو قراءات رصد مستوردة؛ كتالوج المحطات وسجلات الرصد يبدأان فارغين.
- لم يتم نقل أي بيانات من قواعد METRA القديمة.
- مكونات Supabase المدارة مثل Auth وStorage وRealtime لم تُحذف.

التفاصيل: [تقرير إعادة بناء قاعدة البيانات](docs/DATABASE-REBUILD-EXECUTION-2026-11-14.md).

## حالة التطبيق والـ API

تُنقل تدفقات Flutter الأساسية إلى .NET API بدلاً من استدعاء وظائف Edge القديمة. الوظائف المنشورة التالية ما زالت موجودة لكنها غير متوافقة مع المخطط الجديد، ولا تعتمد عليها الشاشات المحدثة:

`station-directory`, `registration`, `registration-approvals`, `observations`, `station-review`.

الخدمات الحالية في .NET 10 تشمل:

- الهوية والعضويات والأدوار والصلاحيات ذات النطاق.
- دليل المحطات المعتمدة ومراجعة المحطات.
- التسجيل وقرارا المراجعة على مرحلتين.
- قاموس أنواع الرصد والمعايير والوحدات، وإرسال الرصد ومراجعته.
- قراءة أحداث التنبيه الموجهة إلى نطاق المستخدم عبر `GET /api/v1/alerts`.

لا توجد محطات أو مستخدمون أو أحداث تنبيه في قاعدة البيانات حتى الآن. كما أن تعريفات المعايير والوحدات العلمية التفصيلية ما زالت فارغة، لذلك لا يسمح التطبيق بإدخال قياسات غير معتمدة أو افتراض حدود علمية.

### التحقق الآلي

- Flutter analyze: ناجح، بلا ملاحظات.
- Flutter tests: 45 اختباراً ناجحاً.
- Flutter Web release: بناء ناجح.
- .NET API tests: 14 اختباراً ناجحاً.
- .NET Release build: ناجح.
- Docker image build للـ API: ناجح.
- وظائف Edge Functions المحتفظ بها: فحص الأنواع والاختبارات ناجحة.
- تم توليد هياكل Android وiOS؛ يجري فحص بناء APK وAAB ونسخة iOS غير الموقعة.

راجع [تشغيل CI](https://github.com/gfa437926-tech/metra-weather-intelligence2026/actions) لآخر نتائج البناء.

### ما يمنع الإطلاق الحي

- تم إنشاء دور `metra_api_runtime` كدور غير قابل لتسجيل الدخول ولا يتجاوز RLS، مع منح وصلاحيات وسياسات داخلية للجداول التي تستخدمها API.
- ما زال يلزم إنشاء/توفير login role مُدار يرث صلاحيات `metra_api_runtime`، وحفظ سلسلة اتصال PostgreSQL في مدير أسرار الاستضافة.
- لا توجد خدمة استضافة .NET منشورة أو عنوان إنتاج `METRA_API_URL`.
- مصادر التنبيه الرسمية، إدخال التنبؤات، إنشاء/تعديل المحطات، الإدارة الكاملة للمستخدمين والأدوار، إدارة التشغيل والأعطال، الملفات والتصدير، وتعديلات/مراجعات الرصد الكاملة ما زالت غير مكتملة.
- ملفات SQL المصدرية المطابقة لثلاث migrations الأساسية لإعادة تأسيس المخطط ما زالت غير موجودة في Git؛ لا تعتبر إعادة البناء من Git مكتملة.

لا تضع مفتاح `service_role` أو كلمة مرور PostgreSQL في Flutter أو ملفات المصدر. لا تدمج إلى `main` قبل اكتمال التحقق والتسليم.

## بنية قاعدة البيانات

- `iam`: الهوية والجهات والعضويات والأدوار والصلاحيات وطلبات التسجيل ومراجعات الوصول.
- `catalog`: دليل المحطات، أنواعها، معرفاتها، مواقعها التاريخية، قدراتها وفترات تشغيلها.
- `ref`: الوحدات والمعايير الجوية وأنواع الرصد. القيم العلمية التفصيلية لا تُملأ قبل اعتمادها.
- `observations`: إرسال الرصد وقيمه typed وإصداراته وقرارات مراجعته وأعلام الجودة.
- `weather`: مزودو البيانات وعمليات الجلب ودورات التنبؤ ونقاط التنبؤ.
- `alerts`: قواعد وأحداث التنبيه والمستلمون.
- `operations`: التجهيزات وأعطالها وبلاغات الدعم.
- `files`: بيانات وصفية للملفات؛ تخزين الملفات الثنائية في Storage الخاص.
- `integration`: مصادر التكامل وتشغيلاتها.
- `audit`: سجل تدقيق append-only.

## التشغيل والبناء

واجهة Flutter:
```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

عند توفر إعدادات Supabase، يستخدم العميل publishable key فقط. لا تضع مفاتيح سرية أو service-role في ملفات Dart أو إعدادات البناء العامة.

## مصادر الطقس الحالية

تستخدم واجهة الصفحة الرئيسية Open-Meteo لعرض ظروف وتنبؤات نموذجية لموقع دمشق. هذه قيم تنبؤ من مزود خارجي وليست قراءات مباشرة من محطات METRA.

- خرائط الأساس: OpenStreetMap.
- لا تدّعي المنصة حالياً وجود تيليمترية تلقائية للمحطات.
- تنبيهات الطقس الرسمية وطبقات الرادار لم تُربط بعد.
- لا تستخدم بيانات مزود رسمي أو تعرضها كبيانات حية ما لم يتم تفعيل عقد التكامل والتحقق من بيانات الاعتماد وشروط الاستخدام.

## توثيق قاعدة البيانات

- [المعمارية الجديدة](docs/DATABASE-ARCHITECTURE-FRESH-DESIGN.md)
- [ERD التفصيلي](docs/DATABASE-ERD-DETAILED.md)
- [قاموس البيانات](docs/DATA-DICTIONARY.md)
- [تتبع المتطلبات](docs/DATABASE-REQUIREMENTS-TRACEABILITY.md)
- [تقرير التنفيذ والتحقق](docs/DATABASE-REBUILD-EXECUTION-2026-11-14.md)
- [جاهزية التنفيذ والخطوات المتبقية](docs/DATABASE-IMPLEMENTATION-READINESS.md)
- [عقد ترحيل .NET API الآمن](docs/API-MIGRATION-CONTRACT.md)

## ملاحظات إعادة البناء

سجل migrations للتغييرات الأخيرة موجود في مشروع Supabase، لكن ملفات SQL المصدرية المطابقة لم تُلتزم في Git بعد بسبب عدم توفر Supabase CLI في بيئة التنفيذ. يجب حفظ ملفات migrations المصدرية في المستودع قبل اعتبار إعادة البناء من Git مكتملة.

لا تعدّل قاعدة METRA القديمة أو مستودعها، ولا تستورد منها أي بيانات.

## Current implementation status (2026-11-14)

The development branch now contains:

- Database-backed .NET 10 endpoints for identity, station directory/review, registration submission/two-stage approval, meteorological reference catalogues, and typed observation submission/history/review.
- Flutter station, registration, station-review, observation and approval screens now call the .NET API rather than the legacy Supabase Edge Function endpoints.
- Flutter observation fields are generated from `ref.parameters`; while that scientific catalogue is empty, measurement submission is intentionally disabled rather than showing invented weather fields or limits.
- A structured `father_name` profile field and explicit station/organization registration-review permissions were added by the new additive migration `20261114203913_metra_registration_review_permissions_and_father_name`.
- CI currently builds .NET, runs scoped-authorization unit tests, type-checks/tests retained Edge Function source, analyzes Flutter, runs Flutter tests and builds the Web release.

### Verified boundaries and remaining blockers

- The new database schema remains the 46-table greenfield design; no legacy data was imported.
- The .NET code builds, but live database-backed execution is not yet verified: `METRA_DATABASE_CONNECTION_STRING`, a least-privilege runtime login/grants and a hosting target are not configured.
- The three earlier greenfield rebuild migrations are recorded in the remote Supabase history, but their matching SQL source files are still absent from Git. The newly added additive migration source is present and version-aligned.
- No organization/station/user seed data has been added. The reference observation types exist, but scientific parameter and unit definitions remain empty pending approved meteorological definitions.
- Station creation/update, user administration, forecast ingestion, alerts, operations, file access, exports, full observation revisions and disposable-database integration/security tests remain incomplete.
- Legacy Edge Functions are no longer called by the migrated Flutter screens, but their deployed copies have not yet been retired.

The repository is not yet a deployable final release. Do not treat successful compilation as proof of live database integration.
