# Changelog

## 7.0.1 — Unreleased

| Kya badla | Kyun | Example |
|---|---|---|
| Mobile-friendly banner aur setup summary | Purane wide boxes phone screen se bahar nikal jaate the | `forge setup` ke baad chhota banner dikhta hai |
| Two-line prompt: naam + current folder | `u0_a193@localhost` aur deep path hata diye | `Yogesh ~`<br>`>` |
| Saved naam mein spaces rahein | `Yogeshwar Team` → `YogeshwarTeam` hua tha | `Yogeshwar Team termux-forge` |
| Long output lines wrap na hon | Do columns spare chhode gaye | `forge help` ki har cheez alag line par |
| OpenCode naye install ke liye `1.19.5` pinned | `npm` latest (v2) Termux par crash ho sakta hai | `forge setup` se OpenCode 1.19.5 install hoga |
| OpenCode binary ka direct download | `npm pack` linux-only package ko reject kar deta hai | `forge setup` successfully OpenCode install karta hai |
| `forge doctor` OpenCode verify karega | Sirf `command -v opencode` kaafi nahi tha | Glibc binary, wrapper aur `grun` check hota hai |
| OpenCode wrapper `LD_PRELOAD` clear karta hai | Termux ka bionic linker glibc binary ko crash kar deta hai | `forge ai` chale bina crash kiye |

---

## 7.0.0 — 2026-11-15

| Kya badla | Kyun | Example |
|---|---|---|
| `forge.sh` syntax error fixed | Script chalti hi nahi thi | `forge setup` ab chalta hai |
| App icon manifest me add hua | Icons ban kar bhi use nahi ho rahe the | `forge icon app.png` ab icon lagata hai |
| Label me `&`, `<`, `"` escape hote hain | Manifest invalid ho jaata tha | `My Notes & <Pro>` safely save hota hai |
| Package change nested sub-package flatten nahi karta | Galti se folders merge ho jaate the | `com.x.y.ui` sahi rehta hai |
| `.deb` postinst version sahi dikhta hai | Purana version dikhta tha | `termux-forge_7.0.0_all.deb` |
| CI ab sach mein fail hota hai | ShellCheck warnings ignore ho rahi thi | Build red ho jata hai agar error ho |
| Keystore password random | Sabke liye `forgerelease` public tha | Har naya install ka alag password |
| Uninstall keystore delete nahi karta | Purane apps update nahi ho paate | Sirf `--purge` se delete hoga |
| `keystore.properties` permission `600` | Security | Sirf owner read kar sakta hai |

### Naye commands (7.0.0)

| Command | Kaam | Example |
|---|---|---|
| `forge list` | Saare projects | `forge list` |
| `forge rename` | App display name badlo | `forge rename my-app "My App"` |
| `forge bump` | Version badhao | `forge bump patch` |
| `forge clean` | Build cache hatao | `forge clean` |
| `forge backup` | Project backup | `forge backup my-app` |
| `forge install` | Built APK install karo | `forge install release` |
| `forge keystore` | Signing key manage | `forge keystore info` |
| `forge update` | Forge update karo | `forge update` |
| `forge info` | Versions, paths, space | `forge info` |

### `forge create` options

| Option | Matlab | Example |
|---|---|---|
| `--template kotlin\|webview` | Template choose karo | `--template webview` |
| `--name "App"` | Display name | `--name "My Notes"` |
| `--package com.x.y` | Package name | `--package com.yogesh.notes` |
| `--url https://...` | WebView ke liye website | `--url https://example.com` |
| `--git` | `git init` karo | `--git` |

---

## 6.5.0

| Kya hua | Example |
|---|---|
| `.deb` package support | `termux-forge-latest.deb` install kar sakte ho |
| GitHub Releases automation | Tag push par release publish hota hai |

---

### Kaise update karein

```bash
# 1. Naya code pull karein
git pull

# 2. Release banayein
git tag -a v7.0.1 -m "Mobile UI fix + OpenCode 1.19.5"
git push origin v7.0.1

# 3. GitHub Actions khud `.deb` banakar Release mein daal dega
# Download karein:
# https://github.com/inyogeshwar/termux-forge/releases/latest/download/termux-forge-latest.deb
```
