# cz_targetX

<p align="center">
  <img src="https://img.shields.io/badge/FiveM-Ready-orange?style=for-the-badge">
  <img src="https://img.shields.io/badge/Framework-Standalone-success?style=for-the-badge">
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=for-the-badge">
</p>

<p align="center">
  A clean and modern <b>3D world-positioned targeting system</b> for FiveM.<br>
  Lightweight. Expandable. Developer-friendly.
</p>

---

## 🎬 Preview

https://github.com/czmenz/cz_targetX/raw/main/preview.mp4

---

## ✨ Features

- 🎯 Floating 3D world UI
- 📚 Multiple stacked targets
- 🔄 Dynamic expand animation
- 🧩 Export support for other resources
- 🔔 Optional GitHub update checker
- 🧠 Optimized performance logic
- 🎨 Optional icon support per target

---

## 🧱 Framework

- ✅ Standalone

---

## 📦 Installation

1. Place resource in:
```
resources/cz_targetX
```

2. Add to server.cfg:
```
ensure cz_targetX
```

3. Run:
```
refresh
start cz_targetX
```

---

## ⚙️ Configuration

File: `config.lua`

```lua
Config.BuildId = "1.0.0" -- Never change this setting
Config.CheckForUpdates = true

Config.DefaultButtonId = 38
Config.DefaultDrawDistance = 15.0
Config.DefaultInteractDistance = 2.0
```

---

### Config Notes

- `DefaultButtonId`: fallback key if target does not define `buttonId` (`38 = E`)
- `DefaultDrawDistance`: prompt visibility range
- `DefaultInteractDistance`: key interaction range
- `CheckForUpdates`: `true` / `false`
- `BuildId`: used for release comparison (do not modify)

---


## 🧩 Exports

### AddTarget(id, data)

```lua
exports.cz_targetX:AddTarget("example_target", {
    coords = vec3(0.0, 0.0, 0.0),
    label = "Example",
    icon = "fa-solid fa-hand"
})
```

---

### UpdateTarget(id, data)

```lua
exports.cz_targetX:UpdateTarget("example_target", {
    label = "New label",
    icon = "fa-solid fa-wrench"
})
```

---

### RemoveTarget(id)

```lua
exports.cz_targetX:RemoveTarget("example_target")
```

---

## 📄 Target Data

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| coords | vector3 | ✅ | World position |
| label | string | ❌ | Display text |
| icon | string | ❌ | FontAwesome icon class |
| drawDistance | number | ❌ | Visibility range |
| interactDistance | number | ❌ | Interaction range |
| buttonId | number | ❌ | Key control |
| event | string | ❌ | Trigger event |
| eventType | string | ❌ | `"client"` or `"server"` |
| args | any | ❌ | Custom arguments |

---

## 🎨 UI Design Philosophy

- Clean minimal 3D layout
- Soft expand animation on active target
- Slight glow on selected row
- Button left, text right
- No over-designed effects
- Performance-first logic

---

## 📜 License & Usage Rules

This project is open source for learning, modifying, and use on servers.

### ✔ You are allowed to:
- Use it in private/public servers
- Modify it for your own needs
- Share improvements with credit

### ❌ You are not allowed to:
- Sell this resource (original or modified)
- Reupload and claim authorship
- Remove original author credit

---

**Author:** Czmenz