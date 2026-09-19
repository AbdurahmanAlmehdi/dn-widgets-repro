# A pushed screen with a forced system bar and actions never appears

```sh
dn pub get
dn run
```

Tap each button:

| Button | `AppBar` | Result |
|---|---|---|
| Push: none | `ios: AppBarIOSConfig(systemBar: true)`, no actions | pushes ✅ |
| Push: barButtonItem | `systemBar: true`, `actions: [BarButtonItem(...)]` | nothing happens ❌ |
| Push: widget | `systemBar: true`, `actions: [GestureDetector(...)]` | nothing happens ❌ |
| Push: barButtonItemDefaultHost | no `ios:`, `actions: [BarButtonItem(...)]` | pushes ✅ |

Each tap logs `push <name>`, so the tap arrives; no route appears and nothing
else is logged. Video: [docs/demo.mp4](docs/demo.mp4).
