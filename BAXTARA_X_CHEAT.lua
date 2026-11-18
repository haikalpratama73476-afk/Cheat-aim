--[[
    BAXTARA X CHEAT  v5.3
    Developer : NUGI CENEL
    UI        : Sidebar dashboard style (mockup inspired)
    Fix       : ESP cleanup, color FOV/box/tracer, safer attack speed, silent autokill
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
local Stats            = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local DrawingLib  = Drawing

getgenv().BAXTARA = getgenv().BAXTARA or {}
local B = getgenv().BAXTARA

local ACCESS_KEY = "BAXTARA X CHEAT"
local WA_URL = "https://whatsapp.com/channel/0029Vb8PluMLtOj5TTbxRl1k"

B.Settings = {
    Aim = {
        Enabled = false, VisibilityCheck = true, HeadAim = true, BodyAim = false,
        MultiBone = false, FOVCircle = true, AimDistance = 800, AimLock = false,
        AimSmoothing = 0.15, AimPrediction = false, PredictionAmount = 0.1,
        DrawTargetLine = true, FOV = 120, TeamCheck = true,
        SilentAim = false, AntiMiss = false, HitPart = "Head",
        AimMagnet = false,
    },
    ESP = {
        Enabled = false, Box = true, Name = true, HealthBar = true, Distance = true,
        Tracer = true, VisibleCheck = true, PriorityMark = true, MaxDistance = 1000,
        ColorName = "Purple",
        VisibleColor = Color3.fromRGB(180, 80, 255),
        HiddenColor = Color3.fromRGB(255, 80, 120),
        PriorityColor = Color3.fromRGB(255, 200, 50),
        TracerColor = Color3.fromRGB(200, 100, 255),
        FOVColor = Color3.fromRGB(170, 70, 255),
        BoxColor = Color3.fromRGB(180, 80, 255),
    },
    Brutal = {
        Fly = false, FlySpeed = 40, SpeedHack = false, SpeedValue = 22,
        InfiniteJump = false, Noclip = false, GodMode = false,
        HitboxExpand = false, HitboxSize = 6, HitboxRedAim = true,
        AntiCooldown = false, InfiniteAmmo = false, AutoShoot = false,
        AttackSpeed = false, AttackSpeedVal = 8, -- safe default 1-15 recommended
        AutoKill = false, DamageConfig = false, DamageValue = 100,
    },
    Visual = { FullBright = false, NoFog = false, AntiLag = false, StreamingMode = false },
    Protect = { AntiKick = true, AutoHopOnFlag = true, SoftCamera = true },
    UI = { Width = 720, Height = 480 },
}

B.Connections, B.Drawings, B.ESPObjects = {}, {}, {}
B.CurrentTarget, B.LockedTarget = nil, nil
B.OriginalCollision, B.OriginalWalkSpeed = {}, 16
B.Unlocked, B.Hopping = false, false
B.FlyBV, B.FlyBG, B.NoclipConn, B.JumpConn = nil, nil, nil, nil
B.LastShoot = 0
B.SessionStart = tick()

local function AddConn(c) table.insert(B.Connections, c) return c end

local function CleanupAll()
    for _, c in ipairs(B.Connections) do pcall(function() c:Disconnect() end) end
    B.Connections = {}
    for _, d in pairs(B.Drawings) do pcall(function() if d.Remove then d:Remove() end end) end
    B.Drawings = {}
    for _, pack in pairs(B.ESPObjects) do
        for _, d in pairs(pack) do pcall(function() if d and d.Remove then d:Remove() end end) end
    end
    B.ESPObjects = {}
    if B.FlyBV then pcall(function() B.FlyBV:Destroy() end) B.FlyBV = nil end
    if B.FlyBG then pcall(function() B.FlyBG:Destroy() end) B.FlyBG = nil end
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
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end
local function IsVisible(from, to, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    params.IgnoreWater = true
    return Workspace:Raycast(from, to - from, params) == nil
end

local ColorPresets = {
    Purple = {vis=Color3.fromRGB(180,80,255), hid=Color3.fromRGB(255,80,120), pri=Color3.fromRGB(255,200,50), tr=Color3.fromRGB(200,100,255), fov=Color3.fromRGB(170,70,255), box=Color3.fromRGB(180,80,255)},
    Green  = {vis=Color3.fromRGB(0,255,140), hid=Color3.fromRGB(255,70,70), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(0,255,180), fov=Color3.fromRGB(0,255,160), box=Color3.fromRGB(0,255,140)},
    Red    = {vis=Color3.fromRGB(255,60,60), hid=Color3.fromRGB(180,40,40), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(255,100,100), fov=Color3.fromRGB(255,80,80), box=Color3.fromRGB(255,60,60)},
    Cyan   = {vis=Color3.fromRGB(0,220,255), hid=Color3.fromRGB(255,80,80), pri=Color3.fromRGB(255,200,0), tr=Color3.fromRGB(0,255,255), fov=Color3.fromRGB(0,200,255), box=Color3.fromRGB(0,220,255)},
    Yellow = {vis=Color3.fromRGB(255,220,40), hid=Color3.fromRGB(255,80,80), pri=Color3.fromRGB(0,255,160), tr=Color3.fromRGB(255,240,100), fov=Color3.fromRGB(255,220,40), box=Color3.fromRGB(255,220,40)},
    White  = {vis=Color3.fromRGB(240,240,255), hid=Color3.fromRGB(255,100,100), pri=Color3.fromRGB(0,255,160), tr=Color3.fromRGB(220,220,255), fov=Color3.fromRGB(220,220,255), box=Color3.fromRGB(240,240,255)},
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

-- ===================== GUI ROOT =====================
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
KeyCard.Size = UDim2.new(0,320,0,360)
KeyCard.Position = UDim2.new(0.5,-160,0.5,-180)
KeyCard.BackgroundColor3 = Color3.fromRGB(16,12,30)
KeyCard.BorderSizePixel = 0
KeyCard.ZIndex = 110
KeyCard.Parent = KeyFrame
Instance.new("UICorner", KeyCard).CornerRadius = UDim.new(0,12)
local ks = Instance.new("UIStroke")
ks.Color = Color3.fromRGB(160,50,255)
ks.Thickness = 1.5
ks.Parent = KeyCard

local function KLabel(parent, text, y, size, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-24,0,size or 18)
    l.Position = UDim2.new(0,12,0,y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(200,120,255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = size or 14
    l.ZIndex = 111
    l.Parent = parent
    return l
end
KLabel(KeyCard, "BAXTARA X CHEAT", 18, 20)
KLabel(KeyCard, "SECURE ACCESS", 44, 12, Color3.fromRGB(140,100,200))
KLabel(KeyCard, "Masukkan access key", 72, 12, Color3.fromRGB(170,150,200))

local InputH = Instance.new("Frame")
InputH.Size = UDim2.new(1,-40,0,38)
InputH.Position = UDim2.new(0,20,0,110)
InputH.BackgroundColor3 = Color3.fromRGB(24,18,40)
InputH.BorderSizePixel = 0
InputH.ZIndex = 111
InputH.Parent = KeyCard
Instance.new("UICorner", InputH).CornerRadius = UDim.new(0,8)
local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1,-16,1,0)
KeyBox.Position = UDim2.new(0,8,0,0)
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

local StatusLbl = KLabel(KeyCard, "", 156, 12, Color3.fromRGB(255,80,100))

local function KBtn(text, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-40,0,36)
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
local VerifyBtn = KBtn("VERIFY KEY", 186, Color3.fromRGB(120,30,200))
KBtn("JOIN WHATSAPP", 230, Color3.fromRGB(20,90,50), function()
    pcall(function() if setclipboard then setclipboard(WA_URL) end end)
end)
KBtn("COPY KEY INFO", 274, Color3.fromRGB(40,30,70), function()
    pcall(function() if setclipboard then setclipboard("Key: BAXTARA X CHEAT") end end)
    StatusLbl.TextColor3 = Color3.fromRGB(100,255,160)
    StatusLbl.Text = "Copied"
end)

-- LOADING
local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(1,0,1,0)
LoadFrame.BackgroundColor3 = Color3.fromRGB(4,2,10)
LoadFrame.BorderSizePixel = 0
LoadFrame.Visible = false
LoadFrame.ZIndex = 90
LoadFrame.Parent = ScreenGui

for i = 1, 16 do
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0,140,0,18)
    t.Position = UDim2.new(math.random(),0,math.random(),0)
    t.BackgroundTransparency = 1
    t.Text = ({"BAXTARA","X CHEAT","EXECUTE","DOMINATE","WIN","BX"})[math.random(1,6)]
    t.TextColor3 = Color3.fromRGB(150+math.random(0,60),40,220)
    t.TextTransparency = 0.4
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 12+math.random(0,6)
    t.ZIndex = 91
    t.Parent = LoadFrame
    task.spawn(function()
        while t.Parent do
            TweenService:Create(t, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(math.random(),0,math.random(),0)
            }):Play()
            task.wait(5)
        end
    end)
end

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1,0,0,36)
LoadTitle.Position = UDim2.new(0,0,0.42,0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "BAXTARA X CHEAT"
LoadTitle.TextColor3 = Color3.fromRGB(200,100,255)
LoadTitle.Font = Enum.Font.GothamBlack
LoadTitle.TextSize = 24
LoadTitle.ZIndex = 95
LoadTitle.Parent = LoadFrame

local LoadBarBG = Instance.new("Frame")
LoadBarBG.Size = UDim2.new(0,220,0,4)
LoadBarBG.Position = UDim2.new(0.5,-110,0.55,0)
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
LoadPct.Size = UDim2.new(1,0,0,16)
LoadPct.Position = UDim2.new(0,0,0.58,0)
LoadPct.BackgroundTransparency = 1
LoadPct.Text = "0%"
LoadPct.TextColor3 = Color3.fromRGB(180,140,230)
LoadPct.Font = Enum.Font.Code
LoadPct.TextSize = 12
LoadPct.ZIndex = 95
LoadPct.Parent = LoadFrame

-- ===================== MAIN DASHBOARD UI =====================
local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.new(0, 720, 0, 480)
Main.Position = UDim2.new(0.5, -360, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.ZIndex = 10
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(140, 40, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1,0,0,42)
TopBar.BackgroundColor3 = Color3.fromRGB(14, 10, 28)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 12
TopBar.Parent = Main

local TopLogo = Instance.new("TextLabel")
TopLogo.Size = UDim2.new(0, 260, 1, 0)
TopLogo.Position = UDim2.new(0, 12, 0, 0)
TopLogo.BackgroundTransparency = 1
TopLogo.Text = "BX  BAXTARA X CHEAT"
TopLogo.TextColor3 = Color3.fromRGB(200, 120, 255)
TopLogo.Font = Enum.Font.GothamBlack
TopLogo.TextSize = 15
TopLogo.TextXAlignment = Enum.TextXAlignment.Left
TopLogo.ZIndex = 13
TopLogo.Parent = TopBar

local TopUser = Instance.new("TextLabel")
TopUser.Size = UDim2.new(0, 200, 1, 0)
TopUser.Position = UDim2.new(1, -280, 0, 0)
TopUser.BackgroundTransparency = 1
TopUser.Text = "User: "..(LocalPlayer.Name).."  |  Key: Active"
TopUser.TextColor3 = Color3.fromRGB(160, 140, 200)
TopUser.Font = Enum.Font.Code
TopUser.TextSize = 11
TopUser.TextXAlignment = Enum.TextXAlignment.Right
TopUser.ZIndex = 13
TopUser.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 120, 140)
CloseBtn.Font = Enum.Font.Code
CloseBtn.TextSize = 13
CloseBtn.ZIndex = 13
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 28)
MinBtn.Position = UDim2.new(1, -74, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 30)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(230, 220, 120)
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 14
MinBtn.ZIndex = 13
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Sidebar
local Side = Instance.new("Frame")
Side.Size = UDim2.new(0, 140, 1, -42)
Side.Position = UDim2.new(0, 0, 0, 42)
Side.BackgroundColor3 = Color3.fromRGB(12, 10, 24)
Side.BorderSizePixel = 0
Side.ZIndex = 11
Side.Parent = Main

local SideNames = {"Home", "ESP", "Aim", "Brutal", "Settings", "About"}
local SideBtns, Pages = {}, {}
local currentPage = "Home"

local function SwitchPage(name)
    currentPage = name
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
        if SideBtns[n] then
            SideBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(50, 25, 90) or Color3.fromRGB(12, 10, 24)
            SideBtns[n].TextColor3 = (n == name) and Color3.fromRGB(220, 150, 255) or Color3.fromRGB(140, 130, 170)
        end
    end
end

for i, name in ipairs(SideNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.Position = UDim2.new(0, 4, 0, 8 + (i-1)*42)
    btn.BackgroundColor3 = Color3.fromRGB(12, 10, 24)
    btn.Text = "  "..name
    btn.TextColor3 = Color3.fromRGB(140, 130, 170)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 12
    btn.Parent = Side
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    SideBtns[name] = btn
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -148, 1, -50)
    page.Position = UDim2.new(0, 144, 0, 46)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(160, 60, 255)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.ZIndex = 11
    page.Parent = Main
    Pages[name] = page
end
SwitchPage("Home")

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1,0,0,16)
Footer.Position = UDim2.new(0,0,1,-16)
Footer.BackgroundColor3 = Color3.fromRGB(10,8,18)
Footer.BorderSizePixel = 0
Footer.Text = "  BAXTARA X CHEAT v5.3  ·  GOOD GAME, BRO!  ·  NUGI CENEL"
Footer.TextColor3 = Color3.fromRGB(130, 80, 180)
Footer.Font = Enum.Font.Code
Footer.TextSize = 9
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.ZIndex = 12
Footer.Parent = Main

-- UI helpers
local function Card(parent, title, h)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, -8, 0, h or 120)
    c.BackgroundColor3 = Color3.fromRGB(18, 14, 32)
    c.BorderSizePixel = 0
    c.ZIndex = 12
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(80, 40, 140)
    st.Thickness = 1
    st.Transparency = 0.4
    st.Parent = c
    if title then
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -16, 0, 22)
        t.Position = UDim2.new(0, 10, 0, 6)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = Color3.fromRGB(200, 140, 255)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 13
        t.Parent = c
    end
    return c
end

local function MakeToggle(parent, text, default, y, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, -16, 0, 28)
    h.Position = UDim2.new(0, 8, 0, y)
    h.BackgroundTransparency = 1
    h.ZIndex = 13
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -50, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220, 210, 240)
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = h
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 40, 0, 20)
    bg.Position = UDim2.new(1, -42, 0.5, -10)
    bg.BackgroundColor3 = default and Color3.fromRGB(140, 40, 220) or Color3.fromRGB(40, 35, 55)
    bg.BorderSizePixel = 0
    bg.ZIndex = 14
    bg.Parent = h
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(245, 240, 255)
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
        TweenService:Create(bg, TweenInfo.new(0.12), {
            BackgroundColor3 = state and Color3.fromRGB(140,40,220) or Color3.fromRGB(40,35,55)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        }):Play()
        if cb then cb(state) end
    end)
    return h
end

local function MakeSlider(parent, text, min, max, default, y, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, -16, 0, 40)
    h.Position = UDim2.new(0, 8, 0, y)
    h.BackgroundTransparency = 1
    h.ZIndex = 13
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 0, 14)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220, 210, 240)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = h
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.35, 0, 0, 14)
    val.Position = UDim2.new(0.65, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = Color3.fromRGB(200, 120, 255)
    val.Font = Enum.Font.Code
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 14
    val.Parent = h
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, 0, 0, 6)
    barBG.Position = UDim2.new(0, 0, 0, 22)
    barBG.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    barBG.BorderSizePixel = 0
    barBG.ZIndex = 14
    barBG.Parent = h
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/math.max(max-min,1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(160, 60, 255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 15
    fill.Parent = barBG
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - barBG.AbsolutePosition.X) / math.max(barBG.AbsoluteSize.X,1), 0, 1)
        local v = math.floor(min + (max-min)*rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
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
    b.Size = UDim2.new(1, -16, 0, 30)
    b.Position = UDim2.new(0, 8, 0, y)
    b.BackgroundColor3 = color or Color3.fromRGB(90, 30, 160)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(245, 235, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.ZIndex = 14
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end

local function Layout(page)
    task.defer(function()
        local y = 6
        for _, ch in ipairs(page:GetChildren()) do
            if ch:IsA("GuiObject") then
                ch.Position = UDim2.new(0, 4, 0, y)
                y = y + ch.Size.Y.Offset + 8
            end
        end
        page.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end)
end

-- HOME PAGE
do
    local p = Pages.Home
    local welcome = Card(p, "Home — Selamat datang di BAXTARA X CHEAT!", 70)
    local wtxt = Instance.new("TextLabel")
    wtxt.Size = UDim2.new(1, -20, 0, 30)
    wtxt.Position = UDim2.new(0, 10, 0, 30)
    wtxt.BackgroundTransparency = 1
    wtxt.Text = "Status: Premium Access  ·  Panel aman & siap digunakan"
    wtxt.TextColor3 = Color3.fromRGB(0, 255, 160)
    wtxt.Font = Enum.Font.Code
    wtxt.TextSize = 12
    wtxt.TextXAlignment = Enum.TextXAlignment.Left
    wtxt.ZIndex = 13
    wtxt.Parent = welcome

    local info = Card(p, "Informasi Panel", 90)
    local it = Instance.new("TextLabel")
    it.Size = UDim2.new(1, -20, 0, 55)
    it.Position = UDim2.new(0, 10, 0, 28)
    it.BackgroundTransparency = 1
    it.Text = "Versi: v5.3\nDeveloper: NUGI CENEL / BAXTARA DEV\nStatus: Premium Access"
    it.TextColor3 = Color3.fromRGB(190, 170, 220)
    it.Font = Enum.Font.Code
    it.TextSize = 12
    it.TextXAlignment = Enum.TextXAlignment.Left
    it.ZIndex = 13
    it.Parent = info

    local stats = Card(p, "Statistik", 70)
    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(1, -20, 0, 35)
    st.Position = UDim2.new(0, 10, 0, 28)
    st.BackgroundTransparency = 1
    st.Text = "Player: -  |  FPS: -  |  Time: 00:00"
    st.TextColor3 = Color3.fromRGB(180, 160, 220)
    st.Font = Enum.Font.Code
    st.TextSize = 12
    st.TextXAlignment = Enum.TextXAlignment.Left
    st.ZIndex = 13
    st.Parent = stats
    B.StatsLabel = st
    Layout(p)
end

-- ESP PAGE
do
    local p = Pages.ESP
    local c = Card(p, "ESP Settings", 320)
    MakeToggle(c, "Enable ESP", false, 32, function(v) B.Settings.ESP.Enabled = v end)
    MakeToggle(c, "Box ESP", true, 62, function(v) B.Settings.ESP.Box = v end)
    MakeToggle(c, "Name", true, 92, function(v) B.Settings.ESP.Name = v end)
    MakeToggle(c, "Health Bar", true, 122, function(v) B.Settings.ESP.HealthBar = v end)
    MakeToggle(c, "Distance", true, 152, function(v) B.Settings.ESP.Distance = v end)
    MakeToggle(c, "Tracer Line", true, 182, function(v) B.Settings.ESP.Tracer = v end)
    MakeToggle(c, "Visible Check", true, 212, function(v) B.Settings.ESP.VisibleCheck = v end)
    MakeSlider(c, "Max Distance", 100, 2000, 1000, 245, function(v) B.Settings.ESP.MaxDistance = v end)
    local col = Card(p, "ESP / FOV Color", 200)
    MakeBtn(col, "Purple", 32, Color3.fromRGB(100,30,160), function() ApplyColor("Purple") end)
    MakeBtn(col, "Green", 66, Color3.fromRGB(0,100,60), function() ApplyColor("Green") end)
    MakeBtn(col, "Red", 100, Color3.fromRGB(140,30,30), function() ApplyColor("Red") end)
    MakeBtn(col, "Cyan", 134, Color3.fromRGB(0,90,120), function() ApplyColor("Cyan") end)
    MakeBtn(col, "Yellow", 168, Color3.fromRGB(120,100,20), function() ApplyColor("Yellow") end)
    Layout(p)
end

-- AIM PAGE
do
    local p = Pages.Aim
    local c = Card(p, "Aim Settings", 380)
    MakeToggle(c, "Enable Aimbot", false, 32, function(v)
        B.Settings.Aim.Enabled = v
        if v and DrawingLib then
            if not B.Drawings.FOV then
                local f = Drawing.new("Circle")
                f.Thickness = 3.5
                f.NumSides = 64
                f.Filled = false
                f.Color = B.Settings.ESP.FOVColor
                f.Transparency = 0.3
                f.Visible = false
                B.Drawings.FOV = f
            end
        end
    end)
    MakeToggle(c, "Silent Aim", false, 62, function(v) B.Settings.Aim.SilentAim = v end)
    MakeToggle(c, "Anti Miss", false, 92, function(v) B.Settings.Aim.AntiMiss = v end)
    MakeToggle(c, "Aim Lock", false, 122, function(v) B.Settings.Aim.AimLock = v if not v then B.LockedTarget = nil end end)
    MakeToggle(c, "Visibility Check", true, 152, function(v) B.Settings.Aim.VisibilityCheck = v end)
    MakeToggle(c, "Head Aim", true, 182, function(v) B.Settings.Aim.HeadAim = v B.Settings.Aim.HitPart = "Head" if v then B.Settings.Aim.BodyAim = false end end)
    MakeToggle(c, "Body Aim", false, 212, function(v) B.Settings.Aim.BodyAim = v B.Settings.Aim.HitPart = "Body" if v then B.Settings.Aim.HeadAim = false end end)
    MakeToggle(c, "FOV Circle", true, 242, function(v) B.Settings.Aim.FOVCircle = v end)
    MakeToggle(c, "Team Check", true, 272, function(v) B.Settings.Aim.TeamCheck = v end)
    MakeSlider(c, "FOV Size", 40, 1000, 120, 305, function(v) B.Settings.Aim.FOV = v end)
    MakeSlider(c, "Smoothness x100", 5, 40, 15, 345, function(v) B.Settings.Aim.AimSmoothing = v/100 end)
    Layout(p)
end

-- BRUTAL PAGE
do
    local p = Pages.Brutal
    local c = Card(p, "Brutal / Combat", 420)
    MakeToggle(c, "Fly", false, 32, function(v)
        B.Settings.Brutal.Fly = v
        -- fly handled in loop
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
    MakeSlider(c, "Fly Speed", 10, 80, 40, 62, function(v) B.Settings.Brutal.FlySpeed = v end)
    MakeToggle(c, "Speed Hack", false, 105, function(v)
        B.Settings.Brutal.SpeedHack = v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if v then B.OriginalWalkSpeed = hum.WalkSpeed hum.WalkSpeed = math.clamp(B.Settings.Brutal.SpeedValue,16,32)
            else hum.WalkSpeed = B.OriginalWalkSpeed or 16 end
        end
    end)
    MakeSlider(c, "Walk Speed", 16, 32, 22, 135, function(v)
        B.Settings.Brutal.SpeedValue = v
        if B.Settings.Brutal.SpeedHack then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end)
    MakeToggle(c, "Noclip", false, 178, function(v)
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
    MakeToggle(c, "Hitbox Expand", false, 208, function(v) B.Settings.Brutal.HitboxExpand = v end)
    MakeSlider(c, "Hitbox Size", 2, 15, 6, 238, function(v) B.Settings.Brutal.HitboxSize = v end)
    MakeToggle(c, "Anti Cooldown", false, 280, function(v) B.Settings.Brutal.AntiCooldown = v end)
    MakeToggle(c, "Infinite Ammo", false, 310, function(v) B.Settings.Brutal.InfiniteAmmo = v end)
    MakeToggle(c, "Attack Speed (safe)", false, 340, function(v) B.Settings.Brutal.AttackSpeed = v end)
    MakeSlider(c, "Attack Speed 1-12", 1, 12, 8, 370, function(v) B.Settings.Brutal.AttackSpeedVal = v end)
    MakeToggle(c, "Auto Kill (silent)", false, 412, function(v) B.Settings.Brutal.AutoKill = v end)
    Layout(p)
end

-- SETTINGS
do
    local p = Pages.Settings
    local c = Card(p, "Pengaturan Panel", 200)
    MakeToggle(c, "FullBright", false, 32, function(v)
        B.Settings.Visual.FullBright = v
        Lighting.Brightness = v and 2.2 or 1
        Lighting.GlobalShadows = not v
    end)
    MakeToggle(c, "Anti Lag", false, 62, function(v)
        B.Settings.Visual.AntiLag = v
        pcall(function()
            settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
        end)
    end)
    MakeToggle(c, "Anti-Kick", true, 92, function(v) B.Settings.Protect.AntiKick = v end)
    MakeToggle(c, "Auto Hop on Flag", true, 122, function(v) B.Settings.Protect.AutoHopOnFlag = v end)
    MakeBtn(c, "FORCE SERVER HOP", 155, Color3.fromRGB(30,70,50), function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    local c2 = Card(p, "Unload", 60)
    MakeBtn(c2, "UNLOAD SCRIPT", 28, Color3.fromRGB(90,25,35), function()
        CleanupAll()
        ScreenGui:Destroy()
        getgenv().BAXTARA = nil
    end)
    Layout(p)
end

-- ABOUT
do
    local p = Pages.About
    local c = Card(p, "Tentang", 120)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 80)
    t.Position = UDim2.new(0, 10, 0, 30)
    t.BackgroundTransparency = 1
    t.Text = "BAXTARA X CHEAT v5.3\nDeveloper: NUGI CENEL\nPLAY · EXPLOIT · DOMINATE\nKey: BAXTARA X CHEAT"
    t.TextColor3 = Color3.fromRGB(180, 150, 220)
    t.Font = Enum.Font.Code
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 13
    t.Parent = c
    Layout(p)
end

-- ===================== CORE SYSTEMS =====================
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
                                    if cross < bestScore then
                                        bestScore = cross
                                        best = p
                                    end
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
                    if d < bd and d < B.Settings.Aim.AimDistance then
                        bd = d
                        best = p
                    end
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

-- ESP with proper cleanup
local function DestroyPack(id)
    local pack = B.ESPObjects[id]
    if not pack then return end
    for _, d in pairs(pack) do
        pcall(function() if d and d.Remove then d:Remove() end end)
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
    B.ESPObjects[id] = pack
    return pack
end

local function HidePack(pack)
    if not pack then return end
    for _, d in pairs(pack) do if d then d.Visible = false end end
end

local function UpdateESP()
    -- cleanup dead / left players first
    local alive = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then alive[p.UserId] = true end
    end
    for id, _ in pairs(B.ESPObjects) do
        if not alive[id] then
            DestroyPack(id)
        end
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

        if not IsAlive(char) then
            HidePack(pack)
            continue
        end
        local root, head = GetRoot(char), GetHead(char)
        if not root or not head then HidePack(pack) continue end
        local dist = DistTo(root.Position)
        if dist > B.Settings.ESP.MaxDistance then HidePack(pack) continue end

        local top = head.Position + Vector3.new(0, 0.45, 0)
        local bot = root.Position - Vector3.new(0, 3, 0)
        local topS, on = WorldToScreen(top)
        local botS = select(1, WorldToScreen(bot))
        local rootS = select(1, WorldToScreen(root.Position))

        local vis = true
        if B.Settings.ESP.VisibleCheck then
            vis = IsVisible(camPos, head.Position, char)
        end
        local color = vis and B.Settings.ESP.VisibleColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.PriorityMark and B.CurrentTarget == player then
            color = B.Settings.ESP.PriorityColor
        end
        local boxCol = B.Settings.ESP.BoxColor
        if not vis then boxCol = B.Settings.ESP.HiddenColor end

        if B.Settings.ESP.Box and pack.Box then
            local h = math.max(math.abs(topS.Y - botS.Y), 14)
            local w = h * 0.68
            pack.Box.Size = Vector2.new(w, h)
            pack.Box.Position = Vector2.new(topS.X - w/2, topS.Y)
            pack.Box.Color = boxCol
            pack.Box.Visible = on
        else
            pack.Box.Visible = false
        end
        if B.Settings.ESP.Name and pack.Name then
            pack.Name.Text = player.DisplayName or player.Name
            pack.Name.Position = Vector2.new(topS.X, topS.Y - 14)
            pack.Name.Color = color
            pack.Name.Visible = on
        else
            pack.Name.Visible = false
        end
        if B.Settings.ESP.HealthBar and pack.Health then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                local h = math.max(math.abs(topS.Y - botS.Y), 14)
                local x = topS.X - (h*0.68)/2 - 5
                pack.Health.From = Vector2.new(x, topS.Y + h)
                pack.Health.To = Vector2.new(x, topS.Y + h*(1-pct))
                pack.Health.Color = Color3.fromRGB(255*(1-pct), 255*pct, 40)
                pack.Health.Visible = on
            end
        else
            pack.Health.Visible = false
        end
        if B.Settings.ESP.Distance and pack.Dist then
            pack.Dist.Text = string.format("[%dm]", math.floor(dist))
            pack.Dist.Position = Vector2.new(botS.X, botS.Y + 3)
            pack.Dist.Color = Color3.fromRGB(180,200,210)
            pack.Dist.Visible = on
        else
            pack.Dist.Visible = false
        end
        if B.Settings.ESP.Tracer and pack.Tracer then
            pack.Tracer.From = bottom
            pack.Tracer.To = rootS
            pack.Tracer.Color = B.Settings.ESP.TracerColor
            pack.Tracer.Visible = on
        else
            pack.Tracer.Visible = false
        end
    end
end

-- AutoKill: snap camera to nearest + fire (best-effort silent)
local function DoAutoKill()
    if not B.Settings.Brutal.AutoKill then return end
    local rate = math.clamp(B.Settings.Brutal.AttackSpeedVal, 1, 12)
    local interval = 1 / rate
    if tick() - B.LastShoot < interval then return end
    B.LastShoot = tick()

    local target = GetNearestEnemy()
    if not target then return end
    local part = GetAimPart(GetChar(target))
    if not part then return end

    -- silent-style: briefly point camera at target then fire
    local current = Camera.CFrame
    Camera.CFrame = CFrame.new(current.Position, part.Position)

    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        -- try common fire remotes
        for _, r in ipairs(tool:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local n = r.Name:lower()
                if n:find("fire") or n:find("shoot") or n:find("shot") or n:find("attack") or n:find("hit") then
                    pcall(function() r:FireServer(part.Position) end)
                    pcall(function() r:FireServer(part) end)
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

local function UpdateHitbox()
    if not B.Settings.Brutal.HitboxExpand then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local root = GetRoot(GetChar(p))
            if root then
                local s = B.Settings.Brutal.HitboxSize
                root.Size = Vector3.new(s, s, s)
                root.Transparency = 0.6
                root.CanCollide = false
                root.Color = (B.CurrentTarget == p) and Color3.fromRGB(255,40,40) or Color3.fromRGB(255,120,120)
            end
        end
    end
end

-- Fly update
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
    -- stats
    if B.StatsLabel then
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local elapsed = math.floor(tick() - B.SessionStart)
        local mm = math.floor(elapsed / 60)
        local ss = elapsed % 60
        local pc = #Players:GetPlayers()
        B.StatsLabel.Text = string.format("Player: %d  |  FPS: %d  |  Time: %02d:%02d", pc, fps, mm, ss)
    end
end))

-- player leave cleanup
AddConn(Players.PlayerRemoving:Connect(function(p)
    DestroyPack(p.UserId)
end))

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
    Main.Size = UDim2.new(0, 720, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 720, 0, 480)
    }):Play()
end
local function HidePanel()
    local tw = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 720, 0, 0)
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
OpenBtn.Size = UDim2.new(0, 46, 0, 46)
OpenBtn.Position = UDim2.new(1, -58, 0.5, -23)
OpenBtn.BackgroundColor3 = Color3.fromRGB(110, 30, 190)
OpenBtn.Text = "BX"
OpenBtn.TextColor3 = Color3.fromRGB(245, 235, 255)
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.TextSize = 14
OpenBtn.Visible = false
OpenBtn.ZIndex = 20
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1,0)
OpenBtn.MouseButton1Click:Connect(function()
    if Main.Visible then HidePanel() else ShowPanel() end
end)

-- KEY
VerifyBtn.MouseButton1Click:Connect(function()
    local input = (KeyBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    if input:upper() == ACCESS_KEY:upper() then
        StatusLbl.TextColor3 = Color3.fromRGB(100,255,160)
        StatusLbl.Text = "ACCESS GRANTED"
        B.Unlocked = true
        task.wait(0.35)
        KeyFrame.Visible = false
        LoadFrame.Visible = true
        for i, pct in ipairs({20,45,70,90,100}) do
            LoadBar:TweenSize(UDim2.new(pct/100,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
            LoadPct.Text = pct.."%"
            task.wait(0.35)
        end
        task.wait(0.2)
        LoadFrame.Visible = false
        OpenBtn.Visible = UserInputService.TouchEnabled
        ShowPanel()
    else
        StatusLbl.TextColor3 = Color3.fromRGB(255,80,100)
        StatusLbl.Text = "INVALID KEY"
    end
end)

print("[BAXTARA X CHEAT v5.3] Sidebar UI | ESP cleanup | Color FOV/Box | Safe AttackSpeed | Silent AutoKill | NUGI CENEL")
