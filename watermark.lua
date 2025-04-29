--[[
    Watermark for Lmaobox with Cathook-style UI
    Enhanced by Devxeno.lua
]]

-- Print initialization message
print("Cathook-style Watermark for Lmaobox loaded successfully")

-- Configuration
local options = {
    X = 10, Y = 10, -- Position (top-left corner)
    Padding = 8, -- Padding inside the box
    CornerRadius = 4, -- Rounded corner radius
    ShadowOffset = 2, -- Shadow offset
    FontName = "Verdana", -- Modern font
    FontSize = 16,
    FontWeight = 600,
    Colors = {
        Background = { 30, 30, 30, 200 }, -- Semi-transparent dark background
        Shadow = { 0, 0, 0, 100 }, -- Subtle shadow
        Text = { 255, 255, 255, 255 }, -- White text
        Border = { 60, 60, 60, 255 }, -- Subtle border
    },
    RainbowSpeed = 1, -- Speed of RGB rainbow effect
}

-- Variables
local lato = nil
local current_fps = 0
local server_tick = 0
local isScriptLoaded = _G.WatermarkLoaded or false
local w, h = 0, 0

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

-- Initialize font
lato = initializeFont()

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
    return 255, 255, 255, 255 -- Fallback color
end

-- Draw rounded rectangle (approximation for Cathook style)
local function drawRoundedRect(x, y, w, h, radius, r, g, b, a)
    draw.Color(r, g, b, a)
    draw.FilledRect(x + radius, y, x + w - radius, y + h) -- Main body
    draw.FilledRect(x, y + radius, x + w, y + h - radius) -- Sides
    for i = 0, radius do
        local t = i / radius
        local offset = math.floor(radius * (1 - math.cos(t * math.pi / 2)))
        draw.FilledRect(x + offset, y + i, x + w - offset, y + i + 1)
        draw.FilledRect(x + offset, y + h - i - 1, x + w - offset, y + h - i)
    end
end

-- Watermark drawing function
local function watermark()
    if not lato or not draw or not draw.GetScreenSize then
        return
    end

    local success, err = pcall(function()
        -- Update screen size
        w, h = draw.GetScreenSize()
        if w == 0 or h == 0 then
            return
        end

        -- Set font
        draw.SetFont(lato)

        -- Update FPS and tick rate every 30 frames (~0.5s at 60 FPS)
        if globals.FrameCount() % 30 == 0 then
            local frameTime = globals.FrameTime()
            current_fps = frameTime > 0 and math.floor(1 / frameTime) or 0

            local tickInterval = globals.TickInterval()
            server_tick = tickInterval > 0 and math.floor(1 / tickInterval) or 0
        end

        -- Prepare text
        local text = "[ lmaobox | fps: " .. current_fps .. " | ticks: " .. server_tick .. " ]"
        local tw, th = draw.GetTextSize(text)
        local boxW = tw + options.Padding * 2
        local boxH = th + options.Padding * 2
        local x = options.X
        local y = options.Y

        -- Draw shadow
        local shadow_r, shadow_g, shadow_b, shadow_a = getColor(options.Colors.Shadow)
        drawRoundedRect(
            x + options.ShadowOffset, y + options.ShadowOffset,
            boxW, boxH, options.CornerRadius,
            shadow_r, shadow_g, shadow_b, shadow_a
        )

        -- Draw background
        local bg_r, bg_g, bg_b, bg_a = getColor(options.Colors.Background)
        drawRoundedRect(x, y, boxW, boxH, options.CornerRadius, bg_r, bg_g, bg_b, bg_a)

        -- Draw border
        local border_r, border_g, border_b, border_a = getColor(options.Colors.Border)
        draw.Color(border_r, border_g, border_b, border_a)
        for i = 1, 1 do
            draw.OutlinedRect(x - i + 1, y - i + 1, x + boxW + i - 1, y + boxH + i - 1)
        end

        -- Draw text with rainbow effect
        local r, g, b = RGBRainbow(options.RainbowSpeed)
        draw.Color(r, g, b, 255)
        draw.Text(x + options.Padding, y + options.Padding, text)
    end)

    if not success then
        print("Watermark Error: " .. tostring(err))
    end
end

-- Register callback with error handling
local success, err = pcall(function()
    if callbacks then
        callbacks.Unregister("Draw", "watermark")
        callbacks.Register("Draw", "watermark", watermark)
    end
end)

-- Show initialization status
if not isScriptLoaded and success then
    print("Watermark callback registered successfully.")
    _G.WatermarkLoaded = true
end

if not success then
    print("Watermark Initialization Error: " .. tostring(err))
end
