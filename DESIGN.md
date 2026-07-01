---
name: LocalHost Monitor
description: Native macOS utility for seeing and acting on running localhost websites.
colors:
  window-background: "#F5F5F5"
  control-background: "#FFFFFF"
  primary-text: "#1D1D1F"
  secondary-text: "#6E6E73"
  separator: "#D2D2D7"
  link: "#0066CC"
  accent: "#0A84FF"
  destructive: "#D70015"
  badge-fill: "#E8E8ED"
typography:
  display:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "normal"
  headline:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "normal"
  title:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "normal"
  body:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "normal"
  label:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.2
    letterSpacing: "normal"
rounded:
  xs: "6px"
  sm: "7px"
  md: "8px"
spacing:
  xxs: "4px"
  xs: "6px"
  sm: "8px"
  md: "10px"
  lg: "12px"
  xl: "14px"
  xxl: "16px"
  empty: "32px"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.control-background}"
    rounded: "{rounded.md}"
    padding: "6px 12px"
  button-secondary:
    backgroundColor: "{colors.control-background}"
    textColor: "{colors.primary-text}"
    rounded: "{rounded.md}"
    padding: "5px 10px"
  button-borderless:
    backgroundColor: "transparent"
    textColor: "{colors.primary-text}"
    rounded: "{rounded.xs}"
    size: "18px"
  metadata-badge:
    backgroundColor: "{colors.badge-fill}"
    textColor: "{colors.secondary-text}"
    rounded: "999px"
    padding: "2px 6px"
  site-row:
    backgroundColor: "{colors.control-background}"
    textColor: "{colors.primary-text}"
    rounded: "{rounded.md}"
    padding: "10px"
---

# Design System: LocalHost Monitor

## 1. Overview

**Creative North Star: "The Local Console"**

LocalHost Monitor should feel like the small native console a developer leaves open beside their editor: quiet, sharp, and instantly readable. The design system is restrained because the task is practical. It favors native macOS controls, system colors, compact rhythm, and clear action hierarchy over brand theatrics.

The system is not trying to become a monitoring dashboard. It is a focused localhost-site utility: the window names what is running, keeps site identity separate from status and process facts, and makes each action obvious without making the interface loud.

Every new surface should reject marketing-site gloss, decorative dashboards, loud gradients, novelty controls, terminal-cosplay styling, and anything that makes local site management feel heavier than the task itself.

**Key Characteristics:**
- Native macOS materials and controls first.
- Restrained density with enough spacing to scan rows quickly.
- One accent for primary action and selection state.
- Metadata remains compact, separate, and factual.
- Destructive actions stay visible, precise, and clearly labeled.

## 2. Colors

The palette is a native macOS system palette: semantic platform colors do the work, with blue used sparingly for links, focus, primary action, and selected emoji state.

### Primary
- **System Accent Blue**: Used for the primary "Open Website" action, selected emoji states, and focus/selection moments. In SwiftUI, use `Color.accentColor`; the frontmatter swatch approximates the default macOS accent.

### Secondary
- **System Link Blue**: Used only for localhost URLs that open in a browser. In SwiftUI, use `Color(nsColor: .linkColor)` so the link tracks system appearance.

### Tertiary
- **System Destructive Red**: Used only for destructive process termination. In SwiftUI, use `.foregroundStyle(.red)` on the "Kill Process" action and keep the label explicit.

### Neutral
- **Window Background**: The app background. In SwiftUI, use `Color(nsColor: .windowBackgroundColor)`.
- **Control Background**: The site row, emoji square, and control-surface background. In SwiftUI, use `Color(nsColor: .controlBackgroundColor)`.
- **Primary Text**: Default readable text through `.foregroundStyle(.primary)`.
- **Secondary Text**: Counts, timestamps, metadata, and quiet utility copy through `.foregroundStyle(.secondary)`.
- **Separator**: Row outlines and dividers through `Color(nsColor: .separatorColor)` with intentional opacity.
- **Badge Fill**: Metadata badge tint through `Color(nsColor: .quaternaryLabelColor).opacity(0.22)`.

### Named Rules

**The Platform Color Rule.** Use semantic macOS colors in SwiftUI, not fixed brand hex values, for window, control, separator, text, link, and accent behavior.

**The One Accent Rule.** Blue appears only for links, primary action, focus, and selection. It is not decoration.

## 3. Typography

**Display Font:** SF Pro / system sans  
**Body Font:** SF Pro / system sans  
**Label/Mono Font:** SF Pro with monospaced digits where counts, times, status, or PID values must align

**Character:** The type system is compact, native, and utilitarian. Weight does the hierarchy work; there is no display face, decorative pairing, or fluid type scale.

### Hierarchy
- **Display** (semibold, 22px, 1.2): Window header title only.
- **Headline** (semibold, platform headline, 1.25): Empty-state title and compact section emphasis.
- **Title** (semibold, 14px, 1.25): Editable site title field.
- **Body** (regular, platform body/callout, 1.35): Controls, menu items, and standard labels.
- **Label** (regular, caption/caption2, 1.2): URLs, status badges, timestamps, process names, PIDs, and secondary metadata. Use monospaced digits for counts and machine-like facts.

### Named Rules

**The Native Scale Rule.** Use fixed platform text styles and small explicit sizes. Do not introduce fluid headings, decorative type, tracked uppercase labels, or marketing-page hierarchy.

## 4. Elevation

The elevation philosophy is tonal layering, no shadows. Depth comes from platform backgrounds, dividers, row outlines, selected tints, and control styles. Site rows are grouped by a subtle control background and a one-pixel separator stroke; no card shadows are part of the system.

### Named Rules

**The No Shadow Rule.** Do not add decorative drop shadows to rows, buttons, badges, popovers, or the window content. Native controls and tonal surfaces provide the hierarchy.

## 5. Components

### Buttons
- **Shape:** Native bordered buttons with gently curved corners (8px visual system radius, platform-controlled in SwiftUI).
- **Primary:** `borderedProminent` only for "Open Website"; it uses the system accent color and should remain the clearest row action.
- **Hover / Focus:** Let macOS provide button hover, press, keyboard focus, and disabled states. Do not invent custom animated treatments.
- **Secondary / Ghost / Tertiary:** Use `bordered` for refresh and kill-process actions, `borderless` for icon-only reset/copy actions, and explicit destructive red text only for "Kill Process".

### Chips
- **Style:** Metadata badges are compact capsules with caption2 monospaced digits, secondary text, horizontal padding (6px), vertical padding (2px), and a quaternary-label fill tint.
- **State:** Badges are informational only. They do not become filters or buttons without a separate interactive affordance.

### Cards / Containers
- **Corner Style:** Site rows use gently rounded corners (8px).
- **Background:** Rows use `controlBackgroundColor` over `windowBackgroundColor`.
- **Shadow Strategy:** No shadows. Use a subtle separator stroke at 35% opacity.
- **Border:** One-pixel separator stroke only.
- **Internal Padding:** Rows use 10px padding; list spacing uses 8px; scroll content uses 14px.

### Inputs / Fields
- **Style:** Editable site titles use SwiftUI's rounded text field style with semibold 14px text.
- **Focus:** Preserve native macOS focus behavior and click-away defocus.
- **Error / Disabled:** Use native disabled states. Alerts should remain system alerts with direct titles and messages.

### Navigation
- **Style:** The menu bar extra is native menu UI: plain text menu items, platform dividers, a toggle, and direct commands. Do not replace it with a custom menu surface.

### Emoji Picker
- **Style:** The emoji button is a fixed 34px square with a 7px radius, control background, and separator stroke.
- **State:** Pressed and selected states use accent-color tints at roughly 22-24% opacity.
- **Popover:** The picker uses a compact 8-column grid of 30px cells with 4px gaps and 8px padding.

## 6. Do's and Don'ts

### Do:
- **Do** use native macOS semantic colors for background, text, separators, links, and controls.
- **Do** keep the default view calm and useful, with deeper detail behind explicit hidden-site and non-OK controls.
- **Do** keep title, emoji, URL, status, process name, PID, and hidden state as distinct visual facts.
- **Do** use monospaced digits for counts, timestamps, HTTP status, and PID labels.
- **Do** keep destructive actions explicit: the label must say "Kill Process" and use the destructive red treatment.
- **Do** preserve WCAG AA contrast through system colors and avoid color-only status cues.

### Don't:
- **Don't** use marketing-site gloss, decorative dashboards, loud gradients, novelty controls, or terminal-cosplay styling.
- **Don't** use generic server-monitoring language when the app is specifically about localhost sites and site preferences.
- **Don't** add card shadows, glassmorphism, decorative grid backgrounds, gradient text, side-stripe borders, or oversized rounded containers.
- **Don't** collapse site facts into one overloaded subtitle.
- **Don't** make process termination feel casual, playful, or hidden behind an ambiguous icon.
- **Don't** replace standard macOS controls with custom controls for flavor.
