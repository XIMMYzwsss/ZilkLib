# HeavNLib

Roblox UI library based on [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib), restyled to match **HeavN** (sidebar tabs, purple accent, pill toggles, group headers).

Published repo: [ZilkLib/HeavNLib](https://github.com/XIMMYzwsss/ZilkLib/tree/main/HeavNLib)

```
ZilkLib/
  HeavNLib/
    Library.lua
    Example.lua
    README.md
    addons/
      ThemeManager.lua
      SaveManager.lua
      BuiltInTabs.lua
```

### Remote load (HttpGet)

```lua
local repo = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/HeavNLib/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local BuiltInTabs = loadstring(game:HttpGet(repo .. 'addons/BuiltInTabs.lua'))()
```

## Quick start

```lua
local ROOT = 'HeavNLib/'
local Library = loadstring(readfile(ROOT .. 'Library.lua'))()
local ThemeManager = loadstring(readfile(ROOT .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(readfile(ROOT .. 'addons/SaveManager.lua'))()
local BuiltInTabs = loadstring(readfile(ROOT .. 'addons/BuiltInTabs.lua'))()

Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
    Folder = 'HeavNLib',
    ConfigFolder = 'HeavN/configs',  -- your path — same idea as heavN.txt
})

local Window = Library:CreateWindow({
    Title = 'My Script',
    Center = true,
    AutoShow = true,
    BuiltInTabs = true,  -- auto Settings + Configs tabs
})

local Main = Window:AddTab('Main')
Main:AddLeftGroupbox('Features'):AddToggle('MyToggle', { Text = 'Hello' })
```

See [Example.lua](Example.lua) for toggles, sliders, dropdowns, colors, keybinds, dependencies, watermark, themes, and configs.

## Built-in tabs

When `BuiltInTabs = true` (default), **Settings** and **Configs** are added automatically:

| Tab | Contents |
|-----|----------|
| **Settings** | Menu key, unload, full theme manager, font, corner radius, keybind list, notifications test |
| **Configs** | Save / load / overwrite / delete (with confirm modals), autoload, **custom config folder path** |

Disable with `BuiltInTabs = false` in `CreateWindow` if you want full manual control.

## Config path

Set on init:

```lua
Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
    ConfigFolder = 'MyScript/configs',
})
```

Or change at runtime in **Configs → Storage → Set config path**.

## Theme manager

- Default theme: **HeavN** (`#9370db` accent)
- Built-in: HeavN, Default, BBot, Tokyo Night, Mint
- Custom themes saved to `{Folder}/themes/*.json`
- All HeavN color fields: section, slider, dropdown, toggles, keybind text colors

Configs ignore theme keys by default (`IgnoreThemeInConfigs = true`).

## Linoria features included

- Tabs, left/right groupboxes, tabboxes
- Toggles (pill), sliders, dropdowns (incl. Player/Team), inputs
- Color pickers, key pickers, dependency boxes
- Watermark, notifications, tooltips
- `Toggles` / `Options` on `getgenv()`
- Unload, menu fade, custom menu keybind

## Files

```
HeavNLib/
  Library.lua
  Example.lua
  addons/
    ThemeManager.lua
    SaveManager.lua
    BuiltInTabs.lua
```

## Default menu key

**RightShift** (change in Settings → Menu bind).
