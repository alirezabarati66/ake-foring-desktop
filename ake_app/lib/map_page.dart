import 'package:flutter/material.dart';
import 'package:neshan_maps_flutter/map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const mapKey = String.fromEnvironment('NESHAN_WEB_KEY');
  final controller = NeshanMapController();
  double latitude = 32.6546, longitude = 51.6680;
  bool busy = false, mapReady = false;
  String? mapError;

  @override
  void initState() {
    super.initState();
    controller.ready.then((_) { if (mounted) setState(() => mapReady = true); }).catchError((error) {
      if (mounted) setState(() => mapError = error.toString());
    });
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  void markReady() { if (mounted) setState(() => mapReady = true); }

  void mapFailed(String message, Exception? exception, StackTrace? stackTrace) {
    debugPrint('Neshan map error: $message | $exception');
    if (mounted) setState(() => mapError = message);
  }

  Future<void> confirm() async {
    setState(() => busy = true);
    try {
      if (!mapReady) throw StateError(mapError ?? 'نقشه هنوز بارگذاری نشده است');
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF14243D), foregroundColor: Colors.white,
      title: const Text('انتخاب موقعیت تحویل', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: mapKey.isEmpty
      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('کلید وب نقشه نشان وارد نشده است. هنگام ساخت برنامه NESHAN_WEB_KEY را تنظیم کنید.', textAlign: TextAlign.center)))
      : Stack(children: [
          Positioned.fill(child: NeshanMap(
            key: const ValueKey('ake-neshan-map'),
            mapKey: mapKey,
            enableDebug: true,
            controller: controller,
            config: NeshanMapConfig(
              initialCenter: const LatLng(32.6546, 51.6680),
              initialZoom: 14,
              mapType: NeshanMapType.neshanVector,
              showPoi: true,
              showTraffic: false,
              showCurrentLocationButton: true,
            ),
            onLocationChanged: (lat, lng) {
              latitude = lat; longitude = lng;
              if (!mapReady) markReady();
            },
            onError: mapFailed,
            onLocationError: mapFailed,
          )),
          const IgnorePointer(child: Center(child: Icon(Icons.location_pin, color: Colors.red, size: 46))),
          if (!mapReady && mapError == null)
            const Positioned(top: 12, left: 12, right: 12, child: LinearProgressIndicator()),
          if (mapError != null)
            Positioned(top: 12, left: 12, right: 12, child: Card(color: Colors.white, child: Padding(
              padding: const EdgeInsets.all(12), child: Text('خطای بارگذاری نقشه: $mapError\nاگر کلید از نوع Mobile است، آن را با کلید Web جایگزین کنید. دسترسی اینترنت WebView و سرویس نقشه پایه را هم بررسی کنید.', style: const TextStyle(color: Colors.red)),
            ))),
        ]),
    bottomNavigationBar: SafeArea(child: Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(width: double.infinity, child: FilledButton(
        onPressed: busy || !mapReady ? null : confirm,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC58D19), padding: const EdgeInsets.symmetric(vertical: 15)),
        child: Text(busy ? 'در حال بررسی موقعیت...' : 'تأیید موقعیت تحویل'),
      )),
    )),
  );
}
