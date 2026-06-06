--[[
	Auto-builds Settings + Configs tabs (HeavN-style) when attached from Library:CreateWindow.
]]

local BuiltInTabs = {} do
	BuiltInTabs.Library = nil
	BuiltInTabs.ThemeManager = nil
	BuiltInTabs.SaveManager = nil

	local FONT_LIST = { 'Gotham', 'GothamBold', 'GothamMedium', 'GothamBlack', 'SourceSans', 'SourceSansBold', 'Code', 'Roboto', 'RobotoMono' }

	local function opt(idx)
		local ge = getgenv()
		return ge and ge.Options and ge.Options[idx]
	end

	local function tgl(idx)
		local ge = getgenv()
		return ge and ge.Toggles and ge.Toggles[idx]
	end

	function BuiltInTabs:SetLibrary(lib)
		self.Library = lib
	end

	function BuiltInTabs:SetThemeManager(tm)
		self.ThemeManager = tm
	end

	function BuiltInTabs:SetSaveManager(sm)
		self.SaveManager = sm
	end

	function BuiltInTabs:BuildSettingsTab(tab, config)
		local lib = self.Library
		local ui = tab:AddLeftGroupbox('UI Settings')

		ui:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
			Default = 'RightShift',
			NoUI = true,
			Mode = 'Hold',
			Text = 'Menu keybind',
		})
		local menuKey = opt('MenuKeybind')
		lib:SetToggleKeybind(menuKey)
		if menuKey and menuKey.OnChanged then
			menuKey:OnChanged(function()
				lib:SetToggleKeybind(menuKey)
			end)
		end

		ui:AddButton('Unload', function()
			lib:Unload()
		end)

		ui:AddDivider()

		if self.ThemeManager then
			local themeBox = tab:AddLeftGroupbox('Themes')
			self.ThemeManager:CreateThemeManager(themeBox)
			
			-- Add background image settings to theme box
			themeBox:AddDivider()
			themeBox:AddLabel('Background Image:')
			
			local bgImageToggle = themeBox:AddToggle('Settings_BGImage', {
				Text = 'Enable background',
				Default = lib.UIBackgroundImageEnabled,
			})
			bgImageToggle:OnChanged(function()
				lib.UIBackgroundImageEnabled = bgImageToggle.Value
				lib:ApplyMainFrameBackground()
			end)

			local bgAssetInput = themeBox:AddInput('Settings_BGAsset', {
				Text = 'Texture id / URL',
				Default = lib.UIBackgroundImageAssetId or '',
				Placeholder = 'rbxassetid://123456 or URL',
				Finished = true,
			})
			bgAssetInput:OnChanged(function()
				lib.UIBackgroundImageAssetId = bgAssetInput.Value
				lib:ApplyMainFrameBackground()
			end)
		else
			ui:AddLabel('Accent'):AddColorPicker('AccentColor', { Default = lib.AccentColor })
			local accentPicker = opt('AccentColor')
			if accentPicker then
				accentPicker:OnChanged(function()
					lib.AccentColor = accentPicker.Value
					lib.AccentColorDark = lib:GetDarkerColor(lib.AccentColor)
					lib:UpdateColorsUsingRegistry()
				end)
			end
			ui:AddLabel('GUI text'):AddColorPicker('FontColor', { Default = lib.FontColor })
			local fontPicker = opt('FontColor')
			if fontPicker then
				fontPicker:OnChanged(function()
					lib.FontColor = fontPicker.Value
					lib:UpdateColorsUsingRegistry()
				end)
			end
		end

		local fontDropdown = ui:AddDropdown('Settings_Font', {
			Text = 'Font',
			Values = FONT_LIST,
			Default = lib.FontName or 'GothamBold',
		})
		fontDropdown:OnChanged(function()
			lib:SetFontName(fontDropdown.Value)
		end)

		ui:AddButton('Test notification', function()
			lib:Notify('HeavNLib', 'Sample notification — theme is live.', 3)
		end)

		local layout = tab:AddRightGroupbox('UI Layout')

		local cornerSlider = layout:AddSlider('Settings_UICorner', {
			Text = 'UI corner radius',
			Default = lib.UICornerRadius or 0,
			Min = 0,
			Max = 8,
			Rounding = 0,
		})
		cornerSlider:OnChanged(function()
			lib.UICornerRadius = cornerSlider.Value
			lib:RefreshAllCorners()
		end)

		local kbTransSlider = layout:AddSlider('Settings_KeybindTrans', {
			Text = 'Keybind list transparency',
			Default = lib.UIKeybindBgTransparency or 0.08,
			Min = 0,
			Max = 1,
			Rounding = 2,
		})
		kbTransSlider:OnChanged(function()
			lib.UIKeybindBgTransparency = kbTransSlider.Value
			if lib.ApplyKeybindPanelStyle then
				lib:ApplyKeybindPanelStyle()
			end
		end)

		local showKeybinds = layout:AddToggle('Settings_ShowKeybinds', {
			Text = 'Show keybind list',
			Default = false,
		})
		showKeybinds:OnChanged(function()
			if lib.KeybindFrame then
				lib.KeybindFrame.Visible = showKeybinds.Value
			end
		end)
		
		-- Set initial visibility
		if lib.KeybindFrame then
			lib.KeybindFrame.Visible = false
		end

		local notifPos = layout:AddDropdown('Settings_NotificationPos', {
			Text = 'Notification position',
			Values = { 'Top Left', 'Top Right', 'Bottom Left', 'Bottom Right' },
			Default = 1,
		})
		notifPos:OnChanged(function()
			if lib.NotificationArea then
				local pos = notifPos.Value
				if pos == 'Top Left' then
					lib.NotificationArea.Position = UDim2.new(0, 0, 0, 40)
				elseif pos == 'Top Right' then
					lib.NotificationArea.Position = UDim2.new(1, -300, 0, 40)
				elseif pos == 'Bottom Left' then
					lib.NotificationArea.Position = UDim2.new(0, 0, 1, -300)
				elseif pos == 'Bottom Right' then
					lib.NotificationArea.Position = UDim2.new(1, -300, 1, -300)
				end
			end
		end)

		local kbListPos = layout:AddDropdown('Settings_KeybindListPos', {
			Text = 'Keybind list position',
			Values = { 'Left', 'Right' },
			Default = 1,
		})
		kbListPos:OnChanged(function()
			if lib.KeybindFrame then
				if kbListPos.Value == 'Left' then
					lib.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
					lib.KeybindFrame.Position = UDim2.new(0, 10, 0.5, 0)
				else
					lib.KeybindFrame.AnchorPoint = Vector2.new(1, 0.5)
					lib.KeybindFrame.Position = UDim2.new(1, -10, 0.5, 0)
				end
			end
		end)

		local tabPosDropdown = layout:AddDropdown('Settings_TabPosition', {
			Text = 'Tab position',
			Values = { 'Sidebar', 'Topbar' },
			Default = 1,
			Tooltip = 'Sidebar = left side (default)\nTopbar = top of window'
		})
		tabPosDropdown:OnChanged(function()
			lib:Notify('Tab Position', 'Tab position change requires reload!\nSave config and reload script.', 5)
		end)

		if config and config.Watermark ~= false then
			local wmToggle = layout:AddToggle('Settings_Watermark', {
				Text = 'Show watermark',
				Default = true,
			})
			wmToggle:OnChanged(function()
				lib:SetWatermarkVisibility(wmToggle.Value)
			end)
		end
	end

	function BuiltInTabs:BuildConfigsTab(tab)
		if not self.SaveManager then
			tab:AddLeftGroupbox('Configs'):AddLabel('SaveManager not loaded — require addons/SaveManager.lua')
			return
		end
		self.SaveManager:BuildConfigSection(tab)

		-- Config path is set in code only, not changeable via UI
		local infoBox = tab:AddRightGroupbox('Info')
		infoBox:AddLabel('Config folder:')
		infoBox:AddLabel(self.SaveManager.Folder, true)
		infoBox:AddDivider()
		infoBox:AddLabel('Path set in InitAddons()', true)
		infoBox:AddLabel('Not changeable via UI', true)
	end

	function BuiltInTabs:Attach(window, config)
		config = config or {}
		local settingsName = config.SettingsTabName or 'Settings'
		local configsName = config.ConfigsTabName or 'Configs'

		local settingsTab = window:AddTab(settingsName)
		local configsTab = window:AddTab(configsName)

		self:BuildSettingsTab(settingsTab, config)
		self:BuildConfigsTab(configsTab)

		window.Tabs.Settings = settingsTab
		window.Tabs.Configs = configsTab
		window.Tabs[settingsName] = settingsTab
		window.Tabs[configsName] = configsTab

		if self.SaveManager and config.AutoloadConfig ~= false then
			task.defer(function()
				self.SaveManager:LoadAutoloadConfig()
			end)
		end

		if self.ThemeManager then
			task.defer(function()
				self.ThemeManager:LoadDefault()
			end)
		end
	end
end

return BuiltInTabs
