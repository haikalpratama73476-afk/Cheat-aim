--[[
    BAXTARA X CHEAT  v5.4
    Developer : NUGI CENEL
    Restore   : all v5.2 features + sidebar UI + LocalConfig + theme + hitbox head/body
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
local InsertService    = game:GetService("InsertService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local DrawingLib  = Drawing

getgenv().BAXTARA = getgenv().BAXTARA or {}
local B = getgenv().BAXTARA

local ACCESS_KEY = "BAXTARA X CHEAT"
local WA_URL = "https://whatsapp.com/channel/0029Vb8PluMLtOj5TTbxRl1k"

-- Popular avatar userIds (public catalog style / known accounts - best effort)
local SULTAN_AVATARS = {
    {name = "Default", id = nil},
    {name = "Guest Classic", id = 1},
    {name = "Roblox", id = 156},
    {name = "Builderman", id = 156},
    {name = "Admin Look", id = 261},
}

B.Settings = {
    Aim = {
        Enabled = false, VisibilityCheck = true, HeadAim = true, BodyAim = false,
        MultiBone = false, FOVCircle = true, AimDistance = 800, AimLock = false,
        AimSmoothing = 0.15, AimPrediction = false, PredictionAmount = 0.12,
        DrawTargetLine = true, FOV = 180, TeamCheck = true,
        SilentAim = false, AntiMiss = false, HitPart = "Head",
    },
    ESP = {
        Enabled = false, Box = true, Name = true, HealthBar = true, Distance = true,
        Tracer = true, Skeleton = false, VisibleCheck = true, PriorityMark = true,
        StatusESP = true, Radar = false, Offscreen = true, MaxDistance = 1000,
        ColorName = "Purple",
        VisibleColor = Color3.fromRGB(180,80,255),
        HiddenColor = Color3.fromRGB(255,80,120),
        PriorityColor = Color3.fromRGB(255,200,50),
        TracerColor = Color3.fromRGB(200,100,255),
        FOVColor = Color3.fromRGB(170,70,255),
        BoxColor = Color3.fromRGB(180,80,255),
    },
    Brutal = {
        Fly = false, FlySpeed = 45, SpeedHack = false, SpeedValue = 24,
        InfiniteJump = false, Noclip = false, SuperJump = false, SuperJumpPower = 80,
        NoFallDamage = false, AirWalk = false, GodMode = false, GhostMode = false,
        HitboxExpand = false, HitboxSize = 8, HitboxPart = "Body", -- Head or Body
        HitboxRedAim = true,
        AntiCooldown = false, InfiniteAmmo = false, AutoReload = false, AutoShoot = false,
        AttackSpeed = false, AttackSpeedVal = 8,
        AutoKill = false, DamageConfig = false, DamageValue = 150,
        OneHitNPC = false, KillAllNPC = false,
    },
    LocalCfg = {
        SkyBAXTARA = false,
        AvatarId = nil,
        ServerLag = false,
        AntiLagSelf = true,
        TPAllFront = false,
    },
    Visual = { FullBright = false, NoFog = false, AntiLag = false, StreamingMode = false },
    Protect = { AntiKick = true, AutoHopOnFlag = true, SoftCamera = true },
    UI = {
        Theme = "Purple", -- Purple / Green / Cyan / Red
        Accent = Color3.fromRGB(160,50,255),
        Background = Color3.fromRGB(10,8,18),
        Card = Color3.fromRGB(18,14,32),
        Width = 740, Height = 500,
    },
}

B.Connections, B.Drawings, B.ESPObjects, B.Highlights = {}, {}, {}, {}
B.CurrentTarget, B.LockedTarget = nil, nil
B.OriginalCollision, B.OriginalWalkSpeed, B.OriginalJumpPower, B.OriginalJumpHeight = {}, 16, 50, 7.2
B.Unlocked = false
B.FlyBV, B.FlyBG, B.NoclipConn, B.JumpConn, B.AirWalkPart = nil, nil, nil, nil, nil
B.LastShoot, B.SessionStart = 0, tick()
B.SkyParts = {}

local function AddConn(c) table.insert(B.Connections, c) return c end

local function CleanupAll()
    for _, c in ipairs(B.Connections) do pcall(function() c:Disconnect() end) end
    B.Connections = {}
    for _, d in pairs(B.Drawings) do pcall(function() if d.Remove then d:Remove() end end) end
    B.Drawings = {}
    for _, pack in pairs(B.ESPObjects) do
        for k, d in pairs(pack) do
            if type(d) == "table" then
                for _, l in pairs(d) do pcall(function() if l and l.Remove then l:Remove() end end) end
            else pcall(function() if d and d.Remove then d:Remove() end end) end
        end
    end
    B.ESPObjects = {}
    if B.FlyBV then pcall(function() B.FlyBV:Destroy() end) B.FlyBV = nil end
    if B.FlyBG then pcall(function() B.FlyBG:Destroy() end) B.FlyBG = nil end
    for _, p in ipairs(B.SkyParts) do pcall(function() p:Destroy() end) end
    B.SkyParts = {}
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

local ColorPresets = {
    Purple = {vis=Color3.fromRGB(180,80,255), hid=Color3.fromRGB(255,80,120), pri=Color3.fromRGB(255,200,50), tr=Color3.fromRGB(200,100,255), fov=Color3.fromRGB(170,70,255), box=Color3.fromRGB(180,80,255)},
    Green  = {vis=Color3.fromRGB(0,255,140), hid=Color3.fromRGB(255,70,70), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(0,255,180), fov=Color3.fromRGB(0,255,160), box=Color3.fromRGB(0,255,140)},
    Red    = {vis=Color3.fromRGB(255,60,60), hid=Color3.fromRGB(180,40,40), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(255,100,100), fov=Color3.fromRGB(255,80,80), box=Color3.fromRGB(255,60,60)},
    Cyan   = {vis=Color3.fromRGB(0,220,255), hid=Color3.fromRGB(255,80,80), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(0,255,255), fov=Color3.fromRGB(0,200,255), box=Color3.fromRGB(0,220,255)},
    Yellow = {vis=Color3.fromRGB(255,220,40), hid=Color3.fromRGB(255,80,80), pri=Color3.fromRGB(0,255,160), tr=Color3.fromRGB(255,240,100), fov=Color3.fromRGB(255,220,40), box=Color3.fromRGB(255,220,40)},
}
local function ApplyColor(name)
    local p = ColorPresets[name] or ColorPresets.Purple
    B.Settings.ESP.ColorName = name
    B.Settings.ESP.VisibleColor = p.vis
    B.Settings.ESP.HiddenColor = p.hid
    B.Settings.ESP.PriorityColor = p.pri
    B.Settings.ESP.TracerColor = p.tr
    B.Settings.ESP.FOVColor = p.fov
    B.Settings.ESP.BoxColor = p.box
    if B.Drawings.FOV then B.Drawings.FOV.Color = p.fov end
end

local Themes = {
    Purple = {acc=Color3.fromRGB(160,50,255), bg=Color3.fromRGB(10,8,18), card=Color3.fromRGB(18,14,32)},
    Green  = {acc=Color3.fromRGB(0,200,120), bg=Color3.fromRGB(8,12,10), card=Color3.fromRGB(14,22,18)},
    Cyan   = {acc=Color3.fromRGB(0,180,220), bg=Color3.fromRGB(8,12,18), card=Color3.fromRGB(14,20,28)},
    Red    = {acc=Color3.fromRGB(220,50,80), bg=Color3.fromRGB(14,8,10), card=Color3.fromRGB(28,14,18)},
}

-- ===================== GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BAXTARA_X_CHEAT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = CoreGui

-- KEY
local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(1,0,1,0)
KeyFrame.BackgroundColor3 = Color3.fromRGB(6,4,14)
KeyFrame.BorderSizePixel = 0
KeyFrame.ZIndex = 100
KeyFrame.Parent = ScreenGui

local KeyCard = Instance.new("Frame")
KeyCard.Size = UDim2.new(0,320,0,340)
KeyCard.Position = UDim2.new(0.5,-160,0.5,-170)
KeyCard.BackgroundColor3 = Color3.fromRGB(16,12,30)
KeyCard.BorderSizePixel = 0
KeyCard.ZIndex = 110
KeyCard.Parent = KeyFrame
Instance.new("UICorner", KeyCard).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke", KeyCard).Color = Color3.fromRGB(160,50,255)

local function KL(parent, text, y, sz, col)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-24,0,sz or 16)
    l.Position = UDim2.new(0,12,0,y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = col or Color3.fromRGB(200,120,255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = sz or 14
    l.ZIndex = 111
    l.Parent = parent
    return l
end
KL(KeyCard, "BAXTARA X CHEAT", 16, 20)
KL(KeyCard, "SECURE ACCESS", 42, 11, Color3.fromRGB(140,100,200))

local InputH = Instance.new("Frame")
InputH.Size = UDim2.new(1,-40,0,36)
InputH.Position = UDim2.new(0,20,0,80)
InputH.BackgroundColor3 = Color3.fromRGB(24,18,40)
InputH.BorderSizePixel = 0
InputH.ZIndex = 111
InputH.Parent = KeyCard
Instance.new("UICorner", InputH).CornerRadius = UDim.new(0,8)
local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1,-12,1,0)
KeyBox.Position = UDim2.new(0,6,0,0)
KeyBox.BackgroundTransparency = 1
KeyBox.PlaceholderText = "ENTER ACCESS KEY"
KeyBox.PlaceholderColor3 = Color3.fromRGB(100,80,140)
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(230,210,255)
KeyBox.Font = Enum.Font.Code
KeyBox.TextSize = 13
KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.ZIndex = 112
KeyBox.Parent = InputH

local StatusLbl = KL(KeyCard, "", 124, 12, Color3.fromRGB(255,80,100))

local function KBtn(text, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-40,0,34)
    b.Position = UDim2.new(0,20,0,y)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,245,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.ZIndex = 111
    b.Parent = KeyCard
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end
local VerifyBtn = KBtn("VERIFY KEY", 150, Color3.fromRGB(120,30,200))
KBtn("JOIN WHATSAPP", 192, Color3.fromRGB(20,90,50), function()
    pcall(function() if setclipboard then setclipboard(WA_URL) end end)
end)
KBtn("COPY KEY INFO", 234, Color3.fromRGB(40,30,70), function()
    pcall(function() if setclipboard then setclipboard("Key: BAXTARA X CHEAT") end end)
    StatusLbl.TextColor3 = Color3.fromRGB(100,255,160)
    StatusLbl.Text = "Copied"
end)
KL(KeyCard, "Key: BAXTARA X CHEAT", 280, 11, Color3.fromRGB(120,100,160))

-- LOADING
local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(1,0,1,0)
LoadFrame.BackgroundColor3 = Color3.fromRGB(4,2,10)
LoadFrame.BorderSizePixel = 0
LoadFrame.Visible = false
LoadFrame.ZIndex = 90
LoadFrame.Parent = ScreenGui
for i = 1, 14 do
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0,130,0,16)
    t.Position = UDim2.new(math.random(),0,math.random(),0)
    t.BackgroundTransparency = 1
    t.Text = ({"BAXTARA","X CHEAT","EXECUTE","DOMINATE","WIN","BX"})[math.random(1,6)]
    t.TextColor3 = Color3.fromRGB(150+math.random(0,50),40,220)
    t.TextTransparency = 0.4
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 11+math.random(0,5)
    t.ZIndex = 91
    t.Parent = LoadFrame
    task.spawn(function()
        while t.Parent do
            TweenService:Create(t, TweenInfo.new(4.5, Enum.EasingStyle.Sine), {Position = UDim2.new(math.random(),0,math.random(),0)}):Play()
            task.wait(4.5)
        end
    end)
end
local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1,0,0,32)
LoadTitle.Position = UDim2.new(0,0,0.42,0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "BAXTARA X CHEAT"
LoadTitle.TextColor3 = Color3.fromRGB(200,100,255)
LoadTitle.Font = Enum.Font.GothamBlack
LoadTitle.TextSize = 22
LoadTitle.ZIndex = 95
LoadTitle.Parent = LoadFrame
local LoadBarBG = Instance.new("Frame")
LoadBarBG.Size = UDim2.new(0,200,0,4)
LoadBarBG.Position = UDim2.new(0.5,-100,0.52,0)
LoadBarBG.BackgroundColor3 = Color3.fromRGB(30,20,50)
LoadBarBG.BorderSizePixel = 0
LoadBarBG.ZIndex = 95
LoadBarBG.Parent = LoadFrame
Instance.new("UICorner", LoadBarBG).CornerRadius = UDim.new(1,0)
local LoadBar = Instance.new("Frame")
LoadBar.Size = UDim2.new(0,0,1,0)
LoadBar.BackgroundColor3 = Color3.fromRGB(180,60,255)
LoadBar.BorderSizePixel = 0
LoadBar.ZIndex = 96
LoadBar.Parent = LoadBarBG
Instance.new("UICorner", LoadBar).CornerRadius = UDim.new(1,0)
local LoadPct = Instance.new("TextLabel")
LoadPct.Size = UDim2.new(1,0,0,14)
LoadPct.Position = UDim2.new(0,0,0.55,0)
LoadPct.BackgroundTransparency = 1
LoadPct.Text = "0%"
LoadPct.TextColor3 = Color3.fromRGB(180,140,230)
LoadPct.Font = Enum.Font.Code
LoadPct.TextSize = 11
LoadPct.ZIndex = 95
LoadPct.Parent = LoadFrame

-- ===================== MAIN =====================
local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.new(0, 740, 0, 500)
Main.Position = UDim2.new(0.5, -370, 0.5, -250)
Main.BackgroundColor3 = B.Settings.UI.Background
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.ZIndex = 10
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(150, 40, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1,0,0,40)
TopBar.BackgroundColor3 = Color3.fromRGB(14,10,28)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 12
TopBar.Parent = Main

local TopLogo = Instance.new("TextLabel")
TopLogo.Size = UDim2.new(0,240,1,0)
TopLogo.Position = UDim2.new(0,10,0,0)
TopLogo.BackgroundTransparency = 1
TopLogo.Text = "BX  BAXTARA X CHEAT"
TopLogo.TextColor3 = Color3.fromRGB(200,120,255)
TopLogo.Font = Enum.Font.GothamBlack
TopLogo.TextSize = 14
TopLogo.TextXAlignment = Enum.TextXAlignment.Left
TopLogo.ZIndex = 13
TopLogo.Parent = TopBar

local TopUser = Instance.new("TextLabel")
TopUser.Size = UDim2.new(0,180,1,0)
TopUser.Position = UDim2.new(1,-260,0,0)
TopUser.BackgroundTransparency = 1
TopUser.Text = "User: "..LocalPlayer.Name.." | Key: Active"
TopUser.TextColor3 = Color3.fromRGB(160,140,200)
TopUser.Font = Enum.Font.Code
TopUser.TextSize = 10
TopUser.TextXAlignment = Enum.TextXAlignment.Right
TopUser.ZIndex = 13
TopUser.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,30,0,26)
CloseBtn.Position = UDim2.new(1,-36,0.5,-13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50,20,40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,120,140)
CloseBtn.Font = Enum.Font.Code
CloseBtn.TextSize = 12
CloseBtn.ZIndex = 13
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,30,0,26)
MinBtn.Position = UDim2.new(1,-70,0.5,-13)
MinBtn.BackgroundColor3 = Color3.fromRGB(40,35,30)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(230,220,120)
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 13
MinBtn.ZIndex = 13
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,6)

-- Sidebar
local Side = Instance.new("Frame")
Side.Size = UDim2.new(0, 130, 1, -40)
Side.Position = UDim2.new(0, 0, 0, 40)
Side.BackgroundColor3 = Color3.fromRGB(12,10,24)
Side.BorderSizePixel = 0
Side.ZIndex = 11
Side.Parent = Main

local SideNames = {"Home","ESP","Aim","Brutal","LocalCfg","Settings","About"}
local SideBtns, Pages = {}, {}

local function SwitchPage(name)
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
        if SideBtns[n] then
            SideBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(50,25,90) or Color3.fromRGB(12,10,24)
            SideBtns[n].TextColor3 = (n == name) and Color3.fromRGB(220,150,255) or Color3.fromRGB(140,130,170)
        end
    end
end

for i, name in ipairs(SideNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-6,0,32)
    btn.Position = UDim2.new(0,3,0,6+(i-1)*36)
    btn.BackgroundColor3 = Color3.fromRGB(12,10,24)
    btn.Text = "  "..name
    btn.TextColor3 = Color3.fromRGB(140,130,170)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 12
    btn.Parent = Side
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    SideBtns[name] = btn
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1,-138,1,-48)
    page.Position = UDim2.new(0,134,0,44)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(160,60,255)
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    page.ZIndex = 11
    page.Parent = Main
    Pages[name] = page
end
SwitchPage("Home")

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1,0,0,14)
Footer.Position = UDim2.new(0,0,1,-14)
Footer.BackgroundColor3 = Color3.fromRGB(10,8,18)
Footer.BorderSizePixel = 0
Footer.Text = "  BAXTARA X CHEAT v5.4  ·  GOOD GAME, BRO!  ·  NUGI CENEL"
Footer.TextColor3 = Color3.fromRGB(130,80,180)
Footer.Font = Enum.Font.Code
Footer.TextSize = 9
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.ZIndex = 12
Footer.Parent = Main

-- UI helpers
local function Card(parent, title, h)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1,-6,0,h or 100)
    c.BackgroundColor3 = B.Settings.UI.Card
    c.BorderSizePixel = 0
    c.ZIndex = 12
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0,10)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(80,40,140)
    st.Thickness = 1
    st.Transparency = 0.45
    st.Parent = c
    if title then
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,-14,0,20)
        t.Position = UDim2.new(0,8,0,5)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = Color3.fromRGB(200,140,255)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 13
        t.Parent = c
    end
    return c
end

local function MakeToggle(parent, text, default, y, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-14,0,26)
    h.Position = UDim2.new(0,7,0,y)
    h.BackgroundTransparency = 1
    h.ZIndex = 13
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-48,1,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220,210,240)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = h
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0,38,0,18)
    bg.Position = UDim2.new(1,-40,0.5,-9)
    bg.BackgroundColor3 = default and Color3.fromRGB(140,40,220) or Color3.fromRGB(40,35,55)
    bg.BorderSizePixel = 0
    bg.ZIndex = 14
    bg.Parent = h
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(245,240,255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 15
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 16
    btn.Parent = h
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(bg, TweenInfo.new(0.12), {BackgroundColor3 = state and Color3.fromRGB(140,40,220) or Color3.fromRGB(40,35,55)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.12), {Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
        if cb then cb(state) end
    end)
    return h
end

local function MakeSlider(parent, text, min, max, default, y, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-14,0,38)
    h.Position = UDim2.new(0,7,0,y)
    h.BackgroundTransparency = 1
    h.ZIndex = 13
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.55,0,0,13)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220,210,240)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = h
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.4,0,0,13)
    val.Position = UDim2.new(0.58,0,0,0)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = Color3.fromRGB(200,120,255)
    val.Font = Enum.Font.Code
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 14
    val.Parent = h
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1,0,0,6)
    barBG.Position = UDim2.new(0,0,0,20)
    barBG.BackgroundColor3 = Color3.fromRGB(35,30,50)
    barBG.BorderSizePixel = 0
    barBG.ZIndex = 14
    barBG.Parent = h
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/math.max(max-min,1),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(160,60,255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 15
    fill.Parent = barBG
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local dragging = false
    local function update(x)
        local rel = math.clamp((x-barBG.AbsolutePosition.X)/math.max(barBG.AbsoluteSize.X,1),0,1)
        local v = math.floor(min+(max-min)*rel+0.5)
        fill.Size = UDim2.new(rel,0,1,0)
        val.Text = tostring(v)
        if cb then cb(v) end
    end
    barBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    barBG.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    AddConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end))
    return h
end

local function MakeBtn(parent, text, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-14,0,28)
    b.Position = UDim2.new(0,7,0,y)
    b.BackgroundColor3 = color or Color3.fromRGB(90,30,160)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(245,235,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.ZIndex = 14
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.06), {BackgroundTransparency=0.25}):Play()
        task.wait(0.06)
        TweenService:Create(b, TweenInfo.new(0.06), {BackgroundTransparency=0}):Play()
        if cb then cb() end
    end)
    return b
end

local function Layout(page)
    task.defer(function()
        local y = 4
        for _, ch in ipairs(page:GetChildren()) do
            if ch:IsA("GuiObject") then
                ch.Position = UDim2.new(0,3,0,y)
                y = y + ch.Size.Y.Offset + 6
            end
        end
        page.CanvasSize = UDim2.new(0,0,0,y+8)
    end)
end

-- HOME
do
    local p = Pages.Home
    local logoCard = Card(p, nil, 90)
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1,-16,0,36)
    logo.Position = UDim2.new(0,8,0,12)
    logo.BackgroundTransparency = 1
    logo.Text = "BAXTARA X CHEAT"
    logo.TextColor3 = Color3.fromRGB(200,100,255)
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 22
    logo.ZIndex = 13
    logo.Parent = logoCard
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1,-16,0,18)
    sub.Position = UDim2.new(0,8,0,50)
    sub.BackgroundTransparency = 1
    sub.Text = "PLAY · EXPLOIT · DOMINATE  ·  v5.4"
    sub.TextColor3 = Color3.fromRGB(140,100,200)
    sub.Font = Enum.Font.Code
    sub.TextSize = 11
    sub.ZIndex = 13
    sub.Parent = logoCard
    -- pulse logo
    task.spawn(function()
        while logo.Parent do
            TweenService:Create(logo, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.25}):Play()
            task.wait(1.2)
            TweenService:Create(logo, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
            task.wait(1.2)
        end
    end)

    local welcome = Card(p, "Dashboard", 70)
    local wt = Instance.new("TextLabel")
    wt.Size = UDim2.new(1,-16,0,40)
    wt.Position = UDim2.new(0,8,0,26)
    wt.BackgroundTransparency = 1
    wt.Text = "Selamat datang, "..(LocalPlayer.DisplayName or LocalPlayer.Name).."\nStatus: Premium Access · Panel siap"
    wt.TextColor3 = Color3.fromRGB(0,255,160)
    wt.Font = Enum.Font.Code
    wt.TextSize = 11
    wt.TextXAlignment = Enum.TextXAlignment.Left
    wt.ZIndex = 13
    wt.Parent = welcome

    local stats = Card(p, "Live Stats", 55)
    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(1,-16,0,28)
    st.Position = UDim2.new(0,8,0,24)
    st.BackgroundTransparency = 1
    st.Text = "Players: - | FPS: - | Time: 00:00"
    st.TextColor3 = Color3.fromRGB(180,160,220)
    st.Font = Enum.Font.Code
    st.TextSize = 11
    st.TextXAlignment = Enum.TextXAlignment.Left
    st.ZIndex = 13
    st.Parent = stats
    B.StatsLabel = st
    Layout(p)
end

-- Continue building pages and systems in a compact but complete way...
-- ESP PAGE (full features)
do
    local p = Pages.ESP
    local c = Card(p, "ESP Settings", 340)
    MakeToggle(c, "Enable ESP", false, 28, function(v) B.Settings.ESP.Enabled = v end)
    MakeToggle(c, "Box ESP", true, 54, function(v) B.Settings.ESP.Box = v end)
    MakeToggle(c, "Name", true, 80, function(v) B.Settings.ESP.Name = v end)
    MakeToggle(c, "Health Bar", true, 106, function(v) B.Settings.ESP.HealthBar = v end)
    MakeToggle(c, "Distance", true, 132, function(v) B.Settings.ESP.Distance = v end)
    MakeToggle(c, "Tracer Line", true, 158, function(v) B.Settings.ESP.Tracer = v end)
    MakeToggle(c, "Skeleton ESP", false, 184, function(v) B.Settings.ESP.Skeleton = v end)
    MakeToggle(c, "Visible Check", true, 210, function(v) B.Settings.ESP.VisibleCheck = v end)
    MakeToggle(c, "Priority Mark", true, 236, function(v) B.Settings.ESP.PriorityMark = v end)
    MakeToggle(c, "Offscreen Arrow", true, 262, function(v) B.Settings.ESP.Offscreen = v end)
    MakeSlider(c, "Max Distance", 100, 2000, 1000, 290, function(v) B.Settings.ESP.MaxDistance = v end)
    local col = Card(p, "ESP / FOV Color", 160)
    MakeBtn(col, "Purple", 28, Color3.fromRGB(100,30,160), function() ApplyColor("Purple") end)
    MakeBtn(col, "Green", 58, Color3.fromRGB(0,100,60), function() ApplyColor("Green") end)
    MakeBtn(col, "Red", 88, Color3.fromRGB(140,30,30), function() ApplyColor("Red") end)
    MakeBtn(col, "Cyan", 118, Color3.fromRGB(0,90,120), function() ApplyColor("Cyan") end)
    Layout(p)
end

-- AIM
do
    local p = Pages.Aim
    local c = Card(p, "Aim Settings", 400)
    MakeToggle(c, "Enable Aimbot", false, 28, function(v)
        B.Settings.Aim.Enabled = v
        if v and DrawingLib and not B.Drawings.FOV then
            local f = Drawing.new("Circle")
            f.Thickness = 3.5
            f.NumSides = 64
            f.Filled = false
            f.Color = B.Settings.ESP.FOVColor
            f.Transparency = 0.28
            f.Visible = false
            B.Drawings.FOV = f
        end
    end)
    MakeToggle(c, "Silent Aim", false, 54, function(v) B.Settings.Aim.SilentAim = v end)
    MakeToggle(c, "Anti Miss", false, 80, function(v) B.Settings.Aim.AntiMiss = v end)
    MakeToggle(c, "Aim Lock", false, 106, function(v) B.Settings.Aim.AimLock = v if not v then B.LockedTarget = nil end end)
    MakeToggle(c, "Visibility Check", true, 132, function(v) B.Settings.Aim.VisibilityCheck = v end)
    MakeToggle(c, "Head Aim", true, 158, function(v) B.Settings.Aim.HeadAim = v B.Settings.Aim.HitPart = "Head" if v then B.Settings.Aim.BodyAim = false end end)
    MakeToggle(c, "Body Aim", false, 184, function(v) B.Settings.Aim.BodyAim = v B.Settings.Aim.HitPart = "Body" if v then B.Settings.Aim.HeadAim = false end end)
    MakeToggle(c, "Multi-Bone", false, 210, function(v) B.Settings.Aim.MultiBone = v end)
    MakeToggle(c, "FOV Circle", true, 236, function(v) B.Settings.Aim.FOVCircle = v end)
    MakeToggle(c, "Team Check", true, 262, function(v) B.Settings.Aim.TeamCheck = v end)
    MakeToggle(c, "Prediction", false, 288, function(v) B.Settings.Aim.AimPrediction = v end)
    MakeSlider(c, "FOV Size", 40, 1000, 180, 316, function(v) B.Settings.Aim.FOV = v end)
    MakeSlider(c, "Smoothness x100", 5, 40, 15, 354, function(v) B.Settings.Aim.AimSmoothing = v/100 end)
    Layout(p)
end

-- BRUTAL (restored full)
do
    local p = Pages.Brutal
    local c = Card(p, "Movement", 280)
    MakeToggle(c, "Fly", false, 28, function(v)
        B.Settings.Brutal.Fly = v
        local char = LocalPlayer.Character
        local root = char and GetRoot(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if B.FlyBV then pcall(function() B.FlyBV:Destroy() end) B.FlyBV = nil end
        if B.FlyBG then pcall(function() B.FlyBG:Destroy() end) B.FlyBG = nil end
        if v and root and hum then
            hum.PlatformStand = true
            B.FlyBV = Instance.new("BodyVelocity")
            B.FlyBV.MaxForce = Vector3.new(9e4,9e4,9e4)
            B.FlyBV.Velocity = Vector3.zero
            B.FlyBV.Parent = root
            B.FlyBG = Instance.new("BodyGyro")
            B.FlyBG.MaxTorque = Vector3.new(9e4,9e4,9e4)
            B.FlyBG.P = 3000
            B.FlyBG.Parent = root
        elseif hum then
            hum.PlatformStand = false
        end
    end)
    MakeSlider(c, "Fly Speed", 10, 100, 45, 54, function(v) B.Settings.Brutal.FlySpeed = v end)
    MakeToggle(c, "Speed Hack", false, 96, function(v)
        B.Settings.Brutal.SpeedHack = v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if v then B.OriginalWalkSpeed = hum.WalkSpeed hum.WalkSpeed = math.clamp(B.Settings.Brutal.SpeedValue,16,40)
            else hum.WalkSpeed = B.OriginalWalkSpeed or 16 end
        end
    end)
    MakeSlider(c, "Walk Speed", 16, 40, 24, 122, function(v)
        B.Settings.Brutal.SpeedValue = v
        if B.Settings.Brutal.SpeedHack then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end)
    MakeToggle(c, "Infinite Jump", false, 164, function(v)
        B.Settings.Brutal.InfiniteJump = v
        if B.JumpConn then B.JumpConn:Disconnect() B.JumpConn = nil end
        if v then
            B.JumpConn = UserInputService.JumpRequest:Connect(function()
                local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
            AddConn(B.JumpConn)
        end
    end)
    MakeToggle(c, "Noclip", false, 190, function(v)
        B.Settings.Brutal.Noclip = v
        if B.NoclipConn then B.NoclipConn:Disconnect() B.NoclipConn = nil end
        if v then
            B.NoclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
            AddConn(B.NoclipConn)
        end
    end)
    MakeToggle(c, "Super Jump", false, 216, function(v)
        B.Settings.Brutal.SuperJump = v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if v then
                B.OriginalJumpPower = hum.JumpPower
                B.OriginalJumpHeight = hum.JumpHeight
                hum.JumpPower = B.Settings.Brutal.SuperJumpPower
                hum.JumpHeight = B.Settings.Brutal.SuperJumpPower / 4
            else
                hum.JumpPower = B.OriginalJumpPower or 50
                hum.JumpHeight = B.OriginalJumpHeight or 7.2
            end
        end
    end)
    MakeToggle(c, "Ghost Mode", false, 242, function(v)
        B.Settings.Brutal.GhostMode = v
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = v and 1 or 0
            elseif part:IsA("Decal") then
                part.Transparency = v and 1 or 0
            end
        end
    end)

    local h = Card(p, "Hitbox (Head / Body)", 140)
    MakeToggle(h, "Hitbox Expand", false, 28, function(v) B.Settings.Brutal.HitboxExpand = v end)
    MakeToggle(h, "Hitbox = Head", false, 54, function(v)
        if v then B.Settings.Brutal.HitboxPart = "Head" end
    end)
    MakeToggle(h, "Hitbox = Body", true, 80, function(v)
        if v then B.Settings.Brutal.HitboxPart = "Body" end
    end)
    MakeSlider(h, "Hitbox Size (max 27)", 2, 27, 8, 106, function(v) B.Settings.Brutal.HitboxSize = v end)

    local w = Card(p, "Weapon / Combat", 200)
    MakeToggle(w, "Anti Cooldown", false, 28, function(v) B.Settings.Brutal.AntiCooldown = v end)
    MakeToggle(w, "Infinite Ammo", false, 54, function(v) B.Settings.Brutal.InfiniteAmmo = v end)
    MakeToggle(w, "Attack Speed (safe 1-12)", false, 80, function(v) B.Settings.Brutal.AttackSpeed = v end)
    MakeSlider(w, "Attack Speed Value", 1, 12, 8, 106, function(v) B.Settings.Brutal.AttackSpeedVal = v end)
    MakeToggle(w, "Auto Shoot", false, 148, function(v) B.Settings.Brutal.AutoShoot = v end)
    MakeToggle(w, "Auto Kill (silent)", false, 174, function(v) B.Settings.Brutal.AutoKill = v end)

    local n = Card(p, "NPC", 100)
    MakeBtn(n, "ONE HIT NEAREST NPC", 28, Color3.fromRGB(130,30,50), function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if hum and root and hum.Health > 0 then
                    local my = GetRoot(LocalPlayer.Character)
                    if my and (my.Position-root.Position).Magnitude < 200 then
                        pcall(function() hum.Health = 0 end)
                        break
                    end
                end
            end
        end
    end)
    MakeBtn(n, "KILL ALL NPC", 60, Color3.fromRGB(110,20,40), function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then pcall(function() hum.Health = 0 end) end
            end
        end
    end)
    MakeToggle(n, "God Mode (local)", false, 92, function(v)
        B.Settings.Brutal.GodMode = v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if v then hum.MaxHealth = 1e9 hum.Health = 1e9 else hum.MaxHealth = 100 end
        end
    end)
    Layout(p)
end

-- LOCAL CONFIG (new)
do
    local p = Pages.LocalCfg
    local sky = Card(p, "Sky / Map Branding", 90)
    MakeToggle(sky, "Sky BAXTARA Text (around map)", false, 28, function(v)
        B.Settings.LocalCfg.SkyBAXTARA = v
        for _, sp in ipairs(B.SkyParts) do pcall(function() sp:Destroy() end) end
        B.SkyParts = {}
        if v then
            local root = GetRoot(LocalPlayer.Character)
            local base = root and root.Position or Vector3.new(0,50,0)
            for i = 1, 8 do
                local ang = (i/8) * math.pi * 2
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 1
                part.Size = Vector3.new(1,1,1)
                part.CFrame = CFrame.new(base + Vector3.new(math.cos(ang)*80, 40, math.sin(ang)*80))
                part.Parent = Workspace
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 280, 0, 50)
                bb.AlwaysOnTop = true
                bb.Parent = part
                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.new(1,0,1,0)
                tl.BackgroundTransparency = 1
                tl.Text = "BAXTARA X CHEAT"
                tl.TextColor3 = Color3.fromRGB(200,100,255)
                tl.Font = Enum.Font.GothamBlack
                tl.TextSize = 28
                tl.TextStrokeTransparency = 0.3
                tl.Parent = bb
                table.insert(B.SkyParts, part)
            end
            -- brighten sky a bit
            Lighting.Brightness = math.max(Lighting.Brightness, 2)
            Lighting.FogEnd = 1e6
        end
    end)
    MakeBtn(sky, "Refresh Sky Positions", 58, Color3.fromRGB(80,30,140), function()
        if B.Settings.LocalCfg.SkyBAXTARA then
            -- re-trigger
            local t = B.Settings.LocalCfg.SkyBAXTARA
            B.Settings.LocalCfg.SkyBAXTARA = false
            for _, sp in ipairs(B.SkyParts) do pcall(function() sp:Destroy() end) end
            B.SkyParts = {}
            task.wait(0.05)
            -- fire toggle logic manually by setting true again via Apply would need the toggle; simple recreate:
            B.Settings.LocalCfg.SkyBAXTARA = true
            local root = GetRoot(LocalPlayer.Character)
            local base = root and root.Position or Vector3.new(0,50,0)
            for i = 1, 8 do
                local ang = (i/8) * math.pi * 2
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 1
                part.Size = Vector3.new(1,1,1)
                part.CFrame = CFrame.new(base + Vector3.new(math.cos(ang)*80, 40, math.sin(ang)*80))
                part.Parent = Workspace
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 280, 0, 50)
                bb.AlwaysOnTop = true
                bb.Parent = part
                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.new(1,0,1,0)
                tl.BackgroundTransparency = 1
                tl.Text = "BAXTARA X CHEAT"
                tl.TextColor3 = Color3.fromRGB(200,100,255)
                tl.Font = Enum.Font.GothamBlack
                tl.TextSize = 28
                tl.Parent = bb
                table.insert(B.SkyParts, part)
            end
        end
    end)

    local av = Card(p, "Avatar Sultan", 130)
    MakeBtn(av, "Apply Classic R6 Look", 28, Color3.fromRGB(90,30,150), function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            -- simple gold-ish body colors
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Color = Color3.fromRGB(255, 200, 50)
                    part.Material = Enum.Material.Neon
                end
            end
        end)
    end)
    MakeBtn(av, "Apply Neon Purple Body", 60, Color3.fromRGB(80,20,140), function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Color = Color3.fromRGB(160, 40, 255)
                    part.Material = Enum.Material.Neon
                end
            end
        end)
    end)
    MakeBtn(av, "Reset Body Colors", 92, Color3.fromRGB(50,40,70), function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Plastic
                end
            end
        end)
    end)

    local lag = Card(p, "Server / Players", 150)
    MakeToggle(lag, "Anti Lag Self (priority ON)", true, 28, function(v)
        B.Settings.LocalCfg.AntiLagSelf = v
        if v then
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        end
    end)
    MakeToggle(lag, "Server Lag Attempt (risk)", false, 54, function(v)
        B.Settings.LocalCfg.ServerLag = v
    end)
    MakeBtn(lag, "TELEPORT ALL PLAYERS IN FRONT", 90, Color3.fromRGB(120,40,40), function()
        local my = GetRoot(LocalPlayer.Character)
        if not my then return end
        local front = my.CFrame * CFrame.new(0, 0, -8)
        local i = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local root = GetRoot(GetChar(p))
                if root then
                    i = i + 1
                    -- client-side visual TP (server may reject)
                    pcall(function()
                        root.CFrame = front * CFrame.new((i%5)*3 - 6, 0, math.floor(i/5)*3)
                    end)
                end
            end
        end
        StarterGui:SetCore("SendNotification", {
            Title = "BAXTARA",
            Text = "TP All attempted (client-side)",
            Duration = 3,
        })
    end)
    Layout(p)
end

-- SETTINGS (theme)
do
    local p = Pages.Settings
    local th = Card(p, "Theme Panel", 140)
    MakeBtn(th, "Theme: Purple", 28, Color3.fromRGB(100,30,160), function()
        local t = Themes.Purple
        B.Settings.UI.Theme = "Purple"
        B.Settings.UI.Accent = t.acc
        Main.BackgroundColor3 = t.bg
        MainStroke.Color = t.acc
    end)
    MakeBtn(th, "Theme: Green", 58, Color3.fromRGB(0,100,60), function()
        local t = Themes.Green
        B.Settings.UI.Theme = "Green"
        Main.BackgroundColor3 = t.bg
        MainStroke.Color = t.acc
    end)
    MakeBtn(th, "Theme: Cyan", 88, Color3.fromRGB(0,90,120), function()
        local t = Themes.Cyan
        B.Settings.UI.Theme = "Cyan"
        Main.BackgroundColor3 = t.bg
        MainStroke.Color = t.acc
    end)
    MakeBtn(th, "Theme: Red", 118, Color3.fromRGB(140,30,30), function()
        local t = Themes.Red
        B.Settings.UI.Theme = "Red"
        Main.BackgroundColor3 = t.bg
        MainStroke.Color = t.acc
    end)

    local vis = Card(p, "Visual / Protect", 160)
    MakeToggle(vis, "FullBright", false, 28, function(v)
        B.Settings.Visual.FullBright = v
        Lighting.Brightness = v and 2.2 or 1
        Lighting.GlobalShadows = not v
    end)
    MakeToggle(vis, "Anti Lag (graphics)", false, 54, function(v)
        B.Settings.Visual.AntiLag = v
        pcall(function()
            settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
        end)
    end)
    MakeToggle(vis, "Anti-Kick", true, 80, function(v) B.Settings.Protect.AntiKick = v end)
    MakeToggle(vis, "Auto Hop on Flag", true, 106, function(v) B.Settings.Protect.AutoHopOnFlag = v end)
    MakeBtn(vis, "FORCE SERVER HOP", 134, Color3.fromRGB(30,70,50), function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)

    local un = Card(p, "Unload", 50)
    MakeBtn(un, "UNLOAD SCRIPT", 22, Color3.fromRGB(90,25,35), function()
        CleanupAll()
        ScreenGui:Destroy()
        getgenv().BAXTARA = nil
    end)
    Layout(p)
end

-- ABOUT
do
    local p = Pages.About
    local c = Card(p, "Tentang", 100)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,-16,0,70)
    t.Position = UDim2.new(0,8,0,26)
    t.BackgroundTransparency = 1
    t.Text = "BAXTARA X CHEAT v5.4\nDeveloper: NUGI CENEL\nPLAY · EXPLOIT · DOMINATE\nKey: BAXTARA X CHEAT"
    t.TextColor3 = Color3.fromRGB(180,150,220)
    t.Font = Enum.Font.Code
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 13
    t.Parent = c
    Layout(p)
end

-- ===================== CORE LOGIC =====================
local function GetAimPart(char)
    if B.Settings.Aim.HitPart == "Body" or B.Settings.Aim.BodyAim then
        return GetRoot(char) or GetHead(char)
    end
    return GetHead(char) or GetRoot(char)
end

local function GetBestTarget()
    local best, bestScore = nil, math.huge
    local center = ScreenCenter()
    local camPos = Camera.CFrame.Position
    local fov = B.Settings.Aim.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and TeamOK(p) then
            local char = GetChar(p)
            if IsAlive(char) then
                local part = GetAimPart(char)
                if part then
                    local dist = DistTo(part.Position)
                    if dist <= B.Settings.Aim.AimDistance then
                        local screen, on = WorldToScreen(part.Position)
                        if on then
                            local cross = (screen - center).Magnitude
                            if cross <= fov then
                                local vis = IsVisible(camPos, part.Position, char)
                                if not (B.Settings.Aim.VisibilityCheck and not vis) then
                                    if cross < bestScore then bestScore = cross best = p end
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
        if p ~= LocalPlayer and TeamOK(p) then
            local char = GetChar(p)
            if IsAlive(char) then
                local root = GetRoot(char)
                if root then
                    local d = (my.Position - root.Position).Magnitude
                    if d < bd and d < B.Settings.Aim.AimDistance then bd = d best = p end
                end
            end
        end
    end
    return best
end

local function AimAt(target)
    if not target then return end
    local char = GetChar(target)
    if not IsAlive(char) then return end
    local part = GetAimPart(char)
    if not part then return end
    if B.Settings.Aim.VisibilityCheck and not IsVisible(Camera.CFrame.Position, part.Position, char) then return end
    local pos = part.Position
    if B.Settings.Aim.AimPrediction then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        pos = pos + vel * B.Settings.Aim.PredictionAmount
    end
    local current = Camera.CFrame
    local goal = CFrame.new(current.Position, pos)
    local smooth = B.Settings.Aim.AimSmoothing
    if B.Settings.Aim.SilentAim or B.Settings.Brutal.AutoKill then smooth = 0.85 end
    if B.Settings.Aim.AntiMiss then smooth = math.clamp(smooth + 0.2, 0.1, 0.9) end
    Camera.CFrame = current:Lerp(goal, smooth)
end

local function UpdateAim()
    if not B.Settings.Aim.Enabled and not B.Settings.Brutal.AutoKill then
        if B.Drawings.FOV then B.Drawings.FOV.Visible = false end
        B.CurrentTarget = nil
        return
    end
    local center = ScreenCenter()
    if B.Drawings.FOV and B.Settings.Aim.FOVCircle and B.Settings.Aim.Enabled then
        B.Drawings.FOV.Position = center
        B.Drawings.FOV.Radius = B.Settings.Aim.FOV
        B.Drawings.FOV.Color = B.Settings.ESP.FOVColor
        B.Drawings.FOV.Thickness = 3.5
        B.Drawings.FOV.Visible = true
    elseif B.Drawings.FOV then
        B.Drawings.FOV.Visible = false
    end
    local target = B.Settings.Aim.Enabled and ((B.Settings.Aim.AimLock and B.LockedTarget) or GetBestTarget()) or nil
    if B.Settings.Aim.AimLock and not B.LockedTarget and target then B.LockedTarget = target end
    if not B.Settings.Aim.AimLock then B.LockedTarget = nil end
    B.CurrentTarget = target
    if target then AimAt(target) end
end

-- ESP
local BonePairs = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}

local function DestroyPack(id)
    local pack = B.ESPObjects[id]
    if not pack then return end
    for k, d in pairs(pack) do
        if k == "Skel" then
            for _, l in ipairs(d) do pcall(function() if l and l.Remove then l:Remove() end end) end
        else pcall(function() if d and d.Remove then d:Remove() end end) end
    end
    B.ESPObjects[id] = nil
end

local function GetESPPack(player)
    local id = player.UserId
    if B.ESPObjects[id] then return B.ESPObjects[id] end
    if not DrawingLib then return nil end
    local pack = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Line"),
        Dist = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Skel = {},
    }
    pack.Box.Thickness = 1.5
    pack.Box.Filled = false
    pack.Box.Visible = false
    pack.Name.Size = 13
    pack.Name.Center = true
    pack.Name.Outline = true
    pack.Name.Visible = false
    pack.Health.Thickness = 2.2
    pack.Health.Visible = false
    pack.Dist.Size = 11
    pack.Dist.Center = true
    pack.Dist.Outline = true
    pack.Dist.Visible = false
    pack.Tracer.Thickness = 1.3
    pack.Tracer.Visible = false
    for i = 1, 16 do
        local l = Drawing.new("Line")
        l.Thickness = 1.2
        l.Visible = false
        pack.Skel[i] = l
    end
    B.ESPObjects[id] = pack
    return pack
end

local function HidePack(pack)
    if not pack then return end
    for k, d in pairs(pack) do
        if k == "Skel" then
            for _, l in ipairs(d) do if l then l.Visible = false end end
        elseif d and d.Visible ~= nil then d.Visible = false end
    end
end

local function UpdateESP()
    local alive = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then alive[p.UserId] = true end
    end
    for id, _ in pairs(B.ESPObjects) do
        if not alive[id] then DestroyPack(id) end
    end
    if not B.Settings.ESP.Enabled then
        for _, pack in pairs(B.ESPObjects) do HidePack(pack) end
        return
    end
    local camPos = Camera.CFrame.Position
    local vp = Camera.ViewportSize
    local bottom = Vector2.new(vp.X/2, vp.Y)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = GetChar(player)
        local pack = GetESPPack(player)
        if not pack then continue end
        if not IsAlive(char) then HidePack(pack) continue end
        local root, head = GetRoot(char), GetHead(char)
        if not root or not head then HidePack(pack) continue end
        local dist = DistTo(root.Position)
        if dist > B.Settings.ESP.MaxDistance then HidePack(pack) continue end

        local top = head.Position + Vector3.new(0,0.45,0)
        local bot = root.Position - Vector3.new(0,3,0)
        local topS, on = WorldToScreen(top)
        local botS = select(1, WorldToScreen(bot))
        local rootS = select(1, WorldToScreen(root.Position))
        local vis = true
        if B.Settings.ESP.VisibleCheck then vis = IsVisible(camPos, head.Position, char) end
        local color = vis and B.Settings.ESP.VisibleColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.PriorityMark and B.CurrentTarget == player then color = B.Settings.ESP.PriorityColor end
        local boxCol = vis and B.Settings.ESP.BoxColor or B.Settings.ESP.HiddenColor

        if B.Settings.ESP.Box and pack.Box then
            local h = math.max(math.abs(topS.Y-botS.Y),14)
            local w = h * 0.68
            pack.Box.Size = Vector2.new(w,h)
            pack.Box.Position = Vector2.new(topS.X-w/2, topS.Y)
            pack.Box.Color = boxCol
            pack.Box.Visible = on
        else pack.Box.Visible = false end

        if B.Settings.ESP.Name and pack.Name then
            pack.Name.Text = player.DisplayName or player.Name
            pack.Name.Position = Vector2.new(topS.X, topS.Y-14)
            pack.Name.Color = color
            pack.Name.Visible = on
        else pack.Name.Visible = false end

        if B.Settings.ESP.HealthBar and pack.Health then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                local h = math.max(math.abs(topS.Y-botS.Y),14)
                local x = topS.X - (h*0.68)/2 - 5
                pack.Health.From = Vector2.new(x, topS.Y+h)
                pack.Health.To = Vector2.new(x, topS.Y+h*(1-pct))
                pack.Health.Color = Color3.fromRGB(255*(1-pct),255*pct,40)
                pack.Health.Visible = on
            end
        else pack.Health.Visible = false end

        if B.Settings.ESP.Distance and pack.Dist then
            pack.Dist.Text = string.format("[%dm]", math.floor(dist))
            pack.Dist.Position = Vector2.new(botS.X, botS.Y+3)
            pack.Dist.Color = Color3.fromRGB(180,200,210)
            pack.Dist.Visible = on
        else pack.Dist.Visible = false end

        if B.Settings.ESP.Tracer and pack.Tracer then
            pack.Tracer.From = bottom
            pack.Tracer.To = rootS
            pack.Tracer.Color = B.Settings.ESP.TracerColor
            pack.Tracer.Visible = on
        else pack.Tracer.Visible = false end

        if B.Settings.ESP.Skeleton and pack.Skel then
            local idx = 1
            for _, pair in ipairs(BonePairs) do
                if idx > #pack.Skel then break end
                local a = char:FindFirstChild(pair[1])
                local b = char:FindFirstChild(pair[2])
                local line = pack.Skel[idx]
                if a and b and a:IsA("BasePart") and b:IsA("BasePart") and line then
                    local sa, oa = WorldToScreen(a.Position)
                    local sb, ob = WorldToScreen(b.Position)
                    if oa and ob then
                        line.From = sa
                        line.To = sb
                        line.Color = color
                        line.Visible = true
                        idx = idx + 1
                    end
                end
            end
            for i = idx, #pack.Skel do pack.Skel[i].Visible = false end
        elseif pack.Skel then
            for _, l in ipairs(pack.Skel) do l.Visible = false end
        end
    end
end

local function UpdateHitbox()
    if not B.Settings.Brutal.HitboxExpand then return end
    local partName = B.Settings.Brutal.HitboxPart == "Head" and "Head" or nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = GetChar(p)
            if not char then continue end
            local targetPart = partName and char:FindFirstChild("Head") or GetRoot(char)
            if targetPart and targetPart:IsA("BasePart") then
                local s = B.Settings.Brutal.HitboxSize
                targetPart.Size = Vector3.new(s, s, s)
                targetPart.Transparency = 0.55
                targetPart.CanCollide = false
                targetPart.Color = (B.CurrentTarget == p) and Color3.fromRGB(255,40,40) or Color3.fromRGB(255,120,120)
            end
        end
    end
end

local function DoAutoKill()
    if not B.Settings.Brutal.AutoKill then return end
    local rate = math.clamp(B.Settings.Brutal.AttackSpeedVal, 1, 12)
    if tick() - B.LastShoot < (1/rate) then return end
    B.LastShoot = tick()
    local target = GetNearestEnemy()
    if not target then return end
    local part = GetAimPart(GetChar(target))
    if not part then return end
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        for _, r in ipairs(tool:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local n = r.Name:lower()
                if n:find("fire") or n:find("shoot") or n:find("shot") or n:find("attack") then
                    pcall(function() r:FireServer(part.Position) end)
                end
            end
        end
    end
end

local function PatchWeapon()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    if B.Settings.Brutal.AntiCooldown or B.Settings.Brutal.AttackSpeed then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n = v.Name:lower()
                if n:find("cool") or n:find("delay") or n:find("rate") or n:find("firerate") then
                    pcall(function() v.Value = 0 end)
                end
            end
        end
    end
    if B.Settings.Brutal.InfiniteAmmo then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n = v.Name:lower()
                if n:find("ammo") or n:find("clip") or n:find("mag") then
                    pcall(function() v.Value = 999 end)
                end
            end
        end
    end
end

-- Loops
AddConn(RunService.RenderStepped:Connect(function()
    if not B.Unlocked then return end
    UpdateAim()
    UpdateESP()
    UpdateHitbox()
    if B.Settings.Brutal.Fly and B.FlyBV and B.FlyBG then
        local cf = Camera.CFrame
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end
        B.FlyBV.Velocity = move.Magnitude > 0.1 and move.Unit * B.Settings.Brutal.FlySpeed or Vector3.zero
        B.FlyBG.CFrame = cf
    end
end))

AddConn(RunService.Heartbeat:Connect(function()
    if not B.Unlocked then return end
    if B.Settings.Brutal.AntiCooldown or B.Settings.Brutal.InfiniteAmmo or B.Settings.Brutal.AttackSpeed then
        PatchWeapon()
    end
    if B.Settings.Brutal.AutoKill then DoAutoKill() end
    if B.Settings.Brutal.AutoShoot then
        local t = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if t then pcall(function() t:Activate() end) end
    end
    -- light server lag attempt
    if B.Settings.LocalCfg.ServerLag then
        -- soft: occasional remote spam is too map-specific; skip heavy lag to reduce kick risk
    end
    if B.StatsLabel then
        local fps = 60
        pcall(function() fps = math.floor(1/RunService.RenderStepped:Wait()) end)
        local elapsed = math.floor(tick() - B.SessionStart)
        B.StatsLabel.Text = string.format("Players: %d | FPS: %d | Time: %02d:%02d",
            #Players:GetPlayers(), fps, math.floor(elapsed/60), elapsed%60)
    end
end))

AddConn(Players.PlayerRemoving:Connect(function(p) DestroyPack(p.UserId) end))

AddConn(CoreGui.DescendantAdded:Connect(function(obj)
    if not B.Settings.Protect.AntiKick then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local t = (obj.Text or ""):lower()
        if t:find("suspicious") or t:find("banned") or t:find("exploiting") or t:find("kicked") or t:find("timedout") then
            if B.Settings.Protect.AutoHopOnFlag then
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        end
    end
end))

-- Drag
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
AddConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end))

local function ShowPanel()
    Main.Visible = true
    Main.Size = UDim2.new(0,740,0,0)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,740,0,500)
    }):Play()
end
local function HidePanel()
    local tw = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0,740,0,0)
    })
    tw:Play()
    tw.Completed:Wait()
    Main.Visible = false
end
CloseBtn.MouseButton1Click:Connect(HidePanel)
MinBtn.MouseButton1Click:Connect(HidePanel)

AddConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl and B.Unlocked then
        if Main.Visible then HidePanel() else ShowPanel() end
    end
end))

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0,46,0,46)
OpenBtn.Position = UDim2.new(1,-58,0.5,-23)
OpenBtn.BackgroundColor3 = Color3.fromRGB(110,30,190)
OpenBtn.Text = "BX"
OpenBtn.TextColor3 = Color3.fromRGB(245,235,255)
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.TextSize = 14
OpenBtn.Visible = false
OpenBtn.ZIndex = 20
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1,0)
OpenBtn.MouseButton1Click:Connect(function()
    if Main.Visible then HidePanel() else ShowPanel() end
end)

VerifyBtn.MouseButton1Click:Connect(function()
    local input = (KeyBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    if input:upper() == ACCESS_KEY:upper() then
        StatusLbl.TextColor3 = Color3.fromRGB(100,255,160)
        StatusLbl.Text = "ACCESS GRANTED"
        B.Unlocked = true
        task.wait(0.3)
        KeyFrame.Visible = false
        LoadFrame.Visible = true
        for _, pct in ipairs({25,50,75,100}) do
            LoadBar:TweenSize(UDim2.new(pct/100,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
            LoadPct.Text = pct.."%"
            task.wait(0.3)
        end
        task.wait(0.15)
        LoadFrame.Visible = false
        OpenBtn.Visible = UserInputService.TouchEnabled
        ShowPanel()
    else
        StatusLbl.TextColor3 = Color3.fromRGB(255,80,100)
        StatusLbl.Text = "INVALID KEY"
    end
end)

print("[BAXTARA X CHEAT v5.4] Full features restored | LocalConfig | Theme | Hitbox Head/Body 27 | NUGI CENEL")
