# jcode Figma assets

This directory contains a practical workflow for getting the current jcode mobile app concept into Figma.

## What’s here

- `jcode-mobile-plugin/` — a Figma plugin that generates **editable** mobile screens
- `jcode-mobile-mockup.svg` — a drag-and-drop SVG mockup you can import directly into Figma
- `jcode-mobile-design-spec.md` — the visual system and screen notes used to build the concept

## Fastest path

### Option A — editable native Figma layers
1. Open **Figma Desktop**
2. Create or open a design file
3. Go to **Plugins → Development → Import plugin from manifest...**
4. Select `jcode-mobile-plugin/manifest.json`
5. Run the plugin from **Plugins → Development → jcode Mobile Screens**
6. The plugin creates three screens:
   - Onboarding
   - Chat
   - Settings

### Option B — immediate visual mockup
1. Open a Figma file
2. Drag `jcode-mobile-mockup.svg` into the canvas
3. Ungroup / edit as needed

## Why there isn’t a pure CLI write flow

Figma’s REST API can read files and metadata, but it does **not** support arbitrary creation of frames/layers for full UI composition the way a design plugin does. The correct way to programmatically create designs inside Figma is a **Figma plugin**.

## Notes

- The plugin uses `Inter` and `Roboto Mono`, both common defaults in Figma
- Colors and layout are based on `ios/Sources/JCodeMobile/Theme.swift` and `ios/Sources/JCodeMobile/ContentView.swift`
- The mockups intentionally mirror the current SwiftUI app shell rather than inventing an unrelated concept
