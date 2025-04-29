--[[
    Enhanced by Devxeno
]]

local time = 0
local sec = 2 -- duration to display boxes

-- Weapon list changed to a lookup table for performance
local bwplist = {
    [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true,
    [9]=true, [10]=true, [11]=true, [20]=true, [22]=true, [23]=true, [24]=true, 
    [25]=true, [58]=true, [61]=true, [65]=true, [72]=true, [73]=true, [78]=true,
    [80]=true, [81]=true, [91]=true
}

local hitboxv = nil
local pbox = 0

local function damage(event)
    if event:GetName() ~= 'player_hurt' then return end

    local localPlayer = entities.GetLocalPlayer()
    if localPlayer == nil then return end

    local victim = entities.GetByUserID(event:GetInt("userid"))
    local attacker = entities.GetByUserID(event:GetInt("attacker"))
    local weaponid = event:GetInt("weaponid")

    if not attacker or attacker:GetIndex() ~= localPlayer:GetIndex() or victim:GetIndex() == localPlayer:GetIndex() then
        return
    end

    if bwplist[weaponid] then
        pbox = 1
        hitboxv = victim:HitboxSurroundingBox()
    else
        pbox = 0
        hitboxv = victim:GetHitboxes()
    end

    time = globals.RealTime()
end

callbacks.Register("FireGameEvent", "damageDraw", damage)

local function HitboxDraw()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() then return end
    if not hitboxv then return end

    local currentTime = globals.RealTime()
    local elapsed = currentTime - time
    if elapsed > sec then return end

    local remaining = math.max(0, sec - elapsed)
    local alpha = math.floor(255 * (remaining / sec))

    if alpha < 1 or alpha > 255 then return end

    draw.Color(255, 255, 255, alpha)  

    for i = 1, #hitboxv do
        local min, max

        if pbox == 1 then
            min = hitboxv[1]
            max = hitboxv[2]
        else
            local hitbox = hitboxv[i]
            if hitbox then
                min = hitbox[1]
                max = hitbox[2]
            end
        end

        if not (min and max) then goto continue end

        local xa, ya, za = min:Unpack()
        local xb, yb, zb = max:Unpack()

        local mool = client.WorldToScreen(Vector3(xb, ya, za))
        local moal = client.WorldToScreen(Vector3(xb, yb, za))
        local moul = client.WorldToScreen(Vector3(xa, yb, za))
        local moql = client.WorldToScreen(Vector3(xb, ya, zb))
        local morl = client.WorldToScreen(Vector3(xa, yb, zb))
        local mozl = client.WorldToScreen(Vector3(xa, ya, zb))
        local min2D = client.WorldToScreen(min)
        local max2D = client.WorldToScreen(max)

        
        if mool and moal and moul and moql and morl and mozl and min2D and max2D then
            draw.Color(255, 255, 255, alpha)

            draw.Line(mozl[1], mozl[2], morl[1], morl[2])
            draw.Line(mozl[1], mozl[2], moql[1], moql[2])
            draw.Line(morl[1], morl[2], max2D[1], max2D[2])
            draw.Line(moql[1], moql[2], max2D[1], max2D[2])

            draw.Line(min2D[1], min2D[2], mool[1], mool[2])
            draw.Line(min2D[1], min2D[2], moul[1], moul[2])
            draw.Line(mool[1], mool[2], moal[1], moal[2])
            draw.Line(moul[1], moul[2], moal[1], moal[2])

            draw.Line(min2D[1], min2D[2], mozl[1], mozl[2])
            draw.Line(moal[1], moal[2], max2D[1], max2D[2])
            draw.Line(moul[1], moul[2], morl[1], morl[2])
            draw.Line(mool[1], mool[2], moql[1], moql[2])
        end

        ::continue::
    end
end

callbacks.Register("Draw", HitboxDraw)