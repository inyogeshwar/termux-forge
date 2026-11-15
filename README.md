<div align="center">

# ⚒️ TERMUX-FORGE

### `Termux` → `OpenCode AI` → `Android APK / AAB`
**Phone par hi Android app banao, build karo, sign karo aur ship karo.** ⚡

[![Release](https://img.shields.io/github/v/release/inyogeshwar/termux-forge?style=for-the-badge&color=22c55e)](https://github.com/inyogeshwar/termux-forge/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/inyogeshwar/termux-forge/ci.yml?style=for-the-badge&label=CI)](https://github.com/inyogeshwar/termux-forge/actions)
[![Termux](https://img.shields.io/badge/Termux-Android-000000?style=for-the-badge&logo=android)](https://termux.dev)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)

</div>

```text
 forge create my-app  →  forge ai  →  forge build  →  forge export
   (project)          (AI se code)    (APK/AAB)       (Download/ForgeApps)
```

---

## 📑 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Install](#-install)
- [Quick Start](#-quick-start-2-minute)
- [Commands](#-commands)
- [Templates](#-templates)
- [Release signing & keystore](#-release-signing--keystore)
- [Troubleshooting](#-troubleshooting)
- [Uninstall](#-uninstall)
- [How it works](#-how-it-works)
- [Development & tests](#-development--tests)
- [Credits](#-credits)

---

## ✨ Features

| | Feature | Details |
|---|---|---|
| 📦 | **Official `.deb` package** | GitHub Releases se direct install, auto-built by CI |
| 🚀 | **One-liner setup** | Android SDK + Gradle + Zsh + OpenCode, ek command me |
| 🤖 | **OpenCode AI** | Phone par natively AI coding agent (`forge ai`) |
| 🏗️ | **Project templates** | `kotlin` (Hello World) aur `webview` (kisi bhi website ka app) |
| 📱 | **APK & AAB** | Debug APK, signed Release APK, Play Store AAB |
| 🔐 | **Safe keystore** | Har install par **random password** wala keystore, backup command ke saath |
| 🎨 | **Custom icon** | Koi bhi PNG/JPG → sabhi densities + manifest auto-update |
| 🔢 | **Version bump** | `forge bump` → `versionName` + `versionCode` ek saath |
| ✏️ | **Rename / package change** | App ka naam aur package badlo, folders automatic move hote hain |
| 📥 | **Import** | Storage ke purane Gradle project ko Termux me lao |
| 💾 | **Backup** | Project (aur keystore) ka `.tar.gz` backup `Download/ForgeBackups` me |
| ⌨️ | **Zsh TAB completion** | `forge <TAB>` se saare commands |
| 🔄 | **Self-update** | `forge update` |
| 🧪 | **Tested** | 60+ automated smoke tests + ShellCheck har push par |

---

## 📋 Requirements

- Android phone, **arm64** (OpenCode sirf arm64 ke liye hai)
- **Termux** — [F-Droid](https://f-droid.org/packages/com.termux/) ya [GitHub releases](https://github.com/termux/termux-app/releases) se. *Play Store wala Termux purana hai, use mat karo.*
- Internet + **kam se kam ~3 GB free space** (SDK, packages aur Gradle cache; cache build ke saath badhta hai)
- Setup me **kaafi data** download hota hai (kam se kam ~500 MB) — Wi-Fi use karo

---

## 🚀 Install

### Option 1 — `.deb` package (Recommended)

```bash
curl -LO https://github.com/inyogeshwar/termux-forge/releases/latest/download/termux-forge-latest.deb
pkg install ./termux-forge-latest.deb
forge setup
```

### Option 2 — One-liner script

```bash
curl -fsSL https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/install.sh | bash
```

Bina sawaal-jawaab ke (non-interactive):

```bash
curl -fsSL https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/install.sh | bash -s -- --yes --name Yogeshwar
```

Setup ke baad Termux restart karo (`exit` → dobara kholo, ya `exec zsh`) aur check karo:

```bash
forge doctor
```

<details>
<summary><b>Setup ke options</b></summary>

| Option | Kaam |
|---|---|
| `--yes`, `-y` | Koi sawaal nahi poochega |
| `--name NAME` | Terminal banner ka naam |
| `--skip-android` | Android SDK skip (sirf shell/AI chahiye to) |
| `--skip-ai` | OpenCode skip |
| `--skip-shell` | Zsh / Oh My Zsh skip |
| `--speedtest` | Pehle internet speed test |

Environment variable: `FORGE_GRADLE_MEM=3072m` (Gradle ko zyada RAM do).
</details>

---

## ⚡ Quick Start (2 minute)

```bash
forge create my-app --name "My App" --package com.yogesh.myapp   # 1. project
cd ~/my-app
forge ai                                                         # 2. AI se code likhwao
forge build                                                      # 3. debug APK
forge install                                                    # 4. phone par install
forge build release && forge export                              # 5. signed APK → Download/ForgeApps
```

> 💡 Project ke **andar** ho to project ka path likhna zaroori nahi. `forge build`, `forge bump` etc. current folder ka project use karte hain.

---

## 🛠️ Commands

### Setup & info

| Command | Kaam |
|---|---|
| `forge setup [options]` | Full setup (SDK, Zsh, OpenCode, keystore, template) |
| `forge doctor` | Sab kuch theek hai ya nahi — health check |
| `forge info` | Versions, paths, free space |
| `forge update` | Latest forge install karo |

### Projects

| Command | Kaam |
|---|---|
| `forge create <name> [options]` | Naya project (niche options dekho) |
| `forge import <path>` | Storage se project Termux me lao (build fast hota hai) |
| `forge list` | Saare projects (naam, version, package) |
| `forge rename [proj] "New Name"` | App ka display name |
| `forge package [proj] com.new.pkg` | Package name (source folders bhi move) |
| `forge icon [proj] logo.png` | App icon (sabhi sizes + manifest) |
| `forge bump [major\|minor\|patch]` | Version badhao (`1.0.0 (1)` → `1.0.1 (2)`) |
| `forge clean [proj]` | Build cache hatao |
| `forge repair [proj]` | `local.properties` + Gradle wrapper theek karo |
| `forge backup [proj]` | `Download/ForgeBackups/` me `.tar.gz` |

`forge create` options:

| Option | Matlab |
|---|---|
| `--template kotlin\|webview` | Template (default `kotlin`) |
| `--name "My App"` | Display name |
| `--package com.x.y` | Package name |
| `--url https://...` | WebView template ke liye website |
| `--git` | `git init` bhi kar do |

### Build & ship

| Command | Kaam |
|---|---|
| `forge build [proj]` | Debug APK |
| `forge build release [proj]` | Signed release APK |
| `forge build -i` | Build ke baad installer khol do |
| `forge bundle [proj]` | Play Store `.aab` |
| `forge install [debug\|release]` | Built APK install karo |
| `forge export [debug\|release\|aab\|all]` | `Download/ForgeApps/` me copy (`name-1.0.1-release.apk`) |
| `forge keystore [info\|backup\|new]` | Release keystore manage karo |

### Tools

| Command | Kaam |
|---|---|
| `forge ai [proj]` | OpenCode AI start |
| `forge sdk <args>` | `sdkmanager` passthrough (e.g. `forge sdk --list`) |
| `forge version` / `forge help` | Version / help |

---

## 🧩 Templates

```bash
# Normal Kotlin app
forge create notes --name "My Notes" --package com.yogesh.notes

# Kisi bhi website ko app bana do (WebView, back-button support ke saath)
forge create blog --template webview --url https://yourblog.com \
      --name "My Blog" --package com.yogesh.blog
```

Sabhi templates: **minSdk 24 · targetSdk/compileSdk 35 · AGP 8.7.3 · Kotlin 2.0.21 · Gradle 8.9 · Java 17**.

---

## 🔐 Release signing & keystore

- Setup ke time ek `release.keystore` **random password** ke saath banta hai: `~/.forge/release.keystore`
- Password `~/.forge/keystore.properties` (permission `600`) me hai aur Gradle ko `~/.gradle/gradle.properties` se milta hai.
- ⚠️ **Keystore kho gaya = Play Store par us app ka update kabhi nahi ho sakta.** Isliye:

```bash
forge keystore backup     # → Download/ForgeBackups/keystore-<date>/
forge keystore info       # SHA-1 / SHA-256 fingerprints (Firebase, Google Sign-In ke liye)
```

Backup folder ko Google Drive / pendrive me rakho.

> v6.x se upgrade kar rahe ho? Purana keystore (password `forgerelease`) chalta rahega — forge usse pehchan leta hai. Chaho to naya `forge keystore new` bana lo (naye apps ke liye).

---

## 🩺 Troubleshooting

| Problem | Solution |
|---|---|
| `forge: command not found` | `exec zsh` ya Termux restart. Phir bhi nahi to `curl ... install.sh \| bash` dobara |
| Build fail: SDK location not found | `forge repair` |
| Build fail: aapt2 error | `forge doctor` → `aapt2` ✗ ho to `pkg install aapt2`, phir `forge setup` |
| Out of memory | `export FORGE_GRADLE_MEM=3072m` phir `forge setup` (ya `~/.gradle/gradle.properties` me `org.gradle.jvmargs`) |
| Download slow / fail | Wi-Fi use karo, `termux-change-repo` se mirror badlo |
| `forge export` → storage error | `termux-setup-storage` chalao aur permission do |
| OpenCode nahi chal raha | `forge setup --skip-android --skip-shell` dobara; device **arm64** hona chahiye |
| Kuch samajh na aaye | `forge doctor` ka output dekho, ya [Issue](https://github.com/inyogeshwar/termux-forge/issues) kholo |

Logs: `~/.forge/pkg_install.log`, `~/.forge/sdk_download.log`

---

## 🗑️ Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/uninstall.sh | bash
```

- Tumhare **projects safe** rehte hain (`~/my-app` etc.)
- **Release keystore safe** rehta hai (`~/.forge/release.keystore`)
- Options: `--yes` (poochhe bina), `--keep-sdk` (SDK + Gradle cache na hatao), `--purge` (keystore bhi delete — dangerous)

---

## 🔧 How it works

```text
install.sh / .deb ──► forge.sh (single script)
                        ├─ setup: pkg → zsh/p10k → OpenCode (grun) → Android SDK
                        │          → Termux ARM aapt2/apksigner patch
                        │          → Gradle wrapper + keystore + ~/hello-forge template
                        └─ CLI : create / build / bundle / icon / bump / keystore / ...
```

Android SDK ke x86 build-tools Termux (ARM) par nahi chalte, isliye forge unke `aapt/aapt2/zipalign/apksigner` ko Termux ke native binaries se replace (symlink) karta hai aur Gradle ko `android.aapt2FromMavenOverride` deta hai.

---

## 🧪 Development & tests

```bash
git clone https://github.com/inyogeshwar/termux-forge && cd termux-forge
bash tests/smoke.sh                                   # 60+ tests, Termux ki zaroorat nahi (stubs)
shellcheck -S warning forge.sh install.sh uninstall.sh
```

- CI (`.github/workflows/ci.yml`) har push/PR par syntax + ShellCheck + smoke tests chalata hai.
- Release: `git tag v7.0.1 && git push --tags` → GitHub Actions `.deb` banakar Release me daal deta hai.

Contributions welcome — PR se pehle `bash tests/smoke.sh` pass hona chahiye.

---

## 🙌 Credits

Made with ❤️ by **[Yogeshwar Kumar](https://github.com/inyogeshwar)** · [Website](https://inyogeshwar.co.in)
Powered by [Termux](https://termux.dev), [OpenCode](https://opencode.ai), Android SDK & Gradle.

**⭐ Pasand aaya to repo ko star zaroor dena! ⭐**

[MIT License](LICENSE)
