import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/delivery_service.dart';
import 'map_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<int,int> items;
  final Map<int, Map<String, String>> selections;
  const CheckoutPage({super.key,required this.items,required this.selections});
  @override
  State<CheckoutPage> createState()=>_CheckoutPageState();
}
class _CheckoutPageState extends State<CheckoutPage>{
  final address=TextEditingController();
  List<double>? location;
  bool busy=false;
  String? error;
  @override
  void dispose(){address.dispose();super.dispose();}
  Future<void> submit() async {
    if(busy || location==null || address.text.trim().isEmpty)return;
    setState((){busy=true;error=null;});
    try{
      final token=await const FlutterSecureStorage().read(key:'ake_token');
      if(token==null){if(mounted)setState(()=>error='ابتدا از بخش حساب کاربری وارد شوید');return;}
      final api=DeliveryService(token);
      await api.me();
      final result=await api.request('order-request',body:{'items':widget.items.map((k,v)=>MapEntry(k.toString(),v)),'options':widget.selections.map((k,v)=>MapEntry(k.toString(),v)),'address':address.text.trim(),'lat':location![0],'lng':location![1]});
      if(result is! Map || result['id'] is! int)throw Exception();
      if(mounted)Navigator.pop(context,result['id']);
    }catch(_){if(mounted)setState(()=>error='ثبت سفارش تایید نشد. قبل از تلاش مجدد، سفارش‌های حساب را بررسی کنید.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ثبت درخواست سفارش')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('هزینه ارسال و مبلغ نهایی پس از بررسی فروشگاه مشخص می‌شود. پرداخت آنلاین در این مرحله انجام نمی‌شود.'),
    TextField(controller:address,enabled:!busy,maxLines:3,decoration:const InputDecoration(labelText:'نشانی کامل تحویل')),
    OutlinedButton.icon(onPressed:busy?null:()async{
      final p=await Navigator.push<List<double>>(context,MaterialPageRoute(builder:(_)=>const MapPage()));
      if(mounted && p!=null)setState(()=>location=p);
    },icon:const Icon(Icons.location_on),label:Text(location==null?'انتخاب موقعیت':'تغییر موقعیت انتخاب شده')),
    if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
    FilledButton(onPressed:busy||location==null?null:submit,child:Text(busy?'در حال ثبت...':'ثبت درخواست سفارش')),
  ]));
}
