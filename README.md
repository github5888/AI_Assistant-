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

The basket and saved items are session-local. Signed-in accounts, coupons, order creation/history/tracking, review submissions, uploads and payment processing are **not** wired: the Express entry point only shows mount paths, not their handlers or schemas. Live mode never creates a simulated order or applies a simulated discount. Basket opens a native in-app checkout showing the real item subtotal and store payment flags. The Orders tab includes tracking and receipts, and Profile links to OTP and Google sign-in. The app does not redirect to a browser: submit and sign-in remain disabled until their backend contracts are available. The payment webhook is backend-only and should never be called by the app.

To continue the write integrations, provide an OpenAPI spec or the route handlers and request/response examples for `auth`, `orders`, `coupons`, `reviews`, `upload` and `payments`, including which routes are customer-facing and how authentication works. Use examples with all tokens, keys and customer data removed. Payment verification and final totals must remain on the server. Test write flows on staging or a payment sandbox first. For Android Google Sign-In, register the APK application ID and signing certificate SHA-1, provide the Web OAuth client ID if using Google ID tokens for backend verification, and document the backend token exchange. An installed-app OAuth client payload alone does not define this exchange.

`lib/store_api.dart` implements the read client, `lib/app_state.dart` manages the live catalog and the local basket, and `test/store_api_test.dart` tests parsing, failures, retry and displaying API data on a narrow screen. A local fixture mode is retained for the original Flutter layout regression tests and is not used by the Android entry point.

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
