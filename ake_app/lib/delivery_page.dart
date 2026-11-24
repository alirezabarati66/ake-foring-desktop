import 'package:flutter/material.dart';
import 'services/delivery_service.dart';

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
    final lat = TextEditingController(), lng = TextEditingController();
    final result = await showDialog<List<double>>(context: context,builder:(ctx)=>AlertDialog(
      title: const Text('مختصات تحویل'),
      content: Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:lat,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'عرض جغرافیایی')),
        TextField(controller:lng,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'طول جغرافیایی')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('انصراف')),FilledButton(onPressed:(){
        final a=double.tryParse(lat.text),b=double.tryParse(lng.text);
        if(a!=null && b!=null && a.isFinite && b.isFinite && a.abs()<=90 && b.abs()<=180) Navigator.pop(ctx,[a,b]);
      },child:const Text('تایید'))]));
    lat.dispose();lng.dispose();
    if(result==null || !mounted) return;
    try {
      await api.saveLocation(id,result[0],result[1]);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('موقعیت ذخیره شد')));
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ذخیره موقعیت ناموفق بود')));
    }
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
        trailing:widget.courier?null:IconButton(onPressed:()=>edit(row['id'] as int),icon:const Icon(Icons.location_on)),
      ))).toList());
    }));
}
