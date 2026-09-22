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
	SaveManager.UseConfirmDialogs = true
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
		if typeof(gui) ~= 'Instance' or not gui.Parent then
			return onConfirm()
		end

		local okBuild, errBuild = pcall(function()
			local host = Lib._ConfirmHost
			if typeof(host) ~= 'Instance' or not host.Parent then
				host = Instance.new('ScreenGui')
				host.Name = 'ZilkConfirmHost'
				host.ResetOnSpawn = false
				host.IgnoreGuiInset = true
				host.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				host.DisplayOrder = math.max((tonumber(gui.DisplayOrder) or 0) + 100, 1000000)
				host.Parent = gui.Parent or gui
				Lib._ConfirmHost = host
			else
				host.DisplayOrder = math.max((tonumber(gui.DisplayOrder) or 0) + 100, 1000000)
			end

			for _, root in ipairs({ host, gui }) do
				local stale = root:FindFirstChild('Zilk_ConfigConfirmOverlay')
				if stale then
					stale:Destroy()
				end
			end

			local accent = (Lib and Lib.AccentColor) or Color3.fromRGB(220, 38, 38)
			local main = (Lib and Lib.MainColor) or Color3.fromRGB(28, 28, 28)
			local outline = (Lib and Lib.OutlineColor) or Color3.fromRGB(50, 50, 50)
			local fontColor = (Lib and Lib.FontColor) or Color3.fromRGB(240, 240, 240)
			local buttonColor = (Lib and Lib.ButtonColor) or Color3.fromRGB(40, 40, 40)
			local font = (Lib and Lib.Font) or Enum.Font.GothamBold

			local overlay = Instance.new('TextButton')
			overlay.Name = 'Zilk_ConfigConfirmOverlay'
			overlay.AutoButtonColor = false
			overlay.Text = ''
			overlay.Size = UDim2.fromScale(1, 1)
			overlay.BackgroundColor3 = Color3.new(0, 0, 0)
			overlay.BackgroundTransparency = 0.35
			overlay.BorderSizePixel = 0
			overlay.ZIndex = 1000
			overlay.Active = true
			overlay.Modal = true
			overlay.Parent = host

			local panel = Instance.new('Frame')
			panel.Name = 'Panel'
			panel.AnchorPoint = Vector2.new(0.5, 0.5)
			panel.Position = UDim2.fromScale(0.5, 0.5)
			panel.Size = UDim2.fromOffset(420, 180)
			panel.BackgroundColor3 = main
			panel.BorderColor3 = outline
			panel.BorderSizePixel = 1
			panel.ZIndex = 1001
			panel.Parent = overlay

			local accentBar = Instance.new('Frame')
			accentBar.BackgroundColor3 = accent
			accentBar.BorderSizePixel = 0
			accentBar.Size = UDim2.new(1, 0, 0, 2)
			accentBar.ZIndex = 1002
			accentBar.Parent = panel

			local titleLabel = Instance.new('TextLabel')
			titleLabel.BackgroundTransparency = 1
			titleLabel.Position = UDim2.fromOffset(12, 12)
			titleLabel.Size = UDim2.new(1, -24, 0, 24)
			titleLabel.Font = font
			titleLabel.TextSize = 16
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.TextColor3 = accent
			titleLabel.Text = tostring(title or 'Confirm')
			titleLabel.ZIndex = 1002
			titleLabel.Parent = panel

			local bodyLabel = Instance.new('TextLabel')
			bodyLabel.BackgroundTransparency = 1
			bodyLabel.Position = UDim2.fromOffset(12, 44)
			bodyLabel.Size = UDim2.new(1, -24, 0, 70)
			bodyLabel.Font = font
			bodyLabel.TextSize = 14
			bodyLabel.TextWrapped = true
			bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
			bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
			bodyLabel.TextColor3 = fontColor
			bodyLabel.Text = tostring(message or '')
			bodyLabel.ZIndex = 1002
			bodyLabel.Parent = panel

			local function makeBtn(text, xScale)
				local btn = Instance.new('TextButton')
				btn.AutoButtonColor = true
				btn.Size = UDim2.new(0.45, 0, 0, 28)
				btn.Position = UDim2.new(xScale, 0, 1, -40)
				btn.BackgroundColor3 = buttonColor
				btn.BorderColor3 = outline
				btn.BorderSizePixel = 1
				btn.Font = font
				btn.TextSize = 14
				btn.TextColor3 = fontColor
				btn.Text = text
				btn.ZIndex = 1003
				btn.Parent = panel
				return btn
			end

			local cancel = makeBtn('Cancel', 0.04)
			local confirmBtn = makeBtn('Confirm', 0.51)

			local function close()
				if overlay.Parent then
					overlay:Destroy()
				end
			end

			cancel.MouseButton1Click:Connect(close)
			confirmBtn.MouseButton1Click:Connect(function()
				close()
				if type(onConfirm) == 'function' then
					pcall(onConfirm)
				end
			end)
		end)

		if not okBuild then
			warn('[ZilkLib] Confirm dialog failed:', errBuild)
			if Lib and Lib.Notify then
				pcall(Lib.Notify, Lib, 'Confirm dialog failed — running action anyway', 3)
			end
			return onConfirm()
		end
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
			name = trimName(name)
			local function doCreate()
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
			end
			local path = self:GetSettingsFolder() .. '/' .. name .. '.json'
			if isfile(path) then
				return self:Confirm(
					'Overwrite config',
					string.format('Config %q already exists. Overwrite it?', name),
					doCreate
				)
			end
			doCreate()
		end):AddButton('Load config', function()
			local o = getOptions()
			local name = (o.SaveManager_ConfigList and o.SaveManager_ConfigList.Value)
				or (o.SaveManager_ConfigName and o.SaveManager_ConfigName.Value)
			if not name or name:gsub(' ', '') == '' then
				return self.Library:Notify('Select a config', 2)
			end
			name = trimName(name)
			self:Confirm(
				'Load config',
				string.format('Load config %q? Unsaved changes will be lost.', name),
				function()
					local success, err = self:Load(name)
					if not success then
						return self.Library:Notify('Failed to load config: ' .. tostring(err))
					end
					self.Library:Notify(string.format('Loaded config %q', name))
					if self.AutoloadLabel then
						self.AutoloadLabel:SetText('Loaded: ' .. name)
					end
				end
			)
		end)

		section:AddButton('Overwrite config', function()
			local o = getOptions()
			local name = o.SaveManager_ConfigList and o.SaveManager_ConfigList.Value
			if not name then
				return self.Library:Notify('Select a config from the list', 2)
			end
			name = trimName(name)
			self:Confirm(
				'Overwrite config',
				string.format('Overwrite config %q with current settings?', name),
				function()
					local success, err = self:Save(name)
					if not success then
						return self.Library:Notify('Failed: ' .. tostring(err))
					end
					self.Library:Notify(string.format('Overwrote config %q', name))
				end
			)
		end)

		section:AddButton('Delete config', function()
			local o = getOptions()
			local name = o.SaveManager_ConfigList and o.SaveManager_ConfigList.Value
			if not name then
				return self.Library:Notify('Select a config', 2)
			end
			name = trimName(name)
			self:Confirm(
				'Delete config',
				string.format('Delete config %q permanently?', name),
				function()
					local success, err = self:Delete(name)
					if not success then
						return self.Library:Notify('Delete failed: ' .. tostring(err))
					end
					self.Library:Notify('Deleted ' .. name)
					o.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
					o.SaveManager_ConfigList:SetValue(nil)
				end
			)
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
			name = trimName(name)
			self:Confirm(
				'Set autoload',
				string.format('Auto-load config %q on startup?', name),
				function()
					self:BuildFolderTree()
					local ok, err = pcall(writefile, self:GetSettingsFolder() .. '/autoload.txt', name)
					if not ok then
						return self.Library:Notify('Failed to set autoload: ' .. tostring(err))
					end
					if self.AutoloadLabel then
						self.AutoloadLabel:SetText('Current autoload config: ' .. name)
					end
					self.Library:Notify(string.format('Set %q to auto load', name))
				end
			)
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
