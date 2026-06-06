--[[
	HeavNLib — Comprehensive Feature Demo
	Shows EVERY possible UI element and feature
	https://github.com/XIMMYzwsss/ZilkLib/tree/main/HeavNLib
]]

local ROOT = 'HeavNLib/'

local function loadLocal(path)
	if readfile and isfile and isfile(path) then
		return loadstring(readfile(path))()
	end
	return nil
end

-- Load Library
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

-- Initialize addons
Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
	Folder = 'HeavNLib_Demo',
	ConfigFolder = 'HeavNLib_Demo/configs',
	IgnoreThemeInConfigs = true,
})

-- Ignore Settings/Config UI elements from being saved
SaveManager:SetIgnoreIndexes({
	'MenuKeybind', 'Settings_UICorner', 'Settings_KeybindTrans',
	'Settings_ShowKeybinds', 'Settings_Watermark', 'Settings_TabPosition',
})

-- Create resizable window (drag bottom-right corner to resize!)
local Window = Library:CreateWindow({
	Title = 'HeavNLib Demo',
	SubTitle = 'v1.0',
	Center = true,
	AutoShow = true,
	BuiltInTabs = true,  -- Auto-creates Settings & Configs tabs
	TabPadding = 5,
	MenuFadeTime = 0.15,
})

-- ═══════════════════════════════════════════════════════
--  TAB 1: Basic Elements
-- ═══════════════════════════════════════════════════════
local Tab1 = Window:AddTab('Basic Elements')

-- Toggles
local ToggleBox = Tab1:AddLeftGroupbox('Toggles')
ToggleBox:AddLabel('Different toggle styles:')

local basicToggle = ToggleBox:AddToggle('BasicToggle', {
	Text = 'Basic Toggle',
	Default = true,
	Tooltip = 'This is a tooltip! Hover to see it.',
})
basicToggle:OnChanged(function()
	print('[HeavNLib] Basic Toggle:', basicToggle.Value)
end)

local toggleWithTooltip = ToggleBox:AddToggle('TooltipToggle', {
	Text = 'Toggle with Tooltip',
	Default = false,
	Tooltip = 'Tooltips appear when you hover!\nYou can have multiple lines too.',
})

ToggleBox:AddDivider() -- Visual separator

-- Sliders
local SliderBox = Tab1:AddLeftGroupbox('Sliders')

local intSlider = SliderBox:AddSlider('IntSlider', {
	Text = 'Integer Slider',
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,  -- No decimals
	Compact = false,
})
-- Throttle slider prints to avoid console spam
local lastSliderPrint = 0
intSlider:OnChanged(function()
	local now = tick()
	if now - lastSliderPrint < 0.2 then return end
	lastSliderPrint = now
	print('[HeavNLib] Int Slider:', intSlider.Value)
end)

local decimalSlider = SliderBox:AddSlider('DecimalSlider', {
	Text = 'Decimal Slider',
	Default = 2.5,
	Min = 0,
	Max = 10,
	Rounding = 2,  -- 2 decimal places
	Suffix = ' meters',  -- Shows unit
})

local compactSlider = SliderBox:AddSlider('CompactSlider', {
	Text = 'Compact Slider (no label)',
	Default = 75,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Compact = true,  -- More compact layout
})

-- Buttons
local ButtonBox = Tab1:AddRightGroupbox('Buttons')

ButtonBox:AddButton({
	Text = 'Simple Button',
	Func = function()
		Library:Notify('Button Clicked!', 2)
	end,
	Tooltip = 'Click me!'
})

ButtonBox:AddButton({
	Text = 'Double-Click Button',
	Func = function()
		Library:Notify('Double-clicked!', 2)
	end,
	DoubleClick = true,
	Tooltip = 'Requires double-click'
})

-- Button with confirmation
ButtonBox:AddButton({
	Text = 'Dangerous Action',
	Func = function()
		Library:Notify('Action executed!', 2)
	end,
	Tooltip = 'This is a risky button'
})

ButtonBox:AddDivider()

-- Inputs
local InputBox = Tab1:AddRightGroupbox('Text Inputs')

local textInput = InputBox:AddInput('TextInput', {
	Text = 'Text Input',
	Default = 'Type here...',
	Placeholder = 'Enter text',
	Finished = false,  -- Triggers on each keystroke
})
textInput:OnChanged(function()
	print('[HeavNLib] Text Input:', textInput.Value)
end)

local numericInput = InputBox:AddInput('NumericInput', {
	Text = 'Numeric Input',
	Default = '123',
	Numeric = true,  -- Only allows numbers
	Finished = true,  -- Only triggers on Enter
})

-- ═══════════════════════════════════════════════════════
--  TAB 2: Dropdowns & Pickers
-- ═══════════════════════════════════════════════════════
local Tab2 = Window:AddTab('Dropdowns & Pickers')

-- Dropdowns
local DropdownBox = Tab2:AddLeftGroupbox('Dropdowns')

-- Single select dropdown
local singleDropdown = DropdownBox:AddDropdown('SingleDropdown', {
	Values = { 'Option 1', 'Option 2', 'Option 3', 'Option 4' },
	Default = 1,
	Text = 'Single Select',
})
singleDropdown:OnChanged(function()
	print('[HeavNLib] Single Dropdown:', singleDropdown.Value)
end)

-- Multi-select dropdown
local multiDropdown = DropdownBox:AddDropdown('MultiDropdown', {
	Values = { 'Red', 'Green', 'Blue', 'Yellow', 'Purple' },
	Default = { 'Red', 'Blue' },
	Multi = true,  -- Allow multiple selections
	Text = 'Multi Select',
})
multiDropdown:OnChanged(function()
	print('[HeavNLib] Multi Dropdown:', multiDropdown.Value)
end)

-- Large dropdown (tests lazy loading!)
local largeList = {}
for i = 1, 100 do
	table.insert(largeList, 'Item ' .. i)
end
local largeDropdown = DropdownBox:AddDropdown('LargeDropdown', {
	Values = largeList,
	Default = 1,
	Text = 'Large Dropdown (100 items)',
	Tooltip = 'Tests lazy loading - only renders visible items!'
})

-- Player/Team dropdowns
local playerDropdown = DropdownBox:AddDropdown('PlayerDropdown', {
	SpecialType = 'Player',  -- Auto-populates with players
	Text = 'Player List',
	AllowNull = true,
})

-- Color Pickers
local ColorBox = Tab2:AddRightGroupbox('Color Pickers')

local colorRow1 = ColorBox:AddLabel('Basic Color'):AddColorPicker('BasicColor', {
	Default = Library.AccentColor,
})

local colorRow2 = ColorBox:AddLabel('Color with Transparency'):AddColorPicker('TransparentColor', {
	Default = Color3.fromRGB(255, 0, 0),
	Transparency = 0.5,  -- Enables transparency slider
})

colorRow2:OnChanged(function()
	print('[HeavNLib] Color:', colorRow2.Value, 'Alpha:', colorRow2.Transparency)
end)

ColorBox:AddDivider()

-- Keybind Pickers
local KeybindBox = Tab2:AddRightGroupbox('Keybind Pickers')

local keyRow1 = KeybindBox:AddLabel('Toggle Key'):AddKeyPicker('ToggleKey', {
	Default = 'MB2',
	Mode = 'Toggle',  -- Modes: Toggle, Hold, Always
	Text = 'Toggle Feature',
})

local keyRow2 = KeybindBox:AddLabel('Hold Key'):AddKeyPicker('HoldKey', {
	Default = 'LeftControl',
	Mode = 'Hold',
	Text = 'Hold Feature',
})
keyRow2:OnChanged(function()
	print('[HeavNLib] Hold Key changed to:', keyRow2.Value)
end)

-- ═══════════════════════════════════════════════════════
--  TAB 3: Advanced Features
-- ═══════════════════════════════════════════════════════
local Tab3 = Window:AddTab('Advanced')

-- Dependency Boxes
local DepBox = Tab3:AddLeftGroupbox('Dependency System')
DepBox:AddLabel('Enable master to show dependent options:')

local masterToggle = DepBox:AddToggle('MasterEnable', {
	Text = 'Master Enable',
	Default = false,
})

-- This box only shows when masterToggle is true
local dependentBox = DepBox:AddDependencyBox()
dependentBox:AddSlider('DepSlider', {
	Text = 'Dependent Slider',
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
})
dependentBox:AddDropdown('DepDropdown', {
	Values = { 'Mode A', 'Mode B', 'Mode C' },
	Default = 1,
	Text = 'Dependent Dropdown',
})
dependentBox:AddToggle('DepToggle', {
	Text = 'Dependent Toggle',
	Default = false,
})
-- Link dependency
dependentBox:SetupDependencies({
	{ masterToggle, true }  -- Only shows when masterToggle is true
})

-- Tabboxes (nested tabs)
local TabboxDemo = Tab3:AddLeftGroupbox('Tabbox Demo')
TabboxDemo:AddLabel('Tabboxes create nested tabs:')

local Tabbox = Tab3:AddLeftTabbox()
local TabA = Tabbox:AddTab('Tab A')
local TabB = Tabbox:AddTab('Tab B')
local TabC = Tabbox:AddTab('Tab C')

TabA:AddToggle('TabA_Toggle', { Text = 'Tab A Toggle', Default = false })
TabA:AddSlider('TabA_Slider', { Text = 'Tab A Slider', Default = 50, Min = 0, Max = 100, Rounding = 0 })

TabB:AddDropdown('TabB_Dropdown', { Values = { 'One', 'Two', 'Three' }, Default = 1, Text = 'Tab B Dropdown' })
TabB:AddButton({ Text = 'Tab B Button', Func = function() Library:Notify('Tab B!', 1) end })

TabC:AddInput('TabC_Input', { Text = 'Tab C Input', Default = '', Placeholder = 'Type here' })
TabC:AddLabel('Nested tabs are useful for organizing!')

-- Special Features
local SpecialBox = Tab3:AddRightGroupbox('Special Features')

SpecialBox:AddButton({
	Text = 'Test Notification (8s)',
	Func = function()
		Library:Notify('HeavNLib', 'This is a notification!\n\nPosition changeable in Settings.\nKeybind list position also changeable.\n\nDefault duration: 8 seconds', 8)
	end,
})

SpecialBox:AddButton({
	Text = 'Show Keybind List',
	Func = function()
		Library.KeybindFrame.Visible = not Library.KeybindFrame.Visible
		Library:Notify('Keybind list toggled!', 2)
	end,
})

SpecialBox:AddButton({
	Text = 'Print All Values',
	Func = function()
		local ge = getgenv()
		print('\n=== Current Values ===')
		for k, v in pairs(ge.Toggles) do
			print(k, '=', v.Value)
		end
		for k, v in pairs(ge.Options) do
			if type(v.Value) ~= 'table' then
				print(k, '=', v.Value)
			end
		end
		print('===================\n')
		Library:Notify('Values printed to console', 2)
	end,
})

SpecialBox:AddDivider()
SpecialBox:AddLabel('Resize menu: Drag bottom-right corner!')
SpecialBox:AddLabel('Menu size is saved in configs')

-- Risk Color Demo
local RiskBox = Tab3:AddRightGroupbox('Visual Styles')
RiskBox:AddLabel('You can customize colors:')
RiskBox:AddLabel('Accent Color'):AddColorPicker('DemoAccent', {
	Default = Library.AccentColor,
})

local accentPicker = getgenv().Options.DemoAccent
if accentPicker then
	accentPicker:OnChanged(function()
		Library.AccentColor = accentPicker.Value
		Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
		Library:UpdateColorsUsingRegistry()
	end)
end

-- ═══════════════════════════════════════════════════════
--  TAB 4: Practical Examples
-- ═══════════════════════════════════════════════════════
local Tab4 = Window:AddTab('Practical Examples')

-- Aimbot Example
local AimbotBox = Tab4:AddLeftGroupbox('Aimbot Example')
local aimbotEnabled = AimbotBox:AddToggle('AimbotEnabled', {
	Text = 'Enabled',
	Default = false,
})

local aimbotKey = AimbotBox:AddLabel('Aimbot Key'):AddKeyPicker('AimbotKey', {
	Default = 'MB2',
	Mode = 'Hold',
	Text = 'Aimbot',
})

AimbotBox:AddDropdown('AimbotPart', {
	Values = { 'Head', 'Torso', 'Closest' },
	Default = 1,
	Text = 'Target Part',
})

AimbotBox:AddSlider('AimbotSmooth', {
	Text = 'Smoothness',
	Default = 10,
	Min = 0,
	Max = 100,
	Rounding = 0,
})

AimbotBox:AddToggle('AimbotWallCheck', {
	Text = 'Wall Check',
	Default = true,
})

-- ESP Example
local ESPBox = Tab4:AddRightGroupbox('ESP Example')
ESPBox:AddToggle('ESPEnabled', {
	Text = 'Master Enable',
	Default = false,
})

ESPBox:AddToggle('ESPBox', {
	Text = 'Box ESP',
	Default = true,
})

ESPBox:AddLabel('Box Color'):AddColorPicker('ESPBoxColor', {
	Default = Color3.fromRGB(255, 255, 255),
})

ESPBox:AddToggle('ESPName', {
	Text = 'Name ESP',
	Default = true,
})

ESPBox:AddToggle('ESPDistance', {
	Text = 'Distance ESP',
	Default = false,
})

ESPBox:AddSlider('ESPMaxDistance', {
	Text = 'Max Distance',
	Default = 500,
	Min = 100,
	Max = 5000,
	Rounding = 0,
	Suffix = ' studs',
})

-- Movement Example
local MovementBox = Tab4:AddLeftGroupbox('Movement Example')
local flyEnabled = MovementBox:AddToggle('FlyEnabled', {
	Text = 'Fly',
	Default = false,
})

local flyKey = MovementBox:AddLabel('Fly Key'):AddKeyPicker('FlyKey', {
	Default = 'E',
	Mode = 'Toggle',
	Text = 'Fly',
})

MovementBox:AddSlider('FlySpeed', {
	Text = 'Fly Speed',
	Default = 100,
	Min = 10,
	Max = 500,
	Rounding = 0,
})

MovementBox:AddToggle('NoClip', {
	Text = 'NoClip',
	Default = false,
})

MovementBox:AddToggle('InfiniteJump', {
	Text = 'Infinite Jump',
	Default = false,
})

-- ═══════════════════════════════════════════════════════
--  Watermark & FPS Counter
-- ═══════════════════════════════════════════════════════
Library:SetWatermarkVisibility(true)
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
	FrameCounter = FrameCounter + 1
	if (tick() - FrameTimer) >= 1 then
		FPS = FrameCounter
		FrameTimer = tick()
		FrameCounter = 0
	end
	local ping = 0
	pcall(function()
		ping = math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
	end)
	Library:SetWatermark(string.format('HeavNLib Demo | %d fps | %d ms', math.floor(FPS), ping))
end)

-- Show keybind list by default for demo
Library.KeybindFrame.Visible = true

-- Cleanup on unload
Library:OnUnload(function()
	WatermarkConnection:Disconnect()
	print('[HeavNLib] Unloaded!')
end)

-- Auto-load last config
task.defer(function()
	if SaveManager then
		SaveManager:LoadAutoloadConfig()
	end
end)

-- Welcome notification
Library:Notify('HeavNLib Demo', 'Loaded successfully!\nExplore all tabs to see features.\n\nPress RightShift to toggle menu.\nDrag bottom-right corner to resize!\n\nSettings tab has theme, notification position,\nkeybind list position, and more!', 10)

print([[
╔══════════════════════════════════════╗
║       HeavNLib Demo Loaded!          ║
║                                      ║
║  • Press RightShift to toggle menu   ║
║  • Drag bottom-right to resize       ║
║  • Check Settings & Configs tabs     ║
║  • Keybind list shows active keys    ║
║                                      ║
║  All features demonstrated! 🎉       ║
╚══════════════════════════════════════╝
]])
