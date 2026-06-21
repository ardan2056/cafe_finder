---
name: Cafe Finder Smart Mapping
colors:
  surface: '#faf9f8'
  surface-dim: '#dadad9'
  surface-bright: '#faf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f2'
  surface-container: '#eeeeed'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e3e2e1'
  on-surface: '#1a1c1c'
  on-surface-variant: '#50453e'
  inverse-surface: '#2f3130'
  inverse-on-surface: '#f1f0f0'
  outline: '#82746d'
  outline-variant: '#d4c3ba'
  surface-tint: '#79573f'
  primary: '#553722'
  on-primary: '#ffffff'
  primary-container: '#6f4e37'
  on-primary-container: '#eec1a4'
  inverse-primary: '#eabda0'
  secondary: '#735a3e'
  on-secondary: '#ffffff'
  secondary-container: '#fdd9b7'
  on-secondary-container: '#785e42'
  tertiary: '#533913'
  on-tertiary: '#ffffff'
  tertiary-container: '#6c5028'
  on-tertiary-container: '#ebc491'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdcc6'
  primary-fixed-dim: '#eabda0'
  on-primary-fixed: '#2d1604'
  on-primary-fixed-variant: '#5f402a'
  secondary-fixed: '#ffddbb'
  secondary-fixed-dim: '#e3c19f'
  on-secondary-fixed: '#291803'
  on-secondary-fixed-variant: '#5a4229'
  tertiary-fixed: '#ffddb4'
  tertiary-fixed-dim: '#e7c08e'
  on-tertiary-fixed: '#291800'
  on-tertiary-fixed-variant: '#5c421b'
  background: '#faf9f8'
  on-background: '#1a1c1c'
  surface-variant: '#e3e2e1'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-tablet: 24px
  gutter: 16px
  bottom-nav-height: 80px
  sheet-peek-height: 240px
---

## Brand & Style
The design system for this product is rooted in the "Modern Coffee House" aesthetic—blending the utility of a high-performance mapping tool with the warmth and comfort of a local café. It targets urban explorers and remote workers who value both professional reliability and sensory experience.

The style is a refined execution of **Material Design 3**, emphasizing a "Tactile Modern" approach. It utilizes soft elevation, rich organic colors, and generous whitespace to prevent data-heavy mapping interfaces from feeling cluttered. The emotional response should be one of calm focus and effortless discovery.

## Colors
The palette is inspired by the roasting process and milk textures. 
- **Primary (Deep Coffee Brown):** Used for key actions, active states, and branding elements to provide a grounded, professional foundation.
- **Secondary (Warm Latte):** Applied to tonal containers, subtle highlights, and secondary buttons.
- **Tertiary (Creamy Beige):** Used for accents, specialized status chips (e.g., "Open Now"), and decorative surface washes.
- **Surface Strategy:** In light mode, surfaces use a "Warm White" (#FDFCFB) to avoid the sterile feel of pure white. In dark mode, the system shifts to a deep "Espresso" black with brown-tinted grays to maintain the coffee-inspired theme without losing contrast.

## Typography
This design system utilizes **Inter** for all roles to ensure maximum legibility at small sizes (essential for map labels) and a clean, modernist look at display sizes. 
- **Headlines:** Use a bold weight with tighter letter-spacing to create a strong visual hierarchy for café names.
- **Labels:** Small labels use a semi-bold weight and slight tracking increase to ensure readability against photographic backgrounds or map textures.
- **Scale:** On mobile devices, headlines scale down slightly to prioritize map real estate while maintaining their structural impact.

## Layout & Spacing
The layout follows a **Fluid Grid** model optimized for the specific ergonomics of coffee discovery.
- **Mobile-First:** A bottom navigation bar provides quick access to "Explore," "Saved," "Map," and "Activity."
- **Search & Filter:** A floating search bar is anchored at the top with a 16px margin from all edges.
- **The "Discovery Sheet":** Influenced by Google Maps and Airbnb, café details appear in a bottom sheet that can be swiped up. The "peek" state is 240px, allowing map visibility while showing the primary café card.
- **Responsive Behavior:** On tablets and larger screens, the bottom sheet transforms into a side-rail or left-aligned master-detail panel to utilize the horizontal aspect ratio.

## Elevation & Depth
In alignment with Material 3, hierarchy is communicated through **Tonal Layers** rather than heavy shadows.
- **Level 0 (Background):** Warm White surface.
- **Level 1 (Cards/Sheet):** A subtle tint of the primary color at 5% opacity or a soft, diffused shadow (Blur: 12px, Y: 4px, 8% Opacity) to lift the café card from the map.
- **Level 2 (Floating Action Buttons):** Higher contrast with a secondary color fill and a more pronounced shadow to indicate primary interactivity.
- **Glassmorphism:** The Search Bar and Filter Chips utilize a subtle backdrop blur (10px) and 90% opacity white/dark-gray to maintain context of the map underneath while ensuring text legibility.

## Shapes
The shape language is characterized by **Extra-Large Radii** to evoke a friendly, approachable atmosphere.
- **Large Components (Cards, Bottom Sheets):** Use a 24px corner radius. This is a signature element that differentiates the product from more rigid utility apps.
- **Medium Components (Buttons, Input Fields):** Use a 16px radius.
- **Small Components (Chips, Tooltips):** Fully rounded (Pill-shaped) to distinguish them as interactive tokens.
- **Images:** All café photography must share the 24px corner radius to maintain visual harmony.

## Components
- **Buttons:** Primary buttons are Deep Coffee Brown (#6F4E37) with white text. They should be tall (56px) for easy thumb tapping.
- **Café Cards:** Feature high-quality photography as the hero element. Use a 24px radius and include a "Quick Save" floating icon in the top right.
- **Chips:** Filter chips for "Wi-Fi," "Specialty Brew," or "Quiet Space" use the Tertiary Creamy Beige with Dark Brown text for high-contrast accessibility.
- **Bottom Navigation:** Uses active indicator "pills" around icons, a core Material 3 pattern, colored in the Secondary Warm Latte.
- **Input Fields:** Search bars should be containerless or have a very soft Warm Latte background to look integrated into the map interface.
- **Map Markers:** Custom pins should use the Primary color with a white inner icon (e.g., a coffee cup) to ensure visibility across diverse map textures.