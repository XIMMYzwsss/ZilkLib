local HttpService = game:GetService('HttpService')

local function opt(idx)
	local ge = getgenv()
	return ge and ge.Options and ge.Options[idx]
end

local ThemeManager = {} do
	ThemeManager.Folder = 'HeavNLib'
	ThemeManager.Library = nil
	ThemeManager.DefaultTheme = 'HeavN'
	ThemeManager._colorPickers = {}

	local function hexColors(tbl)
		return HttpService:JSONDecode(tbl)
	end

	ThemeManager.ColorFields = {
		'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor',
		'SectionColor', 'SliderColor', 'DropdownColor', 'ButtonColor',
		'ToggleOnColor', 'ToggleOffColor', 'VersionTextColor',
		'UIKeybindTextActiveColor', 'UIKeybindTextInactiveColor',
	}

	ThemeManager.BuiltInThemes = {
		['HeavN'] = { 1, hexColors('{"FontColor":"f0f0f0","MainColor":"0a0a0a","AccentColor":"9370db","BackgroundColor":"121212","OutlineColor":"232323","SectionColor":"141414","SliderColor":"9370db","DropdownColor":"1e1e1e","ButtonColor":"282828","ToggleOnColor":"ffffff","ToggleOffColor":"1e1e1e","VersionTextColor":"ff0000","UIKeybindTextActiveColor":"9370db","UIKeybindTextInactiveColor":"f0f0f0"}') },
		['Default'] = { 2, hexColors('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232","SectionColor":"181818","SliderColor":"0055ff","DropdownColor":"1e1e1e","ButtonColor":"282828","ToggleOnColor":"ffffff","ToggleOffColor":"1e1e1e","VersionTextColor":"ff4444","UIKeybindTextActiveColor":"0055ff","UIKeybindTextInactiveColor":"ffffff"}') },
		['BBot'] = { 3, hexColors('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414","SectionColor":"242424","SliderColor":"7e48a3","DropdownColor":"1e1e1e","ButtonColor":"303030","ToggleOnColor":"ffffff","ToggleOffColor":"1e1e1e","VersionTextColor":"ff6666","UIKeybindTextActiveColor":"7e48a3","UIKeybindTextInactiveColor":"ffffff"}') },
		['Tokyo Night'] = { 4, hexColors('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232","SectionColor":"1f1f2b","SliderColor":"6759b3","DropdownColor":"1e1e28","ButtonColor":"2a2a38","ToggleOnColor":"ffffff","ToggleOffColor":"1e1e1e","VersionTextColor":"c77dff","UIKeybindTextActiveColor":"6759b3","UIKeybindTextInactiveColor":"ffffff"}') },
		['Mint'] = { 5, hexColors('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737","SectionColor":"202020","SliderColor":"3db488","DropdownColor":"1e1e1e","ButtonColor":"303030","ToggleOnColor":"ffffff","ToggleOffColor":"1e1e1e","VersionTextColor":"3db488","UIKeybindTextActiveColor":"3db488","UIKeybindTextInactiveColor":"ffffff"}') },
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]
		if not data then return end

		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			-- Skip non-color meta fields (handled below)
			if idx ~= '__Font' and idx ~= '__BGImageEnabled' and idx ~= '__BGImageAsset' then
				self.Library[idx] = Color3.fromHex(col)
				local picker = self._colorPickers[idx]
				if picker then
					picker:SetValueRGB(Color3.fromHex(col))
				end
			end
		end

		-- Apply font + background image meta if present
		if customThemeData then
			if customThemeData.__Font then
				self.Library:SetFontName(customThemeData.__Font)
				if self._fontDropdown then
					pcall(function() self._fontDropdown:SetValue(customThemeData.__Font) end)
				end
			end
			if customThemeData.__BGImageEnabled ~= nil then
				self.Library.UIBackgroundImageEnabled = customThemeData.__BGImageEnabled
				if self._bgImageToggle then
					pcall(function() self._bgImageToggle:SetValue(customThemeData.__BGImageEnabled) end)
				end
			end
			if customThemeData.__BGImageAsset ~= nil then
				self.Library.UIBackgroundImageAssetId = customThemeData.__BGImageAsset
				if self._bgAssetInput then
					pcall(function() self._bgAssetInput:SetValue(customThemeData.__BGImageAsset) end)
				end
			end
			pcall(function() self.Library:ApplyMainFrameBackground() end)
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		for _, field in next, self.ColorFields do
			local picker = self._colorPickers[field]
			if picker then
				self.Library[field] = picker.Value
			end
		end
		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
		self.Library:UpdateColorsUsingRegistry()
		if self.Library.RefreshAllCorners then
			self.Library:RefreshAllCorners()
		end
	end

	function ThemeManager:LoadDefault()
		local theme = self.DefaultTheme
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')
		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false
			end
		end
		if isDefault and self._themeList then
			self._themeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		self._colorPickers = {}

		local function addColor(label, field)
			local row = groupbox:AddLabel(label)
			local picker = row:AddColorPicker(field, { Default = self.Library[field] })
			picker = picker or opt(field)
			if picker and picker.OnChanged then
				self._colorPickers[field] = picker
				picker:OnChanged(function()
					self:ThemeUpdate()
				end)
			end
			return picker
		end

		addColor('Background color', 'BackgroundColor')
		addColor('Main color', 'MainColor')
		addColor('Section color', 'SectionColor')
		addColor('Accent color', 'AccentColor')
		addColor('Outline color', 'OutlineColor')
		addColor('Font color', 'FontColor')
		addColor('Slider color', 'SliderColor')
		addColor('Dropdown color', 'DropdownColor')
		addColor('Button color', 'ButtonColor')
		addColor('Toggle on', 'ToggleOnColor')
		addColor('Toggle off', 'ToggleOffColor')
		addColor('Keybind active', 'UIKeybindTextActiveColor')
		addColor('Keybind inactive', 'UIKeybindTextInactiveColor')

		-- Font (part of theme)
		groupbox:AddDivider()
		local FONT_LIST = { 'Gotham', 'GothamBold', 'GothamMedium', 'GothamBlack', 'SourceSans', 'SourceSansBold', 'Code', 'Roboto', 'RobotoMono' }
		groupbox:AddDropdown('ThemeManager_Font', {
			Text = 'Font',
			Values = FONT_LIST,
			Default = self.Library.FontName or 'GothamBold',
		})
		local fontDropdown = opt('ThemeManager_Font')
		self._fontDropdown = fontDropdown
		if fontDropdown and fontDropdown.OnChanged then
			fontDropdown:OnChanged(function()
				self.Library:SetFontName(fontDropdown.Value)
			end)
		end

		-- Background image (part of theme)
		groupbox:AddDivider()
		local bgImageToggle = groupbox:AddToggle('ThemeManager_BGImage', {
			Text = 'Background image',
			Default = self.Library.UIBackgroundImageEnabled,
		})
		self._bgImageToggle = bgImageToggle
		bgImageToggle:OnChanged(function()
			self.Library.UIBackgroundImageEnabled = bgImageToggle.Value
			self.Library:ApplyMainFrameBackground()
		end)

		local bgAssetInput = groupbox:AddInput('ThemeManager_BGAsset', {
			Text = 'Texture id / URL',
			Default = self.Library.UIBackgroundImageAssetId or '',
			Placeholder = 'rbxassetid://123456 or URL',
			Finished = true,
		})
		self._bgAssetInput = bgAssetInput
		bgAssetInput:OnChanged(function()
			self.Library.UIBackgroundImageAssetId = bgAssetInput.Value
			self.Library:ApplyMainFrameBackground()
		end)

		local ThemesArray = {}
		for Name in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end
		table.sort(ThemesArray, function(a, b)
			return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
		end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })
		local themeList = opt('ThemeManager_ThemeList')
		self._themeList = themeList

		if themeList then
			groupbox:AddButton('Set as default', function()
				self:SaveDefault(themeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', themeList.Value))
			end)

			themeList:OnChanged(function()
				self:ApplyTheme(themeList.Value)
			end)
		end

		groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		local customName = opt('ThemeManager_CustomThemeName')
		local customList = opt('ThemeManager_CustomThemeList')
		groupbox:AddDivider()

		groupbox:AddButton('Save theme', function()
			if customName then self:SaveCustomTheme(customName.Value) end
			if customList then
				customList:SetValues(self:ReloadCustomThemes())
				customList:SetValue(nil)
			end
		end):AddButton('Load theme', function()
			if customList then self:ApplyTheme(customList.Value) end
		end)

		groupbox:AddButton('Refresh list', function()
			if customList then
				customList:SetValues(self:ReloadCustomThemes())
				customList:SetValue(nil)
			end
		end)

		groupbox:AddButton('Set custom default', function()
			if customList and customList.Value then
				self:SaveDefault(customList.Value)
				self.Library:Notify(string.format('Set default theme to %q', customList.Value))
			end
		end)

		ThemeManager:LoadDefault()
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			if isfile(path .. '.json') then path = path .. '.json' else return nil end
		end
		local data = readfile(path)
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		return success and decoded or nil
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end
		local theme = {}
		for _, field in next, self.ColorFields do
			local picker = self._colorPickers[field]
			if picker then
				theme[field] = picker.Value:ToHex()
			end
		end
		-- Save font + background image as part of the theme
		theme.__Font = self.Library.FontName
		theme.__BGImageEnabled = self.Library.UIBackgroundImageEnabled
		theme.__BGImageAsset = self.Library.UIBackgroundImageAssetId
		writefile(self.Folder .. '/themes/' .. file .. '.json', HttpService.JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')
		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end
				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, file:find('.json', 1, true) - 1))
				end
			end
		end
		return out
	end

	function ThemeManager:GetIgnoreIndexes()
		local out = {
			'ThemeManager_ThemeList', 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
			'ThemeManager_Font', 'ThemeManager_BGImage', 'ThemeManager_BGAsset',
		}
		for _, field in next, self.ColorFields do
			table.insert(out, field)
		end
		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}
		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end
		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')
		for i = 1, #paths do
			if not isfolder(paths[i]) then
				makefolder(paths[i])
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = tab:AddRightGroupbox('Themes')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
