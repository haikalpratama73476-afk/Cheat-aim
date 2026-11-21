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
        SilentAim=false, AntiMiss=false, HitPart="Head", AimNPC=false,
    },
    ESP = {
        Enabled=false, Box=true, Name=true, HealthBar=true, Distance=true, Tracer=true,
        Skeleton=false, VisibleCheck=true, PriorityMark=true, Offscreen=true, MaxDistance=1000,
        NPCESP=false, TracerOrigin="Bottom", -- Bottom / Center / Top / Left / Right
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
        AutoKill=false, FlyKillAll=false, SpinBot=false, SpinSpeed=40,
        GodMode=false, GhostMode=false,
    },
    LocalCfg = {
        SkyBAXTARA=false, FreezeOthers=false, AntiLagSelf=true, ServerLag=false,
        SelfTag=false, SelfTagText="BAXTARA", SelfTagColor="Gold", SelfTagRainbow=false,
        ServerChat=false, UnlockPasses=false, AutoRank=false,
        TPTarget="Player", -- Player / Object
    },
    Troll = {
        FakeBan=false, FakeBanText="You have been banned. Reason: Exploiting (Code 2A)",
    },
    VIP = {
        Unlocked=false, Injected=false,
        MagicBullet=false, KillAura=false, VoidWalk=false, NinjaDash=false, WallCling=false,
        BackstabTP=false, FakeDisconnect=false, RealityWarp=false, MeteorRain=false,
        AuraParticle=false, GoldESP=false, StreamerMode=false, SpoofName=false,
        ChatTag=false, DeathEffect=false, SkyVIP=false,
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
        Name="Modern",
        Background=Color3.fromRGB(8, 12, 20),
        Sidebar=Color3.fromRGB(12, 18, 28),
        Card=Color3.fromRGB(16, 24, 36),
        Element=Color3.fromRGB(24, 34, 50),
        Accent=Color3.fromRGB(0, 220, 200),
        Accent2=Color3.fromRGB(60, 140, 255),
        White=Color3.fromRGB(240, 248, 255),
        Muted=Color3.fromRGB(120, 140, 165),
        Off=Color3.fromRGB(40, 50, 65),
        Red=Color3.fromRGB(255, 90, 110),
        Border=Color3.fromRGB(0, 200, 180),
        Corner=12,
        StrokeThick=1.2,
    },
    Galaxy = {
        Name="Galaxy",
        Background=Color3.fromRGB(6, 4, 18),
        Sidebar=Color3.fromRGB(12, 8, 28),
        Card=Color3.fromRGB(18, 12, 36),
        Element=Color3.fromRGB(28, 18, 48),
        Accent=Color3.fromRGB(180, 120, 255),
        Accent2=Color3.fromRGB(80, 180, 255),
        White=Color3.fromRGB(245, 240, 255),
        Muted=Color3.fromRGB(140, 120, 180),
        Off=Color3.fromRGB(35, 25, 55),
        Red=Color3.fromRGB(255, 100, 140),
        Border=Color3.fromRGB(160, 100, 255),
        Corner=16,
        StrokeThick=1.4,
    },
    Lego = {
        Name="Lego",
        Background=Color3.fromRGB(25, 30, 40),
        Sidebar=Color3.fromRGB(35, 45, 60),
        Card=Color3.fromRGB(50, 60, 80),
        Element=Color3.fromRGB(70, 85, 110),
        Accent=Color3.fromRGB(255, 200, 40),
        Accent2=Color3.fromRGB(0, 120, 255),
        White=Color3.fromRGB(255, 255, 255),
        Muted=Color3.fromRGB(180, 190, 200),
        Off=Color3.fromRGB(60, 70, 85),
        Red=Color3.fromRGB(220, 40, 40),
        Border=Color3.fromRGB(255, 180, 0),
        Corner=4,
        StrokeThick=3,
    },
    Ramadhan = {
        Name="Ramadhan",
        Background=Color3.fromRGB(8, 18, 12),
        Sidebar=Color3.fromRGB(12, 28, 18),
        Card=Color3.fromRGB(18, 36, 24),
        Element=Color3.fromRGB(28, 50, 35),
        Accent=Color3.fromRGB(218, 175, 70),
        Accent2=Color3.fromRGB(40, 160, 90),
        White=Color3.fromRGB(255, 250, 235),
        Muted=Color3.fromRGB(150, 160, 130),
        Off=Color3.fromRGB(35, 50, 40),
        Red=Color3.fromRGB(200, 80, 60),
        Border=Color3.fromRGB(200, 160, 50),
        Corner=14,
        StrokeThick=1.5,
    },
}
local T = Themes.Modern

local ThemeDecor = nil -- decorative overlay folder inside Main

local function ClearThemeDecor()
    if ThemeDecor then pcall(function() ThemeDecor:Destroy() end) ThemeDecor = nil end
end

local function ApplyTheme(name)
    local th = Themes[name] or Themes.Modern
    T = th
    B.Settings.UI.Theme = name

    -- core shells
    local Main = B.Main
    local Header = B.Header
    local Sidebar = B.Sidebar
    local MainBorder = B.MainBorder
    local OpenBtn = B.OpenBtn
    if not Main then Notify("THEME", "Panel not ready"); return end

    Main.BackgroundColor3 = th.Background
    if Header then Header.BackgroundColor3 = th.Sidebar end
    if Sidebar then Sidebar.BackgroundColor3 = th.Sidebar end
    if MainBorder then
        MainBorder.Color = th.Border
        MainBorder.Thickness = th.StrokeThick
    end
    if OpenBtn then
        OpenBtn.BackgroundColor3 = th.Accent
        OpenBtn.TextColor3 = th.Background
    end

    for _, obj in ipairs({Main, Header, Sidebar}) do
        if obj then
            local c = obj:FindFirstChildOfClass("UICorner")
            if c then c.CornerRadius = UDim.new(0, th.Corner) end
        end
    end

    ClearThemeDecor()
    ThemeDecor = Instance.new("Folder")
    ThemeDecor.Name = "ThemeDecor"
    ThemeDecor.Parent = Main

    if name == "Galaxy" then
        -- soft nebula gradient bar under header
        local neb = Instance.new("Frame")
        neb.Size = UDim2.new(1, 0, 0, 3)
        neb.Position = UDim2.fromOffset(0, 52)
        neb.BorderSizePixel = 0
        neb.BackgroundColor3 = th.Accent
        neb.ZIndex = 15
        neb.Parent = ThemeDecor
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 40, 160)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 160, 255)),
        })
        g.Parent = neb
        -- floating star dots
        for i = 1, 12 do
            local s = Instance.new("Frame")
            s.Size = UDim2.fromOffset(2, 2)
            s.Position = UDim2.new(math.random(), 0, math.random(), 0)
            s.BackgroundColor3 = Color3.fromRGB(220, 210, 255)
            s.BackgroundTransparency = 0.3
            s.BorderSizePixel = 0
            s.ZIndex = 15
            s.Parent = ThemeDecor
            Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
            task.spawn(function()
                while s.Parent do
                    TweenService:Create(s, TweenInfo.new(1.5 + math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                        BackgroundTransparency = 0.8
                    }):Play()
                    task.wait(2)
                end
            end)
        end
        -- elegant side accent line
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 2, 1, -60)
        line.Position = UDim2.fromOffset(128, 58)
        line.BackgroundColor3 = th.Accent
        line.BackgroundTransparency = 0.5
        line.BorderSizePixel = 0
        line.ZIndex = 15
        line.Parent = ThemeDecor

    elseif name == "Lego" then
        -- stud row under header (Lego bumps)
        local studBar = Instance.new("Frame")
        studBar.Size = UDim2.new(1, -20, 0, 14)
        studBar.Position = UDim2.fromOffset(10, 54)
        studBar.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
        studBar.BorderSizePixel = 0
        studBar.ZIndex = 15
        studBar.Parent = ThemeDecor
        Instance.new("UICorner", studBar).CornerRadius = UDim.new(0, 2)
        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Horizontal
        list.Padding = UDim.new(0, 6)
        list.Parent = studBar
        for i = 1, 14 do
            local stud = Instance.new("Frame")
            stud.Size = UDim2.fromOffset(10, 10)
            stud.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
            stud.BorderSizePixel = 0
            stud.LayoutOrder = i
            stud.Parent = studBar
            Instance.new("UICorner", stud).CornerRadius = UDim.new(1, 0)
        end
        -- thick colored sidebar stripe
        local stripe = Instance.new("Frame")
        stripe.Size = UDim2.new(0, 6, 1, -70)
        stripe.Position = UDim2.fromOffset(0, 60)
        stripe.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        stripe.BorderSizePixel = 0
        stripe.ZIndex = 15
        stripe.Parent = ThemeDecor

    elseif name == "Ramadhan" then
        -- gold top line
        local gold = Instance.new("Frame")
        gold.Size = UDim2.new(1, 0, 0, 3)
        gold.Position = UDim2.fromOffset(0, 52)
        gold.BackgroundColor3 = th.Accent
        gold.BorderSizePixel = 0
        gold.ZIndex = 15
        gold.Parent = ThemeDecor
        local gg = Instance.new("UIGradient")
        gg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 100, 60)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(218, 175, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 100, 60)),
        })
        gg.Parent = gold
        -- crescent + ketupat labels (text decor)
        local decor = Instance.new("TextLabel")
        decor.Size = UDim2.new(1, -20, 0, 18)
        decor.Position = UDim2.fromOffset(10, Main.AbsoluteSize.Y > 0 and 0 or 0)
        decor.Position = UDim2.new(0, 140, 1, -22)
        decor.BackgroundTransparency = 1
        decor.Text = "✦  Ramadhan Mubarak  ✦  Ketupat · Kurma · Berkah"
        decor.TextColor3 = th.Accent
        decor.Font = Enum.Font.Gotham
        decor.TextSize = 10
        decor.ZIndex = 16
        decor.Parent = ThemeDecor
        -- soft lantern dots
        for i = 1, 5 do
            local lan = Instance.new("Frame")
            lan.Size = UDim2.fromOffset(6, 8)
            lan.Position = UDim2.new(0.15 + i * 0.12, 0, 0, 56)
            lan.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
            lan.BackgroundTransparency = 0.2
            lan.BorderSizePixel = 0
            lan.ZIndex = 15
            lan.Parent = ThemeDecor
            Instance.new("UICorner", lan).CornerRadius = UDim.new(0, 3)
        end

    else -- Modern
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 2)
        bar.Position = UDim2.fromOffset(0, 52)
        bar.BackgroundColor3 = th.Accent
        bar.BorderSizePixel = 0
        bar.ZIndex = 15
        bar.Parent = ThemeDecor
        local mg = Instance.new("UIGradient")
        mg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, th.Accent),
            ColorSequenceKeypoint.new(1, th.Accent2),
        })
        mg.Parent = bar
        -- pulse accent
        task.spawn(function()
            while bar.Parent do
                TweenService:Create(bar, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    BackgroundTransparency = 0.4
                }):Play()
                task.wait(1.3)
            end
        end)
    end

    Notify("THEME", name .. " applied")
end


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
B.Main, B.MainBorder, B.MainScale = Main, MainBorder, MainScale

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
B.Header, B.Sidebar = Header, Sidebar
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
    local profile = Card("PLAYER PROFILE", "Welcome to cyber workspace", 150)
    local av = New("ImageLabel", {Position=UDim2.fromOffset(12,48), Size=UDim2.fromOffset(64,64), BackgroundColor3=T.Element, BorderSizePixel=0, ZIndex=13}, profile)
    Round(av, 14)
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and av.Parent then av.Image = img end
    end)
    New("TextLabel", {Position=UDim2.fromOffset(88,52), Size=UDim2.new(1,-100,0,20), BackgroundTransparency=1, Text=LocalPlayer.DisplayName, TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, profile)
    New("TextLabel", {Position=UDim2.fromOffset(88,74), Size=UDim2.new(1,-100,0,16), BackgroundTransparency=1, Text="@"..LocalPlayer.Name.."  ·  SESSION ACTIVE", TextColor3=T.Accent, Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, profile)
    New("TextLabel", {Position=UDim2.fromOffset(88,96), Size=UDim2.new(1,-100,0,14), BackgroundTransparency=1, Text="Key Active · Premium Client", TextColor3=T.Muted, Font=Enum.Font.Code, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, profile)
    local line = New("Frame", {Position=UDim2.fromOffset(12,128), Size=UDim2.new(1,-24,0,2), BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=13}, profile)

    local perf = Card("LIVE STATS", "Real-time client", 90)
    local st = New("TextLabel", {Position=UDim2.fromOffset(12,48), Size=UDim2.new(1,-24,0,30), BackgroundTransparency=1, Text="FPS: -- | Players: -- | Time: 00:00", TextColor3=T.Accent, Font=Enum.Font.Code, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, perf)
    B.StatsLabel = st

    local status = Card("MODULE STATUS", "Active systems", 110)
    local ms = New("TextLabel", {Position=UDim2.fromOffset(12,48), Size=UDim2.new(1,-24,0,50), BackgroundTransparency=1, Text="Aim OFF | ESP OFF | Brutal idle\nVIP tab removed · Troll ready", TextColor3=T.Muted, Font=Enum.Font.Code, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, ZIndex=13}, status)
    B.HomeModuleStatus = ms

    local quick = Card("QUICK ACCESS", "Shortcuts", 80)
    Action(quick, 42, "System notification", function() Notify("BAXTARA", "Dashboard OK · Avatar loaded") end)
end

PageBuilders.ESP = function()
    ClearContent()
    local S = B.Settings.ESP
    local c = Card("ESP SETTINGS", "Player visuals", 360)
    Toggle(c, 42, "Enable ESP", "Master toggle", S.Enabled, function(v) B.Settings.ESP.Enabled=v end)
    Toggle(c, 78, "Box ESP", "Full body box", S.Box, function(v) B.Settings.ESP.Box=v end)
    Toggle(c, 114, "Name", "Player names", S.Name, function(v) B.Settings.ESP.Name=v end)
    Toggle(c, 150, "Health Bar", "HP bar", S.HealthBar, function(v) B.Settings.ESP.HealthBar=v end)
    Toggle(c, 186, "Distance", "Range text", S.Distance, function(v) B.Settings.ESP.Distance=v end)
    Toggle(c, 222, "Tracer Line", "Line to target", S.Tracer, function(v) B.Settings.ESP.Tracer=v end)
    Toggle(c, 258, "Skeleton ESP", "Bone lines", S.Skeleton, function(v) B.Settings.ESP.Skeleton=v end)
    Toggle(c, 294, "Visible Check", "Green/red", S.VisibleCheck, function(v) B.Settings.ESP.VisibleCheck=v end)
    Toggle(c, 330, "NPC / Bot ESP", "Non-player characters", S.NPCESP, function(v) B.Settings.ESP.NPCESP=v end)
    local tr = Card("TRACER ORIGIN", "Where line starts", 160)
    Action(tr, 42, "Origin: Bottom", function() B.Settings.ESP.TracerOrigin="Bottom"; Notify("ESP","Tracer Bottom") end)
    Action(tr, 74, "Origin: Center (crosshair)", function() B.Settings.ESP.TracerOrigin="Center"; Notify("ESP","Tracer Center") end)
    Action(tr, 106, "Origin: Top", function() B.Settings.ESP.TracerOrigin="Top"; Notify("ESP","Tracer Top") end)
    Action(tr, 138, "Origin: Left / Right edge", function()
        B.Settings.ESP.TracerOrigin = (B.Settings.ESP.TracerOrigin=="Left") and "Right" or "Left"
        Notify("ESP","Tracer "..B.Settings.ESP.TracerOrigin)
    end)
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
    local c = Card("AIM SETTINGS", "Aimbot system", 430)
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
    Toggle(c, 366, "Aim NPC / Bot", "Target non-players", S.AimNPC, function(v) B.Settings.Aim.AimNPC=v end)
    local c2 = Card("FOV / SMOOTH", "Values", 120)
    Slider(c2, 42, "FOV Size", 40, 1000, S.FOV, function(v) B.Settings.Aim.FOV=v end)
    Slider(c2, 88, "Smooth x100", 5, 40, math.floor(S.AimSmoothing*100), function(v) B.Settings.Aim.AimSmoothing=v/100 end)
end

PageBuilders.Brutal = function()
    ClearContent()
    local S = B.Settings.Brutal
    local c = Card("MOVEMENT", "Fly speed noclip god ghost", 380)
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
        if hum then if v then B.OriginalWalkSpeed=hum.WalkSpeed; hum.WalkSpeed=math.clamp(B.Settings.Brutal.SpeedValue,16,100) else hum.WalkSpeed=B.OriginalWalkSpeed or 16 end end
    end)
    Slider(c, 158, "Walk Speed", 16, 100, S.SpeedValue, function(v) B.Settings.Brutal.SpeedValue=v if B.Settings.Brutal.SpeedHack then local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=v end end end)
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
    Toggle(c, 272, "God Mode", "Local invincible (best effort)", S.GodMode, function(v)
        B.Settings.Brutal.GodMode = v
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if v then
                B._GodConn = hum.HealthChanged:Connect(function()
                    if B.Settings.Brutal.GodMode and hum.Health < hum.MaxHealth then
                        hum.Health = hum.MaxHealth
                    end
                end)
                hum.Health = hum.MaxHealth
                AddConn(B._GodConn)
            end
        end
    end)
    Toggle(c, 308, "Ghost Mode", "Local invisible", S.GhostMode, function(v)
        B.Settings.Brutal.GhostMode = v
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.LocalTransparencyModifier = v and 1 or 0
            elseif p:IsA("Decal") then
                p.Transparency = v and 1 or 0
            end
        end
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

    local fk = Card("FLY KILL ALL", "Fly up + TP enemies + shoot", 100)
    Toggle(fk, 42, "Fly Kill All", "Hover + pull enemies + auto fire", S.FlyKillAll, function(v)
        B.Settings.Brutal.FlyKillAll = v
        if not v then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            if B.FlyKillBV then pcall(function() B.FlyKillBV:Destroy() end) B.FlyKillBV = nil end
        end
    end)

    local sp = Card("SPIN BOT", "Character spin (free)", 100)
    Toggle(sp, 42, "Spin Bot", "Rotate character", S.SpinBot, function(v) B.Settings.Brutal.SpinBot = v end)
    Slider(sp, 78, "Spin Speed 1-120", 1, 120, S.SpinSpeed or 40, function(v) B.Settings.Brutal.SpinSpeed = v end)
end

PageBuilders.LocalCfg = function()
    ClearContent()
    local S = B.Settings.LocalCfg
    local sky = Card("SKY HACKER", "Bright matrix sky + logo on clouds", 110)
    Toggle(sky, 42, "Hacker Sky ON", "Bright green matrix style", S.SkyBAXTARA, function(v)
        B.Settings.LocalCfg.SkyBAXTARA = v
        if B.SkyFolder then pcall(function() B.SkyFolder:Destroy() end) B.SkyFolder=nil end
        if v then
            B.SkyFolder = Instance.new("Folder")
            B.SkyFolder.Name = "BAXTARA_SKY"
            B.SkyFolder.Parent = Workspace
            -- bright hacker lighting
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(40, 80, 50)
            Lighting.OutdoorAmbient = Color3.fromRGB(60, 120, 70)
            Lighting.FogColor = Color3.fromRGB(20, 60, 40)
            Lighting.FogEnd = 2000
            Lighting.ClockTime = 14
            -- soft logos high in sky (not blocking view)
            local root = GetRoot(LocalPlayer.Character)
            local base = root and root.Position or Vector3.new(0, 0, 0)
            -- cover sky with grid of logos + color atmosphere
            local positions = {}
            for ring = 1, 3 do
                local n = 6 + ring * 2
                local rad = 80 + ring * 70
                local h = 60 + ring * 40
                for i = 1, n do
                    local ang = (i/n) * math.pi * 2
                    table.insert(positions, Vector3.new(base.X + math.cos(ang)*rad, h, base.Z + math.sin(ang)*rad))
                end
            end
            -- top center
            table.insert(positions, Vector3.new(base.X, 160, base.Z))
            for _, pos in ipairs(positions) do
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 1
                part.Size = Vector3.new(1,1,1)
                part.CFrame = CFrame.new(pos)
                part.Parent = B.SkyFolder
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.fromOffset(280, 36)
                bb.MaxDistance = 4000
                bb.AlwaysOnTop = false
                bb.Parent = part
                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.fromScale(1,1)
                tl.BackgroundTransparency = 1
                tl.Text = "BAXTARA X CHEAT"
                tl.TextColor3 = Color3.fromRGB(0, 255, 130)
                tl.TextTransparency = 0.25
                tl.TextStrokeColor3 = Color3.fromRGB(0, 40, 20)
                tl.TextStrokeTransparency = 0.5
                tl.Font = Enum.Font.GothamBlack
                tl.TextScaled = true
                tl.Parent = bb
            end
            -- atmosphere color (covers sky look)
            pcall(function()
                local sky = Lighting:FindFirstChildOfClass("Sky")
                if not sky then
                    sky = Instance.new("Sky")
                    sky.Parent = Lighting
                end
                sky.SkyboxBk = ""
                sky.SkyboxDn = ""
                sky.SkyboxFt = ""
                sky.SkyboxLf = ""
                sky.SkyboxRt = ""
                sky.SkyboxUp = ""
                sky.CelestialBodiesShown = false
            end)
            Lighting.FogColor = Color3.fromRGB(10, 40, 25)
            Lighting.FogStart = 0
            Lighting.FogEnd = 800
        else
            Lighting.Brightness = 1
            Lighting.FogEnd = 100000
        end
    end)
    Action(sky, 78, "Refresh sky logos", function()
        if B.Settings.LocalCfg.SkyBAXTARA then
            local t = true
            B.Settings.LocalCfg.SkyBAXTARA = false
            if B.SkyFolder then pcall(function() B.SkyFolder:Destroy() end) end
            task.wait(0.05)
            -- re-fire by toggling logic: user can toggle again; quick rebuild:
            B.Settings.LocalCfg.SkyBAXTARA = true
            Notify("SKY", "Refreshed")
        end
    end)

    local tag = Card("SELF NAME TAG", "Tag di Avatar kamu", 150)
    Toggle(tag, 42, "Enable Self Tag", "Billboard di atas kepala", S.SelfTag, function(v)
        B.Settings.LocalCfg.SelfTag = v
        if not v and B.SelfTagGui then pcall(function() B.SelfTagGui:Destroy() end) B.SelfTagGui=nil end
    end)
    Action(tag, 78, "Text: BAXTARA", function() B.Settings.LocalCfg.SelfTagText="BAXTARA"; Notify("TAG","BAXTARA") end)
    Action(tag, 110, "Rainbow / Gold toggle", function()
        B.Settings.LocalCfg.SelfTagRainbow = not B.Settings.LocalCfg.SelfTagRainbow
        Notify("TAG", B.Settings.LocalCfg.SelfTagRainbow and "Rainbow" or "Gold")
    end)

    local chat = Card("SERVER CHAT (bubble)", "Custom bubble di atas kepala", 120)
    Toggle(chat, 42, "Show Chat Bubble", "Teks bubble lokal", S.ServerChat, function(v)
        B.Settings.LocalCfg.ServerChat = v
        if not v and B.ChatBubble then pcall(function() B.ChatBubble:Destroy() end) B.ChatBubble=nil end
    end)
    Action(chat, 78, "Set bubble: Hello BAXTARA", function()
        B.Settings.LocalCfg.ChatBubbleText = "Hello BAXTARA"
        B.Settings.LocalCfg.ServerChat = true
        Notify("CHAT", "Bubble set")
    end)

    local un = Card("UNLOCK / RANK", "Best-effort client", 140)
    Toggle(un, 42, "Unlock Passes attempt", "Scan attributes/values", S.UnlockPasses, function(v)
        B.Settings.LocalCfg.UnlockPasses = v
        if v then
            for _, obj in ipairs(LocalPlayer:GetDescendants()) do
                if obj:IsA("BoolValue") then
                    local n = obj.Name:lower()
                    if n:find("vip") or n:find("pass") or n:find("premium") or n:find("gamepass") or n:find("owned") then
                        pcall(function() obj.Value = true end)
                    end
                end
            end
            pcall(function()
                LocalPlayer:SetAttribute("VIP", true)
                LocalPlayer:SetAttribute("Premium", true)
                LocalPlayer:SetAttribute("HasPass", true)
            end)
            Notify("UNLOCK", "Pass attributes forced (client)")
        end
    end)
    Toggle(un, 78, "Auto Rank / Level attempt", "Bump level values", S.AutoRank, function(v)
        B.Settings.LocalCfg.AutoRank = v
    end)
    Action(un, 114, "Force +50 Level once", function()
        for _, obj in ipairs(LocalPlayer:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local n = obj.Name:lower()
                if n:find("level") or n:find("rank") or n:find("xp") then
                    pcall(function() obj.Value = obj.Value + 50 end)
                end
            end
        end
        Notify("RANK", "Level/XP +50 attempt")
    end)

    local plist = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(plist, p) end
    end
    local tpH = 90 + math.min(#plist, 8) * 44
    local tp = Card("TELEPORT PLAYERS", "Klik nama + avatar untuk TP", math.max(tpH, 140))
    Action(tp, 42, "TP ALL in front", function()
        local my = GetRoot(LocalPlayer.Character)
        if not my then return end
        local front = my.CFrame * CFrame.new(0,0,-10)
        local i=0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local r = GetRoot(GetChar(p))
                if r then i=i+1; pcall(function() r.CFrame = front * CFrame.new((i%4)*3-4,0,math.floor(i/4)*3) end) end
            end
        end
        Notify("TP","All front")
    end)
    local y = 74
    for idx, plr in ipairs(plist) do
        if idx > 8 then break end
        local row = New("Frame", {Position=UDim2.fromOffset(10,y), Size=UDim2.new(1,-20,0,40), BackgroundColor3=T.Element, BorderSizePixel=0, ZIndex=13}, tp)
        Round(row, 8)
        local img = New("ImageLabel", {Position=UDim2.fromOffset(4,4), Size=UDim2.fromOffset(32,32), BackgroundColor3=T.Off, BorderSizePixel=0, ZIndex=14}, row)
        Round(img, 6)
        task.spawn(function()
            local ok, url = pcall(function()
                return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and img.Parent then img.Image = url end
        end)
        New("TextLabel", {Position=UDim2.fromOffset(42,4), Size=UDim2.new(1,-100,0,18), BackgroundTransparency=1, Text=plr.DisplayName, TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, row)
        New("TextLabel", {Position=UDim2.fromOffset(42,20), Size=UDim2.new(1,-100,0,14), BackgroundTransparency=1, Text="@"..plr.Name, TextColor3=T.Muted, Font=Enum.Font.Code, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, row)
        local tpb = New("TextButton", {Position=UDim2.new(1,-54,0.5,-12), Size=UDim2.fromOffset(48,24), BackgroundColor3=T.Accent, Text="TP", TextColor3=T.Background, Font=Enum.Font.GothamBold, TextSize=10, ZIndex=14, AutoButtonColor=false}, row)
        Round(tpb, 6)
        tpb.MouseButton1Click:Connect(function()
            local my = GetRoot(LocalPlayer.Character)
            local r = GetRoot(GetChar(plr))
            if my and r then
                my.CFrame = r.CFrame * CFrame.new(0, 0, 3)
                Notify("TP", "→ "..plr.DisplayName)
            else
                Notify("TP", "Player not available")
            end
        end)
        y = y + 44
    end
    if #plist == 0 then
        New("TextLabel", {Position=UDim2.fromOffset(12,74), Size=UDim2.new(1,-24,0,20), BackgroundTransparency=1, Text="No other players in server", TextColor3=T.Muted, Font=Enum.Font.Gotham, TextSize=10, ZIndex=13}, tp)
    end

    local fr = Card("FREEZE / LAG", "Others", 100)
    Toggle(fr, 42, "Freeze All Others", "Anchor HRP", S.FreezeOthers, function(v)
        B.Settings.LocalCfg.FreezeOthers = v
        if not v then
            for _, root in pairs(B.FrozenParts) do pcall(function() if root and root.Parent then root.Anchored=false end end) end
            B.FrozenParts = {}
        end
    end)
    Toggle(fr, 78, "Anti Lag Self", "Low quality", S.AntiLagSelf, function(v)
        B.Settings.LocalCfg.AntiLagSelf = v
        pcall(function() settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic end)
    end)
end

PageBuilders.Settings = function()
    ClearContent()
    local th = Card("TAMPILAN PANEL", "Pilih tema UI premium", 220)
    Action(th, 42, "✦  GALAKSI — elegan ungu bintang", function() ApplyTheme("Galaxy") end)
    Action(th, 74, "■  LEGO — kotak Roblox stud", function() ApplyTheme("Lego") end)
    Action(th, 106, "☪  RAMADHAN — emas & hijau", function() ApplyTheme("Ramadhan") end)
    Action(th, 138, "◆  MODERN — cyan default polish", function() ApplyTheme("Modern") end)
    New("TextLabel", {
        Position = UDim2.fromOffset(12, 175),
        Size = UDim2.new(1, -24, 0, 30),
        BackgroundTransparency = 1,
        Text = "Tema mengubah warna, sudut, border & dekor panel.",
        TextColor3 = T.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 13,
    }, th)

    local pr = Card("PROTECT", "Anti kick / hop", 140)
    Toggle(pr, 42, "Anti-Kick Watch", "Detect kick UI", B.Settings.Protect.AntiKick, function(v) B.Settings.Protect.AntiKick=v end)
    Toggle(pr, 78, "Auto Hop on Flag", "Teleport on detect", B.Settings.Protect.AutoHopOnFlag, function(v) B.Settings.Protect.AutoHopOnFlag=v end)
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
    if B.Settings.Aim.AimNPC then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
                if hum and head and hum.Health > 0 then
                    local dist = DistTo(head.Position)
                    if dist <= B.Settings.Aim.AimDistance then
                        local screen, on = WorldToScreen(head.Position)
                        if on then
                            local cross = (screen - center).Magnitude
                            if cross <= fov and cross < bestScore then
                                bestScore = cross
                                best = {NPC=true, Part=head, Model=obj}
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
    if type(target) == "table" and target.NPC then
        local part = target.Part
        if not part then return end
        local pos = part.Position
        local smooth = B.Settings.Aim.AimSmoothing
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pos), smooth)
        return
    end
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
            local origin = bottom
            local vp = Camera.ViewportSize
            local org = B.Settings.ESP.TracerOrigin or "Bottom"
            if org == "Center" then origin = Vector2.new(vp.X/2, vp.Y/2)
            elseif org == "Top" then origin = Vector2.new(vp.X/2, 10)
            elseif org == "Left" then origin = Vector2.new(10, vp.Y/2)
            elseif org == "Right" then origin = Vector2.new(vp.X-10, vp.Y/2)
            else origin = Vector2.new(vp.X/2, vp.Y)
            end
            pack.Tracer.From=origin; pack.Tracer.To=rootS; pack.Tracer.Color=B.Settings.ESP.TracerColor; pack.Tracer.Visible=on
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
    -- NPC ESP
    if B.Settings.ESP.NPCESP then
        B.NPCDraw = B.NPCDraw or {}
        local used = {}
        local my = GetRoot(LocalPlayer.Character)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if hum and root and hum.Health > 0 then
                    local dist = my and (my.Position-root.Position).Magnitude or 999
                    if dist <= B.Settings.ESP.MaxDistance then
                        local id = obj:GetFullName()
                        used[id] = true
                        if not B.NPCDraw[id] then
                            local t = Drawing.new("Text")
                            t.Size = 12; t.Center = true; t.Outline = true
                            B.NPCDraw[id] = t
                        end
                        local sp, on = WorldToScreen(root.Position + Vector3.new(0, 2, 0))
                        local d = B.NPCDraw[id]
                        d.Text = string.format("[NPC] %s [%dm]", obj.Name, math.floor(dist))
                        d.Position = sp
                        d.Color = Color3.fromRGB(255, 180, 50)
                        d.Visible = on
                    end
                end
            end
        end
        for id, d in pairs(B.NPCDraw) do
            if not used[id] then pcall(function() d:Remove() end); B.NPCDraw[id]=nil end
        end
    elseif B.NPCDraw then
        for id, d in pairs(B.NPCDraw) do pcall(function() d:Remove() end) end
        B.NPCDraw = {}
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
    if B.Settings.Brutal.FlyKillAll then B.DoFlyKillAll() end
    if B.Settings.Brutal.SpinBot then B.DoSpinBot() end
    if B.EnsureSelfTag then B.EnsureSelfTag() end
    -- Speed fix: reapply every heartbeat so server reset does not stick
    if B.Settings.Brutal.SpeedHack then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local sp = math.clamp(B.Settings.Brutal.SpeedValue or 24, 16, 100)
            if hum.WalkSpeed < sp - 1 then hum.WalkSpeed = sp end
        end
    end
    if B.Settings.Brutal.GodMode then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end
    if B.Settings.LocalCfg.ServerChat then
        local head = GetHead(LocalPlayer.Character)
        if head then
            if not B.ChatBubble or not B.ChatBubble.Parent then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.fromOffset(180, 50)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true
                bb.Parent = head
                local f = Instance.new("Frame")
                f.Size = UDim2.fromScale(1,1)
                f.BackgroundColor3 = Color3.fromRGB(255,255,255)
                f.Parent = bb
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
                local tl = Instance.new("TextLabel")
                tl.Name = "Msg"
                tl.Size = UDim2.new(1,-8,1,-4)
                tl.Position = UDim2.fromOffset(4,2)
                tl.BackgroundTransparency = 1
                tl.Text = B.Settings.LocalCfg.ChatBubbleText or "Hello BAXTARA"
                tl.TextColor3 = Color3.fromRGB(30,30,30)
                tl.Font = Enum.Font.Gotham
                tl.TextScaled = true
                tl.Parent = f
                B.ChatBubble = bb
            else
                local msg = B.ChatBubble:FindFirstChild("Msg", true)
                if msg then msg.Text = B.Settings.LocalCfg.ChatBubbleText or "Hello BAXTARA" end
            end
        end
    end
    if B.Settings.LocalCfg.AutoRank and tick() % 5 < 0.05 then
        for _, obj in ipairs(LocalPlayer:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local n = obj.Name:lower()
                if n:find("level") or n:find("xp") then pcall(function() obj.Value = obj.Value + 1 end) end
            end
        end
    end
    if B.HomeModuleStatus then
        B.HomeModuleStatus.Text = string.format("Aim %s | ESP %s | Speed %s\nGod %s | Ghost %s | Spin %s",
            B.Settings.Aim.Enabled and "ON" or "OFF",
            B.Settings.ESP.Enabled and "ON" or "OFF",
            B.Settings.Brutal.SpeedHack and "ON" or "OFF",
            B.Settings.Brutal.GodMode and "ON" or "OFF",
            B.Settings.Brutal.GhostMode and "ON" or "OFF",
            B.Settings.Brutal.SpinBot and "ON" or "OFF")
    end
    -- VIP Kill Aura
    if B.Settings.VIP.Unlocked and B.Settings.VIP.KillAura then
        local my = GetRoot(LocalPlayer.Character)
        if my then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and TeamOK(p) then
                    local char = GetChar(p)
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = GetRoot(char)
                    if hum and root and (my.Position - root.Position).Magnitude < 25 then
                        pcall(function() hum:TakeDamage(5) end)
                    end
                end
            end
        end
    end
    -- VIP Magic bullet = force silent + aim
    if B.Settings.VIP.Unlocked and B.Settings.VIP.MagicBullet then
        B.Settings.Aim.SilentAim = true
        local t = GetNearestEnemy()
        if t then AimAt(t) end
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end
    -- Fake disconnect visual
    if B.Settings.VIP.Unlocked and B.Settings.VIP.FakeDisconnect then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local r = GetRoot(GetChar(p))
                if r then pcall(function() r.Anchored = true end) end
            end
        end
    end
    -- Gold ESP override
    if B.Settings.VIP.Unlocked and B.Settings.VIP.GoldESP then
        B.Settings.ESP.VisibleColor = Color3.fromRGB(255, 215, 0)
        B.Settings.ESP.BoxColor = Color3.fromRGB(255, 200, 50)
        B.Settings.ESP.TracerColor = Color3.fromRGB(255, 220, 80)
    end
    -- Aura particle
    if B.Settings.VIP.Unlocked and B.Settings.VIP.AuraParticle then
        local root = GetRoot(LocalPlayer.Character)
        if root and (not B.AuraPart or not B.AuraPart.Parent) then
            local a = Instance.new("Part")
            a.Name = "BX_Aura"
            a.Shape = Enum.PartType.Ball
            a.Size = Vector3.new(6, 6, 6)
            a.Transparency = 0.7
            a.Color = Color3.fromRGB(255, 200, 50)
            a.Material = Enum.Material.ForceField
            a.CanCollide = false
            a.Massless = true
            a.Anchored = false
            a.Parent = LocalPlayer.Character
            local w = Instance.new("Weld")
            w.Part0 = root
            w.Part1 = a
            w.Parent = a
            B.AuraPart = a
        end
    elseif B.AuraPart then
        pcall(function() B.AuraPart:Destroy() end)
        B.AuraPart = nil
    end
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
    -- IGNORE our own panel (Troll fake ban text was triggering hop)
    if obj:IsDescendantOf(ScreenGui) then return end
    local p = obj.Parent
    while p do
        if p.Name == "BAXTARA_X_CHEAT" or p.Name == "VIPPanel" then return end
        if p == ScreenGui then return end
        p = p.Parent
    end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local t=(obj.Text or ""):lower()
        if t:find("suspicious") or t:find("banned") or t:find("exploiting") or t:find("kicked") or t:find("timedout") or t:find("dikeluarkan") then
            if B.Settings.Protect.AutoHopOnFlag then
                task.delay(0.5, function()
                    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                end)
            end
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
B.OpenBtn = OpenBtn
OpenBtn.MouseButton1Click:Connect(function() if Main.Visible then HidePanel() else ShowPanel() end end)


-- ========== VIP PANEL + SYSTEMS ==========
B.FlyKillBV = nil
B.SelfTagGui = nil
B.VIPPanel = nil
B.SpinAngle = 0
B.VIPChatMessages = {}

function B.EnsureSelfTag()
    if not B.Settings.LocalCfg.SelfTag then
        if B.SelfTagGui then pcall(function() B.SelfTagGui:Destroy() end) B.SelfTagGui=nil end
        return
    end
    local char = LocalPlayer.Character
    local head = char and GetHead(char)
    if not head then return end
    if not B.SelfTagGui or not B.SelfTagGui.Parent then
        local bb = Instance.new("BillboardGui")
        bb.Name = "BX_SelfTag"
        bb.Size = UDim2.fromOffset(200, 40)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 200
        bb.Parent = head
        local tl = Instance.new("TextLabel")
        tl.Name = "Tag"
        tl.Size = UDim2.fromScale(1,1)
        tl.BackgroundTransparency = 1
        tl.Text = B.Settings.LocalCfg.SelfTagText or "BAXTARA"
        tl.Font = Enum.Font.GothamBlack
        tl.TextScaled = true
        tl.TextStrokeTransparency = 0.4
        tl.Parent = bb
        B.SelfTagGui = bb
    end
    local tl = B.SelfTagGui:FindFirstChild("Tag")
    if tl then
        tl.Text = B.Settings.LocalCfg.SelfTagText or "BAXTARA"
        if B.Settings.LocalCfg.SelfTagRainbow then
            local h = (tick() * 0.4) % 1
            tl.TextColor3 = Color3.fromHSV(h, 1, 1)
        else
            tl.TextColor3 = Color3.fromRGB(255, 215, 0)
        end
    end
end

function B.DoFlyKillAll()
    if not B.Settings.Brutal.FlyKillAll then return end
    local char = LocalPlayer.Character
    local root = char and GetRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true
    if not B.FlyKillBV or not B.FlyKillBV.Parent then
        if B.FlyKillBV then pcall(function() B.FlyKillBV:Destroy() end) end
        B.FlyKillBV = Instance.new("BodyVelocity")
        B.FlyKillBV.MaxForce = Vector3.new(9e4, 9e4, 9e4)
        B.FlyKillBV.Velocity = Vector3.zero
        B.FlyKillBV.Parent = root
    end
    -- hover high
    local hover = root.Position + Vector3.new(0, 2, 0)
    if root.Position.Y < (Workspace.FallenPartsDestroyHeight + 500) then
        -- lift to ~40 studs above current ground-ish
        B.FlyKillBV.Velocity = Vector3.new(0, 35, 0)
        if root.Position.Y > 80 then
            B.FlyKillBV.Velocity = Vector3.zero
        end
    end
    -- TP enemies in front
    local front = root.CFrame * CFrame.new(0, 0, -12)
    local i = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and TeamOK(p) then
            local er = GetRoot(GetChar(p))
            if er and IsAlive(GetChar(p)) then
                i = i + 1
                pcall(function()
                    er.CFrame = front * CFrame.new((i % 4) * 3 - 4.5, 0, math.floor(i / 4) * 3)
                end)
            end
        end
    end
    -- auto shoot
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
end

function B.DoSpinBot()
    if not B.Settings.Brutal.SpinBot then return end
    local root = GetRoot(LocalPlayer.Character)
    if not root then return end
    local spd = math.clamp(B.Settings.Brutal.SpinSpeed or 40, 1, 120)
    B.SpinAngle = (B.SpinAngle + spd * 0.05) % 360
    local pos = root.Position
    root.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(B.SpinAngle), 0)
end

-- VIP Panel builder
function B.OpenVIPPanel()
    if B.VIPPanel and B.VIPPanel.Parent then
        B.VIPPanel.Visible = true
        return
    end
    local vp = New("Frame", {
        Name = "VIPPanel",
        Size = UDim2.fromOffset(420, 480),
        Position = UDim2.new(0.5, -210, 0.5, -240),
        BackgroundColor3 = Color3.fromRGB(8, 6, 18),
        BorderSizePixel = 0,
        ZIndex = 40,
        ClipsDescendants = true,
    }, ScreenGui)
    Round(vp, 14)
    local vst = New("UIStroke", {Color = Color3.fromRGB(255, 200, 50), Thickness = 1.5, Transparency = 0.2}, vp)
    -- gold pulse
    task.spawn(function()
        while vp.Parent do
            TweenService:Create(vst, TweenInfo.new(1.2), {Color = Color3.fromRGB(255, 230, 120)}):Play()
            task.wait(1.2)
            if not vp.Parent then break end
            TweenService:Create(vst, TweenInfo.new(1.2), {Color = Color3.fromRGB(255, 180, 40)}):Play()
            task.wait(1.2)
        end
    end)

    local vh = New("Frame", {Size = UDim2.new(1,0,0,44), BackgroundColor3 = Color3.fromRGB(20, 14, 40), BorderSizePixel = 0, ZIndex = 41}, vp)
    Round(vh, 14)
    New("TextLabel", {Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(280, 20), BackgroundTransparency = 1, Text = "BAXTARA VIP  ·  PREMIUM", TextColor3 = Color3.fromRGB(255, 215, 0), Font = Enum.Font.GothamBlack, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42}, vh)
    New("TextLabel", {Position = UDim2.fromOffset(12, 24), Size = UDim2.fromOffset(200, 14), BackgroundTransparency = 1, Text = "INJECTED MODULE", TextColor3 = Color3.fromRGB(180, 160, 100), Font = Enum.Font.Code, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42}, vh)
    local vclose = New("TextButton", {Position = UDim2.new(1, -36, 0.5, -12), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Color3.fromRGB(60, 20, 30), Text = "X", TextColor3 = Color3.fromRGB(255, 120, 120), Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 42, AutoButtonColor = false}, vh)
    Round(vclose, 6)
    vclose.MouseButton1Click:Connect(function() vp.Visible = false end)

    local scroll = New("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 50),
        Size = UDim2.new(1, -16, 1, -58),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(255, 200, 50),
        CanvasSize = UDim2.new(0,0,0,900),
        ZIndex = 41,
    }, vp)

    local function VCard(title, y, h)
        local c = New("Frame", {Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, -4, 0, h), BackgroundColor3 = Color3.fromRGB(18, 12, 32), BorderSizePixel = 0, ZIndex = 42}, scroll)
        Round(c, 10)
        New("TextLabel", {Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -16, 0, 16), BackgroundTransparency = 1, Text = title, TextColor3 = Color3.fromRGB(255, 210, 80), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43}, c)
        return c
    end
    local function VToggle(parent, y, title, key)
        local row = New("Frame", {Position = UDim2.fromOffset(8, y), Size = UDim2.new(1, -16, 0, 28), BackgroundTransparency = 1, ZIndex = 43}, parent)
        New("TextLabel", {Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = title, TextColor3 = Color3.fromRGB(230, 220, 200), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44}, row)
        local sw = New("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(36, 18), BackgroundColor3 = B.Settings.VIP[key] and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(50, 45, 60), ZIndex = 44}, row)
        Round(sw, 18)
        local dot = New("Frame", {Position = B.Settings.VIP[key] and UDim2.new(1, -16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 45}, sw)
        Round(dot, 12)
        local btn = New("TextButton", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", ZIndex = 46}, sw)
        btn.MouseButton1Click:Connect(function()
            B.Settings.VIP[key] = not B.Settings.VIP[key]
            local on = B.Settings.VIP[key]
            TweenService:Create(sw, TweenInfo.new(0.12), {BackgroundColor3 = on and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(50, 45, 60)}):Play()
            TweenService:Create(dot, TweenInfo.new(0.12), {Position = on and UDim2.new(1, -16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
            if key == "StreamerMode" and on then
                Main.Visible = false
                Notify("VIP", "Streamer Mode — panel hidden (RightCtrl to show main)")
            end
            if key == "RealityWarp" then
                if on then
                    Lighting.Ambient = Color3.fromRGB(255, 0, 200)
                    Lighting.ColorShift_Top = Color3.fromRGB(0, 255, 200)
                    Lighting.Brightness = 3
                else
                    Lighting.Ambient = Color3.fromRGB(140, 140, 140)
                    Lighting.ColorShift_Top = Color3.new(0,0,0)
                    Lighting.Brightness = 1
                end
            end
            if key == "SkyVIP" and on then
                Lighting.ClockTime = 0
                Lighting.Brightness = 1.5
                Lighting.Ambient = Color3.fromRGB(20, 10, 40)
                Lighting.OutdoorAmbient = Color3.fromRGB(40, 20, 80)
            end
        end)
    end

    local c1 = VCard("COMBAT DEWA", 0, 130)
    VToggle(c1, 28, "Magic Bullet / Silent", "MagicBullet")
    VToggle(c1, 56, "Kill Aura", "KillAura")
    VToggle(c1, 84, "Backstab Teleport", "BackstabTP")

    local c2 = VCard("MOVEMENT NINJA", 140, 150)
    VToggle(c2, 28, "Void Walk", "VoidWalk")
    VToggle(c2, 56, "Ninja Dash (press Q)", "NinjaDash")
    VToggle(c2, 84, "Wall Cling", "WallCling")
    VToggle(c2, 112, "Full Fly boost", "VoidWalk") -- alias ok

    local c3 = VCard("TROLL / CHAOS", 300, 150)
    VToggle(c3, 28, "Fake Disconnect (local)", "FakeDisconnect")
    VToggle(c3, 56, "Reality Warp", "RealityWarp")
    VToggle(c3, 84, "Meteor Rain (FX)", "MeteorRain")
    VToggle(c3, 112, "Aura Particle", "AuraParticle")

    local c4 = VCard("KOSMETIK VIP", 460, 130)
    VToggle(c4, 28, "Gold / Rainbow ESP", "GoldESP")
    VToggle(c4, 56, "VIP Sky Night", "SkyVIP")
    VToggle(c4, 84, "Chat Tag [VIP]", "ChatTag")

    local c5 = VCard("STREAMER / UTILITY", 600, 100)
    VToggle(c5, 28, "Streamer Mode (hide UI)", "StreamerMode")
    VToggle(c5, 56, "Spoof Name local", "SpoofName")

    -- VIP CHAT
    local c6 = VCard("VIP GLOBAL CHAT", 710, 160)
    local chatBox = New("TextBox", {Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, 24), BackgroundColor3 = Color3.fromRGB(30, 22, 50), Text = "", PlaceholderText = "Pesan VIP...", PlaceholderColor3 = Color3.fromRGB(120, 100, 140), TextColor3 = Color3.fromRGB(255, 240, 200), Font = Enum.Font.Code, TextSize = 11, ZIndex = 44}, c6)
    Round(chatBox, 6)
    local chatLog = New("TextLabel", {Position = UDim2.fromOffset(8, 58), Size = UDim2.new(1, -16, 0, 70), BackgroundColor3 = Color3.fromRGB(12, 8, 24), Text = "[VIP] Chat lokal aktif.\nSesama BAXTARA di device ini terlihat.", TextColor3 = Color3.fromRGB(200, 180, 120), Font = Enum.Font.Code, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 44}, c6)
    Round(chatLog, 6)
    local sendBtn = New("TextButton", {Position = UDim2.fromOffset(8, 132), Size = UDim2.new(1, -16, 0, 22), BackgroundColor3 = Color3.fromRGB(180, 140, 40), Text = "KIRIM", TextColor3 = Color3.fromRGB(20, 15, 5), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 44, AutoButtonColor = false}, c6)
    Round(sendBtn, 6)
    sendBtn.MouseButton1Click:Connect(function()
        local msg = chatBox.Text
        if msg and #msg > 0 then
            local line = string.format("[%s]: %s", LocalPlayer.Name, msg)
            table.insert(B.VIPChatMessages, line)
            if #B.VIPChatMessages > 8 then table.remove(B.VIPChatMessages, 1) end
            chatLog.Text = table.concat(B.VIPChatMessages, "\n")
            chatBox.Text = ""
            -- try MessagingService for cross-server (may fail on client)
            pcall(function()
                local MS = game:GetService("MessagingService")
                MS:PublishAsync("BAXTARA_VIP_CHAT", {from = LocalPlayer.Name, text = msg})
            end)
        end
    end)
    pcall(function()
        local MS = game:GetService("MessagingService")
        MS:SubscribeAsync("BAXTARA_VIP_CHAT", function(data)
            local p = data.Data
            if p and p.from and p.text then
                table.insert(B.VIPChatMessages, string.format("[%s]: %s", p.from, p.text))
                if #B.VIPChatMessages > 8 then table.remove(B.VIPChatMessages, 1) end
                if chatLog and chatLog.Parent then chatLog.Text = table.concat(B.VIPChatMessages, "\n") end
            end
        end)
    end)

    -- drag VIP panel
    local vd, vs, vp0 = false, nil, nil
    vh.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            vd = true; vs = i.Position; vp0 = vp.Position
        end
    end)
    vh.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then vd = false end
    end)
    AddConn(UserInputService.InputChanged:Connect(function(i)
        if vd and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - vs
            vp.Position = UDim2.new(vp0.X.Scale, vp0.X.Offset + d.X, vp0.Y.Scale, vp0.Y.Offset + d.Y)
        end
    end))

    B.VIPPanel = vp
    -- entry anim
    vp.Size = UDim2.fromOffset(420, 0)
    TweenService:Create(vp, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(420, 480)}):Play()
end

-- Ninja dash key
AddConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not B.Settings.VIP.Unlocked then return end
    if B.Settings.VIP.NinjaDash and input.KeyCode == Enum.KeyCode.Q then
        local root = GetRoot(LocalPlayer.Character)
        if root then
            root.CFrame = root.CFrame + Camera.CFrame.LookVector * 40
        end
    end
    if B.Settings.VIP.BackstabTP and input.KeyCode == Enum.KeyCode.E then
        local best, bd = nil, 999
        local my = GetRoot(LocalPlayer.Character)
        if not my then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local r = GetRoot(GetChar(p))
                if r then
                    local d = (my.Position - r.Position).Magnitude
                    if d < bd then bd = d; best = r end
                end
            end
        end
        if best then
            my.CFrame = best.CFrame * CFrame.new(0, 0, 3)
        end
    end
end))

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
if getgenv().BAXTARA_VIP == true then
    B.Settings.VIP.Unlocked = true
end

print("[BAXTARA X CHEAT] +FlyKillAll +SpinBot +SelfTag +VIP(NUGI) panel/chat")


print("[BAXTARA X CHEAT v5.5] Cyber UI | Safe hitbox | Freeze | Key save | Sky fix | NUGI CENEL")
