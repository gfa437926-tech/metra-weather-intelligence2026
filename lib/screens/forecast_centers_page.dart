import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/station_directory_service.dart';
import '../domain/station_record.dart';

const _ink = Color(0xFF102448);
const _blue = Color(0xFF1769D2);

/// Forecast-centre workspace. It deliberately separates verified station
/// metadata from live telemetry: no sensor values are fabricated here.
class ForecastCentersPage extends StatefulWidget {
  const ForecastCentersPage({super.key, required this.client});
  final SupabaseClient? client;

  @override
  State<ForecastCentersPage> createState() => _ForecastCentersPageState();
}

class _ForecastCentersPageState extends State<ForecastCentersPage> {
  late Future<List<StationRecord>>? _stations;
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _stations = widget.client == null
        ? null
        : StationDirectoryService(widget.client!).fetchStations();
  }

  void _refresh() => setState(_load);

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        Row(children: [
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مراكز التنبؤ الجوي', style: TextStyle(
                color: _ink, fontSize: 23, fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('مقارنة المحطات والمناطق وفق الموقع والبيانات المعتمدة',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            ],
          )),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh),
            tooltip: 'تحديث دليل المحطات'),
        ]),
        const SizedBox(height: 14),
        _statusCard(
          icon: Icons.sensors_off_outlined,
          title: 'بيانات القياس اللحظية غير متصلة',
          message: 'تعرض هذه الشاشة بيانات دليل المحطات الموثقة فقط. لا توجد حالياً قناة تيليمترية معتمدة لعرض المطر أو سرعة الرياح واتجاهها؛ لذلك لن تظهر قراءات تقديرية على أنها قراءات محطات.',
          color: const Color(0xFFFFF4DE),
          foreground: const Color(0xFF875B08),
        ),
        const SizedBox(height: 12),
        _statusCard(
          icon: Icons.compare_arrows,
          title: 'مساحة المقارنة الجغرافية',
          message: 'تُرتب المحطات حسب إحداثياتها المتاحة. الارتفاع غير متوفر في نموذج دليل المحطات الحالي، وسيظهر كغير متاح بدلاً من تخمينه.',
          color: const Color(0xFFEAF2FF),
          foreground: _blue,
        ),
        const SizedBox(height: 18),
        const Text('تصفية المحطات', style: TextStyle(
          color: _ink, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 9),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final option in ['الكل', 'كلاسيكية', 'آلية', 'ذات إحداثيات'])
            ChoiceChip(
              label: Text(option),
              selected: _filter == option,
              onSelected: (_) => setState(() => _filter = option),
              selectedColor: const Color(0xFFDCEBFF),
              labelStyle: TextStyle(
                color: _filter == option ? _blue : Colors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
        ]),
        const SizedBox(height: 12),
        if (_stations == null)
          _emptyState('يلزم تسجيل الدخول لقراءة دليل المحطات المعتمد.')
        else
          FutureBuilder<List<StationRecord>>(
            future: _stations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _emptyState('تعذر تحميل دليل المحطات. تحقق من صلاحية الحساب واتصال الخدمة.');
              }
              final all = snapshot.data ?? const <StationRecord>[];
              final visible = all.where((station) {
                switch (_filter) {
                  case 'كلاسيكية': return station.isClassic;
                  case 'آلية': return station.isAutomatic;
                  case 'ذات إحداثيات': return station.hasCoordinates;
                  default: return true;
                }
              }).toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('المحطات المدرجة: ${visible.length}',
                    style: const TextStyle(color: _ink, fontWeight: FontWeight.bold))),
                  Text('من أصل ${all.length}',
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
                ]),
                const SizedBox(height: 9),
                if (visible.isEmpty)
                  _emptyState('لا توجد محطات تطابق عامل التصفية.')
                else
                  for (final station in visible) _stationCard(station),
              ]);
            },
          ),
      ],
    ),
  );

  Widget _stationCard(StationRecord station) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE8EDF5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEAF2FF),
          child: Icon(station.isClassic ? Icons.home_work_outlined : Icons.sensors,
            color: _blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(station.name, style: const TextStyle(
            color: _ink, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('${station.code} • ${station.typeLabel}',
            style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
        ])),
        _pill(station.operationalLabel,
          station.normalizedOperationalStatus == 'active'
            ? const Color(0xFFE5F5EC) : const Color(0xFFFFF2DE)),
      ]),
      const SizedBox(height: 11),
      Wrap(spacing: 14, runSpacing: 7, children: [
        _detail(Icons.location_on_outlined, station.hasCoordinates
          ? '${station.latitude!.toStringAsFixed(4)}, ${station.longitude!.toStringAsFixed(4)}'
          : 'الإحداثيات غير متاحة'),
        _detail(Icons.terrain_outlined, 'الارتفاع: غير متاح'),
        _detail(Icons.verified_outlined, station.approvalLabel),
      ]),
      const SizedBox(height: 9),
      const Divider(height: 1),
      const SizedBox(height: 8),
      const Row(children: [
        Icon(Icons.cloud_off_outlined, color: Colors.blueGrey, size: 15),
        SizedBox(width: 6),
        Expanded(child: Text('لا توجد قراءة لحظية مرتبطة بهذه المحطة',
          style: TextStyle(color: Colors.blueGrey, fontSize: 10))),
      ]),
    ]),
  );

  Widget _detail(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.blueGrey, size: 14),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
    ],
  );

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: _ink, fontSize: 9,
      fontWeight: FontWeight.w600)),
  );

  Widget _statusCard({
    required IconData icon, required String title, required String message,
    required Color color, required Color foreground,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(17)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: foreground, size: 21),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 5),
        Text(message, style: TextStyle(color: foreground, fontSize: 10, height: 1.55)),
      ])),
    ]),
  );

  Widget _emptyState(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Text(message, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
  );
}
