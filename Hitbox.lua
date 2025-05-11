--[[
    Enhanced Hitbox Visualization Script
    By Devxeno, 
]]

-- Configuration
local CONFIG = {
    enabled = true,                      -- Master toggle for the script
    toggle_key = "h",                    -- Key to toggle the script (e.g., "h")
    display_duration = 2,                -- Duration to display hitboxes (seconds)
    default_color = {255, 255, 255},     -- Default hitbox color (R, G, B)
    projectile_color = {255, 100, 100},  -- Color for projectile weapons
    alpha_multiplier = 1.0,              -- Alpha fade multiplier (1.0 = full fade)
    draw_only_head = false,              -- Only draw head hitbox (false = all hitboxes)
}

-- Weapon lookup table (optimized for performance)
local WEAPON_PROJECTILES = {
    [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true,
    [9]=true, [10]=true, [11]=true, [20]=true, [22]=true, [23]=true, [24]=true,
    [25]=true, [58]=true, [61]=true, [65]=true, [72]=true, [73]=true, [78]=true,
    [80]=true, [81]=true, [91]=true
}

-- State variables
local hitbox_data = nil
local hitbox_time = 0
local is_projectile = false
local local_player = nil
local is_enabled = CONFIG.enabled

-- Toggle functionality
local function toggle_hitbox()
    is_enabled = not is_enabled
    print("Hitbox Visualization: " .. (is_enabled and "Enabled" or "Disabled"))
end

-- Bind toggle key
input.RegisterKey(CONFIG.toggle_key, toggle_hitbox)

-- Handle player_hurt event
local function on_player_hurt(event)
    if event:GetName() ~= "player_hurt" or not is_enabled then return end

    -- Cache local player
    if not local_player then
        local_player = entities.GetLocalPlayer()
    end
    if not local_player then return end

    local victim = entities.GetByUserID(event:GetInt("userid"))
    local attacker = entities.GetByUserID(event:GetInt("attacker"))
    local weaponid = event:GetInt("weaponid")

    -- Validate event
    if not attacker or attacker:GetIndex() ~= local_player:GetIndex() or victim:GetIndex() == local_player:GetIndex() then
        return
    end

    -- Determine hitbox type
    is_projectile = WEAPON_PROJECTILES[weaponid] or false
    hitbox_data = is_projectile and victim:HitboxSurroundingBox() or victim:GetHitboxes()
    hitbox_time = globals.RealTime()
end

callbacks.Register("FireGameEvent", "on_player_hurt", on_player_hurt)

-- Draw hitboxes
local function draw_hitboxes()
    if not is_enabled or engine.Con_IsVisible() or engine.IsGameUIVisible() then return end
    if not hitbox_data then return end

    local elapsed = globals.RealTime() - hitbox_time
    if elapsed > CONFIG.display_duration then
        hitbox_data = nil
        return
    end

    -- Calculate alpha for fading effect
    local alpha = math.floor(255 * (1 - (elapsed / CONFIG.display_duration)) * CONFIG.alpha_multiplier)
    if alpha < 1 or alpha > 255 then return end

    -- Set color based on weapon type
    local color = is_projectile and CONFIG.projectile_color or CONFIG.default_color
    draw.Color(color[1], color[2], color[3], alpha)

    -- Handle hitbox rendering
    local hitboxes = is_projectile and {hitbox_data} or hitbox_data
    for i, hitbox in ipairs(hitboxes) do
        if not hitbox then goto continue end

        local min, max = hitbox[1], hitbox[2]
        if not (min and max) then goto continue end

        -- Optional: Skip non-head hitboxes if configured
        if CONFIG.draw_only_head and i ~= 1 then goto continue end -- Assuming hitbox 1 is head

        -- Convert 3D coordinates to 2D screen coordinates
        local points = {
            client.WorldToScreen(Vector3(min.x, min.y, min.z)), -- min
            client.WorldToScreen(Vector3(max.x, min.y, min.z)),
            client.WorldToScreen(Vector3(max.x, max.y, min.z)),
            client.WorldToScreen(Vector3(min.x, max.y, min.z)),
            client.WorldToScreen(Vector3(min.x, min.y, max.z)),
            client.WorldToScreen(Vector3(max.x, min.y, max.z)),
            client.WorldToScreen(Vector3(max.x, max.y, max.z)), -- max
            client.WorldToScreen(Vector3(min.x, max.y, max.z)),
        }

        -- Check if all points are valid
        local valid = true
        for _, point in ipairs(points) do
            if not point then
                valid = false
                break
            end
        end
        if not valid then goto continue end

        -- Draw hitbox lines (12 edges of a cube)
        local edges = {
            {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- Bottom face
            {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- Top face
            {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- Connecting edges
        }

        for _, edge in ipairs(edges) do
            local p1, p2 = points[edge[1]], points[edge[2]]
            draw.Line(p1[1], p1[2], p2[1], p2[2])
        end

        ::continue::
    end
end

callbacks.Register("Draw", "draw_hitboxes", draw_hitboxes)
