-- ZilkLib.lua
-- A complete UI library for Roblox exploits
-- Repository: https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/refs/heads/main/Lib.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Protect GUI if available
local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.Name = "ZilkLib"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

-- Global registry
local Toggles = {}
local Options = {}
getgenv().ZilkToggles = Toggles
getgenv().ZilkOptions = Options

-- Helper functions
local function GetTextBounds(Text, Font, Size)
    local bounds = TextService:GetTextSize(Text, Size, Font or Enum.Font.Gotham, Vector2.new(1920, 1080))
    return bounds.X, bounds.Y
end

local function GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end

local function GetLighterColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, math.min(V * 1.3, 1))
end

-- Library table
local Zilk = {
    Registry = {},
    RegistryMap = {},
    Configs = {},
    Notifications = {},
    Signals = {},
    OpenedFrames = {},
    
    -- Default colors (matching HeavN/Blade style)
    FontColor = Color3.fromRGB(240, 240, 240),
    MainColor = Color3.fromRGB(10, 10, 10),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    SectionColor = Color3.fromRGB(18, 18, 18),
    AccentColor = Color3.fromRGB(147, 112, 219),
    OutlineColor = Color3.fromRGB(35, 35, 35),
    DangerColor = Color3.fromRGB(255, 70, 70),
    SuccessColor = Color3.fromRGB(70, 255, 70),
    ButtonColor = Color3.fromRGB(40, 40, 40),
    DropdownColor = Color3.fromRGB(30, 30, 30),
    SliderColor = Color3.fromRGB(147, 112, 219),
    ToggleOnColor = Color3.fromRGB(255, 255, 255),
    ToggleOffColor = Color3.fromRGB(30, 30, 30),
    
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    
    ScreenGui = ScreenGui,
    
    -- Config system
    ConfigFolder = "Zilk",
    CurrentConfigName = nil,
    ConfigEdited = false,
    
    -- UI References
    UIReferences = {
        toggles = {},
        sliders = {},
        dropdowns = {},
        keybinds = {},
        colorPreviews = {},
        groupBoxes = {},
    },
    
    -- Watermark
    Watermark = nil,
    WatermarkLabel = nil,
}

-- Add to registry for dynamic color updates
function Zilk:AddToRegistry(Instance, Properties)
    local Data = {
        Instance = Instance,
        Properties = Properties,
    }
    table.insert(self.Registry, Data)
    self.RegistryMap[Instance] = Data
end

function Zilk:RemoveFromRegistry(Instance)
    local Data = self.RegistryMap[Instance]
    if Data then
        for i = #self.Registry, 1, -1 do
            if self.Registry[i] == Data then
                table.remove(self.Registry, i)
                break
            end
        end
        self.RegistryMap[Instance] = nil
    end
end

function Zilk:UpdateColors()
    for _, Object in ipairs(self.Registry) do
        for Property, ColorRef in pairs(Object.Properties) do
            if type(ColorRef) == "string" then
                Object.Instance[Property] = self[ColorRef]
            elseif type(ColorRef) == "function" then
                Object.Instance[Property] = ColorRef()
            end
        end
    end
end

-- Create styled instance
function Zilk:Create(Class, Properties)
    local Inst = type(Class) == "string" and Instance.new(Class) or Class
    for Prop, Value in pairs(Properties or {}) do
        Inst[Prop] = Value
    end
    return Inst
end

function Zilk:CreateLabel(Properties)
    local Label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = self.Font,
        TextColor3 = self.FontColor,
        TextSize = 14,
        TextStrokeTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    self:AddToRegistry(Label, { TextColor3 = "FontColor" })
    
    for Prop, Value in pairs(Properties or {}) do
        Label[Prop] = Value
    end
    
    return Label
end

-- Add corner radius
function Zilk:AddCorner(Instance, Radius)
    local Corner = self:Create("UICorner", {
        CornerRadius = UDim.new(0, Radius or 4),
        Parent = Instance,
    })
    return Corner
end

-- Add stroke
function Zilk:AddStroke(Instance, Color, Thickness)
    local Stroke = self:Create("UIStroke", {
        Color = Color or self.OutlineColor,
        Thickness = Thickness or 1,
        Parent = Instance,
    })
    return Stroke
end

-- Make frame draggable
function Zilk:MakeDraggable(Frame, TopCutoff)
    local dragging = false
    local dragStart = Vector2.new()
    local frameStart = UDim2.new()
    
    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local framePos = Vector2.new(Frame.AbsolutePosition.X, Frame.AbsolutePosition.Y)
            
            if mousePos.Y - framePos.Y <= (TopCutoff or 30) then
                dragging = true
                dragStart = mousePos
                frameStart = Frame.Position
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local delta = Vector2.new(Mouse.X, Mouse.Y) - dragStart
            Frame.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
end

-- Check if any frame is open
function Zilk:IsAnyFrameOpen()
    for Frame, _ in pairs(self.OpenedFrames) do
        if Frame and Frame.Parent and Frame.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local framePos = Frame.AbsolutePosition
            local frameSize = Frame.AbsoluteSize
            
            if mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
               mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y then
                return true
            end
        end
    end
    return false
end

-- Add tooltip
function Zilk:AddTooltip(Text, HoverInstance)
    local X, Y = GetTextBounds(Text, self.Font, 12)
    
    local Tooltip = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderColor3 = self.AccentColor,
        Size = UDim2.new(0, X + 12, 0, Y + 6),
        Visible = false,
        ZIndex = 1000,
        Parent = self.ScreenGui,
    })
    
    self:AddCorner(Tooltip, 4)
    self:AddToRegistry(Tooltip, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "AccentColor",
    })
    
    local Label = self:CreateLabel({
        Position = UDim2.new(0, 6, 0, 3),
        Size = UDim2.new(0, X, 0, Y),
        Text = Text,
        TextSize = 12,
        Parent = Tooltip,
    })
    
    local isHovering = false
    
    HoverInstance.MouseEnter:Connect(function()
        if self:IsAnyFrameOpen() then return end
        isHovering = true
        Tooltip.Visible = true
        
        while isHovering and Tooltip.Parent do
            Tooltip.Position = UDim2.new(0, Mouse.X + 15, 0, Mouse.Y + 12)
            RunService.Heartbeat:Wait()
        end
    end)
    
    HoverInstance.MouseLeave:Connect(function()
        isHovering = false
        Tooltip.Visible = false
    end)
end

-- Notification system
function Zilk:Notify(Title, Message, Duration, Color)
    if not self.NotifContainer then
        self.NotifContainer = self:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.75, 0, 0.05, 0),
            Size = UDim2.new(0, 300, 1, -40),
            Parent = self.ScreenGui,
        })
        
        self:Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.NotifContainer,
        })
    end
    
    local Notif = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, 70),
        LayoutOrder = -tick(),
        Parent = self.NotifContainer,
    })
    
    self:AddCorner(Notif, 6)
    self:AddStroke(Notif, Color or self.AccentColor, 1.5)
    self:AddToRegistry(Notif, { BackgroundColor3 = "MainColor" })
    
    local TitleLabel = self:CreateLabel({
        Position = UDim2.new(0, 10, 0, 8),
        Size = UDim2.new(1, -20, 0, 22),
        Text = Title,
        TextSize = 14,
        Font = self.FontBold,
        TextColor3 = Color or self.AccentColor,
        Parent = Notif,
    })
    
    self:AddToRegistry(TitleLabel, { TextColor3 = "AccentColor" })
    
    local MsgLabel = self:CreateLabel({
        Position = UDim2.new(0, 10, 0, 32),
        Size = UDim2.new(1, -20, 0, 30),
        Text = Message,
        TextSize = 12,
        TextWrapped = true,
        Parent = Notif,
    })
    
    TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.1
    }):Play()
    
    table.insert(self.Notifications, Notif)
    
    task.delay(Duration or 3, function()
        if Notif and Notif.Parent then
            TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.3)
            Notif:Destroy()
            
            for i, n in ipairs(self.Notifications) do
                if n == Notif then
                    table.remove(self.Notifications, i)
                    break
                end
            end
        end
    end)
end

-- Watermark
function Zilk:CreateWatermark(Text)
    local Watermark = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderColor3 = self.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0.01, 0, 0.01, 0),
        Size = UDim2.new(0, 180, 0, 24),
        Parent = self.ScreenGui,
    })
    
    self:AddCorner(Watermark, 4)
    self:AddToRegistry(Watermark, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "AccentColor",
    })
    
    local Label = self:CreateLabel({
        Size = UDim2.new(1, -6, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        Text = Text,
        TextSize = 12,
        Parent = Watermark,
    })
    
    self:MakeDraggable(Watermark, 24)
    self.Watermark = Watermark
    self.WatermarkLabel = Label
    
    return Label
end

function Zilk:UpdateWatermark(Text)
    if self.WatermarkLabel then
        self.WatermarkLabel.Text = Text
    end
end

function Zilk:SetWatermarkVisibility(Visible)
    if self.Watermark then
        self.Watermark.Visible = Visible
    end
end

-- ============================================================================
-- CONFIG SYSTEM
-- ============================================================================

local function EnsureConfigFolder()
    if not isfolder then return false end
    if not isfolder(Zilk.ConfigFolder) then
        makefolder(Zilk.ConfigFolder)
    end
    return true
end

function Zilk:GetAllSettings()
    local Settings = {}
    
    for Name, Toggle in pairs(Toggles) do
        if Toggle and Toggle.Value ~= nil then
            Settings[Name] = Toggle.Value
        end
    end
    
    for Name, Option in pairs(Options) do
        if Option and Option.Value ~= nil then
            Settings[Name] = Option.Value
        end
    end
    
    return Settings
end

function Zilk:ApplySettings(Settings)
    for Name, Value in pairs(Settings) do
        if Toggles[Name] then
            Toggles[Name]:SetValue(Value)
        elseif Options[Name] then
            Options[Name]:SetValue(Value)
        end
    end
    self.ConfigEdited = false
    return true
end

function Zilk:SaveConfig(Name)
    if not EnsureConfigFolder() then
        self:Notify("Config Error", "File system not available", 2, self.DangerColor)
        return false
    end
    
    local Settings = self:GetAllSettings()
    local JSON = HttpService:JSONEncode(Settings)
    local Path = string.format("%s/%s.zcfg", self.ConfigFolder, Name)
    
    local Success, Err = pcall(writefile, Path, JSON)
    if Success then
        self.CurrentConfigName = Name
        self.ConfigEdited = false
        self:Notify("Config Saved", string.format("Saved config: %s", Name), 2, self.SuccessColor)
        return true
    else
        self:Notify("Config Error", string.format("Failed to save: %s", tostring(Err)), 2, self.DangerColor)
        return false
    end
end

function Zilk:LoadConfig(Name)
    if not EnsureConfigFolder() then
        self:Notify("Config Error", "File system not available", 2, self.DangerColor)
        return false
    end
    
    local Path = string.format("%s/%s.zcfg", self.ConfigFolder, Name)
    if not isfile(Path) then
        self:Notify("Config Error", "Config not found", 2, self.DangerColor)
        return false
    end
    
    local Content = readfile(Path)
    local Success, Settings = pcall(HttpService.JSONDecode, HttpService, Content)
    
    if Success and type(Settings) == "table" then
        self:ApplySettings(Settings)
        self.CurrentConfigName = Name
        self.ConfigEdited = false
        self:Notify("Config Loaded", string.format("Loaded config: %s", Name), 2, self.SuccessColor)
        return true
    else
        self:Notify("Config Error", "Invalid config file", 2, self.DangerColor)
        return false
    end
end

function Zilk:DeleteConfig(Name)
    if not EnsureConfigFolder() then return false end
    
    local Path = string.format("%s/%s.zcfg", self.ConfigFolder, Name)
    if isfile(Path) then
        delfile(Path)
        if self.CurrentConfigName == Name then
            self.CurrentConfigName = nil
        end
        self:Notify("Config Deleted", string.format("Deleted config: %s", Name), 2, Color3.fromRGB(255, 165, 0))
        return true
    end
    return false
end

function Zilk:ListConfigs()
    if not EnsureConfigFolder() then return {} end
    
    local Configs = {}
    local Files = listfiles(self.ConfigFolder)
    
    for _, File in ipairs(Files) do
        local Name = File:match("([^/\\]+)%.zcfg$")
        if Name then
            table.insert(Configs, Name)
        end
    end
    
    table.sort(Configs)
    return Configs
end

-- Give signal for cleanup
function Zilk:GiveSignal(Signal)
    table.insert(self.Signals, Signal)
end

-- ============================================================================
-- WINDOW CREATION
-- ============================================================================

function Zilk:CreateWindow(Config)
    Config = Config or {}
    Config.Title = Config.Title or "Zilk Menu"
    Config.Size = Config.Size or UDim2.new(0, 600, 0, 550)
    Config.Center = Config.Center ~= false
    Config.AutoShow = Config.AutoShow == true
    Config.TabPadding = Config.TabPadding or 8
    Config.FadeTime = Config.FadeTime or 0.2
    
    local Window = {
        Tabs = {},
        Elements = {},
    }
    
    -- Main frame
    local MainFrame = self:Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Position = Config.Center and UDim2.new(0.5, -Config.Size.X.Offset/2, 0.5, -Config.Size.Y.Offset/2) or UDim2.new(0, 100, 0, 50),
        Size = Config.Size,
        Visible = Config.AutoShow,
        Parent = self.ScreenGui,
    })
    
    self:MakeDraggable(MainFrame, 30)
    self:AddCorner(MainFrame, 8)
    self:AddStroke(MainFrame, self.AccentColor, 2)
    
    -- Inner frame
    local InnerFrame = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        Parent = MainFrame,
    })
    
    self:AddCorner(InnerFrame, 7)
    self:AddToRegistry(InnerFrame, { BackgroundColor3 = "MainColor" })
    
    -- Title bar (matching HeavN style)
    local TitleBar = self:Create("Frame", {
        BackgroundColor3 = self.SectionColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 35),
        Parent = InnerFrame,
    })
    
    self:AddCorner(TitleBar, 7)
    self:AddToRegistry(TitleBar, { BackgroundColor3 = "SectionColor" })
    
    -- Title text
    local TitleLabel = self:CreateLabel({
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Text = Config.Title,
        TextSize = 18,
        Font = self.FontBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = TitleBar,
    })
    
    -- Tab area (left sidebar style like HeavN)
    local TabContainer = self:Create("Frame", {
        BackgroundColor3 = self.SectionColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(0, 100, 1, -35),
        Parent = InnerFrame,
    })
    
    self:AddCorner(TabContainer, 7)
    self:AddToRegistry(TabContainer, { BackgroundColor3 = "SectionColor" })
    
    local TabLayout = self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabContainer,
    })
    
    -- Content area
    local ContentContainer = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 105, 0, 40),
        Size = UDim2.new(1, -115, 1, -50),
        Parent = InnerFrame,
    })
    
    -- Content scrolling frame
    local ContentScrolling = self:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.AccentColor,
        Parent = ContentContainer,
    })
    
    self:AddToRegistry(ContentScrolling, { ScrollBarImageColor3 = "AccentColor" })
    
    -- Two column layout
    local function CreateColumn(Parent, Side)
        local Column = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.49, 0, 1, 0),
            Position = Side == "Left" and UDim2.new(0, 0, 0, 0) or UDim2.new(0.51, 0, 0, 0),
            Parent = Parent,
        })
        
        local Layout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Column,
        })
        
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Parent.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
        end)
        
        return Column, Layout
    end
    
    local function ShowTab(TabName)
        for Name, Tab in pairs(Window.Tabs) do
            if Name == TabName then
                Tab.Container.Visible = true
                if Tab.Button then
                    Tab.Button.BackgroundColor3 = self.MainColor
                    self:AddToRegistry(Tab.Button, { BackgroundColor3 = "MainColor" })
                end
            else
                Tab.Container.Visible = false
                if Tab.Button then
                    Tab.Button.BackgroundColor3 = self.SectionColor
                    self:AddToRegistry(Tab.Button, { BackgroundColor3 = "SectionColor" })
                end
            end
        end
    end
    
    -- Add tab function
    function Window:AddTab(Name)
        local Tab = {
            Name = Name,
            Elements = {},
        }
        
        -- Tab button (sidebar style)
        local Button = self:Create("TextButton", {
            BackgroundColor3 = #Window.Tabs == 0 and self.MainColor or self.SectionColor,
            TextColor3 = self.FontColor,
            Font = self.FontBold,
            TextSize = 13,
            Size = UDim2.new(0.9, 0, 0, 32),
            Text = Name,
            BorderSizePixel = 0,
            Parent = TabContainer,
        })
        
        self:AddCorner(Button, 6)
        self:AddToRegistry(Button, {
            BackgroundColor3 = "MainColor",
            TextColor3 = "FontColor",
        })
        
        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundTransparency = 0.7 }):Play()
        end)
        
        Button.MouseLeave:Connect(function()
            if Button.BackgroundColor3 ~= self.MainColor then
                TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
            end
        end)
        
        Button.MouseButton1Click:Connect(function()
            ShowTab(Name)
        end)
        
        -- Tab content container
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = #Window.Tabs == 0,
            Parent = ContentScrolling,
        })
        
        -- Create left and right columns
        local LeftColumn, LeftLayout = CreateColumn(Container, "Left")
        local RightColumn, RightLayout = CreateColumn(Container, "Right")
        
        Tab.Button = Button
        Tab.Container = Container
        Tab.LeftColumn = LeftColumn
        Tab.RightColumn = RightColumn
        Tab.LeftLayout = LeftLayout
        Tab.RightLayout = RightLayout
        
        Window.Tabs[Name] = Tab
        return Tab
    end
    
    -- Add groupbox (matching HeavN style)
    function Window:AddGroupbox(Page, Title, Side)
        local Tab = Page
        local Column = (Side == "Right" or Side == "right") and Tab.RightColumn or Tab.LeftColumn
        
        local Groupbox = self:Create("Frame", {
            BackgroundColor3 = self.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 40),
            Parent = Column,
        })
        
        self:AddCorner(Groupbox, 6)
        self:AddStroke(Groupbox, self.OutlineColor, 1)
        self:AddToRegistry(Groupbox, {
            BackgroundColor3 = "BackgroundColor",
        })
        
        table.insert(self.UIReferences.groupBoxes, Groupbox)
        
        -- Header
        local Header = self:Create("Frame", {
            BackgroundColor3 = self.SectionColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 28),
            Parent = Groupbox,
        })
        
        self:AddCorner(Header, 6)
        self:AddToRegistry(Header, { BackgroundColor3 = "SectionColor" })
        
        -- Accent line
        local AccentLine = self:Create("Frame", {
            BackgroundColor3 = self.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 2),
            Parent = Header,
        })
        
        self:AddToRegistry(AccentLine, { BackgroundColor3 = "AccentColor" })
        
        -- Title
        local TitleLabel = self:CreateLabel({
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Text = Title:upper(),
            TextSize = 11,
            Font = self.FontBold,
            TextColor3 = self.AccentColor,
            Parent = Header,
        })
        
        self:AddToRegistry(TitleLabel, { TextColor3 = "AccentColor" })
        
        -- Content container
        local Content = self:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 34),
            Size = UDim2.new(1, -24, 0, 0),
            Parent = Groupbox,
        })
        
        local ContentLayout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Content,
        })
        
        local function Resize()
            Groupbox.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y + 42)
        end
        
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Resize)
        Resize()
        
        Groupbox.Content = Content
        Groupbox.ContentLayout = ContentLayout
        
        return Groupbox
    end
    
    -- ========================================================================
    -- UI ELEMENTS (matching HeavN/Blade style)
    -- ========================================================================
    
    -- Add label
    function Window:AddLabel(Groupbox, Text, Wrapped)
        local Label = self:CreateLabel({
            Size = UDim2.new(1, 0, 0, Wrapped and 0 or 20),
            Text = Text,
            TextSize = 12,
            TextWrapped = Wrapped or false,
            Parent = Groupbox.Content,
        })
        
        if Wrapped then
            local X, Y = GetTextBounds(Text, self.Font, 12)
            Label.Size = UDim2.new(1, 0, 0, Y + 6)
        end
        
        return Label
    end
    
    -- Add divider
    function Window:AddDivider(Groupbox)
        local Divider = self:Create("Frame", {
            BackgroundColor3 = self.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundTransparency = 0.5,
            Parent = Groupbox.Content,
        })
        
        self:AddToRegistry(Divider, { BackgroundColor3 = "AccentColor" })
    end
    
    -- Add toggle (matching HeavN style)
    function Window:AddToggle(Groupbox, Index, Config)
        local Toggle = {
            Value = Config.Default or false,
            Type = "Toggle",
            Risky = Config.Risky or false,
            Callback = Config.Callback or function() end,
        }
        
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Size = UDim2.new(1, -50, 1, 0),
            Text = Config.Text,
            TextSize = 13,
            TextColor3 = Toggle.Risky and self.DangerColor or self.FontColor,
            Parent = Container,
        })
        
        if Toggle.Risky then
            self:AddToRegistry(Label, { TextColor3 = "DangerColor" })
        end
        
        local Track = self:Create("Frame", {
            BackgroundColor3 = Toggle.Value and self.AccentColor or self.ToggleOffColor,
            Size = UDim2.new(0, 38, 0, 20),
            Position = UDim2.new(1, -38, 0.5, -10),
            Parent = Container,
        })
        
        self:AddCorner(Track, 10)
        
        local Knob = self:Create("Frame", {
            BackgroundColor3 = self.ToggleOnColor,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(Toggle.Value and 1 or 0, Toggle.Value and -18 or 2, 0.5, -8),
            Parent = Track,
        })
        
        self:AddCorner(Knob, 8)
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Container)
        end
        
        local function UpdateDisplay()
            Track.BackgroundColor3 = Toggle.Value and self.AccentColor or self.ToggleOffColor
            TweenService:Create(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(Toggle.Value and 1 or 0, Toggle.Value and -18 or 2, 0.5, -8)
            }):Play()
        end
        
        function Toggle:SetValue(Value)
            Value = not not Value
            if Toggle.Value == Value then return end
            Toggle.Value = Value
            UpdateDisplay()
            self.Callback(Value)
        end
        
        function Toggle:OnChanged(Callback)
            self.Callback = Callback
        end
        
        Container.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Zilk:IsAnyFrameOpen() then
                Toggle:SetValue(not Toggle.Value)
            end
        end)
        
        UpdateDisplay()
        Toggles[Index] = Toggle
        Zilk.UIReferences.toggles[Index] = Toggle
        
        return Toggle
    end
    
    -- Add slider (matching HeavN style)
    function Window:AddSlider(Groupbox, Index, Config)
        local Slider = {
            Value = Config.Default or Config.Min,
            Min = Config.Min or 0,
            Max = Config.Max or 100,
            Rounding = Config.Rounding or 0,
            Callback = Config.Callback or function() end,
        }
        
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 55),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 22),
            Text = string.format("%s: %s", Config.Text or "Slider", tostring(Slider.Value)),
            TextSize = 12,
            Parent = Container,
        })
        
        local Track = self:Create("Frame", {
            BackgroundColor3 = self.OutlineColor,
            Position = UDim2.new(0, 0, 0, 28),
            Size = UDim2.new(1, 0, 0, 8),
            Parent = Container,
        })
        
        self:AddCorner(Track, 4)
        
        local Fill = self:Create("Frame", {
            BackgroundColor3 = self.SliderColor,
            Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0),
            Parent = Track,
        })
        
        self:AddCorner(Fill, 4)
        self:AddToRegistry(Fill, { BackgroundColor3 = "SliderColor" })
        
        local Knob = self:Create("Frame", {
            BackgroundColor3 = self.ToggleOnColor,
            Position = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), -7, 0.5, -7),
            Size = UDim2.new(0, 14, 0, 14),
            Parent = Track,
        })
        
        self:AddCorner(Knob, 7)
        
        -- Value display
        local ValueLabel = self:CreateLabel({
            Position = UDim2.new(1, -50, 0, 28),
            Size = UDim2.new(0, 45, 0, 22),
            Text = tostring(Slider.Value),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = Container,
        })
        
        if Config.Tooltip then
            Zilk:AddTooltip(Config.Tooltip, Container)
        end
        
        local dragging = false
        
        local function UpdateFromPosition()
            local rel = math.clamp((Mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            local Value = Slider.Min + (Slider.Max - Slider.Min) * rel
            
            if Slider.Rounding == 0 then
                Value = math.floor(Value + 0.5)
            else
                Value = tonumber(string.format("%." .. Slider.Rounding .. "f", Value))
            end
            
            Value = math.clamp(Value, Slider.Min, Slider.Max)
            
            if Value ~= Slider.Value then
                Slider.Value = Value
                local relVal = (Value - Slider.Min) / (Slider.Max - Slider.Min)
                Fill.Size = UDim2.new(relVal, 0, 1, 0)
                Knob.Position = UDim2.new(relVal, -7, 0.5, -7)
                Label.Text = string.format("%s: %s", Config.Text or "Slider", tostring(Value))
                ValueLabel.Text = tostring(Value)
                Slider.Callback(Value)
            end
        end
        
        Track.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                UpdateFromPosition()
            end
        end)
        
        UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(Input)
            if dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateFromPosition()
            end
        end)
        
        function Slider:SetValue(Value)
            Value = math.clamp(Value, self.Min, self.Max)
            if Slider.Value == Value then return end
            Slider.Value = Value
            local rel = (Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Knob.Position = UDim2.new(rel, -7, 0.5, -7)
            Label.Text = string.format("%s: %s", Config.Text or "Slider", tostring(Value))
            ValueLabel.Text = tostring(Value)
            Slider.Callback(Value)
        end
        
        function Slider:OnChanged(Callback)
            Slider.Callback = Callback
        end
        
        Options[Index] = Slider
        
        return Slider
    end
    
    -- Add dropdown (matching HeavN style with search)
    function Window:AddDropdown(Groupbox, Index, Config)
        local Dropdown = {
            Values = Config.Values or {},
            Value = Config.Default or (Config.Values and Config.Values[1]),
            Multi = Config.Multi or false,
            SpecialType = Config.SpecialType,
            Callback = Config.Callback or function() end,
        }
        
        if Dropdown.Multi then
            Dropdown.Value = {}
            if type(Config.Default) == "table" then
                for _, v in ipairs(Config.Default) do
                    Dropdown.Value[v] = true
                end
            end
        end
        
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 50),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 20),
            Text = Config.Text or "Dropdown",
            TextSize = 12,
            Parent = Container,
        })
        
        local Button = self:Create("TextButton", {
            BackgroundColor3 = self.DropdownColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, 0, 0, 26),
            Text = Dropdown.Multi and "Select" or tostring(Dropdown.Value),
            TextColor3 = self.FontColor,
            Font = self.Font,
            TextSize = 12,
            Parent = Container,
        })
        
        self:AddCorner(Button, 6)
        self:AddToRegistry(Button, {
            BackgroundColor3 = "DropdownColor",
            TextColor3 = "FontColor",
        })
        
        -- Dropdown arrow
        local Arrow = self:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031090079",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -22, 0.5, -8),
            Parent = Button,
        })
        
        if Config.Tooltip then
            Zilk:AddTooltip(Config.Tooltip, Container)
        end
        
        -- Dropdown list frame
        local ListFrame = self:Create("Frame", {
            BackgroundColor3 = self.MainColor,
            BorderColor3 = self.AccentColor,
            BorderMode = Enum.BorderMode.Inset,
            Visible = false,
            ZIndex = 100,
            Parent = Zilk.ScreenGui,
        })
        
        self:AddCorner(ListFrame, 6)
        self:AddToRegistry(ListFrame, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "AccentColor",
        })
        
        -- Search box for dropdown
        local SearchBox = self:Create("TextBox", {
            BackgroundColor3 = self.BackgroundColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -10, 0, 26),
            Position = UDim2.new(0, 5, 0, 5),
            PlaceholderText = "Search...",
            Text = "",
            TextColor3 = self.FontColor,
            Font = self.Font,
            TextSize = 12,
            ClearTextOnFocus = false,
            Parent = ListFrame,
        })
        
        self:AddCorner(SearchBox, 4)
        self:AddToRegistry(SearchBox, {
            BackgroundColor3 = "BackgroundColor",
            TextColor3 = "FontColor",
        })
        
        -- Scrolling frame for items
        local ScrollFrame = self:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 36),
            Size = UDim2.new(1, -10, 1, -46),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.AccentColor,
            Parent = ListFrame,
        })
        
        self:AddToRegistry(ScrollFrame, { ScrollBarImageColor3 = "AccentColor" })
        
        local ItemLayout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ScrollFrame,
        })
        
        local function UpdateButtonText()
            if Dropdown.Multi then
                local Selected = {}
                for Value, SelectedBool in pairs(Dropdown.Value) do
                    if SelectedBool then
                        table.insert(Selected, Value)
                    end
                end
                Button.Text = #Selected > 0 and table.concat(Selected, ", ") or "Select"
            else
                Button.Text = tostring(Dropdown.Value)
            end
        end
        
        local function RebuildList(SearchText)
            for _, child in ipairs(ScrollFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            local SearchLower = (SearchText or ""):lower()
            local ListHeight = 0
            local ItemCount = 0
            
            for _, Value in ipairs(Dropdown.Values) do
                if SearchLower == "" or string.lower(tostring(Value)):find(SearchLower, 1, true) then
                    local IsSelected = Dropdown.Multi and Dropdown.Value[Value] or Dropdown.Value == Value
                    
                    local Item = self:Create("TextButton", {
                        BackgroundColor3 = self.BackgroundColor,
                        Text = Value,
                        TextColor3 = IsSelected and self.AccentColor or self.FontColor,
                        Font = self.Font,
                        TextSize = 12,
                        Size = UDim2.new(1, 0, 0, 28),
                        Parent = ScrollFrame,
                    })
                    
                    self:AddToRegistry(Item, {
                        BackgroundColor3 = "BackgroundColor",
                        TextColor3 = "FontColor",
                    })
                    
                    ItemCount = ItemCount + 1
                    ListHeight = ListHeight + 28
                    
                    Item.MouseEnter:Connect(function()
                        Item.BackgroundColor3 = GetLighterColor(self.BackgroundColor)
                    end)
                    
                    Item.MouseLeave:Connect(function()
                        Item.BackgroundColor3 = self.BackgroundColor
                    end)
                    
                    Item.MouseButton1Click:Connect(function()
                        if Dropdown.Multi then
                            Dropdown.Value[Value] = not Dropdown.Value[Value]
                            Item.TextColor3 = Dropdown.Value[Value] and self.AccentColor or self.FontColor
                            UpdateButtonText()
                            Dropdown.Callback(Dropdown.Value)
                        else
                            Dropdown.Value = Value
                            UpdateButtonText()
                            ListFrame.Visible = false
                            Zilk.OpenedFrames[ListFrame] = nil
                            Dropdown.Callback(Value)
                            
                            for _, child in ipairs(ScrollFrame:GetChildren()) do
                                if child:IsA("TextButton") then
                                    child.TextColor3 = child.Text == Value and self.AccentColor or self.FontColor
                                end
                            end
                        end
                    end)
                end
            end
            
            local MaxHeight = math.min(ListHeight, 200)
            ListFrame.Size = UDim2.new(0, Button.AbsoluteSize.X, 0, MaxHeight + 46)
            ScrollFrame.Size = UDim2.new(1, -10, 1, -46)
            ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListHeight)
        end
        
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            RebuildList(SearchBox.Text)
        end)
        
        Button.MouseButton1Click:Connect(function()
            if ListFrame.Visible then
                ListFrame.Visible = false
                Zilk.OpenedFrames[ListFrame] = nil
            else
                for Frame, _ in pairs(Zilk.OpenedFrames) do
                    if Frame and Frame.Parent then
                        Frame.Visible = false
                    end
                end
                Zilk.OpenedFrames = {}
                
                ListFrame.Position = UDim2.new(0, Button.AbsolutePosition.X, 0, Button.AbsolutePosition.Y + Button.AbsoluteSize.Y)
                SearchBox.Text = ""
                RebuildList("")
                ListFrame.Visible = true
                Zilk.OpenedFrames[ListFrame] = true
            end
        end)
        
        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and ListFrame.Visible then
                local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                local framePos = ListFrame.AbsolutePosition
                local frameSize = ListFrame.AbsoluteSize
                
                if not (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                        mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) then
                    ListFrame.Visible = false
                    Zilk.OpenedFrames[ListFrame] = nil
                end
            end
        end)
        
        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                if type(Value) == "table" then
                    Dropdown.Value = Value
                else
                    Dropdown.Value[Value] = true
                end
            else
                Dropdown.Value = Value
            end
            UpdateButtonText()
            Dropdown.Callback(Dropdown.Value)
        end
        
        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
        end
        
        function Dropdown:OnChanged(Callback)
            Dropdown.Callback = Callback
        end
        
        UpdateButtonText()
        Options[Index] = Dropdown
        Zilk.UIReferences.dropdowns[Index] = Dropdown
        
        return Dropdown
    end
    
    -- Add input
    function Window:AddInput(Groupbox, Index, Config)
        local Input = {
            Value = Config.Default or "",
            Numeric = Config.Numeric or false,
            Callback = Config.Callback or function() end,
        }
        
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 50),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 20),
            Text = Config.Text or "Input",
            TextSize = 12,
            Parent = Container,
        })
        
        local TextBox = self:Create("TextBox", {
            BackgroundColor3 = self.DropdownColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, 0, 0, 26),
            Text = Input.Value,
            TextColor3 = self.FontColor,
            Font = self.Font,
            TextSize = 12,
            PlaceholderText = Config.Placeholder or "",
            ClearTextOnFocus = false,
            Parent = Container,
        })
        
        self:AddCorner(TextBox, 6)
        self:AddToRegistry(TextBox, {
            BackgroundColor3 = "DropdownColor",
            TextColor3 = "FontColor",
        })
        
        if Config.Tooltip then
            Zilk:AddTooltip(Config.Tooltip, Container)
        end
        
        local function UpdateValue()
            local NewValue = TextBox.Text
            if Input.Numeric and NewValue ~= "" then
                NewValue = tonumber(NewValue)
                if NewValue == nil then
                    TextBox.Text = tostring(Input.Value)
                    return
                end
            end
            Input.Value = NewValue
            Input.Callback(Input.Value)
        end
        
        if Config.Finished then
            TextBox.FocusLost:Connect(UpdateValue)
        else
            TextBox:GetPropertyChangedSignal("Text"):Connect(UpdateValue)
        end
        
        function Input:SetValue(Value)
            Input.Value = Value
            TextBox.Text = tostring(Value)
            Input.Callback(Value)
        end
        
        function Input:OnChanged(Callback)
            Input.Callback = Callback
        end
        
        Options[Index] = Input
        
        return Input
    end
    
    -- Add button
    function Window:AddButton(Groupbox, Config)
        local Button = self:Create("TextButton", {
            BackgroundColor3 = self.ButtonColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
            Text = Config.Text or "Button",
            TextColor3 = self.FontColor,
            Font = self.FontBold,
            TextSize = 13,
            Parent = Groupbox.Content,
        })
        
        self:AddCorner(Button, 6)
        self:AddToRegistry(Button, {
            BackgroundColor3 = "ButtonColor",
            TextColor3 = "FontColor",
        })
        
        if Config.Tooltip then
            Zilk:AddTooltip(Config.Tooltip, Button)
        end
        
        if Config.DoubleClick then
            local ClickCount = 0
            local ClickTimer = nil
            
            Button.MouseButton1Click:Connect(function()
                ClickCount = ClickCount + 1
                
                if ClickTimer then
                    task.cancel(ClickTimer)
                end
                
                ClickTimer = task.delay(0.5, function()
                    if ClickCount >= 2 then
                        if Config.Func then Config.Func() end
                    end
                    ClickCount = 0
                    ClickTimer = nil
                end)
            end)
        else
            Button.MouseButton1Click:Connect(function()
                if Config.Func then Config.Func() end
            end)
        end
        
        return Button
    end
    
    -- Add color picker
    function Window:AddColorPicker(Groupbox, Index, Config)
        local ColorPicker = {
            Value = Config.Default or Color3.new(1, 1, 1),
            Transparency = Config.Transparency or 0,
            Callback = Config.Callback or function() end,
        }
        
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Size = UDim2.new(1, -50, 1, 0),
            Text = Config.Text or "Color",
            TextSize = 13,
            Parent = Container,
        })
        
        local Preview = self:Create("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 40, 0, 24),
            Position = UDim2.new(1, -40, 0.5, -12),
            Parent = Container,
        })
        
        self:AddCorner(Preview, 6)
        self:AddToRegistry(Preview, { BackgroundColor3 = "MainColor" })
        
        Zilk.UIReferences.colorPreviews[Index] = Preview
        
        if Config.Tooltip then
            Zilk:AddTooltip(Config.Tooltip, Container)
        end
        
        -- Simple color picker popup
        local function ShowColorPicker()
            -- Close any open color picker
            if Zilk.ScreenGui:FindFirstChild("ColorPickerPopup") then
                Zilk.ScreenGui.ColorPickerPopup:Destroy()
            end
            
            local Popup = self:Create("Frame", {
                BackgroundColor3 = self.MainColor,
                BorderColor3 = self.AccentColor,
                BorderMode = Enum.BorderMode.Inset,
                Position = UDim2.new(0, Preview.AbsolutePosition.X, 0, Preview.AbsolutePosition.Y + Preview.AbsoluteSize.Y),
                Size = UDim2.new(0, 200, 0, 200),
                Visible = true,
                ZIndex = 1000,
                Parent = Zilk.ScreenGui,
            })
            
            self:AddCorner(Popup, 6)
            self:AddToRegistry(Popup, {
                BackgroundColor3 = "MainColor",
                BorderColor3 = "AccentColor",
            })
            
            Zilk.OpenedFrames[Popup] = true
            
            -- Simple color presets
            local Colors = {
                Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1),
                Color3.new(1, 1, 0), Color3.new(1, 0, 1), Color3.new(0, 1, 1),
                Color3.new(1, 1, 1), Color3.new(0, 0, 0), ColorPicker.Value
            }
            
            local ColorLayout = self:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 5),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Parent = Popup,
            })
            
            for _, Color in ipairs(Colors) do
                local ColorBtn = self:Create("TextButton", {
                    BackgroundColor3 = Color,
                    Size = UDim2.new(0, 30, 0, 30),
                    Text = "",
                    Parent = Popup,
                })
                
                self:AddCorner(ColorBtn, 4)
                
                ColorBtn.MouseButton1Click:Connect(function()
                    ColorPicker.Value = Color
                    Preview.BackgroundColor3 = Color
                    ColorPicker.Callback(Color, ColorPicker.Transparency)
                    Popup:Destroy()
                    Zilk.OpenedFrames[Popup] = nil
                end)
            end
            
            -- Close picker when clicking outside
            local function ClosePicker(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local popupPos = Popup.AbsolutePosition
                    local popupSize = Popup.AbsoluteSize
                    
                    if not (mousePos.X >= popupPos.X and mousePos.X <= popupPos.X + popupSize.X and
                            mousePos.Y >= popupPos.Y and mousePos.Y <= popupPos.Y + popupSize.Y) then
                        Popup:Destroy()
                        Zilk.OpenedFrames[Popup] = nil
                        connection:Disconnect()
                    end
                end
            end
            
            local connection = UserInputService.InputBegan:Connect(ClosePicker)
        end
        
        Preview.MouseButton1Click:Connect(ShowColorPicker)
        
        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Value = Color
            ColorPicker.Transparency = Transparency or 0
            Preview.BackgroundColor3 = Color
            ColorPicker.Callback(Color, ColorPicker.Transparency)
        end
        
        function ColorPicker:OnChanged(Callback)
            ColorPicker.Callback = Callback
        end
        
        Options[Index] = ColorPicker
        
        return ColorPicker
    end
    
    -- Add keybind picker
    function Window:AddKeyPicker(Groupbox, Index, Config)
        local KeyPicker = {
            Value = Config.Default or "None",
            Mode = Config.Mode or "Toggle",
            Callback = Config.Callback or function() end,
            ChangedCallback = Config.ChangedCallback or function() end,
        }
        
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Size = UDim2.new(1, -70, 1, 0),
            Text = Config.Text or "Keybind",
            TextSize = 13,
            Parent = Container,
        })
        
        local Button = self:Create("TextButton", {
            BackgroundColor3 = self.ButtonColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 70, 0, 24),
            Position = UDim2.new(1, -70, 0.5, -12),
            Text = KeyPicker.Value,
            TextColor3 = self.FontColor,
            Font = self.FontBold,
            TextSize = 11,
            Parent = Container,
        })
        
        self:AddCorner(Button, 6)
        self:AddToRegistry(Button, {
            BackgroundColor3 = "ButtonColor",
            TextColor3 = "FontColor",
        })
        
        if Config.Tooltip then
            Zilk:AddTooltip(Config.Tooltip, Container)
        end
        
        local function GetKeyName(Input)
            if Input.UserInputType == Enum.UserInputType.Keyboard then
                return Input.KeyCode.Name
            elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                return "MB1"
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                return "MB2"
            end
            return "None"
        end
        
        local Listening = false
        local ListenConnection = nil
        
        Button.MouseButton1Click:Connect(function()
            if Listening then
                Listening = false
                if ListenConnection then ListenConnection:Disconnect() end
                Button.Text = KeyPicker.Value
                return
            end
            
            Listening = true
            Button.Text = "..."
            
            ListenConnection = UserInputService.InputBegan:Connect(function(Input, Processed)
                if Processed then return end
                
                local Key = GetKeyName(Input)
                if Key ~= "None" then
                    Listening = false
                    Button.Text = Key
                    KeyPicker.Value = Key
                    KeyPicker.ChangedCallback(Key)
                    ListenConnection:Disconnect()
                end
            end)
            
            task.delay(5, function()
                if Listening then
                    Listening = false
                    if ListenConnection then ListenConnection:Disconnect() end
                    Button.Text = KeyPicker.Value
                end
            end)
        end)
        
        function KeyPicker:SetValue(Key)
            KeyPicker.Value = Key
            Button.Text = Key
            KeyPicker.ChangedCallback(Key)
        end
        
        function KeyPicker:GetState()
            return KeyPicker.CurrentState or false
        end
        
        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end
        
        function KeyPicker:OnChanged(Callback)
            KeyPicker.ChangedCallback = Callback
        end
        
        Options[Index] = KeyPicker
        Zilk.UIReferences.keybinds[Index] = KeyPicker
        
        return KeyPicker
    end
    
    -- Add dependency box
    function Window:AddDependencyBox(Groupbox)
        local Depbox = {
            Dependencies = {},
            Container = nil,
        }
        
        Depbox.Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = true,
            Parent = Groupbox.Content,
        })
        
        local Layout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Depbox.Container,
        })
        
        local function UpdateVisibility()
            for _, Dep in ipairs(Depbox.Dependencies) do
                local Element = Dep[1]
                local RequiredValue = Dep[2]
                
                if Element and Element.Value ~= RequiredValue then
                    Depbox.Container.Visible = false
                    return
                end
            end
            Depbox.Container.Visible = true
        end
        
        function Depbox:SetupDependencies(Dependencies)
            Depbox.Dependencies = Dependencies
            UpdateVisibility()
        end
        
        function Depbox:AddDependencyBox()
            return Window:AddDependencyBox(Depbox)
        end
        
        Depbox.AddToggle = function(self, Index, Config)
            return Window:AddToggle(Depbox, Index, Config)
        end
        
        Depbox.AddSlider = function(self, Index, Config)
            return Window:AddSlider(Depbox, Index, Config)
        end
        
        Depbox.AddDropdown = function(self, Index, Config)
            return Window:AddDropdown(Depbox, Index, Config)
        end
        
        Depbox.AddLabel = function(self, Text, Wrapped)
            return Window:AddLabel(Depbox, Text, Wrapped)
        end
        
        Depbox.AddButton = function(self, Config)
            return Window:AddButton(Depbox, Config)
        end
        
        Depbox.AddInput = function(self, Index, Config)
            return Window:AddInput(Depbox, Index, Config)
        end
        
        Depbox.AddColorPicker = function(self, Index, Config)
            return Window:AddColorPicker(Depbox, Index, Config)
        end
        
        Depbox.AddKeyPicker = function(self, Index, Config)
            return Window:AddKeyPicker(Depbox, Index, Config)
        end
        
        Depbox.AddDivider = function(self)
            return Window:AddDivider(Depbox)
        end
        
        setmetatable(Depbox, {
            __index = function(t, k)
                return Window[k]
            end
        })
        
        return Depbox
    end
    
    -- Function to toggle menu visibility
    local MenuVisible = Config.AutoShow
    local Fading = false
    
    function Window:Toggle()
        if Fading then return end
        
        Fading = true
        MenuVisible = not MenuVisible
        
        if MenuVisible then
            MainFrame.Visible = true
        end
        
        local FadeTime = Config.FadeTime
        
        if MenuVisible then
            MainFrame.Visible = true
            MainFrame.BackgroundTransparency = 1
            TweenService:Create(MainFrame, TweenInfo.new(FadeTime), {
                BackgroundTransparency = 0
            }):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(FadeTime), {
                BackgroundTransparency = 1
            }):Play()
            task.wait(FadeTime)
            MainFrame.Visible = false
        end
        
        Fading = false
    end
    
    -- Set menu keybind
    function Window:SetMenuKey(Keybind)
        UserInputService.InputBegan:Connect(function(Input, Processed)
            if Processed then return end
            
            local Matches = false
            if typeof(Keybind) == "EnumItem" then
                if Keybind.EnumType == Enum.KeyCode then
                    Matches = Input.KeyCode == Keybind
                elseif Keybind.EnumType == Enum.UserInputType then
                    Matches = Input.UserInputType == Keybind
                end
            elseif type(Keybind) == "string" then
                Matches = Input.KeyCode and Input.KeyCode.Name == Keybind
            end
            
            if Matches then
                Window:Toggle()
            end
        end)
    end
    
    -- Unload function
    function Window:Unload()
        Zilk:Unload()
    end
    
    return Window
end

-- Unload everything
function Zilk:Unload()
    for _, Signal in ipairs(self.Signals) do
        Signal:Disconnect()
    end
    
    if self.UnloadCallback then
        self.UnloadCallback()
    end
    
    self.ScreenGui:Destroy()
    getgenv().Zilk = nil
end

function Zilk:OnUnload(Callback)
    self.UnloadCallback = Callback
end

-- Exports
getgenv().Zilk = Zilk
return Zilk
