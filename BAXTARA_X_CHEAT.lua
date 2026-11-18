--[[
    BAXTARA X CHEAT  v5.2
    Developer : NUGI CENEL
    Credit    : @BAXTARA X CHEAT
    Update    : ESP tracer + color, modern panel, attack speed, auto kill, fly fix, text loading
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
local Camera      = Workspace.CurrentCamera
local DrawingLib  = Drawing

getgenv().BAXTARA = getgenv().BAXTARA or {}
local B = getgenv().BAXTARA

local ACCESS_KEY = "BAXTARA X CHEAT"
local WA_URL = "https://whatsapp.com/channel/0029Vb8PluMLtOj5TTbxRl1k"

B.Settings = {
    Aim = {
        Enabled         = false,
        VisibilityCheck = true,
        HeadAim         = true,
        BodyAim         = false,
        MultiBone       = false,
        FOVCircle       = true,
        AimDistance     = 800,
        AimLock         = false,
        AimSmoothing    = 0.18,
        AimPrediction   = false,
        PredictionAmount= 0.12,
        DrawTargetLine  = true,
        TargetHighlight = false,
        FOV             = 200,
        TeamCheck       = true,
        SilentAim       = false,
        AntiMiss        = false,
        HitPart         = "Head",
    },
    ESP = {
        Enabled       = false,
        Box           = true,
        Name          = true,
        HealthBar     = true,
        Distance      = true,
        Tracer        = true,   -- line restored
        Skeleton      = false,
        VisibleCheck  = true,
        PriorityMark  = true,
        StatusESP     = true,
        Radar         = false,
        Offscreen     = true,
        MaxDistance   = 900,
        ColorPreset   = "Green", -- Green / Purple / Red / Cyan / Yellow / White
        VisibleColor  = Color3.fromRGB(0, 255, 140),
        HiddenColor   = Color3.fromRGB(255, 70, 70),
        PriorityColor = Color3.fromRGB(255, 200, 0),
        TracerColor   = Color3.fromRGB(0, 255, 180),
    },
    Brutal = {
        Fly            = false,
        FlySpeed       = 45,
        SpeedHack      = false,
        SpeedValue     = 24,
        InfiniteJump   = false,
        Noclip         = false,
        SuperJump      = false,
        SuperJumpPower = 80,
        NoFallDamage   = false,
        AirWalk        = false,
        GodMode        = false,
        HitboxExpand   = false,
        HitboxSize     = 8,
        HitboxRedAim   = true,
        GhostMode      = false,
        AntiCooldown    = false,
        InfiniteAmmo   = false,
        AutoReload     = false,
        AutoShoot      = false,
        AttackSpeed    = false,
        AttackSpeedVal = 10,   -- 1-25
        AutoKill       = false, -- auto fire at enemies
        DamageConfig   = false,
        DamageValue    = 150,
        OneHitNPC      = false,
        KillAllNPC     = false,
    },
    Visual = {
        FullBright       = false,
        NoFog            = false,
        StreamingMode    = false,
        StreamingOpacity = 0.4,
        AntiLag          = false,
    },
    Protect = {
        AntiKick         = true,
        AutoHopOnFlag    = true,
        SoftCamera       = true,
    },
    UI = {
        Accent     = Color3.fromRGB(160, 50, 255),
        Accent2    = Color3.fromRGB(0, 255, 160),
        Background = Color3.fromRGB(9, 8, 16),
        Card       = Color3.fromRGB(18, 15, 28),
        Text       = Color3.fromRGB(235, 230, 255),
        Width      = 430,
        Height     = 580,
    }
}

B.Connections = {}
B.Drawings = {}
B.Highlights = {}
B.ESPObjects = {}
B.CurrentTarget = nil
B.LockedTarget = nil
B.OriginalCollision = {}
B.OriginalTransparency = {}
B.OriginalWalkSpeed = 16
B.OriginalJumpPower = 50
B.OriginalJumpHeight = 7.2
B.Hopping = false
B.Unlocked = false
B.FlyBV = nil
B.FlyBG = nil
B.NoclipConn = nil
B.JumpConn = nil
B.LastShoot = 0

local function AddConn(c)
    table.insert(B.Connections, c)
    return c
end

local function CleanupAll()
    for _, c in ipairs(B.Connections) do pcall(function() c:Disconnect() end) end
    B.Connections = {}
    for _, d in pairs(B.Drawings) do pcall(function() if d.Remove then d:Remove() end end) end
    B.Drawings = {}
    for _, h in pairs(B.Highlights) do pcall(function() h:Destroy() end) end
    B.Highlights = {}
    for _, pack in pairs(B.ESPObjects) do
        for k, d in pairs(pack) do
            if type(d) == "table" then
                for _, l in pairs(d) do pcall(function() if l and l.Remove then l:Remove() end end) end
            else
                pcall(function() if d and d.Remove then d:Remove() end end)
            end
        end
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
    Green  = {vis = Color3.fromRGB(0,255,140), hid = Color3.fromRGB(255,70,70), pri = Color3.fromRGB(255,200,0), tr = Color3.fromRGB(0,255,180)},
    Purple = {vis = Color3.fromRGB(180,80,255), hid = Color3.fromRGB(255,80,120), pri = Color3.fromRGB(255,180,50), tr = Color3.fromRGB(200,100,255)},
    Red    = {vis = Color3.fromRGB(255,60,60), hid = Color3.fromRGB(180,40,40), pri = Color3.fromRGB(255,200,0), tr = Color3.fromRGB(255,100,100)},
    Cyan   = {vis = Color3.fromRGB(0,220,255), hid = Color3.fromRGB(255,80,80), pri = Color3.fromRGB(255,200,0), tr = Color3.fromRGB(0,255,255)},
    Yellow = {vis = Color3.fromRGB(255,220,40), hid = Color3.fromRGB(255,80,80), pri = Color3.fromRGB(0,255,160), tr = Color3.fromRGB(255,240,100)},
    White  = {vis = Color3.fromRGB(240,240,255), hid = Color3.fromRGB(255,100,100), pri = Color3.fromRGB(0,255,160), tr = Color3.fromRGB(220,220,255)},
}
local function ApplyESPColor(name)
    local p = ColorPresets[name] or ColorPresets.Green
    B.Settings.ESP.ColorPreset = name
    B.Settings.ESP.VisibleColor = p.vis
    B.Settings.ESP.HiddenColor = p.hid
    B.Settings.ESP.PriorityColor = p.pri
    B.Settings.ESP.TracerColor = p.tr
end

-- ===================== ROOT GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BAXTARA_X_CHEAT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = CoreGui

-- ===================== KEY ACCESS =====================
local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(1,0,1,0)
KeyFrame.BackgroundColor3 = Color3.fromRGB(5, 3, 12)
KeyFrame.BorderSizePixel = 0
KeyFrame.ZIndex = 100
KeyFrame.Parent = ScreenGui

for i = 1, 4 do
    local fog = Instance.new("Frame")
    fog.Size = UDim2.new(1.3,0,0.3,0)
    fog.Position = UDim2.new(-0.15,0,0.15+i*0.18,0)
    fog.BackgroundColor3 = Color3.fromRGB(80+i*25, 20, 150)
    fog.BackgroundTransparency = 0.9
    fog.BorderSizePixel = 0
    fog.ZIndex = 101
    fog.Parent = KeyFrame
    Instance.new("UICorner", fog).CornerRadius = UDim.new(1,0)
end

local KeyCard = Instance.new("Frame")
KeyCard.Size = UDim2.new(0, 340, 0, 400)
KeyCard.Position = UDim2.new(0.5, -170, 0.5, -200)
KeyCard.BackgroundColor3 = Color3.fromRGB(14, 10, 26)
KeyCard.BorderSizePixel = 0
KeyCard.ZIndex = 110
KeyCard.Parent = KeyFrame
Instance.new("UICorner", KeyCard).CornerRadius = UDim.new(0, 14)
local ks = Instance.new("UIStroke")
ks.Color = Color3.fromRGB(160, 50, 255)
ks.Thickness = 1.6
ks.Parent = KeyCard

local KeyLogo = Instance.new("TextLabel")
KeyLogo.Size = UDim2.new(1,-20,0,34)
KeyLogo.Position = UDim2.new(0,10,0,16)
KeyLogo.BackgroundTransparency = 1
KeyLogo.Text = "BAXTARA X CHEAT"
KeyLogo.TextColor3 = Color3.fromRGB(200, 100, 255)
KeyLogo.Font = Enum.Font.GothamBlack
KeyLogo.TextSize = 20
KeyLogo.ZIndex = 111
KeyLogo.Parent = KeyCard

local KeySub = Instance.new("TextLabel")
KeySub.Size = UDim2.new(1,-20,0,16)
KeySub.Position = UDim2.new(0,10,0,50)
KeySub.BackgroundTransparency = 1
KeySub.Text = "SECURE ACCESS TERMINAL"
KeySub.TextColor3 = Color3.fromRGB(140, 100, 200)
KeySub.Font = Enum.Font.Code
KeySub.TextSize = 11
KeySub.ZIndex = 111
KeySub.Parent = KeyCard

local KeyDesc = Instance.new("TextLabel")
KeyDesc.Size = UDim2.new(1,-30,0,32)
KeyDesc.Position = UDim2.new(0,15,0,76)
KeyDesc.BackgroundTransparency = 1
KeyDesc.Text = "Masukkan access key untuk membuka panel."
KeyDesc.TextColor3 = Color3.fromRGB(180, 160, 210)
KeyDesc.Font = Enum.Font.Code
KeyDesc.TextSize = 11
KeyDesc.ZIndex = 111
KeyDesc.Parent = KeyCard

local InputHolder = Instance.new("Frame")
InputHolder.Size = UDim2.new(1,-40,0,40)
InputHolder.Position = UDim2.new(0,20,0,120)
InputHolder.BackgroundColor3 = Color3.fromRGB(22, 16, 36)
InputHolder.BorderSizePixel = 0
InputHolder.ZIndex = 111
InputHolder.Parent = KeyCard
Instance.new("UICorner", InputHolder).CornerRadius = UDim.new(0,8)
local is = Instance.new("UIStroke")
is.Color = Color3.fromRGB(100, 50, 160)
is.Thickness = 1.2
is.Parent = InputHolder

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1,-16,1,0)
KeyBox.Position = UDim2.new(0,8,0,0)
KeyBox.BackgroundTransparency = 1
KeyBox.PlaceholderText = "ENTER YOUR ACCESS KEY"
KeyBox.PlaceholderColor3 = Color3.fromRGB(100, 80, 130)
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(230, 210, 255)
KeyBox.Font = Enum.Font.Code
KeyBox.TextSize = 13
KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.ClearTextOnFocus = false
KeyBox.ZIndex = 112
KeyBox.Parent = InputHolder

KeyBox.Focused:Connect(function()
    TweenService:Create(is, TweenInfo.new(0.15), {Color = Color3.fromRGB(180, 80, 255)}):Play()
end)
KeyBox.FocusLost:Connect(function()
    TweenService:Create(is, TweenInfo.new(0.15), {Color = Color3.fromRGB(100, 50, 160)}):Play()
end)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1,-40,0,18)
StatusLbl.Position = UDim2.new(0,20,0,168)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = ""
StatusLbl.Font = Enum.Font.Code
StatusLbl.TextSize = 12
StatusLbl.ZIndex = 111
StatusLbl.Parent = KeyCard

local function MakeKeyBtn(text, y, color, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-40,0,38)
    btn.Position = UDim2.new(0,20,0,y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 245, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 111
    btn.Parent = KeyCard
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(200, 100, 255)
    st.Thickness = 1
    st.Transparency = 0.4
    st.Parent = btn
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.07), {BackgroundTransparency = 0.25}):Play()
        task.wait(0.07)
        TweenService:Create(btn, TweenInfo.new(0.07), {BackgroundTransparency = 0}):Play()
        if cb then cb() end
    end)
    return btn
end

local VerifyBtn = MakeKeyBtn("VERIFY KEY", 198, Color3.fromRGB(120, 30, 200))
MakeKeyBtn("JOIN WHATSAPP CHANNEL", 244, Color3.fromRGB(20, 90, 50), function()
    pcall(function()
        if setclipboard then setclipboard(WA_URL) end
        StarterGui:SetCore("SendNotification", {Title="BAXTARA", Text="WhatsApp link copied", Duration=3})
    end)
end)
MakeKeyBtn("COPY KEY INFO", 290, Color3.fromRGB(40, 30, 70), function()
    pcall(function()
        if setclipboard then setclipboard("Key: BAXTARA X CHEAT\nWA: "..WA_URL) end
        StatusLbl.TextColor3 = Color3.fromRGB(100,255,160)
        StatusLbl.Text = "Key info copied"
    end)
end)

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1,-30,0,36)
Hint.Position = UDim2.new(0,15,0,340)
Hint.BackgroundTransparency = 1
Hint.Text = "Belum punya key? Join saluran resmi\nuntuk info access key."
Hint.TextColor3 = Color3.fromRGB(120, 100, 150)
Hint.Font = Enum.Font.Code
Hint.TextSize = 10
Hint.ZIndex = 111
Hint.Parent = KeyCard

-- ===================== TEXT LOADING (moving names) =====================
local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(1,0,1,0)
LoadFrame.BackgroundColor3 = Color3.fromRGB(3, 2, 8)
LoadFrame.BorderSizePixel = 0
LoadFrame.Visible = false
LoadFrame.ZIndex = 90
LoadFrame.Parent = ScreenGui

local floatingTexts = {}
local names = {"BAXTARA","X CHEAT","NUGI CENEL","EXECUTE","DOMINATE","WIN","BX","AIM","ESP","BRUTAL"}
for i = 1, 22 do
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0, 160, 0, 20)
    t.Position = UDim2.new(math.random(), 0, math.random(), 0)
    t.BackgroundTransparency = 1
    t.Text = names[(i % #names) + 1]
    t.TextColor3 = Color3.fromRGB(140 + math.random(0,80), 40, 220)
    t.TextTransparency = 0.35 + math.random() * 0.4
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 11 + math.random(0,8)
    t.ZIndex = 91
    t.Parent = LoadFrame
    table.insert(floatingTexts, t)
    task.spawn(function()
        while t.Parent do
            local nx, ny = math.random(), math.random()
            TweenService:Create(t, TweenInfo.new(4 + math.random()*3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(nx, 0, ny, 0),
                TextTransparency = 0.25 + math.random()*0.5
            }):Play()
            task.wait(4.5)
        end
    end)
end

local LoadCenter = Instance.new("Frame")
LoadCenter.Size = UDim2.new(0, 260, 0, 260)
LoadCenter.Position = UDim2.new(0.5, -130, 0.5, -150)
LoadCenter.BackgroundTransparency = 1
LoadCenter.ZIndex = 95
LoadCenter.Parent = LoadFrame

local Ring = Instance.new("Frame")
Ring.Size = UDim2.new(1,0,1,0)
Ring.BackgroundTransparency = 1
Ring.ZIndex = 96
Ring.Parent = LoadCenter
Instance.new("UICorner", Ring).CornerRadius = UDim.new(1,0)
local RingStroke = Instance.new("UIStroke")
RingStroke.Color = Color3.fromRGB(160, 50, 255)
RingStroke.Thickness = 3
RingStroke.Parent = Ring

local MainLogo = Instance.new("TextLabel")
MainLogo.Size = UDim2.new(1,0,0,40)
MainLogo.Position = UDim2.new(0,0,0.38,0)
MainLogo.BackgroundTransparency = 1
MainLogo.Text = "BAXTARA X CHEAT"
MainLogo.TextColor3 = Color3.fromRGB(200, 100, 255)
MainLogo.Font = Enum.Font.GothamBlack
MainLogo.TextSize = 22
MainLogo.ZIndex = 97
MainLogo.Parent = LoadCenter

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1,0,0,18)
LoadStatus.Position = UDim2.new(0,0,0.78,0)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "INITIALIZING..."
LoadStatus.TextColor3 = Color3.fromRGB(160, 120, 220)
LoadStatus.Font = Enum.Font.Code
LoadStatus.TextSize = 12
LoadStatus.ZIndex = 97
LoadStatus.Parent = LoadFrame

local LoadBarBG = Instance.new("Frame")
LoadBarBG.Size = UDim2.new(0, 240, 0, 4)
LoadBarBG.Position = UDim2.new(0.5, -120, 0.84, 0)
LoadBarBG.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
LoadBarBG.BorderSizePixel = 0
LoadBarBG.ZIndex = 97
LoadBarBG.Parent = LoadFrame
Instance.new("UICorner", LoadBarBG).CornerRadius = UDim.new(1,0)
local LoadBar = Instance.new("Frame")
LoadBar.Size = UDim2.new(0,0,1,0)
LoadBar.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
LoadBar.BorderSizePixel = 0
LoadBar.ZIndex = 98
LoadBar.Parent = LoadBarBG
Instance.new("UICorner", LoadBar).CornerRadius = UDim.new(1,0)
local LoadPct = Instance.new("TextLabel")
LoadPct.Size = UDim2.new(1,0,0,14)
LoadPct.Position = UDim2.new(0,0,0.87,0)
LoadPct.BackgroundTransparency = 1
LoadPct.Text = "0%"
LoadPct.TextColor3 = Color3.fromRGB(180, 140, 230)
LoadPct.Font = Enum.Font.Code
LoadPct.TextSize = 11
LoadPct.ZIndex = 97
LoadPct.Parent = LoadFrame

-- ===================== MAIN PANEL =====================
local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.new(0, B.Settings.UI.Width, 0, B.Settings.UI.Height)
Main.Position = UDim2.new(0.5, -B.Settings.UI.Width/2, 0.5, -B.Settings.UI.Height/2)
Main.BackgroundColor3 = B.Settings.UI.Background
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.ZIndex = 10
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(150, 50, 255)
MainStroke.Thickness = 1.6
MainStroke.Transparency = 0.2
MainStroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,50)
Header.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
Header.BorderSizePixel = 0
Header.ZIndex = 11
Header.Parent = Main
local hg = Instance.new("UIGradient")
hg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 15, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 30, 50))
}
hg.Parent = Header

local HLogo = Instance.new("TextLabel")
HLogo.Size = UDim2.new(0,48,0,48)
HLogo.Position = UDim2.new(0,6,0,1)
HLogo.BackgroundTransparency = 1
HLogo.Text = "BX"
HLogo.TextColor3 = Color3.fromRGB(190, 90, 255)
HLogo.Font = Enum.Font.GothamBlack
HLogo.TextSize = 22
HLogo.ZIndex = 12
HLogo.Parent = Header

local HTitle = Instance.new("TextLabel")
HTitle.Size = UDim2.new(1,-130,1,0)
HTitle.Position = UDim2.new(0,54,0,0)
HTitle.BackgroundTransparency = 1
HTitle.Text = "BAXTARA X CHEAT  ·  v5.2"
HTitle.TextColor3 = Color3.fromRGB(220, 180, 255)
HTitle.Font = Enum.Font.Code
HTitle.TextSize = 13
HTitle.TextXAlignment = Enum.TextXAlignment.Left
HTitle.ZIndex = 12
HTitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,34,0,34)
CloseBtn.Position = UDim2.new(1,-42,0.5,-17)
CloseBtn.BackgroundColor3 = Color3.fromRGB(55, 20, 45)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 120, 140)
CloseBtn.Font = Enum.Font.Code
CloseBtn.TextSize = 14
CloseBtn.ZIndex = 12
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,34,0,34)
MinBtn.Position = UDim2.new(1,-80,0.5,-17)
MinBtn.BackgroundColor3 = Color3.fromRGB(45, 40, 30)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(230, 220, 120)
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 16
MinBtn.ZIndex = 12
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,8)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,36)
TabBar.Position = UDim2.new(0,0,0,50)
TabBar.BackgroundColor3 = Color3.fromRGB(12, 10, 22)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 11
TabBar.Parent = Main

local TabNames = {"HOME","AIM","ESP","BRUTAL","SETTINGS"}
local TabBtns, TabFrames = {}, {}
local function SwitchTab(name)
    for n, f in pairs(TabFrames) do
        f.Visible = (n == name)
        TabBtns[n].TextColor3 = (n == name) and Color3.fromRGB(210, 130, 255) or Color3.fromRGB(130, 120, 160)
        TabBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(45, 25, 80) or Color3.fromRGB(12, 10, 22)
    end
end

for i, name in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2,0,1,0)
    btn.Position = UDim2.new((i-1)*0.2,0,0,0)
    btn.BackgroundColor3 = Color3.fromRGB(12,10,22)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(130,120,160)
    btn.Font = Enum.Font.Code
    btn.TextSize = 11
    btn.ZIndex = 12
    btn.Parent = TabBar
    TabBtns[name] = btn
    local sc = Instance.new("ScrollingFrame")
    sc.Size = UDim2.new(1,-12,1,-94)
    sc.Position = UDim2.new(0,6,0,90)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(160,60,255)
    sc.CanvasSize = UDim2.new(0,0,0,0)
    sc.Visible = false
    sc.ZIndex = 11
    sc.Parent = Main
    TabFrames[name] = sc
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end
SwitchTab("HOME")

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1,0,0,16)
Footer.Position = UDim2.new(0,0,1,-16)
Footer.BackgroundColor3 = Color3.fromRGB(10,8,18)
Footer.BorderSizePixel = 0
Footer.Text = "  NUGI CENEL  ·  @BAXTARA X CHEAT  ·  EXECUTE · DOMINATE · WIN"
Footer.TextColor3 = Color3.fromRGB(140,80,200)
Footer.Font = Enum.Font.Code
Footer.TextSize = 9
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.ZIndex = 12
Footer.Parent = Main

-- UI helpers
local function MakeSection(parent, title)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,20)
    h.BackgroundTransparency = 1
    h.ZIndex = 12
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = "▸ "..title
    l.TextColor3 = Color3.fromRGB(180,100,255)
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 13
    l.Parent = h
    return h
end

local function MakeToggle(parent, text, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,32)
    h.BackgroundColor3 = B.Settings.UI.Card
    h.BorderSizePixel = 0
    h.ZIndex = 12
    h.Parent = parent
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,8)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-56,1,0)
    l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 13
    l.Parent = h
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0,44,0,22)
    bg.Position = UDim2.new(1,-52,0.5,-11)
    bg.BackgroundColor3 = default and Color3.fromRGB(140,40,220) or Color3.fromRGB(40,35,55)
    bg.BorderSizePixel = 0
    bg.ZIndex = 13
    bg.Parent = h
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,18,0,18)
    knob.Position = default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3 = Color3.fromRGB(245,240,255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 14
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 15
    btn.Parent = h
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(bg, TweenInfo.new(0.14), {
            BackgroundColor3 = state and Color3.fromRGB(140,40,220) or Color3.fromRGB(40,35,55)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.14), {
            Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
        }):Play()
        if cb then cb(state) end
    end)
    return h
end

local function MakeSlider(parent, text, min, max, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,46)
    h.BackgroundColor3 = B.Settings.UI.Card
    h.BorderSizePixel = 0
    h.ZIndex = 12
    h.Parent = parent
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,8)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-56,0,16)
    l.Position = UDim2.new(0,12,0,6)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 13
    l.Parent = h
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0,50,0,16)
    val.Position = UDim2.new(1,-56,0,6)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = Color3.fromRGB(200,120,255)
    val.Font = Enum.Font.Code
    val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 13
    val.Parent = h
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1,-24,0,8)
    barBG.Position = UDim2.new(0,12,0,28)
    barBG.BackgroundColor3 = Color3.fromRGB(35,30,50)
    barBG.BorderSizePixel = 0
    barBG.ZIndex = 13
    barBG.Parent = h
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/math.max(max-min,1),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(160,60,255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 14
    fill.Parent = barBG
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - barBG.AbsolutePosition.X) / math.max(barBG.AbsoluteSize.X,1), 0, 1)
        local v = math.floor(min + (max-min)*rel + 0.5)
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

local function MakeButton(parent, text, color, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,36)
    h.BackgroundTransparency = 1
    h.ZIndex = 12
    h.Parent = parent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = color or Color3.fromRGB(100,30,170)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(245,235,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 13
    btn.Parent = h
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(180,80,255)
    st.Thickness = 1
    st.Transparency = 0.4
    st.Parent = btn
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.06), {BackgroundTransparency = 0.2}):Play()
        task.wait(0.06)
        TweenService:Create(btn, TweenInfo.new(0.06), {BackgroundTransparency = 0}):Play()
        if cb then cb() end
    end)
    return h
end

local function Layout(frame)
    task.defer(function()
        local y = 4
        for _, ch in ipairs(frame:GetChildren()) do
            if ch:IsA("GuiObject") then
                ch.Position = UDim2.new(0,0,0,y)
                y = y + (ch.AbsoluteSize.Y > 0 and ch.AbsoluteSize.Y or ch.Size.Y.Offset) + 5
            end
        end
        frame.CanvasSize = UDim2.new(0,0,0,y + 12)
    end)
end

-- HOME
do
    local f = TabFrames.HOME
    local av = Instance.new("Frame")
    av.Size = UDim2.new(1,-4,0,96)
    av.BackgroundColor3 = Color3.fromRGB(20,14,34)
    av.BorderSizePixel = 0
    av.ZIndex = 12
    av.Parent = f
    Instance.new("UICorner", av).CornerRadius = UDim.new(0,12)
    local avStroke = Instance.new("UIStroke")
    avStroke.Color = Color3.fromRGB(150,50,255)
    avStroke.Thickness = 1.2
    avStroke.Parent = av

    local avIcon = Instance.new("TextLabel")
    avIcon.Size = UDim2.new(0,64,0,64)
    avIcon.Position = UDim2.new(0,14,0.5,-32)
    avIcon.BackgroundColor3 = Color3.fromRGB(35,18,60)
    avIcon.Text = "👤"
    avIcon.TextSize = 28
    avIcon.ZIndex = 13
    avIcon.Parent = av
    Instance.new("UICorner", avIcon).CornerRadius = UDim.new(1,0)

    local avName = Instance.new("TextLabel")
    avName.Size = UDim2.new(1,-100,0,24)
    avName.Position = UDim2.new(0,90,0,22)
    avName.BackgroundTransparency = 1
    avName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
    avName.TextColor3 = Color3.fromRGB(235,210,255)
    avName.Font = Enum.Font.GothamBold
    avName.TextSize = 16
    avName.TextXAlignment = Enum.TextXAlignment.Left
    avName.ZIndex = 13
    avName.Parent = av

    local avSub = Instance.new("TextLabel")
    avSub.Size = UDim2.new(1,-100,0,18)
    avSub.Position = UDim2.new(0,90,0,48)
    avSub.BackgroundTransparency = 1
    avSub.Text = "@"..LocalPlayer.Name.."  ·  ONLINE"
    avSub.TextColor3 = Color3.fromRGB(0,255,160)
    avSub.Font = Enum.Font.Code
    avSub.TextSize = 11
    avSub.TextXAlignment = Enum.TextXAlignment.Left
    avSub.ZIndex = 13
    avSub.Parent = av

    task.spawn(function()
        while av.Parent do
            TweenService:Create(avStroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.55}):Play()
            task.wait(1.1)
            TweenService:Create(avStroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.05}):Play()
            task.wait(1.1)
        end
    end)

    MakeSection(f, "Quick Status")
    local statusCard = Instance.new("Frame")
    statusCard.Size = UDim2.new(1,-4,0,72)
    statusCard.BackgroundColor3 = Color3.fromRGB(20,14,34)
    statusCard.BorderSizePixel = 0
    statusCard.ZIndex = 12
    statusCard.Parent = f
    Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0,10)
    local stTxt = Instance.new("TextLabel")
    stTxt.Size = UDim2.new(1,-16,1,0)
    stTxt.Position = UDim2.new(0,10,0,0)
    stTxt.BackgroundTransparency = 1
    stTxt.Text = "Aim: OFF  |  Silent: OFF\nESP: OFF  |  AutoKill: OFF\nProtect: Anti-Kick ON"
    stTxt.TextColor3 = Color3.fromRGB(180,160,220)
    stTxt.Font = Enum.Font.Code
    stTxt.TextSize = 12
    stTxt.TextXAlignment = Enum.TextXAlignment.Left
    stTxt.TextYAlignment = Enum.TextYAlignment.Center
    stTxt.ZIndex = 13
    stTxt.Parent = statusCard
    B.HomeStatus = stTxt

    MakeSection(f, "Panel Size")
    MakeSlider(f, "Width", 340, 540, B.Settings.UI.Width, function(v)
        B.Settings.UI.Width = v
        Main.Size = UDim2.new(0, v, 0, B.Settings.UI.Height)
    end)
    MakeSlider(f, "Height", 440, 700, B.Settings.UI.Height, function(v)
        B.Settings.UI.Height = v
        Main.Size = UDim2.new(0, B.Settings.UI.Width, 0, v)
    end)
    Layout(f)
end

-- ===================== AIM / ESP / COMBAT CORE =====================
local FOVCircle, TargetLine
local function MakeFOV()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if not DrawingLib then return end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 4.0
    FOVCircle.NumSides = 64
    FOVCircle.Radius = B.Settings.Aim.FOV
    FOVCircle.Filled = false
    FOVCircle.Color = Color3.fromRGB(170, 70, 255)
    FOVCircle.Transparency = 0.25
    FOVCircle.Visible = false
    B.Drawings.FOV = FOVCircle
end
local function MakeLine()
    if TargetLine then pcall(function() TargetLine:Remove() end) end
    if not DrawingLib then return end
    TargetLine = Drawing.new("Line")
    TargetLine.Thickness = 1.6
    TargetLine.Color = Color3.fromRGB(200, 100, 255)
    TargetLine.Transparency = 0.3
    TargetLine.Visible = false
    B.Drawings.TargetLine = TargetLine
end

local function GetAimPart(char)
    if B.Settings.Aim.HitPart == "Body" or B.Settings.Aim.BodyAim then
        return GetRoot(char) or GetHead(char)
    end
    if B.Settings.Aim.MultiBone then
        for _, n in ipairs({"Head","HumanoidRootPart","UpperTorso"}) do
            local p = char:FindFirstChild(n)
            if p then return p end
        end
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
                        local screen, onScreen = WorldToScreen(part.Position)
                        if onScreen then
                            local cross = (screen - center).Magnitude
                            if cross <= fov then
                                local visible = IsVisible(camPos, part.Position, char)
                                if not (B.Settings.Aim.VisibilityCheck and not visible) then
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

local function AimAt(target)
    if not target then return end
    local char = GetChar(target)
    if not IsAlive(char) then
        if B.LockedTarget == target then B.LockedTarget = nil end
        return
    end
    local part = GetAimPart(char)
    if not part then return end
    if B.Settings.Aim.VisibilityCheck and not IsVisible(Camera.CFrame.Position, part.Position, char) then
        B.LockedTarget = nil
        return
    end
    local pos = part.Position
    if B.Settings.Aim.AimPrediction then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        pos = pos + vel * B.Settings.Aim.PredictionAmount
    end
    local current = Camera.CFrame
    local goal = CFrame.new(current.Position, pos)
    local smooth = B.Settings.Aim.AimSmoothing
    if B.Settings.Aim.SilentAim then smooth = 0.65 end
    if B.Settings.Aim.AntiMiss then smooth = math.clamp(smooth + 0.2, 0.12, 0.55) end
    if B.Settings.Protect.SoftCamera and not B.Settings.Aim.SilentAim then
        smooth = math.clamp(smooth * 0.75, 0.05, 0.3)
    end
    Camera.CFrame = current:Lerp(goal, smooth)
end

local function UpdateAim()
    if not B.Settings.Aim.Enabled then
        if FOVCircle then FOVCircle.Visible = false end
        if TargetLine then TargetLine.Visible = false end
        B.CurrentTarget = nil
        return
    end
    local center = ScreenCenter()
    if FOVCircle and B.Settings.Aim.FOVCircle then
        FOVCircle.Position = center
        FOVCircle.Radius = B.Settings.Aim.FOV
        FOVCircle.Thickness = 4.0
        FOVCircle.Visible = true
    elseif FOVCircle then
        FOVCircle.Visible = false
    end

    if B.Settings.Aim.AimLock and B.LockedTarget then
        local char = GetChar(B.LockedTarget)
        if not IsAlive(char) then
            B.LockedTarget = nil
        else
            local part = GetAimPart(char)
            if part then
                local screen, on = WorldToScreen(part.Position)
                local vis = true
                if B.Settings.Aim.VisibilityCheck then
                    vis = IsVisible(Camera.CFrame.Position, part.Position, char)
                end
                if not on or not vis or (screen - center).Magnitude > B.Settings.Aim.FOV * 1.8 then
                    B.LockedTarget = nil
                end
            else
                B.LockedTarget = nil
            end
        end
    end

    local target = (B.Settings.Aim.AimLock and B.LockedTarget) or GetBestTarget()
    if B.Settings.Aim.AimLock and not B.LockedTarget and target then
        B.LockedTarget = target
    end
    if not B.Settings.Aim.AimLock then B.LockedTarget = nil end
    B.CurrentTarget = target

    if target then
        AimAt(target)
        if TargetLine and B.Settings.Aim.DrawTargetLine then
            local part = GetAimPart(GetChar(target))
            if part then
                local screen, on = WorldToScreen(part.Position)
                if on then
                    TargetLine.From = center
                    TargetLine.To = screen
                    TargetLine.Visible = true
                else
                    TargetLine.Visible = false
                end
            end
        end
    else
        if TargetLine then TargetLine.Visible = false end
    end
end

-- ESP with Tracer
local function GetESPPack(player)
    local id = player.UserId
    if B.ESPObjects[id] then return B.ESPObjects[id] end
    local pack = {}
    if DrawingLib then
        pack.Box = Drawing.new("Square")
        pack.Box.Thickness = 1.5
        pack.Box.Filled = false
        pack.Box.Visible = false
        pack.Name = Drawing.new("Text")
        pack.Name.Size = 13
        pack.Name.Center = true
        pack.Name.Outline = true
        pack.Name.Visible = false
        pack.Health = Drawing.new("Line")
        pack.Health.Thickness = 2.3
        pack.Health.Visible = false
        pack.Dist = Drawing.new("Text")
        pack.Dist.Size = 11
        pack.Dist.Center = true
        pack.Dist.Outline = true
        pack.Dist.Visible = false
        pack.Tracer = Drawing.new("Line")
        pack.Tracer.Thickness = 1.4
        pack.Tracer.Visible = false
    end
    B.ESPObjects[id] = pack
    return pack
end

local function HidePack(pack)
    if not pack then return end
    for _, d in pairs(pack) do
        if d and d.Visible ~= nil then d.Visible = false end
    end
end

local function UpdatePlayerESP()
    if not B.Settings.ESP.Enabled then
        for _, pack in pairs(B.ESPObjects) do HidePack(pack) end
        return
    end
    local camPos = Camera.CFrame.Position
    local vp = Camera.ViewportSize
    local centerBottom = Vector2.new(vp.X/2, vp.Y)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = GetChar(player)
        local pack = GetESPPack(player)
        if not IsAlive(char) then HidePack(pack) continue end
        local root, head = GetRoot(char), GetHead(char)
        if not root or not head then HidePack(pack) continue end
        local dist = DistTo(root.Position)
        if dist > B.Settings.ESP.MaxDistance then HidePack(pack) continue end

        local top = head.Position + Vector3.new(0, 0.5, 0)
        local bottom = root.Position - Vector3.new(0, 3, 0)
        local topS, on = WorldToScreen(top)
        local botS = select(1, WorldToScreen(bottom))
        local rootS = select(1, WorldToScreen(root.Position))

        local visible = true
        if B.Settings.ESP.VisibleCheck then
            visible = IsVisible(camPos, head.Position, char)
        end
        local color = visible and B.Settings.ESP.VisibleColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.PriorityMark and B.CurrentTarget == player then
            color = B.Settings.ESP.PriorityColor
        end

        if B.Settings.ESP.Box and pack.Box then
            local h = math.max(math.abs(topS.Y - botS.Y), 16)
            local w = h * 0.7
            pack.Box.Size = Vector2.new(w, h)
            pack.Box.Position = Vector2.new(topS.X - w/2, topS.Y)
            pack.Box.Color = color
            pack.Box.Visible = on
        end
        if B.Settings.ESP.Name and pack.Name then
            pack.Name.Text = player.DisplayName or player.Name
            pack.Name.Position = Vector2.new(topS.X, topS.Y - 15)
            pack.Name.Color = color
            pack.Name.Visible = on
        end
        if B.Settings.ESP.HealthBar and pack.Health then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                local h = math.max(math.abs(topS.Y - botS.Y), 16)
                local x = topS.X - (h*0.7)/2 - 5
                pack.Health.From = Vector2.new(x, topS.Y + h)
                pack.Health.To = Vector2.new(x, topS.Y + h*(1-pct))
                pack.Health.Color = Color3.fromRGB(255*(1-pct), 255*pct, 40)
                pack.Health.Visible = on
            end
        end
        if B.Settings.ESP.Distance and pack.Dist then
            pack.Dist.Text = string.format("[%dm]", math.floor(dist))
            pack.Dist.Position = Vector2.new(botS.X, botS.Y + 4)
            pack.Dist.Color = Color3.fromRGB(180,200,210)
            pack.Dist.Visible = on
        end
        -- TRACER LINE (restored)
        if B.Settings.ESP.Tracer and pack.Tracer then
            pack.Tracer.From = centerBottom
            pack.Tracer.To = rootS
            pack.Tracer.Color = B.Settings.ESP.TracerColor
            pack.Tracer.Visible = on
        elseif pack.Tracer then
            pack.Tracer.Visible = false
        end
    end
end

-- ===================== MOVEMENT / COMBAT =====================
local function SetFly(on)
    local char = LocalPlayer.Character
    local root = char and GetRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if B.FlyBV then pcall(function() B.FlyBV:Destroy() end) B.FlyBV = nil end
    if B.FlyBG then pcall(function() B.FlyBG:Destroy() end) B.FlyBG = nil end

    if on then
        hum.PlatformStand = true
        B.FlyBV = Instance.new("BodyVelocity")
        B.FlyBV.MaxForce = Vector3.new(9e4, 9e4, 9e4)
        B.FlyBV.Velocity = Vector3.zero
        B.FlyBV.P = 1250
        B.FlyBV.Parent = root
        B.FlyBG = Instance.new("BodyGyro")
        B.FlyBG.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
        B.FlyBG.P = 3000
        B.FlyBG.Parent = root

        AddConn(RunService.RenderStepped:Connect(function()
            if not B.Settings.Brutal.Fly or not B.FlyBV or not B.FlyBG then return end
            if not root.Parent then return end
            local cf = Camera.CFrame
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end
            if UserInputService.TouchEnabled and #UserInputService:GetTouches() > 0 then
                move = move + cf.LookVector * 0.7
            end
            if move.Magnitude > 0.1 then
                B.FlyBV.Velocity = move.Unit * B.Settings.Brutal.FlySpeed
            else
                B.FlyBV.Velocity = Vector3.zero
            end
            B.FlyBG.CFrame = cf
        end))
    else
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

local function SetSpeed(on)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then
        B.OriginalWalkSpeed = hum.WalkSpeed
        hum.WalkSpeed = math.clamp(B.Settings.Brutal.SpeedValue, 16, 40)
    else
        hum.WalkSpeed = B.OriginalWalkSpeed or 16
    end
end

local function SetNoclip(on)
    if B.NoclipConn then B.NoclipConn:Disconnect() B.NoclipConn = nil end
    for p, c in pairs(B.OriginalCollision) do
        if p and p.Parent then pcall(function() p.CanCollide = c end) end
    end
    B.OriginalCollision = {}
    if on then
        B.NoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if B.OriginalCollision[part] == nil then
                        B.OriginalCollision[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)
        AddConn(B.NoclipConn)
    end
end

local function SetHitbox(on)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local root = GetRoot(GetChar(p))
            if root then
                if on then
                    local s = B.Settings.Brutal.HitboxSize
                    root.Size = Vector3.new(s, s, s)
                    root.Transparency = 0.55
                    root.CanCollide = false
                    if B.Settings.Brutal.HitboxRedAim and B.CurrentTarget == p then
                        root.Color = Color3.fromRGB(255, 40, 40)
                    else
                        root.Color = Color3.fromRGB(255, 120, 120)
                    end
                else
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end
            end
        end
    end
end

local function GetTool()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Tool")
end

local function PatchWeapon()
    local tool = GetTool()
    if not tool then return end
    if B.Settings.Brutal.AntiCooldown or B.Settings.Brutal.AttackSpeed then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n = v.Name:lower()
                if n:find("cool") or n:find("delay") or n:find("rate") or n:find("firerate") or n:find("interval") or n:find("speed") then
                    pcall(function() v.Value = 0 end)
                end
            end
        end
        pcall(function()
            tool:SetAttribute("Cooldown", 0)
            tool:SetAttribute("FireRate", 0.01)
            tool:SetAttribute("Debounce", false)
            tool:SetAttribute("AttackSpeed", B.Settings.Brutal.AttackSpeedVal)
        end)
    end
    if B.Settings.Brutal.InfiniteAmmo then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n = v.Name:lower()
                if n:find("ammo") or n:find("clip") or n:find("mag") or n:find("bullet") then
                    pcall(function() v.Value = 999 end)
                end
            end
        end
        pcall(function()
            tool:SetAttribute("Ammo", 999)
            tool:SetAttribute("Clip", 999)
        end)
    end
end

local function DoAutoKill()
    if not B.Settings.Brutal.AutoKill then return end
    local now = tick()
    local interval = 1 / math.clamp(B.Settings.Brutal.AttackSpeedVal, 1, 25)
    if now - B.LastShoot < interval then return end
    B.LastShoot = now

    local tool = GetTool()
    if tool then
        pcall(function() tool:Activate() end)
    end

    -- force aim + fire at nearest enemy even behind
    local best, bd = nil, 9999
    local my = GetRoot(LocalPlayer.Character)
    if not my then return end
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
    if best then
        local part = GetAimPart(GetChar(best))
        if part then
            local current = Camera.CFrame
            Camera.CFrame = CFrame.new(current.Position, part.Position)
            if tool then pcall(function() tool:Activate() end) end
        end
    end
end

local function ScanNPCs()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            if hum and root and hum.Health > 0 then
                table.insert(list, {hum = hum, root = root})
            end
        end
    end
    return list
end

local function DoOneHitNPC()
    local list = ScanNPCs()
    local best, bd = nil, 9999
    local my = GetRoot(LocalPlayer.Character)
    if not my then return end
    for _, n in ipairs(list) do
        local d = (my.Position - n.root.Position).Magnitude
        if d < bd then bd = d best = n end
    end
    if best then
        pcall(function()
            if B.Settings.Brutal.DamageConfig then best.hum:TakeDamage(B.Settings.Brutal.DamageValue) end
            best.hum.Health = 0
        end)
    end
end

local function DoKillAllNPC()
    for _, n in ipairs(ScanNPCs()) do
        pcall(function()
            if B.Settings.Brutal.DamageConfig then n.hum:TakeDamage(B.Settings.Brutal.DamageValue) end
            n.hum.Health = 0
        end)
    end
end

-- AIM TAB
do
    local f = TabFrames.AIM
    MakeSection(f, "Core")
    MakeToggle(f, "Enable Aimbot", false, function(v)
        B.Settings.Aim.Enabled = v
        if v then MakeFOV() MakeLine() end
    end)
    MakeToggle(f, "Silent Aim", false, function(v) B.Settings.Aim.SilentAim = v end)
    MakeToggle(f, "Anti Miss Aim", false, function(v) B.Settings.Aim.AntiMiss = v end)
    MakeToggle(f, "Visibility Check", true, function(v) B.Settings.Aim.VisibilityCheck = v end)
    MakeToggle(f, "Head Aim", true, function(v)
        B.Settings.Aim.HeadAim = v
        B.Settings.Aim.HitPart = "Head"
        if v then B.Settings.Aim.BodyAim = false end
    end)
    MakeToggle(f, "Body Aim", false, function(v)
        B.Settings.Aim.BodyAim = v
        B.Settings.Aim.HitPart = "Body"
        if v then B.Settings.Aim.HeadAim = false end
    end)
    MakeToggle(f, "Multi-Bone", false, function(v) B.Settings.Aim.MultiBone = v end)
    MakeSection(f, "FOV")
    MakeToggle(f, "FOV Circle", true, function(v) B.Settings.Aim.FOVCircle = v end)
    MakeSlider(f, "FOV Size", 40, 1000, 200, function(v) B.Settings.Aim.FOV = v end)
    MakeSlider(f, "Aim Distance", 50, 2000, 800, function(v) B.Settings.Aim.AimDistance = v end)
    MakeSection(f, "Feel")
    MakeToggle(f, "Aim Lock", false, function(v)
        B.Settings.Aim.AimLock = v
        if not v then B.LockedTarget = nil end
    end)
    MakeToggle(f, "Prediction", false, function(v) B.Settings.Aim.AimPrediction = v end)
    MakeSlider(f, "Smoothing x100", 5, 50, 18, function(v) B.Settings.Aim.AimSmoothing = v/100 end)
    MakeToggle(f, "Target Line", true, function(v) B.Settings.Aim.DrawTargetLine = v end)
    MakeToggle(f, "Team Check", true, function(v) B.Settings.Aim.TeamCheck = v end)
    MakeToggle(f, "Soft Camera", true, function(v) B.Settings.Protect.SoftCamera = v end)
    Layout(f)
end

-- ESP TAB
do
    local f = TabFrames.ESP
    MakeSection(f, "Player ESP")
    MakeToggle(f, "Enable ESP", false, function(v) B.Settings.ESP.Enabled = v end)
    MakeToggle(f, "Box", true, function(v) B.Settings.ESP.Box = v end)
    MakeToggle(f, "Name", true, function(v) B.Settings.ESP.Name = v end)
    MakeToggle(f, "Health Bar", true, function(v) B.Settings.ESP.HealthBar = v end)
    MakeToggle(f, "Distance", true, function(v) B.Settings.ESP.Distance = v end)
    MakeToggle(f, "Tracer Line", true, function(v) B.Settings.ESP.Tracer = v end)
    MakeToggle(f, "Visible Check", true, function(v) B.Settings.ESP.VisibleCheck = v end)
    MakeToggle(f, "Priority Mark", true, function(v) B.Settings.ESP.PriorityMark = v end)
    MakeSlider(f, "Max Distance", 100, 2000, 900, function(v) B.Settings.ESP.MaxDistance = v end)
    MakeSection(f, "ESP Color")
    MakeButton(f, "Color: GREEN", Color3.fromRGB(0,120,70), function() ApplyESPColor("Green") end)
    MakeButton(f, "Color: PURPLE", Color3.fromRGB(90,30,150), function() ApplyESPColor("Purple") end)
    MakeButton(f, "Color: RED", Color3.fromRGB(140,30,30), function() ApplyESPColor("Red") end)
    MakeButton(f, "Color: CYAN", Color3.fromRGB(0,100,130), function() ApplyESPColor("Cyan") end)
    MakeButton(f, "Color: YELLOW", Color3.fromRGB(140,120,20), function() ApplyESPColor("Yellow") end)
    MakeButton(f, "Color: WHITE", Color3.fromRGB(80,80,100), function() ApplyESPColor("White") end)
    Layout(f)
end

-- BRUTAL TAB
do
    local f = TabFrames.BRUTAL
    MakeSection(f, "Movement")
    MakeToggle(f, "Fly", false, function(v) B.Settings.Brutal.Fly = v SetFly(v) end)
    MakeSlider(f, "Fly Speed", 10, 100, 45, function(v) B.Settings.Brutal.FlySpeed = v end)
    MakeToggle(f, "Speed Hack", false, function(v) B.Settings.Brutal.SpeedHack = v SetSpeed(v) end)
    MakeSlider(f, "Speed", 16, 40, 24, function(v)
        B.Settings.Brutal.SpeedValue = v
        if B.Settings.Brutal.SpeedHack then SetSpeed(true) end
    end)
    MakeToggle(f, "Noclip", false, function(v) B.Settings.Brutal.Noclip = v SetNoclip(v) end)
    MakeToggle(f, "Infinite Jump", false, function(v)
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
    MakeSection(f, "Hitbox")
    MakeToggle(f, "Hitbox Expand", false, function(v) B.Settings.Brutal.HitboxExpand = v SetHitbox(v) end)
    MakeToggle(f, "Hitbox Red on Aim", true, function(v) B.Settings.Brutal.HitboxRedAim = v end)
    MakeSlider(f, "Hitbox Size", 2, 25, 8, function(v)
        B.Settings.Brutal.HitboxSize = v
        if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
    end)
    MakeSection(f, "Weapon / Combat")
    MakeToggle(f, "Anti Cooldown", false, function(v) B.Settings.Brutal.AntiCooldown = v end)
    MakeToggle(f, "Infinite Ammo", false, function(v) B.Settings.Brutal.InfiniteAmmo = v end)
    MakeToggle(f, "Attack Speed", false, function(v) B.Settings.Brutal.AttackSpeed = v end)
    MakeSlider(f, "Attack Speed Value", 1, 25, 10, function(v) B.Settings.Brutal.AttackSpeedVal = v end)
    MakeToggle(f, "Auto Shoot", false, function(v) B.Settings.Brutal.AutoShoot = v end)
    MakeToggle(f, "Auto Kill (FF style)", false, function(v) B.Settings.Brutal.AutoKill = v end)
    MakeSection(f, "NPC")
    MakeToggle(f, "Damage Config", false, function(v) B.Settings.Brutal.DamageConfig = v end)
    MakeSlider(f, "Damage Value", 10, 500, 150, function(v) B.Settings.Brutal.DamageValue = v end)
    MakeButton(f, "ONE HIT NEAREST NPC", Color3.fromRGB(130,30,50), DoOneHitNPC)
    MakeButton(f, "KILL ALL NPC", Color3.fromRGB(110,20,40), DoKillAllNPC)
    MakeToggle(f, "God Mode (local)", false, function(v)
        B.Settings.Brutal.GodMode = v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then
            if v then h.MaxHealth = 1e9 h.Health = 1e9 else h.MaxHealth = 100 end
        end
    end)
    Layout(f)
end

-- SETTINGS
do
    local f = TabFrames.SETTINGS
    MakeSection(f, "Visual / Performance")
    MakeToggle(f, "FullBright", false, function(v)
        B.Settings.Visual.FullBright = v
        Lighting.Brightness = v and 2.2 or 1
        Lighting.GlobalShadows = not v
    end)
    MakeToggle(f, "No Fog", false, function(v)
        B.Settings.Visual.NoFog = v
        Lighting.FogEnd = v and 9e6 or 1000
    end)
    MakeToggle(f, "Anti Lag", false, function(v)
        B.Settings.Visual.AntiLag = v
        pcall(function()
            settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = not v
        end)
    end)
    MakeToggle(f, "Streaming Mode", false, function(v)
        B.Settings.Visual.StreamingMode = v
        local op = v and B.Settings.Visual.StreamingOpacity or 1
        Main.BackgroundTransparency = 1 - op
        Header.BackgroundTransparency = 1 - op
    end)
    MakeSection(f, "Protect")
    MakeToggle(f, "Anti-Kick", true, function(v) B.Settings.Protect.AntiKick = v end)
    MakeToggle(f, "Auto Hop on Flag", true, function(v) B.Settings.Protect.AutoHopOnFlag = v end)
    MakeButton(f, "FORCE SERVER HOP", Color3.fromRGB(30,70,50), function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    MakeButton(f, "UNLOAD", Color3.fromRGB(90,25,35), function()
        CleanupAll()
        ScreenGui:Destroy()
        getgenv().BAXTARA = nil
    end)
    Layout(f)
end

-- Drag
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
AddConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))

local function ShowPanel()
    Main.Visible = true
    Main.Size = UDim2.new(0, B.Settings.UI.Width, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, B.Settings.UI.Width, 0, B.Settings.UI.Height)
    }):Play()
end
local function HidePanel()
    local tw = TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, B.Settings.UI.Width, 0, 0)
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
OpenBtn.Size = UDim2.new(0,48,0,48)
OpenBtn.Position = UDim2.new(1,-60,0.5,-24)
OpenBtn.BackgroundColor3 = Color3.fromRGB(110,30,190)
OpenBtn.Text = "BX"
OpenBtn.TextColor3 = Color3.fromRGB(245,235,255)
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.TextSize = 15
OpenBtn.Visible = false
OpenBtn.ZIndex = 20
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1,0)
OpenBtn.MouseButton1Click:Connect(function()
    if Main.Visible then HidePanel() else ShowPanel() end
end)

-- KEY VERIFY
VerifyBtn.MouseButton1Click:Connect(function()
    local input = (KeyBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    if input:upper() == ACCESS_KEY:upper() then
        StatusLbl.TextColor3 = Color3.fromRGB(100,255,160)
        StatusLbl.Text = "ACCESS GRANTED"
        B.Unlocked = true
        task.wait(0.4)
        TweenService:Create(KeyFrame, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        KeyFrame.Visible = false

        LoadFrame.Visible = true
        TweenService:Create(RingStroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Thickness = 5, Transparency = 0.1
        }):Play()

        local steps = {
            {0.2, "INITIALIZING SYSTEM"},
            {0.4, "LOADING MODULES"},
            {0.6, "BINDING CONTROLS"},
            {0.8, "ACCESS CONFIRMED"},
            {1.0, "READY"},
        }
        for _, s in ipairs(steps) do
            LoadBar:TweenSize(UDim2.new(s[1],0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
            LoadStatus.Text = s[2]
            LoadPct.Text = math.floor(s[1]*100).."%"
            task.wait(0.45)
        end
        task.wait(0.25)
        TweenService:Create(LoadFrame, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        LoadFrame.Visible = false
        OpenBtn.Visible = UserInputService.TouchEnabled
        ShowPanel()
        MakeFOV()
        MakeLine()
    else
        StatusLbl.TextColor3 = Color3.fromRGB(255,80,100)
        StatusLbl.Text = "INVALID KEY"
        local orig = KeyCard.Position
        for i = 1, 5 do
            KeyCard.Position = orig + UDim2.new(0, (i%2==0 and 7 or -7), 0, 0)
            task.wait(0.04)
        end
        KeyCard.Position = orig
    end
end)

-- MAIN LOOPS
AddConn(RunService.RenderStepped:Connect(function()
    if not B.Unlocked then return end
    UpdateAim()
    UpdatePlayerESP()
    if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
end))

AddConn(RunService.Heartbeat:Connect(function()
    if not B.Unlocked then return end
    if B.Settings.Brutal.AntiCooldown or B.Settings.Brutal.InfiniteAmmo or B.Settings.Brutal.AttackSpeed then
        PatchWeapon()
    end
    if B.Settings.Brutal.AutoShoot then
        local t = GetTool()
        if t then pcall(function() t:Activate() end) end
    end
    if B.Settings.Brutal.AutoKill then
        DoAutoKill()
    end
    if B.HomeStatus then
        B.HomeStatus.Text = string.format(
            "Aim: %s  |  Silent: %s\nESP: %s  |  AutoKill: %s\nProtect: Anti-Kick %s",
            B.Settings.Aim.Enabled and "ON" or "OFF",
            B.Settings.Aim.SilentAim and "ON" or "OFF",
            B.Settings.ESP.Enabled and "ON" or "OFF",
            B.Settings.Brutal.AutoKill and "ON" or "OFF",
            B.Settings.Protect.AntiKick and "ON" or "OFF"
        )
    end
end))

AddConn(CoreGui.DescendantAdded:Connect(function(obj)
    if not B.Settings.Protect.AntiKick then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local t = (obj.Text or ""):lower()
        if t:find("suspicious") or t:find("banned") or t:find("exploiting") or t:find("timedout") or t:find("kicked") or t:find("dikeluarkan") then
            if B.Settings.Protect.AutoHopOnFlag then
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        end
    end
end))

local function OnChar(char)
    task.wait(0.4)
    if B.Settings.Brutal.SpeedHack then SetSpeed(true) end
    if B.Settings.Brutal.Fly then SetFly(true) end
    if B.Settings.Brutal.Noclip then SetNoclip(true) end
    if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
end
if LocalPlayer.Character then OnChar(LocalPlayer.Character) end
AddConn(LocalPlayer.CharacterAdded:Connect(OnChar))

print("[BAXTARA X CHEAT v5.2] Tracer ESP | AutoKill | AttackSpeed | Fly fix | Text loading | NUGI CENEL")
