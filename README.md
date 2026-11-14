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

- Flutter Analyze: ناجح بعد توحيد خدمات العمليات.
- Flutter Tests: **67/67 ناجحة** في آخر تشغيل مكتمل.
- Flutter Web release: بناء ناجح.
- Android APK/AAB وiOS غير الموقّع: ما زالت خطوات البناء جارية في أحدث تشغيل.
- .NET API tests: **14/14 ناجحة**، مع نجاح Release build.
- Docker image build للـ API: نجح في آخر تشغيل API CI مكتمل.
- وظائف Edge Functions المحتفظ بها: فحص الأنواع والاختبارات ناجحة.

راجع [تشغيل CI](https://github.com/gfa437926-tech/metra-weather-intelligence2026/actions) لآخر نتائج البناء.

### ما يمنع الإطلاق الحي

- تم إنشاء دور `metra_api_runtime` كدور غير قابل لتسجيل الدخول ولا يتجاوز RLS، مع منح وصلاحيات وسياسات داخلية للجداول التي تستخدمها API.
- ما زال يلزم إنشاء/توفير login role مُدار يرث صلاحيات `metra_api_runtime`، وحفظ سلسلة اتصال PostgreSQL في مدير أسرار الاستضافة.
- لا توجد خدمة استضافة .NET منشورة أو عنوان إنتاج `METRA_API_URL`.
- مصادر التنبيه الرسمية، إدخال التنبؤات، إنشاء/تعديل المحطات، الإدارة الكاملة للمستخدمين والأدوار، إدارة التشغيل والأعطال، الملفات والتصدير، وتعديلات/مراجعات الرصد الكاملة ما زالت غير مكتملة.
- تمت مصالحة سلسلة migrations: أصبحت ملفات SQL النشطة الـ86 مطابقة لإصدارات السجل البعيد، واستُعيدت المصادر المفقودة من نصوص SQL المحفوظة في سجل Supabase. عُزل ملف legacy غير المطبق في `supabase/pending-migrations/`. كما أُصلحت اختلافات محتوى في ملفات موجودة، لا أسماء الملفات فقط.
- أضيف فحص تغطية للملفات وسلسلة إعادة بناء محلية معزولة. نجح `supabase db reset --local --yes` على قاعدة فارغة، ثم نجحت assertions للتحقق من **46 جدولاً، وRLS على 46/46، و86 سجل migration**، وعدم وجود جدول `public.station_catalogue` القديم.
- لم تُطبق migrations أو تعديلات بيانات على قاعدة Supabase الحية أثناء هذه المعالجة.

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

## اتصال PostgreSQL للإنتاج

إجراءات تجهيز اتصال .NET الآمن، ودور الدخول المحدود، وإدارة الأسرار واختبارات ما قبل النشر موثقة في [دليل اتصال PostgreSQL للإنتاج](docs/PRODUCTION-POSTGRES-CONNECTION-RUNBOOK.md). الدليل تحضيري فقط ولا ينشئ دوراً أو يغير قاعدة البيانات المستضافة.

## توثيق قاعدة البيانات

- [المعمارية الجديدة](docs/DATABASE-ARCHITECTURE-FRESH-DESIGN.md)
- [ERD التفصيلي](docs/DATABASE-ERD-DETAILED.md)
- [قاموس البيانات](docs/DATA-DICTIONARY.md)
- [تتبع المتطلبات](docs/DATABASE-REQUIREMENTS-TRACEABILITY.md)
- [تقرير التنفيذ والتحقق](docs/DATABASE-REBUILD-EXECUTION-2026-11-14.md)
- [جاهزية التنفيذ والخطوات المتبقية](docs/DATABASE-IMPLEMENTATION-READINESS.md)
- [عقد ترحيل .NET API الآمن](docs/API-MIGRATION-CONTRACT.md)

## ملاحظات إعادة البناء

تُراجع سلسلة migrations عبر `supabase/migrations/ledger.manifest` و`python3 scripts/verify_migration_source.py`. يجب أن ينجح اختبار إعادة البناء المحلي الكامل قبل اعتبار إعادة البناء من Git مكتملة. ملف `20261110120000` موجود في `supabase/pending-migrations/` للمراجعة فقط ولا يدخل في سلسلة التنفيذ.

لا تعدّل قاعدة METRA القديمة أو مستودعها، ولا تستورد منها أي بيانات.

## Current implementation status

The development branch contains database-backed .NET 10 endpoints for identity, scoped station directory/review, registration submission and two-stage approval, reference catalogues, typed observation submission/history/review, and a scoped alert-event feed. Flutter station, registration, station-review, observation, approval and alert screens use the .NET API. The map reads verified station coordinates through the API. Dashboard weather values are clearly labelled as Open-Meteo forecasts, not station telemetry.

### Verified CI results

- Flutter analyzer: clean.
- Flutter unit/widget tests: 45 passed.
- Flutter Web release build: passed.
- .NET API tests: 14 passed.
- .NET Release build: passed.
- .NET Docker image build: passed.
- Retained Edge Function type checks and validation tests: passed.
- Android APK/App Bundle and unsigned iOS build workflows are enabled; check the latest CI run for their final artifact status.

### Operational blockers

- The database role `metra_api_runtime` is now provisioned with limited grants and internal RLS policies; it is `NOLOGIN` and `NOBYPASSRLS`. A separate managed login role inheriting it, a protected connection secret, and a .NET hosting target are still required for live DB-backed execution.
- The migration audit found 86 versions in remote Supabase history and 55 SQL files in Git: 32 remote versions have no matching local source file, including the three core greenfield rebuild migrations and earlier identity/observation/security migrations. One local file (`20261110120000_honor_scheduled_permission_revocation.sql`) has no matching remote version. Migration history reconciliation and source recovery are release blockers; do not claim `supabase db reset` is reproducible yet. Additive registration-review and API-runtime migrations are present.
- No organization, station or application-user seed data exists. Scientific parameter/unit definitions remain intentionally empty until approved by a meteorological specialist.
- Official alert ingestion, forecast ingestion, station create/update, full user/role administration, operational incidents, file authorization, exports and full observation revision workflows remain incomplete.
- The five legacy Edge Functions remain deployed but are not used by the migrated Flutter screens; retire them only after confirming no external clients depend on them.

The repository is **not yet a deployable final release**. Passing CI proves source analysis and builds, not live authentication-to-database execution. Keep all work on the development branch; do not merge to `main` until the remaining runtime and security checks pass.
