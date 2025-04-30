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
local w, h = 0, 0
local last_update = 0
local last_text = ""
local cached_tw, cached_th = 0, 0 -- Cache text size
local last_screen_check = 0
local WatermarkState = { Loaded = false, Error = "", ErrorTime = 0 }
local callback_name = "watermark_" .. tostring(math.random(1000, 9999))

-- Font creation with fallback
local function initializeFont()
    local success, result = pcall(function()
        return draw.CreateFont(options.FontName, options.FontSize, options.FontWeight) or
               draw.CreateFont("Arial", options.FontSize, options.FontWeight) or
               draw.CreateFont("Default", options.FontSize, 400)
    end)
    if success and result then
        return result
    else
        WatermarkState.Error = "Failed to create font"
        WatermarkState.ErrorTime = globals.RealTime() + 5
        print("Watermark Error: Failed to create font.")
        return nil
    end
end

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

-- Draw rounded rectangle (optimized)
local function drawRoundedRect(x, y, w, h, radius, r, g, b, a)
    draw.Color(r, g, b, a)
    draw.FilledRect(x + radius, y, x + w - radius, y + h)
    draw.FilledRect(x, y + radius, x + w, y + h - radius)
    for i = 0, radius, 4 do -- Further reduced iterations
        local t = i / radius
        local offset = math.floor(radius * (1 - math.cos(t * math.pi / 2)))
        draw.FilledRect(x + offset, y + i, x + w - offset, y + i + 4)
        draw.FilledRect(x + offset, y + h - i - 4, x + w - offset, y + h - i)
    end
end

-- Watermark drawing function
local function watermark()
    if not draw or not globals or not draw.GetScreenSize then
        WatermarkState.Error = "Required APIs not available"
        WatermarkState.ErrorTime = globals.RealTime() + 5
        print("Watermark Error: Required APIs not available")
        return
    end

    local success, err = pcall(function()
        -- Check screen size every 2 seconds
        local curtime = globals.RealTime() or 0
        if curtime - last_screen_check >= 2 then
            w, h = draw.GetScreenSize()
            last_screen_check = curtime
            if w == 0 or h == 0 then
                WatermarkState.Error = "Invalid screen size"
                WatermarkState.ErrorTime = curtime + 5
                print("Watermark Warning: Invalid screen size detected")
                return
            end
        end

        -- Set font once
        if not lato then
            WatermarkState.Error = "Font not loaded"
            WatermarkState.ErrorTime = curtime + 5
            draw.Color(255, 0, 0, 255)
            draw.Text(10, 50, "Watermark Error: Font not loaded")
            return
        end
        draw.SetFont(lato)

        -- Update FPS and tick rate every 0.5 seconds
        if curtime - last_update >= 0.5 then
            local frameTime = globals.FrameTime() or 0
            current_fps = frameTime > 0 and math.floor(1 / frameTime) or 0
            local tickInterval = globals.TickInterval() or 0
            server_tick = tickInterval > 0 and math.floor(1 / tickInterval) or 0
            last_update = curtime
        end

        -- Prepare text and cache size
        local text = "[ lmaobox | fps: " .. current_fps .. " | ticks: " .. server_tick .. " ]"
        if text ~= last_text then
            cached_tw, cached_th = draw.GetTextSize(text)
            last_text = text
        end
        local boxW = cached_tw + options.Padding * 2
        local boxH = cached_th + options.Padding * 2
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
        draw.OutlinedRect(x, y, x + boxW, y + boxH)

        -- Draw text with rainbow effect
        local r, g, b = RGBRainbow(options.RainbowSpeed)
        draw.Color(r, g, b, 255)
        draw.Text(x + options.Padding, y + options.Padding, text)

        -- Show error message for 5 seconds
        if WatermarkState.Error ~= "" and curtime < WatermarkState.ErrorTime then
            draw.Color(255, 0, 0, 255)
            draw.Text(10, 50, "Watermark Error: " .. WatermarkState.Error)
        elseif curtime >= WatermarkState.ErrorTime then
            WatermarkState.Error = ""
        end
    end)

    if not success then
        WatermarkState.Error = tostring(err)
        WatermarkState.ErrorTime = globals.RealTime() + 5
        print("Watermark Error: " .. tostring(err))
    end
end

-- Initialize font
lato = initializeFont()

-- Register callback with error handling
local success, err = pcall(function()
    if callbacks then
        callbacks.Unregister("Draw", callback_name)
        callbacks.Register("Draw", callback_name, watermark)
    else
        WatermarkState.Error = "Callbacks API not available"
        WatermarkState.ErrorTime = globals.RealTime() + 5
        print("Watermark Error: Callbacks API not available")
    end
end)

-- Show initialization status
if not WatermarkState.Loaded and success then
    print("Watermark callback registered successfully.")
    WatermarkState.Loaded = true
end

if not success then
    WatermarkState.Error = tostring(err)
    WatermarkState.ErrorTime = globals.RealTime() + 5
    print("Watermark Initialization Error: " .. tostring(err))
end
