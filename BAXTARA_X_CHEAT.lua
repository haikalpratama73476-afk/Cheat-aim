--[[
    BAXTARA X CHEAT  v2  (Fixed)
    Developer : NUGI CENEL
    Credit    : @BAXTARA X CHEAT
    Executor  : Delta / any Lua executor with Drawing + getgenv
    Notes     : Client-side only. Combat/health changes are local attempts.
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

local DrawingLib = Drawing
if not DrawingLib then
    warn("[BAXTARA] Drawing library missing – visual ESP/FOV limited.")
end

getgenv().BAXTARA = getgenv().BAXTARA or {}
local B = getgenv().BAXTARA

-- ===================== SETTINGS =====================
B.Settings = {
    Aim = {
        Enabled         = false,
        VisibilityCheck = true,
        HeadAim         = true,
        BodyAim         = false,
        MultiBone       = false,
        DynamicFOV      = false,
        FOVCircle       = true,
        AimDistance     = 500,
        AimPart         = "Head",
        AimLock         = false,
        AimPriority     = "Crosshair", -- Crosshair / Distance / Health
        AimSensitivity  = 1.0,
        AimSmoothing    = 0.15,
        AimPrediction   = false,
        PredictionAmount= 0.12,
        TargetSwitch    = false,
        DrawTargetLine  = true,
        TargetHighlight = true,
        FOV             = 120,
        TeamCheck       = true,
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
        WeaponESP     = true,
        StatusESP     = true,
        Radar         = false,
        Offscreen     = true,
        ItemESP       = false,
        LootESP       = false,
        ChestESP      = false,
        VehicleESP    = false,
        NPCESP        = false,
        BossESP       = false,
        DoorESP       = false,
        KeyESP        = false,
        ExitESP       = false,
        MaxDistance   = 800,
        VisibleColor  = Color3.fromRGB(0, 255, 140),
        HiddenColor   = Color3.fromRGB(255, 70, 70),
        PriorityColor = Color3.fromRGB(255, 200, 0),
        OffscreenColor= Color3.fromRGB(0, 200, 255),
    },
    Brutal = {
        Fly            = false,
        FlySpeed       = 50,
        SpeedHack      = false,
        SpeedValue     = 32,
        InfiniteJump   = false,
        Noclip         = false,
        SuperJump      = false,
        SuperJumpPower = 100,
        NoFallDamage   = false,
        GodMode        = false,
        InfiniteHealth = false,
        HitboxExpand   = false,
        HitboxSize     = 8,
        KillAll        = false,
        AutoKill       = false,
        AirWalk        = false,
        SpiderClimb    = false,
        Teleport       = false,
    },
    Visual = {
        FullBright       = false,
        NoFog            = false,
        StreamingMode    = false,
        StreamingOpacity = 0.35,
    },
    UI = {
        Accent     = Color3.fromRGB(0, 255, 140),
        Background = Color3.fromRGB(12, 14, 18),
        Panel      = Color3.fromRGB(18, 22, 28),
        Text       = Color3.fromRGB(220, 230, 240),
        DimText    = Color3.fromRGB(120, 140, 150),
    }
}

B.Connections   = {}
B.Drawings      = {}
B.Highlights    = {}
B.ESPObjects    = {}
B.ObjectESP     = {}
B.CurrentTarget = nil
B.LockedTarget  = nil
B.OriginalCollision = {}
B.OriginalJumpPower = 50
B.OriginalWalkSpeed = 16
B.OriginalJumpHeight = 7.2

local function AddConn(c)
    table.insert(B.Connections, c)
    return c
end

local function CleanupAll()
    for _, c in ipairs(B.Connections) do
        pcall(function() c:Disconnect() end)
    end
    B.Connections = {}
    for _, d in pairs(B.Drawings) do
        pcall(function() if d.Remove then d:Remove() end end)
    end
    B.Drawings = {}
    for _, h in pairs(B.Highlights) do
        pcall(function() h:Destroy() end)
    end
    B.Highlights = {}
    for _, pack in pairs(B.ESPObjects) do
        for _, d in pairs(pack) do
            pcall(function() if d and d.Remove then d:Remove() end end)
        end
    end
    B.ESPObjects = {}
    for _, d in pairs(B.ObjectESP) do
        pcall(function() if d.Remove then d:Remove() end end)
    end
    B.ObjectESP = {}
end

-- ===================== UTILS =====================
local function IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetChar(p)
    return p and p.Character
end

local function GetRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function GetHead(char)
    return char and char:FindFirstChild("Head")
end

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

local function VisibleCheck(from, to, extraIgnore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {LocalPlayer.Character}
    if extraIgnore then
        for _, o in ipairs(extraIgnore) do table.insert(ignore, o) end
    end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    return Workspace:Raycast(from, to - from, params) == nil
end

-- ===================== AIM =====================
local FOVCircle, TargetLine

local function MakeFOV()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if not DrawingLib then return end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Radius = B.Settings.Aim.FOV
    FOVCircle.Filled = false
    FOVCircle.Color = B.Settings.UI.Accent
    FOVCircle.Transparency = 0.65
    FOVCircle.Visible = false
    B.Drawings.FOV = FOVCircle
end

local function MakeLine()
    if TargetLine then pcall(function() TargetLine:Remove() end) end
    if not DrawingLib then return end
    TargetLine = Drawing.new("Line")
    TargetLine.Thickness = 1.2
    TargetLine.Color = Color3.fromRGB(0, 255, 180)
    TargetLine.Transparency = 0.55
    TargetLine.Visible = false
    B.Drawings.TargetLine = TargetLine
end

local function GetAimPart(char)
    if B.Settings.Aim.MultiBone then
        for _, n in ipairs({"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm"}) do
            local p = char:FindFirstChild(n)
            if p then return p end
        end
    end
    if B.Settings.Aim.HeadAim then
        return GetHead(char) or GetRoot(char)
    end
    if B.Settings.Aim.BodyAim then
        return GetRoot(char) or GetHead(char)
    end
    return char:FindFirstChild(B.Settings.Aim.AimPart) or GetHead(char) or GetRoot(char)
end

local function ScoreTarget(player, part, mousePos)
    local screen, onScreen = WorldToScreen(part.Position)
    if not onScreen then return nil end
    local cross = (screen - mousePos).Magnitude
    if cross > B.Settings.Aim.FOV then return nil end
    local dist = DistTo(part.Position)
    if dist > B.Settings.Aim.AimDistance then return nil end

    if B.Settings.Aim.VisibilityCheck then
        if not VisibleCheck(Camera.CFrame.Position, part.Position, {GetChar(player)}) then
            return nil
        end
    end

    local priority = B.Settings.Aim.AimPriority
    if priority == "Distance" then
        return dist
    elseif priority == "Health" then
        local hum = GetChar(player) and GetChar(player):FindFirstChildOfClass("Humanoid")
        return hum and hum.Health or 999
    else -- Crosshair
        return cross
    end
end

local function GetBestTarget()
    local best, bestScore = nil, math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and TeamOK(p) then
            local char = GetChar(p)
            if IsAlive(char) then
                local part = GetAimPart(char)
                if part then
                    local score = ScoreTarget(p, part, mousePos)
                    if score and score < bestScore then
                        bestScore = score
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
    if not IsAlive(char) then
        if B.LockedTarget == target then B.LockedTarget = nil end
        return
    end
    local part = GetAimPart(char)
    if not part then return end

    local pos = part.Position
    if B.Settings.Aim.AimPrediction then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        pos = pos + vel * B.Settings.Aim.PredictionAmount
    end

    local current = Camera.CFrame
    local goal = CFrame.new(current.Position, pos)
    local t = math.clamp(B.Settings.Aim.AimSmoothing * B.Settings.Aim.AimSensitivity, 0.02, 1)
    Camera.CFrame = current:Lerp(goal, t)
end

local function UpdateAim()
    if not B.Settings.Aim.Enabled then
        if FOVCircle then FOVCircle.Visible = false end
        if TargetLine then TargetLine.Visible = false end
        B.CurrentTarget = nil
        return
    end

    local mousePos = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)

    if FOVCircle and B.Settings.Aim.FOVCircle then
        FOVCircle.Position = mousePos
        local r = B.Settings.Aim.FOV
        if B.Settings.Aim.DynamicFOV then
            r = r * (1 + (Camera.FieldOfView / 70) * 0.12)
        end
        FOVCircle.Radius = r
        FOVCircle.Visible = true
    elseif FOVCircle then
        FOVCircle.Visible = false
    end

    -- validate locked target still alive & in FOV
    if B.Settings.Aim.AimLock and B.LockedTarget then
        local char = GetChar(B.LockedTarget)
        if not IsAlive(char) then
            B.LockedTarget = nil
        else
            local part = GetAimPart(char)
            if part then
                local screen, on = WorldToScreen(part.Position)
                if not on or (screen - mousePos).Magnitude > B.Settings.Aim.FOV * 1.4 then
                    if B.Settings.Aim.TargetSwitch then
                        B.LockedTarget = nil
                    end
                end
            end
        end
    end

    local target = (B.Settings.Aim.AimLock and B.LockedTarget) or GetBestTarget()
    if B.Settings.Aim.AimLock and not B.LockedTarget then
        B.LockedTarget = target
    end
    if not B.Settings.Aim.AimLock then
        B.LockedTarget = nil
    end

    B.CurrentTarget = target

    if target then
        AimAt(target)
        if TargetLine and B.Settings.Aim.DrawTargetLine then
            local part = GetAimPart(GetChar(target))
            if part then
                local screen, on = WorldToScreen(part.Position)
                if on then
                    TargetLine.From = mousePos
                    TargetLine.To = screen
                    TargetLine.Visible = true
                else
                    TargetLine.Visible = false
                end
            end
        end
        if B.Settings.Aim.TargetHighlight then
            local char = GetChar(target)
            if char and not B.Highlights[target.UserId] then
                local hl = Instance.new("Highlight")
                hl.Adornee = char
                hl.FillColor = Color3.fromRGB(0, 255, 160)
                hl.OutlineColor = Color3.fromRGB(0, 200, 120)
                hl.FillTransparency = 0.55
                hl.Parent = CoreGui
                B.Highlights[target.UserId] = hl
            end
        end
    else
        if TargetLine then TargetLine.Visible = false end
    end

    for uid, hl in pairs(B.Highlights) do
        if not (target and target.UserId == uid) then
            pcall(function() hl:Destroy() end)
            B.Highlights[uid] = nil
        end
    end
end

-- ===================== ESP =====================
local function GetESPPack(player)
    local id = player.UserId
    if B.ESPObjects[id] then return B.ESPObjects[id] end
    local pack = {}
    if DrawingLib then
        pack.Box = Drawing.new("Square")
        pack.Box.Thickness = 1.2
        pack.Box.Filled = false
        pack.Box.Visible = false

        pack.Name = Drawing.new("Text")
        pack.Name.Size = 14
        pack.Name.Center = true
        pack.Name.Outline = true
        pack.Name.Visible = false

        pack.Health = Drawing.new("Line")
        pack.Health.Thickness = 2.5
        pack.Health.Visible = false

        pack.Dist = Drawing.new("Text")
        pack.Dist.Size = 12
        pack.Dist.Center = true
        pack.Dist.Outline = true
        pack.Dist.Visible = false

        pack.Tracer = Drawing.new("Line")
        pack.Tracer.Thickness = 1
        pack.Tracer.Visible = false

        pack.Weapon = Drawing.new("Text")
        pack.Weapon.Size = 12
        pack.Weapon.Center = true
        pack.Weapon.Outline = true
        pack.Weapon.Visible = false

        -- skeleton lines
        pack.Skel = {}
        for i = 1, 12 do
            local l = Drawing.new("Line")
            l.Thickness = 1.2
            l.Visible = false
            pack.Skel[i] = l
        end

        -- offscreen arrow
        pack.Off = Drawing.new("Triangle")
        pack.Off.Filled = true
        pack.Off.Thickness = 1
        pack.Off.Visible = false
    end
    B.ESPObjects[id] = pack
    return pack
end

local function HidePack(pack)
    if not pack then return end
    for k, d in pairs(pack) do
        if k == "Skel" then
            for _, l in ipairs(d) do if l then l.Visible = false end end
        elseif d and d.Visible ~= nil then
            d.Visible = false
        end
    end
end

local BonePairs = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"},
}

local function UpdatePlayerESP()
    if not B.Settings.ESP.Enabled then
        for _, pack in pairs(B.ESPObjects) do HidePack(pack) end
        return
    end

    local camPos = Camera.CFrame.Position
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = GetChar(player)
        local pack = GetESPPack(player)

        if not IsAlive(char) then
            HidePack(pack)
            continue
        end

        local root = GetRoot(char)
        local head = GetHead(char)
        if not root or not head then
            HidePack(pack)
            continue
        end

        local dist = DistTo(root.Position)
        if dist > B.Settings.ESP.MaxDistance then
            HidePack(pack)
            continue
        end

        local headScreen, onScreen = WorldToScreen(head.Position + Vector3.new(0, 0.4, 0))
        local rootScreen = WorldToScreen(root.Position)
        local visible = true
        if B.Settings.ESP.VisibleCheck then
            visible = VisibleCheck(camPos, head.Position, {char})
        end

        local color = visible and B.Settings.ESP.VisibleColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.PriorityMark and B.CurrentTarget == player then
            color = B.Settings.ESP.PriorityColor
        end

        -- Box
        if B.Settings.ESP.Box and pack.Box then
            local h = math.abs(headScreen.Y - rootScreen.Y)
            local w = h * 0.55
            pack.Box.Size = Vector2.new(w, h)
            pack.Box.Position = Vector2.new(headScreen.X - w/2, headScreen.Y)
            pack.Box.Color = color
            pack.Box.Visible = onScreen
        end

        -- Name
        if B.Settings.ESP.Name and pack.Name then
            pack.Name.Text = player.DisplayName or player.Name
            pack.Name.Position = Vector2.new(headScreen.X, headScreen.Y - 18)
            pack.Name.Color = color
            pack.Name.Visible = onScreen
        end

        -- Health
        if B.Settings.ESP.HealthBar and pack.Health then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local bh = math.abs(headScreen.Y - rootScreen.Y)
                local x = headScreen.X - (bh * 0.55)/2 - 5
                pack.Health.From = Vector2.new(x, headScreen.Y + bh)
                pack.Health.To   = Vector2.new(x, headScreen.Y + bh * (1 - pct))
                pack.Health.Color = Color3.fromRGB(255*(1-pct), 255*pct, 50)
                pack.Health.Visible = onScreen
            end
        end

        -- Distance
        if B.Settings.ESP.Distance and pack.Dist then
            pack.Dist.Text = string.format("[%dm]", math.floor(dist))
            pack.Dist.Position = Vector2.new(rootScreen.X, rootScreen.Y + 8)
            pack.Dist.Color = Color3.fromRGB(180, 200, 210)
            pack.Dist.Visible = onScreen
        end

        -- Tracer
        if B.Settings.ESP.Tracer and pack.Tracer then
            pack.Tracer.From = Vector2.new(vp.X/2, vp.Y)
            pack.Tracer.To = rootScreen
            pack.Tracer.Color = color
            pack.Tracer.Visible = onScreen
        end

        -- Weapon / Status
        if (B.Settings.ESP.WeaponESP or B.Settings.ESP.StatusESP) and pack.Weapon then
            local tool = char:FindFirstChildOfClass("Tool")
            local hum = char:FindFirstChildOfClass("Humanoid")
            local t = ""
            if B.Settings.ESP.WeaponESP and tool then t = tool.Name end
            if B.Settings.ESP.StatusESP and hum then
                t = t .. (t ~= "" and " | " or "") .. string.format("%.0fHP", hum.Health)
            end
            pack.Weapon.Text = t
            pack.Weapon.Position = Vector2.new(rootScreen.X, rootScreen.Y + 22)
            pack.Weapon.Color = Color3.fromRGB(200, 220, 100)
            pack.Weapon.Visible = onScreen and t ~= ""
        end

        -- Skeleton
        if B.Settings.ESP.Skeleton and pack.Skel then
            for i, pair in ipairs(BonePairs) do
                local a = char:FindFirstChild(pair[1])
                local b = char:FindFirstChild(pair[2])
                local line = pack.Skel[i]
                if a and b and line then
                    local sa, oa = WorldToScreen(a.Position)
                    local sb, ob = WorldToScreen(b.Position)
                    if oa and ob then
                        line.From = sa
                        line.To = sb
                        line.Color = color
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                elseif line then
                    line.Visible = false
                end
            end
        elseif pack.Skel then
            for _, l in ipairs(pack.Skel) do l.Visible = false end
        end

        -- Offscreen arrow
        if B.Settings.ESP.Offscreen and pack.Off and not onScreen then
            local dir = (rootScreen - center)
            if dir.Magnitude > 0 then
                dir = dir.Unit
                local edge = center + dir * (math.min(vp.X, vp.Y) * 0.42)
                local ang = math.atan2(dir.Y, dir.X)
                local size = 10
                pack.Off.PointA = edge
                pack.Off.PointB = edge + Vector2.new(math.cos(ang+2.4)*size, math.sin(ang+2.4)*size)
                pack.Off.PointC = edge + Vector2.new(math.cos(ang-2.4)*size, math.sin(ang-2.4)*size)
                pack.Off.Color = B.Settings.ESP.OffscreenColor
                pack.Off.Visible = true
            end
        elseif pack.Off then
            pack.Off.Visible = false
        end
    end
end

-- Object ESP (throttled name scan)
local lastObjectScan = 0
local function ScanObjects()
    if not B.Settings.ESP.Enabled then
        for _, d in pairs(B.ObjectESP) do pcall(function() d:Remove() end) end
        B.ObjectESP = {}
        return
    end

    local keywords = {}
    if B.Settings.ESP.ItemESP    then table.insert(keywords, "item") end
    if B.Settings.ESP.LootESP    then table.insert(keywords, "loot") end
    if B.Settings.ESP.ChestESP   then table.insert(keywords, "chest") end
    if B.Settings.ESP.VehicleESP then table.insert(keywords, "vehicle"); table.insert(keywords, "car") end
    if B.Settings.ESP.NPCESP     then table.insert(keywords, "npc") end
    if B.Settings.ESP.BossESP    then table.insert(keywords, "boss") end
    if B.Settings.ESP.DoorESP    then table.insert(keywords, "door") end
    if B.Settings.ESP.KeyESP     then table.insert(keywords, "key") end
    if B.Settings.ESP.ExitESP    then table.insert(keywords, "exit") end
    if #keywords == 0 then
        for _, d in pairs(B.ObjectESP) do pcall(function() d:Remove() end) end
        B.ObjectESP = {}
        return
    end

    local now = tick()
    if now - lastObjectScan < 1.2 then return end
    lastObjectScan = now

    local seen = {}
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if count > 35 then break end
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw, 1, true) then
                    local pos
                    if obj:IsA("Model") then
                        local r = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                        pos = r and r.Position or obj:GetPivot().Position
                    else
                        pos = obj.Position
                    end
                    if DistTo(pos) < B.Settings.ESP.MaxDistance then
                        local screen, on = WorldToScreen(pos)
                        if on then
                            local id = obj:GetFullName()
                            seen[id] = true
                            if not B.ObjectESP[id] and DrawingLib then
                                local t = Drawing.new("Text")
                                t.Size = 13
                                t.Center = true
                                t.Outline = true
                                t.Color = Color3.fromRGB(255, 180, 50)
                                B.ObjectESP[id] = t
                            end
                            if B.ObjectESP[id] then
                                B.ObjectESP[id].Text = obj.Name
                                B.ObjectESP[id].Position = screen
                                B.ObjectESP[id].Visible = true
                            end
                            count = count + 1
                        end
                    end
                    break
                end
            end
        end
    end
    for id, d in pairs(B.ObjectESP) do
        if not seen[id] then
            pcall(function() d:Remove() end)
            B.ObjectESP[id] = nil
        end
    end
end

-- Simple Radar (2D top-down)
local RadarFrame, RadarDots = nil, {}
local function EnsureRadar()
    if RadarFrame then return end
    RadarFrame = Instance.new("Frame")
    RadarFrame.Name = "BAXTARA_Radar"
    RadarFrame.Size = UDim2.new(0, 130, 0, 130)
    RadarFrame.Position = UDim2.new(1, -150, 0, 20)
    RadarFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
    RadarFrame.BackgroundTransparency = 0.25
    RadarFrame.BorderSizePixel = 0
    RadarFrame.Visible = false
    RadarFrame.Parent = CoreGui:FindFirstChild("BAXTARA_X_CHEAT") or CoreGui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = RadarFrame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 180, 100)
    stroke.Thickness = 1
    stroke.Parent = RadarFrame
    local center = Instance.new("Frame")
    center.Size = UDim2.new(0, 6, 0, 6)
    center.Position = UDim2.new(0.5, -3, 0.5, -3)
    center.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
    center.BorderSizePixel = 0
    center.Parent = RadarFrame
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(1, 0)
    cc.Parent = center
end

local function UpdateRadar()
    EnsureRadar()
    if not B.Settings.ESP.Radar or not B.Settings.ESP.Enabled then
        if RadarFrame then RadarFrame.Visible = false end
        return
    end
    RadarFrame.Visible = true
    local myRoot = GetRoot(LocalPlayer.Character)
    if not myRoot then return end

    local used = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and TeamOK(p) then
            local char = GetChar(p)
            if IsAlive(char) then
                local r = GetRoot(char)
                if r then
                    local rel = myRoot.CFrame:PointToObjectSpace(r.Position)
                    local scale = 130 / (B.Settings.ESP.MaxDistance * 0.6)
                    local x = math.clamp(rel.X * scale + 65, 4, 126)
                    local y = math.clamp(-rel.Z * scale + 65, 4, 126)
                    local id = p.UserId
                    used[id] = true
                    if not RadarDots[id] then
                        local d = Instance.new("Frame")
                        d.Size = UDim2.new(0, 5, 0, 5)
                        d.BorderSizePixel = 0
                        d.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                        d.Parent = RadarFrame
                        local dc = Instance.new("UICorner")
                        dc.CornerRadius = UDim.new(1, 0)
                        dc.Parent = d
                        RadarDots[id] = d
                    end
                    RadarDots[id].Position = UDim2.new(0, x-2.5, 0, y-2.5)
                    RadarDots[id].Visible = true
                end
            end
        end
    end
    for id, d in pairs(RadarDots) do
        if not used[id] then d.Visible = false end
    end
end

-- ===================== MOVEMENT / BRUTAL =====================
local FlyBV, FlyBG
local NoclipConn, JumpConn
local AirWalkPart

local function SetFly(on)
    local char = LocalPlayer.Character
    if not char then return end
    local root = GetRoot(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end

    if on then
        hum.PlatformStand = true
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.MaxForce = Vector3.new(9e5, 9e5, 9e5)
        FlyBV.Velocity = Vector3.zero
        FlyBV.Parent = root
        FlyBG = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(9e5, 9e5, 9e5)
        FlyBG.P = 12000
        FlyBG.Parent = root

        AddConn(RunService.RenderStepped:Connect(function()
            if not B.Settings.Brutal.Fly or not FlyBV or not FlyBG then return end
            local cf = Camera.CFrame
            local move = Vector3.zero
            -- Keyboard
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end
            -- Mobile touch fallback: follow camera look when any touch is held
            if UserInputService.TouchEnabled and #UserInputService:GetTouches() > 0 then
                move = move + cf.LookVector
            end
            if move.Magnitude > 0.1 then
                FlyBV.Velocity = move.Unit * B.Settings.Brutal.FlySpeed
            else
                FlyBV.Velocity = Vector3.zero
            end
            FlyBG.CFrame = cf
        end))
    else
        if hum then hum.PlatformStand = false end
    end
end

local function SetSpeed(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then
        B.OriginalWalkSpeed = hum.WalkSpeed
        hum.WalkSpeed = B.Settings.Brutal.SpeedValue
    else
        hum.WalkSpeed = B.OriginalWalkSpeed or 16
    end
end

local function SetNoclip(on)
    if NoclipConn then
        NoclipConn:Disconnect()
        NoclipConn = nil
    end
    -- restore previous
    for part, col in pairs(B.OriginalCollision) do
        if part and part.Parent then
            pcall(function() part.CanCollide = col end)
        end
    end
    B.OriginalCollision = {}

    if on then
        NoclipConn = RunService.Stepped:Connect(function()
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
        AddConn(NoclipConn)
    end
end

local function SetInfiniteJump(on)
    if JumpConn then
        JumpConn:Disconnect()
        JumpConn = nil
    end
    if on then
        JumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        AddConn(JumpConn)
    end
end

local function SetSuperJump(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then
        B.OriginalJumpPower = hum.JumpPower
        B.OriginalJumpHeight = hum.JumpHeight
        hum.JumpPower = B.Settings.Brutal.SuperJumpPower
        hum.JumpHeight = B.Settings.Brutal.SuperJumpPower / 3.5
    else
        hum.JumpPower = B.OriginalJumpPower or 50
        hum.JumpHeight = B.OriginalJumpHeight or 7.2
    end
end

local function SetNoFall(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        AddConn(hum.StateChanged:Connect(function(_, new)
            if B.Settings.Brutal.NoFallDamage and new == Enum.HumanoidStateType.Landed then
                hum.Health = hum.Health -- no-op keep
            end
        end))
    else
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
end

local function SetGod(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        AddConn(hum.HealthChanged:Connect(function()
            if B.Settings.Brutal.GodMode or B.Settings.Brutal.InfiniteHealth then
                hum.Health = math.huge
            end
        end))
    else
        hum.MaxHealth = 100
        if hum.Health > 100 then hum.Health = 100 end
    end
end

local function SetHitbox(on)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = GetChar(p)
            if char then
                local root = GetRoot(char)
                if root then
                    if on then
                        root.Size = Vector3.new(B.Settings.Brutal.HitboxSize, B.Settings.Brutal.HitboxSize, B.Settings.Brutal.HitboxSize)
                        root.Transparency = 0.65
                        root.CanCollide = false
                    else
                        root.Size = Vector3.new(2, 2, 1)
                        root.Transparency = 1
                    end
                end
            end
        end
    end
end

local function SetAirWalk(on)
    if AirWalkPart then
        AirWalkPart:Destroy()
        AirWalkPart = nil
    end
    if on then
        local char = LocalPlayer.Character
        local root = char and GetRoot(char)
        if not root then return end
        AirWalkPart = Instance.new("Part")
        AirWalkPart.Size = Vector3.new(6, 0.3, 6)
        AirWalkPart.Anchored = true
        AirWalkPart.CanCollide = true
        AirWalkPart.Transparency = 1
        AirWalkPart.Parent = Workspace
        AddConn(RunService.Heartbeat:Connect(function()
            if not B.Settings.Brutal.AirWalk or not AirWalkPart then return end
            local r = GetRoot(LocalPlayer.Character)
            if r then
                AirWalkPart.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.1, r.Position.Z)
            end
        end))
    end
end

local function AttemptKillAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and TeamOK(p) then
            local char = GetChar(p)
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum.Health = 0 end) end
            end
        end
    end
end

-- ===================== UI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BAXTARA_X_CHEAT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- Loading
local LoadF = Instance.new("Frame")
LoadF.Size = UDim2.new(1,0,1,0)
LoadF.BackgroundColor3 = Color3.fromRGB(8,10,14)
LoadF.BorderSizePixel = 0
LoadF.Parent = ScreenGui

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1,0,0,36)
LoadTitle.Position = UDim2.new(0,0,0.36,0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "BAXTARA X CHEAT"
LoadTitle.TextColor3 = Color3.fromRGB(0,255,140)
LoadTitle.Font = Enum.Font.Code
LoadTitle.TextSize = 26
LoadTitle.Parent = LoadF

local LoadSub = Instance.new("TextLabel")
LoadSub.Size = UDim2.new(1,0,0,20)
LoadSub.Position = UDim2.new(0,0,0.36,38)
LoadSub.BackgroundTransparency = 1
LoadSub.Text = "NUGI CENEL  |  @BAXTARA X CHEAT"
LoadSub.TextColor3 = Color3.fromRGB(90,130,110)
LoadSub.Font = Enum.Font.Code
LoadSub.TextSize = 13
LoadSub.Parent = LoadF

local BarBG = Instance.new("Frame")
BarBG.Size = UDim2.new(0,260,0,5)
BarBG.Position = UDim2.new(0.5,-130,0.5,0)
BarBG.BackgroundColor3 = Color3.fromRGB(28,36,42)
BarBG.BorderSizePixel = 0
BarBG.Parent = LoadF
local Bar = Instance.new("Frame")
Bar.Size = UDim2.new(0,0,1,0)
Bar.BackgroundColor3 = Color3.fromRGB(0,255,140)
Bar.BorderSizePixel = 0
Bar.Parent = BarBG
local LoadStat = Instance.new("TextLabel")
LoadStat.Size = UDim2.new(1,0,0,18)
LoadStat.Position = UDim2.new(0,0,0.5,12)
LoadStat.BackgroundTransparency = 1
LoadStat.Text = "assembling dashboard blocks..."
LoadStat.TextColor3 = Color3.fromRGB(130,150,140)
LoadStat.Font = Enum.Font.Code
LoadStat.TextSize = 12
LoadStat.Parent = LoadF

-- Main Panel (responsive-ish)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local panelW = isMobile and math.min(360, Camera.ViewportSize.X - 20) or 400
local panelH = isMobile and math.min(480, Camera.ViewportSize.Y - 40) or 500

local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.new(0, panelW, 0, panelH)
Main.Position = UDim2.new(0.5, -panelW/2, 0.5, -panelH/2)
Main.BackgroundColor3 = B.Settings.UI.Background
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,6)
MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0,170,95)
MainStroke.Thickness = 1.1
MainStroke.Transparency = 0.35
MainStroke.Parent = Main

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,34)
TitleBar.BackgroundColor3 = Color3.fromRGB(14,18,22)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1,-90,1,0)
TitleLbl.Position = UDim2.new(0,10,0,0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "❯ BAXTARA X CHEAT"
TitleLbl.TextColor3 = Color3.fromRGB(0,255,140)
TitleLbl.Font = Enum.Font.Code
TitleLbl.TextSize = 14
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,34,0,34)
CloseBtn.Position = UDim2.new(1,-34,0,0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,80,80)
CloseBtn.Font = Enum.Font.Code
CloseBtn.TextSize = 15
CloseBtn.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,34,0,34)
MinBtn.Position = UDim2.new(1,-68,0,0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(200,200,90)
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 17
MinBtn.Parent = TitleBar

-- Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,30)
TabBar.Position = UDim2.new(0,0,0,34)
TabBar.BackgroundColor3 = Color3.fromRGB(16,20,26)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local TabNames = {"AIM","ESP","BRUTAL","SETTINGS"}
local TabBtns, TabFrames = {}, {}
local ActiveTab = "AIM"

local function SwitchTab(name)
    ActiveTab = name
    for n, f in pairs(TabFrames) do
        f.Visible = (n == name)
        TabBtns[n].TextColor3 = (n == name) and Color3.fromRGB(0,255,140) or Color3.fromRGB(130,150,140)
        TabBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(22,28,34) or Color3.fromRGB(16,20,26)
    end
end

for i, name in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25,0,1,0)
    btn.Position = UDim2.new((i-1)*0.25,0,0,0)
    btn.BackgroundColor3 = Color3.fromRGB(16,20,26)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(130,150,140)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Parent = TabBar
    TabBtns[name] = btn

    local sc = Instance.new("ScrollingFrame")
    sc.Size = UDim2.new(1,-12,1,-72)
    sc.Position = UDim2.new(0,6,0,68)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(0,190,110)
    sc.CanvasSize = UDim2.new(0,0,0,0)
    sc.Visible = false
    sc.Parent = Main
    TabFrames[name] = sc

    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end
SwitchTab("AIM")

-- UI helpers
local function MakeSection(parent, title)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,22)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = "– "..title
    l.TextColor3 = Color3.fromRGB(0,200,120)
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h
    return h
end

local function MakeToggle(parent, text, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,28)
    h.BackgroundTransparency = 1
    h.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-56,1,0)
    l.Position = UDim2.new(0,4,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0,42,0,20)
    bg.Position = UDim2.new(1,-48,0.5,-10)
    bg.BackgroundColor3 = default and Color3.fromRGB(0,155,85) or Color3.fromRGB(40,48,55)
    bg.BorderSizePixel = 0
    bg.Parent = h
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1,0)
    bc.Parent = bg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,16,0,16)
    knob.Position = default and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3 = Color3.fromRGB(240,245,250)
    knob.BorderSizePixel = 0
    knob.Parent = bg
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1,0)
    kc.Parent = knob

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = h

    local function set(v)
        state = v
        TweenService:Create(bg, TweenInfo.new(0.12), {
            BackgroundColor3 = v and Color3.fromRGB(0,155,85) or Color3.fromRGB(40,48,55)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.12), {
            Position = v and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        }):Play()
        if cb then cb(v) end
    end
    btn.MouseButton1Click:Connect(function() set(not state) end)
    return h, set
end

local function MakeSlider(parent, text, min, max, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,40)
    h.BackgroundTransparency = 1
    h.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-50,0,16)
    l.Position = UDim2.new(0,4,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0,48,0,16)
    val.Position = UDim2.new(1,-52,0,0)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = B.Settings.UI.Accent
    val.Font = Enum.Font.Code
    val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = h

    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1,-8,0,8)
    barBG.Position = UDim2.new(0,4,0,22)
    barBG.BackgroundColor3 = Color3.fromRGB(35,42,50)
    barBG.BorderSizePixel = 0
    barBG.Parent = h
    local bbc = Instance.new("UICorner")
    bbc.CornerRadius = UDim.new(1,0)
    bbc.Parent = barBG

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = B.Settings.UI.Accent
    fill.BorderSizePixel = 0
    fill.Parent = barBG
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1,0)
    fc.Parent = fill

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - barBG.AbsolutePosition.X) / barBG.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max-min)*rel + 0.5)
        fill.Size = UDim2.new(rel,0,1,0)
        val.Text = tostring(v)
        if cb then cb(v) end
    end

    barBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    barBG.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    AddConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end))
    return h
end

local function Layout(frame)
    local y = 2
    for _, ch in ipairs(frame:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextLabel") or ch:IsA("TextButton") then
            ch.Position = UDim2.new(0,0,0,y)
            y = y + ch.AbsoluteSize.Y + 3
            if ch.AbsoluteSize.Y < 2 then
                y = y + (ch.Size.Y.Offset > 0 and ch.Size.Y.Offset or 20) + 3
            end
        end
    end
    -- force canvas after a frame
    task.defer(function()
        local maxY = 4
        for _, ch in ipairs(frame:GetChildren()) do
            if ch:IsA("GuiObject") then
                maxY = math.max(maxY, ch.Position.Y.Offset + ch.AbsoluteSize.Y + 6)
            end
        end
        frame.CanvasSize = UDim2.new(0,0,0,maxY)
    end)
end

-- Build AIM
do
    local f = TabFrames.AIM
    MakeSection(f, "Core")
    MakeToggle(f, "Enable Aimbot", false, function(v)
        B.Settings.Aim.Enabled = v
        if v then MakeFOV() MakeLine() end
    end)
    MakeToggle(f, "Visibility Check", true, function(v) B.Settings.Aim.VisibilityCheck = v end)
    MakeToggle(f, "Head Aim", true, function(v)
        B.Settings.Aim.HeadAim = v
        if v then B.Settings.Aim.BodyAim = false B.Settings.Aim.AimPart = "Head" end
    end)
    MakeToggle(f, "Body Aim", false, function(v)
        B.Settings.Aim.BodyAim = v
        if v then B.Settings.Aim.HeadAim = false B.Settings.Aim.AimPart = "HumanoidRootPart" end
    end)
    MakeToggle(f, "Multi-Bone Aim", false, function(v) B.Settings.Aim.MultiBone = v end)

    MakeSection(f, "FOV & Range")
    MakeToggle(f, "Dynamic FOV", false, function(v) B.Settings.Aim.DynamicFOV = v end)
    MakeToggle(f, "FOV Circle", true, function(v) B.Settings.Aim.FOVCircle = v end)
    MakeSlider(f, "FOV Size", 40, 400, 120, function(v) B.Settings.Aim.FOV = v end)
    MakeSlider(f, "Aim Distance", 50, 2000, 500, function(v) B.Settings.Aim.AimDistance = v end)

    MakeSection(f, "Behavior")
    MakeToggle(f, "Aim Lock", false, function(v) B.Settings.Aim.AimLock = v if not v then B.LockedTarget = nil end end)
    MakeToggle(f, "Target Switch (when lock lost)", false, function(v) B.Settings.Aim.TargetSwitch = v end)
    MakeToggle(f, "Aim Prediction", false, function(v) B.Settings.Aim.AimPrediction = v end)
    MakeSlider(f, "Smoothing (x100)", 1, 40, 15, function(v) B.Settings.Aim.AimSmoothing = v/100 end)
    MakeSlider(f, "Sensitivity (x10)", 1, 25, 10, function(v) B.Settings.Aim.AimSensitivity = v/10 end)
    MakeToggle(f, "Draw Target Line", true, function(v) B.Settings.Aim.DrawTargetLine = v end)
    MakeToggle(f, "Target Highlight", true, function(v) B.Settings.Aim.TargetHighlight = v end)
    MakeToggle(f, "Team Check", true, function(v) B.Settings.Aim.TeamCheck = v end)
    Layout(f)
end

-- Build ESP
do
    local f = TabFrames.ESP
    MakeSection(f, "Player ESP")
    MakeToggle(f, "Enable ESP", false, function(v) B.Settings.ESP.Enabled = v end)
    MakeToggle(f, "Box", true, function(v) B.Settings.ESP.Box = v end)
    MakeToggle(f, "Name", true, function(v) B.Settings.ESP.Name = v end)
    MakeToggle(f, "Health Bar", true, function(v) B.Settings.ESP.HealthBar = v end)
    MakeToggle(f, "Distance", true, function(v) B.Settings.ESP.Distance = v end)
    MakeToggle(f, "Tracer", false, function(v) B.Settings.ESP.Tracer = v end)
    MakeToggle(f, "Skeleton", false, function(v) B.Settings.ESP.Skeleton = v end)
    MakeToggle(f, "Visible Check", true, function(v) B.Settings.ESP.VisibleCheck = v end)
    MakeToggle(f, "Priority Mark", true, function(v) B.Settings.ESP.PriorityMark = v end)
    MakeToggle(f, "Weapon / Status", true, function(v)
        B.Settings.ESP.WeaponESP = v
        B.Settings.ESP.StatusESP = v
    end)
    MakeToggle(f, "Offscreen Arrows", true, function(v) B.Settings.ESP.Offscreen = v end)
    MakeToggle(f, "Radar", false, function(v) B.Settings.ESP.Radar = v end)
    MakeSlider(f, "Max Distance", 100, 2000, 800, function(v) B.Settings.ESP.MaxDistance = v end)

    MakeSection(f, "Object ESP")
    MakeToggle(f, "Item", false, function(v) B.Settings.ESP.ItemESP = v end)
    MakeToggle(f, "Loot", false, function(v) B.Settings.ESP.LootESP = v end)
    MakeToggle(f, "Chest", false, function(v) B.Settings.ESP.ChestESP = v end)
    MakeToggle(f, "Vehicle", false, function(v) B.Settings.ESP.VehicleESP = v end)
    MakeToggle(f, "NPC", false, function(v) B.Settings.ESP.NPCESP = v end)
    MakeToggle(f, "Boss", false, function(v) B.Settings.ESP.BossESP = v end)
    MakeToggle(f, "Door", false, function(v) B.Settings.ESP.DoorESP = v end)
    MakeToggle(f, "Key", false, function(v) B.Settings.ESP.KeyESP = v end)
    MakeToggle(f, "Exit", false, function(v) B.Settings.ESP.ExitESP = v end)
    Layout(f)
end

-- Build BRUTAL
do
    local f = TabFrames.BRUTAL
    MakeSection(f, "Movement")
    MakeToggle(f, "Fly", false, function(v) B.Settings.Brutal.Fly = v SetFly(v) end)
    MakeSlider(f, "Fly Speed", 10, 150, 50, function(v) B.Settings.Brutal.FlySpeed = v end)
    MakeToggle(f, "Speed Hack", false, function(v) B.Settings.Brutal.SpeedHack = v SetSpeed(v) end)
    MakeSlider(f, "Speed Value", 16, 120, 32, function(v)
        B.Settings.Brutal.SpeedValue = v
        if B.Settings.Brutal.SpeedHack then SetSpeed(true) end
    end)
    MakeToggle(f, "Infinite Jump", false, function(v) B.Settings.Brutal.InfiniteJump = v SetInfiniteJump(v) end)
    MakeToggle(f, "Noclip", false, function(v) B.Settings.Brutal.Noclip = v SetNoclip(v) end)
    MakeToggle(f, "Super Jump", false, function(v) B.Settings.Brutal.SuperJump = v SetSuperJump(v) end)
    MakeSlider(f, "Jump Power", 50, 300, 100, function(v)
        B.Settings.Brutal.SuperJumpPower = v
        if B.Settings.Brutal.SuperJump then SetSuperJump(true) end
    end)
    MakeToggle(f, "Air Walk", false, function(v) B.Settings.Brutal.AirWalk = v SetAirWalk(v) end)
    MakeToggle(f, "No Fall Damage", false, function(v) B.Settings.Brutal.NoFallDamage = v SetNoFall(v) end)

    MakeSection(f, "Combat (Local attempt)")
    MakeToggle(f, "God Mode", false, function(v) B.Settings.Brutal.GodMode = v SetGod(v) end)
    MakeToggle(f, "Infinite Health", false, function(v) B.Settings.Brutal.InfiniteHealth = v SetGod(v) end)
    MakeToggle(f, "Hitbox Expand", false, function(v) B.Settings.Brutal.HitboxExpand = v SetHitbox(v) end)
    MakeSlider(f, "Hitbox Size", 2, 25, 8, function(v)
        B.Settings.Brutal.HitboxSize = v
        if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
    end)
    MakeToggle(f, "Kill All (Local)", false, function(v)
        B.Settings.Brutal.KillAll = v
        if v then AttemptKillAll() end
    end)
    MakeToggle(f, "Auto Kill (Local)", false, function(v) B.Settings.Brutal.AutoKill = v end)
    Layout(f)
end

-- Build SETTINGS (fixed layout)
do
    local f = TabFrames.SETTINGS
    MakeSection(f, "Visual")
    MakeToggle(f, "FullBright", false, function(v)
        B.Settings.Visual.FullBright = v
        if v then
            Lighting.Brightness = 3
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e6
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
        end
    end)
    MakeToggle(f, "No Fog", false, function(v)
        B.Settings.Visual.NoFog = v
        Lighting.FogEnd = v and 9e6 or 1000
    end)

    MakeSection(f, "Streaming Mode")
    MakeToggle(f, "Streaming Mode (Dim UI)", false, function(v)
        B.Settings.Visual.StreamingMode = v
        local op = v and B.Settings.Visual.StreamingOpacity or 1
        Main.BackgroundTransparency = 1 - op
        TitleBar.BackgroundTransparency = 1 - op
        TabBar.BackgroundTransparency = 1 - op
        MainStroke.Transparency = v and (0.35 + (1-op)*0.4) or 0.35
    end)
    MakeSlider(f, "Dim Opacity %", 10, 90, 35, function(v)
        B.Settings.Visual.StreamingOpacity = v / 100
        if B.Settings.Visual.StreamingMode then
            local op = B.Settings.Visual.StreamingOpacity
            Main.BackgroundTransparency = 1 - op
            TitleBar.BackgroundTransparency = 1 - op
            TabBar.BackgroundTransparency = 1 - op
        end
    end)

    MakeSection(f, "Credits")
    local creditF = Instance.new("Frame")
    creditF.Size = UDim2.new(1,-4,0,70)
    creditF.BackgroundTransparency = 1
    creditF.Parent = f
    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1,0,1,0)
    credit.BackgroundTransparency = 1
    credit.Text = "Developer : NUGI CENEL\nChannel   : @BAXTARA X CHEAT\nScript    : BAXTARA X CHEAT v2\nKeybind   : RightControl / Tap title"
    credit.TextColor3 = Color3.fromRGB(0,190,120)
    credit.Font = Enum.Font.Code
    credit.TextSize = 12
    credit.TextXAlignment = Enum.TextXAlignment.Left
    credit.TextYAlignment = Enum.TextYAlignment.Top
    credit.Parent = creditF

    local unloadHolder = Instance.new("Frame")
    unloadHolder.Size = UDim2.new(1,-4,0,36)
    unloadHolder.BackgroundTransparency = 1
    unloadHolder.Parent = f
    local unloadBtn = Instance.new("TextButton")
    unloadBtn.Size = UDim2.new(1,0,1,0)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(110,28,28)
    unloadBtn.Text = "UNLOAD SCRIPT"
    unloadBtn.TextColor3 = Color3.fromRGB(255,200,200)
    unloadBtn.Font = Enum.Font.Code
    unloadBtn.TextSize = 13
    unloadBtn.Parent = unloadHolder
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0,4)
    uc.Parent = unloadBtn
    unloadBtn.MouseButton1Click:Connect(function()
        CleanupAll()
        if RadarFrame then RadarFrame:Destroy() end
        ScreenGui:Destroy()
        getgenv().BAXTARA = nil
    end)

    Layout(f)
end

-- Dragging (mouse + touch)
local dragging, dragStart, startPos
local function beginDrag(input)
    dragging = true
    dragStart = input.Position
    startPos = Main.Position
end
local function endDrag()
    dragging = false
end
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        beginDrag(input)
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)
AddConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end))

-- Open / Close
local function ShowPanel()
    Main.Visible = true
    Main.Size = UDim2.new(0, panelW, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, panelW, 0, panelH)
    }):Play()
end
local function HidePanel()
    local tw = TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, panelW, 0, 0)
    })
    tw:Play()
    tw.Completed:Wait()
    Main.Visible = false
end
CloseBtn.MouseButton1Click:Connect(HidePanel)
MinBtn.MouseButton1Click:Connect(HidePanel)

-- Keybind + mobile open (tap title when closed is handled by reopen)
AddConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        if Main.Visible then HidePanel() else ShowPanel() end
    end
end))

-- Floating reopen button for mobile
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 48, 0, 48)
OpenBtn.Position = UDim2.new(1, -60, 0.5, -24)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 90)
OpenBtn.Text = "BX"
OpenBtn.TextColor3 = Color3.fromRGB(240,255,245)
OpenBtn.Font = Enum.Font.Code
OpenBtn.TextSize = 16
OpenBtn.Visible = isMobile
OpenBtn.Parent = ScreenGui
local obc = Instance.new("UICorner")
obc.CornerRadius = UDim.new(1,0)
obc.Parent = OpenBtn
OpenBtn.MouseButton1Click:Connect(function()
    if Main.Visible then HidePanel() else ShowPanel() end
end)

-- Main loops
MakeFOV()
MakeLine()

AddConn(RunService.RenderStepped:Connect(function()
    UpdateAim()
    UpdatePlayerESP()
    UpdateRadar()
end))

AddConn(RunService.Heartbeat:Connect(function()
    if B.Settings.Brutal.AutoKill then
        AttemptKillAll()
    end
    ScanObjects()
end))

-- Respawn restore
local function OnChar(char)
    task.wait(0.4)
    if B.Settings.Brutal.SpeedHack then SetSpeed(true) end
    if B.Settings.Brutal.Fly then SetFly(true) end
    if B.Settings.Brutal.Noclip then SetNoclip(true) end
    if B.Settings.Brutal.InfiniteJump then SetInfiniteJump(true) end
    if B.Settings.Brutal.SuperJump then SetSuperJump(true) end
    if B.Settings.Brutal.GodMode or B.Settings.Brutal.InfiniteHealth then SetGod(true) end
    if B.Settings.Brutal.NoFallDamage then SetNoFall(true) end
    if B.Settings.Brutal.AirWalk then SetAirWalk(true) end
    if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
end
if LocalPlayer.Character then OnChar(LocalPlayer.Character) end
AddConn(LocalPlayer.CharacterAdded:Connect(OnChar))

-- Loading anim
task.spawn(function()
    local steps = {
        {0.12, "loading core modules..."},
        {0.28, "building aim controller..."},
        {0.45, "assembling ESP renderer..."},
        {0.60, "linking movement handlers..."},
        {0.75, "painting Termux interface..."},
        {0.88, "finalizing NUGI CENEL build..."},
        {1.00, "ready."},
    }
    for _, s in ipairs(steps) do
        Bar:TweenSize(UDim2.new(s[1],0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
        LoadStat.Text = s[2]
        task.wait(0.25)
    end
    task.wait(0.3)
    LoadF:Destroy()
    ShowPanel()
end)

print("[BAXTARA X CHEAT v2] Loaded | NUGI CENEL | @BAXTARA X CHEAT")
print("[BAXTARA] RightControl or BX button = toggle panel")
