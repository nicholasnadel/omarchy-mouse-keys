# Mouse keys for Omarchy

Use a keyboard to move, scroll, and click the pointer on Omarchy/Hyprland.
This project uses [Kanata](https://github.com/jtroo/kanata) for the input layer.
It is a standalone keyboard service, not an Omarchy shell plugin.

**Status:** Experimental. The Kanata configuration and installer have been
validated on an ARM64 Omarchy MacBook, and Kanata's simulated input confirmed
the main key sequences. Physical-key behavior and other keyboard models still
need testing.

## Keys

| Keys | Action |
| --- | --- |
| Hold Right Command/Super, tap M | Enter mouse mode until Right Command/Super is released |
| Hold D, press a mouse key | Enter D mouse mode until D is released |
| H / J / K / L | Move left / down / up / right |
| V / B / N | Hold left / right / middle mouse button |
| Hold S + H/J/K/L | Scroll left / down / up / right |
| F | Move faster (2× in Command mode, 3.8× in D mode) |
| G in D mode | Move slower (0.5×) |

Right Command/Super works normally until M is pressed. Mouse mode then releases
the modifier so Hyprland does not treat a mouse click as a Super-drag. D remains
a normal letter when typed alone or followed by the common non-mouse keys
listed in the configuration. Its output waits until key release or the next
key press, which may feel different during fast typing. The movement and
scroll speeds approximate the original Karabiner
behavior; Kanata uses different units.

## Install

This installer targets an Omarchy desktop with systemd, udev, Polkit or sudo,
Python 3, `git`, `rust` (`/usr/bin/cargo` and `/usr/bin/rustc`), and `setfacl`
(Arch package `acl`). It builds Kanata 1.12.0 from a pinned source commit if
that version is not already at `~/.local/bin/kanata`. The build uses
`--no-default-features`, which omits Kanata's command action.

List connected keyboards:

```sh
python3 install.py --list
```

Choose the exact name from that output. Repeat `--device` to include more than
one keyboard:

```sh
python3 install.py --device "Apple SPI Keyboard"
```

To inspect the generated Kanata configuration and udev rule first, add
`--preview /tmp/mouse-keys-preview`. Preview mode does not install or change
system state.

The installer checks that the requested keyboard is connected, validates the
Kanata config and systemd unit, and refuses to overwrite a different existing
file. It installs a user service and a udev rule that grants the active desktop
user access only to the selected keyboard devices. A system authentication
prompt is expected for that rule. The service starts with the graphical
session. If you plug in a selected keyboard later, Kanata matches it by name.

## Check

```sh
systemctl --user is-active kanata-mouse-keys.service
journalctl --user -u kanata-mouse-keys.service -n 20 --no-pager
~/.local/bin/kanata --check --cfg ~/.config/kanata/mouse-keys.kbd
```

Try a physical keypress after installation. To stop the mapping, run:

```sh
systemctl --user disable --now kanata-mouse-keys.service
```

Kanata's emergency exit is **Left Control + Space + Escape**. The service
restarts on failure, so a successful emergency exit leaves it stopped.

To remove the installed files after disabling the service, review and delete
`~/.config/kanata/mouse-keys.kbd`,
`~/.config/systemd/user/kanata-mouse-keys.service`, and
`/etc/udev/rules.d/90-kanata-mouse-keys-uaccess.rules`, then run
`sudo udevadm control --reload-rules` and
`systemctl --user daemon-reload`. The compiled Kanata binary can remain if
another configuration uses it.

## Scope

The repository contains no third-party binary or personal keyboard names.
The installer fetches the pinned Kanata source only when it needs to build
the binary. It does not modify Omarchy's packaged files or Hyprland bindings.
Kanata's [configuration guide](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
documents the mouse actions and layers used here.

The scripts and configuration in this repository are MIT licensed. Kanata
itself has its own license and is obtained from its upstream repository.
