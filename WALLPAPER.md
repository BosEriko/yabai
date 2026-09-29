# Wallpaper

## Cycle Wallpaper
Cycles through images in `wallpaper/` on the main display.
- `lalt - j` — next
- `lalt - k` — prev

## Add a Wallpaper

### Run this command for adding a wallpaper
```sh
pnpm wallpaper https://example.com/image.jpg
```

### What the script does
1. Closes any numbering gaps in `wallpaper/`
2. Downloads the image from the URL
3. Normalizes it to PNG
4. Resizes it to cover at least 1920x1080, without upscaling
5. Losslessly compresses it with `optipng`
6. Commits and pushes

## Wallpaper Sources
- [4kwallpapers.com/anime](https://4kwallpapers.com/anime)
