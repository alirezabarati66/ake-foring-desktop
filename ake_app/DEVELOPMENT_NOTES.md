# AKE Forging App — Development Notes

این فایل دفترچه تحویل پروژه است. پیش از هر ویرایش، آن را مرور کن تا مسیرهای شکست‌خورده تکرار نشوند.

## وضعیت فعلی
- Repository: `alirezabarati66/ake-foring-desktop`
- Flutter project: `ake_app/`
- Main UI: `ake_app/lib/main.dart`
- Branch: `main`
- اپ روی POCO C85 اجرا شده است.
- ورود/عضویت، ذخیره دائمی، احراز هویت پیک، سفارش واقعی و تخصیص مأموریت هنوز به API امن WordPress/WooCommerce متصل نیستند.

## حساب‌های آزمایشی (UI only)
- مشتری: «مشتری نمونه AKE»، ایمیل رزروشده `customer-demo@example.com` و شماره placeholder؛ سفارش‌ها، نشانی و علاقه‌مندی‌ها نمایشی‌اند.
- پیک: «امیر رضایی (پیک آزمایشی)»؛ وضعیت آنلاین، مأموریت و سابقه تحویل شبیه‌سازی شده‌اند.
- شناسه‌های `AKE-DEMO-1001` و `AKE-DEMO-1002` ساختگی‌اند؛ در WooCommerce سفارش واقعی ایجاد نشده است.
- نشانی «شهرک صنعتی نمونه» ساختگی است. هرگز از آن برای مسیریابی واقعی استفاده نکن.

## مسیرهای ناموفق و راه‌حل جایگزین
### دانلود از raw.githubusercontent.com با curl
- اجرای `curl.exe -L` روی لینک Raw فایل ۱۴ بایتی با محتوای `404: Not Found` ساخت.
- لینک خام در محیط محلی احراز هویت‌شده نبود؛ برای مخزن خصوصی/محدود، curl بدون توکن راه قابل اتکایی نیست.
- راه جایگزین موفق: فایل را در مرورگر، با حساب دارای دسترسی GitHub باز کن؛ Raw را انتخاب و با `Ctrl+S` در `ake_app\lib\main.dart` ذخیره کن.
- قبل از جایگزینی فایل اصلی، همیشه نسخه پشتیبان تاریخ‌دار بساز.

### بازیابی فایل اصلی
- نسخه پشتیبان `lib\main_backup_before_profiles.dart` وجود داشت.
- پس از ذخیره پاسخ 404 به‌جای Dart، بازیابی با این دستور موفق شد:
  `copy /Y lib\main_backup_before_profiles.dart lib\main.dart`
- هیچ‌وقت فایل دانلودی را قبل از بررسی اندازه و محتوایش روی فایل اصلی ننویس.

## محیط توسعه
- Project: `C:\Users\koosha\develop\ake_app`
- Flutter SDK: `C:\Users\koosha\develop\flutter`
- Android SDK: `C:\Android\Sdk`؛ پیش از تغییر مسیر، `android\local.properties` را بررسی کن.
- Test device: POCO C85، ADB ID `25078PC3EG`.
- Mirror قبلاً برای دریافت Flutter artifacts استفاده شده:
  - CMD: `set FLUTTER_STORAGE_BASE_URL=https://mirror.nju.edu.cn/flutter`
  - PowerShell: `$env:FLUTTER_STORAGE_BASE_URL="https://mirror.nju.edu.cn/flutter"`
- از `flutter clean` بدون دلیل روشن استفاده نکن؛ ممکن است دانلود مجدد وابستگی‌ها لازم شود.

## روال امن ویرایش بعدی
1. این فایل و آخرین commit شاخه main را مرور کن.
2. قبل از تغییر محلی، نسخه پشتیبان تاریخ‌دار بساز.
3. فایل را از GitHub با نشست احراز هویت‌شده بگیر؛ Raw با curl را برای مخزن محدود فرض نکن.
4. پس از تغییر، diff/محتوا را بررسی و فقط فایل‌های لازم را commit کن.
5. کاربر با CMD ویندوز کار می‌کند؛ دستورها را برای CMD بنویس، نه PowerShell، مگر خودش بخواهد.
6. قبل از اجرا، `dir lib\main.dart` را بررسی کن؛ سپس `flutter run`.
7. تنظیمات SDK/Gradle/Kotlin را بدون خطای مشخص تغییر نده.

## آخرین تغییر
- حساب نمایشی مشتری با سفارش/نشانی/علاقه‌مندی/پشتیبانی نمونه و حساب نمایشی پیک با مأموریت و سابقه تحویل نمونه در `ake_app/lib/main.dart` قرار گرفت.
- این داده‌ها فقط برای تست UI هستند.
- Commit کد: `603e6e47fbd6a90abb184c97d13915fc782ea73a`
