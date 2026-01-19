# Yabai (Window Manager)
Download [Brew](https://github.com/BosEriko/brew) as your package manager then install [Yabai](https://github.com/asmvik/yabai).

## Disable System Integrity Protection (Apple Silicon)
Shut down → hold Power → Options → Continue → Terminal
```sh
csrutil disable
sudo nvram boot-args="-arm64e_preview_abi"
reboot
```

## Install Yabai Dependencies
```sh
brew tap FelixKratz/formulae
brew install yabai skhd jq borders sketchybar font-hack-nerd-font
```

## Clone the Repository
```sh
mkdir -p ~/Documents/Codes/Configuration ~/.config/sketchybar/plugins
git clone https://github.com/BosEriko/yabai.git ~/Documents/Codes/Configuration/yabai
cp -R "$(brew --prefix)/share/sketchybar/examples/plugins/." ~/.config/sketchybar/plugins/
ln -sf ~/Documents/Codes/Configuration/yabai/.yabairc ~/.yabairc
ln -sf ~/Documents/Codes/Configuration/yabai/.skhdrc ~/.skhdrc
ln -sf ~/Documents/Codes/Configuration/yabai/sketchybarrc ~/.config/sketchybar/sketchybarrc
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

## Hide Menu Bar
System Settings > Desktop & Dock > Menu Bar
Set Automatically hide and show the menu bar to Always
