---
name: flutter-ui-review
description: Design-system checklist and pitfall list for this app's Flutter UI (widgets, screens, theme, routing). Use this whenever writing or editing anything under lib/features/**/presentation/**, lib/core/theme/**, lib/core/widgets/**, lib/app.dart, or lib/core/router/**, or whenever the user asks for a new screen, a UI/UX pass, better colors/contrast, animations/transitions, responsive layout, or mentions the app looking "wrong"/"feo"/"no se ve bien" on some device. Also consult it before adding any Chip/Chip-like selectable control, before touching MediaQuery/text-scaling, or before adding a new route — this project has already hit real bugs in exactly those spots and this skill exists so they don't get reintroduced.
---

# Flutter UI review — Appmobile-gob

This app's design system already exists and is consistent; the job here is almost
never "invent a new pattern," it's "find the existing one and reuse it." Reach for
`lib/core/theme/`, `lib/core/utils/responsive.dart`, and the reference widgets named
below before writing new layout/color/animation code from scratch.

Read this whole file before touching UI code — it's short on purpose. If you're about
to write a `Container` with a hand-picked color, a `Chip`, a `MediaQuery.clamp`, or a
new route transition, one of the sections below almost certainly already covers it.

## Design tokens — use these, don't hardcode numbers/colors

- Spacing/radius/sizing: `lib/core/theme/app_spacing.dart` — `AppSpacing.xs/sm/md/lg/xl/xxl`,
  `radiusSm/Md/Lg`, `minTouchTarget` (52), `buttonHeight` (56). A bare `16` or `8` in new
  layout code is a sign you should be reaching for one of these instead.
- Color: `lib/core/theme/app_theme.dart` — light/dark via `ColorScheme`, always resolved
  through `Theme.of(context).colorScheme`, never a literal `Color(0x...)` in a widget.
- Text: `lib/core/theme/app_text_styles.dart`, via `Theme.of(context).textTheme`.
- Breakpoints: `AppBreakpoints.tablet` (600) / `AppBreakpoints.desktop` (1024) in the same
  file as spacing.

## Responsive — every screen gets checked at more than one width

This audience uses phones, but tablets are an explicit target too ("optimizado para
tabletas" shows up in this codebase's own comments) — a screen that only looks right at
one width isn't done.

- Wrap page content in `ResponsiveCenter` (`lib/core/utils/responsive.dart`) so it gets
  sensible max-width + padding for free instead of stretching edge-to-edge on a tablet.
- Branch layout with `Responsive.isTabletOrWider(context)` / `Responsive.gridColumns(context)`
  when a screen genuinely needs a different shape at different widths (grid vs. list,
  stacked cards vs. table). The canonical example is `_MatrixField` in
  `lib/features/surveys/presentation/widgets/question_field.dart` —
  `_buildStackedCards` on phones, `_buildTable` on tablet/desktop, same data either way.
- Before calling a UI change done: actually resize/preview at a phone width and a
  tablet/desktop width. A layout that only got eyeballed at one size is the most common
  way a "finished" screen turns out broken for part of the audience.

## Contrast — the bug that actually happened here

A plain `ChoiceChip`/`FilterChip` relying on this app's `chipTheme.labelStyle` (which has
no explicit `color`) rendered **nearly invisible text** once placed over a non-neutral
background like `colorScheme.surfaceContainerLow` — the label just inherited whatever
ambient text color was nearby, which wasn't guaranteed to contrast with that specific
chip background. It shipped, looked fine to skim past, and only showed up as a real bug
on an actual device.

The fix, and the pattern to reuse for *any* new selectable/colored surface (chip, tile,
badge, tag) — don't fight it with a one-off text color, choose a background/border pairing
that's safe with the *default* on-surface text color sitting on top of it:

- Unselected: `border: colorScheme.outlineVariant`, `background: colorScheme.surface`.
- Selected: `border: colorScheme.primary` (width 2 vs 1.5 unselected),
  `background: colorScheme.primaryContainer.withValues(alpha: 0.55)`.
- Reference implementations: `_ChoiceTile` and `_MatrixOptionChip` in
  `lib/features/surveys/presentation/widgets/question_field.dart`.

Before shipping any new colored chip/tile/badge: hold it up against this pattern.
If it needs a custom text color to be readable, that's the signal something's off —
change the background instead of patching the text color.

## Animation — state changes transition, they don't snap

Selecting/deselecting something (a chip, a tile, a toggle) should visibly transition,
not jump. `_MatrixOptionChip` is the reference: `AnimatedContainer` for
border/background (~180ms, `Curves.easeOut`), `AnimatedDefaultTextStyle` for the label
weight change, `AnimatedSwitcher` for the checkmark appearing/disappearing. Match that
duration/curve for consistency rather than picking new ones per widget.

Route-level transitions already exist in `lib/core/router/app_router.dart` — reuse them,
don't invent a third style:
- `_fadeThrough` (220ms cross-fade): top-level destinations (tabs, login).
- `_slideUp` (260ms slide+fade, `easeOutCubic`): screens pushed on top of the shell
  (detail, fill, success, profile) — signals "going deeper" vs. "switching section."

## MediaQuery / text scaling — don't hand-roll this

This app clamps OS text-scaling to `[1.0, 1.4]` (readability accessibility need for an
older audience, but capped so an extreme OS setting can't break layout). The first
version of this did it by manually reading `MediaQuery.of(context).textScaler`, calling
`.clamp(...)` once, and rebuilding `MediaQuery` via `copyWith` at the app root
(`lib/app.dart`'s `builder`). That crashed — `'maxScale > minScale': is not true` —
inside `showDatePicker` on a device with a large OS text-scale setting, because a dialog
opening its own nested `MediaQuery` scope didn't compose safely with a value computed
once, up front, outside a `Builder`.

Use `MediaQuery.withClampedTextScaling(minScaleFactor:, maxScaleFactor:, child:)` instead
— it's the framework's own replacement for exactly that hand-rolled pattern, and resolves
correctly per-subtree. If you ever need text-scale clamping somewhere else in the app,
reach for this API, not the manual `copyWith` version.

## AppBar / icons — keep it consistent, not just "a valid icon"

- Prefer Material `*_rounded` icon variants for filled/active/action icons
  (`Icons.assignment_rounded`, `Icons.sync_rounded`, `Icons.logout_rounded`,
  `Icons.cloud_done_rounded`); `*_outlined` for a neutral/unselected entry point
  (`Icons.account_circle_outlined` for the profile entry point in the survey list app bar).
  Mixing filled and outlined arbitrarily on the same bar reads as inconsistent even when
  each icon individually is a reasonable choice.
- AppBar titles: short and human, not a route name — e.g. `'Hola, ${user.name.split(' ').first}'`
  rather than `'Encuestas'` once a user is known.
- Cap app bar `actions` at 1-2 icon buttons. If a screen needs more entry points than
  that, it's a sign some of them belong inside a screen the icon opens (see: profile
  screen absorbing the logout confirm-dialog that used to live directly in the survey
  list's app bar) rather than stacked in the bar itself.

## Accessibility — this audience specifically

Comments elsewhere in this codebase spell out the target audience as skewing
older/less tech-familiar — that's a real constraint on interaction design, not just a
copy note:

- Minimum touch target `AppSpacing.minTouchTarget` (52px), bigger than Material's own
  48px baseline.
- Prefer tap-based selection over gesture-heavy controls (sliders, swipes, drag) — see
  `_ChoiceTile`'s doc comment for the reasoning. A slider might be more "modern" but is
  harder to operate precisely for this audience; a row of tappable options isn't.
- Don't disable OS text-scaling entirely (real accessibility need) and don't let it break
  layout either — see the MediaQuery section above.

## Before calling a UI change done

1. Checked at a phone width **and** a tablet/desktop width.
2. Checked in light **and** dark theme.
3. Any new colored chip/tile/badge matches the contrast pattern above (background+border
   pairing, no one-off text color).
4. Selection/state changes animate (~150-200ms, `Curves.easeOut`), don't snap.
5. Any new route reuses `_fadeThrough` or `_slideUp` rather than a new transition style.
6. Touch targets ≥ `AppSpacing.minTouchTarget`; icon choice matches the filled/outlined
   convention above.
