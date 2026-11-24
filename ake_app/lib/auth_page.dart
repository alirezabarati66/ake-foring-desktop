import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/digits_service.dart';
import 'services/delivery_service.dart';
import 'delivery_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final service = DigitsService();
  final storage = const FlutterSecureStorage();
  final phone = TextEditingController(), otp = TextEditingController(), name = TextEditingController();
  bool register = false, sent = false, busy = true;
  String? token, error;
  Map<String,dynamic>? identity;
  Future<void> validateSession() async {
    identity = null;
    if (token != null) identity = await DeliveryService(token!).me();
  }
  DateTime? lastSent;
  @override
  void initState() { super.initState(); restore(); }
  Future<void> restore() async {
    await run(() async { token = await storage.read(key: 'ake_token'); await validateSession(); });
  }
  Future<void> run(Future<void> Function() action) async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    try { await action(); } catch (_) {
      if (mounted) setState(() => error = 'عملیات ناموفق بود. شماره، کد و اتصال اینترنت را بررسی کنید.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> send() async {
    if (lastSent != null && DateTime.now().difference(lastSent!).inSeconds < 60) {
      setState(() => error = 'برای ارسال مجدد ۶۰ ثانیه صبر کنید.');
      return;
    }
    await run(() async {
      await service.sendOtp(phone.text, register: register, resend: sent);
      lastSent = DateTime.now();
      sent = true;
    });
  }
  @override
  void dispose() { phone.dispose(); otp.dispose(); name.dispose(); service.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('حساب کاربری', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    if (busy) const LinearProgressIndicator(),
    if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
    if (token != null) ...[
      if (identity == null) ...[
        const Text('اعتبار نشست هنوز تایید نشده است.'),
        OutlinedButton(onPressed: busy ? null : () => run(validateSession), child: const Text('بررسی مجدد')),
      ] else ...[
        Text('خوش آمدید، ${identity!['name']}'),
        FilledButton(onPressed: busy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeliveryPage(token: token!, courier: false))), child: const Text('موقعیت تحویل سفارش‌ها')),
        if (identity!['courier'] == true) FilledButton(onPressed: busy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeliveryPage(token: token!, courier: true))), child: const Text('مأموریت‌های پیک')),
      ],
      FilledButton(onPressed: busy ? null : () => run(() async {
        await service.logout(token!);
        await storage.delete(key: 'ake_token');
        token = null; identity = null; sent = false; otp.clear();
      }), child: const Text('خروج از حساب')),
    ] else ...[
      SwitchListTile(title: const Text('ثبت نام کاربر جدید'), value: register, onChanged: busy || sent ? null : (v) => setState(() => register = v)),
      if (register) TextField(controller: name, enabled: !busy, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی')),
      TextField(controller: phone, enabled: !busy && !sent, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل')),
      if (sent) TextField(controller: otp, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد پیامک')),
      FilledButton(onPressed: busy ? null : sent ? () => run(() async {
        final value = await service.authenticate(phone.text, otp.text, register: register, name: name.text);
        await storage.write(key: 'ake_token', value: value);
        token = value; otp.clear(); await validateSession();
      }) : send, child: Text(sent ? 'تایید کد' : 'ارسال پیامک')),
      if (sent) TextButton(onPressed: busy ? null : send, child: const Text('ارسال مجدد')),
      if (sent) TextButton(onPressed: busy ? null : () => setState(() { sent = false; otp.clear(); }), child: const Text('تغییر شماره')),
    ],
  ]);
}
