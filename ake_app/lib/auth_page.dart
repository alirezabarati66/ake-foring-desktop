import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/digits_service.dart';
import 'services/delivery_service.dart';
import 'delivery_page.dart';

const _dark = Color(0xFF173240);
const _mint = Color(0xFF00A99D);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final service = DigitsService();
  final storage = const FlutterSecureStorage();
  final phone = TextEditingController();
  final otp = TextEditingController();
  final name = TextEditingController();
  bool register = false, sent = false, busy = true;
  String? token, error;
  Map<String, dynamic>? identity;
  DateTime? lastSent;

  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    await run(() async {
      token = await storage.read(key: 'ake_token');
      if (token != null) await validateSession();
    });
  }

  Future<void> validateSession() async {
    identity = null;
    if (token != null) {
      identity = await DeliveryService(token!).me();
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await action();
    } on DigitsApiException catch (e) {
      error = e.message;
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      error = message.length > 180 ? message.substring(0, 180) : message;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> send() async {
    if (lastSent != null && DateTime.now().difference(lastSent!).inSeconds < 60) {
      setState(() => error = 'برای ارسال مجدد پیامک، ۶۰ ثانیه از ارسال قبلی صبر کنید.');
      return;
    }
    await run(() async {
      await service.sendOtp(phone.text, register: register, resend: sent);
      lastSent = DateTime.now();
      sent = true;
      otp.clear();
    });
  }

  Future<void> verify() async {
    await run(() async {
      if (register && name.text.trim().isEmpty) {
        throw const DigitsApiException('برای عضویت نام و نام خانوادگی را وارد کنید.');
      }
      final result = await service.authenticate(
        phone.text, otp.text, register: register, name: name.text,
      );
      await storage.write(key: 'ake_token', value: result);
      token = result;
      otp.clear();
      // Authorization succeeded; profile verification is checked separately.
      try {
        await validateSession();
      } catch (_) {
        identity = null;
        error = 'ورود انجام شد، اما دریافت پروفایل از API مکمل امکان‌پذیر نیست. «بررسی مجدد» را بزنید.';
      }
    });
  }

  Future<void> signOut() async {
    if (token == null) return;
    final oldToken = token!;
    await run(() async {
      try {
        await service.logout(oldToken);
      } catch (_) {
        // Clear device credentials even if network logout fails.
      }
      await storage.delete(key: 'ake_token');
      token = null;
      identity = null;
      sent = false;
      lastSent = null;
      otp.clear();
    });
  }

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    name.dispose();
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_dark, Color(0xFF286474)]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_user_rounded, color: Colors.white, size: 38),
          SizedBox(height: 12),
          Text('حساب کاربری آریان کوب', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 7),
          Text('ورود امن با شماره موبایل و رمز یک‌بارمصرف',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 20),
      if (busy) const LinearProgressIndicator(color: _mint),
      if (error != null) Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(color: const Color(0xFFFFF0EE), borderRadius: BorderRadius.circular(12)),
          child: Padding(padding: const EdgeInsets.all(12),
            child: Text(error!, style: const TextStyle(color: Color(0xFF9A2B20), height: 1.5))),
        ),
      ),
      if (token != null) ...[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('نشست کاربری', style: TextStyle(color: _dark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 9),
            if (identity == null) ...[
              const Text('ورود انجام شده اما پروفایل هنوز تأیید نشده است.'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: busy ? null : () => run(validateSession),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('بررسی مجدد اتصال'),
              ),
            ] else ...[
              Row(children: [
                const Icon(Icons.check_circle_rounded, color: _mint),
                const SizedBox(width: 8),
                Expanded(child: Text('خوش آمدید، ' + (identity!['name'] ?? 'کاربر').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: busy ? null : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DeliveryPage(token: token!, courier: false))),
                child: const Text('موقعیت سفارش‌های من'),
              )),
              if (identity!['courier'] == true) SizedBox(width: double.infinity, child: FilledButton(
                onPressed: busy ? null : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DeliveryPage(token: token!, courier: true))),
                child: const Text('مأموریت‌های پیک'),
              )),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('خروج از حساب / ورود با شماره دیگر'),
        ),
      ] else ...[
        Row(children: [
          Expanded(child: _modeButton('ورود', !register, () { if (!busy) setState(() { register = false; sent = false; error = null; otp.clear(); }); })),
          const SizedBox(width: 8),
          Expanded(child: _modeButton('ثبت‌نام', register, () { if (!busy) setState(() { register = true; sent = false; error = null; otp.clear(); }); })),
        ]),
        const SizedBox(height: 16),
        if (register) ...[
          TextField(
            controller: name, enabled: !busy, textInputAction: TextInputAction.next,
            decoration: _field('نام و نام خانوادگی', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: phone,
          enabled: !busy && !sent,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          maxLength: 13,
          decoration: _field('شماره موبایل (مثلاً 09123456789)', Icons.phone_android_rounded),
        ),
        if (sent) ...[
          const SizedBox(height: 8),
          TextField(
            controller: otp, enabled: !busy,
            keyboardType: TextInputType.number, textDirection: TextDirection.ltr,
            decoration: _field('کد تأیید پیامکی', Icons.pin_outlined),
          ),
          const SizedBox(height: 8),
          Text('کد تأیید برای شماره ' + phone.text + ' درخواست شد.',
            style: const TextStyle(color: _dark, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _mint, padding: const EdgeInsets.symmetric(vertical: 15)),
          onPressed: busy ? null : (sent ? verify : send),
          child: Text(sent ? (register ? 'تکمیل عضویت' : 'ورود به حساب') : 'دریافت کد پیامکی'),
        )),
        if (sent) ...[
          TextButton(onPressed: busy ? null : send, child: const Text('ارسال مجدد کد')),
          TextButton(onPressed: busy ? null : () => setState(() { sent = false; otp.clear(); error = null; }),
              child: const Text('اصلاح شماره موبایل')),
        ],
        const SizedBox(height: 9),
        const Text('رمز یک‌بارمصرف فقط از سرویس Digits سایت ارسال می‌شود؛ اپلیکیشن کد ساختگی تولید نمی‌کند.',
          style: TextStyle(color: Color(0xFF65737D), fontSize: 11, height: 1.7)),
      ],
    ],
  );

  Widget _modeButton(String label, bool selected, VoidCallback onTap) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      backgroundColor: selected ? _dark : Colors.white,
      foregroundColor: selected ? Colors.white : _dark,
      side: BorderSide(color: selected ? _dark : const Color(0xFFE0E7EA)),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    onPressed: onTap,
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );

  InputDecoration _field(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _mint),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    filled: true,
    fillColor: Colors.white,
  );
}
