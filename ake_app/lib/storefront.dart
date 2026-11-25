import 'package:flutter/material.dart';
import 'models/store_product.dart';
import 'services/woocommerce_store_service.dart';

const _ink = Color(0xFF142D39);
const _accent = Color(0xFF00A99D);
const _muted = Color(0xFF637785);
const _panel = Color(0xFFF3F7F8);

typedef AddProduct = void Function(StoreProduct product, int quantity, Map<String, String> selectedAttributes);

class Home extends StatelessWidget {
  final AddProduct onAdd;
  final ValueChanged<int> onNavigate;
  const Home({super.key, required this.onAdd, required this.onNavigate});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _WelcomeHeading(),
          const SizedBox(height: 16),
          SizedBox(height: 205, child: PageView(children: [
            _CampaignBanner(
              title: 'قدرت در هر قطعه',
              subtitle: 'فناوری فورج، دقت تولید و کیفیت صنعتی',
              label: 'آریان کوب اسپادانا',
              colors: [_ink, Color(0xFF246A73)],
              imageUrl: 'https://images.unsplash.com/photo-1661571094656-1887a27885db?fit=crop&w=1100&h=560&q=78&fm=jpg',
            ),
            _CampaignBanner(
              title: 'تأمین مطمئن قطعات',
              subtitle: 'محصولات تخصصی برای صنعت خودرو',
              label: 'مجموعه محصولات',
              colors: [Color(0xFF006F6D), Color(0xFF17B6A8)],
              imageUrl: 'https://images.unsplash.com/photo-1572367417026-d26cb9c9b922?fit=crop&w=1100&h=560&q=78&fm=jpg',
            ),
            _CampaignBanner(
              title: 'از انتخاب تا سفارش',
              subtitle: 'مشخصات فنی و اطلاعات کالا در یک نگاه',
              label: 'خرید هوشمند',
              colors: [Color(0xFF2D415E), Color(0xFF647C95)],
              imageUrl: 'https://images.unsplash.com/photo-1600683729960-0b586e23ec3b?fit=crop&w=1100&h=560&q=78&fm=jpg',
            ),
          ])),
          const SizedBox(height: 19),
          const _SectionHeading(title: 'محصولات منتخب', subtitle: 'مشاهده کالاها و جزئیات فنی'),
        ]),
      )),
      SliverToBoxAdapter(child: ProductList(onAdd: onAdd, onNavigate: onNavigate, embedded: true)),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ],
  );
}

class _WelcomeHeading extends StatelessWidget {
  const _WelcomeHeading();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('سلام، به آریان کوب خوش آمدید', style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20)),
    SizedBox(height: 5),
    Text('مرجع مشاهده و سفارش قطعات صنعتی', style: TextStyle(color: _muted, fontSize: 12)),
  ]);
}

class _SectionHeading extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeading({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 33, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(8))),
    const SizedBox(width: 9),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w900)),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
    ])),
  ]);
}

class _CampaignBanner extends StatelessWidget {
  final String title, subtitle, label;
  final List<Color> colors;
  final String imageUrl;
  const _CampaignBanner({required this.title, required this.subtitle, required this.label, required this.colors, required this.imageUrl});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsetsDirectional.only(end: 9),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors, begin: Alignment.topRight, end: Alignment.bottomLeft),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(children: [
      Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink())),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withValues(alpha: .72), colors.last.withValues(alpha: .38)], begin: Alignment.centerRight, end: Alignment.centerLeft)))),
      Positioned(left: 14, bottom: -34, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .12), width: 26)))),
      Padding(padding: const EdgeInsets.all(23), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 13),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SizedBox(width: 205, child: Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5))),
        ],
      )),
    ]),
  );
}

class Shop extends StatelessWidget {
  final AddProduct onAdd;
  final ValueChanged<int> onNavigate;
  const Shop({super.key, required this.onAdd, required this.onNavigate});
  @override
  Widget build(BuildContext context) => Column(children: [
    const Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 5),
      child: _SectionHeading(title: 'فروشگاه آریان کوب', subtitle: 'دسته‌بندی تخصصی قطعات خودرو'),
    ),
    Expanded(child: ProductList(onAdd: onAdd, onNavigate: onNavigate)),
  ]);
}

class ProductList extends StatefulWidget {
  final AddProduct onAdd;
  final ValueChanged<int> onNavigate;
  final bool embedded;
  const ProductList({super.key, required this.onAdd, required this.onNavigate, this.embedded = false});
  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final svc = WooCommerceStoreService();
  final items = <StoreProduct>[];
  bool busy = false, more = true;
  int page = 0;
  String? error;
  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { svc.dispose(); super.dispose(); }
  Future<void> load({bool refresh = false}) async {
    if (busy) return;
    if (refresh) { items.clear(); page = 0; more = true; }
    if (!more) return;
    setState(() { busy = true; error = null; });
    try {
      final result = await svc.fetchProductsPage(page: page + 1, perPage: 20);
      if (!mounted) return;
      setState(() {
        page++;
        items.addAll(result);
        more = result.length == 20;
        busy = false;
      });
    } catch (e) {
      if (mounted) setState(() { busy = false; error = e.toString(); });
    }
  }
  @override
  Widget build(BuildContext context) {
    final listing = LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 850 ? 4 : constraints.maxWidth >= 580 ? 3 : 2;
      return Column(children: [
        if (items.isEmpty && busy) const Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()),
        if (items.isEmpty && !busy && error == null) const Padding(padding: EdgeInsets.all(32), child: Text('محصولی یافت نشد')),
        if (items.isNotEmpty) GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) => ProductTile(p: items[index], add: widget.onAdd, onNavigate: widget.onNavigate),
        ),
        if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: const TextStyle(color: Colors.red))),
        if (more || error != null) Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 15),
          child: SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: busy ? null : load,
            child: Text(busy ? 'در حال بارگذاری...' : error != null ? 'تلاش مجدد' : 'نمایش محصولات بیشتر'),
          )),
        ),
      ]);
    });
    if (widget.embedded) return listing;
    return RefreshIndicator(
      onRefresh: () => load(refresh: true),
      child: ListView(children: [listing]),
    );
  }
}

class ProductTile extends StatelessWidget {
  final StoreProduct p;
  final AddProduct add;
  final ValueChanged<int> onNavigate;
  const ProductTile({super.key, required this.p, required this.add, required this.onNavigate});

  Future<void> _chooseQuantity(BuildContext context) async {
    var quantity = 1;
    final selected = <String, String>{for (final a in p.attributes) if (a.values.isNotEmpty) a.name: a.values.first};
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('افزودن به سبد خرید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink))), IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))]),
            ListTile(contentPadding: EdgeInsets.zero, leading: p.imageUrl.isEmpty ? const Icon(Icons.settings) : Image.network(p.imageUrl, width: 58, height: 58, fit: BoxFit.contain), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(p.displayPrice.isEmpty ? 'استعلام قیمت' : p.displayPrice)),
            if (p.type == 'variable') ...[
              const Text('این کالا دارای وارییشن است و تا اتصال شناسه دقیق هر وارییشن، افزودن آن غیرفعال است.', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
            ] else ...[
              for (final attribute in p.attributes.where((a) => a.values.isNotEmpty).take(5))
                Padding(padding: const EdgeInsets.only(bottom: 9), child: DropdownButtonFormField<String>(
                  value: selected[attribute.name],
                  decoration: InputDecoration(labelText: attribute.name, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: attribute.values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) { if (v != null) setSheet(() => selected[attribute.name] = v); },
                )),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('تعداد مورد نیاز', style: TextStyle(fontWeight: FontWeight.bold))),
              IconButton(onPressed: quantity > 1 ? () => setSheet(() => quantity--) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              IconButton(onPressed: quantity < 99 ? () => setSheet(() => quantity++) : null, icon: const Icon(Icons.add_circle_outline)),
            ]),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: p.type == 'variable' ? null : () { add(p, quantity, Map<String, String>.from(selected)); Navigator.pop(ctx); },
              icon: const Icon(Icons.shopping_bag_outlined), label: const Text('تأیید و افزودن به سبد'),
            )),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, elevation: 0, borderRadius: BorderRadius.circular(18), clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Detail(p: p, add: add, onNavigate: onNavigate))),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4EBEF)), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(
            width: double.infinity, margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(13)),
            child: p.imageUrl.isEmpty ? const Icon(Icons.precision_manufacturing_rounded, color: _accent, size: 48)
              : Image.network(p.imageUrl, fit: BoxFit.contain, cacheWidth: 480, errorBuilder: (_, _, _) => const Icon(Icons.precision_manufacturing_rounded, color: _accent, size: 48)),
          )),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, height: 1.3, fontSize: 12, fontWeight: FontWeight.w800))),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(p.displayPrice.isNotEmpty ? p.displayPrice : 'استعلام قیمت', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w900))),
          const SizedBox(height: 7),
          Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: SizedBox(width: double.infinity, height: 36, child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _ink, padding: const EdgeInsets.symmetric(horizontal: 5), visualDensity: VisualDensity.compact),
            onPressed: p.inStock && p.type != 'variable' ? () => _chooseQuantity(context) : null,
            icon: const Icon(Icons.add_shopping_cart, size: 15), label: const Text('افزودن به سبد', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ))),
        ]),
      ),
    ),
  );
}

class Detail extends StatelessWidget {
  final StoreProduct p;
  final AddProduct add;
  final ValueChanged<int> onNavigate;
  const Detail({super.key, required this.p, required this.add, required this.onNavigate});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _panel,
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        title: const Text('جزئیات محصول', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: () => onNavigate(3), icon: const Icon(Icons.shopping_bag_outlined))],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 20), children: [
        Container(
          height: 255,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: p.imageUrl.isEmpty ? const Icon(Icons.precision_manufacturing, color: _accent, size: 84)
            : Image.network(p.imageUrl, cacheWidth: 900, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.precision_manufacturing, color: _accent, size: 84)),
        ),
        const SizedBox(height: 16),
        Text(p.name, style: const TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(p.sku.isEmpty ? 'شناسه: ' + p.id.toString() : 'کد فنی: ' + p.sku, style: const TextStyle(color: _muted)),
        const SizedBox(height: 12),
        Text(p.displayPrice.isEmpty ? 'استعلام قیمت' : p.displayPrice, style: const TextStyle(color: _accent, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 7),
        Text(p.inStock ? 'موجود در انبار' : 'ناموجود', style: TextStyle(color: p.inStock ? _accent : Colors.red)),
        const SizedBox(height: 18),
        if (p.shortDescription.isNotEmpty) ...[
          const _SectionHeading(title: 'معرفی کوتاه', subtitle: 'اطلاعات فروشگاه'), const SizedBox(height: 8),
          ProductHtml(html: p.shortDescription), const SizedBox(height: 18),
        ],
        if (p.description.isNotEmpty) ...[
          const _SectionHeading(title: 'توضیحات و مشخصات فنی', subtitle: 'برگرفته از محتوای محصول در وردپرس'), const SizedBox(height: 8),
          ProductHtml(html: p.description), const SizedBox(height: 18),
        ],
        if (p.attributes.isNotEmpty) ...[
          const _SectionHeading(title: 'ویژگی‌های محصول', subtitle: 'اطلاعات ثبت‌شده در فروشگاه'), const SizedBox(height: 9),
          Table(border: TableBorder.all(color: const Color(0xFFE2E9EB), borderRadius: BorderRadius.circular(8)),
            children: [for (final item in p.attributes) TableRow(children: [_tableCell(item.name, bold: true), _tableCell(item.values.join('، '))])]),
          const SizedBox(height: 18),
        ],
        SizedBox(width: double.infinity, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.all(15)),
          onPressed: p.inStock && p.type != 'variable' ? () async {
            var count = 1;
            final selected = <String, String>{for (final a in p.attributes) if (a.values.isNotEmpty) a.name: a.values.first};
            final ok = await showModalBottomSheet<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Directionality(textDirection: TextDirection.rtl, child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('تعداد مورد نیاز', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              for (final attribute in p.attributes.where((a) => a.values.isNotEmpty).take(5))
                DropdownButtonFormField<String>(value: selected[attribute.name], decoration: InputDecoration(labelText: attribute.name), items: attribute.values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) selected[attribute.name] = v; }),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: count > 1 ? () => setSheet(() => count--) : null, icon: const Icon(Icons.remove_circle_outline)),
                Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                IconButton(onPressed: count < 99 ? () => setSheet(() => count++) : null, icon: const Icon(Icons.add_circle_outline)),
              ]),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('افزودن به سبد خرید'))),
            ])))));
            if (ok == true) { add(p, count, Map<String, String>.from(selected)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('به سبد خرید اضافه شد'))); }
          } : null,
          icon: const Icon(Icons.shopping_bag_outlined), label: const Text('افزودن به سبد خرید'),
        )),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) { Navigator.of(context).pop(); onNavigate(index); },
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.store_outlined), label: 'فروشگاه'),
          NavigationDestination(icon: Icon(Icons.article_outlined), label: 'اخبار'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'سبد خرید'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حساب من'),
        ],
      ),
    ),
  );
}

Widget _tableCell(String text, {bool bold = false}) => Padding(
  padding: const EdgeInsets.all(10),
  child: Text(text, style: TextStyle(fontSize: 12, color: _ink, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
);

/// Lightweight HTML display for WooCommerce product descriptions including specification tables.
class ProductHtml extends StatelessWidget {
  final String html;
  const ProductHtml({super.key, required this.html});
  @override
  Widget build(BuildContext context) {
    final tables = RegExp(r'<table\b[^>]*>[\s\S]*?</table>', caseSensitive: false);
    final segments = <Widget>[];
    var index = 0;
    for (final match in tables.allMatches(html)) {
      _addContent(segments, html.substring(index, match.start));
      final rows = <TableRow>[];
      for (final row in RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false).allMatches(match.group(0)!)) {
        final cells = RegExp(r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>', caseSensitive: false)
          .allMatches(row.group(1)!).map((m) => _strip(m.group(1)!)).toList();
        if (cells.isNotEmpty) rows.add(TableRow(children: [
          for (final cell in cells) _tableCell(cell),
        ]));
      }
      if (rows.isNotEmpty) {
        final count = rows.map((r) => r.children.length).reduce((a, b) => a > b ? a : b);
        segments.add(Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: count * 135.0, child: Table(
            border: TableBorder.all(color: const Color(0xFFDCE6E8)),
            children: [for (final row in rows) TableRow(children: [
              ...row.children, for (var i = row.children.length; i < count; i++) _tableCell(''),
            ])],
          )),
        )));
      }
      index = match.end;
    }
    _addContent(segments, html.substring(index));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: segments);
  }
  static String _strip(String raw) {
    return raw.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ').replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&').replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n').trim();
  }
  static void _addContent(List<Widget> children, String fragment) {
    final images = RegExp(r'<img\b[^>]*src=["\x27]([^"\x27]+)["\x27]', caseSensitive: false)
        .allMatches(fragment).map((m) => m.group(1)!).toList();
    final text = _strip(fragment);
    if (text.isNotEmpty) children.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: const TextStyle(color: _ink, height: 1.9, fontSize: 13)),
    ));
    for (final image in images) {
      final address = image.startsWith('http://')
        ? image.replaceFirst('http://', 'https://') : image;
      if (Uri.tryParse(address)?.hasScheme == true) {
        children.add(Padding(padding: const EdgeInsets.symmetric(vertical: 9),
          child: Image.network(address, cacheWidth: 900,
            errorBuilder: (_, _, _) => const SizedBox.shrink())));
      }
    }
  }
}
