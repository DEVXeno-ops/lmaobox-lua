--[[
    Ultimate Cathook-style Watermark and Status Display for Lmaobox
    Original Authors: Zade & Trophy
    Enhanced by Devxeno
]]

-- Print initialization message
print("Authentic Cathook-style Watermark and Status Display for Lmaobox loaded successfully")

-- Configuration
local options = {
    PrimaryPos = { X = 10, Y = 10 }, -- Initial position for primary panel
    SecondaryPos = { X = 10, Y = 80 }, -- Initial position for secondary panel
    Padding = 8, -- Padding inside the box
    LineSpacing = 4, -- Spacing between text lines
    ColumnSpacing = 180, -- Spacing between columns
    CornerRadius = 5, -- Rounded corner radius
    ShadowOffset = 3, -- Shadow offset
    FontName = "Verdana", -- Cathook-style font
    FontSize = 13, -- Adjusted for clarity
    FontWeight = 600,
    Colors = {
        Background = { 20, 20, 20, 200 }, -- Cathook-like semi-transparent dark background
        Shadow = { 0, 0, 0, 120 }, -- Subtle shadow
        Text = { 255, 255, 255, 255 }, -- White text
        Border = { 50, 50, 50, 255 }, -- Dark gray border
        Highlight = { 0, 255, 0, 255 }, -- Green for greetings (Cathook style)
        Warning = { 255, 50, 50, 255 }, -- Red for warnings
    },
    RainbowSpeed = 1, -- Speed of RGB rainbow effect
    TogglePrimaryKey = 45, -- INSERT for primary panel
    ToggleSecondaryKey = 46, -- DELETE for secondary panel
    ConfigFile = "ui_positions.txt" -- File to save UI positions
}

-- Variables
local font = nil
local current_fps = 0
local isScriptLoaded = _G.WatermarkStatusLoaded or false
local showPrimary = true -- Primary panel visibility
local showSecondary = true -- Secondary panel visibility
local w, h = 0, 0

-- Load UI positions from file
local function loadUIPositions()
    local file = io.open(options.ConfigFile, "r")
    if file then
        local success, content = pcall(function()
            return file:read("*all")
        end)
        file:close()
        if success and content then
            local pos = loadstring("return " .. content)()
            if pos and type(pos) == "table" then
                options.PrimaryPos.X = pos.PrimaryX or options.PrimaryPos.X
                options.PrimaryPos.Y = pos.PrimaryY or options.PrimaryPos.Y
                options.SecondaryPos.X = pos.SecondaryX or options.SecondaryPos.X
                options.SecondaryPos.Y = pos.SecondaryY or options.SecondaryPos.Y
                print("UI positions loaded from " .. options.ConfigFile)
            end
        end
    end
end

-- Save UI positions to file
local function saveUIPositions()
    local file = io.open(options.ConfigFile, "w")
    if file then
        local success, err = pcall(function()
            file:write(string.format("{ PrimaryX = %d, PrimaryY = %d, SecondaryX = %d, SecondaryY = %d }",
                options.PrimaryPos.X, options.PrimaryPos.Y,
                options.SecondaryPos.X, options.SecondaryPos.Y))
        end)
        file:close()
        if success then
            print("UI positions saved to " .. options.ConfigFile)
        else
            print("Error saving UI positions: " .. tostring(err))
        end
    else
        print("Error: Could not open " .. options.ConfigFile .. " for writing")
    end
end

-- Font creation with fallback
local function initializeFont()
    local success, result = pcall(function()
        return draw.CreateFont(options.FontName, options.FontSize, options.FontWeight) or
               draw.CreateFont("Arial", options.FontSize, options.FontWeight)
    end)
    if success and result then
        return result
    else
        print("Watermark Error: Failed to create font. Using default.")
        return nil
    end
end

-- Initialize font and load positions
font = initializeFont()
loadUIPositions()

-- RGB Rainbow effect
local function RGBRainbow(frequency)
    local success, curtime = pcall(function()
        return globals.RealTime()
    end)
    if not success then
        return 255, 255, 255
    end

    local r = math.floor(math.sin(curtime * frequency + 0) * 127 + 128)
    local g = math.floor(math.sin(curtime * frequency + 2) * 127 + 128)
    local b = math.floor(math.sin(curtime * frequency + 4) * 127 + 128)
    return r, g, b
end

-- Validate color table
local function getColor(colorTable)
    if type(colorTable) == "table" and #colorTable >= 4 then
        return colorTable[1] or 255, colorTable[2] or 255, colorTable[3] or 255, colorTable[4] or 255
    end
    return 255, 255, 255, 255
end

-- Draw rounded rectangle
local function drawRoundedRect(x, y, w, h, radius, r, g, b, a)
    x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
    radius = math.floor(radius)
    if w <= 0 or h <= 0 or x < 0 or y < 0 then
        return
    end

    draw.Color(r, g, b, a)
    draw.FilledRect(x + radius, y, x + w - radius, y + h)
    draw.FilledRect(x, y + radius, x + w, y + h - radius)
    for i = 0, radius do
        local t = i / radius
        local offset = math.floor(radius * (1 - math.cos(t * math.pi / 2)))
        draw.FilledRect(x + offset, y + i, x + w - offset, y + i + 1)
        draw.FilledRect(x + offset, y + h - i - 1, x + w - offset, y + h - i)
    end
end

-- Handle panel toggling
local function handleInput()
    local success, err = pcall(function()
        -- Toggle primary panel with INSERT
        if input.IsButtonPressed(options.TogglePrimaryKey) then
            showPrimary = not showPrimary
            print("Primary Panel: " .. (showPrimary and "ON" or "OFF"))
            saveUIPositions() -- Save positions when toggling
        end

        -- Toggle secondary panel with DELETE
        if input.IsButtonPressed(options.ToggleSecondaryKey) then
            showSecondary = not showSecondary
            print("Secondary Panel: " .. (showSecondary and "ON" or "OFF"))
            saveUIPositions() -- Save positions when toggling
        end
    end)

    if not success then
        print("Input Handling Error: " .. tostring(err))
    end
end

-- Primary function (greetings and FPS)
local function primary()
    if not showPrimary or not font or not draw or not draw.GetScreenSize then
        return
    end

    local success, err = pcall(function()
        w, h = draw.GetScreenSize()
        if w == 0 or h == 0 then
            return
        end

        draw.SetFont(font)

        -- Calculate FPS every 30 frames (~0.5s at 60 FPS)
        if globals.FrameCount() % 30 == 0 then
            local frameTime = globals.FrameTime()
            current_fps = frameTime > 0 and math.floor(1 / frameTime) or 0
        end

        -- Prepare text
        local texts = {
            { text = "cathook by devxeno", x = options.PrimaryPos.X, y = options.PrimaryPos.Y },
        }

        -- Calculate box dimensions
        local maxW = 0
        local boxH = #texts * (options.FontSize + options.LineSpacing) + options.Padding * 2
        for _, item in ipairs(texts) do
            local tw, _ = draw.GetTextSize(item.text)
            maxW = math.max(maxW, tw)
        end
        local boxW = maxW + options.Padding * 2

        -- Draw shadow
        local shadow_r, shadow_g, shadow_b, shadow_a = getColor(options.Colors.Shadow)
        drawRoundedRect(
            options.PrimaryPos.X + options.ShadowOffset, options.PrimaryPos.Y + options.ShadowOffset,
            boxW, boxH, options.CornerRadius,
            shadow_r, shadow_g, shadow_b, shadow_a
        )

        -- Draw background
        local bg_r, bg_g, bg_b, bg_a = getColor(options.Colors.Background)
        drawRoundedRect(options.PrimaryPos.X, options.PrimaryPos.Y, boxW, boxH, options.CornerRadius, bg_r, bg_g, bg_b, bg_a)

        -- Draw border
        local border_r, border_g, border_b, border_a = getColor(options.Colors.Border)
        draw.Color(border_r, border_g, border_b, border_a)
        draw.OutlinedRect(options.PrimaryPos.X, options.PrimaryPos.Y, options.PrimaryPos.X + boxW, options.PrimaryPos.Y + boxH)

        -- Draw text
        local highlight_r, highlight_g, highlight_b, highlight_a = getColor(options.Colors.Highlight)
        draw.Color(highlight_r, highlight_g, highlight_b, highlight_a)
        for _, item in ipairs(texts) do
            draw.Text(item.x + options.Padding, item.y + options.Padding, item.text)
        end
    end)

    if not success then
        print("Primary Watermark Error: " .. tostring(err))
    end
end

-- Secondary function (status display for all Lmaobox settings)
local function secondary()
    if not showSecondary or not font or not draw or not draw.GetScreenSize then
        return
    end

    local success, err = pcall(function()
        w, h = draw.GetScreenSize()
        if w == 0 or h == 0 then
            return
        end

        draw.SetFont(font)

        -- Retrieve settings safely
        local settings = {}
        local keys = {
            { key = "aim bot", name = "AimBot", type = "bool" },
            { key = "aim method", name = "AimMethod", type = "value" },
            { key = "aim fov", name = "AimFov", type = "value" },
            { key = "double tap (beta)", name = "DoubleTap", type = "bool" },
            { key = "dash move key", name = "DashMoveKey", type = "value" },
            { key = "anti aim", name = "AntiAim", type = "bool" },
            { key = "colored players", name = "Chams", type = "bool" },
            { key = "players", name = "ESP", type = "bool" },
            { key = "fake latency", name = "FakePing", type = "bool" },
            { key = "fake latency value (ms)", name = "FakePingValue", type = "value" },
            { key = "trigger shoot", name = "Triggerbot", type = "bool" },
            { key = "trigger shoot delay (ms)", name = "TriggerDelay", type = "value" },
            { key = "bunny hop", name = "BunnyHop", type = "bool" },
            { key = "anti-obs", name = "AntiOBS", type = "bool" },
            { key = "no hands", name = "NoHands", type = "bool" },
            { key = "no scope", name = "NoScope", type = "bool" },
            { key = "enable custom fov", name = "CustomFOV", type = "bool" },
            { key = "custom fov value", name = "FOVValue", type = "value" },
            { key = "thirdperson", name = "ThirdPerson", type = "bool" },
            { key = "auto backstab", name = "AutoBackstab", type = "bool" },
            { key = "auto heal", name = "AutoHeal", type = "bool" },
            { key = "auto reflect", name = "AutoReflect", type = "bool" },
            { key = "rage", name = "RageMode", type = "bool" },
            { key = "legit", name = "LegitMode", type = "bool" },
            { key = "auto strafe", name = "AutoStrafe", type = "bool" },
            { key = "auto rocket jump", name = "AutoRocketJump", type = "bool" },
            { key = "resolver", name = "Resolver", type = "bool" },
            { key = "backtrack", name = "Backtrack", type = "bool" },
            { key = "silent aim", name = "SilentAim", type = "bool" },
            { key = "no recoil", name = "NoRecoil", type = "bool" },
            { key = "no spread", name = "NoSpread", type = "bool" },
            { key = "auto detonate", name = "AutoDetonate", type = "bool" },
            { key = "crit hack", name = "CritHack", type = "bool" },
            { key = "charge aim", name = "ChargeAim", type = "bool" },
            { key = "auto disguise", name = "AutoDisguise", type = "bool" },
            { key = "auto sap", name = "AutoSap", type = "bool" }
        }

        for _, item in ipairs(keys) do
            local success, value = pcall(function()
                return gui.GetValue(item.key)
            end)
            settings[item.name] = success and value or (item.type == "bool" and 0 or 0)
        end

        -- Prepare text items (two columns)
        local texts = {
            -- Left column
            { text = "AimBot: " .. (settings.AimBot == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y },
            { text = settings.AimBot == 1 and "AimMethod: " .. tostring(settings.AimMethod) or "", x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 20 },
            { text = settings.AimBot == 1 and "AimFov: " .. tostring(settings.AimFov) or "", x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 40 },
            { text = "ESP: " .. (settings.ESP == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 60 },
            { text = "Triggerbot: " .. (settings.Triggerbot == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 80 },
            { text = "TriggerDel: " .. tostring(settings.TriggerDelay) .. "ms", x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 100 },
            { text = settings.SilentAim == 1 and "SilentAim: " .. (settings.SilentAim == 1 and "ON" or "OFF") or "", x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 120 },
            { text = settings.AntiAim == 1 and "AntiAim: WARNING: ON" or "AntiAim: OFF", x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 140, rgb = settings.AntiAim == 1 },
            { text = "DoubleTap: " .. (settings.DoubleTap == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 160 },
            { text = settings.DoubleTap == 1 and "DashKey: " .. tostring(settings.DashMoveKey) or "", x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 180 },
            { text = "Chams: " .. (settings.Chams == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 200 },
            { text = "AutoBackstab: " .. (settings.AutoBackstab == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 220 },
            { text = "AutoHeal: " .. (settings.AutoHeal == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 240 },
            { text = "AutoStrafe: " .. (settings.AutoStrafe == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 260 },
            { text = "NoRecoil: " .. (settings.NoRecoil == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 280 },
            { text = "AutoDetonate: " .. (settings.AutoDetonate == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 300 },
            { text = "CritHack: " .. (settings.CritHack == 1 and "ON" or "OFF"), x = options.SecondaryPos.X, y = options.SecondaryPos.Y + 320 },

            -- Right column
            { text = "BunnyHop: " .. (settings.BunnyHop == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y },
            { text = "ThirdPerson: " .. (settings.ThirdPerson == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 20 },
            { text = "Anti-OBS: " .. (settings.AntiOBS == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 40 },
            { text = "NoScope: " .. (settings.NoScope == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 60 },
            { text = "NoHands: " .. (settings.NoHands == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 80 },
            { text = "FOVChanger: " .. (settings.CustomFOV == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 100 },
            { text = settings.CustomFOV == 1 and "ViewFOV: " .. tostring(settings.FOVValue) or "", x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 120 },
            { text = "FakePing: " .. (settings.FakePing == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 140 },
            { text = settings.FakePing == 1 and "FakePingAmount: " .. tostring(settings.FakePingValue) .. "ms" or "", x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 160 },
            { text = "AutoReflect: " .. (settings.AutoReflect == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 180 },
            { text = "RageMode: " .. (settings.RageMode == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 200 },
            { text = "LegitMode: " .. (settings.LegitMode == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 220 },
            { text = "AutoRocketJump: " .. (settings.AutoRocketJump == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 240 },
            { text = "Resolver: " .. (settings.Resolver == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 260 },
            { text = "Backtrack: " .. (settings.Backtrack == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 280 },
            { text = "NoSpread: " .. (settings.NoSpread == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 300 },
            { text = "ChargeAim: " .. (settings.ChargeAim == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 320 },
            { text = "AutoDisguise: " .. (settings.AutoDisguise == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 340 },
            { text = "AutoSap: " .. (settings.AutoSap == 1 and "ON" or "OFF"), x = options.SecondaryPos.X + options.ColumnSpacing, y = options.SecondaryPos.Y + 360 }
        }

        -- Calculate box dimensions
        local leftMaxW, rightMaxW = 0, 0
        local validTexts = {}
        local leftLines, rightLines = 0, 0
        for _, item in ipairs(texts) do
            if item.text ~= "" then
                local tw, th = draw.GetTextSize(item.text)
                if item.x == options.SecondaryPos.X then
                    leftMaxW = math.max(leftMaxW, tw)
                    leftLines = leftLines + 1
                else
                    rightMaxW = math.max(rightMaxW, tw)
                    rightLines = rightLines + 1
                end
                table.insert(validTexts, item)
            end
        end

        -- Skip drawing if no valid texts
        if leftLines == 0 and rightLines == 0 then
            return
        end

        -- Calculate box dimensions
        local boxW = leftMaxW + rightMaxW + options.ColumnSpacing + options.Padding * 3
        local boxH = math.max(leftLines, rightLines) * (options.FontSize + options.LineSpacing) + options.Padding * 2

        -- Ensure box dimensions are valid
        if boxW <= 0 or boxH <= 0 then
            return
        end

        -- Draw shadow
        local shadow_r, shadow_g, shadow_b, shadow_a = getColor(options.Colors.Shadow)
        drawRoundedRect(
            options.SecondaryPos.X + options.ShadowOffset, options.SecondaryPos.Y + options.ShadowOffset,
            boxW, boxH, options.CornerRadius,
            shadow_r, shadow_g, shadow_b, shadow_a
        )

        -- Draw background
        local bg_r, bg_g, bg_b, bg_a = getColor(options.Colors.Background)
        drawRoundedRect(options.SecondaryPos.X, options.SecondaryPos.Y, boxW, boxH, options.CornerRadius, bg_r, bg_g, bg_b, bg_a)

        -- Draw border
        local border_r, border_g, border_b, border_a = getColor(options.Colors.Border)
        draw.Color(border_r, border_g, border_b, border_a)
        draw.OutlinedRect(options.SecondaryPos.X, options.SecondaryPos.Y, options.SecondaryPos.X + boxW, options.SecondaryPos.Y + boxH)

        -- Draw text
        local text_r, text_g, text_b, text_a = getColor(options.Colors.Text)
        local warning_r, warning_g, warning_b, warning_a = getColor(options.Colors.Warning)
        local r, g, b = RGBRainbow(options.RainbowSpeed)
        draw.SetFont(font)
        local leftY = options.SecondaryPos.Y + options.Padding
        local rightY = options.SecondaryPos.Y + options.Padding
        for _, item in ipairs(validTexts) do
            local currentY = item.x == options.SecondaryPos.X and leftY or rightY
            if item.rgb then
                draw.Color(r, g, b, 255)
            elseif item.text:find("WARNING") then
                draw.Color(warning_r, warning_g, warning_b, warning_a)
            else
                draw.Color(text_r, text_g, text_b, text_a)
            end
            draw.Text(item.x + options.Padding, currentY, item.text)
            if item.x == options.SecondaryPos.X then
                leftY = leftY + options.FontSize + options.LineSpacing
            else
                rightY = rightY + options.FontSize + options.LineSpacing
            end
        end
    end)

    if not success then
        print("Secondary Watermark Error: " .. tostring(err))
    end
end

-- Register callbacks with error handling
local success, err = pcall(function()
    if callbacks then
        callbacks.Unregister("Draw", "primary_watermark")
        callbacks.Unregister("Draw", "secondary_watermark")
        callbacks.Unregister("Draw", "input_handler")
        callbacks.Register("Draw", "primary_watermark", primary)
        callbacks.Register("Draw", "secondary_watermark", secondary)
        callbacks.Register("Draw", "input_handler", handleInput)
    end
end)

-- Show initialization status
if not isScriptLoaded and success then
    print("Watermark and Status callbacks registered successfully.")
    _G.WatermarkStatusLoaded = true
end

if not success then
    print("Watermark Initialization Error: " .. tostring(err))
end