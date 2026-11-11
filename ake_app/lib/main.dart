import 'package:flutter/material.dart';

const Color akeTeal = Color(0xFF01ADA5);
const Color akeGrey = Color(0xFF57595B);
const Color akeInk = Color(0xFF202426);
const Color akeBackground = Color(0xFFF3F6F6);

void main() => runApp(const AkeApp());

class AkeApp extends StatelessWidget {
  const AkeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AKE Forging',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: akeTeal), scaffoldBackgroundColor: akeBackground),
    home: const AkeShell(),
  );
}

class AkeShell extends StatefulWidget {
  const AkeShell({super.key});
  @override
  State<AkeShell> createState() => _AkeShellState();
}

class _AkeShellState extends State<AkeShell> {
  int selectedIndex = 0;
  final pages = const [HomePage(), CategoriesPage(), OrdersPage(), AccountPage()];
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: SafeArea(child: IndexedStack(index: selectedIndex, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (v) => setState(() => selectedIndex = v),
        backgroundColor: Colors.white,
        indicatorColor: akeTeal.withValues(alpha: .13),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'دسته‌بندی'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'سفارش‌ها'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حساب من'),
        ],
      ),
    ),
  );
}

class Product {
  final String title, code, category;
  final IconData icon;
  const Product(this.title, this.code, this.category, this.icon);
}
const products = [
  Product('قطعات فورج صنعتی', 'AKE-1001', 'صنعتی', Icons.settings),
  Product('قطعات خودرو', 'AKE-1002', 'خودرو', Icons.directions_car),
  Product('قطعات سفارشی', 'AKE-1003', 'سفارشی', Icons.precision_manufacturing),
  Product('قالب و تجهیزات', 'AKE-1004', 'تجهیزات', Icons.handyman),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final controller = TextEditingController();
  String query = '';
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) {
      final q = query.trim().toLowerCase();
      return p.title.toLowerCase().contains(q) || p.code.toLowerCase().contains(q) || p.category.toLowerCase().contains(q);
    }).toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: akeTeal, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.precision_manufacturing, color: Colors.white, size: 28)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('آریان کوب اسپادانا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: akeInk)),
            SizedBox(height: 3), Text('AKE FORGING', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: akeGrey, fontWeight: FontWeight.bold)),
          ])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
        ]),
      )),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 18), child: TextField(
        controller: controller, onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(hintText: 'جست‌وجوی محصول یا کد فنی...', prefixIcon: const Icon(Icons.search, color: akeTeal), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16)),
      ))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [akeTeal, Color(0xFF087E79)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مهندسی قدرت،\nکیفیت در هر ضربه', style: TextStyle(color: Colors.white, fontSize: 23, height: 1.5, fontWeight: FontWeight.w900)),
          SizedBox(height: 10), Text('تولید قطعات فورج با تکیه بر دانش فنی و فناوری روز', style: TextStyle(color: Colors.white, height: 1.7)),
          SizedBox(height: 18), Row(children: [Icon(Icons.verified_outlined, color: Colors.white), SizedBox(width: 7), Text('کیفیت و دقت در فرآیند تولید', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        ]),
      ))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 26, 20, 12), child: Row(children: [
        const Expanded(child: Text('دسته‌بندی محصولات', style: TextStyle(color: akeInk, fontSize: 17, fontWeight: FontWeight.w900))),
        TextButton(onPressed: () {}, child: const Text('مشاهده همه')),
      ]))),
      SliverToBoxAdapter(child: SizedBox(height: 106, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: const [
        CategoryTile(title: 'قطعات صنعتی', icon: Icons.settings), CategoryTile(title: 'خودرو', icon: Icons.directions_car), CategoryTile(title: 'سفارشی', icon: Icons.build), CategoryTile(title: 'تجهیزات', icon: Icons.handyman),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 26, 20, 12), child: Text(query.isEmpty ? 'محصولات منتخب' : 'نتایج جست‌وجو', style: const TextStyle(color: akeInk, fontSize: 17, fontWeight: FontWeight.w900)))),
      if (filtered.isEmpty) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('محصولی با این مشخصات پیدا نشد.'))))
      else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) => ProductCard(product: filtered[index]), childCount: filtered.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .82),
      )),
    ]);
  }
}

class CategoryTile extends StatelessWidget {
  final String title; final IconData icon;
  const CategoryTile({super.key, required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Container(width: 91, margin: const EdgeInsets.only(left: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: akeTeal, size: 27), const SizedBox(height: 9), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]));
}

class ProductCard extends StatelessWidget {
  final Product product; const ProductCard({super.key, required this.product});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: akeTeal.withValues(alpha: .09), borderRadius: BorderRadius.circular(13)), child: Icon(product.icon, color: akeTeal, size: 48))),
    const SizedBox(height: 10), Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
    const SizedBox(height: 4), Text('کد: ${product.code}', style: const TextStyle(color: akeGrey, fontSize: 10)), const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: akeTeal, padding: const EdgeInsets.symmetric(vertical: 9)), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بخش استعلام قیمت به‌زودی فعال می‌شود.'))), child: const Text('استعلام قیمت'))),
  ]));
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext context) {
    const entries = [('قطعات صنعتی', Icons.settings), ('قطعات خودرو', Icons.directions_car), ('قطعات سفارشی', Icons.precision_manufacturing), ('قالب و تجهیزات', Icons.handyman)];
    return PageScaffold(title: 'دسته‌بندی محصولات', child: ListView(padding: const EdgeInsets.all(20), children: [for (final e in entries) Card(color: Colors.white, child: ListTile(leading: CircleAvatar(backgroundColor: akeTeal.withValues(alpha: .12), child: Icon(e.$2, color: akeTeal)), title: Text(e.$1), trailing: const Icon(Icons.chevron_left), onTap: () {}))]));
  }
}
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const PageScaffold(title: 'سفارش‌های من', child: EmptyState(icon: Icons.receipt_long_outlined, title: 'هنوز سفارشی ثبت نشده است', subtitle: 'پس از ثبت سفارش، وضعیت آن را در این بخش مشاهده می‌کنید.'));
}
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => PageScaffold(title: 'حساب کاربری', child: ListView(padding: const EdgeInsets.all(20), children: const [
    ListTile(leading: Icon(Icons.person_outline, color: akeTeal), title: Text('اطلاعات حساب کاربری'), trailing: Icon(Icons.chevron_left)), Divider(),
    ListTile(leading: Icon(Icons.location_on_outlined, color: akeTeal), title: Text('نشانی‌های من'), trailing: Icon(Icons.chevron_left)), Divider(),
    ListTile(leading: Icon(Icons.support_agent, color: akeTeal), title: Text('پشتیبانی و تماس با ما'), trailing: Icon(Icons.chevron_left)),
  ]));
}
class PageScaffold extends StatelessWidget {
  final String title; final Widget child;
  const PageScaffold({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12), child: Text(title, style: const TextStyle(color: akeInk, fontSize: 21, fontWeight: FontWeight.w900))), Expanded(child: child)]);
}
class EmptyState extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 58, color: akeTeal), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: akeGrey, height: 1.7))])));
}
