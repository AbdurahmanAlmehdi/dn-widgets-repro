# dn-widgets-repro

Minimal reproductions of DartNative widget-layer issues, one case per
entrypoint. Created with `dn create`.

First measured on DartNative `3.45.0-0.1.pre` (SDK build `19d573b7668`,
framework `80edbf105e`), iPhone 17 Pro and iPhone 17 Pro Max simulators,
iOS 26.1. Open cases re-checked on framework `4d6d99e30d` (2026-09-16),
engine `98a127957cb5`, Dart `3.12.0-192.0.dev`.

| Case | Entrypoint |
|---|---|
| A State built after `dispose()` leaves a red placeholder | `lib/main.dart` |
| `AnnotatedRegion` around a `Scaffold` renders a blank screen | `lib/cases/annotated_region.dart` |
| `SingleChildScrollView` inside `Center` renders nothing | `lib/cases/centred_scroll_view.dart` |
| Standard-host `AppBar` doesn't mirror in RTL | `lib/cases/standard_bar_rtl.dart` |
| `TextField.style.letterSpacing` is ignored | `lib/cases/text_field_letter_spacing.dart` |
| A formatter's returned caret is ignored on paste | `lib/cases/formatter_paste_caret.dart` |
| A pushed screen with a forced system bar and actions never appears | `lib/cases/system_bar_actions_push.dart` |

Fixed upstream in framework `4d6d99e30d`: the red band (#29), the standard
bar in RTL (#30) and the paste caret (#31).

Run a case with `dn run -d <device> -t <entrypoint>`. Its screenshots are in
`docs/cases/`.

## Red band after a root swap — `lib/main.dart`

```sh
dn run -d <ios-simulator>
```

Tap **Swap to B**.

The runApp root replaces its only child, A, with B. In the same tap handler, A
calls `setState` on itself. This is what a login button's `finally` does when
it clears its spinner after the session has already moved the app to its
home screen:

```dart
void _tap() {
  widget.onDone();          // parent: setState(() => _showB = true)
  setState(() => _taps++);  // A marks itself dirty in the same turn
}
```

**Expected (Flutter semantics):** A is deactivated and disposed. A disposed
`State` is never built again, so `setState` on it is a no-op for the frame.
B fills the screen.

**Actual:**

1. DartNative builds A **after** `dispose()`:

   ```
   RootA dispose
   RootA build after dispose (taps 1)
   ```

2. If that late build throws, a red placeholder (`#B00020`, 24 pt tall on the
   iPhone 17 Pro) stays on screen over B and takes layout space. It stays
   until the next cold start:

   ```
   [DN-Build] RootA threw during build, a placeholder stands in its slot: Bad state: RootA built after dispose()
   ```

A's build throws on purpose, to stand in for Riverpod's `ConsumerState`: it
throws `Bad state: Using "ref" after the widget was disposed is unsafe` when
built after dispose. That is how the band showed up in a real app: sign in →
home, and every sign-in and sign-out after that.

| Run | Log | Screen |
|---|---|---|
| `dn run` | late build + `[DN-Build] … placeholder` | ![band](docs/minimal-2-band-after-swap.png) |
| `dn run --dart-define=THROW=false` | late build only | ![no band](docs/minimal-3-no-throw-no-band.png) |

Before the tap: [docs/minimal-1-root-a.png](docs/minimal-1-root-a.png).

So there are two problems. Either fix removes the band in this case:

- **Build after dispose.** A `State` that is disposed in a frame must not
  be built in that frame, even if `setState` marked it dirty earlier in the
  same turn.
- **Orphaned error placeholder.** A build failure in a subtree that is being
  removed should not leave its placeholder mounted in the parent. And a
  placeholder that does show should not persist once its slot is gone.

### Isolation — `lib/red_band_steps.dart`

```sh
dn run -d <ios-simulator> -t lib/red_band_steps.dart --dart-define=STEP=<n> [--dart-define=KEYED=true] …
```

Two roots swapped by a button. The app's ingredients were added back one at a
time (cumulative). **None of them shows the band**, because nothing in the
harness throws when built after dispose. Screenshots are in `docs/steps/`:
`a-cold`, then `b-swapped`, then `a-back`, in Arabic on the iPhone 17 Pro Max.

| Step | Added | Band |
|---|---|---|
| 1 | two trivial roots (Scaffold body, label, button), with and without `KeyedSubtree` | no |
| 2 | `BottomNavigationBar` on B | no |
| 3 | `TextField` on A, focused before the swap | no |
| 4 | `SystemChrome.setSystemUIOverlayStyle` in B's `initState` | no |
| 5 | `Scaffold.backgroundColor` on both | no |
| 6 | `Scaffold.appBar` on B with `AppBarIOSConfig(systemBar: false)` | no |
| 7 | `Navigator.popUntil(isFirst)` post-frame after each swap | no |
| 9 | `registerRoutes`, `SystemChrome.defaultStyle`, `setAppBrightness(light)`, `Scaffold.brightness` | no |
| flags | spinner + `setState` after the swap, `obscureText`, `SegmentedControl`, a login-shaped A | no |

The trigger was found by cutting down the real app (the Daftar port) until
the band went away. In that app, the band needs the outgoing screen to call
`setState` after the swap **and** use `ref` in its build. Take away either one
and the band is gone.
