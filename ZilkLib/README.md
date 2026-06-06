# ZilkLib

Roblox UI library. Built on [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib).

Repo: [XIMMYzwsss/ZilkLib](https://github.com/XIMMYzwsss/ZilkLib)

## Load

```lua
local repo = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local BuiltInTabs = loadstring(game:HttpGet(repo .. 'addons/BuiltInTabs.lua'))()
```

## Save paths

```lua
local ZILK_CONFIGS_PATH = 'Zilk/configs'
local ZILK_THEMES_PATH = 'Zilk/themes'

Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
    ConfigFolder = ZILK_CONFIGS_PATH,
    ThemeFolder = ZILK_THEMES_PATH,
})
```

```
Zilk/
  configs/
  themes/
```

Set in your script. Not changeable in the UI.

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

`BuiltInTabs = true` adds Settings (UI options, configs, themes).

## Keybind gating

```lua
local enabled = box:AddToggle('FeatureEnabled', { Text = 'Enabled', Default = false })
box:AddLabel('Key'):AddKeyPicker('FeatureKey', {
    Default = 'E',
    Mode = 'Hold',
    Text = 'Feature',
    GateToggle = enabled,
})
```

Keybind list stays inactive until the toggle is on.

## Themes

Built-in: Zilk, Default, BBot, Tokyo Night, Mint. Custom themes save to `Zilk/themes/`.

Default menu key: **RightShift**

See `Example.lua` for the full demo.
