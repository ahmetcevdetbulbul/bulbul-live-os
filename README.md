# 🐦 Bulbul OS Live

**A zero-install, boot-and-code Linux live environment for developers.**

Bulbul OS is a lightweight Debian/Ubuntu-based **live ISO** built with [`live-build`](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html). Boot it from a USB stick or a virtual machine and you get a ready-to-use XFCE desktop with a C/C++ toolchain and a code editor already installed — no setup, no installation, nothing to configure. Shut it down and it leaves no trace on the host machine.

![build-system](https://img.shields.io/badge/built%20with-live--build-1f6feb?style=flat-square)
![base](https://img.shields.io/badge/base-Ubuntu%20%22resolute%22%2026.04-E95420?style=flat-square&logo=ubuntu&logoColor=white)
![desktop](https://img.shields.io/badge/desktop-XFCE4-3a3a3a?style=flat-square)
![arch](https://img.shields.io/badge/arch-amd64-blue?style=flat-square)
![status](https://img.shields.io/badge/status-experimental-yellow?style=flat-square)

---

## 📸 Screenshot

Auto-login straight into a working XFCE desktop, with Geany opened on a sample project on first boot:

![Bulbul OS Live desktop screenshot](docs/screenshot.png)

---

## ✨ Features

| | |
|---|---|
| 🖥️ **XFCE4 desktop** | Fast, lightweight desktop environment (panel, window manager, file manager, desktop icons) |
| 📝 **Geany editor** | A ready-to-use, syntax-highlighting code editor — opens automatically with a sample `hello.cpp` on first login |
| ⚙️ **GCC / G++ toolchain** | `build-essential` is pre-installed, so you can compile C/C++ the moment you boot |
| 🔓 **Passwordless auto-login** | Boots straight to the desktop as user `bulbul` — no login screen to click through |
| 💻 **Terminal included** | `xfce4-terminal` for anything the GUI doesn't cover |
| 💽 **Zero install, zero trace** | Runs entirely from RAM/media; nothing is written to the host disk |

---

## 🚀 Quick Start — Run in QEMU

The fastest way to try Bulbul OS is inside [QEMU](https://www.qemu.org/), no real hardware or USB stick required.

> ℹ️ A pre-built `binary.iso` is **not** committed to this repository (it's ~1.8 GB — see [Building from Source](#-building-from-source)). Build it yourself first, or grab it from the [Releases](../../releases) page if one has been published.

```bash
qemu-system-x86_64 -cdrom binary.iso -m 2048 -smp 2
```

That's it — QEMU boots the ISO and you land on the XFCE desktop automatically.

### Useful flags

| Flag | Purpose |
|---|---|
| `-m 2048` | RAM for the VM (tested down to `1024` MB; 2048 MB is more comfortable) |
| `-smp 2` | Number of virtual CPU cores |
| `-enable-kvm` | **Linux hosts only** — hardware acceleration, boots in seconds instead of minutes |
| `-vnc :0` | Headless mode: serve the display over VNC (`localhost:5900`) instead of opening a window |
| `-nographic` | Serial-console-only mode, no graphical display at all (useful for quick boot smoke tests) |

Example with KVM acceleration on native Linux:

```bash
qemu-system-x86_64 -cdrom binary.iso -m 2048 -smp 2 -enable-kvm
```

> ⚠️ **No KVM available?** Without hardware acceleration QEMU falls back to software emulation (TCG), which is *significantly* slower — expect boot + full desktop startup to take a few minutes rather than seconds. This is normal, not a hang; just give it time.

---

## 🪟 Running from Windows via WSL

If you're on Windows, the easiest path is QEMU running *inside* WSL.

### 1. Install WSL (if you haven't already)

Open PowerShell **as Administrator**:

```powershell
wsl --install -d Ubuntu
```

Reboot if prompted, then finish the Ubuntu first-run setup (create a username/password).

### 2. Install QEMU inside WSL

```bash
sudo apt update
sudo apt install -y qemu-system-x86
```

### 3. Get `binary.iso` into your WSL filesystem

Either build it (see [Building from Source](#-building-from-source)) or copy a pre-built ISO in, e.g.:

```bash
cp /mnt/c/Users/<you>/Downloads/binary.iso ~/bulbul-live/
cd ~/bulbul-live
```

> 💡 Keep the ISO on the Linux (`ext4`) side of WSL, not under `/mnt/c/...` — disk I/O is much faster there, which matters a lot for a live ISO.

### 4. Boot it

```bash
qemu-system-x86_64 -cdrom binary.iso -m 2048 -smp 2
```

- **Windows 11 (WSLg):** the QEMU window just pops up on your Windows desktop like a normal app — nothing else to configure.
- **Windows 10 / no WSLg:** run with `-vnc :0` instead, then connect a VNC client (e.g. [TightVNC](https://www.tightvnc.com/), [RealVNC](https://www.realvnc.com/)) from Windows to `localhost:5900`.

```bash
qemu-system-x86_64 -cdrom binary.iso -m 2048 -smp 2 -vnc :0
```

---

## 💿 Writing to a Real USB Drive

You can boot Bulbul OS on real hardware from a USB stick.

> ⚠️ **Current limitation:** this image is built with `--binary-images iso` (a CD/DVD-style ISO), not a true hybrid ISO yet (see [Roadmap](#-roadmap)). That means a raw `dd` write isn't guaranteed to boot on every machine — a proper USB-flashing tool that rebuilds the boot structure is the reliable option for now.

**Recommended — Windows/macOS/Linux, GUI:**

1. Download [Rufus](https://rufus.ie/) (Windows) or [balenaEtcher](https://etcher.balena.io/) (Windows/macOS/Linux).
2. Select `binary.iso` as the source and your USB drive as the target.
3. Write, then reboot the target PC and select the USB drive from the boot menu (BIOS/UEFI boot menu key, commonly `F12`, `F10`, `Esc`, or `Del`).

**Linux/macOS, command line (advanced, know your device node!):**

```bash
# Double- and triple-check /dev/sdX — this is destructive and irreversible.
sudo dd if=binary.iso of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

---

## 🔑 Default Login

Bulbul OS auto-logs-in on boot, so you shouldn't need this — but for reference:

| User | Password |
|---|---|
| `bulbul` | *(none — passwordless account)* |
| `root` | `bulbul` |

This is intended strictly for a disposable, ephemeral live session — **do not** treat these as secure credentials for a persistent install.

---

## 🔨 Building from Source

This repository contains the [`live-build`](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html) configuration used to produce `binary.iso` — the ISO itself isn't tracked in git (it's ~1.8 GB of compiled/downloaded packages, not source).

**Requirements:** a Debian/Ubuntu machine or WSL Ubuntu instance, `live-build` installed, and a decent chunk of free disk space (~10 GB) and time (package downloads + squashfs compression).

```bash
sudo apt update
sudo apt install -y live-build

git clone https://github.com/<your-username>/bulbul-live.git
cd bulbul-live

sudo lb build
```

When it finishes, `binary.iso` will be sitting in the project root, ready to boot with QEMU or flash to a USB drive.

To clean up and start fresh:

```bash
sudo lb clean --all
```

---

## 🧰 Tech Stack

- **[live-build](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html)** — the Debian Live Systems build toolchain
- **Ubuntu 26.04 "resolute"** (amd64) — base distribution
- **[casper](https://gitlab.com/ubuntu-live/casper)** — live-session boot machinery (auto-login, live user creation)
- **GRUB 2** — bootloader
- **[XFCE4](https://www.xfce.org/)** — desktop environment
- **[LightDM](https://github.com/canonical/lightdm)** — display/login manager
- **[Geany](https://www.geany.org/)** — lightweight IDE/text editor
- **GCC / G++** (`build-essential`) — C/C++ compiler toolchain

---

## 🗺️ Roadmap

- [ ] **Python 3** development tooling
- [ ] **Java / OpenJDK**
- [ ] **VS Code** (or a lighter alternative code editor option)
- [ ] Hybrid ISO output (`--binary-images iso-hybrid`) for reliable `dd`-to-USB booting on all firmware types
- [ ] Persistent storage option (save work across reboots)
- [ ] Published pre-built ISO releases

Contributions and suggestions are welcome — feel free to open an issue.

---

## 📁 Project Structure

```
bulbul-live/
├── auto/                    # live-build's build/clean/config entry-point scripts
├── config/
│   ├── package-lists/       # Package selection (live.list.chroot)
│   ├── hooks/                # Post-install chroot hooks (users, auto-login, initramfs)
│   ├── includes.chroot/      # Files copied verbatim into the live filesystem
│   └── templates/            # Custom GRUB template, etc.
└── docs/
    └── screenshot.png
```

---

## 📄 License

No license has been chosen for this project yet.
