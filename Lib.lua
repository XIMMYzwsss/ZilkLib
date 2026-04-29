local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local S = {
    Main       = Color3.fromRGB(10,10,10),
    Section    = Color3.fromRGB(20,20,20),
    Accent     = Color3.fromRGB(147,112,219),
    Text       = Color3.fromRGB(240,240,240),
    ToggleOff  = Color3.fromRGB(30,30,30),
    ToggleOn   = Color3.fromRGB(255,255,255),
    Button     = Color3.fromRGB(40,40,40),
    Dropdown   = Color3.fromRGB(30,30,30),
    Slider     = Color3.fromRGB(147,112,219),
    Stroke     = Color3.fromRGB(35,35,35),
}

local Zilk = { Toggles={}, Options={}, ConfigFolder="ZilkConfigs", MenuBind=Enum.KeyCode.RightShift, UI=nil, _Tabs={} }

local function New(cls, p, c)
    local i = Instance.new(cls)
    for k,v in pairs(p or {}) do i[k]=v end
    if c then i.Parent=c end
    return i
end

function Zilk:SetFolder(f)
    self.ConfigFolder = f
    local b = ""
    for p in f:gmatch("[^/\\]+") do b=b..p.."/"; if not isfolder(b) then makefolder(b) end end
    if self.Options and self.Options.ConfigList then self.Options.ConfigList:SetValues(self:GetConfigs()) end
end

function Zilk:SaveConfig(n)
    local d={Toggles={},Options={}}
    for i,v in pairs(self.Toggles) do d.Toggles[i]=v.Value end
    for i,v in pairs(self.Options) do if i~="ConfigList" and i~="ConfigName" then d.Options[i]=v.Value end end
    self:SetFolder(self.ConfigFolder)
    writefile(self.ConfigFolder.."/"..n..".json", HttpService:JSONEncode(d))
end

function Zilk:LoadConfig(n)
    local p=self.ConfigFolder.."/"..n..".json"
    if not isfile(p) then return end
    local ok,d=pcall(HttpService.JSONDecode,HttpService,readfile(p))
    if not ok then return end
    if d.Toggles then for i,v in pairs(d.Toggles) do if self.Toggles[i] then self.Toggles[i]:SetValue(v) end end end
    if d.Options then for i,v in pairs(d.Options) do if self.Options[i] then self.Options[i]:SetValue(v) end end end
end

function Zilk:GetConfigs()
    if not isfolder(self.ConfigFolder) then self:SetFolder(self.ConfigFolder) end
    local out={}
    if isfolder(self.ConfigFolder) then
        for _,f in pairs(listfiles(self.ConfigFolder)) do
            if f:match("%.json$") then table.insert(out, f:match("([^/\\]+)%.json$")) end
        end
    end
    return out
end

function Zilk:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Zilk"
    local ScreenGui, MainFrame

    ScreenGui = New("ScreenGui",{Name="ZilkUI",ResetOnSpawn=false,DisplayOrder=100,IgnoreGuiInset=true},
        RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui)
    Zilk.UI = ScreenGui

    MainFrame = New("Frame",{Name="Main",Size=UDim2.new(0,700,0,550),Position=UDim2.new(0.5,-350,0.5,-275),
        BackgroundColor3=S.Main,BorderSizePixel=0,Active=true},ScreenGui)
    New("UICorner",{CornerRadius=UDim.new(0,8)},MainFrame)
    New("UIStroke",{Color=S.Accent,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},MainFrame)

    -- Titlebar drag
    local TitleBar = New("Frame",{Size=UDim2.new(1,0,0,35),BackgroundColor3=S.Section,BorderSizePixel=0,ZIndex=2},MainFrame)
    New("UICorner",{CornerRadius=UDim.new(0,8)},TitleBar)
    New("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=S.Section,BorderSizePixel=0,ZIndex=3},TitleBar)
    New("TextLabel",{Size=UDim2.new(1,-15,1,0),Position=UDim2.new(0,15,0,0),BackgroundTransparency=1,
        Text=title,TextColor3=S.Text,Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},TitleBar)

    do
        local dg,ds,fp=false,Vector2.new(),UDim2.new()
        TitleBar.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=true;ds=UserInputService:GetMouseLocation();fp=MainFrame.Position end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dg and i.UserInputType==Enum.UserInputType.MouseMovement then
                local d=UserInputService:GetMouseLocation()-ds
                MainFrame.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end end)
    end

    -- Sidebar
    local Sidebar = New("Frame",{Size=UDim2.new(0,110,1,-35),Position=UDim2.new(0,0,0,35),
        BackgroundColor3=S.Section,BorderSizePixel=0,ZIndex=2},MainFrame)
    New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),
        HorizontalAlignment=Enum.HorizontalAlignment.Center},Sidebar)
    New("UIPadding",{PaddingTop=UDim.new(0,10)},Sidebar)

    -- Separator line
    New("Frame",{Size=UDim2.new(0,1,1,-35),Position=UDim2.new(0,110,0,35),
        BackgroundColor3=S.Stroke,BorderSizePixel=0,ZIndex=2},MainFrame)

    -- Pages container
    local Pages = New("Frame",{Size=UDim2.new(1,-120,1,-45),Position=UDim2.new(0,115,0,40),
        BackgroundTransparency=1,ZIndex=2},MainFrame)

    local TabCount, Window = 0, {}

    local function selectTab(btn, frame)
        for _, t in pairs(Zilk._Tabs) do
            t.frame.Visible = false
            t.btn.BackgroundColor3 = S.Section
            t.btn.TextColor3 = S.Text
        end
        frame.Visible = true
        btn.BackgroundColor3 = S.Button
        btn.TextColor3 = S.Accent
    end

    function Window:AddTab(name, order)
        TabCount = TabCount + 1
        local lo = order or TabCount

        local btn = New("TextButton",{Size=UDim2.new(0.88,0,0,28),BackgroundColor3=S.Section,
            Text=name,TextColor3=S.Text,Font=Enum.Font.GothamBold,TextSize=12,
            BorderSizePixel=0,LayoutOrder=lo,ZIndex=10},Sidebar)
        New("UICorner",{CornerRadius=UDim.new(0,4)},btn)

        local page = New("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Visible=false,ScrollBarThickness=2,ScrollBarImageColor3=S.Accent,
            CanvasSize=UDim2.new(0,0,0,0),BorderSizePixel=0,ZIndex=3},Pages)

        -- Left column
        local LC = New("Frame",{Size=UDim2.new(0.48,0,0,0),Position=UDim2.new(0.01,0,0,8),
            BackgroundTransparency=1,ZIndex=4},page)
        local LL = New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},LC)

        -- Right column
        local RC = New("Frame",{Size=UDim2.new(0.48,0,0,0),Position=UDim2.new(0.51,0,0,8),
            BackgroundTransparency=1,ZIndex=4},page)
        local RL = New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},RC)

        local function UpdateCanvas()
            local h = math.max(LL.AbsoluteContentSize.Y, RL.AbsoluteContentSize.Y)
            LC.Size = UDim2.new(0.48,0,0,LL.AbsoluteContentSize.Y)
            RC.Size = UDim2.new(0.48,0,0,RL.AbsoluteContentSize.Y)
            page.CanvasSize = UDim2.new(0,0,0,h+20)
        end
        LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        RL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        table.insert(Zilk._Tabs,{btn=btn,frame=page})
        btn.MouseButton1Click:Connect(function() selectTab(btn,page) end)

        if TabCount == 1 and not order then selectTab(btn,page) end

        local leftTurn = true
        local Tab = {}

        function Tab:AddGroupbox(gbName)
            local col = leftTurn and LC or RC
            leftTurn = not leftTurn

            local box = New("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(18,18,18),
                BorderSizePixel=0,ZIndex=5},col)
            New("UICorner",{CornerRadius=UDim.new(0,4)},box)
            New("UIStroke",{Color=S.Stroke,Thickness=1},box)

            local header = New("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=Color3.fromRGB(25,25,25),
                BorderSizePixel=0,ZIndex=6},box)
            New("UICorner",{CornerRadius=UDim.new(0,4)},header)
            -- flatten bottom corners of header
            New("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),
                BackgroundColor3=Color3.fromRGB(25,25,25),BorderSizePixel=0,ZIndex=7},header)
            -- accent line under header
            New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
                BackgroundColor3=S.Accent,BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=8},header)
            New("TextLabel",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,
                Text=gbName:upper(),TextColor3=S.Accent,Font=Enum.Font.GothamBold,TextSize=10,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9},header)

            local cont = New("Frame",{Size=UDim2.new(1,-16,0,0),Position=UDim2.new(0,8,0,27),
                BackgroundTransparency=1,ZIndex=6},box)
            local list = New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},cont)

            list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                cont.Size = UDim2.new(1,-16,0,list.AbsoluteContentSize.Y)
                box.Size  = UDim2.new(1,0,0,list.AbsoluteContentSize.Y+35)
            end)

            local G = {}

            function G:AddToggle(idx, o)
                local T = {Value=o.Default or false, Type="Toggle"}
                local row = New("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,ZIndex=7},cont)
                New("TextLabel",{Size=UDim2.new(1,-45,1,0),BackgroundTransparency=1,Text=o.Text or idx,
                    TextColor3=S.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
                local track = New("Frame",{Size=UDim2.new(0,35,0,18),Position=UDim2.new(1,-35,0.5,-9),
                    BackgroundColor3=T.Value and S.Accent or S.ToggleOff,ZIndex=9},row)
                New("UICorner",{CornerRadius=UDim.new(1,0)},track)
                local knob = New("Frame",{Size=UDim2.new(0,14,0,14),
                    Position=T.Value and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
                    BackgroundColor3=Color3.fromRGB(240,240,240),ZIndex=10},track)
                New("UICorner",{CornerRadius=UDim.new(1,0)},knob)
                local clickBtn = New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=11},row)

                function T:SetValue(v)
                    T.Value=v
                    TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=v and S.Accent or S.ToggleOff}):Play()
                    TweenService:Create(knob,TweenInfo.new(0.15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                        {Position=v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
                    if o.Callback then o.Callback(v) end
                end

                clickBtn.MouseButton1Click:Connect(function() T:SetValue(not T.Value) end)
                Zilk.Toggles[idx]=T
                return T
            end

            function G:AddSlider(idx, o)
                local SL = {Value=o.Default or o.Min, Type="Slider"}
                local row = New("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,ZIndex=7},cont)
                local lbl = New("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
                    Text=(o.Text or idx)..": "..(o.Default or o.Min),TextColor3=S.Text,Font=Enum.Font.Gotham,
                    TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
                local bg = New("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,0,24),
                    BackgroundColor3=Color3.fromRGB(30,30,30),ZIndex=9},row)
                New("UICorner",{CornerRadius=UDim.new(1,0)},bg)
                local pct=(SL.Value-o.Min)/(o.Max-o.Min)
                local fill=New("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=S.Slider,ZIndex=10},bg)
                New("UICorner",{CornerRadius=UDim.new(1,0)},fill)
                local clickBtn=New("TextButton",{Size=UDim2.new(1,0,3,0),Position=UDim2.new(0,0,-1,0),BackgroundTransparency=1,Text="",ZIndex=11},bg)

                function SL:SetValue(v)
                    v=math.clamp(v,o.Min,o.Max)
                    if o.Rounding then v=math.floor(v+0.5) else v=math.floor(v*10)/10 end
                    SL.Value=v
                    fill.Size=UDim2.new((v-o.Min)/(o.Max-o.Min),0,1,0)
                    lbl.Text=(o.Text or idx)..": "..v
                    if o.Callback then o.Callback(v) end
                end

                local drag=false
                clickBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;SL:SetValue(o.Min+math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)*(o.Max-o.Min)) end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
                UserInputService.InputChanged:Connect(function(i)
                    if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                        SL:SetValue(o.Min+math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)*(o.Max-o.Min))
                    end
                end)
                Zilk.Options[idx]=SL; return SL
            end

            function G:AddDropdown(idx, o)
                local DD={Value=o.Default, Type="Dropdown"}
                local row=New("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=7},cont)
                New("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=o.Text or idx,
                    TextColor3=S.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
                local mainBtn=New("TextButton",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,21),
                    BackgroundColor3=S.Dropdown,Text=tostring(o.Default or "None"),TextColor3=S.Text,
                    Font=Enum.Font.Gotham,TextSize=11,ZIndex=9},row)
                New("UICorner",{CornerRadius=UDim.new(0,4)},mainBtn)
                New("UIStroke",{Color=Color3.fromRGB(45,45,45),Thickness=1},mainBtn)

                local dropList=New("Frame",{Name="Drop_"..idx,BackgroundColor3=Color3.fromRGB(20,20,20),
                    Visible=false,ZIndex=10000,BorderSizePixel=0},ScreenGui)
                New("UICorner",{CornerRadius=UDim.new(0,4)},dropList)
                New("UIStroke",{Color=S.Accent,Thickness=1},dropList)
                local dropLayout=New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},dropList)

                local function Rebuild()
                    for _,c in pairs(dropList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                    for _,v in pairs(o.Values or {}) do
                        local it=New("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
                            Text=tostring(v),TextColor3=S.Text,Font=Enum.Font.Gotham,TextSize=11,ZIndex=10001},dropList)
                        it.MouseEnter:Connect(function() it.BackgroundTransparency=0.7;it.BackgroundColor3=S.Accent end)
                        it.MouseLeave:Connect(function() it.BackgroundTransparency=1 end)
                        it.MouseButton1Down:Connect(function() DD:SetValue(v);dropList.Visible=false end)
                    end
                    local cnt=#(o.Values or {})
                    dropList.Size=UDim2.new(0,mainBtn.AbsoluteSize.X,0,math.min(cnt*24,120))
                end
                Rebuild()

                function DD:SetValue(v) DD.Value=v; mainBtn.Text=tostring(v); if o.Callback then o.Callback(v) end end
                function DD:SetValues(vals) o.Values=vals; Rebuild() end

                mainBtn.MouseButton1Down:Connect(function()
                    for _,c in pairs(ScreenGui:GetChildren()) do if c:IsA("Frame") and c.Name:sub(1,5)=="Drop_" then c.Visible=false end end
                    local pos=mainBtn.AbsolutePosition
                    dropList.Position=UDim2.new(0,pos.X,0,pos.Y+24)
                    dropList.Visible=true
                end)
                UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 and dropList.Visible then
                        local mp=UserInputService:GetMouseLocation(); local p,sz=dropList.AbsolutePosition,dropList.AbsoluteSize
                        if mp.X<p.X or mp.X>p.X+sz.X or mp.Y<p.Y or mp.Y>p.Y+sz.Y then dropList.Visible=false end
                    end
                end)
                Zilk.Options[idx]=DD; return DD
            end

            function G:AddButton(text, cb)
                local btn=New("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=S.Button,
                    Text=text,TextColor3=S.Text,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=7},cont)
                New("UICorner",{CornerRadius=UDim.new(0,4)},btn)
                btn.MouseButton1Click:Connect(function() if cb then cb() end end)
            end

            function G:AddInput(idx, o)
                local IN={Value=o.Default or "", Type="Input"}
                local row=New("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=7},cont)
                New("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=o.Text or idx,
                    TextColor3=S.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8},row)
                local box=New("TextBox",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,21),
                    BackgroundColor3=S.Dropdown,Text=IN.Value,TextColor3=S.Text,Font=Enum.Font.Gotham,
                    TextSize=11,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9},row)
                New("UICorner",{CornerRadius=UDim.new(0,4)},box)
                New("UIStroke",{Color=Color3.fromRGB(45,45,45),Thickness=1},box)
                New("UIPadding",{PaddingLeft=UDim.new(0,6)},box)
                box.FocusLost:Connect(function() IN.Value=box.Text; if o.Callback then o.Callback(IN.Value) end end)
                function IN:SetValue(v) IN.Value=v; box.Text=tostring(v); if o.Callback then o.Callback(v) end end
                Zilk.Options[idx]=IN; return IN
            end

            return G
        end

        return Tab
    end

    UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==Zilk.MenuBind then ScreenGui.Enabled=not ScreenGui.Enabled end
    end)

    -- Auto Settings + Configs tabs
    local ST=Window:AddTab("Settings",998)
    local CT=Window:AddTab("Configs",999)

    local SG=ST:AddGroupbox("Menu")
    SG:AddButton("Unload",function() Zilk.UI:Destroy() end)

    local CG=CT:AddGroupbox("Config Manager")
    CG:AddInput("ConfigName",{Text="Config Name"})
    CG:AddDropdown("ConfigList",{Text="Configs",Values=Zilk:GetConfigs()})
    CG:AddButton("Save Config",function()
        local n=Zilk.Options.ConfigName.Value
        if n and n~="" then Zilk:SaveConfig(n); Zilk.Options.ConfigList:SetValues(Zilk:GetConfigs()) end
    end)
    CG:AddButton("Load Config",function()
        local n=Zilk.Options.ConfigList.Value
        if n then Zilk:LoadConfig(n) end
    end)
    CG:AddButton("Refresh",function() Zilk.Options.ConfigList:SetValues(Zilk:GetConfigs()) end)

    return Window
end

return Zilk
