-- Zilk Lib - 1:1 HeavN / Blade Style
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Zilk = {
    Toggles = {},
    Options = {},
    Theme = {
        MainColor = Color3.fromRGB(10, 10, 10),
        SectionColor = Color3.fromRGB(20, 20, 20),
        AccentColor = Color3.fromRGB(147, 112, 219),
        TextColor = Color3.fromRGB(240, 240, 240),
        ButtonColor = Color3.fromRGB(40, 40, 40),
        DropdownColor = Color3.fromRGB(30, 30, 30),
        ToggleOffColor = Color3.fromRGB(30, 30, 30),
        ToggleOnColor = Color3.fromRGB(255, 255, 255),
        SliderColor = Color3.fromRGB(147, 112, 219),
        OutlineColor = Color3.fromRGB(35, 35, 35)
    },
    ConfigFolder = "ZilkConfigs",
    MenuKey = Enum.KeyCode.RightShift,
    Tabs = {},
    ActiveTab = nil,
    UI = nil,
    ConfigList = {},
    CurrentConfig = "None"
}

-- Utility Functions
local function Create(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

local function GetInputName(input)
    if typeof(input) == "EnumItem" then
        return input.Name
    end
    if input == Enum.UserInputType.MouseButton1 then return "MB1" end
    if input == Enum.UserInputType.MouseButton2 then return "MB2" end
    if input == Enum.UserInputType.MouseButton3 then return "MB3" end
    return "None"
end

-- Config Management
function Zilk:SetFolder(folder)
    self.ConfigFolder = folder
    if not isfolder(folder) then
        local parts = string.split(folder, "/")
        local path = ""
        for _, part in ipairs(parts) do
            path = path .. part .. "/"
            if not isfolder(path) then makefolder(path) end
        end
    end
end

function Zilk:GetConfigs()
    if not isfolder(self.ConfigFolder) then return {} end
    local files = listfiles(self.ConfigFolder)
    local configs = {}
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            table.insert(configs, file:match("([^/\\]+)%.json$"))
        end
    end
    self.ConfigList = configs
    return configs
end

function Zilk:SaveConfig(name)
    local data = {Toggles = {}, Options = {}}
    for idx, obj in pairs(self.Toggles) do data.Toggles[idx] = obj.Value end
    for idx, obj in pairs(self.Options) do 
        if idx ~= "ConfigName" and idx ~= "ConfigList" then
            data.Options[idx] = obj.Value 
        end
    end
    writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    self.CurrentConfig = name
end

function Zilk:LoadConfig(name)
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok then return end
    
    if data.Toggles then
        for idx, val in pairs(data.Toggles) do
            if self.Toggles[idx] then self.Toggles[idx]:SetValue(val) end
        end
    end
    if data.Options then
        for idx, val in pairs(data.Options) do
            if self.Options[idx] then self.Options[idx]:SetValue(val) end
        end
    end
    self.CurrentConfig = name
end

-- UI Construction
function Zilk:CreateWindow(options)
    options = options or {}
    local Title = options.Title or "Zilk Menu"
    
    local ScreenGui = Create("ScreenGui", {
        Name = "ZilkUI",
        Parent = (RunService:IsStudio() and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")) or CoreGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    self.UI = ScreenGui

    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        Size = UDim2.new(0, 700, 0, 550),
        Position = UDim2.new(0.5, -350, 0.5, -275),
        BackgroundColor3 = Zilk.Theme.MainColor,
        BorderSizePixel = 0,
        Active = true
    })
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
    local MainStroke = Create("UIStroke", {
        Parent = MainFrame,
        Color = Zilk.Theme.AccentColor,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })

    -- Title Bar
    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Zilk.Theme.SectionColor,
        BorderSizePixel = 0,
        ZIndex = 2
    })
    Create("UICorner", {Parent = TitleBar, CornerRadius = UDim.new(0, 8)})
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Zilk.Theme.SectionColor,
        BorderSizePixel = 0,
        Parent = TitleBar,
        ZIndex = 2
    })

    local TitleText = Create("TextLabel", {
        Name = "TitleText",
        Parent = TitleBar,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 = Zilk.Theme.TextColor,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    })

    -- Dragging
    do
        local dragging, dragStart, startPos
        TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    -- Tab Container (Sidebar)
    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = MainFrame,
        Size = UDim2.new(0, 110, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Zilk.Theme.SectionColor,
        BorderSizePixel = 0,
        ZIndex = 2
    })
    local TabList = Create("UIListLayout", {
        Parent = TabContainer,
        Padding = UDim.new(0, 5),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {Parent = TabContainer, PaddingTop = UDim.new(0, 10)})

    -- Separator line
    Create("Frame", {
        Name = "Line",
        Parent = MainFrame,
        BackgroundColor3 = Zilk.Theme.OutlineColor,
        Size = UDim2.new(0, 1, 1, -35),
        Position = UDim2.new(0, 110, 0, 35),
        BorderSizePixel = 0,
        ZIndex = 3
    })

    local Pages = Create("Frame", {
        Name = "Pages",
        Parent = MainFrame,
        Size = UDim2.new(1, -120, 1, -45),
        Position = UDim2.new(0, 115, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 2
    })

    local Window = {}
    local tabCount = 0

    function Window:AddTab(name, order)
        tabCount = tabCount + 1
        local Tab = {Page = nil, Button = nil}
        local lo = order or tabCount
        
        local TabButton = Create("TextButton", {
            Name = name .. "Tab",
            Parent = TabContainer,
            Size = UDim2.new(0.9, 0, 0, 30),
            BackgroundColor3 = Zilk.Theme.SectionColor,
            Text = name,
            TextColor3 = Zilk.Theme.TextColor,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            BorderSizePixel = 0,
            ZIndex = 10,
            LayoutOrder = lo
        })
        Create("UICorner", {Parent = TabButton, CornerRadius = UDim.new(0, 4)})
        Tab.Button = TabButton

        local Page = Create("ScrollingFrame", {
            Name = name .. "Page",
            Parent = Pages,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Zilk.Theme.AccentColor,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 5,
            BorderSizePixel = 0
        })
        Tab.Page = Page

        local LeftCol = Create("Frame", {
            Name = "LeftCol",
            Parent = Page,
            Size = UDim2.new(0.48, 0, 0, 0),
            Position = UDim2.new(0.01, 0, 0, 10),
            BackgroundTransparency = 1,
            ZIndex = 5
        })
        local LeftList = Create("UIListLayout", {Parent = LeftCol, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
        
        local RightCol = Create("Frame", {
            Name = "RightCol",
            Parent = Page,
            Size = UDim2.new(0.48, 0, 0, 0),
            Position = UDim2.new(0.51, 0, 0, 10),
            BackgroundTransparency = 1,
            ZIndex = 5
        })
        local RightList = Create("UIListLayout", {Parent = RightCol, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})

        local function UpdateCanvas()
            LeftCol.Size = UDim2.new(0.48, 0, 0, LeftList.AbsoluteContentSize.Y)
            RightCol.Size = UDim2.new(0.48, 0, 0, RightList.AbsoluteContentSize.Y)
            Page.CanvasSize = UDim2.new(0, 0, 0, math.max(LeftList.AbsoluteContentSize.Y, RightList.AbsoluteContentSize.Y) + 20)
        end
        LeftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        RightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        local function Select()
            for _, t in pairs(Zilk.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Zilk.Theme.SectionColor
                t.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
            Page.Visible = true
            TabButton.BackgroundColor3 = Zilk.Theme.ButtonColor
            TabButton.TextColor3 = Zilk.Theme.AccentColor
            Zilk.ActiveTab = Tab
        end

        TabButton.MouseButton1Click:Connect(Select)
        Zilk.Tabs[name] = Tab

        -- Handle default tab (first tab added)
        if tabCount == 1 and not order then
            task.spawn(Select)
        end

        local toggleLeft = true
        function Tab:AddGroupbox(title)
            local col = toggleLeft and LeftCol or RightCol
            toggleLeft = not toggleLeft
            
            local Box = Create("Frame", {
                Parent = col,
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                BorderSizePixel = 0,
                ZIndex = 6
            })
            Create("UICorner", {Parent = Box, CornerRadius = UDim.new(0, 4)})
            Create("UIStroke", {Parent = Box, Color = Zilk.Theme.OutlineColor, Thickness = 1})
            
            local Header = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                ZIndex = 7
            })
            Create("UICorner", {Parent = Header, CornerRadius = UDim.new(0, 4)})
            Create("Frame", {
                Size = UDim2.new(1, 0, 0, 10),
                Position = UDim2.new(0, 0, 1, -10),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                Parent = Header,
                ZIndex = 7
            })
            
            Create("Frame", {
                Parent = Header,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Zilk.Theme.AccentColor,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                ZIndex = 8
            })
            
            Create("TextLabel", {
                Parent = Header,
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = title:upper(),
                TextColor3 = Zilk.Theme.AccentColor,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 9
            })

            local Container = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, -16, 0, 0),
                Position = UDim2.new(0, 8, 0, 28),
                BackgroundTransparency = 1,
                ZIndex = 7
            })
            local ContainerList = Create("UIListLayout", {Parent = Container, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})

            ContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Container.Size = UDim2.new(1, -16, 0, ContainerList.AbsoluteContentSize.Y)
                Box.Size = UDim2.new(1, 0, 0, ContainerList.AbsoluteContentSize.Y + 35)
            end)

            local Groupbox = {Container = Container}

            function Groupbox:AddToggle(idx, opts)
                local Toggle = {Value = opts.Default or false, Type = "Toggle"}
                local Row = Create("TextButton", {
                    Parent = Container,
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 8
                })
                local Track = Create("Frame", {
                    Parent = Row,
                    Size = UDim2.new(0, 35, 0, 18),
                    Position = UDim2.new(1, -35, 0.5, -9),
                    BackgroundColor3 = Toggle.Value and Zilk.Theme.AccentColor or Zilk.Theme.ToggleOffColor,
                    ZIndex = 9
                })
                Create("UICorner", {Parent = Track, CornerRadius = UDim.new(1, 0)})
                
                local Knob = Create("Frame", {
                    Parent = Track,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = Toggle.Value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(240, 240, 240),
                    ZIndex = 10
                })
                Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})

                local Label = Create("TextLabel", {
                    Parent = Row,
                    Size = UDim2.new(1, -45, 1, 0),
                    BackgroundTransparency = 1,
                    Text = opts.Text or idx,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 9
                })

                function Toggle:SetValue(val)
                    Toggle.Value = val
                    TweenService:Create(Track, TweenInfo.new(0.15), {BackgroundColor3 = val and Zilk.Theme.AccentColor or Zilk.Theme.ToggleOffColor}):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Position = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    }):Play()
                    if opts.Callback then opts.Callback(val) end
                end

                function Toggle:OnChanged(cb) opts.Callback = cb end

                Row.MouseButton1Click:Connect(function() Toggle:SetValue(not Toggle.Value) end)
                Zilk.Toggles[idx] = Toggle
                return Toggle
            end

            function Groupbox:AddSlider(idx, opts)
                local Slider = {Value = opts.Default or opts.Min, Type = "Slider"}
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, ZIndex = 8})
                local Label = Create("TextLabel", {
                    Parent = Row,
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = (opts.Text or idx) .. ": " .. Slider.Value,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 9
                })
                local SliderBg = Create("Frame", {
                    Parent = Row,
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 24),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    ZIndex = 9
                })
                Create("UICorner", {Parent = SliderBg, CornerRadius = UDim.new(1, 0)})
                
                local Fill = Create("Frame", {
                    Parent = SliderBg,
                    Size = UDim2.new((Slider.Value - opts.Min) / (opts.Max - opts.Min), 0, 1, 0),
                    BackgroundColor3 = Zilk.Theme.SliderColor,
                    ZIndex = 10
                })
                Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

                function Slider:SetValue(val)
                    val = math.clamp(val, opts.Min, opts.Max)
                    if opts.Rounding then val = math.floor(val + 0.5) end
                    Slider.Value = val
                    Fill.Size = UDim2.new((val - opts.Min) / (opts.Max - opts.Min), 0, 1, 0)
                    Label.Text = (opts.Text or idx) .. ": " .. val
                    if opts.Callback then opts.Callback(val) end
                end

                function Slider:OnChanged(cb) opts.Callback = cb end

                function Slider:OnChanged(cb) opts.Callback = cb end

                local dragging = false
                local function Update()
                    local percent = math.clamp((UserInputService:GetMouseLocation().X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                    Slider:SetValue(opts.Min + (opts.Max - opts.Min) * percent)
                end
                SliderBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        Update()
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Update()
                    end
                end)

                Zilk.Options[idx] = Slider
                return Slider
            end

            function Groupbox:AddDropdown(idx, opts)
                local Dropdown = {Value = opts.Default, Type = "Dropdown"}
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ZIndex = 8})
                local Label = Create("TextLabel", {
                    Parent = Row,
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = opts.Text or idx,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 9
                })
                local Btn = Create("TextButton", {
                    Parent = Row,
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, 21),
                    BackgroundColor3 = Zilk.Theme.DropdownColor,
                    Text = tostring(Dropdown.Value or "None"),
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    ZIndex = 9
                })
                Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(45, 45, 45), Thickness = 1})

                local List = Create("Frame", {
                    Name = "DropdownList_" .. idx,
                    Parent = ScreenGui,
                    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                    Visible = false,
                    ZIndex = 10000,
                    BorderSizePixel = 0
                })
                Create("UICorner", {Parent = List, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = List, Color = Zilk.Theme.AccentColor, Thickness = 1})
                local ListLayout = Create("UIListLayout", {Parent = List, SortOrder = Enum.SortOrder.LayoutOrder})

                local function Rebuild()
                    for _, c in pairs(List:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                    for _, val in ipairs(opts.Values or {}) do
                        local Opt = Create("TextButton", {
                            Parent = List,
                            Size = UDim2.new(1, 0, 0, 24),
                            BackgroundTransparency = 1,
                            Text = tostring(val),
                            TextColor3 = Zilk.Theme.TextColor,
                            Font = Enum.Font.Gotham,
                            TextSize = 11,
                            ZIndex = 10001
                        })
                        Opt.MouseButton1Click:Connect(function()
                            Dropdown:SetValue(val)
                            List.Visible = false
                        end)
                    end
                    List.Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, math.min(#(opts.Values or {}) * 24, 120))
                end
                Rebuild()

                function Dropdown:SetValue(val)
                    Dropdown.Value = val
                    Btn.Text = tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end
                function Dropdown:SetValues(vals) opts.Values = vals; Rebuild() end

                Btn.MouseButton1Click:Connect(function()
                    List.Visible = not List.Visible
                    if List.Visible then
                        List.Position = UDim2.new(0, Btn.AbsolutePosition.X, 0, Btn.AbsolutePosition.Y + 24)
                    end
                end)

                Zilk.Options[idx] = Dropdown
                return Dropdown
            end

            function Groupbox:AddKeybind(idx, opts)
                local Keybind = {Value = opts.Default or Enum.KeyCode.F, Type = "Keybind"}
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, ZIndex = 8})
                local Label = Create("TextLabel", {
                    Parent = Row,
                    Size = UDim2.new(1, -60, 1, 0),
                    BackgroundTransparency = 1,
                    Text = opts.Text or idx,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 9
                })
                local Btn = Create("TextButton", {
                    Parent = Row,
                    Size = UDim2.new(0, 60, 0, 20),
                    Position = UDim2.new(1, -60, 0.5, -10),
                    BackgroundColor3 = Zilk.Theme.ButtonColor,
                    Text = GetInputName(Keybind.Value),
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    ZIndex = 9
                })
                Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})

                function Keybind:OnChanged(cb) opts.Callback = cb end

                local picking = false
                Btn.MouseButton1Click:Connect(function()
                    if picking then return end
                    picking = true
                    Btn.Text = "..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input)
                        local it = input.UserInputType
                        if it == Enum.UserInputType.Keyboard or it == Enum.UserInputType.MouseButton1 or it == Enum.UserInputType.MouseButton2 or it == Enum.UserInputType.MouseButton3 then
                            local bind = (it == Enum.UserInputType.Keyboard and input.KeyCode) or it
                            Keybind:SetValue(bind)
                            conn:Disconnect()
                            task.wait(0.1)
                            picking = false
                        end
                    end)
                end)

                function Keybind:SetValue(val)
                    Keybind.Value = val
                    Btn.Text = GetInputName(val)
                    if opts.Callback then opts.Callback(val) end
                end

                Zilk.Options[idx] = Keybind
                return Keybind
            end

            function Groupbox:AddColorPicker(idx, opts)
                local ColorPicker = {Value = opts.Default or Color3.fromRGB(255, 255, 255), Type = "ColorPicker"}
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 8})
                local Label = Create("TextLabel", {
                    Parent = Row,
                    Size = UDim2.new(1, -40, 1, 0),
                    BackgroundTransparency = 1,
                    Text = opts.Text or idx,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 9
                })
                local Preview = Create("TextButton", {
                    Parent = Row,
                    Size = UDim2.new(0, 30, 0, 20),
                    Position = UDim2.new(1, -30, 0.5, -10),
                    BackgroundColor3 = ColorPicker.Value,
                    Text = "",
                    ZIndex = 9
                })
                Create("UICorner", {Parent = Preview, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = Preview, Color = Color3.new(0,0,0), Thickness = 1})

                local Popup = Create("Frame", {
                    Name = "ColorPicker_" .. idx,
                    Parent = ScreenGui,
                    Size = UDim2.new(0, 200, 0, 180),
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    Visible = false,
                    ZIndex = 20000
                })
                Create("UICorner", {Parent = Popup, CornerRadius = UDim.new(0, 6)})
                Create("UIStroke", {Parent = Popup, Color = Zilk.Theme.AccentColor, Thickness = 1})

                -- Basic Hue Slider for 1:1 functionality
                local HueSlider = Create("Frame", {
                    Parent = Popup,
                    Size = UDim2.new(1, -20, 0, 15),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundColor3 = Color3.new(1,1,1),
                    ZIndex = 20001
                })
                local HueGrad = Create("UIGradient", {
                    Parent = HueSlider,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(0.2, Color3.fromHSV(0.2, 1, 1)),
                        ColorSequenceKeypoint.new(0.4, Color3.fromHSV(0.4, 1, 1)),
                        ColorSequenceKeypoint.new(0.6, Color3.fromHSV(0.6, 1, 1)),
                        ColorSequenceKeypoint.new(0.8, Color3.fromHSV(0.8, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                    })
                })

                Preview.MouseButton1Click:Connect(function()
                    Popup.Visible = not Popup.Visible
                    Popup.Position = UDim2.new(0, Preview.AbsolutePosition.X - 210, 0, Preview.AbsolutePosition.Y)
                end)

                function ColorPicker:SetValue(val)
                    ColorPicker.Value = val
                    Preview.BackgroundColor3 = val
                    if opts.Callback then opts.Callback(val) end
                end

                function ColorPicker:OnChanged(cb) opts.Callback = cb end

                Zilk.Options[idx] = ColorPicker
                return ColorPicker
            end

            function Groupbox:AddButton(text, callback)
                local Btn = Create("TextButton", {
                    Parent = Container,
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = Zilk.Theme.ButtonColor,
                    Text = text,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = 9
                })
                Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
            end

            function Groupbox:AddInput(idx, opts)
                local Input = {Value = opts.Default or "", Type = "Input"}
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ZIndex = 8})
                local Label = Create("TextLabel", {
                    Parent = Row,
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = opts.Text or idx,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 9
                })
                local Box = Create("TextBox", {
                    Parent = Row,
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, 21),
                    BackgroundColor3 = Zilk.Theme.DropdownColor,
                    Text = Input.Value,
                    TextColor3 = Zilk.Theme.TextColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    PlaceholderText = "Type...",
                    ClearTextOnFocus = false,
                    ZIndex = 9
                })
                Create("UICorner", {Parent = Box, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = Box, Color = Color3.fromRGB(45, 45, 45), Thickness = 1})
                Create("UIPadding", {Parent = Box, PaddingLeft = UDim.new(0, 6)})

                Box.FocusLost:Connect(function()
                    Input.Value = Box.Text
                    if opts.Callback then opts.Callback(Box.Text) end
                end)

                function Input:SetValue(val)
                    Input.Value = val
                    Box.Text = tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end

                Zilk.Options[idx] = Input
                return Input
            end

            return Groupbox
        end

        return Tab
    end

    -- Auto-Add Settings and Config Tabs at high layout orders
    local SettingsTab = Window:AddTab("Settings", 998)
    local ConfigTab = Window:AddTab("Config", 999)

    -- Settings Tab Setup
    local UISet = SettingsTab:AddGroupbox("UI Settings")
    UISet:AddKeybind("MenuKey", {Text = "Toggle GUI Key", Default = Zilk.MenuKey, Callback = function(v) Zilk.MenuKey = v end})
    UISet:AddButton("Unload GUI", function() Zilk.UI:Destroy() end)

    -- Config Manager setup
    local Configs = ConfigTab:AddGroupbox("Config Manager")
    local StatusLabel = Create("TextLabel", {
        Parent = Configs.Container,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "Current: None",
        TextColor3 = Zilk.Theme.TextColor,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })

    Configs:AddInput("ConfigName", {Text = "Config Name"})
    
    local BtnRow = Create("Frame", {
        Parent = Configs.Container,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        ZIndex = 8
    })
    local function CreateCfgBtn(text, pos, color, callback)
        local btn = Create("TextButton", {
            Parent = BtnRow,
            Size = UDim2.new(0.24, -2, 1, 0),
            Position = pos,
            BackgroundColor3 = color,
            Text = text,
            TextColor3 = Color3.new(1,1,1),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            ZIndex = 9
        })
        Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local ConfigList = Configs:AddDropdown("ConfigList", {Text = "Config List", Values = Zilk:GetConfigs()})

    CreateCfgBtn("Save", UDim2.new(0, 0, 0, 0), Zilk.Theme.AccentColor, function()
        local name = Zilk.Options.ConfigName.Value
        if name ~= "" then
            Zilk:SaveConfig(name)
            ConfigList:SetValues(Zilk:GetConfigs())
            StatusLabel.Text = "Current: " .. name .. " (Saved)"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end)
    CreateCfgBtn("Load", UDim2.new(0.25, 2, 0, 0), Color3.fromRGB(50, 150, 255), function()
        local name = Zilk.Options.ConfigList.Value
        if name and name ~= "None" then
            Zilk:LoadConfig(name)
            StatusLabel.Text = "Current: " .. name .. " (Loaded)"
            StatusLabel.TextColor3 = Zilk.Theme.AccentColor
        end
    end)
    CreateCfgBtn("Overwrite", UDim2.new(0.5, 4, 0, 0), Color3.fromRGB(255, 165, 0), function()
        local name = Zilk.Options.ConfigList.Value
        if name and name ~= "None" then
            Zilk:SaveConfig(name)
            StatusLabel.Text = "Current: " .. name .. " (Overwritten)"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        end
    end)
    CreateCfgBtn("Delete", UDim2.new(0.75, 6, 0, 0), Color3.fromRGB(200, 50, 50), function()
        local name = Zilk.Options.ConfigList.Value
        if name and name ~= "None" then
            Zilk:DeleteConfig(name)
            ConfigList:SetValues(Zilk:GetConfigs())
            StatusLabel.Text = "Current: None"
            StatusLabel.TextColor3 = Zilk.Theme.TextColor
        end
    end)

    Configs:AddButton("Refresh Configs", function()
        ConfigList:SetValues(Zilk:GetConfigs())
    end)

    -- Global Input Hook
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Zilk.MenuKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    return Window
end

return Zilk
