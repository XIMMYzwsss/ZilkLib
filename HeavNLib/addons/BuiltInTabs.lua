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

		if self.ThemeManager then
			self.ThemeManager:CreateThemeManager(tab:AddLeftGroupbox('Themes'))
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
			Default = true,
		})
		showKeybinds:OnChanged(function()
			if lib.KeybindFrame then
				lib.KeybindFrame.Visible = showKeybinds.Value
			end
		end)

		local bgImageToggle = layout:AddToggle('Settings_BGImage', {
			Text = 'Main background image',
			Default = lib.UIBackgroundImageEnabled,
		})
		bgImageToggle:OnChanged(function()
			lib.UIBackgroundImageEnabled = bgImageToggle.Value
			lib:ApplyMainFrameBackground()
		end)

		local bgAssetInput = layout:AddInput('Settings_BGAsset', {
			Text = 'Background asset id / URL',
			Default = lib.UIBackgroundImageAssetId or '',
			Finished = true,
		})
		bgAssetInput:OnChanged(function()
			lib.UIBackgroundImageAssetId = bgAssetInput.Value
			lib:ApplyMainFrameBackground()
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

		local pathBox = tab:AddRightGroupbox('Storage')
		pathBox:AddLabel('Config folder:')
		pathBox:AddLabel(self.SaveManager.Folder, true)
		local pathInput = pathBox:AddInput('Configs_CustomPath', {
			Text = 'Set config path (folder)',
			Default = self.SaveManager.Folder,
			Finished = true,
		})
		pathBox:AddButton('Apply path', function()
			local path = pathInput.Value
			if path:gsub(' ', '') == '' then
				return self.Library:Notify('Invalid path', 2)
			end
			self.SaveManager:SetConfigPath(path)
			local list = opt('SaveManager_ConfigList')
			if list then
				list:SetValues(self.SaveManager:RefreshConfigList())
			end
			self.Library:Notify('Config path: ' .. path)
		end)
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
