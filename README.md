# itsclear™ — Flutter Android app

**This is the actual Flutter / Dart Android app**, not the earlier React/Vite website. The archived web prototype lives in `legacy_web/` and is only a visual reference. It is **not** the deliverable and there is no PWA, browser preview, backend, API, real payment, chat, or AI assistant in this app.

The UI is a premium, phone-first `itsclear.in`-style storefront built around the exact black-and-cream Khapli pouch assets in `assets/images/`. The layout follows the phone’s screen size and system insets, including cutouts, gesture navigation and the on-screen keyboard. All shopping flows are local UI state only.

## What is inside

- `lib/main.dart` — app entry, phone shell, frosted app bar, floating dark glass bottom dock.
- `lib/theme.dart` — cream / navy / orange / gold premium palette and reusable typography.
- `lib/data.dart` — products, exact pack images, lab tests, hero slides, bundles, ranking, timeline.
- `lib/app_state.dart` — local cart, wishlist, coupon, calculator, viewer, checkout and order state.
- `lib/widgets.dart` — reusable premium cards, pack image, pills, buttons, quick actions, trust chips.
- `lib/screens/` — Home, Shop, Product, Search, 360° Viewer, Calculator, Lab, Basket, Checkout, Order Success, Tracking, Wishlist, Offers, Notifications, Orders and Profile.
- `assets/images/` — the six exact isolated pouch PNGs plus the two lifestyle JPGs.
- `android/` — native Android host using the Flutter Gradle Plugin.
- `.github/workflows/apk.yml` — GitHub Actions workflow that generates a fresh Android runner, analyzes the Dart source and uploads a release APK.
- `legacy_web/` — archived React/Vite implementation, kept only so the original design reference is not lost.

### Implemented UI flows

Home hero carousel, quick actions, categories, best sellers, editorial stories, promise card and ranked list; Shop filters/sort/search; product gallery, sizes, quantity, overview/nutrition/lab tabs and 360° pack inspector; wishlist; basket with quantity controls, `CLEAR50` coupon and bill; checkout with editable address, delivery slots and payment method selection; order confirmation, order list and tracking timeline; NABL lab certificate and benchmarks; grain/roti calculator; offers, notifications and profile.

Everything is UI-only: no network calls, no database, no real order, no payment gateway and no assistant/chat.

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
flutter run
flutter build apk --release
```

The APK appears at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

If Android Gradle complains about a version mismatch, delete `android/` and rerun the `flutter create --no-overwrite .` command above. Generated `gradlew`, `gradlew.bat`, `gradle-wrapper.jar` and `local.properties` are intentionally ignored by Git.

## Build the APK on GitHub

This sandbox has **no Flutter SDK, Dart SDK or Java**, so a local APK was not built here. The committed GitHub Actions workflow builds it instead:

1. Push to `arena/188580a1-ai-assistant`.
2. Open the repository **Actions** tab and wait for **Build Android APK**.
3. Download the `itsclear-release-apk` artifact from the completed run.

The workflow uses Flutter `stable`, regenerates the Android runner from that exact SDK, runs `flutter pub get`, `flutter analyze`, `flutter test` (including phone layouts), and `flutter build apk --release`, then uploads `app-release.apk`. It does not need secrets or a release keystore because this is a UI demo with debug signing.

## GitHub branch

Active branch:

```text
arena/188580a1-ai-assistant
```

https://github.com/github5888/AI_Assistant-/tree/arena/188580a1-ai-assistant

`main` is intentionally older. Switch the branch dropdown to `arena/188580a1-ai-assistant` to see the Flutter app. No PR/merge has been requested.

## Scope reminder

- Flutter / Dart Android app ✅
- Exact black-and-cream `itsclear™` packaging assets ✅
- Premium phone UI and full ecommerce interaction flow ✅
- UI-only local state ✅
- Website / PWA as deliverable ❌
- Backend, API, real payment, chat or AI assistant ❌
