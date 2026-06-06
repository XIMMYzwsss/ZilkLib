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

		ui:AddDivider()

		ui:AddButton('Test notification', function()
			lib:Notify('HeavNLib', 'Sample notification — theme is live.', 4)
		end):AddButton('Unload', function()
			lib:Unload()
		end)

		if self.SaveManager then
			self.SaveManager:BuildConfigSection(tab)
		end

		if self.ThemeManager then
			local themeBox = tab:AddRightGroupbox('Themes')
			local themeSaveBox = tab:AddRightGroupbox('Theme Configs')
			self.ThemeManager:CreateThemeManager(themeBox, themeSaveBox)
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

	function BuiltInTabs:Attach(window, config)
		config = config or {}
		self._window = window
		local settingsName = config.SettingsTabName or 'Settings'

		local settingsTab = window:AddTab(settingsName)

		self:BuildSettingsTab(settingsTab, config)

		if window.SetTabPosition then
			window:SetTabPosition(config.TabPosition or self.Library.TabPosition or 'Sidebar')
		end

		window.Tabs.Settings = settingsTab
		window.Tabs[settingsName] = settingsTab

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
