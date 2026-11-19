--[[
    BAXTARA X CHEAT  v5.5
    Cyber Premium UI + full features
    Fix: sky branding, hitbox head (no freeze), freeze players, key save
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local TeleportService  = game:GetService("TeleportService")
local StarterGui       = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local DrawingLib = Drawing

getgenv().BAXTARA = getgenv().BAXTARA or {}
local B = getgenv().BAXTARA

-- Persist unlock across re-execute in same session
local ACCESS_KEY = "BAXTARA X CHEAT"
local WA_URL = "https://whatsapp.com/channel/0029Vb8PluMLtOj5TTbxRl1k"
local KEY_FILE = "baxtara_key_save.txt"

local function SaveKeyUnlock()
    getgenv().BAXTARA_UNLOCKED = true
    pcall(function()
        if writefile then writefile(KEY_FILE, ACCESS_KEY) end
    end)
end

local function LoadKeyUnlock()
    if getgenv().BAXTARA_UNLOCKED == true then return true end
    local ok, data = pcall(function()
        if isfile and isfile(KEY_FILE) and readfile then
            return readfile(KEY_FILE)
        end
        return nil
    end)
    if ok and data and tostring(data):upper():find("BAXTARA") then
        getgenv().BAXTARA_UNLOCKED = true
        return true
    end
    return false
end

B.Settings = B.Settings or {
    Aim = {
        Enabled=false, VisibilityCheck=true, HeadAim=true, BodyAim=false, MultiBone=false,
        FOVCircle=true, AimDistance=800, AimLock=false, AimSmoothing=0.15, AimPrediction=false,
        PredictionAmount=0.12, DrawTargetLine=true, FOV=180, TeamCheck=true,
        SilentAim=false, AntiMiss=false, HitPart="Head",
    },
    ESP = {
        Enabled=false, Box=true, Name=true, HealthBar=true, Distance=true, Tracer=true,
        Skeleton=false, VisibleCheck=true, PriorityMark=true, Offscreen=true, MaxDistance=1000,
        ColorName="Cyan",
        VisibleColor=Color3.fromRGB(0,230,200), HiddenColor=Color3.fromRGB(255,85,105),
        PriorityColor=Color3.fromRGB(255,200,50), TracerColor=Color3.fromRGB(0,230,200),
        FOVColor=Color3.fromRGB(0,230,200), BoxColor=Color3.fromRGB(0,230,200),
    },
    Brutal = {
        Fly=false, FlySpeed=45, SpeedHack=false, SpeedValue=24, InfiniteJump=false, Noclip=false,
        SuperJump=false, SuperJumpPower=80, GhostMode=false, GodMode=false,
        HitboxExpand=false, HitboxSize=8, HitboxPart="Body", HitboxRedAim=true,
        AntiCooldown=false, InfiniteAmmo=false, AutoShoot=false, AttackSpeed=false, AttackSpeedVal=8,
        AutoKill=false,
    },
    LocalCfg = {
        SkyBAXTARA=false, FreezeOthers=false, AntiLagSelf=true, ServerLag=false,
    },
    Visual = { FullBright=false, AntiLag=false },
    Protect = { AntiKick=true, AutoHopOnFlag=true, SoftCamera=true },
    UI = { Theme="Modern" },
}

B.Connections, B.Drawings, B.ESPObjects = {}, {}, {}
B.CurrentTarget, B.LockedTarget = nil, nil
B.OriginalWalkSpeed, B.OriginalJumpPower, B.OriginalJumpHeight = 16, 50, 7.2
B.Unlocked = false
B.FlyBV, B.FlyBG, B.NoclipConn, B.JumpConn = nil, nil, nil, nil
B.LastShoot, B.SessionStart = 0, tick()
B.SkyFolder, B.HitboxParts, B.FrozenParts = nil, {}, {}

local function AddConn(c) table.insert(B.Connections, c) return c end

local function CleanupAll()
    for _, c in ipairs(B.Connections) do pcall(function() c:Disconnect() end) end
    B.Connections = {}
    for _, d in pairs(B.Drawings) do pcall(function() if d.Remove then d:Remove() end end) end
    B.Drawings = {}
    for _, pack in pairs(B.ESPObjects) do
        for k, d in pairs(pack) do
            if k == "Skel" then for _, l in ipairs(d) do pcall(function() if l.Remove then l:Remove() end end) end
            else pcall(function() if d and d.Remove then d:Remove() end end) end
        end
    end
    B.ESPObjects = {}
    if B.FlyBV then pcall(function() B.FlyBV:Destroy() end) B.FlyBV=nil end
    if B.FlyBG then pcall(function() B.FlyBG:Destroy() end) B.FlyBG=nil end
    if B.SkyFolder then pcall(function() B.SkyFolder:Destroy() end) B.SkyFolder=nil end
    for _, p in pairs(B.HitboxParts) do pcall(function() p:Destroy() end) end
    B.HitboxParts = {}
    for _, p in pairs(B.FrozenParts) do pcall(function() if p.Parent then p.Anchored=false end end) end
    B.FrozenParts = {}
end

local function IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end
local function GetChar(p) return p and p.Character end
local function GetRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
end
local function GetHead(char) return char and char:FindFirstChild("Head") end
local function TeamOK(p)
    if not B.Settings.Aim.TeamCheck then return true end
    if not LocalPlayer.Team then return true end
    return p.Team ~= LocalPlayer.Team
end
local function WorldToScreen(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on, v.Z
end
local function DistTo(pos)
    local r = GetRoot(LocalPlayer.Character)
    if not r then return 99999 end
    return (r.Position - pos).Magnitude
end
local function ScreenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X*0.5, vp.Y*0.5)
end
local function IsVisible(from, to, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    params.IgnoreWater = true
    return Workspace:Raycast(from, to-from, params) == nil
end

-- Themes
local Themes = {
    Modern = {
        Background=Color3.fromRGB(9,12,19), Sidebar=Color3.fromRGB(14,19,29), Card=Color3.fromRGB(19,26,39),
        Element=Color3.fromRGB(27,37,53), Accent=Color3.fromRGB(0,230,200), Accent2=Color3.fromRGB(40,145,255),
        White=Color3.fromRGB(240,245,250), Muted=Color3.fromRGB(130,145,165), Off=Color3.fromRGB(55,65,80),
        Red=Color3.fromRGB(255,85,105),
    },
    Hacker = {
        Background=Color3.fromRGB(5,10,5), Sidebar=Color3.fromRGB(8,18,8), Card=Color3.fromRGB(12,24,12),
        Element=Color3.fromRGB(20,40,20), Accent=Color3.fromRGB(0,255,70), Accent2=Color3.fromRGB(0,180,50),
        White=Color3.fromRGB(200,255,200), Muted=Color3.fromRGB(80,140,80), Off=Color3.fromRGB(30,50,30),
        Red=Color3.fromRGB(255,60,60),
    },
    Cartoon = {
        Background=Color3.fromRGB(25,15,40), Sidebar=Color3.fromRGB(40,25,60), Card=Color3.fromRGB(55,35,80),
        Element=Color3.fromRGB(70,45,100), Accent=Color3.fromRGB(255,120,200), Accent2=Color3.fromRGB(120,180,255),
        White=Color3.fromRGB(255,240,255), Muted=Color3.fromRGB(180,150,200), Off=Color3.fromRGB(60,40,80),
        Red=Color3.fromRGB(255,100,140),
    },
    Default = {
        Background=Color3.fromRGB(18,18,22), Sidebar=Color3.fromRGB(28,28,34), Card=Color3.fromRGB(36,36,44),
        Element=Color3.fromRGB(48,48,58), Accent=Color3.fromRGB(160,50,255), Accent2=Color3.fromRGB(100,80,200),
        White=Color3.fromRGB(235,230,245), Muted=Color3.fromRGB(140,135,160), Off=Color3.fromRGB(50,50,60),
        Red=Color3.fromRGB(255,90,110),
    },
}
local T = Themes.Modern

local ColorPresets = {
    Cyan   = {vis=Color3.fromRGB(0,230,200), hid=Color3.fromRGB(255,85,105), pri=Color3.fromRGB(255,200,50), tr=Color3.fromRGB(0,230,200), fov=Color3.fromRGB(0,230,200), box=Color3.fromRGB(0,230,200)},
    Purple = {vis=Color3.fromRGB(180,80,255), hid=Color3.fromRGB(255,80,120), pri=Color3.fromRGB(255,200,50), tr=Color3.fromRGB(200,100,255), fov=Color3.fromRGB(170,70,255), box=Color3.fromRGB(180,80,255)},
    Green  = {vis=Color3.fromRGB(0,255,140), hid=Color3.fromRGB(255,70,70), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(0,255,180), fov=Color3.fromRGB(0,255,160), box=Color3.fromRGB(0,255,140)},
    Red    = {vis=Color3.fromRGB(255,60,60), hid=Color3.fromRGB(180,40,40), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(255,100,100), fov=Color3.fromRGB(255,80,80), box=Color3.fromRGB(255,60,60)},
}
local function ApplyColor(name)
    local p = ColorPresets[name] or ColorPresets.Cyan
    B.Settings.ESP.ColorName = name
    B.Settings.ESP.VisibleColor=p.vis; B.Settings.ESP.HiddenColor=p.hid
    B.Settings.ESP.PriorityColor=p.pri; B.Settings.ESP.TracerColor=p.tr
    B.Settings.ESP.FOVColor=p.fov; B.Settings.ESP.BoxColor=p.box
    if B.Drawings.FOV then B.Drawings.FOV.Color = p.fov end
end

-- ===================== GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BAXTARA_X_CHEAT"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = CoreGui

local function New(class, props, parent)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent = parent
    return o
end
local function Round(o, r) New("UICorner", {CornerRadius=UDim.new(0,r or 10)}, o) end
local function Stroke(o, col, tr)
    return New("UIStroke", {Color=col or T.Accent, Thickness=1, Transparency=tr or 0.4}, o)
end

-- KEY
local KeyFrame = New("Frame", {Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(6,8,14), BorderSizePixel=0, ZIndex=100}, ScreenGui)
local KeyCard = New("Frame", {Size=UDim2.fromOffset(320,320), Position=UDim2.new(0.5,-160,0.5,-160), BackgroundColor3=T.Card, BorderSizePixel=0, ZIndex=110}, KeyFrame)
Round(KeyCard, 14); Stroke(KeyCard, T.Accent, 0.3)
New("TextLabel", {Size=UDim2.new(1,-20,0,28), Position=UDim2.fromOffset(10,16), BackgroundTransparency=1, Text="BAXTARA X CHEAT", TextColor3=T.Accent, Font=Enum.Font.GothamBlack, TextSize=18, ZIndex=111}, KeyCard)
New("TextLabel", {Size=UDim2.new(1,-20,0,14), Position=UDim2.fromOffset(10,44), BackgroundTransparency=1, Text="SECURE ACCESS TERMINAL", TextColor3=T.Muted, Font=Enum.Font.Code, TextSize=10, ZIndex=111}, KeyCard)
local InputH = New("Frame", {Size=UDim2.new(1,-40,0,36), Position=UDim2.fromOffset(20,80), BackgroundColor3=T.Element, BorderSizePixel=0, ZIndex=111}, KeyCard)
Round(InputH, 8)
local KeyBox = New("TextBox", {Size=UDim2.new(1,-12,1,0), Position=UDim2.fromOffset(6,0), BackgroundTransparency=1, PlaceholderText="ENTER ACCESS KEY", PlaceholderColor3=T.Muted, Text="", TextColor3=T.White, Font=Enum.Font.Code, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=112}, InputH)
local StatusLbl = New("TextLabel", {Size=UDim2.new(1,-40,0,16), Position=UDim2.fromOffset(20,122), BackgroundTransparency=1, Text="", TextColor3=T.Red, Font=Enum.Font.Code, TextSize=11, ZIndex=111}, KeyCard)
local function KBtn(text, y, col, cb)
    local b = New("TextButton", {Size=UDim2.new(1,-40,0,34), Position=UDim2.fromOffset(20,y), BackgroundColor3=col, Text=text, TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=12, ZIndex=111, AutoButtonColor=false}, KeyCard)
    Round(b, 8)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end
local VerifyBtn = KBtn("VERIFY KEY", 150, Color3.fromRGB(0,140,120))
KBtn("JOIN WHATSAPP", 192, Color3.fromRGB(20,90,50), function()
    pcall(function() if setclipboard then setclipboard(WA_URL) end end)
end)
KBtn("COPY KEY INFO", 234, T.Element, function()
    pcall(function() if setclipboard then setclipboard("Key: BAXTARA X CHEAT") end end)
    StatusLbl.TextColor3 = T.Accent; StatusLbl.Text = "Copied"
end)
New("TextLabel", {Size=UDim2.new(1,-20,0,14), Position=UDim2.fromOffset(10,280), BackgroundTransparency=1, Text="Key: BAXTARA X CHEAT", TextColor3=T.Muted, Font=Enum.Font.Code, TextSize=10, ZIndex=111}, KeyCard)

-- LOADING
local LoadFrame = New("Frame", {Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(5,8,12), BorderSizePixel=0, Visible=false, ZIndex=90}, ScreenGui)
for i=1,12 do
    local t = New("TextLabel", {Size=UDim2.fromOffset(120,14), Position=UDim2.new(math.random(),0,math.random(),0), BackgroundTransparency=1, Text=({"BAXTARA","X CHEAT","EXECUTE","DOMINATE"})[math.random(1,4)], TextColor3=T.Accent, TextTransparency=0.45, Font=Enum.Font.GothamBlack, TextSize=11, ZIndex=91}, LoadFrame)
    task.spawn(function()
        while t.Parent do
            TweenService:Create(t, TweenInfo.new(4, Enum.EasingStyle.Sine), {Position=UDim2.new(math.random(),0,math.random(),0)}):Play()
            task.wait(4)
        end
    end)
end
New("TextLabel", {Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0.42,0), BackgroundTransparency=1, Text="BAXTARA X CHEAT", TextColor3=T.Accent, Font=Enum.Font.GothamBlack, TextSize=22, ZIndex=95}, LoadFrame)
local LoadBarBG = New("Frame", {Size=UDim2.fromOffset(200,4), Position=UDim2.new(0.5,-100,0.52,0), BackgroundColor3=T.Off, BorderSizePixel=0, ZIndex=95}, LoadFrame)
Round(LoadBarBG, 4)
local LoadBar = New("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=96}, LoadBarBG)
Round(LoadBar, 4)
local LoadPct = New("TextLabel", {Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0.55,0), BackgroundTransparency=1, Text="0%", TextColor3=T.Muted, Font=Enum.Font.Code, TextSize=11, ZIndex=95}, LoadFrame)

-- MAIN PANEL (Cyber style)
local Main = New("Frame", {Name="Main", Size=UDim2.fromOffset(560,380), Position=UDim2.new(0.5,-280,0.5,-190), BackgroundColor3=T.Background, BorderSizePixel=0, Visible=false, ClipsDescendants=true, ZIndex=10}, ScreenGui)
Round(Main, 16)
local MainBorder = Stroke(Main, T.Accent, 0.35)
local MainScale = New("UIScale", {Scale=1}, Main)

local Header = New("Frame", {Size=UDim2.new(1,0,0,52), BackgroundColor3=T.Sidebar, BorderSizePixel=0, ZIndex=12}, Main)
Round(Header, 16)
New("Frame", {Position=UDim2.new(0,0,1,-12), Size=UDim2.new(1,0,0,12), BackgroundColor3=T.Sidebar, BorderSizePixel=0, ZIndex=12}, Header)

local LogoBox = New("Frame", {Position=UDim2.fromOffset(12,8), Size=UDim2.fromOffset(34,34), BackgroundColor3=T.Accent, ZIndex=13}, Header)
Round(LogoBox, 10)
New("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="B", TextColor3=T.Background, Font=Enum.Font.GothamBlack, TextSize=20, ZIndex=14}, LogoBox)

New("TextLabel", {Position=UDim2.fromOffset(54,8), Size=UDim2.fromOffset(220,20), BackgroundTransparency=1, Text="BAXTARA X CHEAT", TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, Header)
New("TextLabel", {Position=UDim2.fromOffset(54,28), Size=UDim2.fromOffset(200,14), BackgroundTransparency=1, Text="CYBER PREMIUM v5.5", TextColor3=T.Muted, Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, Header)

local function HBtn(text, x, col)
    local b = New("TextButton", {Position=UDim2.new(1,x,0,12), Size=UDim2.fromOffset(28,28), BackgroundColor3=T.Element, Text=text, TextColor3=col, Font=Enum.Font.GothamBold, TextSize=16, AutoButtonColor=false, ZIndex=13}, Header)
    Round(b, 8)
    return b
end
local MinBtn = HBtn("−", -72, T.Accent)
local CloseBtn = HBtn("×", -36, T.Red)

-- Sidebar
local Sidebar = New("Frame", {Position=UDim2.fromOffset(10,60), Size=UDim2.new(0,120,1,-70), BackgroundColor3=T.Sidebar, BorderSizePixel=0, ZIndex=11}, Main)
Round(Sidebar, 12)
New("TextLabel", {Position=UDim2.fromOffset(10,8), Size=UDim2.new(1,-16,0,14), BackgroundTransparency=1, Text="MAIN MENU", TextColor3=T.Muted, Font=Enum.Font.GothamBold, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12}, Sidebar)

local TabHolder = New("Frame", {Position=UDim2.fromOffset(6,28), Size=UDim2.new(1,-12,0,260), BackgroundTransparency=1, ZIndex=12}, Sidebar)
New("UIListLayout", {Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, TabHolder)
New("TextLabel", {Position=UDim2.new(0,10,1,-28), Size=UDim2.new(1,-16,0,16), BackgroundTransparency=1, Text="BAXTARA v5.5", TextColor3=T.Accent, Font=Enum.Font.GothamBold, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12}, Sidebar)

local Content = New("ScrollingFrame", {
    Position=UDim2.fromOffset(140,60), Size=UDim2.new(1,-150,1,-70),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3,
    ScrollBarImageColor3=T.Accent, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=11
}, Main)
local ContentLayout = New("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, Content)
New("UIPadding", {PaddingBottom=UDim.new(0,6), PaddingRight=UDim.new(0,4)}, Content)

local SideNames = {"Home","ESP","Aim","Brutal","LocalCfg","Settings"}
local TabButtons, CurrentTab = {}, "Home"
local PageBuilders = {}

local function ClearContent()
    for _, ch in ipairs(Content:GetChildren()) do
        if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
    end
    Content.CanvasPosition = Vector2.zero
end

local function Card(title, sub, height)
    local c = New("Frame", {Size=UDim2.new(1,-4,0,height), BackgroundColor3=T.Card, BorderSizePixel=0, ZIndex=12}, Content)
    Round(c, 12); Stroke(c, T.Element, 0.3)
    New("TextLabel", {Position=UDim2.fromOffset(12,8), Size=UDim2.new(1,-20,0,16), BackgroundTransparency=1, Text=title, TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, c)
    if sub then
        New("TextLabel", {Position=UDim2.fromOffset(12,24), Size=UDim2.new(1,-20,0,12), BackgroundTransparency=1, Text=sub, TextColor3=T.Muted, Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, c)
    end
    return c
end

local function Toggle(card, y, title, sub, default, cb)
    local row = New("Frame", {Position=UDim2.fromOffset(10,y), Size=UDim2.new(1,-20,0,36), BackgroundTransparency=1, ZIndex=13}, card)
    New("TextLabel", {Size=UDim2.new(1,-50,0,14), BackgroundTransparency=1, Text=title, TextColor3=T.White, Font=Enum.Font.GothamMedium, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, row)
    if sub then
        New("TextLabel", {Position=UDim2.fromOffset(0,15), Size=UDim2.new(1,-50,0,12), BackgroundTransparency=1, Text=sub, TextColor3=T.Muted, Font=Enum.Font.Gotham, TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, row)
    end
    local sw = New("Frame", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0), Size=UDim2.fromOffset(40,20), BackgroundColor3=default and T.Accent or T.Off, ZIndex=14}, row)
    Round(sw, 20)
    local dot = New("Frame", {Position=default and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,2,0.5,-7), Size=UDim2.fromOffset(14,14), BackgroundColor3=T.White, ZIndex=15}, sw)
    Round(dot, 20)
    local state = default
    local btn = New("TextButton", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", ZIndex=16}, sw)
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3=state and T.Accent or T.Off}):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {Position=state and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
        if cb then cb(state) end
    end)
end

local function Slider(card, y, title, min, max, default, cb)
    local row = New("Frame", {Position=UDim2.fromOffset(10,y), Size=UDim2.new(1,-20,0,42), BackgroundTransparency=1, ZIndex=13}, card)
    New("TextLabel", {Size=UDim2.new(0.6,0,0,14), BackgroundTransparency=1, Text=title, TextColor3=T.White, Font=Enum.Font.GothamMedium, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, row)
    local valL = New("TextLabel", {Position=UDim2.new(0.6,0,0,0), Size=UDim2.new(0.4,0,0,14), BackgroundTransparency=1, Text=tostring(default), TextColor3=T.Accent, Font=Enum.Font.GothamBold, TextSize=10, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=14}, row)
    local bar = New("Frame", {Position=UDim2.fromOffset(0,22), Size=UDim2.new(1,0,0,6), BackgroundColor3=T.Off, ZIndex=14}, row)
    Round(bar, 6)
    local fill = New("Frame", {Size=UDim2.new((default-min)/math.max(max-min,1),0,1,0), BackgroundColor3=T.Accent, ZIndex=15}, bar)
    Round(fill, 6)
    local dragging = false
    local function upd(x)
        local rel = math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        local v = math.floor(min+(max-min)*rel+0.5)
        fill.Size = UDim2.new(rel,0,1,0)
        valL.Text = tostring(v)
        if cb then cb(v) end
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; upd(i.Position.X) end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    AddConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end
    end))
end

local function Action(card, y, title, cb)
    local b = New("TextButton", {Position=UDim2.fromOffset(10,y), Size=UDim2.new(1,-20,0,30), BackgroundColor3=T.Element, Text="", AutoButtonColor=false, ZIndex=13}, card)
    Round(b, 8)
    New("TextLabel", {Position=UDim2.fromOffset(10,0), Size=UDim2.new(1,-30,1,0), BackgroundTransparency=1, Text=title, TextColor3=T.White, Font=Enum.Font.GothamMedium, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, b)
    New("TextLabel", {Position=UDim2.new(1,-22,0,0), Size=UDim2.fromOffset(18,30), BackgroundTransparency=1, Text="›", TextColor3=T.Accent, Font=Enum.Font.GothamBold, TextSize=16, ZIndex=14}, b)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
end

local function Notify(title, msg)
    local box = New("Frame", {Position=UDim2.new(1,20,0,60), Size=UDim2.fromOffset(210,55), BackgroundColor3=T.Card, BorderSizePixel=0, ZIndex=50}, ScreenGui)
    Round(box, 10); Stroke(box, T.Accent, 0.2)
    New("TextLabel", {Position=UDim2.fromOffset(10,6), Size=UDim2.new(1,-16,0,16), BackgroundTransparency=1, Text=title, TextColor3=T.Accent, Font=Enum.Font.GothamBold, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=51}, box)
    New("TextLabel", {Position=UDim2.fromOffset(10,24), Size=UDim2.new(1,-16,0,20), BackgroundTransparency=1, Text=msg, TextColor3=T.White, Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=51}, box)
    TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position=UDim2.new(1,-225,0,60)}):Play()
    task.delay(2.4, function()
        if box.Parent then
            TweenService:Create(box, TweenInfo.new(0.2), {Position=UDim2.new(1,20,0,60)}):Play()
            task.wait(0.25); box:Destroy()
        end
    end)
end

-- PAGE: HOME
PageBuilders.Home = function()
    ClearContent()
    local profile = Card("PLAYER PROFILE", "Welcome to cyber workspace", 120)
    local av = New("Frame", {Position=UDim2.fromOffset(12,48), Size=UDim2.fromOffset(50,50), BackgroundColor3=T.Element, ZIndex=13}, profile)
    Round(av, 12)
    New("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="👤", TextSize=22, ZIndex=14}, av)
    New("TextLabel", {Position=UDim2.fromOffset(72,50), Size=UDim2.new(1,-80,0,18), BackgroundTransparency=1, Text=LocalPlayer.DisplayName, TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, profile)
    New("TextLabel", {Position=UDim2.fromOffset(72,70), Size=UDim2.new(1,-80,0,14), BackgroundTransparency=1, Text="@"..LocalPlayer.Name.."  ·  SESSION ACTIVE", TextColor3=T.Accent, Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, profile)
    local line = New("Frame", {Position=UDim2.fromOffset(12,108), Size=UDim2.new(1,-24,0,2), BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=13}, profile)

    local perf = Card("LIVE STATS", "Real-time client", 90)
    local st = New("TextLabel", {Position=UDim2.fromOffset(12,48), Size=UDim2.new(1,-24,0,30), BackgroundTransparency=1, Text="FPS: -- | Players: -- | Time: 00:00", TextColor3=T.Accent, Font=Enum.Font.Code, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, perf)
    B.StatsLabel = st

    local quick = Card("QUICK ACCESS", "Shortcuts", 80)
    Action(quick, 42, "System notification", function() Notify("BAXTARA", "Dashboard OK") end)
end

-- PAGE: ESP
PageBuilders.ESP = function()
    ClearContent()
    local S = B.Settings.ESP
    local c = Card("ESP SETTINGS", "Player visuals", 340)
    Toggle(c, 42, "Enable ESP", "Master toggle", S.Enabled, function(v) B.Settings.ESP.Enabled=v end)
    Toggle(c, 78, "Box ESP", "Full body box", S.Box, function(v) B.Settings.ESP.Box=v end)
    Toggle(c, 114, "Name", "Player names", S.Name, function(v) B.Settings.ESP.Name=v end)
    Toggle(c, 150, "Health Bar", "HP bar", S.HealthBar, function(v) B.Settings.ESP.HealthBar=v end)
    Toggle(c, 186, "Distance", "Range text", S.Distance, function(v) B.Settings.ESP.Distance=v end)
    Toggle(c, 222, "Tracer Line", "Bottom line", S.Tracer, function(v) B.Settings.ESP.Tracer=v end)
    Toggle(c, 258, "Skeleton ESP", "Bone lines", S.Skeleton, function(v) B.Settings.ESP.Skeleton=v end)
    Toggle(c, 294, "Visible Check", "Green/red", S.VisibleCheck, function(v) B.Settings.ESP.VisibleCheck=v end)
    local c2 = Card("COLOR", "ESP + FOV color", 140)
    Action(c2, 42, "Cyan", function() ApplyColor("Cyan") end)
    Action(c2, 74, "Purple", function() ApplyColor("Purple") end)
    Action(c2, 106, "Green", function() ApplyColor("Green") end)
    local c3 = Card("RANGE", "Max distance", 90)
    Slider(c3, 42, "Max Distance", 100, 2000, S.MaxDistance, function(v) B.Settings.ESP.MaxDistance=v end)
end

PageBuilders.Aim = function()
    ClearContent()
    local S = B.Settings.Aim
    local c = Card("AIM SETTINGS", "Aimbot system", 400)
    Toggle(c, 42, "Enable Aimbot", "Master", S.Enabled, function(v)
        B.Settings.Aim.Enabled=v
        if v and DrawingLib and not B.Drawings.FOV then
            local f=Drawing.new("Circle"); f.Thickness=3.2; f.NumSides=64; f.Filled=false
            f.Color=B.Settings.ESP.FOVColor; f.Transparency=0.3; f.Visible=false; B.Drawings.FOV=f
        end
    end)
    Toggle(c, 78, "Silent Aim", "Hard snap", S.SilentAim, function(v) B.Settings.Aim.SilentAim=v end)
    Toggle(c, 114, "Anti Miss", "Stronger track", S.AntiMiss, function(v) B.Settings.Aim.AntiMiss=v end)
    Toggle(c, 150, "Aim Lock", "Lock target", S.AimLock, function(v) B.Settings.Aim.AimLock=v if not v then B.LockedTarget=nil end end)
    Toggle(c, 186, "Visibility Check", "Only visible", S.VisibilityCheck, function(v) B.Settings.Aim.VisibilityCheck=v end)
    Toggle(c, 222, "Head Aim", "Aim head", S.HeadAim, function(v) B.Settings.Aim.HeadAim=v; B.Settings.Aim.HitPart="Head"; if v then B.Settings.Aim.BodyAim=false end end)
    Toggle(c, 258, "Body Aim", "Aim body", S.BodyAim, function(v) B.Settings.Aim.BodyAim=v; B.Settings.Aim.HitPart="Body"; if v then B.Settings.Aim.HeadAim=false end end)
    Toggle(c, 294, "FOV Circle", "Show FOV", S.FOVCircle, function(v) B.Settings.Aim.FOVCircle=v end)
    Toggle(c, 330, "Team Check", "Skip teammates", S.TeamCheck, function(v) B.Settings.Aim.TeamCheck=v end)
    local c2 = Card("FOV / SMOOTH", "Values", 120)
    Slider(c2, 42, "FOV Size", 40, 1000, S.FOV, function(v) B.Settings.Aim.FOV=v end)
    Slider(c2, 88, "Smooth x100", 5, 40, math.floor(S.AimSmoothing*100), function(v) B.Settings.Aim.AimSmoothing=v/100 end)
end

PageBuilders.Brutal = function()
    ClearContent()
    local S = B.Settings.Brutal
    local c = Card("MOVEMENT", "Fly speed noclip", 300)
    Toggle(c, 42, "Fly", "Free fly", S.Fly, function(v)
        B.Settings.Brutal.Fly=v
        local char=LocalPlayer.Character; local root=char and GetRoot(char); local hum=char and char:FindFirstChildOfClass("Humanoid")
        if B.FlyBV then pcall(function() B.FlyBV:Destroy() end) B.FlyBV=nil end
        if B.FlyBG then pcall(function() B.FlyBG:Destroy() end) B.FlyBG=nil end
        if v and root and hum then
            hum.PlatformStand=true
            B.FlyBV=Instance.new("BodyVelocity"); B.FlyBV.MaxForce=Vector3.new(9e4,9e4,9e4); B.FlyBV.Velocity=Vector3.zero; B.FlyBV.Parent=root
            B.FlyBG=Instance.new("BodyGyro"); B.FlyBG.MaxTorque=Vector3.new(9e4,9e4,9e4); B.FlyBG.P=3000; B.FlyBG.Parent=root
        elseif hum then hum.PlatformStand=false end
    end)
    Slider(c, 78, "Fly Speed", 10, 100, S.FlySpeed, function(v) B.Settings.Brutal.FlySpeed=v end)
    Toggle(c, 122, "Speed Hack", "Walk speed", S.SpeedHack, function(v)
        B.Settings.Brutal.SpeedHack=v
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then if v then B.OriginalWalkSpeed=hum.WalkSpeed; hum.WalkSpeed=math.clamp(B.Settings.Brutal.SpeedValue,16,40) else hum.WalkSpeed=B.OriginalWalkSpeed or 16 end end
    end)
    Slider(c, 158, "Walk Speed", 16, 40, S.SpeedValue, function(v) B.Settings.Brutal.SpeedValue=v if B.Settings.Brutal.SpeedHack then local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=v end end end)
    Toggle(c, 200, "Infinite Jump", "Spam jump", S.InfiniteJump, function(v)
        B.Settings.Brutal.InfiniteJump=v
        if B.JumpConn then B.JumpConn:Disconnect() B.JumpConn=nil end
        if v then B.JumpConn=UserInputService.JumpRequest:Connect(function() local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end); AddConn(B.JumpConn) end
    end)
    Toggle(c, 236, "Noclip", "No collision", S.Noclip, function(v)
        B.Settings.Brutal.Noclip=v
        if B.NoclipConn then B.NoclipConn:Disconnect() B.NoclipConn=nil end
        if v then B.NoclipConn=RunService.Stepped:Connect(function() local ch=LocalPlayer.Character if not ch then return end for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end); AddConn(B.NoclipConn) end
    end)

    local h = Card("HITBOX", "Enlarge Head or Body", 200)
    Toggle(h, 42, "Hitbox Expand", "Enlarge real part", S.HitboxExpand, function(v)
        B.Settings.Brutal.HitboxExpand = v
        if not v then ClearAllHitboxes() end
    end)
    Toggle(h, 78, "Hitbox on Head", "Enlarge Head part", S.HitboxPart=="Head", function(v)
        if v then
            B.Settings.Brutal.HitboxPart = "Head"
            ClearAllHitboxes()
        end
    end)
    Toggle(h, 114, "Hitbox on Body", "Enlarge HRP (body)", S.HitboxPart=="Body", function(v)
        if v then
            B.Settings.Brutal.HitboxPart = "Body"
            ClearAllHitboxes()
        end
    end)
    Slider(h, 150, "Hitbox Size 2-27", 2, 27, S.HitboxSize, function(v)
        B.Settings.Brutal.HitboxSize = v
    end)

    local w = Card("COMBAT", "Weapon & autokill", 200)
    Toggle(w, 42, "Anti Cooldown", "No fire delay", S.AntiCooldown, function(v) B.Settings.Brutal.AntiCooldown=v end)
    Toggle(w, 78, "Infinite Ammo", "Ammo refill", S.InfiniteAmmo, function(v) B.Settings.Brutal.InfiniteAmmo=v end)
    Toggle(w, 114, "Attack Speed 1-12", "Safe rate", S.AttackSpeed, function(v) B.Settings.Brutal.AttackSpeed=v end)
    Slider(w, 150, "Attack Speed Val", 1, 12, S.AttackSpeedVal, function(v) B.Settings.Brutal.AttackSpeedVal=v end)
    Toggle(w, 192, "Auto Kill silent", "Snap+fire nearest", S.AutoKill, function(v) B.Settings.Brutal.AutoKill=v end)
end

PageBuilders.LocalCfg = function()
    ClearContent()
    local S = B.Settings.LocalCfg
    local sky = Card("SKY BRANDING", "BAXTARA text in sky", 100)
    Toggle(sky, 42, "Sky BAXTARA Text", "Ring of text around you", S.SkyBAXTARA, function(v)
        B.Settings.LocalCfg.SkyBAXTARA = v
        if B.SkyFolder then pcall(function() B.SkyFolder:Destroy() end) B.SkyFolder=nil end
        if v then
            B.SkyFolder = Instance.new("Folder")
            B.SkyFolder.Name = "BAXTARA_SKY"
            B.SkyFolder.Parent = Workspace
            local root = GetRoot(LocalPlayer.Character)
            local base = root and root.Position or Vector3.new(0, 30, 0)
            for i = 1, 12 do
                local ang = (i/12) * math.pi * 2
                local part = Instance.new("Part")
                part.Name = "BXSky"
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 1
                part.Size = Vector3.new(2,2,2)
                part.CFrame = CFrame.new(base.X + math.cos(ang)*120, base.Y + 60, base.Z + math.sin(ang)*120)
                part.Parent = B.SkyFolder
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.fromOffset(400, 60)
                bb.MaxDistance = 2000
                bb.Parent = part
                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.fromScale(1,1)
                tl.BackgroundTransparency = 1
                tl.Text = "BAXTARA X CHEAT"
                tl.TextColor3 = Color3.fromRGB(0, 230, 200)
                tl.TextStrokeTransparency = 0.4
                tl.Font = Enum.Font.GothamBlack
                tl.TextScaled = true
                tl.Parent = bb
            end
            Lighting.Brightness = math.max(Lighting.Brightness, 2.5)
            Lighting.Ambient = Color3.fromRGB(140, 160, 180)
            Lighting.FogEnd = 1e6
            Lighting.ClockTime = 14
        end
    end)
    Action(sky, 78, "Refresh sky positions", function()
        if B.Settings.LocalCfg.SkyBAXTARA then
            if B.SkyFolder then pcall(function() B.SkyFolder:Destroy() end) B.SkyFolder=nil end
            B.Settings.LocalCfg.SkyBAXTARA = false
            task.wait(0.05)
            B.Settings.LocalCfg.SkyBAXTARA = true
            -- rebuild
            B.SkyFolder = Instance.new("Folder"); B.SkyFolder.Name="BAXTARA_SKY"; B.SkyFolder.Parent=Workspace
            local root = GetRoot(LocalPlayer.Character)
            local base = root and root.Position or Vector3.new(0,30,0)
            for i=1,12 do
                local ang=(i/12)*math.pi*2
                local part=Instance.new("Part"); part.Anchored=true; part.CanCollide=false; part.Transparency=1; part.Size=Vector3.new(2,2,2)
                part.CFrame=CFrame.new(base.X+math.cos(ang)*120, base.Y+60, base.Z+math.sin(ang)*120); part.Parent=B.SkyFolder
                local bb=Instance.new("BillboardGui"); bb.Size=UDim2.fromOffset(400,60); bb.MaxDistance=2000; bb.Parent=part
                local tl=Instance.new("TextLabel"); tl.Size=UDim2.fromScale(1,1); tl.BackgroundTransparency=1; tl.Text="BAXTARA X CHEAT"
                tl.TextColor3=Color3.fromRGB(0,230,200); tl.Font=Enum.Font.GothamBlack; tl.TextScaled=true; tl.Parent=bb
            end
            Notify("SKY", "Refreshed")
        end
    end)

    local fr = Card("FREEZE PLAYERS", "Others frozen, you free", 120)
    Toggle(fr, 42, "Freeze All Others", "Anchor their HRP (client)", S.FreezeOthers, function(v)
        B.Settings.LocalCfg.FreezeOthers = v
        if not v then
            for uid, root in pairs(B.FrozenParts) do
                pcall(function() if root and root.Parent then root.Anchored = false end end)
            end
            B.FrozenParts = {}
            Notify("FREEZE", "Players unfrozen")
        else
            Notify("FREEZE", "Freezing others...")
        end
    end)
    Action(fr, 78, "Force Unfreeze All", function()
        B.Settings.LocalCfg.FreezeOthers = false
        for uid, root in pairs(B.FrozenParts) do
            pcall(function() if root and root.Parent then root.Anchored = false end end)
        end
        B.FrozenParts = {}
        Notify("FREEZE", "All unfrozen")
    end)

    local tp = Card("TELEPORT / LAG", "Player tools", 120)
    Action(tp, 42, "TP ALL PLAYERS IN FRONT", function()
        local my = GetRoot(LocalPlayer.Character)
        if not my then return end
        local front = my.CFrame * CFrame.new(0,0,-10)
        local i = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local root = GetRoot(GetChar(p))
                if root then
                    i = i + 1
                    pcall(function() root.CFrame = front * CFrame.new((i%5)*3-6, 0, math.floor(i/5)*3) end)
                end
            end
        end
        Notify("TP", "TP All attempted (client)")
    end)
    Toggle(tp, 78, "Anti Lag Self", "Low quality for you", S.AntiLagSelf, function(v)
        B.Settings.LocalCfg.AntiLagSelf = v
        pcall(function()
            settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
        end)
    end)
end

PageBuilders.Settings = function()
    ClearContent()
    local th = Card("PANEL THEME", "4 styles", 180)
    Action(th, 42, "Theme: Modern (Cyan)", function()
        T = Themes.Modern; B.Settings.UI.Theme="Modern"
        Main.BackgroundColor3=T.Background; Header.BackgroundColor3=T.Sidebar; Sidebar.BackgroundColor3=T.Sidebar
        MainBorder.Color=T.Accent; Notify("THEME", "Modern")
    end)
    Action(th, 74, "Theme: Hacker (Green)", function()
        T = Themes.Hacker; B.Settings.UI.Theme="Hacker"
        Main.BackgroundColor3=T.Background; Header.BackgroundColor3=T.Sidebar; Sidebar.BackgroundColor3=T.Sidebar
        MainBorder.Color=T.Accent; Notify("THEME", "Hacker")
    end)
    Action(th, 106, "Theme: Cartoon (Pink)", function()
        T = Themes.Cartoon; B.Settings.UI.Theme="Cartoon"
        Main.BackgroundColor3=T.Background; Header.BackgroundColor3=T.Sidebar; Sidebar.BackgroundColor3=T.Sidebar
        MainBorder.Color=T.Accent; Notify("THEME", "Cartoon")
    end)
    Action(th, 138, "Theme: Default (Purple)", function()
        T = Themes.Default; B.Settings.UI.Theme="Default"
        Main.BackgroundColor3=T.Background; Header.BackgroundColor3=T.Sidebar; Sidebar.BackgroundColor3=T.Sidebar
        MainBorder.Color=T.Accent; Notify("THEME", "Default")
    end)

    local pr = Card("PROTECT", "Anti kick / hop", 140)
    Toggle(pr, 42, "Anti-Kick Watch", "Detect kick UI", true, function(v) B.Settings.Protect.AntiKick=v end)
    Toggle(pr, 78, "Auto Hop on Flag", "Teleport on detect", true, function(v) B.Settings.Protect.AutoHopOnFlag=v end)
    Action(pr, 114, "FORCE SERVER HOP", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)

    local key = Card("KEY SAVE", "Auto login", 100)
    Action(key, 42, "Save Key (auto unlock next run)", function()
        SaveKeyUnlock()
        Notify("KEY", "Saved — next execute skips key")
    end)
    Action(key, 74, "Clear Saved Key", function()
        getgenv().BAXTARA_UNLOCKED = false
        pcall(function() if isfile and isfile(KEY_FILE) and delfile then delfile(KEY_FILE) end end)
        Notify("KEY", "Save cleared")
    end)

    local un = Card("UNLOAD", "Remove script", 60)
    Action(un, 42, "UNLOAD SCRIPT", function()
        CleanupAll(); ScreenGui:Destroy(); getgenv().BAXTARA=nil
    end)
end

-- Tabs
local function SelectTab(name)
    CurrentTab = name
    for n, btn in pairs(TabButtons) do
        local active = (n == name)
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = active and T.Element or T.Sidebar}):Play()
        local ind = btn:FindFirstChild("Ind")
        if ind then ind.BackgroundTransparency = active and 0 or 1 end
    end
    if PageBuilders[name] then PageBuilders[name]() end
end

for i, name in ipairs(SideNames) do
    local btn = New("TextButton", {Size=UDim2.new(1,0,0,32), BackgroundColor3=T.Sidebar, Text="", AutoButtonColor=false, LayoutOrder=i, ZIndex=13}, TabHolder)
    Round(btn, 8)
    local ind = New("Frame", {Name="Ind", Position=UDim2.fromOffset(0,6), Size=UDim2.new(0,3,0,20), BackgroundColor3=T.Accent, BackgroundTransparency=1, BorderSizePixel=0, ZIndex=14}, btn)
    Round(ind, 4)
    New("TextLabel", {Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-16,1,0), BackgroundTransparency=1, Text=name, TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, btn)
    TabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end

-- ===================== CORE =====================
local function GetAimPart(char)
    if B.Settings.Aim.HitPart=="Body" or B.Settings.Aim.BodyAim then return GetRoot(char) or GetHead(char) end
    return GetHead(char) or GetRoot(char)
end

local function GetBestTarget()
    local best, bestScore = nil, math.huge
    local center, camPos, fov = ScreenCenter(), Camera.CFrame.Position, B.Settings.Aim.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and TeamOK(p) then
            local char=GetChar(p)
            if IsAlive(char) then
                local part=GetAimPart(char)
                if part then
                    local dist=DistTo(part.Position)
                    if dist<=B.Settings.Aim.AimDistance then
                        local screen,on=WorldToScreen(part.Position)
                        if on then
                            local cross=(screen-center).Magnitude
                            if cross<=fov then
                                local vis=IsVisible(camPos, part.Position, char)
                                if not (B.Settings.Aim.VisibilityCheck and not vis) and cross<bestScore then
                                    bestScore=cross; best=p
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function GetNearestEnemy()
    local best, bd = nil, 99999
    local my = GetRoot(LocalPlayer.Character)
    if not my then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and TeamOK(p) then
            local char=GetChar(p)
            if IsAlive(char) then
                local root=GetRoot(char)
                if root then
                    local d=(my.Position-root.Position).Magnitude
                    if d<bd and d<B.Settings.Aim.AimDistance then bd=d; best=p end
                end
            end
        end
    end
    return best
end

local function AimAt(target)
    if not target then return end
    local char=GetChar(target); if not IsAlive(char) then return end
    local part=GetAimPart(char); if not part then return end
    if B.Settings.Aim.VisibilityCheck and not IsVisible(Camera.CFrame.Position, part.Position, char) then return end
    local pos=part.Position
    if B.Settings.Aim.AimPrediction then pos=pos+(part.AssemblyLinearVelocity or Vector3.zero)*B.Settings.Aim.PredictionAmount end
    local smooth=B.Settings.Aim.AimSmoothing
    if B.Settings.Aim.SilentAim or B.Settings.Brutal.AutoKill then smooth=0.85 end
    if B.Settings.Aim.AntiMiss then smooth=math.clamp(smooth+0.2,0.1,0.9) end
    Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pos), smooth)
end

local function UpdateAim()
    if not B.Settings.Aim.Enabled and not B.Settings.Brutal.AutoKill then
        if B.Drawings.FOV then B.Drawings.FOV.Visible=false end
        B.CurrentTarget=nil; return
    end
    local center=ScreenCenter()
    if B.Drawings.FOV and B.Settings.Aim.FOVCircle and B.Settings.Aim.Enabled then
        B.Drawings.FOV.Position=center; B.Drawings.FOV.Radius=B.Settings.Aim.FOV
        B.Drawings.FOV.Color=B.Settings.ESP.FOVColor; B.Drawings.FOV.Thickness=3.2; B.Drawings.FOV.Visible=true
    elseif B.Drawings.FOV then B.Drawings.FOV.Visible=false end
    local target=B.Settings.Aim.Enabled and ((B.Settings.Aim.AimLock and B.LockedTarget) or GetBestTarget()) or nil
    if B.Settings.Aim.AimLock and not B.LockedTarget and target then B.LockedTarget=target end
    if not B.Settings.Aim.AimLock then B.LockedTarget=nil end
    B.CurrentTarget=target
    if target then AimAt(target) end
end

-- ESP
local BonePairs={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local function DestroyPack(id)
    local pack=B.ESPObjects[id]; if not pack then return end
    for k,d in pairs(pack) do
        if k=="Skel" then for _,l in ipairs(d) do pcall(function() if l.Remove then l:Remove() end end) end
        else pcall(function() if d and d.Remove then d:Remove() end end) end
    end
    B.ESPObjects[id]=nil
end

local function GetESPPack(player)
    local id=player.UserId
    if B.ESPObjects[id] then return B.ESPObjects[id] end
    if not DrawingLib then return nil end
    local pack={Box=Drawing.new("Square"),Name=Drawing.new("Text"),Health=Drawing.new("Line"),Dist=Drawing.new("Text"),Tracer=Drawing.new("Line"),Skel={}}
    pack.Box.Thickness=1.5; pack.Box.Filled=false; pack.Box.Visible=false
    pack.Name.Size=12; pack.Name.Center=true; pack.Name.Outline=true; pack.Name.Visible=false
    pack.Health.Thickness=2.2; pack.Health.Visible=false
    pack.Dist.Size=11; pack.Dist.Center=true; pack.Dist.Outline=true; pack.Dist.Visible=false
    pack.Tracer.Thickness=1.2; pack.Tracer.Visible=false
    for i=1,14 do local l=Drawing.new("Line"); l.Thickness=1.2; l.Visible=false; pack.Skel[i]=l end
    B.ESPObjects[id]=pack; return pack
end

local function HidePack(pack)
    if not pack then return end
    for k,d in pairs(pack) do
        if k=="Skel" then for _,l in ipairs(d) do if l then l.Visible=false end end
        elseif d and d.Visible~=nil then d.Visible=false end
    end
end

local function UpdateESP()
    local alive={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then alive[p.UserId]=true end end
    for id,_ in pairs(B.ESPObjects) do if not alive[id] then DestroyPack(id) end end
    if not B.Settings.ESP.Enabled then for _,pack in pairs(B.ESPObjects) do HidePack(pack) end return end
    local camPos=Camera.CFrame.Position
    local bottom=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        local char=GetChar(player); local pack=GetESPPack(player); if not pack then continue end
        if not IsAlive(char) then HidePack(pack) continue end
        local root,head=GetRoot(char),GetHead(char); if not root or not head then HidePack(pack) continue end
        local dist=DistTo(root.Position); if dist>B.Settings.ESP.MaxDistance then HidePack(pack) continue end
        local top=head.Position+Vector3.new(0,0.4,0); local bot=root.Position-Vector3.new(0,3,0)
        local topS,on=WorldToScreen(top); local botS=select(1,WorldToScreen(bot)); local rootS=select(1,WorldToScreen(root.Position))
        local vis=true; if B.Settings.ESP.VisibleCheck then vis=IsVisible(camPos,head.Position,char) end
        local color=vis and B.Settings.ESP.VisibleColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.PriorityMark and B.CurrentTarget==player then color=B.Settings.ESP.PriorityColor end
        local boxCol=vis and B.Settings.ESP.BoxColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.Box and pack.Box then
            local h=math.max(math.abs(topS.Y-botS.Y),14); local w=h*0.68
            pack.Box.Size=Vector2.new(w,h); pack.Box.Position=Vector2.new(topS.X-w/2,topS.Y); pack.Box.Color=boxCol; pack.Box.Visible=on
        else pack.Box.Visible=false end
        if B.Settings.ESP.Name and pack.Name then
            pack.Name.Text=player.DisplayName or player.Name; pack.Name.Position=Vector2.new(topS.X,topS.Y-13); pack.Name.Color=color; pack.Name.Visible=on
        else pack.Name.Visible=false end
        if B.Settings.ESP.HealthBar and pack.Health then
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local h=math.max(math.abs(topS.Y-botS.Y),14)
                local x=topS.X-(h*0.68)/2-5
                pack.Health.From=Vector2.new(x,topS.Y+h); pack.Health.To=Vector2.new(x,topS.Y+h*(1-pct))
                pack.Health.Color=Color3.fromRGB(255*(1-pct),255*pct,40); pack.Health.Visible=on
            end
        else pack.Health.Visible=false end
        if B.Settings.ESP.Distance and pack.Dist then
            pack.Dist.Text=string.format("[%dm]",math.floor(dist)); pack.Dist.Position=Vector2.new(botS.X,botS.Y+3); pack.Dist.Color=Color3.fromRGB(180,200,210); pack.Dist.Visible=on
        else pack.Dist.Visible=false end
        if B.Settings.ESP.Tracer and pack.Tracer then
            pack.Tracer.From=bottom; pack.Tracer.To=rootS; pack.Tracer.Color=B.Settings.ESP.TracerColor; pack.Tracer.Visible=on
        else pack.Tracer.Visible=false end
        if B.Settings.ESP.Skeleton and pack.Skel then
            local idx=1
            for _,pair in ipairs(BonePairs) do
                if idx>#pack.Skel then break end
                local a=char:FindFirstChild(pair[1]); local b=char:FindFirstChild(pair[2]); local line=pack.Skel[idx]
                if a and b and a:IsA("BasePart") and b:IsA("BasePart") and line then
                    local sa,oa=WorldToScreen(a.Position); local sb,ob=WorldToScreen(b.Position)
                    if oa and ob then line.From=sa; line.To=sb; line.Color=color; line.Visible=true; idx=idx+1 end
                end
            end
            for i=idx,#pack.Skel do pack.Skel[i].Visible=false end
        elseif pack.Skel then for _,l in ipairs(pack.Skel) do l.Visible=false end end
    end
end

-- SAFE HITBOX: fake part welded, never resize real Head/HRP
local B_OriginalSizes = {} -- [userId] = {Head=Vector3, HRP=Vector3}

local function RestorePlayerSizes(userId)
    local data = B_OriginalSizes[userId]
    if not data then return end
    local player = Players:GetPlayerByUserId(userId)
    if not player then B_OriginalSizes[userId]=nil return end
    local char = player.Character
    if not char then return end
    if data.Head then
        local h = char:FindFirstChild("Head")
        if h and h:IsA("BasePart") then pcall(function() h.Size = data.Head; h.Transparency = data.HeadTrans or 0 end) end
    end
    if data.HRP then
        local r = char:FindFirstChild("HumanoidRootPart")
        if r and r:IsA("BasePart") then pcall(function() r.Size = data.HRP; r.Transparency = data.HRPTrans or 1 end) end
    end
end

local function ClearAllHitboxes()
    for uid,_ in pairs(B_OriginalSizes) do
        RestorePlayerSizes(uid)
    end
    B_OriginalSizes = {}
    for _,p in pairs(B.HitboxParts) do
        pcall(function() if p and p.Parent then p:Destroy() end end)
    end
    B.HitboxParts = {}
end

local function UpdateHitbox()
    if not B.Settings.Brutal.HitboxExpand then
        if next(B_OriginalSizes) or next(B.HitboxParts) then
            ClearAllHitboxes()
        end
        return
    end
    local size = math.clamp(tonumber(B.Settings.Brutal.HitboxSize) or 8, 2, 27)
    local mode = B.Settings.Brutal.HitboxPart -- "Head" or "Body"
    local alive = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = GetChar(p)
        if not IsAlive(char) then continue end
        local head = GetHead(char)
        local root = GetRoot(char)
        if not root then continue end
        alive[p.UserId] = true

        -- store originals once
        if not B_OriginalSizes[p.UserId] then
            B_OriginalSizes[p.UserId] = {}
            if head then
                B_OriginalSizes[p.UserId].Head = head.Size
                B_OriginalSizes[p.UserId].HeadTrans = head.Transparency
            end
            if root then
                B_OriginalSizes[p.UserId].HRP = root.Size
                B_OriginalSizes[p.UserId].HRPTrans = root.Transparency
            end
        end

        local targetSize = Vector3.new(size, size, size)

        if mode == "Head" and head then
            -- enlarge HEAD only; restore HRP if was enlarged
            pcall(function()
                head.Size = targetSize
                head.Transparency = 0.4
                head.CanCollide = false
                head.Massless = true
            end)
            -- restore body if we switched from body mode
            if B_OriginalSizes[p.UserId].HRP and root then
                pcall(function()
                    root.Size = B_OriginalSizes[p.UserId].HRP
                    root.Transparency = B_OriginalSizes[p.UserId].HRPTrans or 1
                end)
            end
            -- visual marker ball (optional, non-blocking)
            local marker = B.HitboxParts[p.UserId]
            if not marker or not marker.Parent then
                marker = Instance.new("Part")
                marker.Name = "BX_HBMark"
                marker.Shape = Enum.PartType.Ball
                marker.Size = targetSize
                marker.Transparency = 0.7
                marker.Color = Color3.fromRGB(255, 50, 50)
                marker.Material = Enum.Material.ForceField
                marker.CanCollide = false
                marker.CanQuery = false
                marker.Massless = true
                marker.Anchored = false
                marker.Parent = char
                local w = Instance.new("Weld")
                w.Part0 = head
                w.Part1 = marker
                w.Parent = marker
                B.HitboxParts[p.UserId] = marker
            else
                marker.Size = targetSize
            end
        else
            -- BODY mode: enlarge HumanoidRootPart
            if root then
                pcall(function()
                    root.Size = targetSize
                    root.Transparency = 0.5
                    root.CanCollide = false
                    root.Massless = true
                end)
            end
            -- restore head if switched
            if B_OriginalSizes[p.UserId].Head and head then
                pcall(function()
                    head.Size = B_OriginalSizes[p.UserId].Head
                    head.Transparency = B_OriginalSizes[p.UserId].HeadTrans or 0
                end)
            end
            local marker = B.HitboxParts[p.UserId]
            if not marker or not marker.Parent then
                marker = Instance.new("Part")
                marker.Name = "BX_HBMark"
                marker.Shape = Enum.PartType.Ball
                marker.Size = targetSize
                marker.Transparency = 0.7
                marker.Color = Color3.fromRGB(255, 80, 80)
                marker.Material = Enum.Material.ForceField
                marker.CanCollide = false
                marker.CanQuery = false
                marker.Massless = true
                marker.Parent = char
                local w = Instance.new("Weld")
                w.Part0 = root
                w.Part1 = marker
                w.Parent = marker
                B.HitboxParts[p.UserId] = marker
            else
                marker.Size = targetSize
            end
        end
    end

    for uid, _ in pairs(B_OriginalSizes) do
        if not alive[uid] then
            RestorePlayerSizes(uid)
            B_OriginalSizes[uid] = nil
            if B.HitboxParts[uid] then
                pcall(function() B.HitboxParts[uid]:Destroy() end)
                B.HitboxParts[uid] = nil
            end
        end
    end
end

local function DoAutoKill()
    if not B.Settings.Brutal.AutoKill then return end
    local rate=math.clamp(B.Settings.Brutal.AttackSpeedVal,1,12)
    if tick()-B.LastShoot<(1/rate) then return end
    B.LastShoot=tick()
    local target=GetNearestEnemy(); if not target then return end
    local part=GetAimPart(GetChar(target)); if not part then return end
    Camera.CFrame=CFrame.new(Camera.CFrame.Position, part.Position)
    local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        for _,r in ipairs(tool:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local n=r.Name:lower()
                if n:find("fire") or n:find("shoot") or n:find("shot") then pcall(function() r:FireServer(part.Position) end) end
            end
        end
    end
end

local function PatchWeapon()
    local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool"); if not tool then return end
    if B.Settings.Brutal.AntiCooldown or B.Settings.Brutal.AttackSpeed then
        for _,v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n=v.Name:lower()
                if n:find("cool") or n:find("delay") or n:find("rate") then pcall(function() v.Value=0 end) end
            end
        end
    end
    if B.Settings.Brutal.InfiniteAmmo then
        for _,v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n=v.Name:lower()
                if n:find("ammo") or n:find("clip") or n:find("mag") then pcall(function() v.Value=999 end) end
            end
        end
    end
end

AddConn(RunService.RenderStepped:Connect(function()
    if not B.Unlocked then return end
    UpdateAim(); UpdateESP(); UpdateHitbox(); UpdateFreeze()
    if B.Settings.Brutal.Fly and B.FlyBV and B.FlyBG then
        local cf=Camera.CFrame; local move=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move=move+cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move=move-cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move=move-cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move=move+cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move=move+Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move=move-Vector3.yAxis end
        B.FlyBV.Velocity=move.Magnitude>0.1 and move.Unit*B.Settings.Brutal.FlySpeed or Vector3.zero
        B.FlyBG.CFrame=cf
    end
end))

AddConn(RunService.Heartbeat:Connect(function()
    if not B.Unlocked then return end
    if B.Settings.Brutal.AntiCooldown or B.Settings.Brutal.InfiniteAmmo or B.Settings.Brutal.AttackSpeed then PatchWeapon() end
    if B.Settings.Brutal.AutoKill then DoAutoKill() end
    if B.StatsLabel then
        local fps=60; pcall(function() fps=math.floor(1/RunService.RenderStepped:Wait()) end)
        local el=math.floor(tick()-B.SessionStart)
        B.StatsLabel.Text=string.format("FPS: %d | Players: %d | Time: %02d:%02d", fps, #Players:GetPlayers(), math.floor(el/60), el%60)
    end
end))

AddConn(Players.PlayerRemoving:Connect(function(p)
    DestroyPack(p.UserId)
    if B.HitboxParts[p.UserId] then pcall(function() B.HitboxParts[p.UserId]:Destroy() end); B.HitboxParts[p.UserId]=nil end
    B.FrozenParts[p.UserId]=nil
end))

AddConn(CoreGui.DescendantAdded:Connect(function(obj)
    if not B.Settings.Protect.AntiKick then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local t=(obj.Text or ""):lower()
        if t:find("suspicious") or t:find("banned") or t:find("exploiting") or t:find("kicked") or t:find("timedout") then
            if B.Settings.Protect.AutoHopOnFlag then pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end
        end
    end
end))

-- Drag
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPos=Main.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
AddConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end))

local function ShowPanel()
    Main.Visible=true
    MainScale.Scale=0.7
    TweenService:Create(MainScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale=1}):Play()
end
local function HidePanel()
    local tw=TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale=0.6})
    tw:Play(); tw.Completed:Wait(); Main.Visible=false
end
CloseBtn.MouseButton1Click:Connect(HidePanel)
MinBtn.MouseButton1Click:Connect(HidePanel)

AddConn(UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.RightControl and B.Unlocked then
        if Main.Visible then HidePanel() else ShowPanel() end
    end
end))

local OpenBtn=New("TextButton", {Size=UDim2.fromOffset(46,46), Position=UDim2.new(1,-58,0.5,-23), BackgroundColor3=T.Accent, Text="BX", TextColor3=T.Background, Font=Enum.Font.GothamBlack, TextSize=14, Visible=false, ZIndex=20, AutoButtonColor=false}, ScreenGui)
Round(OpenBtn, 23)
OpenBtn.MouseButton1Click:Connect(function() if Main.Visible then HidePanel() else ShowPanel() end end)

local function AfterUnlock()
    B.Unlocked=true
    SaveKeyUnlock()
    KeyFrame.Visible=false
    LoadFrame.Visible=true
    for _,pct in ipairs({30,60,90,100}) do
        LoadBar:TweenSize(UDim2.new(pct/100,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        LoadPct.Text=pct.."%"
        task.wait(0.28)
    end
    task.wait(0.1)
    LoadFrame.Visible=false
    OpenBtn.Visible=UserInputService.TouchEnabled
    SelectTab("Home")
    ShowPanel()
    Notify("BAXTARA X CHEAT", "Cyber Premium loaded")
end

VerifyBtn.MouseButton1Click:Connect(function()
    local input=(KeyBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    if input:upper()==ACCESS_KEY:upper() then
        StatusLbl.TextColor3=T.Accent; StatusLbl.Text="ACCESS GRANTED"
        task.wait(0.25)
        AfterUnlock()
    else
        StatusLbl.TextColor3=T.Red; StatusLbl.Text="INVALID KEY"
    end
end)

-- Auto unlock if saved
if LoadKeyUnlock() then
    task.spawn(function()
        task.wait(0.15)
        AfterUnlock()
    end)
end

print("[BAXTARA X CHEAT v5.5] Cyber UI | Safe hitbox | Freeze | Key save | Sky fix | NUGI CENEL")
