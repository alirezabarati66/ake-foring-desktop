import 'dart:convert';
import 'auth_page.dart';
import 'storefront.dart';
import 'checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'models/store_product.dart';

const teal=Color(0xFF01ADA5), bg=Color(0xFFF3F6F6);
void main()=>runApp(const AkeApp());
class AkeApp extends StatelessWidget { const AkeApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp(title:'AKE Forging',debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:teal),scaffoldBackgroundColor:bg,appBarTheme:const AppBarTheme(elevation:0,scrolledUnderElevation:0,backgroundColor:Colors.white),cardTheme:CardThemeData(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.all(Radius.circular(18))))),home:const Shell()); }

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
      const AuthPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Row(children: [
            Image.network(
              'https://www.ake-forging.com/wp-content/uploads/2019/09/logo-300x51.png',
              width: 112, height: 30, fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.precision_manufacturing_rounded, color: teal),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('آریان کوب اسپادانا', overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
          ]),
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

class Basket extends StatelessWidget{final Map<int,StoreProduct> cart;final Map<int,int> qty;final void Function(int,int) change;const Basket({super.key,required this.cart,required this.qty,required this.change});@override Widget build(BuildContext c){final ids=qty.keys.toList();return Column(children:[const Padding(padding:EdgeInsets.all(16),child:Text('سبد خرید',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20))),Expanded(child:ids.isEmpty?const Center(child:Text('سبد خرید خالی است')):ListView(children:[for(final id in ids)if(cart[id]!=null)Card(color:Colors.white,child:ListTile(title:Text(cart[id]!.name),subtitle:Text(cart[id]!.displayPrice),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>change(id,-1),icon:const Icon(Icons.remove)),Text(qty[id].toString()),IconButton(onPressed:()=>change(id,1),icon:const Icon(Icons.add))])))])),if(ids.isNotEmpty)Padding(padding:const EdgeInsets.all(16),child:SizedBox(width:double.infinity,child:FilledButton(onPressed: () async {final snapshot=Map<int,int>.from(qty);final id=await Navigator.of(c).push<int>(MaterialPageRoute(builder:(_)=>CheckoutPage(items:snapshot)));if(id!=null && c.mounted){for(final entry in snapshot.entries){change(entry.key,-entry.value);}ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('درخواست سفارش شماره $id ثبت شد')));}},style:FilledButton.styleFrom(backgroundColor:teal),child:const Text('ادامه و ثبت درخواست'))))]);}}


class News extends StatefulWidget {
  const News({super.key});

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> {
  bool busy = true;
  String? error;
  List<dynamic> posts = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final r = await http
          .get(
            Uri.parse(
              'https://ake-forging.com/wp-json/wp/v2/posts?per_page=20&_embed',
            ),
          )
          .timeout(const Duration(seconds: 25));

      if (r.statusCode != 200) {
        throw Exception('HTTP ${r.statusCode}');
      }

      final data = jsonDecode(utf8.decode(r.bodyBytes)) as List<dynamic>;

      if (mounted) {
        setState(() {
          posts = data;
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          busy = false;
        });
      }
    }
  }

  String clean(String s) {
    return s
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');
  }

  String image(dynamic p) {
    try {
      return p['_embedded']['wp:featuredmedia'][0]['source_url'].toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext c) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'اخبار و مقالات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: busy
              ? const Center(
                  child: CircularProgressIndicator(color: teal),
                )
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!),
                          FilledButton(
                            onPressed: load,
                            child: const Text('تلاش مجدد'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        for (final p in posts)
                          Card(
                            color: Colors.white,
                            child: ListTile(
                              isThreeLine: true,
                              leading: image(p).isEmpty
                                  ? const Icon(Icons.article, color: teal)
                                  : Image.network(
                                      image(p),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.article, color: teal),
                                    ),
                              title: Text(
                                clean(
                                  (p['title']?['rendered'] ?? '').toString(),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                clean(
                                  (p['excerpt']?['rendered'] ?? '').toString(),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  c,
                                  MaterialPageRoute(
                                    builder: (_) => Article(
                                      title: clean(
                                        (p['title']?['rendered'] ?? '')
                                            .toString(),
                                      ),
                                      body: clean(
                                        (p['content']?['rendered'] ?? '')
                                            .toString(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class Article extends StatelessWidget{final String title,body;const Article({super.key,required this.title,required this.body});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('مقاله')),body:ListView(padding:const EdgeInsets.all(20),children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:22)),const SizedBox(height:14),Text(body,style:const TextStyle(height:1.8))]));}
