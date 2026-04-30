-- ZilkLib (Blade UI style) – by XIMMYzwsss
-- Upload to: https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/refs/heads/main/Lib.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library

-- Global holders (you can access them later from your script)
local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

Library.ConfigFolder = nil   -- set by user

-- Utility
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function addStroke(obj, color, thickness)
	local stroke = create("UIStroke", {
		Color = color or Color3.new(0,0,0),
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	})
	stroke.Parent = obj
	return stroke
end

function Library:Notify(title, msg, duration)
	duration = duration or 3
	local notif = create("Frame", {
		Size = UDim2.new(0, 260, 0, 70),
		BackgroundColor3 = self.MainColor,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = self.Gui,
	})
	addStroke(notif, self.AccentColor)
	local titleL = create("TextLabel", {
		Size = UDim2.new(1, -10, 0, 18),
		Position = UDim2.new(0, 5, 0, 5),
		Text = title,
		TextColor3 = self.AccentColor,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		BackgroundTransparency = 1,
		Parent = notif,
	})
	local msgL = create("TextLabel", {
		Size = UDim2.new(1, -10, 0, 40),
		Position = UDim2.new(0, 5, 0, 24),
		Text = msg,
		TextColor3 = self.TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Parent = notif,
	})
	notif.Position = UDim2.new(1, -270, 0.5, -35)
	spawn(function()
		wait(duration)
		TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		wait(0.4)
		notif:Destroy()
	end)
end

-- Window creator
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local Title       = cfg.Title or "Zilk"
	local Position    = cfg.Position   or UDim2.new(0, 175, 0, 50)
	local Size        = cfg.Size       or UDim2.new(0, 550, 0, 600)
	local Accent      = cfg.AccentColor or Color3.fromRGB(147,112,219)
	local MainColor   = cfg.MainColor  or Color3.fromRGB(20,20,20)
	local TextColor   = cfg.TextColor  or Color3.fromRGB(240,240,240)

	local ScreenGui = create("ScreenGui", {
		Name = "ZilkGUI",
		Parent = CoreGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false
	})
	if protectgui then protectgui(ScreenGui) end  -- basic protection

	local Window = setmetatable({
		Gui = ScreenGui,
		AccentColor = Accent,
		MainColor = MainColor,
		TextColor = TextColor,
		ConfigFolder = nil,
		Tabs = {},
	}, Library)

	-- Main frame
	local MFrame = create("Frame", {
		Name = "MainFrame",
		Size = Size,
		Position = Position,
		BackgroundColor3 = MainColor,
		BorderSizePixel = 0,
		Active = true,
		Parent = ScreenGui,
	})
	addStroke(MFrame, Accent, 2)

	-- Title bar (Blade style)
	local TitleBar = create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(25,25,25),
		BorderSizePixel = 0,
		Parent = MFrame,
	})
	local TitleLabel = create("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Text = Title,
		TextColor3 = TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = TitleBar,
	})
	addStroke(TitleLabel)
	local VersionLabel = create("TextLabel", {
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.new(0.6, 0, 0, 0),
		Text = "v1.0",
		TextColor3 = Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = TitleBar,
	})
	addStroke(VersionLabel)

	-- Sidebar
	local Sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 100, 1, -30),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(25,25,25),
		BorderSizePixel = 0,
		Parent = MFrame,
	})
	local TabList = create("UIListLayout", {
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Sidebar,
	})

	-- Pages holder
	local PageContainer = create("Frame", {
		Name = "Pages",
		Size = UDim2.new(1, -100, 1, -30),
		Position = UDim2.new(0, 100, 0, 30),
		BackgroundTransparency = 1,
		Parent = MFrame,
	})

	local tabCount = 0
	function Window:AddTab(name)
		tabCount = tabCount + 1
		local tabBtn = create("TextButton", {
			Name = name,
			Size = UDim2.new(0.9, 0, 0, 28),
			BackgroundColor3 = tabCount == 1 and Accent or Color3.fromRGB(35,35,35),
			Text = name,
			TextColor3 = TextColor,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			BorderSizePixel = 0,
			Parent = Sidebar,
		})
		addStroke(tabBtn)

		local page = create("ScrollingFrame", {
			Name = name .. "Page",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Accent,
			CanvasSize = UDim2.new(0,0,0,1000),
			Parent = PageContainer,
		})
		local pageLayout = create("UIListLayout", {
			Padding = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})

		-- Make tabs switchable
		tabBtn.MouseButton1Click:Connect(function()
			for _, pg in pairs(PageContainer:GetChildren()) do
				if pg:IsA("ScrollingFrame") then pg.Visible = false end
			end
			for _, btn in pairs(Sidebar:GetChildren()) do
				if btn:IsA("TextButton") then btn.BackgroundColor3 = Color3.fromRGB(35,35,35) end
			end
			page.Visible = true
			tabBtn.BackgroundColor3 = Accent
		end)
		if tabCount == 1 then
			tabBtn.BackgroundColor3 = Accent
			page.Visible = true
		end

		local tab = {
			Page = page,
			Layout = pageLayout,
			Groupboxes = {},
		}

		function tab:AddGroupbox(title)
			local box = create("Frame", {
				Name = "Groupbox",
				Size = UDim2.new(0.95, 0, 0, 100),
				BackgroundColor3 = Color3.fromRGB(18,18,18),
				BorderSizePixel = 0,
				Parent = page,
			})
			local boxStroke = addStroke(box, Color3.fromRGB(35,35,35), 1)
			local header = create("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = Color3.fromRGB(25,25,25),
				BorderSizePixel = 0,
				Parent = box,
			})
			local accentLine = create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Accent,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Parent = header,
			})
			local headerTitle = create("TextLabel", {
				Size = UDim2.new(1, -10, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				Text = title:upper(),
				TextColor3 = Accent,
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Parent = header,
			})
			addStroke(headerTitle)

			local content = create("Frame", {
				Size = UDim2.new(1, -20, 1, -24),
				Position = UDim2.new(0, 10, 0, 24),
				BackgroundTransparency = 1,
				Parent = box,
			})
			local contentLayout = create("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = content,
			})
			box.Size = UDim2.new(0.95, 0, 0, 24 + contentLayout.AbsoluteContentSize.Y + 10)
			contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				box.Size = UDim2.new(0.95, 0, 0, 24 + contentLayout.AbsoluteContentSize.Y + 10)
			end)

			local group = {
				Content = content,
				Layout = contentLayout,
			}

			-- Element adders (Toggle, Slider, Dropdown, Keybind, ColorPicker, Button, Label, Divider)
			function group:AddToggle(idx, info)
				local toggle = {
					Value = info.Default or false,
					Callback = info.Callback or function() end,
				}
				local row = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 24),
					Text = "",
					BackgroundTransparency = 1,
					Parent = content,
				})
				local lbl = create("TextLabel", {
					Size = UDim2.new(1, -40, 1, 0),
					Text = info.Text or idx,
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Parent = row,
				})
				addStroke(lbl)
				local track = create("Frame", {
					Size = UDim2.new(0, 30, 0, 14),
					Position = UDim2.new(1, -35, 0.5, -7),
					BackgroundColor3 = toggle.Value and Accent or Color3.fromRGB(50,50,50),
					BorderSizePixel = 0,
					Parent = row,
				})
				local knob = create("Frame", {
					Size = UDim2.new(0, 10, 0, 10),
					Position = UDim2.new(0, toggle.Value and 17 or 2, 0.5, -5),
					BackgroundColor3 = Color3.new(1,1,1),
					BorderSizePixel = 0,
					Parent = track,
				})
				local function updateVis()
					track.BackgroundColor3 = toggle.Value and Accent or Color3.fromRGB(50,50,50)
					TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, toggle.Value and 17 or 2, 0.5, -5)}):Play()
				end
				row.MouseButton1Click:Connect(function()
					toggle.Value = not toggle.Value
					updateVis()
					toggle.Callback(toggle.Value)
				end)
				toggle.UpdateVisuals = updateVis
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
				local lbl = create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					Text = (info.Text or idx) .. ": " .. tostring(math.floor(slider.Value*100)/100),
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Parent = content,
				})
				addStroke(lbl)
				local bar = create("Frame", {
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundColor3 = Color3.fromRGB(30,30,30),
					BorderSizePixel = 0,
					Parent = content,
				})
				local fill = create("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = Accent,
					BorderSizePixel = 0,
					Parent = bar,
				})
				local function update(val)
					local ratio = math.clamp((val - slider.Min) / (slider.Max - slider.Min), 0, 1)
					fill.Size = UDim2.new(ratio, 0, 1, 0)
					lbl.Text = (info.Text or idx) .. ": " .. tostring(math.floor(val*100 + 0.5)/100)
				end
				update(slider.Value)
				local drag, moveConn, endConn
				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						drag = true
						local function setFromMouse()
							local mx = UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X
							local ratio = math.clamp(mx / bar.AbsoluteSize.X, 0, 1)
							slider.Value = slider.Min + ratio * (slider.Max - slider.Min)
							update(slider.Value)
							slider.Callback(slider.Value)
						end
						setFromMouse()
						moveConn = UserInputService.InputChanged:Connect(function(move)
							if drag and (move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch) then
								setFromMouse()
							end
						end)
						endConn = UserInputService.InputEnded:Connect(function(endInput)
							if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
								drag = false
								if moveConn then moveConn:Disconnect() end
								if endConn then endConn:Disconnect() end
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
				local lbl = create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					Text = info.Text or idx,
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Parent = content,
				})
				addStroke(lbl)
				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					Text = dropdown.Value,
					BackgroundColor3 = Color3.fromRGB(30,30,30),
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					BorderSizePixel = 0,
					Parent = content,
				})
				addStroke(btn)
				local list = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(20,20,20),
					Visible = false,
					ClipsDescendants = true,
					BorderSizePixel = 0,
					Parent = btn,
				})
				local listLayout = create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
				local function rebuild()
					for _, child in pairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
					for _, v in pairs(dropdown.Values) do
						local opt = create("TextButton", {
							Size = UDim2.new(1, 0, 0, 20),
							Text = v,
							TextColor3 = TextColor,
							Font = Enum.Font.GothamBold,
							TextSize = 12,
							BackgroundTransparency = 1,
							Parent = list,
						})
						opt.MouseButton1Click:Connect(function()
							dropdown.Value = v
							btn.Text = v
							list.Visible = false
							dropdown.Callback(v)
						end)
					end
					list.Size = UDim2.new(1, 0, 0, #dropdown.Values * 20)
				end
				btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
				rebuild()
				Options[idx] = dropdown
				return dropdown
			end

			function group:AddKeybind(idx, info)
				local keybind = {
					Value = info.Default or Enum.KeyCode.LeftControl,
					Callback = info.Callback or function() end,
				}
				local container = create("Frame", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					Parent = content,
				})
				local label = create("TextLabel", {
					Size = UDim2.new(0.6, 0, 1, 0),
					Text = info.Text or idx,
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Parent = container,
				})
				addStroke(label)
				local btn = create("TextButton", {
					Size = UDim2.new(0.4, 0, 1, 0),
					Position = UDim2.new(0.6, 0, 0, 0),
					Text = keybind.Value.Name,
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					BackgroundColor3 = Color3.fromRGB(30,30,30),
					BorderSizePixel = 0,
					Parent = container,
				})
				addStroke(btn)
				btn.MouseButton1Click:Connect(function()
					btn.Text = "..."
					local conn = UserInputService.InputBegan:Connect(function(input, gp)
						if gp then return end
						if input.UserInputType == Enum.UserInputType.Keyboard then
							keybind.Value = input.KeyCode
							btn.Text = input.KeyCode.Name
							keybind.Callback(input.KeyCode)
							conn:Disconnect()
						end
					end)
				end)
				Options[idx] = keybind
				return keybind
			end

			function group:AddColorPicker(idx, info)
				local color = {
					Value = info.Default or Color3.new(1,1,1),
					Callback = info.Callback or function() end,
				}
				local container = create("Frame", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					Parent = content,
				})
				local label = create("TextLabel", {
					Size = UDim2.new(0.6, 0, 1, 0),
					Text = info.Text or idx,
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Parent = container,
				})
				addStroke(label)
				local preview = create("TextButton", {
					Size = UDim2.new(0.4, 0, 1, 0),
					Position = UDim2.new(0.6, 0, 0, 0),
					Text = "",
					BackgroundColor3 = color.Value,
					BorderSizePixel = 0,
					Parent = container,
				})
				local pickerOpen = false
				preview.MouseButton1Click:Connect(function()
					if pickerOpen then return end
					pickerOpen = true
					-- simple color cycle for brevity; replace with full picker if needed
					local hue = math.random()
					color.Value = Color3.fromHSV(hue, 1, 1)
					preview.BackgroundColor3 = color.Value
					color.Callback(color.Value)
					pickerOpen = false
				end)
				Options[idx] = color
				return color
			end

			function group:AddButton(info)
				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 24),
					Text = info.Text or "Button",
					BackgroundColor3 = Accent,
					BackgroundTransparency = 0.2,
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					BorderSizePixel = 0,
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
					Text = text,
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					BackgroundTransparency = 1,
					TextWrapped = true,
					Parent = content,
				})
				addStroke(lbl)
			end

			function group:AddDivider()
				local div = create("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = Accent,
					BackgroundTransparency = 0.5,
					Parent = content,
				})
			end

			tab.Groupboxes[title] = group
			return group
		end

		Window.Tabs[name] = tab
		return tab
	end

	-- Automatically append Settings and Config tabs
	local settingsTab = Window:AddTab("Settings")
	local setGrp = settingsTab:AddGroupbox("Menu")
	setGrp:AddKeybind("MenuKeybind", {
		Text = "Menu Key",
		Default = Enum.KeyCode.RightShift,
		Callback = function(key) end,
	})
	setGrp:AddButton({
		Text = "Unload",
		Callback = function()
			ScreenGui:Destroy()
			Window = nil
		end,
	})

	local configTab = Window:AddTab("Config")
	local cfgGrp = configTab:AddGroupbox("Config Manager")
	local cfgName = create("TextBox", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Color3.fromRGB(30,30,30),
		TextColor3 = TextColor,
		PlaceholderText = "Config name...",
		PlaceholderColor3 = Color3.fromRGB(150,150,150),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		ClearTextOnFocus = false,
		Parent = cfgGrp.Content,
	})
	addStroke(cfgName)
	cfgGrp:AddButton({Text = "Save", Callback = function()
		local name = cfgName.Text:match("^%s*(.-)%s*$")
		if name == "" then return end
		local folder = Window.ConfigFolder
		if not folder then Window:Notify("Config", "Set ConfigFolder first", 3) return end
		local data = {Toggles={}, Options={}}
		for k,v in pairs(Toggles) do data.Toggles[k] = v.Value end
		for k,v in pairs(Options) do
			if v.Value and type(v.Value) == "userdata" and tostring(v.Value):find("KeyCode") then
				data.Options[k] = v.Value.Name
			elseif v.Value and type(v.Value) == "userdata" and tostring(v.Value):find("Color3") then
				local c = v.Value
				data.Options[k] = {c.R, c.G, c.B}
			else
				data.Options[k] = v.Value
			end
		end
		local json = HttpService:JSONEncode(data)
		pcall(makefolder, folder)
		writefile(folder .. "/" .. name .. ".cfg", json)
		Window:Notify("Config", "Saved: " .. name, 2)
		refreshCfgList()
	end})
	cfgGrp:AddButton({Text = "Load", Callback = function()
		local name = cfgName.Text:match("^%s*(.-)%s*$")
		if name == "" then return end
		local folder = Window.ConfigFolder
		if not folder then return end
		local ok, content = pcall(readfile, folder .. "/" .. name .. ".cfg")
		if not ok then Window:Notify("Config", "Not found", 2) return end
		local data = HttpService:JSONDecode(content)
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
					if Options[k].Type == "Keybind" and type(val) == "string" then
						local key = Enum.KeyCode[val]
						if key then Options[k].Value = key end
					elseif Options[k].Type == "ColorPicker" and type(val) == "table" then
						Options[k].Value = Color3.new(val[1], val[2], val[3])
					else
						Options[k].Value = val
					end
				end
			end
		end
		Window:Notify("Config", "Loaded: " .. name, 2)
	end})
	cfgGrp:AddButton({Text = "Delete", Callback = function()
		local name = cfgName.Text:match("^%s*(.-)%s*$")
		if name == "" then return end
		local folder = Window.ConfigFolder
		if not folder then return end
		pcall(delfile, folder .. "/" .. name .. ".cfg")
		cfgName.Text = ""
		refreshCfgList()
		Window:Notify("Config", "Deleted", 2)
	end})

	local cfgListFrame = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Accent,
		CanvasSize = UDim2.new(0,0,0,0),
		Parent = cfgGrp.Content,
	})
	local cfgListLayout = create("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = cfgListFrame,
	})
	cfgListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		cfgListFrame.CanvasSize = UDim2.new(0,0,0, cfgListLayout.AbsoluteContentSize.Y + 10)
	end)

	function refreshCfgList()
		for _, v in pairs(cfgListFrame:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end
		local folder = Window.ConfigFolder
		if not folder then return end
		local files = pcall(function() return listfiles(folder) end) and listfiles(folder) or {}
		for _, file in pairs(files) do
			local name = file:match("([^\\/]+)%.cfg$")
			if name then
				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					Text = name,
					BackgroundColor3 = Color3.fromRGB(35,35,35),
					TextColor3 = TextColor,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					BorderSizePixel = 0,
					Parent = cfgListFrame,
				})
				btn.MouseButton1Click:Connect(function()
					cfgName.Text = name
				end)
			end
		end
	end

	refreshCfgList()

	return Window
end

function Library:SetConfigFolder(path)
	self.ConfigFolder = path
end

return Library
