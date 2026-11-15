# ⚒️ TERMUX-FORGE

<div align="center">

### `Termux` → `OpenCode` → `Android APK` — **AI-powered Development** ⚡

[![GitHub](https://img.shields.io/badge/GitHub-inyogeshwar-181717?style=for-the-badge&logo=github)](https://github.com/inyogeshwar)
[![Termux](https://img.shields.io/badge/Termux-Android-000000?style=for-the-badge&logo=android)](https://termux.dev)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)

```text
┌────────────────────────────────────┐
│  ⚒️  T E R M U X - F O R G E       │
├────────────────────────────────────┤
│  🎯 v6.0  │  🤖 OpenCode  │  ⚙️ SDK │
│  👤 github.com/inyogeshwar         │
└────────────────────────────────────┘
```

</div>

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| 🚀 **One-liner** | `curl \| bash` — bas ek command |
| 🤖 **OpenCode AI** | Phone par natively AI coding. |
| 📱 **APK Builder** | Bina laptop ke, Android SDK 35. |
| 🎨 **Custom Icon** | Kisi bhi image ko app icon banao. |
| ⚒️ **CLI Tools** | `forge create`, `build`, `export`, `repair`. |

---

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/install.sh | bash
```

Install ke baad → `exec zsh` → `forge doctor`

---

## 🛠️ Ultimate CLI Commands

### 🏗️ 1. Naya Project Banao
```bash
forge create my-app
```
*Yeh tumse App ka Name aur Package Name poochega, aur ek ready-to-code project bana dega.*

### 🎨 2. App Icon Set Karo
```bash
forge icon ~/my-app ~/storage/downloads/my-logo.png
```
*Yeh tumhari kisi bhi image (PNG/JPG) ko resize karke sabhi screens (mdpi se xxxhdpi) ke liye app icon bana dega.*

### 🚀 3. APK Build Karo
```bash
cd ~/my-app
opencode   # (AI se code likhwao)
forge build
```

### 📲 4. APK Phone Storage Mein Bhejo
```bash
forge export ~/my-app
```
*APK seedha `Download/ForgeApps/` folder mein chala jayega aur install ka popup khul jayega.*

### 🔧 5. Project Repair Karo (Agar build fail ho)
```bash
forge repair ~/my-app
```
*Yeh `local.properties`, `gradlew` aur SDK paths ko automatically fix kar deta hai.*

### 🗑️ 6. Complete Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/uninstall.sh | bash
```
*Yeh poora setup, SDK, aur AI ko clean kar dega.*

---

## 🔧 Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `FORGE_NAME` | prompt | Banner naam |
| `FORGE_YES` | `0` | `1` = skip prompts |
| `ANDROID_SDK` | `~/android-sdk` | SDK path |

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
✓ imagemagick
✓ OpenCode
✓ Android SDK
✓ platforms/android-35
✓ build-tools/35.0.0
✓ Base Template APK
🎯 Sab theek hai! 🚀
```

---

<div align="center">

### ⚒️ Made with ❤️ by **Yogeshwar Kumar**

[`GitHub`](https://github.com/inyogeshwar) · [`Website`](https://inyogeshwar.co.in)

**⭐ Agar pasand aaya to star dena mat bhoolna! ⭐**

</div>