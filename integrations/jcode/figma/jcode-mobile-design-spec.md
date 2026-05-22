# jcode mobile design spec

This concept is derived from the current native iOS client in:

- `ios/Sources/JCodeMobile/Theme.swift`
- `ios/Sources/JCodeMobile/ContentView.swift`
- `docs/IOS_CLIENT.md`

## Product framing

jcode mobile is not a terminal emulator. It is a touch-first remote control and conversation surface for a jcode server running on a developer’s laptop or desktop.

Core themes:
- dark, calm, focused
- terminal-native identity without looking retro
- mint accent for active / live / connected states
- dense information presented in touchable cards
- high signal, low chrome

## Visual tokens

### Colors

- Background: `#0F0F14`
- Surface: `#1A1A1F`
- Surface elevated: `#242429`
- Border: `rgba(255,255,255,0.08)`
- Accent mint: `#4DD9A6`
- Accent tint: `rgba(77,217,166,0.15)`
- Text primary: `rgba(255,255,255,0.92)`
- Text secondary: `rgba(255,255,255,0.55)`
- Text tertiary: `rgba(255,255,255,0.35)`
- Warning/orange: `#F59E0B`
- Error/red: `#D94D59`

### Typography

- Primary UI font: `Inter`
- Monospace UI font: `Roboto Mono`
- Large title: 28 / bold
- Title: 22 / bold
- Headline: 17 / semibold
- Body: 15 / regular
- Callout: 14 / regular
- Caption: 12 / medium
- Mono: 12–13 / regular

### Shape

- Phone frame radius: 36
- Primary cards: 16
- Inputs / pills: 12–20
- Buttons are soft-rounded, never sharp

## Screen set

## 1. Onboarding

Purpose: pair a phone with a running jcode server.

Content:
- animated terminal prompt mark
- product title and pocket-assistant positioning
- primary CTA: scan QR code
- helper text referencing `jcode pair`
- manual connection form with host, port, pair code, device name
- secondary CTA: pair & connect

## 2. Chat

Purpose: daily-use control surface.

Content:
- live connection header with status dot, server name, server version
- current model pill
- message feed with system, user, and assistant styling
- expandable tool execution card
- interrupt / stop affordances when processing
- attachment-aware input composer

## 3. Settings

Purpose: operational control.

Content:
- connection status card
- saved servers list
- sessions list
- model picker list

## Interaction notes

- assistant content sits on neutral elevated surfaces
- user content uses a mint-tinted bubble
- system notices use a warm warning tint
- active selection uses mint tint + mint border emphasis
- long identifiers use monospaced text and middle truncation

## What the included assets are for

- `jcode-mobile-plugin/` generates editable screens directly in Figma
- `jcode-mobile-mockup.svg` gives a fast importable preview

## Suggested next iterations

1. ambient dashboard screen
2. lock-screen approval flow
3. push notification states
4. landscape iPad console companion
5. handoff specs for implementation spacing and dynamic type
