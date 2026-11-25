import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/digits_service.dart';
import 'services/delivery_service.dart';
import 'delivery_page.dart';

const _dark = Color(0xFF10243E);
const _gold = Color(0xFFC58D19);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final service = DigitsService();
  final storage = const FlutterSecureStorage();
  final phone = TextEditingController(), otp = TextEditingController();
  final name = TextEditingController(), password = TextEditingController(), confirmPassword = TextEditingController();
  bool register = false, sent = false, busy = true, obscure = true;
  String loginMethod = 'password';
  String? token, error;
  Map<String, dynamic>? identity;
  DateTime? lastSent;

  @override
  void initState() { super.initState(); restore(); }

  Future<void> restore() async {
    await run(() async {
      token = await storage.read(key: 'ake_token');
      if (token != null) await validateSession();
    });
  }

  Future<void> validateSession() async {
    identity = null;
    if (token != null) identity = await DeliveryService(token!).me();
  }

  Future<void> run(Future<void> Function() action) async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    try { await action(); }
    on DigitsApiException catch (e) { error = e.message; }
    catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\\s*'), '');
      error = message.length > 180 ? message.substring(0, 180) : message;
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> sendOtp() async {
    if (lastSent != null && DateTime.now().difference(lastSent!).inSeconds < 60) {
      setState(() => error = 'برای ارسال مجدد پیامک، ۶۰ ثانیه صبر کنید.');
      return;
    }
    await run(() async {
      await service.sendOtp(phone.text, register: register, resend: sent);
      lastSent = DateTime.now();
      sent = true;
      otp.clear();
    });
  }

  Future<void> authenticate() async {
    await run(() async {
      if (register) {
        if (name.text.trim().isEmpty) throw const DigitsApiException('نام و نام خانوادگی را وارد کنید.');
        if (password.text.length < 8) throw const DigitsApiException('رمز عبور باید حداقل ۸ کاراکتر باشد.');
        if (password.text != confirmPassword.text) throw const DigitsApiException('تکرار رمز عبور مطابقت ندارد.');
        if (!sent || otp.text.trim().isEmpty) throw const DigitsApiException('ابتدا کد پیامکی را دریافت و وارد کنید.');
      } else if (loginMethod == 'password' && password.text.isEmpty) {
        throw const DigitsApiException('رمز عبور را وارد کنید.');
      } else if (loginMethod == 'otp' && (!sent || otp.text.trim().isEmpty)) {
        throw const DigitsApiException('ابتدا کد پیامکی را دریافت و وارد کنید.');
      }
      final result = await service.authenticate(
        phone.text,
        otp: (register || loginMethod == 'otp') ? otp.text : null,
        password: password.text.isEmpty ? null : password.text,
        register: register,
        name: name.text,
      );
      await storage.write(key: 'ake_token', value: result);
      token = result;
      otp.clear(); password.clear(); confirmPassword.clear();
      try { await validateSession(); }
      catch (_) { identity = null; error = 'ورود انجام شد، اما پروفایل از API مکمل دریافت نشد.'; }
    });
  }

  Future<void> signOut() async {
    if (token == null) return;
    final oldToken = token!;
    await run(() async {
      try { await service.logout(oldToken); } catch (_) {}
      await storage.delete(key: 'ake_token');
      token = null; identity = null; sent = false; lastSent = null;
      otp.clear(); password.clear(); confirmPassword.clear();
    });
  }

  @override
  void dispose() {
    phone.dispose(); otp.dispose(); name.dispose(); password.dispose(); confirmPassword.dispose();
    service.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_dark, Color(0xFF263D5C)]), borderRadius: BorderRadius.circular(24)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.account_circle_outlined, color: Colors.white, size: 38),
          SizedBox(height: 12),
          Text('حساب کاربری آریان کوب', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('مدیریت سفارش‌ها و اطلاعات حساب', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 18),
      if (busy) const LinearProgressIndicator(color: _gold),
      if (error != null) Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xFFFFF0EE), borderRadius: BorderRadius.circular(12)),
          child: Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: const TextStyle(color: Color(0xFF9A2B20), height: 1.5)))),
      ),
      if (token != null) ...[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('خوش آمدید، ${identity?['name'] ?? 'کاربر'}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _dark)),
            const SizedBox(height: 5),
            Text(identity?['courier'] == true ? 'حساب پیک مجاز' : 'حساب مشتری', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            _dashboardTile('سفارش‌های من', 'پیگیری سفارش و تعیین محل تحویل', Icons.inventory_2_outlined, false),
            if (identity?['courier'] == true) ...[
              const SizedBox(height: 12),
              _dashboardTile('پنل اختصاصی پیک', 'مأموریت‌ها، وضعیت تحویل و مسیریابی', Icons.local_shipping_outlined, true),
            ],
            if (identity == null) OutlinedButton.icon(onPressed: busy ? null : () => run(validateSession), icon: const Icon(Icons.refresh), label: const Text('بررسی مجدد اتصال')),
          ]),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: busy ? null : signOut, icon: const Icon(Icons.logout), label: const Text('خروج از حساب')),
      ] else ...[
        Row(children: [
          Expanded(child: _modeButton('ورود', !register, () => setState(() { register = false; sent = false; error = null; }))),
          const SizedBox(width: 8),
          Expanded(child: _modeButton('عضویت', register, () => setState(() { register = true; sent = false; error = null; }))),
        ]),
        const SizedBox(height: 16),
        if (register) ...[
          TextField(controller: name, enabled: !busy, decoration: _field('نام و نام خانوادگی', Icons.person_outline)),
          const SizedBox(height: 12),
        ],
        TextField(controller: phone, enabled: !busy && !sent, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr,
          decoration: _field('شماره موبایل', Icons.phone_android)),
        const SizedBox(height: 12),
        if (!register) ...[
          const Text('روش ورود', style: TextStyle(fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'password', label: Text('رمز عبور'), icon: Icon(Icons.lock_outline)),
              ButtonSegment(value: 'otp', label: Text('رمز یک‌بارمصرف'), icon: Icon(Icons.sms_outlined)),
            ],
            selected: {loginMethod},
            onSelectionChanged: busy ? null : (v) => setState(() { loginMethod = v.first; sent = false; error = null; }),
          ),
          const SizedBox(height: 12),
        ],
        if (register || loginMethod == 'password') ...[
          TextField(controller: password, enabled: !busy, obscureText: obscure, decoration: _field('رمز عبور (حداقل ۸ کاراکتر برای عضویت)', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)))),
          if (register) ...[
            const SizedBox(height: 12),
            TextField(controller: confirmPassword, enabled: !busy, obscureText: obscure, decoration: _field('تکرار رمز عبور', Icons.lock_reset)),
          ],
        ],
        if (register || loginMethod == 'otp') ...[
          const SizedBox(height: 12),
          if (!sent) SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: busy ? null : sendOtp, icon: const Icon(Icons.sms_outlined), label: const Text('دریافت کد تأیید پیامکی'))),
          if (sent) ...[
            TextField(controller: otp, enabled: !busy, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: _field('کد تأیید پیامکی', Icons.pin_outlined)),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: busy ? null : sendOtp, child: const Text('ارسال مجدد کد'))),
            TextButton(onPressed: busy ? null : () => setState(() { sent = false; otp.clear(); }), child: const Text('اصلاح شماره موبایل')),
          ],
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
          onPressed: busy || (register && !sent) || (!register && loginMethod == 'otp' && !sent) ? null : authenticate,
          child: Text(register ? 'ایجاد حساب کاربری' : 'ورود به حساب'),
        )),
      ],
    ],
  );

  Widget _dashboardTile(String title, String subtitle, IconData icon, bool courier) => Material(
    color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(16),
    child: ListTile(contentPadding: const EdgeInsets.all(13), leading: CircleAvatar(backgroundColor: _dark, foregroundColor: Colors.white, child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left), onTap: busy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeliveryPage(token: token!, courier: courier)))),
  );

  Widget _modeButton(String label, bool selected, VoidCallback onTap) => OutlinedButton(
    style: OutlinedButton.styleFrom(backgroundColor: selected ? _dark : Colors.white, foregroundColor: selected ? Colors.white : _dark,
      side: BorderSide(color: selected ? _dark : const Color(0xFFE0E7EA)), padding: const EdgeInsets.symmetric(vertical: 13)),
    onPressed: busy ? null : onTap, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );

  InputDecoration _field(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: _gold),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: Colors.white,
  );
}
