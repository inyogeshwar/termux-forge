# ⚒️ TERMUX-FORGE

<div align="center">

### `Termux` → `OpenCode` → `Android APK / AAB` — **AI-powered Development** ⚡

[![GitHub Release](https://img.shields.io/github/v/release/inyogeshwar/termux-forge?style=for-the-badge&color=22c55e)](https://github.com/inyogeshwar/termux-forge/releases)
[![GitHub](https://img.shields.io/badge/GitHub-inyogeshwar-181717?style=for-the-badge&logo=github)](https://github.com/inyogeshwar)
[![Termux](https://img.shields.io/badge/Termux-Android-000000?style=for-the-badge&logo=android)](https://termux.dev)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)

```text
┌────────────────────────────────────┐
│  ⚒️  T E R M U X - F O R G E       │
├────────────────────────────────────┤
│  🎯 v6.5.0 │  🤖 OpenCode │ ⚙️ SDK │
│  👤 [github.com/inyogeshwar](https://github.com/inyogeshwar)         │
└────────────────────────────────────┘

```

---

## ✨ Features

| Feature | Description |
| --- | --- |
| 📦 **Official `.deb` Package** | GitHub Releases se direct `.deb` install karo.

 |
| 🚀 **One-liner Setup** | `curl | bash` — bas ek command.

 |
| 🤖 **OpenCode AI** | Phone par natively AI coding.

 |
| 📱 **APK & AAB** | Debug, Release APK aur Play Store AAB.

 |
| 🎨 **Custom Icon** | Kisi bhi image ko app icon banao.

 |
| 📦 **Import Old** | Storage se purane project import karo.

 |
| 🔐 **Auto Keystore** | Release APK apne aap sign hoti hai.

 |

---

## 🚀 Quick Install

### Option 1: Install via `.deb` Package (Recommended)

```bash
curl -LO [https://github.com/inyogeshwar/termux-forge/releases/latest/download/termux-forge_6.5.0_all.deb](https://github.com/inyogeshwar/termux-forge/releases/latest/download/termux-forge_6.5.0_all.deb)
pkg install ./termux-forge_6.5.0_all.deb
forge setup

```

### Option 2: Direct One-Liner Script

```bash
curl -fsSL [https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/install.sh](https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/install.sh) | bash

```

Install ke baad → `exec zsh` → `forge doctor`

---

## 🛠️ Ultimate CLI Commands

### ⚙️ 1. Environment Setup (For `.deb` users)

```bash
forge setup

```

Yeh Android SDK, Gradle Wrapper, Zsh + Powerlevel10k aur OpenCode AI setup karega.

### 🏗️ 2. Naya Project Banao

```bash
forge create my-app

```

Yeh tumse App ka Name aur Package Name poochega, aur ek ready-to-code project bana dega.

### 📥 3. Purana Project Import Karo

Agar tumhara project `/storage/emulated/0/Download/` mein hai:

```bash
forge import ~/storage/downloads/MyOldApp

```

Yeh project ko Termux ke fast internal memory mein le aayega taaki build fast ho.

### 🎨 4. App Icon Set Karo

```bash
forge icon ~/my-app ~/storage/downloads/my-logo.png

```

Yeh tumhari kisi bhi image (PNG/JPG) ko resize karke sabhi screens ke liye app icon bana dega.

### 🔄 5. Package Name Badlo

```bash
forge package ~/my-app com.yourname.yourapp

```

### 🚀 6. Build APK / AAB

**Debug APK:**

```bash
forge build ~/my-app

```

**Release APK (Signed):**

```bash
forge build release ~/my-app

```

**Play Store AAB Bundle:**

```bash
forge bundle ~/my-app

```

### 📲 7. Normal Storage Mein Export Karo

```bash
forge export ~/my-app

```

Yeh saari build files (Debug APK, Release APK, AAB) ko utha kar `Download/ForgeApps/` folder mein daal dega.

### 🔧 8. Project Repair Karo

```bash
forge repair ~/my-app

```

### 🗑️ 9. Complete Uninstall

```bash
curl -fsSL [https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/uninstall.sh](https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/uninstall.sh) | bash

```

---

## 🩺 Doctor Output

```bash
➜ forge doctor

✓ Termux
✓ Storage
✓ zsh
✓ git
✓ curl
✓ java
✓ gradle
✓ aapt2
✓ OpenCode
✓ Android SDK
✓ platforms/android-35
✓ build-tools/35.0.0
✓ Keystore
✓ Base Template
🎯 Sab theek hai! 🚀

```

---

### ⚒️ Made with ❤️ by **Yogeshwar Kumar**

[`GitHub`](https://github.com/inyogeshwar) · [`Website`](https://inyogeshwar.co.in)

**⭐ Agar pasand aaya to star dena mat bhoolna! ⭐**v
