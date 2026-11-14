# METRA — مصفوفة تتبع المتطلبات إلى نموذج البيانات

**مصدر التتبع:** شاشات Flutter وخدمات البيانات الموجودة في فرع التصميم بتاريخ 2026-11-14، إضافة إلى حدود المنتج الموثقة في README.  
**الحالة:** تحليل متطلبات قاعدة البيانات، وليس تأكيداً بأن كل ميزة متصلة حالياً بقاعدة جديدة.

| الشاشة/الخدمة | الوظيفة المرصودة في التطبيق | الكيانات المطلوبة | عمليات البيانات | نطاق الصلاحية | المرحلة |
|---|---|---|---|---|---|
| إنشاء حساب Auth | إنشاء هوية وتسجيل دخول | مزود Auth + iam.user_profiles | إنشاء/قراءة profile | صاحب الهوية؛ لا صلاحيات مجال تلقائية | MVP |
| بوابة التسجيل | تحديد active/pending/blocked/needs_registration | user_profiles, memberships, registration_requests | قراءة حالة موثوقة | صاحب الحساب فقط؛ القرار خادمي | MVP |
| نموذج طلب الانتساب | الاسم، الهاتف، الدور، المحطة، الموافقة على الشروط، idempotency | registration_requests, roles, stations | إنشاء طلب idempotent | طالب الطلب؛ لا يختار actor أو state | MVP |
| قائمة أدوار التسجيل | عرض الأدوار القابلة للطلب | roles | قراءة أدوار requestable | عامة للمصادق أو حسب السياسة | MVP |
| اختيار المحطة | عرض المحطات المعتمدة والفعالة فقط | stations, station_locations | قراءة دليل معتمد | حسب سياسة دليل المحطات | MVP |
| دليل المحطات | الاسم/الرمز/النوع/الاعتماد/التشغيل/الإحداثيات | stations, station_types, station_locations, station_reviews | قراءة وفلترة | المستخدم النشط؛ التفاصيل وفق النطاق | MVP |
| خريطة المحطات | تجميع المواقع المتطابقة واستبعاد الإحداثيات غير الصالحة/منتهية | station_locations + stations | قراءة مواقع سارية | مستخدم مخول | MVP |
| مراجعة دليل المحطات | approved/rejected/changes_requested مع سبب | station_reviews, stations, audit.events | قرار append-only وتغيير حالة مضبوط | grant مباشر + نطاق مراجعة | MVP |
| سياق الوصول | أدوار وصلاحيات وعضويات | memberships, role_assignments, roles, permissions, role_permissions, permission_grants | حساب صلاحيات فعالة | الخادم فقط | MVP |
| شاشة الرصد | مسودة أو إرسال رصد يدوي | submissions, values, observation_types, parameters, units | create/update draft؛ submit | مستخدم ذو station assignment وصلاحية | MVP |
| قائمة رصد المستخدم | سجلاته وحالاتها | submissions, values, revisions | read own/assigned | مالك الرصد أو مراجع مخول | MVP |
| قائمة انتظار المراجعة | الرصد المقدم لمحطات النطاق | submissions, review_decisions | read queue | صلاحية مراجعة المحطة | MVP |
| مراجعة الرصد | approve/return/reject وملاحظة | review_decisions, revisions, audit.events | append decision + state transition | reviewer غير مقدم الرصد | MVP |
| تصحيح الرصد | حفظ نسخة جديدة دون محو السابق | revisions, values | create revision | صاحب الرصد أو مصحح مخول | MVP |
| QC | قواعد وإشارات الجودة | quality_flags, parameters | evaluate/resolve | خدمة QC ومراجع مختص | مرحلي |
| مرفقات الرصد | دليل/صورة مرتبطة بالإرسال | files.objects, attachments | upload metadata/link | المالك والمراجع المصرح | مرحلي |
| الطقس الحالي | Open-Meteo Damascus في التنفيذ الحالي | weather.providers, ingestion_runs, forecast_runs, forecast_points | fetch/import/cache | قراءة عامة للتنبؤ مع provenance | مرحلي |
| التنبؤ الساعي | قائمة زمنية لدرجات الحرارة وأكواد الطقس | forecast_runs, forecast_points, parameters | import/query | قراءة حسب سياسة النشر | مرحلي |
| مراكز التنبؤ | مقارنة مواقع المحطات؛ لا بيانات تيليمترية لحظية | stations, station_locations | قراءة فقط | مستخدم نشط | MVP للكتالوج |
| التحذيرات الرسمية | غير متصلة حالياً | alerts domain غير معتمد بعد | لا توجد عمليات live | — | مستقبل |
| طبقات الرادار/الهطول/الرياح | غير متصلة حالياً | provider-backed products TBD | لا تخزين live قبل عقد المصدر | — | مستقبل |
| المناخ/Climatol/AI | غير معتمد بعقد علمي هنا | climate datasets/jobs/results TBD | لا DDL قبل العقد | — | مستقبل |
| التدقيق | تسجيل قرارات التسجيل/المحطة/الرصد والصلاحيات | audit.events | append-only write | خدمة خادمية؛ قراءة محدودة | MVP |
| تكامل المصادر | تسجيل مصدر، عملية جلب، نتيجة، correlation | integration.sources, execution_runs | orchestration metadata | خدمة خادمية | مرحلي |

## 1. متطلبات API والمعاملات

- جميع الأفعال الحساسة تنفذ عبر trusted .NET API أو خدمة خادمية موثوقة، مع اشتقاق actor من JWT validated.
- إنشاء التسجيل والرصد وقرارات المراجعة idempotent أو محمية بمفتاح/expected state.
- تغيير الحالة وسجل القرار والـ audit event تتم في transaction واحدة.
- لا يقبل الخادم station_id أو reviewer_id أو role_id كدليل صلاحية؛ يعيد التحقق من النطاق والصلاحيات.
- كل استعلام محطة/رصد يقيّد بالجهة والمحطة المصرح بهما؛ اختبار BOLA/IDOR إلزامي.
- لا تنشأ بيانات demo في الإنتاج؛ بيانات الاختبار الاصطناعية تحمل `is_demo=true` أو namespace منفصل.

## 2. فجوات تتطلب اعتماداً قبل migrations

1. قاموس الرصد العلمي: أسماء المعايير، النوع، الوحدة، الدقة، الحدود، طرق القياس، الترميز.
2. التوقيت: هل تدخل الشاشة وقتاً محلياً أم UTC؟ ما سياسة حفظ الوقت الأصلي والانزياح؟
3. النموذج: هل `daily` و`phenomenon` هما كل أنواع الرصد المطلوبة؟ ما حقول النماذج المعتمدة؟
4. الصلاحيات: قائمة الأدوار الفعلية، granular permissions، scopes، الفصل بين مرحلتي المراجعة.
5. سجل المحطة: مصدر البيانات الجديد، المالك، سياسة التحقق من الموقع والارتفاع والرموز الخارجية.
6. التكاملات: مزود الطقس المرخص، معدل الجلب، حفظ payload، شروط الاحتفاظ.
7. الملفات: الأنواع المسموحة، الحجم، الفحص، مدة الاحتفاظ والتصنيف.
8. الحوكمة: الاحتفاظ والحذف/التصدير والنسخ الاحتياطي والتدقيق.

## 3. قرار خاص بإعادة البناء من الصفر

يحتوي المستودع حالياً على `supabase/migrations` قائمة مرتبطة بخط التطبيق الحالي. لا يجوز تعديل ملفاتها التاريخية أو حذفها أو إعادة ترقيمها لتبدو كأنها قاعدة جديدة. بعد اعتماد ERD والقاموس، تُنشأ baseline مستقلة لاختبار disposable database بمسار/config مستقل، مع خطوات تشغيل موثقة، وتبقى سلسلة التطبيق الحالية كما هي. يجب أن يثبت الاختبار أن قاعدة فارغة يمكن أن تُبنى بالكامل دون الاتصال بقاعدة الإنتاج ودون أي استيراد بيانات قديمة.
