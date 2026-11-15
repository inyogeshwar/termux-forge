# ⚒️ TERMUX-FORGE

<div align="center">

### `Termux` → `OpenCode` → `Android APK / AAB` — **AI-powered Development** ⚡

[![GitHub](https://img.shields.io/badge/GitHub-inyogeshwar-181717?style=for-the-badge&logo=github)](https://github.com/inyogeshwar)
[![Termux](https://img.shields.io/badge/Termux-Android-000000?style=for-the-badge&logo=android)](https://termux.dev)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)

```text
┌────────────────────────────────────┐
│  ⚒️  T E R M U X - F O R G E       │
├────────────────────────────────────┤
│  🎯 v6.2  │  🤖 OpenCode  │  ⚙️ SDK │
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
| 📱 **APK & AAB** | Debug, Release APK aur Play Store AAB. |
| 🎨 **Custom Icon** | Kisi bhi image ko app icon banao. |
| 📦 **Import Old** | Storage se purane project import karo. |
| 🔐 **Auto Keystore** | Release APK apne aap sign hoti hai. |

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

### 📥 2. Purana Project Import Karo
Agar tumhara project `/storage/emulated/0/Download/` mein hai:
```bash
forge import ~/storage/downloads/MyOldApp
```
*Yeh project ko Termux ke fast internal memory mein le aayega taaki build fast ho.*

### 🎨 3. App Icon Set Karo
```bash
forge icon ~/my-app ~/storage/downloads/my-logo.png
```
*Yeh tumhari kisi bhi image (PNG/JPG) ko resize karke sabhi screens ke liye app icon bana dega.*

### 🔄 4. Package Name Badlo
```bash
forge package ~/my-app com.yourname.yourapp
```

### 🚀 5. Build APK / AAB
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

### 📲 6. Normal Storage Mein Export Karo
```bash
forge export ~/my-app
```
*Yeh saari build files (Debug APK, Release APK, AAB) ko utha kar `Download/ForgeApps/` folder mein daal dega.*

### 🔧 7. Project Repair Karo
```bash
forge repair ~/my-app
```

### 🗑️ 8. Complete Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/uninstall.sh | bash
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
✓ imagemagick
✓ OpenCode
✓ Android SDK
✓ platforms/android-35
✓ build-tools/35.0.0
✓ Keystore
✓ Base Template APK
🎯 Sab theek hai! 🚀
```

---

<div align="center">

### ⚒️ Made with ❤️ by **Yogeshwar Kumar**

[`GitHub`](https://github.com/inyogeshwar) · [`Website`](https://inyogeshwar.co.in)

**⭐ Agar pasand aaya to star dena mat bhoolna! ⭐**

</div>