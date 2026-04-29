--[[
    Zilk UI Library
    A clean Linoria-style API library built for Da Hood / Blade Ball menus.
    Author: XIMMYzwsss
    Repo:   https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/refs/heads/main/Lib.lua

    USAGE:
        local Zilk = loadstring(game:HttpGet('https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/refs/heads/main/Lib.lua'))()

        local Win  = Zilk:CreateWindow({ Title = "My Menu", Center = true, AutoShow = true })
        local Tabs = { Main = Win:AddTab("Main") }

        local Box  = Tabs.Main:AddLeftGroupbox("Combat")
        Box:AddToggle("Aimbot", { Text = "Aimbot", Default = false, Tooltip = "Enable aimbot" })
        Box:AddSlider("FOV",    { Text = "FOV", Default = 100, Min = 50, Max = 500, Rounding = 0 })

        -- Access values anywhere:
        --   Toggles.Aimbot.Value
        --   Options.FOV.Value

    BUILT-IN TABS (always appended automatically):
        Settings  -- UI colours, keybind, watermark toggle, unload
        Config    -- Save / load / delete / autoload configs
]]

-- ============================================================================
-- SERVICES
-- ============================================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local TextService   = game:GetService("TextService")
local HttpService   = game:GetService("HttpService")
local CoreGui       = game:GetService("CoreGui")

local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

-- ============================================================================
-- GLOBAL REGISTRIES  (mirroring Linoria's getgenv() pattern)
-- ============================================================================
local Toggles = {}
local Options  = {}
getgenv().Toggles = Toggles
getgenv().Options  = Options

-- ============================================================================
-- SCREEN GUI
-- ============================================================================
local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.Name             = "ZilkLib"
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn     = false
ScreenGui.Parent           = CoreGui

-- ============================================================================
-- LIBRARY TABLE
-- ============================================================================
local Zilk = {
    -- Registries
    Registry    = {},
    RegistryMap = {},
    Signals     = {},
    OpenedFrames = {},

    -- Colours  (all tweakable from Settings tab)
    FontColor       = Color3.fromRGB(240, 240, 240),
    MainColor       = Color3.fromRGB(10,  10,  10 ),
    BackgroundColor = Color3.fromRGB(20,  20,  20 ),
    SectionColor    = Color3.fromRGB(18,  18,  18 ),
    AccentColor     = Color3.fromRGB(147, 112, 219),
    OutlineColor    = Color3.fromRGB(35,  35,  35 ),
    DangerColor     = Color3.fromRGB(255, 70,  70 ),
    SuccessColor    = Color3.fromRGB(70,  255, 70 ),
    ButtonColor     = Color3.fromRGB(40,  40,  40 ),
    DropdownColor   = Color3.fromRGB(30,  30,  30 ),
    SliderColor     = Color3.fromRGB(147, 112, 219),
    ToggleOnColor   = Color3.fromRGB(255, 255, 255),
    ToggleOffColor  = Color3.fromRGB(30,  30,  30 ),

    Font      = Enum.Font.Gotham,
    FontBold  = Enum.Font.GothamBold,
    FontMedium= Enum.Font.GothamMedium,

    ScreenGui = ScreenGui,

    -- Config
    ConfigFolder      = "Zilk",
    ConfigExtension   = ".zcfg",
    CurrentConfig     = nil,
    AutoloadConfig    = nil,

    -- State
    Unloaded        = false,
    WatermarkLabel  = nil,
    WatermarkFrame  = nil,
    KeybindFrame    = nil,

    -- Internal
    _window         = nil,
    _notifications  = {},
    _keybindItems   = {},
    _unloadCbs      = {},
}

-- ============================================================================
-- UTIL HELPERS
-- ============================================================================
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(inst, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 4) }, inst)
end

local function Stroke(inst, col, thick)
    return New("UIStroke", { Color = col or Zilk.OutlineColor, Thickness = thick or 1 }, inst)
end

local function Padding(inst, top, right, bottom, left)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
    }, inst)
end

local function ListLayout(inst, dir, pad, align, sort)
    return New("UIListLayout", {
        FillDirection       = dir   or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, pad or 0),
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        SortOrder           = sort  or Enum.SortOrder.LayoutOrder,
    }, inst)
end

local function Tween(inst, info, props)
    TweenService:Create(inst, info, props):Play()
end

local function TextBounds(text, size, font)
    return TextService:GetTextSize(text, size, font or Enum.Font.Gotham, Vector2.new(1920, 1080))
end

-- Registry: lets us re-colour everything on theme change
function Zilk:Reg(inst, props)
    local d = { Instance = inst, Props = props }
    table.insert(self.Registry, d)
    self.RegistryMap[inst] = d
end

function Zilk:ApplyTheme()
    for _, d in ipairs(self.Registry) do
        for prop, key in pairs(d.Props) do
            local v = type(key) == "function" and key() or self[key]
            if v then pcall(function() d.Instance[prop] = v end) end
        end
    end
end

-- Tooltip
function Zilk:AddTooltip(text, hover)
    if not text or text == "" then return end
    local bounds = TextBounds(text, 12)
    local tip = New("Frame", {
        BackgroundColor3 = self.MainColor,
        Size             = UDim2.new(0, bounds.X + 14, 0, bounds.Y + 8),
        Visible          = false,
        ZIndex           = 500,
        Parent           = ScreenGui,
    })
    Corner(tip, 4)
    Stroke(tip, self.AccentColor)
    New("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 7, 0, 4),
        Size       = UDim2.new(1, -14, 1, -8),
        Text       = text,
        TextColor3 = self.FontColor,
        Font       = self.Font,
        TextSize   = 12,
        ZIndex     = 501,
        Parent     = tip,
    })
    local hovering = false
    hover.MouseEnter:Connect(function()
        hovering = true
        tip.Visible = true
        while hovering and tip.Parent do
            tip.Position = UDim2.new(0, Mouse.X + 14, 0, Mouse.Y + 10)
            RunService.Heartbeat:Wait()
        end
    end)
    hover.MouseLeave:Connect(function()
        hovering = false
        tip.Visible = false
    end)
end

-- Dragging
function Zilk:MakeDraggable(frame, cutoff)
    local drag, ds, fs = false, Vector2.new(), UDim2.new()
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            local mp = Vector2.new(Mouse.X, Mouse.Y)
            if mp.Y - frame.AbsolutePosition.Y <= (cutoff or 30) then
                drag = true; ds = mp; fs = frame.Position
            end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    RunService.RenderStepped:Connect(function()
        if drag then
            local d = Vector2.new(Mouse.X, Mouse.Y) - ds
            frame.Position = UDim2.new(fs.X.Scale, fs.X.Offset + d.X, fs.Y.Scale, fs.Y.Offset + d.Y)
        end
    end)
end

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================
function Zilk:Notify(title, message, duration, color)
    if not self._notifContainer then
        local c = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.75, 0, 0.05, 0),
            Size     = UDim2.new(0, 300, 1, -40),
            Parent   = ScreenGui,
        })
        ListLayout(c, Enum.FillDirection.Vertical, 6)
        self._notifContainer = c
    end
    local col = color or self.AccentColor
    local n = New("Frame", {
        BackgroundColor3      = self.MainColor,
        BackgroundTransparency= 0.1,
        Size                  = UDim2.new(1, 0, 0, 72),
        LayoutOrder           = -tick(),
        Parent                = self._notifContainer,
    })
    Corner(n, 6)
    Stroke(n, col, 1.5)
    New("TextLabel", {
        BackgroundTransparency = 1,
        Position  = UDim2.new(0, 10, 0, 8),
        Size      = UDim2.new(1, -20, 0, 22),
        Text      = title,
        TextColor3= col,
        Font      = self.FontBold,
        TextSize  = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent    = n,
    })
    New("TextLabel", {
        BackgroundTransparency = 1,
        Position     = UDim2.new(0, 10, 0, 32),
        Size         = UDim2.new(1, -20, 0, 32),
        Text         = message,
        TextColor3   = self.FontColor,
        Font         = self.Font,
        TextSize     = 12,
        TextWrapped  = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent       = n,
    })
    table.insert(self._notifications, n)
    task.delay(duration or 3, function()
        if n and n.Parent then
            Tween(n, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
            task.wait(0.25)
            n:Destroy()
        end
    end)
end

-- ============================================================================
-- WATERMARK
-- ============================================================================
function Zilk:SetWatermark(text)
    if self.WatermarkLabel then self.WatermarkLabel.Text = text end
end

function Zilk:SetWatermarkVisibility(v)
    if self.WatermarkFrame then self.WatermarkFrame.Visible = v end
end

local function BuildWatermark(zilk)
    local f = New("Frame", {
        BackgroundColor3 = zilk.MainColor,
        Position = UDim2.new(0.01, 0, 0.01, 0),
        Size     = UDim2.new(0, 220, 0, 26),
        Visible  = false,
        Parent   = ScreenGui,
    })
    Corner(f, 4)
    Stroke(f, zilk.AccentColor)
    local lbl = New("TextLabel", {
        BackgroundTransparency = 1,
        Position  = UDim2.new(0, 8, 0, 0),
        Size      = UDim2.new(1, -8, 1, 0),
        Text      = "Zilk",
        TextColor3= zilk.FontColor,
        Font      = zilk.FontBold,
        TextSize  = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent    = f,
    })
    zilk:MakeDraggable(f, 26)
    zilk.WatermarkFrame = f
    zilk.WatermarkLabel = lbl
end

-- ============================================================================
-- KEYBIND LIST
-- ============================================================================
local function BuildKeybindFrame(zilk)
    local gui = New("ScreenGui", {
        Name = "ZilkLib_Keybinds",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false,
        Parent = CoreGui,
    })
    ProtectGui(gui)
    local f = New("Frame", {
        BackgroundColor3 = zilk.MainColor,
        Position = UDim2.new(0.01, 0, 0.3, 0),
        Size     = UDim2.new(0, 160, 0, 24),
        Visible  = true,
        Parent   = gui,
    })
    Corner(f, 4)
    Stroke(f, zilk.AccentColor)
    New("TextLabel", {
        BackgroundTransparency = 1,
        Size      = UDim2.new(1, 0, 0, 20),
        Position  = UDim2.new(0, 8, 0, 2),
        Text      = "KEYBINDS",
        TextColor3= zilk.AccentColor,
        Font      = zilk.FontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent    = f,
    })
    local list = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 22),
        Size     = UDim2.new(1, 0, 0, 0),
        Parent   = f,
    })
    local layout = ListLayout(list, Enum.FillDirection.Vertical, 2)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        f.Size = UDim2.new(0, 160, 0, 26 + layout.AbsoluteContentSize.Y)
    end)
    zilk.KeybindFrame = f
    zilk._keybindList  = list
    zilk:MakeDraggable(f, 24)
end

function Zilk:_AddKeybindItem(text, getState)
    if not self._keybindList then return end
    local row = New("Frame", {
        BackgroundTransparency = 1,
        Size   = UDim2.new(1, 0, 0, 18),
        Parent = self._keybindList,
    })
    local lbl = New("TextLabel", {
        BackgroundTransparency = 1,
        Size      = UDim2.new(0.65, -4, 1, 0),
        Position  = UDim2.new(0, 8, 0, 0),
        Text      = text,
        TextColor3= self.FontColor,
        Font      = self.Font,
        TextSize  = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent    = row,
    })
    local val = New("TextLabel", {
        BackgroundTransparency = 1,
        Size      = UDim2.new(0.35, -4, 1, 0),
        Position  = UDim2.new(0.65, 0, 0, 0),
        Text      = "OFF",
        TextColor3= self.DangerColor,
        Font      = self.FontBold,
        TextSize  = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent    = row,
    })
    table.insert(self._keybindItems, { val = val, getState = getState })
    RunService.Heartbeat:Connect(function()
        local s = getState()
        val.Text      = s and "ON" or "OFF"
        val.TextColor3= s and self.SuccessColor or self.DangerColor
    end)
    return row
end

-- ============================================================================
-- CONFIG SYSTEM
-- ============================================================================
local function EnsureFolder(zilk)
    if type(makefolder) ~= "function" then return false end
    if type(isfolder) == "function" and not isfolder(zilk.ConfigFolder) then
        makefolder(zilk.ConfigFolder)
    end
    return true
end

function Zilk:GetAllValues()
    local t = {}
    for k, v in pairs(Toggles) do if v and v.Value ~= nil then t[k] = v.Value end end
    for k, v in pairs(Options)  do if v and v.Value ~= nil then t[k] = v.Value end end
    return t
end

function Zilk:ApplyValues(data)
    for k, v in pairs(data) do
        if Toggles[k] then pcall(function() Toggles[k]:SetValue(v) end)
        elseif Options[k] then pcall(function() Options[k]:SetValue(v) end)
        end
    end
end

function Zilk:SaveConfig(name)
    if not EnsureFolder(self) then
        self:Notify("Config", "Filesystem not available", 2, self.DangerColor); return false
    end
    local path = self.ConfigFolder .. "/" .. name .. self.ConfigExtension
    local ok, err = pcall(writefile, path, HttpService:JSONEncode(self:GetAllValues()))
    if ok then
        self.CurrentConfig = name
        self:Notify("Config", "Saved: " .. name, 2, self.SuccessColor)
        return true
    else
        self:Notify("Config", "Save failed", 2, self.DangerColor); return false
    end
end

function Zilk:LoadConfig(name)
    if not EnsureFolder(self) then
        self:Notify("Config", "Filesystem not available", 2, self.DangerColor); return false
    end
    local path = self.ConfigFolder .. "/" .. name .. self.ConfigExtension
    if type(isfile) == "function" and not isfile(path) then
        self:Notify("Config", "Not found: " .. name, 2, self.DangerColor); return false
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if ok and type(data) == "table" then
        self:ApplyValues(data)
        self.CurrentConfig = name
        self:Notify("Config", "Loaded: " .. name, 2, self.SuccessColor)
        return true
    else
        self:Notify("Config", "Load failed", 2, self.DangerColor); return false
    end
end

function Zilk:DeleteConfig(name)
    if not EnsureFolder(self) then return false end
    local path = self.ConfigFolder .. "/" .. name .. self.ConfigExtension
    if type(isfile) == "function" and isfile(path) then
        pcall(delfile, path)
        if self.CurrentConfig == name then self.CurrentConfig = nil end
        self:Notify("Config", "Deleted: " .. name, 2, self.AccentColor)
        return true
    end
    return false
end

function Zilk:SetAutoload(name)
    if not EnsureFolder(self) then return end
    self.AutoloadConfig = name
    pcall(writefile, self.ConfigFolder .. "/_autoload.txt", name)
end

function Zilk:LoadAutoloadConfig()
    if not EnsureFolder(self) then return end
    local ok, name = pcall(readfile, self.ConfigFolder .. "/_autoload.txt")
    if ok and name and name ~= "" then
        self:LoadConfig(name:match("^%s*(.-)%s*$"))
    end
end

function Zilk:ListConfigs()
    if not EnsureFolder(self) then return {} end
    if type(listfiles) ~= "function" then return {} end
    local out = {}
    for _, f in ipairs(listfiles(self.ConfigFolder)) do
        local n = f:match("([^\\/]+)" .. self.ConfigExtension .. "$")
        if n then table.insert(out, n) end
    end
    table.sort(out)
    return out
end

-- ============================================================================
-- UNLOAD
-- ============================================================================
function Zilk:OnUnload(cb)
    table.insert(self._unloadCbs, cb)
end

function Zilk:Unload()
    self.Unloaded = true
    for _, cb in ipairs(self._unloadCbs) do pcall(cb) end
    for _, s in ipairs(self.Signals) do pcall(function() s:Disconnect() end) end
    pcall(function() ScreenGui:Destroy() end)
    pcall(function()
        if game.CoreGui:FindFirstChild("ZilkLib_Keybinds") then
            game.CoreGui.ZilkLib_Keybinds:Destroy()
        end
    end)
    getgenv().Zilk = nil
end

function Zilk:GiveSignal(s)
    table.insert(self.Signals, s)
end

-- ============================================================================
-- ELEMENT CONSTRUCTORS (shared, called by groupbox / depbox)
-- ============================================================================

-- Each constructor receives (parent_content_frame, index_or_nil, config)
-- Returns a Lua-table wrapper so callers can do :OnChanged, :SetValue, etc.

local Constructors = {}

-- ─── TOGGLE ─────────────────────────────────────────────────────────────────
function Constructors.Toggle(lib, content, index, cfg)
    cfg = cfg or {}
    local obj = {
        Value    = cfg.Default == true,
        Type     = "Toggle",
        _cbs     = {},
    }

    local row = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), Parent=content })
    local lbl = New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,-48,1,0),
        Text=cfg.Text or "Toggle", TextColor3=cfg.Risky and lib.DangerColor or lib.FontColor,
        Font=lib.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local track = New("Frame", {
        BackgroundColor3 = obj.Value and lib.AccentColor or lib.ToggleOffColor,
        Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-38,0.5,-10), Parent=row,
    })
    Corner(track, 10)
    local knob = New("Frame", {
        BackgroundColor3=lib.ToggleOnColor,
        Size=UDim2.new(0,16,0,16),
        Position=UDim2.new(obj.Value and 1 or 0, obj.Value and -18 or 2, 0.5, -8),
        Parent=track,
    })
    Corner(knob, 8)

    if cfg.Tooltip then lib:AddTooltip(cfg.Tooltip, row) end

    local tweenInfo = TweenInfo.new(0.15)
    local function Refresh()
        Tween(track, tweenInfo, { BackgroundColor3 = obj.Value and lib.AccentColor or lib.ToggleOffColor })
        Tween(knob,  tweenInfo, { Position = UDim2.new(obj.Value and 1 or 0, obj.Value and -18 or 2, 0.5, -8) })
    end

    function obj:SetValue(v)
        self.Value = v == true
        Refresh()
        for _, cb in ipairs(self._cbs) do pcall(cb, self.Value) end
        if cfg.Callback then pcall(cfg.Callback, self.Value) end
    end

    function obj:OnChanged(cb) table.insert(self._cbs, cb) end

    local btn = New("TextButton", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text="", Parent=row,
    })
    btn.MouseButton1Click:Connect(function() obj:SetValue(not obj.Value) end)

    if index then Toggles[index] = obj end
    return obj
end

-- ─── SLIDER ──────────────────────────────────────────────────────────────────
function Constructors.Slider(lib, content, index, cfg)
    cfg = cfg or {}
    local min, max, round = cfg.Min or 0, cfg.Max or 100, cfg.Rounding or 0
    local function clamp(v) return math.clamp(tonumber(v) or min, min, max) end
    local function fmt(v)
        return (round == 0 and tostring(math.floor(v)) or string.format("%." .. round .. "f", v))
            .. (cfg.Suffix or "")
    end

    local obj = { Value = clamp(cfg.Default or min), Type = "Slider", _cbs = {} }

    local wrapper = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0, cfg.Compact and 22 or 42), Parent=content })

    if not cfg.Compact then
        local topRow = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,18), Parent=wrapper })
        New("TextLabel", {
            BackgroundTransparency=1, Size=UDim2.new(0.7,0,1,0),
            Text=cfg.Text or "Slider", TextColor3=lib.FontColor,
            Font=lib.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=topRow,
        })
    end

    local track = New("Frame", {
        BackgroundColor3=lib.DropdownColor,
        Size=UDim2.new(1,0,0,18),
        Position=UDim2.new(0,0,0, cfg.Compact and 0 or 22),
        Parent=wrapper,
    })
    Corner(track, 4)
    local fill = New("Frame", {
        BackgroundColor3=lib.SliderColor,
        Size=UDim2.new((obj.Value-min)/(max-min),0,1,0),
        Parent=track,
    })
    Corner(fill, 4)
    local valLbl = New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        Text=fmt(obj.Value), TextColor3=lib.FontColor,
        Font=lib.FontBold, TextSize=11, ZIndex=2, Parent=track,
    })
    if cfg.Tooltip then lib:AddTooltip(cfg.Tooltip, wrapper) end

    local function SetFill(v)
        obj.Value = clamp(v)
        fill.Size = UDim2.new((obj.Value-min)/(max-min), 0, 1, 0)
        valLbl.Text = fmt(obj.Value)
    end

    local dragging = false
    local function CalcValue(absX)
        local rel = math.clamp((Mouse.X - absX) / track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel
        local step = 10^(-round)
        return math.floor(raw / step + 0.5) * step
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            SetFill(CalcValue(track.AbsolutePosition.X))
            for _, cb in ipairs(obj._cbs) do pcall(cb, obj.Value) end
            if cfg.Callback then pcall(cfg.Callback, obj.Value) end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            SetFill(CalcValue(track.AbsolutePosition.X))
            for _, cb in ipairs(obj._cbs) do pcall(cb, obj.Value) end
            if cfg.Callback then pcall(cfg.Callback, obj.Value) end
        end
    end)

    function obj:SetValue(v) SetFill(v) end
    function obj:OnChanged(cb) table.insert(self._cbs, cb) end

    if index then Options[index] = obj end
    return obj
end

-- ─── INPUT ───────────────────────────────────────────────────────────────────
function Constructors.Input(lib, content, index, cfg)
    cfg = cfg or {}
    local obj = { Value = tostring(cfg.Default or ""), Type = "Input", _cbs = {} }

    local wrapper = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,42), Parent=content })
    New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,18),
        Text=cfg.Text or "Input", TextColor3=lib.FontColor,
        Font=lib.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=wrapper,
    })
    local bg = New("Frame", {
        BackgroundColor3=lib.DropdownColor, Size=UDim2.new(1,0,0,22),
        Position=UDim2.new(0,0,0,20), Parent=wrapper,
    })
    Corner(bg, 4)
    local tb = New("TextBox", {
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,4,0,0),
        Text=obj.Value, PlaceholderText=cfg.Placeholder or "", PlaceholderColor3=Color3.fromRGB(120,120,120),
        TextColor3=lib.FontColor, Font=lib.Font, TextSize=12,
        ClearTextOnFocus=false, TextXAlignment=Enum.TextXAlignment.Left, Parent=bg,
    })
    if cfg.Tooltip then lib:AddTooltip(cfg.Tooltip, wrapper) end

    local function update()
        local v = tb.Text
        if cfg.Numeric then v = tonumber(v) or obj.Value end
        obj.Value = v
        for _, cb in ipairs(obj._cbs) do pcall(cb, obj.Value) end
        if cfg.Callback then pcall(cfg.Callback, obj.Value) end
    end
    if cfg.Finished then tb.FocusLost:Connect(update)
    else tb:GetPropertyChangedSignal("Text"):Connect(update) end

    function obj:SetValue(v) obj.Value = tostring(v); tb.Text = tostring(v) end
    function obj:OnChanged(cb) table.insert(self._cbs, cb) end

    if index then Options[index] = obj end
    return obj
end

-- ─── DROPDOWN ────────────────────────────────────────────────────────────────
function Constructors.Dropdown(lib, content, index, cfg)
    cfg = cfg or {}
    local multi = cfg.Multi == true
    local vals   = cfg.Values or {}

    -- default value
    local defVal
    if cfg.Default then
        if type(cfg.Default) == "number" then
            defVal = vals[cfg.Default]
        else
            defVal = cfg.Default
        end
    else
        defVal = multi and {} or vals[1]
    end

    local obj = {
        Value  = multi and (type(defVal)=="table" and defVal or {}) or defVal,
        Values = vals,
        Type   = "Dropdown",
        _cbs   = {},
        _multi = multi,
    }

    local wrapper = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,42), Parent=content })
    New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,18),
        Text=cfg.Text or "Dropdown", TextColor3=lib.FontColor,
        Font=lib.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=wrapper,
    })

    local btn = New("TextButton", {
        BackgroundColor3=lib.DropdownColor, Size=UDim2.new(1,0,0,22),
        Position=UDim2.new(0,0,0,20), Text="", Parent=wrapper,
    })
    Corner(btn, 4)
    local dispLbl = New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,6,0,0),
        TextColor3=lib.FontColor, Font=lib.Font, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=btn,
    })
    New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-22,0,0),
        Text="▼", TextColor3=lib.AccentColor, Font=lib.FontBold, TextSize=11, Parent=btn,
    })

    -- Popup
    local popupHolder = New("Frame", {
        BackgroundColor3=lib.DropdownColor, Size=UDim2.new(1,0,0,0),
        Position=UDim2.new(0,0,1,2), Visible=false, ZIndex=50,
        ClipsDescendants=true, Parent=btn,
    })
    Corner(popupHolder, 4)
    Stroke(popupHolder, lib.AccentColor)
    local popupScroll = New("ScrollingFrame", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=3,
        ScrollBarImageColor3=lib.AccentColor, ZIndex=51, Parent=popupHolder,
    })
    local popupLayout = ListLayout(popupScroll, Enum.FillDirection.Vertical, 2)
    popupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local h = math.min(popupLayout.AbsoluteContentSize.Y + 6, 150)
        popupHolder.Size = UDim2.new(1, 0, 0, h)
        popupScroll.CanvasSize = UDim2.new(0,0,0,popupLayout.AbsoluteContentSize.Y)
    end)

    local function DisplayValue()
        if multi then
            local parts = {}
            for k, v in pairs(obj.Value) do if v then table.insert(parts, k) end end
            table.sort(parts)
            dispLbl.Text = #parts == 0 and "None" or table.concat(parts, ", ")
        else
            dispLbl.Text = tostring(obj.Value or "")
        end
    end

    local function FireCbs()
        for _, cb in ipairs(obj._cbs) do pcall(cb, obj.Value) end
        if cfg.Callback then pcall(cfg.Callback, obj.Value) end
    end

    local function BuildItems()
        for _, c in ipairs(popupScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local itemVals = obj.Values
        if cfg.SpecialType == "Player" then
            itemVals = {}
            for _, p in ipairs(Players:GetPlayers()) do table.insert(itemVals, p.Name) end
        end
        for _, v in ipairs(itemVals) do
            local selected = multi and (obj.Value[v] == true) or (obj.Value == v)
            local item = New("TextButton", {
                BackgroundColor3 = selected and lib.AccentColor or lib.MainColor,
                Size=UDim2.new(1,0,0,24), Text="",
                ZIndex=52, Parent=popupScroll,
            })
            Corner(item, 3)
            New("TextLabel", {
                BackgroundTransparency=1, Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,6,0,0),
                Text=v, TextColor3=lib.FontColor, Font=lib.Font, TextSize=12,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=53, Parent=item,
            })
            item.MouseButton1Click:Connect(function()
                if multi then
                    obj.Value[v] = not obj.Value[v]
                else
                    obj.Value = v
                    popupHolder.Visible = false
                end
                BuildItems(); DisplayValue(); FireCbs()
            end)
        end
    end

    local open = false
    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then BuildItems() end
        popupHolder.Visible = open
        lib.OpenedFrames[popupHolder] = open or nil
    end)
    UIS.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and open then
            task.wait()
            if open and not btn:IsMouseOver() then
                open = false; popupHolder.Visible = false
                lib.OpenedFrames[popupHolder] = nil
            end
        end
    end)

    if cfg.SpecialType == "Player" then
        Players.PlayerAdded:Connect(function() if open then BuildItems() end end)
        Players.PlayerRemoving:Connect(function() if open then BuildItems() end end)
    end

    DisplayValue()
    if cfg.Tooltip then lib:AddTooltip(cfg.Tooltip, wrapper) end

    function obj:SetValue(v)
        if multi and type(v)=="table" then obj.Value = v
        else obj.Value = v end
        DisplayValue(); FireCbs()
    end
    function obj:OnChanged(cb) table.insert(self._cbs, cb) end

    if index then Options[index] = obj end
    return obj
end

-- ─── BUTTON ──────────────────────────────────────────────────────────────────
function Constructors.Button(lib, content, cfg)
    cfg = cfg or {}
    local rowFrame = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), Parent=content })

    local btn = New("TextButton", {
        BackgroundColor3=lib.ButtonColor, BorderSizePixel=0,
        Size=UDim2.new(1,0,1,0), Text=cfg.Text or "Button",
        TextColor3=lib.FontColor, Font=lib.FontBold, TextSize=13, Parent=rowFrame,
    })
    Corner(btn, 6)
    if cfg.Tooltip then lib:AddTooltip(cfg.Tooltip, btn) end

    if cfg.DoubleClick then
        local cc, ct = 0, nil
        btn.MouseButton1Click:Connect(function()
            cc = cc + 1
            if ct then task.cancel(ct) end
            ct = task.delay(0.45, function()
                if cc >= 2 and cfg.Func then pcall(cfg.Func) end
                cc = 0; ct = nil
            end)
        end)
    else
        btn.MouseButton1Click:Connect(function() if cfg.Func then pcall(cfg.Func) end end)
    end

    -- Hover flash
    btn.MouseEnter:Connect(function() Tween(btn, TweenInfo.new(0.1), { BackgroundColor3=Color3.fromRGB(60,60,60) }) end)
    btn.MouseLeave:Connect(function() Tween(btn, TweenInfo.new(0.1), { BackgroundColor3=lib.ButtonColor }) end)

    local wrapper = { _row = rowFrame, _btn = btn }
    function wrapper:AddButton(subCfg)
        -- Shrink main button, add sibling sub-button
        btn.Size = UDim2.new(0.5, -2, 1, 0)
        btn.Position = UDim2.new(0, 0, 0, 0)
        local sub = New("TextButton", {
            BackgroundColor3=lib.ButtonColor, BorderSizePixel=0,
            Size=UDim2.new(0.5,-2,1,0), Position=UDim2.new(0.5,2,0,0),
            Text=subCfg.Text or "Sub", TextColor3=lib.FontColor,
            Font=lib.FontBold, TextSize=13, Parent=rowFrame,
        })
        Corner(sub, 6)
        if subCfg.Tooltip then lib:AddTooltip(subCfg.Tooltip, sub) end
        if subCfg.DoubleClick then
            local cc, ct = 0, nil
            sub.MouseButton1Click:Connect(function()
                cc = cc + 1
                if ct then task.cancel(ct) end
                ct = task.delay(0.45, function()
                    if cc >= 2 and subCfg.Func then pcall(subCfg.Func) end
                    cc = 0; ct = nil
                end)
            end)
        else
            sub.MouseButton1Click:Connect(function() if subCfg.Func then pcall(subCfg.Func) end end)
        end
        sub.MouseEnter:Connect(function() Tween(sub, TweenInfo.new(0.1), { BackgroundColor3=Color3.fromRGB(60,60,60) }) end)
        sub.MouseLeave:Connect(function() Tween(sub, TweenInfo.new(0.1), { BackgroundColor3=lib.ButtonColor }) end)
        return sub
    end
    return wrapper
end

-- ─── LABEL ───────────────────────────────────────────────────────────────────
function Constructors.Label(lib, content, text, wrap)
    local bounds = TextBounds(text or "", 12, lib.Font)
    local h = wrap and (bounds.Y + 6) or 20
    local lbl = New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,h),
        Text=text or "", TextColor3=lib.FontColor, Font=lib.Font, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=wrap or false, Parent=content,
    })

    -- Allows label:AddColorPicker / label:AddKeyPicker  (Linoria pattern)
    local wrapper = { _lbl = lbl }
    function wrapper:AddColorPicker(index, cfg)
        return Constructors.ColorPicker(lib, content, index, cfg)
    end
    function wrapper:AddKeyPicker(index, cfg)
        return Constructors.KeyPicker(lib, content, index, cfg)
    end
    return wrapper
end

-- ─── DIVIDER ─────────────────────────────────────────────────────────────────
function Constructors.Divider(lib, content)
    New("Frame", {
        BackgroundColor3=lib.AccentColor, BackgroundTransparency=0.4,
        Size=UDim2.new(1,0,0,1), Parent=content,
    })
end

-- ─── COLOR PICKER ────────────────────────────────────────────────────────────
function Constructors.ColorPicker(lib, content, index, cfg)
    cfg = cfg or {}
    local obj = {
        Value        = cfg.Default or Color3.new(1,1,1),
        Transparency = cfg.Transparency or 0,
        Type         = "ColorPicker",
        _cbs         = {},
    }

    local row = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), Parent=content })
    New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,-44,1,0),
        Text=cfg.Text or "Color", TextColor3=lib.FontColor,
        Font=lib.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local preview = New("TextButton", {
        BackgroundColor3=obj.Value, Size=UDim2.new(0,38,0,22),
        Position=UDim2.new(1,-38,0.5,-11), Text="", Parent=row,
    })
    Corner(preview, 4)

    -- Colour picker popup
    local popup = New("Frame", {
        BackgroundColor3=lib.SectionColor, Size=UDim2.new(0,220,0,200),
        Position=UDim2.new(0,0,1,4), Visible=false, ZIndex=100, Parent=row,
    })
    Corner(popup, 6)
    Stroke(popup, lib.AccentColor)

    -- HSV canvas (simplified SV square)
    local hueBar = New("Frame", {
        BackgroundColor3=Color3.new(1,0,0), Size=UDim2.new(1,-20,0,16),
        Position=UDim2.new(0,0,0,4), ZIndex=101, Parent=popup,
    })
    Corner(hueBar, 3)
    local hueCursor = New("Frame", {
        BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(0,6,1,0),
        Position=UDim2.new(0,0,0,0), ZIndex=102, Parent=hueBar,
    })
    Corner(hueCursor, 2)

    -- Hue gradient
    local hueGrad = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,1,1)),
            ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6,1,1)),
            ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6,1,1)),
            ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6,1,1)),
            ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6,1,1)),
            ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6,1,1)),
            ColorSequenceKeypoint.new(1,   Color3.fromHSV(1,1,1)),
        }),
        Rotation = 0,
    }, hueBar)

    local svCanvas = New("ImageLabel", {
        BackgroundColor3=Color3.new(1,0,0),
        Image="rbxassetid://698052001", -- SV gradient asset
        Size=UDim2.new(1,-20,0,120), Position=UDim2.new(0,0,0,26),
        ZIndex=101, Parent=popup,
    })
    Corner(svCanvas, 3)
    local svCursor = New("Frame", {
        BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(0,8,0,8),
        Position=UDim2.new(0,0,0,0), ZIndex=102, Parent=svCanvas,
    })
    Corner(svCursor, 4)

    local H, S, V = Color3.toHSV(obj.Value)

    local function UpdatePreview()
        obj.Value = Color3.fromHSV(H, S, V)
        preview.BackgroundColor3 = obj.Value
        svCanvas.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        hueCursor.Position  = UDim2.new(H, -3, 0, 0)
        svCursor.Position   = UDim2.new(S, -4, 1-V, -4)
        for _, cb in ipairs(obj._cbs) do pcall(cb, obj.Value, obj.Transparency) end
        if cfg.Callback then pcall(cfg.Callback, obj.Value, obj.Transparency) end
    end

    local draggingHue, draggingSV = false, false
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = false; draggingSV = false
        end
    end)
    svCanvas.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true end
    end)
    RunService.RenderStepped:Connect(function()
        if draggingHue then
            H = math.clamp((Mouse.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
            UpdatePreview()
        end
        if draggingSV then
            S = math.clamp((Mouse.X - svCanvas.AbsolutePosition.X) / svCanvas.AbsoluteSize.X, 0, 1)
            V = 1 - math.clamp((Mouse.Y - svCanvas.AbsolutePosition.Y) / svCanvas.AbsoluteSize.Y, 0, 1)
            UpdatePreview()
        end
    end)

    -- Transparency slider (optional)
    if cfg.Transparency ~= nil then
        local tRow = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,-20,0,18), Position=UDim2.new(0,0,0,154), ZIndex=101, Parent=popup })
        New("TextLabel", {
            BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0),
            Text="Transparency", TextColor3=lib.FontColor, Font=lib.Font, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102, Parent=tRow,
        })
        local tTrack = New("Frame", {
            BackgroundColor3=lib.DropdownColor, Size=UDim2.new(0.5,0,0,14),
            Position=UDim2.new(0.5,0,0.5,-7), ZIndex=102, Parent=tRow,
        })
        Corner(tTrack, 3)
        local tFill = New("Frame", {
            BackgroundColor3=lib.SliderColor, Size=UDim2.new(1-obj.Transparency,0,1,0),
            ZIndex=103, Parent=tTrack,
        })
        Corner(tFill, 3)
        local tDrag = false
        tTrack.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then tDrag = true end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then tDrag = false end
        end)
        RunService.RenderStepped:Connect(function()
            if tDrag then
                obj.Transparency = 1 - math.clamp((Mouse.X - tTrack.AbsolutePosition.X)/tTrack.AbsoluteSize.X,0,1)
                tFill.Size = UDim2.new(1-obj.Transparency,0,1,0)
                for _, cb in ipairs(obj._cbs) do pcall(cb, obj.Value, obj.Transparency) end
                if cfg.Callback then pcall(cfg.Callback, obj.Value, obj.Transparency) end
            end
        end)
    end

    UpdatePreview()

    local popOpen = false
    preview.MouseButton1Click:Connect(function()
        popOpen = not popOpen
        popup.Visible = popOpen
        lib.OpenedFrames[popup] = popOpen or nil
    end)

    function obj:SetValueRGB(c) H,S,V = Color3.toHSV(c); UpdatePreview() end
    function obj:SetValue(c, t)
        H,S,V = Color3.toHSV(c); if t ~= nil then self.Transparency = t end; UpdatePreview()
    end
    function obj:OnChanged(cb) table.insert(self._cbs, cb) end

    if cfg.Tooltip then lib:AddTooltip(cfg.Tooltip, row) end
    if index then Options[index] = obj end
    return obj
end

-- ─── KEY PICKER ──────────────────────────────────────────────────────────────
function Constructors.KeyPicker(lib, content, index, cfg)
    cfg = cfg or {}
    local obj = {
        Value        = cfg.Default or "None",
        Mode         = cfg.Mode or "Toggle",
        CurrentState = false,
        Type         = "KeyPicker",
        _cbs         = {},
        _clickCbs    = {},
    }

    local row = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), Parent=content })
    New("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,-78,1,0),
        Text=cfg.Text or "Keybind", TextColor3=lib.FontColor,
        Font=lib.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local btn = New("TextButton", {
        BackgroundColor3=lib.ButtonColor, Size=UDim2.new(0,70,0,24),
        Position=UDim2.new(1,-70,0.5,-12), Text=obj.Value,
        TextColor3=lib.FontColor, Font=lib.FontBold, TextSize=11, Parent=row,
    })
    Corner(btn, 6)
    if cfg.Tooltip then lib:AddTooltip(cfg.Tooltip, row) end

    local listening = false
    local listenConn = nil

    local function GetKeyName(i)
        if i.UserInputType == Enum.UserInputType.Keyboard then return i.KeyCode.Name
        elseif i.UserInputType == Enum.UserInputType.MouseButton1 then return "MB1"
        elseif i.UserInputType == Enum.UserInputType.MouseButton2 then return "MB2"
        end; return "None"
    end

    btn.MouseButton1Click:Connect(function()
        if listening then
            listening = false
            if listenConn then listenConn:Disconnect(); listenConn = nil end
            btn.Text = obj.Value; return
        end
        listening = true; btn.Text = "..."
        listenConn = UIS.InputBegan:Connect(function(i, proc)
            if proc then return end
            local k = GetKeyName(i)
            if k ~= "None" then
                listening = false; obj.Value = k; btn.Text = k
                for _, cb in ipairs(obj._cbs) do pcall(cb, k) end
                if cfg.ChangedCallback then pcall(cfg.ChangedCallback, k) end
                if listenConn then listenConn:Disconnect(); listenConn = nil end
            end
        end)
        task.delay(6, function()
            if listening then
                listening = false
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                btn.Text = obj.Value
            end
        end)
    end)

    -- State tracking
    UIS.InputBegan:Connect(function(i, proc)
        if proc or listening or Zilk.Unloaded then return end
        local k = GetKeyName(i)
        if k ~= obj.Value then return end
        if obj.Mode == "Toggle" then
            obj.CurrentState = not obj.CurrentState
            for _, cb in ipairs(obj._clickCbs) do pcall(cb) end
        elseif obj.Mode == "Hold" then
            obj.CurrentState = true
        elseif obj.Mode == "Always" then
            obj.CurrentState = true
        end
        if cfg.Callback then pcall(cfg.Callback, obj.CurrentState) end
    end)
    UIS.InputEnded:Connect(function(i)
        if obj.Mode == "Hold" then
            if GetKeyName(i) == obj.Value then obj.CurrentState = false end
        end
    end)

    function obj:GetState() return self.CurrentState end
    function obj:SetValue(t)
        if type(t) == "table" then
            if t[1] then self.Value = t[1]; btn.Text = t[1] end
            if t[2] then self.Mode = t[2] end
        else
            self.Value = tostring(t); btn.Text = tostring(t)
        end
    end
    function obj:OnChanged(cb) table.insert(self._cbs, cb) end
    function obj:OnClick(cb) table.insert(self._clickCbs, cb) end

    -- Add to keybind list (unless NoUI)
    if not cfg.NoUI then
        lib:_AddKeybindItem(cfg.Text or index or "Keybind", function() return obj.CurrentState end)
    end

    if index then Options[index] = obj end
    return obj
end

-- ============================================================================
-- DEPENDENCY BOX
-- ============================================================================
local function MakeGroupboxAPI(lib, contentFrame)
    -- Shared API mixed into both Groupbox and Depbox tables
    local api = { Content = contentFrame }

    function api:AddToggle(index, cfg)    return Constructors.Toggle(lib, contentFrame, index, cfg) end
    function api:AddSlider(index, cfg)    return Constructors.Slider(lib, contentFrame, index, cfg) end
    function api:AddInput(index, cfg)     return Constructors.Input(lib, contentFrame, index, cfg) end
    function api:AddDropdown(index, cfg)  return Constructors.Dropdown(lib, contentFrame, index, cfg) end
    function api:AddButton(cfg)           return Constructors.Button(lib, contentFrame, cfg) end
    function api:AddLabel(text, wrap)     return Constructors.Label(lib, contentFrame, text, wrap) end
    function api:AddDivider()             return Constructors.Divider(lib, contentFrame) end
    function api:AddColorPicker(i, cfg)   return Constructors.ColorPicker(lib, contentFrame, i, cfg) end
    function api:AddKeyPicker(i, cfg)     return Constructors.KeyPicker(lib, contentFrame, i, cfg) end

    function api:AddDependencyBox()
        local depFrame = New("Frame", {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,0),
            Visible=true, Parent=contentFrame,
        })
        local depLayout = ListLayout(depFrame, Enum.FillDirection.Vertical, 8)
        depLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            depFrame.Size = UDim2.new(1,0,0,depFrame.Visible and depLayout.AbsoluteContentSize.Y or 0)
        end)
        local depAPI   = MakeGroupboxAPI(lib, depFrame)
        local depDeps  = {}

        function depAPI:SetupDependencies(deps)
            depDeps = deps
            local function check()
                for _, d in ipairs(depDeps) do
                    local elem, want = d[1], d[2]
                    if elem and elem.Value ~= want then
                        depFrame.Visible = false; return
                    end
                end
                depFrame.Visible = true
            end
            check()
            for _, d in ipairs(depDeps) do
                if d[1] and d[1].OnChanged then
                    d[1]:OnChanged(function() check() end)
                end
            end
        end

        return depAPI
    end

    return api
end

-- ============================================================================
-- GROUPBOX BUILDER
-- ============================================================================
local function BuildGroupbox(lib, parentColumn, title)
    local gbFrame = New("Frame", {
        BackgroundColor3 = lib.BackgroundColor,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 36),
        Parent           = parentColumn,
    })
    Corner(gbFrame, 6)
    Stroke(gbFrame, lib.OutlineColor)

    -- Header
    local header = New("Frame", {
        BackgroundColor3 = lib.SectionColor,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 28),
        Parent           = gbFrame,
    })
    Corner(header, 6)
    -- flat bottom on header so it doesn't round into content
    New("Frame", {
        BackgroundColor3 = lib.SectionColor,
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        Parent           = header,
    })
    -- accent bottom line
    New("Frame", {
        BackgroundColor3 = lib.AccentColor,
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        Parent           = header,
    })
    New("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 10, 0, 0),
        Size       = UDim2.new(1, -20, 1, 0),
        Text       = (title or ""):upper(),
        TextColor3 = lib.AccentColor,
        Font       = lib.FontBold,
        TextSize   = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 2,
        Parent     = header,
    })

    -- Content container
    local content = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 32),
        Size     = UDim2.new(1, -16, 0, 0),
        Parent   = gbFrame,
    })
    local layout = ListLayout(content, Enum.FillDirection.Vertical, 8)
    Padding(content, 4, 0, 6, 0)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local h = layout.AbsoluteContentSize.Y + 10
        content.Size  = UDim2.new(1, -16, 0, h)
        gbFrame.Size  = UDim2.new(1, 0, 0, 32 + h + 8)
    end)

    local api = MakeGroupboxAPI(lib, content)
    api._frame = gbFrame
    return api
end

-- ============================================================================
-- TAB
-- ============================================================================
local function MakeTab(lib, scrollLeft, scrollRight)
    local tabAPI = {}

    function tabAPI:AddLeftGroupbox(title)
        return BuildGroupbox(lib, scrollLeft, title)
    end
    function tabAPI:AddRightGroupbox(title)
        return BuildGroupbox(lib, scrollRight, title)
    end
    function tabAPI:AddLeftTabbox()
        -- Tabbox: a tabbed container on the left column
        local tbFrame = New("Frame", {
            BackgroundColor3=lib.BackgroundColor, Size=UDim2.new(1,0,0,40), Parent=scrollLeft,
        })
        Corner(tbFrame, 6)
        Stroke(tbFrame, lib.OutlineColor)
        local tabBar = New("Frame", {
            BackgroundColor3=lib.SectionColor, Size=UDim2.new(1,0,0,28), Parent=tbFrame,
        })
        Corner(tabBar, 6)
        local tabBtnLayout = ListLayout(tabBar, Enum.FillDirection.Horizontal, 0)
        Padding(tabBar, 4, 4, 4, 4)
        local content = New("Frame", {
            BackgroundTransparency=1, Position=UDim2.new(0,10,0,34),
            Size=UDim2.new(1,-20,0,0), Parent=tbFrame,
        })
        local layout = ListLayout(content, Enum.FillDirection.Vertical, 8)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tbFrame.Size = UDim2.new(1,0,0,layout.AbsoluteContentSize.Y + 44)
        end)

        local pages = {}
        local tbxAPI = {}
        function tbxAPI:AddTab(name)
            local page = New("Frame", {
                BackgroundTransparency=1, Size=UDim2.new(1,0,0,0),
                Visible=false, Parent=content,
            })
            local pageLayout = ListLayout(page, Enum.FillDirection.Vertical, 8)
            pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                page.Size = UDim2.new(1,0,0, page.Visible and pageLayout.AbsoluteContentSize.Y or 0)
            end)
            local tabBtn = New("TextButton", {
                BackgroundTransparency= #pages==0 and 0 or 1,
                BackgroundColor3=lib.AccentColor,
                Size=UDim2.new(0,70,1,0), Text=name,
                TextColor3=lib.FontColor, Font=lib.FontBold, TextSize=11, Parent=tabBar,
            })
            Corner(tabBtn, 4)
            table.insert(pages, { page=page, btn=tabBtn })
            if #pages == 1 then page.Visible = true end
            tabBtn.MouseButton1Click:Connect(function()
                for _, p in ipairs(pages) do
                    p.page.Visible = false
                    p.btn.BackgroundTransparency = 1
                end
                page.Visible = true
                tabBtn.BackgroundTransparency = 0
            end)
            return MakeGroupboxAPI(lib, page)
        end
        return tbxAPI
    end
    function tabAPI:AddRightTabbox()
        local tbFrame = New("Frame", {
            BackgroundColor3=lib.BackgroundColor, Size=UDim2.new(1,0,0,40), Parent=scrollRight,
        })
        Corner(tbFrame, 6)
        Stroke(tbFrame, lib.OutlineColor)
        local tabBar = New("Frame", {
            BackgroundColor3=lib.SectionColor, Size=UDim2.new(1,0,0,28), Parent=tbFrame,
        })
        Corner(tabBar, 6)
        Padding(tabBar, 4, 4, 4, 4)
        ListLayout(tabBar, Enum.FillDirection.Horizontal, 0)
        local content = New("Frame", {
            BackgroundTransparency=1, Position=UDim2.new(0,10,0,34),
            Size=UDim2.new(1,-20,0,0), Parent=tbFrame,
        })
        local cLayout = ListLayout(content, Enum.FillDirection.Vertical, 8)
        cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tbFrame.Size = UDim2.new(1,0,0,cLayout.AbsoluteContentSize.Y + 44)
        end)
        local pages = {}
        local rTbx = {}
        function rTbx:AddTab(name)
            local page = New("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), Visible=#pages==0, Parent=content })
            local pLayout = ListLayout(page, Enum.FillDirection.Vertical, 8)
            pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                page.Size = UDim2.new(1,0,0, page.Visible and pLayout.AbsoluteContentSize.Y or 0)
            end)
            local tabBtn = New("TextButton", {
                BackgroundTransparency=#pages==0 and 0 or 1, BackgroundColor3=lib.AccentColor,
                Size=UDim2.new(0,70,1,0), Text=name,
                TextColor3=lib.FontColor, Font=lib.FontBold, TextSize=11, Parent=tabBar,
            })
            Corner(tabBtn, 4)
            table.insert(pages, {page=page, btn=tabBtn})
            tabBtn.MouseButton1Click:Connect(function()
                for _, p in ipairs(pages) do p.page.Visible=false; p.btn.BackgroundTransparency=1 end
                page.Visible=true; tabBtn.BackgroundTransparency=0
            end)
            return MakeGroupboxAPI(lib, page)
        end
        return rTbx
    end
    return tabAPI
end

-- ============================================================================
-- SETTINGS TAB  — user calls ThemeManager:ApplyToTab(tab) to attach this
-- ============================================================================
local function BuildSettingsTab(lib, tabAPI, specificBox)
    local uiBox, menuBox
    if specificBox then
        uiBox   = specificBox
        menuBox = specificBox
    else
        uiBox   = tabAPI:AddLeftGroupbox("UI Settings")
        menuBox = tabAPI:AddRightGroupbox("Menu")
    end

    uiBox:AddLabel("Accent Color"):AddColorPicker("ZilkAccentColor", {
        Default  = lib.AccentColor,
        Title    = "Accent Color",
        Callback = function(c) lib.AccentColor = c; lib:ApplyTheme() end,
    })

    uiBox:AddDivider()

    uiBox:AddToggle("ZilkWatermark", {
        Text    = "Show Watermark",
        Default = false,
        Callback = function(v) lib:SetWatermarkVisibility(v) end,
    })

    uiBox:AddToggle("ZilkKeybindList", {
        Text    = "Show Keybind List",
        Default = true,
        Callback = function(v)
            if lib.KeybindFrame then lib.KeybindFrame.Visible = v end
        end,
    })

    uiBox:AddToggle("ZilkNotifications", {
        Text    = "Show Notifications",
        Default = true,
        Callback = function(v) lib._notifEnabled = v end,
    })

    if not specificBox then
        menuBox:AddLabel("Menu Keybind"):AddKeyPicker("ZilkMenuKey", {
            Default = "RightShift",
            Mode    = "Toggle",
            NoUI    = true,
            Text    = "Menu keybind",
        })
        task.defer(function()
            if Options.ZilkMenuKey then lib.ToggleKeybind = Options.ZilkMenuKey end
        end)
        menuBox:AddDivider()
        menuBox:AddButton({
            Text = "Unload Menu",
            Func = function() lib:Unload() end,
        })
    end
end

-- ============================================================================
-- CONFIG TAB  — user calls SaveManager:BuildConfigSection(tab) to attach this
-- ============================================================================
local function BuildConfigTab(lib, tabAPI, saveMgr)
    local left  = tabAPI:AddLeftGroupbox("Config Manager")
    local right = tabAPI:AddRightGroupbox("Saved Configs")

    left:AddInput("ZilkConfigName", {
        Text        = "Config Name",
        Placeholder = "Enter name...",
        Default     = "",
    })

    left:AddButton({ Text = "Save Config",
        Func = function()
            local n = Options.ZilkConfigName and Options.ZilkConfigName.Value or ""
            if n ~= "" then lib:SaveConfig(n) else lib:Notify("Config","Enter a config name",2,lib.DangerColor) end
        end })

    left:AddButton({ Text = "Load Config",
        Func = function()
            local n = Options.ZilkConfigName and Options.ZilkConfigName.Value or ""
            if n ~= "" then lib:LoadConfig(n) else lib:Notify("Config","Enter a config name",2,lib.DangerColor) end
        end })

    left:AddButton({ Text = "Delete Config",
        Func = function()
            local n = Options.ZilkConfigName and Options.ZilkConfigName.Value or ""
            if n ~= "" then
                lib:DeleteConfig(n)
                RefreshConfigList()
            else lib:Notify("Config","Enter a config name",2,lib.DangerColor) end
        end })

    left:AddDivider()

    left:AddButton({ Text = "Set as Autoload",
        Func = function()
            local n = Options.ZilkConfigName and Options.ZilkConfigName.Value or ""
            if n ~= "" then
                lib:SetAutoload(n)
                lib:Notify("Config","Autoload set to: "..n,2,lib.AccentColor)
            else lib:Notify("Config","Enter a config name",2,lib.DangerColor) end
        end })

    -- Config list on the right
    local listLabel = right:AddLabel("No configs saved yet.", false)
    local configBtns = {}

    local function RefreshConfigList()
        for _, b in ipairs(configBtns) do
            if b._row and b._row.Parent then b._row:Destroy() end
        end
        configBtns = {}
        local configs = lib:ListConfigs()
        if #configs == 0 then
            listLabel._lbl.Text    = "No configs saved yet."
            listLabel._lbl.Visible = true
        else
            listLabel._lbl.Visible = false
            for _, name in ipairs(configs) do
                local b = Constructors.Button(lib, right.Content, {
                    Text = name,
                    Func = function()
                        if Options.ZilkConfigName then Options.ZilkConfigName:SetValue(name) end
                    end,
                })
                table.insert(configBtns, b)
            end
        end
    end

    right:AddDivider()
    right:AddButton({ Text = "↺ Refresh", Func = function() RefreshConfigList() end })
    RefreshConfigList()
end

-- ============================================================================
-- SAVE MANAGER  (Linoria pattern: SaveManager:SetLibrary / SetFolder / BuildConfigSection)
-- ============================================================================
local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager:SetLibrary(lib)
    self._lib = lib
end

function SaveManager:SetFolder(path)
    self._folder = path
    if self._lib then
        self._lib.ConfigFolder = path
    end
end

function SaveManager:IgnoreThemeSettings()
    self._ignoreTheme = true
end

function SaveManager:SetIgnoreIndexes(t)
    self._ignoreIndexes = t or {}
end

function SaveManager:BuildConfigSection(tab)
    if not self._lib then return end
    BuildConfigTab(self._lib, tab, self)
end

function SaveManager:LoadAutoloadConfig()
    if self._lib then self._lib:LoadAutoloadConfig() end
end

Zilk.SaveManager = SaveManager

-- ============================================================================
-- THEME MANAGER  (Linoria pattern: ThemeManager:SetLibrary / ApplyToTab)
-- ============================================================================
local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager:SetLibrary(lib)
    self._lib = lib
end

function ThemeManager:SetFolder(path)
    self._folder = path
end

function ThemeManager:ApplyToTab(tab)
    if not self._lib then return end
    BuildSettingsTab(self._lib, tab)
end

function ThemeManager:ApplyToGroupbox(box)
    if not self._lib then return end
    BuildSettingsTab(self._lib, nil, box)
end

Zilk.ThemeManager = ThemeManager

-- ============================================================================
-- CREATE WINDOW
-- ============================================================================
function Zilk:CreateWindow(cfg)
    cfg = cfg or {}
    cfg.Title      = cfg.Title    or "Zilk"
    cfg.Size       = cfg.Size     or UDim2.new(0, 660, 0, 560)
    cfg.Center     = cfg.Center   ~= false
    cfg.AutoShow   = cfg.AutoShow == true
    cfg.FadeTime   = cfg.FadeTime or 0.2

    local lib = self

    -- Outer border frame (accent coloured ring)
    local mainFrame = New("Frame", {
        BackgroundColor3 = lib.AccentColor,
        Size    = cfg.Size,
        Position = cfg.Center
            and UDim2.new(0.5, -cfg.Size.X.Offset/2, 0.5, -cfg.Size.Y.Offset/2)
            or  UDim2.new(0, 100, 0, 50),
        Visible = cfg.AutoShow,
        Parent  = ScreenGui,
    })
    Corner(mainFrame, 8)
    self:MakeDraggable(mainFrame, 36)

    -- Inner dark body
    local body = New("Frame", {
        BackgroundColor3 = lib.MainColor,
        Position = UDim2.new(0, 1, 0, 1),
        Size     = UDim2.new(1, -2, 1, -2),
        Parent   = mainFrame,
    })
    Corner(body, 7)

    -- Title bar
    local titleBar = New("Frame", {
        BackgroundColor3 = lib.SectionColor,
        Size     = UDim2.new(1, 0, 0, 36),
        Parent   = body,
    })
    Corner(titleBar, 7)
    -- bottom corners of title bar should be square (clip with body)
    New("Frame", {
        BackgroundColor3 = lib.SectionColor,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size     = UDim2.new(1, 0, 0.5, 0),
        Parent   = titleBar,
    })
    New("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 12, 0, 0),
        Size       = UDim2.new(1, -24, 1, 0),
        Text       = cfg.Title,
        TextColor3 = lib.FontColor,
        Font       = lib.FontBold,
        TextSize   = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 2,
        Parent     = titleBar,
    })

    -- Sidebar (left tab strip)
    local sidebar = New("Frame", {
        BackgroundColor3 = lib.SectionColor,
        Position = UDim2.new(0, 0, 0, 36),
        Size     = UDim2.new(0, 112, 1, -36),
        Parent   = body,
    })
    -- square top-right corner to merge with title bar
    New("Frame", {
        BackgroundColor3 = lib.SectionColor,
        Position = UDim2.new(1, -8, 0, 0),
        Size     = UDim2.new(0, 8, 0.1, 0),
        Parent   = sidebar,
    })
    Corner(sidebar, 7)
    -- accent separator line between sidebar and content
    New("Frame", {
        BackgroundColor3 = lib.AccentColor,
        Position = UDim2.new(1, -1, 0, 0),
        Size     = UDim2.new(0, 1, 1, 0),
        ZIndex   = 2,
        Parent   = sidebar,
    })

    local sideLayout = ListLayout(sidebar, Enum.FillDirection.Vertical, 4)
    Padding(sidebar, 10, 6, 8, 6)

    -- Content area (right of sidebar)
    local contentArea = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 118, 0, 42),
        Size     = UDim2.new(1, -126, 1, -50),
        Parent   = body,
    })

    local Window = {
        Tabs    = {},
        _lib    = lib,
        _frame  = mainFrame,
        _pages  = {},
        _sidebar = sidebar,
        _contentArea = contentArea,
    }
    self._window = Window

    local function ActivateTab(entry)
        for _, e in ipairs(Window._pages) do
            e.page.Visible = false
            e.btn.BackgroundColor3      = Color3.fromRGB(0,0,0)
            e.btn.BackgroundTransparency = 1
            e.btn.TextColor3            = Color3.fromRGB(160,160,160)
        end
        entry.page.Visible              = true
        entry.btn.BackgroundColor3      = lib.AccentColor
        entry.btn.BackgroundTransparency = 0
        entry.btn.TextColor3            = Color3.fromRGB(255,255,255)
    end

    -- Add tab
    function Window:AddTab(name)
        local tabBtn = New("TextButton", {
            BackgroundColor3      = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 1,
            Size       = UDim2.new(1, 0, 0, 28),
            Text       = name,
            TextColor3 = Color3.fromRGB(160,160,160),
            Font       = lib.FontBold,
            TextSize   = 12,
            Parent     = sidebar,
        })
        Corner(tabBtn, 5)

        -- Page (scrolling)
        local page = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = lib.AccentColor,
            BorderSizePixel        = 0,
            Visible                = false,
            Parent                 = contentArea,
        })

        -- Two columns
        local leftCol = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 6),
            Size     = UDim2.new(0.5, -5, 1, -6),
            Parent   = page,
        })
        local rightCol = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 5, 0, 6),
            Size     = UDim2.new(0.5, -5, 1, -6),
            Parent   = page,
        })

        local leftLayout  = ListLayout(leftCol,  Enum.FillDirection.Vertical, 8)
        local rightLayout = ListLayout(rightCol, Enum.FillDirection.Vertical, 8)

        local function UpdateCanvas()
            local h = math.max(
                leftLayout.AbsoluteContentSize.Y,
                rightLayout.AbsoluteContentSize.Y
            ) + 20
            page.CanvasSize = UDim2.new(0, 0, 0, h)
        end
        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        local entry = { btn = tabBtn, page = page, left = leftCol, right = rightCol }
        table.insert(Window._pages, entry)
        Window.Tabs[name] = entry

        -- Activate first tab automatically
        if #Window._pages == 1 then
            ActivateTab(entry)
        end

        tabBtn.MouseButton1Click:Connect(function()
            ActivateTab(entry)
        end)

        return MakeTab(lib, leftCol, rightCol)
    end

    -- Menu toggle
    local menuVis = cfg.AutoShow
    local fading  = false
    local function ToggleMenu()
        if fading then return end
        fading = true
        menuVis = not menuVis
        if menuVis then
            mainFrame.Visible = true
            mainFrame.BackgroundTransparency = 1
            Tween(mainFrame, TweenInfo.new(cfg.FadeTime), { BackgroundTransparency = 0 })
        else
            Tween(mainFrame, TweenInfo.new(cfg.FadeTime), { BackgroundTransparency = 1 })
            task.wait(cfg.FadeTime)
            mainFrame.Visible = false
        end
        fading = false
    end

    lib.ToggleMenu = ToggleMenu

    UIS.InputBegan:Connect(function(i, proc)
        if proc or lib.Unloaded then return end
        local toggle = lib.ToggleKeybind
        if toggle then
            local k = i.KeyCode and i.KeyCode.Name or ""
            if k == tostring(toggle.Value) then ToggleMenu() end
        else
            if i.KeyCode == Enum.KeyCode.RightShift then ToggleMenu() end
        end
    end)

    -- Build watermark + keybind HUD
    BuildWatermark(lib)
    BuildKeybindFrame(lib)

    return Window
end

-- ============================================================================
-- EXPORTS
-- ============================================================================
getgenv().Zilk    = Zilk
getgenv().Toggles = Toggles
getgenv().Options  = Options

return Zilk
