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
local GUI_NAME = "BAXTARA_X_FOUR_WORLDS_V7"
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
}

local Theme = Themes[State.Theme]
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
    { Name = "PROFILE", Icon = "◉" },
    { Name = "APPEARANCE", Icon = "◈" },
    { Name = "VISUAL LAB", Icon = "✦" },
    { Name = "PREFERENCES", Icon = "⚙" },
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

local PageRenderers = {
    OVERVIEW = pageOverview,
    PROFILE = pageProfile,
    APPEARANCE = pageAppearance,
    ["VISUAL LAB"] = pageVisualLab,
    PREFERENCES = pagePreferences,
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

renderUI()

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

print("[BAXTARA] Four Worlds UI v7.1 loaded. Local interface only. Use BX launcher or RightControl.")
