# hyprland-dotfiles

My Hyprland setup. Built on top of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
(illogical-impulse), with personal overrides kept in `hypr/custom/`.

## Layout

```
dotfiles/
└── hypr/              -> symlinked to ~/.config/hypr
    ├── hyprland.conf  # entry point, sources everything else
    ├── custom/        # my overrides (edit here)
    ├── hyprland/      # upstream defaults from dots-hyprland
    ├── hyprlock.conf
    ├── hypridle.conf
    ├── monitors.conf  # written by nwg-displays
    └── workspaces.conf
```

`~/.config/hypr` is a symlink to `dotfiles/hypr`, so edits are tracked by git
and stay live at the same time.

## Install

Prerequisites: the [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
dependencies (Hyprland, quickshell, the `ii` shell config, fonts, etc.).

```sh
git clone git@github.com:justrhey/hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` backs up any existing `~/.config/hypr` and creates the symlink.
Run `hyprctl reload` (or re-login) to apply.

## Notes

- `custom/` is the only place I edit. `hyprland/` is upstream and may be
  replaced when dots-hyprland is updated.
- The look: glassmorphism (no borders, blurred translucent windows) in
  `custom/general.conf`.
- Lock/idle is driven by quickshell (`ii`) with `hyprlock` as fallback.

## License

GPL-3.0. The files under `hypr/hyprland/` and `hypr/hyprlock/` are derived from
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), also GPL-3.0.
See [LICENSE](LICENSE).
