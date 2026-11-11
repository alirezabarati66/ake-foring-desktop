import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/store_product.dart';
import 'services/woocommerce_store_service.dart';

const teal=Color(0xFF01ADA5), grey=Color(0xFF57595B), bg=Color(0xFFF3F6F6);
void main()=>runApp(const AkeApp());
class AkeApp extends StatelessWidget { const AkeApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp(title:'AKE Forging',debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:teal),scaffoldBackgroundColor:bg),home:const Shell()); }

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  final Map<int, StoreProduct> cart = {};
  final Map<int, int> qty = {};

  void add(StoreProduct p) {
    setState(() {
      cart[p.id] = p;
      qty[p.id] = (qty[p.id] ?? 0) + 1;
    });
  }

  void change(int id, int delta) {
    setState(() {
      final next = (qty[id] ?? 0) + delta;
      if (next <= 0) {
        qty.remove(id);
        cart.remove(id);
      } else {
        qty[id] = next;
      }
    });
  }

  int get count => qty.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      Home(onAdd: add),
      Shop(onAdd: add),
      const News(),
      Basket(cart: cart, qty: qty, change: change),
      const Account(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'آریان کوب اسپادانا',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: () => setState(() => tab = 3),
              icon: Badge(
                label: Text(count.toString()),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                Container(
                  color: teal,
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'AKE FORGING\nآریان کوب اسپادانا',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                _menu(context, 'خانه', Icons.home, 0),
                _menu(context, 'فروشگاه', Icons.store, 1),
                _menu(context, 'اخبار و مقالات', Icons.article, 2),
                _menu(context, 'سبد خرید ($count)', Icons.shopping_cart, 3),
                _menu(context, 'حساب کاربری', Icons.person, 4),
                ListTile(
                  leading: const Icon(Icons.local_shipping, color: teal),
                  title: const Text('پنل پیک'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('پنل پیک با API امن وردپرس فعال خواهد شد.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(index: tab, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          backgroundColor: Colors.white,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              label: 'فروشگاه',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              label: 'اخبار',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'سبد خرید',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'حساب من',
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, String label, IconData icon, int index) {
    return ListTile(
      leading: Icon(icon, color: teal),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        setState(() => tab = index);
      },
    );
  }
}

class Home extends StatelessWidget{final ValueChanged<StoreProduct> onAdd;const Home({super.key,required this.onAdd});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:teal,borderRadius:BorderRadius.circular(20)),child:const Text('مهندسی قدرت، کیفیت در هر ضربه\nتولید قطعات فورج با دانش فنی روز',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.bold))),const SizedBox(height:16),const Text('محصولات فروشگاه',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),SizedBox(height:650,child:ProductList(onAdd:onAdd))]);}
class Shop extends StatelessWidget{final ValueChanged<StoreProduct> onAdd;const Shop({super.key,required this.onAdd});@override Widget build(BuildContext c)=>Column(children:[const Padding(padding:EdgeInsets.all(16),child:Text('فروشگاه محصولات',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),Expanded(child:ProductList(onAdd:onAdd))]);}
class ProductList extends StatefulWidget{final ValueChanged<StoreProduct> onAdd;const ProductList({super.key,required this.onAdd});@override State<ProductList> createState()=>_ProductListState();}
class _ProductListState extends State<ProductList>{final svc=WooCommerceStoreService();List<StoreProduct> items=[];bool busy=true;String? error;@override void initState(){super.initState();load();} @override void dispose(){svc.dispose();super.dispose();}
 Future<void> load()async{setState((){busy=true;error=null;});try{final r=await svc.fetchProducts();if(mounted)setState((){items=r;busy=false;});}catch(e){if(mounted)setState((){error=e.toString();busy=false;});}}
 @override Widget build(BuildContext c){if(busy)return const Center(child:CircularProgressIndicator(color:teal));if(error!=null)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),FilledButton(onPressed:load,child:const Text('تلاش مجدد'))]));return RefreshIndicator(onRefresh:load,child:GridView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:.62),itemBuilder:(c,i)=>ProductTile(p:items[i],add:widget.onAdd)));}}
class ProductTile extends StatelessWidget {
  final StoreProduct p;
  final ValueChanged<StoreProduct> add;
  const ProductTile({super.key, required this.p, required this.add});

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Detail(p: p, add: add)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: p.imageUrl.isEmpty
                      ? const Icon(Icons.precision_manufacturing, color: teal, size: 48)
                      : Image.network(
                          p.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.precision_manufacturing, color: teal, size: 48),
                        ),
                ),
              ),
              Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                p.sku.isNotEmpty ? 'کد: ${p.sku}' : 'شناسه: ${p.id}',
                style: const TextStyle(color: grey, fontSize: 11),
              ),
              Text(
                p.displayPrice.isNotEmpty ? p.displayPrice : 'استعلام قیمت',
                style: const TextStyle(color: teal, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: teal),
                  onPressed: () => _open(context),
                  child: const Text('مشاهده محصول'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Detail extends StatelessWidget {
  final StoreProduct p;
  final ValueChanged<StoreProduct> add;
  const Detail({super.key, required this.p, required this.add});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('جزئیات محصول')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SizedBox(
              height: 260,
              child: p.imageUrl.isEmpty
                  ? const Icon(Icons.precision_manufacturing, color: teal, size: 80)
                  : Image.network(
                      p.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.precision_manufacturing, color: teal, size: 80),
                    ),
            ),
            const SizedBox(height: 16),
            Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(p.sku.isNotEmpty ? 'کد فنی: ${p.sku}' : 'شناسه: ${p.id}'),
            Text(
              p.displayPrice.isNotEmpty ? p.displayPrice : 'استعلام قیمت',
              style: const TextStyle(color: teal, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(p.inStock ? 'موجود' : 'ناموجود'),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: teal),
              onPressed: p.inStock
                  ? () {
                      add(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('به سبد خرید اضافه شد')),
                      );
                    }
                  : null,
              child: const Text('افزودن به سبد خرید'),
            ),
          ],
        ),
      ),
    );
  }
}

class Basket extends StatelessWidget{final Map<int,StoreProduct> cart;final Map<int,int> qty;final void Function(int,int) change;const Basket({super.key,required this.cart,required this.qty,required this.change});@override Widget build(BuildContext c){final ids=qty.keys.toList();return Column(children:[const Padding(padding:EdgeInsets.all(16),child:Text('سبد خرید',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20))),Expanded(child:ids.isEmpty?const Center(child:Text('سبد خرید خالی است')):ListView(children:[for(final id in ids)if(cart[id]!=null)Card(color:Colors.white,child:ListTile(title:Text(cart[id]!.name),subtitle:Text(cart[id]!.displayPrice),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>change(id,-1),icon:const Icon(Icons.remove)),Text(qty[id].toString()),IconButton(onPressed:()=>change(id,1),icon:const Icon(Icons.add))])))])),if(ids.isNotEmpty)Padding(padding:const EdgeInsets.all(16),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('درگاه درون‌اپی نیازمند API سفارش و پرداخت وردپرس است.'))),style:FilledButton.styleFrom(backgroundColor:teal),child:const Text('ادامه و پرداخت'))))]);}}

class News extends StatefulWidget{const News({super.key});@override State<News> createState()=>_NewsState();}
class _NewsState extends State<News>{bool busy=true;String? error;List<dynamic> posts=[];@override void initState(){super.initState();load();}Future<void> load()async{setState(()=>{busy=true,error=null});try{final r=await http.get(Uri.parse('https://ake-forging.com/wp-json/wp/v2/posts?per_page=20&_embed')).timeout(const Duration(seconds:25));if(r.statusCode!=200)throw Exception('HTTP '+r.statusCode.toString());final data=jsonDecode(utf8.decode(r.bodyBytes)) as List<dynamic>;if(mounted)setState((){posts=data;busy=false;});}catch(e){if(mounted)setState(()=>{error=e.toString(),busy=false});}}
String clean(String s)=>s.replaceAll(RegExp(r'<[^>]*>'),'').replaceAll('&amp;','&').replaceAll('&nbsp;',' ');
String image(dynamic p){try{return p['_embedded']['wp:featuredmedia'][0]['source_url'].toString();}catch(_){return '';}}
@override Widget build(BuildContext c)=>Column(children:[const Padding(padding:EdgeInsets.all(16),child:Text('اخبار و مقالات',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),Expanded(child:busy?const Center(child:CircularProgressIndicator(color:teal)):error!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!),FilledButton(onPressed:load,child:const Text('تلاش مجدد'))])):ListView(children:[for(final p in posts)Card(color:Colors.white,child:ListTile(isThreeLine:true,leading:image(p).isEmpty?const Icon(Icons.article,color:teal):Image.network(image(p),width:60,height:60,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.article,color:teal)),title:Text(clean((p['title']?['rendered']??'').toString()),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text(clean((p['excerpt']?['rendered']??'').toString()),maxLines:3,overflow:TextOverflow.ellipsis),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Article(title:clean((p['title']?['rendered']??'').toString()),body:clean((p['content']?['rendered']??'').toString()))))))]))]);}
class Article extends StatelessWidget{final String title,body;const Article({super.key,required this.title,required this.body});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('مقاله')),body:ListView(padding:const EdgeInsets.all(20),children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:22)),const SizedBox(height:14),Text(body,style:const TextStyle(height:1.8))]));}
class Account extends StatelessWidget{const Account({super.key});@override Widget build(BuildContext c)=>const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('حساب کاربری\nورود پیامکی Digitss با اتصال API اختصاصی وردپرس فعال می‌شود.',textAlign:TextAlign.center)));}