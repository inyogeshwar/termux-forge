# ⚒️ TERMUX-FORGE

<div align="center">

### `Termux` → `OpenCode` → `Android APK` — **one command** me sab kuch ⚡

[![GitHub](https://img.shields.io/badge/GitHub-inyogeshwar-181717?style=for-the-badge&logo=github)](https://github.com/inyogeshwar)
[![Termux](https://img.shields.io/badge/Termux-Android-000000?style=for-the-badge&logo=android)](https://termux.dev)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-Passing-brightgreen?style=for-the-badge)](https://www.shellcheck.net)

```text
╔══════════════════════════════════════════════════════════╗
║   ███████╗ ██████╗ ██████╗  ██████╗ ███████╗             ║
║   ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝             ║
║   █████╗  ██║   ██║██████╔╝██║  ███╗█████╗               ║
║   ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝               ║
║   ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗             ║
║   ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝             ║
╠══════════════════════════════════════════════════════════╣
║  🎯 v4.0  │  🤖 OpenCode  │  ⚙️  Android SDK  │  ⚒️  ║
║  👤 github.com/inyogeshwar                              ║
╚══════════════════════════════════════════════════════════╝
```

</div>

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| 🚀 **One-liner** | `curl \| bash` — bas ek command |
| 🔁 **Idempotent** | Dobara chalao, sirf missing steps chalenge |
| 🔧 **Wrapper Fix** | `--no-validate-url` + system gradle fallback |
| 📍 **Auto `local.properties`** | `SDK location not found` bug gone |
| 🤖 **Non-interactive** | `FORGE_YES=1` for automation |
| ⚒️ **`forge` CLI** | `forge build`, `forge doctor`, `forge ai` |
| 📱 **Sample APK** | `hello-forge` pehli baar me hi build hota hai |

---

## 📊 Data & Storage Requirements

> ⚠️ **Warning:** Android development tools bade hote hain. Setup shuru karne se pehle apne phone mein **kam se kam 5 GB ki free storage** zaroor check kar lein, warna installation beech mein fail ho sakta hai.

| Resource | Approx. Size | Description |
| :--- | :--- | :--- |
| 📥 **Internet Data** | **~1.2 GB - 1.6 GB** | Pehli baar setup karte waqt download hoga (Packages, SDK, OpenCode, APK build cache). |
| 💾 **Phone Storage** | **~2.5 GB - 4 GB** | Extract hone ke baad aur Gradle cache banne ke baad phone mein itni jagah occupy hogi. |
| ⏱️ **Time** | **10 - 15 Minutes** | Achhe internet par pehli baar setup poora hone mein itna time lagta hai. |

**Note:** Agar aap dobara script chalate hain (`bash forge.sh`), toh script pehle se installed cheezein skip kar degi. Us waqt data aur time dono bahut kam lagega (sirf missing cheezein update hongi).

---

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/inyogeshwar/termux-forge/main/install.sh | bash
```

Ya manual:

```bash
pkg install -y git
git clone https://github.com/inyogeshwar/termux-forge.git
cd termux-forge
bash install.sh
```

Install ke baad → `exec zsh` → `forge doctor`

---

## ⚒️ Forge CLI

```bash
➜ forge build              # default ~/hello-forge
➜ forge build ~/my-app     # custom project
➜ forge doctor             # 🩺 health check
➜ forge ai                 # 🤖 OpenCode
➜ forge sdk list           # ⚙️  sdkmanager wrapper
➜ forge version            # version info
```

---

## 🔧 Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `FORGE_NAME` | prompt | Banner naam |
| `FORGE_YES` | `0` | `1` = skip prompts |
| `SKIP_ANDROID` | `0` | `1` = Android skip |
| `SKIP_TEST_APK` | `0` | `1` = test APK skip |
| `ANDROID_SDK` | `~/android-sdk` | SDK path |

```bash
FORGE_NAME=Yogesh FORGE_YES=1 bash install.sh
```

---

## 🐛 Fixed Bugs

| Bug | Fix |
| :--- | :--- |
| `Test of distribution url ... failed` | System gradle fallback + `--no-validate-url` |
| `./gradlew: No such file or directory` | `[[ -x gradlew ]] && gradlew \|\| gradle` |
| `SDK location not found` | Auto-create `local.properties` |
| `$GRADLE_VER` empty | Script ke andar `readonly GRADLE_VER` |
| `aapt2` hardcoded | `command -v aapt2` dynamic |
| `sdkmanager` interactive pause | `yes \|` + `--sdk_root` |
| Double install on rerun | `dpkg -s` check |
| `glibc-runner` not found | Alag se `glibc-repo` add aur `pkg update` |

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
✓ Test APK
🎯 Sab theek hai! 🚀
```

---

## 📱 Install APK

```bash
termux-open ~/hello-forge/app/build/outputs/apk/debug/app-debug.apk
```

Ya `~/storage/downloads/` me copy karke file manager se install karo.

---

## 🗂️ Project Structure

```text
termux-forge/
├── 🚀 install.sh
├── ⚒️  forge.sh
├── 📖 README.md
├── 📜 LICENSE
├── 🚫 .gitignore
└── ⚙️  .github/workflows/shellcheck.yml
```

---

## 🤝 Contributing

1. Fork karo 🍴
2. Branch banao: `git checkout -b feature/amazing`
3. Commit karo: `git commit -m "✨ feat: amazing feature"`
4. Push karo: `git push origin feature/amazing`
5. PR kholo 🎯

---

## 📄 License

MIT © [Yogeshwar Kumar](https://github.com/inyogeshwar) — [`LICENSE`](LICENSE) dekho.

---

<div align="center">

### ⚒️ Made with ❤️ by **Yogeshwar Kumar**

[`GitHub`](https://github.com/inyogeshwar) · [`Website`](https://inyogeshwar.co.in)

`⚡ 16-year-old Developer · AI Tools Creator · Mozilla Approved ⚡`

**⭐ Agar pasand aaya to star dena mat bhoolna! ⭐**

</div>