---
name: mobile-ui-ux-optimization
description: >-
  Expert guidelines for Flutter mobile UI/UX enhancements, responsive layouts, 60/120fps fluid performance,
  and battery/resource optimization. Use when refining interfaces, fixing lag/jank, eliminating memory leaks,
  preventing widget rebuilds, improving responsiveness across mobile/tablet/desktop, or enhancing touch/haptic interactions.
---

# Mobile UI/UX & Resource Optimization Guide — Flutter

This guide contains best practices and actionable checklists for ensuring high-performance, fluid (60/120 FPS), battery-efficient, accessible, and fully responsive Flutter mobile applications with institutional-grade design systems.

---

## 1. UI/UX Standards & Design Tokens

### Consistent Design Tokens
- **Spacing & Radius**: Always use `AppSpacing` tokens (`AppSpacing.xs/sm/md/lg/xl/xxl`, `radiusSm/Md/Lg`). Never hardcode magic numbers (e.g. bare `16`, `8`, `24`).
- **Colors**: Always resolve colors from `Theme.of(context).colorScheme` or centralized constants (`AppColors`). Never hardcode raw hex values in individual widget trees.
- **Institutional Brand Hierarchy**:
  - **Top Bars & Hero Headers**: Solid `colorScheme.tertiary` (Brand Red) with `onTertiary` foreground.
  - **Headings & Titles**: `colorScheme.secondary` (Brand Magenta) for high visual emphasis.
  - **Subtitles & Supporting Labels**: `colorScheme.primary` (Brand Green/Teal) or `onSurfaceVariant`.
  - **Primary Action Buttons**: `colorScheme.secondary` background with high-contrast white text.
  - **Bottom Navigation**: Fixed dark background (`AppColors.brandBlack`) with tan accents (`AppColors.brandTan`).
- **No Heavy Gradients/Shadows**: Keep the UI flat, clean, and modern. Elevation should be `0` with subtle border outlines (`outlineVariant`) rather than heavy drop shadows.

### Micro-interactions & Tactile Feedback
- **Haptic Feedback**: Add subtle tactile cues on key user actions (`HapticFeedback.lightImpact()` on button presses, `HapticFeedback.selectionClick()` on chip/radio/checkbox selections). This gives a native, high-end feel without consuming measurable CPU/battery.
- **State Transitions**: Animate state changes smoothly (~150–250ms with `Curves.easeOut` or `Curves.easeOutCubic`) using `AnimatedContainer`, `AnimatedScale`, `AnimatedOpacity`, or `AnimatedSlide`. Avoid abrupt visual snaps.
- **Touch Target Sizing**: Maintain touch targets $\ge 52\text{px}$ (`AppSpacing.minTouchTarget`) for accessible, error-free tapping on mobile screens.

---

## 2. Fluidity & Resource/Battery Optimization (60/120 FPS)

### Eliminate Expensive GPU Layers (`saveLayer`)
- **Avoid `Opacity` Widget**: Wrapping widgets in `Opacity(opacity: ...)` forces Flutter into offscreen rendering (`saveLayer`), causing unnecessary GPU draw passes and draining mobile battery.
  - **Fix for images/textures**: Use `DecorationImage(opacity: 0.16, ...)` or `ResizeImage`.
  - **Fix for colors**: Use `color.withValues(alpha: ...)` or `Color.fromRGBO(...)`.

### Smart State Management & Rebuild Isolation (Riverpod)
- **Use `.select()` on Providers**: Avoid watching entire composite state objects or lists if a widget only depends on a single field or length.
  ```dart
  // ❌ Bad: rebuilds when any property inside the list changes
  final count = ref.watch(syncableResponsesProvider).valueOrNull?.length ?? 0;

  // ✅ Good: only rebuilds when the count integer changes
  final count = ref.watch(
    syncableResponsesProvider.select((s) => s.valueOrNull?.length ?? 0),
  );
  ```
- **Extract Stateful Subtrees**: Keep high-frequency mutations (like text field typing or animations) in isolated stateful widgets or localized notifiers so the parent screen doesn't rebuild every frame.

### Memory & List Virtualization
- **Lazy Rendering**: Use `ListView.builder`, `GridView.builder`, or `CustomScrollView` with `SliverList`/`SliverGrid` for variable or large datasets. Avoid eager `Wrap` or `Column` inside a `SingleChildScrollView` when displaying growing collections.
- **Const Constructors**: Use `const` widgets wherever possible to enable compile-time caching and skip reconciliation during widget tree rebuilds.
- **Image Resizing**: Always constrain decoded image sizes using `ResizeImage` with `devicePixelRatio` to prevent large image allocations in memory (RAM).

### I/O, Network & Database Throttling
- **Debounced Autosave**: When saving form inputs or drafts to SQLite/Drift, debounce writes by `300–500ms` so disk I/O isn't triggered on every single keystroke.
- **Non-blocking Background Operations**: GPS fixes (`LocationService`) and sync jobs must run asynchronously in the background (`unawaited`), never blocking the main UI thread.

---

## 3. Responsive Layouts & Accessibility

### Multi-Screen Scaling
- **Breakpoints**:
  - Phone: $< 600\text{px}$ (single column, stacked inputs, vertical flow).
  - Tablet: $600\text{px} - 1023\text{px}$ (multi-column grids, list/detail or matrix tables).
  - Desktop: $\ge 1024\text{px}$ (capped content width with `ResponsiveCenter`, max width 900px).
- **Responsive Wrappers**: Wrap page content with `ResponsiveCenter` so wide screens look balanced and text lines don't stretch excessively edge-to-edge.
- **Adaptive Matrix/Tables**: Display Likert/matrix questions as stacked cards with chip options on narrow phones, and switch to clean `Table` views on tablets/desktop.

### Text-Scale Clamping & Overflow Prevention
- **Accessible Scaling**: Clamp system font scaling to `[1.0, 1.4]` via `MediaQuery.withClampedTextScaling(...)` at the root.
- **Preventing `RenderFlex` Overflows**:
  - Always verify layouts at **1.4x text scale**.
  - For rows containing text or inputs with variable label lengths, use `Column` (stacked) or `Wrap` rather than rigid `Row(children: [Expanded(...)])` slices.
  - Apply `overflow: TextOverflow.ellipsis` and `maxLines` on titles and dynamic server-provided labels.

### Keyboard & Focus UX
- Dismiss software keyboards smoothly when tapping outside input fields:
  ```dart
  GestureDetector(
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    behavior: HitTestBehavior.translucent,
    child: ...
  )
  ```

---

## 4. Verification Checklist Before Delivery

1. **Static Analysis**: `flutter analyze` passes with 0 errors and 0 deprecated warnings.
2. **Tests**: All widget and unit tests pass (`flutter test`).
3. **Responsive Check**: Screen looks visually balanced on phone width (360–400px) and tablet width (600–800px+).
4. **Text Scale Check**: No yellow/black overflow stripes at 1.4x font scale.
5. **GPU & Battery Check**: No unnecessary `Opacity` widgets wrapping background decor.
6. **Rebuild Check**: Riverpod providers use `.select()` where applicable.
7. **Offline Support**: Offline states and banners communicate clearly without blocking the user.
