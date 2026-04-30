local Zilk = {
    Version = "1.0",
    Toggles = {},
    Options = {},
    ConfigFolder = "Zilk_Configs", -- Can be changed by user
    MenuKeybind = Enum.KeyCode.RightShift,
    Instances = {},
    Connections = {},
    Theme = {
        Background = Color3.fromRGB(20, 20, 20),
        SectionBackground = Color3.fromRGB(25, 25, 25),
        Border = Color3.fromRGB(45, 45, 45),
        Accent = Color3.fromRGB(100, 150, 255),
        Text = Color3.fromRGB(240, 240, 240),
        TextMuted = Color3.fromRGB(150, 150, 150),
        Hover = Color3.fromRGB(35, 35, 35),
        Click = Color3.fromRGB(45, 45, 45)
    }
}

local Services = {
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    Players = game:GetService("Players")
}

local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Services.Players.LocalPlayer

local function Create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    table.insert(Zilk.Instances, inst)
    return inst
end

local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    Zilk.Connections[#Zilk.Connections+1] = topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    Zilk.Connections[#Zilk.Connections+1] = topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    Zilk.Connections[#Zilk.Connections+1] = Services.UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local delta = input.Position - DragStart
            object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y)
        end
    end)
end

function Zilk:CreateWindow(options)
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        Title = options.Title or "Zilk Library"
    }

    local Size = options.Size or UDim2.fromOffset(600, 400)

    -- GUI Setup
    local ScreenGui = Create("ScreenGui", {
        Name = Services.HttpService:GenerateGUID(false),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    local success, err = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not success then
        ScreenGui.Parent = LocalPlayer.PlayerGui
    end
    
    Zilk.GUI = ScreenGui

    local MainFrame = Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Zilk.Theme.Background,
        BorderColor3 = Zilk.Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = Size,
        AnchorPoint = Vector2.new(0.5, 0.5)
    })

    local TopBar = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Zilk.Theme.SectionBackground,
        BorderColor3 = Zilk.Theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 25)
    })

    local TitleLabel = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Enum.Font.Code,
        Text = Window.Title,
        TextColor3 = Zilk.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local TabContainer = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(1, 0, 0, 25)
    })
    
    Create("UIListLayout", {
        Parent = TabContainer,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local Line = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Zilk.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 0, 2)
    })

    local ContentContainer = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 1, -52)
    })

    MakeDraggable(TopBar, MainFrame)

    -- Toggle Menu
    Zilk.Connections[#Zilk.Connections+1] = Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Zilk.MenuKeybind then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    function Window:AddTab(name)
        local Tab = {
            Name = name,
            Groupboxes = {Left = {}, Right = {}}
        }
        
        local TabButton = Create("TextButton", {
            Parent = TabContainer,
            BackgroundColor3 = Zilk.Theme.SectionBackground,
            BorderColor3 = Zilk.Theme.Border,
            BorderSizePixel = 1,
            Size = UDim2.new(0, 100, 1, 0),
            Font = Enum.Font.Code,
            Text = name,
            TextColor3 = Zilk.Theme.TextMuted,
            TextSize = 13,
            AutoButtonColor = false
        })

        local TabContent = Create("Frame", {
            Parent = ContentContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false
        })

        local LeftSide = Create("ScrollingFrame", {
            Parent = TabContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 5),
            Size = UDim2.new(0.5, -7, 1, -10),
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })

        local RightSide = Create("ScrollingFrame", {
            Parent = TabContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 2, 0, 5),
            Size = UDim2.new(0.5, -7, 1, -10),
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })

        Create("UIListLayout", {
            Parent = LeftSide,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })

        Create("UIListLayout", {
            Parent = RightSide,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })

        table.insert(self.Tabs, {Button = TabButton, Content = TabContent, Obj = Tab})

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(self.Tabs) do
                t.Content.Visible = false
                t.Button.TextColor3 = Zilk.Theme.TextMuted
                t.Button.BackgroundColor3 = Zilk.Theme.SectionBackground
            end
            TabContent.Visible = true
            TabButton.TextColor3 = Zilk.Theme.Text
            TabButton.BackgroundColor3 = Zilk.Theme.Hover
            self.ActiveTab = Tab
        end)

        if #self.Tabs == 1 then
            TabContent.Visible = true
            TabButton.TextColor3 = Zilk.Theme.Text
            TabButton.BackgroundColor3 = Zilk.Theme.Hover
            self.ActiveTab = Tab
        end

        function Tab:AddGroupbox(name, side)
            local sideFrame = (side == "Right") and RightSide or LeftSide
            
            local Groupbox = {
                Elements = {}
            }

            local BoxFrame = Create("Frame", {
                Parent = sideFrame,
                BackgroundColor3 = Zilk.Theme.SectionBackground,
                BorderColor3 = Zilk.Theme.Border,
                BorderSizePixel = 1,
                Size = UDim2.new(1, -5, 0, 20),
                AutomaticSize = Enum.AutomaticSize.Y
            })

            local BoxTitle = Create("TextLabel", {
                Parent = BoxFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0, 0),
                Size = UDim2.new(1, -10, 0, 20),
                Font = Enum.Font.Code,
                Text = name,
                TextColor3 = Zilk.Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local BoxLine = Create("Frame", {
                Parent = BoxFrame,
                BackgroundColor3 = Zilk.Theme.Border,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 20),
                Size = UDim2.new(1, 0, 0, 1)
            })

            local ElementContainer = Create("Frame", {
                Parent = BoxFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 25),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })

            Create("UIListLayout", {
                Parent = ElementContainer,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2)
            })
            
            Create("UIPadding", {
                Parent = ElementContainer,
                PaddingBottom = UDim.new(0, 5)
            })

            function Groupbox:AddToggle(idx, opts)
                local Toggle = {Value = opts.Default or false}
                
                local ToggleFrame = Create("TextButton", {
                    Parent = ElementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = ""
                })

                local Indicator = Create("Frame", {
                    Parent = ToggleFrame,
                    BackgroundColor3 = Toggle.Value and Zilk.Theme.Accent or Zilk.Theme.Background,
                    BorderColor3 = Zilk.Theme.Border,
                    Position = UDim2.new(0, 5, 0.5, -6),
                    Size = UDim2.new(0, 12, 0, 12)
                })

                local Label = Create("TextLabel", {
                    Parent = ToggleFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 25, 0, 0),
                    Size = UDim2.new(1, -25, 1, 0),
                    Font = Enum.Font.Code,
                    Text = opts.Text,
                    TextColor3 = Zilk.Theme.TextMuted,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local function SetValue(val)
                    Toggle.Value = val
                    Indicator.BackgroundColor3 = val and Zilk.Theme.Accent or Zilk.Theme.Background
                    Label.TextColor3 = val and Zilk.Theme.Text or Zilk.Theme.TextMuted
                    Zilk.Toggles[idx] = Toggle
                    if opts.Callback then
                        task.spawn(opts.Callback, val)
                    end
                end

                ToggleFrame.MouseButton1Click:Connect(function()
                    SetValue(not Toggle.Value)
                end)

                function Toggle:SetValue(val)
                    SetValue(val)
                end

                SetValue(Toggle.Value)
                return Toggle
            end

            function Groupbox:AddSlider(idx, opts)
                local Slider = {Value = opts.Default or opts.Min}
                
                local SliderFrame = Create("Frame", {
                    Parent = ElementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 35)
                })

                local Label = Create("TextLabel", {
                    Parent = SliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0, 0),
                    Size = UDim2.new(1, -10, 0, 15),
                    Font = Enum.Font.Code,
                    Text = opts.Text .. " : " .. tostring(Slider.Value),
                    TextColor3 = Zilk.Theme.TextMuted,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local SliderBack = Create("TextButton", {
                    Parent = SliderFrame,
                    BackgroundColor3 = Zilk.Theme.Background,
                    BorderColor3 = Zilk.Theme.Border,
                    Position = UDim2.new(0, 5, 0, 18),
                    Size = UDim2.new(1, -10, 0, 10),
                    Text = "",
                    AutoButtonColor = false
                })

                local SliderFill = Create("Frame", {
                    Parent = SliderBack,
                    BackgroundColor3 = Zilk.Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0)
                })

                local function SetValue(val)
                    val = math.clamp(val, opts.Min, opts.Max)
                    if opts.Rounding then
                        val = math.floor((val / opts.Rounding) + 0.5) * opts.Rounding
                    else
                        val = math.floor(val)
                    end
                    Slider.Value = val
                    Label.Text = opts.Text .. " : " .. tostring(val)
                    
                    local pct = (val - opts.Min) / (opts.Max - opts.Min)
                    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                    
                    Zilk.Options[idx] = Slider
                    if opts.Callback then
                        task.spawn(opts.Callback, val)
                    end
                end

                local dragging = false
                SliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)

                Services.UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                Services.UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local pct = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                        local val = opts.Min + (pct * (opts.Max - opts.Min))
                        SetValue(val)
                    end
                end)

                function Slider:SetValue(val)
                    SetValue(val)
                end

                SetValue(Slider.Value)
                return Slider
            end

            function Groupbox:AddDropdown(idx, opts)
                local Dropdown = {Value = opts.Default or nil}
                
                local DropFrame = Create("Frame", {
                    Parent = ElementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 45)
                })

                local Label = Create("TextLabel", {
                    Parent = DropFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0, 0),
                    Size = UDim2.new(1, -10, 0, 15),
                    Font = Enum.Font.Code,
                    Text = opts.Text,
                    TextColor3 = Zilk.Theme.TextMuted,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local DropButton = Create("TextButton", {
                    Parent = DropFrame,
                    BackgroundColor3 = Zilk.Theme.Background,
                    BorderColor3 = Zilk.Theme.Border,
                    Position = UDim2.new(0, 5, 0, 18),
                    Size = UDim2.new(1, -10, 0, 20),
                    Font = Enum.Font.Code,
                    Text = tostring(Dropdown.Value or "Select..."),
                    TextColor3 = Zilk.Theme.Text,
                    TextSize = 13
                })

                local DropList = Create("ScrollingFrame", {
                    Parent = ContentContainer,
                    BackgroundColor3 = Zilk.Theme.SectionBackground,
                    BorderColor3 = Zilk.Theme.Border,
                    ZIndex = 10,
                    Visible = false,
                    ScrollBarThickness = 2
                })
                
                Create("UIListLayout", { Parent = DropList })

                local function UpdateList()
                    for _, child in pairs(DropList:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    local h = 0
                    for _, val in ipairs(opts.Values) do
                        local btn = Create("TextButton", {
                            Parent = DropList,
                            BackgroundColor3 = Zilk.Theme.SectionBackground,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 20),
                            Font = Enum.Font.Code,
                            Text = tostring(val),
                            TextColor3 = Zilk.Theme.TextMuted,
                            TextSize = 13,
                            ZIndex = 11
                        })
                        btn.MouseButton1Click:Connect(function()
                            Dropdown:SetValue(val)
                            DropList.Visible = false
                        end)
                        h = h + 20
                    end
                    DropList.CanvasSize = UDim2.new(0, 0, 0, h)
                    DropList.Size = UDim2.new(0, DropButton.AbsoluteSize.X, 0, math.min(h, 100))
                end

                DropButton.MouseButton1Click:Connect(function()
                    DropList.Visible = not DropList.Visible
                    if DropList.Visible then
                        DropList.Position = UDim2.new(0, DropButton.AbsolutePosition.X - ContentContainer.AbsolutePosition.X, 0, DropButton.AbsolutePosition.Y - ContentContainer.AbsolutePosition.Y + 22)
                        UpdateList()
                    end
                end)

                function Dropdown:SetValue(val)
                    Dropdown.Value = val
                    DropButton.Text = tostring(val)
                    Zilk.Options[idx] = Dropdown
                    if opts.Callback then
                        task.spawn(opts.Callback, val)
                    end
                end

                function Dropdown:SetValues(newVals)
                    opts.Values = newVals
                    UpdateList()
                end

                if Dropdown.Value then Dropdown:SetValue(Dropdown.Value) end
                return Dropdown
            end

            function Groupbox:AddInput(idx, opts)
                local InputOpt = {Value = opts.Default or ""}
                
                local InputFrame = Create("Frame", {
                    Parent = ElementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 45)
                })

                local Label = Create("TextLabel", {
                    Parent = InputFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0, 0),
                    Size = UDim2.new(1, -10, 0, 15),
                    Font = Enum.Font.Code,
                    Text = opts.Text,
                    TextColor3 = Zilk.Theme.TextMuted,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local TextBox = Create("TextBox", {
                    Parent = InputFrame,
                    BackgroundColor3 = Zilk.Theme.Background,
                    BorderColor3 = Zilk.Theme.Border,
                    Position = UDim2.new(0, 5, 0, 18),
                    Size = UDim2.new(1, -10, 0, 20),
                    Font = Enum.Font.Code,
                    Text = InputOpt.Value,
                    TextColor3 = Zilk.Theme.Text,
                    TextSize = 13,
                    ClearTextOnFocus = false
                })

                TextBox.FocusLost:Connect(function()
                    InputOpt.Value = TextBox.Text
                    Zilk.Options[idx] = InputOpt
                    if opts.Callback then
                        task.spawn(opts.Callback, TextBox.Text)
                    end
                end)

                function InputOpt:SetValue(val)
                    TextBox.Text = tostring(val)
                    InputOpt.Value = tostring(val)
                    Zilk.Options[idx] = InputOpt
                    if opts.Callback then task.spawn(opts.Callback, val) end
                end

                Zilk.Options[idx] = InputOpt
                return InputOpt
            end

            function Groupbox:AddButton(text, callback)
                local ButtonFrame = Create("Frame", {
                    Parent = ElementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30)
                })

                local Btn = Create("TextButton", {
                    Parent = ButtonFrame,
                    BackgroundColor3 = Zilk.Theme.Background,
                    BorderColor3 = Zilk.Theme.Border,
                    Position = UDim2.new(0, 5, 0, 5),
                    Size = UDim2.new(1, -10, 0, 20),
                    Font = Enum.Font.Code,
                    Text = text,
                    TextColor3 = Zilk.Theme.Text,
                    TextSize = 13
                })

                Btn.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
            end

            return Groupbox
        end

        return Tab
    end
    
    Window.WindowInstance = ScreenGui
    return Window
end

-- SaveManager Implementation Built-in Zilk
local SaveManager = {}
SaveManager.Folder = Zilk.ConfigFolder

function SaveManager:SetFolder(folder)
    self.Folder = folder
    Zilk.ConfigFolder = folder
end

function SaveManager:CheckFolder()
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
end

function SaveManager:Save(name)
    self:CheckFolder()
    local data = {
        Toggles = {},
        Options = {}
    }
    
    for idx, toggle in pairs(Zilk.Toggles) do
        data.Toggles[idx] = toggle.Value
    end
    for idx, opt in pairs(Zilk.Options) do
        data.Options[idx] = opt.Value
    end
    
    writefile(self.Folder .. "/" .. name .. ".json", Services.HttpService:JSONEncode(data))
end

function SaveManager:Load(name)
    local path = self.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        local success, decoded = pcall(function()
            return Services.HttpService:JSONDecode(readfile(path))
        end)
        
        if success and type(decoded) == "table" then
            if decoded.Toggles then
                for idx, val in pairs(decoded.Toggles) do
                    if Zilk.Toggles[idx] then
                        Zilk.Toggles[idx]:SetValue(val)
                    end
                end
            end
            if decoded.Options then
                for idx, val in pairs(decoded.Options) do
                    if Zilk.Options[idx] then
                        Zilk.Options[idx]:SetValue(val)
                    end
                end
            end
        end
    end
end

function SaveManager:RefreshConfigs()
    self:CheckFolder()
    local configs = {}
    for _, file in ipairs(listfiles(self.Folder)) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(configs, name) end
        end
    end
    return configs
end

function Zilk:BuildSettingsTab(WindowObject)
    local SettingsTab = WindowObject:AddTab("Settings")
    local ConfigBox = SettingsTab:AddGroupbox("Configuration", "Left")
    
    local ConfigInput = ConfigBox:AddInput("ConfigName", {
        Text = "Config Name",
        Default = "Default"
    })
    
    local ConfigDrop = ConfigBox:AddDropdown("ConfigList", {
        Text = "Select Config",
        Values = SaveManager:RefreshConfigs(),
        Default = nil
    })

    ConfigBox:AddButton("Refresh Configs", function()
        ConfigDrop:SetValues(SaveManager:RefreshConfigs())
    end)

    ConfigBox:AddButton("Save Config", function()
        local name = Zilk.Options["ConfigName"].Value
        if name ~= "" then
            SaveManager:Save(name)
            ConfigDrop:SetValues(SaveManager:RefreshConfigs())
        end
    end)
    
    ConfigBox:AddButton("Load Config", function()
        local name = Zilk.Options["ConfigList"].Value
        if name and name ~= "" then
            SaveManager:Load(name)
        end
    end)

    local MenuBox = SettingsTab:AddGroupbox("Menu", "Right")
    MenuBox:AddButton("Unload Zilk", function()
        Zilk:Unload()
    end)
    
    return SettingsTab
end

function Zilk:Unload()
    for _, inst in pairs(self.Instances) do
        if inst and inst.Parent then
            inst:Destroy()
        end
    end
    for _, conn in pairs(self.Connections) do
        conn:Disconnect()
    end
end

Zilk.SaveManager = SaveManager

return Zilk
