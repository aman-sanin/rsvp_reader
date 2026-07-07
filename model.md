# RSVP Reader — Front-End Design Document (Flutter)

## 1. Product Overview

A Rapid Serial Visual Presentation (RSVP) speed reader built in **Flutter**. Words are flashed one-at-a-time at a fixed focal point. The user controls pace, rewinds, pauses, and adjusts reading parameters through gestures, keyboard, and a settings panel. The entire experience is a single-screen app.

---

## 2. Screen Architecture

There are **three layers**, always present, with varying visibility:

| Layer              | Widget                                                    | Purpose                                                    | Default State |
| ------------------ | --------------------------------------------------------- | ---------------------------------------------------------- | ------------- |
| **Background**     | `Stack` of gradient + blur containers                     | Atmospheric, non-distracting                               | Visible       |
| **Reader Stage**   | `Column` centered in `SizedBox.expand`                    | Word display, guide line, progress bar, transport controls | Visible       |
| **Settings Panel** | `ModalBottomSheet` or custom `AnimatedContainer` slide-up | All tunable parameters                                     | Hidden        |

Nothing else. No `AppBar`, no `BottomNavigationBar`, no `Drawer`. The word is the hero.

---

## 3. Background Design

### 3.1 Philosophy

The background must **never compete** with the word. It should create depth and warmth without drawing the eye. Think "stage lighting in a dark room."

### 3.2 Implementation (Flutter)

- **Base**: A `Container` filled with `Theme.of(context).colorScheme.surface`.
- **Layer 1 — Radial glow**: A `RadialGradient` centered slightly above the word display area. Color derived from `colorScheme.primary` at ~4–6% opacity, spreading to transparent. Implemented as a `BoxDecoration` on a positioned `Container`.
- **Layer 2 — Noise texture**: An `Image.asset` or procedurally generated noise overlay at ~2–3% opacity. Use a small repeating tile (`RepeatMode.repeat`) with `ColorFiltered` + `BlendMode.dstOver` at low opacity. This removes digital flatness.
- **Layer 3 — Floating orbs (theme-dependent)**: 2–3 `Container` widgets with `BoxDecoration(gradient: ..., borderRadius: ..., boxShadow: [...])` and `BackdropFilter(blur: 80)`. Positioned off-center with `AnimatedPositioned` or `AnimationController` driving a slow 30–60s drift loop. Opacity capped at 3–5%. **Disabled in light theme.**

### 3.3 Rules

- No images other than the noise tile. No fine patterns.
- No animation faster than 20s cycle.
- Light theme: remove orbs, reduce glow intensity by 50%, increase noise to ~4% for paper-like texture.

---

## 4. Font System

### 4.1 Font Pairing Philosophy

The reading font and the UI font must share similar x-heights and weight distributions so the eye doesn't readjust when looking at controls vs. the word. Choose from these **pre-approved pairings** — do not mix pairings.

### 4.2 Approved Font Pairings

| Pair ID | Reading Font (word display) | UI Font (stats, labels, settings) | Character                                                             |
| ------- | --------------------------- | --------------------------------- | --------------------------------------------------------------------- |
| **A**   | `SpaceMono`                 | `SpaceGrotesk`                    | Geometric, modern, slightly technical. Mono gives stable word widths. |
| **B**   | `SourceCodePro`             | `SourceSans3`                     | Adobe pair. Warm, excellent readability, very organic feel.           |
| **C**   | `JetBrainsMono`             | `Inter`                           | Crisp, high x-height, neutral. Inter is legible at small sizes.       |
| **D**   | `IBM Plex Mono`             | `IBM Plex Sans`                   | Designed as a family. Perfect weight alignment. Slightly editorial.   |
| **E**   | `FiraCode`                  | `FiraSans`                        | Mozilla pair. Friendly, slightly rounded terminals.                   |

### 4.3 Rules

- **Always use a pair as a unit.** Never mix reading font from Pair A with UI font from Pair C.
- Default: **Pair A** (SpaceMono + SpaceGrotesk).
- The user selects the _pair_, not individual fonts. The setting label is the Pair ID name (e.g., "Geometric", "Warm", "Crisp", "Editorial", "Friendly").
- Reading font weights: `w500`–`w600` only. Never `w300` (too thin for flash), never `w800`+ (too dense).
- UI font weights: labels `w500`, stats `w400`, muted text `w400`.
- Font sizes for UI elements are fixed per the spec below — only the reading word font size is user-adjustable.

### 4.4 Flutter Implementation

- Bundle all 10 font files (5 pairs × 2 variants) in `assets/fonts/`.
- Define a `FontPair` class:
  ```
  class FontPair {
    final String id;
    final String label;
    final String readingFontFamily;
    final String uiFontFamily;
  }
  ```
- Apply via `TextStyle(fontFamily: currentPair.readingFontFamily)` for the word, `fontFamily: currentPair.uiFontFamily` everywhere else.
- On pair change: wrap the entire widget tree in an `AnimatedDefaultTextStyle` with `duration: 300ms, curve: Curves.easeInOut` so fonts cross-fade smoothly.

---

## 5. Reader Stage (Center)

### 5.1 Layout

```
┌─────────────────────────────────┐
│                                 │
│         [word 47 / 312]        │  ← top stat line, small, muted
│                                 │
│            ┊                    │  ← fixation guide line (vertical)
│        S e│n t e   ║            │  ← ORP-highlighted word, ORP aligned to line
│            ┊                    │
│      ─────────●──────────       │  ← thin progress bar
│                                 │
│    ◁◁    ▶ / ❚❚    ▷▷          │  ← minimal transport controls
│                                 │
└─────────────────────────────────┘
```

### 5.2 Fixation Guide Line

- A **vertical line** positioned at the ORP's horizontal anchor point.
- Height: extends from `40px` above the word to `40px` below the word (not full-screen — just a local guide).
- Width: `1.5px`.
- Color: `colorScheme.primary` at **15% opacity**.
- **This line never moves.** The word is positioned so its ORP letter always lands exactly on this line. This gives the eye a fixed vertical axis to lock onto, dramatically reducing saccade fatigue.
- Implementation: The word is rendered inside a `Stack`. The line is a `Positioned` or `Align` widget at the ORP x-offset. The word's `Text` widget is left-aligned within a container whose left edge is offset so the ORP character lands on the line. Calculate the offset by measuring the pre-ORP substring width with `TextPainter`.
- **Optional setting**: "Show guide line" toggle (on by default). When off, the line fades out with `AnimatedOpacity(duration: 300ms)`.

### 5.3 Context Words (Previous / Next)

When enabled, the immediately previous and next words are shown flanking the current word, providing spatial context.

```
      previous      CURRENT      next
      (greyed)     (highlighted)  (greyed)
```

- **Previous word**: Positioned to the left of the current word, offset by the current word's width + `24px` gap.
- **Next word**: Positioned to the right, same gap.
- **Styling**: Same font, same size as current word. Color: `colorScheme.onSurface` at **20% opacity** (deeply muted — present in peripheral vision but not readable).
- **ORP highlighting**: Only applied to the **current** word. Context words are plain.
- **Guide line**: Extends through all three words but is only prominent at the current word's ORP position.
- **Edge cases**: At the first word, no previous word shown. At the last word, no next word shown.
- **Setting control**: See Section 6 — three options: Hidden / Greyed Out / Greyed with line extension.

### 5.4 Word Display (Current)

- **Font**: Current pair's reading font.
- **Size**: User-adjustable. Default `36`. Range: `18` – `72` (in Flutter logical pixels).
- **Weight**: `w500`–`w600`.
- **Color**: `colorScheme.onSurface`.
- **ORP Highlighting**: The ORP letter is colored `colorScheme.primary` with a subtle `colorScheme.primaryContainer` background pill (`BorderRadius.circular(4)`, padding horizontal `3`).
- **Transition on word change**: `AnimatedSwitcher` with `duration: Duration(milliseconds: 60)` using a `FadeTransition`. Not a slide, not a scale. Just a quick opacity pulse.

### 5.5 Progress Bar

- Full width of the reader stage (constrained `maxWidth: 600`).
- Height: `2`. Filled: `colorScheme.primary`. Unfilled: `colorScheme.outlineVariant`.
- Wrap in a `GestureDetector`: tapping a position calculates the proportional word index and jumps there.
- Animate width changes with `AnimatedContainer(duration: Duration(milliseconds: 150))`.

### 5.6 Transport Controls

- Three `IconButton`s: `skip_previous`, `play_arrow`/`pause`, `skip_next`.
- Color: `colorScheme.onSurfaceVariant`. On hover/press: `colorScheme.onSurface`.
- Icon size: `20`. Spacing between buttons: `32`.
- **Auto-hide**: After 3 seconds of no interaction, wrap controls in `AnimatedOpacity(opacity: 0.15, duration: 300ms)`. Any touch/pointer event in the reader stage restores `opacity: 1.0`.

### 5.7 Top Stat Line

- Left: `"Word 47 / 312"` using UI font, `fontSize: 12`, `colorScheme.onSurfaceVariant`.
- Right: `"~2m 14s"` same style.
- Update every word change.

---

## 6. Settings Panel

### 6.1 Entry / Exit

- **Enter**: Long press on reader stage (500ms), double-tap, `S` key, or a small `IconButton(icons.settings)` in the bottom-right corner (visible always on mobile, hover-only on desktop via `MouseRegion`).
- **Exit**: Tap backdrop, `Escape` key, or close `IconButton` inside the panel.
- **Animation**: `showModalBottomSheet` with `isScrollControlled: true` and a custom `AnimationController` for deceleration curve (`Curves.decelerate`). Sheet max height: `0.7 * MediaQuery.of(context).size.height`. Top corners: `BorderRadius.vertical(top: Radius.circular(20))`.
- **Backdrop**: Built-in with `ModalBottomSheetRoute` (barrierColor: `Colors.black54`).

### 6.2 Layout Inside Settings

```
┌─ Settings ───────────────── ✕ ─┐
│                                 │
│  SPEED                          │
│  ──────────────●────── 350 WPM  │
│  100                     1000   │
│                                 │
│  FONT SIZE                      │
│  ────────●────────── 36         │
│  18                       72    │
│                                 │
│  ORP POSITION                   │
│  ─────────●───────── 33%        │
│  0%                      50%    │
│                                 │
│  ── APPEARANCE ──────────────── │
│                                 │
│  Theme                          │
│  [●Dark] [○Light] [○Sepia]      │
│                                 │
│  Font Pair                      │
│  [●Geometric] [○Warm] [○Crisp]  │
│  [○Editorial] [○Friendly]       │
│                                 │
│  ── READING AIDS ────────────── │
│                                 │
│  Guide line              [ ✓ ] │
│  Context words          [ ▼  ] │
│    → Hidden                     │
│    → Greyed out          ●      │
│    → Greyed + line ext.         │
│                                 │
│  ── BEHAVIOR ────────────────── │
│                                 │
│  Pause at punctuation    [ ✓ ] │
│  Pause at sentence end    [ ✓ ] │
│  Pause duration         [  ▼  ] │
│  Auto-hide controls      [ ✓ ] │
│                                 │
│  ── TEXT INPUT ──────────────── │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Paste or type text here │    │
│  │ to begin reading...     │    │
│  └─────────────────────────┘    │
│                                 │
│        [ Start Reading ]        │
│                                 │
└─────────────────────────────────┘
```

### 6.3 New Settings — Detailed Spec

#### Context Words Selector

- **Type**: Segmented button group or dropdown (`DropdownButton`).
- **Options**:
  1. **Hidden** — Only the current word is displayed. Clean, minimal. Default for first-time users.
  2. **Greyed out** — Previous and next words shown at 20% opacity. No guide line extension.
  3. **Greyed + line extension** — Previous and next words shown at 20% opacity, and the fixation guide line extends through all three words (full height of the word row, at 15% opacity across the full span, slightly brighter at the ORP position).
- **Default**: "Hidden".
- **Live update**: Changing this immediately affects the reader stage. No restart needed.
- When switching from "Hidden" to either greyed option, context words fade in with `AnimatedOpacity(duration: 200ms)`.
- When switching to "Hidden", they fade out.

#### Font Pair Selector

- **Type**: Segmented button group (wrapping, 2–3 per row) or a horizontal scrollable `ChoiceChip` list.
- **Labels**: "Geometric", "Warm", "Crisp", "Editorial", "Friendly" (the Pair ID labels from Section 4.2).
- **Each chip**: Selected = `colorScheme.primary` fill, `colorScheme.onPrimary` text. Unselected = `colorScheme.surfaceContainerHighest` fill, `colorScheme.onSurfaceVariant` text.
- **Preview**: Below the selector, show a small preview line: `"The quick brown fox"` rendered in the selected reading font at `fontSize: 16`. Updates live. This helps users choose without starting a session.
- **Live update**: Applies immediately to the reader stage and all UI text.

### 6.4 Other Controls (Unchanged from previous spec, adapted for Flutter)

**Sliders**: Use `SliderThemeData` to customize:

- `activeTrackColor`: `colorScheme.primary`
- `inactiveTrackColor`: `colorScheme.outlineVariant`
- `thumbColor`: `colorScheme.primary`
- `thumbShape`: `RoundSliderThumbShape(enabledThumbRadius: 10)`
- `overlayShape`: `RoundSliderOverlayShape(overlayRadius: 20)` with `colorScheme.primary` at 12% opacity
- Show current value in a `Text` widget to the right: UI font, `fontSize: 14`, `colorScheme.primary`, `fontFeatures: [FontFeature.tabularFigures()]` for stable number widths.

**Toggle Switches**: Use `Switch` with `SwitchThemeData`:

- `thumbColor`: `WidgetStateProperty.resolveWith` — on: `colorScheme.onPrimary`, off: `colorScheme.outline`
- `trackColor`: on: `colorScheme.primary`, off: `colorScheme.outlineVariant`

**Text Input**: `TextField` with `maxLines: 5`, `minLines: 3`. Style:

- `decoration`: `InputDecoration(filled: true, fillColor: colorScheme.surfaceContainerLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary)))`
- `style`: UI font, `fontSize: 14`, `colorScheme.onSurface`.

**Start Reading Button**: `FilledButton` with custom `ButtonStyle`:

- `backgroundColor`: `colorScheme.primary`
- `foregroundColor`: `colorScheme.onPrimary`
- `padding`: `EdgeInsets.symmetric(vertical: 14)`
- `shape`: `StadiumBorder()`
- `textStyle`: UI font, `w600`, `fontSize: 15`
- Disabled: `colorScheme.onSurface.withOpacity(0.3)` when text is empty.

### 6.5 Settings Persistence

- Use `shared_preferences` package.
- Key format: `rsvp_{settingName}` (e.g., `rsvp_wpm`, `rsvp_theme`, `rsvp_font_pair`, `rsvp_context_mode`, `rsvp_text`).
- Save on every change. Load in `initState` of the root widget.

---

## 7. Theme System

### 7.1 Themes — `ThemeData` Overrides

| Token                                 | Dark                    | Light                   | Sepia                    |
| ------------------------------------- | ----------------------- | ----------------------- | ------------------------ |
| `colorScheme.surface`                 | `#0f0f0f`               | `#f5f0e8`               | `#2c2418`                |
| `colorScheme.surfaceContainerLow`     | `#1a1a1a`               | `#ebe5d9`               | `#352b1f`                |
| `colorScheme.onSurface`               | `#e8e4de`               | `#1a1714`               | `#d4c4a8`                |
| `colorScheme.onSurfaceVariant`        | `#6b6560`               | `#8a837a`               | `#7a6e5a`                |
| `colorScheme.primary`                 | `#e8a849`               | `#c47d1a`               | `#c4956a`                |
| `colorScheme.primaryContainer`        | `rgba(232,168,73,0.08)` | `rgba(196,125,26,0.08)` | `rgba(196,149,106,0.08)` |
| `colorScheme.surfaceContainerHighest` | `#161616`               | `#ffffff`               | `#332820`                |
| `colorScheme.outlineVariant`          | `#2a2725`               | `#d9d2c7`               | `#4a3e30`                |

### 7.2 Implementation

- Define three `ThemeData` objects in a `theme_provider.dart` or similar.
- Wrap the app in `AnimatedTheme(duration: Duration(milliseconds: 600), child: ...)` so theme transitions are smooth.
- All color references use `Theme.of(context).colorScheme.*` exclusively. Never hardcode a color in any widget.

---

## 8. ORP (Optimal Recognition Point) Logic

### 8.1 Algorithm

```
int getOrpIndex(String word, double orpPercent) {
  if (word.length <= 1) return 0;
  if (word.length <= 3) return 1;
  if (word.length <= 5) return 2;
  if (word.length <= 9) return 3;
  if (word.length <= 13) return 4;
  return (word.length * orpPercent).floor();
}
```

The `orpPercent` slider (default 0.33) overrides the fixed breakpoints when the user adjusts it.

### 8.2 Rendering with Guide Line

- Measure the pre-ORP substring width with `TextPainter(text: TextSpan(text: preOrp), ...).width`.
- Position the word container so the ORP character's left edge aligns with the guide line's x-position.
- Split the word into three `TextSpan` children inside a single `RichText`:
  - Pre-ORP: `colorScheme.onSurfaceVariant`
  - ORP letter: `colorScheme.primary`, `background: Paint()..color = colorScheme.primaryContainer`
  - Post-ORP: `colorScheme.onSurface`

### 8.3 Guide Line + Context Words Alignment

When context words are visible:

- The guide line's x-position is the **global anchor**.
- The current word's ORP is placed at the line (as above).
- The previous word is positioned to the **left**: its right edge is `24px` left of the current word's left edge. Right-aligned.
- The next word is positioned to the **right**: its left edge is `24px` right of the current word's right edge. Left-aligned.
- In "Greyed + line extension" mode, the guide line spans the full width of all three words combined (with `16px` padding top/bottom). The line is at uniform 15% opacity across the full span, with a subtle `Gradient` that brightens to 25% at the ORP x-position.

Use a `Stack` with `Positioned` widgets for each word, calculated in a layout function that runs on every word change.

---

## 9. Timing & Pacing

### 9.1 Base Interval

```
intervalMs = 60000 / wpm
```

### 9.2 Word-Level Adjustments

- **Long word penalty**: `if (word.length > 8) intervalMs += (word.length - 8) * 15`
- **Short word bonus**: `if (word.length <= 2) intervalMs -= 30` (clamp min 30ms)
- **Punctuation pause**: `,;:—` → add `pauseDuration` (default 150ms). `.!?` → add `pauseDuration * 2.5` (default 375ms). Only if toggle is on.
- **Paragraph break**: `isParagraphStart == true` → add `pauseDuration * 4`.

### 9.3 Timer Implementation

- Use a `Timer` with dynamically calculated durations. On each tick:
  1. Calculate `currentInterval` for the next word.
  2. Cancel previous timer.
  3. Create `Timer(Duration(milliseconds: currentInterval.round()), advanceWord)`.
- Alternatively, use a `Ticker` (via `SingleTickerProviderStateMixin`) with elapsed-time accumulation for more precision. Preferred for smooth WPM changes mid-reading.
- **Paused state**: Simply stop the ticker/timer. Do not dispose it — just `ticker.stop()`. Resume with `ticker.start()`. No re-initialization.

---

## 10. Text Preprocessing Pipeline

```dart
class WordToken {
  final String text;
  final bool isParagraphStart;
}

List<WordToken> preprocessText(String raw) {
  // 1. Normalize: collapse whitespace, preserve \n\n as paragraph markers
  // 2. Split on spaces
  // 3. Strip leading/trailing whitespace per token
  // 4. Remove empty tokens
  // 5. Mark paragraph starts (token following a \n\n)
  // 6. Return List<WordToken>
}
```

---

## 11. Gesture System

### 11.1 Touch Gestures

| Gesture         | Action               | Implementation Detail                                                                                                                 |
| --------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tap**         | Play / Pause         | `GestureDetector(onTap: ...)`. Dead zone: if `onPanStart` fires, cancel tap recognition. Use `onTapUp` + a flag set by `onPanStart`.  |
| **Swipe Left**  | Skip forward 5 words | `onPanEnd`: if `velocity.pixelsPerSecond.dx < -100` and `details.offsetFromOrigin.dx < -30`.                                          |
| **Swipe Right** | Rewind 5 words       | `velocity.pixelsPerSecond.dx > 100` and `dx > 30`.                                                                                    |
| **Swipe Up**    | WPM +25              | `velocity.pixelsPerSecond.dy < -100`. Show floating WPM toast.                                                                        |
| **Swipe Down**  | WPM -25              | `velocity.pixelsPerSecond.dy > 100`. Clamp to 50.                                                                                     |
| **Long Press**  | Open Settings        | `onLongPress` with `duration: 500ms`. Cancel if pan detected >20px (use `onLongPressStart` + `onLongPressMoveUpdate` with threshold). |
| **Pinch Out**   | Font size +          | `ScaleGestureRecognizer`. Track `scale` delta. Step `fontSize` by `0.25` per `0.05` scale change.                                     |
| **Pinch In**    | Font size -          | Same recognizer, inverse. Clamp to min/max.                                                                                           |

**Important**: Use a `RawGestureDetector` or compose multiple `GestureDetector`s carefully to avoid gesture conflicts. A `GestureArena` approach is recommended — e.g., `EagerGestureRecognizer` for long press so it doesn't lose to tap.

### 11.2 Mouse / Desktop

| Input              | Action                    |
| ------------------ | ------------------------- |
| Click (center)     | Play / Pause              |
| Scroll Up          | WPM +25                   |
| Scroll Down        | WPM -25                   |
| Click + Drag Left  | Rewind (1 word per 30px)  |
| Click + Drag Right | Forward (1 word per 30px) |
| Double Click       | Open Settings             |

### 11.3 Keyboard

| Key        | Action                 |
| ---------- | ---------------------- |
| `Space`    | Play / Pause           |
| `→` or `L` | Forward 5 words        |
| `←` or `J` | Rewind 5 words         |
| `↑` or `K` | WPM +25                |
| `↓` or `;` | WPM -25                |
| `+` / `=`  | Font size +            |
| `-`        | Font size -            |
| `Escape`   | Close settings / Pause |
| `S`        | Toggle settings        |
| `R`        | Restart                |
| `T`        | Cycle theme            |

Use `KeyboardListener` or `FocusNode` + `onKeyEvent` at the root level.

### 11.4 Gesture Feedback

| Event             | Feedback                                                                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| WPM change        | A large number (e.g., `375`) appears center-screen in `colorScheme.primary`, `fontSize: 32`, fades out over 800ms via `AnimatedOpacity`. |
| Skip forward/back | Word `Transform.translate` nudges 12px in direction, springs back over 150ms (`Curves.elasticOut`).                                      |
| Play/Pause        | Word `AnimatedOpacity` to 0.4. A "PAUSED" `Text` fades in below (`fontSize: 12`, `colorScheme.onSurfaceVariant`).                        |
| Pinch font change | Brief floating font size number, same style as WPM toast but smaller (`fontSize: 22`).                                                   |
| End of text       | Word shows "DONE" in `colorScheme.primary`. Controls fade out. "Restart" `TextButton` fades in after 1s.                                 |

**Debounce rule**: If the same feedback type fires within 200ms of the previous one, cancel the previous animation and show only the latest value.

---

## 12. Micro-Interactions & Feedback (Full Table)

| Event                   | Widget Animation                                             | Duration         | Curve               |
| ----------------------- | ------------------------------------------------------------ | ---------------- | ------------------- |
| Word changes            | `AnimatedSwitcher` fade                                      | 60ms             | `Curves.easeIn`     |
| Pause                   | Word `Opacity 1→0.4`, "PAUSED" `Opacity 0→1`                 | 300ms            | `Curves.easeInOut`  |
| Resume                  | Inverse of pause                                             | 200ms            | `Curves.easeOut`    |
| WPM toast               | `AnimatedOpacity` 1→0, slight `Transform.translate` y: 0→-20 | 800ms            | `Curves.easeOut`    |
| Skip nudge              | `Transform.translate` x: ±12→0                               | 150ms            | `Curves.elasticOut` |
| Theme switch            | `AnimatedTheme` cross-fade                                   | 600ms            | `Curves.easeInOut`  |
| Settings open           | `BottomSheet` slide up + backdrop fade                       | 350ms            | `Curves.decelerate` |
| Settings close          | Inverse                                                      | 300ms            | `Curves.easeIn`     |
| Context words appear    | `AnimatedOpacity` 0→0.2                                      | 200ms            | `Curves.easeOut`    |
| Context words disappear | `AnimatedOpacity` 0.2→0                                      | 150ms            | `Curves.easeIn`     |
| Guide line toggle       | `AnimatedOpacity` 0.15→0 or reverse                          | 300ms            | `Curves.easeInOut`  |
| Empty text attempt      | `Transform.translate` x oscillation ±4, 3 cycles             | 300ms            | Custom spring       |
| End of text             | "DONE" fade in, controls fade out, restart button fade in    | 1000ms staggered | `Curves.easeInOut`  |

---

## 13. Edge Cases

- **Empty input**: Disable Start button. If triggered, show `SnackBar`: "Paste some text to begin."
- **Single word**: Display it. Progress at 100%. Play/pause works (stays on word).
- **Very long words** (20+ chars): Never reduce font below `18`. Allow overflow visible — better to clip than reflow.
- **WPM at 1000+**: Disable the opacity pulse on word change (becomes a strobe). Set `AnimatedSwitcher` duration to `Duration.zero`.
- **WPM at ≤75**: Pulse is fine.
- **Rapid gesture firing**: Debounce toasts (200ms). Do not debounce the actual WPM/value change — only the visual feedback.
- **Context words at boundaries**: First word → no previous. Last word → no next. Adjust layout to keep current word centered even when only one context word is present (shift slightly to compensate).
- **Guide line with no context words**: Line is short (just spans the current word ± 40px).
- **Guide line with context words (line extension mode)**: Line spans all three words + 16px padding each side.
- **Font pair change during reading**: Apply immediately. The guide line position may shift slightly due to different character widths — recalculate and animate with `AnimatedPositioned(duration: 300ms)`.
- **`prefers-reduced-motion`**: Check `MediaQuery.of(context).disableAnimations`. If true: disable background orb animation, word nudge, opacity pulse. Keep theme transitions. Use a `disableAnimations`-aware wrapper for all animations.

---

## 14. Initial State / First Launch

When the app launches with no saved preferences:

1. **Settings panel is open** (sheet visible).
2. Background renders in **Dark** theme.
3. Reader stage is visible behind the backdrop but dimmed.
4. Textarea focused and empty, with hint text: _"Paste any text below, adjust your speed, and start reading."_
5. **Pre-populate** the textarea with a short sample paragraph (3–4 sentences) so the user can immediately tap "Start Reading."
6. All other settings at defaults: 350 WPM, font size 36, ORP 33%, "Geometric" font pair, guide line ON, context words "Hidden", punctuation pause ON, sentence pause ON, auto-hide controls ON.

---

## 15. Responsive Behavior

| Condition                     | Adjustments                                                                                                |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Width ≥ 768 (`LayoutBuilder`) | Word `fontSize` max `72`. Settings sheet `maxWidth: 500`, centered. Transport spacing `32`.                |
| Width < 768                   | Word `fontSize` max `48`. Settings sheet full-width. Transport spacing `24`. Settings icon always visible. |
| Width < 400                   | Word `fontSize` max `36`. Reduce settings padding to `16`. Stat line `fontSize: 10`.                       |

Use `MediaQuery.of(context).size.width` in layout builders. Font size slider max dynamically adjusts to the breakpoint-appropriate maximum.

---

## 16. Accessibility

- **Semantics**: Wrap the current word in `Semantics(label: "Current word: $word", liveRegion: true)`.
- **Focus**: All interactive widgets get default Flutter focus indicators. Customize with `FocusNode` + `focusedBorder` on text fields.
- **ARIA equivalents**: Use `Semantics` widgets with `button`, `slider`, `switch` roles where native widgets don't provide enough context.
- **Contrast**: All `onSurface` on `surface` combinations meet WCAG AA (4.5:1). `onSurfaceVariant` is supplementary only.
- **Keyboard**: Every action per Section 11.3.
- **Reduced motion**: Per Section 13.

---

## 17. Suggested Widget Tree (Conceptual)

```
MaterialApp
  └─ AnimatedTheme
      └─ Scaffold (no appBar, no bottomNav)
          └─ Stack
              ├─ BackgroundLayer (gradient, noise, orbs)
              ├─ ReaderStage (centered Column)
              │   ├─ StatLine (Row: wordCount, timeRemaining)
              │   ├─ WordDisplay (Stack)
              │   │   ├─ GuideLine (Positioned vertical line)
              │   │   ├─ ContextWordPrevious (Positioned, AnimatedOpacity)
              │   │   ├─ CurrentWord (RichText with ORP spans)
              │   │   └─ ContextWordNext (Positioned, AnimatedOpacity)
              │   ├─ PauseLabel (AnimatedOpacity)
              │   ├─ ProgressBar (GestureDetector + AnimatedContainer)
              │   ├─ TransportControls (Row of IconButtons, AnimatedOpacity)
              │   └─ WpmToast (AnimatedOpacity + AnimatedPositioned)
              ├─ FeedbackOverlays (WpmToast, FontSizeToast)
              └─ SettingsIcon (Positioned bottom-right, MouseRegion for hover)
```

Settings panel is shown via `showModalBottomSheet` or a persistent `AnimatedContainer` at the bottom of this stack — implementer's choice based on animation control needs.

---

This document is implementation-ready for Flutter. Pass it directly to your builder model.
