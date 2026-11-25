import 'package:flutter/material.dart';
import 'models/store_product.dart';
import 'services/woocommerce_store_service.dart';

const _ink = Color(0xFF142D39);
const _accent = Color(0xFF00A99D);
const _muted = Color(0xFF637785);
const _panel = Color(0xFFF3F7F8);

class Home extends StatelessWidget {
  final ValueChanged<StoreProduct> onAdd;
  const Home({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _WelcomeHeading(),
          const SizedBox(height: 16),
          SizedBox(height: 205, child: PageView(children: const [
            _CampaignBanner(
              title: 'قدرت در هر قطعه',
              subtitle: 'فناوری فورج، دقت تولید و کیفیت صنعتی',
              label: 'آریان کوب اسپادانا',
              colors: [_ink, Color(0xFF246A73)],
              icon: Icons.precision_manufacturing_rounded,
            ),
            _CampaignBanner(
              title: 'تأمین مطمئن قطعات',
              subtitle: 'محصولات تخصصی برای صنعت خودرو',
              label: 'مجموعه محصولات',
              colors: [Color(0xFF006F6D), Color(0xFF17B6A8)],
              icon: Icons.settings_suggest_rounded,
            ),
            _CampaignBanner(
              title: 'از انتخاب تا سفارش',
              subtitle: 'مشخصات فنی و اطلاعات کالا در یک نگاه',
              label: 'خرید هوشمند',
              colors: [Color(0xFF2D415E), Color(0xFF647C95)],
              icon: Icons.inventory_2_rounded,
            ),
          ])),
          const SizedBox(height: 19),
          const _SectionHeading(title: 'محصولات منتخب', subtitle: 'مشاهده کالاها و جزئیات فنی'),
        ]),
      )),
      SliverToBoxAdapter(child: ProductList(onAdd: onAdd, embedded: true)),
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
  final IconData icon;
  const _CampaignBanner({required this.title, required this.subtitle, required this.label, required this.colors, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsetsDirectional.only(end: 9),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors, begin: Alignment.topRight, end: Alignment.bottomLeft),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(children: [
      Positioned(left: -30, top: -40, child: Icon(icon, size: 230, color: Colors.white.withValues(alpha: .13))),
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
  final ValueChanged<StoreProduct> onAdd;
  const Shop({super.key, required this.onAdd});
  @override
  Widget build(BuildContext context) => Column(children: [
    const Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 5),
      child: _SectionHeading(title: 'فروشگاه آریان کوب', subtitle: 'دسته‌بندی تخصصی قطعات خودرو'),
    ),
    Expanded(child: ProductList(onAdd: onAdd)),
  ]);
}

class ProductList extends StatefulWidget {
  final ValueChanged<StoreProduct> onAdd;
  final bool embedded;
  const ProductList({super.key, required this.onAdd, this.embedded = false});
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
          itemBuilder: (context, index) => ProductTile(p: items[index], add: widget.onAdd),
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
  final ValueChanged<StoreProduct> add;
  const ProductTile({super.key, required this.p, required this.add});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 0,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Detail(p: p, add: add))),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4EBEF)), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(13)),
            child: p.imageUrl.isEmpty
              ? const Icon(Icons.precision_manufacturing_rounded, color: _accent, size: 48)
              : Image.network(p.imageUrl, fit: BoxFit.contain, cacheWidth: 480,
                  errorBuilder: (_, _, _) => const Icon(Icons.precision_manufacturing_rounded, color: _accent, size: 48)),
          )),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(p.name,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ink, height: 1.3, fontSize: 12, fontWeight: FontWeight.w800))),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(
            p.displayPrice.isNotEmpty ? p.displayPrice : 'استعلام قیمت',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w900),
          )),
          const SizedBox(height: 6),
          Container(width: double.infinity, color: const Color(0xFFEAF6F4),
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: const Text('مشاهده مشخصات', textAlign: TextAlign.center,
              style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
      ),
    ),
  );
}

class Detail extends StatelessWidget {
  final StoreProduct p;
  final ValueChanged<StoreProduct> add;
  const Detail({super.key, required this.p, required this.add});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مشخصات محصول')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          height: 280,
          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22)),
          child: p.imageUrl.isEmpty ? const Icon(Icons.precision_manufacturing, color: _accent, size: 84)
            : Image.network(p.imageUrl, cacheWidth: 900, fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.precision_manufacturing, color: _accent, size: 84)),
        ),
        const SizedBox(height: 16),
        Text(p.name, style: const TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(p.sku.isEmpty ? 'شناسه: ' + p.id.toString() : 'کد فنی: ' + p.sku,
          style: const TextStyle(color: _muted)),
        const SizedBox(height: 12),
        Text(p.displayPrice.isEmpty ? 'استعلام قیمت' : p.displayPrice,
          style: const TextStyle(color: _accent, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 7),
        Text(p.inStock ? 'موجود در انبار' : 'ناموجود', style: TextStyle(color: p.inStock ? _accent : Colors.red)),
        const SizedBox(height: 18),
        if (p.shortDescription.isNotEmpty) ...[
          const _SectionHeading(title: 'معرفی کوتاه', subtitle: 'اطلاعات فروشگاه'),
          const SizedBox(height: 8),
          ProductHtml(html: p.shortDescription),
          const SizedBox(height: 18),
        ],
        if (p.description.isNotEmpty) ...[
          const _SectionHeading(title: 'توضیحات و مشخصات فنی', subtitle: 'برگرفته از محتوای محصول در وردپرس'),
          const SizedBox(height: 8),
          ProductHtml(html: p.description),
          const SizedBox(height: 18),
        ],
        if (p.attributes.isNotEmpty) ...[
          const _SectionHeading(title: 'ویژگی‌های محصول', subtitle: 'اطلاعات ثبت‌شده در فروشگاه'),
          const SizedBox(height: 9),
          Table(
            border: TableBorder.all(color: const Color(0xFFE2E9EB), borderRadius: BorderRadius.circular(8)),
            children: [for (final item in p.attributes) TableRow(children: [
              _tableCell(item.name, bold: true), _tableCell(item.values.join('، ')),
            ])],
          ),
          const SizedBox(height: 18),
        ],
        SizedBox(width: double.infinity, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.all(15)),
          onPressed: p.inStock ? () { add(p); ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('به سبد خرید اضافه شد'))); } : null,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('افزودن به سبد خرید'),
        )),
      ]),
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
