# Yabai (Window Manager)
Download [Brew](https://github.com/BosEriko/brew) as your package manager then install [Yabai](https://github.com/asmvik/yabai).

## Disable System Integrity Protection (Apple Silicon)
Shut down → hold Power → Options → Continue → Then open Terminal
```sh
csrutil disable
```

## Enable arm64e Preview ABI
Reboot into macOS, then run these from a normal Terminal
```sh
sudo nvram boot-args="-arm64e_preview_abi"
reboot
```

## Install Yabai Dependencies
```sh
brew install asmvik/formulae/yabai
brew install asmvik/formulae/skhd
brew install jq borders sketchybar
```

## Install Nerd Font
```sh
brew install --cask font-hack-nerd-font
```

## Clone the Repository
```sh
mkdir -p ~/Documents/Codes/Configuration ~/.config/borders ~/.config/sketchybar
git clone https://github.com/BosEriko/yabai.git ~/Documents/Codes/Configuration/yabai
ln -sf ~/Documents/Codes/Configuration/yabai/.yabairc ~/.yabairc
ln -sf ~/Documents/Codes/Configuration/yabai/.skhdrc ~/.skhdrc
ln -sf ~/Documents/Codes/Configuration/yabai/sketchybarrc ~/.config/sketchybar/sketchybarrc
ln -sf ~/Documents/Codes/Configuration/yabai/bordersrc ~/.config/borders/bordersrc
```

## Start Yabai
```sh
yabai --install-service
yabai --start-service
sudo sh -c "echo \"$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d ' ' -f1) $(which yabai) --load-sa\" > /private/etc/sudoers.d/yabai"
sudo yabai --load-sa
```

## Start skhd
```sh
skhd --install-service
skhd --start-service
```

## Start Sketchybar
```sh
brew services start sketchybar
```

While SketchyBar is running, the battery plugin checks every 10 seconds and automatically sleeps the Mac when the battery is below 10%, discharging, and using Battery Power. Systems without an internal battery, such as a Mac mini, are skipped. Connecting AC power prevents automatic sleep. Waking without connecting power will cause it to sleep again on the next check. Sleep reduces battery drain but does not eliminate it.

The mouse button to the left of the clock toggles the AFK avoider. While it is on (yellow), the mouse starts moving in a small circle after 60 seconds without mouse input and stops as soon as the mouse is moved, clicked or scrolled. Keyboard input is ignored. The toggle state is remembered across restarts, and `cliclick` is installed with Brew the first time it is turned on.

If the button shows "No access" (red), SketchyBar needs Accessibility permission to move the mouse:
1. Reveal the real SketchyBar binary in Finder and open the Accessibility settings:
```sh
open -R "$(realpath "$(which sketchybar)")"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```
2. Drag `sketchybar` from Finder into the Accessibility list. Use the revealed file, not `/opt/homebrew/opt/sketchybar/bin/sketchybar`, because that path is a symlink and macOS can ignore it.
3. Reload SketchyBar:
```sh
sketchybar --reload
```

The button switches to "On" within 30 seconds. The list may not show `sketchybar` until System Settings is quit (Cmd+Q) and reopened, even though the permission is already granted. After a `brew upgrade` of SketchyBar, the binary path changes, so drag the new one in again.

## Start JankyBorders
```sh
brew services start borders
```

## Hide Menu Bar
System Settings → Menu Bar → Set Automatically hide and show the menu bar to "Always"

## Hide Dock
System Settings → Desktop & Dock → Toggle Automatically hide and show the Dock to true

## Remove Click Wallpaper Feature
System Settings → Desktop & Dock → Set Click wallpaper to show desktop to "Only in Stage Manager"

## Keep Spaces in Order
System Settings → Desktop & Dock → Mission Control → Toggle off "Automatically rearrange Spaces based on most recent use"

## Reboot
Restart so the scripting addition loads and every service starts cleanly against a fresh session.
```sh
reboot
```

## Wallpaper
See [WALLPAPER.md](WALLPAPER.md).
