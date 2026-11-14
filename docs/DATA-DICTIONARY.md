# METRA Weather Intelligence — قاموس البيانات والقيود

**الحالة:** مسودة تفصيلية للمراجعة؛ ليست DDL مطبقة.  
**المبدأ:** تصميم جديد؛ لا نقل بيانات ولا استنساخ مخطط قديم.  
**الأنواع:** PostgreSQL مقترحة. PK مفتاح أساسي، FK أجنبي، UQ تفرد، NN إلزامي، CK تحقق، IDX فهرس.

## 1. قواعد مشتركة

- UUID للمعرفات؛ `timestamptz` للأوقات المطلقة.
- كل جدول تشغيلي يملك PK، وحقول created_at/updated_at حسب قابلية التعديل.
- الفترات: valid_from < valid_to، مع منع التداخل حيث يلزم.
- actor يشتق من JWT/سياق API موثوق، لا من client.
- لا كلمات مرور أو مفاتيح API أو service-role أو أسرار في الجداول.
- كل حالات lifecycle مضبوطة بقيم معروفة.
- لا تُحذف سجلات الرصد والقرارات والتدقيق لإخفاء التاريخ.
- الحدود والدقة العلمية **TBD** حتى اعتماد مختص الأرصاد.

## 2. IAM — schema `iam`

### user_profiles
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | معرف الملف |
| auth_subject | uuid | لا | UQ | subject خارجي من Auth |
| display_name | text | نعم | CK غير فارغ عند وجوده | الاسم المعروض |
| preferred_locale | text | لا | CK قائمة لغات معتمدة | اللغة |
| profile_state | text | لا | CK active/disabled/pending_review | حالة الملف |
| created_at | timestamptz | لا | default now() | الإنشاء |
| updated_at | timestamptz | نعم | — | التحديث |

### organizations
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ | رمز الجهة |
| name_ar | text | لا | CK غير فارغ | الاسم العربي |
| name_en | text | نعم | — | الاسم الإنجليزي |
| organization_state | text | لا | CK active/suspended/closed | الحالة |
| created_at | timestamptz | لا | default now() | الإنشاء |
| updated_at | timestamptz | نعم | — | التحديث |

### organization_units
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| organization_id | uuid | لا | FK organizations؛ IDX | الجهة |
| parent_unit_id | uuid | نعم | FK self؛ IDX | الوحدة الأم |
| code | text | لا | UQ(organization_id,code) | رمز داخل الجهة |
| name_ar | text | لا | CK غير فارغ | الاسم |
| name_en | text | نعم | — | الاسم الإنجليزي |
| unit_state | text | لا | CK active/inactive | الحالة |
| created_at | timestamptz | لا | default now() | الإنشاء |

### memberships
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| user_id | uuid | لا | FK user_profiles؛ IDX | المستخدم |
| organization_id | uuid | لا | FK organizations؛ IDX | الجهة |
| organization_unit_id | uuid | نعم | FK organization_units؛ IDX | الوحدة |
| membership_state | text | لا | CK requested/active/suspended/ended | الحالة |
| valid_from | timestamptz | نعم | CK مع valid_to | بداية السريان |
| valid_to | timestamptz | نعم | CK valid_from < valid_to | النهاية |
| created_at | timestamptz | لا | default now() | الإنشاء |
| created_by | uuid | نعم | FK user_profiles | منشئ العضوية |

### roles
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ؛ صيغة code معتمدة | رمز ثابت |
| name_ar | text | لا | CK غير فارغ | الاسم |
| name_en | text | نعم | — | الاسم الإنجليزي |
| description | text | نعم | — | الوصف |
| is_requestable | boolean | لا | default false | قابل للطلب |
| is_system | boolean | لا | default false | دور محمي |
| role_state | text | لا | CK active/retired | الحالة |
| created_at | timestamptz | لا | default now() | الإنشاء |

### permissions
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ | رمز domain.action |
| name_ar | text | لا | CK غير فارغ | الاسم |
| description | text | نعم | — | الوصف |
| risk_level | text | لا | CK low/medium/high/critical | الخطورة |
| permission_state | text | لا | CK active/retired | الحالة |
| created_at | timestamptz | لا | default now() | الإنشاء |

### role_permissions
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| role_id | uuid | لا | PK جزء + FK roles | الدور |
| permission_id | uuid | لا | PK جزء + FK permissions | الصلاحية |
| created_at | timestamptz | لا | default now() | الإنشاء |
| created_by | uuid | نعم | FK user_profiles | المعتمد |

PK(role_id, permission_id).

### role_assignments
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| membership_id | uuid | لا | FK memberships؛ IDX | العضوية |
| role_id | uuid | لا | FK roles؛ IDX | الدور |
| scope_type | text | لا | CK global/organization/unit/station | النطاق |
| organization_id | uuid | نعم | FK organizations | نطاق الجهة |
| organization_unit_id | uuid | نعم | FK organization_units | نطاق الوحدة |
| station_id | uuid | نعم | FK catalog.stations | نطاق المحطة |
| valid_from | timestamptz | لا | CK | البداية |
| valid_to | timestamptz | نعم | CK valid_from < valid_to | النهاية |
| assignment_state | text | لا | CK active/suspended/revoked/expired | الحالة |
| assigned_by | uuid | لا | FK user_profiles | المعيّن |
| created_at | timestamptz | لا | default now() | الإنشاء |

CK يطابق scope_type مع معرفات النطاق. تطابق organization/unit/station يحتاج FK مركب أو trigger معتمد.

### permission_grants
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| user_id | uuid | لا | FK user_profiles؛ IDX | المستفيد |
| permission_id | uuid | لا | FK permissions؛ IDX | الصلاحية |
| scope_type | text | لا | CK كما في role_assignments | النطاق |
| organization_id | uuid | نعم | FK organizations | الجهة |
| organization_unit_id | uuid | نعم | FK organization_units | الوحدة |
| station_id | uuid | نعم | FK catalog.stations | المحطة |
| valid_from | timestamptz | لا | CK | البداية |
| valid_to | timestamptz | لا | CK valid_from < valid_to | نهاية إلزامية |
| grant_state | text | لا | CK active/revoked/expired | الحالة |
| granted_by | uuid | لا | FK user_profiles | المانح |
| reason | text | لا | CK غير فارغ | المبرر |
| created_at | timestamptz | لا | default now() | الإنشاء |

### access_reviews
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| role_assignment_id | uuid | نعم | FK role_assignments | التعيين محل المراجعة |
| permission_grant_id | uuid | نعم | FK permission_grants | التفويض محل المراجعة |
| reviewer_user_id | uuid | لا | FK user_profiles | المراجع |
| decision | text | لا | CK retain/revoke/expire | القرار |
| reason | text | لا | CK غير فارغ | السبب |
| decided_at | timestamptz | لا | default now() | الوقت |
| next_review_at | timestamptz | نعم | CK > decided_at | الموعد التالي |

CK XOR: أحد مرجعي التعيين أو التفويض فقط.

### registration_requests
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| applicant_user_id | uuid | لا | FK user_profiles؛ IDX | مقدم الطلب |
| requested_role_id | uuid | لا | FK roles؛ IDX | الدور المطلوب |
| requested_station_id | uuid | لا | FK catalog.stations؛ IDX | المحطة |
| first_name | text | لا | CK غير فارغ | الاسم الأول |
| father_name | text | لا | CK غير فارغ | اسم الأب |
| last_name | text | لا | CK غير فارغ | اسم العائلة |
| contact_phone | text | نعم | صيغة معيارية TBD | الهاتف |
| terms_version | text | لا | مرجع إصدار شروط معتمد | النسخة المقبولة |
| terms_accepted_at | timestamptz | لا | — | وقت الموافقة |
| idempotency_key | text | لا | UQ(applicant_user_id,key) | منع التكرار |
| request_state | text | لا | CK pending_station/pending_system/approved/rejected/withdrawn | الحالة |
| submitted_at | timestamptz | لا | default now() | الإرسال |
| updated_at | timestamptz | نعم | — | التحديث |

### registration_decisions
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| request_id | uuid | لا | FK registration_requests؛ IDX | الطلب |
| stage | text | لا | CK station/system | المرحلة |
| decision | text | لا | CK approved/rejected/changes_requested | النتيجة |
| actor_user_id | uuid | لا | FK user_profiles | صاحب القرار |
| reason | text | لا | CK مطلوب للرفض/التعديل | السبب |
| decided_at | timestamptz | لا | default now() | الوقت |
| correlation_id | uuid | نعم | IDX | ربط العملية |

يمنع أن يكون مقدم الطلب هو صاحب القرار. سياسة إعادة المحاولة/attempt_no تُحسم قبل DDL.

## 3. دليل المحطات — schema `catalog`

### station_types
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ | الرمز |
| name_ar | text | لا | CK غير فارغ | الاسم |
| name_en | text | نعم | — | الاسم الإنجليزي |
| state | text | لا | CK active/retired | الحالة |

### stations
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| organization_id | uuid | لا | FK iam.organizations؛ IDX | المالك |
| station_type_id | uuid | لا | FK station_types؛ IDX | النوع |
| local_station_code | text | لا | UQ(organization_id,code) | رمز محلي جديد |
| name_ar | text | لا | CK غير فارغ | الاسم |
| name_en | text | نعم | — | الاسم الإنجليزي |
| approval_status | text | لا | CK pending/approved/rejected/changes_requested | اعتماد الكتالوج |
| operational_status | text | لا | CK unverified/active/inactive/suspended/decommissioned | حالة التشغيل |
| catalogue_source_id | uuid | نعم | FK integration.sources؛ IDX | المصدر |
| source_record_key | text | نعم | UQ(source,key) partial | مفتاح المصدر |
| is_demo | boolean | لا | default false | بيانات اصطناعية معلّمة |
| created_at | timestamptz | لا | default now() | الإنشاء |
| created_by | uuid | نعم | FK iam.user_profiles | المنشئ |
| updated_at | timestamptz | نعم | — | التحديث |

### station_identifiers
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| station_id | uuid | لا | FK stations؛ IDX | المحطة |
| namespace | text | لا | — | مصدر الرمز |
| identifier | text | لا | UQ(namespace,identifier) | الرمز الخارجي |
| valid_from | timestamptz | نعم | CK | البداية |
| valid_to | timestamptz | نعم | CK | النهاية |
| verified_at | timestamptz | نعم | — | التحقق |
| verification_source | text | نعم | — | مرجع التحقق |

### station_locations
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| station_id | uuid | لا | FK stations؛ IDX | المحطة |
| latitude | numeric(9,6) | نعم | CK -90..90 | خط العرض |
| longitude | numeric(9,6) | نعم | CK -180..180 | خط الطول |
| elevation_m | numeric(9,2) | نعم | المدى TBD | الارتفاع |
| elevation_datum | text | نعم | — | مرجع الارتفاع |
| timezone_id | text | نعم | IANA validation at API | المنطقة الزمنية |
| valid_from | timestamptz | لا | CK | بداية صلاحية الموقع |
| valid_to | timestamptz | نعم | CK valid_from < valid_to | نهاية الصلاحية |
| verification_state | text | لا | CK unverified/pending/verified/rejected | التحقق |
| source_reference | text | نعم | — | المصدر |
| verified_by | uuid | نعم | FK iam.user_profiles | المتحقق |
| created_at | timestamptz | لا | default now() | الإنشاء |

الإحداثيات اختيارية حتى ترد من مصدر موثق؛ يمنع تداخل المواقع السارية للمحطة وفق السياسة.

### station_capabilities
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| station_id | uuid | لا | FK stations؛ IDX | المحطة |
| capability_code | text | لا | قاموس معتمد TBD | القدرة |
| valid_from | timestamptz | لا | CK | البداية |
| valid_to | timestamptz | نعم | CK | النهاية |
| capability_state | text | لا | CK active/inactive/maintenance | الحالة |
| source_reference | text | نعم | — | المصدر |

### station_operating_periods
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| station_id | uuid | لا | FK stations؛ IDX | المحطة |
| operating_state | text | لا | CK active/inactive/suspended/decommissioned | حالة التشغيل |
| valid_from | timestamptz | لا | CK | البداية |
| valid_to | timestamptz | نعم | CK | النهاية |
| reason_code | text | نعم | قاموس TBD | السبب |
| notes | text | نعم | — | ملاحظات |
| recorded_by | uuid | نعم | FK iam.user_profiles | المسجل |

### station_reviews
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| station_id | uuid | لا | FK stations؛ IDX | المحطة |
| reviewer_user_id | uuid | لا | FK iam.user_profiles | المراجع |
| decision | text | لا | CK approved/rejected/changes_requested | القرار |
| reason | text | لا | CK غير فارغ | السبب |
| evidence_file_id | uuid | نعم | FK files.objects | الدليل |
| decided_at | timestamptz | لا | default now() | الوقت |
| review_version | integer | لا | UQ(station_id,version); CK > 0 | الإصدار |

## 4. القواميس العلمية — schema `ref`

### units
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ | رمز الوحدة |
| symbol | text | لا | — | الرمز |
| name_ar | text | لا | CK غير فارغ | الاسم |
| name_en | text | نعم | — | الاسم الإنجليزي |
| quantity_kind | text | لا | قاموس معتمد TBD | نوع الكمية |
| is_canonical | boolean | لا | default false | وحدة معيارية |
| unit_state | text | لا | CK active/retired | الحالة |
| definition_version | text | لا | — | إصدار التعريف |

### meteorological_parameters
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ(code,definition_version) | رمز البارامتر |
| name_ar | text | لا | CK غير فارغ | الاسم |
| name_en | text | نعم | — | الاسم الإنجليزي |
| quantity_kind | text | لا | قاموس TBD | نوع الكمية |
| canonical_unit_id | uuid | نعم | FK units | الوحدة القياسية |
| value_kind | text | لا | CK decimal/integer/text/boolean/code | نوع القيمة |
| precision_scale | smallint | نعم | TBD | الدقة |
| valid_min | numeric | نعم | TBD؛ CK min<=max | الحد الأدنى |
| valid_max | numeric | نعم | TBD؛ CK max>=min | الحد الأعلى |
| definition_version | text | لا | — | الإصدار |
| valid_from | timestamptz | لا | — | بداية الاعتماد |
| valid_to | timestamptz | نعم | CK | نهاية الاعتماد |
| parameter_state | text | لا | CK active/retired | الحالة |
| specification_reference | text | نعم | — | وثيقة الاعتماد العلمي |

**لا تضع أرقاماً في valid_min/valid_max أو precision_scale قبل اعتماد المرجع العلمي.**

### observation_types
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ | الرمز |
| name_ar | text | لا | — | الاسم |
| name_en | text | نعم | — | الاسم الإنجليزي |
| cadence_code | text | نعم | TBD | الدورية |
| form_version | text | لا | — | إصدار النموذج |
| type_state | text | لا | CK active/retired | الحالة |

## 5. الرصد — schema `observations`

### submissions
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| station_id | uuid | لا | FK catalog.stations؛ IDX | المحطة |
| author_user_id | uuid | لا | FK iam.user_profiles؛ IDX | مقدم الرصد |
| observation_type_id | uuid | لا | FK ref.observation_types | النوع |
| observed_at | timestamptz | لا | IDX | وقت الرصد |
| source_local_time | timestamp | نعم | — | الوقت المحلي الأصلي |
| source_timezone_id | text | نعم | — | المنطقة الزمنية الأصلية |
| submission_state | text | لا | CK draft/submitted/returned/approved/rejected/withdrawn | الحالة |
| idempotency_key | text | لا | UQ(author,idempotency_key) | منع التكرار |
| request_fingerprint | text | نعم | — | بصمة الطلب |
| submitted_at | timestamptz | نعم | required after submit | وقت الإرسال |
| current_revision_no | integer | لا | default 1؛ CK > 0 | الإصدار الحالي |
| created_at | timestamptz | لا | default now() | الإنشاء |
| updated_at | timestamptz | نعم | — | التحديث |
| source_kind | text | لا | CK manual/instrument/imported | المصدر |
| source_reference | text | نعم | — | معرف المصدر |

### values
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| submission_id | uuid | لا | FK submissions؛ IDX | الإرسال |
| parameter_id | uuid | لا | FK ref.meteorological_parameters؛ IDX | البارامتر |
| value_decimal | numeric | نعم | typed XOR | قيمة عشرية |
| value_integer | bigint | نعم | typed XOR | قيمة صحيحة |
| value_text | text | نعم | typed XOR | قيمة نصية/رمزية |
| value_boolean | boolean | نعم | typed XOR | قيمة منطقية |
| reported_unit_id | uuid | نعم | FK ref.units | الوحدة المبلّغ بها |
| normalized_value_decimal | numeric | نعم | — | القيمة المحولة |
| normalized_unit_id | uuid | نعم | FK ref.units | الوحدة القياسية |
| reported_value_text | text | نعم | — | النص الأصلي |
| measurement_method | text | نعم | قاموس TBD | طريقة القياس |
| quality_state | text | لا | CK unassessed/valid/suspect/invalid | حالة الجودة |
| created_at | timestamptz | لا | default now() | الإنشاء |

يلزم تطابق العمود typed الوحيد مع value_kind في تعريف البارامتر. التكرار للبارامتر الواحد يتطلب تعريفاً صريحاً للأبعاد/المستوى/replicate.

### revisions
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| submission_id | uuid | لا | FK submissions؛ IDX | الإرسال |
| revision_no | integer | لا | UQ(submission,revision_no); CK > 0 | الإصدار |
| snapshot | jsonb | لا | object only | لقطة إصدار |
| schema_version | text | لا | — | إصدار المخطط |
| change_reason | text | لا | CK غير فارغ | السبب |
| created_by | uuid | لا | FK iam.user_profiles | المنشئ |
| created_at | timestamptz | لا | default now() | الإنشاء |

### review_decisions
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| submission_id | uuid | لا | FK submissions؛ IDX | الإرسال |
| reviewer_user_id | uuid | لا | FK iam.user_profiles؛ IDX | المراجع |
| decision | text | لا | CK approved/return_for_correction/rejected | القرار |
| note | text | نعم | required on return/reject | الملاحظة |
| expected_revision_no | integer | لا | CK > 0 | optimistic concurrency |
| decided_at | timestamptz | لا | default now() | الوقت |
| correlation_id | uuid | نعم | IDX | ربط الطلب |

يمنع self-review، ويجب تحقق station scope، وتمنع القرارات على نسخة قديمة.

### quality_flags
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| submission_id | uuid | نعم | FK submissions | مستوى الإرسال |
| observation_value_id | uuid | نعم | FK values | مستوى القيمة |
| rule_code | text | لا | — | رمز القاعدة |
| rule_version | text | لا | — | إصدارها |
| severity | text | لا | CK info/warning/error/critical | الشدة |
| result | text | لا | CK pass/suspect/fail/manual_review | النتيجة |
| explanation | text | نعم | — | السبب |
| evaluated_at | timestamptz | لا | default now() | وقت التقييم |
| resolved_by | uuid | نعم | FK iam.user_profiles | المعالج |
| resolved_at | timestamptz | نعم | CK مع resolved_by | وقت المعالجة |

CK XOR: submission_id أو observation_value_id فقط.

### attachments
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| submission_id | uuid | لا | FK submissions؛ IDX | الإرسال |
| file_object_id | uuid | لا | FK files.objects؛ IDX | الملف |
| attachment_kind | text | لا | قاموس TBD | النوع |
| caption | text | نعم | — | الوصف |
| attached_by | uuid | لا | FK iam.user_profiles | الرافع |
| attached_at | timestamptz | لا | default now() | الوقت |
| is_restricted | boolean | لا | default true | التصنيف |

## 6. التنبؤات الخارجية — schema `weather` (مرحلي)

### providers
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ | الرمز |
| name | text | لا | CK غير فارغ | الاسم |
| provider_kind | text | لا | CK forecast/observation/alert | النوع |
| documentation_url | text | نعم | — | الوثائق |
| contract_version | text | نعم | — | إصدار العقد |
| provider_state | text | لا | CK planned/active/suspended/retired | الحالة |
| terms_reference | text | نعم | — | شروط الاستخدام |

### ingestion_runs
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| provider_id | uuid | لا | FK providers؛ IDX | المزود |
| idempotency_key | text | لا | UQ(provider,key) | منع التكرار |
| started_at | timestamptz | لا | — | البداية |
| completed_at | timestamptz | نعم | CK >= start | النهاية |
| run_state | text | لا | CK queued/running/succeeded/partial/failed/cancelled | الحالة |
| records_received | bigint | نعم | CK >= 0 | المستلم |
| records_accepted | bigint | نعم | CK >= 0 | المقبول |
| error_code | text | نعم | — | الخطأ |
| correlation_id | uuid | نعم | IDX | ربط العملية |

### forecast_runs
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| provider_id | uuid | لا | FK providers؛ IDX | المزود |
| ingestion_run_id | uuid | لا | FK ingestion_runs؛ IDX | عملية الجلب |
| model_code | text | نعم | — | النموذج |
| model_version | text | نعم | — | الإصدار |
| issued_at | timestamptz | لا | IDX | الإصدار |
| retrieved_at | timestamptz | لا | — | الاسترجاع |
| coverage_start | timestamptz | نعم | CK | بداية التغطية |
| coverage_end | timestamptz | نعم | CK | النهاية |
| run_state | text | لا | CK received/validated/published/withdrawn | الحالة |
| source_reference | text | نعم | UQ(provider,reference) partial | مرجع المصدر |

### forecast_points
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| forecast_run_id | uuid | لا | FK forecast_runs؛ IDX | الدورة |
| parameter_id | uuid | لا | FK ref.parameters؛ IDX | البارامتر |
| valid_at | timestamptz | لا | IDX | وقت الصلاحية |
| latitude | numeric(9,6) | نعم | CK -90..90 | خط العرض |
| longitude | numeric(9,6) | نعم | CK -180..180 | خط الطول |
| grid_cell_reference | text | نعم | — | مرجع خلية |
| value_decimal | numeric | نعم | حسب value_kind | قيمة عشرية |
| value_integer | bigint | نعم | حسب value_kind | صحيحة |
| value_text | text | نعم | حسب value_kind | نصية |
| unit_id | uuid | نعم | FK ref.units | الوحدة |
| provider_parameter_code | text | نعم | — | رمز المزود |
| created_at | timestamptz | لا | default now() | الإنشاء |

يجب تحديد تمثيل مكاني واحد بعقد المزود؛ لا يسمح بسجل بلا موقع أو خلية.

### forecast_parameter_mappings
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| provider_id | uuid | لا | FK providers | المزود |
| provider_parameter_code | text | لا | UQ(provider,code,version) | رمز المزود |
| parameter_id | uuid | لا | FK ref.parameters | البارامتر القياسي |
| provider_unit_code | text | نعم | — | وحدة المزود |
| mapping_version | text | لا | — | الإصدار |
| valid_from | timestamptz | لا | — | البداية |
| valid_to | timestamptz | نعم | CK | النهاية |

### provider_payload_references
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| ingestion_run_id | uuid | لا | FK ingestion_runs؛ IDX | التشغيل |
| file_object_id | uuid | لا | FK files.objects؛ IDX | الملف |
| payload_kind | text | لا | CK response/request/manifest | النوع |
| captured_at | timestamptz | لا | default now() | الالتقاط |
| retention_until | timestamptz | نعم | — | الاحتفاظ |
| content_sha256 | text | لا | CK 64 hex | البصمة |

## 7. الملفات والتكامل والتدقيق

### files.objects
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| bucket_name | text | لا | — | bucket خاص |
| object_key | text | لا | UQ(bucket,key) | المسار |
| original_filename | text | نعم | sanitization | الاسم الأصلي |
| content_type | text | لا | allow-list API | MIME |
| byte_size | bigint | لا | CK >= 0 | الحجم |
| sha256 | text | لا | CK 64 hex | البصمة |
| classification | text | لا | CK public/internal/confidential/restricted | التصنيف |
| owner_user_id | uuid | نعم | FK iam.user_profiles | المالك |
| uploaded_at | timestamptz | لا | default now() | الرفع |
| retention_until | timestamptz | نعم | — | موعد الحذف |
| object_state | text | لا | CK pending/available/quarantined/deleted | الحالة |

### integration.sources
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| code | text | لا | UQ | الرمز |
| name | text | لا | — | الاسم |
| source_kind | text | لا | CK station_catalog/forecast/alert/climate/other | النوع |
| contract_version | text | نعم | — | إصدار العقد |
| endpoint_reference | text | نعم | بلا أسرار/tokens | مرجع endpoint |
| source_state | text | لا | CK planned/active/suspended/retired | الحالة |
| approved_at | timestamptz | نعم | — | الاعتماد |

### integration.execution_runs
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| source_id | uuid | لا | FK integration.sources؛ IDX | المصدر |
| operation_code | text | لا | — | العملية |
| idempotency_key | text | لا | UQ(source,key) | منع التكرار |
| started_at | timestamptz | لا | — | البداية |
| completed_at | timestamptz | نعم | CK >= start | النهاية |
| run_state | text | لا | CK queued/running/succeeded/partial/failed/cancelled | الحالة |
| result_summary | jsonb | نعم | object only; bounded | ملخص غير حساس |
| error_code | text | نعم | — | رمز الخطأ |
| correlation_id | uuid | نعم | IDX | الربط |

### audit.events
| العمود | النوع | Null | القيود | المعنى |
|---|---|---:|---|---|
| id | uuid | لا | PK | المعرف |
| occurred_at | timestamptz | لا | default now(); IDX | وقت الحدث |
| actor_user_id | uuid | نعم | FK iam.user_profiles؛ IDX | الفاعل |
| action_code | text | لا | — | الفعل |
| entity_schema | text | لا | — | schema |
| entity_table | text | لا | — | الجدول |
| entity_id | uuid | نعم | — | الكيان |
| organization_id | uuid | نعم | FK iam.organizations؛ IDX | نطاق الجهة |
| station_id | uuid | نعم | FK catalog.stations؛ IDX | نطاق المحطة |
| outcome | text | لا | CK success/denied/failure | النتيجة |
| correlation_id | uuid | نعم | IDX | ربط الطلب |
| metadata | jsonb | لا | object only; redacted | metadata منقحة |

audit.events append-only؛ يمنع UPDATE/DELETE عبر أدوار التطبيق.

## 8. مصفوفة العلاقات والمفاتيح الأجنبية

| المصدر | العمود | الهدف | التعددية | الحذف |
|---|---|---|---|---|
| organization_units | organization_id / parent_unit_id | organizations / self | N:1 | RESTRICT |
| memberships | user_id / organization_id / unit_id | profiles / organizations / units | N:1 | RESTRICT |
| role_permissions | role_id / permission_id | roles / permissions | N:M bridge | RESTRICT |
| role_assignments | membership_id / role_id / scope IDs | memberships / roles / scope entities | N:1 | RESTRICT |
| permission_grants | user_id / permission_id | profiles / permissions | N:1 | RESTRICT |
| registration_requests | applicant / role / station | profiles / roles / stations | N:1 | RESTRICT |
| registration_decisions | request_id / actor | requests / profiles | N:1 | RESTRICT |
| stations | organization_id / station_type_id | organizations / station_types | N:1 | RESTRICT |
| station child tables | station_id | stations | 1:N | RESTRICT |
| submissions | station / author / type | stations / profiles / observation_types | N:1 | RESTRICT |
| values | submission / parameter / unit | submissions / parameters / units | N:1 | RESTRICT |
| revisions | submission_id | submissions | 1:N | RESTRICT |
| review_decisions | submission / reviewer | submissions / profiles | N:1 | RESTRICT |
| quality_flags | submission XOR value | submissions / values | N:1 | RESTRICT |
| attachments | submission / file | submissions / files.objects | N:1 | RESTRICT |
| forecast_runs | provider / ingestion_run | providers / ingestion_runs | N:1 | RESTRICT |
| forecast_points | run / parameter / unit | forecast_runs / parameters / units | N:1 | RESTRICT |
| audit.events | actor / org / station | profiles / organizations / stations | optional N:1 | SET NULL only by approved audit policy |

## 9. الفهارس والقيود الإضافية

- فهرس لكل FK غير مغطى ببداية PK/UQ.
- memberships(user_id, organization_id, membership_state).
- role_assignments(membership_id, assignment_state, valid_from, valid_to).
- permission_grants(user_id, permission_id, grant_state, valid_from, valid_to).
- stations(organization_id, approval_status, operational_status).
- station_locations(station_id, valid_from, valid_to).
- submissions(station_id, observed_at DESC) و(author_user_id, created_at DESC).
- values(submission_id, parameter_id)، review_decisions(submission_id, decided_at DESC).
- forecast_runs(provider_id, issued_at DESC)، forecast_points(run_id, valid_at, parameter_id).
- audit.events(occurred_at DESC).
- idempotency unique per actor/provider and operation.
- CHECK ranges للإحداثيات، byte_size، counts، revision numbers، intervals.
- typed values: exactly one value column matches parameter.value_kind.
- station status: approval and operation remain separate.
- RLS on every exposed table; private schemas remain unexposed; views use security_invoker when applicable.
- sensitive workflows validate actor, scope, active membership, permission, expected state and separation of duties in one transaction.

## 10. ما يبقى TBD قبل DDL

- قائمة البارامترات والوحدات والدقة والمدى وطرق القياس وقواعد QC.
- النماذج العلمية ودورياتها وتوقيتاتها والحقول المطلوبة.
- قائمة الأدوار والصلاحيات ونطاقاتها المعتمدة.
- مصدر المحطات الجديدة، مرجع الإحداثيات والارتفاع والرموز الخارجية.
- مزود التنبؤ وشروط الاستخدام ومعدل الجلب والاحتفاظ بالحمولات.
- أنواع الملفات وأحجامها والفحص وسياسة الاحتفاظ.
- مدة الاحتفاظ بالرصد والقرارات وسجلات التدقيق.
- هل الإنذارات الرسمية والمناخ والتحليلات خارج MVP أم ضمن نطاق لاحق.

## 11. بوابة المراجعة

يرجى مراجعة:
1. علاقة الجهة ← الوحدة ← المحطة.
2. مرحلتي اعتماد طلب الانتساب (محطة ثم نظام) وهل هما ثابتتان.
3. هل حقول الرصد المعروضة في التطبيق نموذج مؤقت أم عقد علمي نهائي.
4. المرجع الرسمي لقاموس المعايير والوحدات والحدود.
5. إدراج weather ضمن أول baseline أم تأجيله.
6. سياسة الاحتفاظ والتدقيق والملفات.

لن يتم إنشاء migrations قبل اعتماد ERD والقاموس. وستكون baseline الاختبار مستقلة عن سلسلة migrations الحالية المستخدمة في التطبيق.
