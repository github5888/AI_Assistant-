# itsclear™ — Flutter Android app

The Flutter Android app reads the live itsclear storefront API. The earlier React/Vite prototype is archived under `legacy_web/` for visual reference only.

## Live API integration

| Read endpoint | Use in the app |
| --- | --- |
| `GET /api/products` | Home, Shop, search and saved items: products, prices, pack variants, stock and product photos |
| `GET /api/products/:id` | Refresh product details, nutrition and batch reference |
| `GET /api/config` | Website payment availability and free-delivery threshold |
| `GET /api/health` | Store/database status in the guest profile |
| `GET /api/reviews?productId=:id` | Written reviews on product details; the live endpoint currently returns an empty array. The reader only shows records with a matching product ID, valid rating and comment. |

The default API origin is `https://itsclear.in`. Use `--dart-define=ITSCLEAR_API_BASE_URL=https://your-staging-host.example` with `flutter run` or `flutter build apk --release` to test another HTTPS origin. Android release builds require the `INTERNET` permission in `android/app/src/main/AndroidManifest.xml`; the APK workflow preserves that manifest when generating its matching Gradle runner.

## Mobile storefront layout

Home opens with a swipeable pack-led banner, compact Orders and Calculator shortcuts, and photo tiles that open the matching Shop filters. Search is accessible in the Home header. Shop puts search and filters above the same card layout. Home and Shop share a lazy, responsive catalog grid. On standard phone widths, cards fit two across with a compact Add button next to the price; larger system fonts use a wider horizontal card. Product thumbnails are decoded near their display size to reduce scrolling memory use. `test/catalog_layout_test.dart` checks layout and basket interaction on narrow phone viewports.

## Customer sign-in

Profile supports Email OTP (send and verify), password sign-in, Email OTP account registration and resend, and native Google sign-in. Google uses `POST /api/auth/google`; an existing local account is linked only after an Email OTP via `POST /api/auth/google/link`. The app uses the customer portal only. It stores the returned itsclear session in Android secure storage, validates a restored session with `GET /api/auth/me`, and removes it on sign-out. Test-mode email codes returned by the backend are never displayed by the app.

The Google native SDK needs an **Android OAuth client** registered in the same Google Cloud project for `com.itsclear.app` and the SHA-1 of the certificate that signs the actual installed APK. The workflow preserves `com.itsclear.app`; its debug-signed artifacts may have a different APK fingerprint from an existing local build. Use the intended signing key for distribution and check the APK with `apksigner verify --print-certs app-release.apk`. Do not commit the signing key. The SDK's **server client ID** is the Web OAuth ID accepted as the backend's token audience (defaults to the auth handler’s public fallback). Override with `--dart-define=ITSCLEAR_GOOGLE_WEB_CLIENT_ID=<web-client-id>` if the server uses a different value. The Android OAuth client ID is not the server client ID.

`test/auth_test.dart` checks request contracts, OTP and Google-linking UI, and session handling against mock responses. `test/order_api_test.dart` and `test/payment_flow_test.dart` check authenticated order payloads, Razorpay proof handoff, price/stock errors and cancellation/return routes using mocks. Testing on a real registered Android build with test credentials and Razorpay test keys is still required for Google, email delivery and the native payment sheet.

## Checkout and tracking

Basket opens a native checkout without a browser redirect. Delivery name, mobile, six-digit PIN, city, street address and Home/Work type are editable and validated. Order creation uses the signed-in customer token and `POST /api/orders`; the server calculates the quote, validates stock and owns payment/order state. Cash on delivery is submitted only when enabled by store config. The app does not clear the basket or show confirmation until the server returns the created order. If the final request times out or returns an ambiguous server error, the app first directs the customer to check order history before another attempt, avoiding accidental duplicate COD orders. Customer order history uses `GET /api/orders`; order details display the returned tracking/status/receipt fields, eligible cancellation calls `POST /api/orders/:id/cancel`, and delivered orders can request a return via `POST /api/orders/:id/return`. Checkout confirmation and order details include a schematic route card and an external Google Maps directions link when a delivery address is present. It labels GPS as live only when valid coordinates are included in the order response; the app does not embed a map API key or invent a driver's location. For a true live route, the backend must expose current delivery coordinates and route progress. The live catalog maps mustard oil and desi ghee categories into dedicated filters and uses website API images and exact variant labels when available, with bundled product-image fallbacks. UPI is available only when `/api/config` enables online payments: the app creates a server-priced Razorpay order through `POST /api/payments/create-order`, opens the native Razorpay Flutter checkout, and submits the returned signature with `POST /api/orders` for server-side capture verification. A gateway success alone never creates the local order confirmation; the order API must accept it. Card/netbanking, coupon application, saved-address persistence, review submissions and uploads are not connected. The app never fabricates order status, totals or receipts.

The server order route is expected to remain authoritative for price, inventory, payment proof and order status. `POST /api/payments/webhook` is strictly server-to-server: the provided Express bootstrap mounts the raw-body handler before JSON parsing, and its HMAC signature check must stay on the backend. The Android app never calls the webhook or receives the webhook secret. The basket and saved items are session-local.

## Run locally on Windows

Your earlier `flutter upgrade` error came from the extracted folder name `AI_Assistant--arena-188580a1-ai-assistant`: capitals and hyphens are not a valid Dart package name. Use a lowercase folder such as `itsclear_app`, or keep the explicit `--project-name itsclear_app` flag below. Also run the global `flutter upgrade` from outside the project folder, for example from `C:\Users\salon`.

```powershell
cd C:\Users\salon
flutter upgrade
flutter doctor

cd C:\Users\salon\Downloads
ren AI_Assistant--arena-188580a1-ai-assistant itsclear_app
cd itsclear_app

# Repair/generate the Android runner without overwriting lib/ or pubspec.yaml.
flutter create --platforms=android --project-name itsclear_app --org com.itsclear.app --no-overwrite .

flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

The APK appears at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

If Android Gradle reports a template mismatch, follow the APK workflow’s generation steps and keep the checked-in Android manifest. Generated `gradlew`, `gradlew.bat`, `gradle-wrapper.jar` and `local.properties` are intentionally ignored by Git.

## Build the APK on GitHub

This sandbox has **no Flutter SDK, Dart SDK or Java**, so a local APK was not built here. The committed GitHub Actions workflow builds it instead:

1. Push to `arena/188580a1-ai-assistant`.
2. Open the repository **Actions** tab and wait for **Build Android APK**.
3. Download the `itsclear-release-apk` artifact from the completed run.

The workflow uses Flutter `stable`, regenerates the Android runner from that exact SDK, runs `flutter pub get`, `flutter analyze`, `flutter test` (including phone layouts), and `flutter build apk --release`, then uploads `app-release.apk`. It does not need secrets or a release keystore because the APK uses debug signing for testing.

## GitHub branch

Active branch:

```text
arena/188580a1-ai-assistant
```

https://github.com/github5888/AI_Assistant-/tree/arena/188580a1-ai-assistant

`main` is intentionally older. Switch the branch dropdown to `arena/188580a1-ai-assistant` to see the Flutter app. No PR/merge has been requested.
