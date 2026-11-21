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

## Customer sign-in

Profile supports Email OTP (send and verify), password sign-in, Email OTP account registration and resend, and native Google sign-in. Google uses `POST /api/auth/google`; an existing local account is linked only after an Email OTP via `POST /api/auth/google/link`. The app uses the customer portal only. It stores the returned itsclear session in Android secure storage, validates a restored session with `GET /api/auth/me`, and removes it on sign-out. Test-mode email codes returned by the backend are never displayed by the app.

The Google native SDK needs an **Android OAuth client** registered in the same Google Cloud project for `com.itsclear.app` and the SHA-1 of the certificate that signs the actual installed APK. The workflow preserves `com.itsclear.app`; its debug-signed artifacts may have a different APK fingerprint from an existing local build. Use the intended signing key for distribution and check the APK with `apksigner verify --print-certs app-release.apk`. Do not commit the signing key. The SDK's **server client ID** is the Web OAuth ID accepted as the backend's token audience (defaults to the auth handler’s public fallback). Override with `--dart-define=ITSCLEAR_GOOGLE_WEB_CLIENT_ID=<web-client-id>` if the server uses a different value. The Android OAuth client ID is not the server client ID.

`test/auth_test.dart` checks request contracts, OTP and Google-linking UI, and session handling against mock responses. Testing on a real registered Android build with a test account is still required for Google and email delivery.

## Checkout and tracking

Basket opens a native checkout with the item subtotal and store payment flags, without a browser redirect. The Orders tab has sections for tracking and receipts. Actual order creation/history/tracking, receipts, payments, coupons, review submissions and uploads are not wired: their route handlers and response schemas have not been provided. The app does not fabricate order status, receipts or payment confirmation.

For the next integration provide the `orders`, `payments` and `coupons` route handlers or an OpenAPI spec including the receipt and tracking responses, with secrets and customer data removed. Final prices, order states and payments must be verified server-side. The payment webhook is backend-only. The basket and saved items are session-local.

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
