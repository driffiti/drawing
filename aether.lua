--[[
    Aether UI Library
    Made by empulsia
    Version 1.2
]]

local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local ws = game:GetService("Workspace")
local http_service = game:GetService("HttpService")
local gui_service = game:GetService("GuiService")
local run = game:GetService("RunService")
local stats = game:GetService("Stats")
local coregui = game:GetService("CoreGui")
local tween_service = game:GetService("TweenService")
local marketplace = game:GetService("MarketplaceService")
local text_service = game:GetService("TextService")
local content_provider = game:GetService("ContentProvider")

local vec2 = Vector2.new
local dim2 = UDim2.new
local dim = UDim.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new
local numseq = NumberSequence.new
local numkey = NumberSequenceKeypoint.new

local camera = ws.CurrentCamera
local lp = players.LocalPlayer
local mouse = lp:GetMouse()
local gui_offset = gui_service:GetGuiInset().Y

local clamp = math.clamp
local floor = math.floor
local min = math.min
local max = math.max
local abs = math.abs

local insert = table.insert
local find = table.find
local remove = table.remove
local concat = table.concat

-- Library init
getgenv().Aether = getgenv().Aether or {}
local library = {
    directory = "Aether",
    folders = {
        "/fonts",
        "/configs",
        "/assets",
    },
    flags = {},
    config_flags = {},
    connections = {},
    notifications = { notifs = {} },
    current_open = nil,
    version = "1.2",
    theme_dirty = false,
    silent = false,
}

library.__index = library

for _, path in next, library.folders do
    pcall(makefolder, library.directory .. path)
end

local flags = library.flags
local config_flags = library.config_flags
local notifications = library.notifications

-- Theme (matches original dark Milenium palette)
local themes = {
    preset = {
        accent = rgb(155, 150, 219),
        background = rgb(14, 14, 16),
        section = rgb(22, 22, 24),
        element = rgb(25, 25, 29),
        light = rgb(33, 33, 35),
        hover = rgb(39, 39, 43),
        line = rgb(21, 21, 23),
        text = rgb(245, 245, 245),
        dimtext = rgb(72, 72, 73),
        dimicon = rgb(72, 72, 73),
    },
    utility = {
        accent = {
            BackgroundColor3 = {},
            TextColor3 = {},
            ImageColor3 = {},
            ScrollBarImageColor3 = {},
            Color = {}, -- UIStroke
        },
    },
}

local keys = {
    [Enum.KeyCode.LeftShift] = "LS",
    [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC",
    [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS",
    [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent",
    [Enum.KeyCode.LeftAlt] = "LA",
    [Enum.KeyCode.RightAlt] = "RA",
    [Enum.KeyCode.CapsLock] = "CAPS",
    [Enum.KeyCode.One] = "1",
    [Enum.KeyCode.Two] = "2",
    [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4",
    [Enum.KeyCode.Five] = "5",
    [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7",
    [Enum.KeyCode.Eight] = "8",
    [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Zero] = "0",
    [Enum.KeyCode.KeypadOne] = "Num1",
    [Enum.KeyCode.KeypadTwo] = "Num2",
    [Enum.KeyCode.KeypadThree] = "Num3",
    [Enum.KeyCode.KeypadFour] = "Num4",
    [Enum.KeyCode.KeypadFive] = "Num5",
    [Enum.KeyCode.KeypadSix] = "Num6",
    [Enum.KeyCode.KeypadSeven] = "Num7",
    [Enum.KeyCode.KeypadEight] = "Num8",
    [Enum.KeyCode.KeypadNine] = "Num9",
    [Enum.KeyCode.KeypadZero] = "Num0",
    [Enum.KeyCode.Minus] = "-",
    [Enum.KeyCode.Equals] = "=",
    [Enum.KeyCode.Tilde] = "~",
    [Enum.KeyCode.LeftBracket] = "[",
    [Enum.KeyCode.RightBracket] = "]",
    [Enum.KeyCode.RightParenthesis] = ")",
    [Enum.KeyCode.LeftParenthesis] = "(",
    [Enum.KeyCode.Semicolon] = ";",
    [Enum.KeyCode.Quote] = "'",
    [Enum.KeyCode.BackSlash] = "\\",
    [Enum.KeyCode.Comma] = ",",
    [Enum.KeyCode.Period] = ".",
    [Enum.KeyCode.Slash] = "/",
    [Enum.KeyCode.Asterisk] = "*",
    [Enum.KeyCode.Plus] = "+",
    [Enum.KeyCode.Backquote] = "`",
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
    [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC",
}

-- Custom fonts (kept lightweight)
local fonts = {}
do
    local function Register_Font(Name, Weight, Style, Asset)
        local path = library.directory .. "/fonts/" .. Asset.Id
        if not isfile(path) then
            pcall(function()
                writefile(path, Asset.Font)
            end)
        end

        local jsonPath = library.directory .. "/fonts/" .. Name .. ".font"
        pcall(delfile, jsonPath)

        local Data = {
            name = Name,
            faces = {
                {
                    name = "Normal",
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(path),
                },
            },
        }

        writefile(jsonPath, http_service:JSONEncode(Data))
        return getcustomasset(jsonPath)
    end

    local MediumOk, Medium = pcall(function()
        return Register_Font("Medium", 200, "Normal", {
            Id = "Medium.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-Medium.ttf"),
        })
    end)

    local SemiOk, SemiBold = pcall(function()
        return Register_Font("SemiBold", 200, "Normal", {
            Id = "SemiBold.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-SemiBold.ttf"),
        })
    end)

    fonts = {
        small = Font.new(MediumOk and Medium or Font.fromEnum(Enum.Font.GothamMedium).Family, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        font = Font.new(SemiOk and SemiBold or Font.fromEnum(Enum.Font.GothamMedium).Family, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    }
end

-- Icon system from Zolar (lucide)
local IconPack
pcall(function()
    local Url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
    IconPack = loadstring(game:HttpGetAsync(Url))()
    IconPack.SetIconsType("lucide")
end)

local function ResolveIcon(Icon)
    if type(Icon) == "number" then
        return "rbxassetid://" .. Icon
    end
    if type(Icon) ~= "string" then
        return "rbxassetid://0"
    end
    if string.match(Icon, "^rbxassetid://") or string.match(Icon, "^rbxasset://") then
        return Icon
    end
    if string.match(Icon, "^%d+$") then
        return "rbxassetid://" .. Icon
    end
    if IconPack then
        local Ok, Result = pcall(function()
            return IconPack.GetIcon(Icon)
        end)
        if Ok and Result and Result ~= "rbxassetid://0" then
            return Result
        end
    end
    return "rbxassetid://0"
end

local function ApplyIcon(Object, Icon)
    if not Icon then return end
    local Image = ResolveIcon(Icon)
    Object.Image = Image
end

-- Utility
function library:tween(obj, properties, easing_style, time)
    local tween = tween_service:Create(
        obj,
        TweenInfo.new(time or 0.25, easing_style or Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0),
        properties
    )
    tween:Play()
    return tween
end

function library:connection(signal, callback)
    local connection = signal:Connect(callback)
    insert(library.connections, connection)
    return connection
end

function library:create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do
        ins[prop] = value
    end
    return ins
end

function library:round(number, float)
    local multiplier = 1 / (float or 1)
    return floor(number * multiplier + 0.5) / multiplier
end

function library:apply_theme(instance, theme, property)
    if not instance then return end
    local bucket = themes.utility[theme] and themes.utility[theme][property]
    if not bucket then
        -- auto-create missing property tables so theming never crashes
        if themes.utility[theme] then
            themes.utility[theme][property] = {}
            bucket = themes.utility[theme][property]
        else
            return
        end
    end
    insert(bucket, instance)
end

function library:update_theme(theme, color)
    for _, property in themes.utility[theme] do
        for m, object in property do
            if object[_] == themes.preset[theme] then
                object[_] = color
            end
        end
    end
    themes.preset[theme] = color
end

function library:close_element(new_path)
    local open_element = library.current_open
    if open_element and new_path ~= open_element then
        if open_element.set_visible then
            open_element.set_visible(false)
        end
        open_element.open = false
    end
    if new_path ~= open_element then
        library.current_open = new_path or nil
    end
end

function library:mouse_in_frame(uiobject)
    local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
    local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X
    return (y_cond and x_cond)
end

function library:draggify(frame)
    local dragging = false
    local start_size = frame.Position
    local start

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            start_size = frame.Position
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport_x = camera.ViewportSize.X
            local viewport_y = camera.ViewportSize.Y
            local current_position = dim2(
                0,
                clamp(start_size.X.Offset + (input.Position.X - start.X), 0, viewport_x - frame.Size.X.Offset),
                0,
                clamp(start_size.Y.Offset + (input.Position.Y - start.Y), 0, viewport_y - frame.Size.Y.Offset)
            )
            frame.Position = current_position
            library:close_element()
        end
    end)
end

function library:resizify(frame)
    local Frame = Instance.new("TextButton")
    Frame.Position = dim2(1, -10, 1, -10)
    Frame.Size = dim2(0, 10, 0, 10)
    Frame.BackgroundTransparency = 1
    Frame.Text = ""
    Frame.Parent = frame

    local resizing = false
    local start_size
    local start
    local og_size = frame.Size

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            start = input.Position
            start_size = frame.Size
        end
    end)

    Frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local viewport_x = camera.ViewportSize.X
            local viewport_y = camera.ViewportSize.Y
            local current_size = dim2(
                start_size.X.Scale,
                clamp(start_size.X.Offset + (input.Position.X - start.X), og_size.X.Offset, viewport_x),
                start_size.Y.Scale,
                clamp(start_size.Y.Offset + (input.Position.Y - start.Y), og_size.Y.Offset, viewport_y)
            )
            frame.Size = current_size
        end
    end)
end

function library:next_flag()
    local index = 0
    for _ in flags do
        index = index + 1
    end
    return string.format("flagnumber%s", index + 1)
end

function library:convert(str)
    local values = {}
    for value in string.gmatch(str, "[^,]+") do
        insert(values, tonumber(value))
    end
    if #values == 4 then
        return unpack(values)
    end
end

function library:convert_enum(enum)
    local enum_parts = {}
    for part in string.gmatch(enum, "[%w_]+") do
        insert(enum_parts, part)
    end
    local enum_table = Enum
    for i = 2, #enum_parts do
        enum_table = enum_table[enum_parts[i]]
    end
    return enum_table
end

function library:unload_menu()
    if library["items"] then
        library["items"]:Destroy()
    end
    if library["other"] then
        library["other"]:Destroy()
    end
    if library["watermark_gui"] then
        library["watermark_gui"]:Destroy()
    end
    for _, connection in library.connections do
        pcall(function()
            connection:Disconnect()
        end)
    end
    getgenv().Aether = nil
end

-- Config system (Zolar style)
function library:get_config(Created)
    local Config = {}
    for _, v in next, flags do
        if type(v) == "table" and v.key then
            Config[_] = { active = v.active, mode = v.mode, key = tostring(v.key) }
        elseif type(v) == "table" and v["Transparency"] and v["Color"] then
            Config[_] = { Transparency = v["Transparency"], Color = v["Color"]:ToHex() }
        else
            Config[_] = v
        end
    end

    Config.__accent = themes.preset.accent:ToHex()
    Config.__created = Created or os.date("%d.%m.%Y %H:%M")
    Config.__version = library.version
    Config.__creator = lp.DisplayName

    return http_service:JSONEncode(Config)
end

function library:load_config(config_json)
    local Ok, config = pcall(function()
        return http_service:JSONDecode(config_json)
    end)
    if not Ok or type(config) ~= "table" then
        return false
    end

    library.silent = true
    for _, v in config do
        local function_set = library.config_flags[_]
        if not function_set then
            continue
        end
        if type(v) == "table" and v["Transparency"] and v["Color"] then
            function_set(hex(v["Color"]), v["Transparency"])
        elseif type(v) == "table" and v["active"] then
            function_set(v)
        else
            function_set(v)
        end
    end

    if type(config.__accent) == "string" then
        local OkColor, Color = pcall(hex, config.__accent)
        if OkColor then
            library:update_theme("accent", Color)
        end
    end

    library.silent = false
    return true
end

function library:SaveConfigFile(Name)
    if not writefile then
        return false
    end
    writefile(library.directory .. "/configs/" .. Name .. ".json", library:get_config())
    return true
end

function library:LoadConfigFile(Name)
    if not isfile then
        return false
    end
    local Path = library.directory .. "/configs/" .. Name .. ".json"
    if not isfile(Path) then
        return false
    end
    return library:load_config(readfile(Path))
end

function library:ListConfigs()
    local Result = {}
    if not listfiles then
        return Result
    end
    for _, File in listfiles(library.directory .. "/configs") do
        if string.sub(File, -5) ~= ".json" then
            continue
        end
        local Name = string.match(File, "([^/\\]+)%.json$")
        if Name then
            insert(Result, Name)
        end
    end
    return Result
end

-- Window
function library:window(properties)
    local cfg = {
        suffix = properties.suffix or properties.Suffix or "tech",
        name = properties.name or properties.Name or "Aether",
        game_name = properties.gameInfo or properties.game_info or properties.GameInfo or "Aether for Roblox",
        size = properties.size or properties.Size or dim2(0, 700, 0, 565),
        selected_tab = nil,
        items = {},
    }

    library["items"] = library:create("ScreenGui", {
        Parent = coregui,
        Name = "\0",
        Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
    })

    library["other"] = library:create("ScreenGui", {
        Parent = coregui,
        Name = "\0",
        Enabled = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    library["cache"] = library:create("Folder", {
        Parent = library["other"],
        Name = "\0",
    })

    local items = cfg.items
    do
        items["main"] = library:create("Frame", {
            Parent = library["items"],
            Size = cfg.size,
            Name = "\0",
            Position = dim2(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2),
            BorderColor3 = rgb(0, 0, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
        })
        items["main"].Position = dim2(0, items["main"].AbsolutePosition.X, 0, items["main"].AbsolutePosition.Y)

        library:create("UICorner", {
            Parent = items["main"],
            CornerRadius = dim(0, 10),
        })

        library:create("UIStroke", {
            Color = rgb(23, 23, 29),
            Parent = items["main"],
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })

        items["side_frame"] = library:create("Frame", {
            Parent = items["main"],
            BackgroundTransparency = 1,
            Name = "\0",
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 196, 1, -25),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
        })

        library:create("Frame", {
            AnchorPoint = vec2(1, 0),
            Parent = items["side_frame"],
            Position = dim2(1, 0, 0, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 1, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.line,
        })

        items["button_holder"] = library:create("Frame", {
            Parent = items["side_frame"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 60),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 1, -60),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        cfg.button_holder = items["button_holder"]

        library:create("UIListLayout", {
            Parent = items["button_holder"],
            Padding = dim(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        library:create("UIPadding", {
            PaddingTop = dim(0, 16),
            PaddingBottom = dim(0, 36),
            Parent = items["button_holder"],
            PaddingRight = dim(0, 11),
            PaddingLeft = dim(0, 10),
        })

        items["title"] = library:create("TextLabel", {
            FontFace = fonts.font,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["side_frame"],
            Name = "\0",
            Text = string.format('<u>%s</u><font color = "rgb(255, 255, 255)">%s</font>', cfg.name, cfg.suffix),
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 0, 70),
            TextColor3 = themes.preset.accent,
            BorderSizePixel = 0,
            RichText = true,
            TextSize = 30,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        library:apply_theme(items["title"], "accent", "TextColor3")

        items["multi_holder"] = library:create("Frame", {
            Parent = items["main"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 196, 0, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -196, 0, 56),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        cfg.multi_holder = items["multi_holder"]

        library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["multi_holder"],
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.line,
        })

        items["shadow"] = library:create("ImageLabel", {
            ImageColor3 = rgb(0, 0, 0),
            ScaleType = Enum.ScaleType.Slice,
            Parent = items["main"],
            BorderColor3 = rgb(0, 0, 0),
            Name = "\0",
            BackgroundColor3 = rgb(255, 255, 255),
            Size = dim2(1, 75, 1, 75),
            AnchorPoint = vec2(0.5, 0.5),
            Image = "rbxassetid://112971167999062",
            BackgroundTransparency = 1,
            Position = dim2(0.5, 0, 0.5, 0),
            SliceScale = 0.75,
            ZIndex = -100,
            BorderSizePixel = 0,
            SliceCenter = Rect.new(vec2(112, 112), vec2(147, 147)),
        })

        items["global_fade"] = library:create("Frame", {
            Parent = items["main"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 196, 0, 56),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -196, 1, -81),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
            ZIndex = 2,
        })

        library:create("UICorner", {
            Parent = items["shadow"],
            CornerRadius = dim(0, 5),
        })

        items["info"] = library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["main"],
            Name = "\0",
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 25),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(23, 23, 25),
        })

        library:create("UICorner", {
            Parent = items["info"],
            CornerRadius = dim(0, 10),
        })

        items["grey_fill"] = library:create("Frame", {
            Name = "\0",
            Parent = items["info"],
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 6),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(23, 23, 25),
        })

        items["game"] = library:create("TextLabel", {
            FontFace = fonts.font,
            Parent = items["info"],
            TextColor3 = themes.preset.dimtext,
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.game_name,
            Name = "\0",
            Size = dim2(1, 0, 0, 0),
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 10, 0.5, -1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.XY,
            TextSize = 14,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        items["other_info"] = library:create("TextLabel", {
            Parent = items["info"],
            RichText = true,
            Name = "\0",
            TextColor3 = themes.preset.accent,
            BorderColor3 = rgb(0, 0, 0),
            Text = '<font color="rgb(72, 72, 73)">empulsia, </font>' .. cfg.name .. cfg.suffix,
            Size = dim2(1, 0, 0, 0),
            Position = dim2(0, -10, 0.5, -1),
            AnchorPoint = vec2(0, 0.5),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            AutomaticSize = Enum.AutomaticSize.XY,
            FontFace = fonts.font,
            TextSize = 14,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        library:apply_theme(items["other_info"], "accent", "TextColor3")
    end

    library:draggify(items["main"])
    library:resizify(items["main"])

    function cfg.toggle_menu(bool)
        library["items"].Enabled = bool
    end

    return setmetatable(cfg, library)
end

-- Tab
function library:tab(properties)
    local cfg = {
        name = properties.name or properties.Name or "visuals",
        icon = properties.icon or properties.Icon or "layers",
        tabs = properties.tabs or properties.Tabs or { "Main", "Misc.", "Settings" },
        pages = {},
        current_multi = nil,
        items = {},
    }

    local items = cfg.items
    do
        items["tab_holder"] = library:create("Frame", {
            Parent = library.cache,
            Name = "\0",
            Visible = false,
            BackgroundTransparency = 1,
            Position = dim2(0, 196, 0, 56),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -216, 1, -101),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        items["button"] = library:create("TextButton", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = "",
            Parent = self.items["button_holder"],
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Name = "\0",
            Size = dim2(1, 0, 0, 35),
            BorderSizePixel = 0,
            TextSize = 16,
            BackgroundColor3 = rgb(29, 29, 29),
        })

        items["icon"] = library:create("ImageLabel", {
            ImageColor3 = themes.preset.dimicon,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["button"],
            AnchorPoint = vec2(0, 0.5),
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0.5, 0),
            Name = "\0",
            Size = dim2(0, 22, 0, 22),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        ApplyIcon(items["icon"], cfg.icon)
        library:apply_theme(items["icon"], "accent", "ImageColor3")

        items["name"] = library:create("TextLabel", {
            FontFace = fonts.font,
            TextColor3 = themes.preset.dimtext,
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.name,
            Parent = items["button"],
            Name = "\0",
            Size = dim2(0, 0, 1, 0),
            Position = dim2(0, 40, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 16,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIPadding", {
            Parent = items["name"],
            PaddingRight = dim(0, 5),
            PaddingLeft = dim(0, 5),
        })

        library:create("UICorner", {
            Parent = items["button"],
            CornerRadius = dim(0, 7),
        })

        items["multi_section_button_holder"] = library:create("Frame", {
            Parent = library.cache,
            BackgroundTransparency = 1,
            Name = "\0",
            Visible = false,
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIListLayout", {
            Parent = items["multi_section_button_holder"],
            Padding = dim(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
        })

        library:create("UIPadding", {
            PaddingTop = dim(0, 8),
            PaddingBottom = dim(0, 7),
            Parent = items["multi_section_button_holder"],
            PaddingRight = dim(0, 7),
            PaddingLeft = dim(0, 7),
        })

        for _, section in cfg.tabs do
            local data = { items = {} }
            local multi_items = data.items

            multi_items["button"] = library:create("TextButton", {
                FontFace = fonts.font,
                TextColor3 = rgb(255, 255, 255),
                BorderColor3 = rgb(0, 0, 0),
                AutoButtonColor = false,
                Text = "",
                Parent = items["multi_section_button_holder"],
                Name = "\0",
                Size = dim2(0, 0, 0, 39),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 16,
                BackgroundColor3 = rgb(25, 25, 29),
            })

            multi_items["name"] = library:create("TextLabel", {
                FontFace = fonts.font,
                TextColor3 = rgb(62, 62, 63),
                BorderColor3 = rgb(0, 0, 0),
                Text = section,
                Parent = multi_items["button"],
                Name = "\0",
                Size = dim2(0, 0, 1, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 16,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UIPadding", {
                Parent = multi_items["name"],
                PaddingRight = dim(0, 5),
                PaddingLeft = dim(0, 5),
            })

            multi_items["accent"] = library:create("Frame", {
                BorderColor3 = rgb(0, 0, 0),
                AnchorPoint = vec2(0, 1),
                Parent = multi_items["button"],
                BackgroundTransparency = 1,
                Position = dim2(0, 10, 1, 4),
                Name = "\0",
                Size = dim2(1, -20, 0, 6),
                BorderSizePixel = 0,
                BackgroundColor3 = themes.preset.accent,
            })
            library:apply_theme(multi_items["accent"], "accent", "BackgroundColor3")

            library:create("UICorner", {
                Parent = multi_items["accent"],
                CornerRadius = dim(0, 999),
            })

            library:create("UIPadding", {
                Parent = multi_items["button"],
                PaddingRight = dim(0, 10),
                PaddingLeft = dim(0, 10),
            })

            library:create("UICorner", {
                Parent = multi_items["button"],
                CornerRadius = dim(0, 7),
            })

            multi_items["tab"] = library:create("Frame", {
                Parent = library.cache,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = rgb(0, 0, 0),
                Size = dim2(1, -20, 1, -20),
                BorderSizePixel = 0,
                Visible = false,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                Parent = multi_items["tab"],
                Padding = dim(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
            })

            library:create("UIPadding", {
                PaddingTop = dim(0, 7),
                PaddingBottom = dim(0, 7),
                Parent = multi_items["tab"],
                PaddingRight = dim(0, 7),
                PaddingLeft = dim(0, 7),
            })

            data.text = multi_items["name"]
            data.accent = multi_items["accent"]
            data.button = multi_items["button"]
            data.page = multi_items["tab"]
            data.parent = setmetatable(data, library):sub_tab({}).items["tab_parent"]

            function data.open_page()
                local page = cfg.current_multi
                if page and page.text ~= data.text then
                    self.items["global_fade"].BackgroundTransparency = 0
                    library:tween(self.items["global_fade"], { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, 0.4)
                    page.page.Size = dim2(1, -20, 1, -20)
                end

                if page then
                    library:tween(page.text, { TextColor3 = rgb(62, 62, 63) })
                    library:tween(page.accent, { BackgroundTransparency = 1 })
                    library:tween(page.button, { BackgroundTransparency = 1 })
                    page.page.Visible = false
                    page.page.Parent = library["cache"]
                end

                library:tween(data.text, { TextColor3 = rgb(255, 255, 255) })
                library:tween(data.accent, { BackgroundTransparency = 0 })
                library:tween(data.button, { BackgroundTransparency = 0 })
                library:tween(data.page, { Size = dim2(1, 0, 1, 0) }, Enum.EasingStyle.Quad, 0.4)

                data.page.Visible = true
                data.page.Parent = items["tab_holder"]
                cfg.current_multi = data
                library:close_element()
            end

            multi_items["button"].MouseButton1Down:Connect(function()
                data.open_page()
            end)

            cfg.pages[#cfg.pages + 1] = setmetatable(data, library)
        end

        cfg.pages[1].open_page()
    end

    function cfg.open_tab()
        local selected_tab = self.selected_tab
        if selected_tab then
            if selected_tab[4] ~= items["tab_holder"] then
                self.items["global_fade"].BackgroundTransparency = 0
                library:tween(self.items["global_fade"], { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, 0.4)
                selected_tab[4].Size = dim2(1, -216, 1, -101)
            end
            library:tween(selected_tab[1], { BackgroundTransparency = 1 })
            library:tween(selected_tab[2], { ImageColor3 = themes.preset.dimicon })
            library:tween(selected_tab[3], { TextColor3 = themes.preset.dimtext })
            selected_tab[4].Visible = false
            selected_tab[4].Parent = library["cache"]
            selected_tab[5].Visible = false
            selected_tab[5].Parent = library["cache"]
        end

        library:tween(items["button"], { BackgroundTransparency = 0 })
        library:tween(items["icon"], { ImageColor3 = themes.preset.accent })
        library:tween(items["name"], { TextColor3 = rgb(255, 255, 255) })
        library:tween(items["tab_holder"], { Size = dim2(1, -196, 1, -81) }, Enum.EasingStyle.Quad, 0.4)

        items["tab_holder"].Visible = true
        items["tab_holder"].Parent = self.items["main"]
        items["multi_section_button_holder"].Visible = true
        items["multi_section_button_holder"].Parent = self.items["multi_holder"]

        self.selected_tab = {
            items["button"],
            items["icon"],
            items["name"],
            items["tab_holder"],
            items["multi_section_button_holder"],
        }
        library:close_element()
    end

    items["button"].MouseButton1Down:Connect(function()
        cfg.open_tab()
    end)

    if not self.selected_tab then
        cfg.open_tab(true)
    end

    return unpack(cfg.pages)
end

function library:seperator(properties)
    local cfg = { items = {}, name = properties.Name or properties.name or "General" }
    local items = cfg.items
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = self.items["button_holder"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        Position = dim2(0, 40, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })
    return setmetatable(cfg, library)
end

function library:column(properties)
    local cfg = { items = {}, size = properties.size or 1 }
    local items = cfg.items
    items["column"] = library:create("Frame", {
        Parent = self["parent"] or self.items["tab_parent"],
        BackgroundTransparency = 1,
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, cfg.size, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", {
        PaddingBottom = dim(0, 10),
        Parent = items["column"],
    })
    library:create("UIListLayout", {
        Parent = items["column"],
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Padding = dim(0, 10),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return setmetatable(cfg, library)
end

function library:sub_tab(properties)
    local cfg = { items = {}, order = properties.order or 0, size = properties.size or 1 }
    local items = cfg.items
    items["tab_parent"] = library:create("Frame", {
        Parent = self.items["tab"],
        BackgroundTransparency = 1,
        Name = "\0",
        Size = dim2(0, 0, cfg.size, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        Visible = true,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
        Parent = items["tab_parent"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return setmetatable(cfg, library)
end

function library:section(properties)
    local cfg = {
        name = properties.name or properties.Name or "section",
        side = properties.side or properties.Side or "left",
        default = properties.default or properties.Default or false,
        size = properties.size or properties.Size or self.size or 0.5,
        icon = properties.icon or properties.Icon or "box",
        fading_toggle = properties.fading or properties.Fading or false,
        items = {},
    }

    local items = cfg.items
    do
        items["outline"] = library:create("Frame", {
            Name = "\0",
            Parent = self.items["column"],
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 0, cfg.size, -3),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.element,
        })

        library:create("UICorner", {
            Parent = items["outline"],
            CornerRadius = dim(0, 7),
        })

        items["inline"] = library:create("Frame", {
            Parent = items["outline"],
            Name = "\0",
            Position = dim2(0, 1, 0, 1),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.section,
        })

        library:create("UICorner", {
            Parent = items["inline"],
            CornerRadius = dim(0, 7),
        })

        items["scrolling"] = library:create("ScrollingFrame", {
            ScrollBarImageColor3 = rgb(44, 44, 46),
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            Parent = items["inline"],
            Name = "\0",
            Size = dim2(1, 0, 1, -40),
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 35),
            BackgroundColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            BorderSizePixel = 0,
            CanvasSize = dim2(0, 0, 0, 0),
        })

        items["elements"] = library:create("Frame", {
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["scrolling"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0, 10),
            Size = dim2(1, -20, 0, 0),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIListLayout", {
            Parent = items["elements"],
            Padding = dim(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        library:create("UIPadding", {
            PaddingBottom = dim(0, 15),
            Parent = items["elements"],
        })

        items["button"] = library:create("TextButton", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = "",
            AutoButtonColor = false,
            Parent = items["outline"],
            Name = "\0",
            Position = dim2(0, 1, 0, 1),
            Size = dim2(1, -2, 0, 35),
            BorderSizePixel = 0,
            TextSize = 16,
            BackgroundColor3 = rgb(19, 19, 21),
        })

        library:create("UICorner", {
            Parent = items["button"],
            CornerRadius = dim(0, 7),
        })

        items["Icon"] = library:create("ImageLabel", {
            ImageColor3 = themes.preset.accent,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["button"],
            AnchorPoint = vec2(0, 0.5),
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0.5, 0),
            Name = "\0",
            Size = dim2(0, 22, 0, 22),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        ApplyIcon(items["Icon"], cfg.icon)
        library:apply_theme(items["Icon"], "accent", "ImageColor3")

        items["section_title"] = library:create("TextLabel", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.name,
            Parent = items["button"],
            Name = "\0",
            Size = dim2(0, 0, 1, 0),
            Position = dim2(0, 40, 0, -1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 16,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["button"],
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(36, 36, 37),
        })
    end

    return setmetatable(cfg, library)
end

-- Toggle (kept from original for compatibility)
function library:toggle(options)
    local cfg = {
        enabled = options.enabled or nil,
        name = options.name or "Toggle",
        info = options.info or nil,
        flag = options.flag or library:next_flag(),
        type = options.type and string.lower(options.type) or "checkbox",
        default = options.default or false,
        folding = options.folding or false,
        callback = options.callback or function() end,
        items = {},
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["toggle"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["toggle"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["toggle"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    items["checkbox"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Parent = items["right_components"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        Size = dim2(0, 16, 0, 16),
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = rgb(33, 33, 35),
    })
    library:apply_theme(items["checkbox"], "accent", "BackgroundColor3")

    library:create("UICorner", {
        Parent = items["checkbox"],
        CornerRadius = dim(0, 4),
    })

    items["checkbox_inline"] = library:create("Frame", {
        Parent = items["checkbox"],
        Size = dim2(1, -2, 1, -2),
        Name = "\0",
        BorderMode = Enum.BorderMode.Inset,
        BorderColor3 = rgb(0, 0, 0),
        Position = dim2(0, 1, 0, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(33, 33, 35),
    })
    library:apply_theme(items["checkbox_inline"], "accent", "BackgroundColor3")

    library:create("UICorner", {
        Parent = items["checkbox_inline"],
        CornerRadius = dim(0, 4),
    })

    function cfg.set(bool)
        cfg.enabled = bool
        flags[cfg.flag] = bool
        library:tween(items["checkbox"], { BackgroundColor3 = bool and themes.preset.accent or rgb(33, 33, 35) })
        library:tween(items["checkbox_inline"], { BackgroundColor3 = bool and themes.preset.accent or rgb(33, 33, 35) })
        cfg.callback(bool)
    end

    items["checkbox"].MouseButton1Click:Connect(function()
        cfg.set(not cfg.enabled)
    end)

    items["toggle"].MouseButton1Click:Connect(function()
        cfg.set(not cfg.enabled)
    end)

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

-- Slider (Zolar style)
function library:slider(options)
    local cfg = {
        name = options.name or "Slider",
        min = options.min or 0,
        max = options.max or 100,
        default = options.default or options.min or 0,
        interval = options.interval or options.decimals or 1,
        suffix = options.suffix or "",
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        items = {},
        value = 0,
        sliding = false,
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["slider"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 42),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    -- Top row: name (left) + value (right) — both constrained so value never leaves the menu
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["slider"],
        Name = "\0",
        Size = dim2(1, -70, 0, 18),
        Position = dim2(0, 5, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["value"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = tostring(cfg.default) .. cfg.suffix,
        Parent = items["slider"],
        Name = "\0",
        Size = dim2(0, 60, 0, 18),
        Position = dim2(1, -65, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["track"] = library:create("Frame", {
        Parent = items["slider"],
        Name = "\0",
        Position = dim2(0, 5, 0, 24),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -10, 0, 8),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["track"],
        CornerRadius = dim(0, 4),
    })

    items["fill"] = library:create("Frame", {
        Parent = items["track"],
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent,
    })
    library:apply_theme(items["fill"], "accent", "BackgroundColor3")

    library:create("UICorner", {
        Parent = items["fill"],
        CornerRadius = dim(0, 4),
    })

    items["knob"] = library:create("Frame", {
        Parent = items["track"],
        Name = "\0",
        AnchorPoint = vec2(0.5, 0.5),
        Position = dim2(0, 0, 0.5, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 12, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
        ZIndex = 2,
    })

    library:create("UICorner", {
        Parent = items["knob"],
        CornerRadius = dim(0, 999),
    })

    library:create("UIStroke", {
        Color = themes.preset.accent,
        Parent = items["knob"],
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    library:apply_theme(items["knob"]:FindFirstChildOfClass("UIStroke"), "accent", "Color")

    items["hit"] = library:create("TextButton", {
        Parent = items["track"],
        Name = "\0",
        Text = "",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        ZIndex = 3,
        BorderSizePixel = 0,
    })

    function cfg.set(value)
        value = clamp(library:round(value, cfg.interval), cfg.min, cfg.max)
        cfg.value = value
        flags[cfg.flag] = value

        local fraction = (cfg.max - cfg.min) == 0 and 0 or (value - cfg.min) / (cfg.max - cfg.min)
        items["fill"].Size = dim2(fraction, 0, 1, 0)
        items["knob"].Position = dim2(fraction, 0, 0.5, 0)
        items["value"].Text = tostring(value) .. cfg.suffix

        if not library.silent then
            cfg.callback(value)
        end
    end

    local function calculate(input)
        local fraction = clamp((input.Position.X - items["track"].AbsolutePosition.X) / items["track"].AbsoluteSize.X, 0, 1)
        return cfg.min + (cfg.max - cfg.min) * fraction
    end

    items["hit"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.sliding = true
            cfg.set(calculate(input))
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if cfg.sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            cfg.set(calculate(input))
        end
    end)

    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.sliding = false
        end
    end)

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

-- Dropdown (Zolar style with search)
function library:dropdown(options)
    local cfg = {
        name = options.name or "Dropdown",
        options = options.items or options.Options or options.options or {},
        default = options.default,
        multi = options.multi or false,
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        items = {},
        value = nil,
        open = false,
    }

    if cfg.multi then
        cfg.value = {}
    end

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["dropdown"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 54),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["dropdown"],
        Name = "\0",
        Size = dim2(1, -10, 0, 18),
        Position = dim2(0, 5, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["box"] = library:create("Frame", {
        Parent = items["dropdown"],
        Name = "\0",
        Position = dim2(0, 5, 0, 22),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -10, 0, 28),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["box"],
        CornerRadius = dim(0, 6),
    })

    items["selected"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = "None",
        Parent = items["box"],
        Name = "\0",
        Size = dim2(1, -34, 1, 0),
        Position = dim2(0, 11, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["arrow"] = library:create("ImageLabel", {
        ImageColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Parent = items["box"],
        AnchorPoint = vec2(1, 0.5),
        BackgroundTransparency = 1,
        Position = dim2(1, -10, 0.5, 0),
        Name = "\0",
        Size = dim2(0, 14, 0, 14),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    ApplyIcon(items["arrow"], "chevron-down")

    items["hit"] = library:create("TextButton", {
        Parent = items["box"],
        Name = "\0",
        Text = "",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        ZIndex = 2,
        BorderSizePixel = 0,
    })

    -- Popup
    local popup = {
        open = false,
        order = {},
    }

    local popupFrame = library:create("Frame", {
        Parent = library["other"],
        Name = "\0",
        Size = dim2(0, 150, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.element,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 50,
    })

    library:create("UICorner", {
        Parent = popupFrame,
        CornerRadius = dim(0, 6),
    })

    local searchHolder = library:create("Frame", {
        Parent = popupFrame,
        Name = "\0",
        Size = dim2(1, 0, 0, 30),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.element,
        Visible = false,
        ZIndex = 51,
    })

    local searchIcon = library:create("ImageLabel", {
        Parent = searchHolder,
        BackgroundTransparency = 1,
        Position = dim2(0, 9, 0, 8),
        Size = dim2(0, 13, 0, 13),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 52,
    })
    ApplyIcon(searchIcon, "search")

    local searchBox = library:create("TextBox", {
        Parent = searchHolder,
        FontFace = fonts.font,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = themes.preset.dimtext,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 27, 0, 0),
        Size = dim2(1, -32, 1, 0),
        TextSize = 14,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        ZIndex = 52,
    })

    library:create("Frame", {
        Parent = searchHolder,
        Position = dim2(0, 6, 1, -1),
        Size = dim2(1, -12, 0, 1),
        BackgroundColor3 = themes.preset.line,
        BorderSizePixel = 0,
        ZIndex = 52,
    })

    local scroll = library:create("ScrollingFrame", {
        Parent = popupFrame,
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = dim2(0, 0, 0, 0),
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 51,
    })

    library:create("UIListLayout", {
        Parent = scroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 3),
    })

    library:create("UIPadding", {
        Parent = scroll,
        PaddingTop = dim(0, 4),
        PaddingBottom = dim(0, 4),
        PaddingLeft = dim(0, 4),
        PaddingRight = dim(0, 4),
    })

    local function applySearch(query)
        query = string.lower(query or "")
        for _, data in popup.order do
            local match = query == "" or string.find(string.lower(data.name), query, 1, true) ~= nil
            data.row.Visible = match
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applySearch(searchBox.Text)
    end)

    local function addRow(text)
        local row = library:create("TextButton", {
            Parent = scroll,
            Text = "",
            AutoButtonColor = false,
            Size = dim2(1, -4, 0, 26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.section,
            ZIndex = 52,
        })

        library:create("UICorner", {
            Parent = row,
            CornerRadius = dim(0, 4),
        })

        local line = library:create("Frame", {
            Parent = row,
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 6, 0.5, 0),
            Size = dim2(0, 3, 0, 0),
            BackgroundColor3 = themes.preset.accent,
            BorderSizePixel = 0,
            ZIndex = 53,
        })
        library:apply_theme(line, "accent", "BackgroundColor3")

        library:create("UICorner", {
            Parent = line,
            CornerRadius = dim(0, 4),
        })

        local label = library:create("TextLabel", {
            Parent = row,
            FontFace = fonts.font,
            Text = text,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(0, 14, 0, 0),
            Size = dim2(1, -20, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BorderSizePixel = 0,
            ZIndex = 53,
        })

        local data = {
            name = text,
            selected = false,
            row = row,
            line = line,
            label = label,
        }

        function data:Set(active, instant)
            data.selected = active
            local color = active and themes.preset.text or themes.preset.dimtext
            local bg = active and 0 or 1
            local lineH = active and 16 or 0
            if instant then
                row.BackgroundTransparency = bg
                label.TextColor3 = color
                line.Size = dim2(0, 3, 0, lineH)
            else
                library:tween(row, { BackgroundTransparency = bg })
                library:tween(label, { TextColor3 = color })
                library:tween(line, { Size = dim2(0, 3, 0, lineH) })
            end
        end

        row.MouseEnter:Connect(function()
            if not data.selected then
                library:tween(row, { BackgroundTransparency = 0.7 })
            end
        end)

        row.MouseLeave:Connect(function()
            if not data.selected then
                library:tween(row, { BackgroundTransparency = 1 })
            end
        end)

        row.MouseButton1Down:Connect(function()
            if cfg.multi then
                local idx = find(cfg.value, data.name)
                if idx then
                    remove(cfg.value, idx)
                    data:Set(false)
                else
                    insert(cfg.value, data.name)
                    data:Set(true)
                end
            else
                cfg.value = data.name
                for _, other in popup.order do
                    other:Set(other == data)
                end
                cfg.set_visible(false)
                cfg.open = false
            end
            cfg.report()
        end)

        insert(popup.order, data)
        return data
    end

    function cfg.report()
        flags[cfg.flag] = cfg.value
        if cfg.multi then
            items["selected"].Text = #cfg.value > 0 and concat(cfg.value, ", ") or "None"
        else
            items["selected"].Text = cfg.value ~= nil and tostring(cfg.value) or "None"
        end
        if not library.silent then
            cfg.callback(cfg.value)
        end
    end

    function cfg.set_visible(bool)
        popup.open = bool
        if bool then
            local showSearch = #popup.order > 8
            local width = items["box"].AbsoluteSize.X
            local listHeight = min(#popup.order * 30 + 8, 168)

            searchBox.Text = ""
            applySearch("")

            searchHolder.Visible = showSearch
            if showSearch then
                scroll.Position = dim2(0, 0, 0, 30)
                scroll.Size = dim2(1, 0, 1, -30)
                popupFrame.Size = dim2(0, width, 0, listHeight + 30)
            else
                scroll.Position = dim2(0, 0, 0, 0)
                scroll.Size = dim2(1, 0, 1, 0)
                popupFrame.Size = dim2(0, width, 0, listHeight)
            end

            popupFrame.Position = dim2(0, items["box"].AbsolutePosition.X, 0, items["box"].AbsolutePosition.Y + items["box"].AbsoluteSize.Y + 8)
            popupFrame.Parent = library["items"]
            popupFrame.Visible = true
            library:tween(items["arrow"], { Rotation = 180 })
            library:close_element(cfg)
        else
            popupFrame.Visible = false
            popupFrame.Parent = library["other"]
            library:tween(items["arrow"], { Rotation = 0 })
        end
    end

    function cfg.set(value)
        if cfg.multi then
            if type(value) ~= "table" then
                return
            end
            cfg.value = value
            for _, data in popup.order do
                data:Set(find(value, data.name) ~= nil, true)
            end
        else
            local found = false
            for _, data in popup.order do
                if data.name == value then
                    found = true
                end
            end
            if not found and value ~= nil then
                return
            end
            cfg.value = value
            for _, data in popup.order do
                data:Set(data.name == value, true)
            end
        end
        cfg.report()
    end

    function cfg.refresh(list)
        for _, data in popup.order do
            data.row:Destroy()
        end
        popup.order = {}
        cfg.options = list
        for _, option in list do
            addRow(tostring(option))
        end
    end

    items["hit"].MouseButton1Down:Connect(function()
        cfg.open = not cfg.open
        cfg.set_visible(cfg.open)
    end)

    for _, option in cfg.options do
        addRow(tostring(option))
    end

    if cfg.default ~= nil then
        cfg.set(cfg.default)
    else
        cfg.report()
    end

    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

-- Button
function library:button(options)
    local cfg = {
        name = options.name or "Button",
        callback = options.callback or function() end,
        items = {},
    }

    local items = cfg.items
    items["button_element"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["button"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Parent = items["button_element"],
        Name = "\0",
        Position = dim2(1, -4, 0, 0),
        Size = dim2(1, -8, 0, 30),
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["button"],
        CornerRadius = dim(0, 3),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["button"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["button"].MouseButton1Click:Connect(function()
        cfg.callback()
        items["name"].TextColor3 = themes.preset.accent
        library:tween(items["name"], { TextColor3 = themes.preset.text })
    end)

    return setmetatable(cfg, library)
end

-- Textbox
function library:textbox(options)
    local cfg = {
        name = options.name or "TextBox",
        placeholder = options.placeholder or options.placeholdertext or options.holder or "type here...",
        default = options.default or "",
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        items = {},
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["textbox"] = library:create("TextButton", {
        LayoutOrder = -1,
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["textbox"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["textbox"],
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 4, 0, 19),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
    })

    items["input"] = library:create("TextBox", {
        FontFace = fonts.font,
        Text = "",
        Parent = items["right_components"],
        Name = "\0",
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        PlaceholderColor3 = themes.preset.dimtext,
        PlaceholderText = cfg.placeholder,
        ClearTextOnFocus = false,
        TextSize = 14,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Position = dim2(1, 0, 0, 0),
        Size = dim2(1, -4, 0, 30),
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["input"],
        CornerRadius = dim(0, 3),
    })

    library:create("UIPadding", {
        Parent = items["right_components"],
        PaddingTop = dim(0, 4),
        PaddingRight = dim(0, 4),
    })

    function cfg.set(text)
        flags[cfg.flag] = text
        items["input"].Text = text
        if not library.silent then
            cfg.callback(text)
        end
    end

    items["input"]:GetPropertyChangedSignal("Text"):Connect(function()
        cfg.set(items["input"].Text)
    end)

    items["input"].Focused:Connect(function()
        library:tween(items["input"], { TextColor3 = themes.preset.text })
    end)

    items["input"].FocusLost:Connect(function()
        library:tween(items["input"], { TextColor3 = themes.preset.dimtext })
    end)

    if cfg.default ~= "" then
        cfg.set(cfg.default)
    end

    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

-- Keybind
function library:keybind(options)
    local cfg = {
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        name = options.name or nil,
        key = options.key or nil,
        mode = options.mode or "Toggle",
        active = options.default or false,
        open = false,
        binding = nil,
        items = {},
    }

    flags[cfg.flag] = {
        mode = cfg.mode,
        key = cfg.key,
        active = cfg.active,
    }

    local items = cfg.items
    items["keybind_element"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["keybind_element"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["keybind_element"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    items["keybind_holder"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = items["right_components"],
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Size = dim2(0, 0, 0, 16),
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 14,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["keybind_holder"],
        CornerRadius = dim(0, 4),
    })

    items["key"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = "NONE",
        Parent = items["keybind_holder"],
        Name = "\0",
        Size = dim2(1, -12, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["key"],
        PaddingTop = dim(0, 1),
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    function cfg.set(input)
        if type(input) == "boolean" then
            cfg.active = input
            if cfg.mode == "Always" then
                cfg.active = true
            end
        elseif tostring(input):find("Enum") then
            input = input.Name == "Escape" and "NONE" or input
            cfg.key = input or "NONE"
        elseif find({ "Toggle", "Hold", "Always" }, input) then
            if input == "Always" then
                cfg.active = true
            end
            cfg.mode = input
        elseif type(input) == "table" then
            input.key = type(input.key) == "string" and input.key ~= "NONE" and library:convert_enum(input.key) or input.key
            input.key = input.key == Enum.KeyCode.Escape and "NONE" or input.key
            cfg.key = input.key or "NONE"
            cfg.mode = input.mode or "Toggle"
            if input.active then
                cfg.active = input.active
            end
        end

        cfg.callback(cfg.active)

        local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
        local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))
        items["key"].Text = __text or "NONE"

        flags[cfg.flag] = {
            mode = cfg.mode,
            key = cfg.key,
            active = cfg.active,
        }
    end

    items["keybind_holder"].MouseButton1Down:Connect(function()
        task.wait()
        items["key"].Text = "..."
        cfg.binding = library:connection(uis.InputBegan, function(keycode)
            cfg.set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)
            cfg.binding:Disconnect()
            cfg.binding = nil
        end)
    end)

    library:connection(uis.InputBegan, function(input, game_event)
        if not game_event then
            local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
            if selected_key == cfg.key then
                if cfg.mode == "Toggle" then
                    cfg.active = not cfg.active
                    cfg.set(cfg.active)
                elseif cfg.mode == "Hold" then
                    cfg.set(true)
                end
            end
        end
    end)

    library:connection(uis.InputEnded, function(input, game_event)
        if game_event then
            return
        end
        local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
        if selected_key == cfg.key then
            if cfg.mode == "Hold" then
                cfg.set(false)
            end
        end
    end)

    cfg.set({ mode = cfg.mode, active = cfg.active, key = cfg.key })
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

-- Colorpicker (simplified, functional)
function library:colorpicker(options)
    local cfg = {
        name = options.name or "Color",
        flag = options.flag or library:next_flag(),
        color = options.color or options.default or themes.preset.accent,
        alpha = options.alpha or options.transparency or 0,
        callback = options.callback or function() end,
        items = {},
        open = false,
    }

    flags[cfg.flag] = {
        Color = cfg.color,
        Transparency = cfg.alpha,
    }

    local items = cfg.items
    items["colorpicker"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["colorpicker"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["swatch"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Parent = items["colorpicker"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        Size = dim2(0, 16, 0, 16),
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = cfg.color,
    })

    library:create("UICorner", {
        Parent = items["swatch"],
        CornerRadius = dim(0, 4),
    })

    function cfg.set(color, alpha)
        if typeof(color) == "Color3" then
            cfg.color = color
        end
        if alpha then
            cfg.alpha = alpha
        end
        items["swatch"].BackgroundColor3 = cfg.color
        flags[cfg.flag] = {
            Color = cfg.color,
            Transparency = cfg.alpha,
        }
        if not library.silent then
            cfg.callback(cfg.color, cfg.alpha)
        end
    end

    items["swatch"].MouseButton1Click:Connect(function()
        -- Simple cycle through accent presets for performance / simplicity
        local presets = {
            rgb(155, 150, 219),
            rgb(120, 132, 255),
            rgb(96, 170, 255),
            rgb(72, 214, 168),
            rgb(245, 130, 120),
            rgb(240, 118, 150),
        }
        local current = find(presets, cfg.color) or 1
        local nextColor = presets[(current % #presets) + 1]
        cfg.set(nextColor, cfg.alpha)
        if options.name and string.find(string.lower(options.name), "accent") then
            library:update_theme("accent", nextColor)
        end
    end)

    cfg.set(cfg.color, cfg.alpha)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

-- Label
function library:label(options)
    local cfg = {
        name = options.name or "Label",
        items = {},
    }

    local items = cfg.items
    items["label"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = self.items["elements"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["label"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    function cfg.set(text)
        items["label"].Text = tostring(text)
    end

    return setmetatable(cfg, library)
end

-- List
function library:list(properties)
    local cfg = {
        items = {},
        options = properties.options or { "1", "2", "3" },
        flag = properties.flag or library:next_flag(),
        callback = properties.callback or function() end,
        data_store = {},
        current_element = nil,
    }

    local items = cfg.items
    items["list"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        Parent = items["list"],
        Padding = dim(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    library:create("UIPadding", {
        Parent = items["list"],
        PaddingRight = dim(0, 4),
        PaddingLeft = dim(0, 4),
    })

    function cfg.refresh_options(options_to_refresh)
        for _, option in cfg.data_store do
            option:Destroy()
        end
        cfg.data_store = {}

        for _, option_data in options_to_refresh do
            local button = library:create("TextButton", {
                FontFace = fonts.small,
                TextColor3 = rgb(0, 0, 0),
                BorderColor3 = rgb(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = vec2(1, 0),
                Parent = items["list"],
                Name = "\0",
                Position = dim2(1, 0, 0, 0),
                Size = dim2(1, 0, 0, 30),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundColor3 = themes.preset.light,
            })
            cfg.data_store[#cfg.data_store + 1] = button

            local name = library:create("TextLabel", {
                FontFace = fonts.font,
                TextColor3 = themes.preset.dimtext,
                BorderColor3 = rgb(0, 0, 0),
                Text = option_data,
                Parent = button,
                Name = "\0",
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 1, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 14,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UICorner", {
                Parent = button,
                CornerRadius = dim(0, 3),
            })

            button.MouseButton1Click:Connect(function()
                local current = cfg.current_element
                if current and current ~= name then
                    library:tween(current, { TextColor3 = themes.preset.dimtext })
                end
                flags[cfg.flag] = option_data
                cfg.callback(option_data)
                library:tween(name, { TextColor3 = themes.preset.text })
                cfg.current_element = name
            end)

            name.MouseEnter:Connect(function()
                if cfg.current_element == name then
                    return
                end
                library:tween(name, { TextColor3 = rgb(140, 140, 140) })
            end)

            name.MouseLeave:Connect(function()
                if cfg.current_element == name then
                    return
                end
                library:tween(name, { TextColor3 = themes.preset.dimtext })
            end)
        end
    end

    cfg.refresh_options(cfg.options)
    return setmetatable(cfg, library)
end

-- Config + Theme panel (Zolar style)
function library:init_config(window)
    window:seperator({ name = "Settings" })
    local main = window:tab({ name = "Configs", icon = "folder", tabs = { "Configs", "Theme", "User" } })

    -- ========== CONFIGS TAB ==========
    local left = main:column({})
    local right = main:column({})

    -- Create + list section
    local createSec = left:section({ name = "Configs", icon = "folder", size = 1 })

    createSec:textbox({
        name = "Config name",
        flag = "config_name_text",
        placeholder = "config name",
    })

    createSec:button({
        name = "Create",
        callback = function()
            local name = tostring(flags["config_name_text"] or ""):gsub("[^%w _%-]", "")
            if name == "" then
                library:Notification({ Name = "Name required", Description = "Type a name before creating.", Icon = "triangle-alert" })
                return
            end
            local path = library.directory .. "/configs/" .. name .. ".json"
            if isfile and isfile(path) then
                library:Notification({ Name = "Already exists", Description = "\"" .. name .. "\" already exists. Use Overwrite.", Icon = "triangle-alert" })
                return
            end
            library:SaveConfigFile(name)
            flags["config_name_list"] = name
            if config_list then config_list.refresh_options(library:ListConfigs()) end
            if show_info then show_info(name) end
            library:Notification({ Name = "Config created", Description = "\"" .. name .. "\" saved.", Icon = "plus" })
        end,
    })

    local config_list = createSec:list({
        options = library:ListConfigs(),
        flag = "config_name_list",
        callback = function(name)
            if show_info then show_info(name) end
            library:LoadConfigFile(name)
            library:Notification({ Name = "Config loaded", Description = "Restored \"" .. name .. "\".", Icon = "check" })
        end,
    })

    createSec:button({
        name = "Save / Overwrite",
        callback = function()
            local name = flags["config_name_list"] or flags["config_name_text"]
            if not name or name == "" then
                library:Notification({ Name = "Select a config", Description = "Pick a config or type a name first.", Icon = "triangle-alert" })
                return
            end
            library:SaveConfigFile(name)
            if config_list then config_list.refresh_options(library:ListConfigs()) end
            if show_info then show_info(name) end
            library:Notification({ Name = "Config saved", Description = "Overwrote \"" .. name .. "\".", Icon = "download" })
        end,
    })

    createSec:button({
        name = "Copy to Clipboard",
        callback = function()
            local name = flags["config_name_list"]
            if not name then return end
            local path = library.directory .. "/configs/" .. name .. ".json"
            if isfile and isfile(path) and setclipboard then
                setclipboard(readfile(path))
                library:Notification({ Name = "Config copied", Description = "\"" .. name .. "\" copied.", Icon = "share-2" })
            end
        end,
    })

    createSec:button({
        name = "Delete",
        callback = function()
            local name = flags["config_name_list"]
            if not name then return end
            local path = library.directory .. "/configs/" .. name .. ".json"
            if isfile and isfile(path) then delfile(path) end
            if config_list then config_list.refresh_options(library:ListConfigs()) end
            if show_info then show_info(nil) end
            library:Notification({ Name = "Config deleted", Description = "Removed \"" .. name .. "\".", Icon = "trash-2" })
        end,
    })

    -- Config info panel
    local infoSec = right:section({ name = "Config info", icon = "info", size = 0.55 })

    local info_labels = {}
    local function add_info_row(label)
        local l = infoSec:label({ name = label .. ": -" })
        info_labels[label] = l
        return l
    end

    add_info_row("Config version")
    add_info_row("Compatibility")
    add_info_row("Created")
    add_info_row("Creator")
    add_info_row("Saved flags")

    function show_info(name)
        if not name then
            for k, l in info_labels do
                l:Set(k .. ": -")
            end
            return
        end
        local path = library.directory .. "/configs/" .. name .. ".json"
        local data = {}
        pcall(function()
            data = http_service:JSONDecode(readfile(path))
        end)
        local count = 0
        for key in data do
            if string.sub(tostring(key), 1, 2) ~= "__" then
                count = count + 1
            end
        end
        local same = data.__version == library.version
        info_labels["Config version"]:Set("Config version: " .. (data.__version or "Unknown"))
        info_labels["Compatibility"]:Set("Compatibility: " .. (same and "Compatible" or "Outdated"))
        info_labels["Created"]:Set("Created: " .. (data.__created or "Unknown"))
        info_labels["Creator"]:Set("Creator: " .. (data.__creator or "Unknown"))
        info_labels["Saved flags"]:Set("Saved flags: " .. tostring(count) .. " flags")
    end

    show_info(nil)

    -- Theme quick section on configs page
    local themeQuick = right:section({ name = "Theme", icon = "palette", size = 0.45 })
    themeQuick:colorpicker({
        name = "Accent",
        flag = "menu_accent",
        color = themes.preset.accent,
        callback = function(color)
            library:update_theme("accent", color)
        end,
    })
    themeQuick:label({ name = "Presets: Default / Azure / Emerald / Ocean / Rose" })
    themeQuick:button({
        name = "Default Theme",
        callback = function()
            library:update_theme("accent", rgb(155, 150, 219))
            library:Notification({ Name = "Theme", Description = "Default accent applied.", Icon = "palette" })
        end,
    })
    themeQuick:button({
        name = "Azure Theme",
        callback = function()
            library:update_theme("accent", rgb(96, 150, 255))
            library:Notification({ Name = "Theme", Description = "Azure accent applied.", Icon = "palette" })
        end,
    })
    themeQuick:button({
        name = "Emerald Theme",
        callback = function()
            library:update_theme("accent", rgb(76, 214, 148))
            library:Notification({ Name = "Theme", Description = "Emerald accent applied.", Icon = "palette" })
        end,
    })

    -- ========== THEME TAB ==========
    local themePage = select(2, window:tab({ name = "Theme", icon = "palette", tabs = { "Colors" } }))
    -- Note: main already created Configs/Theme/User subtabs via the first tab call.
    -- Theme subtab is the second page from the Configs tab above.

    -- ========== USER TAB ==========
    -- Re-fetch pages: Configs tab returned pages for "Configs", "Theme", "User"
    -- We already used first two columns on page 1. Page 3 = User.

    -- Actually the tab() returns multiple pages. Let me structure properly.
end

-- User control panel (matches screenshot style)
function library:UserPanel(window)
    local userTab = window:tab({
        name = "User",
        icon = "user",
        tabs = { "Profile" },
    })

    local col = userTab:column({})
    local sec = col:section({ name = "Profile", icon = "user", size = 1 })

    local display = lp.DisplayName or lp.Name
    local uname = "@" .. (lp.Name or "unknown")
    local uid = tostring(lp.UserId or 0)

    local accountAge = "Unknown"
    pcall(function()
        accountAge = tostring(lp.AccountAge or 0) .. " days"
    end)

    sec:label({ name = display })
    sec:label({ name = uname })
    sec:label({ name = "User ID: " .. uid })
    sec:label({ name = "Account age: " .. accountAge })
    sec:label({ name = "Library: Aether v" .. library.version })

    sec:slider({
        name = "Interface scale",
        flag = "ui_scale",
        min = 50,
        max = 150,
        default = 100,
        suffix = "%",
        callback = function(v)
            -- scale is handled if UIScale exists
            if library.UIScale then
                library.UIScale.Scale = v / 100
            end
        end,
    })

    sec:keybind({
        name = "Menu toggle",
        flag = "menu_bind",
        key = Enum.KeyCode.RightControl,
        mode = "Toggle",
        callback = function(active)
            if window and window.toggle_menu then
                window.toggle_menu(active)
            end
        end,
    })

    sec:button({
        name = "Unload",
        callback = function()
            library:Notification({ Name = "Unloading", Description = "Aether is shutting down.", Icon = "power" })
            task.wait(0.4)
            library:unload_menu()
        end,
    })

    return sec
end

-- Watermark (Zolar style, Aether colors)
function library:Watermark(params)
    params = params or {}
    if library.WatermarkBar then
        return library.WatermarkBar
    end

    -- Dedicated always-on ScreenGui so watermark never hides with the menu
    if not library["watermark_gui"] then
        library["watermark_gui"] = library:create("ScreenGui", {
            Parent = coregui,
            Name = "\0",
            Enabled = true,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = 9999,
        })
    end

    local Icon = params.Icon or "layers"
    local Items = {}

    Items.Bar = library:create("Frame", {
        Parent = library["watermark_gui"],
        AnchorPoint = vec2(0.5, 0),
        Position = dim2(0.5, 0, 0, 14),
        Size = dim2(0, 0, 0, 32),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 60,
        Active = false,
    })
    Items.Bar.AutomaticSize = Enum.AutomaticSize.X

    library:create("UICorner", {
        Parent = Items.Bar,
        CornerRadius = dim(0, 8),
    })

    library:create("UIPadding", {
        Parent = Items.Bar,
        PaddingLeft = dim(0, 12),
        PaddingRight = dim(0, 12),
    })

    library:create("UIListLayout", {
        Parent = Items.Bar,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 10),
    })

    local order = 0
    local function NextOrder()
        order = order + 1
        return order
    end

    local iconLabel = library:create("ImageLabel", {
        Parent = Items.Bar,
        BackgroundTransparency = 1,
        Size = dim2(0, 20, 0, 20),
        ImageColor3 = rgb(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 61,
        ScaleType = Enum.ScaleType.Fit,
    })
    iconLabel.LayoutOrder = NextOrder()
    ApplyIcon(iconLabel, Icon)

    local function Separator()
        local Sep = library:create("Frame", {
            Parent = Items.Bar,
            Size = dim2(0, 1, 0, 14),
            BackgroundColor3 = themes.preset.light,
            BorderSizePixel = 0,
            ZIndex = 61,
        })
        Sep.LayoutOrder = NextOrder()
    end

    local function Stat(Text)
        local Label = library:create("TextLabel", {
            Parent = Items.Bar,
            FontFace = fonts.font,
            Text = Text,
            TextSize = 14,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Size = dim2(0, 0, 0, 16),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 61,
        })
        Label.LayoutOrder = NextOrder()
        return Label
    end

    Separator()
    local GameStat = Stat("...")
    Separator()
    local FpsStat = Stat("0 fps")
    Separator()
    local PingStat = Stat("0 ms")
    Separator()
    local TimeStat = Stat(os.date("%I:%M %p"))

    task.spawn(function()
        local Ok, Info = pcall(function()
            return marketplace:GetProductInfo(game.PlaceId)
        end)
        GameStat.Text = (Ok and Info and Info.Name) or "Unknown"
    end)

    local Frames = 0
    library:connection(run.RenderStepped, function()
        Frames = Frames + 1
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if not Items.Bar or not Items.Bar.Parent then
                break
            end
            FpsStat.Text = tostring(Frames * 2) .. " fps"
            Frames = 0

            local Ping = 0
            pcall(function()
                local Stat = stats.Network.ServerStatsItem["Data Ping"]
                Ping = floor(Stat:GetValue())
            end)
            PingStat.Text = tostring(Ping) .. " ms"
            TimeStat.Text = os.date("%I:%M %p")
        end
    end)

    -- Watermark is completely non-interactive / non-draggable
    Items.Bar.Active = false
    library.WatermarkBar = Items.Bar

    local Watermark = { Instance = Items.Bar }

    function Watermark:SetIcon(NewIcon)
        ApplyIcon(iconLabel, NewIcon)
    end

    function Watermark:SetVisible(Bool)
        Items.Bar.Visible = Bool
    end

    return Watermark
end

-- Notifications (right side, cleaner design with icon)
function notifications:refresh_notifs()
    local offset = 50
    local viewport = camera.ViewportSize.X
    for i, v in notifications.notifs do
        if v and v.Parent then
            local targetX = viewport - v.AbsoluteSize.X - 20
            library:tween(v, { Position = dim2(0, targetX, 0, offset) }, Enum.EasingStyle.Quad, 0.35)
            offset = offset + (v.AbsoluteSize.Y + 12)
        end
    end
    return offset
end

function notifications:fade(path, is_fading)
    local fading = is_fading and 1 or 0
    library:tween(path, { BackgroundTransparency = fading }, Enum.EasingStyle.Quad, 0.8)
    for _, instance in path:GetDescendants() do
        if instance:IsA("UIStroke") then
            library:tween(instance, { Transparency = fading }, Enum.EasingStyle.Quad, 0.8)
        elseif instance:IsA("TextLabel") then
            library:tween(instance, { TextTransparency = fading }, Enum.EasingStyle.Quad, 0.8)
        elseif instance:IsA("ImageLabel") then
            library:tween(instance, { ImageTransparency = fading }, Enum.EasingStyle.Quad, 0.8)
        elseif instance:IsA("Frame") and instance ~= path then
            -- keep accent bar visible longer
        end
    end
end

function notifications:create_notification(options)
    local cfg = {
        name = options.name or "Notification",
        info = options.info or options.Description or "",
        lifetime = options.lifetime or 3.5,
        icon = options.icon or options.Icon or "terminal",
        items = {},
    }

    local items = cfg.items
    local width = 240

    items["notification"] = library:create("Frame", {
        Parent = library["items"],
        Size = dim2(0, width, 0, 0),
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        AnchorPoint = vec2(0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = themes.preset.section,
        ZIndex = 80,
    })

    library:create("UICorner", {
        Parent = items["notification"],
        CornerRadius = dim(0, 8),
    })

    library:create("UIStroke", {
        Color = rgb(30, 30, 36),
        Parent = items["notification"],
        Transparency = 1,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    -- Left accent strip
    items["strip"] = library:create("Frame", {
        Parent = items["notification"],
        Size = dim2(0, 3, 1, 0),
        Position = dim2(0, 0, 0, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent,
        BackgroundTransparency = 1,
        ZIndex = 81,
    })
    library:apply_theme(items["strip"], "accent", "BackgroundColor3")

    library:create("UICorner", {
        Parent = items["strip"],
        CornerRadius = dim(0, 8),
    })

    -- Icon
    items["icon"] = library:create("ImageLabel", {
        Parent = items["notification"],
        BackgroundTransparency = 1,
        Position = dim2(0, 14, 0, 12),
        Size = dim2(0, 18, 0, 18),
        ImageColor3 = themes.preset.accent,
        BorderSizePixel = 0,
        ZIndex = 82,
        ImageTransparency = 1,
    })
    library:apply_theme(items["icon"], "accent", "ImageColor3")
    ApplyIcon(items["icon"], cfg.icon)

    -- Title
    items["title"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["notification"],
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 40, 0, 10),
        Size = dim2(1, -52, 0, 18),
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 14,
        TextTransparency = 1,
        ZIndex = 82,
    })

    -- Description
    items["info"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.info,
        Parent = items["notification"],
        Name = "\0",
        Position = dim2(0, 40, 0, 30),
        Size = dim2(1, -52, 0, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 13,
        TextTransparency = 1,
        ZIndex = 82,
    })

    library:create("UIPadding", {
        PaddingBottom = dim(0, 14),
        Parent = items["notification"],
    })

    -- Progress bar at bottom
    items["bar"] = library:create("Frame", {
        AnchorPoint = vec2(0, 1),
        Parent = items["notification"],
        Name = "\0",
        Position = dim2(0, 0, 1, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 0, 2),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent,
        ZIndex = 83,
    })
    library:apply_theme(items["bar"], "accent", "BackgroundColor3")

    local index = #notifications.notifs + 1
    notifications.notifs[index] = items["notification"]

    -- Start off-screen to the right
    local viewport = camera.ViewportSize.X
    items["notification"].Position = dim2(0, viewport + 20, 0, 50)
    items["notification"].BackgroundTransparency = 0

    -- Fade in elements
    library:tween(items["strip"], { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad, 0.4)
    library:tween(items["icon"], { ImageTransparency = 0 }, Enum.EasingStyle.Quad, 0.4)
    library:tween(items["title"], { TextTransparency = 0 }, Enum.EasingStyle.Quad, 0.4)
    library:tween(items["info"], { TextTransparency = 0 }, Enum.EasingStyle.Quad, 0.4)
    library:tween(items["notification"]:FindFirstChildOfClass("UIStroke"), { Transparency = 0 }, Enum.EasingStyle.Quad, 0.4)

    local offset = notifications:refresh_notifs()
    local targetX = viewport - width - 20
    library:tween(items["notification"], { Position = dim2(0, targetX, 0, offset) }, Enum.EasingStyle.Quint, 0.45)
    library:tween(items["bar"], { Size = dim2(1, 0, 0, 2) }, Enum.EasingStyle.Linear, cfg.lifetime)

    task.spawn(function()
        task.wait(cfg.lifetime)
        notifications.notifs[index] = nil
        notifications:fade(items["notification"], true)
        library:tween(items["notification"], {
            Position = dim2(0, viewport + 30, 0, items["notification"].Position.Y.Offset)
        }, Enum.EasingStyle.Quad, 0.5)
        notifications:refresh_notifs()
        task.wait(0.6)
        if items["notification"] then
            items["notification"]:Destroy()
        end
    end)
end

-- Expose notification helper
function library:Notification(params)
    notifications:create_notification({
        name = params.Name or params.name or "Notification",
        info = params.Description or params.info or "",
        lifetime = params.Lifetime or 3.5,
        icon = params.Icon or params.icon or "terminal",
    })
end

getgenv().Aether = library
return library
