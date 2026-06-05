--[[
	HeavNLib — full example (HeavN-themed Linoria fork)
	Place this folder in your workspace or upload to your script host.

	Local load (executor with readfile):
		local root = 'HeavNLib/' -- adjust path
		local Library = loadstring(readfile(root .. 'Library.lua'))()
		...
]]

local ROOT = 'HeavNLib/'

local function loadLocal(path)
	if readfile and isfile and isfile(path) then
		return loadstring(readfile(path))()
	end
	return nil
end

local Library = loadLocal(ROOT .. 'Library.lua')
local ThemeManager = loadLocal(ROOT .. 'addons/ThemeManager.lua')
local SaveManager = loadLocal(ROOT .. 'addons/SaveManager.lua')
local BuiltInTabs = loadLocal(ROOT .. 'addons/BuiltInTabs.lua')

if not Library then
	-- Fallback: raw GitHub (replace USER/REPO if you publish)
	local repo = 'https://raw.githubusercontent.com/YOUR_USER/HeavNLib/main/HeavNLib/'
	Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
	ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
	SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
	BuiltInTabs = loadstring(game:HttpGet(repo .. 'addons/BuiltInTabs.lua'))()
end

-- === Init addons (theme + configs path) ===
-- ConfigFolder: where .json configs are saved (user can change in UI too)
Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
	Folder = 'HeavNLib',                    -- themes + autoload metadata
	ConfigFolder = 'HeavNLib/configs',      -- your config saves (customize!)
	IgnoreThemeInConfigs = true,
})

SaveManager:SetIgnoreIndexes({
	'MenuKeybind', 'Settings_Font', 'Settings_UICorner', 'Settings_KeybindTrans',
	'Settings_ShowKeybinds', 'Settings_BGImage', 'Settings_BGAsset', 'Settings_Watermark', 'Configs_CustomPath',
})

local Window = Library:CreateWindow({
	Title = 'HeavNLib',
	SubTitle = 'v1.0',
	Center = true,
	AutoShow = true,
	BuiltInTabs = true,   -- auto Settings + Configs tabs
	TabPadding = 5,
	MenuFadeTime = 0.15,
})

-- User tabs (add yours before or after built-ins — built-ins attach at end)
local Tabs = {
	Main = Window:AddTab('Main'),
}

local MainBox = Tabs.Main:AddLeftGroupbox('Features')

MainBox:AddToggle('DemoToggle', {
	Text = 'Example toggle',
	Default = true,
	Tooltip = 'Pill-style HeavN toggle',
})

Toggles.DemoToggle:OnChanged(function()
	print('[HeavNLib] DemoToggle:', Toggles.DemoToggle.Value)
end)

MainBox:AddSlider('DemoSlider', {
	Text = 'Example slider',
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
})

Options.DemoSlider:OnChanged(function()
	print('[HeavNLib] DemoSlider:', Options.DemoSlider.Value)
end)

MainBox:AddDropdown('DemoDropdown', {
	Values = { 'Alpha', 'Bravo', 'Charlie' },
	Default = 1,
	Text = 'Example dropdown',
})

MainBox:AddInput('DemoInput', {
	Text = 'Example input',
	Default = 'hello',
	Finished = false,
})

MainBox:AddLabel('Accent color'):AddColorPicker('DemoColor', {
	Default = Library.AccentColor,
})

MainBox:AddLabel('Keybind'):AddKeyPicker('DemoKey', {
	Default = 'MB2',
	Mode = 'Toggle',
	Text = 'Hold feature',
})

local DepBox = Tabs.Main:AddRightGroupbox('Dependencies')
DepBox:AddToggle('MasterSwitch', { Text = 'Enable extras', Default = false })

local Sub = DepBox:AddDependencyBox()
Sub:AddSlider('DepSlider', { Text = 'Dependent slider', Default = 10, Min = 0, Max = 50, Rounding = 0 })
Sub:SetupDependencies({ { Toggles.MasterSwitch, true } })

-- Tabbox example
local Tabbox = Tabs.Main:AddRightTabbox()
local T1 = Tabbox:AddTab('Tab A')
local T2 = Tabbox:AddTab('Tab B')
T1:AddToggle('TabA_Toggle', { Text = 'Tab A toggle' })
T2:AddToggle('TabB_Toggle', { Text = 'Tab B toggle' })

-- Watermark (Linoria feature + HeavN style)
Library:SetWatermarkVisibility(true)
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
	FrameCounter += 1
	if (tick() - FrameTimer) >= 1 then
		FPS = FrameCounter
		FrameTimer = tick()
		FrameCounter = 0
	end
	local ping = 0
	pcall(function()
		ping = math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
	end)
	Library:SetWatermark(('HeavNLib | %s fps | %s ms'):format(math.floor(FPS), ping))
end)

Library.KeybindFrame.Visible = true

Options.Settings_ShowKeybinds:OnChanged(function()
	Library.KeybindFrame.Visible = Options.Settings_ShowKeybinds.Value
end)

Library:OnUnload(function()
	WatermarkConnection:Disconnect()
	print('HeavNLib unloaded')
end)

-- Settings + Configs tabs are added automatically after your tabs (deferred Attach).
-- Themes: Settings tab → Themes groupbox | Configs: save/load + custom folder path

task.defer(function()
	if SaveManager then SaveManager:LoadAutoloadConfig() end
end)

print('HeavNLib loaded — open menu with RightShift (change in Settings)')
