--[[
==============================================================================
  AETHER ESP
  Professional Drawing-only ESP framework for Roblox (Luau)
  No Highlight · No SelectionBox · No HandleAdornments · No third-party ESP libs

  loadstring(game:HttpGet("URL"))()
  local ESP = Aether  -- or return value of loadstring

  ESP:Enable()
  ESP:SetConfig({ ... })
  ESP:Destroy()
==============================================================================
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local Aether = {
    _version = "1.0.0",
    _alive   = true,
    _enabled = false,
    _conns   = {},
    _players = {}, -- [Player] = PlayerState
    _render  = nil,
}

--==============================================================================
-- DEFAULT CONFIG
--==============================================================================
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[k] = deepCopy(v)
    end
    return n
end

local DEFAULT_CONFIG = {
    Enabled = true,
    MaxDistance = 2000,
    TeamCheck = false,
    TeamColor = Color3.fromRGB(80, 180, 255),
    RenderTeammates = false, -- if TeamCheck and true, render with TeamColor instead of skip
    VisibilityCheck = false,
    ScaleWithDistance = true,
    MinScale = 0.65,
    MaxScale = 1.15,

    Box = {
        Enabled = true,
        Type = "Corner", -- Corner | Full
        Color = Color3.fromRGB(245, 245, 250),
        Thickness = 1.25,
        Transparency = 1, -- Drawing: treated as opacity multiplier (1 = full)
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        OutlineThickness = 2.4,
    },

    Name = {
        Enabled = true,
        UseDisplayName = true,
        Color = Color3.fromRGB(245, 245, 250),
        Size = 13,
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    Health = {
        Enabled = true,
        Bar = true,
        Text = false,
        Width = 2.5,
        Side = "Left", -- Left | Right
        Gradient = true,
        HighColor = Color3.fromRGB(90, 255, 150),
        MidColor = Color3.fromRGB(255, 210, 70),
        LowColor = Color3.fromRGB(255, 70, 90),
        Background = Color3.fromRGB(12, 12, 16),
        TextColor = Color3.fromRGB(230, 230, 235),
        TextSize = 11,
    },

    Distance = {
        Enabled = true,
        Color = Color3.fromRGB(170, 175, 190),
        Size = 12,
        Outline = true,
        Suffix = "m",
    },

    Tracer = {
        Enabled = false,
        Color = Color3.fromRGB(245, 245, 250),
        Thickness = 1.1,
        Transparency = 1,
        Origin = "Bottom", -- Bottom | Center | Mouse | Top
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    Skeleton = {
        Enabled = false,
        Color = Color3.fromRGB(245, 245, 250),
        Thickness = 1.15,
        Transparency = 1,
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    Head = {
        Enabled = false,
        Color = Color3.fromRGB(245, 245, 250),
        Thickness = 1.2,
        Filled = false,
        FillTransparency = 0.85,
    },

    Weapon = {
        Enabled = false,
        Color = Color3.fromRGB(200, 190, 255),
        Size = 12,
        Outline = true,
    },

    -- Screen-space limb projection chams (Drawing only — no Highlight)
    Chams = {
        Enabled = true,
        FillColor = Color3.fromRGB(140, 100, 255),
        OutlineColor = Color3.fromRGB(220, 210, 255),
        FillTransparency = 0.72,   -- higher = more glass-like (stock Drawing: 0 opaque, so inverted in renderer)
        OutlineTransparency = 0.15,
        Thickness = 1.15,
        VisibleColor = Color3.fromRGB(140, 100, 255),
        HiddenColor = Color3.fromRGB(255, 95, 110),
        IncludeAccessories = false, -- accessories are noisy; body limbs only by default
        MaxParts = 16,
    },

    OffScreen = {
        Enabled = true,
        Color = Color3.fromRGB(245, 245, 250),
        Size = 10,          -- arrow size px
        Margin = 28,        -- inset from screen edge
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        ShowDistance = true,
        DistanceSize = 11,
        DistanceColor = Color3.fromRGB(180, 185, 200),
    },

    VisibleColor = nil, -- optional global override when visible
    HiddenColor = nil,
}

Aether.Config = deepCopy(DEFAULT_CONFIG)

--==============================================================================
-- DRAWING LAYER
--==============================================================================
local DrawingAvailable = false
pcall(function()
    if typeof(Drawing) == "table" or typeof(Drawing) == "userdata" then
        local t = Drawing.new("Line")
        t.Visible = false
        t:Remove()
        DrawingAvailable = true
    end
end)

local HasTriangle = false
pcall(function()
    if not DrawingAvailable then return end
    local t = Drawing.new("Triangle")
    t.Visible = false
    t:Remove()
    HasTriangle = true
end)

local function dnew(class)
    if not DrawingAvailable then return nil end
    local ok, obj = pcall(Drawing.new, class)
    if ok and obj then
        pcall(function() obj.Visible = false end)
        return obj
    end
    return nil
end

local function dkill(obj)
    if not obj then return end
    pcall(function()
        obj.Visible = false
        if obj.Remove then obj:Remove() elseif obj.Destroy then obj:Destroy() end
    end)
end

-- Opacity: we store Config Transparency as 0..1 where 1 = fully visible.
-- Stock Drawing uses Transparency 0 = opaque, 1 = invisible.
local function setOpacity(obj, opacity)
    if not obj then return end
    opacity = math.clamp(tonumber(opacity) or 1, 0, 1)
    pcall(function()
        obj.Transparency = 1 - opacity
    end)
end

local function setLine(obj, from, to, color, thickness, opacity)
    if not obj then return end
    obj.From = from
    obj.To = to
    obj.Color = color
    obj.Thickness = thickness or 1
    setOpacity(obj, opacity)
    obj.Visible = true
end

local function hideObj(obj)
    if obj then pcall(function() obj.Visible = false end) end
end

--==============================================================================
-- RIG MAPS
--==============================================================================
local SKELETON_R15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local SKELETON_R6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

local CHAMS_R15 = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local CHAMS_R6 = {
    "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

local function detectRig(char)
    if char:FindFirstChild("UpperTorso") then return "R15" end
    if char:FindFirstChild("Torso") then return "R6" end
    return "R15"
end

--==============================================================================
-- UTILS
--==============================================================================
local function isTeammate(plr)
    local cfg = Aether.Config
    if not cfg.TeamCheck then return false end
    if not LocalPlayer.Team or not plr.Team then return false end
    return LocalPlayer.Team == plr.Team
end

local function w2s(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on and v.Z > 0, v.Z
end

local function lerpColor(a, b, t)
    t = math.clamp(t, 0, 1)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

local function healthColor(frac, hcfg)
    frac = math.clamp(frac, 0, 1)
    if hcfg.Gradient then
        if frac > 0.5 then
            return lerpColor(hcfg.MidColor or hcfg.HighColor, hcfg.HighColor, (frac - 0.5) * 2)
        end
        return lerpColor(hcfg.LowColor, hcfg.MidColor or hcfg.HighColor, frac * 2)
    end
    if frac > 0.6 then return hcfg.HighColor end
    if frac > 0.3 then return hcfg.MidColor or hcfg.HighColor end
    return hcfg.LowColor
end

local function distanceScale(dist, cfg)
    if not cfg.ScaleWithDistance then return 1 end
    local maxd = math.max(cfg.MaxDistance or 2000, 1)
    local t = math.clamp(1 - (dist / maxd), 0, 1)
    local mn, mx = cfg.MinScale or 0.65, cfg.MaxScale or 1.15
    return mn + (mx - mn) * t
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(character, root)
    local cam = Camera
    if not cam or not root then return false end
    local origin = cam.CFrame.Position
    local target = root.Position
    local dir = target - origin
    local filter = { LocalPlayer.Character, Camera }
    -- exclude the target character so we only hit world geometry
    -- actually we want: if first hit is part of character, visible
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = Workspace:Raycast(origin, dir, rayParams)
    if not result then return true end
    return result.Instance and result.Instance:IsDescendantOf(character)
end

local function getToolName(char)
    local t = char:FindFirstChildOfClass("Tool")
    return t and t.Name or nil
end

local function deepMerge(dst, src)
    if type(src) ~= "table" then return dst end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" and typeof(v) ~= "Color3" and typeof(dst[k]) ~= "Color3" then
            -- Color3 is userdata in Roblox; plain tables get merged
            local isColor = (v.R ~= nil and v.G ~= nil and v.B ~= nil and v[1] == nil)
            if typeof(v) == "Color3" or typeof(dst[k]) == "Color3" then
                dst[k] = v
            elseif type(dst[k]) == "table" and not (dst[k].R and dst[k].G) then
                deepMerge(dst[k], v)
            else
                dst[k] = v
            end
        else
            dst[k] = v
        end
    end
    return dst
end

-- Part world corners (oriented bounding box)
local function partCorners(part)
    local cf, size = part.CFrame, part.Size
    local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
    return {
        cf * Vector3.new( hx,  hy,  hz),
        cf * Vector3.new( hx,  hy, -hz),
        cf * Vector3.new( hx, -hy,  hz),
        cf * Vector3.new( hx, -hy, -hz),
        cf * Vector3.new(-hx,  hy,  hz),
        cf * Vector3.new(-hx,  hy, -hz),
        cf * Vector3.new(-hx, -hy,  hz),
        cf * Vector3.new(-hx, -hy, -hz),
    }
end

-- Project corners → 2D AABB + list of on-screen points
local function projectPart(part)
    local corners = partCorners(part)
    local pts, minX, minY, maxX, maxY = {}, math.huge, math.huge, -math.huge, -math.huge
    local any = false
    for i = 1, 8 do
        local sp, on, z = w2s(corners[i])
        if on and z > 0 then
            any = true
            pts[#pts + 1] = sp
            if sp.X < minX then minX = sp.X end
            if sp.Y < minY then minY = sp.Y end
            if sp.X > maxX then maxX = sp.X end
            if sp.Y > maxY then maxY = sp.Y end
        end
    end
    if not any then return nil end
    return {
        pts = pts,
        x1 = minX, y1 = minY, x2 = maxX, y2 = maxY,
    }
end

--==============================================================================
-- PLAYER STATE / OBJECT POOLS
--==============================================================================
local function allocBoxLines()
    -- 8 corner segments + 8 outline, or 4 full + 4 outline
    local t = {}
    for i = 1, 16 do t[i] = dnew("Line") end
    return t
end

local function allocSkeleton()
    local t = { main = {}, outline = {} }
    for i = 1, 14 do
        t.main[i] = dnew("Line")
        t.outline[i] = dnew("Line")
    end
    return t
end

local function allocChams(maxParts)
    maxParts = maxParts or 16
    local t = { outlines = {}, fills = {} }
    for i = 1, maxParts do
        -- 12 edges max per part outline (box edges) — use 4 AABB edges for speed/clarity
        local edges = {}
        for e = 1, 4 do edges[e] = dnew("Line") end
        t.outlines[i] = edges
        -- fill: 2 triangles if available, else skip
        if HasTriangle then
            t.fills[i] = { dnew("Triangle"), dnew("Triangle") }
        else
            t.fills[i] = nil
        end
    end
    return t
end

local function allocOffScreen()
    return {
        a = dnew("Line"),
        b = dnew("Line"),
        c = dnew("Line"),
        oa = dnew("Line"),
        ob = dnew("Line"),
        oc = dnew("Line"),
        text = dnew("Text"),
    }
end

local function createPlayerState(player)
    local st = {
        player = player,
        character = nil,
        humanoid = nil,
        root = nil,
        head = nil,
        rig = "R15",
        parts = {}, -- name → BasePart cache
        box = allocBoxLines(),
        name = dnew("Text"),
        distance = dnew("Text"),
        weapon = dnew("Text"),
        healthBar = {
            bg = dnew("Line"),
            fg = dnew("Line"),
            outline = dnew("Line"),
            text = dnew("Text"),
        },
        tracer = { main = dnew("Line"), outline = dnew("Line") },
        skeleton = allocSkeleton(),
        headCircle = dnew("Circle"),
        chams = allocChams(16),
        offscreen = allocOffScreen(),
        customColor = nil,
        conns = {},
    }
    if st.name then
        st.name.Center = true
        st.name.Outline = true
    end
    if st.distance then
        st.distance.Center = true
        st.distance.Outline = true
    end
    if st.weapon then
        st.weapon.Center = true
        st.weapon.Outline = true
    end
    if st.healthBar.text then
        st.healthBar.text.Center = true
        st.healthBar.text.Outline = true
    end
    if st.headCircle then
        st.headCircle.Filled = false
        st.headCircle.NumSides = 16
    end
    if st.offscreen.text then
        st.offscreen.text.Center = true
        st.offscreen.text.Outline = true
    end
    return st
end

local function hideAll(st)
    if not st then return end
    for _, ln in pairs(st.box) do hideObj(ln) end
    hideObj(st.name)
    hideObj(st.distance)
    hideObj(st.weapon)
    for _, ln in pairs(st.healthBar) do hideObj(ln) end
    hideObj(st.tracer.main)
    hideObj(st.tracer.outline)
    for _, ln in pairs(st.skeleton.main) do hideObj(ln) end
    for _, ln in pairs(st.skeleton.outline) do hideObj(ln) end
    hideObj(st.headCircle)
    for i = 1, #st.chams.outlines do
        for _, ln in pairs(st.chams.outlines[i]) do hideObj(ln) end
        if st.chams.fills[i] then
            hideObj(st.chams.fills[i][1])
            hideObj(st.chams.fills[i][2])
        end
    end
    for _, ln in pairs(st.offscreen) do hideObj(ln) end
end

local function destroyState(st)
    if not st then return end
    for _, c in pairs(st.conns) do pcall(function() c:Disconnect() end) end
    st.conns = {}
    hideAll(st)
    for _, ln in pairs(st.box) do dkill(ln) end
    dkill(st.name)
    dkill(st.distance)
    dkill(st.weapon)
    for _, ln in pairs(st.healthBar) do dkill(ln) end
    dkill(st.tracer.main)
    dkill(st.tracer.outline)
    for _, ln in pairs(st.skeleton.main) do dkill(ln) end
    for _, ln in pairs(st.skeleton.outline) do dkill(ln) end
    dkill(st.headCircle)
    for i = 1, #st.chams.outlines do
        for _, ln in pairs(st.chams.outlines[i]) do dkill(ln) end
        if st.chams.fills[i] then
            dkill(st.chams.fills[i][1])
            dkill(st.chams.fills[i][2])
        end
    end
    for _, ln in pairs(st.offscreen) do dkill(ln) end
end

local function cacheCharacter(st, char)
    st.character = char
    st.humanoid = char and char:FindFirstChildOfClass("Humanoid") or nil
    st.root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")) or nil
    st.head = char and char:FindFirstChild("Head") or nil
    st.rig = char and detectRig(char) or "R15"
    st.parts = {}
    if not char then return end
    local list = st.rig == "R6" and CHAMS_R6 or CHAMS_R15
    for _, name in ipairs(list) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            st.parts[name] = p
        end
    end
end

--==============================================================================
-- DRAW HELPERS
--==============================================================================
local function drawCornerBox(lines, x1, y1, x2, y2, col, th, op, ocol, oth, useOutline)
    local w, h = x2 - x1, y2 - y1
    local len = math.clamp(math.min(math.abs(w), math.abs(h)) * 0.22, 4, 18)
    local segs = {
        {Vector2.new(x1, y1), Vector2.new(x1 + len, y1)},
        {Vector2.new(x1, y1), Vector2.new(x1, y1 + len)},
        {Vector2.new(x2, y1), Vector2.new(x2 - len, y1)},
        {Vector2.new(x2, y1), Vector2.new(x2, y1 + len)},
        {Vector2.new(x1, y2), Vector2.new(x1 + len, y2)},
        {Vector2.new(x1, y2), Vector2.new(x1, y2 - len)},
        {Vector2.new(x2, y2), Vector2.new(x2 - len, y2)},
        {Vector2.new(x2, y2), Vector2.new(x2, y2 - len)},
    }
    if useOutline then
        for i = 1, 8 do
            setLine(lines[i + 8], segs[i][1], segs[i][2], ocol, oth, op)
        end
    else
        for i = 9, 16 do hideObj(lines[i]) end
    end
    for i = 1, 8 do
        setLine(lines[i], segs[i][1], segs[i][2], col, th, op)
    end
end

local function drawFullBox(lines, x1, y1, x2, y2, col, th, op, ocol, oth, useOutline)
    local segs = {
        {Vector2.new(x1, y1), Vector2.new(x2, y1)},
        {Vector2.new(x2, y1), Vector2.new(x2, y2)},
        {Vector2.new(x2, y2), Vector2.new(x1, y2)},
        {Vector2.new(x1, y2), Vector2.new(x1, y1)},
    }
    if useOutline then
        for i = 1, 4 do
            setLine(lines[i + 8], segs[i][1], segs[i][2], ocol, oth, op)
        end
        for i = 13, 16 do hideObj(lines[i]) end
    else
        for i = 9, 16 do hideObj(lines[i]) end
    end
    for i = 1, 4 do
        setLine(lines[i], segs[i][1], segs[i][2], col, th, op)
    end
    for i = 5, 8 do hideObj(lines[i]) end
end

local function drawChamPart(chamsSlot, fillSlot, proj, fillCol, outCol, fillOp, outOp, thickness)
    if not proj then
        if chamsSlot then for _, ln in pairs(chamsSlot) do hideObj(ln) end end
        if fillSlot then hideObj(fillSlot[1]); hideObj(fillSlot[2]) end
        return
    end
    local x1, y1, x2, y2 = proj.x1, proj.y1, proj.x2, proj.y2
    -- slight padding for cleaner limb silhouette
    local pad = 0.5
    x1, y1, x2, y2 = x1 - pad, y1 - pad, x2 + pad, y2 + pad

    -- fill via two triangles
    if fillSlot and HasTriangle then
        local t1, t2 = fillSlot[1], fillSlot[2]
        local function paint(tri, a, b, c)
            if not tri then return end
            pcall(function()
                tri.PointA = a
                tri.PointB = b
                tri.PointC = c
                tri.Color = fillCol
                tri.Filled = true
                setOpacity(tri, fillOp)
                tri.Visible = true
            end)
        end
        local tl = Vector2.new(x1, y1)
        local tr = Vector2.new(x2, y1)
        local br = Vector2.new(x2, y2)
        local bl = Vector2.new(x1, y2)
        paint(t1, tl, tr, br)
        paint(t2, tl, br, bl)
    end

    -- outline rectangle
    if chamsSlot then
        setLine(chamsSlot[1], Vector2.new(x1, y1), Vector2.new(x2, y1), outCol, thickness, outOp)
        setLine(chamsSlot[2], Vector2.new(x2, y1), Vector2.new(x2, y2), outCol, thickness, outOp)
        setLine(chamsSlot[3], Vector2.new(x2, y2), Vector2.new(x1, y2), outCol, thickness, outOp)
        setLine(chamsSlot[4], Vector2.new(x1, y2), Vector2.new(x1, y1), outCol, thickness, outOp)
    end
end

local function drawOffscreenArrow(os, tip, dir, size, col, ocol, useOutline, opacity)
    -- dir unit vector pointing toward target from center
    local right = Vector2.new(-dir.Y, dir.X)
    local base = tip - dir * size
    local p1 = tip
    local p2 = base + right * (size * 0.55)
    local p3 = base - right * (size * 0.55)
    if useOutline then
        setLine(os.oa, p1, p2, ocol, 2.6, opacity)
        setLine(os.ob, p2, p3, ocol, 2.6, opacity)
        setLine(os.oc, p3, p1, ocol, 2.6, opacity)
    else
        hideObj(os.oa); hideObj(os.ob); hideObj(os.oc)
    end
    setLine(os.a, p1, p2, col, 1.3, opacity)
    setLine(os.b, p2, p3, col, 1.3, opacity)
    setLine(os.c, p3, p1, col, 1.3, opacity)
end

--==============================================================================
-- PER-PLAYER RENDER
--==============================================================================
local function renderPlayer(st)
    local cfg = Aether.Config
    local player = st.player
    if not player or not player.Parent then return end

    -- team
    if isTeammate(player) and not cfg.RenderTeammates then
        hideAll(st)
        return
    end

    local char = player.Character
    if char ~= st.character then
        cacheCharacter(st, char)
    end
    if not st.character or not st.root or not st.humanoid then
        -- try soft recache
        if char then cacheCharacter(st, char) end
    end
    if not st.character or not st.root or not st.head or not st.humanoid then
        hideAll(st)
        return
    end

    local root, head, hum = st.root, st.head, st.humanoid
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("UpperTorso"))
    local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
    if dist > (cfg.MaxDistance or 2000) then
        hideAll(st)
        return
    end

    local vis = true
    if cfg.VisibilityCheck then
        vis = isVisible(st.character, root)
    end

    local baseColor = st.customColor
        or (isTeammate(player) and cfg.TeamColor)
        or (cfg.Box and cfg.Box.Color)
        or Color3.fromRGB(245, 245, 250)

    if cfg.VisibilityCheck then
        if vis and cfg.VisibleColor then baseColor = cfg.VisibleColor end
        if not vis and cfg.HiddenColor then baseColor = cfg.HiddenColor end
    end

    local scale = distanceScale(dist, cfg)
    local topW, onTop = w2s(head.Position + Vector3.new(0, 0.85, 0))
    local botW, onBot = w2s(root.Position - Vector3.new(0, 3.05, 0))
    local midW, onMid, midZ = w2s(root.Position)

    -- Off-screen indicator
    local onScreen = (onTop or onBot or onMid)
    if not onScreen then
        hideAll(st)
        local osc = cfg.OffScreen
        if osc and osc.Enabled and midW then
            local vp = Camera.ViewportSize
            local cx, cy = vp.X * 0.5, vp.Y * 0.5
            local dir = Vector2.new(midW.X - cx, midW.Y - cy)
            if dir.Magnitude < 1e-3 then return end
            dir = dir.Unit
            local margin = osc.Margin or 28
            -- intersect ray from center with inset rectangle
            local sx = (vp.X * 0.5 - margin) / math.abs(dir.X + 1e-6)
            local sy = (vp.Y * 0.5 - margin) / math.abs(dir.Y + 1e-6)
            local t = math.min(sx, sy)
            local tip = Vector2.new(cx, cy) + dir * t
            drawOffscreenArrow(st.offscreen, tip, dir, (osc.Size or 10) * scale, osc.Color or baseColor, osc.OutlineColor or Color3.new(0,0,0), osc.Outline ~= false, 1)
            if osc.ShowDistance and st.offscreen.text then
                st.offscreen.text.Text = string.format("%d%s", math.floor(dist + 0.5), (cfg.Distance and cfg.Distance.Suffix) or "m")
                st.offscreen.text.Size = (osc.DistanceSize or 11) * scale
                st.offscreen.text.Color = osc.DistanceColor or Color3.fromRGB(180, 185, 200)
                st.offscreen.text.Outline = true
                st.offscreen.text.Position = tip - dir * ((osc.Size or 10) + 12)
                st.offscreen.text.Visible = true
            end
        end
        return
    end

    -- hide offscreen objs when on-screen
    for _, ln in pairs(st.offscreen) do hideObj(ln) end

    local h = math.abs(botW.Y - topW.Y)
    if h < 3 or h > 1400 then hideAll(st) return end
    local w = h * 0.52
    local cx = (topW.X + botW.X) * 0.5
    local x1, y1 = cx - w * 0.5, math.min(topW.Y, botW.Y)
    local x2, y2 = cx + w * 0.5, math.max(topW.Y, botW.Y)

    -- BOX
    local bcfg = cfg.Box
    if bcfg and bcfg.Enabled then
        local th = (bcfg.Thickness or 1.25) * scale
        local oth = (bcfg.OutlineThickness or 2.4) * scale
        local op = bcfg.Transparency or 1
        local col = baseColor
        if bcfg.Type == "Full" then
            drawFullBox(st.box, x1, y1, x2, y2, col, th, op, bcfg.OutlineColor, oth, bcfg.Outline)
        else
            drawCornerBox(st.box, x1, y1, x2, y2, col, th, op, bcfg.OutlineColor, oth, bcfg.Outline)
        end
    else
        for _, ln in pairs(st.box) do hideObj(ln) end
    end

    -- HEALTH
    local hcfg = cfg.Health
    if hcfg and hcfg.Enabled then
        local frac = math.clamp((hum.Health or 0) / math.max(hum.MaxHealth or 100, 1), 0, 1)
        local barX = (hcfg.Side == "Right") and (x2 + 3.5 * scale) or (x1 - 3.5 * scale)
        local width = (hcfg.Width or 2.5) * scale
        local col = healthColor(frac, hcfg)
        if hcfg.Bar then
            setLine(st.healthBar.outline, Vector2.new(barX, y1 - 1), Vector2.new(barX, y2 + 1), Color3.new(0, 0, 0), width + 2, 1)
            setLine(st.healthBar.bg, Vector2.new(barX, y1), Vector2.new(barX, y2), hcfg.Background or Color3.fromRGB(12,12,16), width, 1)
            local filledY = y2 - (y2 - y1) * frac
            if frac > 0.001 then
                setLine(st.healthBar.fg, Vector2.new(barX, filledY), Vector2.new(barX, y2), col, width, 1)
            else
                hideObj(st.healthBar.fg)
            end
        else
            hideObj(st.healthBar.outline); hideObj(st.healthBar.bg); hideObj(st.healthBar.fg)
        end
        if hcfg.Text and st.healthBar.text then
            st.healthBar.text.Text = string.format("%d", math.floor((hum.Health or 0) + 0.5))
            st.healthBar.text.Size = (hcfg.TextSize or 11) * scale
            st.healthBar.text.Color = hcfg.TextColor or Color3.fromRGB(230, 230, 235)
            st.healthBar.text.Outline = true
            st.healthBar.text.Position = Vector2.new(barX, y1 - 12 * scale)
            st.healthBar.text.Visible = true
        else
            hideObj(st.healthBar.text)
        end
    else
        for _, o in pairs(st.healthBar) do hideObj(o) end
    end

    -- NAME
    local ncfg = cfg.Name
    if ncfg and ncfg.Enabled and st.name then
        local label = ncfg.UseDisplayName and ((player.DisplayName ~= "" and player.DisplayName) or player.Name) or player.Name
        st.name.Text = label
        st.name.Size = (ncfg.Size or 13) * scale
        st.name.Color = ncfg.Color or baseColor
        st.name.Outline = ncfg.Outline ~= false
        st.name.OutlineColor = ncfg.OutlineColor or Color3.new(0, 0, 0)
        st.name.Position = Vector2.new(cx, y1 - 15 * scale)
        st.name.Visible = true
    else
        hideObj(st.name)
    end

    -- DISTANCE
    local dcfg = cfg.Distance
    local distOffset = 3 * scale
    if dcfg and dcfg.Enabled and st.distance then
        st.distance.Text = string.format("%d%s", math.floor(dist + 0.5), dcfg.Suffix or "m")
        st.distance.Size = (dcfg.Size or 12) * scale
        st.distance.Color = dcfg.Color
        st.distance.Outline = dcfg.Outline ~= false
        st.distance.Position = Vector2.new(cx, y2 + distOffset)
        st.distance.Visible = true
        distOffset = distOffset + (dcfg.Size or 12) * scale + 2
    else
        hideObj(st.distance)
    end

    -- WEAPON
    local wcfg = cfg.Weapon
    if wcfg and wcfg.Enabled and st.weapon then
        local wname = getToolName(st.character)
        if wname then
            st.weapon.Text = wname
            st.weapon.Size = (wcfg.Size or 12) * scale
            st.weapon.Color = wcfg.Color
            st.weapon.Outline = wcfg.Outline ~= false
            st.weapon.Position = Vector2.new(cx, y2 + distOffset)
            st.weapon.Visible = true
        else
            hideObj(st.weapon)
        end
    else
        hideObj(st.weapon)
    end

    -- TRACER
    local tcfg = cfg.Tracer
    if tcfg and tcfg.Enabled then
        local vp = Camera.ViewportSize
        local origin
        local o = tcfg.Origin or "Bottom"
        if o == "Center" then
            origin = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        elseif o == "Mouse" then
            local m = UserInputService:GetMouseLocation()
            origin = Vector2.new(m.X, m.Y)
        elseif o == "Top" then
            origin = Vector2.new(vp.X * 0.5, 0)
        else
            origin = Vector2.new(vp.X * 0.5, vp.Y)
        end
        local target = Vector2.new(cx, y2)
        if tcfg.Outline then
            setLine(st.tracer.outline, origin, target, tcfg.OutlineColor or Color3.new(0,0,0), (tcfg.Thickness or 1.1) * scale + 1.5, tcfg.Transparency or 1)
        else
            hideObj(st.tracer.outline)
        end
        setLine(st.tracer.main, origin, target, tcfg.Color or baseColor, (tcfg.Thickness or 1.1) * scale, tcfg.Transparency or 1)
    else
        hideObj(st.tracer.main); hideObj(st.tracer.outline)
    end

    -- SKELETON
    local sk = cfg.Skeleton
    if sk and sk.Enabled then
        local pairsMap = st.rig == "R6" and SKELETON_R6 or SKELETON_R15
        local idx = 1
        for _, pair in ipairs(pairsMap) do
            if idx > #st.skeleton.main then break end
            local a = st.parts[pair[1]] or st.character:FindFirstChild(pair[1])
            local b = st.parts[pair[2]] or st.character:FindFirstChild(pair[2])
            local ml, ol = st.skeleton.main[idx], st.skeleton.outline[idx]
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local pa, oa = w2s(a.Position)
                local pb, ob = w2s(b.Position)
                if oa and ob then
                    if sk.Outline then
                        setLine(ol, pa, pb, sk.OutlineColor or Color3.new(0,0,0), (sk.Thickness or 1.15) * scale + 1.4, sk.Transparency or 1)
                    else
                        hideObj(ol)
                    end
                    setLine(ml, pa, pb, sk.Color or baseColor, (sk.Thickness or 1.15) * scale, sk.Transparency or 1)
                else
                    hideObj(ml); hideObj(ol)
                end
            else
                hideObj(ml); hideObj(ol)
            end
            idx = idx + 1
        end
        for i = idx, #st.skeleton.main do
            hideObj(st.skeleton.main[i]); hideObj(st.skeleton.outline[i])
        end
    else
        for i = 1, #st.skeleton.main do
            hideObj(st.skeleton.main[i]); hideObj(st.skeleton.outline[i])
        end
    end

    -- HEAD CIRCLE
    local hd = cfg.Head
    if hd and hd.Enabled and st.headCircle then
        local hp, onH = w2s(head.Position)
        if onH then
            local radius = math.clamp(h * 0.12, 3, 18) * scale
            st.headCircle.Position = hp
            st.headCircle.Radius = radius
            st.headCircle.Color = hd.Color or baseColor
            st.headCircle.Thickness = (hd.Thickness or 1.2) * scale
            st.headCircle.Filled = hd.Filled == true
            if hd.Filled then
                setOpacity(st.headCircle, 1 - (hd.FillTransparency or 0.85))
            else
                setOpacity(st.headCircle, 1)
            end
            st.headCircle.Visible = true
        else
            hideObj(st.headCircle)
        end
    else
        hideObj(st.headCircle)
    end

    -- CHAMS (screen-space limb quads)
    local ccfg = cfg.Chams
    if ccfg and ccfg.Enabled then
        local fillCol = ccfg.FillColor
        local outCol = ccfg.OutlineColor
        if cfg.VisibilityCheck then
            fillCol = vis and (ccfg.VisibleColor or fillCol) or (ccfg.HiddenColor or fillCol)
            outCol = fillCol
        end
        if isTeammate(player) and cfg.RenderTeammates then
            fillCol = cfg.TeamColor or fillCol
        end
        if st.customColor then fillCol = st.customColor end

        -- Config FillTransparency: 0 = solid, 1 = invisible → convert to opacity
        local fillOp = 1 - math.clamp(ccfg.FillTransparency or 0.72, 0, 1)
        local outOp = 1 - math.clamp(ccfg.OutlineTransparency or 0.15, 0, 1)
        local th = (ccfg.Thickness or 1.15) * scale

        local list = st.rig == "R6" and CHAMS_R6 or CHAMS_R15
        local maxP = math.min(ccfg.MaxParts or 16, #st.chams.outlines)
        local pi = 0
        for _, name in ipairs(list) do
            if pi >= maxP then break end
            pi = pi + 1
            local part = st.parts[name] or st.character:FindFirstChild(name)
            local proj = (part and part:IsA("BasePart")) and projectPart(part) or nil
            drawChamPart(st.chams.outlines[pi], st.chams.fills[pi], proj, fillCol, outCol, fillOp, outOp, th)
        end
        for i = pi + 1, #st.chams.outlines do
            for _, ln in pairs(st.chams.outlines[i]) do hideObj(ln) end
            if st.chams.fills[i] then hideObj(st.chams.fills[i][1]); hideObj(st.chams.fills[i][2]) end
        end
    else
        for i = 1, #st.chams.outlines do
            for _, ln in pairs(st.chams.outlines[i]) do hideObj(ln) end
            if st.chams.fills[i] then hideObj(st.chams.fills[i][1]); hideObj(st.chams.fills[i][2]) end
        end
    end
end

--==============================================================================
-- PLAYER LIFECYCLE
--==============================================================================
local function bindPlayer(player)
    if player == LocalPlayer then return end
    if Aether._players[player] then return end
    local st = createPlayerState(player)
    Aether._players[player] = st

    local function onChar(char)
        task.defer(function()
            if not Aether._alive or not Aether._players[player] then return end
            if char then
                pcall(function() char:WaitForChild("Humanoid", 5) end)
                pcall(function()
                    local root = char:FindFirstChild("HumanoidRootPart")
                        or char:FindFirstChild("UpperTorso")
                        or char:FindFirstChild("Torso")
                    if not root then
                        root = char:WaitForChild("HumanoidRootPart", 3)
                            or char:WaitForChild("UpperTorso", 2)
                            or char:WaitForChild("Torso", 2)
                    end
                    return root
                end)
            end
            cacheCharacter(st, char)
        end)
    end

    if player.Character then onChar(player.Character) end
    st.conns[#st.conns + 1] = player.CharacterAdded:Connect(onChar)
    st.conns[#st.conns + 1] = player.CharacterRemoving:Connect(function()
        cacheCharacter(st, nil)
        hideAll(st)
    end)
end

local function unbindPlayer(player)
    local st = Aether._players[player]
    if not st then return end
    destroyState(st)
    Aether._players[player] = nil
end

--==============================================================================
-- MAIN LOOP
--==============================================================================
local function renderStep()
    if not Aether._alive or not Aether._enabled then return end
    if not Aether.Config.Enabled then return end
    Camera = Workspace.CurrentCamera
    if not Camera then return end
    for player, st in pairs(Aether._players) do
        if player.Parent then
            local ok, err = pcall(renderPlayer, st)
            if not ok then
                -- soft fail one player
            end
        else
            unbindPlayer(player)
        end
    end
end

--==============================================================================
-- PUBLIC API
--==============================================================================
function Aether:Enable()
    if not Aether._alive then return self end
    Aether._enabled = true
    Aether.Config.Enabled = true
    if not DrawingAvailable then
        warn("[Aether] Drawing API not available — ESP cannot render")
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        bindPlayer(plr)
    end
    return self
end

function Aether:Disable()
    Aether._enabled = false
    Aether.Config.Enabled = false
    for _, st in pairs(Aether._players) do
        hideAll(st)
    end
    return self
end

function Aether:IsEnabled()
    return Aether._enabled == true
end

function Aether:GetConfig()
    return Aether.Config
end

function Aether:SetConfig(partial)
    if type(partial) ~= "table" then return self end
    deepMerge(Aether.Config, partial)
    if partial.Enabled ~= nil then
        if partial.Enabled then self:Enable() else self:Disable() end
    end
    return self
end

function Aether:SetFeatureEnabled(feature, enabled)
    local key = tostring(feature or "")
    local map = {
        Box = "Box", Name = "Name", Health = "Health", Distance = "Distance",
        Tracer = "Tracer", Skeleton = "Skeleton", Head = "Head", Weapon = "Weapon",
        Chams = "Chams", OffScreen = "OffScreen",
    }
    local section = map[key] or map[key:sub(1,1):upper() .. key:sub(2)]
    if section and Aether.Config[section] then
        Aether.Config[section].Enabled = enabled and true or false
    end
    return self
end

function Aether:SetMaxDistance(n)
    Aether.Config.MaxDistance = tonumber(n) or Aether.Config.MaxDistance
    return self
end

function Aether:SetPlayerColor(player, color)
    local st = Aether._players[player]
    if st and typeof(color) == "Color3" then
        st.customColor = color
    elseif st and color == nil then
        st.customColor = nil
    end
    return self
end

function Aether:AddPlayer(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        bindPlayer(player)
    end
    return self
end

function Aether:RemovePlayer(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        unbindPlayer(player)
    end
    return self
end

function Aether:Refresh()
    for player, st in pairs(Aether._players) do
        cacheCharacter(st, player.Character)
    end
    return self
end

function Aether:Destroy()
    Aether._alive = false
    Aether._enabled = false
    for _, c in ipairs(Aether._conns) do
        pcall(function() c:Disconnect() end)
    end
    Aether._conns = {}
    for player in pairs(Aether._players) do
        unbindPlayer(player)
    end
    Aether._players = {}
    if Aether._render then
        pcall(function() Aether._render:Disconnect() end)
        Aether._render = nil
    end
    if getgenv then pcall(function() getgenv().Aether = nil end) end
    pcall(function() _G.Aether = nil end)
    pcall(function() shared.Aether = nil end)
    print("[Aether] Destroyed")
end

--==============================================================================
-- BOOTSTRAP
--==============================================================================
local function addConn(c)
    Aether._conns[#Aether._conns + 1] = c
    return c
end

addConn(Players.PlayerAdded:Connect(function(plr)
    if Aether._enabled then bindPlayer(plr) end
end))
addConn(Players.PlayerRemoving:Connect(function(plr)
    unbindPlayer(plr)
end))

Aether._render = RunService.RenderStepped:Connect(function()
    renderStep()
end)
addConn(Aether._render)

-- Auto-enable with defaults (library is ready on load)
Aether:Enable()

if getgenv then pcall(function() getgenv().Aether = Aether end) end
_G.Aether = Aether
shared.Aether = Aether

print(string.format("[Aether] v%s ready · Drawing=%s Triangle=%s", Aether._version, tostring(DrawingAvailable), tostring(HasTriangle)))

return Aether
