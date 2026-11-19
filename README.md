# itsclear™ — Full Ecommerce App UI

A complete, polished **ecommerce app UI** for the [itsclear.in](https://itsclear.in/) storefront, rebuilt around the **exact black-and-cream `itsclear™` Khapli Atta pouch** from the user-provided reference screenshot. This is **UI only**: no backend, payments, API calls, AI assistant or chat interface.

The default route is a native-style **phone app**. On desktop it appears inside a 390 × 844 device frame with a side note; on a phone-sized viewport it fills the screen. The responsive desktop storefront is also available at **`?web=1`**.

The latest **v3.1 polish** adds a cleaner hero, four quick actions, editorial story cards, a dark “clear standard” promise card, product ratings, viewer tabs and spec tiles, a lab verification seal, a gold-member badge, a secure-checkout note, an order progress pill and a floating desktop purity-score card — without changing the exact packaging or the UI-only scope.

## Exact packaging

The old jute-bori artwork is gone. `docs/reference-packaging.png` is the screenshot you supplied; `scripts/make_packs.py` isolates that real pouch with ImageMagick and produces six transparent PNGs in `public/images/`:

| Asset | Use |
| --- | --- |
| `pack-khapli.png` | exact front pouch |
| `pack-protein.png` | same pouch + 36g UI seal |
| `pack-lineup.png` | 1kg / 5kg / 10kg lineup |
| `pack-badges.png` | same pouch + lab-verification seals |
| `pack-duo.png` | two-pouch protein duo |
| `pack-handle.png` | zoomed carry-handle / wordmark |

All product cards, categories, bundles, hero, 360° inspector, galleries, basket, checkout and catalog views use these exact pack shots. `docs/packaging-variants.png` shows the generated set. This is screenshot-derived artwork, not an invented AI pack or a generic atta bag.

## Run it

```bash
npm install
npm run dev        # http://localhost:5173  (0.0.0.0 for live preview)
npm run build      # production build in dist/
npm run preview    # serve the production build

# companion desktop storefront
open http://localhost:5173/?web=1
```

Requires Node.js 20.19+ and ImageMagick's `convert` / `mogrify` only if regenerating pack assets. Tested on Node 22.

## Full phone-app flows

| Area | What it does |
| --- | --- |
| **Home** | Screenshot-style hero with exact pouch, orange harvest pill, navy/orange headline, 3-slide pack story, 360° inspector entry, delivery pin, trust pills, 4 quick actions, categories, rated best sellers, editorial story cards, dark promise card, sale countdown, lab promo, calculator shortcut and ranked list. |
| **Shop** | Search entry, `All / Khapli / Protein / Family / Bundle` filters, featured / price / rating sorting, 5-product grid and 3 monthly bundles. |
| **360° inspector** | Drag-to-rotate pouch, live angle readout, six exact pack views, filmstrip, Front / Handle / Range tabs, cold-milling spec, 3 spec tiles and reset. |
| **Product detail** | Gallery, rating row, pack sizes, quantity, wishlist, Overview / Nutrition / Lab report tabs, key facts, related products and add-to-basket. |
| **Basket** | Free-shipping progress, quantity stepper, remove, `CLEAR50` coupon, bill breakdown and route into checkout. |
| **Checkout** | Address form, delivery slots, UPI / card / cash selection, secure on-device note, order summary and place-order CTA. |
| **Order + tracking** | Order confirmation with progress pill, EV delivery timeline, order history and back-to-home flow that clears the basket. |
| **Zero-Maida Lab** | NABL batch certificate with verification seal, 6 passed tests, 5 benchmarks and QR verification mark. |
| **Wishlist / Offers / Notifications / Profile** | Saved flours, coupons, harvest/delivery updates, account stats with gold-member badge, lab certificates, desktop link and FAQ. |
| **Search + grain calculator** | Live product/bundle search and interactive family-size / rotis-per-day calculator. |

Bottom-tab navigation stays visible on the five main tabs; detail flows use a back stack and hide the tab bar for a native feel. All cart, checkout, wishlist, coupon, calculator, gallery and order state is local UI state.

## Desktop companion (`?web=1`)

The earlier full desktop storefront is restyled in the same navy / orange / cream system and now uses the exact pouch in its 360° viewer, categories, best sellers, bundles, ranked list, catalog, product detail, cart and thumbnails. A floating **98/100 purity-score card** sits between the viewer and the shop card. It also has a dedicated **Checkout view** with address, delivery slot, payment method and order summary. Desktop hero copy mirrors the reference: “Discover The Purest Chakki Atta Online”.

## Design system

- **Palette:** warm white `#fffdf8`, paper `#ffffff`, deep navy `#101a3a`, burnt orange `#ef5b25`, wheat gold `#c6922f`.
- **Type:** self-hosted **Manrope Variable** for bold editorial headings, **DM Sans Variable** for compact UI; Fraunces remains installed for legacy sections.
- **Details:** 390px device geometry, rounded cards, hairline borders, soft shadows, micro-transitions, safe-area padding, reduced-motion support and no horizontal overflow at phone width.

## Verification

- **26/26 v3.1 headless checks passed** — exact pack assets, all three hero slides with no copy/pouch overlap, quick actions, editorial cards, ratings, 360° viewer tabs/spec tiles, filters, search, product detail, size pricing, gallery, tabs, basket maths, `CLEAR50`, checkout secure note, order progress/tracking, lab seal, profile badge, calculator, all five tabs, desktop purity card, desktop checkout, 390px overflow, images and zero browser errors.
- Earlier work: **25/25** exact-packaging checks, **78/78** desktop-storefront checks and **27/27** earlier phone-app checks.
- Production build passes (`vite v8.3.8`), all six pack PNGs return `200`, and no console/page errors were captured.

Main screenshots: `docs/preview.png` / `docs/preview-phone.png` (presentation), `docs/preview-phone-home.png`, `preview-phone-shop.png`, `preview-phone-product.png`, `preview-phone-viewer.png`, `preview-phone-basket.png`, `preview-phone-checkout.png`, `preview-phone-order.png`, `preview-phone-tracking.png`, `preview-phone-lab.png`, `preview-phone-profile.png`, `docs/preview-desktop.png` and `docs/preview-desktop-checkout.png`.

## Project structure

```
index.html                  app shell, mobile viewport + theme colour
vite.config.js              Vite + React, 0.0.0.0 host
src/main.jsx                route switch: phone app by default, ?web=1 desktop
src/PhoneApp.jsx            full phone ecommerce app: tabs, screens, flows + UI state
src/phone.css               base phone app styles
src/phone-theme.css         navy/orange theme + v3.1 phone polish, viewer/checkout/list-screen styles
src/theme.css               shared brand variables
src/App.jsx                 desktop storefront home + global state
src/Views.jsx               desktop Lab / catalog / product views
src/CheckoutView.jsx        desktop checkout view
src/data.js                 products, categories, lab tests, nutrition, reviews, pack paths
src/styles.css              desktop design system + appended v3/v3.1 theme, purity-card and checkout CSS
public/images/              6 exact pack PNGs + 2 lifestyle images
scripts/make_packs.py       isolates the pouch from the reference screenshot
docs/                      reference screenshot, packaging variants and all UI screenshots
```

> This is a front-end design demo only. Cart, checkout, search, coupon, orders and forms are local UI state; no payments or network requests are made.

---

## Original repository project (unchanged)

The repository originally contained a Streamlit-powered Generative AI Assistant using LangChain + Ollama (`scripts/simple_genai_app.py`). It is still present and untouched, but it is **not part of this storefront/app UI task**.

```bash
streamlit run scripts/simple_genai_app.py
```

* LangSmith tracking · structured `ChatPromptTemplate` · Streamlit Q&A UI · `OllamaLLM` with `gemma2:2b`.
* Prerequisites: Python 3.10+, Ollama, LangSmith + LangChain (API key in `.env`).
