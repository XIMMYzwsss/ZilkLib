# ZilkLib

Roblox UI library. Built on [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib).

Repo: [XIMMYzwsss/ZilkLib](https://github.com/XIMMYzwsss/ZilkLib)

## Load

Copy the `ZilkLib/` folder into your executor workspace next to your script, then load each file with `loadZilkModule`. Local `readfile` is used when the files exist; otherwise it falls back to GitHub.

```lua
local ZILK_CONFIGS_PATH = 'MyScript/configs'   -- any path you want
local ZILK_THEMES_PATH = 'MyScript/themes'     -- any path you want

local function loadZilkModule(path)
	if typeof(readfile) == 'function' and typeof(isfile) == 'function' and isfile(path) then
		return loadstring(readfile(path), '@' .. path)()
	end
	local repo = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/'
	local rel = path:gsub('^ZilkLib/', '')
	return loadstring(game:HttpGet(repo .. rel), '@ZilkLib/' .. rel)()
end

local Library = loadZilkModule('ZilkLib/Library.lua')
local ThemeManager = loadZilkModule('ZilkLib/addons/ThemeManager.lua')
local SaveManager = loadZilkModule('ZilkLib/addons/SaveManager.lua')
local BuiltInTabs = loadZilkModule('ZilkLib/addons/BuiltInTabs.lua')

Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
	ConfigFolder = ZILK_CONFIGS_PATH,
	ThemeFolder = ZILK_THEMES_PATH,
	IgnoreThemeInConfigs = true,
})
SaveManager:SetIgnoreIndexes({ 'MenuKeybind', 'Settings_ShowKeybinds', 'Settings_Watermark' })
```

Optional: load `Loader.lua` once from GitHub if you only want the helper without copying it:

```lua
local Loader = loadstring(game:HttpGet('https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/Loader.lua'))()
local loadZilkModule = Loader.loadZilkModule
local Library, ThemeManager, SaveManager, BuiltInTabs = Loader.Load()
```

## Save paths

Config and theme folders are **whatever you set in your script** — they do not have to be named `Zilk`. Pick any folder path your executor supports (e.g. per-script or per-game names).

Example layout (names are up to you):

```
MyScript/
  configs/
  themes/
ZilkLib/
  Library.lua
  addons/
    ThemeManager.lua
    SaveManager.lua
    BuiltInTabs.lua
```

Set paths in your script before `CreateWindow`. Not changeable in the UI.

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
