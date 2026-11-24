# AKE integration test candidate
Use a staging WordPress site or a backed-up test environment. The current API URLs point to www.ake-forging.com; change them to staging before testing. Do not activate on production until reviewed.
Install wordpress/ake-delivery.php as a plugin (zip it inside an ake-delivery directory). Digits REST addon and WooCommerce must be active. Use a Neshan Web map key, not a Mobile key.
From ake_app:
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=NESHAN_WEB_KEY=YOUR_WEB_KEY
flutter build apk --debug --dart-define=NESHAN_WEB_KEY=YOUR_WEB_KEY

Test OTP send, resend, registration, login, expired session, logout; map pan and GPS denial; selected coordinates; simple in-stock product request; WooCommerce pending order and correct customer; assign an account with AKE Courier role; change order to processing only when appropriate; verify only assigned courier sees destination. Test external navigation and unauthorized API requests. Test duplicate submissions and interrupted network.
This is a request-order workflow, not a paid checkout: shipping quote, payment gateway, robust idempotency and stock reservation require further work. Do not accept live payments using this candidate. No successful build or live integration test has been recorded yet.
