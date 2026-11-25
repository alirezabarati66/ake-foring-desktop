import 'dart:convert';
import 'auth_page.dart';
import 'storefront.dart';
import 'checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/store_product.dart';
import 'services/woocommerce_store_service.dart';

const teal=Color(0xFF01ADA5), grey=Color(0xFF57595B), bg=Color(0xFFF3F6F6);
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
          title: Row(children: const [
            Image(image: NetworkImage('https://www.ake-forging.com/wp-content/uploads/2019/09/logo-300x51.png'), width: 112, height: 30, fit: BoxFit.contain,
              errorBuilder: null),
            SizedBox(width: 8),
            Expanded(child: Text('آریان کوب اسپادانا', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
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
class Account extends StatefulWidget {
  const Account({super.key});
  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  // Demo-only customer profile; replace with authenticated WooCommerce data later.
  String name = 'مشتری نمونه AKE';
  String phone = '09XX-XXX-XX-01';
  String email = 'customer-demo@example.com';
  String company = 'مجموعه نمونه قطعات صنعتی';
  final addressController = TextEditingController();

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone == 'شماره موبایل ثبت نشده' ? '' : phone);
    final emailCtrl = TextEditingController(text: email);
    final companyCtrl = TextEditingController(text: company);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ویرایش اطلاعات حساب'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person_outline))),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل', prefixIcon: Icon(Icons.phone_outlined))),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل', prefixIcon: Icon(Icons.email_outlined))),
            TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'نام مجموعه (اختیاری)', prefixIcon: Icon(Icons.business_outlined))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('ذخیره')),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        name = nameCtrl.text.trim().isEmpty ? 'مشتری AKE' : nameCtrl.text.trim();
        phone = phoneCtrl.text.trim().isEmpty ? 'شماره موبایل ثبت نشده' : phoneCtrl.text.trim();
        email = emailCtrl.text.trim();
        company = companyCtrl.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اطلاعات در همین نشست برنامه به‌روزرسانی شد. برای ذخیره دائمی، اتصال حساب کاربری لازم است.')));
    }
    nameCtrl.dispose(); phoneCtrl.dispose(); emailCtrl.dispose(); companyCtrl.dispose();
  }

  void _showInfo(String title, String message) {
    showDialog<void>(context: context, builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(title: Text(title), content: Text(message), actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('متوجه شدم')),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [teal, Color(0xFF07847F)]), borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, color: teal, size: 34)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(phone, style: const TextStyle(color: Colors.white70)),
            if (company.isNotEmpty) Text(company, style: const TextStyle(color: Colors.white70)),
          ])),
          IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit_outlined, color: Colors.white), tooltip: 'ویرایش پروفایل'),
        ]),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: _editProfile,
          icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white),
          label: const Text('ویرایش اطلاعات حساب', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white70)),
        )),
      ]),
    ),
    const SizedBox(height: 18),
    const Text('حساب کاربری من', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _ProfileActionCard(icon: Icons.shopping_bag_outlined, title: 'سفارش‌ها', subtitle: '۲ سفارش آزمایشی', onTap: () => _showInfo('سفارش‌های من', 'AKE-DEMO-1002 | قطعه فورج سفارشی | در حال آماده‌سازی\n\nAKE-DEMO-1001 | مجموعه قطعات صنعتی | تحویل‌شده\n\nاین سفارش‌ها صرفاً نمایشی هستند و در سایت ثبت نشده‌اند.'))),
      const SizedBox(width: 9),
      Expanded(child: _ProfileActionCard(icon: Icons.location_on_outlined, title: 'نشانی‌ها', subtitle: 'نشانی پیش‌فرض نمونه', onTap: () => _showInfo('نشانی تحویل نمونه', 'اصفهان، شهرک صنعتی نمونه، خیابان تولید، پلاک آزمایشی\n\nاین نشانی ساختگی است و فقط برای نمایش رابط کاربری است.'))),
    ]),
    const SizedBox(height: 9),
    Row(children: [
      Expanded(child: _ProfileActionCard(icon: Icons.favorite_border, title: 'علاقه‌مندی‌ها', subtitle: '۳ محصول نمونه', onTap: () => _showInfo('علاقه‌مندی‌های نمونه', 'قطعات فورج فولادی\nقطعات خودرو\nقطعات صنعتی سفارشی\n\nاین فهرست فعلاً نمایشی است.'))),
      const SizedBox(width: 9),
      Expanded(child: _ProfileActionCard(icon: Icons.support_agent_outlined, title: 'پشتیبانی', subtitle: 'پیگیری و راهنمایی', onTap: () => _showInfo('پشتیبانی AKE', 'موضوع نمونه: پیگیری سفارش AKE-DEMO-1002\nوضعیت: درخواست آزمایشی\n\nاطلاعات تماس واقعی پس از اتصال مسیر پشتیبانی درج می‌شود.'))),
    ]),
    const SizedBox(height: 18),
    const Text('اطلاعات تماس', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Card(color: Colors.white, elevation: 0, child: Column(children: [
      ListTile(leading: const Icon(Icons.phone_outlined, color: teal), title: const Text('شماره موبایل'), subtitle: Text(phone)),
      const Divider(height: 1, indent: 16, endIndent: 16),
      ListTile(leading: const Icon(Icons.email_outlined, color: teal), title: const Text('ایمیل'), subtitle: Text(email.isEmpty ? 'ثبت نشده' : email)),
      const Divider(height: 1, indent: 16, endIndent: 16),
      ListTile(leading: const Icon(Icons.business_outlined, color: teal), title: const Text('مجموعه'), subtitle: Text(company.isEmpty ? 'ثبت نشده' : company)),
    ])),
    const SizedBox(height: 12),
    const Text('توجه: تغییرات این صفحه فعلاً در حافظه موقت برنامه نگهداری می‌شوند. برای ورود امن، ذخیره دائمی اطلاعات، سفارش‌ها و نشانی‌ها باید API سایت متصل شود.', style: TextStyle(color: grey, height: 1.7, fontSize: 12)),
  ]);
}

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ProfileActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: teal.withValues(alpha: .1), child: Icon(icon, color: teal)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: grey, fontSize: 11)),
      ]),
    )),
  );
}

class _StatBox extends StatelessWidget {
  final IconData icon; final String label;
  const _StatBox(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [Icon(icon, color: teal), const SizedBox(height: 8), const Text('—', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: grey))]));
}

class _AccountTile extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _AccountTile(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: teal.withValues(alpha: .1), child: Icon(icon, color: teal)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این بخش با اتصال API فعال می‌شود.')),
      ),
    ),
  );
}

class CourierPanel extends StatefulWidget {
  const CourierPanel({super.key});
  @override
  State<CourierPanel> createState() => _CourierPanelState();
}

class _CourierPanelState extends State<CourierPanel> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    backgroundColor: bg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('پنل پیک AKE'),
      actions: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('آفلاین', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    ),
    body: IndexedStack(index: tab, children: [_missions(), _history(), _profile()]),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), backgroundColor: Colors.white, destinations: const [
      NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'مأموریت‌ها'),
      NavigationDestination(icon: Icon(Icons.history), label: 'سوابق'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'حساب پیک'),
    ]),
  ));

  Widget _missions() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: teal, borderRadius: BorderRadius.circular(20)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('سلام، پیک عزیز!', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
      SizedBox(height: 5), Text('مأموریت‌های تحویل خود را مدیریت کنید.', style: TextStyle(color: Colors.white70)),
      SizedBox(height: 18), Row(children: [Expanded(child: _CourierStat('ماموریت امروز')), SizedBox(width: 10), Expanded(child: _CourierStat('تحویل موفق'))]),
    ])),
    const SizedBox(height: 20), const Text('مأموریت‌های فعال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
    Card(color: Colors.white, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('مأموریت AKE-DEMO-1002', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.person_pin_circle_outlined, color: teal), title: Text('تحویل‌گیرنده: مشتری نمونه AKE'), subtitle: Text('شماره تماس: 09XX-XXX-XX-01')),
      const Divider(),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.location_on_outlined, color: teal), title: Text('مقصد آزمایشی'), subtitle: Text('اصفهان، شهرک صنعتی نمونه، خیابان تولید')),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.inventory_2_outlined, color: teal), title: Text('محموله'), subtitle: Text('یک بسته قطعات فورج · سفارش AKE-DEMO-1002')),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('این مأموریت فقط نمایشی است؛ ثبت واقعی پس از اتصال API فعال می‌شود.'))), child: const Text('تأیید دریافت بسته (نمایشی)'), style: FilledButton.styleFrom(backgroundColor: teal))),
    ]))),
    const SizedBox(height: 14), const _MissionStep(Icons.inventory_2_outlined, 'دریافت سفارش از مجموعه', 'تأیید دریافت بسته'),
    const _MissionStep(Icons.map_outlined, 'مسیریابی به مشتری', 'نمایش نشانی و مسیر روی نقشه'),
    const _MissionStep(Icons.password_outlined, 'تأیید تحویل', 'ثبت کد مشتری و تکمیل سفارش'),
  ]);
  Widget _history() => ListView(padding: const EdgeInsets.all(16), children: [const Text('سوابق تحویل آزمایشی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Card(color: Colors.white, elevation: 0, child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFE4F5F2), child: Icon(Icons.check_circle, color: teal)), title: const Text('AKE-DEMO-1001'), subtitle: const Text('تحویل موفق · مشتری نمونه AKE\nقطعات صنعتی · مقصد آزمایشی اصفهان'), trailing: const Text('دیروز', style: TextStyle(color: grey, fontSize: 11)))), const SizedBox(height: 8), const Text('این سابقه ساختگی است و در سفارش‌های واقعی سایت وجود ندارد.', style: TextStyle(color: grey, fontSize: 12))]);
  Widget _profile() => const CourierProfile();
}

class CourierProfile extends StatefulWidget {
  const CourierProfile({super.key});
  @override
  State<CourierProfile> createState() => _CourierProfileState();
}

class _CourierProfileState extends State<CourierProfile> {
  // Demo-only courier profile; all operational data is simulated locally.
  String name = 'امیر رضایی (پیک آزمایشی)';
  String phone = '09XX-XXX-XX-02';
  String vehicle = 'موتورسیکلت';
  String plate = 'پلاک آزمایشی';
  bool online = true;

  Future<void> _edit() async {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    final vehicleCtrl = TextEditingController(text: vehicle);
    final plateCtrl = TextEditingController(text: plate);
    final saved = await showDialog<bool>(context: context, builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('ویرایش پروفایل پیک'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person_outline))),
          TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل', prefixIcon: Icon(Icons.phone_outlined))),
          TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'نوع وسیله نقلیه', prefixIcon: Icon(Icons.two_wheeler_outlined))),
          TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'شماره پلاک', prefixIcon: Icon(Icons.confirmation_number_outlined))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ذخیره')),
        ],
      ),
    ));
    if (saved == true && mounted) {
      setState(() {
        name = nameCtrl.text.trim().isEmpty ? 'پیک AKE' : nameCtrl.text.trim();
        phone = phoneCtrl.text.trim();
        vehicle = vehicleCtrl.text.trim().isEmpty ? 'ثبت نشده' : vehicleCtrl.text.trim();
        plate = plateCtrl.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اطلاعات در همین نشست برنامه به‌روزرسانی شد؛ ذخیره دائمی نیازمند اتصال API است.')));
    }
    nameCtrl.dispose(); phoneCtrl.dispose(); vehicleCtrl.dispose(); plateCtrl.dispose();
  }

  Widget _detail(IconData icon, String title, String value) => ListTile(
    leading: CircleAvatar(backgroundColor: teal.withValues(alpha: .1), child: Icon(icon, color: teal)),
    title: Text(title, style: const TextStyle(fontSize: 12, color: grey)),
    subtitle: Text(value.isEmpty ? 'ثبت نشده' : value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
  );

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [teal, Color(0xFF07847F)]), borderRadius: BorderRadius.circular(22)), child: Column(children: [
      const CircleAvatar(radius: 37, backgroundColor: Colors.white, child: Icon(Icons.delivery_dining, color: teal, size: 42)),
      const SizedBox(height: 10),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(phone.isEmpty ? 'شماره موبایل ثبت نشده' : phone, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 10, color: online ? Colors.lightGreenAccent : Colors.orangeAccent),
        const SizedBox(width: 7),
        Text(online ? 'آماده دریافت مأموریت' : 'در حال حاضر آفلاین', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ])),
    ])),
    const SizedBox(height: 16),
    Card(color: Colors.white, elevation: 0, child: Column(children: [
      _detail(Icons.person_outline, 'نام و نام خانوادگی', name),
      const Divider(height: 1, indent: 16, endIndent: 16),
      _detail(Icons.phone_outlined, 'شماره موبایل', phone),
      const Divider(height: 1, indent: 16, endIndent: 16),
      _detail(Icons.two_wheeler_outlined, 'وسیله نقلیه', vehicle),
      const Divider(height: 1, indent: 16, endIndent: 16),
      _detail(Icons.confirmation_number_outlined, 'شماره پلاک', plate),
    ])),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined), label: const Text('ویرایش اطلاعات پیک'), style: FilledButton.styleFrom(backgroundColor: teal, padding: const EdgeInsets.symmetric(vertical: 14))),
    const SizedBox(height: 10),
    SwitchListTile(
      value: online,
      onChanged: (v) => setState(() => online = v),
      activeColor: teal,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      secondary: const Icon(Icons.wifi_tethering, color: teal),
      title: const Text('وضعیت فعالیت'),
      subtitle: Text(online ? 'آماده دریافت مأموریت (نمایشی)' : 'آفلاین (نمایشی)'),
    ),
    const SizedBox(height: 12),
    const Text('اطلاعات این پروفایل فعلاً روی همین صفحه و به‌صورت موقت نگهداری می‌شود. برای احراز هویت پیک، ذخیره اطلاعات، وضعیت آنلاین واقعی و دریافت مأموریت‌ها باید سرویس امن سایت متصل شود.', style: TextStyle(color: grey, height: 1.7, fontSize: 12)),
  ]);
}

class _CourierStat extends StatelessWidget {
  final String label; const _CourierStat(this.label);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Text('—', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))]));
}

class _MissionStep extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _MissionStep(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(leading: CircleAvatar(backgroundColor: teal.withValues(alpha: .1), child: Icon(icon, color: teal)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle)));
}