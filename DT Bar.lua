--[[ 
    Doubletap Bar for Lmaobox - Modern UI Style
    Author: LNX (original), Modified by Devxeno.lua
    Reworked by Devxeno
]]

-- Print a message to the console with credit
print("Doubletap Bar for Lmaobox - Modern UI Style")
print("Author: LNX (original), Modified by Devxeno.lua")

local options = {
    X = 0.5, Y = 0.65, Size = 6,
    ShowText = true, ShowTimer = true,
    TextSize = 14, FontName = "Verdana", FontWeight = 600,
    CornerRadius = 8, OutlineThickness = 1, TextOffset = 8, ShadowOffset = 3,
    Colors = {
        BG = { 30, 30, 40, 180 },
        Recharge = { { 90, 200, 255, 255 }, { 50, 140, 220, 255 } },
        Ready = { { 80, 255, 160, 255 }, { 40, 200, 100, 255 } },
        Unavail = { 255, 100, 90, 255 },
        Outline = { 0, 0, 0, 180 },
        Text = { 255, 255, 255, 255 },
        Shadow = { 0, 0, 0, 100 },
        Timer = { 200, 200, 200, 255 }
    },
    OptimizePerformance = true -- Option to reduce heavy effects
}

local MAX_TICKS = 23
local w, h, font = 0, 0, nil
local lastW, lastH = 0, 0
local isScriptLoaded = _G.DoubletapBarLoaded or false

-- Safely unpack color values
local function unpackColor(colorTable)
    if type(colorTable) == "table" and #colorTable == 4 then
        for i = 1, 4 do
            colorTable[i] = math.floor(tonumber(colorTable[i]) or 0)
            colorTable[i] = math.max(0, math.min(255, colorTable[i]))
        end
        return colorTable[1], colorTable[2], colorTable[3], colorTable[4]
    end
    return 255, 255, 255, 255
end

-- Check if Double Tap is enabled
local function isDTEnabled()
    local success, result = pcall(function()
        return gui and gui.GetValue and (gui.GetValue("double tap (beta)") ~= "off" or gui.GetValue("dash move key") ~= 0)
    end)
    return success and result or false
end

-- Get status text
local function getStatus(ticks, warping, canDT)
    if warping or ticks < MAX_TICKS then return "Recharging"
    elseif canDT then return "Ready"
    else return "Not Supported" end
end

-- Get timer text
local function getTimerText(ticks)
    local remaining = (MAX_TICKS - ticks) * 0.066
    return string.format("%.1fs", math.max(0, remaining))
end

-- Simplified gradient drawing for performance
local function drawVerticalGradient(x, y1, y2, width, color1, color2)
    if options.OptimizePerformance then
        -- Use single color for performance
        local r, g, b, a = unpackColor(color1)
        draw.Color(r, g, b, a)
        draw.FilledRect(x, y1, x + width, y2)
    else
        local steps = math.max(1, math.floor((y2 - y1) / 4)) -- Reduced steps
        for i = 0, steps do
            local t = i / steps
            local r = color1[1] + (color2[1] - color1[1]) * t
            local g = color1[2] + (color2[2] - color1[2]) * t
            local b = color1[3] + (color2[3] - color1[3]) * t
            local a = color1[4] + (color2[4] - color1[4]) * t
            draw.Color(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
            draw.FilledRect(x, y1 + i * 4, x + width, y1 + (i + 1) * 4)
        end
    end
end

-- Main draw function with error handling
local function drawBar()
    -- Initial checks with error handling
    local success, err = pcall(function()
        if not (warp and warp.GetChargedTicks and warp.IsWarping and warp.CanDoubleTap and draw and isDTEnabled()) then
            return
        end

        local player = entities.GetLocalPlayer()
        if not player or engine.IsGameUIVisible() then
            return
        end

        local weapon = player:GetPropEntity("m_hActiveWeapon")
        if not weapon then
            return
        end

        -- Update screen size safely
        if draw.GetScreenSize then
            w, h = draw.GetScreenSize()
            if w == 0 or h == 0 then
                return -- Prevent invalid screen size
            end
            if w ~= lastW or h ~= lastH then
                lastW, lastH = w, h
            end
        else
            return
        end

        -- Get Double Tap status
        local ticks = warp.GetChargedTicks() or 0
        local ratio = math.min(ticks / MAX_TICKS, 1)
        local barW = 26 * options.Size
        local barH = math.floor(5 * options.Size)
        local fillW = math.floor(barW * ratio)
        local x = math.floor(w * options.X - barW * 0.5)
        local y = math.floor(h * options.Y - barH * 0.5)

        -- Shadow
        local shadowColor = { unpackColor(options.Colors.Shadow) }
        draw.Color(shadowColor[1], shadowColor[2], shadowColor[3], shadowColor[4])
        draw.FilledRect(x + options.ShadowOffset, y + options.ShadowOffset, x + barW + options.ShadowOffset, y + barH + options.ShadowOffset)

        -- Background
        local bgColor = { unpackColor(options.Colors.BG) }
        draw.Color(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        draw.FilledRect(x, y, x + barW, y + barH)

        -- Bar filling logic
        local isWarping = warp.IsWarping()
        local canDT = warp.CanDoubleTap(weapon)
        if isWarping or ticks < MAX_TICKS then
            drawVerticalGradient(x, y, y + barH, fillW, options.Colors.Recharge[1], options.Colors.Recharge[2])
        elseif canDT then
            drawVerticalGradient(x, y, y + barH, fillW, options.Colors.Ready[1], options.Colors.Ready[2])
        else
            local unavailColor = { unpackColor(options.Colors.Unavail) }
            draw.Color(unavailColor[1], unavailColor[2], unavailColor[3], unavailColor[4])
            draw.FilledRect(x, y, x + fillW, y + barH)
        end

        -- Outline (reduced thickness for performance)
        if not options.OptimizePerformance then
            local outlineColor = { unpackColor(options.Colors.Outline) }
            draw.Color(outlineColor[1], outlineColor[2], outlineColor[3], outlineColor[4])
            for i = 1, math.min(options.OutlineThickness, 2) do
                draw.OutlinedRect(x - i + 1, y - i + 1, x + barW + i - 1, y + barH + i - 1)
            end
        end

        -- Text
        if (options.ShowText or options.ShowTimer) and draw.CreateFont then
            if not font then
                font = draw.CreateFont(options.FontName, options.TextSize, options.FontWeight, 1) or draw.CreateFont("Arial", options.TextSize, options.FontWeight, 1)
                if not font then
                    return -- Prevent text rendering if font creation fails
                end
            end

            draw.SetFont(font)
            local text = options.ShowText and getStatus(ticks, isWarping, canDT) or ""
            local timer = options.ShowTimer and getTimerText(ticks) or ""
            local displayText = text .. (text ~= "" and timer ~= "" and " " or "") .. timer
            local tw, th = draw.GetTextSize(displayText)
            local tx = math.floor(x + (barW - tw) * 0.5)
            local ty = y + barH + options.TextOffset

            local shadowTextColor = { unpackColor(options.Colors.Shadow) }
            draw.Color(shadowTextColor[1], shadowTextColor[2], shadowTextColor[3], shadowTextColor[4])
            draw.Text(tx + 1, ty + 1, displayText)

            -- Pulsing text effect for ready state
            if canDT and not options.OptimizePerformance then
                local pulse = math.sin(globals.RealTime() * 4) * 0.1 + 0.9
                local textColor = { unpackColor(options.Colors.Text) }
                draw.Color(
                    math.floor(textColor[1] * pulse),
                    math.floor(textColor[2] * pulse),
                    math.floor(textColor[3] * pulse),
                    textColor[4]
                )
            else
                local textColor = { unpackColor(options.Colors.Text) }
                draw.Color(textColor[1], textColor[2], textColor[3], textColor[4])
            end
            draw.Text(tx, ty, displayText)
        end
    end)

    -- Handle errors
    if not success then
        print("Doubletap Bar Error: " .. tostring(err))
    end
end

-- Initialize screen size and register callback
local success, err = pcall(function()
    if draw and draw.GetScreenSize then
        w, h = draw.GetScreenSize()
    end
    if callbacks then
        callbacks.Unregister("Draw", "lnx_DTBar")
        callbacks.Register("Draw", "lnx_DTBar", drawBar)
    end
end)

-- Show notification only on first load
if not isScriptLoaded and success then
    print("Doubletap Bar loaded successfully.")
    _G.DoubletapBarLoaded = true
end

-- Handle initialization errors
if not success then
    print("Doubletap Bar Initialization Error: " .. tostring(err))
end
