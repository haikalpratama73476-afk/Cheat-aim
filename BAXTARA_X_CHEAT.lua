--[[
BAXTARA X — FOUR WORLDS UI / v7.0

LOCAL INTERFACE ONLY.
- Runs as a Roblox LocalScript in StarterPlayerScripts.
- Includes responsive UI, profile/session display, theme selector,
  visual lab, preferences, FPS/player counters, drag, and open/close controls.
- Does not automate gameplay, alter other players, invoke remotes, modify
  character physics, manipulate server state, or evade anti-cheat/moderation.

The four themes use different layout systems and opening sequences:
Galaxy: space backdrop + orbital frame + zooming planet.
LEGO: brick-built panel + studs + assembly/opening box sequence.
Modern: editorial workspace + scan sweep.
Idul Fitri: emerald/gold ornaments + greeting before panel reveal.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[BAXTARA] LocalPlayer unavailable. Use a LocalScript.")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GUI_NAME = "BAXTARA_X_CHEAT"
local old = PlayerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local Themes = {
    Galaxy = {
        Name = "GALAXY / ORBITAL SYSTEM",
        Short = "GALAXY",
        Style = "Galaxy",
        Background = Color3.fromRGB(4, 7, 20),
        Surface = Color3.fromRGB(10, 15, 34),
        Card = Color3.fromRGB(16, 23, 48),
        Raised = Color3.fromRGB(25, 35, 69),
        Element = Color3.fromRGB(34, 46, 85),
        Text = Color3.fromRGB(241, 244, 255),
        Muted = Color3.fromRGB(143, 158, 195),
        Accent = Color3.fromRGB(166, 111, 255),
        Accent2 = Color3.fromRGB(65, 207, 255),
        Border = Color3.fromRGB(111, 86, 204),
        Off = Color3.fromRGB(48, 59, 94),
        Danger = Color3.fromRGB(255, 102, 139),
        Radius = 18,
    },
    Lego = {
        Name = "LEGO / BRICKWORK STUDIO",
        Short = "BRICKWORK",
        Style = "Lego",
        Background = Color3.fromRGB(22, 29, 43),
        Surface = Color3.fromRGB(34, 43, 60),
        Card = Color3.fromRGB(43, 57, 78),
        Raised = Color3.fromRGB(64, 78, 101),
        Element = Color3.fromRGB(80, 96, 121),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(213, 220, 231),
        Accent = Color3.fromRGB(255, 199, 45),
        Accent2 = Color3.fromRGB(45, 137, 255),
        Border = Color3.fromRGB(13, 18, 29),
        Off = Color3.fromRGB(73, 87, 108),
        Danger = Color3.fromRGB(240, 67, 58),
        Radius = 4,
    },
    Modern = {
        Name = "MODERN / EDITORIAL WORKSPACE",
        Short = "STUDIO",
        Style = "Modern",
        Background = Color3.fromRGB(12, 16, 23),
        Surface = Color3.fromRGB(18, 24, 33),
        Card = Color3.fromRGB(23, 31, 42),
        Raised = Color3.fromRGB(30, 40, 53),
        Element = Color3.fromRGB(39, 51, 66),
        Text = Color3.fromRGB(243, 246, 250),
        Muted = Color3.fromRGB(151, 164, 181),
        Accent = Color3.fromRGB(100, 184, 255),
        Accent2 = Color3.fromRGB(107, 224, 207),
        Border = Color3.fromRGB(79, 103, 130),
        Off = Color3.fromRGB(59, 72, 88),
        Danger = Color3.fromRGB(255, 112, 120),
        Radius = 13,
    },
    Eid = {
        Name = "IDUL FITRI / SERENITY",
        Short = "SERENITY",
        Style = "Eid",
        Background = Color3.fromRGB(5, 25, 20),
        Surface = Color3.fromRGB(10, 43, 33),
        Card = Color3.fromRGB(15, 55, 42),
        Raised = Color3.fromRGB(23, 69, 53),
        Element = Color3.fromRGB(34, 86, 65),
        Text = Color3.fromRGB(255, 249, 231),
        Muted = Color3.fromRGB(193, 198, 164),
        Accent = Color3.fromRGB(229, 190, 105),
        Accent2 = Color3.fromRGB(87, 171, 116),
        Border = Color3.fromRGB(179, 143, 75),
        Off = Color3.fromRGB(55, 83, 67),
        Danger = Color3.fromRGB(226, 103, 86),
        Radius = 15,
    },
}

local State = {
    Theme = "Galaxy",
    Page = "OVERVIEW",
    PanelVisible = false,
    Opening = false,
    Destroyed = false,
    Ambient = true,
    StarParticles = true,
    OrbitMotion = true,
    KetupatMotion = true,
    ReduceMotion = false,
    CompactCards = false,
    Glow = 0.72,
    AnimationSpeed = 1.0,
    -- FEATURES
    AimEnabled = false,
    SilentAim = false,
    AntiMiss = false,
    AimLock = false,
    VisCheck = true,
    HeadAim = true,
    BodyAim = false,
    FOVCircle = true,
    TeamCheck = true,
    AimNPC = false,
    FOV = 180,
    Smooth = 15,
    AimDist = 800,
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDist = true,
    ESPTracer = true,
    ESPSkeleton = false,
    ESPNPC = false,
    TracerOrigin = "Bottom",
    ESPMaxDist = 1000,
    Fly = false,
    FlySpeed = 45,
    SpeedHack = false,
    SpeedValue = 28,
    InfJump = false,
    Noclip = false,
    GodMode = false,
    GhostMode = false,
    Hitbox = false,
    HitboxSize = 8,
    HitboxPart = "Body",
    SpinBot = false,
    SpinSpeed = 40,
    FlyKillAll = false,
    AntiCD = false,
    InfAmmo = false,
    AttackSpeed = false,
    AttackSpeedVal = 8,
    SkyHack = false,
    SelfTag = false,
    SelfTagText = "BAXTARA",
    SelfTagRainbow = false,
    ChatBubble = false,
    FreezeOthers = false,
    AntiLag = false,
    HitboxHead = false,
    ESPHue = 0.55,
    ESPSat = 0.9,
    ESPVal = 1.0,
    ModernESP = false,
    ModernAim = false,
    PanelHidden = false,
}



local Theme = Themes[State.Theme]
local Features = {} -- filled later by feature engine

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 90
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Stage, Main, Launcher, Content
local FpsLabel, PlayerLabel, SessionLabel
local OrbitNodes, StarNodes, KetupatNodes = {}, {}, {}
local Dragging, DragInput, DragStart = false, nil, nil
local ActiveSlider = nil
local SessionStart = os.clock()
local LastStats = os.clock()
local Frames = 0
local FPS = 0
local Connections = {}
local renderUI
local openPanel
local closePanel

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function make(className, properties, parent)
    local obj = Instance.new(className)
    for key, value in pairs(properties or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radius) }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency == nil and 0.35 or transparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function gradient(parent, a, b, rotation)
    return make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, a),
            ColorSequenceKeypoint.new(1, b),
        }),
        Rotation = rotation or 0,
    }, parent)
end

local function label(parent, value, size, color, font, position, dimensions, alignment)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = value or "",
        TextColor3 = color or Theme.Text,
        TextSize = size or 12,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        Position = position or UDim2.new(),
        Size = dimensions or UDim2.new(1, 0, 0, 22),
        ZIndex = (parent.ZIndex or 1) + 1,
    }, parent)
end

local function playTween(object, duration, props, style, direction)
    if not object or not object.Parent then return nil end
    if State.ReduceMotion then
        for key, value in pairs(props) do object[key] = value end
        return nil
    end
    local tw = TweenService:Create(object, TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    ), props)
    tw:Play()
    return tw
end

local function notify(message, tint)
    if State.Destroyed then return end
    local toast = make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 24, 0, 18),
        Size = UDim2.fromOffset(252, 52),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ZIndex = 150,
    }, ScreenGui)
    corner(toast, Theme.Style == "Lego" and 4 or 12)
    stroke(toast, tint or Theme.Accent, Theme.Style == "Lego" and 2 or 1, 0.16)
    label(toast, "BAXTARA / NOTICE", 9, tint or Theme.Accent, Enum.Font.GothamBold,
        UDim2.fromOffset(12, 5), UDim2.new(1, -22, 0, 14))
    label(toast, message, 11, Theme.Text, Enum.Font.GothamMedium,
        UDim2.fromOffset(12, 22), UDim2.new(1, -22, 0, 20))
    playTween(toast, 0.28, { Position = UDim2.new(1, -14, 0, 18) }, Enum.EasingStyle.Back)
    task.delay(2.2, function()
        if toast.Parent then
            playTween(toast, 0.18, { Position = UDim2.new(1, 24, 0, 18) })
            task.delay(0.22, function() if toast.Parent then toast:Destroy() end end)
        end
    end)
end

local function addPlanet(parent, size, accent, accent2, z)
    local host = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size * 1.8, size * 1.8),
        ZIndex = z or 5,
    }, parent)
    local ring = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 0.40),
        Rotation = -27,
        BackgroundTransparency = 1,
        ZIndex = (z or 5) + 1,
    }, host)
    corner(ring, 99)
    stroke(ring, accent2, 2, 0.12)
    local sphere = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        ZIndex = (z or 5) + 2,
    }, host)
    corner(sphere, 99)
    gradient(sphere, accent2, accent, 35)
    stroke(sphere, Color3.fromRGB(240, 245, 255), 1, 0.55)
    local shine = make("Frame", {
        Position = UDim2.new(0.18, 0, 0.16, 0),
        Size = UDim2.new(0.36, 0, 0.14, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.68,
        BorderSizePixel = 0,
        ZIndex = (z or 5) + 3,
    }, sphere)
    corner(shine, 99)
    return host, ring, sphere
end

local function addKetupat(parent, position, size, collection, zIndex)
    local wrap = make("Frame", {
        BackgroundTransparency = 1,
        Position = position,
        Size = UDim2.fromOffset(size, size + 20),
        ZIndex = zIndex or 8,
    }, parent)
    local cord = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(2, 14),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = (zIndex or 8) + 1,
    }, wrap)
    local diamond = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, size * 0.62),
        Size = UDim2.fromOffset(size * 0.67, size * 0.67),
        Rotation = 45,
        BackgroundColor3 = Theme.Accent2,
        BorderSizePixel = 0,
        ZIndex = (zIndex or 8) + 2,
    }, wrap)
    corner(diamond, 3)
    gradient(diamond, Color3.fromRGB(116, 188, 113), Color3.fromRGB(22, 91, 59), 45)
    stroke(diamond, Theme.Accent, 1.5, 0.12)
    for i = 1, 3 do
        local band = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, i / 4, 0),
            Size = UDim2.new(1.13, 0, 0, 2),
            BackgroundColor3 = Color3.fromRGB(222, 193, 118),
            BorderSizePixel = 0,
            ZIndex = (zIndex or 8) + 3,
        }, diamond)
        band.Rotation = i == 2 and 90 or 0
    end
    if collection then table.insert(collection, wrap) end
    return wrap
end

local function makeLogo(parent, themeName, position, size)
    local artSize = size or 44
    local host = make("Frame", {
        BackgroundTransparency = 1,
        Position = position or UDim2.fromOffset(14, 8),
        Size = UDim2.fromOffset(artSize, artSize),
        ZIndex = math.max(20, (parent.ZIndex or 1) + 1),
    }, parent)
    local baseZ = host.ZIndex
    if themeName == "Galaxy" then
        local ring = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1.2, 0, 0.48, 0),
            Rotation = -31,
            BackgroundTransparency = 1,
            ZIndex = baseZ,
        }, host)
        corner(ring, 99)
        stroke(ring, Theme.Accent2, 2, 0.05)
        local sphere = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(artSize * 0.58, artSize * 0.58),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = baseZ + 2,
        }, host)
        corner(sphere, 99)
        gradient(sphere, Theme.Accent2, Theme.Accent, 40)
        stroke(sphere, Theme.Text, 1, 0.48)
        local satellite = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.83, 0, 0.35, 0),
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = Theme.Text,
            BorderSizePixel = 0,
            ZIndex = baseZ + 3,
        }, host)
        corner(satellite, 99)
    elseif themeName == "Lego" then
        -- Minifigure-style head: round face + top stud, deliberately not a square badge.
        local head = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.58, 0),
            Size = UDim2.fromOffset(artSize * 0.66, artSize * 0.66),
            BackgroundColor3 = Color3.fromRGB(255, 207, 48),
            BorderSizePixel = 0,
            ZIndex = baseZ + 2,
        }, host)
        corner(head, 99)
        stroke(head, Color3.fromRGB(172, 117, 19), 1.5, 0.12)
        local stud = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.13, 0),
            Size = UDim2.fromOffset(artSize * 0.25, artSize * 0.16),
            BackgroundColor3 = Color3.fromRGB(255, 220, 83),
            BorderSizePixel = 0,
            ZIndex = baseZ + 3,
        }, host)
        corner(stud, 5)
        label(head, "•  •", 9, Color3.fromRGB(50, 43, 27), Enum.Font.GothamBlack,
            UDim2.new(0, 0, 0.25, 0), UDim2.new(1, 0, 0, 11), Enum.TextXAlignment.Center)
        label(head, "⌣", 15, Color3.fromRGB(50, 43, 27), Enum.Font.GothamBold,
            UDim2.new(0, 0, 0.40, 0), UDim2.new(1, 0, 0, 17), Enum.TextXAlignment.Center)
    elseif themeName == "Eid" then
        local crescent = label(host, "☾", artSize * 0.88, Theme.Accent, Enum.Font.GothamBold,
            UDim2.fromScale(0.03, -0.12), UDim2.fromScale(0.92, 1.05), Enum.TextXAlignment.Center)
        crescent.TextStrokeTransparency = 0.72
        local mini = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.68, 0, 0.72, 0),
            Size = UDim2.fromOffset(artSize * 0.26, artSize * 0.26),
            Rotation = 45,
            BackgroundColor3 = Theme.Accent2,
            BorderSizePixel = 0,
            ZIndex = baseZ + 2,
        }, host)
        corner(mini, 2)
        stroke(mini, Theme.Accent, 1.2, 0.08)
    else
        local ring = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -3, 1, -3),
            BackgroundTransparency = 1,
            Rotation = -8,
            ZIndex = baseZ,
        }, host)
        corner(ring, 13)
        stroke(ring, Theme.Accent, 1.5, 0.14)
        label(host, "BX", artSize * 0.43, Theme.Text, Enum.Font.GothamBlack,
            UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.96, 0.94), Enum.TextXAlignment.Center)
        local slash = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.77, 0, 0.5, 0),
            Size = UDim2.new(0, 2, 0.72, 0),
            Rotation = 24,
            BackgroundColor3 = Theme.Accent2,
            BorderSizePixel = 0,
            ZIndex = baseZ + 2,
        }, host)
    end
    return host
end

local function buildBackdrop()
    -- Never paint over the Roblox viewport. Theme decoration is attached to Main.
    if Stage then
        Stage:Destroy()
        Stage = nil
    end
    OrbitNodes, StarNodes, KetupatNodes = {}, {}, {}
end

local function buildPanelDecor(parent)
    local decor = make("Frame", {
        Name = "ThemeDecor",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 20,
    }, parent)

    if Theme.Style == "Galaxy" then
        -- Deep-space color is confined to the panel. Orbital paths sit near its edges.
        for i = 1, 2 do
            local nebula = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = i == 1 and UDim2.new(0.16, 0, 0.18, 0) or UDim2.new(0.84, 0, 0.82, 0),
                Size = UDim2.fromScale(0.40, 0.30),
                BackgroundColor3 = i == 1 and Color3.fromRGB(77, 37, 137) or Color3.fromRGB(25, 64, 130),
                BackgroundTransparency = 0.91,
                BorderSizePixel = 0,
                ZIndex = 20,
            }, decor)
            corner(nebula, 999)
            gradient(nebula, Theme.Accent, Theme.Accent2, i == 1 and 28 or 142)
        end
        for i = 1, 34 do
            local star = make("Frame", {
                Position = UDim2.new(math.random(4, 96) / 100, 0, math.random(5, 95) / 100, 0),
                Size = UDim2.fromOffset(i % 7 == 0 and 3 or 2, i % 7 == 0 and 3 or 2),
                BackgroundColor3 = i % 4 == 0 and Theme.Accent2 or Theme.Text,
                BackgroundTransparency = math.random(45, 78) / 100,
                BorderSizePixel = 0,
                ZIndex = 20,
            }, decor)
            corner(star, 99)
            table.insert(StarNodes, { Object = star, Phase = math.random() * 6.28, Base = star.BackgroundTransparency })
        end
        for i = 1, 2 do
            local orbit = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.52),
                Size = i == 1 and UDim2.new(1, -26, 1, -36) or UDim2.new(1, -72, 1, -82),
                Rotation = i == 1 and -9 or 12,
                BackgroundTransparency = 1,
                ZIndex = 20,
            }, decor)
            corner(orbit, 999)
            stroke(orbit, i == 1 and Theme.Accent2 or Theme.Accent, 1.35, 0.48)
        end
        for i = 1, 3 do
            local host, ring = addPlanet(decor, i == 1 and 20 or 15,
                i == 1 and Theme.Accent or Theme.Accent2,
                i == 1 and Theme.Accent2 or Color3.fromRGB(229, 166, 255), 20)
            table.insert(OrbitNodes, {
                Host = host, Ring = ring,
                Phase = i * 2.12,
                RX = i == 1 and 0.39 or (i == 2 and 0.42 or 0.34),
                RY = i == 1 and 0.34 or (i == 2 and 0.30 or 0.38),
                Speed = i == 1 and 0.13 or (i == 2 and -0.10 or 0.08),
            })
        end
    elseif Theme.Style == "Lego" then
        -- LEGO studs are a subtle build-plate texture behind the actual controls.
        for row = 1, 7 do
            for col = 1, 12 do
                local stud = make("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((col - 0.5) / 12, 0, (row - 0.5) / 7, 0),
                    Size = UDim2.fromOffset(15, 9),
                    BackgroundColor3 = Color3.fromRGB(80, 98, 125),
                    BackgroundTransparency = 0.78,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                }, decor)
                corner(stud, 3)
                stroke(stud, Color3.fromRGB(130, 149, 178), 1, 0.86)
            end
        end
        local bottomRail = make("Frame", {
            Position = UDim2.new(0, 12, 1, -8),
            Size = UDim2.new(1, -24, 0, 5),
            BackgroundColor3 = Color3.fromRGB(44, 190, 75),
            BorderSizePixel = 0,
            ZIndex = 21,
        }, decor)
        corner(bottomRail, 2)
    elseif Theme.Style == "Eid" then
        -- Hanging ornaments and the crescent remain inside the panel clipping boundary.
        local crescent = label(decor, "☾", 100, Color3.fromRGB(198, 157, 78), Enum.Font.GothamBold,
            UDim2.new(1, -132, 0, 45), UDim2.fromOffset(108, 112), Enum.TextXAlignment.Center)
        crescent.TextTransparency = 0.84
        for i = 1, 3 do
            local x = ({ 0.16, 0.82, 0.91 })[i]
            local cord = make("Frame", {
                Position = UDim2.new(x, 0, 0, 0),
                Size = UDim2.fromOffset(1, 42 + i * 10),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.48,
                BorderSizePixel = 0,
                ZIndex = 20,
            }, decor)
            local lantern = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.fromOffset(12, 16),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.38,
                BorderSizePixel = 0,
                ZIndex = 21,
            }, cord)
            corner(lantern, 4)
        end
        addKetupat(decor, UDim2.new(0, 18, 0, 112), 29, KetupatNodes, 21)
        addKetupat(decor, UDim2.new(1, -49, 1, -78), 32, KetupatNodes, 21)
    else
        -- Modern uses a restrained edge glow and precise divider, not a full-screen wash.
        local glow = make("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -18, 0, 82),
            Size = UDim2.fromOffset(180, 180),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.95,
            BorderSizePixel = 0,
            ZIndex = 20,
        }, decor)
        corner(glow, 999)
        local rail = make("Frame", {
            Position = UDim2.new(0, 0, 0, 61),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Border,
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            ZIndex = 21,
        }, decor)
    end
    return decor
end

local PageNames = {
    { Name = "OVERVIEW", Icon = "⌂" },
    { Name = "AIM", Icon = "◎" },
    { Name = "ESP", Icon = "▣" },
    { Name = "MODERN", Icon = "◆" },
    { Name = "BRUTAL", Icon = "⚡" },
    { Name = "LOCAL", Icon = "⚙" },
    { Name = "APPEARANCE", Icon = "◈" },
    { Name = "ABOUT", Icon = "i" },
}

local function addSectionHeading(parent, title, subtitle)
    local titleSize = Theme.Style == "Modern" and 22 or 19
    label(parent, title, titleSize, Theme.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(3, 0), UDim2.new(1, -6, 0, 30))
    label(parent, subtitle, 10, Theme.Muted, Enum.Font.Gotham,
        UDim2.fromOffset(4, 30), UDim2.new(1, -8, 0, 25))
    local divider = make("Frame", {
        Position = UDim2.fromOffset(4, 61),
        Size = UDim2.new(1, -8, 0, Theme.Style == "Lego" and 4 or 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = Theme.Style == "Modern" and 0.68 or 0.30,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, parent)
    if Theme.Style == "Lego" then
        corner(divider, 1)
        for i = 1, 12 do
            local stud = make("Frame", {
                Position = UDim2.new((i - 1) / 12, 2, 0, -2),
                Size = UDim2.fromOffset(9, 7),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 7,
            }, divider)
            corner(stud, 3)
        end
    end
end

local function makeCard(parent, titleText, subtitle, height, order, colorOverride)
    local style = Theme.Style
    local bg = colorOverride or Theme.Card
    if style == "Lego" and not colorOverride then
        local palette = {
            Color3.fromRGB(190, 43, 43),
            Color3.fromRGB(28, 91, 190),
            Color3.fromRGB(206, 151, 24),
            Color3.fromRGB(39, 139, 70),
        }
        bg = palette[((order or 1) - 1) % #palette + 1]
    end
    local card = make("Frame", {
        Size = UDim2.new(1, -8, 0, height or 120),
        BackgroundColor3 = bg,
        BorderSizePixel = 0,
        LayoutOrder = order or 1,
        ZIndex = 6,
    }, parent)
    corner(card, style == "Lego" and 2 or (style == "Galaxy" and 17 or Theme.Radius))
    if style == "Lego" then
        stroke(card, Color3.fromRGB(5, 9, 17), 3, 0.02)
        local studCount = 12
        for i = 1, studCount do
            local stud = make("Frame", {
                Position = UDim2.new((i - 1) / studCount, 6, 0, 4),
                Size = UDim2.fromOffset(11, 8),
                BackgroundColor3 = bg:Lerp(Color3.new(1, 1, 1), 0.19),
                BorderSizePixel = 0,
                ZIndex = 8,
            }, card)
            corner(stud, 3)
            stroke(stud, bg:Lerp(Color3.new(0, 0, 0), 0.18), 1, 0.2)
        end
        local greenRail = make("Frame", {
            Position = UDim2.new(0, 3, 1, -8),
            Size = UDim2.new(1, -6, 0, 5),
            BackgroundColor3 = Color3.fromRGB(37, 193, 68),
            BorderSizePixel = 0,
            ZIndex = 8,
        }, card)
        corner(greenRail, 1)
        label(card, titleText, 13, Theme.Text, Enum.Font.GothamBlack,
            UDim2.fromOffset(14, 17), UDim2.new(1, -28, 0, 20))
        if subtitle then
            label(card, subtitle, 9, Color3.fromRGB(245, 246, 248), Enum.Font.GothamMedium,
                UDim2.fromOffset(14, 40), UDim2.new(1, -28, 0, 24))
        end
    elseif style == "Galaxy" then
        stroke(card, Theme.Border, 1.2, 0.28)
        gradient(card, Theme.Card, Theme.Surface, 28)
        local glow = make("Frame", {
            Position = UDim2.new(0, 12, 0, 13),
            Size = UDim2.fromOffset(3, math.max(28, (height or 120) - 26)),
            BackgroundColor3 = Theme.Accent2,
            BackgroundTransparency = 0.16,
            BorderSizePixel = 0,
            ZIndex = 7,
        }, card)
        corner(glow, 4)
        label(card, titleText, 12, Theme.Accent2, Enum.Font.GothamBold,
            UDim2.fromOffset(24, 11), UDim2.new(1, -38, 0, 20))
        if subtitle then label(card, subtitle, 9, Theme.Muted, Enum.Font.Gotham,
            UDim2.fromOffset(24, 32), UDim2.new(1, -38, 0, 23)) end
    elseif style == "Eid" then
        stroke(card, Theme.Accent, 1.1, 0.34)
        gradient(card, Theme.Card, Theme.Surface, 90)
        local marker = make("Frame", {
            Position = UDim2.fromOffset(13, 13),
            Size = UDim2.fromOffset(9, 9),
            Rotation = 45,
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 8,
        }, card)
        label(card, titleText, 12, Theme.Accent, Enum.Font.GothamBold,
            UDim2.fromOffset(32, 8), UDim2.new(1, -44, 0, 22))
        if subtitle then label(card, subtitle, 9, Theme.Muted, Enum.Font.Gotham,
            UDim2.fromOffset(32, 32), UDim2.new(1, -44, 0, 24)) end
        local trim = make("Frame", {
            Position = UDim2.new(0, 12, 1, -3),
            Size = UDim2.new(1, -24, 0, 1),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.32,
            BorderSizePixel = 0,
            ZIndex = 8,
        }, card)
    else
        stroke(card, Theme.Border, 1, 0.72)
        local accent = make("Frame", {
            Position = UDim2.new(0, 0, 0, 13),
            Size = UDim2.new(0, 2, 0, math.max(24, (height or 120) - 26)),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 7,
        }, card)
        label(card, titleText, 12, Theme.Text, Enum.Font.GothamSemibold,
            UDim2.fromOffset(17, 10), UDim2.new(1, -30, 0, 20))
        if subtitle then label(card, subtitle, 9, Theme.Muted, Enum.Font.Gotham,
            UDim2.fromOffset(17, 32), UDim2.new(1, -30, 0, 23)) end
    end
    return card
end

local function addAction(parent, titleText, position, size, callback, variant)
    variant = variant or "primary"
    local style = Theme.Style
    local host = make("Frame", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        ZIndex = 10,
    }, parent)
    if style == "Lego" then
        local shadow = make("Frame", {
            Position = UDim2.fromOffset(0, 5),
            Size = UDim2.new(1, 0, 1, -1),
            BackgroundColor3 = Color3.fromRGB(9, 15, 26),
            BorderSizePixel = 0,
            ZIndex = 10,
        }, host)
        corner(shadow, 3)
    end
    local faceColor = variant == "danger" and Theme.Danger or (variant == "secondary" and Theme.Element or Theme.Raised)
    local face = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = faceColor,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, host)
    corner(face, style == "Lego" and 3 or (style == "Galaxy" and 99 or (style == "Modern" and 8 or 12)))
    stroke(face, style == "Lego" and Color3.fromRGB(13, 18, 29) or Theme.Border,
        style == "Lego" and 2 or 1, style == "Modern" and 0.70 or 0.24)
    if style == "Lego" then
        for i = 1, math.max(1, math.floor((size.X.Offset or 100) / 70)) do
            local stud = make("Frame", {
                Position = UDim2.new((i - 1) / math.max(1, math.floor((size.X.Offset or 100) / 70)), 9, 0, 4),
                Size = UDim2.fromOffset(12, 7),
                BackgroundColor3 = faceColor:Lerp(Color3.new(1, 1, 1), 0.25),
                BorderSizePixel = 0,
                ZIndex = 12,
            }, face)
            corner(stud, 3)
        end
    elseif style == "Galaxy" then
        gradient(face, Theme.Raised, Theme.Surface, 0)
        local node = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, -15, 0.5, 0),
            Size = UDim2.fromOffset(7, 7),
            BackgroundColor3 = Theme.Accent2,
            BorderSizePixel = 0,
            ZIndex = 12,
        }, face)
        corner(node, 99)
    elseif style == "Modern" then
        make("Frame", {
            Position = UDim2.fromOffset(0, 8),
            Size = UDim2.new(0, 3, 1, -16),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 12,
        }, face)
    else
        label(face, "◆", 8, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(1, -27, 0, 0), UDim2.fromOffset(18, size.Y.Offset or 34), Enum.TextXAlignment.Center)
    end
    local left = style == "Lego" and 12 or (style == "Modern" and 17 or 14)
    label(face, titleText, style == "Lego" and 10 or 10, Theme.Text,
        style == "Lego" and Enum.Font.GothamBlack or Enum.Font.GothamSemibold,
        UDim2.fromOffset(left, 0), UDim2.new(1, -left - 30, 1, 0))

    face.Activated:Connect(function()
        if style == "Lego" then
            playTween(face, 0.07, { Position = UDim2.fromOffset(0, 4) }, Enum.EasingStyle.Quad)
            task.delay(0.09, function()
                if face.Parent then playTween(face, 0.13, { Position = UDim2.new() }, Enum.EasingStyle.Back) end
            end)
        elseif style == "Galaxy" then
            playTween(face, 0.10, { BackgroundColor3 = Theme.Accent }, Enum.EasingStyle.Quad)
            task.delay(0.14, function() if face.Parent then playTween(face, 0.18, { BackgroundColor3 = faceColor }) end end)
        else
            playTween(face, 0.08, { BackgroundColor3 = Theme.Accent }, Enum.EasingStyle.Quad)
            task.delay(0.12, function() if face.Parent then playTween(face, 0.18, { BackgroundColor3 = faceColor }) end end)
        end
        if callback then callback() end
    end)
    return host
end

local function addToggle(parent, titleText, desc, key, y)
    local rowHeight = State.CompactCards and 48 or 56
    local row = make("Frame", {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, rowHeight),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, parent)
    corner(row, Theme.Style == "Lego" and 3 or (Theme.Style == "Galaxy" and 13 or 9))
    if Theme.Style == "Lego" then stroke(row, Color3.fromRGB(6, 11, 20), 2, 0.08) end
    label(row, titleText, 10, Theme.Text, Enum.Font.GothamSemibold,
        UDim2.fromOffset(10, 5), UDim2.new(1, -80, 0, 16))
    if desc then label(row, desc, 8, Theme.Muted, Enum.Font.Gotham,
        UDim2.fromOffset(10, 23), UDim2.new(1, -82, 0, 14)) end

    local track = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(44, 23),
        BackgroundColor3 = State[key] and Theme.Accent or Theme.Off,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, row)
    corner(track, Theme.Style == "Lego" and 3 or 99)
    if Theme.Style == "Galaxy" then stroke(track, Theme.Accent2, 1, 0.34) end
    local knobSize = Theme.Style == "Lego" and 15 or 15
    local knob = make("Frame", {
        Position = State[key] and UDim2.new(1, -knobSize - 3, 0.5, -knobSize / 2) or UDim2.new(0, 3, 0.5, -knobSize / 2),
        Size = UDim2.fromOffset(knobSize, knobSize),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, track)
    corner(knob, Theme.Style == "Lego" and 3 or 99)
    local hit = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 13 }, track)
    hit.Activated:Connect(function()
        State[key] = not State[key]
        playTween(track, 0.16, { BackgroundColor3 = State[key] and Theme.Accent or Theme.Off })
        playTween(knob, 0.18, {
            Position = State[key] and UDim2.new(1, -knobSize - 3, 0.5, -knobSize / 2) or UDim2.new(0, 3, 0.5, -knobSize / 2),
        }, Enum.EasingStyle.Back)
        notify(titleText .. (State[key] and " enabled" or " disabled"))
        if key == "CompactCards" then task.defer(function() if not State.Destroyed then renderUI() end end) end
    end)
    return row
end

local function addSlider(parent, titleText, desc, key, minimum, maximum, y)
    local row = make("Frame", {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 69),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, parent)
    corner(row, Theme.Style == "Lego" and 3 or 9)
    label(row, titleText, 10, Theme.Text, Enum.Font.GothamSemibold,
        UDim2.fromOffset(10, 5), UDim2.new(0.69, 0, 0, 16))
    local valueText = label(row, string.format("%.2f", State[key]), 9, Theme.Accent,
        Enum.Font.GothamBold, UDim2.new(0.70, 0, 0, 5), UDim2.new(0.27, -8, 0, 16), Enum.TextXAlignment.Right)
    label(row, desc or "", 8, Theme.Muted, Enum.Font.Gotham,
        UDim2.fromOffset(10, 22), UDim2.new(1, -20, 0, 12))
    local bar = make("Frame", {
        Position = UDim2.new(0, 10, 0, 47),
        Size = UDim2.new(1, -20, 0, Theme.Style == "Lego" and 9 or 5),
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, row)
    corner(bar, Theme.Style == "Lego" and 2 or 99)
    local pct = math.clamp((State[key] - minimum) / (maximum - minimum), 0, 1)
    local fill = make("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, bar)
    corner(fill, Theme.Style == "Lego" and 2 or 99)
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local value = minimum + (maximum - minimum) * rel
        State[key] = value
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valueText.Text = string.format("%.2f", value)
    end
    local hit = make("TextButton", {
        Position = UDim2.new(0, 0, 0, -10),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 12,
    }, bar)
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            ActiveSlider = update
            update(input.Position.X)
        end
    end)
    return row
end

local function clearContent()
    if not Content then return end
    for _, child in ipairs(Content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
    Content.CanvasPosition = Vector2.zero
end

local function setupContentList()
    make("UIListLayout", {
        Padding = UDim.new(0, Theme.Style == "Lego" and 9 or (State.CompactCards and 7 or 11)),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Content)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 13),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3),
    }, Content)
end

local function addStatCard(parent, heading, initial, order)
    local card = make("Frame", {
        Size = UDim2.new(1 / 3, -7, 1, 0),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 8,
    }, parent)
    corner(card, Theme.Style == "Lego" and 3 or 10)
    stroke(card, Theme.Border, Theme.Style == "Lego" and 2 or 1, 0.64)
    label(card, heading, 8, Theme.Muted, Enum.Font.GothamBold,
        UDim2.fromOffset(8, 7), UDim2.new(1, -14, 0, 14))
    local value = label(card, initial, 17, Theme.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(8, 25), UDim2.new(1, -14, 0, 24))
    return value
end

local function pageOverview()
    clearContent(); setupContentList()
    local titleText = Theme.Style == "Lego" and "BRICKWORK CONTROL DECK" or (Theme.Style == "Eid" and "SELAMAT DATANG" or (Theme.Style == "Galaxy" and "ORBITAL COMMAND" or "Workspace"))
    local subText = Theme.Style == "Eid" and "Semoga hari penuh kedamaian dan kebersamaan." or "A local interface with four independent visual systems."
    addSectionHeading(Content, titleText, subText)

    local hero = makeCard(Content, Theme.Style == "Lego" and "BAXTARA BUILD BAY" or "BAXTARA X / INTERFACE",
        Theme.Style == "Galaxy" and "Explore a quiet corner of the universe." or "Choose a design language and tune the atmosphere.", 150, 2)
    if Theme.Style == "Galaxy" then
        label(hero, "A universe of controls, arranged around your workspace.", 12, Theme.Text,
            Enum.Font.GothamSemibold, UDim2.fromOffset(24, 66), UDim2.new(0.60, -28, 0, 39))
        local planet, ring = addPlanet(hero, 48, Theme.Accent, Theme.Accent2, 9)
        planet.AnchorPoint = Vector2.new(0.5, 0.5)
        planet.Position = UDim2.new(1, -92, 0.60, 0)
        table.insert(OrbitNodes, { Host = planet, Ring = ring, Sphere = planet:FindFirstChildWhichIsA("Frame"), Phase = 1, RX = 0, RY = 0, Speed = 0.18, Local = true })
    elseif Theme.Style == "Lego" then
        label(hero, "BUILD • SNAP • EXPLORE", 16, Theme.Text, Enum.Font.GothamBlack,
            UDim2.fromOffset(14, 64), UDim2.new(1, -28, 0, 26))
        label(hero, "Brick by brick. Every control has its own shape and depth.", 9, Theme.Text,
            Enum.Font.GothamMedium, UDim2.fromOffset(14, 94), UDim2.new(1, -28, 0, 22))
        for i, col in ipairs({Color3.fromRGB(220, 51, 46), Color3.fromRGB(255, 195, 39), Color3.fromRGB(35, 124, 224), Color3.fromRGB(44, 156, 77)}) do
            local brick = make("Frame", {
                Position = UDim2.new(1, -164 + (i - 1) * 34, 0, 75 - (i % 2) * 14),
                Size = UDim2.fromOffset(40, 28),
                BackgroundColor3 = col,
                BorderSizePixel = 0,
                ZIndex = 9,
            }, hero)
            corner(brick, 3); stroke(brick, Color3.fromRGB(8, 13, 21), 1.4, 0.08)
            for s = 1, 2 do
                local stud = make("Frame", {
                    Position = UDim2.fromOffset(6 + (s - 1) * 19, -5),
                    Size = UDim2.fromOffset(13, 8),
                    BackgroundColor3 = col:Lerp(Color3.new(1, 1, 1), 0.24),
                    BorderSizePixel = 0,
                    ZIndex = 10,
                }, brick)
                corner(stud, 4)
            end
        end
    elseif Theme.Style == "Eid" then
        label(hero, "Selamat Hari Raya Idul Fitri", 16, Theme.Text, Enum.Font.GothamBold,
            UDim2.fromOffset(15, 65), UDim2.new(0.72, -15, 0, 28))
        label(hero, "Mohon maaf lahir dan batin", 11, Theme.Accent, Enum.Font.GothamSemibold,
            UDim2.fromOffset(15, 96), UDim2.new(0.72, -15, 0, 20))
        label(hero, "☾", 43, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(1, -116, 0, 57), UDim2.fromOffset(50, 58), Enum.TextXAlignment.Center)
        addKetupat(hero, UDim2.new(1, -70, 0, 65), 34, KetupatNodes, 9)
    else
        label(hero, "A calmer, clearer control surface.", 14, Theme.Text, Enum.Font.GothamSemibold,
            UDim2.fromOffset(17, 64), UDim2.new(0.65, -20, 0, 30))
        label(hero, "Measured spacing. Focused typography. Quiet interaction feedback.", 9, Theme.Muted,
            Enum.Font.Gotham, UDim2.fromOffset(17, 94), UDim2.new(0.66, -20, 0, 24))
        local mark = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, -82, 0.58, 0),
            Size = UDim2.fromOffset(78, 78),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 9,
        }, hero)
        corner(mark, 22); stroke(mark, Theme.Border, 1.3, 0.35)
        label(mark, "BX", 24, Theme.Accent, Enum.Font.GothamBlack,
            UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
    end

    local stats = make("Frame", {
        Size = UDim2.new(1, -8, 0, 69),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        ZIndex = 7,
    }, Content)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, stats)
    FpsLabel = addStatCard(stats, "CLIENT FPS", tostring(FPS), 1)
    PlayerLabel = addStatCard(stats, "PLAYERS", tostring(#Players:GetPlayers()), 2)
    SessionLabel = addStatCard(stats, "SESSION", "00:00", 3)

    local quick = makeCard(Content, "QUICK ACCESS", "Open the theme selector or tune the motion system.", 112, 4)
    addAction(quick, "CHANGE THEME", UDim2.fromOffset(12, 62), UDim2.new(0.48, -12, 0, 34), function()
        State.Page = "APPEARANCE"; renderUI()
    end, "primary")
    addAction(quick, "VISUAL LAB", UDim2.new(0.52, 0, 0, 62), UDim2.new(0.48, -12, 0, 34), function()
        State.Page = "VISUAL LAB"; renderUI()
    end, "secondary")
end

local function pageProfile()
    clearContent(); setupContentList()
    addSectionHeading(Content, "PLAYER PROFILE", "Read-only identity information from this local client.")
    local card = makeCard(Content, "CURRENT PLAYER", "Roblox account snapshot", 155, 2)
    local avatar = make("ImageLabel", {
        Position = UDim2.fromOffset(16, 61),
        Size = UDim2.fromOffset(68, 68),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Image = "",
        ZIndex = 10,
    }, card)
    corner(avatar, Theme.Style == "Lego" and 6 or 18); stroke(avatar, Theme.Accent, 1.4, 0.2)
    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and avatar.Parent then avatar.Image = image end
    end)
    local textColor = Theme.Style == "Lego" and Color3.new(1, 1, 1) or Theme.Text
    label(card, LocalPlayer.DisplayName, 13, textColor, Enum.Font.GothamBold,
        UDim2.fromOffset(99, 68), UDim2.new(1, -112, 0, 22))
    label(card, "@" .. LocalPlayer.Name, 9, textColor, Enum.Font.Code,
        UDim2.fromOffset(99, 93), UDim2.new(1, -112, 0, 17))
    label(card, "USER ID  " .. tostring(LocalPlayer.UserId), 8, Theme.Accent, Enum.Font.GothamBold,
        UDim2.fromOffset(99, 115), UDim2.new(1, -112, 0, 16))
    local session = makeCard(Content, "SESSION DETAILS", "Information reported by the current client.", 104, 3)
    label(session, "Account age: " .. tostring(LocalPlayer.AccountAge) .. " days", 10, Theme.Text, Enum.Font.Gotham,
        UDim2.fromOffset(15, 61), UDim2.new(1, -30, 0, 17))
    label(session, "Players in server: " .. tostring(#Players:GetPlayers()), 10, Theme.Text, Enum.Font.Gotham,
        UDim2.fromOffset(15, 81), UDim2.new(1, -30, 0, 17))
end

local function themeCard(parent, themeName, titleText, details, position)
    local palette = Themes[themeName]
    local tile = make("TextButton", {
        Position = position,
        Size = UDim2.new(0.49, -6, 0, 91),
        BackgroundColor3 = palette.Card,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, parent)
    corner(tile, themeName == "Lego" and 3 or (themeName == "Galaxy" and 16 or palette.Radius))
    stroke(tile, palette.Border, themeName == "Lego" and 2 or 1, State.Theme == themeName and 0.08 or 0.6)
    if themeName == "Lego" then
        for i = 1, 3 do
            local stud = make("Frame", {
                Position = UDim2.fromOffset(10 + (i - 1) * 14, 4),
                Size = UDim2.fromOffset(9, 7),
                BackgroundColor3 = palette.Accent,
                BorderSizePixel = 0,
                ZIndex = 11,
            }, tile)
            corner(stud, 3)
        end
    elseif themeName == "Galaxy" then
        local planet = make("Frame", {
            Position = UDim2.fromOffset(12, 24),
            Size = UDim2.fromOffset(35, 35),
            BackgroundColor3 = palette.Accent,
            BorderSizePixel = 0,
            ZIndex = 11,
        }, tile)
        corner(planet, 99); gradient(planet, palette.Accent2, palette.Accent, 25)
        local ring = make("Frame", {
            Position = UDim2.fromOffset(7, 34),
            Size = UDim2.fromOffset(46, 14),
            BackgroundTransparency = 1,
            Rotation = -20,
            ZIndex = 12,
        }, tile)
        corner(ring, 99); stroke(ring, palette.Accent2, 1.2, 0.12)
    elseif themeName == "Eid" then
        label(tile, "☾", 33, palette.Accent, Enum.Font.GothamBold,
            UDim2.fromOffset(9, 17), UDim2.fromOffset(43, 48), Enum.TextXAlignment.Center)
    else
        label(tile, "B", 29, palette.Accent, Enum.Font.GothamBlack,
            UDim2.fromOffset(12, 21), UDim2.fromOffset(38, 42), Enum.TextXAlignment.Center)
    end
    local textX = 59
    label(tile, titleText, 10, palette.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(textX, 18), UDim2.new(1, -textX - 7, 0, 18))
    label(tile, details, 8, palette.Muted, Enum.Font.Gotham,
        UDim2.fromOffset(textX, 39), UDim2.new(1, -textX - 7, 0, 30))
    if State.Theme == themeName then
        label(tile, "ACTIVE", 7, palette.Accent, Enum.Font.GothamBlack,
            UDim2.fromOffset(textX, 72), UDim2.new(1, -textX - 7, 0, 12))
    end
    tile.Activated:Connect(function()
        State.Theme = themeName
        Theme = Themes[themeName]
        renderUI()
        notify(Themes[themeName].Name .. " APPLIED", Themes[themeName].Accent)
    end)
end

local function pageAppearance()
    clearContent(); setupContentList()
    addSectionHeading(Content, "VISUAL WORLDS", "Four separate design systems. Each changes its layout, controls and opening sequence.")
    local card = makeCard(Content, "CHOOSE A WORLD", "Theme changes rebuild the full interface.", 258, 2)
    themeCard(card, "Galaxy", "GALAXY", "Nebula, planet rail, orbital borders", UDim2.fromOffset(12, 58))
    themeCard(card, "Lego", "LEGO", "Brick menu, studded controls, build plate", UDim2.new(0.51, 0, 0, 58))
    themeCard(card, "Modern", "MODERN", "Editorial grid, thin rail, quiet surfaces", UDim2.fromOffset(12, 154))
    themeCard(card, "Eid", "IDUL FITRI", "Emerald, gold, crescent, woven ketupat", UDim2.new(0.51, 0, 0, 154))
    local notes = makeCard(Content, "CURRENT DESIGN LANGUAGE", "The active theme's component rules.", 104, 3)
    local descriptions = {
        Galaxy = "Planets become navigation points. Rings orbit the panel while the backdrop uses deep-space layers.",
        Lego = "Navigation is assembled from colored bricks. Buttons compress into their shadow; cards use studs and green rails.",
        Modern = "A slim icon rail, typography-led content, asymmetric spacing and a scanner-style open transition.",
        Eid = "Gold-trimmed emerald surfaces, hanging ketupat ornaments and a Hari Raya greeting on every opening.",
    }
    label(notes, descriptions[State.Theme], 9, Theme.Text, Enum.Font.Gotham,
        UDim2.fromOffset(15, 59), UDim2.new(1, -30, 0, 31))
end

local function pageVisualLab()
    clearContent(); setupContentList()
    addSectionHeading(Content, "LOCAL VISUAL LAB", "All switches here control decorative UI motion only.")
    local atmosphere = makeCard(Content, "ATMOSPHERE", "Turn individual effects on or off.", 292, 2)
    addToggle(atmosphere, "Ambient animation", "Enable the theme's decorative motion.", "Ambient", 58)
    addToggle(atmosphere, "Star particles", "Twinkle the star field in Galaxy mode.", "StarParticles", 115)
    addToggle(atmosphere, "Orbit motion", "Move planets around the orbital paths.", "OrbitMotion", 172)
    addToggle(atmosphere, "Ketupat sway", "Animate hanging ornaments in Idul Fitri mode.", "KetupatMotion", 229)
    local motion = makeCard(Content, "MOTION TUNING", "Adjust animation intensity and speed.", 187, 3)
    addSlider(motion, "Glow intensity", "Strength of ambient highlights", "Glow", 0, 1, 58)
    addSlider(motion, "Animation speed", "Decorative motion multiplier", "AnimationSpeed", 0.25, 2, 112)
end

local function pagePreferences()
    clearContent(); setupContentList()
    addSectionHeading(Content, "PREFERENCES", "Comfort and panel behavior.")
    local card = makeCard(Content, "DISPLAY OPTIONS", "Changes apply immediately.", 179, 2)
    addToggle(card, "Reduce motion", "Disable continuous animations and transitions.", "ReduceMotion", 58)
    addToggle(card, "Compact cards", "Use tighter vertical spacing.", "CompactCards", 116)
    local actions = makeCard(Content, "PANEL MAINTENANCE", "Manage the local UI instance.", 151, 3)
    addAction(actions, "RESET VISUAL SETTINGS", UDim2.fromOffset(12, 59), UDim2.new(1, -24, 0, 33), function()
        State.Ambient = true
        State.StarParticles = true
        State.OrbitMotion = true
        State.KetupatMotion = true
        State.ReduceMotion = false
        State.CompactCards = false
        State.Glow = 0.72
        State.AnimationSpeed = 1
        renderUI()
        notify("Visual settings reset")
    end, "secondary")
    addAction(actions, "UNLOAD INTERFACE", UDim2.fromOffset(12, 102), UDim2.new(1, -24, 0, 33), function()
        State.Destroyed = true
        for _, connection in ipairs(Connections) do pcall(function() connection:Disconnect() end) end
        ScreenGui:Destroy()
    end, "danger")
end

local function pageAbout()
    clearContent(); setupContentList()
    addSectionHeading(Content, "ABOUT BAXTARA", "A UI project focused on distinct visual identity.")
    local card = makeCard(Content, "BAXTARA X / UI EDITION 7.1", "Four themes • Responsive layout • Local controls", 145, 2)
    label(card, "Galaxy, LEGO, Modern and Idul Fitri each have their own panel composition, logo treatment, navigation geometry and opening animation.",
        9, Theme.Text, Enum.Font.Gotham, UDim2.fromOffset(15, 59), UDim2.new(1, -30, 0, 54))
    local scope = makeCard(Content, "EXECUTION SCOPE", "Local interface only.", 126, 3)
    label(scope, "No gameplay automation • No player manipulation • No remote calls • No anti-cheat bypass • No ban or kick evasion",
        9, Theme.Accent2, Enum.Font.GothamBold, UDim2.fromOffset(15, 60), UDim2.new(1, -30, 0, 43))
end



-- ========== FEATURE PAGES ==========
local function pageAim()
    addSectionHeading(Content, "AIMBOT", "Lock, FOV, silent and NPC targeting.")
    local y = 72
    addToggle(Content, "Enable Aimbot", "Master aimbot switch", "AimEnabled", y); y = y + 58
    addToggle(Content, "Silent Aim", "Hard camera snap", "SilentAim", y); y = y + 58
    addToggle(Content, "Anti Miss", "Stronger tracking", "AntiMiss", y); y = y + 58
    addToggle(Content, "Aim Lock", "Keep current target", "AimLock", y); y = y + 58
    addToggle(Content, "Visibility Check", "Only visible targets", "VisCheck", y); y = y + 58
    addToggle(Content, "Head Aim", "Aim at head", "HeadAim", y); y = y + 58
    addToggle(Content, "Body Aim", "Aim at body", "BodyAim", y); y = y + 58
    addToggle(Content, "FOV Circle", "Draw FOV circle", "FOVCircle", y); y = y + 58
    addToggle(Content, "Team Check", "Skip teammates", "TeamCheck", y); y = y + 58
    addToggle(Content, "Aim NPC / Bot", "Target non-players", "AimNPC", y); y = y + 58
    addSlider(Content, "FOV Size", "Aim field radius", "FOV", 40, 1000, y); y = y + 78
    addSlider(Content, "Smoothness", "Lower = snappier", "Smooth", 5, 40, y)
end

local function pageESP()
    addSectionHeading(Content, "ESP", "Boxes, tracers, skeleton, NPC, custom color.")
    local y = 72
    addToggle(Content, "Enable ESP", "Master ESP switch", "ESPEnabled", y); y = y + 58
    addToggle(Content, "Box", "Player boxes", "ESPBox", y); y = y + 58
    addToggle(Content, "Name", "Display names", "ESPName", y); y = y + 58
    addToggle(Content, "Health Bar", "HP bar", "ESPHealth", y); y = y + 58
    addToggle(Content, "Distance", "Range text", "ESPDist", y); y = y + 58
    addToggle(Content, "Tracer", "Line to players", "ESPTracer", y); y = y + 58
    addToggle(Content, "Skeleton", "Bone lines", "ESPSkeleton", y); y = y + 58
    addToggle(Content, "NPC / Bot ESP", "Non-player models", "ESPNPC", y); y = y + 58
    addSlider(Content, "ESP Color Hue", "0–1 full spectrum", "ESPHue", 0, 1, y); y = y + 78
    addSlider(Content, "ESP Saturation", "Color intensity", "ESPSat", 0, 1, y); y = y + 78
    addSlider(Content, "ESP Brightness", "Value / brightness", "ESPVal", 0.2, 1, y); y = y + 78
    addAction(Content, "Tracer origin: BOTTOM", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        State.TracerOrigin = "Bottom"; notify("Tracer → Bottom")
    end); y = y + 42
    addAction(Content, "Tracer origin: CENTER", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        State.TracerOrigin = "Center"; notify("Tracer → Center")
    end); y = y + 42
    addAction(Content, "Tracer origin: TOP", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        State.TracerOrigin = "Top"; notify("Tracer → Top")
    end); y = y + 42
    addAction(Content, "Tracer origin: EDGE", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        State.TracerOrigin = (State.TracerOrigin == "Left") and "Right" or "Left"
        notify("Tracer → " .. State.TracerOrigin)
    end)
end

local function pageBrutal()
    addSectionHeading(Content, "BRUTAL", "Movement, hitbox, combat helpers.")
    local y = 72
    addToggle(Content, "Fly", "BodyVelocity flight", "Fly", y); y = y + 58
    addSlider(Content, "Fly Speed", "Flight velocity", "FlySpeed", 10, 100, y); y = y + 78
    addToggle(Content, "Speed Hack", "WalkSpeed boost", "SpeedHack", y); y = y + 58
    addSlider(Content, "Walk Speed", "16–100", "SpeedValue", 16, 100, y); y = y + 78
    addToggle(Content, "Infinite Jump", "Jump spam", "InfJump", y); y = y + 58
    addToggle(Content, "Noclip", "No collision", "Noclip", y); y = y + 58
    addToggle(Content, "God Mode", "Local HP refill", "GodMode", y); y = y + 58
    addToggle(Content, "Ghost Mode", "Local invisible", "GhostMode", y); y = y + 58
    addToggle(Content, "Hitbox Expand", "Enlarge target parts", "Hitbox", y); y = y + 58
    addToggle(Content, "Hitbox = HEAD (off Body)", "Head vs body expand", "HitboxHead", y); y = y + 58
    addSlider(Content, "Hitbox Size", "2–27 studs", "HitboxSize", 2, 27, y); y = y + 78
    addToggle(Content, "Spin Bot", "Rotate character", "SpinBot", y); y = y + 58
    addSlider(Content, "Spin Speed", "1–120", "SpinSpeed", 1, 120, y); y = y + 78
    addToggle(Content, "Fly Kill All", "Hover + pull + fire", "FlyKillAll", y); y = y + 58
    addToggle(Content, "Anti Cooldown", "Weapon patch", "AntiCD", y); y = y + 58
    addToggle(Content, "Infinite Ammo", "Ammo patch", "InfAmmo", y)
end

local function pageLocal()
    addSectionHeading(Content, "LOCAL CONFIG", "Sky, tags, teleport, utility.")
    local y = 72
    addToggle(Content, "Hacker Sky", "Bright sky + BAXTARA logos", "SkyHack", y); y = y + 58
    addToggle(Content, "Self Name Tag", "Tag above your head", "SelfTag", y); y = y + 58
    addToggle(Content, "Tag Rainbow", "Rainbow tag color", "SelfTagRainbow", y); y = y + 58
    addToggle(Content, "Chat Bubble", "Local bubble text", "ChatBubble", y); y = y + 58
    addToggle(Content, "Freeze Others", "Anchor other HRPs", "FreezeOthers", y); y = y + 58
    addToggle(Content, "Anti Lag Self", "Low graphics", "AntiLag", y); y = y + 58
    addAction(Content, "OPEN TP PLAYER LIST", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        if Features and Features.OpenTPList then Features.OpenTPList() end
    end); y = y + 42
    addAction(Content, "TP all players in front", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        if Features and Features.TPAllFront then Features.TPAllFront() end
        notify("TP all front")
    end); y = y + 42
    addAction(Content, "HIDE / SHOW PANEL", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        if Main then
            Main.Visible = not Main.Visible
            State.PanelHidden = not Main.Visible
            if Launcher then Launcher.Visible = true end
            notify(Main.Visible and "Panel shown" or "Panel hidden — BX to reopen")
        end
    end)
end

local function pageModern()
    addSectionHeading(Content, "MODERN MODE", "Different ESP geometry + premium aim feel.")
    local y = 72
    addToggle(Content, "Modern ESP Style", "Corner brackets + dashed tracers", "ModernESP", y); y = y + 58
    addToggle(Content, "Modern Aim", "Predictive soft lock + FOV pulse", "ModernAim", y); y = y + 58
    addAction(Content, "Style note: corners not full box", UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 34), function()
        notify("Modern ESP uses corner brackets + angled tracers")
    end)
end


local PageRenderers = {
    OVERVIEW = pageOverview,
    AIM = pageAim,
    ESP = pageESP,
    MODERN = pageModern,
    BRUTAL = pageBrutal,
    LOCAL = pageLocal,
    APPEARANCE = pageAppearance,
    ABOUT = pageAbout,
}

local function navButton(parent, item, index, mobile, horizontal)
    local page = item.Name
    local active = State.Page == page
    local style = Theme.Style
    local width, height
    if horizontal then
        width = UDim2.new(0, style == "Lego" and 112 or 108, 0, 38)
        height = UDim2.fromOffset(style == "Lego" and 112 or 108, 38)
    elseif style == "Galaxy" then
        width = UDim2.new(1, -12, 0, 61); height = UDim2.fromOffset(76, 61)
    elseif style == "Eid" then
        width = UDim2.new(1, -12, 0, 48); height = UDim2.fromOffset(86, 48)
    else
        width = UDim2.new(1, -10, 0, 49); height = UDim2.fromOffset(54, 49)
    end
    local button = make("TextButton", {
        Size = width,
        BackgroundColor3 = active and Theme.Raised or Theme.Surface,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = index,
        ZIndex = 9,
    }, parent)
    if style == "Galaxy" then
        corner(button, 99)
        stroke(button, active and Theme.Accent2 or Theme.Border, active and 1.6 or 1, active and 0.1 or 0.74)
        local center = mobile and horizontal
        local planet = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = center and UDim2.new(0, 17, 0.5, 0) or UDim2.new(0.5, 0, 0.37, 0),
            Size = UDim2.fromOffset(active and 24 or 20, active and 24 or 20),
            BackgroundColor3 = active and Theme.Accent or Theme.Element,
            BorderSizePixel = 0,
            ZIndex = 10,
        }, button)
        corner(planet, 99); gradient(planet, Theme.Accent2, Theme.Accent, 35)
        if center then
            label(button, page, 8, active and Theme.Text or Theme.Muted, Enum.Font.GothamBold,
                UDim2.fromOffset(34, 0), UDim2.new(1, -38, 1, 0))
        else
            label(button, item.Icon, 10, Theme.Text, Enum.Font.GothamBold,
                UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.76), Enum.TextXAlignment.Center)
            label(button, page, 7, active and Theme.Text or Theme.Muted, Enum.Font.GothamBold,
                UDim2.new(0, 1, 1, -18), UDim2.new(1, -2, 0, 12), Enum.TextXAlignment.Center)
        end
    elseif style == "Lego" then
        corner(button, 3)
        stroke(button, Color3.fromRGB(6, 11, 20), 2.2, 0.02)
        local blockColors = {
            Color3.fromRGB(208, 48, 43), Color3.fromRGB(34, 108, 211),
            Color3.fromRGB(224, 164, 28), Color3.fromRGB(38, 146, 69),
        }
        button.BackgroundColor3 = active and Theme.Accent or blockColors[(index - 1) % #blockColors + 1]
        for i = 1, 3 do
            local stud = make("Frame", {
                Position = UDim2.fromOffset(7 + (i - 1) * 18, 3),
                Size = UDim2.fromOffset(12, 7),
                BackgroundColor3 = active and Color3.fromRGB(255, 226, 112) or Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = active and 0.06 or 0.35,
                BorderSizePixel = 0,
                ZIndex = 11,
            }, button)
            corner(stud, 3)
        end
        label(button, page, 8, Theme.Text, Enum.Font.GothamBlack,
            UDim2.new(0, 6, 0, 13), UDim2.new(1, -12, 1, -13), Enum.TextXAlignment.Center)
    elseif style == "Eid" then
        corner(button, 13)
        stroke(button, active and Theme.Accent or Theme.Border, active and 1.6 or 1, active and 0.08 or 0.58)
        label(button, "◆", 9, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(0, 7, 0, 0), UDim2.fromOffset(20, 48), Enum.TextXAlignment.Center)
        label(button, page, 8, active and Theme.Text or Theme.Muted, Enum.Font.GothamBold,
            UDim2.fromOffset(29, 0), UDim2.new(1, -33, 1, 0))
    else
        corner(button, 8)
        stroke(button, active and Theme.Border or Theme.Surface, 1, active and 0.38 or 1)
        if active then
            make("Frame", {
                Position = UDim2.fromOffset(0, 8),
                Size = UDim2.new(0, 3, 1, -16),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 11,
            }, button)
        end
        if horizontal then
            label(button, item.Icon, 14, active and Theme.Accent or Theme.Muted, Enum.Font.GothamBold,
                UDim2.fromOffset(8, 0), UDim2.fromOffset(24, 38), Enum.TextXAlignment.Center)
            label(button, page, 8, active and Theme.Text or Theme.Muted, Enum.Font.GothamSemibold,
                UDim2.fromOffset(34, 0), UDim2.new(1, -38, 1, 0))
        else
            -- Desktop Modern uses an icon-only rail; labels live in the page heading.
            label(button, item.Icon, 17, active and Theme.Accent or Theme.Muted, Enum.Font.GothamBold,
                UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
        end
    end

    button.Activated:Connect(function()
        State.Page = page
        renderUI()
    end)
    return button
end

local function bindDrag(header)
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragInput = input.Position
            DragStart = Main.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
end

local function makeLauncher()
    local style = Theme.Style
    local launcherSize = style == "Lego" and UDim2.fromOffset(76, 62)
        or (style == "Modern" and UDim2.fromOffset(70, 56) or UDim2.fromOffset(64, 64))
    local host = make("TextButton", {
        Name = "BAXTARA_LAUNCHER",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -22, 0.64, 0),
        Size = launcherSize,
        BackgroundColor3 = style == "Lego" and Color3.fromRGB(35, 119, 218)
            or (style == "Eid" and Theme.Surface or Theme.Surface),
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Visible = not State.PanelVisible,
        ZIndex = 80,
    }, ScreenGui)
    if style == "Galaxy" then
        corner(host, 99)
        stroke(host, Theme.Accent2, 1.8, 0.05)
        makeLogo(host, style, UDim2.fromOffset(11, 11), 42)
    elseif style == "Lego" then
        corner(host, 4)
        stroke(host, Color3.fromRGB(7, 13, 23), 3, 0.02)
        for i = 1, 3 do
            local stud = make("Frame", {
                Position = UDim2.fromOffset(9 + (i - 1) * 20, 3),
                Size = UDim2.fromOffset(14, 8),
                BackgroundColor3 = Color3.fromRGB(99, 171, 244),
                BorderSizePixel = 0,
                ZIndex = 82,
            }, host)
            corner(stud, 3)
            stroke(stud, Color3.fromRGB(18, 79, 152), 1, 0.2)
        end
        makeLogo(host, style, UDim2.fromOffset(17, 15), 42)
    elseif style == "Eid" then
        host.BackgroundTransparency = 1
        local diamond = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(48, 48),
            Rotation = 45,
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 81,
        }, host)
        corner(diamond, 7)
        stroke(diamond, Theme.Accent, 1.8, 0.08)
        makeLogo(host, style, UDim2.fromOffset(11, 11), 42)
    else
        corner(host, 16)
        stroke(host, Theme.Border, 1.2, 0.38)
        makeLogo(host, style, UDim2.fromOffset(13, 7), 42)
    end
    host.Activated:Connect(function() openPanel() end)
    return host
end

local function makePanel()
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1000, 700)
    local mobile = viewport.X < 680
    local panelSize = mobile and UDim2.new(0.96, 0, 0.91, 0) or UDim2.new(0.86, 0, 0.84, 0)
    Main = make("Frame", {
        Name = "BAXTARA_MAIN_PANEL",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = panelSize,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = State.PanelVisible,
        ZIndex = 20,
    }, ScreenGui)
    make("UISizeConstraint", { MinSize = Vector2.new(320, 390), MaxSize = Vector2.new(1100, 820) }, Main)
    if Theme.Style == "Lego" then
        corner(Main, 5); stroke(Main, Color3.fromRGB(5, 9, 16), 4, 0.02)
    elseif Theme.Style == "Galaxy" then
        corner(Main, 22); stroke(Main, Theme.Accent2, 1.5, 0.12); gradient(Main, Theme.Background, Theme.Surface, 28)
    elseif Theme.Style == "Eid" then
        corner(Main, 20); stroke(Main, Theme.Accent, 1.6, 0.14); gradient(Main, Theme.Background, Theme.Surface, 90)
    else
        corner(Main, 14); stroke(Main, Theme.Border, 1, 0.6); gradient(Main, Theme.Background, Theme.Surface, 90)
    end
    buildPanelDecor(Main)

    local headerHeight = Theme.Style == "Lego" and 66 or 62
    local header = make("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, headerHeight),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 22,
    }, Main)
    if Theme.Style == "Lego" then
        header.BackgroundColor3 = Color3.fromRGB(207, 45, 42)
        corner(header, 4)
        for i = 1, 18 do
            local stud = make("Frame", {
                Position = UDim2.new((i - 1) / 18, 7, 0, 5),
                Size = UDim2.fromOffset(13, 9),
                BackgroundColor3 = Color3.fromRGB(242, 81, 73),
                BorderSizePixel = 0,
                ZIndex = 24,
            }, header)
            corner(stud, 3); stroke(stud, Color3.fromRGB(145, 26, 25), 1, 0.25)
        end
    elseif Theme.Style == "Galaxy" then
        gradient(header, Color3.fromRGB(18, 23, 56), Color3.fromRGB(39, 22, 76), 0)
    elseif Theme.Style == "Eid" then
        gradient(header, Color3.fromRGB(14, 65, 46), Color3.fromRGB(7, 39, 31), 0)
    else
        header.BackgroundColor3 = Color3.fromRGB(17, 23, 32)
    end

    makeLogo(header, Theme.Style, UDim2.fromOffset(14, 10), 42)
    label(header, "BAXTARA X CHEAT", 13, Theme.Text, Enum.Font.GothamBlack,
        UDim2.fromOffset(66, 10), UDim2.new(0.58, -76, 0, 22))
    label(header, Theme.Name, 8, Theme.Style == "Lego" and Color3.fromRGB(255, 236, 196) or Theme.Muted,
        Enum.Font.GothamBold, UDim2.fromOffset(67, 33), UDim2.new(0.58, -76, 0, 15))

    if Theme.Style == "Eid" then
        label(header, "✦", 17, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(1, -139, 0, 12), UDim2.fromOffset(24, 26), Enum.TextXAlignment.Center)
        addKetupat(header, UDim2.new(1, -111, 0, 0), 25, KetupatNodes, 25)
        addKetupat(header, UDim2.new(1, -78, 0, 3), 21, KetupatNodes, 25)
    elseif Theme.Style == "Galaxy" then
        label(header, "✧", 21, Theme.Accent2, Enum.Font.GothamBold,
            UDim2.new(1, -139, 0, 9), UDim2.fromOffset(25, 28), Enum.TextXAlignment.Center)
    elseif Theme.Style == "Modern" then
        label(header, "LOCAL WORKSPACE  /  07", 8, Theme.Muted, Enum.Font.Code,
            UDim2.new(1, -218, 0, 0), UDim2.fromOffset(145, 62), Enum.TextXAlignment.Right)
    end

    local close = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(31, 30),
        BackgroundColor3 = Theme.Style == "Lego" and Color3.fromRGB(175, 29, 27) or Theme.Raised,
        Text = "×",
        TextColor3 = Theme.Style == "Lego" and Color3.new(1, 1, 1) or Theme.Danger,
        TextSize = 21,
        Font = Enum.Font.GothamBlack,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, header)
    corner(close, Theme.Style == "Lego" and 3 or (Theme.Style == "Galaxy" and 99 or 8))
    close.Activated:Connect(function() closePanel() end)

    local bodyTop = headerHeight + 10
    local nav, navHorizontal, contentX, contentY, contentSize
    if Theme.Style == "Lego" then
        -- Full-width row of tactile brick tabs, like a physical LEGO control board.
        navHorizontal = true
        nav = make("ScrollingFrame", {
            Position = UDim2.fromOffset(10, bodyTop),
            Size = UDim2.new(1, -20, 0, 49),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            CanvasSize = UDim2.new(0, #PageNames * 119, 0, 0),
            ZIndex = 23,
        }, Main)
        make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, nav)
        contentX, contentY = 12, bodyTop + 56
        contentSize = UDim2.new(1, -24, 1, -(bodyTop + 66))
    elseif Theme.Style == "Galaxy" and not mobile then
        navHorizontal = false
        nav = make("Frame", {
            Position = UDim2.fromOffset(10, bodyTop + 2),
            Size = UDim2.new(0, 82, 1, -(bodyTop + 14)),
            BackgroundColor3 = Theme.Surface,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ZIndex = 23,
        }, Main)
        corner(nav, 30); stroke(nav, Theme.Border, 1.2, 0.38)
        make("UIListLayout", { Padding = UDim.new(0, 7), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, nav)
        make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, nav)
        label(nav, "ORBIT", 7, Theme.Accent2, Enum.Font.GothamBlack,
            UDim2.new(0, 0, 1, -21), UDim2.new(1, 0, 0, 14), Enum.TextXAlignment.Center)
        contentX, contentY = 102, bodyTop + 3
        contentSize = UDim2.new(1, -114, 1, -(bodyTop + 14))
    elseif Theme.Style == "Modern" and not mobile then
        navHorizontal = false
        nav = make("Frame", {
            Position = UDim2.fromOffset(12, bodyTop + 1),
            Size = UDim2.new(0, 58, 1, -(bodyTop + 13)),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 23,
        }, Main)
        corner(nav, 11); stroke(nav, Theme.Border, 1, 0.78)
        make("UIListLayout", { Padding = UDim.new(0, 7), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, nav)
        make("UIPadding", { PaddingTop = UDim.new(0, 9) }, nav)
        label(nav, "BX", 9, Theme.Accent, Enum.Font.GothamBlack,
            UDim2.new(0, 0, 1, -22), UDim2.new(1, 0, 0, 14), Enum.TextXAlignment.Center)
        contentX, contentY = 82, bodyTop + 1
        contentSize = UDim2.new(1, -94, 1, -(bodyTop + 13))
    elseif Theme.Style == "Eid" and not mobile then
        -- Eid uses a right-hand ornamental menu, deliberately unlike Modern's left rail.
        navHorizontal = false
        nav = make("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 0, bodyTop + 2),
            Size = UDim2.new(0, 112, 1, -(bodyTop + 14)),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 23,
        }, Main)
        corner(nav, 18); stroke(nav, Theme.Accent, 1.2, 0.38)
        make("UIListLayout", { Padding = UDim.new(0, 7), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, nav)
        make("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, nav)
        label(nav, "☾  MENU", 8, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(0, 0, 1, -23), UDim2.new(1, 0, 0, 14), Enum.TextXAlignment.Center)
        contentX, contentY = 12, bodyTop + 2
        contentSize = UDim2.new(1, -134, 1, -(bodyTop + 14))
    else
        -- Compact-screen fallback: theme-specific horizontal nav without clipping.
        navHorizontal = true
        nav = make("ScrollingFrame", {
            Position = UDim2.fromOffset(10, bodyTop),
            Size = UDim2.new(1, -20, 0, 47),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            CanvasSize = UDim2.new(0, #PageNames * 115, 0, 0),
            ZIndex = 23,
        }, Main)
        make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, nav)
        contentX, contentY = 11, bodyTop + 54
        contentSize = UDim2.new(1, -22, 1, -(bodyTop + 64))
    end

    for index, page in ipairs(PageNames) do
        navButton(nav, page, index, mobile, navHorizontal)
    end

    Content = make("ScrollingFrame", {
        Name = "PageContent",
        Position = UDim2.fromOffset(contentX, contentY),
        Size = contentSize,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 22,
    }, Main)

    bindDrag(header)
end

local function revealPanel()
    if State.Destroyed or not Main or not Main.Parent then return end
    Main.Visible = true
    local initialScale = 0.84
    if Theme.Style == "Modern" then initialScale = 0.055
    elseif Theme.Style == "Galaxy" then initialScale = 0.78
    elseif Theme.Style == "Lego" then initialScale = 0.82
    elseif Theme.Style == "Eid" then initialScale = 0.90 end
    local scale = Main:FindFirstChildOfClass("UIScale") or make("UIScale", { Scale = initialScale }, Main)
    scale.Scale = State.ReduceMotion and 1 or initialScale
    Main.Rotation = 0
    Main.BackgroundTransparency = State.ReduceMotion and 0 or 0.08
    local duration = Theme.Style == "Modern" and 0.56 or 0.34
    playTween(scale, duration, { Scale = 1 }, Enum.EasingStyle.Back)
    playTween(Main, 0.24, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quart)
    if Launcher then Launcher.Visible = false end
end

local function makeOpeningLayer()
    local layer = make("Frame", {
        Name = "OpeningSequence",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 120,
    }, ScreenGui)
    return layer
end

local function runGalaxyOpen(layer)
    label(layer, "ENTERING ORBIT", 10, Theme.Accent2, Enum.Font.GothamBlack,
        UDim2.new(0.5, -100, 0.5, 104), UDim2.fromOffset(200, 22), Enum.TextXAlignment.Center)
    local planet, ring = addPlanet(layer, 66, Theme.Accent, Theme.Accent2, 124)
    planet.AnchorPoint = Vector2.new(0.5, 0.5)
    planet.Position = UDim2.fromScale(0.5, 0.47)
    local scale = make("UIScale", { Scale = 0.45 }, planet)
    local ring2 = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.5, 0.58),
        Rotation = 35,
        BackgroundTransparency = 1,
        ZIndex = 125,
    }, planet)
    corner(ring2, 99); stroke(ring2, Theme.Text, 1.4, 0.25)
    playTween(scale, 0.72, { Scale = 3.9 }, Enum.EasingStyle.Quint)
    playTween(ring, 0.7, { Rotation = 48 }, Enum.EasingStyle.Quart)
    playTween(ring2, 0.7, { Rotation = -42 }, Enum.EasingStyle.Quart)
    task.wait(0.76)
    playTween(layer, 0.20, { BackgroundTransparency = 1 })
    task.wait(0.22)
end

local function runLegoOpen(layer)
    label(layer, "ASSEMBLING BAXTARA", 10, Color3.fromRGB(255, 224, 112), Enum.Font.GothamBlack,
        UDim2.new(0.5, -120, 0.5, 105), UDim2.fromOffset(240, 22), Enum.TextXAlignment.Center)
    local center = UDim2.new(0.5, 0, 0.46, 0)
    local pieces = {}
    local colors = {
        Color3.fromRGB(208, 47, 42), Color3.fromRGB(33, 111, 215),
        Color3.fromRGB(255, 194, 39), Color3.fromRGB(44, 158, 76),
        Color3.fromRGB(208, 47, 42), Color3.fromRGB(33, 111, 215),
    }
    for i = 1, 6 do
        local piece = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(center.X.Scale, (i % 2 == 0 and 1 or -1) * 260, center.Y.Scale, (i - 3) * 90),
            Size = UDim2.fromOffset(88, 42),
            BackgroundColor3 = colors[i],
            BorderSizePixel = 0,
            ZIndex = 124 + i,
        }, layer)
        corner(piece, 3); stroke(piece, Color3.fromRGB(8, 13, 22), 2, 0.05)
        for s = 1, 3 do
            local stud = make("Frame", {
                Position = UDim2.fromOffset(9 + (s - 1) * 25, -5),
                Size = UDim2.fromOffset(17, 10),
                BackgroundColor3 = colors[i]:Lerp(Color3.new(1, 1, 1), 0.24),
                BorderSizePixel = 0,
                ZIndex = 132 + i,
            }, piece)
            corner(stud, 4)
        end
        table.insert(pieces, piece)
    end
    for i, piece in ipairs(pieces) do
        local row = math.floor((i - 1) / 2)
        local col = (i - 1) % 2
        playTween(piece, 0.23 + row * 0.05, {
            Position = UDim2.new(center.X.Scale, (col == 0 and -46 or 46), center.Y.Scale, (row - 1) * 40),
        }, Enum.EasingStyle.Back)
        task.wait(0.055)
    end
    task.wait(0.30)
    -- Top bricks slide up and tip open after the brick box is assembled.
    if pieces[1] then
        playTween(pieces[1], 0.24, { Position = UDim2.new(center.X.Scale, -46, center.Y.Scale, -108), Rotation = -16 }, Enum.EasingStyle.Back)
    end
    if pieces[2] then
        playTween(pieces[2], 0.24, { Position = UDim2.new(center.X.Scale, 46, center.Y.Scale, -108), Rotation = 16 }, Enum.EasingStyle.Back)
    end
    task.wait(0.30)
    playTween(layer, 0.18, { BackgroundTransparency = 1 })
    for _, piece in ipairs(pieces) do playTween(piece, 0.18, { BackgroundTransparency = 1 }) end
    task.wait(0.20)
end

local function runModernOpen(layer)
    local frame = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 154),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 124,
    }, layer)
    corner(frame, 18)
    stroke(frame, Theme.Border, 1.2, 0.24)
    gradient(frame, Theme.Surface, Theme.Background, 0)

    local scale = make("UIScale", { Scale = 0.06 }, frame)
    local logoHost = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 26),
        Size = UDim2.fromOffset(72, 72),
        ZIndex = 126,
    }, frame)
    makeLogo(logoHost, "Modern", UDim2.fromOffset(2, 2), 68)

    label(frame, "BAXTARA X", 17, Theme.Text, Enum.Font.GothamBlack,
        UDim2.fromOffset(108, 35), UDim2.new(1, -126, 0, 26))
    label(frame, "MODERN WORKSPACE", 8, Theme.Muted, Enum.Font.Code,
        UDim2.fromOffset(110, 64), UDim2.new(1, -128, 0, 18))
    local rail = make("Frame", {
        Position = UDim2.new(0, 20, 1, -28),
        Size = UDim2.new(1, -40, 0, 3),
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0,
        ZIndex = 126,
    }, frame)
    corner(rail, 99)
    local fill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 127,
    }, rail)
    corner(fill, 99)
    local status = label(frame, "INITIALIZING INTERFACE", 7, Theme.Accent2, Enum.Font.Code,
        UDim2.fromOffset(110, 85), UDim2.new(1, -128, 0, 16))

    playTween(scale, 0.58, { Scale = 1.04 }, Enum.EasingStyle.Back)
    playTween(fill, 0.72, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quart)
    task.wait(0.62)
    playTween(scale, 0.13, { Scale = 1 }, Enum.EasingStyle.Quad)
    status.Text = "SCAN COMPLETE  /  OPENING"
    task.wait(0.18)
    playTween(frame, 0.16, { BackgroundTransparency = 1 })
    task.wait(0.18)
end

local function runEidOpen(layer)
    label(layer, "☾", 64, Theme.Accent, Enum.Font.GothamBold,
        UDim2.new(0.5, -40, 0.5, -132), UDim2.fromOffset(80, 76), Enum.TextXAlignment.Center)
    local left = addKetupat(layer, UDim2.new(0.5, -105, 0.5, -52), 58, nil, 125)
    local right = addKetupat(layer, UDim2.new(0.5, 48, 0.5, -48), 52, nil, 125)
    local greeting = label(layer, "Selamat Hari Raya Idul Fitri", 18, Theme.Text, Enum.Font.GothamBold,
        UDim2.new(0.5, -180, 0.5, 36), UDim2.fromOffset(360, 30), Enum.TextXAlignment.Center)
    local sub = label(layer, "Mohon maaf lahir dan batin", 12, Theme.Accent, Enum.Font.GothamSemibold,
        UDim2.new(0.5, -170, 0.5, 69), UDim2.fromOffset(340, 24), Enum.TextXAlignment.Center)
    greeting.TextTransparency = 1
    sub.TextTransparency = 1
    playTween(left, 0.35, { Rotation = -8 }, Enum.EasingStyle.Sine)
    playTween(right, 0.35, { Rotation = 8 }, Enum.EasingStyle.Sine)
    playTween(greeting, 0.45, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
    task.wait(0.24)
    playTween(sub, 0.40, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
    task.wait(1.28)
    playTween(layer, 0.23, { BackgroundTransparency = 1 })
    playTween(greeting, 0.18, { TextTransparency = 1 })
    playTween(sub, 0.18, { TextTransparency = 1 })
    task.wait(0.25)
end

openPanel = function()
    if State.Destroyed or State.PanelVisible or State.Opening then return end
    State.Opening = true
    local layer = makeOpeningLayer()
    if State.ReduceMotion then
        layer:Destroy()
        State.PanelVisible = true
        revealPanel()
        State.Opening = false
        return
    end
    task.spawn(function()
        if Theme.Style == "Galaxy" then
            runGalaxyOpen(layer)
        elseif Theme.Style == "Lego" then
            runLegoOpen(layer)
        elseif Theme.Style == "Eid" then
            runEidOpen(layer)
        else
            runModernOpen(layer)
        end
        if layer and layer.Parent then layer:Destroy() end
        State.PanelVisible = true
        revealPanel()
        State.Opening = false
    end)
end

closePanel = function()
    if State.Destroyed or not State.PanelVisible or State.Opening then return end
    State.Opening = true
    local closingScan = nil
    if Main and Main.Parent and not State.ReduceMotion then
        local scale = Main:FindFirstChildOfClass("UIScale") or make("UIScale", { Scale = 1 }, Main)
        local duration = 0.28
        local targetScale = 0.10
        local targetRotation = 0

        if Theme.Style == "Galaxy" then
            duration, targetScale, targetRotation = 0.34, 0.06, 16
        elseif Theme.Style == "Lego" then
            duration, targetScale, targetRotation = 0.30, 0.12, 3
        elseif Theme.Style == "Modern" then
            duration, targetScale, targetRotation = 0.30, 0.055, 0
            closingScan = make("Frame", {
                Position = UDim2.new(0, 0, 1, -3),
                Size = UDim2.new(0, 0, 0, 2),
                BackgroundColor3 = Theme.Accent2,
                BorderSizePixel = 0,
                ZIndex = 60,
            }, Main)
            playTween(closingScan, 0.13, { Size = UDim2.new(1, 0, 0, 2) }, Enum.EasingStyle.Linear)
            task.wait(0.14)
        elseif Theme.Style == "Eid" then
            duration, targetScale, targetRotation = 0.38, 0.08, -3
        end

        local scaleTween = playTween(scale, duration, { Scale = targetScale }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        playTween(Main, duration * 0.82, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if targetRotation ~= 0 then
            playTween(Main, duration, { Rotation = targetRotation }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        end
        if scaleTween then scaleTween.Completed:Wait() end
    end
    if closingScan and closingScan.Parent then closingScan:Destroy() end
    if Main and Main.Parent then
        Main.Visible = false
        Main.Rotation = 0
        Main.BackgroundTransparency = 0
        local scale = Main:FindFirstChildOfClass("UIScale")
        if scale then scale.Scale = 1 end
    end
    State.PanelVisible = false
    if Launcher then Launcher.Visible = true end
    State.Opening = false
end

local function togglePanel()
    if State.PanelVisible then closePanel() else openPanel() end
end

-- Build initial state: only the floating launcher is visible; no theme art covers the viewport.
renderUI = function()
    if State.Destroyed then return end
    Theme = Themes[State.Theme] or Themes.Galaxy
    if Main and Main.Parent then Main:Destroy() end
    if Launcher and Launcher.Parent then Launcher:Destroy() end
    buildBackdrop()
    makePanel()
    Launcher = makeLauncher()
    local renderer = PageRenderers[State.Page] or pageOverview
    renderer()
end


-- ========== KEY GATE + LOADING ==========
local KEY_VALID = "BAXTARA X CHEAT"
local KEY_FILE = "baxtara_x_key.txt"
local function keySaved()
    local ok, data = pcall(function()
        if isfile and isfile(KEY_FILE) and readfile then return readfile(KEY_FILE) end
        return getgenv().BAXTARA_KEY_SAVE
    end)
    return ok and data and tostring(data):gsub("^%s+",""):gsub("%s+$","") == KEY_VALID
end
local function saveKey()
    pcall(function()
        if writefile then writefile(KEY_FILE, KEY_VALID) end
        getgenv().BAXTARA_KEY_SAVE = KEY_VALID
        getgenv().BAXTARA_UNLOCKED = true
    end)
end

local function drawLogo(parent, pos, size)
    -- geometric BX logo (no emoji)
    local host = Instance.new("Frame")
    host.BackgroundTransparency = 1
    host.Position = pos
    host.Size = UDim2.fromOffset(size, size)
    host.ZIndex = 50
    host.Parent = parent
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Size = UDim2.fromScale(1, 1)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 50
    ring.Parent = host
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
    local rs = Instance.new("UIStroke"); rs.Color = Color3.fromRGB(0, 220, 200); rs.Thickness = 2; rs.Parent = ring
    local core = Instance.new("Frame")
    core.AnchorPoint = Vector2.new(0.5, 0.5)
    core.Position = UDim2.fromScale(0.5, 0.5)
    core.Size = UDim2.fromScale(0.62, 0.62)
    core.BackgroundColor3 = Color3.fromRGB(0, 180, 160)
    core.BorderSizePixel = 0
    core.ZIndex = 51
    core.Parent = host
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = core
    local bx = Instance.new("TextLabel")
    bx.Size = UDim2.fromScale(1, 1)
    bx.BackgroundTransparency = 1
    bx.Text = "BX"
    bx.TextColor3 = Color3.fromRGB(8, 12, 20)
    bx.Font = Enum.Font.GothamBlack
    bx.TextScaled = true
    bx.ZIndex = 52
    bx.Parent = core
    return host
end

local function runCartoonLoading(done)
    local layer = Instance.new("Frame")
    layer.Size = UDim2.fromScale(1, 1)
    layer.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
    layer.BorderSizePixel = 0
    layer.ZIndex = 100
    layer.Parent = ScreenGui
    local a = Instance.new("Frame")
    a.Size = UDim2.fromOffset(70, 90)
    a.Position = UDim2.new(0.3, -35, 0.5, -45)
    a.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
    a.BorderSizePixel = 0
    a.ZIndex = 101
    a.Parent = layer
    Instance.new("UICorner", a).CornerRadius = UDim.new(0, 16)
    local b = Instance.new("Frame")
    b.Size = UDim2.fromOffset(70, 90)
    b.Position = UDim2.new(0.7, -35, 0.5, -45)
    b.BackgroundColor3 = Color3.fromRGB(255, 100, 120)
    b.BorderSizePixel = 0
    b.ZIndex = 101
    b.Parent = layer
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 16)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0.5, 70)
    title.BackgroundTransparency = 1
    title.Text = "BAXTARA  VS  CHEAT"
    title.TextColor3 = Color3.fromRGB(240, 245, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.ZIndex = 102
    title.Parent = layer
    -- fight bounce
    task.spawn(function()
        for i = 1, 8 do
            TweenService:Create(a, TweenInfo.new(0.12), {Position = UDim2.new(0.42, -35, 0.5, -45 + (i%2)*10)}):Play()
            TweenService:Create(b, TweenInfo.new(0.12), {Position = UDim2.new(0.58, -35, 0.5, -45 - (i%2)*10)}):Play()
            task.wait(0.13)
        end
        -- smash
        TweenService:Create(a, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -80, 0.5, -45), Rotation = -25}):Play()
        TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 10, 0.5, -45), Rotation = 25}):Play()
        task.wait(0.25)
        -- shatter particles
        for i = 1, 14 do
            local p = Instance.new("Frame")
            p.Size = UDim2.fromOffset(math.random(6, 14), math.random(6, 14))
            p.Position = UDim2.new(0.5, math.random(-20, 20), 0.5, math.random(-20, 20))
            p.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(255, 100, 120)
            p.BorderSizePixel = 0
            p.ZIndex = 103
            p.Parent = layer
            Instance.new("UICorner", p).CornerRadius = UDim.new(0, 3)
            TweenService:Create(p, TweenInfo.new(0.45), {
                Position = UDim2.new(0.5, math.random(-220, 220), 0.5, math.random(-160, 160)),
                BackgroundTransparency = 1,
                Rotation = math.random(-90, 90),
            }):Play()
        end
        TweenService:Create(a, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(b, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        task.wait(0.5)
        TweenService:Create(layer, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        layer:Destroy()
        if done then done() end
    end)
end

local function runTerminalLoading(done)
    local layer = Instance.new("Frame")
    layer.Size = UDim2.fromScale(1, 1)
    layer.BackgroundColor3 = Color3.fromRGB(6, 10, 14)
    layer.BorderSizePixel = 0
    layer.ZIndex = 100
    layer.Parent = ScreenGui
    drawLogo(layer, UDim2.new(0.5, -36, 0.22, 0), 72)
    local term = Instance.new("Frame")
    term.Size = UDim2.fromOffset(340, 160)
    term.Position = UDim2.new(0.5, -170, 0.5, -40)
    term.BackgroundColor3 = Color3.fromRGB(10, 16, 22)
    term.BorderSizePixel = 0
    term.ZIndex = 101
    term.Parent = layer
    Instance.new("UICorner", term).CornerRadius = UDim.new(0, 8)
    local ts = Instance.new("UIStroke"); ts.Color = Color3.fromRGB(0, 200, 160); ts.Thickness = 1; ts.Parent = term
    local log = Instance.new("TextLabel")
    log.Size = UDim2.new(1, -20, 1, -20)
    log.Position = UDim2.fromOffset(10, 10)
    log.BackgroundTransparency = 1
    log.TextXAlignment = Enum.TextXAlignment.Left
    log.TextYAlignment = Enum.TextYAlignment.Top
    log.TextColor3 = Color3.fromRGB(0, 255, 180)
    log.Font = Enum.Font.Code
    log.TextSize = 12
    log.Text = ""
    log.ZIndex = 102
    log.Parent = term
    -- computer body (drawn)
    local pc = Instance.new("Frame")
    pc.Size = UDim2.fromOffset(90, 60)
    pc.Position = UDim2.new(0.5, -100, 0.72, 0)
    pc.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
    pc.BorderSizePixel = 0
    pc.ZIndex = 101
    pc.Parent = layer
    Instance.new("UICorner", pc).CornerRadius = UDim.new(0, 4)
    local screen = Instance.new("Frame")
    screen.Size = UDim2.new(1, -10, 0.55, 0)
    screen.Position = UDim2.fromOffset(5, 5)
    screen.BackgroundColor3 = Color3.fromRGB(0, 180, 140)
    screen.BorderSizePixel = 0
    screen.ZIndex = 102
    screen.Parent = pc
    -- screwdriver (rotating tool drawn)
    local tool = Instance.new("Frame")
    tool.Size = UDim2.fromOffset(8, 50)
    tool.AnchorPoint = Vector2.new(0.5, 0.5)
    tool.Position = UDim2.new(0.5, 50, 0.72, 30)
    tool.BackgroundColor3 = Color3.fromRGB(180, 190, 200)
    tool.BorderSizePixel = 0
    tool.ZIndex = 102
    tool.Parent = layer
    local handle = Instance.new("Frame")
    handle.Size = UDim2.fromOffset(16, 22)
    handle.Position = UDim2.new(0.5, -8, 1, -4)
    handle.BackgroundColor3 = Color3.fromRGB(220, 80, 60)
    handle.BorderSizePixel = 0
    handle.ZIndex = 103
    handle.Parent = tool
    Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 3)
    local lines = {
        "> BAXTARA X CHEAT boot...",
        "> mount modules [AIM][ESP][BRUTAL]",
        "> check integrity ........ OK",
        "> load interface ........ OK",
        "> screwdriver calibrate..",
        "> READY.",
    }
    task.spawn(function()
        local rot = 0
        local spin = true
        task.spawn(function()
            while spin and tool.Parent do
                rot = (rot + 12) % 360
                tool.Rotation = rot
                task.wait(0.03)
            end
        end)
        local acc = ""
        for _, line in ipairs(lines) do
            acc = acc .. line .. "\n"
            log.Text = acc
            task.wait(0.28)
        end
        spin = false
        task.wait(0.35)
        TweenService:Create(layer, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        layer:Destroy()
        if done then done() end
    end)
end

local function showKeyGate()
    local gate = Instance.new("Frame")
    gate.Name = "KeyGate"
    gate.Size = UDim2.fromScale(1, 1)
    gate.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
    gate.BorderSizePixel = 0
    gate.ZIndex = 200
    gate.Parent = ScreenGui
    drawLogo(gate, UDim2.new(0.5, -40, 0.12, 0), 80)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 28)
    title.Position = UDim2.new(0, 20, 0.28, 0)
    title.BackgroundTransparency = 1
    title.Text = "BAXTARA X CHEAT"
    title.TextColor3 = Color3.fromRGB(0, 230, 200)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 22
    title.ZIndex = 201
    title.Parent = gate
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -40, 0, 18)
    sub.Position = UDim2.new(0, 20, 0.28, 30)
    sub.BackgroundTransparency = 1
    sub.Text = "ENTER ACCESS KEY"
    sub.TextColor3 = Color3.fromRGB(120, 140, 160)
    sub.Font = Enum.Font.Code
    sub.TextSize = 12
    sub.ZIndex = 201
    sub.Parent = gate
    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(300, 40)
    box.Position = UDim2.new(0.5, -150, 0.42, 0)
    box.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
    box.Text = ""
    box.PlaceholderText = "BAXTARA X CHEAT"
    box.PlaceholderColor3 = Color3.fromRGB(80, 90, 110)
    box.TextColor3 = Color3.fromRGB(240, 248, 255)
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.ZIndex = 201
    box.Parent = gate
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local unlock = Instance.new("TextButton")
    unlock.Size = UDim2.fromOffset(300, 40)
    unlock.Position = UDim2.new(0.5, -150, 0.42, 52)
    unlock.BackgroundColor3 = Color3.fromRGB(0, 180, 150)
    unlock.Text = "UNLOCK"
    unlock.TextColor3 = Color3.fromRGB(8, 12, 20)
    unlock.Font = Enum.Font.GothamBlack
    unlock.TextSize = 14
    unlock.ZIndex = 201
    unlock.Parent = gate
    Instance.new("UICorner", unlock).CornerRadius = UDim.new(0, 8)
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.fromOffset(300, 36)
    saveBtn.Position = UDim2.new(0.5, -150, 0.42, 100)
    saveBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
    saveBtn.Text = "SAVE KEY (auto login next time)"
    saveBtn.TextColor3 = Color3.fromRGB(180, 200, 220)
    saveBtn.Font = Enum.Font.Gotham
    saveBtn.TextSize = 12
    saveBtn.ZIndex = 201
    saveBtn.Parent = gate
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)
    local doSave = false
    saveBtn.MouseButton1Click:Connect(function()
        doSave = not doSave
        saveBtn.Text = doSave and "SAVE KEY: ON" or "SAVE KEY (auto login next time)"
        saveBtn.BackgroundColor3 = doSave and Color3.fromRGB(0, 120, 100) or Color3.fromRGB(30, 40, 55)
    end)
    local wa = Instance.new("TextButton")
    wa.Size = UDim2.fromOffset(300, 36)
    wa.Position = UDim2.new(0.5, -150, 0.42, 148)
    wa.BackgroundColor3 = Color3.fromRGB(20, 90, 60)
    wa.Text = "WhatsApp Channel"
    wa.TextColor3 = Color3.fromRGB(200, 255, 220)
    wa.Font = Enum.Font.GothamBold
    wa.TextSize = 12
    wa.ZIndex = 201
    wa.Parent = gate
    Instance.new("UICorner", wa).CornerRadius = UDim.new(0, 8)
    wa.MouseButton1Click:Connect(function()
        pcall(function()
            local link = "https://whatsapp.com/channel/0029Vb8PluMLtOj5TTbxRl1k"
            if setclipboard then setclipboard(link) end
            notify("WhatsApp link copied")
        end)
    end)
    local loadPick = Instance.new("TextLabel")
    loadPick.Size = UDim2.fromOffset(300, 20)
    loadPick.Position = UDim2.new(0.5, -150, 0.42, 200)
    loadPick.BackgroundTransparency = 1
    loadPick.Text = "Loading style after unlock:"
    loadPick.TextColor3 = Color3.fromRGB(120, 140, 160)
    loadPick.Font = Enum.Font.Gotham
    loadPick.TextSize = 11
    loadPick.ZIndex = 201
    loadPick.Parent = gate
    local styleCartoon = true
    local c1 = Instance.new("TextButton")
    c1.Size = UDim2.fromOffset(145, 34)
    c1.Position = UDim2.new(0.5, -150, 0.42, 224)
    c1.BackgroundColor3 = Color3.fromRGB(0, 140, 120)
    c1.Text = "CARTUN"
    c1.TextColor3 = Color3.fromRGB(255, 255, 255)
    c1.Font = Enum.Font.GothamBold
    c1.TextSize = 12
    c1.ZIndex = 201
    c1.Parent = gate
    Instance.new("UICorner", c1).CornerRadius = UDim.new(0, 6)
    local c2 = Instance.new("TextButton")
    c2.Size = UDim2.fromOffset(145, 34)
    c2.Position = UDim2.new(0.5, 5, 0.42, 224)
    c2.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
    c2.Text = "TERMINAL"
    c2.TextColor3 = Color3.fromRGB(200, 210, 220)
    c2.Font = Enum.Font.GothamBold
    c2.TextSize = 12
    c2.ZIndex = 201
    c2.Parent = gate
    Instance.new("UICorner", c2).CornerRadius = UDim.new(0, 6)
    c1.MouseButton1Click:Connect(function()
        styleCartoon = true
        c1.BackgroundColor3 = Color3.fromRGB(0, 140, 120)
        c2.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
    end)
    c2.MouseButton1Click:Connect(function()
        styleCartoon = false
        c2.BackgroundColor3 = Color3.fromRGB(0, 140, 120)
        c1.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
    end)
    local function tryUnlock()
        local k = (box.Text or ""):gsub("^%s+",""):gsub("%s+$","")
        if k:upper() == KEY_VALID:upper() then
            if doSave then saveKey() end
            gate:Destroy()
            local function afterLoad()
                renderUI()
                openPanel()
            end
            if styleCartoon then
                runCartoonLoading(afterLoad)
            else
                runTerminalLoading(afterLoad)
            end
        else
            box.Text = ""
            box.PlaceholderText = "WRONG KEY"
            task.delay(1.2, function() if box.Parent then box.PlaceholderText = "BAXTARA X CHEAT" end end)
        end
    end
    unlock.MouseButton1Click:Connect(tryUnlock)
    box.FocusLost:Connect(function(enter) if enter then tryUnlock() end end)
end

-- Boot sequence
if keySaved() or getgenv().BAXTARA_UNLOCKED then
    task.spawn(function()
        runTerminalLoading(function()
            renderUI()
            -- launcher only until user opens
        end)
    end)
else
    showKeyGate()
end

-- connect input (was after renderUI)
connect(UserInputService.InputChanged, function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        ActiveSlider(input.Position.X)
    end
    if Dragging and DragInput and DragStart and Main and Main.Parent then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - DragInput
            Main.Position = UDim2.new(
                DragStart.X.Scale, DragStart.X.Offset + delta.X,
                DragStart.Y.Scale, DragStart.Y.Offset + delta.Y
            )
        end
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ActiveSlider = nil
        Dragging = false
    end
end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then togglePanel() end
end)

connect(Players.PlayerAdded, function()
    if PlayerLabel and PlayerLabel.Parent then PlayerLabel.Text = tostring(#Players:GetPlayers()) end
end)
connect(Players.PlayerRemoving, function()
    if PlayerLabel and PlayerLabel.Parent then PlayerLabel.Text = tostring(math.max(0, #Players:GetPlayers() - 1)) end
end)

connect(RunService.RenderStepped, function()
    if State.Destroyed then return end
    Frames = Frames + 1
    local now = os.clock()
    if now - LastStats >= 1 then
        FPS = math.floor(Frames / math.max(now - LastStats, 0.001) + 0.5)
        Frames = 0
        LastStats = now
        if FpsLabel and FpsLabel.Parent then FpsLabel.Text = tostring(FPS) end
        if PlayerLabel and PlayerLabel.Parent then PlayerLabel.Text = tostring(#Players:GetPlayers()) end
        if SessionLabel and SessionLabel.Parent then
            local elapsed = math.floor(now - SessionStart)
            SessionLabel.Text = string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60)
        end
    end

    if State.ReduceMotion or not State.Ambient then return end
    local phase = now * State.AnimationSpeed
    if Theme.Style == "Galaxy" then
        if State.StarParticles then
            for _, item in ipairs(StarNodes) do
                if item.Object and item.Object.Parent then
                    local wave = (math.sin(phase * 1.6 + item.Phase) + 1) * 0.5
                    item.Object.BackgroundTransparency = math.clamp(item.Base + (1 - wave) * State.Glow * 0.38, 0.08, 0.97)
                end
            end
        end
        if State.OrbitMotion then
            for _, item in ipairs(OrbitNodes) do
                if item.Host and item.Host.Parent and not item.Local then
                    local angle = phase * item.Speed + item.Phase
                    item.Host.AnchorPoint = Vector2.new(0.5, 0.5)
                    item.Host.Position = UDim2.new(0.5 + math.cos(angle) * item.RX, 0,
                        0.5 + math.sin(angle) * item.RY, 0)
                    item.Host.ZIndex = math.sin(angle) > 0 and 21 or 20
                end
            end
        end
    elseif Theme.Style == "Eid" and State.KetupatMotion then
        for i, item in ipairs(KetupatNodes) do
            if item and item.Parent then item.Rotation = math.sin(phase * 0.85 + i) * 4 end
        end
    end
end)

ScreenGui.Destroying:Connect(function()
    State.Destroyed = true
    for _, connection in ipairs(Connections) do pcall(function() connection:Disconnect() end) end
    table.clear(Connections)
    table.clear(OrbitNodes)
    table.clear(StarNodes)
    table.clear(KetupatNodes)
end)


-- ========== FEATURE ENGINE ==========
Features = Features or {}
local Camera = Workspace.CurrentCamera
local DrawingLib = Drawing
local FeatDrawings = { FOV = nil, ESP = {}, NPC = {} }
local FeatConns = {}
local FlyBV, FlyBG, NoclipConn, JumpConn
local OrigWalk, SpinAng, HitboxOrig = 16, 0, {}
local LockedTarget, LastShoot = nil, 0
local SkyFolder, SelfTagGui, ChatBubbleGui

local function featConn(c) table.insert(FeatConns, c); return c end
local function getChar(p) return p and p.Character end
local function getRoot(c) return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")) end
local function getHead(c) return c and c:FindFirstChild("Head") end
local function alive(c)
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function teamOK(p)
    if not State.TeamCheck then return true end
    if not LocalPlayer.Team then return true end
    return p.Team ~= LocalPlayer.Team
end
local function w2s(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on
end
local function dist(pos)
    local r = getRoot(LocalPlayer.Character)
    return r and (r.Position - pos).Magnitude or 99999
end
local function visible(from, to, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    return Workspace:Raycast(from, to - from, params) == nil
end

function Features.SetFly(on)
    local char = LocalPlayer.Character
    local root = getRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if FlyBV then pcall(function() FlyBV:Destroy() end) FlyBV = nil end
    if FlyBG then pcall(function() FlyBG:Destroy() end) FlyBG = nil end
    if on and root and hum then
        hum.PlatformStand = true
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.MaxForce = Vector3.new(9e4,9e4,9e4)
        FlyBV.Velocity = Vector3.zero
        FlyBV.Parent = root
        FlyBG = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(9e4,9e4,9e4)
        FlyBG.P = 3000
        FlyBG.Parent = root
    elseif hum then
        hum.PlatformStand = false
    end
end

function Features.SetSpeed(on)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then
        OrigWalk = hum.WalkSpeed
        hum.WalkSpeed = math.clamp(State.SpeedValue or 28, 16, 100)
    else
        hum.WalkSpeed = OrigWalk or 16
    end
end

function Features.SetNoclip(on)
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    if on then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
        featConn(NoclipConn)
    end
end

function Features.SetInfJump(on)
    if JumpConn then JumpConn:Disconnect(); JumpConn = nil end
    if on then
        JumpConn = UserInputService.JumpRequest:Connect(function()
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        featConn(JumpConn)
    end
end

function Features.SetGhost(on)
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = on and 1 or 0
        elseif p:IsA("Decal") then p.Transparency = on and 1 or 0 end
    end
end

function Features.ClearHitbox()
    for uid, data in pairs(HitboxOrig) do
        local plr = Players:GetPlayerByUserId(uid)
        local char = plr and plr.Character
        if char and data then
            if data.Head then local h = char:FindFirstChild("Head"); if h then pcall(function() h.Size = data.Head; h.Transparency = data.HeadT or 0 end) end end
            if data.HRP then local r = char:FindFirstChild("HumanoidRootPart"); if r then pcall(function() r.Size = data.HRP; r.Transparency = data.HRPT or 1 end) end end
        end
    end
    HitboxOrig = {}
end

function Features.SetSky(on)
    if SkyFolder then pcall(function() SkyFolder:Destroy() end) SkyFolder = nil end
    if not on then return end
    SkyFolder = Instance.new("Folder")
    SkyFolder.Name = "BX_SKY"
    SkyFolder.Parent = Workspace
    local root = getRoot(LocalPlayer.Character)
    local base = root and root.Position or Vector3.new(0,0,0)
    for ring = 1, 3 do
        local n, rad, h = 6 + ring * 2, 80 + ring * 70, 60 + ring * 40
        for i = 1, n do
            local ang = (i / n) * math.pi * 2
            local part = Instance.new("Part")
            part.Anchored = true; part.CanCollide = false; part.Transparency = 1; part.Size = Vector3.new(1,1,1)
            part.CFrame = CFrame.new(base.X + math.cos(ang) * rad, h, base.Z + math.sin(ang) * rad)
            part.Parent = SkyFolder
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.fromOffset(260, 34); bb.MaxDistance = 4000; bb.Parent = part
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.fromScale(1,1); tl.BackgroundTransparency = 1
            tl.Text = "BAXTARA X CHEAT"; tl.TextColor3 = Color3.fromRGB(0,255,130)
            tl.TextTransparency = 0.3; tl.Font = Enum.Font.GothamBlack; tl.TextScaled = true
            tl.Parent = bb
        end
    end
    pcall(function()
        local Lighting = game:GetService("Lighting")
        Lighting.Brightness = 3
        Lighting.FogColor = Color3.fromRGB(10, 40, 25)
        Lighting.FogEnd = 900
        Lighting.ClockTime = 14
    end)
end

function Features.ClearSelfTag()
    if SelfTagGui then pcall(function() SelfTagGui:Destroy() end) SelfTagGui = nil end
end


function Features.OpenTPList()
    if Features._TPGui and Features._TPGui.Parent then
        Features._TPGui:Destroy()
        Features._TPGui = nil
        return
    end
    local gui = Instance.new("Frame")
    gui.Name = "BX_TPList"
    gui.Size = UDim2.fromOffset(280, 360)
    gui.Position = UDim2.new(0.5, -140, 0.5, -180)
    gui.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
    gui.BorderSizePixel = 0
    gui.ZIndex = 80
    gui.Parent = ScreenGui
    Instance.new("UICorner", gui).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke")
    st.Color = Theme.Accent; st.Thickness = 1.5; st.Parent = gui
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 36)
    title.Position = UDim2.fromOffset(12, 4)
    title.BackgroundTransparency = 1
    title.Text = "TP PLAYERS"
    title.TextColor3 = Theme.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 81
    title.Parent = gui
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(28, 28)
    close.Position = UDim2.new(1, -36, 0, 6)
    close.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 120, 120)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.ZIndex = 81
    close.Parent = gui
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
    close.MouseButton1Click:Connect(function()
        gui:Destroy()
        Features._TPGui = nil
    end)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(8, 42)
    scroll.Size = UDim2.new(1, -16, 1, -50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = 81
    scroll.Parent = gui
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.Parent = scroll
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 48)
            row.BackgroundColor3 = Color3.fromRGB(22, 28, 42)
            row.BorderSizePixel = 0
            row.ZIndex = 82
            row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.fromOffset(36, 36)
            img.Position = UDim2.fromOffset(6, 6)
            img.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
            img.BorderSizePixel = 0
            img.ZIndex = 83
            img.Parent = row
            Instance.new("UICorner", img).CornerRadius = UDim.new(0, 6)
            task.spawn(function()
                local ok, url = pcall(function()
                    return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if ok and img.Parent then img.Image = url end
            end)
            local nm = Instance.new("TextLabel")
            nm.Position = UDim2.fromOffset(48, 6)
            nm.Size = UDim2.new(1, -110, 0, 18)
            nm.BackgroundTransparency = 1
            nm.Text = plr.DisplayName
            nm.TextColor3 = Color3.fromRGB(240, 245, 255)
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.ZIndex = 83
            nm.Parent = row
            local un = Instance.new("TextLabel")
            un.Position = UDim2.fromOffset(48, 24)
            un.Size = UDim2.new(1, -110, 0, 14)
            un.BackgroundTransparency = 1
            un.Text = "@" .. plr.Name
            un.TextColor3 = Color3.fromRGB(140, 150, 170)
            un.Font = Enum.Font.Code
            un.TextSize = 10
            un.TextXAlignment = Enum.TextXAlignment.Left
            un.ZIndex = 83
            un.Parent = row
            local tpb = Instance.new("TextButton")
            tpb.Size = UDim2.fromOffset(48, 28)
            tpb.Position = UDim2.new(1, -56, 0.5, -14)
            tpb.BackgroundColor3 = Theme.Accent
            tpb.Text = "TP"
            tpb.TextColor3 = Color3.fromRGB(10, 12, 20)
            tpb.Font = Enum.Font.GothamBold
            tpb.TextSize = 11
            tpb.ZIndex = 83
            tpb.Parent = row
            Instance.new("UICorner", tpb).CornerRadius = UDim.new(0, 6)
            tpb.MouseButton1Click:Connect(function()
                local my = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local their = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if my and their then
                    my.CFrame = their.CFrame * CFrame.new(0, 0, 3)
                    notify("TP → " .. plr.DisplayName)
                else
                    notify("Target unavailable")
                end
            end)
        end
    end
    Features._TPGui = gui
    -- drag
    local dragging, start, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; start = input.Position; startPos = gui.Position
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - start
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

function Features.TPNearest()
    local my = getRoot(LocalPlayer.Character)
    if not my then return end
    local best, bd = nil, 9999
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local r = getRoot(getChar(p))
            if r then
                local d = (my.Position - r.Position).Magnitude
                if d < bd then bd = d; best = r end
            end
        end
    end
    if best then my.CFrame = best.CFrame * CFrame.new(0, 0, 3) end
end

function Features.TPAllFront()
    local my = getRoot(LocalPlayer.Character)
    if not my then return end
    local front = my.CFrame * CFrame.new(0, 0, -10)
    local i = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local r = getRoot(getChar(p))
            if r then
                i = i + 1
                pcall(function() r.CFrame = front * CFrame.new((i % 4) * 3 - 4, 0, math.floor(i / 4) * 3) end)
            end
        end
    end
end

local function aimPart(char)
    if State.BodyAim then return getRoot(char) or getHead(char) end
    return getHead(char) or getRoot(char)
end

local function bestTarget()
    local best, score = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local camPos = Camera.CFrame.Position
    local fov = State.FOV or 180
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and teamOK(p) then
            local char = getChar(p)
            if alive(char) then
                local part = aimPart(char)
                if part and dist(part.Position) <= (State.AimDist or 800) then
                    local screen, on = w2s(part.Position)
                    if on then
                        local cross = (screen - center).Magnitude
                        if cross <= fov then
                            if not (State.VisCheck and not visible(camPos, part.Position, char)) then
                                if cross < score then score = cross; best = p end
                            end
                        end
                    end
                end
            end
        end
    end
    if State.AimNPC then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
                if hum and head and hum.Health > 0 then
                    local screen, on = w2s(head.Position)
                    if on then
                        local cross = (screen - center).Magnitude
                        if cross <= fov and cross < score and dist(head.Position) <= (State.AimDist or 800) then
                            score = cross
                            best = { NPC = true, Part = head }
                        end
                    end
                end
            end
        end
    end
    return best
end

local function doAim()
    if not State.AimEnabled and not State.FlyKillAll then
        if FeatDrawings.FOV then FeatDrawings.FOV.Visible = false end
        return
    end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    if State.FOVCircle and State.AimEnabled and DrawingLib then
        if not FeatDrawings.FOV then
            local f = Drawing.new("Circle")
            f.Thickness = 2.5; f.NumSides = 64; f.Filled = false
            f.Color = Theme.Accent; f.Transparency = 0.35
            FeatDrawings.FOV = f
        end
        FeatDrawings.FOV.Position = center
        FeatDrawings.FOV.Radius = State.FOV or 180
        FeatDrawings.FOV.Color = Theme.Accent
        FeatDrawings.FOV.Visible = true
    elseif FeatDrawings.FOV then
        FeatDrawings.FOV.Visible = false
    end
    if not State.AimEnabled then return end
    local target = (State.AimLock and LockedTarget) or bestTarget()
    if State.AimLock and not LockedTarget and target then LockedTarget = target end
    if not State.AimLock then LockedTarget = nil end
    if not target then return end
    local part
    if type(target) == "table" and target.NPC then part = target.Part
    else
        local char = getChar(target)
        if not alive(char) then return end
        part = aimPart(char)
        if State.VisCheck and not visible(Camera.CFrame.Position, part.Position, char) then return end
    end
    if not part then return end
    local smooth = (State.Smooth or 15) / 100
    if State.SilentAim then smooth = 0.85 end
    if State.AntiMiss then smooth = math.clamp(smooth + 0.2, 0.1, 0.9) end
    if State.ModernAim then
        smooth = math.clamp(smooth * 0.85, 0.08, 0.7)
        -- light velocity prediction
        if part.Parent then
            local hrp = part.Parent:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.AssemblyLinearVelocity then
                local pred = part.Position + hrp.AssemblyLinearVelocity * 0.12
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pred), smooth)
                if FeatDrawings.FOV then
                    FeatDrawings.FOV.Radius = (State.FOV or 180) * (1 + 0.06 * math.sin(tick() * 6))
                end
                return
            end
        end
    end
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), smooth)
end

local function destroyESP(id)
    local pack = FeatDrawings.ESP[id]
    if not pack then return end
    for k, d in pairs(pack) do
        if k == "Skel" or k == "Corners" then
            if type(d) == "table" then for _, l in ipairs(d) do pcall(function() if l.Remove then l:Remove() end end) end end
        else pcall(function() if d and d.Remove then d:Remove() end end) end
    end
    FeatDrawings.ESP[id] = nil
end

local function doESP()
    if not DrawingLib then return end
    local aliveIds = {}
    if not State.ESPEnabled then
        for id in pairs(FeatDrawings.ESP) do destroyESP(id) end
        return
    end
    local bottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local org = State.TracerOrigin or "Bottom"
    local origin = bottom
    local vp = Camera.ViewportSize
    if org == "Center" then origin = Vector2.new(vp.X/2, vp.Y/2)
    elseif org == "Top" then origin = Vector2.new(vp.X/2, 8)
    elseif org == "Left" then origin = Vector2.new(8, vp.Y/2)
    elseif org == "Right" then origin = Vector2.new(vp.X-8, vp.Y/2)
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        aliveIds[p.UserId] = true
        local char = getChar(p)
        if not alive(char) then destroyESP(p.UserId) continue end
        local root, head = getRoot(char), getHead(char)
        if not root or not head then destroyESP(p.UserId) continue end
        local d = dist(root.Position)
        if d > (State.ESPMaxDist or 1000) then destroyESP(p.UserId) continue end
        local pack = FeatDrawings.ESP[p.UserId]
        if not pack then
            pack = {
                Box = Drawing.new("Square"), Name = Drawing.new("Text"),
                Health = Drawing.new("Line"), Dist = Drawing.new("Text"),
                Tracer = Drawing.new("Line"), Skel = {},
            }
            pack.Box.Thickness = 1.4; pack.Box.Filled = false
            pack.Name.Size = 12; pack.Name.Center = true; pack.Name.Outline = true
            pack.Health.Thickness = 2
            pack.Dist.Size = 11; pack.Dist.Center = true; pack.Dist.Outline = true
            pack.Tracer.Thickness = 1.2
            for i = 1, 12 do local l = Drawing.new("Line"); l.Thickness = 1.1; pack.Skel[i] = l end
            FeatDrawings.ESP[p.UserId] = pack
        end
        local topS, on = w2s(head.Position + Vector3.new(0, 0.4, 0))
        local botS = select(1, w2s(root.Position - Vector3.new(0, 3, 0)))
        local rootS = select(1, w2s(root.Position))
        local col = Color3.fromHSV(
            math.clamp(State.ESPHue or 0.55, 0, 1),
            math.clamp(State.ESPSat or 0.9, 0, 1),
            math.clamp(State.ESPVal or 1, 0.2, 1)
        )
        if State.ESPBox then
            local h = math.max(math.abs(topS.Y - botS.Y), 14)
            local w = h * 0.68
            local px, py = topS.X - w * 0.5, topS.Y
            if State.ModernESP then
                -- corner-style: hide full box, use tracer thickness as cue
                pack.Box.Visible = false
                if not pack.Corners then
                    pack.Corners = {}
                    for i = 1, 8 do
                        local ln = Drawing.new("Line")
                        ln.Thickness = 2
                        pack.Corners[i] = ln
                    end
                end
                local len = math.clamp(w * 0.28, 6, 18)
                local pts = {
                    {Vector2.new(px, py), Vector2.new(px + len, py)},
                    {Vector2.new(px, py), Vector2.new(px, py + len)},
                    {Vector2.new(px + w, py), Vector2.new(px + w - len, py)},
                    {Vector2.new(px + w, py), Vector2.new(px + w, py + len)},
                    {Vector2.new(px, py + h), Vector2.new(px + len, py + h)},
                    {Vector2.new(px, py + h), Vector2.new(px, py + h - len)},
                    {Vector2.new(px + w, py + h), Vector2.new(px + w - len, py + h)},
                    {Vector2.new(px + w, py + h), Vector2.new(px + w, py + h - len)},
                }
                for i, seg in ipairs(pts) do
                    pack.Corners[i].From = seg[1]
                    pack.Corners[i].To = seg[2]
                    pack.Corners[i].Color = col
                    pack.Corners[i].Visible = on
                end
            else
                if pack.Corners then for _, ln in ipairs(pack.Corners) do ln.Visible = false end end
                pack.Box.Size = Vector2.new(w, h)
                pack.Box.Position = Vector2.new(px, py)
                pack.Box.Color = col; pack.Box.Visible = on
            end
        else
            pack.Box.Visible = false
            if pack.Corners then for _, ln in ipairs(pack.Corners) do ln.Visible = false end end
        end
        if State.ESPName then
            pack.Name.Text = p.DisplayName or p.Name
            pack.Name.Position = Vector2.new(topS.X, topS.Y - 14)
            pack.Name.Color = col; pack.Name.Visible = on
        else pack.Name.Visible = false end
        if State.ESPDist then
            pack.Dist.Text = string.format("[%dm]", math.floor(d))
            pack.Dist.Position = Vector2.new(botS.X, botS.Y + 2)
            pack.Dist.Color = Theme.Muted; pack.Dist.Visible = on
        else pack.Dist.Visible = false end
        if State.ESPTracer then
            pack.Tracer.From = origin; pack.Tracer.To = rootS
            pack.Tracer.Color = Theme.Accent2; pack.Tracer.Visible = on
        else pack.Tracer.Visible = false end
        if State.ESPHealth then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local h = math.max(math.abs(topS.Y - botS.Y), 14)
                local x = topS.X - h * 0.34 - 5
                pack.Health.From = Vector2.new(x, topS.Y + h)
                pack.Health.To = Vector2.new(x, topS.Y + h * (1 - pct))
                pack.Health.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 40)
                pack.Health.Visible = on
            end
        else pack.Health.Visible = false end
        -- skeleton simple
        if State.ESPSkeleton then
            local pairs_ = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},{"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
            local idx = 1
            for _, pr in ipairs(pairs_) do
                if idx > #pack.Skel then break end
                local a, b = char:FindFirstChild(pr[1]), char:FindFirstChild(pr[2])
                if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                    local sa, oa = w2s(a.Position); local sb, ob = w2s(b.Position)
                    if oa and ob then
                        pack.Skel[idx].From = sa; pack.Skel[idx].To = sb
                        pack.Skel[idx].Color = col; pack.Skel[idx].Visible = true
                        idx = idx + 1
                    end
                end
            end
            for i = idx, #pack.Skel do pack.Skel[i].Visible = false end
        else
            for _, l in ipairs(pack.Skel) do l.Visible = false end
        end
    end
    for id in pairs(FeatDrawings.ESP) do
        if not aliveIds[id] then destroyESP(id) end
    end
end

local LastFly, LastSpeed, LastNoclip, LastJump, LastGhost, LastSky = false, false, false, false, false, false
featConn(RunService.RenderStepped:Connect(function()
    if State.Destroyed then return end
    Camera = Workspace.CurrentCamera
    -- side-effect sync from UI toggles
    if State.Fly ~= LastFly then LastFly = State.Fly; Features.SetFly(State.Fly) end
    if State.SpeedHack ~= LastSpeed then LastSpeed = State.SpeedHack; Features.SetSpeed(State.SpeedHack) end
    if State.Noclip ~= LastNoclip then LastNoclip = State.Noclip; Features.SetNoclip(State.Noclip) end
    if State.InfJump ~= LastJump then LastJump = State.InfJump; Features.SetInfJump(State.InfJump) end
    if State.GhostMode ~= LastGhost then LastGhost = State.GhostMode; Features.SetGhost(State.GhostMode) end
    if State.SkyHack ~= LastSky then LastSky = State.SkyHack; Features.SetSky(State.SkyHack) end
    if not State.Hitbox then Features.ClearHitbox() end
    if not State.SelfTag then Features.ClearSelfTag() end
    doAim()
    doESP()
    -- fly control
    if State.Fly and FlyBV and FlyBG then
        local cf = Camera.CFrame
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end
        FlyBV.Velocity = move.Magnitude > 0.1 and move.Unit * (State.FlySpeed or 45) or Vector3.zero
        FlyBG.CFrame = cf
    end
    -- speed reapply
    if State.SpeedHack then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed < (State.SpeedValue or 28) - 1 then
            hum.WalkSpeed = math.clamp(State.SpeedValue, 16, 100)
        end
    end
    -- god
    if State.GodMode then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end
    -- spin
    if State.SpinBot then
        local root = getRoot(LocalPlayer.Character)
        if root then
            SpinAng = (SpinAng + (State.SpinSpeed or 40) * 0.05) % 360
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(SpinAng), 0)
        end
    end
    -- hitbox
    if State.Hitbox then
        local size = math.clamp(State.HitboxSize or 8, 2, 27)
        local useHead = State.HitboxHead == true
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = getChar(p)
            if not alive(char) then continue end
            local head, root = getHead(char), getRoot(char)
            if not HitboxOrig[p.UserId] then
                HitboxOrig[p.UserId] = {}
                if head then HitboxOrig[p.UserId].Head = head.Size; HitboxOrig[p.UserId].HeadT = head.Transparency end
                if root then HitboxOrig[p.UserId].HRP = root.Size; HitboxOrig[p.UserId].HRPT = root.Transparency end
            end
            if useHead and head then
                pcall(function() head.Size = Vector3.new(size,size,size); head.Transparency = 0.4; head.CanCollide = false end)
            elseif root then
                pcall(function() root.Size = Vector3.new(size,size,size); root.Transparency = 0.5; root.CanCollide = false end)
            end
        end
    end
    -- freeze
    if State.FreezeOthers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local r = getRoot(getChar(p))
                if r then pcall(function() r.Anchored = true end) end
            end
        end
    end
    -- self tag
    if State.SelfTag then
        local head = getHead(LocalPlayer.Character)
        if head then
            if not SelfTagGui or not SelfTagGui.Parent then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.fromOffset(180, 36); bb.StudsOffset = Vector3.new(0, 2.4, 0)
                bb.AlwaysOnTop = true; bb.Parent = head
                local tl = Instance.new("TextLabel")
                tl.Name = "T"; tl.Size = UDim2.fromScale(1,1); tl.BackgroundTransparency = 1
                tl.Font = Enum.Font.GothamBlack; tl.TextScaled = true; tl.TextStrokeTransparency = 0.4
                tl.Parent = bb
                SelfTagGui = bb
            end
            local tl = SelfTagGui:FindFirstChild("T")
            if tl then
                tl.Text = State.SelfTagText or "BAXTARA"
                if State.SelfTagRainbow then
                    tl.TextColor3 = Color3.fromHSV((tick() * 0.35) % 1, 1, 1)
                else
                    tl.TextColor3 = Color3.fromRGB(255, 215, 0)
                end
            end
        end
    end
    -- fly kill all
    if State.FlyKillAll then
        local root = getRoot(LocalPlayer.Character)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if root and hum then
            hum.PlatformStand = true
            if not FlyBV then Features.SetFly(true) end
            if root.Position.Y < 70 and FlyBV then FlyBV.Velocity = Vector3.new(0, 40, 0)
            elseif FlyBV then FlyBV.Velocity = Vector3.zero end
            local front = root.CFrame * CFrame.new(0, 0, -12)
            local i = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and teamOK(p) then
                    local er = getRoot(getChar(p))
                    if er and alive(getChar(p)) then
                        i = i + 1
                        pcall(function() er.CFrame = front * CFrame.new((i % 4) * 3 - 4.5, 0, 0) end)
                    end
                end
            end
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end
    -- weapon patch
    if State.AntiCD or State.InfAmmo then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n = v.Name:lower()
                    if State.AntiCD and (n:find("cool") or n:find("delay") or n:find("rate")) then pcall(function() v.Value = 0 end) end
                    if State.InfAmmo and (n:find("ammo") or n:find("clip") or n:find("mag")) then pcall(function() v.Value = 999 end) end
                end
            end
        end
    end
    if State.AntiLag then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end
end))

-- sync feature toggles when UI toggles change via State keys that need side effects
-- (Fly/Speed etc. applied on next frame check if needed)

print("[BAXTARA X CHEAT] v7.1 Four Worlds UI + Aim/ESP/Brutal/Local | BX or RightControl")

