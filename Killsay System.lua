
local killsay_messages = {
    "ez clap, %s",
    "outplayed, %s",
    "better luck next time, %s",
    "uninstall, %s",
    "you call that aim, %s?",
    "%s just got clowned",
    "missed that shot, huh %s?",
    "BOOM, headshot on %s!",
    "too easy for me, %s",
    "wake up, %s!"
}


local function get_random_killsay(name)
    local msg = killsay_messages[math.random(#killsay_messages)]
    return string.format(msg, name)
end


callbacks.Register("FireGameEvent", function(event)
    if event:GetName() ~= "player_death" then return end

    local localPlayer = entities.GetLocalPlayer()
    if not localPlayer then return end

    local attacker = entities.GetByUserID(event:GetInt("attacker"))
    local victim = entities.GetByUserID(event:GetInt("userid"))

    if attacker == nil or victim == nil then return end

    if attacker:GetIndex() == localPlayer:GetIndex() and victim:GetIndex() ~= localPlayer:GetIndex() then
        local victim_name = client.GetPlayerNameByUserID(event:GetInt("userid"))
        client.ChatSay(get_random_killsay(victim_name))
    end
end)
