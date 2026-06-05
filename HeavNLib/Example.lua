--[[
	HeavNLib — full example
	https://github.com/XIMMYzwsss/ZilkLib/tree/main/HeavNLib
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
	local repo = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/HeavNLib/'
	Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
	ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
	SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
	BuiltInTabs = loadstring(game:HttpGet(repo .. 'addons/BuiltInTabs.lua'))()
end

Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
	Folder = 'HeavNLib',
	ConfigFolder = 'HeavNLib/configs',
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
	BuiltInTabs = true,
	TabPadding = 5,
	MenuFadeTime = 0.15,
})

local Main = Window:AddTab('Main')
local Combat = Window:AddTab('Combat')

-- === Main tab ===
local Features = Main:AddLeftGroupbox('Features')

local demoToggle = Features:AddToggle('DemoToggle', {
	Text = 'Example toggle',
	Default = true,
	Tooltip = 'Pill-style HeavN toggle',
})
demoToggle:OnChanged(function()
	print('[HeavNLib] DemoToggle:', demoToggle.Value)
end)

local demoSlider = Features:AddSlider('DemoSlider', {
	Text = 'Example slider',
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
})
demoSlider:OnChanged(function()
	print('[HeavNLib] DemoSlider:', demoSlider.Value)
end)

local demoDropdown = Features:AddDropdown('DemoDropdown', {
	Values = { 'Alpha', 'Bravo', 'Charlie' },
	Default = 1,
	Text = 'Example dropdown',
})
demoDropdown:OnChanged(function()
	print('[HeavNLib] DemoDropdown:', demoDropdown.Value)
end)

Features:AddDivider()

local demoInput = Features:AddInput('DemoInput', {
	Text = 'Example input',
	Default = 'Type here...',
	Finished = false,
})

local colorRow = Features:AddLabel('Accent color')
local demoColor = colorRow:AddColorPicker('DemoColor', { Default = Library.AccentColor })

local keyRow = Features:AddLabel('Feature keybind')
local demoKey = keyRow:AddKeyPicker('DemoKey', {
	Default = 'MB2',
	Mode = 'Toggle',
	Text = 'Demo feature',
})

local Visuals = Main:AddRightGroupbox('Visuals')
Visuals:AddToggle('ShowESP', { Text = 'ESP master', Default = false })
Visuals:AddSlider('ESP_Distance', {
	Text = 'Max distance',
	Default = 500,
	Min = 50,
	Max = 2000,
	Rounding = 0,
})
Visuals:AddDropdown('ESP_BoxType', {
	Text = 'Box type',
	Values = { 'Normal', 'Corner', '3D' },
	Default = 1,
})

local DepBox = Main:AddRightGroupbox('Dependencies')
local masterSwitch = DepBox:AddToggle('MasterSwitch', { Text = 'Enable extras', Default = false })
local sub = DepBox:AddDependencyBox()
sub:AddSlider('DepSlider', { Text = 'Dependent slider', Default = 10, Min = 0, Max = 50, Rounding = 0 })
sub:AddDropdown('DepDropdown', { Text = 'Extra mode', Values = { 'Safe', 'Normal', 'Aggressive' }, Default = 2 })
sub:SetupDependencies({ { masterSwitch, true } })

local Tabbox = Main:AddLeftTabbox()
local T1 = Tabbox:AddTab('Movement')
local T2 = Tabbox:AddTab('Misc')
T1:AddToggle('FlyToggle', { Text = 'Fly', Default = false })
T1:AddSlider('FlySpeed', { Text = 'Fly speed', Default = 70, Min = 10, Max = 500, Rounding = 0 })
T2:AddToggle('AutoStomp', { Text = 'Auto stomp', Default = false })
T2:AddButton({ Text = 'Print state', Func = function()
	local ge = getgenv()
	local fly = ge.Toggles and ge.Toggles.FlyToggle
	print('[HeavNLib] Fly toggle:', fly and fly.Value)
end })

-- === Combat tab ===
local Aim = Combat:AddLeftGroupbox('Aimbot')
Aim:AddToggle('AimEnabled', { Text = 'Enabled', Default = false })
Aim:AddDropdown('AimPart', { Text = 'Hit part', Values = { 'Head', 'Torso', 'Random' }, Default = 1 })
Aim:AddSlider('AimFOV', { Text = 'FOV', Default = 120, Min = 10, Max = 500, Rounding = 0 })

local Rage = Combat:AddRightGroupbox('Rage')
Rage:AddToggle('RageEnabled', { Text = 'Ragebot', Default = false })
Rage:AddLabel('FOV color'):AddColorPicker('RageFOVColor', { Default = Library.AccentColor })

-- Watermark
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

Library:OnUnload(function()
	WatermarkConnection:Disconnect()
	print('HeavNLib unloaded')
end)

task.defer(function()
	if SaveManager then SaveManager:LoadAutoloadConfig() end
end)

print('HeavNLib loaded — press RightShift to toggle menu')
