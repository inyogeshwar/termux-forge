# Changelog

## 7.0.1 — Unreleased

- Phone-width setup banners, completion instructions, help and project list.
- Compact two-line Zsh prompt with saved display name and shortened path.
- No localhost context, right-side clock or Nerd Font requirement.
- Manual release workflow uploads a testable `.deb` artifact before tagging.
- Pin new OpenCode installations to phone-tested 1.19.5 instead of npm latest; existing installations are preserved.
- OpenCode install/download now fetches the arm64 tarball directly instead of `npm pack` (npm rejects linux-only packages on Termux).
- `forge doctor` verifies glibc binary, wrapper and `grun`; wrapper clears `LD_PRELOAD` so Termux’s bionic linker doesn’t crash the glibc OpenCode binary.
- Re-run replaces a stale/half-installed OpenCode instead of skipping it.
- Prompt now keeps spaces in the saved name (`Yogeshwar Team` no longer becomes `YogeshwarTeam`) and
  shows only the current folder instead of a truncated deep path.
- Long output lines now leave two columns free, so Termux stops wrapping them oddly on narrow screens;
  the setup-complete summary uses numbered blocks without wide rules.

## 7.0.0 — 2026-11-15

### 🚨 Critical fixes
- **`forge.sh` syntax error fix** — `pkg_install` me `\vert{}` (galti se `||` / `|` ki jagah) tha, jis se script chalti hi nahi thi. v6.5.0 ka `.deb` bhi isse broken tha.
- `step_finalize` ab same-file `cp` par crash nahi karta (install.sh flow me `forge` command ban hi nahi paati thi).
- Icon command ab manifest me `android:icon` bhi lagata hai (pehle icons ban jaate the par app me use nahi hote the).
- Label me `&`, `<`, `"` ab XML-escape hote hain (pehle manifest invalid ho jaata tha).
- Package change nested sub-packages (`com.x.y.ui`) ko flatten nahi karta.
- `.deb` ke `postinst` me version ab sahi dikhta hai.
- CI ab sach me fail hota hai (pehle ShellCheck `|| true` se ignore hota tha).

### 🔐 Security
- Keystore ka password ab **random** (pehle sabke liye `forgerelease` public tha). Purane keystore backward-compatible.
- Uninstall ab release keystore ko **delete nahi karta** (sirf `--purge` se).
- `keystore.properties` permission `600`.

### ✨ New
- Naye commands: `list`, `rename`, `bump`, `clean`, `backup`, `install`, `keystore [info|backup|new]`, `update`, `info`.
- `forge create` flags: `--template`, `--name`, `--package`, `--url`, `--git` (non-interactive).
- **WebView template** (website → app).
- `forge build -i` (build + install), project auto-detect (current folder), `forge build` ke baad APK size/path.
- Export file names me version: `my-app-1.0.1-release.apk`.
- Zsh TAB completion; zshrc block ab har setup par refresh hota hai.
- Setup flags: `--yes --name --skip-android --skip-ai --skip-shell --speedtest`.
- Stable `.deb` link: `releases/latest/download/termux-forge-latest.deb`.
- 60+ automated smoke tests + ShellCheck CI; release workflow `.deb` banane se pehle tests chalata hai.

### 🧹 Changed
- Speed test ab opt-in (`--speedtest`); python ab base packages me nahi (kam download).
- Banner layout fix, doctor me double ✓ hata, README table fix.
- Default `versionName` template me `1.0.0`.

## 6.5.0
- `.deb` package support, GitHub Releases automation.
