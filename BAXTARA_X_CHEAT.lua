--[[
    BAXTARA X CHEAT — FOUR WORLDS UI REDESIGN
    Version: 6.0 UI-only redesign

    Install: Roblox Studio > StarterPlayer > StarterPlayerScripts > LocalScript
    This file builds a local interface only. It does not modify gameplay,
    characters, other players, RemoteEvents, hitboxes, weapons, server state,
    anti-cheat, bans, kicks, or moderation behavior.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[BAXTARA] LocalPlayer is unavailable. Run this as a LocalScript.")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GUI_NAME = "BAXTARA_FOUR_WORLDS_UI"

local previous = PlayerGui:FindFirstChild(GUI_NAME)
if previous then
    previous:Destroy()
end

local Themes = {
    Galaxy = {
        Name = "GALAXY / ORBITAL",
        Background = Color3.fromRGB(5, 7, 19),
        Surface = Color3.fromRGB(11, 15, 34),
        Card = Color3.fromRGB(16, 22, 46),
        Raised = Color3.fromRGB(23, 31, 62),
        Element = Color3.fromRGB(30, 38, 75),
        Text = Color3.fromRGB(239, 243, 255),
        Muted = Color3.fromRGB(139, 153, 190),
        Accent = Color3.fromRGB(153, 100, 255),
        Accent2 = Color3.fromRGB(61, 205, 255),
        Border = Color3.fromRGB(111, 83, 197),
        Off = Color3.fromRGB(52, 59, 91),
        Danger = Color3.fromRGB(255, 100, 132),
        Radius = 18,
        Style = "Galaxy",
    },
    Lego = {
        Name = "LEGO / BRICKWORK",
        Background = Color3.fromRGB(26, 32, 45),
        Surface = Color3.fromRGB(39, 49, 66),
        Card = Color3.fromRGB(55, 68, 88),
        Raised = Color3.fromRGB(71, 86, 109),
        Element = Color3.fromRGB(88, 105, 130),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(205, 212, 223),
        Accent = Color3.fromRGB(255, 196, 37),
        Accent2 = Color3.fromRGB(44, 139, 255),
        Border = Color3.fromRGB(255, 174, 34),
        Off = Color3.fromRGB(77, 88, 107),
        Danger = Color3.fromRGB(255, 91, 83),
        Radius = 5,
        Style = "Lego",
    },
    Modern = {
        Name = "MODERN / STUDIO",
        Background = Color3.fromRGB(13, 17, 24),
        Surface = Color3.fromRGB(19, 25, 34),
        Card = Color3.fromRGB(24, 31, 42),
        Raised = Color3.fromRGB(31, 40, 53),
        Element = Color3.fromRGB(39, 49, 64),
        Text = Color3.fromRGB(242, 245, 250),
        Muted = Color3.fromRGB(151, 163, 180),
        Accent = Color3.fromRGB(95, 178, 255),
        Accent2 = Color3.fromRGB(111, 226, 207),
        Border = Color3.fromRGB(69, 90, 116),
        Off = Color3.fromRGB(59, 70, 85),
        Danger = Color3.fromRGB(255, 112, 119),
        Radius = 13,
        Style = "Modern",
    },
    Eid = {
        Name = "IDUL FITRI / SERENITY",
        Background = Color3.fromRGB(7, 27, 22),
        Surface = Color3.fromRGB(12, 43, 34),
        Card = Color3.fromRGB(17, 57, 44),
        Raised = Color3.fromRGB(24, 72, 54),
        Element = Color3.fromRGB(31, 86, 64),
        Text = Color3.fromRGB(255, 249, 230),
        Muted = Color3.fromRGB(190, 199, 164),
        Accent = Color3.fromRGB(225, 190, 104),
        Accent2 = Color3.fromRGB(92, 175, 119),
        Border = Color3.fromRGB(191, 151, 76),
        Off = Color3.fromRGB(55, 83, 67),
        Danger = Color3.fromRGB(225, 106, 91),
        Radius = 15,
        Style = "Eid",
    },
}

local State = {
    Theme = "Galaxy",
    SelectedPage = "OVERVIEW",
    Ambient = true,
    StarParticles = true,
    OrbitMotion = true,
    KetupatMotion = true,
    ReduceMotion = false,
    CompactCards = false,
    Glow = 0.72,
    AnimationSpeed = 1.0,
    PanelVisible = true,
    Destroyed = false,
}

local Theme = Themes[State.Theme]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 50
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main, FloatingButton, ToastLayer
local Content, PageTitle, PageSubtitle
local FpsValue, PlayerValue, SessionValue
local OrbitNodes = {}
local StarNodes = {}
local HeaderKetupatNodes = {}
local PageKetupatNodes = {}
local ActiveSlider = nil
local renderUI, renderPage, bindHeaderDrag
local Dragging = false
local DragInputPosition = nil
local DragStartPosition = nil
local LastStatsRefresh = 0
local FrameCounter = 0
local FPS = 0
local SessionStart = os.clock()
local IntroPlayed = false

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

ToastLayer = make("Frame", {
    Name = "ToastLayer",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 100,
}, ScreenGui)

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radius) }, parent)
end

local function outline(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency == nil and 0.35 or transparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function addGradient(parent, first, second, rotation)
    return make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, first),
            ColorSequenceKeypoint.new(1, second),
        }),
        Rotation = rotation or 0,
    }, parent)
end

local function text(parent, value, size, color, font, position, dimensions, alignment)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = value or "",
        TextColor3 = color or Theme.Text,
        TextSize = size or 13,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        Position = position or UDim2.new(),
        Size = dimensions or UDim2.new(1, 0, 0, 22),
        ZIndex = (parent.ZIndex or 1) + 1,
    }, parent)
end

local function tween(object, duration, properties, style, direction)
    if not object or not object.Parent or State.ReduceMotion then
        if object and object.Parent then
            for property, value in pairs(properties) do
                object[property] = value
            end
        end
        return nil
    end
    local animation = TweenService:Create(object, TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    ), properties)
    animation:Play()
    return animation
end

local function showNotice(message, tint)
    if State.Destroyed or not ToastLayer then return end
    local toast = make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 24, 0, 18),
        Size = UDim2.fromOffset(250, 50),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, ToastLayer)
    corner(toast, Theme.Style == "Lego" and 5 or 13)
    outline(toast, tint or Theme.Accent, Theme.Style == "Lego" and 2 or 1, 0.18)
    local stripe = make("Frame", {
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(0, 3, 1, -16),
        BackgroundColor3 = tint or Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 101,
    }, toast)
    corner(stripe, 4)
    text(toast, "BAXTARA NOTICE", 9, tint or Theme.Accent, Enum.Font.GothamBold,
        UDim2.fromOffset(13, 5), UDim2.new(1, -22, 0, 14))
    text(toast, message, 11, Theme.Text, Enum.Font.GothamMedium,
        UDim2.fromOffset(13, 20), UDim2.new(1, -22, 0, 22))
    tween(toast, 0.28, { Position = UDim2.new(1, -14, 0, 18) }, Enum.EasingStyle.Back)
    task.delay(2.2, function()
        if toast and toast.Parent then
            tween(toast, 0.18, { Position = UDim2.new(1, 24, 0, 18) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.22, function()
                if toast and toast.Parent then toast:Destroy() end
            end)
        end
    end)
end

local function addPageHeading(parent, heading, description)
    text(parent, heading, 19, Theme.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, 28))
    text(parent, description, 11, Theme.Muted, Enum.Font.Gotham,
        UDim2.fromOffset(4, 28), UDim2.new(1, -8, 0, 30))
    make("Frame", {
        Position = UDim2.fromOffset(4, 62),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
    }, parent)
end

local function addCard(parent, titleText, subText, height, layoutOrder)
    local card = make("Frame", {
        Size = UDim2.new(1, -8, 0, height or 110),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 1,
        ZIndex = 4,
    }, parent)
    corner(card, Theme.Style == "Lego" and 5 or Theme.Radius)
    outline(card, Theme.Border, Theme.Style == "Lego" and 2 or 1, Theme.Style == "Modern" and 0.72 or 0.42)
    if Theme.Style == "Lego" then
        local cap = make("Frame", {
            Position = UDim2.fromOffset(9, 0),
            Size = UDim2.new(1, -18, 0, 5),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, card)
        corner(cap, 3)
    elseif Theme.Style == "Eid" then
        make("Frame", {
            Position = UDim2.fromOffset(12, 11),
            Size = UDim2.fromOffset(3, math.max(20, (height or 110) - 22)),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, card)
    elseif Theme.Style == "Modern" then
        make("Frame", {
            Position = UDim2.fromOffset(15, 14),
            Size = UDim2.fromOffset(28, 3),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, card)
    end
    local titleY = Theme.Style == "Modern" and 25 or 12
    local subY = titleY + 19
    text(card, titleText or "SECTION", 11, Theme.Accent, Enum.Font.GothamBold,
        UDim2.fromOffset(15, titleY), UDim2.new(1, -30, 0, 17))
    if subText and subText ~= "" then
        text(card, subText, 9, Theme.Muted, Enum.Font.Gotham,
            UDim2.fromOffset(15, subY), UDim2.new(1, -30, 0, 16))
    end
    return card
end

local function addButton(parent, titleText, position, size, callback, variant)
    variant = variant or "primary"
    local style = Theme.Style
    local buttonHost = make("Frame", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        ZIndex = 8,
    }, parent)

    if style == "Lego" then
        local shadow = make("Frame", {
            Position = UDim2.fromOffset(0, 4),
            Size = UDim2.new(1, 0, 1, -2),
            BackgroundColor3 = Color3.fromRGB(24, 33, 48),
            BorderSizePixel = 0,
            ZIndex = 8,
        }, buttonHost)
        corner(shadow, 5)
    end

    local face = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = variant == "secondary" and Theme.Element or Theme.Raised,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, buttonHost)
    corner(face, style == "Lego" and 5 or (style == "Galaxy" and 18 or (style == "Modern" and 10 or 13)))
    outline(face, variant == "danger" and Theme.Danger or Theme.Border,
        style == "Lego" and 2 or 1, style == "Modern" and 0.72 or 0.30)

    if style == "Galaxy" then
        addGradient(face, Theme.Raised, Theme.Surface, 25)
        local dot = make("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = Theme.Accent2,
            BorderSizePixel = 0,
            ZIndex = 11,
        }, face)
        corner(dot, 99)
    elseif style == "Lego" then
        local stud = make("Frame", {
            Position = UDim2.fromOffset(9, 5),
            Size = UDim2.fromOffset(8, 6),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 11,
        }, face)
        corner(stud, 3)
    elseif style == "Modern" then
        make("Frame", {
            Position = UDim2.fromOffset(0, 8),
            Size = UDim2.new(0, 3, 1, -16),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 11,
        }, face)
    elseif style == "Eid" then
        text(face, "◆", 9, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(1, -27, 0, 0), UDim2.fromOffset(18, size.Y.Offset), Enum.TextXAlignment.Center)
    end

    local leftPad = style == "Modern" and 17 or (style == "Lego" and 22 or 13)
    text(face, titleText, style == "Lego" and 11 or 10,
        variant == "danger" and Theme.Danger or Theme.Text,
        style == "Lego" and Enum.Font.GothamBlack or Enum.Font.GothamSemibold,
        UDim2.fromOffset(leftPad, 0), UDim2.new(1, -leftPad - 34, 1, 0))

    face.Activated:Connect(function()
        if style == "Lego" then
            tween(face, 0.07, { Position = UDim2.fromOffset(0, 3) }, Enum.EasingStyle.Quad)
            task.delay(0.09, function()
                if face and face.Parent then tween(face, 0.12, { Position = UDim2.new() }, Enum.EasingStyle.Back) end
            end)
        else
            tween(face, 0.08, { BackgroundColor3 = Theme.Accent }, Enum.EasingStyle.Quad)
            task.delay(0.10, function()
                if face and face.Parent then
                    tween(face, 0.18, { BackgroundColor3 = variant == "secondary" and Theme.Element or Theme.Raised })
                end
            end)
        end
        if callback then callback() end
    end)
    return buttonHost
end

local function addToggle(parent, titleText, description, key, y)
    local rowHeight = State.CompactCards and 45 or 55
    local row = make("Frame", {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, rowHeight),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, parent)
    corner(row, Theme.Style == "Lego" and 4 or 10)
    text(row, titleText, 10, Theme.Text, Enum.Font.GothamSemibold,
        UDim2.fromOffset(10, 5), UDim2.new(1, -75, 0, 16))
    if description then
        text(row, description, 8, Theme.Muted, Enum.Font.Gotham,
            UDim2.fromOffset(10, 22), UDim2.new(1, -78, 0, 14))
    end
    local track = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = State[key] and Theme.Accent or Theme.Off,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, row)
    corner(track, Theme.Style == "Lego" and 4 or 15)
    local knob = make("Frame", {
        Position = State[key] and UDim2.new(1, -19, 0.5, -7) or UDim2.new(0, 5, 0.5, -7),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, track)
    corner(knob, Theme.Style == "Lego" and 3 or 99)
    local hit = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 11,
    }, track)
    hit.Activated:Connect(function()
        State[key] = not State[key]
        tween(track, 0.16, { BackgroundColor3 = State[key] and Theme.Accent or Theme.Off })
        tween(knob, 0.18, {
            Position = State[key] and UDim2.new(1, -19, 0.5, -7) or UDim2.new(0, 5, 0.5, -7),
        }, Enum.EasingStyle.Back)
        showNotice(titleText .. (State[key] and " ON" or " OFF"))
        if key == "CompactCards" then
            task.defer(function() if not State.Destroyed then renderUI() end end)
        end
    end)
    return row
end

local function addSlider(parent, titleText, description, key, minimum, maximum, y)
    local row = make("Frame", {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 67),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, parent)
    corner(row, Theme.Style == "Lego" and 4 or 10)
    text(row, titleText, 10, Theme.Text, Enum.Font.GothamSemibold,
        UDim2.fromOffset(10, 5), UDim2.new(0.68, 0, 0, 16))
    local valueLabel = text(row, string.format("%.2f", State[key]), 9, Theme.Accent,
        Enum.Font.GothamBold, UDim2.new(0.70, 0, 0, 5), UDim2.new(0.27, -8, 0, 16), Enum.TextXAlignment.Right)
    text(row, description or "", 8, Theme.Muted, Enum.Font.Gotham,
        UDim2.fromOffset(10, 22), UDim2.new(1, -20, 0, 12))
    local bar = make("Frame", {
        Position = UDim2.new(0, 10, 0, 46),
        Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, row)
    corner(bar, 6)
    local ratio = math.clamp((State[key] - minimum) / (maximum - minimum), 0, 1)
    local fill = make("Frame", {
        Size = UDim2.new(ratio, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, bar)
    corner(fill, 6)
    local function update(x)
        local relative = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local value = minimum + (maximum - minimum) * relative
        State[key] = value
        fill.Size = UDim2.new(relative, 0, 1, 0)
        valueLabel.Text = string.format("%.2f", value)
    end
    local hit = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, -9),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10,
    }, bar)
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            ActiveSlider = { Bar = bar, Update = update }
            update(input.Position.X)
        end
    end)
    return row
end

local function clearContent()
    table.clear(OrbitNodes)
    table.clear(PageKetupatNodes)
    for _, child in ipairs(Content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    Content.CanvasPosition = Vector2.zero
end

local function createListContent()
    local layout = make("UIListLayout", {
        Padding = UDim.new(0, State.CompactCards and 7 or 11),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Content)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3),
    }, Content)
    return layout
end

local function makeOrbitArt(parent, compact)
    local art = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -18, 0.54, 0),
        Size = UDim2.fromOffset(compact and 100 or 145, compact and 100 or 145),
        ZIndex = 8,
    }, parent)
    local ringA = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.98, 0.48),
        Rotation = -28,
        BackgroundTransparency = 1,
        ZIndex = 8,
    }, art)
    corner(ringA, 999)
    outline(ringA, Theme.Accent2, 1.4, 0.20)
    local ringB = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.76, 0.94),
        Rotation = 48,
        BackgroundTransparency = 1,
        ZIndex = 8,
    }, art)
    corner(ringB, 999)
    outline(ringB, Theme.Accent, 1.1, 0.28)
    local core = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(compact and 34 or 48, compact and 34 or 48),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, art)
    corner(core, 999)
    addGradient(core, Theme.Accent2, Theme.Accent, 40)
    outline(core, Theme.Text, 1, 0.55)
    make("Frame", {
        Position = UDim2.new(0.18, 0, 0.22, 0),
        Size = UDim2.new(0.38, 0, 0.14, 0),
        BackgroundColor3 = Theme.Text,
        BackgroundTransparency = 0.66,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, core)
    local moon = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Theme.Accent2,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, art)
    corner(moon, 99)
    table.insert(OrbitNodes, { Root = art, Planet = moon, Phase = 0.8, Radius = 0.46 })
    return art
end

local function makeKetupat(parent, position, size, collection)
    local wrap = make("Frame", {
        BackgroundTransparency = 1,
        Position = position,
        Size = UDim2.fromOffset(size, size + 18),
        ZIndex = 9,
    }, parent)
    local stringLine = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(2, 12),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, wrap)
    local diamond = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, size * 0.57),
        Size = UDim2.fromOffset(size * 0.68, size * 0.68),
        Rotation = 45,
        BackgroundColor3 = Theme.Accent2,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, wrap)
    corner(diamond, 4)
    outline(diamond, Theme.Accent, 2, 0.10)
    addGradient(diamond, Color3.fromRGB(113, 190, 111), Color3.fromRGB(28, 103, 68), 45)
    local bandA = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.35),
        Size = UDim2.new(1.18, 0, 0, 3),
        Rotation = 0,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, diamond)
    local bandB = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.65),
        Size = UDim2.new(1.18, 0, 0, 3),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, diamond)
    local cross = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 3, 1.12, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, diamond)
    table.insert(collection or PageKetupatNodes, wrap)
    return wrap
end

local function buildThemeDecor(header, panel, mobile)
    OrbitNodes = {}
    StarNodes = {}
    HeaderKetupatNodes = {}
    PageKetupatNodes = {}

    if Theme.Style == "Galaxy" then
        local strip = make("Frame", {
            Position = UDim2.new(0, 0, 1, -3),
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 15,
        }, header)
        addGradient(strip, Theme.Accent, Theme.Accent2, 0)
        for index = 1, 18 do
            local star = make("Frame", {
                Position = UDim2.new(math.random(5, 95) / 100, 0, math.random(10, 90) / 100, 0),
                Size = UDim2.fromOffset(math.random(2, 3), math.random(2, 3)),
                BackgroundColor3 = Theme.Text,
                BackgroundTransparency = math.random(15, 50) / 100,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, panel)
            corner(star, 99)
            table.insert(StarNodes, { Object = star, Phase = math.random() * 6.28 })
        end
    elseif Theme.Style == "Lego" then
        local studStrip = make("Frame", {
            Position = UDim2.new(0, 14, 1, -13),
            Size = UDim2.new(1, -28, 0, 10),
            BackgroundColor3 = Color3.fromRGB(207, 52, 47),
            BorderSizePixel = 0,
            ZIndex = 15,
        }, header)
        corner(studStrip, 2)
        local count = 12
        for index = 1, count do
            local stud = make("Frame", {
                Position = UDim2.new((index - 1) / count, 4, 0, 1),
                Size = UDim2.fromOffset(12, 8),
                BackgroundColor3 = Color3.fromRGB(255, 213, 73),
                BorderSizePixel = 0,
                ZIndex = 16,
            }, studStrip)
            corner(stud, 3)
            outline(stud, Color3.fromRGB(174, 127, 29), 1, 0.2)
        end
    elseif Theme.Style == "Eid" then
        local goldLine = make("Frame", {
            Position = UDim2.new(0, 0, 1, -3),
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 15,
        }, header)
        addGradient(goldLine, Theme.Accent2, Theme.Accent, 0)
        local crescent = text(header, "☾", 25, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(1, -124, 0, 11), UDim2.fromOffset(35, 35), Enum.TextXAlignment.Center)
        crescent.Name = "EidCrescent"
        if not mobile then
            makeKetupat(header, UDim2.new(1, -78, 0, -1), 28, HeaderKetupatNodes)
            makeKetupat(header, UDim2.new(1, -43, 0, 3), 22, HeaderKetupatNodes)
        end
    else
        local divider = make("Frame", {
            Position = UDim2.new(0, 18, 1, -2),
            Size = UDim2.new(1, -36, 0, 1),
            BackgroundColor3 = Theme.Border,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ZIndex = 15,
        }, header)
        addGradient(divider, Theme.Accent, Theme.Accent2, 0)
    end
end

local PageNames = {
    { Name = "OVERVIEW", Icon = "⌂", Description = "Workspace overview" },
    { Name = "PROFILE", Icon = "◉", Description = "Player profile" },
    { Name = "APPEARANCE", Icon = "◈", Description = "Four visual themes" },
    { Name = "VISUAL LAB", Icon = "✦", Description = "Local interface effects" },
    { Name = "PREFERENCES", Icon = "⚙", Description = "Panel preferences" },
    { Name = "ABOUT", Icon = "i", Description = "Project information" },
}

local function createStatCard(parent, titleText, initialText, order)
    local card = make("Frame", {
        Size = UDim2.new(1/3, -8, 1, 0),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 6,
    }, parent)
    corner(card, Theme.Style == "Lego" and 4 or 11)
    outline(card, Theme.Border, 1, 0.62)
    text(card, titleText, 8, Theme.Muted, Enum.Font.GothamBold,
        UDim2.fromOffset(9, 8), UDim2.new(1, -14, 0, 14))
    local value = text(card, initialText, 18, Theme.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(9, 25), UDim2.new(1, -14, 0, 25))
    return value
end

local function pageOverview()
    clearContent()
    createListContent()
    addPageHeading(Content, "COMMAND OVERVIEW", "A clean control room for your local BAXTARA interface.")

    local hero = addCard(Content, "BAXTARA / FOUR WORLDS", "One interface. Four distinct visual identities.", 154, 2)
    text(hero, "Choose a world. Shape the atmosphere.", 14, Theme.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(15, 58), UDim2.new(0.64, -12, 0, 25))
    text(hero, "Galaxy orbit • LEGO brickwork • Modern studio • Idul Fitri serenity",
        9, Theme.Muted, Enum.Font.Gotham, UDim2.fromOffset(15, 86), UDim2.new(0.64, -12, 0, 30))
    if Theme.Style == "Galaxy" then
        makeOrbitArt(hero, true)
    elseif Theme.Style == "Lego" then
        for index = 1, 5 do
            local brick = make("Frame", {
                Position = UDim2.fromOffset(175 + (index - 1) * 21, 99 - (index % 2) * 9),
                Size = UDim2.fromOffset(25, 20),
                BackgroundColor3 = ({Color3.fromRGB(224, 54, 48), Color3.fromRGB(255, 198, 40), Color3.fromRGB(38, 132, 232), Color3.fromRGB(52, 180, 103)})[(index - 1) % 4 + 1],
                BorderSizePixel = 0,
                ZIndex = 8,
            }, hero)
            corner(brick, 3)
            outline(brick, Color3.fromRGB(255, 255, 255), 1, 0.72)
            for studIndex = 1, 2 do
                local stud = make("Frame", {
                    Position = UDim2.fromOffset(4 + (studIndex - 1) * 11, -4),
                    Size = UDim2.fromOffset(7, 6),
                    BackgroundColor3 = brick.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.28),
                    BorderSizePixel = 0,
                    ZIndex = 9,
                }, brick)
                corner(stud, 3)
            end
        end
    elseif Theme.Style == "Eid" then
        text(hero, "☾", 38, Theme.Accent, Enum.Font.GothamBold,
            UDim2.new(1, -137, 0, 38), UDim2.fromOffset(48, 48), Enum.TextXAlignment.Center)
        makeKetupat(hero, UDim2.new(1, -84, 0, 44), 35, PageKetupatNodes)
    else
        local badge = make("Frame", {
            Position = UDim2.new(1, -122, 0, 48),
            Size = UDim2.fromOffset(94, 58),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 8,
        }, hero)
        corner(badge, 12)
        outline(badge, Theme.Border, 1, 0.4)
        text(badge, "BX", 25, Theme.Accent, Enum.Font.GothamBold,
            UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
    end

    local statRow = make("Frame", {
        Size = UDim2.new(1, -8, 0, 72),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        ZIndex = 5,
    }, Content)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, statRow)
    FpsValue = createStatCard(statRow, "CLIENT FPS", tostring(FPS), 1)
    PlayerValue = createStatCard(statRow, "PLAYERS HERE", tostring(#Players:GetPlayers()), 2)
    SessionValue = createStatCard(statRow, "SESSION", "00:00", 3)

    local launch = addCard(Content, "QUICK ACCESS", "Jump directly to the parts of the interface you use most.", 112, 4)
    addButton(launch, "CHANGE THEME", UDim2.fromOffset(12, 54), UDim2.new(0.48, -12, 0, 38), function()
        State.SelectedPage = "APPEARANCE"
        renderPage()
    end, "primary")
    addButton(launch, "VISUAL LAB", UDim2.new(0.52, 0, 0, 54), UDim2.new(0.48, -12, 0, 38), function()
        State.SelectedPage = "VISUAL LAB"
        renderPage()
    end, "secondary")
end

local function themeTile(parent, name, titleText, description, position)
    local palette = Themes[name]
    local tile = make("TextButton", {
        Position = position,
        Size = UDim2.new(0.49, -6, 0, 90),
        BackgroundColor3 = palette.Card,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, parent)
    corner(tile, name == "Lego" and 5 or (name == "Galaxy" and 18 or (name == "Modern" and 10 or 14)))
    outline(tile, palette.Border, name == "Lego" and 2 or 1, State.Theme == name and 0.05 or 0.56)
    local swatch = make("Frame", {
        Position = UDim2.fromOffset(10, 13),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, tile)
    corner(swatch, name == "Galaxy" and 99 or (name == "Lego" and 5 or 11))
    addGradient(swatch, palette.Accent, palette.Accent2, 35)
    if name == "Lego" then
        for i = 1, 2 do
            local stud = make("Frame", {
                Position = UDim2.fromOffset(6 + (i - 1) * 17, -4),
                Size = UDim2.fromOffset(12, 8),
                BackgroundColor3 = Color3.fromRGB(255, 224, 104),
                BorderSizePixel = 0,
                ZIndex = 10,
            }, swatch)
            corner(stud, 3)
        end
    elseif name == "Galaxy" then
        outline(swatch, palette.Text, 1, 0.32)
    elseif name == "Eid" then
        text(swatch, "◆", 19, palette.Text, Enum.Font.GothamBold,
            UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
    else
        make("Frame", {
            Position = UDim2.fromOffset(0, 33),
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = palette.Accent2,
            BorderSizePixel = 0,
            ZIndex = 10,
        }, swatch)
    end
    text(tile, titleText, 10, palette.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(60, 17), UDim2.new(1, -68, 0, 18))
    text(tile, description, 8, palette.Muted, Enum.Font.Gotham,
        UDim2.fromOffset(60, 38), UDim2.new(1, -68, 0, 30))
    if State.Theme == name then
        text(tile, "ACTIVE", 7, palette.Accent, Enum.Font.GothamBlack,
            UDim2.fromOffset(60, 68), UDim2.new(1, -68, 0, 12))
    end
    tile.Activated:Connect(function()
        State.Theme = name
        Theme = Themes[name]
        State.SelectedPage = "APPEARANCE"
        renderUI()
        showNotice(palette.Name .. " APPLIED", palette.Accent)
    end)
end

local function pageAppearance()
    clearContent()
    createListContent()
    addPageHeading(Content, "VISUAL WORLDS", "Every theme has its own geometry, navigation, materials and motion language.")
    local card = addCard(Content, "SELECT A DESIGN LANGUAGE", "Switching themes rebuilds the interface without resetting your preferences.", 258, 2)
    themeTile(card, "Galaxy", "GALAXY", "Orbital rings, planet nodes, nebula tones", UDim2.fromOffset(12, 59))
    themeTile(card, "Lego", "LEGO", "Raised bricks, studs, modular blocks", UDim2.new(0.51, 0, 0, 59))
    themeTile(card, "Modern", "MODERN", "Editorial spacing, subtle accents, clean surfaces", UDim2.fromOffset(12, 156))
    themeTile(card, "Eid", "IDUL FITRI", "Emerald, warm gold, crescent and ketupat", UDim2.new(0.51, 0, 0, 156))

    local details = addCard(Content, "DESIGN NOTES", "Theme-specific components, not just a recolor.", 122, 3)
    local notes = {
        Galaxy = "Planet-shaped navigation, orbital hero art, star field and restrained glow.",
        Lego = "Brick navigation, stud details, raised action keys and squared modular cards.",
        Modern = "Slim navigation rail, editorial hierarchy, understated borders and spacing.",
        Eid = "Emerald surfaces, gold trim, crescent ornament and layered ketupat geometry.",
    }
    text(details, notes[State.Theme], 10, Theme.Text, Enum.Font.Gotham,
        UDim2.fromOffset(15, 56), UDim2.new(1, -30, 0, 45))
end

local function pageProfile()
    clearContent()
    createListContent()
    addPageHeading(Content, "PLAYER PROFILE", "Identity and session details visible to this local client.")
    local card = addCard(Content, "CURRENT PLAYER", "Roblox profile snapshot", 154, 2)
    local avatar = make("ImageLabel", {
        Position = UDim2.fromOffset(15, 53),
        Size = UDim2.fromOffset(76, 76),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Image = "",
        ZIndex = 8,
    }, card)
    corner(avatar, Theme.Style == "Lego" and 5 or 18)
    outline(avatar, Theme.Accent, 1.4, 0.18)
    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and avatar and avatar.Parent then avatar.Image = image end
    end)
    text(card, LocalPlayer.DisplayName, 13, Theme.Text, Enum.Font.GothamBold,
        UDim2.fromOffset(105, 59), UDim2.new(1, -120, 0, 22))
    text(card, "@" .. LocalPlayer.Name, 9, Theme.Muted, Enum.Font.Code,
        UDim2.fromOffset(105, 83), UDim2.new(1, -120, 0, 18))
    text(card, "USER ID  " .. tostring(LocalPlayer.UserId), 8, Theme.Accent, Enum.Font.GothamBold,
        UDim2.fromOffset(105, 107), UDim2.new(1, -120, 0, 17))

    local info = addCard(Content, "SESSION INFORMATION", "Read-only local session information.", 115, 3)
    text(info, "Account age: " .. tostring(LocalPlayer.AccountAge) .. " days", 10, Theme.Text,
        Enum.Font.Gotham, UDim2.fromOffset(15, 56), UDim2.new(1, -30, 0, 18))
    text(info, "Players in this server: " .. tostring(#Players:GetPlayers()), 10, Theme.Text,
        Enum.Font.Gotham, UDim2.fromOffset(15, 80), UDim2.new(1, -30, 0, 18))
end

local function pageVisualLab()
    clearContent()
    createListContent()
    addPageHeading(Content, "LOCAL VISUAL LAB", "These controls affect this interface only. They do not change the game world.")
    local toggleCard = addCard(Content, "ATMOSPHERE", "Enable or disable decorative layers.", 300, 2)
    addToggle(toggleCard, "Ambient animation", "Subtle motion in decorative elements.", "Ambient", 55)
    addToggle(toggleCard, "Star particles", "Small decorative stars in Galaxy mode.", "StarParticles", 113)
    addToggle(toggleCard, "Orbit motion", "Move the small satellite around the planet.", "OrbitMotion", 171)
    addToggle(toggleCard, "Ketupat sway", "Gentle hanging ornament motion in Idul Fitri mode.", "KetupatMotion", 229)
    local sliders = addCard(Content, "MOTION TUNING", "Control the pace and intensity of UI animation.", 188, 3)
    addSlider(sliders, "Glow intensity", "Decorative highlight strength", "Glow", 0, 1, 54)
    addSlider(sliders, "Animation speed", "Animation multiplier", "AnimationSpeed", 0.25, 2, 111)
end

local function pagePreferences()
    clearContent()
    createListContent()
    addPageHeading(Content, "PREFERENCES", "Practical controls for comfort, readability and panel behavior.")
    local card = addCard(Content, "INTERFACE BEHAVIOR", "Changes apply immediately.", 180, 2)
    addToggle(card, "Reduce motion", "Stop continuous decorative animation.", "ReduceMotion", 55)
    addToggle(card, "Compact cards", "Reduce vertical spacing in page sections.", "CompactCards", 113)
    local actions = addCard(Content, "PANEL ACTIONS", "Quick maintenance for the local interface.", 158, 3)
    addButton(actions, "RESET VISUAL PREFERENCES", UDim2.fromOffset(12, 54), UDim2.new(1, -24, 0, 34), function()
        State.Ambient = true
        State.StarParticles = true
        State.OrbitMotion = true
        State.KetupatMotion = true
        State.ReduceMotion = false
        State.CompactCards = false
        State.Glow = 0.72
        State.AnimationSpeed = 1.0
        renderUI()
        showNotice("VISUAL PREFERENCES RESET")
    end, "secondary")
    addButton(actions, "UNLOAD INTERFACE", UDim2.fromOffset(12, 98), UDim2.new(1, -24, 0, 34), function()
        State.Destroyed = true
        ScreenGui:Destroy()
    end, "danger")
end

local function pageAbout()
    clearContent()
    createListContent()
    addPageHeading(Content, "ABOUT BAXTARA", "A visual interface project with four independent design systems.")
    local card = addCard(Content, "BAXTARA X / UI EDITION 6.0", "Local interface • Responsive layout • No external asset dependency", 155, 2)
    text(card, "The panel focuses on presentation: navigation, responsive cards, theme geometry, interaction feedback and decorative motion.",
        10, Theme.Text, Enum.Font.Gotham, UDim2.fromOffset(15, 56), UDim2.new(1, -30, 0, 50))
    local safety = addCard(Content, "SCOPE", "What this script does and does not do.", 136, 3)
    text(safety, "UI ONLY  •  No gameplay automation  •  No player manipulation  •  No anti-cheat bypass  •  No ban or kick evasion",
        10, Theme.Accent2, Enum.Font.GothamBold, UDim2.fromOffset(15, 56), UDim2.new(1, -30, 0, 52))
end

local PageRenderers = {
    OVERVIEW = pageOverview,
    PROFILE = pageProfile,
    APPEARANCE = pageAppearance,
    ["VISUAL LAB"] = pageVisualLab,
    PREFERENCES = pagePreferences,
    ABOUT = pageAbout,
}

local function makeNavButton(parent, page, icon, horizontal, order)
    local active = State.SelectedPage == page
    local style = Theme.Style
    local width, height
    if horizontal then
        width, height = UDim2.new(0, 112, 1, -8), UDim2.new(0, 36, 0, 36)
    elseif style == "Galaxy" then
        width, height = UDim2.new(1, -12, 0, 54), UDim2.new(1, -12, 0, 54)
    else
        width, height = UDim2.new(1, -10, 0, 43), UDim2.new(1, -10, 0, 43)
    end
    local button = make("TextButton", {
        Size = width,
        BackgroundColor3 = active and Theme.Raised or Theme.Surface,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 7,
    }, parent)
    if style == "Galaxy" then
        corner(button, 99)
        outline(button, active and Theme.Accent or Theme.Border, active and 1.5 or 1, active and 0.12 or 0.72)
        if horizontal then
            local planet = make("Frame", {
                Position = UDim2.fromOffset(8, 8),
                Size = UDim2.fromOffset(21, 21),
                BackgroundColor3 = active and Theme.Accent or Theme.Element,
                BorderSizePixel = 0,
                ZIndex = 8,
            }, button)
            corner(planet, 99)
            addGradient(planet, active and Theme.Accent2 or Theme.Element, Theme.Accent, 35)
            text(planet, icon, 9, Theme.Text, Enum.Font.GothamBold,
                UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
            text(button, page, 8, active and Theme.Text or Theme.Muted, Enum.Font.GothamBold,
                UDim2.fromOffset(35, 0), UDim2.new(1, -40, 1, 0))
        else
            local planet = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, -5),
                Size = UDim2.fromOffset(23, 23),
                BackgroundColor3 = active and Theme.Accent or Theme.Element,
                BorderSizePixel = 0,
                ZIndex = 8,
            }, button)
            corner(planet, 99)
            addGradient(planet, active and Theme.Accent2 or Theme.Element, Theme.Accent, 35)
            text(planet, icon, 11, Theme.Text, Enum.Font.GothamBold,
                UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
            text(button, page, 7, active and Theme.Text or Theme.Muted, Enum.Font.GothamBold,
                UDim2.new(0, 0, 1, -15), UDim2.new(1, 0, 0, 12), Enum.TextXAlignment.Center)
            if active then
                local ring = make("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.42),
                    Size = UDim2.fromOffset(39, 39),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                }, button)
                corner(ring, 99)
                outline(ring, Theme.Accent2, 1, 0.28)
            end
        end
    elseif style == "Lego" then
        corner(button, 4)
        outline(button, active and Theme.Accent or Theme.Border, 2, active and 0.08 or 0.4)
        local studs = make("Frame", {
            Position = UDim2.fromOffset(7, 5),
            Size = UDim2.fromOffset(10, 7),
            BackgroundColor3 = active and Theme.Accent or Theme.Accent2,
            BorderSizePixel = 0,
            ZIndex = 8,
        }, button)
        corner(studs, 3)
        text(button, icon .. "  " .. page, 8, Theme.Text, Enum.Font.GothamBlack,
            UDim2.fromOffset(8, horizontal and 12 or 13),
            UDim2.new(1, -12, 1, horizontal and -12 or -13), horizontal and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left)
    elseif style == "Eid" then
        corner(button, 13)
        outline(button, active and Theme.Accent or Theme.Border, active and 1.6 or 1, active and 0.12 or 0.55)
        text(button, horizontal and "◆" or icon, horizontal and 12 or 15, Theme.Accent, Enum.Font.GothamBold,
            UDim2.fromOffset(horizontal and 7 or 9, 0), UDim2.fromOffset(25, horizontal and 36 or 43), Enum.TextXAlignment.Center)
        text(button, page, 8, active and Theme.Text or Theme.Muted, Enum.Font.GothamBold,
            UDim2.fromOffset(horizontal and 32 or 38, 0), UDim2.new(1, horizontal and -36 or -42, 1, 0))
    else
        corner(button, 9)
        outline(button, active and Theme.Border or Theme.Surface, 1, active and 0.38 or 1)
        if active then
            make("Frame", {
                Position = UDim2.fromOffset(0, 8),
                Size = UDim2.new(0, 3, 1, -16),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 9,
            }, button)
        end
        text(button, icon, 14, active and Theme.Accent or Theme.Muted, Enum.Font.GothamBold,
            UDim2.fromOffset(9, 0), UDim2.fromOffset(24, 43), Enum.TextXAlignment.Center)
        text(button, page, 8, active and Theme.Text or Theme.Muted, Enum.Font.GothamSemibold,
            UDim2.fromOffset(37, 0), UDim2.new(1, -41, 1, 0))
    end

    button.Activated:Connect(function()
        State.SelectedPage = page
        renderUI()
    end)
    return button
end

renderPage = function()
    if not Content then return end
    local renderer = PageRenderers[State.SelectedPage] or pageOverview
    renderer()
end

renderUI = function()
    if State.Destroyed then return end
    Dragging = false
    DragInputPosition = nil
    DragStartPosition = nil
    ActiveSlider = nil
    Theme = Themes[State.Theme] or Themes.Galaxy
    OrbitNodes = {}
    StarNodes = {}
    HeaderKetupatNodes = {}
    PageKetupatNodes = {}

    if Main and Main.Parent then Main:Destroy() end
    if FloatingButton and FloatingButton.Parent then FloatingButton:Destroy() end

    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(900, 700)
    local mobile = viewport.X < 680
    local mainSize = mobile and UDim2.new(0.97, 0, 0.91, 0) or UDim2.new(0.88, 0, 0.84, 0)

    Main = make("Frame", {
        Name = "MainPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = mainSize,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    }, ScreenGui)
    corner(Main, Theme.Style == "Lego" and 7 or (Theme.Style == "Galaxy" and 22 or Theme.Radius + 3))
    outline(Main, Theme.Border, Theme.Style == "Lego" and 3 or 1.2, Theme.Style == "Modern" and 0.55 or 0.18)
    addGradient(Main, Theme.Background, Theme.Surface, 90)
    make("UISizeConstraint", {
        MinSize = Vector2.new(310, 420),
        MaxSize = Vector2.new(980, 720),
    }, Main)

    local headerHeight = 60
    local header = make("Frame", {
        Size = UDim2.new(1, 0, 0, headerHeight),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, Main)
    if Theme.Style == "Lego" then
        corner(header, 5)
    else
        corner(header, Theme.Radius)
    end

    local logo = make("Frame", {
        Position = UDim2.fromOffset(14, 9),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, header)
    corner(logo, Theme.Style == "Galaxy" and 99 or (Theme.Style == "Lego" and 5 or 12))
    addGradient(logo, Theme.Accent, Theme.Accent2, 40)
    text(logo, "BX", 13, Theme.Background, Enum.Font.GothamBlack,
        UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
    text(header, "BAXTARA X", 14, Theme.Text, Enum.Font.GothamBlack,
        UDim2.fromOffset(64, 9), UDim2.new(0.58, -60, 0, 22))
    text(header, Theme.Name, 8, Theme.Muted, Enum.Font.GothamBold,
        UDim2.fromOffset(65, 31), UDim2.new(0.58, -60, 0, 14))

    local close = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(32, 30),
        BackgroundColor3 = Theme.Raised,
        Text = "×",
        TextColor3 = Theme.Danger,
        TextSize = 21,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, header)
    corner(close, Theme.Style == "Lego" and 5 or 10)
    close.Activated:Connect(function()
        State.PanelVisible = false
        if Main then Main.Visible = false end
        if FloatingButton then FloatingButton.Visible = true end
    end)
    local minimize = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.fromOffset(28, 30),
        BackgroundColor3 = Theme.Raised,
        Text = "−",
        TextColor3 = Theme.Accent,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, header)
    corner(minimize, Theme.Style == "Lego" and 5 or 10)
    minimize.Activated:Connect(function()
        State.PanelVisible = false
        Main.Visible = false
        if FloatingButton then FloatingButton.Visible = true end
    end)

    buildThemeDecor(header, Main, mobile)

    local navHorizontal = mobile or Theme.Style == "Lego"
    local navFrame
    if navHorizontal then
        navFrame = make("ScrollingFrame", {
            Position = UDim2.fromOffset(10, 68),
            Size = UDim2.new(1, -20, 0, 46),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            CanvasSize = UDim2.new(0, #PageNames * 120, 0, 0),
            ZIndex = 6,
        }, Main)
        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, navFrame)
    else
        local navWidth = Theme.Style == "Galaxy" and 88 or (Theme.Style == "Eid" and 136 or 118)
        navFrame = make("Frame", {
            Position = UDim2.fromOffset(12, 74),
            Size = UDim2.new(0, navWidth, 1, -88),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 6,
        }, Main)
        corner(navFrame, Theme.Style == "Galaxy" and 22 or (Theme.Style == "Eid" and 18 or 11))
        outline(navFrame, Theme.Border, 1, 0.72)
        make("UIListLayout", {
            Padding = UDim.new(0, Theme.Style == "Galaxy" and 7 or 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, navFrame)
        make("UIPadding", {
            PaddingTop = UDim.new(0, 9),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
        }, navFrame)
        if Theme.Style == "Galaxy" then
            text(navFrame, "ORBIT", 8, Theme.Accent2, Enum.Font.GothamBlack,
                UDim2.new(0, 0, 1, -23), UDim2.new(1, 0, 0, 14), Enum.TextXAlignment.Center)
        elseif Theme.Style == "Eid" then
            text(navFrame, "☾  MENU", 8, Theme.Accent, Enum.Font.GothamBold,
                UDim2.new(0, 8, 1, -24), UDim2.new(1, -16, 0, 15))
        else
            text(navFrame, "WORKSPACE", 7, Theme.Muted, Enum.Font.GothamBold,
                UDim2.new(0, 8, 1, -23), UDim2.new(1, -16, 0, 14))
        end
    end

    for index, page in ipairs(PageNames) do
        makeNavButton(navFrame, page.Name, page.Icon, navHorizontal, index)
    end

    local contentX, contentY, contentSize
    if navHorizontal then
        contentX, contentY = 12, 123
        contentSize = UDim2.new(1, -24, 1, -134)
    else
        local navWidth = Theme.Style == "Galaxy" and 88 or (Theme.Style == "Eid" and 136 or 118)
        contentX, contentY = navWidth + 24, 74
        contentSize = UDim2.new(1, -navWidth - 36, 1, -88)
    end
    Content = make("ScrollingFrame", {
        Position = UDim2.fromOffset(contentX, contentY),
        Size = contentSize,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 5,
    }, Main)

    FloatingButton = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.62, 0),
        Size = UDim2.fromOffset(52, 52),
        BackgroundColor3 = Theme.Accent,
        Text = "BX",
        TextColor3 = Theme.Background,
        TextSize = 14,
        Font = Enum.Font.GothamBlack,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Visible = not State.PanelVisible,
        ZIndex = 30,
    }, ScreenGui)
    corner(FloatingButton, Theme.Style == "Lego" and 7 or 99)
    outline(FloatingButton, Theme.Accent2, Theme.Style == "Lego" and 2 or 1.5, 0.18)
    FloatingButton.Activated:Connect(function()
        State.PanelVisible = true
        if Main then
            Main.Visible = true
            local scale = make("UIScale", { Scale = 0.94 }, Main)
            tween(scale, 0.23, { Scale = 1 }, Enum.EasingStyle.Back)
        end
        FloatingButton.Visible = false
    end)

    renderPage()

    if not IntroPlayed and State.PanelVisible then
        IntroPlayed = true
        local scale = make("UIScale", { Scale = 0.94 }, Main)
        tween(scale, 0.34, { Scale = 1 }, Enum.EasingStyle.Back)
        tween(Main, 0.28, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quart)
    end
    Main.Visible = State.PanelVisible
    if bindHeaderDrag then bindHeaderDrag() end
end

-- Dragging is limited to the header so page controls remain usable.
bindHeaderDrag = function()
    local header = Main and Main:FindFirstChildWhichIsA("Frame")
    if not header then return end
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragInputPosition = input.Position
            DragStartPosition = Main.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
end

renderUI()
bindHeaderDrag()

UserInputService.InputChanged:Connect(function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        ActiveSlider.Update(input.Position.X)
    end
    if Dragging and DragInputPosition and DragStartPosition and Main and Main.Parent then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - DragInputPosition
            Main.Position = UDim2.new(
                DragStartPosition.X.Scale,
                DragStartPosition.X.Offset + delta.X,
                DragStartPosition.Y.Scale,
                DragStartPosition.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ActiveSlider = nil
        Dragging = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        State.PanelVisible = not State.PanelVisible
        if Main then Main.Visible = State.PanelVisible end
        if FloatingButton then FloatingButton.Visible = not State.PanelVisible end
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    if State.Destroyed then return end
    FrameCounter = FrameCounter + 1
    local now = os.clock()
    if now - LastStatsRefresh >= 1 then
        FPS = math.floor(FrameCounter / math.max(now - LastStatsRefresh, 0.001) + 0.5)
        FrameCounter = 0
        LastStatsRefresh = now
        if FpsValue and FpsValue.Parent then FpsValue.Text = tostring(FPS) end
        if PlayerValue and PlayerValue.Parent then PlayerValue.Text = tostring(#Players:GetPlayers()) end
        if SessionValue and SessionValue.Parent then
            local elapsed = math.floor(now - SessionStart)
            SessionValue.Text = string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60)
        end
    end

    if State.ReduceMotion or not State.Ambient then return end
    local phase = now * State.AnimationSpeed
    if Theme.Style == "Galaxy" and State.StarParticles then
        for index, item in ipairs(StarNodes) do
            if item.Object and item.Object.Parent then
                item.Object.BackgroundTransparency = math.clamp(0.94 - ((math.sin(phase * 1.6 + item.Phase) + 1) * 0.5 * State.Glow), 0.12, 0.98)
            end
        end
    end
    if Theme.Style == "Galaxy" and State.OrbitMotion then
        for _, item in ipairs(OrbitNodes) do
            if item.Root and item.Root.Parent and item.Planet and item.Planet.Parent then
                local angle = phase * 0.9 + item.Phase
                local x = 0.5 + math.cos(angle) * item.Radius
                local y = 0.5 + math.sin(angle) * item.Radius * 0.48
                item.Planet.Position = UDim2.fromScale(x, y)
            end
        end
    end
    if Theme.Style == "Eid" and State.KetupatMotion then
        local allKetupats = {}
        for _, object in ipairs(HeaderKetupatNodes) do table.insert(allKetupats, object) end
        for _, object in ipairs(PageKetupatNodes) do table.insert(allKetupats, object) end
        for index, object in ipairs(allKetupats) do
            if object and object.Parent then
                object.Rotation = math.sin(phase * 0.9 + index) * 4
            end
        end
    end
end)

Players.PlayerAdded:Connect(function()
    if PlayerValue and PlayerValue.Parent then
        PlayerValue.Text = tostring(#Players:GetPlayers())
    end
end)
Players.PlayerRemoving:Connect(function()
    if PlayerValue and PlayerValue.Parent then
        PlayerValue.Text = tostring(math.max(0, #Players:GetPlayers() - 1))
    end
end)

ScreenGui.Destroying:Connect(function()
    State.Destroyed = true
    ActiveSlider = nil
    table.clear(OrbitNodes)
    table.clear(StarNodes)
    table.clear(HeaderKetupatNodes)
    table.clear(PageKetupatNodes)
end)

showNotice("FOUR WORLDS UI ONLINE", Theme.Accent)
print("[BAXTARA] Four Worlds UI loaded. Local interface only.")
