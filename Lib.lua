local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Zilk = {
    Toggles = {},
    Options = {},
    Theme = {
        MainColor = Color3.fromRGB(10, 10, 10),
        SectionColor = Color3.fromRGB(20, 20, 20),
        AccentColor = Color3.fromRGB(147, 112, 219),
        TextColor = Color3.fromRGB(240, 240, 240),
        ToggleOnColor = Color3.fromRGB(147, 112, 219),
        ToggleOffColor = Color3.fromRGB(30, 30, 30),
        ButtonColor = Color3.fromRGB(40, 40, 40),
        DropdownColor = Color3.fromRGB(30, 30, 30),
        StrokeColor = Color3.fromRGB(35, 35, 35)
    },
    Registry = {},
    ConfigFolder = "ZilkConfigs",
    MenuBind = Enum.KeyCode.RightShift,
    Tabs = {},
    ActiveTab = nil,
    UI = nil
}

local function Create(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

function Zilk:SetFolder(folder)
    self.ConfigFolder = folder
    local buildPath = ""
    for pathPart in string.gmatch(folder, "[^/\\]+") do
        buildPath = buildPath .. pathPart .. "/"
        if not isfolder(buildPath) then makefolder(buildPath) end
    end
    if self.Options and self.Options.ConfigList then
        self.Options.ConfigList:SetValues(self:GetConfigs())
    end
end

function Zilk:SaveConfig(name)
    local save = { Toggles = {}, Options = {} }
    for i, v in pairs(self.Toggles) do save.Toggles[i] = v.Value end
    for i, v in pairs(self.Options) do 
        if i ~= "ConfigList" and i ~= "ConfigName" then save.Options[i] = v.Value end
    end
    self:SetFolder(self.ConfigFolder)
    writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(save))
end

function Zilk:LoadConfig(name)
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if isfile(path) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success then
            if decoded.Toggles then
                for i, v in pairs(decoded.Toggles) do if self.Toggles[i] then self.Toggles[i]:SetValue(v) end end
            end
            if decoded.Options then
                for i, v in pairs(decoded.Options) do if self.Options[i] then self.Options[i]:SetValue(v) end end
            end
        end
    end
end

function Zilk:GetConfigs()
    if not isfolder(self.ConfigFolder) then self:SetFolder(self.ConfigFolder) end
    if not isfolder(self.ConfigFolder) then return {} end
    local files = listfiles(self.ConfigFolder)
    local names = {}
    for _, file in pairs(files) do
        if file:match("%.json$") then table.insert(names, file:match("([^/\\]+)%.json$")) end
    end
    return names
end

function Zilk:CreateWindow(options)
    local Window = {}
    options = options or {}
    options.Title = options.Title or "HeavN Style UI"
    
    local ScreenGui = Create("ScreenGui", {
        Name = "ZilkUI",
        Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    Zilk.UI = ScreenGui

    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Zilk.Theme.MainColor,
        Position = UDim2.new(0.5, -350, 0.5, -275),
        Size = UDim2.new(0, 700, 0, 550),
        BorderSizePixel = 0,
        Active = true
    })
    
    Create("UICorner", { Parent = MainFrame, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = MainFrame, Color = Zilk.Theme.AccentColor, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })

    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Parent = MainFrame,
        BackgroundColor3 = Zilk.Theme.SectionColor,
        Size = UDim2.new(1, 0, 0, 35),
        BorderSizePixel = 0,
        ZIndex = 2
    })
    Create("UICorner", { Parent = TitleBar, CornerRadius = UDim.new(0, 8) })
    
    -- Hide bottom rounded corners of title bar
    Create("Frame", {
        Parent = TitleBar,
        BackgroundColor3 = Zilk.Theme.SectionColor,
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BorderSizePixel = 0,
        ZIndex = 2
    })

    local TitleText = Create("TextLabel", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Text = options.Title,
        TextColor3 = Zilk.Theme.TextColor,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    })

    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = MainFrame,
        BackgroundColor3 = Zilk.Theme.SectionColor,
        Size = UDim2.new(0, 130, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BorderSizePixel = 0,
        ZIndex = 2
    })
    
    -- Hide top right rounded corner of TabContainer
    Create("Frame", { Parent = TabContainer, BackgroundColor3 = Zilk.Theme.SectionColor, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(1, -8, 0, 0), BorderSizePixel = 0, ZIndex = 2 })
    -- Hide bottom right rounded corner of TabContainer
    Create("Frame", { Parent = TabContainer, BackgroundColor3 = Zilk.Theme.SectionColor, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(1, -8, 1, -8), BorderSizePixel = 0, ZIndex = 2 })

    local TabList = Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    Create("UIPadding", { Parent = TabContainer, PaddingTop = UDim.new(0, 10) })

    local Pages = Create("Frame", {
        Name = "Pages",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -140, 1, -45),
        Position = UDim2.new(0, 135, 0, 40),
        ZIndex = 2
    })
    
    local TabCount = 0

    function Window:AddTab(name, layoutOrder)
        TabCount = TabCount + 1
        local Tab = {}
        local order = layoutOrder or TabCount
        
        local TabButton = Create("TextButton", {
            Parent = TabContainer,
            Size = UDim2.new(0.9, 0, 0, 30),
            BackgroundColor3 = Zilk.Theme.SectionColor,
            Text = name,
            TextColor3 = Zilk.Theme.TextColor,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 10
        })
        Create("UICorner", { Parent = TabButton, CornerRadius = UDim.new(0, 4) })
        
        local TabFrame = Create("ScrollingFrame", {
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
        
        local LeftCol = Create("Frame", { Parent = TabFrame, Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.01, 0, 0, 10), BackgroundTransparency = 1, ZIndex = 5 })
        local LeftList = Create("UIListLayout", { Parent = LeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })
        
        local RightCol = Create("Frame", { Parent = TabFrame, Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.51, 0, 0, 10), BackgroundTransparency = 1, ZIndex = 5 })
        local RightList = Create("UIListLayout", { Parent = RightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Zilk.Tabs) do
                t.Frame.Visible = false
                t.Button.BackgroundColor3 = Zilk.Theme.SectionColor
                t.Button.TextColor3 = Zilk.Theme.TextColor
            end
            TabFrame.Visible = true
            TabButton.BackgroundColor3 = Zilk.Theme.ButtonColor
            TabButton.TextColor3 = Zilk.Theme.AccentColor
            Zilk.ActiveTab = Tab
        end)
        
        if TabCount == 1 and not layoutOrder then
            TabFrame.Visible = true
            TabButton.BackgroundColor3 = Zilk.Theme.ButtonColor
            TabButton.TextColor3 = Zilk.Theme.AccentColor
            Zilk.ActiveTab = Tab
        end
        
        Zilk.Tabs[name] = { Button = TabButton, Frame = TabFrame }
        
        local ColTurn = true
        function Tab:AddGroupbox(gbName)
            local Groupbox = {}
            local targetCol = ColTurn and LeftCol or RightCol
            ColTurn = not ColTurn
            
            local Box = Create("Frame", {
                Parent = targetCol,
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                BorderSizePixel = 0,
                ZIndex = 6
            })
            Create("UICorner", { Parent = Box, CornerRadius = UDim.new(0, 4) })
            Create("UIStroke", { Parent = Box, Color = Zilk.Theme.StrokeColor, Thickness = 1 })
            
            local Header = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                ZIndex = 7
            })
            Create("UICorner", { Parent = Header, CornerRadius = UDim.new(0, 4) })
            
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
                Text = gbName:upper(),
                TextColor3 = Zilk.Theme.AccentColor,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 9
            })
            
            local Container = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundTransparency = 1,
                ZIndex = 7
            })
            local BoxList = Create("UIListLayout", { Parent = Container, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
            
            local function UpdateSize()
                Box.Size = UDim2.new(1, 0, 0, BoxList.AbsoluteContentSize.Y + 40)
                TabFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(LeftList.AbsoluteContentSize.Y, RightList.AbsoluteContentSize.Y) + 20)
            end
            BoxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSize)
            UpdateSize()

            function Groupbox:AddToggle(idx, opts)
                local Toggle = { Value = opts.Default or false, Type = "Toggle" }
                local TFrame = Create("Frame", { Parent = Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25) })
                local TLabel = Create("TextLabel", { Parent = TFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 1, 0), Text = opts.Text or idx, TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
                
                local TBtn = Create("TextButton", { Parent = TFrame, Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -40, 0.5, -10), BackgroundColor3 = Toggle.Value and Zilk.Theme.ToggleOnColor or Zilk.Theme.ToggleOffColor, Text = "" })
                Create("UICorner", { Parent = TBtn, CornerRadius = UDim.new(0, 10) })
                
                local Indicator = Create("Frame", { Parent = TBtn, Size = UDim2.new(0, 16, 0, 16), Position = Toggle.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
                Create("UICorner", { Parent = Indicator, CornerRadius = UDim.new(1, 0) })
                
                function Toggle:SetValue(val)
                    Toggle.Value = val
                    TweenService:Create(TBtn, TweenInfo.new(0.2), { BackgroundColor3 = val and Zilk.Theme.ToggleOnColor or Zilk.Theme.ToggleOffColor }):Play()
                    TweenService:Create(Indicator, TweenInfo.new(0.2), { Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }):Play()
                    if opts.Callback then opts.Callback(val) end
                end
                
                TBtn.MouseButton1Click:Connect(function() Toggle:SetValue(not Toggle.Value) end)
                
                Zilk.Toggles[idx] = Toggle
                return Toggle
            end
            
            function Groupbox:AddSlider(idx, opts)
                local Slider = { Value = opts.Default or opts.Min, Type = "Slider" }
                local SFrame = Create("Frame", { Parent = Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) })
                local SLabel = Create("TextLabel", { Parent = SFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 15), Text = opts.Text or idx, TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
                local SValue = Create("TextLabel", { Parent = SFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 50, 0, 15), Position = UDim2.new(1, -50, 0, 0), Text = tostring(Slider.Value), TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })
                
                local Bg = Create("Frame", { Parent = SFrame, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 25), BackgroundColor3 = Color3.fromRGB(40, 40, 40) })
                Create("UICorner", { Parent = Bg, CornerRadius = UDim.new(1, 0) })
                
                local pct = (Slider.Value - opts.Min) / (opts.Max - opts.Min)
                local Fill = Create("Frame", { Parent = Bg, Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = Zilk.Theme.AccentColor })
                Create("UICorner", { Parent = Fill, CornerRadius = UDim.new(1, 0) })
                
                local Btn = Create("TextButton", { Parent = Bg, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" })
                
                function Slider:SetValue(val)
                    val = math.clamp(val, opts.Min, opts.Max)
                    if opts.Rounding then val = math.floor(val + 0.5) else val = math.floor(val * 10) / 10 end
                    Slider.Value = val
                    Fill.Size = UDim2.new((val - opts.Min) / (opts.Max - opts.Min), 0, 1, 0)
                    SValue.Text = tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end
                
                local dragging = false
                Btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Slider:SetValue(opts.Min + math.clamp((input.Position.X - Bg.AbsolutePosition.X) / Bg.AbsoluteSize.X, 0, 1) * (opts.Max - opts.Min)) end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Slider:SetValue(opts.Min + math.clamp((input.Position.X - Bg.AbsolutePosition.X) / Bg.AbsoluteSize.X, 0, 1) * (opts.Max - opts.Min))
                    end
                end)
                
                Zilk.Options[idx] = Slider
                return Slider
            end
            
            function Groupbox:AddDropdown(idx, opts)
                local Dropdown = { Value = opts.Default, Type = "Dropdown" }
                local DFrame = Create("Frame", { Parent = Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50) })
                local DLabel = Create("TextLabel", { Parent = DFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Text = opts.Text or idx, TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
                
                local MainBtn = Create("TextButton", { Parent = DFrame, Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 25), BackgroundColor3 = Zilk.Theme.DropdownColor, Text = "  " .. tostring(Dropdown.Value or "None"), TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
                Create("UICorner", { Parent = MainBtn, CornerRadius = UDim.new(0, 4) })
                Create("UIStroke", { Parent = MainBtn, Color = Color3.fromRGB(45, 45, 45), Thickness = 1 })
                
                local DropContainer = Create("ScrollingFrame", { Parent = ScreenGui, Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Zilk.Theme.SectionColor, Visible = false, ZIndex = 100, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0) })
                Create("UICorner", { Parent = DropContainer, CornerRadius = UDim.new(0, 4) })
                Create("UIStroke", { Parent = DropContainer, Color = Zilk.Theme.StrokeColor, Thickness = 1 })
                local DropList = Create("UIListLayout", { Parent = DropContainer, SortOrder = Enum.SortOrder.LayoutOrder })
                
                local open = false
                
                local function UpdateList()
                    for _, v in pairs(DropContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                    local count = 0
                    for _, v in pairs(opts.Values or {}) do
                        count = count + 1
                        local item = Create("TextButton", { Parent = DropContainer, Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = "  " .. tostring(v), TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101 })
                        item.MouseButton1Click:Connect(function() Dropdown:SetValue(v); open = false; DropContainer.Visible = false end)
                    end
                    local targetH = math.min(count * 25, 100)
                    DropContainer.Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, targetH)
                    DropContainer.CanvasSize = UDim2.new(0, 0, 0, count * 25)
                end
                UpdateList()
                
                function Dropdown:SetValue(val)
                    Dropdown.Value = val
                    MainBtn.Text = "  " .. tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end
                function Dropdown:SetValues(vals) opts.Values = vals; UpdateList() end
                
                MainBtn.MouseButton1Click:Connect(function()
                    open = not open
                    DropContainer.Visible = open
                    if open then
                        DropContainer.Position = UDim2.new(0, MainBtn.AbsolutePosition.X, 0, MainBtn.AbsolutePosition.Y + 28)
                        DropContainer.Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, math.min(#(opts.Values or {}) * 25, 100))
                    end
                end)
                
                Zilk.Options[idx] = Dropdown
                return Dropdown
            end

            function Groupbox:AddButton(text, cb)
                local BFrame = Create("Frame", { Parent = Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30) })
                local Btn = Create("TextButton", { Parent = BFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Zilk.Theme.ButtonColor, Text = text, TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.GothamBold, TextSize = 12 })
                Create("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 4) })
                Create("UIStroke", { Parent = Btn, Color = Color3.fromRGB(50, 50, 50), Thickness = 1 })
                Btn.MouseButton1Click:Connect(function() if cb then cb() end end)
            end
            
            function Groupbox:AddInput(idx, opts)
                local Input = { Value = opts.Default or "", Type = "Input" }
                local IFrame = Create("Frame", { Parent = Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50) })
                local ILabel = Create("TextLabel", { Parent = IFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Text = opts.Text or idx, TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
                local IBox = Create("TextBox", { Parent = IFrame, Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 25), BackgroundColor3 = Zilk.Theme.DropdownColor, Text = Input.Value, TextColor3 = Zilk.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
                Create("UICorner", { Parent = IBox, CornerRadius = UDim.new(0, 4) })
                Create("UIStroke", { Parent = IBox, Color = Color3.fromRGB(45, 45, 45), Thickness = 1 })
                Create("UIPadding", { Parent = IBox, PaddingLeft = UDim.new(0, 8) })
                
                IBox.FocusLost:Connect(function() Input.Value = IBox.Text; if opts.Callback then opts.Callback(Input.Value) end end)
                function Input:SetValue(val) Input.Value = val; IBox.Text = tostring(val); if opts.Callback then opts.Callback(val) end end
                
                Zilk.Options[idx] = Input
                return Input
            end

            return Groupbox
        end
        return Tab
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Zilk.MenuBind then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    -- Auto generate Settings and Configs tabs
    local SettingsTab = Window:AddTab("Settings", 998)
    local ConfigTab = Window:AddTab("Configs", 999)
    
    local SGroup = SettingsTab:AddGroupbox("Menu Settings")
    SGroup:AddButton("Unload", function() Zilk.UI:Destroy() end)
    
    local CGroup = ConfigTab:AddGroupbox("Config Manager")
    CGroup:AddInput("ConfigName", { Text = "Config Name" })
    CGroup:AddDropdown("ConfigList", { Text = "Configs", Values = Zilk:GetConfigs() })
    CGroup:AddButton("Save Config", function()
        local name = Zilk.Options.ConfigName.Value
        if name and name ~= "" then
            Zilk:SaveConfig(name)
            Zilk.Options.ConfigList:SetValues(Zilk:GetConfigs())
        end
    end)
    CGroup:AddButton("Load Config", function()
        local name = Zilk.Options.ConfigList.Value
        if name and name ~= "None" then Zilk:LoadConfig(name) end
    end)
    CGroup:AddButton("Refresh Configs", function() Zilk.Options.ConfigList:SetValues(Zilk:GetConfigs()) end)

    return Window
end

return Zilk
