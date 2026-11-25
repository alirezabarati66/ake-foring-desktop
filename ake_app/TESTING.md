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


## UI refresh / auth verification (2026-11-25)
The Flutter source now includes gradient/vector marketing banners (no large raster files), a responsive paginated product catalog, a live WordPress-hosted logo, and a lightweight renderer for product descriptions, embedded images and basic HTML tables/attributes. Some complex WPBakery/VC widgets and merged-cell HTML tables may not render exactly like the website: compare representative product pages.

Digits route existence on the live site was verified read-only; this does NOT confirm SMS gateway delivery, registration, token validation or login. The app now displays the actual server error instead of masking every error. Do not share OTP codes, access tokens or phone numbers in screenshots.

The previous default widget test was stale. Run:
```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
```
Build of these commits has not yet been executed by the assistant; the user built a preceding beta. Test the new version on a phone and report the exact on-screen message (redacted if personal).
For a smaller *testing-only* APK, compare:
```sh
flutter build apk --release --target-platform android-arm64 --split-per-abi
```
Output is normally under build/app/outputs/flutter-apk/ and usually called app-arm64-v8a-release.apk. Release signing is presently configured with DEBUG keys, so this artifact must NOT be distributed as a production signed app. Before production distribution, configure a unique application ID, versioning and a secure release keystore.

The mobile checkout still requires a valid Neshan web key and careful WooCommerce quote/payment validation. No production order should be placed during unaudited tests. Do not overwrite a local, low-RAM android/gradle.properties without preserving a backup.


## Requested mobile UI and order workflow changes (2026-11-26)
- Storefront banners now use photographic industrial backgrounds with dark overlays; cards include an add-to-cart action and quantity/attribute selection sheet.
- Product detail is an in-app route with its own app header, bottom navigation and Aali & Aali footer link.
- Selected simple-product attributes are passed through checkout and saved as WooCommerce order-item metadata. True WooCommerce variable products are intentionally blocked from adding until variation IDs/price/stock are integrated; do not sell a variable item as a simple product.
- Login now offers password or OTP. Registration asks for a password and confirmation, and verifies the phone by OTP before creating the account.
- Root cause of Digits registration's Error: Unexpected user: Digits REST Addon 2.3 reads data.user_id from digits_create_user(), while Digits 8.6.2's digits_user_created_response returns success without user_id. The AKE Delivery plugin now adds the ID through that official filter. The updated wordpress/ake-delivery.php must be deployed to the existing ake mokamel/ake-delivery.php plugin on WordPress before registration is expected to work. Do not edit vendor Digits files.
- Courier dashboard now includes assigned order, customer/phone/address/total, external navigation, and status progression (assigned -> accepted -> picked_up -> out_for_delivery -> delivered). The matching REST status endpoint is in wordpress/ake-delivery.php; it must be deployed with the same plugin update.
- Neshan: the Flutter SDK uses the Neshan Web SDK on mobile WebView; use a Web key, do not restrict domain/IP for the app's key, and ensure the key has a base-map tile service enabled. Runtime errors are now surfaced in the map screen. Neshan Web key is passed at build with --dart-define=NESHAN_WEB_KEY=...; never commit the key.
- The Aali & Aali footer link opens https://aalioaali.com.
- Build/test status must be read from the latest GitHub Actions run before release. Manual QA remains required for SMS registration, password login, map tile rendering, order item metadata, and courier status changes.
