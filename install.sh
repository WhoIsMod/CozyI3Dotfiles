#!/usr/bin/env bash
# Cozy Dark i3 (X11). Copies the configs into $HOME (existing files are backed up).
# Usage: ./install.sh [--deps]   (--deps also installs packages: Arch, Debian/Ubuntu or Fedora)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
have_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_distro() {
    # shellcheck disable=SC1091
    . /etc/os-release 2>/dev/null || true
    case " ${ID:-} ${ID_LIKE:-} " in
        *" arch "*|*" cachyos "*)         echo arch ;;
        *" debian "*|*" ubuntu "*)        echo debian ;;
        *" fedora "*|*" rhel "*)          echo fedora ;;
        *)                                echo unknown ;;
    esac
}

install_nerd_font() {
    if ! fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd'; then
        echo ">> Installing JetBrainsMono Nerd Font"
        local tmp; tmp="$(mktemp -d)"
        if curl -fL -o "$tmp/jb.tar.xz" \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz; then
            mkdir -p ~/.local/share/fonts/JetBrainsMonoNerd
            tar -xJf "$tmp/jb.tar.xz" -C ~/.local/share/fonts/JetBrainsMonoNerd
            fc-cache -f
        else
            echo ">> Font download failed; install a Nerd Font manually."
        fi
        rm -rf "$tmp"
    fi
}

install_obs_flatpak() {
    have_cmd obs && return 0
    if have_cmd flatpak; then
        echo ">> obs-studio isn't in your repos; installing OBS from Flathub"
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
        flatpak install --user -y flathub com.obsproject.Studio || echo ">> OBS install failed; see the README."
    fi
}

fetch() { curl -fL --retry 2 -o "$2" "$1"; }

unpack_zip() {
    if have_cmd unzip; then unzip -qo "$1" -d "$2"
    elif have_cmd bsdtar; then bsdtar -xf "$1" -C "$2"
    else python3 -m zipfile -e "$1" "$2"; fi
}

install_symbols_font() {
    fc-list 2>/dev/null | grep -qi 'Symbols Nerd Font' && return 0
    echo ">> Installing Symbols Nerd Font (icon fallback)"
    local tmp; tmp="$(mktemp -d)"
    if fetch https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz "$tmp/s.tar.xz"; then
        mkdir -p ~/.local/share/fonts/SymbolsNerd
        tar -xJf "$tmp/s.tar.xz" -C ~/.local/share/fonts/SymbolsNerd
    else
        echo ">> Symbols font download failed."
    fi
    rm -rf "$tmp"
}

install_fa6_font() {
    fc-list 2>/dev/null | grep -qi 'Font Awesome 6 Free' && return 0
    echo ">> Installing Font Awesome 6 Free (the panel names this exact version)"
    local tmp; tmp="$(mktemp -d)"
    if fetch https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip "$tmp/fa.zip"; then
        mkdir -p "$tmp/x" ~/.local/share/fonts/FontAwesome6
        unpack_zip "$tmp/fa.zip" "$tmp/x"
        find "$tmp/x" -name '*.otf' -exec cp {} ~/.local/share/fonts/FontAwesome6/ \;
    else
        echo ">> Font Awesome download failed."
    fi
    rm -rf "$tmp"
}

# All icon fonts the panel needs, installed for your user only (no sudo); skipped if present.
install_fonts() {
    have_cmd curl || { echo ">> curl is missing: install it so the icon fonts can be downloaded"; return 0; }
    install_nerd_font
    install_symbols_font
    install_fa6_font
    fc-cache -f
}

deps_arch() {
    sudo pacman -S --needed i3-wm polybar picom rofi dunst feh maim xclip xss-lock i3lock \
        xorg-xinput xorg-xset xorg-xsetroot \
        brightnessctl playerctl pavucontrol pipewire pipewire-pulse pipewire-alsa pipewire-audio \
        pipewire-jack wireplumber xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils \
        networkmanager network-manager-applet power-profiles-daemon gamemode libnotify \
        kitty dolphin openvpn polkit-gnome zenity obs-studio bluez bluez-utils blueman \
        gnome-themes-extra adwaita-icon-theme dconf gsettings-desktop-schemas \
        alsa-utils alsa-ucm-conf sof-firmware libpulse intel-media-driver libva-utils vulkan-intel \
        ttf-jetbrains-mono-nerd ttf-font-awesome curl jq
    sudo systemctl enable --now bluetooth
}

deps_debian() {
    have_pkg() { apt-cache show "$1" >/dev/null 2>&1; }
    sudo apt-get update
    local want=(i3 polybar picom rofi dunst feh maim xclip xss-lock i3lock xinput x11-xserver-utils
        brightnessctl playerctl pavucontrol pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils network-manager network-manager-gnome
        power-profiles-daemon gamemode libnotify-bin kitty dolphin fonts-font-awesome curl xz-utils jq
        openvpn zenity dbus dbus-user-session obs-studio bluez libspa-0.2-bluetooth blueman rfkill
        intel-media-va-driver vainfo mesa-vulkan-drivers gnome-themes-extra adwaita-icon-theme
        dconf-gsettings-backend libglib2.0-bin gsettings-desktop-schemas
        alsa-utils alsa-ucm-conf firmware-sof-signed pulseaudio-utils)
    local ok=() missing=() p
    for p in "${want[@]}"; do if have_pkg "$p"; then ok+=("$p"); else missing+=("$p"); fi; done
    sudo apt-get install -y "${ok[@]}"
    (( ${#missing[@]} )) && echo ">> Not available on this release: ${missing[*]}"
    for p in pkexec policykit-1; do if have_pkg "$p"; then sudo apt-get install -y "$p"; break; fi; done
    for p in policykit-1-gnome polkit-kde-agent-1 mate-polkit lxpolkit; do
        if have_pkg "$p"; then sudo apt-get install -y "$p"; break; fi
    done
    install_nerd_font
    sudo systemctl enable --now bluetooth 2>/dev/null || true
}

deps_fedora() {
    have_pkg() { rpm -q "$1" >/dev/null 2>&1 || dnf repoquery -q "$1" 2>/dev/null | grep -q .; }
    local want=(i3 polybar picom rofi dunst feh maim xclip xss-lock i3lock xinput xorg-x11-server-utils
        brightnessctl playerctl pavucontrol pipewire pipewire-pulseaudio pipewire-alsa
        pipewire-jack-audio-connection-kit wireplumber pulseaudio-utils alsa-utils alsa-ucm alsa-sof-firmware
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils NetworkManager network-manager-applet
        nm-connection-editor polkit gamemode libnotify kitty dolphin openvpn zenity curl xz jq bluez blueman
        gnome-themes-extra adwaita-icon-theme dconf glib2 dbus-tools
        libva-utils mesa-vulkan-drivers libva-intel-media-driver intel-media-driver)
    local ok=() missing=() p
    for p in "${want[@]}"; do if have_pkg "$p"; then ok+=("$p"); else missing+=("$p"); fi; done
    sudo dnf install -y "${ok[@]}"
    (( ${#missing[@]} )) && echo ">> Not available in your enabled repos: ${missing[*]}"
    for p in polkit-gnome lxqt-policykit; do if have_pkg "$p"; then sudo dnf install -y "$p"; break; fi; done
    for p in fontawesome-fonts-all fontawesome-6-free-fonts fontawesome-fonts; do
        if have_pkg "$p"; then sudo dnf install -y "$p"; break; fi
    done
    rpm -q tuned-ppd >/dev/null 2>&1 || rpm -q power-profiles-daemon >/dev/null 2>&1 \
        || sudo dnf install -y power-profiles-daemon || true
    if have_pkg obs-studio; then sudo dnf install -y obs-studio; else install_obs_flatpak; fi
    install_nerd_font
    sudo systemctl enable --now bluetooth 2>/dev/null || true
}

if [[ "${1:-}" == "--fonts" ]]; then
    install_fonts
    echo "Fonts installed. Restart the panel: ~/.config/polybar/launch.sh   (check: ~/.local/bin/check-icons)"
    exit 0
fi

if [[ "${1:-}" == "--deps" ]]; then
    case "$(detect_distro)" in
        arch)   deps_arch ;;
        debian) deps_debian ;;
        fedora) deps_fedora ;;
        *) echo ">> Unknown distro: install these yourself: i3, polybar, picom, rofi, dunst, feh, maim, xclip,"
           echo "   xss-lock, i3lock, xinput, brightnessctl, playerctl, pavucontrol, pipewire (+pulse/alsa/jack),"
           echo "   wireplumber, xdg-desktop-portal-gtk, gamemode, openvpn, obs-studio, bluez, a polkit agent." ;;
    esac
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
fi

install_fonts

cd "$HERE"
find .config .local -type f ! -path '.config/obs-studio/*' | while read -r f; do
    dest="$HOME/$f"
    mkdir -p "$(dirname "$dest")"
    [[ -e "$dest" ]] && cp "$dest" "$dest.bak-$STAMP"
    cp "$f" "$dest"
done

# OBS "Cozy Stream" profile (never overwrites an existing one)
OBS_PROFILE="$HOME/.config/obs-studio/basic/profiles/Cozy_Stream"
if [[ ! -d "$OBS_PROFILE" ]]; then
    mkdir -p "$(dirname "$OBS_PROFILE")"
    cp -r .config/obs-studio/basic/profiles/Cozy_Stream "$OBS_PROFILE"
fi

mkdir -p ~/.config/kitty
grep -qs 'cozy-dark.conf' ~/.config/kitty/kitty.conf || echo 'include cozy-dark.conf' >> ~/.config/kitty/kitty.conf

chmod +x ~/.local/bin/{desktop-mode,wallpaper,cozy-menu,polybar-json,polybar-bt,polybar-mic,polybar-uptime,polybar-mpris,polybar-workspaces,polybar-battery,polybar-idle,obs-idle-guard,check-icons,touchpad-setup,status-mode,status-obs,status-weather,obs-open,launch-game,openvpn-menu,openvpn-status,bluetooth-menu,mic-menu,audio-inputs,polkit-agent} \
         ~/.config/polybar/launch.sh
mkdir -p ~/.local/state ~/Pictures/Wallpapers ~/.config/openvpn-gui
echo "Done. Put wallpapers in ~/Pictures/Wallpapers."
echo "Log out and choose the 'i3' session at your login screen."
