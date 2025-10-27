EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_ZoneChange", EVENT_PLAYER_ACTIVATED, function()
    zo_callLater(function()
        -- Only proceed if auto-swap is enabled
        if not CritTracker.savedVars.autoSwapPresets then
            return
        end

        local newZoneType = nil
        local presetToLoad = nil

        -- Home
        local zoneId = GetZoneId(GetCurrentMapZoneIndex())
        local homeId = CritTracker:CheckAndApplyHomePreset(zoneId)

        if homeId then
            newZoneType = "home"
            if CritTracker.savedVars.homePresets and CritTracker.savedVars.homePresets[homeId] then
                presetToLoad = CritTracker.savedVars.homePresets[homeId]
            end
            -- Dungeon
        elseif IsUnitInDungeon("player") then
            newZoneType = "dungeon"
            presetToLoad = 3
            -- Overland
        elseif not IsUnitInDungeon("player") and not CritTracker.savedVars.isHome then
            newZoneType = "overland"
            presetToLoad = 2
        end

        -- Only apply preset if zone type changed
        if newZoneType and newZoneType ~= CritTracker.currentZoneType then
            CritTracker.currentZoneType = newZoneType

            if presetToLoad then
                CritTracker:LoadFromPresetSlot(presetToLoad)
            end
        end
    end, 1000)
end)