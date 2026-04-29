local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Zilk = {
    Toggles = {},
    Options = {},
    Theme = {
        Accent = Color3.fromRGB(85, 170, 255),
        Background = Color3.fromRGB(20, 20, 20),
        Container = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(45, 45, 45),
        Dark = Color3.fromRGB(15, 15, 15),
        Hover = Color3.fromRGB(40, 40, 40)
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
        if not isfolder(buildPath) then
            makefolder(buildPath)
        end
    end
    if self.Options and self.Options.ConfigList then
        self.Options.ConfigList:SetValues(self:GetConfigs())
    end
end

function Zilk:SaveConfig(name)
    local save = { Toggles = {}, Options = {} }
    for i, v in pairs(self.Toggles) do save.Toggles[i] = v.Value end
    for i, v in pairs(self.Options) do 
        if i ~= "ConfigList" and i ~= "ConfigName" then 
            save.Options[i] = v.Value 
        end
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
        if file:match("%.json$") then
            table.insert(names, file:match("([^/\\]+)%.json$"))
        end
    end
    return names
end

function Zilk:CreateWindow(options)
    local Window = {}
    options = options or {}
    options.Title = options.Title or "Zilk Lib"
    
    local ScreenGui = Create("ScreenGui", {
        Name = "ZilkUI",
        Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui,
        ResetOnSpawn = false,
        DisplayOrder = 100
    })
    Zilk.UI = ScreenGui

    local MainFrame = Create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        BackgroundColor3 = Zilk.Theme.Background,
        Position = UDim2.new(0.5, -275, 0.5, -175),
        Size = UDim2.new(0, 550, 0, 350),
        Active = true
    })
    
    Create("UIStroke", { Parent = MainFrame, Color = Zilk.Theme.Outline, Thickness = 1 })

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

    local Topbar = Create("Frame", {
        Name = "Topbar",
        Parent = MainFrame,
        BackgroundColor3 = Zilk.Theme.Dark,
        Size = UDim2.new(1, 0, 0, 25),
        BorderSizePixel = 0
    })
    
    Create("Frame", {
        Name = "Line",
        Parent = Topbar,
        BackgroundColor3 = Zilk.Theme.Accent,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0
    })

    local TitleLabel = Create("TextLabel", {
        Parent = Topbar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Text = options.Title,
        TextColor3 = Zilk.Theme.Accent,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = MainFrame,
        BackgroundColor3 = Zilk.Theme.Container,
        Size = UDim2.new(0, 130, 1, -26),
        Position = UDim2.new(0, 0, 0, 26),
        BorderSizePixel = 0
    })
    
    Create("Frame", {
        Name = "Line",
        Parent = TabContainer,
        BackgroundColor3 = Zilk.Theme.Outline,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BorderSizePixel = 0
    })

    local TabList = Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -131, 1, -26),
        Position = UDim2.new(0, 131, 0, 26)
    })
    
    local TabCount = 0

    function Window:AddTab(name, layoutOrder)
        TabCount = TabCount + 1
        local Tab = {}
        local order = layoutOrder or TabCount
        
        local TabButton = Create("TextButton", {
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Zilk.Theme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            LayoutOrder = order
        })
        
        local TabFrame = Create("ScrollingFrame", {
            Parent = ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = Zilk.Theme.Accent
        })
        
        local LeftLayout = Create("UIListLayout", {
            Parent = TabFrame,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Vertical
        })
        Create("UIPadding", { Parent = TabFrame, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) })

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Zilk.Tabs) do
                t.Frame.Visible = false
                t.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
                t.Button.BackgroundColor3 = Zilk.Theme.Container
                t.Button.BackgroundTransparency = 1
            end
            TabFrame.Visible = true
            TabButton.TextColor3 = Zilk.Theme.Accent
            TabButton.BackgroundColor3 = Zilk.Theme.Dark
            TabButton.BackgroundTransparency = 0
            Zilk.ActiveTab = Tab
        end)
        
        if TabCount == 1 and not layoutOrder then
            TabFrame.Visible = true
            TabButton.TextColor3 = Zilk.Theme.Accent
            TabButton.BackgroundColor3 = Zilk.Theme.Dark
            TabButton.BackgroundTransparency = 0
            Zilk.ActiveTab = Tab
        else
            TabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        
        Zilk.Tabs[name] = { Button = TabButton, Frame = TabFrame }
        
        function Tab:AddGroupbox(gbName)
            local Groupbox = {}
            local Box = Create("Frame", {
                Parent = TabFrame,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundColor3 = Zilk.Theme.Container,
                BorderColor3 = Zilk.Theme.Outline
            })
            Create("UIStroke", { Parent = Box, Color = Zilk.Theme.Outline, Thickness = 1 })
            
            local BoxTitle = Create("TextLabel", {
                Parent = Box,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 0, 0),
                Text = gbName,
                TextColor3 = Zilk.Theme.Accent,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local BoxLine = Create("Frame", {
                Parent = Box,
                BackgroundColor3 = Zilk.Theme.Outline,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 0, 20),
                BorderSizePixel = 0
            })
            
            local BoxContent = Create("Frame", {
                Parent = Box,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, -21),
                Position = UDim2.new(0, 0, 0, 21)
            })
            
            local BoxList = Create("UIListLayout", { Parent = BoxContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
            Create("UIPadding", { Parent = BoxContent, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
            
            BoxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Box.Size = UDim2.new(1, 0, 0, BoxList.AbsoluteContentSize.Y + 37)
                TabFrame.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y + 20)
            end)

            function Groupbox:AddToggle(idx, opts)
                local Toggle = { Value = opts.Default or false, Type = "Toggle" }
                local TFrame = Create("Frame", { Parent = BoxContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16) })
                local TBox = Create("Frame", { Parent = TFrame, Size = UDim2.new(0, 16, 0, 16), BackgroundColor3 = Toggle.Value and Zilk.Theme.Accent or Zilk.Theme.Dark })
                Create("UIStroke", { Parent = TBox, Color = Zilk.Theme.Outline, Thickness = 1 })
                local TLabel = Create("TextLabel", { Parent = TFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -25, 1, 0), Position = UDim2.new(0, 25, 0, 0), Text = opts.Text or idx, TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local TButton = Create("TextButton", { Parent = TFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" })
                
                function Toggle:SetValue(val)
                    Toggle.Value = val
                    TBox.BackgroundColor3 = val and Zilk.Theme.Accent or Zilk.Theme.Dark
                    if opts.Callback then opts.Callback(val) end
                end
                
                function Toggle:OnChanged(cb) opts.Callback = cb end
                
                TButton.MouseButton1Click:Connect(function() Toggle:SetValue(not Toggle.Value) end)
                
                Zilk.Toggles[idx] = Toggle
                return Toggle
            end
            
            function Groupbox:AddSlider(idx, opts)
                local Slider = { Value = opts.Default or opts.Min, Type = "Slider" }
                local SFrame = Create("Frame", { Parent = BoxContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35) })
                local SLabel = Create("TextLabel", { Parent = SFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Text = opts.Text or idx, TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local SValue = Create("TextLabel", { Parent = SFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Text = tostring(Slider.Value), TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
                local SBar = Create("Frame", { Parent = SFrame, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 0, 20), BackgroundColor3 = Zilk.Theme.Dark })
                Create("UIStroke", { Parent = SBar, Color = Zilk.Theme.Outline, Thickness = 1 })
                local SFill = Create("Frame", { Parent = SBar, Size = UDim2.new((Slider.Value - opts.Min) / (opts.Max - opts.Min), 0, 1, 0), BackgroundColor3 = Zilk.Theme.Accent, BorderSizePixel = 0 })
                local SButton = Create("TextButton", { Parent = SBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" })
                
                function Slider:SetValue(val)
                    val = math.clamp(val, opts.Min, opts.Max)
                    if opts.Rounding then val = math.floor(val + 0.5) else val = math.floor(val * 10) / 10 end
                    Slider.Value = val
                    SFill.Size = UDim2.new((val - opts.Min) / (opts.Max - opts.Min), 0, 1, 0)
                    SValue.Text = tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end
                
                function Slider:OnChanged(cb) opts.Callback = cb end
                
                local dragging = false
                SButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Slider:SetValue(opts.Min + math.clamp((input.Position.X - SBar.AbsolutePosition.X) / SBar.AbsoluteSize.X, 0, 1) * (opts.Max - opts.Min)) end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Slider:SetValue(opts.Min + math.clamp((input.Position.X - SBar.AbsolutePosition.X) / SBar.AbsoluteSize.X, 0, 1) * (opts.Max - opts.Min))
                    end
                end)
                
                Zilk.Options[idx] = Slider
                return Slider
            end
            
            function Groupbox:AddDropdown(idx, opts)
                local Dropdown = { Value = opts.Default, Type = "Dropdown" }
                local DFrame = Create("Frame", { Parent = BoxContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45) })
                local DLabel = Create("TextLabel", { Parent = DFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Text = opts.Text or idx, TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local DBox = Create("Frame", { Parent = DFrame, Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 20), BackgroundColor3 = Zilk.Theme.Dark })
                Create("UIStroke", { Parent = DBox, Color = Zilk.Theme.Outline, Thickness = 1 })
                local DValue = Create("TextLabel", { Parent = DBox, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), Text = tostring(Dropdown.Value or "None"), TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local DButton = Create("TextButton", { Parent = DBox, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" })
                
                local DropContainer = Create("ScrollingFrame", { Parent = ScreenGui, Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Zilk.Theme.Container, Visible = false, ZIndex = 10, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0) })
                Create("UIStroke", { Parent = DropContainer, Color = Zilk.Theme.Outline, Thickness = 1 })
                local DropList = Create("UIListLayout", { Parent = DropContainer, SortOrder = Enum.SortOrder.LayoutOrder })
                
                local open = false
                
                local function UpdateList()
                    for _, v in pairs(DropContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                    local count = 0
                    for _, v in pairs(opts.Values or {}) do
                        count = count + 1
                        local item = Create("TextButton", { Parent = DropContainer, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, BorderSizePixel = 0, Text = " " .. tostring(v), TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 })
                        item.MouseButton1Click:Connect(function()
                            Dropdown:SetValue(v)
                            open = false
                            DropContainer.Visible = false
                        end)
                    end
                    local targetH = math.min(count * 20, 100)
                    DropContainer.Size = UDim2.new(0, DBox.AbsoluteSize.X, 0, targetH)
                    DropContainer.CanvasSize = UDim2.new(0, 0, 0, count * 20)
                end
                UpdateList()
                
                function Dropdown:SetValue(val)
                    Dropdown.Value = val
                    DValue.Text = tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end
                
                function Dropdown:SetValues(vals)
                    opts.Values = vals
                    UpdateList()
                end
                
                function Dropdown:OnChanged(cb) opts.Callback = cb end
                
                DButton.MouseButton1Click:Connect(function()
                    open = not open
                    DropContainer.Visible = open
                    if open then
                        DropContainer.Position = UDim2.new(0, DBox.AbsolutePosition.X, 0, DBox.AbsolutePosition.Y + 27)
                        DropContainer.Size = UDim2.new(0, DBox.AbsoluteSize.X, 0, math.min(#(opts.Values or {}) * 20, 100))
                    end
                end)
                
                Zilk.Options[idx] = Dropdown
                return Dropdown
            end

            function Groupbox:AddButton(text, cb)
                local BFrame = Create("Frame", { Parent = BoxContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25) })
                local Btn = Create("TextButton", { Parent = BFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Zilk.Theme.Dark, Text = text, TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13 })
                Create("UIStroke", { Parent = Btn, Color = Zilk.Theme.Outline, Thickness = 1 })
                Btn.MouseButton1Click:Connect(function() if cb then cb() end end)
            end
            
            function Groupbox:AddInput(idx, opts)
                local Input = { Value = opts.Default or "", Type = "Input" }
                local IFrame = Create("Frame", { Parent = BoxContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45) })
                local ILabel = Create("TextLabel", { Parent = IFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Text = opts.Text or idx, TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local IBox = Create("TextBox", { Parent = IFrame, Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 20), BackgroundColor3 = Zilk.Theme.Dark, Text = Input.Value, TextColor3 = Zilk.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
                Create("UIStroke", { Parent = IBox, Color = Zilk.Theme.Outline, Thickness = 1 })
                Create("UIPadding", { Parent = IBox, PaddingLeft = UDim.new(0, 5) })
                
                IBox.FocusLost:Connect(function()
                    Input.Value = IBox.Text
                    if opts.Callback then opts.Callback(Input.Value) end
                end)
                
                function Input:SetValue(val)
                    Input.Value = val
                    IBox.Text = tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end
                
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

    -- Automatically append Settings and Configs tabs as requested
    local SettingsTab = Window:AddTab("Settings", 998)
    local ConfigTab = Window:AddTab("Configs", 999)
    
    local SGroup = SettingsTab:AddGroupbox("Menu Settings")
    SGroup:AddButton("Unload", function()
        Zilk.UI:Destroy()
    end)
    
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
        if name and name ~= "None" then
            Zilk:LoadConfig(name)
        end
    end)
    
    CGroup:AddButton("Refresh Configs", function()
        Zilk.Options.ConfigList:SetValues(Zilk:GetConfigs())
    end)

    return Window
end

return Zilk
