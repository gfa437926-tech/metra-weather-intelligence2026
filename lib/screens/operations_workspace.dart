import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registration_flow.dart';
import 'station_review_page.dart';
import 'observation_forms_catalogue_page.dart';

const _ink = Color(0xFF102448), _navy = Color(0xFF071A43), _blue = Color(0xFF1769D2), _canvas = Color(0xFFF3F6FC);

enum WorkspaceModule { observationForms, forecastCenter, forecastOffice, bulletins, electronicAudit, paperAudit, aiModelManagement, aftn, climatol, homogenization, reports, userAccess, qualityControl, archive, stationReview, registrationApprovals, alerts, settings }

class WorkspaceModuleInfo {
  const WorkspaceModuleInfo(this.module, this.title, this.description, this.icon, this.group, this.status);
  final WorkspaceModule module;
  final String title, description, group, status;
  final IconData icon;
}

const workspaceModules = <WorkspaceModuleInfo>[
  WorkspaceModuleInfo(WorkspaceModule.observationForms, 'نماذج الرصد التفصيلية', 'النشرات الساعية واليومية والزراعية والمطرية والظواهر والأعطال', Icons.dynamic_form, 'التنبؤ والعمليات', 'حقول مفصلة — الإرسال مقيد'),
  WorkspaceModuleInfo(WorkspaceModule.forecastCenter, 'مراكز التنبؤ الجوي', 'مقارنة المحطات والمناطق حسب الإحداثيات والارتفاع ومتابعة الرصد اللحظي', Icons.query_stats, 'التنبؤ والعمليات', 'بانتظار ربط القياسات'),
  WorkspaceModuleInfo(WorkspaceModule.forecastOffice, 'مكتب المتنبئ', 'إعداد وتحليل النشرات والتوقعات الجوية ومراجعة صلاحيتها', Icons.cloud_sync_outlined, 'التنبؤ والعمليات', 'واجهة تشغيلية قيد الربط'),
  WorkspaceModuleInfo(WorkspaceModule.bulletins, 'النشرات الجوية', 'النشرات الساعية واليومية والملخصات والرسائل المشفرة', Icons.description_outlined, 'التنبؤ والعمليات', 'واجهة إدخال ومراجعة'),
  WorkspaceModuleInfo(WorkspaceModule.alerts, 'التنبيهات الجوية', 'متابعة التحذيرات الرسمية وحالات الطقس المؤثرة', Icons.warning_amber_rounded, 'التنبؤ والعمليات', 'مصدر رسمي غير مربوط'),
  WorkspaceModuleInfo(WorkspaceModule.electronicAudit, 'سجل التدقيق الإلكتروني', 'تتبع التغييرات والقرارات وسجل المراجعة والأخطاء', Icons.fact_check_outlined, 'الجودة والرقابة', 'بانتظار ربط سجل التدقيق'),
  WorkspaceModuleInfo(WorkspaceModule.paperAudit, 'تدقيق السجلات الورقية والآلية', 'مقارنة الدفاتر الورقية ومسجلات الأجهزة والرصد الإلكتروني', Icons.document_scanner, 'الجودة والرقابة', 'مراجعة بشرية إلزامية'),
  WorkspaceModuleInfo(WorkspaceModule.aiModelManagement, 'إدارة نماذج الذكاء الاصطناعي', 'مكتبة الأجهزة والتدريب وإصدارات النماذج ودرجات الثقة', Icons.model_training, 'الجودة والرقابة', 'بيئة التدريب غير مهيأة'),
  WorkspaceModuleInfo(WorkspaceModule.qualityControl, 'ضبط جودة البيانات', 'قواعد التحقق والتنبيهات والقيم الشاذة ومتابعة التصحيحات', Icons.rule_folder_outlined, 'الجودة والرقابة', 'قواعد الاعتماد مطلوبة'),
  WorkspaceModuleInfo(WorkspaceModule.aftn, 'مركز AFTN', 'إنشاء الرسائل الجوية ومراجعتها وتتبع حالة الإرسال والاستلام', Icons.send_outlined, 'الاتصالات والتوزيع', 'بوابة الإرسال غير مربوطة'),
  WorkspaceModuleInfo(WorkspaceModule.climatol, 'المناخ وCLIMATOL', 'تجميع السلاسل المناخية والتحقق منها وإعداد منتجات CLIMAT', Icons.stacked_line_chart, 'المناخ والإحصاء', 'بانتظار اعتماد القواعد العلمية'),
  WorkspaceModuleInfo(WorkspaceModule.homogenization, 'تجانس السلاسل المناخية', 'كشف الانقطاعات ومقارنة المحطات المرجعية وإدارة السلاسل المصححة', Icons.timeline, 'المناخ والإحصاء', 'البيانات الخام محفوظة دون تعديل'),
  WorkspaceModuleInfo(WorkspaceModule.reports, 'التقارير والإحصاء', 'التقارير اليومية والشهرية والسنوية ومؤشرات المحطات', Icons.assessment_outlined, 'المناخ والإحصاء', 'مصدر التقارير غير مربوط'),
  WorkspaceModuleInfo(WorkspaceModule.archive, 'الأرشيف المناخي', 'البحث في السجلات التاريخية ومراجعة اكتمال البيانات ومصدرها', Icons.inventory_2_outlined, 'المناخ والإحصاء', 'قراءة الأرشيف غير مفعلة'),
  WorkspaceModuleInfo(WorkspaceModule.userAccess, 'المستخدمون والصلاحيات', 'إدارة الهوية والأدوار والعضويات وتفويض الصلاحيات', Icons.admin_panel_settings_outlined, 'الإدارة والحوكمة', 'إدارة الصلاحيات مقيدة'),
  WorkspaceModuleInfo(WorkspaceModule.stationReview, 'اعتماد دليل المحطات', 'مراجعة بيانات المحطة ونوعها وإحداثياتها ومصدرها', Icons.location_searching, 'الإدارة والحوكمة', 'مراجعة حسب الصلاحية'),
  WorkspaceModuleInfo(WorkspaceModule.registrationApprovals, 'طلبات الانتساب', 'مراجعة الطلبات على مرحلتين وفصل مهام الاعتماد', Icons.how_to_reg_outlined, 'الإدارة والحوكمة', 'مراجعة حسب الصلاحية'),
  WorkspaceModuleInfo(WorkspaceModule.settings, 'إعدادات الحساب', 'حالة الحساب وتفضيلات التطبيق وتسجيل الخروج', Icons.settings_outlined, 'الإدارة والحوكمة', 'إعدادات التطبيق'),
];

bool isValidAftnAddress(String value) => RegExp(r'^[A-Z]{8}.hasMatch(value.trim().toUpperCase());
bool isValidAftnPriority(String value) => const {'SS', 'DD', 'FF', 'GG', 'KK'}.contains(value.trim().toUpperCase());

class OperationsHubPage extends StatelessWidget {
  const OperationsHubPage({super.key, this.client});
  final SupabaseClient? client;
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<WorkspaceModuleInfo>>{};
    for (final item in workspaceModules) { groups.putIfAbsent(item.group, () => []).add(item); }
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.hub_outlined, color: Colors.white, size: 27)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مركز العمل', style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w900)),
                Text('وحدات METRA التشغيلية والإدارية', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 18),
            const _InlineWarning(text: 'هذه الواجهات تعرض حالة التكامل بوضوح. لا تُعرض قياسات محطات أو نشرات أو تنبيهات على أنها مباشرة ما لم تصل من مصدر موثوق ومصرّح به.'),
            const SizedBox(height: 18),
          ]),
        )),
        for (final entry in groups.entries)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(entry.key, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.bold))),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: entry.value.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.18),
                itemBuilder: (context, index) { final item = entry.value[index]; return _ModuleCard(item: item, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkspaceModulePage(module: item.module, client: client)))); },
              ),
            ]),
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ])),
    ));
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.item, required this.onTap});
  final WorkspaceModuleInfo item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(12)), child: Icon(item.icon, color: _blue, size: 21)),
          const Spacer(), const Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey, size: 13),
        ]),
        const Spacer(),
        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(item.status, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
      ]),
    )),
  );
}

class WorkspaceModulePage extends StatelessWidget {
  const WorkspaceModulePage({super.key, required this.module, this.client});
  final WorkspaceModule module;
  final SupabaseClient? client;
  @override
  Widget build(BuildContext context) {
    switch (module) {
      case WorkspaceModule.observationForms: return const ObservationFormsCataloguePage();
      case WorkspaceModule.forecastCenter: return const ForecastCenterPage();
      case WorkspaceModule.forecastOffice: return const ForecastOfficePage();
      case WorkspaceModule.bulletins: return const BulletinWorkspacePage();
      case WorkspaceModule.electronicAudit: return const ElectronicAuditPage();
      case WorkspaceModule.paperAudit: return const PaperAndRecorderAuditPage();
      case WorkspaceModule.aiModelManagement: return const AiModelManagementPage();
      case WorkspaceModule.aftn: return const AftnWorkspacePage();
      case WorkspaceModule.climatol: return const ClimatolWorkspacePage();
      case WorkspaceModule.homogenization: return const ClimateHomogenizationPage();
      case WorkspaceModule.reports: return const ReportsWorkspacePage();
      case WorkspaceModule.userAccess: return const UserAccessWorkspacePage();
      case WorkspaceModule.qualityControl: return const _ModuleStatusPage(title: 'ضبط جودة البيانات', subtitle: 'قواعد التحقق ومتابعة الحالات غير الطبيعية', message: 'تظهر هنا نتائج قواعد التحقق المعتمدة، وسجل القيم المرفوضة، وطلبات التصحيح. لم يتم تحميل قواعد النطاقات العلمية أو ربط محرك الجودة بعد.', icon: Icons.rule_folder_outlined);
      case WorkspaceModule.archive: return const _ModuleStatusPage(title: 'الأرشيف المناخي', subtitle: 'استعراض السجلات التاريخية ومصدرها', message: 'واجهة الأرشيف جاهزة للتكامل. لا تُعرض السجلات التاريخية قبل تثبيت عقد القراءة وربط كل سجل بمحطته ومصدره دون تخمين.', icon: Icons.inventory_2_outlined);
      case WorkspaceModule.stationReview: return StationReviewPage(client: client);
      case WorkspaceModule.registrationApprovals: return client == null ? const _ModuleStatusPage(title: 'طلبات الانتساب', subtitle: 'مراجعة ثنائية المرحلة', message: 'تتطلب هذه الشاشة جلسة مصادقاً عليها وصلاحية المراجعة المناسبة.', icon: Icons.how_to_reg_outlined) : const RegistrationApprovalsPage();
      case WorkspaceModule.alerts: return const _ModuleStatusPage(title: 'التنبيهات الجوية', subtitle: 'التحذيرات الرسمية وحالات الطقس المؤثرة', message: 'لا يوجد مصدر رسمي موثّق متصل حالياً. لن يتم إنشاء تنبيه أو عرضه على أنه صادر عن جهة الأرصاد دون تغذية موثوقة.', icon: Icons.warning_amber_rounded);
      case WorkspaceModule.settings: return SettingsWorkspacePage(client: client);
    }
  }
}

class ForecastCenterPage extends StatefulWidget {
  const ForecastCenterPage({super.key});
  @override State<ForecastCenterPage> createState() => _ForecastCenterPageState();
}
class _ForecastCenterPageState extends State<ForecastCenterPage> {
  String region = 'كل المناطق', altitude = 'كل الارتفاعات', search = '';
  final regions = const ['كل المناطق', 'الساحل', 'الداخل', 'المرتفعات', 'الجزيرة', 'الجنوب'];
  final altitudes = const ['كل الارتفاعات', 'أقل من 500 م', '500–1000 م', '1000–1500 م', 'أكثر من 1500 م'];
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'مراكز التنبؤ الجوي', subtitle: 'مقارنة المحطات والمناطق ومتابعة القراءات اللحظية', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SourceStatus(title: 'تغذية المحطات اللحظية', detail: 'لم يتم ربط بوابة القياسات الآلية أو تدفق الرصد المباشر بعد.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'معايير المقارنة', child: Column(children: [
      TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(labelText: 'بحث باسم المحطة أو رمزها', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: region, decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()), items: regions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => region = v ?? regions.first)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: altitude, decoration: const InputDecoration(labelText: 'نطاق الارتفاع', border: OutlineInputBorder()), items: altitudes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => altitude = v ?? altitudes.first)),
      const SizedBox(height: 10),
      const Align(alignment: Alignment.centerRight, child: Text('تُحسب المنطقة والارتفاع من بيانات المحطة الموثقة فقط؛ لا تُستنتج من اسم الموقع.', style: TextStyle(color: Colors.blueGrey, fontSize: 11))),
    ])),
    const SizedBox(height: 14),
    const Text('مؤشرات المقارنة', style: TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 16)),
    const SizedBox(height: 10),
    const Wrap(spacing: 8, runSpacing: 8, children: [
      _MetricPill(icon: Icons.water_drop, label: 'الأمطار'), _MetricPill(icon: Icons.air, label: 'سرعة الرياح'), _MetricPill(icon: Icons.explore, label: 'اتجاه الرياح'), _MetricPill(icon: Icons.speed, label: 'هبات الرياح'), _MetricPill(icon: Icons.thermostat, label: 'الحرارة'), _MetricPill(icon: Icons.compress, label: 'الضغط'),
    ]),
    const SizedBox(height: 14),
    _Panel(title: 'جدول المحطات المقارن', child: Column(children: [
      Text('الفلاتر الحالية: $region • $altitude • بحث: $search', style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
      const SizedBox(height: 12),
      const _EmptyState(icon: Icons.sensors_off_outlined, title: 'لا توجد قراءات لحظية متاحة', message: 'ستظهر هنا المحطة والرمز والإحداثيات والارتفاع ووقت آخر قراءة، ثم المطر والرياح واتجاهها والهبات وبقية العناصر بعد ربط مصدر المحطات.'),
    ])),
    const SizedBox(height: 14),
    const _Panel(title: 'تفاصيل النشرة الواردة', child: _EmptyState(icon: Icons.article_outlined, title: 'بانتظار أول نشرة موثقة', message: 'عند وصول نشرة من محطة، ستظهر تفاصيلها الخام والمفككة ووقت الاستلام ومصدرها وسجل التحقق، مع إمكانية فتح سجل المحطة.')),
  ]));
}

class ForecastOfficePage extends StatefulWidget {
  const ForecastOfficePage({super.key});
  @override State<ForecastOfficePage> createState() => _ForecastOfficePageState();
}
class _ForecastOfficePageState extends State<ForecastOfficePage> {
  final formKey = GlobalKey<FormState>();
  String product = 'توقعات 24 ساعة', validity = '00–24 UTC';
  final area = TextEditingController(), synopsis = TextEditingController();
  @override void dispose() { area.dispose(); synopsis.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'مكتب المتنبئ', subtitle: 'إعداد منتجات التنبؤ ومراجعتها قبل الإصدار', child: Form(key: formKey, child: Column(children: [
    const _SourceStatus(title: 'مصادر التحليل', detail: 'لا توجد حالياً تغذية تشغيلية موثقة لخرائط التحليل أو النماذج العددية داخل هذه الشاشة.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'بيانات المنتج', child: Column(children: [
      DropdownButtonFormField<String>(value: product, decoration: const InputDecoration(labelText: 'نوع المنتج', border: OutlineInputBorder()), items: const ['توقعات 24 ساعة', 'توقعات 48 ساعة', 'توقعات 72 ساعة', 'توقعات بحرية', 'توقعات زراعية', 'توقعات خاصة'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => product = v ?? product)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: validity, decoration: const InputDecoration(labelText: 'فترة الصلاحية', border: OutlineInputBorder()), items: const ['00–24 UTC', '06–06 UTC', '12–12 UTC', '18–18 UTC'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => validity = v ?? validity)),
      const SizedBox(height: 12),
      TextFormField(controller: area, decoration: const InputDecoration(labelText: 'المنطقة / النطاق الجغرافي', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل النطاق الجغرافي' : null),
      const SizedBox(height: 12),
      TextFormField(controller: synopsis, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'ملخص الحالة الجوية والتحليل', alignLabelWithHint: true, border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().length < 10) ? 'أدخل ملخصاً أوضح' : null),
      const SizedBox(height: 14),
      const _InlineWarning(text: 'هذه معاينة تحرير محلية فقط. لا يتم اعتماد أو إصدار توقع رسمي قبل ربط مصادر التحليل وسير اعتماد المتنبئ.'),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { if (formKey.currentState!.validate()) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتمل التحقق المحلي. لم يتم حفظ المنتج أو إصداره.'))); } }, icon: const Icon(Icons.fact_check_outlined), label: const Text('التحقق من اكتمال المسودة'))),
    ])),
  ])));
}

class BulletinWorkspacePage extends StatefulWidget {
  const BulletinWorkspacePage({super.key});
  @override State<BulletinWorkspacePage> createState() => _BulletinWorkspacePageState();
}
class _BulletinWorkspacePageState extends State<BulletinWorkspacePage> {
  String type = 'نشرة ساعية', stationCode = '';
  final raw = TextEditingController();
  @override void dispose() { raw.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'النشرات الجوية', subtitle: 'إدخال ومراجعة النشرات الساعية واليومية والملخصات', child: Column(children: [
    const _SourceStatus(title: 'خدمة النشرات', detail: 'تجهيز الواجهة متاح؛ عقد الحفظ والتدقيق النهائي لم يعتمد بعد لجميع أنواع النشرات.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'اختيار نوع النشرة', child: Wrap(spacing: 8, runSpacing: 8, children: [
      for (final item in ['نشرة ساعية', 'نشرة يومية', 'SYNOP', 'METAR', 'TAF', 'ملخص جوي']) ChoiceChip(label: Text(item), selected: type == item, onSelected: (_) => setState(() => type = item)),
    ])),
    const SizedBox(height: 14),
    _Panel(title: 'بيانات النشرة', child: Column(children: [
      TextFormField(onChanged: (v) => stationCode = v, decoration: const InputDecoration(labelText: 'رمز المحطة المعتمد', hintText: 'يُقرأ من دليل المحطات', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: raw, minLines: 5, maxLines: 9, decoration: InputDecoration(labelText: 'محتوى النشرة / الرسالة', alignLabelWithHint: true, hintText: type == 'METAR' || type == 'SYNOP' ? 'أدخل النص المشفر للمراجعة' : 'أدخل محتوى النشرة', border: const OutlineInputBorder())),
      const SizedBox(height: 10),
      const _InlineWarning(text: 'لا تُرسل هذه المسودة إلى قاعدة البيانات. يلزم ربط مخطط الحقول والمدقق العلمي الخاص بكل نوع نشرة.'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () { if (stationCode.trim().isEmpty || raw.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رمز المحطة ومحتوى النشرة أولاً.'))); return; } ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فحص اكتمال الحقول محلياً فقط.'))); }, icon: const Icon(Icons.rule), label: const Text('فحص الحقول'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.save_outlined), label: const Text('حفظ / إرسال'))),
      ]),
    ])),
    const SizedBox(height: 14),
    const _Panel(title: 'سجل النشرات', child: _EmptyState(icon: Icons.inbox_outlined, title: 'لا توجد نشرات محملة', message: 'سيظهر سجل النشرات بعد توصيل واجهة القراءة مع حالة كل نشرة ووقت إنشائها ومراجعتها واعتمادها.')),
  ]));
}

class ElectronicAuditPage extends StatefulWidget {
  const ElectronicAuditPage({super.key});
  @override State<ElectronicAuditPage> createState() => _ElectronicAuditPageState();
}
class _ElectronicAuditPageState extends State<ElectronicAuditPage> {
  String status = 'الكل';
  final query = TextEditingController();
  @override void dispose() { query.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'التدقيق الإلكتروني', subtitle: 'سجل غير قابل للتعديل لعمليات الإدخال والمراجعة والاعتماد', child: Column(children: [
    const _SourceStatus(title: 'سجل التدقيق', detail: 'مصدر السجل غير مربوط في واجهة Flutter. لن تُنشأ أحداث تدقيق محلية بديلة عن سجل الخادم.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'البحث والتصفية', child: Column(children: [
      TextField(controller: query, decoration: const InputDecoration(labelText: 'بحث برقم العملية أو المستخدم أو المحطة', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
      const SizedBox(height: 10),
      Wrap(spacing: 7, children: [
        for (final item in ['الكل', 'إدخال', 'تعديل', 'إرسال', 'اعتماد', 'إرجاع']) ChoiceChip(label: Text(item), selected: status == item, onSelected: (_) => setState(() => status = item)),
      ]),
    ])),
    const SizedBox(height: 14),
    _Panel(title: 'سجل الأحداث', child: Column(children: [
      Text('عامل التصفية: $status', style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
      const SizedBox(height: 12),
      const _EmptyState(icon: Icons.verified_user_outlined, title: 'لا توجد أحداث محملة', message: 'عند ربط السجل ستظهر هوية المنفذ المستخرجة من الجلسة، نوع العملية، الكائن المتأثر، التوقيت UTC، والنتيجة ومعرّف الارتباط.'),
    ])),
    const SizedBox(height: 12),
    const _InlineWarning(text: 'يجب أن تبقى سجلات التدقيق للقراءة فقط، وأن تأتي من مصدر خادمي موثوق مع ضوابط منع التعديل والحذف.'),
  ]));
}

class AftnWorkspacePage extends StatefulWidget {
  const AftnWorkspacePage({super.key});
  @override State<AftnWorkspacePage> createState() => _AftnWorkspacePageState();
}
class _AftnWorkspacePageState extends State<AftnWorkspacePage> {
  final formKey = GlobalKey<FormState>();
  final origin = TextEditingController(), destination = TextEditingController(), body = TextEditingController();
  String priority = 'GG';
  @override
  void dispose() { origin.dispose(); destination.dispose(); body.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: _WorkspaceScaffold(
      title: 'مركز AFTN',
      subtitle: 'إنشاء الرسائل ومتابعة الوارد والصادر وإشعارات التسليم',
      child: Column(children: [
        const _SourceStatus(title: 'بوابة AFTN', detail: 'لا يوجد اتصال مع محطة الرسائل أو بوابة الإرسال. الإرسال معطل حتى اعتماد إعدادات الاتصال والمراقبة.', connected: false),
        const SizedBox(height: 12),
        const TabBar(isScrollable: true, labelColor: _blue, unselectedLabelColor: Colors.blueGrey, tabs: [
          Tab(text: 'إنشاء رسالة'), Tab(text: 'الصادر'), Tab(text: 'الوارد'), Tab(text: 'التسليم والتتبع'),
        ]),
        SizedBox(height: 650, child: TabBarView(children: [
          Form(key: formKey, child: ListView(padding: const EdgeInsets.only(top: 14), children: [
            _Panel(title: 'ترويسة الرسالة', child: Column(children: [
              TextFormField(controller: origin, textCapitalization: TextCapitalization.characters, maxLength: 8, decoration: const InputDecoration(labelText: 'عنوان المرسل (8 أحرف AFTN)', border: OutlineInputBorder()), validator: (v) => isValidAftnAddress(v ?? '') ? null : 'أدخل عنوان AFTN من ثمانية أحرف لاتينية'),
              const SizedBox(height: 8),
              TextFormField(controller: destination, textCapitalization: TextCapitalization.characters, maxLength: 8, decoration: const InputDecoration(labelText: 'عنوان المستلم (8 أحرف AFTN)', border: OutlineInputBorder()), validator: (v) => isValidAftnAddress(v ?? '') ? null : 'أدخل عنوان AFTN من ثمانية أحرف لاتينية'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(labelText: 'درجة الأولوية', border: OutlineInputBorder()), items: const ['SS', 'DD', 'FF', 'GG', 'KK'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => priority = v ?? 'GG')),
            ])),
            const SizedBox(height: 12),
            _Panel(title: 'محتوى الرسالة', child: Column(children: [
              TextFormField(controller: body, minLines: 8, maxLines: 12, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'نص الرسالة', alignLabelWithHint: true, border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().length < 10) ? 'أدخل نص الرسالة' : null),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: Text(body.text.length.toString() + ' حرف', style: const TextStyle(color: Colors.blueGrey, fontSize: 11))),
              const SizedBox(height: 10),
              const _InlineWarning(text: 'التحقق هنا شكلي ومحلي فقط؛ لا يثبت صحة التوجيه أو قبول الرسالة من شبكة AFTN.'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () { if (formKey.currentState!.validate()) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اجتازت الرسالة فحص الحقول المحلي فقط.'))); } }, child: const Text('التحقق من الرسالة'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.send), label: const Text('إرسال AFTN'))),
              ]),
            ])),
          ])),
          const _AftnQueueTab(title: 'قائمة الرسائل الصادرة', detail: 'تظهر الرسائل التي أنشأها المستخدم وحالة الفحص والاعتماد والتوجيه، مع إمكانية فتح الترويسة والنص وسجل المحاولات.'),
          const _AftnQueueTab(title: 'قائمة الرسائل الواردة', detail: 'تظهر الرسائل المستلمة من البوابة مع المرسل ووقت الاستلام UTC والأولوية وحالة فك الترميز والتصنيف.'),
          const _AftnQueueTab(title: 'إشعارات التسليم والتتبع', detail: 'تعرض ACK وNACK وإشعارات التأخير وإعادة المحاولة ومعرّف الرسالة وسجل التوجيه بين المحطات.'),
        ])),
      ]),
    ),
  );
}

class _AftnQueueTab extends StatelessWidget {
  const _AftnQueueTab({required this.title, required this.detail});
  final String title, detail;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    _Panel(title: title, child: _EmptyState(icon: Icons.mark_email_unread_outlined, title: 'لا توجد رسائل محملة', message: detail)),
    const SizedBox(height: 12),
    const _InlineWarning(text: 'هذه القائمة تنتظر عقد اتصال موثقاً مع بوابة AFTN. لا يتم إنشاء حالات إرسال أو تسليم تجريبية على أنها حقيقية.'),
  ]);
}

class ClimatolWorkspacePage extends StatefulWidget {
  const ClimatolWorkspacePage({super.key});
  @override State<ClimatolWorkspacePage> createState() => _ClimatolWorkspacePageState();
}
class _ClimatolWorkspacePageState extends State<ClimatolWorkspacePage> {
  String period = 'شهري', variable = 'درجة الحرارة';
  int year = 2026;
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'المناخ وCLIMATOL', subtitle: 'ضبط السلاسل المناخية والتحقق وإعداد المنتجات', child: Column(children: [
    const _SourceStatus(title: 'مصدر السلاسل المناخية', detail: 'لم يتم ربط مستودع البيانات المناخية أو محرك CLIMATOL بهذه الواجهة.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'إعداد مجموعة التحليل', child: Column(children: [
      DropdownButtonFormField<String>(value: period, decoration: const InputDecoration(labelText: 'الفترة', border: OutlineInputBorder()), items: const ['يومي', 'شهري', 'سنوي'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => period = v ?? period)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: variable, decoration: const InputDecoration(labelText: 'العنصر المناخي', border: OutlineInputBorder()), items: const ['درجة الحرارة', 'الأمطار', 'الرطوبة', 'سرعة الرياح', 'الضغط الجوي', 'الرؤية', 'الغيوم'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => variable = v ?? variable)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(value: year, decoration: const InputDecoration(labelText: 'السنة', border: OutlineInputBorder()), items: [for (var y = 2020; y <= 2026; y++) y].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(), onChanged: (v) => setState(() => year = v ?? year)),
      const SizedBox(height: 12),
      const _InlineWarning(text: 'لا تُحسب مؤشرات أو قيم مناخية قبل اعتماد قاموس العناصر والوحدات والفترات الزمنية وقواعد القيم المفقودة من المسؤول العلمي.'),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.play_arrow), label: const Text('تشغيل التحليل المناخي'))),
    ])),
    const SizedBox(height: 14),
    _Panel(title: 'معاينة مهمة التحليل', child: Column(children: [
      _KeyValue(label: 'الفترة', value: period), _KeyValue(label: 'العنصر', value: variable), _KeyValue(label: 'السنة', value: '$year'),
      const Divider(),
      const _EmptyState(icon: Icons.query_stats, title: 'لا توجد نتائج تحليل', message: 'بعد اعتماد التعاريف وربط البيانات ستظهر نسبة الاكتمال والفحوصات والسلاسل المقبولة والمرفوضة ومخرجات CLIMAT.'),
    ])),
  ]));
}

class ReportsWorkspacePage extends StatelessWidget {
  const ReportsWorkspacePage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 3, child: _WorkspaceScaffold(title: 'التقارير والإحصاء', subtitle: 'استعراض التقارير التشغيلية والمناخية', child: Column(children: [
    const TabBar(labelColor: _blue, unselectedLabelColor: Colors.blueGrey, tabs: [Tab(text: 'يومي'), Tab(text: 'شهري'), Tab(text: 'سنوي')]),
    SizedBox(height: 420, child: TabBarView(children: [
      _ReportTab(title: 'التقرير اليومي', message: 'يعرض ملخص الرصد اليومي ونسب الاكتمال وملاحظات التدقيق بعد ربط بيانات الرصد.'),
      _ReportTab(title: 'التقرير الشهري', message: 'يعرض ملخصات الشهر ومقارنات المحطات والمؤشرات المعتمدة بعد اعتماد طرق التجميع.'),
      _ReportTab(title: 'التقرير السنوي', message: 'يعرض الإحصاءات السنوية والسلاسل المناخية والاتجاهات بعد اعتماد التعاريف العلمية.'),
    ])),
  ])));
}
class _ReportTab extends StatelessWidget {
  const _ReportTab({required this.title, required this.message});
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14), child: _Panel(title: title, child: Column(children: [
    const _SourceStatus(title: 'مصدر التقرير', detail: 'لا يوجد عقد بيانات تقارير متصل حالياً.', connected: false),
    const SizedBox(height: 14),
    _EmptyState(icon: Icons.insert_chart_outlined, title: 'لا توجد بيانات تقرير', message: message),
    const SizedBox(height: 14),
    const Row(children: [Expanded(child: OutlinedButton(onPressed: null, child: Text('PDF'))), SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: null, child: Text('Excel')))]),
  ])));
}

class UserAccessWorkspacePage extends StatelessWidget {
  const UserAccessWorkspacePage({super.key});
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'المستخدمون والصلاحيات', subtitle: 'الهوية والأدوار والعضويات والتفويض', child: Column(children: [
    const _SourceStatus(title: 'خدمة إدارة الهوية', detail: 'تتوفر قراءة سياق الصلاحيات في الإعدادات، لكن لا توجد واجهة آمنة مكتملة لمنح الصلاحيات أو تعديل الأدوار.', connected: false),
    const SizedBox(height: 14),
    const _Panel(title: 'الأدوار الوظيفية', child: Column(children: [
      _RoleRow('مدير النظام', 'إدارة النظام وفق التفويض الأعلى'), _RoleRow('مدير الرصد', 'الإشراف على عمليات الرصد والمحطات'), _RoleRow('رئيس محطة', 'متابعة محطة محددة ومراجعة رصدها'), _RoleRow('راصد جوي', 'إدخال الرصد للمحطة المسندة'), _RoleRow('مدقق محطة', 'تدقيق السجلات ضمن نطاق المحطة'), _RoleRow('متنبئ جوي', 'إعداد منتجات التنبؤ'), _RoleRow('مسؤول AFTN', 'إعداد الرسائل الجوية وتوزيعها'), _RoleRow('مسؤول المناخ', 'المنتجات والإحصاءات المناخية'),
    ])),
    const SizedBox(height: 14),
    const _InlineWarning(text: 'لا تسمح هذه الواجهة بمنح أو تعديل الصلاحيات. أي عملية تفويض يجب أن تمر عبر معاملة خادمية تتحقق من صلاحية المفوّض ونطاقه وفصل المهام.'),
  ]));
}
class _RoleRow extends StatelessWidget {
  const _RoleRow(this.title, this.description);
  final String title, description;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: Color(0xFFEAF2FF), child: Icon(Icons.badge_outlined, color: _blue)), title: Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text(description, style: const TextStyle(color: Colors.blueGrey, fontSize: 11))));
}
class _ModuleStatusPage extends StatelessWidget {
  const _ModuleStatusPage({required this.title, required this.subtitle, required this.message, required this.icon});
  final String title, subtitle, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: title, subtitle: subtitle, child: Column(children: [
    _SourceStatus(title: title, detail: message, connected: false), const SizedBox(height: 14),
    _EmptyState(icon: icon, title: 'لا توجد عناصر متاحة للعرض', message: message),
  ]));
}

class _WorkspaceScaffold extends StatelessWidget {
  const _WorkspaceScaffold({required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    backgroundColor: _canvas,
    appBar: AppBar(backgroundColor: _canvas, foregroundColor: _ink, title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)), const SizedBox(height: 16), child,
      ]),
    )))),
  ));
}
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7ECF4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 13), child,
  ]));
}
class _SourceStatus extends StatelessWidget {
  const _SourceStatus({required this.title, required this.detail, required this.connected});
  final String title, detail;
  final bool connected;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: connected ? const Color(0xFFE8F7EF) : const Color(0xFFFFF4DF), borderRadius: BorderRadius.circular(16), border: Border.all(color: connected ? const Color(0xFFB7E2C8) : const Color(0xFFF1D9A8))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(connected ? Icons.check_circle_outline : Icons.link_off, color: connected ? Colors.green : const Color(0xFF9A6700)), const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
      Text(detail, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, height: 1.5)), const SizedBox(height: 5),
      Text(connected ? 'متصل' : 'غير متصل / غير معتمد', style: TextStyle(color: connected ? Colors.green : Colors.orange[900], fontSize: 10, fontWeight: FontWeight.bold)),
    ])),
  ]));
}
class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.info_outline, color: Color(0xFF9A6700), size: 18), const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF76520B), fontSize: 11, height: 1.45))),
  ]));
}
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25), decoration: BoxDecoration(color: const Color(0xFFF8FAFD), borderRadius: BorderRadius.circular(14)), child: Column(children: [
    Icon(icon, color: Colors.blueGrey, size: 34), const SizedBox(height: 9),
    Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 6),
    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, height: 1.5)),
  ]));
}
class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, color: _blue, size: 16), label: Text(label), backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFDDE7F5)));
}
class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
    Expanded(child: Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12))),
    Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 12)),
  ]));
}


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  bool busy = false, sent = false;
  String? error;
  @override
  void dispose() { email.dispose(); super.dispose(); }
  Future<void> sendReset() async {
    final value = email.text.trim();
    if (value.isEmpty || !value.contains('@')) {
      setState(() => error = 'أدخل بريداً إلكترونياً صحيحاً.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      await widget.client.auth.resetPasswordForEmail(value);
      if (mounted) setState(() => sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر إرسال رابط الاستعادة حالياً.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset, size: 54, color: _blue),
            const SizedBox(height: 14),
            const Text('استعادة الوصول إلى حسابك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ink)),
            const SizedBox(height: 10),
            Text(sent ? 'إذا كان البريد مسجلاً، فستصلك تعليمات الاستعادة وفق إعدادات مزود الهوية.' : 'أدخل بريد الحساب لإرسال رابط استعادة كلمة المرور.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 20),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: busy || sent ? null : sendReset, child: busy ? const CircularProgressIndicator() : const Text('إرسال رابط الاستعادة'))),
          ],
        )),
      )),
    ),
  );
}

class SettingsWorkspacePage extends StatefulWidget {
  const SettingsWorkspacePage({super.key, this.client});
  final SupabaseClient? client;
  @override
  State<SettingsWorkspacePage> createState() => _SettingsWorkspacePageState();
}
class _SettingsWorkspacePageState extends State<SettingsWorkspacePage> {
  bool signingOut = false;
  String units = 'مئوية';
  Future<void> signOut() async {
    if (widget.client == null) return;
    setState(() => signingOut = true);
    try {
      await widget.client!.auth.signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تسجيل الخروج. تحقق من الاتصال.')));
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(
    title: 'إعدادات الحساب', subtitle: 'تفضيلات العرض وحالة جلسة المستخدم',
    child: Column(children: [
      _Panel(title: 'تفضيلات العرض', child: Column(children: [
        DropdownButtonFormField<String>(value: units, decoration: const InputDecoration(labelText: 'وحدة الحرارة', border: OutlineInputBorder()), items: const ['مئوية', 'فهرنهايت'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => units = v ?? units)),
        const SizedBox(height: 10),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.language, color: _blue), title: Text('لغة الواجهة'), subtitle: Text('العربية — من اليمين إلى اليسار')),
      ])),
      const SizedBox(height: 14),
      _Panel(title: 'الجلسة والأمان', child: Column(children: [
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.verified_user_outlined, color: _blue), title: const Text('حالة المصادقة'), subtitle: Text(widget.client == null ? 'وضع عرض دون اتصال' : 'تدار الجلسة بواسطة مزود الهوية')),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: widget.client == null || signingOut ? null : signOut, icon: const Icon(Icons.logout), label: Text(signingOut ? 'جارٍ تسجيل الخروج' : 'تسجيل الخروج'))),
      ])),
    ]),
  );
}


class PaperAndRecorderAuditPage extends StatelessWidget {
  const PaperAndRecorderAuditPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: _WorkspaceScaffold(
      title: 'تدقيق السجلات الورقية والآلية',
      subtitle: 'مطابقة المصادر الثلاثة مع حفظ الأصل ومراجعة بشرية إلزامية',
      child: Column(children: [
        const _InlineWarning(text: 'لا يتم تعديل الصورة أو السجل الأصلي. أي قيمة مستخرجة أو مصححة تحفظ كنسخة مشتقة منفصلة، ولا تعتمد قبل موافقة المدقق والمراجع المخوّل.'),
        const SizedBox(height: 12),
        const TabBar(
          isScrollable: true,
          labelColor: _blue,
          unselectedLabelColor: Colors.blueGrey,
          tabs: [
            Tab(text: 'لوحة التدقيق'),
            Tab(text: 'السجلات الورقية'),
            Tab(text: 'المسجلات الآلية'),
            Tab(text: 'مقارنة المصادر'),
          ],
        ),
        SizedBox(height: 610, child: TabBarView(children: [
          _AuditDashboardTab(),
          _AuditSourceTab(
            title: 'السجلات الورقية',
            icon: Icons.menu_book_outlined,
            sourceType: 'دفتر الرصد الورقي',
            details: 'رفع صورة صفحة الدفتر مع المحطة والتاريخ والوردية ورقم الصفحة. تحفظ الصورة الأصلية وبصمتها الرقمية وبيانات الرفع.',
          ),
          _AuditSourceTab(
            title: 'المسجلات الميكانيكية',
            icon: Icons.settings_input_component,
            sourceType: 'نوع الجهاز',
            details: 'يدعم سجل الأجهزة Thermograph وHygrograph وBarograph وPluviograph، مع صورة المخطط والفترة الزمنية ومعايرة الجهاز.',
          ),
          _ThreeSourceComparisonTab(),
        ])),
      ]),
    ),
  );
}

class _AuditDashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: const [
    Wrap(spacing: 8, runSpacing: 8, children: [
      _MetricPill(icon: Icons.upload_file, label: 'الوارد'),
      _MetricPill(icon: Icons.compare_arrows, label: 'بانتظار المطابقة'),
      _MetricPill(icon: Icons.rate_review_outlined, label: 'بانتظار التدقيق'),
      _MetricPill(icon: Icons.verified_outlined, label: 'المعتمد'),
    ]),
    SizedBox(height: 14),
    _EmptyState(icon: Icons.fact_check_outlined, title: 'لا توجد ملفات تدقيق محملة', message: 'ستظهر هنا قوائم المهام حسب المحطة والتاريخ ونوع المصدر وحالة الاستخراج ودرجة الثقة واسم المدقق.'),
    SizedBox(height: 12),
    _Panel(title: 'الأدوار ومسار الاعتماد', child: Column(children: [
      _RoleRow('رافع السجلات', 'رفع الأصل وإدخال بياناته الوصفية دون اعتماد النتائج'),
      _RoleRow('المدقق', 'مراجعة الاستخراج ومقارنة المصادر واقتراح التصحيح'),
      _RoleRow('المعتمد', 'اعتماد النتيجة أو إعادتها مع السبب'),
      _RoleRow('مدير النماذج', 'إدارة نسخ النموذج ومجموعات التدريب'),
      _RoleRow('مدير النظام', 'إدارة الإعدادات والصلاحيات ضمن التفويض'),
    ])),
  ]);
}

class _AuditSourceTab extends StatefulWidget {
  const _AuditSourceTab({required this.title, required this.icon, required this.sourceType, required this.details});
  final String title, sourceType, details;
  final IconData icon;
  @override
  State<_AuditSourceTab> createState() => _AuditSourceTabState();
}
class _AuditSourceTabState extends State<_AuditSourceTab> {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    _Panel(title: 'بيانات المصدر', child: Column(children: [
      Text('نوع المصدر: ${widget.sourceType}', style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 6),
      Text(widget.details, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5)),
      const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(labelText: 'رمز المحطة من الدليل المعتمد', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(decoration: const InputDecoration(labelText: 'تاريخ السجل / بداية الفترة (UTC)', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات وبيانات وصفية', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      const _SourceStatus(title: 'خدمة رفع الملفات', detail: 'لم يتم ربط التخزين الآمن أو خدمة استخراج القيم بعد. لا يمكن رفع ملفات فعلية من هذه الشاشة حالياً.', connected: false),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: null, icon: Icon(widget.icon), label: const Text('اختيار الملف الأصلي'))),
      const SizedBox(height: 6),
      const Text('الأصل غير قابل للاستبدال • تحفظ النسخ المشتقة بإصدار مستقل', style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
    ])),
    const SizedBox(height: 12),
    const _EmptyState(icon: Icons.folder_open_outlined, title: 'لا توجد ملفات ضمن هذا النوع', message: 'بعد تفعيل الرفع ستظهر الملفات مع بصمة SHA-256 ووقت الرفع وصاحب العملية وحالة الفحص.'),
  ]);
}

class _ThreeSourceComparisonTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    const _Panel(title: 'مصادر المقارنة', child: Column(children: [
      _KeyValue(label: 'المصدر الأول', value: 'السجل الورقي'),
      _KeyValue(label: 'المصدر الثاني', value: 'المسجل الميكانيكي'),
      _KeyValue(label: 'المصدر الثالث', value: 'الرصد الإلكتروني'),
    ])),
    const SizedBox(height: 12),
    const _Panel(title: 'نتائج المطابقة حسب العنصر والوقت', child: _EmptyState(icon: Icons.compare_arrows, title: 'لا توجد مقارنة بعد', message: 'ستعرض المقارنة القيم المتقابلة والانحراف ودرجة الثقة ومصدر كل قيمة وحالة الاتفاق والاختلاف، دون استبدال أي قيمة أصلية.')),
    const SizedBox(height: 12),
    const _InlineWarning(text: 'مخرجات الذكاء الاصطناعي اقتراحات مساعدة فقط. قرار التصحيح أو الاعتماد يبقى بشرياً ويُسجل مع السبب وهوية المراجع.'),
  ]);
}

class AiModelManagementPage extends StatelessWidget {
  const AiModelManagementPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: _WorkspaceScaffold(
      title: 'إدارة نماذج الذكاء الاصطناعي',
      subtitle: 'مكتبة الأجهزة ومجموعات التدريب وإصدارات النماذج',
      child: Column(children: [
        const TabBar(
          isScrollable: true,
          labelColor: _blue,
          unselectedLabelColor: Colors.blueGrey,
          tabs: [Tab(text: 'مكتبة الأجهزة'), Tab(text: 'التدريب'), Tab(text: 'الإصدارات'), Tab(text: 'التقارير')],
        ),
        SizedBox(height: 560, child: TabBarView(children: [
          _ModelLibraryTab(),
          _ModelTrainingTab(),
          _ModelVersionsTab(),
          const _ModuleStatusPage(title: 'تقارير النموذج', subtitle: 'مؤشرات الدقة والأخطاء والانحراف', message: 'تظهر تقارير الأداء بعد توافر مجموعة تحقق معتمدة ومقاييس تقييم موثقة.', icon: Icons.analytics_outlined),
        ])),
      ]),
    ),
  );
}
class _ModelLibraryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    const _Panel(title: 'أنواع الأجهزة', child: Column(children: [
      _RoleRow('Thermograph', 'مسجل درجة الحرارة'),
      _RoleRow('Hygrograph', 'مسجل الرطوبة'),
      _RoleRow('Barograph', 'مسجل الضغط الجوي'),
      _RoleRow('Pluviograph', 'مسجل الأمطار'),
    ])),
    const SizedBox(height: 12),
    const _SourceStatus(title: 'أرشيف الصور المرجعية', detail: 'لم يتم ربط مستودع ملفات الأجهزة أو مكتبة الصور المرجعية.', connected: false),
    const SizedBox(height: 12),
    const _EmptyState(icon: Icons.photo_library_outlined, title: 'لا توجد صور مرجعية', message: 'ستحفظ الصور الأصلية وبيانات الجهاز والمعايرة والمحطة وتاريخ الالتقاط ومصدر الصورة.'),
  ]);
}
class _ModelTrainingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    const _Panel(title: 'إعداد مجموعة التدريب', child: Column(children: [
      _KeyValue(label: 'المدخلات', value: 'صور سجلات معتمدة وموسومة'),
      _KeyValue(label: 'مخرجات التدريب', value: 'اقتراح استخراج منظم مع الثقة'),
      _KeyValue(label: 'التحقق', value: 'مجموعة مستقلة غير مستخدمة بالتدريب'),
      _KeyValue(label: 'الاعتماد', value: 'مراجعة بشرية قبل النشر'),
    ])),
    const SizedBox(height: 12),
    const _InlineWarning(text: 'لا تستخدم بيانات محطة أو صوراً حقيقية للتدريب قبل اعتماد سياسة الخصوصية والموافقة ومصدر البيانات وفصل بيانات التدريب عن الاختبار.'),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.model_training), label: const Text('بدء التدريب'))),
  ]);
}
class _ModelVersionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: const [
    _EmptyState(icon: Icons.layers_outlined, title: 'لا توجد إصدارات منشورة', message: 'سيظهر لكل إصدار رقم النسخة وبصمة النموذج ومجموعة التدريب ومقاييس التحقق وتاريخ النشر وحالة التراجع.'),
  ]);
}

class ClimateHomogenizationPage extends StatefulWidget {
  const ClimateHomogenizationPage({super.key});
  @override
  State<ClimateHomogenizationPage> createState() => _ClimateHomogenizationPageState();
}
class _ClimateHomogenizationPageState extends State<ClimateHomogenizationPage> {
  String variable = 'درجة الحرارة';
  String period = 'سنوي';
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: _WorkspaceScaffold(
      title: 'تجانس السلاسل المناخية',
      subtitle: 'كشف الانقطاعات ومقارنة المحطات وإدارة السلاسل المصححة',
      child: Column(children: [
        const _InlineWarning(text: 'تبقى السلسلة الخام محفوظة كما وردت دون تعديل. تُنشأ سلسلة مصححة مستقلة مع سجل كامل لكل تغيير وسبب التصحيح وإصدار خوارزمية التجانس.'),
        const SizedBox(height: 12),
        _Panel(title: 'إعداد التحليل', child: Column(children: [
          DropdownButtonFormField<String>(value: variable, decoration: const InputDecoration(labelText: 'العنصر', border: OutlineInputBorder()), items: const ['درجة الحرارة', 'الأمطار', 'سرعة الرياح', 'الرطوبة', 'الضغط'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => variable = v ?? variable)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: period, decoration: const InputDecoration(labelText: 'الفترة التحليلية', border: OutlineInputBorder()), items: const ['شهري', 'فصلي', 'سنوي'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => period = v ?? period)),
        ])),
        const SizedBox(height: 12),
        const TabBar(isScrollable: true, labelColor: _blue, unselectedLabelColor: Colors.blueGrey, tabs: [
          Tab(text: 'السلاسل الزمنية'), Tab(text: 'نقاط الانقطاع'), Tab(text: 'المحطات المرجعية'), Tab(text: 'السلسلة المصححة'), Tab(text: 'المناخيات والتقارير'),
        ]),
        SizedBox(height: 560, child: TabBarView(children: [
          _ClimatePanelTab(title: 'تحليل السلسلة الزمنية', message: 'عرض القيم الخام والفجوات والقيم الشاذة حسب الزمن. لا يتم تعديل السلسلة الخام.', icon: Icons.show_chart),
          _ClimatePanelTab(title: 'نقاط الانقطاع', message: 'تحديد نقاط التغير المحتملة ومراجعة تاريخ الأجهزة أو نقل المحطة أو تغير البيئة المحيطة.', icon: Icons.timeline),
          _ClimatePanelTab(title: 'مقارنة المحطات المرجعية', message: 'اختيار محطات مرجعية متجانسة مكانياً ومناخياً، مع توثيق سبب اختيار كل محطة.', icon: Icons.compare_arrows),
          _ClimatePanelTab(title: 'إدارة السلاسل المصححة', message: 'عرض نسخة مصححة منفصلة ومقارنة قبل/بعد مع إصدار الخوارزمية وموافقة المسؤول.', icon: Icons.rule_folder_outlined),
          _ClimatePanelTab(title: 'المعدلات المناخية والتقارير', message: 'المعدلات الشهرية والفصلية والسنوية والأمطار والحرارة والرياح والمؤشرات والاتجاهات والمقارنة الجغرافية.', icon: Icons.assessment_outlined),
        ])),
      ]),
    ),
  );
}
class _ClimatePanelTab extends StatelessWidget {
  const _ClimatePanelTab({required this.title, required this.message, required this.icon});
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14), child: _Panel(title: title, child: Column(children: [
    const _SourceStatus(title: 'محرك CLIMATOL / R', detail: 'لم يتم ربط محرك التحليل أو مستودع السلاسل بعد.', connected: false),
    const SizedBox(height: 12),
    _EmptyState(icon: icon, title: 'لا توجد نتائج متاحة', message: message),
  ])));
}
).hasMatch(value.trim().toUpperCase());
bool isValidAftnPriority(String value) => const {'SS', 'DD', 'FF', 'GG', 'KK'}.contains(value.trim().toUpperCase());

class OperationsHubPage extends StatelessWidget {
  const OperationsHubPage({super.key, this.client});
  final SupabaseClient? client;
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<WorkspaceModuleInfo>>{};
    for (final item in workspaceModules) { groups.putIfAbsent(item.group, () => []).add(item); }
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.hub_outlined, color: Colors.white, size: 27)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مركز العمل', style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w900)),
                Text('وحدات METRA التشغيلية والإدارية', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 18),
            const _InlineWarning(text: 'هذه الواجهات تعرض حالة التكامل بوضوح. لا تُعرض قياسات محطات أو نشرات أو تنبيهات على أنها مباشرة ما لم تصل من مصدر موثوق ومصرّح به.'),
            const SizedBox(height: 18),
          ]),
        )),
        for (final entry in groups.entries)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(entry.key, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.bold))),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: entry.value.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.18),
                itemBuilder: (context, index) { final item = entry.value[index]; return _ModuleCard(item: item, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkspaceModulePage(module: item.module, client: client)))); },
              ),
            ]),
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ])),
    ));
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.item, required this.onTap});
  final WorkspaceModuleInfo item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(12)), child: Icon(item.icon, color: _blue, size: 21)),
          const Spacer(), const Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey, size: 13),
        ]),
        const Spacer(),
        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(item.status, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
      ]),
    )),
  );
}

class WorkspaceModulePage extends StatelessWidget {
  const WorkspaceModulePage({super.key, required this.module, this.client});
  final WorkspaceModule module;
  final SupabaseClient? client;
  @override
  Widget build(BuildContext context) {
    switch (module) {
      case WorkspaceModule.observationForms: return const ObservationFormsCataloguePage();
      case WorkspaceModule.forecastCenter: return const ForecastCenterPage();
      case WorkspaceModule.forecastOffice: return const ForecastOfficePage();
      case WorkspaceModule.bulletins: return const BulletinWorkspacePage();
      case WorkspaceModule.electronicAudit: return const ElectronicAuditPage();
      case WorkspaceModule.paperAudit: return const PaperAndRecorderAuditPage();
      case WorkspaceModule.aiModelManagement: return const AiModelManagementPage();
      case WorkspaceModule.aftn: return const AftnWorkspacePage();
      case WorkspaceModule.climatol: return const ClimatolWorkspacePage();
      case WorkspaceModule.homogenization: return const ClimateHomogenizationPage();
      case WorkspaceModule.reports: return const ReportsWorkspacePage();
      case WorkspaceModule.userAccess: return const UserAccessWorkspacePage();
      case WorkspaceModule.qualityControl: return const _ModuleStatusPage(title: 'ضبط جودة البيانات', subtitle: 'قواعد التحقق ومتابعة الحالات غير الطبيعية', message: 'تظهر هنا نتائج قواعد التحقق المعتمدة، وسجل القيم المرفوضة، وطلبات التصحيح. لم يتم تحميل قواعد النطاقات العلمية أو ربط محرك الجودة بعد.', icon: Icons.rule_folder_outlined);
      case WorkspaceModule.archive: return const _ModuleStatusPage(title: 'الأرشيف المناخي', subtitle: 'استعراض السجلات التاريخية ومصدرها', message: 'واجهة الأرشيف جاهزة للتكامل. لا تُعرض السجلات التاريخية قبل تثبيت عقد القراءة وربط كل سجل بمحطته ومصدره دون تخمين.', icon: Icons.inventory_2_outlined);
      case WorkspaceModule.stationReview: return StationReviewPage(client: client);
      case WorkspaceModule.registrationApprovals: return client == null ? const _ModuleStatusPage(title: 'طلبات الانتساب', subtitle: 'مراجعة ثنائية المرحلة', message: 'تتطلب هذه الشاشة جلسة مصادقاً عليها وصلاحية المراجعة المناسبة.', icon: Icons.how_to_reg_outlined) : const RegistrationApprovalsPage();
      case WorkspaceModule.alerts: return const _ModuleStatusPage(title: 'التنبيهات الجوية', subtitle: 'التحذيرات الرسمية وحالات الطقس المؤثرة', message: 'لا يوجد مصدر رسمي موثّق متصل حالياً. لن يتم إنشاء تنبيه أو عرضه على أنه صادر عن جهة الأرصاد دون تغذية موثوقة.', icon: Icons.warning_amber_rounded);
      case WorkspaceModule.settings: return SettingsWorkspacePage(client: client);
    }
  }
}

class ForecastCenterPage extends StatefulWidget {
  const ForecastCenterPage({super.key});
  @override State<ForecastCenterPage> createState() => _ForecastCenterPageState();
}
class _ForecastCenterPageState extends State<ForecastCenterPage> {
  String region = 'كل المناطق', altitude = 'كل الارتفاعات', search = '';
  final regions = const ['كل المناطق', 'الساحل', 'الداخل', 'المرتفعات', 'الجزيرة', 'الجنوب'];
  final altitudes = const ['كل الارتفاعات', 'أقل من 500 م', '500–1000 م', '1000–1500 م', 'أكثر من 1500 م'];
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'مراكز التنبؤ الجوي', subtitle: 'مقارنة المحطات والمناطق ومتابعة القراءات اللحظية', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SourceStatus(title: 'تغذية المحطات اللحظية', detail: 'لم يتم ربط بوابة القياسات الآلية أو تدفق الرصد المباشر بعد.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'معايير المقارنة', child: Column(children: [
      TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(labelText: 'بحث باسم المحطة أو رمزها', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: region, decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()), items: regions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => region = v ?? regions.first)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: altitude, decoration: const InputDecoration(labelText: 'نطاق الارتفاع', border: OutlineInputBorder()), items: altitudes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => altitude = v ?? altitudes.first)),
      const SizedBox(height: 10),
      const Align(alignment: Alignment.centerRight, child: Text('تُحسب المنطقة والارتفاع من بيانات المحطة الموثقة فقط؛ لا تُستنتج من اسم الموقع.', style: TextStyle(color: Colors.blueGrey, fontSize: 11))),
    ])),
    const SizedBox(height: 14),
    const Text('مؤشرات المقارنة', style: TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 16)),
    const SizedBox(height: 10),
    const Wrap(spacing: 8, runSpacing: 8, children: [
      _MetricPill(icon: Icons.water_drop, label: 'الأمطار'), _MetricPill(icon: Icons.air, label: 'سرعة الرياح'), _MetricPill(icon: Icons.explore, label: 'اتجاه الرياح'), _MetricPill(icon: Icons.speed, label: 'هبات الرياح'), _MetricPill(icon: Icons.thermostat, label: 'الحرارة'), _MetricPill(icon: Icons.compress, label: 'الضغط'),
    ]),
    const SizedBox(height: 14),
    _Panel(title: 'جدول المحطات المقارن', child: Column(children: [
      Text('الفلاتر الحالية: $region • $altitude • بحث: $search', style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
      const SizedBox(height: 12),
      const _EmptyState(icon: Icons.sensors_off_outlined, title: 'لا توجد قراءات لحظية متاحة', message: 'ستظهر هنا المحطة والرمز والإحداثيات والارتفاع ووقت آخر قراءة، ثم المطر والرياح واتجاهها والهبات وبقية العناصر بعد ربط مصدر المحطات.'),
    ])),
    const SizedBox(height: 14),
    const _Panel(title: 'تفاصيل النشرة الواردة', child: _EmptyState(icon: Icons.article_outlined, title: 'بانتظار أول نشرة موثقة', message: 'عند وصول نشرة من محطة، ستظهر تفاصيلها الخام والمفككة ووقت الاستلام ومصدرها وسجل التحقق، مع إمكانية فتح سجل المحطة.')),
  ]));
}

class ForecastOfficePage extends StatefulWidget {
  const ForecastOfficePage({super.key});
  @override State<ForecastOfficePage> createState() => _ForecastOfficePageState();
}
class _ForecastOfficePageState extends State<ForecastOfficePage> {
  final formKey = GlobalKey<FormState>();
  String product = 'توقعات 24 ساعة', validity = '00–24 UTC';
  final area = TextEditingController(), synopsis = TextEditingController();
  @override void dispose() { area.dispose(); synopsis.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'مكتب المتنبئ', subtitle: 'إعداد منتجات التنبؤ ومراجعتها قبل الإصدار', child: Form(key: formKey, child: Column(children: [
    const _SourceStatus(title: 'مصادر التحليل', detail: 'لا توجد حالياً تغذية تشغيلية موثقة لخرائط التحليل أو النماذج العددية داخل هذه الشاشة.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'بيانات المنتج', child: Column(children: [
      DropdownButtonFormField<String>(value: product, decoration: const InputDecoration(labelText: 'نوع المنتج', border: OutlineInputBorder()), items: const ['توقعات 24 ساعة', 'توقعات 48 ساعة', 'توقعات 72 ساعة', 'توقعات بحرية', 'توقعات زراعية', 'توقعات خاصة'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => product = v ?? product)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: validity, decoration: const InputDecoration(labelText: 'فترة الصلاحية', border: OutlineInputBorder()), items: const ['00–24 UTC', '06–06 UTC', '12–12 UTC', '18–18 UTC'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => validity = v ?? validity)),
      const SizedBox(height: 12),
      TextFormField(controller: area, decoration: const InputDecoration(labelText: 'المنطقة / النطاق الجغرافي', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل النطاق الجغرافي' : null),
      const SizedBox(height: 12),
      TextFormField(controller: synopsis, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'ملخص الحالة الجوية والتحليل', alignLabelWithHint: true, border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().length < 10) ? 'أدخل ملخصاً أوضح' : null),
      const SizedBox(height: 14),
      const _InlineWarning(text: 'هذه معاينة تحرير محلية فقط. لا يتم اعتماد أو إصدار توقع رسمي قبل ربط مصادر التحليل وسير اعتماد المتنبئ.'),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { if (formKey.currentState!.validate()) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتمل التحقق المحلي. لم يتم حفظ المنتج أو إصداره.'))); } }, icon: const Icon(Icons.fact_check_outlined), label: const Text('التحقق من اكتمال المسودة'))),
    ])),
  ])));
}

class BulletinWorkspacePage extends StatefulWidget {
  const BulletinWorkspacePage({super.key});
  @override State<BulletinWorkspacePage> createState() => _BulletinWorkspacePageState();
}
class _BulletinWorkspacePageState extends State<BulletinWorkspacePage> {
  String type = 'نشرة ساعية', stationCode = '';
  final raw = TextEditingController();
  @override void dispose() { raw.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'النشرات الجوية', subtitle: 'إدخال ومراجعة النشرات الساعية واليومية والملخصات', child: Column(children: [
    const _SourceStatus(title: 'خدمة النشرات', detail: 'تجهيز الواجهة متاح؛ عقد الحفظ والتدقيق النهائي لم يعتمد بعد لجميع أنواع النشرات.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'اختيار نوع النشرة', child: Wrap(spacing: 8, runSpacing: 8, children: [
      for (final item in ['نشرة ساعية', 'نشرة يومية', 'SYNOP', 'METAR', 'TAF', 'ملخص جوي']) ChoiceChip(label: Text(item), selected: type == item, onSelected: (_) => setState(() => type = item)),
    ])),
    const SizedBox(height: 14),
    _Panel(title: 'بيانات النشرة', child: Column(children: [
      TextFormField(onChanged: (v) => stationCode = v, decoration: const InputDecoration(labelText: 'رمز المحطة المعتمد', hintText: 'يُقرأ من دليل المحطات', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: raw, minLines: 5, maxLines: 9, decoration: InputDecoration(labelText: 'محتوى النشرة / الرسالة', alignLabelWithHint: true, hintText: type == 'METAR' || type == 'SYNOP' ? 'أدخل النص المشفر للمراجعة' : 'أدخل محتوى النشرة', border: const OutlineInputBorder())),
      const SizedBox(height: 10),
      const _InlineWarning(text: 'لا تُرسل هذه المسودة إلى قاعدة البيانات. يلزم ربط مخطط الحقول والمدقق العلمي الخاص بكل نوع نشرة.'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () { if (stationCode.trim().isEmpty || raw.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رمز المحطة ومحتوى النشرة أولاً.'))); return; } ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فحص اكتمال الحقول محلياً فقط.'))); }, icon: const Icon(Icons.rule), label: const Text('فحص الحقول'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.save_outlined), label: const Text('حفظ / إرسال'))),
      ]),
    ])),
    const SizedBox(height: 14),
    const _Panel(title: 'سجل النشرات', child: _EmptyState(icon: Icons.inbox_outlined, title: 'لا توجد نشرات محملة', message: 'سيظهر سجل النشرات بعد توصيل واجهة القراءة مع حالة كل نشرة ووقت إنشائها ومراجعتها واعتمادها.')),
  ]));
}

class ElectronicAuditPage extends StatefulWidget {
  const ElectronicAuditPage({super.key});
  @override State<ElectronicAuditPage> createState() => _ElectronicAuditPageState();
}
class _ElectronicAuditPageState extends State<ElectronicAuditPage> {
  String status = 'الكل';
  final query = TextEditingController();
  @override void dispose() { query.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'التدقيق الإلكتروني', subtitle: 'سجل غير قابل للتعديل لعمليات الإدخال والمراجعة والاعتماد', child: Column(children: [
    const _SourceStatus(title: 'سجل التدقيق', detail: 'مصدر السجل غير مربوط في واجهة Flutter. لن تُنشأ أحداث تدقيق محلية بديلة عن سجل الخادم.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'البحث والتصفية', child: Column(children: [
      TextField(controller: query, decoration: const InputDecoration(labelText: 'بحث برقم العملية أو المستخدم أو المحطة', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
      const SizedBox(height: 10),
      Wrap(spacing: 7, children: [
        for (final item in ['الكل', 'إدخال', 'تعديل', 'إرسال', 'اعتماد', 'إرجاع']) ChoiceChip(label: Text(item), selected: status == item, onSelected: (_) => setState(() => status = item)),
      ]),
    ])),
    const SizedBox(height: 14),
    _Panel(title: 'سجل الأحداث', child: Column(children: [
      Text('عامل التصفية: $status', style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
      const SizedBox(height: 12),
      const _EmptyState(icon: Icons.verified_user_outlined, title: 'لا توجد أحداث محملة', message: 'عند ربط السجل ستظهر هوية المنفذ المستخرجة من الجلسة، نوع العملية، الكائن المتأثر، التوقيت UTC، والنتيجة ومعرّف الارتباط.'),
    ])),
    const SizedBox(height: 12),
    const _InlineWarning(text: 'يجب أن تبقى سجلات التدقيق للقراءة فقط، وأن تأتي من مصدر خادمي موثوق مع ضوابط منع التعديل والحذف.'),
  ]));
}

class AftnWorkspacePage extends StatefulWidget {
  const AftnWorkspacePage({super.key});
  @override State<AftnWorkspacePage> createState() => _AftnWorkspacePageState();
}
class _AftnWorkspacePageState extends State<AftnWorkspacePage> {
  final formKey = GlobalKey<FormState>();
  final origin = TextEditingController(), destination = TextEditingController(), body = TextEditingController();
  String priority = 'GG';
  @override void dispose() { origin.dispose(); destination.dispose(); body.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'مركز AFTN', subtitle: 'إنشاء الرسائل الجوية ومراجعتها قبل التوزيع', child: Form(key: formKey, child: Column(children: [
    const _SourceStatus(title: 'بوابة AFTN', detail: 'لا يوجد اتصال مع محطة الرسائل أو بوابة الإرسال. الإرسال معطل حتى اعتماد إعدادات الاتصال والمراقبة.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'إنشاء رسالة', child: Column(children: [
      TextFormField(controller: origin, textCapitalization: TextCapitalization.characters, maxLength: 4, decoration: const InputDecoration(labelText: 'عنوان المرسل (4 أحرف)', border: OutlineInputBorder()), validator: (v) => isValidAftnAddress(v ?? '') ? null : 'أدخل عنواناً من أربعة أحرف لاتينية كبيرة'),
      const SizedBox(height: 8),
      TextFormField(controller: destination, textCapitalization: TextCapitalization.characters, maxLength: 4, decoration: const InputDecoration(labelText: 'عنوان المستلم (4 أحرف)', border: OutlineInputBorder()), validator: (v) => isValidAftnAddress(v ?? '') ? null : 'أدخل عنواناً من أربعة أحرف لاتينية كبيرة'),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(labelText: 'درجة الأولوية', border: OutlineInputBorder()), items: const ['SS', 'DD', 'FF', 'GG', 'KK'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => priority = v ?? 'GG')),
      const SizedBox(height: 12),
      TextFormField(controller: body, minLines: 6, maxLines: 10, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'نص الرسالة', alignLabelWithHint: true, border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().length < 10) ? 'أدخل نص الرسالة' : null),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerLeft, child: Text(body.text.length.toString() + ' حرف', style: const TextStyle(color: Colors.blueGrey, fontSize: 11))),
      const SizedBox(height: 10),
      const _InlineWarning(text: 'التحقق هنا شكلي ومحلي فقط؛ لا يثبت صحة التوجيه أو صلاحية العنوان أو قبول الرسالة من شبكة AFTN.'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () { if (formKey.currentState!.validate()) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اجتازت الرسالة فحص الحقول المحلي فقط.'))); } }, child: const Text('التحقق من الرسالة'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.send), label: const Text('إرسال AFTN'))),
      ]),
    ])),
    const SizedBox(height: 14),
    const _Panel(title: 'حالة الرسائل', child: _EmptyState(icon: Icons.outbox_outlined, title: 'لا توجد رسائل في قائمة الإرسال', message: 'ستعرض القائمة الرسائل المعلقة والمرسلة والمرفوضة وإشعارات التسليم بعد ربط البوابة.')),
  ])),
  );
}

class ClimatolWorkspacePage extends StatefulWidget {
  const ClimatolWorkspacePage({super.key});
  @override State<ClimatolWorkspacePage> createState() => _ClimatolWorkspacePageState();
}
class _ClimatolWorkspacePageState extends State<ClimatolWorkspacePage> {
  String period = 'شهري', variable = 'درجة الحرارة';
  int year = 2026;
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'المناخ وCLIMATOL', subtitle: 'ضبط السلاسل المناخية والتحقق وإعداد المنتجات', child: Column(children: [
    const _SourceStatus(title: 'مصدر السلاسل المناخية', detail: 'لم يتم ربط مستودع البيانات المناخية أو محرك CLIMATOL بهذه الواجهة.', connected: false),
    const SizedBox(height: 14),
    _Panel(title: 'إعداد مجموعة التحليل', child: Column(children: [
      DropdownButtonFormField<String>(value: period, decoration: const InputDecoration(labelText: 'الفترة', border: OutlineInputBorder()), items: const ['يومي', 'شهري', 'سنوي'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => period = v ?? period)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: variable, decoration: const InputDecoration(labelText: 'العنصر المناخي', border: OutlineInputBorder()), items: const ['درجة الحرارة', 'الأمطار', 'الرطوبة', 'سرعة الرياح', 'الضغط الجوي', 'الرؤية', 'الغيوم'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => variable = v ?? variable)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(value: year, decoration: const InputDecoration(labelText: 'السنة', border: OutlineInputBorder()), items: [for (var y = 2020; y <= 2026; y++) y].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(), onChanged: (v) => setState(() => year = v ?? year)),
      const SizedBox(height: 12),
      const _InlineWarning(text: 'لا تُحسب مؤشرات أو قيم مناخية قبل اعتماد قاموس العناصر والوحدات والفترات الزمنية وقواعد القيم المفقودة من المسؤول العلمي.'),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.play_arrow), label: const Text('تشغيل التحليل المناخي'))),
    ])),
    const SizedBox(height: 14),
    _Panel(title: 'معاينة مهمة التحليل', child: Column(children: [
      _KeyValue(label: 'الفترة', value: period), _KeyValue(label: 'العنصر', value: variable), _KeyValue(label: 'السنة', value: '$year'),
      const Divider(),
      const _EmptyState(icon: Icons.query_stats, title: 'لا توجد نتائج تحليل', message: 'بعد اعتماد التعاريف وربط البيانات ستظهر نسبة الاكتمال والفحوصات والسلاسل المقبولة والمرفوضة ومخرجات CLIMAT.'),
    ])),
  ]));
}

class ReportsWorkspacePage extends StatelessWidget {
  const ReportsWorkspacePage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 3, child: _WorkspaceScaffold(title: 'التقارير والإحصاء', subtitle: 'استعراض التقارير التشغيلية والمناخية', child: Column(children: [
    const TabBar(labelColor: _blue, unselectedLabelColor: Colors.blueGrey, tabs: [Tab(text: 'يومي'), Tab(text: 'شهري'), Tab(text: 'سنوي')]),
    SizedBox(height: 420, child: TabBarView(children: [
      _ReportTab(title: 'التقرير اليومي', message: 'يعرض ملخص الرصد اليومي ونسب الاكتمال وملاحظات التدقيق بعد ربط بيانات الرصد.'),
      _ReportTab(title: 'التقرير الشهري', message: 'يعرض ملخصات الشهر ومقارنات المحطات والمؤشرات المعتمدة بعد اعتماد طرق التجميع.'),
      _ReportTab(title: 'التقرير السنوي', message: 'يعرض الإحصاءات السنوية والسلاسل المناخية والاتجاهات بعد اعتماد التعاريف العلمية.'),
    ])),
  ])));
}
class _ReportTab extends StatelessWidget {
  const _ReportTab({required this.title, required this.message});
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14), child: _Panel(title: title, child: Column(children: [
    const _SourceStatus(title: 'مصدر التقرير', detail: 'لا يوجد عقد بيانات تقارير متصل حالياً.', connected: false),
    const SizedBox(height: 14),
    _EmptyState(icon: Icons.insert_chart_outlined, title: 'لا توجد بيانات تقرير', message: message),
    const SizedBox(height: 14),
    const Row(children: [Expanded(child: OutlinedButton(onPressed: null, child: Text('PDF'))), SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: null, child: Text('Excel')))]),
  ])));
}

class UserAccessWorkspacePage extends StatelessWidget {
  const UserAccessWorkspacePage({super.key});
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: 'المستخدمون والصلاحيات', subtitle: 'الهوية والأدوار والعضويات والتفويض', child: Column(children: [
    const _SourceStatus(title: 'خدمة إدارة الهوية', detail: 'تتوفر قراءة سياق الصلاحيات في الإعدادات، لكن لا توجد واجهة آمنة مكتملة لمنح الصلاحيات أو تعديل الأدوار.', connected: false),
    const SizedBox(height: 14),
    const _Panel(title: 'الأدوار الوظيفية', child: Column(children: [
      _RoleRow('مدير النظام', 'إدارة النظام وفق التفويض الأعلى'), _RoleRow('مدير الرصد', 'الإشراف على عمليات الرصد والمحطات'), _RoleRow('رئيس محطة', 'متابعة محطة محددة ومراجعة رصدها'), _RoleRow('راصد جوي', 'إدخال الرصد للمحطة المسندة'), _RoleRow('مدقق محطة', 'تدقيق السجلات ضمن نطاق المحطة'), _RoleRow('متنبئ جوي', 'إعداد منتجات التنبؤ'), _RoleRow('مسؤول AFTN', 'إعداد الرسائل الجوية وتوزيعها'), _RoleRow('مسؤول المناخ', 'المنتجات والإحصاءات المناخية'),
    ])),
    const SizedBox(height: 14),
    const _InlineWarning(text: 'لا تسمح هذه الواجهة بمنح أو تعديل الصلاحيات. أي عملية تفويض يجب أن تمر عبر معاملة خادمية تتحقق من صلاحية المفوّض ونطاقه وفصل المهام.'),
  ]));
}
class _RoleRow extends StatelessWidget {
  const _RoleRow(this.title, this.description);
  final String title, description;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: Color(0xFFEAF2FF), child: Icon(Icons.badge_outlined, color: _blue)), title: Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text(description, style: const TextStyle(color: Colors.blueGrey, fontSize: 11))));
}
class _ModuleStatusPage extends StatelessWidget {
  const _ModuleStatusPage({required this.title, required this.subtitle, required this.message, required this.icon});
  final String title, subtitle, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(title: title, subtitle: subtitle, child: Column(children: [
    _SourceStatus(title: title, detail: message, connected: false), const SizedBox(height: 14),
    _EmptyState(icon: icon, title: 'لا توجد عناصر متاحة للعرض', message: message),
  ]));
}

class _WorkspaceScaffold extends StatelessWidget {
  const _WorkspaceScaffold({required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    backgroundColor: _canvas,
    appBar: AppBar(backgroundColor: _canvas, foregroundColor: _ink, title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)), const SizedBox(height: 16), child,
      ]),
    )))),
  ));
}
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7ECF4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 13), child,
  ]));
}
class _SourceStatus extends StatelessWidget {
  const _SourceStatus({required this.title, required this.detail, required this.connected});
  final String title, detail;
  final bool connected;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: connected ? const Color(0xFFE8F7EF) : const Color(0xFFFFF4DF), borderRadius: BorderRadius.circular(16), border: Border.all(color: connected ? const Color(0xFFB7E2C8) : const Color(0xFFF1D9A8))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(connected ? Icons.check_circle_outline : Icons.link_off, color: connected ? Colors.green : const Color(0xFF9A6700)), const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
      Text(detail, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, height: 1.5)), const SizedBox(height: 5),
      Text(connected ? 'متصل' : 'غير متصل / غير معتمد', style: TextStyle(color: connected ? Colors.green : Colors.orange[900], fontSize: 10, fontWeight: FontWeight.bold)),
    ])),
  ]));
}
class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.info_outline, color: Color(0xFF9A6700), size: 18), const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF76520B), fontSize: 11, height: 1.45))),
  ]));
}
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25), decoration: BoxDecoration(color: const Color(0xFFF8FAFD), borderRadius: BorderRadius.circular(14)), child: Column(children: [
    Icon(icon, color: Colors.blueGrey, size: 34), const SizedBox(height: 9),
    Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 6),
    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, height: 1.5)),
  ]));
}
class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, color: _blue, size: 16), label: Text(label), backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFDDE7F5)));
}
class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
    Expanded(child: Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12))),
    Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 12)),
  ]));
}


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  bool busy = false, sent = false;
  String? error;
  @override
  void dispose() { email.dispose(); super.dispose(); }
  Future<void> sendReset() async {
    final value = email.text.trim();
    if (value.isEmpty || !value.contains('@')) {
      setState(() => error = 'أدخل بريداً إلكترونياً صحيحاً.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      await widget.client.auth.resetPasswordForEmail(value);
      if (mounted) setState(() => sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر إرسال رابط الاستعادة حالياً.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset, size: 54, color: _blue),
            const SizedBox(height: 14),
            const Text('استعادة الوصول إلى حسابك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ink)),
            const SizedBox(height: 10),
            Text(sent ? 'إذا كان البريد مسجلاً، فستصلك تعليمات الاستعادة وفق إعدادات مزود الهوية.' : 'أدخل بريد الحساب لإرسال رابط استعادة كلمة المرور.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 20),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: busy || sent ? null : sendReset, child: busy ? const CircularProgressIndicator() : const Text('إرسال رابط الاستعادة'))),
          ],
        )),
      )),
    ),
  );
}

class SettingsWorkspacePage extends StatefulWidget {
  const SettingsWorkspacePage({super.key, this.client});
  final SupabaseClient? client;
  @override
  State<SettingsWorkspacePage> createState() => _SettingsWorkspacePageState();
}
class _SettingsWorkspacePageState extends State<SettingsWorkspacePage> {
  bool signingOut = false;
  String units = 'مئوية';
  Future<void> signOut() async {
    if (widget.client == null) return;
    setState(() => signingOut = true);
    try {
      await widget.client!.auth.signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تسجيل الخروج. تحقق من الاتصال.')));
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }
  @override
  Widget build(BuildContext context) => _WorkspaceScaffold(
    title: 'إعدادات الحساب', subtitle: 'تفضيلات العرض وحالة جلسة المستخدم',
    child: Column(children: [
      _Panel(title: 'تفضيلات العرض', child: Column(children: [
        DropdownButtonFormField<String>(value: units, decoration: const InputDecoration(labelText: 'وحدة الحرارة', border: OutlineInputBorder()), items: const ['مئوية', 'فهرنهايت'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => units = v ?? units)),
        const SizedBox(height: 10),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.language, color: _blue), title: Text('لغة الواجهة'), subtitle: Text('العربية — من اليمين إلى اليسار')),
      ])),
      const SizedBox(height: 14),
      _Panel(title: 'الجلسة والأمان', child: Column(children: [
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.verified_user_outlined, color: _blue), title: const Text('حالة المصادقة'), subtitle: Text(widget.client == null ? 'وضع عرض دون اتصال' : 'تدار الجلسة بواسطة مزود الهوية')),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: widget.client == null || signingOut ? null : signOut, icon: const Icon(Icons.logout), label: Text(signingOut ? 'جارٍ تسجيل الخروج' : 'تسجيل الخروج'))),
      ])),
    ]),
  );
}


class PaperAndRecorderAuditPage extends StatelessWidget {
  const PaperAndRecorderAuditPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: _WorkspaceScaffold(
      title: 'تدقيق السجلات الورقية والآلية',
      subtitle: 'مطابقة المصادر الثلاثة مع حفظ الأصل ومراجعة بشرية إلزامية',
      child: Column(children: [
        const _InlineWarning(text: 'لا يتم تعديل الصورة أو السجل الأصلي. أي قيمة مستخرجة أو مصححة تحفظ كنسخة مشتقة منفصلة، ولا تعتمد قبل موافقة المدقق والمراجع المخوّل.'),
        const SizedBox(height: 12),
        const TabBar(
          isScrollable: true,
          labelColor: _blue,
          unselectedLabelColor: Colors.blueGrey,
          tabs: [
            Tab(text: 'لوحة التدقيق'),
            Tab(text: 'السجلات الورقية'),
            Tab(text: 'المسجلات الآلية'),
            Tab(text: 'مقارنة المصادر'),
          ],
        ),
        SizedBox(height: 610, child: TabBarView(children: [
          _AuditDashboardTab(),
          _AuditSourceTab(
            title: 'السجلات الورقية',
            icon: Icons.menu_book_outlined,
            sourceType: 'دفتر الرصد الورقي',
            details: 'رفع صورة صفحة الدفتر مع المحطة والتاريخ والوردية ورقم الصفحة. تحفظ الصورة الأصلية وبصمتها الرقمية وبيانات الرفع.',
          ),
          _AuditSourceTab(
            title: 'المسجلات الميكانيكية',
            icon: Icons.settings_input_component,
            sourceType: 'نوع الجهاز',
            details: 'يدعم سجل الأجهزة Thermograph وHygrograph وBarograph وPluviograph، مع صورة المخطط والفترة الزمنية ومعايرة الجهاز.',
          ),
          _ThreeSourceComparisonTab(),
        ])),
      ]),
    ),
  );
}

class _AuditDashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: const [
    Wrap(spacing: 8, runSpacing: 8, children: [
      _MetricPill(icon: Icons.upload_file, label: 'الوارد'),
      _MetricPill(icon: Icons.compare_arrows, label: 'بانتظار المطابقة'),
      _MetricPill(icon: Icons.rate_review_outlined, label: 'بانتظار التدقيق'),
      _MetricPill(icon: Icons.verified_outlined, label: 'المعتمد'),
    ]),
    SizedBox(height: 14),
    _EmptyState(icon: Icons.fact_check_outlined, title: 'لا توجد ملفات تدقيق محملة', message: 'ستظهر هنا قوائم المهام حسب المحطة والتاريخ ونوع المصدر وحالة الاستخراج ودرجة الثقة واسم المدقق.'),
    SizedBox(height: 12),
    _Panel(title: 'الأدوار ومسار الاعتماد', child: Column(children: [
      _RoleRow('رافع السجلات', 'رفع الأصل وإدخال بياناته الوصفية دون اعتماد النتائج'),
      _RoleRow('المدقق', 'مراجعة الاستخراج ومقارنة المصادر واقتراح التصحيح'),
      _RoleRow('المعتمد', 'اعتماد النتيجة أو إعادتها مع السبب'),
      _RoleRow('مدير النماذج', 'إدارة نسخ النموذج ومجموعات التدريب'),
      _RoleRow('مدير النظام', 'إدارة الإعدادات والصلاحيات ضمن التفويض'),
    ])),
  ]);
}

class _AuditSourceTab extends StatefulWidget {
  const _AuditSourceTab({required this.title, required this.icon, required this.sourceType, required this.details});
  final String title, sourceType, details;
  final IconData icon;
  @override
  State<_AuditSourceTab> createState() => _AuditSourceTabState();
}
class _AuditSourceTabState extends State<_AuditSourceTab> {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    _Panel(title: 'بيانات المصدر', child: Column(children: [
      Text('نوع المصدر: ${widget.sourceType}', style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 6),
      Text(widget.details, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5)),
      const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(labelText: 'رمز المحطة من الدليل المعتمد', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(decoration: const InputDecoration(labelText: 'تاريخ السجل / بداية الفترة (UTC)', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات وبيانات وصفية', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      const _SourceStatus(title: 'خدمة رفع الملفات', detail: 'لم يتم ربط التخزين الآمن أو خدمة استخراج القيم بعد. لا يمكن رفع ملفات فعلية من هذه الشاشة حالياً.', connected: false),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: null, icon: Icon(widget.icon), label: const Text('اختيار الملف الأصلي'))),
      const SizedBox(height: 6),
      const Text('الأصل غير قابل للاستبدال • تحفظ النسخ المشتقة بإصدار مستقل', style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
    ])),
    const SizedBox(height: 12),
    const _EmptyState(icon: Icons.folder_open_outlined, title: 'لا توجد ملفات ضمن هذا النوع', message: 'بعد تفعيل الرفع ستظهر الملفات مع بصمة SHA-256 ووقت الرفع وصاحب العملية وحالة الفحص.'),
  ]);
}

class _ThreeSourceComparisonTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    const _Panel(title: 'مصادر المقارنة', child: Column(children: [
      _KeyValue(label: 'المصدر الأول', value: 'السجل الورقي'),
      _KeyValue(label: 'المصدر الثاني', value: 'المسجل الميكانيكي'),
      _KeyValue(label: 'المصدر الثالث', value: 'الرصد الإلكتروني'),
    ])),
    const SizedBox(height: 12),
    const _Panel(title: 'نتائج المطابقة حسب العنصر والوقت', child: _EmptyState(icon: Icons.compare_arrows, title: 'لا توجد مقارنة بعد', message: 'ستعرض المقارنة القيم المتقابلة والانحراف ودرجة الثقة ومصدر كل قيمة وحالة الاتفاق والاختلاف، دون استبدال أي قيمة أصلية.')),
    const SizedBox(height: 12),
    const _InlineWarning(text: 'مخرجات الذكاء الاصطناعي اقتراحات مساعدة فقط. قرار التصحيح أو الاعتماد يبقى بشرياً ويُسجل مع السبب وهوية المراجع.'),
  ]);
}

class AiModelManagementPage extends StatelessWidget {
  const AiModelManagementPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: _WorkspaceScaffold(
      title: 'إدارة نماذج الذكاء الاصطناعي',
      subtitle: 'مكتبة الأجهزة ومجموعات التدريب وإصدارات النماذج',
      child: Column(children: [
        const TabBar(
          isScrollable: true,
          labelColor: _blue,
          unselectedLabelColor: Colors.blueGrey,
          tabs: [Tab(text: 'مكتبة الأجهزة'), Tab(text: 'التدريب'), Tab(text: 'الإصدارات'), Tab(text: 'التقارير')],
        ),
        SizedBox(height: 560, child: TabBarView(children: [
          _ModelLibraryTab(),
          _ModelTrainingTab(),
          _ModelVersionsTab(),
          const _ModuleStatusPage(title: 'تقارير النموذج', subtitle: 'مؤشرات الدقة والأخطاء والانحراف', message: 'تظهر تقارير الأداء بعد توافر مجموعة تحقق معتمدة ومقاييس تقييم موثقة.', icon: Icons.analytics_outlined),
        ])),
      ]),
    ),
  );
}
class _ModelLibraryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    const _Panel(title: 'أنواع الأجهزة', child: Column(children: [
      _RoleRow('Thermograph', 'مسجل درجة الحرارة'),
      _RoleRow('Hygrograph', 'مسجل الرطوبة'),
      _RoleRow('Barograph', 'مسجل الضغط الجوي'),
      _RoleRow('Pluviograph', 'مسجل الأمطار'),
    ])),
    const SizedBox(height: 12),
    const _SourceStatus(title: 'أرشيف الصور المرجعية', detail: 'لم يتم ربط مستودع ملفات الأجهزة أو مكتبة الصور المرجعية.', connected: false),
    const SizedBox(height: 12),
    const _EmptyState(icon: Icons.photo_library_outlined, title: 'لا توجد صور مرجعية', message: 'ستحفظ الصور الأصلية وبيانات الجهاز والمعايرة والمحطة وتاريخ الالتقاط ومصدر الصورة.'),
  ]);
}
class _ModelTrainingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: [
    const _Panel(title: 'إعداد مجموعة التدريب', child: Column(children: [
      _KeyValue(label: 'المدخلات', value: 'صور سجلات معتمدة وموسومة'),
      _KeyValue(label: 'مخرجات التدريب', value: 'اقتراح استخراج منظم مع الثقة'),
      _KeyValue(label: 'التحقق', value: 'مجموعة مستقلة غير مستخدمة بالتدريب'),
      _KeyValue(label: 'الاعتماد', value: 'مراجعة بشرية قبل النشر'),
    ])),
    const SizedBox(height: 12),
    const _InlineWarning(text: 'لا تستخدم بيانات محطة أو صوراً حقيقية للتدريب قبل اعتماد سياسة الخصوصية والموافقة ومصدر البيانات وفصل بيانات التدريب عن الاختبار.'),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.model_training), label: const Text('بدء التدريب'))),
  ]);
}
class _ModelVersionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(top: 14), children: const [
    _EmptyState(icon: Icons.layers_outlined, title: 'لا توجد إصدارات منشورة', message: 'سيظهر لكل إصدار رقم النسخة وبصمة النموذج ومجموعة التدريب ومقاييس التحقق وتاريخ النشر وحالة التراجع.'),
  ]);
}

class ClimateHomogenizationPage extends StatefulWidget {
  const ClimateHomogenizationPage({super.key});
  @override
  State<ClimateHomogenizationPage> createState() => _ClimateHomogenizationPageState();
}
class _ClimateHomogenizationPageState extends State<ClimateHomogenizationPage> {
  String variable = 'درجة الحرارة';
  String period = 'سنوي';
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: _WorkspaceScaffold(
      title: 'تجانس السلاسل المناخية',
      subtitle: 'كشف الانقطاعات ومقارنة المحطات وإدارة السلاسل المصححة',
      child: Column(children: [
        const _InlineWarning(text: 'تبقى السلسلة الخام محفوظة كما وردت دون تعديل. تُنشأ سلسلة مصححة مستقلة مع سجل كامل لكل تغيير وسبب التصحيح وإصدار خوارزمية التجانس.'),
        const SizedBox(height: 12),
        _Panel(title: 'إعداد التحليل', child: Column(children: [
          DropdownButtonFormField<String>(value: variable, decoration: const InputDecoration(labelText: 'العنصر', border: OutlineInputBorder()), items: const ['درجة الحرارة', 'الأمطار', 'سرعة الرياح', 'الرطوبة', 'الضغط'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => variable = v ?? variable)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: period, decoration: const InputDecoration(labelText: 'الفترة التحليلية', border: OutlineInputBorder()), items: const ['شهري', 'فصلي', 'سنوي'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => period = v ?? period)),
        ])),
        const SizedBox(height: 12),
        const TabBar(isScrollable: true, labelColor: _blue, unselectedLabelColor: Colors.blueGrey, tabs: [
          Tab(text: 'السلاسل الزمنية'), Tab(text: 'نقاط الانقطاع'), Tab(text: 'المحطات المرجعية'), Tab(text: 'السلسلة المصححة'), Tab(text: 'المناخيات والتقارير'),
        ]),
        SizedBox(height: 560, child: TabBarView(children: [
          _ClimatePanelTab(title: 'تحليل السلسلة الزمنية', message: 'عرض القيم الخام والفجوات والقيم الشاذة حسب الزمن. لا يتم تعديل السلسلة الخام.', icon: Icons.show_chart),
          _ClimatePanelTab(title: 'نقاط الانقطاع', message: 'تحديد نقاط التغير المحتملة ومراجعة تاريخ الأجهزة أو نقل المحطة أو تغير البيئة المحيطة.', icon: Icons.timeline),
          _ClimatePanelTab(title: 'مقارنة المحطات المرجعية', message: 'اختيار محطات مرجعية متجانسة مكانياً ومناخياً، مع توثيق سبب اختيار كل محطة.', icon: Icons.compare_arrows),
          _ClimatePanelTab(title: 'إدارة السلاسل المصححة', message: 'عرض نسخة مصححة منفصلة ومقارنة قبل/بعد مع إصدار الخوارزمية وموافقة المسؤول.', icon: Icons.rule_folder_outlined),
          _ClimatePanelTab(title: 'المعدلات المناخية والتقارير', message: 'المعدلات الشهرية والفصلية والسنوية والأمطار والحرارة والرياح والمؤشرات والاتجاهات والمقارنة الجغرافية.', icon: Icons.assessment_outlined),
        ])),
      ]),
    ),
  );
}
class _ClimatePanelTab extends StatelessWidget {
  const _ClimatePanelTab({required this.title, required this.message, required this.icon});
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14), child: _Panel(title: title, child: Column(children: [
    const _SourceStatus(title: 'محرك CLIMATOL / R', detail: 'لم يتم ربط محرك التحليل أو مستودع السلاسل بعد.', connected: false),
    const SizedBox(height: 12),
    _EmptyState(icon: icon, title: 'لا توجد نتائج متاحة', message: message),
  ])));
}
