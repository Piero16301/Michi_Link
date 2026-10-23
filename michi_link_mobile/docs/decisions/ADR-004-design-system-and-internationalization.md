# ADR-004: Expressive Design System and Flutter l10n Internationalization

## Status
Accepted

## Date
2026-10-23

## Context
Michi Link Mobile requires an expressive, modern, and accessible user experience (Material 3 Expressive) with dynamic personalization (user-selected base seed color, light/dark mode transitions, and custom typography). In addition, full multi-language support (English and Spanish as baseline) must be supported with compile-time type safety.

## Decision
1. **Design System with `expressive_kit` and `material_ui`**:
   - Adopts Material 3 Expressive design tokens.
   - Algorithmic tonal palette generation from a single `baseColor` (`ExpressiveTheme.light` and `ExpressiveTheme.dark`).
   - Dynamic font family switching at runtime without app restarts.
2. **Official Flutter Localization (`flutter_localizations` + `intl`)**:
   - Standard ARB files (`lib/l10n/arb/app_en.arb`, `app_es.arb`).
   - Automated code generation managed via `l10n.yaml` targeting `lib/l10n/gen`.
   - Context extension `context.l10n` for clean, type-safe string resolution.

## Alternatives Considered

### Standard Flutter ThemeData without ExpressiveKit
- **Pros**: Zero additional external UI dependencies.
- **Cons**: Substantial manual boilerplate required to produce harmonious tonal color schemes, shape curves, and animated transitions.
- **Rejected**: `expressive_kit` delivers an immediate, cohesive Material 3 Expressive experience.

### Easy Localization
- **Pros**: Dynamic JSON loading without compilation steps.
- **Cons**: Extra runtime wrapper overhead and less integration with standard Flutter toolchains and analyzer linters.
- **Rejected**: Official ARB tooling is faster, standardized, and fully type-safe.

## Consequences
- **Positive**:
  - Consistent, polished, and customizable UI across all screen sizes.
  - Type-safe, autocompleted translation keys with strict compiler checks.
- **Negative / Trade-offs**:
  - New translation keys must be maintained across both `.arb` files to prevent build warnings.
