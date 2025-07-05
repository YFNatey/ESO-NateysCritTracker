local defaults = {
    fontSize = 18,
    labelPosX = 560,
    labelPosY = 20,
    showNotifications = false,
    simpleMode = true,
    showCritDmg = true,
    fontStyle = "bold"
    showCritDmg = true,
    fontStyle = "bold"
}

CritTracker = {}
local ADDON_NAME = "CritTracker"


CritTracker.savedVars = nil
CritTracker.playerDamage = 0
CritTracker.critCount = 0
CritTracker.normalCount = 0
CritTracker.totalCritDamage = 0
CritTracker.totalNormalDamage = 0
CritTracker.inCombat = false
CritTracker.delay = false
CritTracker.critMultiplier = 0
CritTracker.critDamagePercent = 0
CritTracker.fightCritCount = 0
CritTracker.fightNormalCount = 0
CritTracker.fightTotalCritDamage = 0
CritTracker.fightTotalNormalDamage = 0
CritTracker.fightMaxCrit = nil

--=============================================================================
-- GET STAT SHEET CRIT CHANCE
--=============================================================================
function CritTracker:GetCharSheetCritChance()
    -- Get weapon crit rating
    local critRating = GetPlayerStat(STAT_CRITICAL_STRIKE)

    -- Convert rating to percentage
    local critChance = (critRating / 219)

    return math.min(critChance, 100)
end

--=============================================================================
-- TRACK PLAYER DAMAGE
--=============================================================================
function CritTracker:OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic,
                                   abilityActionSlotType,
                                   sourceName, sourceType, targetName, targetType,
                                   hitValue, powerType, damageType, combatMechanic,
                                   sourceUnitId, targetUnitId, abilityId, overflow)
    if sourceType == COMBAT_UNIT_TYPE_PLAYER and hitValue > 1 then
        self.playerDamage = self.playerDamage + hitValue

        if result == ACTION_RESULT_CRITICAL_DAMAGE or result == ACTION_RESULT_DOT_TICK_CRITICAL then
            self.critCount = self.critCount + 1
            self.totalCritDamage = self.totalCritDamage + hitValue
            self.fightCritCount = self.fightCritCount + 1
            self.fightTotalCritDamage = self.fightTotalCritDamage + hitValue
        elseif result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_DOT_TICK then
            self.normalCount = self.normalCount + 1
            self.totalNormalDamage = self.totalNormalDamage + hitValue
            self.fightNormalCount = self.fightNormalCount + 1
            self.fightTotalNormalDamage = self.fightTotalNormalDamage + hitValue
        end
    end
    if self.inCombat and not self.delay then
        self:UpdateDisplay()
    end
end

--=============================================================================
-- UPDATE DISPLAY
--=============================================================================
function CritTracker:UpdateDisplay()
    local totalHits = self.critCount + self.normalCount
    local charSheet = self:GetCharSheetCritChance()

    if totalHits == 0 then
        -- Show stat sheet info when no combat data
        if self.savedVars.simpleMode then
            local line1Text = string.format("%.1f%%", charSheet)
            line1_CritInfo:SetText(line1Text)
            line2_CritDamage:SetText("") -- Clear second line in simple mode
        else
            if self.savedVars.simpleMode then
                local line1Text = string.format("%.1f%%", charSheet)
            end
            local line1Text = string.format("Base: %.1f%%", charSheet)
            line1_CritInfo:SetText(line1Text)
            line2_CritDamage:SetText("")
        end
        return
    end

    -- Crit rate
    local critRate = (self.critCount / totalHits) * 100

    -- Calculate average crit damage vs normal damage
    local avgCritDamage = self.critCount > 0 and (self.totalCritDamage / self.critCount) or 0
    local avgNormalDamage = self.normalCount > 0 and (self.totalNormalDamage / self.normalCount) or 0
    self.critMultiplier = avgNormalDamage > 0 and (avgCritDamage / avgNormalDamage) or 0
    self.critDamagePercent = self.critMultiplier > 0 and ((self.critMultiplier - 1) * 100) or 0

    if totalHits >= 4 then
        if not self.fightMaxCrit or critRate > self.fightMaxCrit then
            self.fightMaxCrit = critRate
        end
    end


    -- Simple Mode
    if self.savedVars.simpleMode then
        local line1Text = string.format("%.1f%%", critRate)
        if self.savedVars.showCritDmg then
            line1Text = string.format("%.1f%% • Dmg: %.0f%%", critRate, self.critDamagePercent)
        end
        line1_CritInfo:SetText(line1Text)
        line2_CritDamage:SetText("")
    else
        local line1Text = string.format("Effective: %.1f%% • Base: %.1f%%",
            critRate, charSheet)
        local line2Text = ""
        if self.savedVars.showCritDmg then
            line2Text = string.format("Average Crit Damage: %.0f%%", self.critDamagePercent)
        end
        line1_CritInfo:SetText(line1Text)
        line2_CritDamage:SetText(line2Text)
    end
end

--=============================================================================
-- COMBAT SUMMARY
--=============================================================================
function CritTracker:PrintCombatSummary()
    local totalHits = self.fightCritCount + self.fightNormalCount
    if totalHits > 0 then
        local critRate = (self.fightCritCount / totalHits) * 100
        local avgCrit = self.fightCritCount > 0 and (self.fightTotalCritDamage / self.fightCritCount) or 0
        local avgNormal = self.fightNormalCount > 0 and (self.fightTotalNormalDamage / self.fightNormalCount) or 0

        local currentMultiplier = avgNormal > 0 and (avgCrit / avgNormal) or 0
        local currentCritDamagePercent = currentMultiplier > 0 and ((currentMultiplier - 1) * 100) or 0

        self:DebugPrint("=== Combat Summary ===")
        self:DebugPrint(string.format("Total Hits: %d (%d crits, %d normal)", totalHits, self.fightCritCount, self
            .fightNormalCount))
        if self.fightMaxCrit then
            self.fightMaxCrit = math.max(self.fightMaxCrit, critRate)
            self:DebugPrint(string.format("Crit Rate: %.1f%% (Max: %.1f%%)", critRate, self.fightMaxCrit))
        else
            self:DebugPrint(string.format("Crit Rate: %.1f%%", critRate))
        end
        self:DebugPrint(string.format("Avg Crit DMG: %.0f crit, %.0f normal (+%.0f%% / %.2fx)", avgCrit, avgNormal,
            currentCritDamagePercent, currentMultiplier))
    end
end

--=============================================================================
-- RESET VARIABLES
--=============================================================================
function CritTracker:OnCombatStateChanged(inCombat)
    if inCombat then
        self.inCombat = true
        self.fightCritCount = 0
        self.fightNormalCount = 0
        self.fightTotalCritDamage = 0
        self.fightTotalNormalDamage = 0
        self.fightMaxCrit = nil
        self.fightMeanCrit = nil
    else
        self.inCombat = false
        self:DebugPrint("Combat Ended")
        if self.savedVars.showNotifications then
            self:PrintCombatSummary()
        end

        -- Delay to let buffs expire before reading character sheet
        self.delay = true
        zo_callLater(function()
            self.delay = false
            self:UpdateDisplay()
        end, 7000)
    end
end

--=============================================================================
-- INITIALIZE
--=============================================================================
local function Initialize()
    CritTracker.savedVars = ZO_SavedVars:NewAccountWide(
        "CritTracker_SavedVars",
        1,
        nil,
        {
            fontSize = 18,
            labelPosX = 560,
            labelPosY = 20,
            showNotifications = false,
            simpleMode = true,
            showCritDmg = true
        }
    )

    local labels = CritTracker:GetLabels()
    for i, label in ipairs(labels) do
        if label then
            label:SetHidden(false)
        end
    end

    CritTracker:UpdateLabelSettings()

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT,
        function(...) CritTracker:OnCombatEvent(...) end)

    CritTracker:CreateSettingsMenu()
    CritTracker:UpdateDisplay()
end

--=============================================================================
-- EVENT MANAGERS
--=============================================================================
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE,
    function(_, inCombat)
        CritTracker:OnCombatStateChanged(inCombat)
    end)

local function OnAddOnLoaded(event, addonName)
    if addonName == ADDON_NAME then
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
        Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

--=============================================================================
-- DEBUG HELPER
--=============================================================================
function CritTracker:DebugPrint(message)
    if self.savedVars and self.savedVars.showNotifications then
        d(message)
    end
end
