local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Zilk = {
    _version = "1.0.0",
    _windows = {},
    _connections = {},
    _themeBindings = {},
    _options = {},
    _configFolder = "ZilkLib",
    _menuKeybind = Enum.KeyCode.RightShift,
    _notificationGui = nil,
}

local DEFAULT_THEME = {
    MainColor = Color3.fromRGB(20, 20, 24),
    SectionColor = Color3.fromRGB(28, 28, 34),
    AccentColor = Color3.fromRGB(155, 88, 255),
    TextColor = Color3.fromRGB(240, 240, 245),
    MutedTextColor = Color3.fromRGB(170, 170, 180),
    StrokeColor = Color3.fromRGB(10, 10, 12),
    Font = Enum.Font.Gotham,
}

Zilk._theme = table.clone(DEFAULT_THEME)

local function cloneTable(tbl)
    local new = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            new[k] = cloneTable(v)
        else
            new[k] = v
        end
    end
    return new
end

local function safeCall(cb, ...)
    if typeof(cb) ~= "function" then
        return
    end
    local ok, err = pcall(cb, ...)
    if not ok then
        warn("[Zilk] callback error:", err)
    end
end

local function makeCorner(inst, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = inst
    return corner
end

local function makeStroke(inst, color)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Parent = inst
    return stroke
end

local function registerThemeBinding(inst, prop, token)
    table.insert(Zilk._themeBindings, { inst = inst, prop = prop, token = token })
end

local function applyThemeToInstance(inst, prop, token)
    if inst and inst.Parent then
        local value = Zilk._theme[token]
        if value ~= nil then
            inst[prop] = value
        end
    end
end

function Zilk:_applyThemeBindings()
    for i = #self._themeBindings, 1, -1 do
        local entry = self._themeBindings[i]
        if not entry.inst or not entry.inst.Parent then
            table.remove(self._themeBindings, i)
        else
            applyThemeToInstance(entry.inst, entry.prop, entry.token)
        end
    end
end

function Zilk:GetTheme()
    return cloneTable(self._theme)
end

function Zilk:SetTheme(themeTable)
    if type(themeTable) ~= "table" then
        return
    end
    for key, value in pairs(themeTable) do
        if self._theme[key] ~= nil then
            self._theme[key] = value
        end
    end
    self:_applyThemeBindings()
end

local function createNotificationGui()
    if Zilk._notificationGui and Zilk._notificationGui.Parent then
        return Zilk._notificationGui
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "Zilk_Notifications"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = game:GetService("CoreGui")

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.AnchorPoint = Vector2.new(1, 0)
    holder.Position = UDim2.new(1, -20, 0, 20)
    holder.Size = UDim2.new(0, 360, 1, -40)
    holder.BackgroundTransparency = 1
    holder.Parent = gui

    local layout = Instance.new("UIListLayout")
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 10)
    layout.Parent = holder

    Zilk._notificationGui = gui
    return gui
end

function Zilk:Notify(title, message, duration)
    duration = duration or 3
    local gui = createNotificationGui()
    local holder = gui:FindFirstChild("Holder")
    if not holder then
        return
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 74)
    toast.BackgroundColor3 = self._theme.SectionColor
    toast.BackgroundTransparency = 0.08
    toast.Parent = holder
    makeCorner(toast, 8)
    makeStroke(toast, self._theme.AccentColor)
    registerThemeBinding(toast, "BackgroundColor3", "SectionColor")

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Font = self._theme.Font
    titleLabel.TextColor3 = self._theme.TextColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextSize = 15
    titleLabel.Text = tostring(title or "Zilk")
    titleLabel.Parent = toast
    registerThemeBinding(titleLabel, "TextColor3", "TextColor")
    registerThemeBinding(titleLabel, "Font", "Font")

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Position = UDim2.new(0, 10, 0, 30)
    bodyLabel.Size = UDim2.new(1, -20, 0, 34)
    bodyLabel.Font = self._theme.Font
    bodyLabel.TextColor3 = self._theme.MutedTextColor
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
    bodyLabel.TextWrapped = true
    bodyLabel.TextSize = 13
    bodyLabel.Text = tostring(message or "")
    bodyLabel.Parent = toast
    registerThemeBinding(bodyLabel, "TextColor3", "MutedTextColor")
    registerThemeBinding(bodyLabel, "Font", "Font")

    task.delay(duration, function()
        if toast and toast.Parent then
            toast:Destroy()
        end
    end)
end

local function normalizeId(text)
    local id = tostring(text or "Option"):gsub("%s+", "_"):gsub("[^%w_]", "")
    if id == "" then
        id = "Option"
    end
    return id
end

local function addControlRecord(window, record)
    window._controls[record.id] = record
end

local function createContainer(parent)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = frame
    return frame
end

local Groupbox = {}
Groupbox.__index = Groupbox

local Tab = {}
Tab.__index = Tab

local Window = {}
Window.__index = Window

local function makeControlObject(record)
    local obj = {}
    obj.Value = record.value

    function obj:SetValue(newValue)
        record.set(newValue, true)
    end

    function obj:OnChanged(cb)
        record.changed = cb
    end

    return obj
end

function Groupbox:_newControlShell(labelText)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Zilk._theme.SectionColor
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BorderSizePixel = 0
    row.Parent = self._content
    makeCorner(row, 6)
    makeStroke(row, Zilk._theme.StrokeColor)
    registerThemeBinding(row, "BackgroundColor3", "SectionColor")

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 8, 0, 0)
    label.Size = UDim2.new(1, -16, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Zilk._theme.TextColor
    label.Font = Zilk._theme.Font
    label.TextSize = 13
    label.Text = labelText
    label.Parent = row
    registerThemeBinding(label, "TextColor3", "TextColor")
    registerThemeBinding(label, "Font", "Font")
    return row, label
end

function Groupbox:CreateToggle(text, default, callback, id)
    id = id or normalizeId(text)
    local row = self:_newControlShell(text)
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -8, 0.5, 0)
    button.Size = UDim2.new(0, 22, 0, 22)
    button.Text = ""
    button.BackgroundColor3 = Zilk._theme.MainColor
    button.BorderSizePixel = 0
    button.Parent = row
    makeCorner(button, 4)
    makeStroke(button, Zilk._theme.StrokeColor)
    registerThemeBinding(button, "BackgroundColor3", "MainColor")

    local marker = Instance.new("Frame")
    marker.AnchorPoint = Vector2.new(0.5, 0.5)
    marker.Position = UDim2.new(0.5, 0, 0.5, 0)
    marker.Size = UDim2.new(1, -6, 1, -6)
    marker.BackgroundColor3 = Zilk._theme.AccentColor
    marker.Visible = false
    marker.BorderSizePixel = 0
    marker.Parent = button
    makeCorner(marker, 3)
    registerThemeBinding(marker, "BackgroundColor3", "AccentColor")

    local record = { id = id, type = "toggle", value = default == true, changed = callback }
    local out = makeControlObject(record)
    Zilk._options[id] = out
    record.set = function(v, fromApi)
        record.value = v == true
        out.Value = record.value
        marker.Visible = record.value
        if fromApi or callback then
            safeCall(record.changed, record.value)
        end
    end

    button.MouseButton1Click:Connect(function()
        record.set(not record.value, true)
    end)
    addControlRecord(self._window, record)
    record.set(record.value, false)
    return out
end

function Groupbox:CreateButton(text, callback)
    local row = self:_newControlShell("")
    row.Size = UDim2.new(1, 0, 0, 30)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 1, -6)
    button.Position = UDim2.new(0, 5, 0, 3)
    button.BackgroundColor3 = Zilk._theme.MainColor
    button.BorderSizePixel = 0
    button.TextColor3 = Zilk._theme.TextColor
    button.Font = Zilk._theme.Font
    button.TextSize = 13
    button.Text = text
    button.Parent = row
    makeCorner(button, 4)
    makeStroke(button, Zilk._theme.StrokeColor)
    registerThemeBinding(button, "BackgroundColor3", "MainColor")
    registerThemeBinding(button, "TextColor3", "TextColor")
    registerThemeBinding(button, "Font", "Font")
    button.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)
    return button
end

function Groupbox:CreateSlider(text, min, max, default, rounding, callback, id)
    id = id or normalizeId(text)
    rounding = rounding or 0
    min = min or 0
    max = max or 100
    default = default or min

    local row, label = self:_newControlShell(text)
    row.Size = UDim2.new(1, 0, 0, 44)
    label.Size = UDim2.new(0.55, -12, 0, 20)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(0.55, 0, 0, 0)
    valueLabel.Size = UDim2.new(0.45, -8, 0, 20)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = Zilk._theme.MutedTextColor
    valueLabel.Font = Zilk._theme.Font
    valueLabel.TextSize = 12
    valueLabel.Parent = row
    registerThemeBinding(valueLabel, "TextColor3", "MutedTextColor")
    registerThemeBinding(valueLabel, "Font", "Font")

    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0, 8, 0, 24)
    bar.Size = UDim2.new(1, -16, 0, 14)
    bar.BackgroundColor3 = Zilk._theme.MainColor
    bar.BorderSizePixel = 0
    bar.Parent = row
    makeCorner(bar, 4)
    makeStroke(bar, Zilk._theme.StrokeColor)
    registerThemeBinding(bar, "BackgroundColor3", "MainColor")

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Zilk._theme.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = bar
    makeCorner(fill, 4)
    registerThemeBinding(fill, "BackgroundColor3", "AccentColor")

    local record = { id = id, type = "slider", value = default, changed = callback, min = min, max = max, rounding = rounding }
    local out = makeControlObject(record)
    Zilk._options[id] = out
    record.set = function(v, fromApi)
        local nv = math.clamp(tonumber(v) or min, min, max)
        local power = 10 ^ rounding
        nv = math.round(nv * power) / power
        record.value = nv
        out.Value = record.value
        local pct = (nv - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = tostring(nv)
        safeCall(record.changed, record.value)
    end

    local dragging = false
    local function updateFromMouse()
        local x = UserInputService:GetMouseLocation().X
        local left = bar.AbsolutePosition.X
        local width = math.max(bar.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - left) / width, 0, 1)
        record.set(min + ((max - min) * alpha), true)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)

    addControlRecord(self._window, record)
    record.set(default, false)
    return out
end

function Groupbox:CreateDropdown(text, values, default, callback, id)
    id = id or normalizeId(text)
    values = values or {}
    default = default or values[1]

    local row, label = self:_newControlShell(text)
    label.Size = UDim2.new(0.45, -8, 1, 0)
    local button = Instance.new("TextButton")
    button.Position = UDim2.new(0.45, 0, 0, 4)
    button.Size = UDim2.new(0.55, -8, 1, -8)
    button.BackgroundColor3 = Zilk._theme.MainColor
    button.BorderSizePixel = 0
    button.TextColor3 = Zilk._theme.TextColor
    button.Font = Zilk._theme.Font
    button.TextSize = 12
    button.Text = ""
    button.Parent = row
    makeCorner(button, 4)
    makeStroke(button, Zilk._theme.StrokeColor)
    registerThemeBinding(button, "BackgroundColor3", "MainColor")
    registerThemeBinding(button, "TextColor3", "TextColor")
    registerThemeBinding(button, "Font", "Font")

    local list = Instance.new("Frame")
    list.BackgroundColor3 = Zilk._theme.SectionColor
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 60
    list.Position = UDim2.new(0, 0, 1, 4)
    list.Size = UDim2.new(1, 0, 0, (#values * 24) + 4)
    list.Parent = button
    makeCorner(list, 4)
    makeStroke(list, Zilk._theme.StrokeColor)
    registerThemeBinding(list, "BackgroundColor3", "SectionColor")

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = list

    local record = { id = id, type = "dropdown", value = default, changed = callback, values = values }
    local out = makeControlObject(record)
    Zilk._options[id] = out
    record.set = function(v, fromApi)
        record.value = v
        out.Value = record.value
        button.Text = tostring(v)
        safeCall(record.changed, record.value)
    end

    for _, value in ipairs(values) do
        local opt = Instance.new("TextButton")
        opt.Size = UDim2.new(1, -4, 0, 22)
        opt.Position = UDim2.new(0, 2, 0, 0)
        opt.BackgroundColor3 = Zilk._theme.MainColor
        opt.BorderSizePixel = 0
        opt.TextColor3 = Zilk._theme.TextColor
        opt.Font = Zilk._theme.Font
        opt.TextSize = 12
        opt.Text = tostring(value)
        opt.ZIndex = 61
        opt.Parent = list
        makeCorner(opt, 4)
        registerThemeBinding(opt, "BackgroundColor3", "MainColor")
        registerThemeBinding(opt, "TextColor3", "TextColor")
        registerThemeBinding(opt, "Font", "Font")

        opt.MouseButton1Click:Connect(function()
            list.Visible = false
            record.set(value, true)
        end)
    end

    button.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
    end)

    addControlRecord(self._window, record)
    record.set(default, false)
    return out
end

function Groupbox:CreateInput(text, default, callback, id)
    id = id or normalizeId(text)
    local row, label = self:_newControlShell(text)
    label.Size = UDim2.new(0.4, -8, 1, 0)

    local box = Instance.new("TextBox")
    box.Position = UDim2.new(0.4, 0, 0, 4)
    box.Size = UDim2.new(0.6, -8, 1, -8)
    box.BackgroundColor3 = Zilk._theme.MainColor
    box.BorderSizePixel = 0
    box.Font = Zilk._theme.Font
    box.TextColor3 = Zilk._theme.TextColor
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.PlaceholderText = "..."
    box.ClearTextOnFocus = false
    box.Parent = row
    makeCorner(box, 4)
    makeStroke(box, Zilk._theme.StrokeColor)
    registerThemeBinding(box, "BackgroundColor3", "MainColor")
    registerThemeBinding(box, "TextColor3", "TextColor")
    registerThemeBinding(box, "Font", "Font")

    local record = { id = id, type = "input", value = default or "", changed = callback }
    local out = makeControlObject(record)
    Zilk._options[id] = out
    record.set = function(v, fromApi)
        record.value = tostring(v or "")
        out.Value = record.value
        box.Text = record.value
        safeCall(record.changed, record.value)
    end

    box.FocusLost:Connect(function()
        record.set(box.Text, true)
    end)

    addControlRecord(self._window, record)
    record.set(default or "", false)
    return out
end

function Groupbox:CreateKeybind(text, defaultKey, callback, id)
    id = id or normalizeId(text)
    local row = self:_newControlShell(text)
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -8, 0.5, 0)
    button.Size = UDim2.new(0, 100, 0, 22)
    button.BackgroundColor3 = Zilk._theme.MainColor
    button.BorderSizePixel = 0
    button.TextColor3 = Zilk._theme.TextColor
    button.Font = Zilk._theme.Font
    button.TextSize = 12
    button.Parent = row
    makeCorner(button, 4)
    makeStroke(button, Zilk._theme.StrokeColor)
    registerThemeBinding(button, "BackgroundColor3", "MainColor")
    registerThemeBinding(button, "TextColor3", "TextColor")
    registerThemeBinding(button, "Font", "Font")

    local record = { id = id, type = "keybind", value = defaultKey or Enum.KeyCode.Unknown, changed = callback, listening = false }
    local out = makeControlObject(record)
    Zilk._options[id] = out
    record.set = function(v, fromApi)
        record.value = v
        out.Value = record.value
        local name = (typeof(v) == "EnumItem" and v.Name) or tostring(v)
        button.Text = name
        safeCall(record.changed, record.value)
    end

    button.MouseButton1Click:Connect(function()
        record.listening = true
        button.Text = "Press key..."
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if record.listening and input.UserInputType == Enum.UserInputType.Keyboard then
            record.listening = false
            record.set(input.KeyCode, true)
            return
        end
        if input.KeyCode == record.value then
            safeCall(record.changed, true)
        end
    end)

    addControlRecord(self._window, record)
    record.set(record.value, false)
    return out
end

function Groupbox:CreateColorPicker(text, defaultColor, callback, id)
    id = id or normalizeId(text)
    local row = self:_newControlShell(text)

    local preview = Instance.new("TextButton")
    preview.AnchorPoint = Vector2.new(1, 0.5)
    preview.Position = UDim2.new(1, -8, 0.5, 0)
    preview.Size = UDim2.new(0, 28, 0, 22)
    preview.Text = ""
    preview.BorderSizePixel = 0
    preview.Parent = row
    makeCorner(preview, 4)
    makeStroke(preview, Zilk._theme.StrokeColor)

    local colors = {
        Color3.fromRGB(255, 72, 72),
        Color3.fromRGB(88, 255, 130),
        Color3.fromRGB(91, 176, 255),
        Color3.fromRGB(255, 214, 77),
        Color3.fromRGB(182, 124, 255),
        Color3.fromRGB(255, 255, 255),
    }

    local picker = Instance.new("Frame")
    picker.Visible = false
    picker.Size = UDim2.new(0, 170, 0, 86)
    picker.Position = UDim2.new(1, -170, 1, 4)
    picker.BackgroundColor3 = Zilk._theme.SectionColor
    picker.BorderSizePixel = 0
    picker.ZIndex = 70
    picker.Parent = row
    makeCorner(picker, 6)
    makeStroke(picker, Zilk._theme.StrokeColor)
    registerThemeBinding(picker, "BackgroundColor3", "SectionColor")

    local record = { id = id, type = "color", value = defaultColor or Zilk._theme.AccentColor, changed = callback }
    local out = makeControlObject(record)
    Zilk._options[id] = out
    record.set = function(v, fromApi)
        if typeof(v) ~= "Color3" then
            return
        end
        record.value = v
        out.Value = record.value
        preview.BackgroundColor3 = v
        safeCall(record.changed, record.value)
    end

    for i, color in ipairs(colors) do
        local cbtn = Instance.new("TextButton")
        cbtn.Size = UDim2.new(0, 24, 0, 24)
        cbtn.Position = UDim2.new(0, 8 + (((i - 1) % 6) * 26), 0, 10)
        cbtn.BackgroundColor3 = color
        cbtn.BorderSizePixel = 0
        cbtn.Text = ""
        cbtn.ZIndex = 71
        cbtn.Parent = picker
        makeCorner(cbtn, 4)
        cbtn.MouseButton1Click:Connect(function()
            record.set(color, true)
            picker.Visible = false
        end)
    end

    preview.MouseButton1Click:Connect(function()
        picker.Visible = not picker.Visible
    end)

    addControlRecord(self._window, record)
    record.set(record.value, false)
    return out
end

function Groupbox:CreateLabel(text)
    local row = self:_newControlShell(text)
    row.Size = UDim2.new(1, 0, 0, 24)
    return row
end

function Groupbox:CreateDivider()
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, 0, 0, 1)
    div.BackgroundColor3 = Zilk._theme.StrokeColor
    div.BorderSizePixel = 0
    div.Parent = self._content
    registerThemeBinding(div, "BackgroundColor3", "StrokeColor")
    return div
end

function Tab:CreateGroupBox(side, title)
    local host = side == "right" and self._right or self._left
    local box = Instance.new("Frame")
    box.BackgroundColor3 = Zilk._theme.SectionColor
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.Parent = host
    makeCorner(box, 6)
    makeStroke(box, Zilk._theme.StrokeColor)
    registerThemeBinding(box, "BackgroundColor3", "SectionColor")

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -12, 0, 24)
    titleLabel.Position = UDim2.new(0, 8, 0, 2)
    titleLabel.TextColor3 = Zilk._theme.TextColor
    titleLabel.Font = Zilk._theme.Font
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = tostring(title)
    titleLabel.Parent = box
    registerThemeBinding(titleLabel, "TextColor3", "TextColor")
    registerThemeBinding(titleLabel, "Font", "Font")

    local content = createContainer(box)
    content.Position = UDim2.new(0, 8, 0, 28)
    content.Size = UDim2.new(1, -16, 0, 0)

    local group = setmetatable({
        _window = self._window,
        _content = content,
    }, Groupbox)

    return group
end

function Window:CreateTab(name, isDefault)
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(1, -10, 0, 30)
    tabButton.Position = UDim2.new(0, 5, 0, 0)
    tabButton.BackgroundColor3 = Zilk._theme.SectionColor
    tabButton.BorderSizePixel = 0
    tabButton.TextColor3 = Zilk._theme.TextColor
    tabButton.Font = Zilk._theme.Font
    tabButton.TextSize = 13
    tabButton.Text = tostring(name)
    tabButton.Parent = self._tabContainer
    makeCorner(tabButton, 6)
    makeStroke(tabButton, Zilk._theme.StrokeColor)
    registerThemeBinding(tabButton, "BackgroundColor3", "SectionColor")
    registerThemeBinding(tabButton, "TextColor3", "TextColor")
    registerThemeBinding(tabButton, "Font", "Font")

    local page = Instance.new("ScrollingFrame")
    page.Name = tostring(name) .. "_Page"
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, -100, 1, -10)
    page.Position = UDim2.new(0, 95, 0, 5)
    page.ScrollBarThickness = 4
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = isDefault == true
    page.Parent = self._mainFrame

    local left = createContainer(page)
    left.Size = UDim2.new(0.5, -6, 0, 0)
    left.Position = UDim2.new(0, 0, 0, 0)

    local right = createContainer(page)
    right.Size = UDim2.new(0.5, -6, 0, 0)
    right.Position = UDim2.new(0.5, 6, 0, 0)

    local tab = setmetatable({
        _window = self,
        _page = page,
        _left = left,
        _right = right,
    }, Tab)

    table.insert(self._tabs, { name = name, button = tabButton, page = page })
    tabButton.MouseButton1Click:Connect(function()
        for _, info in ipairs(self._tabs) do
            info.page.Visible = false
            info.button.BackgroundColor3 = Zilk._theme.SectionColor
        end
        page.Visible = true
        tabButton.BackgroundColor3 = Zilk._theme.AccentColor
    end)

    if isDefault then
        tabButton.BackgroundColor3 = Zilk._theme.AccentColor
    end

    return tab
end

function Window:Toggle()
    self._visible = not self._visible
    self._screenGui.Enabled = self._visible
end

function Window:Unload()
    if self._screenGui and self._screenGui.Parent then
        self._screenGui:Destroy()
    end
    for _, conn in ipairs(self._connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    self._connections = {}
end

local function createBaseWindow(opts)
    opts = opts or {}
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = opts.Name or "ZilkGUI"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = opts.Size or UDim2.fromOffset(760, 560)
    mainFrame.Position = opts.Position or UDim2.new(0.5, -380, 0.5, -280)
    mainFrame.BackgroundColor3 = Zilk._theme.MainColor
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    makeCorner(mainFrame, 8)
    makeStroke(mainFrame, Zilk._theme.AccentColor)
    registerThemeBinding(mainFrame, "BackgroundColor3", "MainColor")

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Zilk._theme.SectionColor
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    makeCorner(titleBar, 8)
    registerThemeBinding(titleBar, "BackgroundColor3", "SectionColor")

    local titleText = Instance.new("TextLabel")
    titleText.BackgroundTransparency = 1
    titleText.Size = UDim2.new(1, -20, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.Text = opts.Title or "Zilk UI"
    titleText.TextColor3 = Zilk._theme.TextColor
    titleText.Font = Zilk._theme.Font
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    registerThemeBinding(titleText, "TextColor3", "TextColor")
    registerThemeBinding(titleText, "Font", "Font")

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 90, 1, -38)
    tabContainer.Position = UDim2.new(0, 5, 0, 34)
    tabContainer.BackgroundColor3 = Zilk._theme.SectionColor
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    makeCorner(tabContainer, 6)
    registerThemeBinding(tabContainer, "BackgroundColor3", "SectionColor")

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabContainer

    local dragging = false
    local dragStart = Vector2.zero
    local startPos = UDim2.new()
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = UserInputService:GetMouseLocation()
            startPos = mainFrame.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = UserInputService:GetMouseLocation() - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return screenGui, mainFrame, tabContainer
end

function Zilk:CreateWindow(opts)
    local screenGui, mainFrame, tabContainer = createBaseWindow(opts)
    local window = setmetatable({
        _screenGui = screenGui,
        _mainFrame = mainFrame,
        _tabContainer = tabContainer,
        _tabs = {},
        _controls = {},
        _connections = {},
        _visible = true,
    }, Window)

    table.insert(self._windows, window)
    return window
end

function Zilk:SetMenuKeybind(keyCode)
    if typeof(keyCode) == "EnumItem" then
        self._menuKeybind = keyCode
    end
end

function Zilk:GetOptions()
    return self._options
end

function Zilk:SetConfigFolder(folder)
    self._configFolder = tostring(folder or "ZilkLib")
end

local function canFileApi()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
        and typeof(makefolder) == "function"
        and typeof(listfiles) == "function"
end

local function ensureFolder(path)
    if typeof(isfolder) == "function" and isfolder(path) then
        return true
    end
    if typeof(makefolder) == "function" then
        pcall(makefolder, path)
    end
    return typeof(isfolder) == "function" and isfolder(path)
end

function Zilk:SaveConfig(name)
    if not canFileApi() then
        return false, "File API unavailable"
    end
    ensureFolder(self._configFolder)
    local payload = {}
    for id, record in pairs(self._options) do
        if type(record) == "table" and record.Value ~= nil then
            local v = record.Value
            if typeof(v) == "Color3" then
                payload[id] = { __type = "Color3", r = v.R, g = v.G, b = v.B }
            elseif typeof(v) == "EnumItem" then
                payload[id] = { __type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
            else
                payload[id] = v
            end
        end
    end
    local file = string.format("%s/%s.json", self._configFolder, normalizeId(name))
    writefile(file, HttpService:JSONEncode(payload))
    return true
end

function Zilk:LoadConfig(name)
    if not canFileApi() then
        return false, "File API unavailable"
    end
    local file = string.format("%s/%s.json", self._configFolder, normalizeId(name))
    if not isfile(file) then
        return false, "Config not found"
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(file))
    end)
    if not ok then
        return false, "Invalid config format"
    end

    for id, value in pairs(data) do
        local option = self._options[id]
        if option and typeof(option.SetValue) == "function" then
            if type(value) == "table" and value.__type == "Color3" then
                option:SetValue(Color3.new(value.r, value.g, value.b))
            else
                option:SetValue(value)
            end
        end
    end
    return true
end

function Zilk:ListConfigs()
    if not canFileApi() then
        return {}
    end
    ensureFolder(self._configFolder)
    local out = {}
    for _, path in ipairs(listfiles(self._configFolder)) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            table.insert(out, name)
        end
    end
    table.sort(out)
    return out
end

function Zilk:Unload()
    for _, window in ipairs(self._windows) do
        window:Unload()
    end
    self._windows = {}

    for _, conn in ipairs(self._connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    self._connections = {}

    if self._notificationGui and self._notificationGui.Parent then
        self._notificationGui:Destroy()
    end
    self._notificationGui = nil
end

table.insert(Zilk._connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Zilk._menuKeybind then
        for _, window in ipairs(Zilk._windows) do
            window:Toggle()
        end
    end
end))

return Zilk
