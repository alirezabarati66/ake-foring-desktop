import 'package:flutter/material.dart';
import 'package:neshan_maps_flutter/map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState()=>_MapPageState();
}
class _MapPageState extends State<MapPage> {
  static const keyValue=String.fromEnvironment('NESHAN_WEB_KEY');
  final controller=NeshanMapController();
  bool busy=false;
  @override
  void dispose(){controller.dispose();super.dispose();}
  Future<void> confirm() async {
    setState(()=>busy=true);
    try {
      await controller.ready.timeout(const Duration(seconds:15));
      final center=await controller.getCurrentLocation().timeout(const Duration(seconds:10));
      if(mounted) Navigator.pop(context,[center.latitude,center.longitude]);
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('دریافت موقعیت نقشه ناموفق بود')));
    } finally {if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('انتخاب موقعیت تحویل')),
    body:keyValue.isEmpty?const Center(child:Text('کلید نقشه نشان تنظیم نشده است')):Stack(children:[
      NeshanMap(mapKey:keyValue,controller:controller,config:NeshanMapConfig(initialCenter:const LatLng(32.6546,51.6680),initialZoom:13,showCurrentLocationButton:true)),
      const IgnorePointer(child:Center(child:Icon(Icons.location_pin,color:Colors.red,size:42))),
    ]),
    bottomNavigationBar:SafeArea(child:Padding(padding:const EdgeInsets.all(12),child:FilledButton(onPressed:busy||keyValue.isEmpty?null:confirm,child:const Text('تایید موقعیت تحویل')))));
}
