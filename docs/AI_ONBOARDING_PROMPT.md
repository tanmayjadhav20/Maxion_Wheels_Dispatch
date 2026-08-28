# Vistar LR Management — AI Onboarding Prompt

**How to use this file (for the intern):**
Paste everything below the `--- BEGIN PROMPT ---` line into your AI assistant
(Claude Code / ChatGPT / Copilot Chat) **at the start of every new chat**, then add
your actual task at the bottom under "TASK". Without this context the AI will
invent patterns that do not match our codebase and your PR will be rejected.

---

--- BEGIN PROMPT ---

You are helping me work on **Vistar Transport Management System (VTMS)**, an
internal production Flutter app for Vistar Logitek Pvt Ltd. It digitises Lorry
Receipts (LR) — booking, dispatch, delivery, billing and reporting for a road
transport business. Real operations staff use it daily; this is NOT a toy project.

I am a junior developer new to Flutter/Dart. Explain what you change in plain
language, keep changes small and reviewable, and never invent APIs — if you are
unsure whether something exists in the codebase, tell me to grep for it first.

## 1. Stack (do not swap any of these out)

| Concern | What we use |
|---|---|
| Language | **Dart** (SDK `^3.11.5`), sound null safety, no code generation |
| Framework | **Flutter** (CI pins `3.41.9`, stable channel) |
| Targets | **Web (primary, Cloudflare Pages)**, plus Windows / Android / iOS builds exist |
| State management | **Riverpod 2** (`flutter_riverpod: ^2.5.1`) — hand-written providers, **no** riverpod_generator, no BLoC, no Provider, no GetX, no setState-driven app state |
| Routing | **go_router `^14.6.2`** with a `StatefulShellRoute` (branch per nav destination) |
| HTTP | **dio `^5.7.0`** wrapped in our own `ApiClient` (JWT auth + refresh interceptor) |
| Token storage | `flutter_secure_storage` (access + refresh JWT) |
| Local prefs | `shared_preferences` |
| Design | Material 3, `useMaterial3: true`, **Plus Jakarta Sans** via `google_fonts` |
| Formatting | `intl` (INR currency, `dd MMM yyyy` dates) |
| PDF / print | `pdf` + `printing` (LR slip, 4 copies) |
| Excel export | `excel` package (client-side `.xlsx` for Reports / MIS) |
| Maps | `flutter_map` + OpenStreetMap tiles (keyless); geocoding via our backend `/maps` proxy |
| Files / ids | `file_picker`, `uuid` |
| Lints | `flutter_lints: ^6.0.0` via `analysis_options.yaml` |
| Tests | `flutter_test` widget/unit tests in `test/` |

**Never add a new package** without telling me first and explaining why an
existing dependency cannot do the job.

## 2. Commands I run to verify your work

```bash
flutter pub get
flutter run -d chrome                     # dev (web is our primary target)
flutter analyze                           # must be clean (CI runs --no-fatal-infos)
flutter test                              # must pass — CI blocks deploy on failure
flutter build web --release --base-href "/"
```

Point at a local backend with:
`flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4099/api/v1/lr-management`

## 3. Architecture — 3 layers, feature-first

```
lib/
  main.dart                 ProviderScope + MaterialApp.router
  core/
    network/                ApiClient (dio + JWT refresh), ApiConfig, ApiException,
                            api_providers.dart, paginate.dart, token_storage.dart
    router/                 app_router.dart (all routes), nav_items.dart (sidebar)
    theme/                  app_colors.dart, app_theme.dart
    constants/  utils/      strings, assets, formatters, perf_log, lr_number_format
  shared/
    models/                 plain Dart models: lr_models.dart, user.dart, vehicle.dart, ...
    widgets/                AppButton, AppCard, SearchableField, MasterFormDialog,
                            LabeledField, ConfirmDialog, LoadingShimmer, RefreshGate, Pills
  features/<feature>/
    data/                   *_repository.dart  -> talks to the API, returns models
    providers/              *_provider(s).dart -> Riverpod providers / StateNotifiers
    screens/                *_screen.dart      -> routed pages (ConsumerWidget / ConsumerStatefulWidget)
    widgets/                feature-only widgets
```

Features: `auth`, `dashboard`, `lr`, `masters`, `lookups`, `ewb`, `warehouse`,
`reports`, `accounts`, `admin`, `users`, `maps`, `shell`.

**Strict dependency direction:** `screen -> provider -> repository -> ApiClient`

- A **screen never calls dio or a repository directly.** It watches providers.
- A **repository never imports Flutter widgets** and holds no state.
- A **model never calls the network.** It only parses/serialises JSON.
- Cross-feature reuse goes through `shared/` or `core/`, never
  `features/a/... -> features/b/screens/...`.

When adding a feature, mirror this exact folder layout.

## 4. Riverpod rules (the part people get wrong)

Patterns actually used in this repo:

```dart
// 1) Plain dependency injection
final vehiclesRepositoryProvider = Provider<VehiclesRepository>(
  (ref) => VehiclesRepository(ref.watch(apiClientProvider)),
);

// 2) A list of rows owned by a StateNotifier — the dominant pattern
class VehiclesNotifier extends StateNotifier<List<Vehicle>> {
  VehiclesNotifier(this._repo) : super(const []) { refresh(); }
  final VehiclesRepository _repo;

  Future<void> refresh() async {
    try { state = await _repo.list(); } catch (_) { /* keep prior state */ }
  }
  Future<void> add(Vehicle v) async {
    final created = await _repo.create(v);
    state = [...state, created];                                  // immutable update
  }
  Future<void> update(Vehicle v) async {
    final updated = await _repo.update(v);
    state = [for (final x in state) x.id == updated.id ? updated : x];
  }
  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = state.where((x) => x.id != id).toList();
  }
}
final vehiclesProvider = StateNotifierProvider<VehiclesNotifier, List<Vehicle>>(
    (ref) => VehiclesNotifier(ref.watch(vehiclesRepositoryProvider)));

// 3) Read-once async data -> FutureProvider (see lookupsProvider)
final lookupsProvider = FutureProvider<Map<String, List<LookupValue>>>((ref) async { ... });

// 4) Derived/computed value -> Provider that watches others (keeps widgets dumb)
final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authProvider).user);

// 5) Small UI flags -> StateProvider (e.g. activeRefreshCountProvider, first-load flags)
```

Rules:
- **`ref.watch`** in `build()` and inside provider bodies. **`ref.read`** only
  inside callbacks (`onPressed`, one-shot init) and in the router `redirect`.
- **Never mutate state in place.** Always assign a new list/object (`state = [...]`).
- Filter/derive in a `Provider`, not inside `build()` — memoised compute is why the
  heavy screens are fast (see `features/accounts` and `lr_providers.dart`).
- Screens are `ConsumerWidget` / `ConsumerStatefulWidget` (`ConsumerState`).
- Never create a provider inside `build()`. Providers are top-level `final`s.
- Mutation methods are `async` and **rethrow** so the screen can show the error via
  `friendlyErrorMessage(e)` in a SnackBar; only `refresh()` swallows errors, so a
  transient backend blip does not blank a working screen.

## 5. Networking and the backend contract

The backend is a **separate Node/Express + PostgreSQL repo** (`vistar_CRM`, at
`D:\Vistar\vistar_CRM` on the dev machine). Base URL comes from `ApiConfig.baseUrl`
(`--dart-define=API_BASE_URL=...`), default
`https://vistar-crm.onrender.com/api/v1/lr-management`.

- **Response envelope:** `{ success, data, meta }`. Repositories read
  `res.data['data']`; list endpoints paginate by **cursor** in `meta.next_cursor` —
  always use the shared helper `fetchAllPages(api, '/vehicles', query: {...})`
  (`core/network/paginate.dart`) instead of hand-rolling pagination.
- **Auth:** `POST /auth/login` with `{tenant_code, username, password}` returns
  `{access_token, refresh_token, user}`. Tenant defaults to
  `ApiConfig.defaultTenantCode` (`VISTAR`). `GET /auth/me` returns
  `{ data: { user: {...} } }` — note the nested `user`. Tokens live in
  `flutter_secure_storage`; `ApiClient`'s interceptor attaches
  `Authorization: Bearer`, refreshes on 401, queues concurrent requests during a
  refresh, and retries transient 5xx on GETs. **Do not re-implement any of this in
  a repository.**
- **Optimistic concurrency:** every `PATCH` sends `If-Match: <version>`. A 412 /
  `VERSION_CONFLICT` means the row changed underneath — the notifier refetches and
  we show a "refreshed, please retry" message. Keep the `version` field on models
  you edit.
- **Errors:** dio errors are mapped to `ApiException` (`status`, `code`, `message`,
  `traceId`, `details`) with helpers `isValidation`, `isVersionConflict`,
  `isForbidden`, `isRateLimited`, and so on. Render user-facing text with
  `friendlyErrorMessage(e)` — never dump `e.toString()` into the UI.
- **Idempotency gotcha (known bug, do not make it worse):** an LR create sends an
  idempotency key, and a *failed* save can burn that key so the corrected re-save
  keeps returning 409. If you touch LR save, generate a **fresh** key per attempt.
- Lookup / dropdown values (`PAY_TYPE`, `DELIVERY_TYPE`, `LR_STATUS`,
  `PACKAGE_TYPE`, `VEHICLE_TYPE`, `VEHICLE_CAPACITY`, `ADVANCE_PAID_BY`,
  `TRIP_LEAD_BY`, `EWB_LOAD_TYPE`) are **server-driven** via `lookupsProvider` —
  never hardcode a dropdown list in a widget.

## 6. Models

Plain hand-written Dart classes in `lib/shared/models/` (plus a few in feature
`data/`). No `freezed`, no `json_serializable`, no build_runner.

```dart
class Vehicle {
  const Vehicle({required this.id, required this.number, this.version = 0});
  final String id; final String number; final int version;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(...);
  Map<String, dynamic> toJson() => {...};
  Vehicle copyWith({String? number}) => Vehicle(...);
}
```

- Fields are `final`; classes are immutable; changes go through `copyWith`.
- API JSON is **snake_case**, Dart is **camelCase** — map explicitly in
  `fromJson` / `toJson`.
- Parse defensively (the backend may return a string *or* an object for `role` —
  see `AppUser.fromJson`). Use the helpers in `core/utils/json_parse.dart`.
- Enums (`UserRole`, `LrStatus`) parse from server codes via a `...FromCode(String)`
  static — extend those, don't compare raw strings in the UI.

## 7. Routing

`core/router/app_router.dart` owns every route.

- `routerProvider` builds a single `GoRouter`. It **must not `ref.watch(authProvider)`**
  — that would rebuild the router and wipe in-progress form state (it once made the
  login fields vanish on submit). It reads auth with `ref.read` inside `redirect`,
  and a small listenable pokes the router when auth actually transitions.
- `redirect` handles `/splash` while a saved session is restored, `/login` when
  unauthenticated, and role/permission gates per route.
- Top-level destinations are **shell branches** (`StatefulShellRoute`) so each page's
  widget tree mounts once and is then preserved — sidebar taps are an `IndexedStack`
  visibility swap, with no rebuild and no refetch. Branch pages use `NoTransitionPage`.
- Sub-pages (`/lrs/:id`, `/lrs/new`, admin sub-pages) nest **inside** their branch so
  back-navigation stays in the branch.
- Wrap a routed screen in **`RefreshGate`** to fire a fetch on entry; the notifier
  decides whether to actually refetch (30 s TTL + in-flight dedupe in `LrNotifier`).
- Navigate with `context.go('/lrs')` / `context.push(...)`. Sidebar entries live in
  `core/router/nav_items.dart` with a `canAccess(AppUser)` predicate — add nav items
  there, not by hardcoding a widget in the sidebar.

## 8. Roles and permissions

`UserRole { superAdmin, admin, operator, accounts }` plus a **string permission set**
on `AppUser` (`LR_CREATE`, `LR_EDIT`, `LR_DELETE`, `REPORTS_VIEW`, `MASTERS_MANAGE`,
`MASTER_*_MANAGE`, `VIEW_VISTAR_MARGIN`, `VIEW_TRANSPORTER_RATE`,
`VIEW_CUSTOMER_RATE`, `ADMIN_ACCESS`, `SUPERADMIN_ACCESS`).

- Gate UI with the semantic getters — `user.canCreateLr`, `user.canDeleteLr`,
  `user.canViewVistarMargin`, `user.canManageVehicles` — **never** with ad-hoc
  `role == UserRole.admin` checks inside a screen.
- Operators must not see margins or transporter rates, and only see LRs they created.
- Client-side gating is UX only; the backend enforces the real rule. Never treat a
  hidden widget as security.

## 9. UI conventions

- Colours **only** from `AppColors` (brand plum `#7A1F6E`, orange, amber, ink, slate,
  mist, line, ok/warn/danger). No literal `Color(0x...)` in widgets.
- Typography, inputs, buttons and cards come from `AppTheme.light()` — don't restyle
  locally; extend the theme if something is genuinely missing. The app is
  **light-theme only** today.
- Reuse `shared/widgets/` before writing new ones: `AppButton`, `AppCard`,
  `SectionTitle`, `LabeledField`, `SearchableField` (typeahead master picker),
  `MasterFormDialog` (all master CRUD dialogs), `ConfirmDialog` (destructive
  actions), `LoadingShimmer` (skeletons), `Pills` (status chips).
- Money via `inr(value)`, dates via `formatDate` / `formatDateTime` / `formatTime24`,
  percentages via `pctText` — all in `core/utils/formatters.dart`. Never construct a
  `NumberFormat` / `DateFormat` inline in a build method.
- Layout must work on **web at desktop widths and on mobile** — use `LayoutBuilder`,
  `Wrap`, `Flexible`; never a fixed pixel width for content.
- Show a shimmer/skeleton on first load — never a frozen previous screen, and never a
  bare spinner sitting on top of stale numbers.

## 10. Performance rules (learned the hard way — the recent commits are all perf fixes)

- Hoist `RegExp`, `DateFormat`, `NumberFormat` to top-level `final`s; never build them
  per row.
- Do heavy computation in a memoised `Provider`, not in `build()`.
- Long lists: `ListView.builder`, `const` constructors, stable `Key`s, shallow item
  widgets. Do not build hundreds of rows eagerly.
- Respect the caching layers already there (TTL, in-flight dedupe, generation counters
  that discard superseded fetches). If you add a refresh path, add the same guards and
  bump `activeRefreshCountProvider` around background work.
- `core/utils/perf_log.dart` has gated logging (`kAccPerfLog`) — measure instead of
  guessing.

## 11. Conventions and hygiene

- **Commit style:** `type(scope): imperative summary` — for example
  `perf(accounts): slim the payment card render`,
  `feat(lr): add halting charge field`,
  `fix(auth): keep tokens on transient refresh failure`.
- Comments explain **why**, especially where the code looks odd. That convention is
  dense in this repo and is deliberate. Preserve existing comments; if you change the
  behaviour they describe, update them.
- Keep diffs focused: no drive-by reformatting, no renaming unrelated symbols, no
  reordering imports in a file you barely touched.
- Add or extend a test in `test/` for logic changes (see `advance_percent_test.dart`,
  `lr_number_format_test.dart`, `progressive_load_test.dart` for the style).
- `flutter analyze` clean and `flutter test` green **before** I review anything.

## 12. Hard "do not" list

1. Do **not** introduce another state management library, or rewrite existing
   `StateNotifier`s into `AsyncNotifier` / codegen.
2. Do **not** call dio or http from a widget or a model.
3. Do **not** hardcode dropdown options, colours, currency/date formats, URLs, or
   permission strings scattered across screens.
4. Do **not** add packages, run `build_runner`, or change `pubspec.yaml` / CI without
   asking me.
5. Do **not** commit secrets, `.env` files, tokens, or customer data. Don't touch
   `build/` or `.dart_tool/` (both gitignored).
6. Do **not** push to `main` or deploy. Pushing `main` auto-deploys to Cloudflare Pages
   via `.github/workflows/deploy-cloudflare.yml` (analyze -> test -> build web ->
   `wrangler pages deploy`). Work on a feature branch and open a PR.
7. Do **not** add a caching service worker to `web/` — it strands users on old builds
   (see `DEPLOYMENT.md`).
8. Do **not** change the backend from this repo unless I say so; a backend change must
   be deployed **before** the frontend code that depends on it goes live.
9. Do **not** delete or "clean up" code you don't understand — ask.

## 13. Domain glossary

- **LR (Lorry Receipt)** — the core consignment document; numbered series, 4 printable
  copies, status flow (booked -> in-transit -> delivered), attachments.
- **Consignor** = sender. **Consignee** = receiver. **Party / Customer** = the billed
  entity. **Transporter** = the vendor supplying the vehicle.
- **Route** — origin-to-destination pair; carries vehicle type and vehicle capacity,
  which an LR auto-inherits.
- **Freight** — the customer rate. Extra heads: additional freight, express charges,
  extra point delivery, halting charge. **Advance %** is what we pay the transporter
  up front.
- **Vistar margin** = customer rate minus transporter rate (restricted visibility).
- **EWB (E-Way Bill)** — 12-digit GST document with expiry tracking.
- **MIS** — management reports / Excel exports (region-wise, user-wise).
- **Tally export** — the accounting hand-off format.

## 14. How I want you to work on a task

1. **Restate the goal** in one or two sentences and list the files you expect to touch.
   If anything is ambiguous, ask **before** writing code.
2. **Read the existing code around it first** and follow the nearest existing pattern
   rather than a generic tutorial pattern.
3. Implement the **smallest change that fully does the job**, layer by layer:
   model -> repository -> provider -> screen.
4. Tell me exactly what to run to see it work, and what I should expect to see.
5. List anything you left out, assumed, or could not verify — especially anything that
   needs a **backend change** (new endpoint, column, or permission), because that ships
   from a different repo and must go first.
6. If you are guessing about an endpoint, field name, or widget, say "I'm not sure this
   exists — grep for X" instead of inventing it.

## TASK

<describe the task here: what should change, on which screen, the expected behaviour,
and paste any error message or description of the screenshot you have>

--- END PROMPT ---
