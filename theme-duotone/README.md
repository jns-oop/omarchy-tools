# theme-duotone

Recolours `~/Pictures/omarchy.png` into two colours taken from the current
Omarchy theme and writes the result into that theme's background folder, so
`omarchy theme bg next` can pick it up.

The image is flattened to luminance and its levels are stretched, then mapped
through a two-stop gradient: the darkest tone becomes the shadow colour, the
lightest the highlight colour. On the stock Omarchy logo — which is only black
and one grey — that produces literally two colours in the output PNG.

## Install

```sh
./install.sh                 # -> ~/.local/bin/theme-duotone
```

Requires `imagemagick` and `gum`:

```sh
sudo pacman -S --needed imagemagick gum
```

## Use

Run it bare for the picker:

```sh
theme-duotone
```

You get a preset list with live colour swatches, a hint footer, and a
confirmation prompt for setting the result as the current background.

| Key | Action |
| --- | --- |
| `↑` / `↓` | move |
| `/` | search presets |
| `enter` | select |
| `esc` | cancel |
| `y` / `n` | answer the confirm prompt |

Presets: **Theme match**, **Deep**, **Soft**, **Inverted**, **Pop**, **Mono**,
and **Custom…** to pick any two colours from the palette.

Non-interactive use:

```sh
theme-duotone --preset inverted --set
theme-duotone -c '#1b1112,#d66b6b' -y --no-set
```

```
-s, --source PATH    image to recolour (default: ~/Pictures/omarchy.png)
-t, --theme SLUG     theme to take colours from (default: the current theme)
-d, --dest-dir DIR   output folder (default: ~/.config/omarchy/backgrounds/<theme>)
-c, --colors A,B     shadow,highlight hex pair
-p, --preset NAME    theme-match|deep|soft|inverted|pop|mono
    --set            also make it the current background
    --no-set         never set it
-y, --yes            no prompts (needs --colors or --preset)
-h, --help           help
```

## Files it touches

- Reads the palette from `~/.local/state/omarchy/current/theme/colors.toml`,
  falling back to `omarchy-theme-dir <slug>`.
- Writes `~/.config/omarchy/backgrounds/<theme>/omarchy.png`. It never writes
  into `/usr/share/omarchy`.
- With `--set`, calls `omarchy-theme-bg-set`; if the file it just wrote is
  already the active background, it additionally calls
  `omarchy-shell -q background setInstant` — otherwise the running shell
  ignores a re-render at the same path and keeps showing the old pixels.

## Notes

- Theme palettes vary: some themes ship only `accent`, `background`,
  `foreground` and `color0..color15`. The preset rows fall back through the
  keys that exist, and the Custom picker lists every unique palette colour.
- `--theme` accepts a slug, not the display name (`eva-01`, not `Eva 01`).
