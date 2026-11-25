import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/delivery_service.dart';
import 'map_page.dart';

const _navy = Color(0xFF10243E);
const _gold = Color(0xFFC58D19);
const _bg = Color(0xFFF3F5F8);

class DeliveryPage extends StatefulWidget {
  final String token;
  final bool courier;
  const DeliveryPage({super.key, required this.token, required this.courier});
  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  late final api = DeliveryService(widget.token);
  late Future<List<Map<String, dynamic>>> items = load();
  bool actionBusy = false;
  Future<List<Map<String, dynamic>>> load() => widget.courier ? api.missions() : api.orders();

  Future<void> edit(int id) async {
    final result = await Navigator.of(context).push<List<double>>(MaterialPageRoute(builder: (_) => const MapPage()));
    if (result == null || !mounted) return;
    try {
      await api.saveLocation(id, result[0], result[1]);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('موقعیت تحویل ذخیره شد'))); setState(() => items = load()); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ذخیره موقعیت ناموفق بود: $e')));
    }
  }

  Future<void> navigate(Map<String, dynamic> row) async {
    final lat = row['lat'], lng = row['lng'];
    if (lat == null || lng == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مختصات مقصد ثبت نشده است'))); return; }
    final choices = <String, Uri>{
      'مسیریاب پیش‌فرض گوشی': Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
      'Google Maps': Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '$lat,$lng'}),
      'Waze': Uri.https('waze.com', '/ul', {'ll': '$lat,$lng', 'navigate': 'yes'}),
    };
    final uri = await showModalBottomSheet<Uri>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('انتخاب مسیریاب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
      for (final item in choices.entries) ListTile(leading: const Icon(Icons.navigation), title: Text(item.key), onTap: () => Navigator.pop(ctx, item.value)),
    ])));
    if (uri == null || !mounted) return;
    try { if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw Exception(); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('باز کردن مسیریاب ناموفق بود'))); }
  }

  String statusLabel(String value) => switch (value) {
    'accepted' => 'پذیرفته‌شده', 'picked_up' => 'کالا دریافت شده', 'out_for_delivery' => 'در مسیر تحویل',
    'delivered' => 'تحویل شده', 'assigned' => 'تخصیص‌یافته', _ => value.isEmpty ? 'در انتظار بررسی' : value,
  };
  String nextStatus(String value) => switch (value) {
    'assigned' => 'accepted', 'accepted' => 'picked_up', 'picked_up' => 'out_for_delivery',
    'out_for_delivery' => 'delivered', _ => '',
  };
  String nextLabel(String value) => switch (value) {
    'assigned' => 'پذیرش مأموریت', 'accepted' => 'تأیید دریافت کالا', 'picked_up' => 'شروع مسیر تحویل',
    'out_for_delivery' => 'ثبت تحویل سفارش', _ => 'مأموریت تکمیل شده',
  };

  Future<void> updateStatus(Map<String, dynamic> row) async {
    final id = (row['id'] as num?)?.toInt();
    final next = nextStatus((row['delivery_status'] ?? 'assigned').toString());
    if (id == null || next.isEmpty || actionBusy) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأیید تغییر وضعیت'), content: Text('وضعیت مأموریت به «${statusLabel(next)}» تغییر کند؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأیید'))],
    ));
    if (confirm != true || !mounted) return;
    setState(() => actionBusy = true);
    try {
      await api.updateMissionStatus(id, next);
      if (mounted) { setState(() => items = load()); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('وضعیت مأموریت: ${statusLabel(next)}'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت وضعیت ناموفق بود: $e'))); }
    finally { if (mounted) setState(() => actionBusy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _navy, foregroundColor: Colors.white,
      title: Text(widget.courier ? 'مرکز عملیات پیک' : 'سفارش‌های من', style: const TextStyle(fontWeight: FontWeight.w900)),
      actions: [IconButton(onPressed: () => setState(() => items = load()), icon: const Icon(Icons.refresh_rounded))]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: items, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: _gold));
      if (snapshot.hasError) return _empty('دریافت اطلاعات ناموفق بود', retry: true);
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return _empty(widget.courier ? 'در حال حاضر مأموریت فعالی ندارید' : 'هنوز سفارشی ثبت نکرده‌اید');
      return widget.courier ? _courierDashboard(rows) : _customerOrders(rows);
    }),
  );

  Widget _empty(String text, {bool retry = false}) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey), const SizedBox(height: 12), Text(text),
    if (retry) TextButton(onPressed: () => setState(() => items = load()), child: const Text('تلاش مجدد')),
  ]));

  Widget _courierDashboard(List<Map<String, dynamic>> rows) {
    final completed = rows.where((r) => r['delivery_status'] == 'delivered').length;
    final active = rows.length - completed;
    return RefreshIndicator(onRefresh: () async => setState(() => items = load()), child: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, Color(0xFF29466C)]), borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.delivery_dining, color: Colors.white, size: 28)), SizedBox(width: 10), Expanded(child: Text('داشبورد پیک آریان کوب', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)))]),
          const SizedBox(height: 18),
          Row(children: [_metric('کل مأموریت‌ها', '${rows.length}'), _metric('در جریان', '$active'), _metric('تحویل‌شده', '$completed')]),
        ])),
      const SizedBox(height: 18), const Text('مأموریت‌های تخصیص‌یافته', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _navy)),
      const SizedBox(height: 10), for (final row in rows) _missionCard(row),
    ]));
  }

  Widget _metric(String label, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]));

  Widget _missionCard(Map<String, dynamic> row) {
    final state = (row['delivery_status'] ?? 'assigned').toString();
    final next = nextStatus(state);
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE5EAF0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('سفارش #${row['number'] ?? row['id']}', style: const TextStyle(fontWeight: FontWeight.w900, color: _navy, fontSize: 16))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: state == 'delivered' ? const Color(0xFFE5F6EC) : const Color(0xFFFFF3D9), borderRadius: BorderRadius.circular(20)),
            child: Text(statusLabel(state), style: TextStyle(color: state == 'delivered' ? Colors.green.shade800 : Colors.brown, fontSize: 11, fontWeight: FontWeight.bold)))]),
        const Divider(height: 22),
        _detail(Icons.person_outline, (row['customer'] ?? 'مشتری').toString()),
        if ((row['phone'] ?? '').toString().isNotEmpty) _detail(Icons.phone_outlined, row['phone'].toString(), onTap: () => launchUrl(Uri(scheme: 'tel', path: row['phone'].toString()))),
        _detail(Icons.location_on_outlined, (row['address'] ?? 'نشانی ثبت نشده').toString()),
        if ((row['total'] ?? '').toString().isNotEmpty) _detail(Icons.payments_outlined, row['total'].toString()),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => navigate(row), icon: const Icon(Icons.directions), label: const Text('مسیریابی'))),
          const SizedBox(width: 9),
          Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: _gold),
            onPressed: next.isEmpty || actionBusy ? null : () => updateStatus(row),
            child: Text(actionBusy ? 'در حال ثبت...' : nextLabel(state), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))),
        ]),
      ]),
    );
  }

  Widget _customerOrders(List<Map<String, dynamic>> rows) => RefreshIndicator(onRefresh: () async => setState(() => items = load()), child: ListView(padding: const EdgeInsets.all(14), children: [
    const Text('سفارش‌های شما', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _navy)),
    const SizedBox(height: 12),
    for (final row in rows) Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('سفارش #${row['number'] ?? row['id']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 6), Text('وضعیت سفارش: ${row['status'] ?? 'نامشخص'}'),
      if ((row['date'] ?? '').toString().isNotEmpty) Text('تاریخ: ${row['date']}'),
      if ((row['total'] ?? '').toString().isNotEmpty) Text('مبلغ: ${row['total']}'),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () => edit((row['id'] as num).toInt()), icon: const Icon(Icons.location_on_outlined), label: const Text('انتخاب / تغییر موقعیت تحویل'))),
    ]))),
  ]));

  Widget _detail(IconData icon, String text, {VoidCallback? onTap}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
    child: InkWell(onTap: onTap, child: Row(children: [
      Icon(icon, size: 18, color: _gold), const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF34465B)))),
      if (onTap != null) const Icon(Icons.call, size: 16, color: _gold),
    ])));
}
