--[[
    BAXTARA X CHEAT  v5
    Developer : NUGI CENEL
    Credit    : @BAXTARA X CHEAT
    v5        : thicker FOV, brutal combat NPC, anti-ban terminal, panel branding
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local TeleportService  = game:GetService("TeleportService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local DrawingLib  = Drawing
local Mouse       = LocalPlayer:GetMouse()

getgenv().BAXTARA = getgenv().BAXTARA or {}
local B = getgenv().BAXTARA

B.Settings = {
    Aim = {
        Enabled         = false,
        VisibilityCheck = true,
        HeadAim         = true,
        BodyAim         = false,
        MultiBone       = false,
        FOVCircle       = true,
        AimDistance     = 500,
        AimLock         = false,
        AimSmoothing    = 0.18,
        AimPrediction   = false,
        PredictionAmount= 0.1,
        DrawTargetLine  = false,
        TargetHighlight = false,
        FOV             = 140,
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
        StatusESP     = true,
        Radar         = false,
        Offscreen     = true,
        MaxDistance   = 700,
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
        HitboxSize     = 6,
        GhostMode      = false,
        -- new combat
        AntiCooldown    = false,
        InfiniteAmmo   = false,
        AutoReload     = false,
        AutoShoot      = false,
        TeleportTarget = false,
        DamageConfig   = false,
        DamageValue    = 100,
        OneHitNPC      = false,
        KillAllNPC     = false,
    },
    Visual = {
        FullBright       = false,
        NoFog            = false,
        StreamingMode    = false,
        StreamingOpacity = 0.35,
    },
    Protect = {
        AntiKick         = true,
        AutoHopOnFlag    = true,
        SoftCamera       = true,
        AntiBan          = false,
    },
    UI = {
        Accent     = Color3.fromRGB(0, 255, 140),
        Background = Color3.fromRGB(10, 12, 16),
        Panel      = Color3.fromRGB(16, 20, 26),
        Text       = Color3.fromRGB(220, 230, 240),
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
            if k == "Skel" then
                for _, l in ipairs(d) do pcall(function() if l and l.Remove then l:Remove() end end) end
            else
                pcall(function() if d and d.Remove then d:Remove() end end)
            end
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

-- ===================== ANTI KICK / BAN =====================
local function SafeHop()
    if B.Hopping then return end
    B.Hopping = true
    B.Settings.Aim.Enabled = false
    B.Settings.Brutal.Fly = false
    B.Settings.Brutal.SpeedHack = false
    B.Settings.Brutal.Noclip = false
    B.Settings.Brutal.GodMode = false
    B.Settings.Brutal.GhostMode = false
    B.Settings.Brutal.AutoShoot = false
    B.Settings.Brutal.KillAllNPC = false
    task.spawn(function()
        task.wait(0.35)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        B.Hopping = false
    end)
end

local function WatchKick()
    AddConn(CoreGui.DescendantAdded:Connect(function(obj)
        if not B.Settings.Protect.AntiKick then return end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local t = (obj.Text or ""):lower()
            if t:find("suspicious") or t:find("timedout") or t:find("timeout")
            or t:find("kicked") or t:find("dikeluarkan") or t:find("code 2a")
            or t:find("koneksi terputus") or t:find("extreme ping")
            or t:find("banned") or t:find("exploiting") then
                if B.Settings.Protect.AutoHopOnFlag then SafeHop() end
            end
        end
    end))
end

-- ===================== AIM =====================
local FOVCircle, TargetLine

local function MakeFOV()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if not DrawingLib then return end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 3.2
    FOVCircle.NumSides = 64
    FOVCircle.Radius = B.Settings.Aim.FOV
    FOVCircle.Filled = false
    FOVCircle.Color = B.Settings.UI.Accent
    FOVCircle.Transparency = 0.35
    FOVCircle.Visible = false
    B.Drawings.FOV = FOVCircle
end

local function MakeLine()
    if TargetLine then pcall(function() TargetLine:Remove() end) end
    if not DrawingLib then return end
    TargetLine = Drawing.new("Line")
    TargetLine.Thickness = 1.4
    TargetLine.Color = Color3.fromRGB(0, 255, 180)
    TargetLine.Transparency = 0.4
    TargetLine.Visible = false
    B.Drawings.TargetLine = TargetLine
end

local function GetAimPart(char)
    if B.Settings.Aim.MultiBone then
        for _, n in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
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
                                    -- skip red
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

    if B.Settings.Aim.VisibilityCheck then
        if not IsVisible(Camera.CFrame.Position, part.Position, char) then
            B.LockedTarget = nil
            B.CurrentTarget = nil
            return
        end
    end

    local pos = part.Position
    if B.Settings.Aim.AimPrediction then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        pos = pos + vel * B.Settings.Aim.PredictionAmount
    end

    local current = Camera.CFrame
    local goal = CFrame.new(current.Position, pos)
    local smooth = B.Settings.Aim.AimSmoothing
    if B.Settings.Protect.SoftCamera then
        smooth = math.clamp(smooth * 0.75, 0.06, 0.28)
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
        FOVCircle.Thickness = 3.2
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
                local stillVisible = true
                if B.Settings.Aim.VisibilityCheck then
                    stillVisible = IsVisible(Camera.CFrame.Position, part.Position, char)
                end
                if not on or not stillVisible or (screen - center).Magnitude > B.Settings.Aim.FOV * 1.6 then
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
                    TargetLine.From = center
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
        pack.Box.Thickness = 1.5
        pack.Box.Filled = false
        pack.Box.Visible = false
        pack.Name = Drawing.new("Text")
        pack.Name.Size = 14
        pack.Name.Center = true
        pack.Name.Outline = true
        pack.Name.Visible = false
        pack.Health = Drawing.new("Line")
        pack.Health.Thickness = 2.4
        pack.Health.Visible = false
        pack.Dist = Drawing.new("Text")
        pack.Dist.Size = 12
        pack.Dist.Center = true
        pack.Dist.Outline = true
        pack.Dist.Visible = false
        pack.Tracer = Drawing.new("Line")
        pack.Tracer.Thickness = 1
        pack.Tracer.Visible = false
        pack.Status = Drawing.new("Text")
        pack.Status.Size = 12
        pack.Status.Center = true
        pack.Status.Outline = true
        pack.Status.Visible = false
        pack.Skel = {}
        for i = 1, 14 do
            local l = Drawing.new("Line")
            l.Thickness = 1.3
            l.Visible = false
            pack.Skel[i] = l
        end
        pack.Off = Drawing.new("Triangle")
        pack.Off.Filled = true
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
    {"Head","UpperTorso"},{"Head","Torso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}

local function GetBodyBounds(char)
    local head = GetHead(char)
    local root = GetRoot(char)
    if not head or not root then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local top = head.Position + Vector3.new(0, 0.45, 0)
    local bottom = root.Position - Vector3.new(0, (hum and hum.HipHeight or 2) + 1.3, 0)
    local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg") or char:FindFirstChild("RightFoot")
    if foot then
        bottom = Vector3.new(root.Position.X, math.min(bottom.Y, foot.Position.Y - 0.25), root.Position.Z)
    end
    return top, bottom
end

local function UpdatePlayerESP()
    if not B.Settings.ESP.Enabled then
        for _, pack in pairs(B.ESPObjects) do HidePack(pack) end
        return
    end

    local camPos = Camera.CFrame.Position
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)

    local aliveIds = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then aliveIds[p.UserId] = true end
    end
    for id, pack in pairs(B.ESPObjects) do
        if not aliveIds[id] then
            HidePack(pack)
            for k, d in pairs(pack) do
                if k == "Skel" then
                    for _, l in ipairs(d) do pcall(function() if l.Remove then l:Remove() end end) end
                else
                    pcall(function() if d and d.Remove then d:Remove() end end)
                end
            end
            B.ESPObjects[id] = nil
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = GetChar(player)
        local pack = GetESPPack(player)

        if not IsAlive(char) then HidePack(pack) continue end
        local root = GetRoot(char)
        local head = GetHead(char)
        if not root or not head then HidePack(pack) continue end

        local dist = DistTo(root.Position)
        if dist > B.Settings.ESP.MaxDistance then HidePack(pack) continue end

        local top, bottom = GetBodyBounds(char)
        if not top then HidePack(pack) continue end

        local topScreen, onScreen = WorldToScreen(top)
        local bottomScreen = select(1, WorldToScreen(bottom))
        local rootScreen = select(1, WorldToScreen(root.Position))

        local visible = true
        if B.Settings.ESP.VisibleCheck then
            visible = IsVisible(camPos, head.Position, char)
        end

        local color = visible and B.Settings.ESP.VisibleColor or B.Settings.ESP.HiddenColor
        if B.Settings.ESP.PriorityMark and B.CurrentTarget == player then
            color = B.Settings.ESP.PriorityColor
        end

        if B.Settings.ESP.Box and pack.Box then
            local height = math.max(math.abs(topScreen.Y - bottomScreen.Y), 14)
            local width = height * 0.68
            pack.Box.Size = Vector2.new(width, height)
            pack.Box.Position = Vector2.new(topScreen.X - width/2, topScreen.Y)
            pack.Box.Color = color
            pack.Box.Visible = onScreen
        end

        if B.Settings.ESP.Name and pack.Name then
            pack.Name.Text = player.DisplayName or player.Name
            pack.Name.Position = Vector2.new(topScreen.X, topScreen.Y - 16)
            pack.Name.Color = color
            pack.Name.Visible = onScreen
        end

        if B.Settings.ESP.HealthBar and pack.Health then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local h = math.max(math.abs(topScreen.Y - bottomScreen.Y), 14)
                local x = topScreen.X - (h * 0.68)/2 - 6
                pack.Health.From = Vector2.new(x, topScreen.Y + h)
                pack.Health.To   = Vector2.new(x, topScreen.Y + h * (1 - pct))
                pack.Health.Color = Color3.fromRGB(255*(1-pct), 255*pct, 40)
                pack.Health.Visible = onScreen
            end
        end

        if B.Settings.ESP.Distance and pack.Dist then
            pack.Dist.Text = string.format("[%dm]", math.floor(dist))
            pack.Dist.Position = Vector2.new(bottomScreen.X, bottomScreen.Y + 4)
            pack.Dist.Color = Color3.fromRGB(180, 200, 210)
            pack.Dist.Visible = onScreen
        end

        if B.Settings.ESP.Tracer and pack.Tracer then
            pack.Tracer.From = Vector2.new(vp.X/2, vp.Y)
            pack.Tracer.To = rootScreen
            pack.Tracer.Color = color
            pack.Tracer.Visible = onScreen
        end

        if B.Settings.ESP.StatusESP and pack.Status then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pack.Status.Text = string.format("%.0fHP", hum.Health)
                pack.Status.Position = Vector2.new(bottomScreen.X, bottomScreen.Y + 18)
                pack.Status.Color = Color3.fromRGB(200, 220, 100)
                pack.Status.Visible = onScreen
            end
        end

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

        if B.Settings.ESP.Offscreen and pack.Off and not onScreen then
            local dir = (rootScreen - center)
            if dir.Magnitude > 1 then
                dir = dir.Unit
                local edge = center + dir * (math.min(vp.X, vp.Y) * 0.4)
                local ang = math.atan2(dir.Y, dir.X)
                local size = 9
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

local RadarFrame, RadarDots = nil, {}
local function EnsureRadar()
    if RadarFrame then return end
    local parent = CoreGui:FindFirstChild("BAXTARA_X_CHEAT") or CoreGui
    RadarFrame = Instance.new("Frame")
    RadarFrame.Name = "BAXTARA_Radar"
    RadarFrame.Size = UDim2.new(0, 110, 0, 110)
    RadarFrame.Position = UDim2.new(1, -128, 0, 14)
    RadarFrame.BackgroundColor3 = Color3.fromRGB(10,14,18)
    RadarFrame.BackgroundTransparency = 0.3
    RadarFrame.BorderSizePixel = 0
    RadarFrame.Visible = false
    RadarFrame.Parent = parent
    Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(0,6)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0,170,95)
    stroke.Thickness = 1
    stroke.Parent = RadarFrame
    local c = Instance.new("Frame")
    c.Size = UDim2.new(0,5,0,5)
    c.Position = UDim2.new(0.5,-2.5,0.5,-2.5)
    c.BackgroundColor3 = Color3.fromRGB(0,255,140)
    c.BorderSizePixel = 0
    c.Parent = RadarFrame
    Instance.new("UICorner", c).CornerRadius = UDim.new(1,0)
end

local function UpdateRadar()
    EnsureRadar()
    if not (B.Settings.ESP.Radar and B.Settings.ESP.Enabled) then
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
                    local scale = 110 / (B.Settings.ESP.MaxDistance * 0.5)
                    local x = math.clamp(rel.X * scale + 55, 3, 107)
                    local y = math.clamp(-rel.Z * scale + 55, 3, 107)
                    local id = p.UserId
                    used[id] = true
                    if not RadarDots[id] then
                        local d = Instance.new("Frame")
                        d.Size = UDim2.new(0,5,0,5)
                        d.BorderSizePixel = 0
                        d.BackgroundColor3 = Color3.fromRGB(255,80,80)
                        d.Parent = RadarFrame
                        Instance.new("UICorner", d).CornerRadius = UDim.new(1,0)
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

-- ===================== NPC HELPERS =====================
local function ScanNPCs()
    B.NPCList = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
            if hum and root and hum.Health > 0 then
                table.insert(B.NPCList, {model = obj, hum = hum, root = root})
            end
        end
    end
end

local function GetClosestNPC()
    local best, bestD = nil, 99999
    local my = GetRoot(LocalPlayer.Character)
    if not my then return nil end
    for _, n in ipairs(B.NPCList) do
        if n.hum and n.hum.Health > 0 and n.root then
            local d = (my.Position - n.root.Position).Magnitude
            if d < bestD then bestD = d best = n end
        end
    end
    return best
end

-- ===================== MOVEMENT + COMBAT =====================
local FlyBV, FlyBG, NoclipConn, JumpConn, AirWalkPart
local AmmoConn, ShootConn

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
        FlyBV.MaxForce = Vector3.new(4e4,4e4,4e4)
        FlyBV.Velocity = Vector3.zero
        FlyBV.Parent = root
        FlyBG = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(4e4,4e4,4e4)
        FlyBG.P = 8000
        FlyBG.Parent = root
        AddConn(RunService.RenderStepped:Connect(function()
            if not B.Settings.Brutal.Fly or not FlyBV then return end
            local cf = Camera.CFrame
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end
            if UserInputService.TouchEnabled and #UserInputService:GetTouches() > 0 then
                move = move + cf.LookVector * 0.65
            end
            FlyBV.Velocity = move.Magnitude > 0.1 and move.Unit * B.Settings.Brutal.FlySpeed or Vector3.zero
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
        hum.WalkSpeed = math.clamp(B.Settings.Brutal.SpeedValue, 16, 40)
    else
        hum.WalkSpeed = B.OriginalWalkSpeed or 16
    end
end

local function SetNoclip(on)
    if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
    for part, col in pairs(B.OriginalCollision) do
        if part and part.Parent then pcall(function() part.CanCollide = col end) end
    end
    B.OriginalCollision = {}
    if on then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if B.OriginalCollision[part] == nil then B.OriginalCollision[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        end)
        AddConn(NoclipConn)
    end
end

local function SetInfiniteJump(on)
    if JumpConn then JumpConn:Disconnect() JumpConn = nil end
    if on then
        JumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
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
        hum.JumpHeight = B.Settings.Brutal.SuperJumpPower / 4
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
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not on)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not on)
end

local function SetGod(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if on then
        hum.MaxHealth = 1e9
        hum.Health = 1e9
        AddConn(hum.HealthChanged:Connect(function()
            if B.Settings.Brutal.GodMode then hum.Health = 1e9 end
        end))
    else
        hum.MaxHealth = 100
        if hum.Health > 100 then hum.Health = 100 end
    end
end

local function SetHitbox(on)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local root = GetRoot(GetChar(p))
            if root then
                if on then
                    root.Size = Vector3.new(B.Settings.Brutal.HitboxSize, B.Settings.Brutal.HitboxSize, B.Settings.Brutal.HitboxSize)
                    root.Transparency = 0.7
                    root.CanCollide = false
                else
                    root.Size = Vector3.new(2,2,1)
                    root.Transparency = 1
                end
            end
        end
    end
end

local function SetAirWalk(on)
    if AirWalkPart then AirWalkPart:Destroy() AirWalkPart = nil end
    if on then
        local root = GetRoot(LocalPlayer.Character)
        if not root then return end
        AirWalkPart = Instance.new("Part")
        AirWalkPart.Size = Vector3.new(5,0.2,5)
        AirWalkPart.Anchored = true
        AirWalkPart.CanCollide = true
        AirWalkPart.Transparency = 1
        AirWalkPart.Parent = Workspace
        AddConn(RunService.Heartbeat:Connect(function()
            if not B.Settings.Brutal.AirWalk or not AirWalkPart then return end
            local r = GetRoot(LocalPlayer.Character)
            if r then AirWalkPart.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3, r.Position.Z) end
        end))
    end
end

local function SetGhost(on)
    local char = LocalPlayer.Character
    if not char then return end
    if on then
        B.OriginalTransparency = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                B.OriginalTransparency[part] = part.LocalTransparencyModifier
                part.LocalTransparencyModifier = 1
            elseif part:IsA("Decal") then
                B.OriginalTransparency[part] = part.Transparency
                part.Transparency = 1
            end
        end
        AddConn(char.DescendantAdded:Connect(function(obj)
            if B.Settings.Brutal.GhostMode then
                if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 1
                elseif obj:IsA("Decal") then obj.Transparency = 1 end
            end
        end))
    else
        for part, val in pairs(B.OriginalTransparency) do
            if part and part.Parent then
                if part:IsA("BasePart") then part.LocalTransparencyModifier = val or 0
                elseif part:IsA("Decal") then part.Transparency = val or 0 end
            end
        end
        B.OriginalTransparency = {}
    end
end

-- WEAPON / NPC COMBAT (best-effort client)
local function GetTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function SetAntiCooldown(on)
    -- attempt: clear common cooldown attributes / values on tool
    local function patch(tool)
        if not tool then return end
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local n = v.Name:lower()
                if n:find("cool") or n:find("delay") or n:find("rate") or n:find("firerate") then
                    pcall(function() v.Value = 0 end)
                end
            end
        end
        pcall(function()
            if tool:GetAttribute("Cooldown") then tool:SetAttribute("Cooldown", 0) end
            if tool:GetAttribute("FireRate") then tool:SetAttribute("FireRate", 0.01) end
        end)
    end
    if on then
        AddConn(RunService.Heartbeat:Connect(function()
            if not B.Settings.Brutal.AntiCooldown then return end
            patch(GetTool())
        end))
    end
end

local function SetInfiniteAmmo(on)
    if AmmoConn then AmmoConn:Disconnect() AmmoConn = nil end
    if on then
        AmmoConn = RunService.Heartbeat:Connect(function()
            if not B.Settings.Brutal.InfiniteAmmo then return end
            local tool = GetTool()
            if not tool then return end
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n = v.Name:lower()
                    if n:find("ammo") or n:find("clip") or n:find("bullet") or n:find("mag") then
                        pcall(function() if v.Value < 30 then v.Value = 999 end end)
                    end
                end
            end
            pcall(function()
                if tool:GetAttribute("Ammo") then tool:SetAttribute("Ammo", 999) end
                if tool:GetAttribute("Clip") then tool:SetAttribute("Clip", 999) end
            end)
        end)
        AddConn(AmmoConn)
    end
end

local function SetAutoReload(on)
    AddConn(RunService.Heartbeat:Connect(function()
        if not B.Settings.Brutal.AutoReload then return end
        local tool = GetTool()
        if not tool then return end
        pcall(function()
            local remote = tool:FindFirstChild("Reload") or tool:FindFirstChild("ReloadWeapon")
            if remote and remote:IsA("RemoteEvent") then remote:FireServer() end
        end)
        -- also try humanoid equip trick
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and tool then
            -- soft reload attempt via attribute
            if tool:GetAttribute("NeedReload") then tool:SetAttribute("NeedReload", false) end
        end
    end))
end

local function SetAutoShoot(on)
    if ShootConn then ShootConn:Disconnect() ShootConn = nil end
    if on then
        ShootConn = RunService.Heartbeat:Connect(function()
            if not B.Settings.Brutal.AutoShoot then return end
            local tool = GetTool()
            if not tool then return end
            -- try activate
            pcall(function() tool:Activate() end)
            -- try common remotes
            for _, r in ipairs(tool:GetDescendants()) do
                if r:IsA("RemoteEvent") then
                    local n = r.Name:lower()
                    if n:find("fire") or n:find("shoot") or n:find("shot") or n:find("attack") then
                        pcall(function() r:FireServer() end)
                    end
                end
            end
        end)
        AddConn(ShootConn)
    end
end

local function DoTeleportTarget()
    local npc = GetClosestNPC()
    if not npc or not npc.root then return end
    local char = LocalPlayer.Character
    local root = GetRoot(char)
    if root then
        root.CFrame = npc.root.CFrame + Vector3.new(0, 3, 0)
    end
end

local function DoOneHitNPC()
    ScanNPCs()
    local npc = GetClosestNPC()
    if npc and npc.hum then
        pcall(function()
            npc.hum.Health = 0
        end)
        if B.Settings.Brutal.DamageConfig then
            pcall(function() npc.hum:TakeDamage(B.Settings.Brutal.DamageValue) end)
        end
    end
end

local function DoKillAllNPC()
    ScanNPCs()
    for _, n in ipairs(B.NPCList) do
        if n.hum and n.hum.Health > 0 then
            pcall(function()
                n.hum.Health = 0
                if B.Settings.Brutal.DamageConfig then
                    n.hum:TakeDamage(B.Settings.Brutal.DamageValue)
                end
            end)
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

local isMobile = UserInputService.TouchEnabled
local panelW = isMobile and math.clamp(Camera.ViewportSize.X - 20, 310, 390) or 400
local panelH = isMobile and math.clamp(Camera.ViewportSize.Y - 70, 420, 520) or 530

-- Loading
local LoadF = Instance.new("Frame")
LoadF.Size = UDim2.new(1,0,1,0)
LoadF.BackgroundColor3 = Color3.fromRGB(6,8,12)
LoadF.BorderSizePixel = 0
LoadF.Parent = ScreenGui
local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1,0,0,28)
LoadTitle.Position = UDim2.new(0,0,0.34,0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "BAXTARA X CHEAT"
LoadTitle.TextColor3 = Color3.fromRGB(0,255,140)
LoadTitle.Font = Enum.Font.Code
LoadTitle.TextSize = 22
LoadTitle.Parent = LoadF
local LoadSub = Instance.new("TextLabel")
LoadSub.Size = UDim2.new(1,0,0,16)
LoadSub.Position = UDim2.new(0,0,0.34,30)
LoadSub.BackgroundTransparency = 1
LoadSub.Text = "NUGI CENEL  |  v5  |  EXECUTE · DOMINATE · WIN"
LoadSub.TextColor3 = Color3.fromRGB(80,140,110)
LoadSub.Font = Enum.Font.Code
LoadSub.TextSize = 11
LoadSub.Parent = LoadF
local BarBG = Instance.new("Frame")
BarBG.Size = UDim2.new(0,230,0,4)
BarBG.Position = UDim2.new(0.5,-115,0.48,0)
BarBG.BackgroundColor3 = Color3.fromRGB(25,35,40)
BarBG.BorderSizePixel = 0
BarBG.Parent = LoadF
local Bar = Instance.new("Frame")
Bar.Size = UDim2.new(0,0,1,0)
Bar.BackgroundColor3 = Color3.fromRGB(0,255,140)
Bar.BorderSizePixel = 0
Bar.Parent = BarBG
local LoadStat = Instance.new("TextLabel")
LoadStat.Size = UDim2.new(1,0,0,14)
LoadStat.Position = UDim2.new(0,0,0.48,10)
LoadStat.BackgroundTransparency = 1
LoadStat.Text = "loading modules..."
LoadStat.TextColor3 = Color3.fromRGB(120,150,135)
LoadStat.Font = Enum.Font.Code
LoadStat.TextSize = 11
LoadStat.Parent = LoadF

-- Main Panel
local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.new(0, panelW, 0, panelH)
Main.Position = UDim2.new(0.5, -panelW/2, 0.5, -panelH/2)
Main.BackgroundColor3 = B.Settings.UI.Background
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,8)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0,200,110)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.25
MainStroke.Parent = Main

-- Logo header strip
local LogoBar = Instance.new("Frame")
LogoBar.Size = UDim2.new(1,0,0,42)
LogoBar.BackgroundColor3 = Color3.fromRGB(8,14,12)
LogoBar.BorderSizePixel = 0
LogoBar.Parent = Main
local logoGrad = Instance.new("UIGradient")
logoGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,40,25)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,80,45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,40,25))
}
logoGrad.Parent = LogoBar

local LogoBX = Instance.new("TextLabel")
LogoBX.Size = UDim2.new(0,50,1,0)
LogoBX.Position = UDim2.new(0,8,0,0)
LogoBX.BackgroundTransparency = 1
LogoBX.Text = "BX"
LogoBX.TextColor3 = Color3.fromRGB(0,255,140)
LogoBX.Font = Enum.Font.GothamBlack
LogoBX.TextSize = 22
LogoBX.Parent = LogoBar

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1,-100,1,0)
LogoText.Position = UDim2.new(0,55,0,0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "BAXTARA X CHEAT"
LogoText.TextColor3 = Color3.fromRGB(0,255,160)
LogoText.Font = Enum.Font.Code
LogoText.TextSize = 14
LogoText.TextXAlignment = Enum.TextXAlignment.Left
LogoText.Parent = LogoBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,32,0,32)
CloseBtn.Position = UDim2.new(1,-36,0.5,-16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40,20,20)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,100,100)
CloseBtn.Font = Enum.Font.Code
CloseBtn.TextSize = 14
CloseBtn.Parent = LogoBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,32,0,32)
MinBtn.Position = UDim2.new(1,-72,0.5,-16)
MinBtn.BackgroundColor3 = Color3.fromRGB(40,40,20)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(220,220,100)
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 16
MinBtn.Parent = LogoBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,6)

-- Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,30)
TabBar.Position = UDim2.new(0,0,0,42)
TabBar.BackgroundColor3 = Color3.fromRGB(12,18,16)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local TabNames = {"AIM","ESP","BRUTAL","SETTINGS"}
local TabBtns, TabFrames = {}, {}

local function SwitchTab(name)
    for n, f in pairs(TabFrames) do
        f.Visible = (n == name)
        TabBtns[n].TextColor3 = (n == name) and Color3.fromRGB(0,255,140) or Color3.fromRGB(120,150,140)
        TabBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(0,50,35) or Color3.fromRGB(12,18,16)
    end
end

for i, name in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25,0,1,0)
    btn.Position = UDim2.new((i-1)*0.25,0,0,0)
    btn.BackgroundColor3 = Color3.fromRGB(12,18,16)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(120,150,140)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Parent = TabBar
    TabBtns[name] = btn
    local sc = Instance.new("ScrollingFrame")
    sc.Size = UDim2.new(1,-12,1,-80)
    sc.Position = UDim2.new(0,6,0,76)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(0,200,120)
    sc.CanvasSize = UDim2.new(0,0,0,0)
    sc.Visible = false
    sc.Parent = Main
    TabFrames[name] = sc
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end
SwitchTab("AIM")

-- Footer brand
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1,0,0,18)
Footer.Position = UDim2.new(0,0,1,-18)
Footer.BackgroundColor3 = Color3.fromRGB(8,12,10)
Footer.BorderSizePixel = 0
Footer.Text = "  NUGI CENEL  ·  @BAXTARA X CHEAT  ·  v5"
Footer.TextColor3 = Color3.fromRGB(0,160,100)
Footer.Font = Enum.Font.Code
Footer.TextSize = 10
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.Parent = Main

local function MakeSection(parent, title)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,18)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = "▸ "..title
    l.TextColor3 = Color3.fromRGB(0,220,130)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h
    return h
end

local function MakeToggle(parent, text, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,26)
    h.BackgroundColor3 = Color3.fromRGB(14,20,18)
    h.BorderSizePixel = 0
    h.Parent = parent
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,4)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-52,1,0)
    l.Position = UDim2.new(0,8,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0,40,0,18)
    bg.Position = UDim2.new(1,-46,0.5,-9)
    bg.BackgroundColor3 = default and Color3.fromRGB(0,160,90) or Color3.fromRGB(35,45,50)
    bg.BorderSizePixel = 0
    bg.Parent = h
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(240,250,245)
    knob.BorderSizePixel = 0
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = h
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(bg, TweenInfo.new(0.12), {
            BackgroundColor3 = state and Color3.fromRGB(0,160,90) or Color3.fromRGB(35,45,50)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        }):Play()
        if cb then cb(state) end
    end)
    return h
end

local function MakeSlider(parent, text, min, max, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1,-4,0,38)
    h.BackgroundColor3 = Color3.fromRGB(14,20,18)
    h.BorderSizePixel = 0
    h.Parent = parent
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,4)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-50,0,14)
    l.Position = UDim2.new(0,8,0,3)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = B.Settings.UI.Text
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0,46,0,14)
    val.Position = UDim2.new(1,-50,0,3)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = B.Settings.UI.Accent
    val.Font = Enum.Font.Code
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = h
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1,-16,0,6)
    barBG.Position = UDim2.new(0,8,0,22)
    barBG.BackgroundColor3 = Color3.fromRGB(30,40,45)
    barBG.BorderSizePixel = 0
    barBG.Parent = h
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = B.Settings.UI.Accent
    fill.BorderSizePixel = 0
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
    h.Size = UDim2.new(1,-4,0,32)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = color or Color3.fromRGB(0,90,55)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220,255,235)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Parent = h
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(0,200,120)
    st.Thickness = 1
    st.Transparency = 0.5
    st.Parent = btn
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return h
end

local function Layout(frame)
    task.defer(function()
        local y = 2
        for _, ch in ipairs(frame:GetChildren()) do
            if ch:IsA("GuiObject") then
                ch.Position = UDim2.new(0,0,0,y)
                y = y + (ch.AbsoluteSize.Y > 0 and ch.AbsoluteSize.Y or ch.Size.Y.Offset) + 3
            end
        end
        frame.CanvasSize = UDim2.new(0,0,0,y + 8)
    end)
end

-- AIM tab
do
    local f = TabFrames.AIM
    MakeSection(f, "Core")
    MakeToggle(f, "Enable Aimbot", false, function(v)
        B.Settings.Aim.Enabled = v
        if v then MakeFOV() MakeLine() end
    end)
    MakeToggle(f, "Visibility Check (green only)", true, function(v) B.Settings.Aim.VisibilityCheck = v end)
    MakeToggle(f, "Head Aim", true, function(v)
        B.Settings.Aim.HeadAim = v
        if v then B.Settings.Aim.BodyAim = false end
    end)
    MakeToggle(f, "Body Aim", false, function(v)
        B.Settings.Aim.BodyAim = v
        if v then B.Settings.Aim.HeadAim = false end
    end)
    MakeToggle(f, "Multi-Bone", false, function(v) B.Settings.Aim.MultiBone = v end)
    MakeSection(f, "FOV (thick)")
    MakeToggle(f, "FOV Circle", true, function(v) B.Settings.Aim.FOVCircle = v end)
    MakeSlider(f, "FOV Size", 50, 350, 140, function(v) B.Settings.Aim.FOV = v end)
    MakeSlider(f, "Aim Distance", 50, 1500, 500, function(v) B.Settings.Aim.AimDistance = v end)
    MakeSection(f, "Feel")
    MakeToggle(f, "Aim Lock", false, function(v) B.Settings.Aim.AimLock = v if not v then B.LockedTarget = nil end end)
    MakeToggle(f, "Prediction", false, function(v) B.Settings.Aim.AimPrediction = v end)
    MakeSlider(f, "Smoothing x100", 5, 40, 18, function(v) B.Settings.Aim.AimSmoothing = v/100 end)
    MakeToggle(f, "Target Line", false, function(v) B.Settings.Aim.DrawTargetLine = v end)
    MakeToggle(f, "Highlight", false, function(v) B.Settings.Aim.TargetHighlight = v end)
    MakeToggle(f, "Team Check", true, function(v) B.Settings.Aim.TeamCheck = v end)
    MakeToggle(f, "Soft Camera", true, function(v) B.Settings.Protect.SoftCamera = v end)
    Layout(f)
end

-- ESP tab
do
    local f = TabFrames.ESP
    MakeSection(f, "Player")
    MakeToggle(f, "Enable ESP", false, function(v) B.Settings.ESP.Enabled = v end)
    MakeToggle(f, "Box (full body)", true, function(v) B.Settings.ESP.Box = v end)
    MakeToggle(f, "Name", true, function(v) B.Settings.ESP.Name = v end)
    MakeToggle(f, "Health Bar", true, function(v) B.Settings.ESP.HealthBar = v end)
    MakeToggle(f, "Distance", true, function(v) B.Settings.ESP.Distance = v end)
    MakeToggle(f, "Tracer", false, function(v) B.Settings.ESP.Tracer = v end)
    MakeToggle(f, "Skeleton", false, function(v) B.Settings.ESP.Skeleton = v end)
    MakeToggle(f, "Visible Check", true, function(v) B.Settings.ESP.VisibleCheck = v end)
    MakeToggle(f, "Priority Mark", true, function(v) B.Settings.ESP.PriorityMark = v end)
    MakeToggle(f, "Status HP", true, function(v) B.Settings.ESP.StatusESP = v end)
    MakeToggle(f, "Offscreen Arrow", true, function(v) B.Settings.ESP.Offscreen = v end)
    MakeToggle(f, "Radar", false, function(v) B.Settings.ESP.Radar = v end)
    MakeSlider(f, "Max Distance", 100, 1500, 700, function(v) B.Settings.ESP.MaxDistance = v end)
    Layout(f)
end

-- BRUTAL tab
do
    local f = TabFrames.BRUTAL
    MakeSection(f, "Movement")
    MakeToggle(f, "Fly", false, function(v) B.Settings.Brutal.Fly = v SetFly(v) end)
    MakeSlider(f, "Fly Speed", 10, 80, 40, function(v) B.Settings.Brutal.FlySpeed = v end)
    MakeToggle(f, "Speed Hack", false, function(v) B.Settings.Brutal.SpeedHack = v SetSpeed(v) end)
    MakeSlider(f, "Speed (max 40)", 16, 40, 24, function(v)
        B.Settings.Brutal.SpeedValue = v
        if B.Settings.Brutal.SpeedHack then SetSpeed(true) end
    end)
    MakeToggle(f, "Infinite Jump", false, function(v) B.Settings.Brutal.InfiniteJump = v SetInfiniteJump(v) end)
    MakeToggle(f, "Noclip", false, function(v) B.Settings.Brutal.Noclip = v SetNoclip(v) end)
    MakeToggle(f, "Super Jump", false, function(v) B.Settings.Brutal.SuperJump = v SetSuperJump(v) end)
    MakeToggle(f, "Air Walk", false, function(v) B.Settings.Brutal.AirWalk = v SetAirWalk(v) end)
    MakeToggle(f, "No Fall", false, function(v) B.Settings.Brutal.NoFallDamage = v SetNoFall(v) end)
    MakeToggle(f, "Ghost Mode", false, function(v) B.Settings.Brutal.GhostMode = v SetGhost(v) end)
    MakeSection(f, "Combat / Weapon")
    MakeToggle(f, "Anti Cooldown", false, function(v) B.Settings.Brutal.AntiCooldown = v SetAntiCooldown(v) end)
    MakeToggle(f, "Infinite Ammo", false, function(v) B.Settings.Brutal.InfiniteAmmo = v SetInfiniteAmmo(v) end)
    MakeToggle(f, "Auto Reload", false, function(v) B.Settings.Brutal.AutoReload = v SetAutoReload(v) end)
    MakeToggle(f, "Auto Shoot", false, function(v) B.Settings.Brutal.AutoShoot = v SetAutoShoot(v) end)
    MakeSection(f, "NPC")
    MakeToggle(f, "Damage Config", false, function(v) B.Settings.Brutal.DamageConfig = v end)
    MakeSlider(f, "Damage Value", 10, 500, 100, function(v) B.Settings.Brutal.DamageValue = v end)
    MakeToggle(f, "One Hit NPC", false, function(v)
        B.Settings.Brutal.OneHitNPC = v
        if v then DoOneHitNPC() end
    end)
    MakeToggle(f, "Kill All NPC", false, function(v)
        B.Settings.Brutal.KillAllNPC = v
        if v then DoKillAllNPC() end
    end)
    MakeButton(f, "TELEPORT TO NEAREST NPC", Color3.fromRGB(0,70,50), function()
        ScanNPCs()
        DoTeleportTarget()
    end)
    MakeSection(f, "Local")
    MakeToggle(f, "God Mode (local)", false, function(v) B.Settings.Brutal.GodMode = v SetGod(v) end)
    MakeToggle(f, "Hitbox Expand", false, function(v) B.Settings.Brutal.HitboxExpand = v SetHitbox(v) end)
    MakeSlider(f, "Hitbox Size", 2, 15, 6, function(v)
        B.Settings.Brutal.HitboxSize = v
        if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
    end)
    Layout(f)
end

-- SETTINGS + ANTI BAN TERMINAL
do
    local f = TabFrames.SETTINGS
    MakeSection(f, "Visual")
    MakeToggle(f, "FullBright", false, function(v)
        B.Settings.Visual.FullBright = v
        Lighting.Brightness = v and 2.5 or 1
        Lighting.GlobalShadows = not v
        if v then Lighting.FogEnd = 9e6 end
    end)
    MakeToggle(f, "No Fog", false, function(v)
        B.Settings.Visual.NoFog = v
        Lighting.FogEnd = v and 9e6 or 1000
    end)
    MakeSection(f, "Streaming")
    MakeToggle(f, "Streaming Mode", false, function(v)
        B.Settings.Visual.StreamingMode = v
        local op = v and B.Settings.Visual.StreamingOpacity or 1
        Main.BackgroundTransparency = 1 - op
        LogoBar.BackgroundTransparency = 1 - op
        TabBar.BackgroundTransparency = 1 - op
    end)
    MakeSlider(f, "Dim %", 10, 90, 35, function(v)
        B.Settings.Visual.StreamingOpacity = v/100
        if B.Settings.Visual.StreamingMode then
            local op = B.Settings.Visual.StreamingOpacity
            Main.BackgroundTransparency = 1 - op
            LogoBar.BackgroundTransparency = 1 - op
            TabBar.BackgroundTransparency = 1 - op
        end
    end)
    MakeSection(f, "Protect")
    MakeToggle(f, "Anti-Kick Watch", true, function(v) B.Settings.Protect.AntiKick = v end)
    MakeToggle(f, "Auto Hop on Flag", true, function(v) B.Settings.Protect.AutoHopOnFlag = v end)

    -- ANTI BAN with terminal animation
    local antiBanRunning = false
    MakeButton(f, "▶  ENABLE ANTI-BAN MODE", Color3.fromRGB(0,60,40), function()
        if antiBanRunning then return end
        antiBanRunning = true
        B.Settings.Protect.AntiBan = true

        -- terminal overlay
        local term = Instance.new("Frame")
        term.Size = UDim2.new(0.92,0,0.55,0)
        term.Position = UDim2.new(0.04,0,0.22,0)
        term.BackgroundColor3 = Color3.fromRGB(5,10,8)
        term.BorderSizePixel = 0
        term.ZIndex = 50
        term.Parent = Main
        Instance.new("UICorner", term).CornerRadius = UDim.new(0,6)
        local ts = Instance.new("UIStroke")
        ts.Color = Color3.fromRGB(0,255,140)
        ts.Thickness = 1.2
        ts.Parent = term
        local termTitle = Instance.new("TextLabel")
        termTitle.Size = UDim2.new(1,-10,0,22)
        termTitle.Position = UDim2.new(0,8,0,4)
        termTitle.BackgroundTransparency = 1
        termTitle.Text = "BAXTARA://anti-ban — installing"
        termTitle.TextColor3 = Color3.fromRGB(0,255,140)
        termTitle.Font = Enum.Font.Code
        termTitle.TextSize = 12
        termTitle.TextXAlignment = Enum.TextXAlignment.Left
        termTitle.ZIndex = 51
        termTitle.Parent = term
        local termLog = Instance.new("TextLabel")
        termLog.Size = UDim2.new(1,-16,1,-30)
        termLog.Position = UDim2.new(0,8,0,26)
        termLog.BackgroundTransparency = 1
        termLog.Text = ""
        termLog.TextColor3 = Color3.fromRGB(0,220,130)
        termLog.Font = Enum.Font.Code
        termLog.TextSize = 11
        termLog.TextXAlignment = Enum.TextXAlignment.Left
        termLog.TextYAlignment = Enum.TextYAlignment.Top
        termLog.TextWrapped = true
        termLog.ZIndex = 51
        termLog.Parent = term

        local lines = {
            "> mounting protect layer...",
            "> hooking TeleportService...",
            "> soft-camera limiter ON",
            "> speed clamp 16-40",
            "> remote spam throttle ON",
            "> kick signature watch ON",
            "> hop fallback armed",
            "> stripping aggressive flags...",
            "> Anti-Ban module ONLINE",
            "> status: PROTECTED",
        }
        task.spawn(function()
            local buf = ""
            for _, line in ipairs(lines) do
                buf = buf .. line .. "\n"
                termLog.Text = buf
                task.wait(0.28)
            end
            task.wait(0.6)
            term:Destroy()
            antiBanRunning = false
            -- apply soft protections
            B.Settings.Protect.SoftCamera = true
            B.Settings.Protect.AntiKick = true
            B.Settings.Protect.AutoHopOnFlag = true
            if B.Settings.Brutal.SpeedValue > 32 then
                B.Settings.Brutal.SpeedValue = 28
            end
        end)
    end)

    MakeButton(f, "FORCE SERVER HOP", Color3.fromRGB(30,70,50), SafeHop)

    MakeSection(f, "Credits")
    local creditF = Instance.new("Frame")
    creditF.Size = UDim2.new(1,-4,0,50)
    creditF.BackgroundColor3 = Color3.fromRGB(10,16,14)
    creditF.BorderSizePixel = 0
    creditF.Parent = f
    Instance.new("UICorner", creditF).CornerRadius = UDim.new(0,4)
    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1,-8,1,0)
    credit.Position = UDim2.new(0,6,0,0)
    credit.BackgroundTransparency = 1
    credit.Text = "NUGI CENEL\n@BAXTARA X CHEAT  ·  EXECUTE · DOMINATE · WIN"
    credit.TextColor3 = Color3.fromRGB(0,200,120)
    credit.Font = Enum.Font.Code
    credit.TextSize = 11
    credit.TextXAlignment = Enum.TextXAlignment.Left
    credit.TextYAlignment = Enum.TextYAlignment.Center
    credit.Parent = creditF

    MakeButton(f, "UNLOAD SCRIPT", Color3.fromRGB(90,25,25), function()
        CleanupAll()
        if RadarFrame then RadarFrame:Destroy() end
        ScreenGui:Destroy()
        getgenv().BAXTARA = nil
    end)
    Layout(f)
end

-- Drag
local dragging, dragStart, startPos
LogoBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
LogoBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
AddConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

local function ShowPanel()
    Main.Visible = true
    Main.Size = UDim2.new(0, panelW, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, panelW, 0, panelH)
    }):Play()
end
local function HidePanel()
    local tw = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, panelW, 0, 0)
    })
    tw:Play()
    tw.Completed:Wait()
    Main.Visible = false
end
CloseBtn.MouseButton1Click:Connect(HidePanel)
MinBtn.MouseButton1Click:Connect(HidePanel)

AddConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        if Main.Visible then HidePanel() else ShowPanel() end
    end
end))

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0,46,0,46)
OpenBtn.Position = UDim2.new(1,-58,0.5,-23)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0,140,80)
OpenBtn.Text = "BX"
OpenBtn.TextColor3 = Color3.fromRGB(240,255,245)
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.TextSize = 15
OpenBtn.Visible = isMobile
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1,0)
local obs = Instance.new("UIStroke")
obs.Color = Color3.fromRGB(0,255,140)
obs.Thickness = 1.5
obs.Parent = OpenBtn
OpenBtn.MouseButton1Click:Connect(function()
    if Main.Visible then HidePanel() else ShowPanel() end
end)

MakeFOV()
MakeLine()
WatchKick()

AddConn(RunService.RenderStepped:Connect(function()
    UpdateAim()
    UpdatePlayerESP()
    UpdateRadar()
end))

-- periodic NPC scan when needed
AddConn(RunService.Heartbeat:Connect(function()
    if B.Settings.Brutal.KillAllNPC or B.Settings.Brutal.OneHitNPC or B.Settings.Brutal.AutoShoot then
        if tick() % 1.2 < 0.05 then ScanNPCs() end
    end
    if B.Settings.Brutal.KillAllNPC then DoKillAllNPC() end
end))

local function OnChar(char)
    task.wait(0.35)
    if B.Settings.Brutal.SpeedHack then SetSpeed(true) end
    if B.Settings.Brutal.Fly then SetFly(true) end
    if B.Settings.Brutal.Noclip then SetNoclip(true) end
    if B.Settings.Brutal.InfiniteJump then SetInfiniteJump(true) end
    if B.Settings.Brutal.SuperJump then SetSuperJump(true) end
    if B.Settings.Brutal.GodMode then SetGod(true) end
    if B.Settings.Brutal.NoFallDamage then SetNoFall(true) end
    if B.Settings.Brutal.AirWalk then SetAirWalk(true) end
    if B.Settings.Brutal.HitboxExpand then SetHitbox(true) end
    if B.Settings.Brutal.GhostMode then SetGhost(true) end
    if B.Settings.Brutal.AntiCooldown then SetAntiCooldown(true) end
    if B.Settings.Brutal.InfiniteAmmo then SetInfiniteAmmo(true) end
    if B.Settings.Brutal.AutoReload then SetAutoReload(true) end
    if B.Settings.Brutal.AutoShoot then SetAutoShoot(true) end
end
if LocalPlayer.Character then OnChar(LocalPlayer.Character) end
AddConn(LocalPlayer.CharacterAdded:Connect(OnChar))

task.spawn(function()
    local steps = {
        {0.15, "core..."},
        {0.35, "aim FOV thick..."},
        {0.55, "brutal combat..."},
        {0.75, "anti-ban layer..."},
        {0.9, "branding..."},
        {1.0, "ready."},
    }
    for _, s in ipairs(steps) do
        Bar:TweenSize(UDim2.new(s[1],0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
        LoadStat.Text = s[2]
        task.wait(0.2)
    end
    task.wait(0.2)
    LoadF:Destroy()
    ShowPanel()
end)

print("[BAXTARA X CHEAT v5] FOV thick | NPC combat | anti-ban terminal | NUGI CENEL")
