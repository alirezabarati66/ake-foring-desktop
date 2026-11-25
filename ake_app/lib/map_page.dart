import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neshan_maps_flutter/map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const buildMapKey = String.fromEnvironment('NESHAN_WEB_KEY');
  static const storageKey = 'ake_neshan_web_key';
  final secureStorage = const FlutterSecureStorage();
  final keyInput = TextEditingController();
  NeshanMapController controller = NeshanMapController();

  String? mapKey;
  String? mapError;
  double latitude = 32.6546, longitude = 51.6680;
  bool busy = false, mapReady = false, savingKey = false;

  @override
  void initState() {
    super.initState();
    _restoreKey();
  }

  Future<void> _restoreKey() async {
    try {
      final saved = await secureStorage.read(key: storageKey);
      final key = buildMapKey.trim().isNotEmpty ? buildMapKey.trim() : saved;
      if (!mounted) return;
      setState(() => mapKey = key);
      if (key != null && key.isNotEmpty) _waitForMap();
    } catch (e) {
      if (mounted) setState(() => mapError = 'خواندن تنظیمات امن نقشه ناموفق بود: $e');
    }
  }

  void _waitForMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await controller.ready.timeout(const Duration(seconds: 18));
        if (mounted) setState(() => mapReady = true);
      } catch (e) {
        if (mounted) setState(() => mapError = 'نقشه آماده نشد: $e');
      }
    });
  }

  Future<void> saveMapKey() async {
    final key = keyInput.text.trim();
    if (key.isEmpty) {
      setState(() => mapError = 'کلید Web نشان را وارد کنید.');
      return;
    }
    setState(() { savingKey = true; mapError = null; mapReady = false; });
    try {
      await secureStorage.write(key: storageKey, value: key);
      if (!mounted) return;
      setState(() { mapKey = key; savingKey = false; });
      _waitForMap();
    } catch (e) {
      if (mounted) setState(() { savingKey = false; mapError = 'ذخیره امن کلید نقشه ناموفق بود: $e'; });
    }
  }

  void mapFailed(String message, Exception? exception, StackTrace? stackTrace) {
    debugPrint('Neshan map error: $message | $exception');
    if (mounted) setState(() { mapError = message; mapReady = false; });
  }

  Future<void> confirm() async {
    if (mapError != null || !mapReady) return;
    setState(() => busy = true);
    try {
      final center = await controller.getCurrentLocation().timeout(const Duration(seconds: 10));
      if (center == null) throw StateError('Map center unavailable');
      if (mounted) Navigator.pop(context, [center.latitude, center.longitude]);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('انتخاب موقعیت ممکن نشد: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    keyInput.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF14243D), foregroundColor: Colors.white,
      title: const Text('انتخاب موقعیت تحویل', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        if (mapKey != null)
          IconButton(
            tooltip: 'تغییر کلید Web نقشه',
            onPressed: () { controller.dispose(); controller = NeshanMapController(); setState(() { mapKey = null; mapReady = false; mapError = null; keyInput.clear(); }); },
            icon: const Icon(Icons.key_outlined),
          ),
      ],
    ),
    body: mapKey == null || mapKey!.isEmpty
      ? _keySetup()
      : Stack(children: [
          Positioned.fill(child: NeshanMap(
            key: ValueKey(mapKey),
            mapKey: mapKey!,
            controller: controller,
            enableDebug: true,
            config: NeshanMapConfig(
              initialCenter: const LatLng(32.6546, 51.6680),
              initialZoom: 14,
              mapType: NeshanMapType.neshanVector,
              showPoi: true,
              showTraffic: false,
              showCurrentLocationButton: true,
            ),
            onLocationChanged: (lat, lng) {
              latitude = lat;
              longitude = lng;
              if (!mapReady && mapError == null) setState(() => mapReady = true);
            },
            onError: mapFailed,
            onLocationError: mapFailed,
          )),
          const IgnorePointer(child: Center(child: Icon(Icons.location_pin, color: Colors.red, size: 46))),
          if (!mapReady && mapError == null)
            const Positioned(top: 12, left: 12, right: 12, child: LinearProgressIndicator()),
          if (mapError != null)
            Positioned(top: 12, left: 12, right: 12, child: Card(color: Colors.white, child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('خطای بارگذاری نقشه: $mapError\nکلید این افزونه باید از نوع Web باشد؛ کلید Mobile/Android کار نمی‌کند. اتصال اینترنت WebView و فعال بودن سرویس نقشه پایه را هم بررسی کنید.', style: const TextStyle(color: Colors.red)),
            ))),
        ]),
    bottomNavigationBar: mapKey == null
      ? null
      : SafeArea(child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(width: double.infinity, child: FilledButton(
            onPressed: busy || !mapReady || mapError != null ? null : confirm,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC58D19), padding: const EdgeInsets.symmetric(vertical: 15)),
            child: Text(busy ? 'در حال بررسی موقعیت...' : 'تأیید موقعیت تحویل'),
          )),
        )),
  );

  Widget _keySetup() => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE4EAF0))),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.map_outlined, color: Color(0xFFC58D19), size: 42),
      const SizedBox(height: 12),
      const Text('تنظیم نقشه نشان', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF14243D))),
      const SizedBox(height: 8),
      const Text('برای نمایش خیابان‌ها باید کلید Web بسازید. کلید Mobile که قبلاً ساخته شده با این SDK سازگار نیست. در پنل نشان، نوع کلید را Web انتخاب کنید و سرویس نقشه پایه وب را فعال کنید.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.7, color: Colors.blueGrey)),
      const SizedBox(height: 16),
      TextField(
        controller: keyInput,
        obscureText: true,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(labelText: 'کلید Web نقشه نشان', border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)), prefixIcon: const Icon(Icons.key)),
      ),
      if (mapError != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(mapError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: savingKey ? null : saveMapKey,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC58D19), padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Text(savingKey ? 'در حال ذخیره...' : 'ذخیره امن کلید و نمایش نقشه'),
      ),
      const SizedBox(height: 6),
      const Text('کلید فقط در حافظه امن همین گوشی ذخیره می‌شود و داخل سورس یا GitHub قرار نمی‌گیرد.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
    ]),
  )));
}
