# HeavNLib

LinoriaLib fork with HeavN styling. Purple accent, sidebar/topbar tabs, pill toggles.

Repo: [ZilkLib/HeavNLib](https://github.com/XIMMYzwsss/ZilkLib/tree/main/HeavNLib)

## Load

```lua
local repo = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/HeavNLib/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local BuiltInTabs = loadstring(game:HttpGet(repo .. 'addons/BuiltInTabs.lua'))()
```

## Paths (set in your script, like heavN.txt)

```lua
local HEAVN_CONFIGS_PATH = 'HeavN/configs'
local HEAVN_THEMES_PATH = 'HeavN/themes'

Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
    ConfigFolder = HEAVN_CONFIGS_PATH,
    ThemeFolder = HEAVN_THEMES_PATH,
})
```

- Configs → `HeavN/configs/*.json`
- Themes → `HeavN/themes/*.json`
- Both paths are code-only. No UI to change them.

## Window

```lua
local Window = Library:CreateWindow({
    Title = 'My Script',
    Center = true,
    AutoShow = true,
    BuiltInTabs = true,
})

local Main = Window:AddTab('Main')
Main:AddLeftGroupbox('Features'):AddToggle('MyToggle', { Text = 'Hello' })
```

`BuiltInTabs = true` adds a **Settings** tab with:
- UI settings (menu key, watermark, keybind list)
- Config save/load (inside Settings, not a separate tab)
- Themes (colors, font, background, layout)
- Theme configs (save/load custom themes)

## Keybind list + toggle gating

If a keybind should only look "active" when a master toggle is on, pass `GateToggle`:

```lua
local enabled = box:AddToggle('AimbotEnabled', { Text = 'Enabled', Default = false })
box:AddLabel('Key'):AddKeyPicker('AimbotKey', {
    Default = 'E',
    Mode = 'Hold',
    Text = 'Aimbot',
    GateToggle = enabled,
})
```

The keybind list stays gray until the toggle is on, even if you hold the key.

## Themes

Built-in: HeavN, Default, BBot, Tokyo Night, Mint.

Custom themes save colors + font + background + tab position + corner radius + keybind transparency + window size.

Configs ignore theme keys by default (`IgnoreThemeInConfigs = true`).

## Menu key

Default: **RightShift** (change in Settings).

See `Example.lua` for the full demo.
