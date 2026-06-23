-- Config/theme folders: use any path you want (not required to be named "Zilk")
local CONFIG_PATH = 'Zilk/configs'
local THEME_PATH = 'Zilk/themes'

local repo = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/'
local Loader = loadstring(game:HttpGet(repo .. 'Loader.lua'))()
local Library, ThemeManager, SaveManager, BuiltInTabs = Loader.Load(repo)
Library:InitAddons(ThemeManager, SaveManager, BuiltInTabs, {
	ConfigFolder = CONFIG_PATH,
	ThemeFolder = THEME_PATH,
	IgnoreThemeInConfigs = true,
})
SaveManager:SetIgnoreIndexes({
	'MenuKeybind', 'Settings_ShowKeybinds', 'Settings_Watermark',
})
local Window = Library:CreateWindow({
	Title = 'ZilkLib Demo',
	SubTitle = 'v1.0',
	Center = true,
	AutoShow = true,
	BuiltInTabs = true,
	TabPadding = 5,
	MenuFadeTime = 0.15,
})
local Tab1 = Window:AddTab('Basic Elements')
local ToggleBox = Tab1:AddLeftGroupbox('Toggles')
ToggleBox:AddLabel('Different toggle styles:')
local basicToggle = ToggleBox:AddToggle('BasicToggle', {
	Text = 'Basic Toggle',
	Default = true,
	Tooltip = 'This is a tooltip! Hover to see it.',
})
basicToggle:OnChanged(function()
	print('[ZilkLib] Basic Toggle:', basicToggle.Value)
end)
local toggleWithTooltip = ToggleBox:AddToggle('TooltipToggle', {
	Text = 'Toggle with Tooltip',
	Default = false,
	Tooltip = 'Tooltips appear when you hover!\nYou can have multiple lines too.',
})
ToggleBox:AddDivider()
local SliderBox = Tab1:AddLeftGroupbox('Sliders')
local intSlider = SliderBox:AddSlider('IntSlider', {
	Text = 'Integer Slider',
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Compact = false,
})
local lastSliderPrint = 0
intSlider:OnChanged(function()
	local now = tick()
	if now - lastSliderPrint < 0.2 then return end
	lastSliderPrint = now
	print('[ZilkLib] Int Slider:', intSlider.Value)
end)
local decimalSlider = SliderBox:AddSlider('DecimalSlider', {
	Text = 'Decimal Slider',
	Default = 2.5,
	Min = 0,
	Max = 10,
	Rounding = 2,
	Suffix = ' meters',
})
local compactSlider = SliderBox:AddSlider('CompactSlider', {
	Text = 'Compact Slider (no label)',
	Default = 75,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Compact = true,
})
local ButtonBox = Tab1:AddRightGroupbox('Buttons')
ButtonBox:AddButton({
	Text = 'Simple Button',
	Func = function()
		Library:Notify('Button Clicked!', 2)
	end,
	Tooltip = 'Click me!'
})
ButtonBox:AddButton({
	Text = 'Double Click Button',
	Func = function()
		Library:Notify('Double clicked!', 2)
	end,
	DoubleClick = true,
	Tooltip = 'Requires double click'
})
ButtonBox:AddButton({
	Text = 'Dangerous Action',
	Func = function()
		Library:Notify('Action executed!', 2)
	end,
	Tooltip = 'This is a risky button'
})
ButtonBox:AddDivider()
local InputBox = Tab1:AddRightGroupbox('Text Inputs')
local textInput = InputBox:AddInput('TextInput', {
	Text = 'Text Input',
	Default = 'Type here...',
	Placeholder = 'Enter text',
})
textInput:OnChanged(function()
	print('[ZilkLib] Text Input:', textInput.Value)
end)
local numericInput = InputBox:AddInput('NumericInput', {
	Text = 'Numeric Input',
	Default = '123',
	Numeric = true,
})
local Tab2 = Window:AddTab('Dropdowns & Pickers')
local DropdownBox = Tab2:AddLeftGroupbox('Dropdowns')
local singleDropdown = DropdownBox:AddDropdown('SingleDropdown', {
	Values = { 'Option 1', 'Option 2', 'Option 3', 'Option 4' },
	Default = 1,
	Text = 'Single Select',
})
singleDropdown:OnChanged(function()
	print('[ZilkLib] Single Dropdown:', singleDropdown.Value)
end)
local multiDropdown = DropdownBox:AddDropdown('MultiDropdown', {
	Values = { 'Red', 'Green', 'Blue', 'Yellow', 'Purple' },
	Default = { 'Red', 'Blue' },
	Multi = true,
	Text = 'Multi Select',
})
multiDropdown:OnChanged(function()
	print('[ZilkLib] Multi Dropdown:', multiDropdown.Value)
end)
local largeList = {}
for i = 1, 100 do
	table.insert(largeList, 'Item ' .. i)
end
local largeDropdown = DropdownBox:AddDropdown('LargeDropdown', {
	Values = largeList,
	Default = 1,
	Text = 'Large Dropdown (100 items)',
	Tooltip = 'Lazy loads items as you scroll'
})
local playerDropdown = DropdownBox:AddDropdown('PlayerDropdown', {
	SpecialType = 'Player',
	Text = 'Player List',
	AllowNull = true,
})
local ColorBox = Tab2:AddRightGroupbox('Color Pickers')
local colorRow1 = ColorBox:AddLabel('Basic Color'):AddColorPicker('BasicColor', {
	Default = Library.AccentColor,
})
local colorRow2 = ColorBox:AddLabel('Color with Transparency'):AddColorPicker('TransparentColor', {
	Default = Color3.fromRGB(255, 0, 0),
	Transparency = 0.5,
})
colorRow2:OnChanged(function()
	print('[ZilkLib] Color:', colorRow2.Value, 'Alpha:', colorRow2.Transparency)
end)
ColorBox:AddDivider()
local KeybindBox = Tab2:AddRightGroupbox('Keybind Pickers')
local keyRow1 = KeybindBox:AddLabel('Toggle Key'):AddKeyPicker('ToggleKey', {
	Default = 'MB2',
	Mode = 'Toggle',
	Text = 'Toggle Feature',
})
local keyRow2 = KeybindBox:AddLabel('Hold Key'):AddKeyPicker('HoldKey', {
	Default = 'LeftControl',
	Mode = 'Hold',
	Text = 'Hold Feature',
})
keyRow2:OnChanged(function()
	print('[ZilkLib] Hold Key changed to:', keyRow2.Value)
end)
local Tab3 = Window:AddTab('Advanced')
local DepBox = Tab3:AddLeftGroupbox('Dependency System')
DepBox:AddLabel('Enable master to show dependent options:')
local masterToggle = DepBox:AddToggle('MasterEnable', {
	Text = 'Master Enable',
	Default = false,
})
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
dependentBox:SetupDependencies({
	{ masterToggle, true }
})
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
local SpecialBox = Tab3:AddRightGroupbox('Special Features')
SpecialBox:AddButton({
	Text = 'Show Keybind List',
	Func = function()
		local ge = getgenv()
		local t = ge.Toggles and ge.Toggles['Settings_ShowKeybinds']
		if t then
			t:SetValue(not t.Value)
		end
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
SpecialBox:AddLabel('Resize menu: drag the bottom right corner')
SpecialBox:AddLabel('Menu size is saved in configs')
local Tab4 = Window:AddTab('Practical Examples')
local RunService = game:GetService('RunService')
local HowToBox = Tab4:AddLeftGroupbox('How keybinds + toggles work')
HowToBox:AddLabel('There are two common patterns:', true)
HowToBox:AddLabel('1) Aimbot below has an "Enabled" toggle. Its keybind does NOTHING unless that toggle is ON. Turn it on first, then hold the key.', true)
HowToBox:AddDivider()
HowToBox:AddLabel('2) Fly has NO toggle. Its keybind works by itself. Press the key to toggle fly.', true)
local AimbotBox = Tab4:AddLeftGroupbox('Aimbot (needs toggle ON)')
local aimbotEnabled = AimbotBox:AddToggle('AimbotEnabled', {
	Text = 'Enabled',
	Default = false,
	Tooltip = 'The aimbot key only works while this is ON',
})
AimbotBox:AddLabel('Aimbot Key'):AddKeyPicker('AimbotKey', {
	Default = 'E',
	Mode = 'Hold',
	Text = 'Aimbot',
	GateToggle = aimbotEnabled,
})
local aimbotKey = getgenv().Options.AimbotKey
local aimbotStatus = AimbotBox:AddLabel('Status: toggle OFF, key ignored', true)
local aimDep = AimbotBox:AddDependencyBox()
aimDep:AddDropdown('AimbotPart', {
	Values = { 'Head', 'Torso', 'Closest' },
	Default = 1,
	Text = 'Target Part',
})
aimDep:AddSlider('AimbotSmooth', {
	Text = 'Smoothness',
	Default = 10,
	Min = 0,
	Max = 100,
	Rounding = 0,
})
aimDep:AddToggle('AimbotWallCheck', {
	Text = 'Wall Check',
	Default = true,
})
aimDep:SetupDependencies({ { aimbotEnabled, true } })
aimbotEnabled:OnChanged(function()
	aimbotStatus:SetText(aimbotEnabled.Value and 'Status: ON, hold key to aim' or 'Status: toggle OFF, key ignored')
end)
local aimWasDown = false
local AimbotConnection = RunService.RenderStepped:Connect(function()
	local down = aimbotKey and aimbotKey:GetState() or false
	if down and not aimWasDown and aimbotEnabled.Value then
		Library:Notify('Aimbot', 'Locking onto target...', 1)
	end
	aimWasDown = down
end)
local FlyBox = Tab4:AddRightGroupbox('Fly (keybind only, no toggle)')
FlyBox:AddLabel('No toggle here. Just press the key.', true)
FlyBox:AddLabel('Fly Key'):AddKeyPicker('FlyKey', {
	Default = 'F',
	Mode = 'Toggle',
	Text = 'Fly',
})
local flyKey = getgenv().Options.FlyKey
FlyBox:AddSlider('FlySpeed', {
	Text = 'Fly Speed',
	Default = 100,
	Min = 10,
	Max = 500,
	Rounding = 0,
})
local flyWasOn = false
local FlyConnection = RunService.RenderStepped:Connect(function()
	local on = flyKey and flyKey:GetState() or false
	if on ~= flyWasOn then
		flyWasOn = on
		Library:Notify('Fly', on and 'Fly on' or 'Fly off', 2)
	end
end)
local ESPBox = Tab4:AddRightGroupbox('ESP Example')
local espMaster = ESPBox:AddToggle('ESPEnabled', {
	Text = 'Master Enable',
	Default = false,
})
local espDep = ESPBox:AddDependencyBox()
espDep:AddToggle('ESPBox', { Text = 'Box ESP', Default = true })
espDep:AddLabel('Box Color'):AddColorPicker('ESPBoxColor', { Default = Color3.fromRGB(255, 255, 255) })
espDep:AddToggle('ESPName', { Text = 'Name ESP', Default = true })
espDep:AddToggle('ESPDistance', { Text = 'Distance ESP', Default = false })
espDep:AddSlider('ESPMaxDistance', {
	Text = 'Max Distance',
	Default = 500,
	Min = 100,
	Max = 5000,
	Rounding = 0,
	Suffix = ' studs',
})
espDep:SetupDependencies({ { espMaster, true } })
local MovementBox = Tab4:AddLeftGroupbox('Movement Extras')
MovementBox:AddToggle('NoClip', { Text = 'NoClip', Default = false })
MovementBox:AddToggle('InfiniteJump', { Text = 'Infinite Jump', Default = false })
MovementBox:AddSlider('WalkSpeed', {
	Text = 'Walk Speed', Default = 16, Min = 16, Max = 200, Rounding = 0,
})
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
	Library:SetWatermark(string.format('ZilkLib Demo | %d fps | %d ms', math.floor(FPS), ping))
end)
Library:OnUnload(function()
	WatermarkConnection:Disconnect()
	if AimbotConnection then AimbotConnection:Disconnect() end
	if FlyConnection then FlyConnection:Disconnect() end
	print('[ZilkLib] Unloaded!')
end)
Library:Notify('ZilkLib Demo', 'Loaded. RightShift = menu. Settings has themes + configs.', 6)
print('[ZilkLib] Demo loaded. RightShift opens menu')