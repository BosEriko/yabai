# Yabai (Window Manager)
Download [Brew](https://github.com/BosEriko/brew) as your package manager then install [Yabai](https://github.com/asmvik/yabai).

Disable System Integrity Protection:
Apple Silicon: Shut down → hold Power → Options → Continue
```
csrutil disable
sudo nvram boot-args="-arm64e_preview_abi"
reboot
```
---
Install Yabai Dependencies:
```
brew tap FelixKratz/formulae
brew install yabai skhd jq borders sketchybar font-hack-nerd-font
```
---
Start Yabai (Also enable on accessibility):
```
yabai --install-service
yabai --start-service
```
---
Enable Yabai Scripting:
```
sudo sh -c "echo \"$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d ' ' -f1) $(which yabai) --load-sa\" > /private/etc/sudoers.d/yabai"
sudo yabai --load-sa
```
---
Start skhd (Also enable on accessibility):
```
skhd --install-service
skhd --start-service
```
---
Start Sketchybar
```
mkdir -p ~/.config/sketchybar/plugins
cp $(brew --prefix)/share/sketchybar/examples/sketchybarrc ~/.config/sketchybar/sketchybarrc
cp -r $(brew --prefix)/share/sketchybar/examples/plugins/ ~/.config/sketchybar/plugins/
brew services start sketchybar
```
---
Hide Menu Bar:
System Settings > Desktop & Dock > Menu Bar
Set Automatically hide and show the menu bar to Always
