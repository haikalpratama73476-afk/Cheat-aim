--[[
    BAXTARA X CHEAT  v5.1
    Developer : NUGI CENEL
    Credit    : @BAXTARA X CHEAT
    Flow      : Key Access → Cinematic Load → Modern Panel (Home/Aim/ESP/Brutal/Settings)
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local GuiService       = game:GetService("GuiService")

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
        AimSmoothing    = 0.2,
        AimPrediction   = false,
        PredictionAmount= 0.12,
        DrawTargetLine  = false,
        TargetHighlight = false,
        FOV             = 180,
        TeamCheck       = true,
        SilentAim       = false,
        AntiMiss        = false,
        HitPart         = "Head", -- Head / Body
    },
    ESP = {
        Enabled       = false,
        Box           = true,
        Name          = true,
        HealthBar     = true,
        Distance      = true,
        Tracer        = false,
        Skeleton      = false,
        VisibleCheck  = true,
        PriorityMark  = true,
        StatusESP     = true,
        Radar         = false,
        Offscreen     = true,
        MaxDistance   = 900,
        VisibleColor  = Color3.fromRGB(0, 255, 140),
        HiddenColor   = Color3.fromRGB(255, 70, 70),
        PriorityColor = Color3.fromRGB(255, 200, 0),
        OffscreenColor= Color3.fromRGB(0, 200, 255),
    },
    Brutal = {
        Fly            = false,
        FlySpeed       = 40,
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
        AntiBan          = false,
    },
    UI = {
        Accent     = Color3.fromRGB(160, 40, 255),
        Accent2    = Color3.fromRGB(0, 255, 140),
        Background = Color3.fromRGB(8, 8, 14),
        Card       = Color3.fromRGB(16, 14, 24),
        Text       = Color3.fromRGB(235, 230, 255),
        Width      = 420,
        Height     = 560,
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
B.NPCList = {}
B.Unlocked = false

local function AddConn(c) table.insert(B.Connections, c) return c end

local function CleanupAll()
    for _, c in ipairs(B.Connections) do pcall(function() c:Disconnect() end) end
    B.Connections = {}
    for _, d in pairs(B.Drawings) do pcall(function() if d.Remove then d:Remove() end end) end
    B.Drawings = {}
    for _, h in pairs(B.Highlights) do pcall(function() h:Destroy() end) end
    B.Highlights = {}
    for _, pack in pairs(B.ESPObjects) do
        for k, d in pairs(pack) do
            if k == "Skel" then
                for _, l in ipairs(d) do pcall(function() if l and l.Remove then l:Remove() end end) end
            else pcall(function() if d and d.Remove then d:Remove() end end) end
        end
    end
    B.ESPObjects = {}
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
KeyFrame.BackgroundColor3 = Color3.fromRGB(4, 2, 10)
KeyFrame.BorderSizePixel = 0
KeyFrame.ZIndex = 100
KeyFrame.Parent = ScreenGui

-- purple fog layers
for i = 1, 3 do
    local fog = Instance.new("Frame")
    fog.Size = UDim2.new(1.2, 0, 0.35, 0)
    fog.Position = UDim2.new(-0.1, 0, 0.2 + i*0.15, 0)
    fog.BackgroundColor3 = Color3.fromRGB(90 + i*20, 20, 160)
    fog.BackgroundTransparency = 0.88 + i*0.02
    fog.BorderSizePixel = 0
    fog.ZIndex = 101
    fog.Parent = KeyFrame
    Instance.new("UICorner", fog).CornerRadius = UDim.new(1, 0)
end

-- particles (simple dots)
for i = 1, 18 do
    local p = Instance.new("Frame")
    p.Size = UDim2.new(0, math.random(2,5), 0, math.random(2,5))
    p.Position = UDim2.new(math.random(), 0, math.random(), 0)
    p.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
    p.BackgroundTransparency = 0.3
    p.BorderSizePixel = 0
    p.ZIndex = 102
    p.Parent = KeyFrame
    Instance.new("UICorner", p).CornerRadius = UDim.new(1,0)
    task.spawn(function()
        while p.Parent do
            TweenService:Create(p, TweenInfo.new(3+math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Position = UDim2.new(math.random(), 0, math.random(), 0),
                BackgroundTransparency = 0.2 + math.random()*0.5
            }):Play()
            task.wait(4)
        end
    end)
end

local KeyCard = Instance.new("Frame")
KeyCard.Size = UDim2.new(0, 340, 0, 420)
KeyCard.Position = UDim2.new(0.5, -170, 0.5, -210)
KeyCard.BackgroundColor3 = Color3.fromRGB(12, 8, 22)
KeyCard.BackgroundTransparency = 0.15
KeyCard.BorderSizePixel = 0
KeyCard.ZIndex = 110
KeyCard.Parent = KeyFrame
Instance.new("UICorner", KeyCard).CornerRadius = UDim.new(0, 14)
local ks = Instance.new("UIStroke")
ks.Color = Color3.fromRGB(160, 40, 255)
ks.Thickness = 1.8
ks.Transparency = 0.2
ks.Parent = KeyCard

local KeyLogo = Instance.new("TextLabel")
KeyLogo.Size = UDim2.new(1, -20, 0, 36)
KeyLogo.Position = UDim2.new(0, 10, 0, 18)
KeyLogo.BackgroundTransparency = 1
KeyLogo.Text = "BAXTARA X CHEAT"
KeyLogo.TextColor3 = Color3.fromRGB(200, 100, 255)
KeyLogo.Font = Enum.Font.GothamBlack
KeyLogo.TextSize = 20
KeyLogo.ZIndex = 111
KeyLogo.Parent = KeyCard

local KeySub = Instance.new("TextLabel")
KeySub.Size = UDim2.new(1, -20, 0, 18)
KeySub.Position = UDim2.new(0, 10, 0, 52)
KeySub.BackgroundTransparency = 1
KeySub.Text = "SECURE ACCESS TERMINAL"
KeySub.TextColor3 = Color3.fromRGB(140, 100, 200)
KeySub.Font = Enum.Font.Code
KeySub.TextSize = 12
KeySub.ZIndex = 111
KeySub.Parent = KeyCard

local KeyDesc = Instance.new("TextLabel")
KeyDesc.Size = UDim2.new(1, -30, 0, 36)
KeyDesc.Position = UDim2.new(0, 15, 0, 80)
KeyDesc.BackgroundTransparency = 1
KeyDesc.Text = "Masukkan access key untuk membuka\npanel BAXTARA X CHEAT."
KeyDesc.TextColor3 = Color3.fromRGB(180, 160, 210)
KeyDesc.Font = Enum.Font.Code
KeyDesc.TextSize = 11
KeyDesc.TextWrapped = true
KeyDesc.ZIndex = 111
KeyDesc.Parent = KeyCard

-- input
local InputHolder = Instance.new("Frame")
InputHolder.Size = UDim2.new(1, -40, 0, 42)
InputHolder.Position = UDim2.new(0, 20, 0, 130)
InputHolder.BackgroundColor3 = Color3.fromRGB(20, 14, 32)
InputHolder.BorderSizePixel = 0
InputHolder.ZIndex = 111
InputHolder.Parent = KeyCard
Instance.new("UICorner", InputHolder).CornerRadius = UDim.new(0, 8)
local is = Instance.new("UIStroke")
is.Color = Color3.fromRGB(100, 50, 160)
is.Thickness = 1.2
is.Parent = InputHolder

local KeyIcon = Instance.new("TextLabel")
KeyIcon.Size = UDim2.new(0, 30, 1, 0)
KeyIcon.BackgroundTransparency = 1
KeyIcon.Text = "🔑"
KeyIcon.TextSize = 14
KeyIcon.ZIndex = 112
KeyIcon.Parent = InputHolder

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -70, 1, 0)
KeyBox.Position = UDim2.new(0, 32, 0, 0)
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

local ShowBtn = Instance.new("TextButton")
ShowBtn.Size = UDim2.new(0, 36, 1, 0)
ShowBtn.Position = UDim2.new(1, -36, 0, 0)
ShowBtn.BackgroundTransparency = 1
ShowBtn.Text = "👁"
ShowBtn.TextSize = 12
ShowBtn.ZIndex = 112
ShowBtn.Parent = InputHolder
local keyHidden = true
KeyBox.TextTransparency = 0
ShowBtn.MouseButton1Click:Connect(function()
    keyHidden = not keyHidden
    -- TextBox doesn't support password mode cleanly on all platforms; just toggle placeholder feel
    ShowBtn.Text = keyHidden and "👁" or "🔒"
end)

KeyBox.Focused:Connect(function()
    TweenService:Create(is, TweenInfo.new(0.15), {Color = Color3.fromRGB(180, 80, 255)}):Play()
end)
KeyBox.FocusLost:Connect(function()
    TweenService:Create(is, TweenInfo.new(0.15), {Color = Color3.fromRGB(100, 50, 160)}):Play()
end)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, -40, 0, 20)
StatusLbl.Position = UDim2.new(0, 20, 0, 178)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = ""
StatusLbl.TextColor3 = Color3.fromRGB(255, 80, 100)
StatusLbl.Font = Enum.Font.Code
StatusLbl.TextSize = 12
StatusLbl.ZIndex = 111
StatusLbl.Parent = KeyCard

local function MakeKeyBtn(text, y, color, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 245, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.ZIndex = 111
    btn.Parent = KeyCard
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(200, 100, 255)
    st.Thickness = 1
    st.Transparency = 0.4
    st.Parent = btn
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(1, -48, 0, 36)}):Play()
        task.wait(0.08)
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(1, -40, 0, 40)}):Play()
        if cb then cb() end
    end)
    return btn
end

local VerifyBtn = MakeKeyBtn("VERIFY KEY", 210, Color3.fromRGB(120, 30, 200), nil)
local WABtn = MakeKeyBtn("JOIN WHATSAPP CHANNEL", 258, Color3.fromRGB(20, 90, 50), function()
    pcall(function()
        if setclipboard then setclipboard(WA_URL) end
        StarterGui:SetCore("SendNotification", {
            Title = "BAXTARA",
            Text = "WhatsApp link copied. Open browser.",
            Duration = 4,
        })
    end)
    pcall(function()
        -- some executors support open url
        if typeof(request) == "function" then end
    end)
end)
local CopyBtn = MakeKeyBtn("COPY KEY INFO", 306, Color3.fromRGB(40, 30, 70), function()
    pcall(function()
        if setclipboard then setclipboard("Key: BAXTARA X CHEAT\nWA: "..WA_URL) end
        StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 160)
        StatusLbl.Text = "Key info copied."
    end)
end)

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1, -30, 0, 40)
Hint.Position = UDim2.new(0, 15, 0, 360)
Hint.BackgroundTransparency = 1
Hint.Text = "Belum mempunyai key? Join saluran resmi\nuntuk mendapatkan informasi access key."
Hint.TextColor3 = Color3.fromRGB(120, 100, 150)
Hint.Font = Enum.Font.Code
Hint.TextSize = 10
Hint.TextWrapped = true
Hint.ZIndex = 111
Hint.Parent = KeyCard

-- ===================== CINEMATIC LOADING =====================
local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(1,0,1,0)
LoadFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
LoadFrame.BorderSizePixel = 0
LoadFrame.Visible = false
LoadFrame.ZIndex = 90
LoadFrame.Parent = ScreenGui

local LoadCenter = Instance.new("Frame")
LoadCenter.Size = UDim2.new(0, 280, 0, 280)
LoadCenter.Position = UDim2.new(0.5, -140, 0.5, -160)
LoadCenter.BackgroundTransparency = 1
LoadCenter.ZIndex = 91
LoadCenter.Parent = LoadFrame

-- ring
local Ring = Instance.new("Frame")
Ring.Size = UDim2.new(1,0,1,0)
Ring.BackgroundTransparency = 1
Ring.ZIndex = 92
Ring.Parent = LoadCenter
local RingStroke = Instance.new("UIStroke")
RingStroke.Color = Color3.fromRGB(160, 40, 255)
RingStroke.Thickness = 3
RingStroke.Transparency = 0.3
RingStroke.Parent = Ring
Instance.new("UICorner", Ring).CornerRadius = UDim.new(1,0)

local HoodEmoji = Instance.new("TextLabel")
HoodEmoji.Size = UDim2.new(1,0,1,0)
HoodEmoji.BackgroundTransparency = 1
HoodEmoji.Text = "👁"
HoodEmoji.TextSize = 64
HoodEmoji.TextColor3 = Color3.fromRGB(200, 80, 255)
HoodEmoji.ZIndex = 93
HoodEmoji.Parent = LoadCenter

local CrownLbl = Instance.new("TextLabel")
CrownLbl.Size = UDim2.new(1,0,0,40)
CrownLbl.Position = UDim2.new(0,0,-0.05,0)
CrownLbl.BackgroundTransparency = 1
CrownLbl.Text = "👑"
CrownLbl.TextSize = 36
CrownLbl.TextTransparency = 1
CrownLbl.ZIndex = 94
CrownLbl.Parent = LoadCenter

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1,0,0,36)
LoadTitle.Position = UDim2.new(0,0,1,10)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "BAXTARA X CHEAT"
LoadTitle.TextColor3 = Color3.fromRGB(200, 100, 255)
LoadTitle.Font = Enum.Font.GothamBlack
LoadTitle.TextSize = 22
LoadTitle.TextTransparency = 1
LoadTitle.ZIndex = 94
LoadTitle.Parent = LoadCenter

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1,0,0,18)
LoadStatus.Position = UDim2.new(0,0,0.82,0)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "INITIALIZING BAXTARA SYSTEM..."
LoadStatus.TextColor3 = Color3.fromRGB(160, 120, 220)
LoadStatus.Font = Enum.Font.Code
LoadStatus.TextSize = 12
LoadStatus.ZIndex = 94
LoadStatus.Parent = LoadFrame

local LoadBarBG = Instance.new("Frame")
LoadBarBG.Size = UDim2.new(0, 260, 0, 4)
LoadBarBG.Position = UDim2.new(0.5, -130, 0.88, 0)
LoadBarBG.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
LoadBarBG.BorderSizePixel = 0
LoadBarBG.ZIndex = 94
LoadBarBG.Parent = LoadFrame
Instance.new("UICorner", LoadBarBG).CornerRadius = UDim.new(1,0)
local LoadBar = Instance.new("Frame")
LoadBar.Size = UDim2.new(0,0,1,0)
LoadBar.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
LoadBar.BorderSizePixel = 0
LoadBar.ZIndex = 95
LoadBar.Parent = LoadBarBG
Instance.new("UICorner", LoadBar).CornerRadius = UDim.new(1,0)

local LoadPct = Instance.new("TextLabel")
LoadPct.Size = UDim2.new(1,0,0,16)
LoadPct.Position = UDim2.new(0,0,0.9,0)
LoadPct.BackgroundTransparency = 1
LoadPct.Text = "0%"
LoadPct.TextColor3 = Color3.fromRGB(180, 140, 230)
LoadPct.Font = Enum.Font.Code
LoadPct.TextSize = 11
LoadPct.ZIndex = 94
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
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(140, 40, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.25
MainStroke.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,48)
Header.BackgroundColor3 = Color3.fromRGB(14, 10, 24)
Header.BorderSizePixel = 0
Header.ZIndex = 11
Header.Parent = Main
local hg = Instance.new("UIGradient")
hg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 10, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 30, 40))
}
hg.Parent = Header

local HLogo = Instance.new("TextLabel")
HLogo.Size = UDim2.new(0, 44, 0, 44)
HLogo.Position = UDim2.new(0, 6, 0, 2)
HLogo.BackgroundTransparency = 1
HLogo.Text = "BX"
HLogo.TextColor3 = Color3.fromRGB(180, 80, 255)
HLogo.Font = Enum.Font.GothamBlack
HLogo.TextSize = 20
HLogo.ZIndex = 12
HLogo.Parent = Header

local HTitle = Instance.new("TextLabel")
HTitle.Size = UDim2.new(1, -120, 1, 0)
HTitle.Position = UDim2.new(0, 50, 0, 0)
HTitle.BackgroundTransparency = 1
HTitle.Text = "BAXTARA X CHEAT  ·  v5.1"
HTitle.TextColor3 = Color3.fromRGB(220, 180, 255)
HTitle.Font = Enum.Font.Code
HTitle.TextSize = 13
HTitle.TextXAlignment = Enum.TextXAlignment.Left
HTitle.ZIndex = 12
HTitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -17)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 120, 140)
CloseBtn.Font = Enum.Font.Code
CloseBtn.TextSize = 14
CloseBtn.ZIndex = 12
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 34, 0, 34)
MinBtn.Position = UDim2.new(1, -78, 0.5, -17)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 30)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(230, 220, 120)
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 16
MinBtn.ZIndex = 12
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,34)
TabBar.Position = UDim2.new(0,0,0,48)
TabBar.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 11
TabBar.Parent = Main

local TabNames = {"HOME","AIM","ESP","BRUTAL","SETTINGS"}
local TabBtns, TabFrames = {}, {}
local function SwitchTab(name)
    for n, f in pairs(TabFrames) do
        f.Visible = (n == name)
        TabBtns[n].TextColor3 = (n == name) and Color3.fromRGB(200, 120, 255) or Color3.fromRGB(130, 120, 160)
        TabBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(40, 20, 70) or Color3.fromRGB(12, 10, 20)
    end
end

for i, name in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 1, 0)
    btn.Position = UDim2.new((i-1)*0.2, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(130, 120, 160)
    btn.Font = Enum.Font.Code
    btn.TextSize = 11
    btn.ZIndex = 12
    btn.Parent = TabBar
    TabBtns[name] = btn
    local sc = Instance.new("ScrollingFrame")
    sc.Size = UDim2.new(1, -12, 1, -90)
    sc.Position = UDim2.new(0, 6, 0, 86)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(160, 60, 255)
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
Footer.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
Footer.BorderSizePixel = 0
Footer.Text = "  NUGI CENEL  ·  @BAXTARA X CHEAT  ·  EXECUTE · DOMINATE · WIN"
Footer.TextColor3 = Color3.fromRGB(140, 80, 200)
Footer.Font = Enum.Font.Code
Footer.TextSize = 9
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.ZIndex = 12
Footer.Parent = Main

-- UI builders
local function MakeSection(parent, title)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, -4, 0, 20)
    h.BackgroundTransparency = 1
    h.ZIndex = 12
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = "▸ "..title
    l.TextColor3 = Color3.fromRGB(180, 100, 255)
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 13
    l.Parent = h
    return h
end

local function MakeToggle(parent, text, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, -4, 0, 30)
    h.BackgroundColor3 = B.Settings.UI.Card
    h.BorderSizePixel = 0
    h.ZIndex = 12
    h.Parent = parent
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -54, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 13
    l.Parent = h
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 42, 0, 20)
    bg.Position = UDim2.new(1, -48, 0.5, -10)
    bg.BackgroundColor3 = default and Color3.fromRGB(140, 40, 220) or Color3.fromRGB(40, 35, 55)
    bg.BorderSizePixel = 0
    bg.ZIndex = 13
    bg.Parent = h
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(245, 240, 255)
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
        TweenService:Create(bg, TweenInfo.new(0.12), {
            BackgroundColor3 = state and Color3.fromRGB(140, 40, 220) or Color3.fromRGB(40, 35, 55)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
        if cb then cb(state) end
    end)
    return h
end

local function MakeSlider(parent, text, min, max, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, -4, 0, 42)
    h.BackgroundColor3 = B.Settings.UI.Card
    h.BorderSizePixel = 0
    h.ZIndex = 12
    h.Parent = parent
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -54, 0, 16)
    l.Position = UDim2.new(0, 10, 0, 4)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 13
    l.Parent = h
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 48, 0, 16)
    val.Position = UDim2.new(1, -54, 0, 4)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = Color3.fromRGB(200, 120, 255)
    val.Font = Enum.Font.Code
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 13
    val.Parent = h
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, -20, 0, 7)
    barBG.Position = UDim2.new(0, 10, 0, 26)
    barBG.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    barBG.BorderSizePixel = 0
    barBG.ZIndex = 13
    barBG.Parent = h
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/math.max(max-min,1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(160, 60, 255)
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
    h.Size = UDim2.new(1, -4, 0, 34)
    h.BackgroundTransparency = 1
    h.ZIndex = 12
    h.Parent = parent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = color or Color3.fromRGB(90, 30, 160)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 230, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 13
    btn.Parent = h
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(180, 80, 255)
    st.Thickness = 1
    st.Transparency = 0.45
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
                ch.Position = UDim2.new(0, 0, 0, y)
                y = y + (ch.AbsoluteSize.Y > 0 and ch.AbsoluteSize.Y or ch.Size.Y.Offset) + 4
            end
        end
        frame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end)
end

-- HOME
do
    local f = TabFrames.HOME
    local av = Instance.new("Frame")
    av.Size = UDim2.new(1, -4, 0, 100)
    av.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
    av.BorderSizePixel = 0
    av.ZIndex = 12
    av.Parent = f
    Instance.new("UICorner", av).CornerRadius = UDim.new(0, 10)
    local avStroke = Instance.new("UIStroke")
    avStroke.Color = Color3.fromRGB(140, 40, 255)
    avStroke.Thickness = 1
    avStroke.Parent = av

    local avIcon = Instance.new("TextLabel")
    avIcon.Size = UDim2.new(0, 70, 0, 70)
    avIcon.Position = UDim2.new(0, 12, 0.5, -35)
    avIcon.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
    avIcon.Text = "👤"
    avIcon.TextSize = 32
    avIcon.ZIndex = 13
    avIcon.Parent = av
    Instance.new("UICorner", avIcon).CornerRadius = UDim.new(1,0)

    local avName = Instance.new("TextLabel")
    avName.Size = UDim2.new(1, -100, 0, 24)
    avName.Position = UDim2.new(0, 95, 0, 22)
    avName.BackgroundTransparency = 1
    avName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
    avName.TextColor3 = Color3.fromRGB(230, 200, 255)
    avName.Font = Enum.Font.GothamBold
    avName.TextSize = 16
    avName.TextXAlignment = Enum.TextXAlignment.Left
    avName.ZIndex = 13
    avName.Parent = av

    local avSub = Instance.new("TextLabel")
    avSub.Size = UDim2.new(1, -100, 0, 18)
    avSub.Position = UDim2.new(0, 95, 0, 48)
    avSub.BackgroundTransparency = 1
    avSub.Text = "@"..LocalPlayer.Name.."  ·  ONLINE"
    avSub.TextColor3 = Color3.fromRGB(0, 255, 160)
    avSub.Font = Enum.Font.Code
    avSub.TextSize = 11
    avSub.TextXAlignment = Enum.TextXAlignment.Left
    avSub.ZIndex = 13
    avSub.Parent = av

    -- pulse anim on avatar ring
    task.spawn(function()
        while av.Parent do
            TweenService:Create(avStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.6}):Play()
            task.wait(1.2)
            TweenService:Create(avStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.1}):Play()
            task.wait(1.2)
        end
    end)

    MakeSection(f, "Quick Status")
    local statusCard = Instance.new("Frame")
    statusCard.Size = UDim2.new(1, -4, 0, 70)
    statusCard.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
    statusCard.BorderSizePixel = 0
    statusCard.ZIndex = 12
    statusCard.Parent = f
    Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 8)
    local stTxt = Instance.new("TextLabel")
    stTxt.Size = UDim2.new(1, -16, 1, 0)
    stTxt.Position = UDim2.new(0, 8, 0, 0)
    stTxt.BackgroundTransparency = 1
    stTxt.Text = "Aim: OFF\nESP: OFF\nProtect: Anti-Kick ON"
    stTxt.TextColor3 = Color3.fromRGB(180, 160, 220)
    stTxt.Font = Enum.Font.Code
    stTxt.TextSize = 12
    stTxt.TextXAlignment = Enum.TextXAlignment.Left
    stTxt.TextYAlignment = Enum.TextYAlignment.Center
    stTxt.ZIndex = 13
    stTxt.Parent = statusCard
    B.HomeStatus = stTxt

    MakeSection(f, "Panel Size")
    MakeSlider(f, "Width", 320, 520, B.Settings.UI.Width, function(v)
        B.Settings.UI.Width = v
        Main.Size = UDim2.new(0, v, 0, B.Settings.UI.Height)
    end)
    MakeSlider(f, "Height", 420, 680, B.Settings.UI.Height, function(v)
        B.Settings.UI.Height = v
        Main.Size = UDim2.new(0, B.Settings.UI.Width, 0, v)
    end)

    MakeSection(f, "About")
    local about = Instance.new("Frame")
    about.Size = UDim2.new(1, -4, 0, 60)
    about.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
    about.BorderSizePixel = 0
    about.ZIndex = 12
    about.Parent = f
    Instance.new("UICorner", about).CornerRadius = UDim.new(0, 8)
    local ab = Instance.new("TextLabel")
    ab.Size = UDim2.new(1, -12, 1, 0)
    ab.Position = UDim2.new(0, 8, 0, 0)
    ab.BackgroundTransparency = 1
    ab.Text = "BAXTARA X CHEAT v5.1\nDeveloper: NUGI CENEL\nEXECUTE · DOMINATE · WIN"
    ab.TextColor3 = Color3.fromRGB(160, 120, 220)
    ab.Font = Enum.Font.Code
    ab.TextSize = 11
    ab.TextXAlignment = Enum.TextXAlignment.Left
    ab.TextYAlignment = Enum.TextYAlignment.Center
    ab.ZIndex = 13
    ab.Parent = about
    Layout(f)
end

-- Continue in next part due to length - AIM, ESP, BRUTAL, SETTINGS, systems
-- I'll append the rest via a second write by reading and noting - actually complete in one go with essential systems.

-- AIM systems + rest of UI built below after key validation
local FOVCircle, TargetLine
local function MakeFOV()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if not DrawingLib then return end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 3.5
    FOVCircle.NumSides = 64
    FOVCircle.Radius = B.Settings.Aim.FOV
    FOVCircle.Filled = false
    FOVCircle.Color = Color3.fromRGB(160, 60, 255)
    FOVCircle.Transparency = 0.3
    FOVCircle.Visible = false
    B.Drawings.FOV = FOVCircle
end
local function MakeLine()
    if TargetLine then pcall(function() TargetLine:Remove() end) end
    if not DrawingLib then return end
    TargetLine = Drawing.new("Line")
    TargetLine.Thickness = 1.5
    TargetLine.Color = Color3.fromRGB(200, 100, 255)
    TargetLine.Transparency = 0.35
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
                                if B.Settings.Aim.VisibilityCheck and not visible then
                                else
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
    -- NPC targets for silent / anti-miss
    if B.Settings.Aim.SilentAim or B.Settings.Aim.AntiMiss then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if hum and hum.Health > 0 and root then
                    local dist = DistTo(root.Position)
                    if dist <= B.Settings.Aim.AimDistance then
                        local screen, on = WorldToScreen(root.Position)
                        if on then
                            local cross = (screen - center).Magnitude
                            if cross <= fov and cross < bestScore then
                                bestScore = cross
                                best = obj -- store model as target
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
    local char, part
    if typeof(target) == "Instance" and target:IsA("Player") then
        char = GetChar(target)
        if not IsAlive(char) then B.LockedTarget = nil return end
        part = GetAimPart(char)
    elseif typeof(target) == "Instance" and target:IsA("Model") then
        char = target
        part = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
    end
    if not part then return end
    if B.Settings.Aim.VisibilityCheck and typeof(target) == "Instance" and target:IsA("Player") then
        if not IsVisible(Camera.CFrame.Position, part.Position, char) then
            B.LockedTarget = nil
            return
        end
    end
    local pos = part.Position
    if B.Settings.Aim.AimPrediction then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        pos = pos + vel * B.Settings.Aim.PredictionAmount
    end
    if B.Settings.Aim.SilentAim then
        -- soft snap: still move camera slightly for feedback but stronger to target
        local current = Camera.CFrame
        Camera.CFrame = current:Lerp(CFrame.new(current.Position, pos), 0.55)
    else
        local current = Camera.CFrame
        local goal = CFrame.new(current.Position, pos)
        local smooth = B.Settings.Aim.AimSmoothing
        if B.Settings.Protect.SoftCamera then smooth = math.clamp(smooth * 0.7, 0.05, 0.3) end
        if B.Settings.Aim.AntiMiss then smooth = math.clamp(smooth + 0.15, 0.1, 0.45) end
        Camera.CFrame = current:Lerp(goal, smooth)
    end
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
        FOVCircle.Thickness = 3.5
        FOVCircle.Visible = true
    elseif FOVCircle then FOVCircle.Visible = false end

    if B.Settings.Aim.AimLock and B.LockedTarget then
        local still = false
        if typeof(B.LockedTarget) == "Instance" and B.LockedTarget:IsA("Player") then
            local char = GetChar(B.LockedTarget)
            if IsAlive(char) then
                local part = GetAimPart(char)
                if part then
                    local screen, on = WorldToScreen(part.Position)
                    local vis = true
                    if B.Settings.Aim.VisibilityCheck then vis = IsVisible(Camera.CFrame.Position, part.Position, char) end
                    if on and vis and (screen - center).Magnitude <= B.Settings.Aim.FOV * 1.8 then still = true end
                end
            end
        end
        if not still then B.LockedTarget = nil end
    end

    local target = (B.Settings.Aim.AimLock and B.LockedTarget) or GetBestTarget()
    if B.Settings.Aim.AimLock and not B.LockedTarget and target then B.LockedTarget = target end
    if not B.Settings.Aim.AimLock then B.LockedTarget = nil end
    B.CurrentTarget = target
    if target then
        AimAt(target)
        if TargetLine and B.Settings.Aim.DrawTargetLine then
            local part
            if typeof(target) == "Instance" and target:IsA("Player") then
                part = GetAimPart(GetChar(target))
            elseif typeof(target) == "Instance" then
                part = target:FindFirstChild("Head") or target.PrimaryPart
            end
            if part then
                local screen, on = WorldToScreen(part.Position)
                if on then
                    TargetLine.From = center
                    TargetLine.To = screen
                    TargetLine.Visible = true
                else TargetLine.Visible = false end
            end
        end
    else
        if TargetLine then TargetLine.Visible = false end
    end
end

-- ESP simplified stable
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
    end
    B.ESPObjects[id] = pack
    return pack
end
local function HidePack(pack)
    if not pack then return end
    for _, d in pairs(pack) do if d and d.Visible ~= nil then d.Visible = false end end
end
local function UpdatePlayerESP()
    if not B.Settings.ESP.Enabled then
        for _, pack in pairs(B.ESPObjects) do HidePack(pack) end
        return
    end
    local camPos = Camera.CFrame.Position
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
        local visible = true
        if B.Settings.ESP.VisibleCheck then visible = IsVisible(camPos, head.Position, char) end
        local color = visible and B.Settings.ESP.VisibleColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.PriorityMark and B.CurrentTarget == player then color = B.Settings.ESP.PriorityColor end
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
            pack.Dist.Color = Color3.fromRGB(180, 200, 210)
            pack.Dist.Visible = on
        end
    end
end

-- Movement + combat stubs (from v5, condensed)
local FlyBV, FlyBG, NoclipConn, JumpConn
local function SetFly(on)
    local char = LocalPlayer.Character
    local root = char and GetRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if FlyBV then FlyBV:Destroy() FlyBV=nil end
    if FlyBG then FlyBG:Destroy() FlyBG=nil end
    if on then
        hum.PlatformStand = true
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.MaxForce = Vector3.new(4e4,4e4,4e4)
        FlyBV.Parent = root
        FlyBG = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(4e4,4e4,4e4)
        FlyBG.P = 8000
        FlyBG.Parent = root
        AddConn(RunService.RenderStepped:Connect(function()
            if not B.Settings.Brutal.Fly or not FlyBV then return end
            local cf = Camera.CFrame
            local m = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then m=m+cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then m=m-cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then m=m-cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then m=m+cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then m=m+Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then m=m-Vector3.yAxis end
            FlyBV.Velocity = m.Magnitude>0.1 and m.Unit*B.Settings.Brutal.FlySpeed or Vector3.zero
            FlyBG.CFrame = cf
        end))
    else
        if hum then hum.PlatformStand = false end
    end
end
local function SetSpeed(on)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then B.OriginalWalkSpeed = hum.WalkSpeed hum.WalkSpeed = math.clamp(B.Settings.Brutal.SpeedValue,16,40)
    else hum.WalkSpeed = B.OriginalWalkSpeed or 16 end
end
local function SetNoclip(on)
    if NoclipConn then NoclipConn:Disconnect() NoclipConn=nil end
    for p,c in pairs(B.OriginalCollision) do if p and p.Parent then pcall(function() p.CanCollide=c end) end end
    B.OriginalCollision = {}
    if on then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if B.OriginalCollision[part]==nil then B.OriginalCollision[part]=part.CanCollide end
                    part.CanCollide = false
                end
            end
        end)
        AddConn(NoclipConn)
    end
end
local function SetHitbox(on)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local root = GetRoot(GetChar(p))
            if root then
                if on then
                    root.Size = Vector3.new(B.Settings.Brutal.HitboxSize, B.Settings.Brutal.HitboxSize, B.Settings.Brutal.HitboxSize)
                    root.Transparency = 0.55
                    root.CanCollide = false
                    if B.Settings.Brutal.HitboxRedAim and B.CurrentTarget == p then
                        root.Color = Color3.fromRGB(255, 40, 40)
                    else
                        root.Color = Color3.fromRGB(255, 100, 100)
                    end
                else
                    root.Size = Vector3.new(2,2,1)
                    root.Transparency = 1
                end
            end
        end
    end
end
local function ScanNPCs()
    B.NPCList = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            if hum and root and hum.Health > 0 then
                table.insert(B.NPCList, {model=obj, hum=hum, root=root})
            end
        end
    end
end
local function DoKillAllNPC()
    ScanNPCs()
    for _, n in ipairs(B.NPCList) do
        pcall(function()
            if B.Settings.Brutal.DamageConfig then
                n.hum:TakeDamage(B.Settings.Brutal.DamageValue)
            end
            n.hum.Health = 0
        end)
    end
end
local function DoOneHitNPC()
    ScanNPCs()
    local best, bd = nil, 9999
    local my = GetRoot(LocalPlayer.Character)
    if not my then return end
    for _, n in ipairs(B.NPCList) do
        local d = (my.Position - n.root.Position).Magnitude
        if d < bd then bd=d best=n end
    end
    if best then
        pcall(function()
            if B.Settings.Brutal.DamageConfig then best.hum:TakeDamage(B.Settings.Brutal.DamageValue) end
            best.hum.Health = 0
        end)
    end
end
local function GetTool()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Tool")
end
local function PatchWeapon()
    local tool = GetTool()
    if not tool then return end
    if B.Settings.Brutal.AntiCooldown then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n = v.Name:lower()
                if n:find("cool") or n:find("delay") or n:find("rate") or n:find("firerate") or n:find("interval") then
                    pcall(function() v.Value = 0 end)
                end
            end
        end
        pcall(function()
            tool:SetAttribute("Cooldown", 0)
            tool:SetAttribute("FireRate", 0.01)
            tool:SetAttribute("Debounce", false)
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

-- AIM tab
do
    local f = TabFrames.AIM
    MakeSection(f, "Core")
    MakeToggle(f, "Enable Aimbot", false, function(v) B.Settings.Aim.Enabled=v if v then MakeFOV() MakeLine() end end)
    MakeToggle(f, "Silent Aim (snap hard)", false, function(v) B.Settings.Aim.SilentAim=v end)
    MakeToggle(f, "Anti Miss Aim", false, function(v) B.Settings.Aim.AntiMiss=v end)
    MakeToggle(f, "Visibility Check", true, function(v) B.Settings.Aim.VisibilityCheck=v end)
    MakeToggle(f, "Head Aim", true, function(v) B.Settings.Aim.HeadAim=v B.Settings.Aim.HitPart="Head" if v then B.Settings.Aim.BodyAim=false end end)
    MakeToggle(f, "Body Aim", false, function(v) B.Settings.Aim.BodyAim=v B.Settings.Aim.HitPart="Body" if v then B.Settings.Aim.HeadAim=false end end)
    MakeToggle(f, "Multi-Bone", false, function(v) B.Settings.Aim.MultiBone=v end)
    MakeSection(f, "FOV")
    MakeToggle(f, "FOV Circle", true, function(v) B.Settings.Aim.FOVCircle=v end)
    MakeSlider(f, "FOV Size", 40, 1000, 180, function(v) B.Settings.Aim.FOV=v end)
    MakeSlider(f, "Aim Distance", 50, 2000, 800, function(v) B.Settings.Aim.AimDistance=v end)
    MakeSection(f, "Feel")
    MakeToggle(f, "Aim Lock", false, function(v) B.Settings.Aim.AimLock=v if not v then B.LockedTarget=nil end end)
    MakeToggle(f, "Prediction", false, function(v) B.Settings.Aim.AimPrediction=v end)
    MakeSlider(f, "Smoothing x100", 5, 50, 20, function(v) B.Settings.Aim.AimSmoothing=v/100 end)
    MakeToggle(f, "Target Line", false, function(v) B.Settings.Aim.DrawTargetLine=v end)
    MakeToggle(f, "Team Check", true, function(v) B.Settings.Aim.TeamCheck=v end)
    MakeToggle(f, "Soft Camera", true, function(v) B.Settings.Protect.SoftCamera=v end)
    Layout(f)
end

-- ESP
do
    local f = TabFrames.ESP
    MakeSection(f, "Player ESP")
    MakeToggle(f, "Enable ESP", false, function(v) B.Settings.ESP.Enabled=v end)
    MakeToggle(f, "Box", true, function(v) B.Settings.ESP.Box=v end)
    MakeToggle(f, "Name", true, function(v) B.Settings.ESP.Name=v end)
    MakeToggle(f, "Health Bar", true, function(v) B.Settings.ESP.HealthBar=v end)
    MakeToggle(f, "Distance", true, function(v) B.Settings.ESP.Distance=v end)
    MakeToggle(f, "Visible Check", true, function(v) B.Settings.ESP.VisibleCheck=v end)
    MakeToggle(f, "Priority Mark", true, function(v) B.Settings.ESP.PriorityMark=v end)
    MakeSlider(f, "Max Distance", 100, 2000, 900, function(v) B.Settings.ESP.MaxDistance=v end)
    Layout(f)
end

-- BRUTAL
do
    local f = TabFrames.BRUTAL
    MakeSection(f, "Movement")
    MakeToggle(f, "Fly", false, function(v) B.Settings.Brutal.Fly=v SetFly(v) end)
    MakeSlider(f, "Fly Speed", 10, 80, 40, function(v) B.Settings.Brutal.FlySpeed=v end)
    MakeToggle(f, "Speed Hack", false, function(v) B.Settings.Brutal.SpeedHack=v SetSpeed(v) end)
    MakeSlider(f, "Speed", 16, 40, 24, function(v) B.Settings.Brutal.SpeedValue=v if B.Settings.Brutal.SpeedHack then SetSpeed(true) end end)
    MakeToggle(f, "Noclip", false, function(v) B.Settings.Brutal.Noclip=v SetNoclip(v) end)
    MakeToggle(f, "Infinite Jump", false, function(v)
        B.Settings.Brutal.InfiniteJump=v
        if JumpConn then JumpConn:Disconnect() JumpConn=nil end
        if v then
            JumpConn = UserInputService.JumpRequest:Connect(function()
                local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
            AddConn(JumpConn)
        end
    end)
    MakeSection(f, "Hitbox")
    MakeToggle(f, "Hitbox Expand", false, function(v) B.Settings.Brutal.HitboxExpand=v SetHitbox(v) end)
    MakeToggle(f, "Hitbox Red on Aim", true, function(v) B.Settings.Brutal.HitboxRedAim=v end)
    MakeSlider(f, "Hitbox Size", 2, 25, 8, function(v) B.Settings.Brutal.HitboxSize=v if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end end)
    MakeSection(f, "Weapon")
    MakeToggle(f, "Anti Cooldown", false, function(v) B.Settings.Brutal.AntiCooldown=v end)
    MakeToggle(f, "Infinite Ammo", false, function(v) B.Settings.Brutal.InfiniteAmmo=v end)
    MakeToggle(f, "Auto Shoot", false, function(v) B.Settings.Brutal.AutoShoot=v end)
    MakeSection(f, "NPC")
    MakeToggle(f, "Damage Config", false, function(v) B.Settings.Brutal.DamageConfig=v end)
    MakeSlider(f, "Damage Value", 10, 500, 150, function(v) B.Settings.Brutal.DamageValue=v end)
    MakeButton(f, "ONE HIT NEAREST NPC", Color3.fromRGB(120, 30, 50), DoOneHitNPC)
    MakeButton(f, "KILL ALL NPC", Color3.fromRGB(100, 20, 40), DoKillAllNPC)
    MakeToggle(f, "God Mode (local)", false, function(v)
        B.Settings.Brutal.GodMode=v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then
            if v then h.MaxHealth=1e9 h.Health=1e9 else h.MaxHealth=100 end
        end
    end)
    Layout(f)
end

-- SETTINGS
do
    local f = TabFrames.SETTINGS
    MakeSection(f, "Visual / Performance")
    MakeToggle(f, "FullBright", false, function(v)
        B.Settings.Visual.FullBright=v
        Lighting.Brightness = v and 2.2 or 1
        Lighting.GlobalShadows = not v
    end)
    MakeToggle(f, "No Fog", false, function(v) B.Settings.Visual.NoFog=v Lighting.FogEnd = v and 9e6 or 1000 end)
    MakeToggle(f, "Anti Lag (low quality)", false, function(v)
        B.Settings.Visual.AntiLag = v
        pcall(function()
            settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = not v
            Lighting.Technology = v and Enum.Technology.Legacy or Enum.Technology.ShadowMap
        end)
    end)
    MakeToggle(f, "Streaming Mode", false, function(v)
        B.Settings.Visual.StreamingMode=v
        local op = v and B.Settings.Visual.StreamingOpacity or 1
        Main.BackgroundTransparency = 1-op
        Header.BackgroundTransparency = 1-op
    end)
    MakeSection(f, "Protect")
    MakeToggle(f, "Anti-Kick", true, function(v) B.Settings.Protect.AntiKick=v end)
    MakeToggle(f, "Auto Hop on Flag", true, function(v) B.Settings.Protect.AutoHopOnFlag=v end)
    MakeButton(f, "FORCE SERVER HOP", Color3.fromRGB(30, 70, 50), function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    MakeButton(f, "UNLOAD", Color3.fromRGB(90, 25, 35), function()
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
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
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
OpenBtn.Size = UDim2.new(0, 48, 0, 48)
OpenBtn.Position = UDim2.new(1, -60, 0.5, -24)
OpenBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 180)
OpenBtn.Text = "BX"
OpenBtn.TextColor3 = Color3.fromRGB(240, 230, 255)
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
    local input = (KeyBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if input:upper() == ACCESS_KEY:upper() then
        StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 160)
        StatusLbl.Text = "ACCESS GRANTED"
        B.Unlocked = true
        task.wait(0.45)
        TweenService:Create(KeyFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        for _, ch in ipairs(KeyFrame:GetDescendants()) do
            if ch:IsA("Frame") then TweenService:Create(ch, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play() end
            if ch:IsA("TextLabel") or ch:IsA("TextButton") or ch:IsA("TextBox") then
                TweenService:Create(ch, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
            end
        end
        task.wait(0.4)
        KeyFrame.Visible = false

        -- cinematic
        LoadFrame.Visible = true
        local steps = {
            {0.15, "INITIALIZING SYSTEM"},
            {0.35, "LOADING INTERFACE"},
            {0.55, "PREPARING MODULES"},
            {0.75, "ACCESS CONFIRMED"},
            {1.0, "READY"},
        }
        TweenService:Create(CrownLbl, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
        TweenService:Create(LoadTitle, TweenInfo.new(1), {TextTransparency = 0}):Play()
        TweenService:Create(RingStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Thickness = 5, Transparency = 0.05
        }):Play()
        for i, s in ipairs(steps) do
            LoadBar:TweenSize(UDim2.new(s[1], 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35, true)
            LoadStatus.Text = s[2]
            LoadPct.Text = math.floor(s[1]*100).."%"
            task.wait(0.55)
        end
        task.wait(0.3)
        TweenService:Create(LoadFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        task.wait(0.4)
        LoadFrame.Visible = false
        OpenBtn.Visible = UserInputService.TouchEnabled
        ShowPanel()
        MakeFOV()
        MakeLine()
    else
        StatusLbl.TextColor3 = Color3.fromRGB(255, 80, 100)
        StatusLbl.Text = "INVALID KEY"
        -- shake
        local orig = KeyCard.Position
        for i = 1, 4 do
            KeyCard.Position = orig + UDim2.new(0, (i%2==0 and 6 or -6), 0, 0)
            task.wait(0.04)
        end
        KeyCard.Position = orig
    end
end)

-- Main loops after unlock only effectively (UpdateAim checks Enabled)
AddConn(RunService.RenderStepped:Connect(function()
    if not B.Unlocked then return end
    UpdateAim()
    UpdatePlayerESP()
    if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
end))
AddConn(RunService.Heartbeat:Connect(function()
    if not B.Unlocked then return end
    if B.Settings.Brutal.AntiCooldown or B.Settings.Brutal.InfiniteAmmo then PatchWeapon() end
    if B.Settings.Brutal.AutoShoot then
        local t = GetTool()
        if t then pcall(function() t:Activate() end) end
    end
    if B.HomeStatus then
        B.HomeStatus.Text = string.format(
            "Aim: %s  |  Silent: %s\nESP: %s\nProtect: Anti-Kick %s",
            B.Settings.Aim.Enabled and "ON" or "OFF",
            B.Settings.Aim.SilentAim and "ON" or "OFF",
            B.Settings.ESP.Enabled and "ON" or "OFF",
            B.Settings.Protect.AntiKick and "ON" or "OFF"
        )
    end
end))

AddConn(CoreGui.DescendantAdded:Connect(function(obj)
    if not B.Settings.Protect.AntiKick then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local t = (obj.Text or ""):lower()
        if t:find("suspicious") or t:find("banned") or t:find("exploiting") or t:find("timedout") or t:find("kicked") then
            if B.Settings.Protect.AutoHopOnFlag then
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        end
    end
end))

print("[BAXTARA X CHEAT v5.1] Key gate | Cinematic | Silent+AntiMiss | FOV1000 | Hitbox25 | NUGI CENEL")
