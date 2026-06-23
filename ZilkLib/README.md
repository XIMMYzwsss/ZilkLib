# ZilkLib

Roblox UI library. Built on [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib).

Repo: [XIMMYzwsss/ZilkLib](https://github.com/XIMMYzwsss/ZilkLib)

## Load

ZilkLib only loads from GitHub. `Library.lua` and addons cannot be run from local files (`readfile`, etc).

```lua
local repo = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/'
local Loader = loadstring(game:HttpGet(repo .. 'Loader.lua'))()
local Library, ThemeManager, SaveManager, BuiltInTabs = Loader.Load(repo)
```

## Save paths

Config and theme folders are **whatever you set in your script** — they do not have to be named `Zilk`. Pick any folder path your executor supports (e.g. per-script or per-game names).

```lua
local CONFIG_PATH = 'MyScript/configs'   -- any path you want
local THEME_PATH = 'MyScript/themes'     -- any path you want

Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
    ConfigFolder = CONFIG_PATH,
    ThemeFolder = THEME_PATH,
})
```

Example layout (names are up to you):

```
MyScript/
  configs/
  themes/
```

Set in your script before `CreateWindow`. Not changeable in the UI.

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

Built-in: Zilk, Default, BBot, Tokyo Night, Mint. Custom themes save to whatever you pass as `ThemeFolder`.

Default menu key: **RightShift**

See `Example.lua` for the full demo.
