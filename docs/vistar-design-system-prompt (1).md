# Build Prompt — "Vistar Premium" Design System

Paste everything below into a fresh AI session (or hand it to a developer). It reproduces the **exact** UI/UX, fonts, theme, logo usage, loaders, background, and shimmer of the Vistar Hire app — only the application's purpose and screens change.

> **How to use:** Fill in the one section marked `<<< … >>>`, attach the two Vistar logo files (`logo_name.png` = wordmark, `logo.png` = the "S" swoosh), and send. Everything else is fixed and should be reproduced verbatim.

---

## ROLE & GOAL

You are a senior product designer + frontend engineer. Build a **high-end, premium, dark-themed** single-file interactive HTML/CSS/JS prototype (no build step, works offline, opens in any browser). It must look polished and distinctive — never generic or "default AI." Reuse the **exact design system** specified below. Do not invent new colors, fonts, or component styles; only the app's content and screens differ.

## THE APP TO BUILD

```
<<< DESCRIBE YOUR APP HERE:
- App name + one-line purpose
- The user roles (if any) and what each can do
- The list of screens from login → last screen
- Key modules / data per screen
- Any domain-specific demo data flavour
>>>
```

Walk the flow **login → … → last screen**. If there are multiple roles, add a top-bar "View as role" switcher that rebuilds the sidebar nav and landing screen per role, so every role's screens are demonstrable in one file.

---

## BRAND ASSETS (use the two attached Vistar logos)

Process each logo once, then embed as a base64 `data:` URI inside the HTML (so the file is fully self-contained — no external image links):

1. **Remove the black background → transparent**, autocrop tight, then resize.
2. Create three variants:
   - **S mark ~360px** (`logo.png`, the rainbow swoosh) — used for loaders, watermark, card corners.
   - **S mark ~140px** — small UI spots.
   - **Wordmark ~486px wide** (`logo_name.png`) — splash + login only.
3. Inline each as `url(data:image/png;base64,…)` in the CSS.

**Where each asset appears (do not change these placements):**

| Asset | Used in |
|---|---|
| **S mark** | Splash orbit loader · route-change loader overlay · faint full-page background watermark · card bottom-right corner accent · sidebar brand glyph · login mini-mark |
| **Wordmark** | Splash screen · login left panel |

---

## DESIGN TOKENS — paste this `:root` block verbatim

```css
:root{
  /* Vistar brand ribbon */
  --purple:#7A1FB0; --violet:#9B30C9; --magenta:#C018C0; --pink:#E0218A;
  --red:#C8102E; --orange-red:#F0480C; --orange:#F06000; --amber:#F0C000;
  --yellow:#F0E060; --cream:#FFF6CC;
  --ribbon:linear-gradient(115deg,#7A1FB0 0%,#B81FB8 22%,#E0218A 40%,#D11630 56%,#F0480C 70%,#F06000 80%,#F0C000 92%,#F7EE9A 100%);
  --ribbon-soft:linear-gradient(115deg,rgba(155,48,201,.9),rgba(224,33,138,.9),rgba(240,72,12,.9),rgba(240,192,0,.9));

  /* Surfaces (near-black premium) */
  --bg:#070611; --bg2:#0B0A18;
  --surface:#110F1E; --surface2:#16142A; --surface3:#1D1A33;
  --line:rgba(255,255,255,.08); --line2:rgba(255,255,255,.13);
  --txt:#F2EEFB; --txt2:#B9B2D6; --txt3:#7E769B;
  --ok:#34D399; --warn:#FBBF24; --bad:#FB6F84; --info:#5BA8FF;
  --r:16px; --r-sm:11px; --r-lg:22px;
  --shadow:0 24px 60px -28px rgba(0,0,0,.85);
  --glow:0 0 0 1px rgba(255,255,255,.05), 0 18px 50px -22px rgba(192,24,192,.4);
}
```

**Rules:** The rainbow `--ribbon` gradient is the signature accent — use it sparingly and with intent (primary buttons, the active-nav left bar, section accents, KPI numbers via `background-clip:text`, the "on" role chip). Everything else stays in the dark surface/line/text scale. Never use flat saturated brand colors as large fills; the ribbon is for thin accents and small highlights only.

---

## TYPOGRAPHY

Load via Google Fonts (graceful system fallback if offline):

```html
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,600;12..96,700;12..96,800&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
```

- **Bricolage Grotesque** → all display text: `h1–h4`, page titles, KPI numbers, brand name. `letter-spacing:-.4px`.
- **Manrope** → all body, labels, table text, inputs. `letter-spacing:.1px`, antialiased.

---

## SIGNATURE "S" TREATMENTS (reproduce all five exactly)

```css
/* 1) Ambient page background: aurora glows + faint S watermark + grain */
#ambient{position:fixed;inset:0;z-index:0;overflow:hidden;background:
  radial-gradient(800px 600px at 12% -8%,rgba(122,31,176,.22),transparent 60%),
  radial-gradient(700px 600px at 105% 8%,rgba(224,33,138,.16),transparent 55%),
  radial-gradient(900px 700px at 80% 110%,rgba(240,96,0,.12),transparent 55%),
  var(--bg);}
#ambient .swoosh{position:absolute;right:-6%;top:50%;transform:translateY(-50%) rotate(4deg);
  width:62vmax;height:62vmax;background:url(S_MARK) center/contain no-repeat;
  opacity:.05;filter:saturate(1.2) blur(.4px);pointer-events:none;}
#ambient .grain{position:absolute;inset:0;opacity:.045;mix-blend-mode:overlay;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");}

/* 2) Splash orbit loader: two counter-spinning rings + breathing S + wordmark + ribbon bar */
.s-orbit{width:200px;height:200px;position:relative;display:grid;place-items:center}
.s-orbit .ring{position:absolute;inset:0;border-radius:50%;border:1.5px solid transparent}
.s-orbit .ring.r1{border-top-color:rgba(224,33,138,.65);border-right-color:rgba(240,96,0,.4);animation:spin 1.6s linear infinite}
.s-orbit .ring.r2{inset:22px;border-bottom-color:rgba(155,48,201,.65);border-left-color:rgba(240,192,0,.45);animation:spin 2.2s linear infinite reverse}
.s-orbit .smark{width:96px;height:97px;background:url(S_MARK) center/contain no-repeat;animation:breathe 2.2s ease-in-out infinite;filter:drop-shadow(0 0 26px rgba(224,33,138,.55))}
.splash-bar{width:200px;height:4px;border-radius:10px;background:rgba(255,255,255,.07);overflow:hidden}
.splash-bar i{display:block;height:100%;width:40%;border-radius:10px;background:var(--ribbon);animation:load 1.4s ease-in-out infinite;background-size:200% 100%}

/* 3) Route-change loader overlay (shown ~360ms on every screen switch) */
#routeload{position:absolute;inset:0;z-index:20;display:none;place-items:center;background:rgba(7,6,17,.55);backdrop-filter:blur(2px)}
#routeload.on{display:grid}
#routeload .s{width:64px;height:65px;background:url(S_MARK) center/contain no-repeat;animation:breathe 1s ease-in-out infinite;filter:drop-shadow(0 0 18px rgba(224,33,138,.5))}

/* 4) Skeleton shimmer (rainbow sweep, S-themed) — use while "loading" */
.skel{position:relative;overflow:hidden;background:var(--surface2);border-radius:10px}
.skel::after{content:"";position:absolute;inset:0;transform:translateX(-100%);
  background:linear-gradient(90deg,transparent,rgba(224,33,138,.16),rgba(240,96,0,.12),transparent);animation:shimmer 1.3s infinite}

/* 5) Card corner S accent */
.card .corner-s{position:absolute;right:-26px;bottom:-30px;width:120px;height:120px;background:url(S_MARK) center/contain no-repeat;opacity:.05}

/* keyframes */
@keyframes spin{to{transform:rotate(360deg)}}
@keyframes breathe{0%,100%{transform:scale(.92) translateY(2px)}50%{transform:scale(1.04) translateY(-2px)}}
@keyframes load{0%{transform:translateX(-110%)}100%{transform:translateX(360%)}}
@keyframes shimmer{100%{transform:translateX(100%)}}
@keyframes fade{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}
```

Replace `S_MARK` with the inlined base64 of the S mark.

---

## LAYOUT / SHELL PATTERN

1. **Splash** (z 90) — radial dark glow bg, orbit S loader, wordmark, uppercase tagline (`letter-spacing:3px`), ribbon progress bar. Auto-hides after ~2.2s.
2. **Login** (z 80) — split `grid-template-columns:1.05fr .95fr`:
   - **Left "art" panel:** radial brand glows + huge rotated faint S (`opacity:.16`), wordmark top, a pitch headline (one word ribbon-gradient via `background-clip:text`), short paragraph, 2–3 stat figures.
   - **Right "form" panel** (`--bg2`): mini S, title, fields (`.inp` with pink focus ring), gradient primary button, and a role-picker grid of `.role-chip`s (active chip uses `--ribbon`).
3. **App shell** (`#app`, fade-in) — `grid-template-columns:248px 1fr`:
   - **Sidebar:** brand row (S glyph + Bricolage name + tiny caption), grouped nav with uppercase group labels; active item = soft ribbon tint + 3px ribbon left bar (`.nav.on::before`) + optional count badge; footer user block with ribbon `.avatar`.
   - **Topbar (64px, blurred):** search box, spacer, optional role switcher (`select`), icon buttons with notification dot, avatar.
   - **Canvas:** scrollable, contains `#routeload` overlay + a `#screens` host. Each screen mounts as `.screen.active` with the `fade` animation. A page header pattern: breadcrumb (with ribbon-gradient accent word), big title, description, right-aligned action buttons.

---

## COMPONENT LIBRARY (match these recipes)

```css
/* Buttons */
.btn{border:none;border-radius:var(--r-sm);padding:13px 18px;font-weight:700;font-size:14px;transition:.18s;display:inline-flex;align-items:center;gap:9px;justify-content:center}
.btn-grad{background:var(--ribbon);background-size:160% 160%;color:#fff;box-shadow:0 14px 34px -14px rgba(224,33,138,.7)}
.btn-grad:hover{background-position:100% 0;transform:translateY(-1px)}
.btn-ghost{background:var(--surface2);color:var(--txt);border:1px solid var(--line)}
.btn-ghost:hover{border-color:var(--line2);background:var(--surface3)}
.btn-sm{padding:9px 14px;font-size:13px;border-radius:10px}

/* Inputs */
.inp{width:100%;background:var(--surface);border:1px solid var(--line);border-radius:var(--r-sm);padding:13px 14px;color:var(--txt);font-size:14px;transition:.18s;outline:none}
.inp:focus{border-color:rgba(224,33,138,.6);box-shadow:0 0 0 4px rgba(224,33,138,.12);background:var(--surface2)}

/* Card + KPI */
.card{background:linear-gradient(180deg,rgba(22,20,42,.7),rgba(17,15,30,.7));border:1px solid var(--line);border-radius:var(--r);padding:18px;position:relative;overflow:hidden}
.card.glow:hover{border-color:var(--line2);box-shadow:var(--glow);transform:translateY(-2px);transition:.2s}
.kpi .ic{width:38px;height:38px;border-radius:11px;display:grid;place-items:center;background:rgba(224,33,138,.12);color:var(--pink)}
.kpi .val{font-family:"Bricolage Grotesque";font-size:30px;font-weight:800;margin-top:14px;line-height:1}

/* Section title with ribbon accent */
.sect-ttl{font-size:15px;font-weight:800;margin-bottom:13px;display:flex;align-items:center;gap:9px}
.sect-ttl .acc{width:5px;height:16px;border-radius:6px;background:var(--ribbon)}

/* Table */
.tbl-wrap{border:1px solid var(--line);border-radius:var(--r);overflow:hidden;background:var(--surface)}
thead th{text-align:left;padding:13px 16px;font-size:11px;letter-spacing:.6px;text-transform:uppercase;color:var(--txt3);font-weight:700;background:var(--surface2);border-bottom:1px solid var(--line)}
tbody td{padding:13px 16px;border-bottom:1px solid var(--line);color:var(--txt2)}
tbody tr:hover{background:var(--surface2)}

/* Status pills — translucent tint + colored dot. Define a family keyed to your app's statuses */
.pill{display:inline-flex;align-items:center;gap:6px;padding:4px 10px;border-radius:20px;font-size:11.5px;font-weight:700;white-space:nowrap}
.pill .d{width:6px;height:6px;border-radius:50%}
/* e.g. info → rgba(91,168,255,.14); amber → rgba(240,192,0,.14); violet → rgba(155,48,201,.18);
   pink → rgba(224,33,138,.16); green/ok → rgba(52,211,153,.14); orange → rgba(240,96,0,.16);
   bad → rgba(251,111,132,.14); neutral → rgba(255,255,255,.07) */
```

Also include, styled consistently: **avatars** (rounded-square, ribbon bg, initials), **tabs**, **segmented toggles**, **filter chips**, **1–5 rating dots** (fill up to selected), and a **toast** (slide-in confirmation). Custom scrollbars use a translucent violet thumb that brightens to pink on hover. `::selection` is translucent pink.

---

## BUILD CONSTRAINTS & QUALITY BAR

- **One self-contained `.html` file.** All CSS + JS inline; all images inlined as base64. No external requests except the Google Fonts link. No frameworks required (vanilla JS router is fine: a `go(screen)` function that flashes `#routeload`, then swaps `#screens` innerHTML).
- **Dark theme only.** Generous negative space, crisp 1px hairline borders (`--line`), soft shadows, `border-radius` from the token scale. Mobile-friendly where the role implies it.
- **Realistic, domain-specific demo data** — never "Lorem ipsum" or "User 1." Make it feel like a real working instance of the app described above.
- **Restraint with the rainbow:** thin accents and small highlights only; the canvas stays dark and quiet so the ribbon pops.
- **No browser storage APIs** (`localStorage`/`sessionStorage`) — keep all state in JS variables/in-memory.
- Validate that the script boots with **zero console errors** and every screen renders before delivering.

The result should feel like a single premium product family: change the app, keep the soul.
