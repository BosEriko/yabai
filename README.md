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

## Reboot
Restart so the scripting addition loads and every service starts cleanly against a fresh session.
```sh
reboot
```
