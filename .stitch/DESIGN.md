# Design System: DTServices Premium

## 1. Visual Theme & Atmosphere
A restrained, highly-legible daily-utility interface with confident asymmetric spacing and tactile spring-physics interactions. The atmosphere is clinical yet premium — like a high-end fintech application. It prioritizes clarity for dense telecom data (data plans, credit balances, OTPs) through structural whitespace and strong typographic hierarchy, avoiding visual clutter and unnecessary bounding boxes.

## 2. Color Palette & Roles
- **Canvas White** (`#F9FAFB`) — Primary background surface for the whole application.
- **Pure Surface** (`#FFFFFF`) — High-elevation card and container fill.
- **Charcoal Ink** (`#18181B`) — Primary text, headings, and high-emphasis data.
- **Muted Steel** (`#71717A`) — Secondary text, helper descriptions, and metadata.
- **Whisper Border** (`rgba(226,232,240,0.5)`) — Card borders and 1px structural dividers.
- **Signal Cobalt** (`#0258d4`) — Single accent color for CTAs, active states, progress indicators, and focus rings. (Muted saturation, professional and trustworthy. No purple/neon).

## 3. Typography Rules
- **Display/Headlines:** `Outfit` — Track-tight, controlled scale, weight-driven hierarchy. Used for section titles and primary greetings.
- **Body:** `Satoshi` — Relaxed leading, highly readable secondary text.
- **Numbers & Metrics:** `JetBrains Mono` — Used strictly for telecom data: account balances, data quotas, phone numbers, and OTP input fields to ensure rigid vertical alignment.
- **Banned:** `Inter`, `Roboto` (too generic), generic serif fonts.

## 4. Component Stylings
- **Buttons:** Flat rectangles with slightly rounded corners (0.5rem). No drop shadows on buttons, no outer glow. Tactile -1px downward translate on active press. Accent fill for primary, ghost/outline for secondary.
- **Cards:** Moderately rounded corners (1rem). Diffused whisper shadow only when elevation signifies a floating interaction (e.g., a modal or biometric prompt). High-density dashboard areas: replace cards with bottom-border dividers.
- **Inputs & Forms (OTP/Login):** Minimalist block inputs. Label above, error strictly below. Focus ring in Signal Cobalt. Never use floating labels.
- **Loaders:** Skeletal shimmer that exactly matches the expected layout dimensions of top-ups or balance queries. No generic circular spinners.
- **Empty States:** Composed, illustrated compositions showing how to add a service — not just "No data available" centered text.

## 5. Layout Principles
- Mobile-First strict layout constraint. No horizontal scrolling outside of explicit carousel elements (like multiple registered numbers).
- No overlapping layers or elements absolute-positioned over typography. Every piece of data occupies its own clear spatial zone.
- Asymmetric Hero/Header section (e.g., Avatar left, Welcome text right).
- Consistent internal padding (`1.5rem` / `24px` margins minimum on mobile edges).

## 6. Motion & Interaction
- Spring physics default (`stiffness: 100, damping: 20`) for route transitions and modal presentations to provide a weighted, premium feel. 
- Fast, tactile click responses. Staggered cascade reveals when mounting horizontal lists (like TopUp packages).
- Perpetual micro-loops on critical components (e.g., a subtle pulse on the biometric scan prompt).

## 7. Anti-Patterns (Strictly Banned)
- NEVER DO: "AI Purple/Blue Neon" aesthetic — no purple button glows, no neon gradients.
- NEVER DO: Pure black (`#000000`).
- NEVER DO: Inter font.
- NEVER DO: 3-column equal grid layouts or flexbox percentage math.
- NEVER DO: Filler copy ("Scroll to explore", "Next-Gen Telecom app").
- NEVER DO: Broken/fake data widgets ("18.5k SYSTEM STATS"). All placeholders must visibly look like dummy data: `[BALANCE]`.
- NEVER DO: Custom generic serif fonts.
- NEVER DO: Overlapping typography.
