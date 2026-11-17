# Mouse keys for Omarchy

Use a keyboard to move, scroll, and click the pointer on Omarchy/Hyprland.
The Omarchy bar widget shows service status, a shortcut guide, and a start/stop button.
[Kanata](https://github.com/jtroo/kanata) handles the keyboard input below the
desktop shell. Adding the widget never installs or starts Kanata automatically.

**Status:** Experimental. The Kanata configuration and installer have been
validated on an ARM64 Omarchy MacBook. Holding D for pointer movement worked
on its Apple keyboard; typing and speed sequences passed Kanata's simulator.
Other keyboard models still need testing.

## Keys

| Keys | Action |
| --- | --- |
| Hold D for 250 ms | Temporarily enter mouse mode |
| D + H/J/K/L | Move left / down / up / right |
| D + V/B/N | Hold left / right / middle mouse button |
| D + S + H/J/K/L | Scroll left / down / up / right |
| Hold D + F / G | Move faster (3.8×) / slower (0.5×) |

When the service runs, mouse controls work only while D is held. Release D to
type normally, including in text fields. A quick D still types the letter;
its 250 ms hold threshold avoids taking over fast D-led typing. The bar button
enables or disables the service.
The movement and scroll speeds approximate the original Karabiner behavior;
Kanata uses different units.

## Install

Install and enable the Omarchy widget:

```sh
omarchy plugin add https://github.com/nicholasnadel/omarchy-mouse-keys.git --enable
```

The widget initially says **Setup needed**. Run its setup command from the
installed plugin folder, or use the same commands from a local clone:

```sh
cd ~/.config/omarchy/plugins/io.github.nicholasnadel.mouse-keys
python3 install.py --list
python3 install.py --device "Apple SPI Keyboard"
```

Choose your keyboard's exact name from `--list`; the name above is an example.
Repeat `--device` to include more than one keyboard. Once the service is
installed, the widget can stop or start it without elevated privileges.

The installer targets an Omarchy desktop with systemd, udev, Polkit or sudo,
Python 3, `git`, `rust` (`/usr/bin/cargo` and `/usr/bin/rustc`), and `setfacl`
(Arch package `acl`). It builds Kanata 1.12.0 from a pinned source commit if
that version is not already at `~/.local/bin/kanata`. The build uses
`--no-default-features`, which omits Kanata's command action.

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

Then remove the bar widget with:

```sh
omarchy plugin remove io.github.nicholasnadel.mouse-keys
```

Removing the widget alone leaves the Kanata service and keyboard permissions
in place. Stop the service first if you no longer want the keyboard mapping.

## Scope

The repository contains no third-party binary or personal keyboard names.
The installer fetches the pinned Kanata source only when it needs to build
the binary. It does not modify Omarchy's packaged files or Hyprland bindings.
Kanata's [configuration guide](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
documents the mouse actions and layers used here.

The scripts and configuration in this repository are MIT licensed. Kanata
itself has its own license and is obtained from its upstream repository.
