# Cozy Dark i3 (X11)

The Sway setup, moved to **X11 with i3** so OBS Studio has all its features, with the
same keyboard shortcuts and structure:

- **i3** window manager (same config layout and keybinds as the Sway edition)
- **polybar** panel (workspace dots, dock-style launchers, coloured icons)
- **picom** compositor (rounded corners, blur), **rofi** launcher, **dunst** notifications
- **PipeWire** audio, **feh** wallpapers, **i3lock** + **xss-lock** screen locking
- Game / Business / **Stream** modes, OpenVPN, Bluetooth, microphone menus, OBS profile

## Why X11 for OBS

On Sway (Wayland) OBS can only capture whole monitors through the portal and its global
hotkeys don't work. On X11 you get everything: **Window Capture (Xcomposite)**,
**Screen Capture (XSHM)**, global hotkeys (Settings -> Hotkeys), the virtual camera
and per-window capture for games.

"Display manager" is the login screen (SDDM, GDM, LightDM...). You don't need to change
it: choose the **i3** session there. Your Sway session stays available.

## Install

```
unzip cozy-i3.zip && cd cozy-i3
bash install.sh --deps      # --deps installs packages (Arch, Debian/Ubuntu or Fedora)
```

Then log out and choose the **i3** session at the login screen. The installer backs up
files it replaces as `<file>.bak-<timestamp>`. Packages that don't exist on your release
are listed and skipped (on Fedora, OBS falls back to the Flathub build).

Put wallpapers in `~/Pictures/Wallpapers`. To validate the config: `i3 -C`.

## Keybinds (`$mod` = Super)

| Keys | Action |
|---|---|
| `$mod+Return` | Terminal (kitty) |
| `$mod+d` | App launcher (rofi) |
| `$mod+b` / `$mod+e` | Browser / Files (Dolphin) |
| `$mod+Shift+q` | Close window |
| `$mod+Shift+c` / `$mod+Shift+r` | Reload config / restart i3 in place |
| `$mod+h/j/k/l` or arrows | Focus (add `Shift` to move the window) |
| `$mod+1..0` | Switch workspace (`Shift` to move window there) |
| `$mod+v` / `$mod+s` | Split vertical / horizontal |
| `$mod+f` | Fullscreen |
| `$mod+space` | Toggle floating |
| `$mod+r` | Resize mode (`Esc` to leave) |
| `$mod+g` | **Toggle Game / Business mode** |
| `$mod+Shift+g` | Game mode + launch Steam/Lutris |
| `$mod+Shift+b` | Business mode |
| `$mod+Shift+o` | **Stream mode** (opens OBS, silences notifications) |
| `$mod+o` | Focus / launch OBS Studio |
| `$mod+m` | Mode menu (modes, lock, logout, reboot, shutdown) |
| `$mod+Escape` | System mode (g/s/b/l/q) |
| `$mod+w` / `$mod+Shift+w` | Next / random wallpaper |
| `$mod+Shift+v` | VPN menu |
| `$mod+Shift+t` | Bluetooth menu |
| `$mod+Shift+m` | Microphone / input device menu |
| `$mod+Shift+i` | Hide / show the panel (privacy while capturing the screen) |
| `$mod+n` / `$mod+Shift+n` | Volume control / network editor |
| `$mod+Shift+x` | Lock screen |
| `Print` / `Shift+Print` / `Ctrl+Print` | Screenshot region / full screen / region to clipboard |

Volume, mic mute, media and brightness keys work via `wpctl`, `playerctl`, `brightnessctl`.

## The panel (same as the Sway edition)

Bottom bar, 40 px, dark translucent background, same colours and icon order:

- **Left:** app grid (rofi), workspace dots (1-5 always shown, more appear when used; click
  to switch, scroll to cycle), window title
- **Centre:** coloured launchers: terminal, files, browser, Discord, Spotify, Steam
- **Right:** now playing, **OBS**, mode pill, keep-awake eye, clock, weather, CPU, RAM,
  uptime, **VPN**, **Bluetooth**, brightness, volume, **mic**, Wi-Fi, battery, tray, power

The OBS, mode and VPN buttons are rounded pills like on Sway: the mode pill is blue in
Business, lavender in Game and red in Stream; the VPN pill is grey / yellow / green for
disconnected / connecting / connected; the OBS pill turns red while OBS runs.

Clicks are the same: mode pill toggles Game/Business (right-click: menu); OBS button
focuses or launches OBS (right-click: Stream mode); VPN, Bluetooth and mic open their menus
(right-click: disconnect / power toggle / mute); the eye toggles "keep screen awake"; the
clock click swaps time and date; scroll on brightness and mic changes the level.
Bluetooth shows the connected device's name and battery when it reports one, otherwise
the number of connected devices. The battery uses the same five icons and turns yellow at
30% and red at 15%. While OBS is open the screen stays awake (as on Sway) and normal
blanking returns when it closes.

Differences polybar can't avoid: no hover tooltips, no hover highlight on the launchers,
and the window title isn't shortened for Firefox. Needs `jq` (installed by `--deps`) for
the workspace dots.

## Game / Business / Stream mode

| | Business | Game | Stream |
|---|---|---|---|
| GameMode client | off | on | on |
| Power profile | balanced | performance | performance |
| picom compositor | on | **off** (less GPU load) | **off** |
| Notifications | on | on | **silenced** (dunst paused) |
| Screen blanking | normal | normal | **disabled** |

Stream mode also launches OBS if it isn't running and warns if you are on battery.
Turning the compositor off can cause tearing on Intel graphics; if you see it, enable
TearFree for the modesetting driver (`/etc/X11/xorg.conf.d/20-intel.conf`:
`Section "Device"`, `Identifier "Intel"`, `Driver "modesetting"`,
`Option "TearFree" "true"`, `EndSection`). A silent reset to Business mode runs at login.

## Streaming with OBS Studio

- **Capture:** add *Window Capture (Xcomposite)* for one window, or *Screen Capture (XSHM)*
  for a monitor. Global hotkeys work in *Settings -> Hotkeys*. If you capture the whole
  screen, hide the panel with `$mod+Shift+i`.
- **Encoder (Intel laptop):** the installer adds an OBS profile called **Cozy Stream**
  (1080p, 30 fps, x264 `veryfast`, CBR 6000 kbps). For much lower CPU load and heat use
  *Settings -> Output -> Streaming -> Encoder* -> **FFmpeg VAAPI H.264 (hardware)**, device
  `/dev/dri/renderD128`. Check with `vainfo` that H264 encoding is listed (look for
  `VAEntrypointEncSlice` or `EncSliceLP`). The profile is never overwritten.
- **Audio routing:** PipeWire creates three virtual outputs: *Stream Game*, *Stream
  Music*, *Stream Chat*. In `pavucontrol` -> Playback send each app to one; you still hear
  everything. In OBS add an *Audio Input Capture (PulseAudio)* source per output and pick
  **Monitor of Stream Game** (etc.) plus your microphone. Mute OBS's *Desktop Audio* so
  nothing is captured twice. Restart PipeWire once to load the sinks:
  `systemctl --user restart pipewire pipewire-pulse wireplumber`.
- **Virtual camera (optional):** needs the `v4l2loopback` kernel module, e.g.
  `sudo modprobe v4l2loopback exclusive_caps=1 card_label="OBS Camera"`.

## Microphones and aux (3.5 mm / inline) inputs

All inputs go through PipeWire, so OBS, Audacity, Discord and JACK apps see them.
`~/.local/bin/audio-inputs status` shows what PipeWire sees, the kernel's jack-detection
state and a **Verdict**; `audio-inputs fix` moves a card off the Pro Audio profile,
enables capture controls and unmutes inputs. `mic-menu` (`$mod+Shift+m`) picks the default
input. In pavucontrol -> Input Devices set *Show:* to **All Input Devices**.

A mic with a plain 3.5 mm plug in a laptop's single headset (combo) jack is seen as
headphones, so the codec reports no microphone. Use a mic-to-headset (TRS to TRRS) adapter
or a USB sound card. USB mics and 48 V XLR condenser mics (which need an interface with
phantom power) are described in the same script's output.

## VPN and Bluetooth

- **VPN:** the VPN button lists configs from `~/.config/openvpn-gui/` (or use *Import
  config*), connects through `pkexec` (a polkit agent starts with i3) and turns green
  when the tunnel is up. Left-click: menu; right-click: disconnect.
- **Bluetooth:** icon is grey when off, blue when on, green with a count when devices are
  connected. Left-click: connect / disconnect / pair (10 s scan) / power; right-click:
  power toggle.

## Troubleshooting

- **Panel shows `/bin/sh: ... /.local/bin/...: No such file or directory`:** the session was
  started without `HOME` set. `launch.sh` now resolves it and writes absolute paths into
  `~/.cache/polybar/config.ini`, and every helper script sets `HOME` itself. Re-run
  `install.sh`, then `$mod+Shift+r`.
- **Icons show as empty boxes or wrong symbols:** the panel needs JetBrainsMono Nerd Font,
  Font Awesome **6** (Free and Brands) and Symbols Nerd Font. `install.sh` now fetches any
  that are missing into `~/.local/share/fonts` (no sudo); run just that with
  `bash install.sh --fonts`, then `~/.config/polybar/launch.sh`. `check-icons` lists every
  icon and which font provides it (or MISSING). Distros that ship Font Awesome 7 use
  different family names, which is why the exact version 6 is installed.
- **Panel missing:** run `~/.config/polybar/launch.sh` from a terminal and read the output.
- **File dialogs white or oversized:** GTK dark theme lives in `~/.config/gtk-3.0` and
  `gtk-4.0`; i3 rules centre dialogs at 60% x 70% of the screen. Reset a stored huge
  size with `gsettings reset-recursively org.gtk.Settings.FileChooser`, then restart
  `xdg-desktop-portal`.
- **Touchpad taps do nothing:** `touchpad-setup` enables tap, natural scrolling and
  palm rejection via `xinput` at login.
- **Blur or rounded corners glitch:** start picom without blur by editing
  `~/.config/picom/picom.conf` (`blur-method = "none";`).

## Files

```
~/.config/i3/config              main config
~/.config/polybar/{config.ini,launch.sh}
~/.config/{picom,dunst,rofi}/    compositor, notifications, launcher theme
~/.config/kitty/cozy-dark.conf   terminal colours
~/.config/gtk-3.0, gtk-4.0       dark GTK theme
~/.config/gamemode.ini
~/.config/pipewire/pipewire.conf.d/10-stream-sinks.conf
~/.config/xdg-desktop-portal/i3-portals.conf
~/.config/obs-studio/basic/profiles/Cozy_Stream/
~/.local/bin/
    desktop-mode                 game / business / stream controller
    wallpaper                    feh wallpaper manager
    cozy-menu                    rofi dmenu wrapper used by the menus
    openvpn-menu, openvpn-status VPN
    bluetooth-menu               Bluetooth
    mic-menu, audio-inputs       microphones
    obs-open                     focus-or-launch OBS
    polybar-*, status-*          panel helpers
    polkit-agent, touchpad-setup, launch-game
```

## Palette

| | | |
|---|---|---|
| bg `#1a1d2b` | surface `#2c3147` | text `#d9deee` |
| blue `#8aa4ff` | lavender `#b4a0ff` | cyan `#8ad6e0` |
| green `#a9d9a0` | yellow `#ecd08a` | red `#ef8e9a` |
