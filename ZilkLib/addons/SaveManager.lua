local HttpService = game:GetService('HttpService')

local function getToggles()
	return (getgenv and rawget(getgenv(), 'Toggles')) or Toggles
end

local function getOptions()
	return (getgenv and rawget(getgenv(), 'Options')) or Options
end

local function trimName(name)
	return tostring(name or ''):gsub('[%s%z\r\n]+$', '')
end

local function configFileName(path)
	path = tostring(path):gsub('\\', '/')
	return path:match('([^/]+)%.json$')
end

local SaveManager = {} do
	SaveManager.Folder = 'Zilk'
	SaveManager.UseConfirmDialogs = false
	SaveManager.Ignore = {}
	SaveManager.LoadedConfigName = nil

	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object)
				return { type = 'Toggle', idx = idx, value = object.Value }
			end,
			Load = function(idx, data)
				local t = getToggles()
				if t and t[idx] then
					t[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				local o = getOptions()
				if o and o[idx] then
					o[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
			end,
			Load = function(idx, data)
				local o = getOptions()
				if o and o[idx] then
					o[idx]:SetValue(data.value)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				local o = getOptions()
				if o and o[idx] then
					o[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				local o = getOptions()
				if o and o[idx] then
					o[idx]:SetValue({ data.key, data.mode })
				end
			end,
		},
		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				local o = getOptions()
				if o and o[idx] and type(data.text) == 'string' then
					o[idx]:SetValue(data.text)
				end
			end,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:SetConfigPath(folder)
		self:SetFolder(folder)
	end

	function SaveManager:GetSettingsFolder()
		return self.Folder .. '/settings'
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. '/themes',
			self.Folder .. '/settings',
		}
		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				pcall(makefolder, str)
			end
		end
	end

	function SaveManager:Save(name)
		name = trimName(name)
		if name == '' then
			return false, 'no config file is selected'
		end
		self:BuildFolderTree()
		local fullPath = self:GetSettingsFolder() .. '/' .. name .. '.json'
		local data = { objects = {} }
		local toggles = getToggles() or {}
		local options = getOptions() or {}

		for idx, toggle in next, toggles do
			if self.Ignore[idx] then
				continue
			end
			if not self.Parser[toggle.Type] then
				continue
			end
			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end
		for idx, option in next, options do
			if not self.Parser[option.Type] then
				continue
			end
			if self.Ignore[idx] then
				continue
			end
			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end

		local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
		if not success then
			return false, 'failed to encode data'
		end
		local ok, err = pcall(writefile, fullPath, encoded)
		if not ok then
			return false, tostring(err)
		end
		self.LoadedConfigName = name
		return true
	end

	function SaveManager:Load(name)
		name = trimName(name)
		if name == '' then
			return false, 'no config file is selected'
		end
		local file = self:GetSettingsFolder() .. '/' .. name .. '.json'
		if not isfile(file) then
			local legacy = self.Folder .. '/' .. name .. '.json'
			if isfile(legacy) then
				file = legacy
			else
				return false, 'invalid file'
			end
		end
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
		if not success then
			return false, 'decode error'
		end
		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(function()
					self.Parser[option.type].Load(option.idx, option)
				end)
			end
		end
		self.LoadedConfigName = name
		return true
	end

	function SaveManager:Delete(name)
		name = trimName(name)
		if name == '' then
			return false, 'no config'
		end
		local file = self:GetSettingsFolder() .. '/' .. name .. '.json'
		local legacy = self.Folder .. '/' .. name .. '.json'
		local removed = false
		if isfile(file) then
			pcall(delfile, file)
			removed = true
		end
		if isfile(legacy) then
			pcall(delfile, legacy)
			removed = true
		end
		if removed then
			if self.LoadedConfigName == name then
				self.LoadedConfigName = nil
			end
			return true
		end
		return false, 'file not found'
	end

	function SaveManager:IgnoreThemeSettings()
		if self.Library and self.Library.ThemeManager then
			self:SetIgnoreIndexes(self.Library.ThemeManager:GetIgnoreIndexes())
			return
		end
		self:SetIgnoreIndexes({
			'BackgroundColor', 'MainColor', 'AccentColor', 'OutlineColor', 'FontColor',
			'SectionColor', 'DropdownColor', 'ButtonColor',
			'VersionTextColor',
			'ThemeManager_ThemeList', 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
		})
	end

	function SaveManager:RefreshConfigList()
		self:BuildFolderTree()
		local out, seen = {}, {}
		local function addFrom(folder)
			local ok, list = pcall(listfiles, folder)
			if not ok or type(list) ~= 'table' then
				return
			end
			for i = 1, #list do
				local name = configFileName(list[i])
				if name and name ~= '' and not seen[name] then
					seen[name] = true
					table.insert(out, name)
				end
			end
		end
		addFrom(self:GetSettingsFolder())
		addFrom(self.Folder)
		table.sort(out)
		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:LoadAutoloadConfig()
		local paths = {
			self:GetSettingsFolder() .. '/autoload.txt',
			self.Folder .. '/autoload.txt',
		}
		local name
		for _, autoloadPath in ipairs(paths) do
			if isfile(autoloadPath) then
				name = trimName(readfile(autoloadPath))
				if name ~= '' then
					break
				end
			end
		end
		if not name or name == '' then
			return
		end
		local success, err = self:Load(name)
		if not success then
			return self.Library:Notify('Failed to load autoload config: ' .. tostring(err))
		end
		self.Library:Notify(string.format('Auto loaded config %q', name))
	end

	function SaveManager:Confirm(title, message, onConfirm)
		if not self.UseConfirmDialogs then
			return onConfirm()
		end
		local Lib = self.Library
		local gui = Lib and Lib.ScreenGui
		if typeof(gui) ~= 'Instance' then
			return onConfirm()
		end
		if gui:FindFirstChild('Zilk_ConfigConfirmOverlay') then
			return onConfirm()
		end

		local overlay = Instance.new('TextButton')
		overlay.Name = 'Zilk_ConfigConfirmOverlay'
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 0.42
		overlay.Text = ''
		overlay.ZIndex = 200000
		overlay.AutoButtonColor = false
		overlay.Parent = gui

		local panelOuter = Lib:Create('Frame', {
			Size = UDim2.new(0, 400, 0, 172);
			Position = UDim2.new(0.5, -200, 0.45, -86);
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			ZIndex = 200001;
			Parent = overlay;
		})
		local panel = Lib:Create('Frame', {
			Size = UDim2.new(1, -2, 1, -2);
			Position = UDim2.new(0, 1, 0, 1);
			BackgroundColor3 = Lib.MainColor;
			BorderColor3 = Lib.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			ZIndex = 200002;
			Parent = panelOuter;
		})
		if Lib.EnsureCorner then
			Lib:EnsureCorner(panelOuter)
			Lib:EnsureCorner(panel)
		end
		Lib:AddToRegistry(panel, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		})
		local accent = Lib:Create('Frame', {
			Size = UDim2.new(1, 0, 0, 2);
			BackgroundColor3 = Lib.AccentColor;
			BorderSizePixel = 0;
			ZIndex = 200003;
			Parent = panel;
		})
		Lib:AddToRegistry(accent, { BackgroundColor3 = 'AccentColor' })
		Lib:Create('TextLabel', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, -16, 0, 26);
			Position = UDim2.new(0, 8, 0, 8);
			Font = Lib.Font;
			TextSize = 16;
			TextColor3 = Lib.AccentColor;
			TextXAlignment = Enum.TextXAlignment.Left;
			Text = title;
			ZIndex = 200003;
			Parent = panel;
		})
		Lib:Create('TextLabel', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, -16, 0, 72);
			Position = UDim2.new(0, 8, 0, 38);
			Font = Lib.Font;
			TextSize = 14;
			TextColor3 = Lib.FontColor;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			Text = message;
			ZIndex = 200003;
			Parent = panel;
		})
		local row = Lib:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, -16, 0, 24);
			Position = UDim2.new(0, 8, 1, -36);
			ZIndex = 200003;
			Parent = panel;
		})
		local function makeDialogButton(text, position)
			local outer = Lib:Create('Frame', {
				BackgroundColor3 = Color3.new(0, 0, 0);
				BorderColor3 = Color3.new(0, 0, 0);
				Size = UDim2.new(0.48, 0, 0, 20);
				Position = position;
				ZIndex = 200004;
				Parent = row;
			})
			local inner = Lib:Create('Frame', {
				BackgroundColor3 = Lib.ButtonColor;
				BorderColor3 = Lib.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 1, 0);
				ZIndex = 200005;
				Parent = outer;
			})
			Lib:Create('TextLabel', {
				BackgroundTransparency = 1;
				Size = UDim2.new(1, 0, 1, 0);
				Text = text;
				TextColor3 = Lib.FontColor;
				Font = Lib.Font;
				TextSize = 14;
				ZIndex = 200006;
				Parent = inner;
			})
			local btn = Lib:Create('TextButton', {
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 1, 0);
				Text = '';
				ZIndex = 200007;
				Parent = outer;
			})
			Lib:AddToRegistry(outer, { BorderColor3 = 'Black' })
			Lib:AddToRegistry(inner, {
				BackgroundColor3 = 'ButtonColor';
				BorderColor3 = 'OutlineColor';
			})
			Lib:OnHighlight(outer, outer, { BorderColor3 = 'AccentColor' }, { BorderColor3 = 'Black' })
			return btn
		end
		local cancel = makeDialogButton('Cancel', UDim2.new(0, 0, 0.5, -10))
		local ok = makeDialogButton('Confirm', UDim2.new(0.52, 0, 0.5, -10))
		local function close()
			if overlay.Parent then
				overlay:Destroy()
			end
		end
		cancel.MouseButton1Click:Connect(close)
		ok.MouseButton1Click:Connect(function()
			close()
			pcall(onConfirm)
		end)
	end

	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')
		local section = tab:AddLeftGroupbox('Configuration')
		local opts = getOptions()

		section:AddInput('SaveManager_ConfigName', { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', {
			Text = 'Config list',
			Values = self:RefreshConfigList(),
			AllowNull = true,
		})
		section:AddDivider()

		section:AddButton('Create config', function()
			local o = getOptions()
			local name = o and o.SaveManager_ConfigName and o.SaveManager_ConfigName.Value
			if not name or name:gsub(' ', '') == '' then
				return self.Library:Notify('Invalid config name (empty)', 2)
			end
			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to save config: ' .. tostring(err))
			end
			self.Library:Notify(string.format('Created config %q', name))
			o.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			o.SaveManager_ConfigList:SetValue(nil)
			if self.AutoloadLabel then
				self.AutoloadLabel:SetText('Loaded: ' .. name)
			end
		end):AddButton('Load config', function()
			local o = getOptions()
			local name = (o.SaveManager_ConfigList and o.SaveManager_ConfigList.Value)
				or (o.SaveManager_ConfigName and o.SaveManager_ConfigName.Value)
			if not name or name:gsub(' ', '') == '' then
				return self.Library:Notify('Select a config', 2)
			end
			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load config: ' .. tostring(err))
			end
			self.Library:Notify(string.format('Loaded config %q', name))
			if self.AutoloadLabel then
				self.AutoloadLabel:SetText('Loaded: ' .. name)
			end
		end)

		section:AddButton('Overwrite config', function()
			local o = getOptions()
			local name = o.SaveManager_ConfigList and o.SaveManager_ConfigList.Value
			if not name then
				return self.Library:Notify('Select a config from the list', 2)
			end
			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed: ' .. tostring(err))
			end
			self.Library:Notify(string.format('Overwrote config %q', name))
		end)

		section:AddButton('Delete config', function()
			local o = getOptions()
			local name = o.SaveManager_ConfigList and o.SaveManager_ConfigList.Value
			if not name then
				return self.Library:Notify('Select a config', 2)
			end
			local success, err = self:Delete(name)
			if not success then
				return self.Library:Notify('Delete failed: ' .. tostring(err))
			end
			self.Library:Notify('Deleted ' .. name)
			o.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			o.SaveManager_ConfigList:SetValue(nil)
		end)

		section:AddButton('Refresh list', function()
			local o = getOptions()
			o.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			o.SaveManager_ConfigList:SetValue(nil)
		end)

		section:AddButton('Set as autoload', function()
			local o = getOptions()
			local name = o.SaveManager_ConfigList and o.SaveManager_ConfigList.Value
			if not name then
				return
			end
			self:BuildFolderTree()
			local ok, err = pcall(writefile, self:GetSettingsFolder() .. '/autoload.txt', name)
			if not ok then
				return self.Library:Notify('Failed to set autoload: ' .. tostring(err))
			end
			if self.AutoloadLabel then
				self.AutoloadLabel:SetText('Current autoload config: ' .. name)
			end
			self.Library:Notify(string.format('Set %q to auto load', name))
		end)

		self.AutoloadLabel = section:AddLabel('Current autoload config: none', true)
		local autoPath = self:GetSettingsFolder() .. '/autoload.txt'
		local legacyAuto = self.Folder .. '/autoload.txt'
		if isfile(autoPath) then
			self.AutoloadLabel:SetText('Current autoload config: ' .. trimName(readfile(autoPath)))
		elseif isfile(legacyAuto) then
			self.AutoloadLabel:SetText('Current autoload config: ' .. trimName(readfile(legacyAuto)))
		end
		if self.LoadedConfigName then
			self.AutoloadLabel:SetText('Loaded: ' .. self.LoadedConfigName)
		end
		self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
