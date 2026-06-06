--[[
	Auto-builds Settings + Configs tabs (HeavN-style) when attached from Library:CreateWindow.
]]

local BuiltInTabs = {} do
	BuiltInTabs.Library = nil
	BuiltInTabs.ThemeManager = nil
	BuiltInTabs.SaveManager = nil

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

		local showKeybinds = ui:AddToggle('Settings_ShowKeybinds', {
			Text = 'Show keybind list',
			Default = false,
		})
		showKeybinds:OnChanged(function()
			if lib.KeybindFrame then
				lib.KeybindFrame.Visible = showKeybinds.Value
			end
		end)
		if lib.KeybindFrame then
			lib.KeybindFrame.Visible = showKeybinds.Value
		end

		if config and config.Watermark ~= false then
			local wmToggle = ui:AddToggle('Settings_Watermark', {
				Text = 'Show watermark',
				Default = true,
			})
			wmToggle:OnChanged(function()
				lib:SetWatermarkVisibility(wmToggle.Value)
			end)
			lib:SetWatermarkVisibility(wmToggle.Value)
		end

		local tabPosDropdown = ui:AddDropdown('Settings_TabPosition', {
			Text = 'Tab position',
			Values = { 'Sidebar', 'Topbar' },
			Default = lib.TabPosition or 'Sidebar',
			Tooltip = 'Sidebar = left side (default)\nTopbar = tabs across the top',
		})
		tabPosDropdown:OnChanged(function()
			lib.TabPosition = tabPosDropdown.Value
			if self._window and self._window.SetTabPosition then
				self._window:SetTabPosition(tabPosDropdown.Value)
			end
		end)

		local cornerSlider = ui:AddSlider('Settings_UICorner', {
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

		local kbTransSlider = ui:AddSlider('Settings_KeybindTrans', {
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

		ui:AddDivider()

		ui:AddButton('Test notification', function()
			lib:Notify('HeavNLib', 'Sample notification — theme is live.', 4)
		end):AddButton('Unload', function()
			lib:Unload()
		end)

		-- Themes (right side) — all theme/appearance options live here
		if self.ThemeManager then
			local themeBox = tab:AddRightGroupbox('Themes')
			self.ThemeManager:CreateThemeManager(themeBox)
		else
			local themeBox = tab:AddRightGroupbox('Themes')
			themeBox:AddLabel('Accent'):AddColorPicker('AccentColor', { Default = lib.AccentColor })
			local accentPicker = opt('AccentColor')
			if accentPicker then
				accentPicker:OnChanged(function()
					lib.AccentColor = accentPicker.Value
					lib.AccentColorDark = lib:GetDarkerColor(lib.AccentColor)
					lib:UpdateColorsUsingRegistry()
				end)
			end
			themeBox:AddLabel('GUI text'):AddColorPicker('FontColor', { Default = lib.FontColor })
			local fontPicker = opt('FontColor')
			if fontPicker then
				fontPicker:OnChanged(function()
					lib.FontColor = fontPicker.Value
					lib:UpdateColorsUsingRegistry()
				end)
			end
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
		self._window = window
		local settingsName = config.SettingsTabName or 'Settings'
		local configsName = config.ConfigsTabName or 'Configs'

		local settingsTab = window:AddTab(settingsName)
		local configsTab = window:AddTab(configsName)

		self:BuildSettingsTab(settingsTab, config)
		self:BuildConfigsTab(configsTab)

		-- Apply initial tab position from config/library
		if window.SetTabPosition then
			window:SetTabPosition(config.TabPosition or self.Library.TabPosition or 'Sidebar')
		end

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
