--[[
	ZilkLib v1.0
	Author: XIMMYzwsss
	API: https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/refs/heads/main/Lib.lua
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Library = {}
Library.__index = Library

-- Global tables for saving/loading
local Toggles = {}
local Options = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

Library.ConfigFolder = nil  -- set by user

-- Utility
local function protectGui(gui)
	pcall(function()
		if protectgui then protectgui(gui) end
		if syn and syn.protect_gui then syn.protect_gui(gui) end
	end)
end

local function create(className, properties)
	local inst = Instance.new(className)
	for k, v in pairs(properties) do
		inst[k] = v
	end
	return inst
end

local function addStroke(obj, color, thickness)
	local stroke = create("UIStroke", {
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	})
	stroke.Parent = obj
	return stroke
end

local function getTextSize(text, font, size)
	local vec = TextService:GetTextSize(text, size or 14, font or Enum.Font.GothamBold, Vector2.new(1920, 1080))
	return vec.X, vec.Y
end

-- Window creation
function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Zilk"
	local position = config.Position or UDim2.new(0, 175, 0, 50)
	local size = config.Size or UDim2.new(0, 550, 0, 600)
	local accent = config.AccentColor or Color3.fromRGB(147, 112, 219)
	local mainColor = config.MainColor or Color3.fromRGB(20, 20, 20)
	local textColor = config.TextColor or Color3.fromRGB(240, 240, 240)

	local ScreenGui = create("ScreenGui", {
		Name = "ZilkGUI",
		Parent = CoreGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	})
	protectGui(ScreenGui)

	local window = setmetatable({
		Gui = ScreenGui,
		Tabs = {},
		AccentColor = accent,
		MainColor = mainColor,
		TextColor = textColor,
		ConfigFolder = nil,
	}, Library)

	-- Main frame
	local main = create("Frame", {
		Name = "Main",
		Size = size,
		Position = position,
		BackgroundColor3 = mainColor,
		BorderSizePixel = 0,
		Parent = ScreenGui,
	})

	local stroke = addStroke(main, accent, 2)

	-- Title bar
	local titleBar = create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = main,
	})
	local titleLabel = create("TextLabel", {
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 5, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = textColor,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleBar,
	})
	addStroke(titleLabel)

	-- Tab container
	local tabContainer = create("Frame", {
		Name = "TabContainer",
		Size = UDim2.new(0, 120, 1, -30),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = main,
	})
	local tabList = create("UIListLayout", {
		Padding = UDim.new(0, 2),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabContainer,
	})

	-- Page container
	local pageContainer = create("Frame", {
		Name = "PageContainer",
		Size = UDim2.new(1, -120, 1, -30),
		Position = UDim2.new(0, 120, 0, 30),
		BackgroundTransparency = 1,
		Parent = main,
	})

	-- Functions for tabs
	local tabCount = 0
	function window:AddTab(name)
		tabCount = tabCount + 1
		local tabButton = create("TextButton", {
			Name = name,
			Size = UDim2.new(0.9, 0, 0, 30),
			BackgroundColor3 = tabCount == 1 and accent or Color3.fromRGB(30,30,30),
			TextColor3 = textColor,
			Text = name,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			BorderSizePixel = 0,
			Parent = tabContainer,
		})
		addStroke(tabButton)

		local page = create("ScrollingFrame", {
			Name = name .. "Page",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = accent,
			CanvasSize = UDim2.new(0, 0, 0, 1000),
			Parent = pageContainer,
		})
		local pageLayout = create("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})

		local groupBoxes = {}
		local tab = {
			Page = page,
			Layout = pageLayout,
		}

		function tab:AddGroupbox(titleText)
			local box = create("Frame", {
				Name = "Groupbox",
				Size = UDim2.new(0.95, 0, 0, 100),
				BackgroundColor3 = Color3.fromRGB(25,25,25),
				BorderSizePixel = 0,
				Parent = page,
			})
			local boxStroke = addStroke(box, accent, 1)
			local boxHeader = create("Frame", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = accent,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				Parent = box,
			})
			local boxTitle = create("TextLabel", {
				Size = UDim2.new(1, -6, 1, 0),
				Position = UDim2.new(0, 6, 0, 0),
				BackgroundTransparency = 1,
				Text = titleText,
				TextColor3 = textColor,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = boxHeader,
			})
			addStroke(boxTitle)
			local content = create("Frame", {
				Size = UDim2.new(1, -10, 1, -22),
				Position = UDim2.new(0, 5, 0, 22),
				BackgroundTransparency = 1,
				Parent = box,
			})
			local contentLayout = create("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = content,
			})
			box.Size = UDim2.new(0.95, 0, 0, contentLayout.AbsoluteContentSize.Y + 30)
			contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				box.Size = UDim2.new(0.95, 0, 0, contentLayout.AbsoluteContentSize.Y + 25)
			end)

			local group = {
				Content = content,
				Layout = contentLayout,
				Box = box,
			}

			-- Element adding methods
			function group:AddToggle(idx, info)
				local toggle = {
					Value = info.Default or false,
					Callback = info.Callback or function() end,
				}
				local labelText = info.Text or idx
				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 24),
					Text = "",
					BackgroundTransparency = 1,
					Parent = content,
				})
				local label = create("TextLabel", {
					Size = UDim2.new(1, -40, 1, 0),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = labelText,
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = btn,
				})
				addStroke(label)
				local track = create("Frame", {
					Size = UDim2.new(0, 30, 0, 14),
					Position = UDim2.new(1, -35, 0.5, -7),
					BackgroundColor3 = toggle.Value and accent or Color3.fromRGB(50,50,50),
					BorderSizePixel = 0,
					Parent = btn,
				})
				local knob = create("Frame", {
					Size = UDim2.new(0, 10, 0, 10),
					Position = UDim2.new(0, toggle.Value and 17 or 2, 0.5, -5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Parent = track,
				})
				local function updateVisuals()
					track.BackgroundColor3 = toggle.Value and accent or Color3.fromRGB(50,50,50)
					TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, toggle.Value and 17 or 2, 0.5, -5)}):Play()
				end
				btn.MouseButton1Click:Connect(function()
					toggle.Value = not toggle.Value
					updateVisuals()
					toggle.Callback(toggle.Value)
				end)
				toggle.UpdateVisuals = updateVisuals
				Toggles[idx] = toggle
				return toggle
			end

			function group:AddSlider(idx, info)
				local slider = {
					Value = info.Default,
					Min = info.Min,
					Max = info.Max,
					Callback = info.Callback or function() end,
				}
				local labelText = info.Text or idx
				local lbl = create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = labelText .. ": " .. tostring(slider.Value),
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = content,
				})
				addStroke(lbl)
				local sliderBar = create("Frame", {
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundColor3 = Color3.fromRGB(40,40,40),
					BorderSizePixel = 0,
					Parent = content,
				})
				local fill = create("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = accent,
					BorderSizePixel = 0,
					Parent = sliderBar,
				})
				local dragging = false
				local function updateFill(val)
					local ratio = math.clamp((val - slider.Min) / (slider.Max - slider.Min), 0, 1)
					fill.Size = UDim2.new(ratio, 0, 1, 0)
					lbl.Text = labelText .. ": " .. tostring(math.floor(val * 100) / 100)
				end
				updateFill(slider.Value)
				sliderBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						local function move()
							local rel = math.clamp((UserInputService:GetMouseLocation().X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
							local val = slider.Min + (slider.Max - slider.Min) * rel
							slider.Value = val
							updateFill(val)
							slider.Callback(val)
						end
						move()
						local conn
						conn = UserInputService.InputChanged:Connect(function(inp)
							if inp.UserInputType == Enum.UserInputType.MouseMovement then
								move()
							end
						end)
						local endConn
						endConn = UserInputService.InputEnded:Connect(function(inp)
							if inp.UserInputType == Enum.UserInputType.MouseButton1 then
								dragging = false
								conn:Disconnect()
								endConn:Disconnect()
							end
						end)
					end
				end)
				Options[idx] = slider
				return slider
			end

			function group:AddDropdown(idx, info)
				local dropdown = {
					Values = info.Values,
					Value = info.Default,
					Callback = info.Callback or function() end,
				}
				local labelText = info.Text or idx
				local lbl = create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = labelText,
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = content,
				})
				addStroke(lbl)
				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					Text = dropdown.Value,
					BackgroundColor3 = Color3.fromRGB(40,40,40),
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					Parent = content,
				})
				addStroke(btn)
				local list = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(20,20,20),
					Visible = false,
					Parent = btn,
				})
				local listLayout = create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = list,
				})
				local function rebuildList()
					for _, v in ipairs(list:GetChildren()) do
						if v:IsA("TextButton") then v:Destroy() end
					end
					for _, v in ipairs(dropdown.Values) do
						local optBtn = create("TextButton", {
							Size = UDim2.new(1, 0, 0, 20),
							Text = v,
							BackgroundTransparency = 1,
							TextColor3 = textColor,
							Font = Enum.Font.GothamBold,
							TextSize = 12,
							Parent = list,
						})
						optBtn.MouseButton1Click:Connect(function()
							dropdown.Value = v
							btn.Text = v
							list.Visible = false
							dropdown.Callback(v)
						end)
					end
					list.Size = UDim2.new(1, 0, 0, #dropdown.Values * 20)
				end
				btn.MouseButton1Click:Connect(function()
					list.Visible = not list.Visible
				end)
				rebuildList()
				Options[idx] = dropdown
				return dropdown
			end

			function group:AddKeybind(idx, info)
				local keybind = {
					Value = info.Default or Enum.KeyCode.LeftControl,
					Callback = info.Callback or function() end,
				}
				local labelText = info.Text or idx
				local lbl = create("TextLabel", {
					Size = UDim2.new(0.6, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = labelText,
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = content,
				})
				addStroke(lbl)
				local btn = create("TextButton", {
					Size = UDim2.new(0.4, 0, 0, 20),
					Position = UDim2.new(0.6, 0, 0, 0),
					Text = keybind.Value.Name,
					BackgroundColor3 = Color3.fromRGB(40,40,40),
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					Parent = content,
				})
				addStroke(btn)
				local waiting = false
				btn.MouseButton1Click:Connect(function()
					if waiting then return end
					waiting = true
					btn.Text = "..."
					local conn
					conn = UserInputService.InputBegan:Connect(function(input, gp)
						if gp then return end
						if input.UserInputType == Enum.UserInputType.Keyboard then
							keybind.Value = input.KeyCode
							btn.Text = input.KeyCode.Name
							keybind.Callback(input.KeyCode)
							waiting = false
							conn:Disconnect()
						end
					end)
				end)
				Options[idx] = keybind
				return keybind
			end

			function group:AddColorPicker(idx, info)
				local color = {
					Value = info.Default or Color3.fromRGB(255,255,255),
					Callback = info.Callback or function() end,
				}
				local labelText = info.Text or idx
				local lbl = create("TextLabel", {
					Size = UDim2.new(0.6, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = labelText,
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = content,
				})
				addStroke(lbl)
				local preview = create("TextButton", {
					Size = UDim2.new(0.4, 0, 0, 20),
					Position = UDim2.new(0.6, 0, 0, 0),
					Text = "",
					BackgroundColor3 = color.Value,
					BorderSizePixel = 0,
					Parent = content,
				})
				-- simple color popup (omitted for brevity, you can use a basic picker)
				preview.MouseButton1Click:Connect(function()
					-- In a real implementation you'd open a color picker here
					-- For simplicity we just cycle through some colors
					local r = math.random()
					local newCol = Color3.fromHSV(r, 1, 1)
					color.Value = newCol
					preview.BackgroundColor3 = newCol
					color.Callback(newCol)
				end)
				Options[idx] = color
				return color
			end

			function group:AddButton(info)
				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 24),
					Text = info.Text or "Button",
					BackgroundColor3 = accent,
					BackgroundTransparency = 0.2,
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					Parent = content,
				})
				addStroke(btn)
				btn.MouseButton1Click:Connect(function()
					if info.Callback then info.Callback() end
				end)
			end

			function group:AddLabel(text)
				local lbl = create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Parent = content,
				})
				addStroke(lbl)
			end

			function group:AddDivider()
				local div = create("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = accent,
					BackgroundTransparency = 0.5,
					Parent = content,
				})
			end

			table.insert(groupBoxes, group)
			return group
		end

		-- Tab switching
		tabButton.MouseButton1Click:Connect(function()
			for _, otherPage in ipairs(pageContainer:GetChildren()) do
				if otherPage:IsA("ScrollingFrame") then otherPage.Visible = false end
			end
			for _, otherBtn in ipairs(tabContainer:GetChildren()) do
				if otherBtn:IsA("TextButton") then
					otherBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
				end
			end
			page.Visible = true
			tabButton.BackgroundColor3 = accent
		end)
		if tabCount == 1 then
			tabButton.BackgroundColor3 = accent
			page.Visible = true
		end
		window.Tabs[name] = tab
		return tab
	end

	-- Add Settings and Config tabs automatically
	local settingsTab = window:AddTab("Settings")
	local settingsGroup = settingsTab:AddGroupbox("UI Settings")
	settingsGroup:AddKeybind("MenuKeybind", {
		Text = "Menu Keybind",
		Default = Enum.KeyCode.RightShift,
		Callback = function(key)
			-- User can manually handle toggling
		end,
	})
	settingsGroup:AddButton({
		Text = "Unload",
		Callback = function()
			window.Gui:Destroy()
		end,
	})

	local configTab = window:AddTab("Config")
	local configGroup = configTab:AddGroupbox("Config Manager")
	local configNameBox = nil
	local configListFrame = nil
	local function refreshConfigList()
		if not configListFrame then return end
		for _, v in ipairs(configListFrame:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end
		local folder = window.ConfigFolder
		if not folder then return end
		pcall(function() makefolder(folder) end)
		local files = listfiles(folder) or {}
		for _, file in ipairs(files) do
			local name = file:match("([^\\/]+)%.cfg$")
			if name then
				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					Text = name,
					BackgroundColor3 = Color3.fromRGB(40,40,40),
					TextColor3 = textColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					Parent = configListFrame,
				})
				btn.MouseButton1Click:Connect(function()
					if configNameBox then configNameBox.Text = name end
				end)
			end
		end
	end

	configNameBox = create("TextBox", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = Color3.fromRGB(40,40,40),
		TextColor3 = textColor,
		PlaceholderText = "Config name...",
		PlaceholderColor3 = Color3.fromRGB(120,120,120),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		ClearTextOnFocus = false,
		Parent = configGroup.Content,
	})

	configGroup:AddButton({
		Text = "Save",
		Callback = function()
			local name = configNameBox.Text
			if name == "" then return end
			local folder = window.ConfigFolder
			if not folder then return end
			-- save Toggles and Options
			local data = {Toggles = {}, Options = {}}
			for k, v in pairs(Toggles) do
				data.Toggles[k] = v.Value
			end
			for k, v in pairs(Options) do
				if v.Type == "Slider" or v.Type == "Dropdown" then
					data.Options[k] = v.Value
				elseif v.Type == "Keybind" then
					data.Options[k] = v.Value.Name
				elseif v.Type == "ColorPicker" then
					data.Options[k] = {v.Value.R, v.Value.G, v.Value.B}
				end
			end
			local json = game:GetService("HttpService"):JSONEncode(data)
			pcall(function() makefolder(folder) end)
			writefile(folder .. "/" .. name .. ".cfg", json)
			refreshConfigList()
		end,
	})
	configGroup:AddButton({
		Text = "Load",
		Callback = function()
			local name = configNameBox.Text
			if name == "" then return end
			local folder = window.ConfigFolder
			if not folder then return end
			local success, content = pcall(readfile, folder .. "/" .. name .. ".cfg")
			if not success then return end
			local data = game:GetService("HttpService"):JSONDecode(content)
			if data.Toggles then
				for k, val in pairs(data.Toggles) do
					if Toggles[k] then
						Toggles[k].Value = val
						if Toggles[k].UpdateVisuals then Toggles[k].UpdateVisuals() end
					end
				end
			end
			if data.Options then
				for k, val in pairs(data.Options) do
					if Options[k] then
						if Options[k].Type == "Slider" or Options[k].Type == "Dropdown" then
							Options[k].Value = val
						elseif Options[k].Type == "Keybind" and type(val) == "string" then
							local key = Enum.KeyCode[val]
							if key then Options[k].Value = key end
						elseif Options[k].Type == "ColorPicker" and type(val) == "table" then
							Options[k].Value = Color3.new(val[1], val[2], val[3])
						end
						-- Update visuals if possible
						if Options[k].Update then Options[k].Update() end
					end
				end
			end
		end,
	})
	configGroup:AddButton({
		Text = "Delete",
		Callback = function()
			local name = configNameBox.Text
			if name == "" then return end
			local folder = window.ConfigFolder
			if not folder then return end
			pcall(delfile, folder .. "/" .. name .. ".cfg")
			configNameBox.Text = ""
			refreshConfigList()
		end,
	})
	configListFrame = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = configGroup.Content,
	})
	local configListLayout = create("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = configListFrame,
	})
	configListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		configListFrame.CanvasSize = UDim2.new(0, 0, 0, configListLayout.AbsoluteContentSize.Y + 10)
	end)
	refreshConfigList()

	-- Menu toggle via keybind (optional, can be set by user)
	-- Example: Use Settings.MenuKeybind key to toggle visibility
	window.MenuKeybind = Toggles["MenuKeybind"] or nil

	-- Notifications
	local notificationContainer = create("Frame", {
		Size = UDim2.new(0, 250, 1, -20),
		Position = UDim2.new(1, -260, 0, 0),
		BackgroundTransparency = 1,
		Parent = ScreenGui,
	})
	local notifLayout = create("UIListLayout", {
		Padding = UDim.new(0, 5),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notificationContainer,
	})
	function Library:Notify(title, message, duration)
		duration = duration or 3
		local notif = create("Frame", {
			Size = UDim2.new(1, 0, 0, 70),
			BackgroundColor3 = mainColor,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Parent = notificationContainer,
		})
		local stroke = addStroke(notif, accent)
		local titleLabel = create("TextLabel", {
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0, 5, 0, 5),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = accent,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = notif,
		})
		local msgLabel = create("TextLabel", {
			Size = UDim2.new(1, -10, 0, 35),
			Position = UDim2.new(0, 5, 0, 25),
			BackgroundTransparency = 1,
			Text = message,
			TextColor3 = textColor,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = notif,
		})
		delay(duration, function()
			TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
			delay(0.3, function() notif:Destroy() end)
		end)
	end

	return window
end

function Library:SetConfigFolder(path)
	self.ConfigFolder = path
end

return Library
