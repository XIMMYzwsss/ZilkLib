--[[
	Auto-builds Settings + Configs tabs (HeavN-style) when attached from Library:CreateWindow.
]]

local BuiltInTabs = {} do
	BuiltInTabs.Library = nil
	BuiltInTabs.ThemeManager = nil
	BuiltInTabs.SaveManager = nil

	local FONT_LIST = { 'Gotham', 'GothamBold', 'GothamMedium', 'GothamBlack', 'SourceSans', 'SourceSansBold', 'Code', 'Roboto', 'RobotoMono' }

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

		ui:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })
		lib.ToggleKeybind = Options.MenuKeybind

		ui:AddButton('Unload', function()
			lib:Unload()
		end)

		if self.ThemeManager then
			self.ThemeManager:ApplyToTab(tab)
		else
			ui:AddLabel('Accent'):AddColorPicker('AccentColor', { Default = lib.AccentColor })
			Options.AccentColor:OnChanged(function()
				lib.AccentColor = Options.AccentColor.Value
				lib.AccentColorDark = lib:GetDarkerColor(lib.AccentColor)
				lib:UpdateColorsUsingRegistry()
			end)
			ui:AddLabel('GUI text'):AddColorPicker('FontColor', { Default = lib.FontColor })
			Options.FontColor:OnChanged(function()
				lib.FontColor = Options.FontColor.Value
				lib:UpdateColorsUsingRegistry()
			end)
		end

		ui:AddDropdown('Settings_Font', { Text = 'Font', Values = FONT_LIST, Default = lib.FontName or 'GothamBold' })
		Options.Settings_Font:OnChanged(function()
			lib:SetFontName(Options.Settings_Font.Value)
		end)

		ui:AddButton('Test notification', function()
			lib:Notify('HeavNLib', 'Sample notification — theme is live.', 3)
		end)

		local layout = tab:AddRightGroupbox('UI Layout')

		layout:AddSlider('Settings_UICorner', {
			Text = 'UI corner radius',
			Default = lib.UICornerRadius or 0,
			Min = 0,
			Max = 8,
			Rounding = 0,
		})
		Options.Settings_UICorner:OnChanged(function()
			lib.UICornerRadius = Options.Settings_UICorner.Value
			lib:RefreshAllCorners()
		end)

		layout:AddSlider('Settings_KeybindTrans', {
			Text = 'Keybind list transparency',
			Default = lib.UIKeybindBgTransparency or 0.08,
			Min = 0,
			Max = 1,
			Rounding = 2,
		})
		Options.Settings_KeybindTrans:OnChanged(function()
			lib.UIKeybindBgTransparency = Options.Settings_KeybindTrans.Value
			if lib.KeybindFrame then
				lib.KeybindFrame.BackgroundTransparency = lib.UIKeybindBgTransparency
			end
		end)

		layout:AddToggle('Settings_ShowKeybinds', { Text = 'Show keybind list', Default = true })
		Toggles.Settings_ShowKeybinds:OnChanged(function()
			if lib.KeybindFrame then
				lib.KeybindFrame.Visible = Toggles.Settings_ShowKeybinds.Value
			end
		end)

		layout:AddToggle('Settings_BGImage', { Text = 'Main background image', Default = lib.UIBackgroundImageEnabled })
		Toggles.Settings_BGImage:OnChanged(function()
			lib.UIBackgroundImageEnabled = Toggles.Settings_BGImage.Value
		end)
		layout:AddInput('Settings_BGAsset', { Text = 'Background asset id / URL', Default = lib.UIBackgroundImageAssetId or '', Finished = true })
		Options.Settings_BGAsset:OnChanged(function()
			lib.UIBackgroundImageAssetId = Options.Settings_BGAsset.Value
		end)

		local wm = config and config.Watermark ~= false
		if wm then
			layout:AddToggle('Settings_Watermark', { Text = 'Show watermark', Default = true })
			Toggles.Settings_Watermark:OnChanged(function()
				lib:SetWatermarkVisibility(Toggles.Settings_Watermark.Value)
			end)
		end
	end

	function BuiltInTabs:BuildConfigsTab(tab)
		if not self.SaveManager then
			tab:AddLeftGroupbox('Configs'):AddLabel('SaveManager not loaded — require addons/SaveManager.lua')
			return
		end
		self.SaveManager:BuildConfigSection(tab)

		local pathBox = tab:AddRightGroupbox('Storage')
		pathBox:AddLabel('Config folder:')
		pathBox:AddLabel(self.SaveManager.Folder, true)
		pathBox:AddInput('Configs_CustomPath', {
			Text = 'Set config path (folder)',
			Default = self.SaveManager.Folder,
			Finished = true,
		})
		pathBox:AddButton('Apply path', function()
			local path = Options.Configs_CustomPath.Value
			if path:gsub(' ', '') == '' then
				return self.Library:Notify('Invalid path', 2)
			end
			self.SaveManager:SetConfigPath(path)
			Options.SaveManager_ConfigList:SetValues(self.SaveManager:RefreshConfigList())
			self.Library:Notify('Config path: ' .. path)
		end)
	end

	function BuiltInTabs:Attach(window, config)
		config = config or {}
		local settingsName = config.SettingsTabName or 'Settings'
		local configsName = config.ConfigsTabName or 'Configs'

		local reserved = {}
		reserved[settingsName] = true
		reserved[configsName] = true

		window._UserTabsFirst = window._UserTabsFirst ~= false

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
