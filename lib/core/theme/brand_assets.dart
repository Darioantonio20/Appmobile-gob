/// Official Gobierno de Chiapas 2024–2030 brand assets ("Humanismo que
/// Transforma"), bundled under `assets/branding/`. Centralized here so
/// every screen that needs one of these references the same path instead
/// of a scattered string literal.
class BrandAssets {
  BrandAssets._();

  /// Vertical "grecas" pattern (Mayan-inspired geometric motif, brand
  /// primary/tertiary colors) — used as a thin decorative accent strip,
  /// tiled vertically ([ImageRepeat.repeatY]), never stretched.
  static const String grecas = 'assets/branding/grecas.png';

  /// The primary app mark: icon + "Humanismo que Transforma" + "Gobierno de
  /// Chiapas 2024–2030". This is the one to show wherever the app needs a
  /// single, recognizable brand mark (login hero, splash).
  static const String humanismoQueTransforma = 'assets/branding/logo_humanismo_que_transforma.png';

  /// The complete institutional lockup — [humanismoQueTransforma] plus
  /// "Secretaría Ejecutiva del Sistema Anticorrupción del Estado de
  /// Chiapas". Wide format; use where there's room for a footer-style
  /// attribution rather than as a hero.
  static const String secretaria = 'assets/branding/logo_secretaria.png';
}
