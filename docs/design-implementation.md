# Design implementation

How the visual system in this repo is actually built. Every value below is the
one currently loaded; file paths are relative to `~/.config/hypr` (the repo's
`hypr/`).

The design has three layers:

1. **Windows** — borderless, slightly translucent, with a heavy blur and a soft
   shadow doing the separation work a border used to do.
2. **Shell surfaces** — quickshell `ii` panels (bar, sidebars, menus, OSD,
   overview) rendered as frosted glass over whatever is behind them.
3. **Motion** — expressive easing curves for windows, layers and workspaces.

---

## 1. Windows: borderless glass with soft elevation

Source: `custom/general.conf` (loaded after `hyprland/general.conf`, so it wins).

```conf
general {
    border_size = 0
}

decoration {
    active_opacity = 0.96
    inactive_opacity = 0.92
    dim_inactive = false

    blur {
        enabled = true
        size = 6
        passes = 3
        ignore_opacity = true
        xray = false
        new_optimizations = true
        vibrancy = 0.4
    }

    shadow {
        enabled = true
        range = 24
        offset = 0 6
        render_power = 3
        color = rgba(00000050)
    }
}
```

### Decisions

- **`border_size = 0`** removes the 1px accent outline inherited from
  `hyprland/general.conf` (`border_size = 1`, accent `rgba(0DB7D455)`). A native
  window should be separated by material and shadow, not by a drawn rectangle.
  The accent color variables still exist in `hyprland/colors.conf`; they are
  simply invisible at size 0.
- **Opacity 0.96 / 0.92.** Active windows stay nearly opaque so text contrast
  holds; inactive windows drop a little further so the focused window reads
  without relying on a border or a dim overlay.
- **`dim_inactive = false`.** Upstream dims inactive windows to 0.25 strength.
  With translucent glass that reads as muddy, so dimming is off and the opacity
  delta plus shadow does the hierarchy work.
- **`ignore_opacity = true`.** This is the key to the frosted effect: blur is
  computed even for windows whose opacity is below 1. Without it, translucency
  would show the sharp wallpaper through the window instead of a blurred
  version of it.
- **Blur size 6, passes 3.** Upstream uses size 3 / passes 1 — cheap and subtle.
  Doubling the radius and tripling the passes produces the large, smooth
  "ground glass" falloff visible behind kitty and the sidebars.
- **`xray = false`.** Upstream enables xray. Turning it off keeps the blur
  sampling local to what is directly behind the window, which preserves depth
  in a stacked layout instead of flattening every window into one backdrop.
- **`vibrancy = 0.4`** (upstream 0.35) pushes color saturation back into the
  blurred region so the blue wallpaper reads through dark windows.
- **Shadow, not outline.** `range = 24`, `offset = 0 6`, `render_power = 3`,
  `rgba(00000050)`. A downward-biased, wide, soft shadow makes the window float
  above the wallpaper. Upstream has shadows disabled; here they replace the
  border as the elevation cue.

### Geometry

From `hyprland/general.conf`:

```conf
general {
    gaps_in = 4
    gaps_out = 5
    gaps_workspaces = 50

    snap {
        enabled = true
        window_gap = 4
        monitor_gap = 5
        respect_gaps = true
    }
}

decoration {
    rounding = 18
    rounding_power = 2.4
}
```

`rounding = 18` is the base corner radius; `rounding_power = 2.4` biases the
curve toward a squircle rather than a plain rounded rectangle. The upstream
comment notes that fully clear squircles look off, so only +0.4 is applied —
enough to feel continuous, not enough to look like a pill. Tight gaps (4/5)
keep the glass panes visually connected instead of floating as isolated cards.

---

## 2. Shell surfaces: frosting the quickshell layer

Source: `custom/rules.conf`. This is where most of the "frosted shell" work
happens, because layer-shell surfaces are not windows and are not affected by
the `decoration` block above.

Hyprland's newer rule syntax is `layerrule = match:namespace <ns>, <property>`.
Quickshell surfaces are namespaced `quickshell:<surface>`.

```conf
# Frosted shell surfaces: retain blur under translucent pixels.
layerrule = match:namespace quickshell:bar, ignore_alpha 0.45
layerrule = match:namespace quickshell:sidebarLeft, ignore_alpha 0.45
layerrule = match:namespace quickshell:sidebarRight, ignore_alpha 0.45
layerrule = match:namespace quickshell:notificationPopup, ignore_alpha 0.45

# Sidebars sit above applications: blur that live content, not only wallpaper.
layerrule = match:namespace quickshell:sidebarLeft, xray off
layerrule = match:namespace quickshell:sidebarRight, xray off
layerrule = match:namespace quickshell:notificationPopup, xray off
```

The same material is applied to the rest of the shell in one grouped rule, while
excluding screenshot/selection surfaces and the authentication layer:

```conf
layerrule = match:namespace quickshell:(dock|overview|popup|mediaControls|indicator.*|osd.*|session|wallpaperSelector), ignore_alpha 0.45
layerrule = match:namespace quickshell:(dock|overview|popup|mediaControls|indicator.*|osd.*|session|wallpaperSelector), xray off
```

### Why `ignore_alpha 0.45`

Hyprland builds the blur mask from the layer's alpha, and the default cutoff
scales with the surface's own transparency. The upstream base used `0.79`, but
the shell material's fill is around `0.70` alpha — at `0.79`, the material is
below the cutoff, so Hyprland treats it as fully transparent and there is
nothing left to blur. The result is a flat, un-frosted panel.

Lowering the cutoff to `0.45` keeps the translucent fill inside the blur mask
while still excluding the near-transparent parts of the surface (the soft
shadow edges, max alpha `0.30`, and the fully transparent margins). That is what
makes the bar and sidebars look like glass rather than tinted rectangles.

### Why `xray off` on sidebars

The sidebars and notification popup float above application content. With xray
enabled, the blur behaves as if the layer were alone on the desktop and only
samples the wallpaper; with it off, the panel frosts the live application behind
it. That distinction is visible in the screenshots: the control center blurs the
desktop and widgets, not just the wallpaper.

The grouped rule covers `dock`, `overview`, `popup`, `mediaControls`,
`indicator.*`, `osd.*`, `session`, and `wallpaperSelector`. Screenshot and
selection surfaces are intentionally left out: blurring the thing you are
trying to select or capture would be wrong.

---

## 3. Motion: expressive but fast

Source: `hyprland/general.conf`.

```conf
animations {
    bezier = expressiveFastSpatial, 0.42, 1.67, 0.21, 0.90
    bezier = expressiveSlowSpatial, 0.39, 1.29, 0.35, 0.98
    bezier = emphasizedDecel,       0.05, 0.70, 0.10, 1.00
    bezier = emphasizedAccel,       0.30, 0.00, 0.80, 0.15
    bezier = menu_decel,            0.10, 1.00, 0.00, 1.00
    bezier = menu_accel,            0.52, 0.03, 0.72, 0.08
    bezier = stall,                 1.00, -0.10, 0.70, 0.85

    animation = windowsIn,  1, 3,   emphasizedDecel, popin 80%
    animation = windowsOut, 1, 2,   emphasizedDecel, popin 90%
    animation = layersIn,   1, 2.7, emphasizedDecel, popin 93%
    animation = layersOut,  1, 2.4, menu_accel,     popin 94%
    animation = workspaces, 1, 7,   menu_decel,     slide
    animation = specialWorkspaceIn, 1, 2.8, emphasizedDecel, slidevert
    animation = border, 1, 10, emphasizedDecel
}
```

The `expressive*` curves overshoot (control points above 1), which gives the
scale/slide motion a little spring without a bounce. Windows enter fast (3) and
leave faster (2); layers enter a touch slower with a larger popin (93%) so the
sidebars feel like they unfold rather than snap. Workspaces use the slow
`menu_decel` at 7 for a calm horizontal slide. `stall` is reserved for fading
layers out so dismissal feels decisive.

Gestures mirror the same model:

```conf
gesture = 3, swipe, move,
gesture = 2, pinch, float
gesture = 4, horizontal, workspace
gesture = 4, up,   dispatcher, global, quickshell:overviewWorkspacesToggle
gesture = 4, down, dispatcher, global, quickshell:overviewWorkspacesClose

gestures {
    workspace_swipe_distance = 700
    workspace_swipe_cancel_ratio = 0.2
    workspace_swipe_min_speed_to_force = 5
    workspace_swipe_direction_lock = true
    workspace_swipe_direction_lock_threshold = 10
    workspace_swipe_create_new = true
}
```

A 700px swipe is long enough not to fire accidentally on a 1920px panel; the
0.2 cancel ratio and direction lock make a half-swipe return cleanly instead of
snapping to the next workspace.

---

## 4. Widgets and shell surfaces

The shell is quickshell (`ii`), started as a user service:

```conf
exec-once = systemctl --user start quickshell@$qsConfig.service
```

`$qsConfig` is set to `ii` at the top of `hyprland.conf`. The surfaces visible
in the screenshots:

| Surface | Toggle | What it shows |
| --- | --- | --- |
| Top bar | always on (`Super` `J` hides it) | workspaces, focused title, media, tray, clock, indicators, weather, battery |
| Desktop widgets | always on | analog clock + weather card |
| Right sidebar | `Super` `N` | Wi-Fi/Bluetooth/VPN/screen share, media, quick toggles, notifications, calendar |
| Left sidebar | `Super` `A` | AI assistant panel |
| Resources HUD | quickshell module | live RAM, swap, CPU load |
| Overview | `Super` `Tab` | workspace thumbnails |

All of them get the layer rules above, so they share one material: translucent
fill, blurred backdrop, soft shadow, 18px squircle corners. Consistency comes
from the shared rule, not from styling each panel separately.

Wallpaper is handled by the dots-hyprland pipeline. `hyprland/execs.conf` runs a
generated restore hook at startup:

```conf
exec-once = ~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh
```

That file is rewritten by `switchwall.sh` whenever the wallpaper changes
(`Ctrl+Super` `T` opens the selector), so it is not meant to be edited by hand.

---

## 5. Idle and lock

`hypridle.conf` defines the power ladder:

| Timeout | Action |
| --- | --- |
| 300 s | `loginctl lock-session` |
| 600 s | DPMS off |
| 900 s | `systemctl suspend` (fallback `loginctl suspend`) |

Before sleep the session is locked; `inhibit_sleep = 3` lets a short grace
period run first. The lock command prefers the quickshell lock:

```conf
$lock_cmd = hyprctl dispatch global quickshell:lock & pidof qs quickshell hyprlock || hyprlock
```

`hyprlock.conf` is a centred, minimal lock screen: a 250×50 input field, a 65pt
clock, the date, the username, a live status line, and a Caps Lock warning.
Colors and the background image come from `hyprlock/colors.conf`, which is
generated by matugen — regenerate it with the wallpaper instead of editing it.

---

## 6. Environment and hardware

`hyprland/env.conf` contains the machine-specific part of the design:

```conf
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = AQ_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0
env = LIBVA_DRIVER_NAME,iHD
env = QT_QPA_PLATFORM, wayland
env = QT_QPA_PLATFORMTHEME, kde
env = TERMINAL,kitty -1
```

`card1` is the Intel HD 530 that drives eDP-1; `card0` is the NVIDIA 940MX on
the legacy 470 driver. Forcing the iGPU as the primary DRM device avoids the
legacy-NVIDIA-on-Wayland problems (and the commented `GBM_BACKEND` /
`__GLX_VENDOR_LIBRARY_NAME` lines are the alternative that was tried and
dropped). VA-API uses `iHD` so video decode stays on the Intel GPU.

`Super` `G` / `Super+Shift` `G` call `~/.local/bin/gpu-toggle` for per-app GPU
switching without restarting the session.

---

## 7. Tuning recipes

All changes go in `custom/general.conf` or `custom/rules.conf`, then
`hyprctl reload`.

**More frost / more depth**

```conf
active_opacity = 0.90
inactive_opacity = 0.86
blur { passes = 4; size = 8 }
```

**Better performance on the iGPU**

```conf
blur { size = 4; passes = 2; vibrancy = 0.3 }
shadow { enabled = false }
```

**Bring back a thin outline**

```conf
general { border_size = 1 }
```

**Shell blur is too soft / too harsh**

Raise `ignore_alpha` toward `0.6` for a thinner frost, lower it toward `0.3`
for a denser one. Do not go below the shell's fill alpha or the panel loses its
blur entirely — that was the original `0.79` bug.

**Battery-first**

```conf
decoration { dim_inactive = true; dim_strength = 0.2 }
```

---

## 8. Validation

- `hyprctl configerrors` returns empty after `hyprctl reload`.
- Screenshots in `assets/` are 1920×1080 captures of the live session.
- Values in this document were read from the tracked files, not reconstructed
  from memory.

Known limits: the monitor layout and GPU env are specific to this laptop;
`hyprlock/colors.conf` is matugen output and will be overwritten; upstream
`hyprland/` files can be replaced by a dots-hyprland update, so keep personal
changes in `custom/`.
