local HttpService = game:GetService('HttpService')
local SaveManager = {} do
	SaveManager.Folder = 'Zilk/configs'
	SaveManager.UseConfirmDialogs = true
	SaveManager.Ignore = {}
	SaveManager.LoadedConfigName = nil
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object)
				return { type = 'Toggle', idx = idx, value = object.Value }
			end,
			Load = function(idx, data)
				if Toggles[idx] then Toggles[idx]:SetValue(data.value) end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValue(data.value) end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValue(data.value) end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency) end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValue({ data.key, data.mode }) end
			end,
		},
		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then Options[idx]:SetValue(data.text) end
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
	function SaveManager:BuildFolderTree()
		local paths = { self.Folder }
		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end
		for i = 1, #paths do
			if not isfolder(paths[i]) then
				makefolder(paths[i])
			end
		end
	end
	function SaveManager:Save(name)
		if not name then return false, 'no config file is selected' end
		local fullPath = self.Folder .. '/' .. name .. '.json'
		local data = { objects = {} }
		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end
		for idx, option in next, Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end
			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end
		local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
		if not success then return false, 'failed to encode data' end
		writefile(fullPath, encoded)
		self.LoadedConfigName = name
		return true
	end
	function SaveManager:Load(name)
		if not name then return false, 'no config file is selected' end
		local file = self.Folder .. '/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
		if not success then return false, 'decode error' end
		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(function() self.Parser[option.type].Load(option.idx, option) end)
			end
		end
		self.LoadedConfigName = name
		return true
	end
	function SaveManager:Delete(name)
		if not name then return false, 'no config' end
		local file = self.Folder .. '/' .. name .. '.json'
		if isfile(file) then
			delfile(file)
			if self.LoadedConfigName == name then self.LoadedConfigName = nil end
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
		local list = listfiles(self.Folder)
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
		table.sort(out)
		return out
	end
	function SaveManager:SetLibrary(library)
		self.Library = library
	end
	function SaveManager:LoadAutoloadConfig()
		local autoloadPath = self.Folder .. '/autoload.txt'
		if isfile(autoloadPath) then
			local name = readfile(autoloadPath)
			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load autoload config: ' .. tostring(err))
			end
			self.Library:Notify(string.format('Auto loaded config %q', name))
		end
	end
	function SaveManager:Confirm(title, message, onConfirm)
		if not self.UseConfirmDialogs then
			return onConfirm()
		end
		local Lib = self.Library
		local gui = Lib.ScreenGui
		if gui:FindFirstChild('Zilk_ConfigConfirmOverlay') then return end

		local overlay = Instance.new('TextButton')
		overlay.Name = 'Zilk_ConfigConfirmOverlay'
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 0.42
		overlay.Text = ''
		overlay.ZIndex = 200000
		overlay.AutoButtonColor = false
		overlay.Parent = gui

		-- Outer black rim + inset outline = same Linoria 3D look as main menu
		local panelOuter = Lib:Create('Frame', {
			Size = UDim2.new(0, 400, 0, 172);
			Position = UDim2.new(0.5, -200, 0.45, -86);
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			ZIndex = 200001;
			Parent = overlay;
		})

		local panel = Lib:Create('Frame', {
			Size = UDim2.new(1, 0, 1, 0);
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

		local ttl = Instance.new('TextLabel')
		ttl.BackgroundTransparency = 1
		ttl.Size = UDim2.new(1, -16, 0, 26)
		ttl.Position = UDim2.new(0, 8, 0, 8)
		ttl.Font = Lib.Font
		ttl.TextSize = 16
		ttl.TextColor3 = Lib.AccentColor
		ttl.TextXAlignment = Enum.TextXAlignment.Left
		ttl.Text = title
		ttl.ZIndex = 200003
		ttl.Parent = panel

		local body = Instance.new('TextLabel')
		body.BackgroundTransparency = 1
		body.Size = UDim2.new(1, -16, 0, 72)
		body.Position = UDim2.new(0, 8, 0, 38)
		body.Font = Lib.Font
		body.TextSize = 14
		body.TextColor3 = Lib.FontColor
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.Text = message
		body.ZIndex = 200003
		body.Parent = panel

		local row = Instance.new('Frame')
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -16, 0, 28)
		row.Position = UDim2.new(0, 8, 1, -40)
		row.ZIndex = 200003
		row.Parent = panel

		local function makeDialogButton(text, position)
			-- Same Outer/Inner bevel as Library AddButton (no UICorner — it kills BorderSizePixel).
			local outer = Lib:Create('Frame', {
				BackgroundColor3 = Color3.new(0, 0, 0);
				BorderColor3 = Color3.new(0, 0, 0);
				Size = UDim2.new(0.48, 0, 1, 0);
				Position = position;
				ZIndex = 200004;
				Parent = row;
			})

			local inner = Lib:Create('Frame', {
				BackgroundColor3 = Lib.ButtonColor or Lib.MainColor;
				BorderColor3 = Lib.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 1, 0);
				ZIndex = 200005;
				Parent = outer;
			})

			local btn = Lib:Create('TextButton', {
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 1, 0);
				Text = text;
				TextColor3 = Lib.FontColor;
				Font = Lib.Font;
				TextSize = 14;
				AutoButtonColor = false;
				ZIndex = 200006;
				Parent = inner;
			})

			Lib:AddToRegistry(outer, { BorderColor3 = 'Black' })
			Lib:AddToRegistry(inner, {
				BackgroundColor3 = 'ButtonColor';
				BorderColor3 = 'OutlineColor';
			})
			Lib:OnHighlight(outer, outer,
				{ BorderColor3 = 'AccentColor' },
				{ BorderColor3 = 'Black' }
			)

			return btn
		end

		local cancel = makeDialogButton('Cancel', UDim2.new(0, 0, 0, 0))
		local ok = makeDialogButton('Confirm', UDim2.new(0.52, 0, 0, 0))

		local function close()
			if overlay.Parent then overlay:Destroy() end
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
		section:AddInput('SaveManager_ConfigName', { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })
		section:AddDivider()
		section:AddButton('Create config', function()
			local name = Options.SaveManager_ConfigName.Value
			if name:gsub(' ', '') == '' then return self.Library:Notify('Invalid config name (empty)', 2) end
			self:Confirm('Save config', 'Save config "' .. name .. '"?', function()
				local success, err = self:Save(name)
				if not success then return self.Library:Notify('Failed to save config: ' .. tostring(err)) end
				self.Library:Notify(string.format('Created config %q', name))
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
				if self.AutoloadLabel then self.AutoloadLabel:SetText('Loaded: ' .. name) end
			end)
		end):AddButton('Load config', function()
			local name = Options.SaveManager_ConfigList.Value or Options.SaveManager_ConfigName.Value
			if not name or name:gsub(' ', '') == '' then return self.Library:Notify('Select a config', 2) end
			self:Confirm('Load config', 'Load "' .. name .. '"? Current settings will be replaced.', function()
				local success, err = self:Load(name)
				if not success then return self.Library:Notify('Failed to load config: ' .. tostring(err)) end
				self.Library:Notify(string.format('Loaded config %q', name))
				if self.AutoloadLabel then self.AutoloadLabel:SetText('Loaded: ' .. name) end
			end)
		end)
		section:AddButton('Overwrite config', function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('Select a config from the list', 2) end
			self:Confirm('Overwrite config', 'Overwrite "' .. name .. '"?', function()
				local success, err = self:Save(name)
				if not success then return self.Library:Notify('Failed: ' .. tostring(err)) end
				self.Library:Notify(string.format('Overwrote config %q', name))
			end)
		end)
		section:AddButton('Delete config', function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('Select a config', 2) end
			self:Confirm('Delete config', 'Delete "' .. name .. '" permanently?', function()
				local success, err = self:Delete(name)
				if not success then return self.Library:Notify('Delete failed: ' .. tostring(err)) end
				self.Library:Notify('Deleted ' .. name)
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
				if self.AutoloadLabel then self.AutoloadLabel:SetText('Current autoload config: ' .. (readfile(self.Folder .. '/autoload.txt') or 'none')) end
			end)
		end)
		section:AddButton('Refresh list', function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end)
		section:AddButton('Set as autoload', function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then return end
			writefile(self.Folder .. '/autoload.txt', name)
			if self.AutoloadLabel then self.AutoloadLabel:SetText('Current autoload config: ' .. name) end
			self.Library:Notify(string.format('Set %q to auto load', name))
		end)
		self.AutoloadLabel = section:AddLabel('Current autoload config: none', true)
		if isfile(self.Folder .. '/autoload.txt') then
			self.AutoloadLabel:SetText('Current autoload config: ' .. readfile(self.Folder .. '/autoload.txt'))
		end
		if self.LoadedConfigName then
			self.AutoloadLabel:SetText('Loaded: ' .. self.LoadedConfigName)
		end
		self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
	end
	SaveManager:BuildFolderTree()
end
return SaveManager