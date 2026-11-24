import 'package:flutter/material.dart';
import 'services/delivery_service.dart';
import 'map_page.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryPage extends StatefulWidget {
  final String token;
  final bool courier;
  const DeliveryPage({super.key, required this.token, required this.courier});
  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}
class _DeliveryPageState extends State<DeliveryPage> {
  late final api = DeliveryService(widget.token);
  late Future<List<Map<String,dynamic>>> items = load();
  Future<List<Map<String,dynamic>>> load() => widget.courier ? api.missions() : api.orders();
  Future<void> edit(int id) async {
    final result = await Navigator.of(context).push<List<double>>(MaterialPageRoute(builder: (_) => const MapPage()));
    if(result==null || !mounted) return;
    try {
      await api.saveLocation(id,result[0],result[1]);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('موقعیت ذخیره شد')));
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ذخیره موقعیت ناموفق بود')));
    }
  }
  Future<void> navigate(Map<String,dynamic> row) async {
    final lat=row['lat'],lng=row['lng'];
    final choices={'انتخاب برنامه مسیریاب':Uri.parse('geo:$lat,$lng?q=$lat,$lng'),'Google Maps':Uri.https('www.google.com','/maps/dir/',{'api':'1','destination':'$lat,$lng'}),'Waze':Uri.https('waze.com','/ul',{'ll':'$lat,$lng','navigate':'yes'})};
    final uri=await showDialog<Uri>(context:context,builder:(ctx)=>SimpleDialog(title:const Text('مسیریابی'),children:choices.entries.map((e)=>SimpleDialogOption(onPressed:()=>Navigator.pop(ctx,e.value),child:Text(e.key))).toList()));
    if(uri==null || !mounted) return;
    try { if(!await launchUrl(uri,mode:LaunchMode.externalApplication)) throw Exception(); }
    catch (_) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('باز کردن مسیریاب ناموفق بود'))); }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.courier?'مأموریت‌های پیک':'سفارش‌های من'),actions:[IconButton(onPressed:()=>setState(()=>items=load()),icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:items,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done) return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError) return const Center(child:Text('دریافت اطلاعات ناموفق بود'));
      final rows=snapshot.data??[];
      if(rows.isEmpty) return const Center(child:Text('موردی یافت نشد'));
      return ListView(children:rows.map((row)=>Card(child:ListTile(
        title:Text('سفارش ${row['number']??row['id']}'),
        subtitle:Text(widget.courier?'${row['address']}\n${row['lat']}, ${row['lng']}':'${row['status']}'),
        trailing:widget.courier?IconButton(icon:const Icon(Icons.directions),onPressed:()=>navigate(row)):IconButton(onPressed:()=>edit(row['id'] as int),icon:const Icon(Icons.location_on)),
      ))).toList());
    }));
}
