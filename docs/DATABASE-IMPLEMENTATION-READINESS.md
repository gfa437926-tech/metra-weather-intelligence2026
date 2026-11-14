# METRA Greenfield Database — خطة تنفيذ migrations والتحقق

**الحالة:** بوابة تنفيذ وتجهيز؛ لا توجد migrations جديدة مطبقة بعد.  
**الفرع:** `work/database-architecture-fresh-design-2026-11-14`  
**قاعدة السلامة:** لا اتصال ولا كتابة على أي مشروع Supabase مستضاف خلال هذه المرحلة.

## 1. قرار الفصل

المستودع يحتوي بالفعل على `supabase/migrations/` لتاريخ تنفيذ التطبيق الحالي. لن نعيد كتابة هذه الملفات أو نعيد ترقيمها أو نضع baseline الجديدة بينها.

سيكون مصدر الحقيقة المستقل للتصميم الجديد في مساحة عمل منفصلة (Greenfield workdir) بعد اعتماد هذا المستند، بحيث:
- تكون migrations الجديدة مستقلة عن التاريخ الحالي.
- تبدأ من قاعدة اختبار فارغة تماماً.
- لا تتطلب schema أو بيانات أو migration history من مشروع مستضاف.
- لا تتضمن أي INSERT لبيانات محطات أو مستخدمين قديمة.
- بيانات الاختبار الاصطناعية، إن أضيفت لاحقاً، تكون منفصلة ومعلّمة بوضوح.

## 2. متطلبات بيئة البناء

- Supabase CLI مثبت بإصدار مثبت/محدد في CI.
- Docker-compatible runtime لتشغيل Supabase local stack.
- قاعدة محلية مؤقتة disposable.
- لا تستخدم `supabase link` ولا متغيرات `SUPABASE_DB_PASSWORD` أو مفاتيح مشروع مستضاف في وظيفة اختبار baseline.
- لا تستخدم `--remote` أو `--linked` في وظيفة إعادة البناء.
- يجب أن يفشل CI إذا لم يكن الهدف محلياً أو إذا تطلبت الأوامر اتصالاً مستضافاً.

**ملاحظة بيئية:** بيئة التنفيذ المستخدمة في جلسة إعداد هذا المستند لا تحتوي على Supabase CLI أو Docker أو psql؛ لذلك لم أتمكن من توليد ملف migration عبر CLI أو تشغيل إعادة البناء محلياً. لا أصف أي migration بأنها مختبرة قبل تشغيلها في بيئة مناسبة.

## 3. طريقة إنشاء ملفات migration

عند بدء التنفيذ داخل مساحة العمل الجديدة، استخدم CLI لتوليد كل ملف، ولا تنشئ أسماء timestamp يدوياً:

```bash
supabase --workdir <greenfield-workdir> migration new 0001_create_foundation
supabase --workdir <greenfield-workdir> migration new 0002_create_identity_and_catalog
supabase --workdir <greenfield-workdir> migration new 0003_create_observation_domain
supabase --workdir <greenfield-workdir> migration new 0004_add_security_and_audit
```

تُملأ الملفات بالـ DDL المعتمد فقط. لا تنفذها على مشروع مستضاف.

## 4. ترتيب التنفيذ المقترح

| الترتيب | Migration | المحتوى | شرط البدء |
|---:|---|---|---|
| 1 | foundation | schemas, extensions المعتمدة, common functions, grants baseline | اعتماد حدود schemas والإضافات |
| 2 | identity | profiles, organizations, units, memberships, roles, permissions, assignments, grants | اعتماد RBAC وAuth subject mapping |
| 3 | catalogue | station types, stations, identifiers, locations, capabilities, operating periods, reviews | اعتماد مصدر المحطات وحقول الموقع |
| 4 | reference | units, parameters, observation types | اعتماد قاموس علمي أولي |
| 5 | observations | submissions, values, revisions, review decisions, QC flags, attachments | اعتماد نماذج الرصد ودورياتها |
| 6 | weather | providers, ingestion, forecast runs/points, mappings | اعتماد مزود وعقد البيانات |
| 7 | integration/audit | execution runs, file metadata, audit events | اعتماد الاحتفاظ والتصنيف |
| 8 | security | RLS, grants, policies, API-only mutation boundaries | اعتماد مصفوفة الصلاحيات النهائية |

لا يلزم أن تدخل جميع المجالات في MVP؛ يمكن تأجيل migrations الخاصة بـ weather أو غيرها بقرار نطاق موثق.

## 5. اختبارات إعادة البناء المطلوبة

كل الاختبارات التالية يجب أن تعمل على قاعدة محلية فارغة:

1. تشغيل `supabase start` على بيئة الاختبار.
2. تشغيل `supabase db reset` وإثبات تطبيق جميع migrations بالترتيب.
3. إعادة تشغيل reset مرة ثانية وإثبات عدم وجود اعتماد على حالة سابقة.
4. التحقق من وجود جميع schemas والجداول والمفاتيح والقيود والفهارس.
5. التحقق من أن كل جدول مكشوف للعميل عليه RLS وسياسات محددة، وأن schemas الداخلية غير مكشوفة.
6. اختبار مستخدمين بنطاقين مختلفين لإثبات منع الوصول الأفقي BOLA/IDOR.
7. اختبار منع المراجع من اعتماد إرساله الشخصي.
8. اختبار منع قرار على revision قديمة ومنع تكرار idempotency key.
9. اختبار XOR لحقول typed values وquality flags ومراجع access review.
10. اختبار منع UPDATE/DELETE على audit events من أدوار التطبيق.
11. التأكد من أن القاعدة الفارغة لا تحتوي أي سجلات محطة أو مستخدمين من قواعد سابقة.
12. استخراج schema snapshot ومقارنته مع baseline المعتمدة.

## 6. معايير قبول migration

- قابلة للتطبيق من قاعدة فارغة.
- حتمية: النتيجة نفسها في كل إعادة بناء.
- لا تعتمد على ترتيب تنفيذ يدوي خارج migration history.
- لا تتضمن أسراراً أو مفاتيح أو بيانات إنتاج.
- كل FK وCHECK وUNIQUE موثق في قاموس البيانات.
- كل صلاحية لها اختبار إيجابي وسلبي.
- كل جدول حساس له RLS أو حظر صريح للوصول المباشر.
- لا توجد صلاحيات عامة أو دوال SECURITY DEFINER بلا ضرورة ومراجعة.
- لا تتغير migrations الحالية للتطبيق.
- لا يتم نشر migration إلى Supabase المستضاف قبل موافقة مستقلة وصريحة.

## 7. مسائل يجب حسمها قبل DDL الكامل

1. اعتماد هيكل الجهات والوحدات وربط المحطات.
2. اعتماد قائمة الأدوار والصلاحيات ونطاق كل دور.
3. اعتماد طريقة ربط `auth.users.id` مع `iam.user_profiles.auth_subject`.
4. اعتماد مصدر المحطات الجديد ومعرفاته وإحداثياته.
5. اعتماد قاموس البارامترات والوحدات ونماذج الرصد من مختص الأرصاد.
6. تحديد MVP: هل التنبؤات الخارجية تدخل baseline الأولى أم تؤجل؟
7. اعتماد سياسات الاحتفاظ بالملفات والتدقيق والبيانات التشغيلية.

## 8. سجل التحقق الحالي

| الفحص | النتيجة |
|---|---|
| ERD وقاموس البيانات محفوظان في الفرع | ناجح — تم التحقق من GitHub |
| تتبع الشاشات إلى الكيانات | ناجح — وثيقة موجودة |
| فصل المسار الجديد عن migrations الحالية | محدد كشرط إلزامي |
| Supabase CLI متاح في بيئة الجلسة | غير متاح |
| Docker / PostgreSQL client متاح | غير متاح |
| إنشاء migration عبر CLI | لم ينفذ |
| إعادة البناء على قاعدة فارغة | لم تنفذ |
| اختبار RLS وقيود المجال | لم ينفذ |
| تطبيق على مشروع مستضاف | لم ينفذ، وممنوع ضمن هذه المرحلة |

## 9. مراجع الأدوات

- Supabase CLI v3 migration guide: https://supabase.com/docs/guides/local-development/cli/migrating-to-v3
- Local development workflow: https://supabase.com/docs/guides/local-development/cli-workflows
- CLI migration new: https://supabase.com/docs/reference/cli/supabase-migration-new
