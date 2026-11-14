import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/metra_api_client.dart';
import '../data/metra_operations_service.dart';

class ObservationsPage extends StatefulWidget {
  const ObservationsPage({super.key, required this.client});
  final SupabaseClient? client;

  @override
  State<ObservationsPage> createState() => _ObservationsPageState();
}

class _ObservationsPageState extends State<ObservationsPage> {
  late Future<Map<String, dynamic>> future;
  final Map<String, TextEditingController> valueControllers = {};
  final Map<String, bool?> booleanValues = {};
  String? selectedStationId;
  String? selectedTypeCode;
  DateTime observedAt = DateTime.now();
  bool busy = false;
  String? idempotencyKey;
  String? pendingFingerprint;

  @override
  void initState() {
    super.initState();
    idempotencyKey = _newIdempotencyKey();
    future = loadData();
  }

  @override
  void dispose() {
    for (final controller in valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _newIdempotencyKey() {
    final userId = widget.client?.auth.currentUser?.id ?? 'user';
    return '$userId-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<Map<String, dynamic>> loadData() async {
    final client = widget.client;
    if (client == null) {
      throw Exception('يلزم إعداد المصادقة وخدمة METRA API.');
    }
    final operations = MetraOperationsService.fromSupabase(client);
    final stations = await operations.fetchObservationStations();
    final own = await operations.fetchOwnObservations();
    List<Map<String, dynamic>> review = [];
    try {
      review = await operations.fetchObservationReviewQueue();
    } on MetraApiException catch (exception) {
      if (exception.statusCode != 403) rethrow;
    }

    final typeResponse = await operations.fetchObservationTypes();
    final parameterResponse = await operations.fetchObservationParameters();
    final types = (typeResponse['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final parameters = (parameterResponse['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    _ensureControllers(parameters);
    return {
      'stations': stations,
      'own': own,
      'review': review,
      'types': types,
      'parameters': parameters,
    };
  }

  void _ensureControllers(List<Map<String, dynamic>> parameters) {
    final codes = parameters
        .map((item) => item['parameter_code']?.toString() ?? '')
        .where((code) => code.isNotEmpty)
        .toSet();
    for (final code in valueControllers.keys.toList()) {
      if (!codes.contains(code)) {
        valueControllers.remove(code)?.dispose();
        booleanValues.remove(code);
      }
    }
    for (final code in codes) {
      valueControllers.putIfAbsent(code, TextEditingController.new);
    }
  }

  Future<void> _chooseObservedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: observedAt,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: 'تاريخ الرصد',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(observedAt),
      helpText: 'وقت الرصد',
    );
    if (time == null || !mounted) return;
    setState(() {
      observedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveObservation({
    required bool submit,
    required List<Map<String, dynamic>> parameters,
  }) async {
    if (busy || widget.client == null) return;
    if (selectedStationId == null || selectedTypeCode == null) {
      _toast('اختر المحطة ونوع الرصد أولاً.');
      return;
    }
    if (parameters.isEmpty) {
      _toast('لا يمكن إدخال الرصد قبل اعتماد معايير القياس ووحداتها.');
      return;
    }

    final values = <Map<String, dynamic>>[];
    for (final parameter in parameters) {
      final code = parameter['parameter_code']?.toString() ?? '';
      final kind = parameter['value_kind']?.toString() ?? '';
      if (code.isEmpty) continue;
      if (kind == 'boolean') {
        final value = booleanValues[code];
        if (value != null) {
          values.add({
            'parameter_code': code,
            'value_kind': kind,
            'value_boolean': value,
            'sequence_number': 1,
          });
        }
        continue;
      }

      final raw = valueControllers[code]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      if (kind == 'decimal') {
        final value = double.tryParse(raw);
        if (value == null || !value.isFinite) {
          _toast('القيمة المدخلة في «${parameter['name_ar']}» ليست رقماً صالحاً.');
          return;
        }
        values.add({
          'parameter_code': code,
          'value_kind': kind,
          'value_decimal': value,
          'sequence_number': 1,
        });
      } else if (kind == 'integer') {
        final value = int.tryParse(raw);
        if (value == null) {
          _toast('القيمة المدخلة في «${parameter['name_ar']}» يجب أن تكون عدداً صحيحاً.');
          return;
        }
        values.add({
          'parameter_code': code,
          'value_kind': kind,
          'value_integer': value,
          'sequence_number': 1,
        });
      } else if (kind == 'text') {
        values.add({
          'parameter_code': code,
          'value_kind': kind,
          'value_text': raw,
          'sequence_number': 1,
        });
      }
    }

    if (values.isEmpty) {
      _toast('أدخل قيمة واحدة على الأقل من المعايير المعتمدة.');
      return;
    }

    final requestBody = <String, dynamic>{
      'station_id': selectedStationId,
      'observation_type': selectedTypeCode,
      'observed_at': observedAt.toUtc().toIso8601String(),
      'timezone_name': null,
      'payload': values,
      'submit': submit,
    };
    final fingerprint = jsonEncode(requestBody);
    if (pendingFingerprint != fingerprint) {
      idempotencyKey = _newIdempotencyKey();
      pendingFingerprint = fingerprint;
    }

    setState(() {
      busy = true;
    });
    try {
      final result = await MetraOperationsService.fromSupabase(widget.client!)
          .submitObservation({...requestBody, 'idempotency_key': idempotencyKey});
      final id = result['id']?.toString() ?? '';
      final status = result['status']?.toString() ?? '';
      if (id.isEmpty || !const {'draft', 'submitted'}.contains(status)) {
        throw Exception('لم يؤكد الخادم حفظ سجل الرصد.');
      }
      idempotencyKey = _newIdempotencyKey();
      pendingFingerprint = null;
      for (final controller in valueControllers.values) {
        controller.clear();
      }
      booleanValues.clear();
      if (!mounted) return;
      _toast(result['replayed'] == true
          ? 'تم التعرف على العملية السابقة دون إنشاء سجل مكرر.'
          : submit
              ? 'تم إرسال الرصد للمراجعة.'
              : 'تم حفظ مسودة الرصد.');
      setState(() => future = loadData());
    } catch (exception) {
      if (mounted) _toast(exception.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سبب قرار المراجعة'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'اكتب سبب القرار (3 أحرف على الأقل)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().length < 3) return;
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _decide(Map<String, dynamic> item, String decision) async {
    final reason = await _askReason();
    if (reason == null || !mounted || widget.client == null || busy) return;
    setState(() => busy = true);
    try {
      await MetraOperationsService.fromSupabase(widget.client!).decideObservation(
        item['id']?.toString() ?? '',
        {'decision': decision, 'reason': reason},
      );
      if (!mounted) return;
      _toast(decision == 'approved' ? 'تم اعتماد الرصد.' : 'أعيد الرصد للتصحيح.');
      setState(() => future = loadData());
    } catch (exception) {
      if (mounted) _toast(exception.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _status(String? status) => switch (status) {
        'draft' => 'مسودة',
        'submitted' => 'بانتظار المراجعة',
        'under_review' => 'قيد المراجعة',
        'approved' => 'معتمد',
        'returned' => 'معاد للتصحيح',
        'rejected' => 'مرفوض',
        _ => 'غير معروف',
      };

  String _type(String? type, List<Map<String, dynamic>> types) {
    for (final item in types) {
      if (item['type_code'] == type) return item['name_ar']?.toString() ?? 'رصد';
    }
    return type ?? 'رصد';
  }

  String _valueText(Map<String, dynamic> value) {
    final kind = value['value_kind'];
    final raw = switch (kind) {
      'decimal' => value['value_decimal'],
      'integer' => value['value_integer'],
      'text' => value['value_text'],
      'boolean' => value['value_boolean'] == true ? 'نعم' : 'لا',
      _ => null,
    };
    final unit = value['unit_symbol']?.toString();
    return '${value['name_ar'] ?? value['parameter_code']}: $raw${unit == null || unit.isEmpty ? '' : ' $unit'}';
  }

  Widget _sectionTitle(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 18),
        child: Row(children: [
          Expanded(
            child: Text(title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102448))),
          ),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ]),
      );

  Widget _observationCard(
    Map<String, dynamic> item, {
    required bool review,
    required List<Map<String, dynamic>> types,
  }) {
    final values = (item['values'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
    final observedAt = DateTime.tryParse(item['observed_at']?.toString() ?? '')?.toLocal();
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.sensors, color: Color(0xFF1769D2)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              item['station_name']?.toString() ?? 'محطة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
            Chip(label: Text(_status(item['submission_state']?.toString()),
              style: const TextStyle(fontSize: 10))),
          ]),
          Text(
            '${_type(item['observation_type']?.toString(), types)} • ${item['station_code'] ?? ''}',
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          if (observedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'وقت الرصد: ${observedAt.year}-${observedAt.month.toString().padLeft(2, '0')}-${observedAt.day.toString().padLeft(2, '0')} ${observedAt.hour.toString().padLeft(2, '0')}:${observedAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
            ),
          if (values.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: values.map((value) => Chip(
                  label: Text(_valueText(value), style: const TextStyle(fontSize: 11)),
                )).toList(),
              ),
            ),
          if (review) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              FilledButton.icon(
                onPressed: busy ? null : () => _decide(item, 'approved'),
                icon: const Icon(Icons.verified_outlined, size: 17),
                label: const Text('اعتماد'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _decide(item, 'returned'),
                icon: const Icon(Icons.assignment_return_outlined, size: 17),
                label: const Text('إعادة للتصحيح'),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _parameterField(Map<String, dynamic> parameter) {
    final code = parameter['parameter_code']?.toString() ?? '';
    final kind = parameter['value_kind']?.toString() ?? '';
    final name = parameter['name_ar']?.toString() ?? code;
    final unit = parameter['unit_symbol']?.toString();
    final precision = parameter['precision_scale'];
    final hint = precision == null ? null : 'الدقة: $precision منازل عشرية';

    if (kind == 'boolean') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(name),
        value: booleanValues[code] ?? false,
        onChanged: busy ? null : (value) => setState(() => booleanValues[code] = value),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: valueControllers[code],
        keyboardType: kind == 'text'
            ? TextInputType.text
            : TextInputType.numberWithOptions(decimal: kind == 'decimal', signed: true),
        maxLines: kind == 'text' ? 3 : 1,
        decoration: InputDecoration(
          labelText: name,
          suffixText: unit,
          helperText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  FutureBuilder<Map<String, dynamic>> _buildBody() => FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off, color: Colors.blueGrey, size: 36),
                const SizedBox(height: 10),
                Text(snapshot.error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => setState(() => future = loadData()),
                  child: const Text('إعادة المحاولة'),
                ),
              ]),
            ));
          }

          final data = snapshot.data ?? <String, dynamic>{};
          final stations = (data['stations'] as List? ?? const [])
              .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final own = (data['own'] as List? ?? const [])
              .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final review = (data['review'] as List? ?? const [])
              .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final types = (data['types'] as List? ?? const [])
              .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final parameters = (data['parameters'] as List? ?? const [])
              .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

          selectedStationId ??= stations.isEmpty ? null : stations.first['id']?.toString();
          selectedTypeCode ??= types.isEmpty ? null : types.first['type_code']?.toString();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'تُبنى حقول الرصد من القاموس العلمي المعتمد في قاعدة البيانات. لا تُستخدم حدود أو وحدات قياس مفترضة داخل التطبيق.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF234A7C)),
                ),
              ),
              if (stations.isNotEmpty && types.isNotEmpty) ...[
                _sectionTitle('إدخال رصد جديد', 'معايير معتمدة فقط'),
                DropdownButtonFormField<String>(
                  value: selectedStationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'محطة الرصد', border: OutlineInputBorder()),
                  items: stations.map((station) => DropdownMenuItem<String>(
                    value: station['id']?.toString(),
                    child: Text(
                      '${station['name_ar'] ?? 'محطة'} • ${station['local_station_code'] ?? ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: busy ? null : (value) => setState(() => selectedStationId = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTypeCode,
                  decoration: const InputDecoration(
                    labelText: 'نوع الرصد', border: OutlineInputBorder()),
                  items: types.map((type) => DropdownMenuItem<String>(
                    value: type['type_code']?.toString(),
                    child: Text(type['name_ar']?.toString() ?? type['type_code'].toString()),
                  )).toList(),
                  onChanged: busy ? null : (value) => setState(() => selectedTypeCode = value),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: busy ? null : _chooseObservedAt,
                  icon: const Icon(Icons.schedule),
                  label: Text('وقت الرصد: ${observedAt.toLocal()}'),
                ),
                const SizedBox(height: 10),
                if (parameters.isEmpty)
                  const _Notice(
                    message: 'قاموس المعايير والوحدات العلمية فارغ حالياً. تم تعطيل إرسال القياسات حتى تُضاف التعريفات المعتمدة.',
                    warning: true,
                  )
                else ...[
                  _sectionTitle('القيم المرصودة', '${parameters.length} معيار'),
                  ...parameters.map(_parameterField),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _saveObservation(
                        submit: false, parameters: parameters),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('حفظ مسودة'),
                    ),
                    FilledButton.icon(
                      onPressed: busy ? null : () => _saveObservation(
                        submit: true, parameters: parameters),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('إرسال للمراجعة'),
                    ),
                    if (busy)
                      const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ]),
                ],
              ] else
                const _Notice(
                  message: 'لا توجد محطة مكلف بها الحساب أو لا توجد أنواع رصد نشطة متاحة. لن تظهر حقول إدخال غير مرتبطة ببيانات معتمدة.',
                  warning: true,
                ),
              _sectionTitle('طلبات المراجعة', '${review.length}'),
              if (review.isEmpty)
                const Text('لا توجد قراءات بانتظار المراجعة ضمن صلاحياتك.',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ...review.map((item) => _observationCard(item, review: true, types: types)),
              _sectionTitle('سجل رصدك', '${own.length}'),
              if (own.isEmpty)
                const Text('لم تسجل أي قراءات بعد.',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ...own.map((item) => _observationCard(item, review: false, types: types)),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الرصد التشغيلي'),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: busy ? null : () => setState(() => future = loadData()),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: widget.client == null
              ? const Center(child: Text('يلزم إعداد اتصال METRA API.'))
              : _buildBody(),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.warning});
  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: warning ? const Color(0xFFFFF4DE) : const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message, style: TextStyle(
          color: warning ? const Color(0xFF875B08) : const Color(0xFF234A7C),
          fontSize: 12,
          height: 1.5,
        )),
      );
}
