-- ZilkLib | HeavN/Blade Style UI Library
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Zilk = { Toggles = {}, Options = {}, ConfigFolder = "ZilkConfigs", MenuBind = Enum.KeyCode.RightShift, _tabs = {} }

local T = {
    Main = Color3.fromRGB(10,10,10), Section = Color3.fromRGB(20,20,20),
    Accent = Color3.fromRGB(147,112,219), Text = Color3.fromRGB(240,240,240),
    Dim = Color3.fromRGB(150,150,150), ToggleOff = Color3.fromRGB(30,30,30),
    Button = Color3.fromRGB(40,40,40), Drop = Color3.fromRGB(30,30,30),
    Slider = Color3.fromRGB(147,112,219), Stroke = Color3.fromRGB(35,35,35),
    Box = Color3.fromRGB(18,18,18), Header = Color3.fromRGB(25,25,25),
}

local function N(cls, props, parent)
    local i = Instance.new(cls)
    for k,v in pairs(props or {}) do i[k]=v end
    if parent then i.Parent = parent end
    return i
end

local function corner(r, p) return N("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(c,t,p) return N("UIStroke",{Color=c,Thickness=t},p) end
local function pad(top,bot,l,r,p) return N("UIPadding",{PaddingTop=UDim.new(0,top),PaddingBottom=UDim.new(0,bot),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)},p) end

-- ============================================================
-- Config System
-- ============================================================
function Zilk:SetFolder(f)
    self.ConfigFolder = f
    local b=""
    for p in f:gmatch("[^/\\]+") do b=b..p.."/"; if not isfolder(b) then pcall(makefolder,b) end end
end

function Zilk:GetConfigs()
    if not isfolder(self.ConfigFolder) then pcall(makefolder,self.ConfigFolder) end
    local out={}
    if isfolder(self.ConfigFolder) then
        for _,f in pairs(listfiles(self.ConfigFolder)) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(out,name) end
        end
    end
    return out
end

function Zilk:SaveConfig(name)
    local d={Toggles={},Options={}}
    for i,v in pairs(self.Toggles) do d.Toggles[i]=v.Value end
    for i,v in pairs(self.Options) do
        if i~="ConfigList" and i~="ConfigName" then d.Options[i]=v.Value end
    end
    self:SetFolder(self.ConfigFolder)
    writefile(self.ConfigFolder.."/"..name..".json", HttpService:JSONEncode(d))
end

function Zilk:LoadConfig(name)
    local path=self.ConfigFolder.."/"..name..".json"
    if not isfile(path) then return false,"File not found" end
    local ok,d=pcall(HttpService.JSONDecode,HttpService,readfile(path))
    if not ok then return false,d end
    if d.Toggles then for i,v in pairs(d.Toggles) do if self.Toggles[i] then self.Toggles[i]:SetValue(v) end end end
    if d.Options then for i,v in pairs(d.Options) do if self.Options[i] then self.Options[i]:SetValue(v) end end end
    return true
end

function Zilk:DeleteConfig(name)
    local path=self.ConfigFolder.."/"..name..".json"
    if isfile(path) then pcall(delfile,path); return true end
    return false
end

-- ============================================================
-- Window
-- ============================================================
function Zilk:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Zilk"
    local ScreenGui

    ScreenGui = N("ScreenGui",{Name="ZilkUI",ResetOnSpawn=false,DisplayOrder=100,IgnoreGuiInset=true},
        RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui)
    Zilk.UI = ScreenGui

    local MF = N("Frame",{Name="Main",Size=UDim2.new(0,700,0,550),Position=UDim2.new(0.5,-350,0.5,-275),
        BackgroundColor3=T.Main,BorderSizePixel=0,Active=true},ScreenGui)
    corner(8,MF); stroke(T.Accent,2,MF).ApplyStrokeMode=Enum.ApplyStrokeMode.Border

    -- Title bar
    local TB = N("Frame",{Size=UDim2.new(1,0,0,35),BackgroundColor3=T.Section,BorderSizePixel=0,ZIndex=2},MF)
    corner(8,TB)
    N("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=T.Section,BorderSizePixel=0,ZIndex=3},TB)
    N("TextLabel",{Size=UDim2.new(1,-15,1,0),Position=UDim2.new(0,15,0,0),BackgroundTransparency=1,
        Text=title,TextColor3=T.Text,Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},TB)

    do -- Drag
        local dg,ds,fp=false
        TB.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=true;ds=UserInputService:GetMouseLocation();fp=MF.Position end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dg and i.UserInputType==Enum.UserInputType.MouseMovement then
                local d=UserInputService:GetMouseLocation()-ds
                MF.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end end)
    end

    -- Sidebar
    local SB = N("Frame",{Size=UDim2.new(0,110,1,-35),Position=UDim2.new(0,0,0,35),
        BackgroundColor3=T.Section,BorderSizePixel=0,ZIndex=2},MF)
    N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),
        HorizontalAlignment=Enum.HorizontalAlignment.Center},SB)
    pad(10,0,0,0,SB)
    -- separator
    N("Frame",{Size=UDim2.new(0,1,1,-35),Position=UDim2.new(0,110,0,35),
        BackgroundColor3=T.Stroke,BorderSizePixel=0,ZIndex=2},MF)

    -- Pages
    local Pages = N("Frame",{Size=UDim2.new(1,-120,1,-45),Position=UDim2.new(0,115,0,40),
        BackgroundTransparency=1,ZIndex=2},MF)

    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(i,gp)
        if not gp and i.KeyCode==Zilk.MenuBind then ScreenGui.Enabled=not ScreenGui.Enabled end
    end)

    local tabCount = 0
    local Window = {}

    local function selectTab(btn, frame)
        for _,t in pairs(Zilk._tabs) do
            t.f.Visible=false; t.b.BackgroundColor3=T.Section; t.b.TextColor3=T.Dim
        end
        frame.Visible=true; btn.BackgroundColor3=T.Button; btn.TextColor3=T.Accent
    end

    -- ============================================================
    -- Core element builders (HeavN-style)
    -- ============================================================
    local function mkGroupbox(parent, gbName)
        local box = N("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=T.Box,BorderSizePixel=0,ZIndex=5},parent)
        corner(4,box); stroke(T.Stroke,1,box)
        local hdr = N("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=T.Header,BorderSizePixel=0,ZIndex=6},box)
        corner(4,hdr)
        N("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),BackgroundColor3=T.Header,BorderSizePixel=0,ZIndex=7},hdr)
        N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.Accent,
            BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=8},hdr)
        N("TextLabel",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,
            Text=gbName:upper(),TextColor3=T.Accent,Font=Enum.Font.GothamBold,TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9},hdr)
        local cont = N("Frame",{Size=UDim2.new(1,-16,0,0),Position=UDim2.new(0,8,0,26),
            BackgroundTransparency=1,ZIndex=6},box)
        local lst = N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},cont)
        lst:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            cont.Size=UDim2.new(1,-16,0,lst.AbsoluteContentSize.Y)
            box.Size=UDim2.new(1,0,0,lst.AbsoluteContentSize.Y+34)
        end)
        return box, cont
    end

    local function mkToggle(cont, text, default, callback)
        local T2={Value=default or false}
        local row=N("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,ZIndex=7},cont)
        N("TextLabel",{Size=UDim2.new(1,-45,1,0),BackgroundTransparency=1,Text=text,
            TextColor3=T.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
        local track=N("Frame",{Size=UDim2.new(0,35,0,18),Position=UDim2.new(1,-35,0.5,-9),
            BackgroundColor3=default and T.Accent or T.ToggleOff,ZIndex=9},row)
        corner(100,track)
        local knob=N("Frame",{Size=UDim2.new(0,14,0,14),
            Position=default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
            BackgroundColor3=Color3.fromRGB(240,240,240),ZIndex=10},track)
        corner(100,knob)
        local cb=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=11},row)
        function T2:SetValue(v)
            T2.Value=v
            TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=v and T.Accent or T.ToggleOff}):Play()
            TweenService:Create(knob,TweenInfo.new(0.15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                {Position=v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
            if callback then callback(v) end
        end
        cb.MouseButton1Click:Connect(function() T2:SetValue(not T2.Value) end)
        return T2
    end

    local function mkSlider(cont, text, min, max, default, callback)
        local SL={Value=default or min}
        local row=N("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,ZIndex=7},cont)
        local lbl=N("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
            Text=text..": "..(default or min),TextColor3=T.Text,Font=Enum.Font.Gotham,TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
        local bg=N("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,0,26),
            BackgroundColor3=Color3.fromRGB(30,30,30),ZIndex=9},row)
        corner(100,bg)
        local pct=math.clamp((SL.Value-min)/(max-min),0,1)
        local fill=N("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=T.Slider,ZIndex=10},bg)
        corner(100,fill)
        local hit=N("TextButton",{Size=UDim2.new(1,0,5,0),Position=UDim2.new(0,0,-2,0),BackgroundTransparency=1,Text="",ZIndex=11},bg)
        function SL:SetValue(v)
            v=math.clamp(v,min,max); v=math.floor(v+0.5)
            SL.Value=v; fill.Size=UDim2.new((v-min)/(max-min),0,1,0)
            lbl.Text=text..": "..v; if callback then callback(v) end
        end
        local drag=false
        hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;SL:SetValue(min+(max-min)*math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
        UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then SL:SetValue(min+(max-min)*math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)) end end)
        return SL
    end

    local function mkDropdown(cont, text, values, default, callback)
        local DD={Value=default}
        local row=N("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=7},cont)
        N("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=text,
            TextColor3=T.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
        local mb=N("TextButton",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,21),
            BackgroundColor3=T.Drop,Text=tostring(default or "None"),TextColor3=T.Text,
            Font=Enum.Font.Gotham,TextSize=11,ZIndex=9},row)
        corner(4,mb); stroke(Color3.fromRGB(45,45,45),1,mb)
        local dl=N("Frame",{Name="DL_"..text,BackgroundColor3=Color3.fromRGB(20,20,20),
            Visible=false,ZIndex=10000,BorderSizePixel=0},ScreenGui)
        corner(4,dl); stroke(T.Accent,1,dl)
        N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},dl)
        local function rebuild()
            for _,c in pairs(dl:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,v in pairs(values or {}) do
                local it=N("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
                    Text=tostring(v),TextColor3=T.Text,Font=Enum.Font.Gotham,TextSize=11,ZIndex=10001},dl)
                it.MouseEnter:Connect(function() it.BackgroundTransparency=0.7;it.BackgroundColor3=T.Accent end)
                it.MouseLeave:Connect(function() it.BackgroundTransparency=1 end)
                it.MouseButton1Down:Connect(function() DD:SetValue(v);dl.Visible=false end)
            end
            dl.Size=UDim2.new(0,mb.AbsoluteSize.X,0,math.min(#(values or {})*24,120))
        end
        rebuild()
        function DD:SetValue(v) DD.Value=v; mb.Text=tostring(v); if callback then callback(v) end end
        function DD:SetValues(v) values=v; rebuild() end
        mb.MouseButton1Down:Connect(function()
            for _,c in pairs(ScreenGui:GetChildren()) do if c:IsA("Frame") and c.Name:sub(1,3)=="DL_" then c.Visible=false end end
            local p=mb.AbsolutePosition
            dl.Position=UDim2.new(0,p.X,0,p.Y+24); dl.Visible=true
        end)
        UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 and dl.Visible then
                local mp=UserInputService:GetMouseLocation(); local dp,ds2=dl.AbsolutePosition,dl.AbsoluteSize
                if mp.X<dp.X or mp.X>dp.X+ds2.X or mp.Y<dp.Y or mp.Y>dp.Y+ds2.Y then dl.Visible=false end
            end
        end)
        return DD
    end

    local function mkButton(cont, text, callback)
        local btn=N("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=T.Button,
            Text=text,TextColor3=T.Text,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=7},cont)
        corner(4,btn)
        btn.MouseButton1Click:Connect(function() if callback then callback() end end)
        return btn
    end

    local function mkInput(cont, text, default, callback)
        local IN={Value=default or ""}
        local row=N("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=7},cont)
        N("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=text,
            TextColor3=T.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
        local box=N("TextBox",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,21),
            BackgroundColor3=T.Drop,Text=IN.Value,TextColor3=T.Text,Font=Enum.Font.Gotham,
            TextSize=11,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9},row)
        corner(4,box); stroke(Color3.fromRGB(45,45,45),1,box); pad(0,0,6,0,box)
        box.FocusLost:Connect(function() IN.Value=box.Text; if callback then callback(IN.Value) end end)
        function IN:SetValue(v) IN.Value=v; box.Text=tostring(v); if callback then callback(v) end end
        return IN
    end

    -- ============================================================
    -- AddTab
    -- ============================================================
    function Window:AddTab(name, order)
        tabCount=tabCount+1
        local lo=order or tabCount

        local btn=N("TextButton",{Size=UDim2.new(0.88,0,0,28),BackgroundColor3=T.Section,
            Text=name,TextColor3=T.Dim,Font=Enum.Font.GothamBold,TextSize=12,
            BorderSizePixel=0,LayoutOrder=lo,ZIndex=10},SB)
        corner(4,btn)

        local page=N("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Visible=false,ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,
            CanvasSize=UDim2.new(0,0,0,0),BorderSizePixel=0,ZIndex=3},Pages)

        local LC=N("Frame",{Size=UDim2.new(0.48,0,0,0),Position=UDim2.new(0.01,0,0,8),BackgroundTransparency=1,ZIndex=4},page)
        local LL=N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},LC)
        local RC=N("Frame",{Size=UDim2.new(0.48,0,0,0),Position=UDim2.new(0.51,0,0,8),BackgroundTransparency=1,ZIndex=4},page)
        local RL=N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},RC)

        local function upCanvas()
            LC.Size=UDim2.new(0.48,0,0,LL.AbsoluteContentSize.Y)
            RC.Size=UDim2.new(0.48,0,0,RL.AbsoluteContentSize.Y)
            page.CanvasSize=UDim2.new(0,0,0,math.max(LL.AbsoluteContentSize.Y,RL.AbsoluteContentSize.Y)+20)
        end
        LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upCanvas)
        RL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upCanvas)

        table.insert(Zilk._tabs,{b=btn,f=page})
        btn.MouseButton1Click:Connect(function() selectTab(btn,page) end)
        if lo==1 then selectTab(btn,page) end

        local leftTurn=true
        local Tab={}

        function Tab:AddGroupbox(gbName)
            local col=leftTurn and LC or RC; leftTurn=not leftTurn
            local _,cont=mkGroupbox(col,gbName)
            local G={}
            function G:AddToggle(idx,o)
                local tg=mkToggle(cont,o.Text or idx,o.Default,o.Callback)
                function tg:OnChanged(cb) o.Callback=cb end
                Zilk.Toggles[idx]=tg; return tg
            end
            function G:AddSlider(idx,o)
                local sl=mkSlider(cont,o.Text or idx,o.Min,o.Max,o.Default,o.Callback)
                function sl:OnChanged(cb) o.Callback=cb end
                Zilk.Options[idx]=sl; return sl
            end
            function G:AddDropdown(idx,o)
                local dd=mkDropdown(cont,o.Text or idx,o.Values,o.Default,o.Callback)
                function dd:OnChanged(cb) o.Callback=cb end
                Zilk.Options[idx]=dd; return dd
            end
            function G:AddButton(text,cb) mkButton(cont,text,cb) end
            function G:AddInput(idx,o)
                local inp=mkInput(cont,o.Text or idx,o.Default,o.Callback)
                Zilk.Options[idx]=inp; return inp
            end
            return G
        end

        return Tab
    end

    -- ============================================================
    -- Settings Tab
    -- ============================================================
    local SettingsTab = Window:AddTab("Settings", 998)

    local SG1 = SettingsTab:AddGroupbox("UI Settings")
    SG1:AddToggle("ShowMenuKeybind", {Text="Toggle Key: RightShift", Default=true})

    local SG2 = SettingsTab:AddGroupbox("Actions")
    SG2:AddButton("Unload UI", function() Zilk.UI:Destroy() end)

    -- ============================================================
    -- Config Tab (HeavN style)
    -- ============================================================
    local ConfigTab = Window:AddTab("Configs", 999)
    local CG = ConfigTab:AddGroupbox("Config Manager")

    local function getConfigList() return Zilk:GetConfigs() end

    CG:AddInput("ConfigName", {Text="Config Name"})
    local cfgListDD = CG:AddDropdown("ConfigList", {Text="Select Config", Values=getConfigList(), Default=""})

    CG:AddButton("Save Config", function()
        local n = Zilk.Options.ConfigName.Value
        if not n or n=="" then return end
        Zilk:SaveConfig(n)
        cfgListDD:SetValues(getConfigList())
    end)
    CG:AddButton("Load Config", function()
        local n = Zilk.Options.ConfigList.Value
        if not n or n=="" then return end
        Zilk:LoadConfig(n)
    end)
    CG:AddButton("Delete Config", function()
        local n = Zilk.Options.ConfigList.Value
        if not n or n=="" then return end
        Zilk:DeleteConfig(n)
        cfgListDD:SetValues(getConfigList())
    end)
    CG:AddButton("Refresh List", function()
        cfgListDD:SetValues(getConfigList())
    end)

    return Window
end

return Zilk
