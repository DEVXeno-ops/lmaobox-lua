--[[
    Auto Queue for Lmaobox
    Author: LNX (github.com/lnx00)
    Modified: Enhanced error handling, stability, and user experience
]]

-- Global variables
AutoQueue = true
local lastTime = 0
local casualQueue = party.GetAllMatchGroups()["Casual"]
local isScriptLoaded = _G.AutoQueueLoaded or false

-- Main AutoQueue function with error handling
local function Draw_AutoQueue()
    -- Check if script is disabled or in invalid state
    if not AutoQueue then
        return
    end

    -- Validate casualQueue
    if casualQueue == nil then
        engine.Notification("AutoQueue Error", "Casual match group not found! Disabling AutoQueue.")
        AutoQueue = false
        return
    end

    -- Prevent execution in match or connected states
    local success, err = pcall(function()
        if gamecoordinator.HasLiveMatch() or 
           gamecoordinator.IsConnectedToMatchServer() or 
           gamecoordinator.GetNumMatchInvites() > 0 then
            return
        end

        -- Enforce 6-second delay (increased from 4 for performance)
        if globals.RealTime() - lastTime < 6 then
            return
        end

        lastTime = globals.RealTime()

        -- Queue logic
        if #party.GetQueuedMatchGroups() == 0 and 
           not party.IsInStandbyQueue() and 
           party.CanQueueForMatchGroup(casualQueue) then
            local queueSuccess = party.QueueUp(casualQueue)
            if not queueSuccess then
                engine.Notification("AutoQueue Warning", "Failed to queue for Casual. Retrying in 6 seconds.")
            end
        end
    end)

    -- Handle errors
    if not success then
        engine.Notification("AutoQueue Error", "Error occurred: " .. tostring(err))
    end
end

-- Unregister and register Draw callback
callbacks.Unregister("Draw", "Draw_AutoQueue")
callbacks.Register("Draw", "Draw_AutoQueue", Draw_AutoQueue)

-- Show notification only on first load
if not isScriptLoaded then
    engine.Notification("AutoQueue Info", 
        "AutoQueue script loaded successfully.\n" ..
        "To stop: lua AutoQueue = false\n" ..
        "To re-enable: lua AutoQueue = true or reload the script.")
    client.Command('play "ui/buttonclick"', true)
    _G.AutoQueueLoaded = true
end