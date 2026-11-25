# AKE Delivery API 0.2.0

این فایل جایگزین فایل قبلی افزونه در مسیر زیر می‌شود:

wp-content/plugins/ake mokamel/ake-delivery.php

## نصب امن
1. از فایل فعلی نسخه پشتیبان بگیرید.
2. فایل جدید ake-delivery.php را در همان مسیر جایگزین کنید.
3. از پیشخوان وردپرس > افزونه‌ها بررسی کنید افزونه AKE Delivery API فعال و نسخه آن 0.2.0 باشد.
4. فایل‌های خود افزونه Digits و Digits REST API را تغییر ندهید.

این افزونه برای Digits REST API 2.3 و ساختار ثبت‌نام فعلی Digits تنظیم شده است. پس از نصب، ثبت‌نام یک حساب آزمایشی با شماره‌ای که متعلق به خودتان است و ارسال پیامک واقعی را تست کنید.

## APIها
- GET /wp-json/ake/v1/me
- GET /wp-json/ake/v1/orders
- POST /wp-json/ake/v1/order-request
- POST /wp-json/ake/v1/orders/{id}/location
- GET /wp-json/ake/v1/missions
- POST /wp-json/ake/v1/missions/{id}/status

برای تست مأموریت پیک، سفارش باید در ووکامرس به یک کاربر دارای نقش AKE Courier تخصیص داده شود و مختصات تحویل داشته باشد.