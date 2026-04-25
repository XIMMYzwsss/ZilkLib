local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/refs/heads/main/Lib.lua"))()

Library:SetConfigFolder("ZilkConfigs")
Library:SetMenuKeybind(Enum.KeyCode.RightShift)
Library:SetKeybindFrameVisible(true)

local Window = Library:CreateWindow({
    Name = "ZilkExample",
    Title = "Zilk UI Library Example",
})

local MainTab = Window:CreateTab("Main", true)
local MiscTab = Window:CreateTab("Misc")

local Left = MainTab:CreateGroupBox("left", "Core Controls")
local Right = MainTab:CreateGroupBox("right", "More Controls")

local enabled = Left:CreateToggle("Enable Feature", false, function(v)
    Library:Notify("Toggle Changed", "Enable Feature: " .. tostring(v), 2)
end, "EnableFeature")

Left:CreateButton("Run Action", function()
    Library:Notify("Button", "Action button clicked", 2)
end)

local power = Left:CreateSlider("Power", 0, 100, 35, 0, function(v)
    -- Slider callback
end, "PowerSlider")

local mode = Right:CreateDropdown("Mode", { "Legit", "Rage", "Hybrid" }, "Legit", function(v)
    -- Dropdown callback
end, "ModeDropdown")

local targets = Right:CreateMultiDropdown("Target Parts", { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }, {
    Head = true,
}, function(v)
    -- Multi dropdown callback
end, "TargetParts")

local note = Right:CreateInput("Profile Name", "MyConfig", function(v)
    -- Input callback
end, "ProfileName")

local trigger = Right:CreateKeybind("Trigger Key", Enum.KeyCode.Q, function(v)
    -- Fires on set and key press
end, "TriggerKey")

local accent = Right:CreateColorPicker("Accent Preview", Color3.fromRGB(155, 88, 255), function(v)
    Library:SetTheme({ AccentColor = v })
end, "AccentPreview")

local MiscLeft = MiscTab:CreateGroupBox("left", "Theme + Config")
MiscLeft:CreateButton("Purple Theme", function()
    Library:SetTheme({
        MainColor = Color3.fromRGB(20, 20, 24),
        SectionColor = Color3.fromRGB(28, 28, 34),
        AccentColor = Color3.fromRGB(155, 88, 255),
        TextColor = Color3.fromRGB(240, 240, 245),
        MutedTextColor = Color3.fromRGB(170, 170, 180),
    })
    Library:Notify("Theme", "Purple theme applied", 2)
end)

MiscLeft:CreateButton("Red Theme", function()
    Library:SetTheme({
        MainColor = Color3.fromRGB(23, 16, 16),
        SectionColor = Color3.fromRGB(32, 21, 21),
        AccentColor = Color3.fromRGB(255, 70, 70),
        TextColor = Color3.fromRGB(245, 230, 230),
        MutedTextColor = Color3.fromRGB(205, 170, 170),
    })
    Library:Notify("Theme", "Red theme applied", 2)
end)

MiscLeft:CreateDivider()

MiscLeft:CreateButton("Save Config", function()
    local cfgName = note.Value ~= "" and note.Value or "Default"
    local ok, err = Library:SaveConfig(cfgName)
    if ok then
        Library:Notify("Config", "Saved: " .. cfgName, 2)
    else
        Library:Notify("Config Error", tostring(err), 3)
    end
end)

MiscLeft:CreateButton("Load Config", function()
    local cfgName = note.Value ~= "" and note.Value or "Default"
    local ok, err = Library:LoadConfig(cfgName)
    if ok then
        Library:Notify("Config", "Loaded: " .. cfgName, 2)
    else
        Library:Notify("Config Error", tostring(err), 3)
    end
end)

MiscLeft:CreateButton("List Configs", function()
    local names = Library:ListConfigs()
    Library:Notify("Configs", (#names > 0 and table.concat(names, ", ")) or "No configs found", 4)
end)

local MiscRight = MiscTab:CreateGroupBox("right", "Runtime")
MiscRight:CreateLabel("Menu keybind: RightShift")
MiscRight:CreateButton("Print Current Values", function()
    print("EnableFeature:", enabled.Value)
    print("PowerSlider:", power.Value)
    print("ModeDropdown:", mode.Value)
    print("TargetParts:", targets.Value)
    print("TriggerKey:", trigger.Value)
    print("AccentPreview:", accent.Value)
end)

MiscRight:CreateButton("Unload UI", function()
    Library:Unload()
end)

Library:Notify("Zilk", "Example loaded. Press RightShift to toggle menu.", 4)
