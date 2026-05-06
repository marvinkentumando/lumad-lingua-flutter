# Lumad Lingua - Brand & Design System

This document outlines the core visual identity, typography, color palettes, and cultural design elements that make up the "Lumad Lingua" design system.

## 🎨 Color Palette

The app relies on two primary color scales, designed to reflect nature and ancestral heritage.

### Forest Green Scale (Primary)
Used heavily in Dark Mode ("Forest Mode") backgrounds and as primary accents in Light Mode.
- **`forest900`** (`#030A04`): Deepest background for dark mode.
- **`forest700`** (`#0D1E0D`): Deep Forest.
- **`forest500`** (`#1E3A22`): **Primary Brand Color** (Forest Floor).
- **`forest200`** (`#65A870`): Lighter accent.

### Ancestral Gold Scale (Accent & CTA)
Used for calls-to-action, highlights, and primary accents in Dark Mode.
- **`gold900`** (`#4A2E00`): Deep gold shadow.
- **`gold500`** (`#FFC200`): **Primary Accent / CTA**.
- **`gold100`** (`#FFF8DE`): Subtle gold background highlight.

### Semantics & Neutrals
- **Cream Background**: `#FEF8ED` (Primary background for "Cream Mode" / Light Mode).
- **Cream Text**: `#1A0E05` (Primary text color for light backgrounds).
- **Terracotta**: `#C84E1A` (Used as a secondary accent).
- **Semantic Green**: `#3DAF5C` (Correct / Success).
- **Semantic Red**: `#F04848` (Error / Incorrect).

## 🔤 Typography

The typography system mixes playful, accessible headings with clean, modern body text.

### Headings (Display & Titles)
**Font Family**: `Fredoka`
- Used for all major headers (`h1`, `h2`, `h3`, `display`).
- **Characteristics**: Rounded, friendly, and highly legible. Weights range from `SemiBold` (600) to `Bold` (700).

### Body text
**Font Family**: `Nunito`
- Used for paragraph text, descriptions, and UI labels.
- **Characteristics**: Rounded, friendly, and highly legible sans-serif. Weights used are `Regular` (400) for body, `Medium` (500) for body large, and `Bold` (700) for small all-caps labels.

### Monospace
**Font Family**: `DM Mono`
- Used for specific technical data, codes, or exact phonetic transcriptions.

## 🌗 Theming (Light vs. Dark)

### Light Theme ("Cream Mode")
- **Background**: `creamBg` (`#FEF8ED`)
- **Primary Color**: `forest500`
- **Secondary Color**: `terracotta`
- **Feel**: Like reading an ancient, well-kept parchment. Warm, inviting, and highly readable.

### Dark Theme ("Forest Mode")
- **Background**: `forest900` (`#030A04`)
- **Primary Color**: `gold500`
- **Secondary Color**: `forest400`
- **Feel**: Like navigating a dense, mystical forest at night illuminated by firelight (gold accents). Deep contrast and immersive.

## 🏺 Cultural Patterns & Graphics
To reinforce the indigenous theme, the UI utilizes custom generative background patterns painted subtly (10% opacity) via `CustomPainter`.

- **Dagmay**: A traditional Mandaya textile pattern represented by intersecting diamonds and geometric shapes.
- **Inabal**: A Bagobo textile pattern represented by dynamic, intersecting diagonal lines.
- **T'nalak**: (Conceptual) Woven patterns representing dream-weavers.

These patterns are used to break up flat backgrounds in cards, headers, and bottom sheets, adding rich cultural depth to the digital experience without overwhelming the content.
