-- ZilkLib.lua
-- A modern UI library for Roblox exploits
-- Repository: https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/refs/heads/main/Lib.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

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

-- Library table
local Zilk = {
    Registry = {},
    RegistryMap = {},
    Configs = {},
    
    -- Default colors
    FontColor = Color3.fromRGB(255, 255, 255),
    MainColor = Color3.fromRGB(20, 20, 20),
    BackgroundColor = Color3.fromRGB(15, 15, 15),
    AccentColor = Color3.fromRGB(147, 112, 219),
    OutlineColor = Color3.fromRGB(45, 45, 45),
    DangerColor = Color3.fromRGB(255, 70, 70),
    SuccessColor = Color3.fromRGB(70, 255, 70),
    
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    
    OpenedFrames = {},
    Notifications = {},
    Signals = {},
    ScreenGui = ScreenGui,
    
    -- Config system
    ConfigFolder = "Zilk",
    ConfigsLoaded = {},
    CurrentConfigName = nil,
    ConfigEdited = false,
    
    -- UI elements
    NotifContainer = nil,
    Watermark = nil,
}

-- Helper functions
local function GetTextBounds(Text, Font, Size)
    local bounds = TextService:GetTextSize(Text, Size, Font, Vector2.new(1920, 1080))
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

function Zilk:CreateLabel(Properties, IsHud)
    local Label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = self.Font,
        TextColor3 = self.FontColor,
        TextSize = 14,
        TextStrokeTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Add outline stroke
    local Stroke = self:Create("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        Parent = Label,
    })
    
    self:AddToRegistry(Label, { TextColor3 = "FontColor" })
    
    for Prop, Value in pairs(Properties or {}) do
        Label[Prop] = Value
    end
    
    return Label
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

-- Add tooltip
function Zilk:AddTooltip(Text, HoverInstance)
    local X, Y = GetTextBounds(Text, self.Font, 12)
    
    local Tooltip = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderColor3 = self.OutlineColor,
        Size = UDim2.new(0, X + 8, 0, Y + 4),
        Visible = false,
        ZIndex = 1000,
        Parent = self.ScreenGui,
    })
    
    self:AddToRegistry(Tooltip, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
    })
    
    local Label = self:CreateLabel({
        Position = UDim2.new(0, 4, 0, 2),
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

-- Check if any frame is open (dropdowns, color pickers, etc)
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

-- Notification system
function Zilk:Notify(Title, Message, Duration, Color)
    if not self.NotifContainer then
        self.NotifContainer = self:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.75, 0, 0.05, 0),
            Size = UDim2.new(0, 280, 1, -40),
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
    
    self:AddToRegistry(Notif, { BackgroundColor3 = "MainColor" })
    
    local Corner = self:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Notif })
    local Stroke = self:Create("UIStroke", { Color = Color or self.AccentColor, Thickness = 1.5, Parent = Notif })
    
    local TitleLabel = self:CreateLabel({
        Position = UDim2.new(0, 10, 0, 8),
        Size = UDim2.new(1, -20, 0, 22),
        Text = Title,
        TextSize = 14,
        Font = self.FontBold,
        TextColor3 = Color or self.AccentColor,
        Parent = Notif,
    })
    
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
        Size = UDim2.new(0, 150, 0, 24),
        Parent = self.ScreenGui,
    })
    
    self:AddToRegistry(Watermark, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "AccentColor",
    })
    
    local Label = self:CreateLabel({
        Size = UDim2.new(1, -4, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        Text = Text,
        TextSize = 12,
        Parent = Watermark,
    })
    
    self:MakeDraggable(Watermark, 24)
    self.Watermark = Watermark
    
    return Label
end

function Zilk:UpdateWatermark(Text)
    if self.Watermark and self.Watermark:FindFirstChildOfClass("TextLabel") then
        self.Watermark:FindFirstChildOfClass("TextLabel").Text = Text
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
    
    -- Iterate through all toggles and options
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

-- ============================================================================
-- WINDOW CREATION
-- ============================================================================

function Zilk:CreateWindow(Config)
    Config = Config or {}
    Config.Title = Config.Title or "Zilk Menu"
    Config.Size = Config.Size or UDim2.new(0, 550, 0, 500)
    Config.Center = Config.Center ~= false
    Config.AutoShow = Config.AutoShow == true
    Config.TabPadding = Config.TabPadding or 5
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
    self:AddToRegistry(MainFrame, { BackgroundColor3 = "Black" })
    
    -- Inner frame
    local InnerFrame = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderColor3 = self.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        Parent = MainFrame,
    })
    
    self:AddToRegistry(InnerFrame, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "AccentColor",
    })
    
    -- Title bar
    local TitleBar = self:Create("Frame", {
        BackgroundColor3 = self.BackgroundColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 30),
        Parent = InnerFrame,
    })
    
    self:AddToRegistry(TitleBar, { BackgroundColor3 = "BackgroundColor" })
    
    local TitleLabel = self:CreateLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Text = Config.Title,
        TextSize = 16,
        Font = self.FontBold,
        Parent = TitleBar,
    })
    
    -- Tab area
    local TabArea = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 35),
        Size = UDim2.new(1, -16, 0, 25),
        Parent = InnerFrame,
    })
    
    local TabLayout = self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, Config.TabPadding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabArea,
    })
    
    -- Content container
    local ContentContainer = self:Create("Frame", {
        BackgroundColor3 = self.BackgroundColor,
        BorderColor3 = self.OutlineColor,
        Position = UDim2.new(0, 8, 0, 65),
        Size = UDim2.new(1, -16, 1, -73),
        Parent = InnerFrame,
    })
    
    self:AddToRegistry(ContentContainer, {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
    })
    
    -- Content scrolling frame
    local ContentScrolling = self:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.AccentColor,
        Parent = ContentContainer,
    })
    
    self:AddToRegistry(ContentScrolling, { ScrollBarImageColor3 = "AccentColor" })
    
    local ContentLayout = self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ContentScrolling,
    })
    
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentScrolling.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
    end)
    
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
                    Tab.Button.BackgroundColor3 = self.BackgroundColor
                    self:AddToRegistry(Tab.Button, { BackgroundColor3 = "BackgroundColor" })
                end
            end
        end
    end
    
    -- Add tab function
    function Window:AddTab(Name)
        local Tab = {
            Name = Name,
            Elements = {},
            Containers = {Left = {}, Right = {}},
        }
        
        -- Tab button
        local Button = self:Create("TextButton", {
            BackgroundColor3 = #Window.Tabs == 0 and self.MainColor or self.BackgroundColor,
            Text = Name,
            TextColor3 = self.FontColor,
            Font = self.Font,
            TextSize = 13,
            Size = UDim2.new(0, GetTextBounds(Name, self.Font, 13) + 20, 1, 0),
            BorderSizePixel = 0,
            Parent = TabArea,
        })
        
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
        
        -- Tab container
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = #Window.Tabs == 0,
            Parent = ContentScrolling,
        })
        
        -- Left column
        local LeftColumn = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -4, 1, 0),
            Parent = Container,
        })
        
        local LeftLayout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = LeftColumn,
        })
        
        -- Right column
        local RightColumn = self:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 4, 0, 0),
            Size = UDim2.new(0.5, -4, 1, 0),
            Parent = Container,
        })
        
        local RightLayout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = RightColumn,
        })
        
        Tab.Button = Button
        Tab.Container = Container
        Tab.LeftColumn = LeftColumn
        Tab.RightColumn = RightColumn
        Tab.LeftLayout = LeftLayout
        Tab.RightLayout = RightLayout
        
        Window.Tabs[Name] = Tab
        return Tab
    end
    
    -- Add groupbox
    function Window:AddGroupbox(Parent, Title, Side)
        local Tab = Parent
        local Column = (Side == "Right") and Tab.RightColumn or Tab.LeftColumn
        
        local Groupbox = self:Create("Frame", {
            BackgroundColor3 = self.BackgroundColor,
            BorderColor3 = self.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 0, 40),
            Parent = Column,
        })
        
        self:AddToRegistry(Groupbox, {
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
        })
        
        -- Header
        local Header = self:Create("Frame", {
            BackgroundColor3 = self.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 22),
            Parent = Groupbox,
        })
        
        self:AddToRegistry(Header, { BackgroundColor3 = "MainColor" })
        
        local HeaderLine = self:Create("Frame", {
            BackgroundColor3 = self.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            Parent = Header,
        })
        
        self:AddToRegistry(HeaderLine, { BackgroundColor3 = "AccentColor" })
        
        local TitleLabel = self:CreateLabel({
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
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
            Position = UDim2.new(0, 8, 0, 28),
            Size = UDim2.new(1, -16, 0, 0),
            Parent = Groupbox,
        })
        
        local ContentLayout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Content,
        })
        
        local function Resize()
            Groupbox.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y + 34)
        end
        
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Resize)
        Resize()
        
        Groupbox.Content = Content
        Groupbox.ContentLayout = ContentLayout
        
        return Groupbox
    end
    
    -- ========================================================================
    -- UI ELEMENTS
    -- ========================================================================
    
    -- Add label
    function Window:AddLabel(Groupbox, Text, Wrapped)
        local Label = self:CreateLabel({
            Size = UDim2.new(1, 0, 0, Wrapped and 0 or 18),
            Text = Text,
            TextSize = 12,
            TextWrapped = Wrapped or false,
            Parent = Groupbox.Content,
        })
        
        if Wrapped then
            local X, Y = GetTextBounds(Text, self.Font, 12, Groupbox.Content.AbsoluteSize)
            Label.Size = UDim2.new(1, 0, 0, Y + 4)
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
    
    -- Add toggle
    function Window:AddToggle(Groupbox, Index, Config)
        local Toggle = {
            Value = Config.Default or false,
            Type = "Toggle",
            Callback = Config.Callback or function() end,
        }
        
        local Container = self:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Size = UDim2.new(1, -50, 1, 0),
            Text = Config.Text,
            TextSize = 13,
            Parent = Container,
        })
        
        local Track = self:Create("Frame", {
            BackgroundColor3 = Toggle.Value and self.AccentColor or self.OutlineColor,
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -36, 0.5, -9),
            Parent = Container,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })
        
        local Knob = self:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(Toggle.Value and 1 or 0, Toggle.Value and -16 or 2, 0.5, -7),
            Parent = Track,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Container)
        end
        
        local function UpdateDisplay()
            Track.BackgroundColor3 = Toggle.Value and self.AccentColor or self.OutlineColor
            TweenService:Create(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(Toggle.Value and 1 or 0, Toggle.Value and -16 or 2, 0.5, -7)
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
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not self:IsAnyFrameOpen() then
                Toggle:SetValue(not Toggle.Value)
            end
        end)
        
        UpdateDisplay()
        Toggles[Index] = Toggle
        
        return Toggle
    end
    
    -- Add slider
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
            Size = UDim2.new(1, 0, 0, 50),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 20),
            Text = string.format("%s: %s", Config.Text or "Slider", tostring(Slider.Value)),
            TextSize = 12,
            Parent = Container,
        })
        
        local Track = self:Create("Frame", {
            BackgroundColor3 = self.OutlineColor,
            Position = UDim2.new(0, 0, 0, 28),
            Size = UDim2.new(1, 0, 0, 6),
            Parent = Container,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })
        
        local Fill = self:Create("Frame", {
            BackgroundColor3 = self.AccentColor,
            Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0),
            Parent = Track,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
        self:AddToRegistry(Fill, { BackgroundColor3 = "AccentColor" })
        
        local Knob = self:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), -6, 0.5, -6),
            Size = UDim2.new(0, 12, 0, 12),
            Parent = Track,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Container)
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
                Knob.Position = UDim2.new(relVal, -6, 0.5, -6)
                Label.Text = string.format("%s: %s", Config.Text or "Slider", tostring(Value))
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
            Knob.Position = UDim2.new(rel, -6, 0.5, -6)
            Label.Text = string.format("%s: %s", Config.Text or "Slider", tostring(Value))
            Slider.Callback(Value)
        end
        
        function Slider:OnChanged(Callback)
            Slider.Callback = Callback
        end
        
        Options[Index] = Slider
        
        return Slider
    end
    
    -- Add dropdown
    function Window:AddDropdown(Groupbox, Index, Config)
        local Dropdown = {
            Values = Config.Values or {},
            Value = Config.Default or (Config.Values and Config.Values[1]),
            Multi = Config.Multi or false,
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
            Size = UDim2.new(1, 0, 0, 45),
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
            BackgroundColor3 = self.MainColor,
            BorderColor3 = self.OutlineColor,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, 0, 0, 20),
            Text = Dropdown.Multi and "Select" or tostring(Dropdown.Value),
            TextColor3 = self.FontColor,
            Font = self.Font,
            TextSize = 12,
            Parent = Container,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Button })
        self:AddToRegistry(Button, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            TextColor3 = "FontColor",
        })
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Container)
        end
        
        local ListFrame = self:Create("Frame", {
            BackgroundColor3 = self.MainColor,
            BorderColor3 = self.OutlineColor,
            Visible = false,
            ZIndex = 100,
            Parent = self.ScreenGui,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ListFrame })
        self:AddToRegistry(ListFrame, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
        })
        
        local ListLayout = self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ListFrame,
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
        
        local function RebuildList()
            for _, child in ipairs(ListFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            local ListHeight = 0
            
            for _, Value in ipairs(Dropdown.Values) do
                local IsSelected = Dropdown.Multi and Dropdown.Value[Value] or Dropdown.Value == Value
                
                local Item = self:Create("TextButton", {
                    BackgroundColor3 = self.BackgroundColor,
                    Text = Value,
                    TextColor3 = IsSelected and self.AccentColor or self.FontColor,
                    Font = self.Font,
                    TextSize = 12,
                    Size = UDim2.new(1, 0, 0, 25),
                    Parent = ListFrame,
                })
                
                self:AddToRegistry(Item, {
                    BackgroundColor3 = "BackgroundColor",
                    TextColor3 = "FontColor",
                })
                
                ListHeight = ListHeight + 25
                
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
                        self.OpenedFrames[ListFrame] = nil
                        Dropdown.Callback(Value)
                        
                        for _, child in ipairs(ListFrame:GetChildren()) do
                            if child:IsA("TextButton") then
                                child.TextColor3 = child.Text == Value and self.AccentColor or self.FontColor
                            end
                        end
                    end
                end)
            end
            
            ListFrame.Size = UDim2.new(0, Button.AbsoluteSize.X, 0, math.min(ListHeight, 150))
        end
        
        Button.MouseButton1Click:Connect(function()
            if ListFrame.Visible then
                ListFrame.Visible = false
                self.OpenedFrames[ListFrame] = nil
            else
                for Frame, _ in pairs(self.OpenedFrames) do
                    if Frame and Frame.Parent then
                        Frame.Visible = false
                    end
                end
                self.OpenedFrames = {}
                
                ListFrame.Position = UDim2.new(0, Button.AbsolutePosition.X, 0, Button.AbsolutePosition.Y + Button.AbsoluteSize.Y)
                RebuildList()
                ListFrame.Visible = true
                self.OpenedFrames[ListFrame] = true
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
                    self.OpenedFrames[ListFrame] = nil
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
            Size = UDim2.new(1, 0, 0, 45),
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
            BackgroundColor3 = self.MainColor,
            BorderColor3 = self.OutlineColor,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, 0, 0, 20),
            Text = Input.Value,
            TextColor3 = self.FontColor,
            Font = self.Font,
            TextSize = 12,
            PlaceholderText = Config.Placeholder or "",
            ClearTextOnFocus = false,
            Parent = Container,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TextBox })
        self:AddToRegistry(TextBox, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            TextColor3 = "FontColor",
        })
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Container)
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
            BackgroundColor3 = self.ButtonColor or self.MainColor,
            BorderColor3 = self.OutlineColor,
            Size = UDim2.new(1, 0, 0, 30),
            Text = Config.Text or "Button",
            TextColor3 = self.FontColor,
            Font = self.FontBold,
            TextSize = 13,
            Parent = Groupbox.Content,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Button })
        self:AddToRegistry(Button, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            TextColor3 = "FontColor",
        })
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Button)
        end
        
        Button.MouseButton1Click:Connect(function()
            if Config.Func then
                Config.Func()
            end
        end)
        
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
            Size = UDim2.new(1, 0, 0, 30),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Size = UDim2.new(1, -40, 1, 0),
            Text = Config.Text or "Color",
            TextSize = 13,
            Parent = Container,
        })
        
        local Preview = self:Create("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = self.OutlineColor,
            Size = UDim2.new(0, 30, 0, 20),
            Position = UDim2.new(1, -30, 0.5, -10),
            Parent = Container,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Preview })
        self:AddToRegistry(Preview, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
        })
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Container)
        end
        
        local H, S, V = Color3.toHSV(ColorPicker.Value)
        
        local function UpdatePreview()
            Preview.BackgroundColor3 = ColorPicker.Value
            ColorPicker.Callback(ColorPicker.Value, ColorPicker.Transparency)
        end
        
        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Value = Color
            ColorPicker.Transparency = Transparency or 0
            UpdatePreview()
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
            Size = UDim2.new(1, 0, 0, 30),
            Parent = Groupbox.Content,
        })
        
        local Label = self:CreateLabel({
            Size = UDim2.new(1, -70, 1, 0),
            Text = Config.Text or "Keybind",
            TextSize = 13,
            Parent = Container,
        })
        
        local Button = self:Create("TextButton", {
            BackgroundColor3 = self.MainColor,
            BorderColor3 = self.OutlineColor,
            Size = UDim2.new(0, 60, 0, 20),
            Position = UDim2.new(1, -60, 0.5, -10),
            Text = KeyPicker.Value,
            TextColor3 = self.FontColor,
            Font = self.Font,
            TextSize = 11,
            Parent = Container,
        })
        
        self:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Button })
        self:AddToRegistry(Button, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            TextColor3 = "FontColor",
        })
        
        if Config.Tooltip then
            self:AddTooltip(Config.Tooltip, Container)
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
        
        Button.MouseButton1Click:Connect(function()
            if Listening then
                Listening = false
                Button.Text = KeyPicker.Value
                return
            end
            
            Listening = true
            Button.Text = "..."
            
            local Connection
            Connection = UserInputService.InputBegan:Connect(function(Input, Processed)
                if Processed then return end
                
                local Key = GetKeyName(Input)
                if Key ~= "None" then
                    Listening = false
                    Button.Text = Key
                    KeyPicker.Value = Key
                    KeyPicker.ChangedCallback(Key)
                    Connection:Disconnect()
                end
            end)
            
            task.delay(5, function()
                if Listening then
                    Listening = false
                    Button.Text = KeyPicker.Value
                    if Connection then Connection:Disconnect() end
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
            Padding = UDim.new(0, 6),
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
        
        Depbox.AddToggle = function(self, ...)
            return Window:AddToggle(Depbox, ...)
        end
        
        Depbox.AddSlider = function(self, ...)
            return Window:AddSlider(Depbox, ...)
        end
        
        Depbox.AddDropdown = function(self, ...)
            return Window:AddDropdown(Depbox, ...)
        end
        
        Depbox.AddLabel = function(self, ...)
            return Window:AddLabel(Depbox, ...)
        end
        
        Depbox.AddButton = function(self, ...)
            return Window:AddButton(Depbox, ...)
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
        
        for _, Desc in ipairs(MainFrame:GetDescendants()) do
            if Desc:IsA("Frame") or Desc:IsA("ScrollingFrame") then
                TweenService:Create(Desc, TweenInfo.new(FadeTime), {
                    BackgroundTransparency = MenuVisible and 0 or 1
                }):Play()
            elseif Desc:IsA("TextLabel") or Desc:IsA("TextButton") or Desc:IsA("TextBox") then
                TweenService:Create(Desc, TweenInfo.new(FadeTime), {
                    TextTransparency = MenuVisible and 0 or 1
                }):Play()
            end
        end
        
        task.wait(FadeTime)
        
        if not MenuVisible then
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
            end
            
            if Matches then
                Window:Toggle()
            end
        end)
    end
    
    -- Unload function
    function Window:Unload()
        self:Notify("ZilkLib", "Unloading menu...", 1)
        task.wait(0.5)
        MainFrame:Destroy()
    end
    
    return Window
end

-- Add unload signal
function Zilk:OnUnload(Callback)
    self.UnloadCallback = Callback
end

function Zilk:Unload()
    for _, Signal in ipairs(self.Signals) do
        Signal:Disconnect()
    end
    
    if self.UnloadCallback then
        self.UnloadCallback()
    end
    
    self.ScreenGui:Destroy()
end

-- Exports
getgenv().Zilk = Zilk
return Zilk
