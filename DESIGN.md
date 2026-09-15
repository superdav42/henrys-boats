---
version: alpha
name: henrys-boats
description: A clear, touch-first naval strategy interface for home, match setup, upgrades, and play.
colors:
  primary: "#EAF7FF"
  secondary: "#9FC5D9"
  tertiary: "#48BFFF"
  neutral: "#0A1A2C"
  background: "#0A1A2C"
  surface: "#12314A"
  on-surface: "#EAF7FF"
  error: "#FF8A80"
  outline: "#4B7189"
typography:
  headline-display: {fontFamily: system, fontSize: 42px, fontWeight: 700, lineHeight: 1.1, letterSpacing: -0.02em}
  headline-lg: {fontFamily: system, fontSize: 34px, fontWeight: 600, lineHeight: 1.2}
  body-md: {fontFamily: system, fontSize: 16px, fontWeight: 400, lineHeight: 1.5}
  label-md: {fontFamily: system, fontSize: 16px, fontWeight: 600, lineHeight: 1.4}
rounded: {none: 0, sm: 4px, md: 8px, lg: 16px, xl: 24px, full: 9999px}
spacing: {unit: 8px, xs: 4px, sm: 8px, md: 16px, lg: 32px, xl: 64px, gutter: 24px, margin: 32px}
components:
  button-primary: {backgroundColor: "{colors.tertiary}", textColor: "{colors.background}", typography: "{typography.label-md}", rounded: "{rounded.md}", padding: 12px}
  button-primary-hover: {backgroundColor: "#7AD3FF"}
  button-secondary: {backgroundColor: "{colors.surface}", textColor: "{colors.on-surface}", typography: "{typography.label-md}", rounded: "{rounded.md}", padding: 12px}
  input-default: {backgroundColor: "{colors.surface}", textColor: "{colors.on-surface}", typography: "{typography.body-md}", rounded: "{rounded.sm}", padding: 12px}
  card: {backgroundColor: "{colors.surface}", textColor: "{colors.on-surface}", rounded: "{rounded.lg}", padding: 24px}
---

# Design System: Henry's Boats

## 1. Overview

**Mood**: playful, tactical, and calm.
**Density**: balanced.
**Atmosphere**: deep navy waters frame bright fleet colours and uncomplicated strategic decisions.

- Use one clear primary action per screen.
- Keep game-critical labels legible over the board and avoid decorative UI that competes with pieces.
- Use a clearly lighter teal page background behind the framed blue map so an empty-water board never disappears into the surrounding canvas.
- Auto-fit the complete map inside the available play area when a match or editor map opens; zoom and pan remain optional detail controls rather than requirements for seeing the map.

## 2. Colors

The palette uses dark ocean surfaces with a sky-blue action accent.

- **Primary (`#EAF7FF`)**: high-contrast text and headings.
- **Secondary (`#9FC5D9`)**: supporting text and metadata.
- **Tertiary (`#48BFFF`)**: primary actions, selected states, and focus.
- **Neutral/background (`#0A1A2C`)**: app canvas and overlays.
- **Surface (`#12314A`)**: menu panels and secondary controls.
- **Error (`#FF8A80`)**: validation and failed save feedback.
- **Outline (`#4B7189`)**: dividers and focus boundaries.

## 3. Typography

System sans-serif keeps mobile rendering fast and clear. Use 42px for the home title, 34px for screen titles, 20–24px for game HUD information, and no smaller than 16px for controls.

## 4. Layout

The portrait layout is a 720px logical canvas with 32px page margins and 16px gaps between related controls. Menus are centered single-column stacks. The game board remains visible only during a match; menus use full-screen navy panels for orientation.

## 5. Elevation & Depth

Use tonal layers, not shadows: background for the sea, surface for controls, and a near-opaque background overlay for modal menus.

## 6. Shapes

Buttons and inputs use 8px corners; grouped menu panels may use 16px corners. Do not mix sharp and heavily rounded shapes in one screen.

## 7. Components

### Cross-cutting component rules

- Every actionable control is at least 44px high; primary menu actions are 56px or higher.
- Controls have visible text labels, keyboard focus, disabled states, and direct validation feedback.
- Back is always available from match setup, upgrades, and map editing and returns to home rather than leaving the player stranded.
- Selection controls use the surface colour and bright text; errors remain visible until the player makes a corrective action.
- The in-match inspector uses a dark surface card with text labels for terrain, unit facts, and defence. Legal movement uses green overlays; legal attacks use coral overlays, and neither colour is the only source of meaning because the inspector and invalid-action message explain the rules.
- Board terrain is illustrated with moving wave strokes for water, sand bands for shore, grass marks for land, peaked mountains, coral reef clusters, and a bright river channel. These patterns remain distinct at zoomed-out sizes.
- Shore tiles blend water and sand by adjacency: each edge facing land or either mountain type extends the sandy half of the tile, while edges facing water or reef retain visible water and foam. Snow-capped mountains use bright white peaks and remain distinct from ordinary mountains.
- Surface units use hull and bridge silhouettes; air units use winged aircraft silhouettes. Team colour fills the silhouette while a dark outline, short type code, and HP pips provide non-colour identification. A white diamond identifies the selected unit, and move/attack overlays carry `M`/`A` markers as well as their colours.
- Submarines use a low oval hull and conning-tower silhouette. Enemy submarines remain hidden unless they are within a friendly destroyer's two-tile detection/attack range.
- The read-only inspector identifies the selected tile or unit, terrain, team, unit type, HP, movement, range, attack, target rules, defence, and the current legal move/attack count.

### Navigation

Home contains Play, Permanent Upgrades, and Map Editor. Play opens setup, which can start a match or return to Home. Map Editor can be reached from Home or setup and has a return route. Upgrades return to Home after purchases or reset.

## 8. Do's and Don'ts

**Do:** use sky blue for the primary action, preserve contrast, and explain unavailable actions in plain language.
**Don't:** use colour as the only status indicator, shrink touch targets below 44px, or hide a destructive profile reset behind an unlabelled control.

## 9. Responsive Behaviour

At mobile widths, use a single column and retain 32px side margins where possible. At tablet and desktop widths, keep menu content centered with a readable maximum width. Board controls may wrap, but their 44px minimum target size is preserved.

## 10. Agent Prompt Guide

Use `background` for full-screen game and menu canvas, `surface` for controls, `tertiary` for the one primary action, and `error` for failed validation or storage outcomes. Match new menus to `scenes/setup_menu.tscn` and `scenes/upgrade_screen.tscn`.
