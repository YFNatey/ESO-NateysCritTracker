local defaults = {
    fontSize = 28,
    labelPosX = 560,
    labelPosY = 60,
    showNotifications = false
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

--=============================================================================
-- DEBUG HELPER
--=============================================================================
function CritTracker:DebugPrint(message)
    if self.savedVars and self.savedVars.showNotifications then
        d(message)
    end
end

--=============================================================================
-- GET STAT SHEET CRIT CHANCE
--=============================================================================
function CritTracker:GetStatSheetCritChance()
    -- Get weapon crit rating
    local critRating = GetPlayerStat(STAT_CRITICAL_STRIKE)

    -- Convert rating to percentage
    local critChance = (critRating / 219)

    return math.min(critChance, 100) -- Cap at 100%
end

--=============================================================================
-- RESET VARIABLES
--=============================================================================
function CritTracker:OnCombatStateChanged(inCombat)
    if inCombat then
        self.inCombat = true
        self.critCount = 0
        self.normalCount = 0
        self.totalCritDamage = 0
        self.totalNormalDamage = 0
        self:DebugPrint("Combat Started")
    else
        self.inCombat = false
        self:DebugPrint("Combat Ended")
        self:UpdateDisplay()
    end
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

        if result == ACTION_RESULT_CRITICAL_DAMAGE then
            self:DebugPrint("CRITICAL hit for" .. hitValue)
            self.critCount = self.critCount + 1
            self.totalCritDamage = self.totalCritDamage + hitValue
        elseif result == ACTION_RESULT_DAMAGE then
            self.normalCount = self.normalCount + 1
            self:DebugPrint("NORMAL hit for" .. hitValue)
            self.totalNormalDamage = self.totalNormalDamage + hitValue
        end

        -- Show crit ratio
        local totalHits = self.critCount + self.normalCount
        if totalHits > 0 then
            local critRate = (self.critCount / totalHits) * 100
            self:DebugPrint(string.format("Crit Rate: %.1f%% (%d crits / %d total)", critRate, self.critCount, totalHits))
        end
    end
    if self.inCombat then
        self:UpdateDisplay()
    end
end

--=============================================================================
-- UPDATE DISPLAY
--=============================================================================
function CritTracker:UpdateDisplay()
    local totalHits = self.critCount + self.normalCount
    local totalDamage = self.totalCritDamage + self.totalNormalDamage

    if totalHits == 0 then
        -- Show stat sheet info when no combat data
        local statSheetCrit = self:GetStatSheetCritChance()
        local line1Text = string.format("Stat Sheet Crit: %.1f%%",
            statSheetCrit)

        line1_CritInfo:SetText(line1Text)
        return
    end

    -- Crit rate
    local activeCritRate = (self.critCount / totalHits) * 100
    local statSheetCrit = self:GetStatSheetCritChance()

    -- Calculate average crit damage vs normal damage
    local avgCritDamage = self.critCount > 0 and (self.totalCritDamage / self.critCount) or 0
    local avgNormalDamage = self.normalCount > 0 and (self.totalNormalDamage / self.normalCount) or 0
    local critMultiplier = avgNormalDamage > 0 and (avgCritDamage / avgNormalDamage) or 0

    -- Display lines
    local line1Text = string.format("Stat Sheet: %.1f%% | Active Crit: %.1f%%",
        statSheetCrit, activeCritRate)

    local critDamagePercent = critMultiplier > 0 and ((critMultiplier - 1) * 100) or 0

    local line3Text = string.format("Crit Damage: +%.0f%% (%.2fx)",
        critDamagePercent, critMultiplier)

    line1_CritInfo:SetText(line1Text)

    line3_CritDamage:SetText(line3Text)
end

--=============================================================================
-- FORMAT NUMBERS
--=============================================================================
function CritTracker:FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fk", number / 1000)
    else
        return string.format("%.0f", number)
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
            labelPosY = 60,
            showNotifications = false,
        }
    )
    -- Hide labels initially
    local labels = CritTracker:GetLabels()
    for i, label in ipairs(labels) do
        if label then
            label:SetHidden(true)
        end
    end

    CritTracker:UpdateLabelSettings()

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT,
        function(...) CritTracker:OnCombatEvent(...) end)

    CritTracker:CreateSettingsMenu()
end


--=============================================================================
-- UI MANAGEMENT
--=============================================================================
function CritTracker:GetLabels()
    return {
        _G["line1_CritInfo"],
        _G["line2_CritStats"],
        _G["line3_CritDamage"]
    }
end

function CritTracker:UpdateLabelSettings()
    local fontSize = self.savedVars.fontSize or 24
    local posX = self.savedVars.labelPosX or 560
    local posY = self.savedVars.labelPosY or 60
    local labels = self:GetLabels()

    for i, label in ipairs(labels) do
        if label then
            label:SetFont(string.format("$(BOLD_FONT)|%d", fontSize))
            label:ClearAnchors()
            local yOffset = posY + (i - 1) * 30
            label:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, yOffset)
        else
            self:DebugPrint("Warning: Label " .. i .. " not found")
        end
    end
end

function CritTracker:ClearLabels()
    local labels = self:GetLabels()
    for i, label in ipairs(labels) do
        if label then
            label:SetText("")
        end
    end
end

--=============================================================================
-- Settings Menu
--=============================================================================
function CritTracker:CreateSettingsMenu()
    local LAM = LibAddonMenu2
    local panelName = "CritTrackerSettings"

    local panelData = {
        type = "panel",
        name = "Crit Tracker",
        author = "YFNatey",
        version = "1.0",
        registerForRefresh = true,
        registerForDefaults = true
    }

    local optionsTable = {
        [1] = {
            type = "button",
            name = "Toggle UI",
            tooltip = "Show/hide the crit tracking display",
            func = function()
                local labels = self:GetLabels()
                local isCurrentlyHidden = labels[1] and labels[1]:IsHidden()

                if isCurrentlyHidden then
                    -- Show labels
                    for i, label in ipairs(labels) do
                        if label then
                            label:SetHidden(false)
                        end
                    end
                    self:UpdateDisplay()
                else
                    -- Hide labels
                    for i, label in ipairs(labels) do
                        if label then
                            label:SetHidden(true)
                        end
                    end
                end
            end
        },
        [2] = {
            type = "button",
            name = "Reset Stats",
            tooltip = "Clear current combat crit statistics",
            func = function()
                self.critCount = 0
                self.normalCount = 0
                self.totalCritDamage = 0
                self.totalNormalDamage = 0
                self:UpdateDisplay()
                d("Crit stats reset")
            end
        },
        [3] = {
            type = "divider",
        },
        [4] = {
            type = "description",
            text = "Adjust UI Position and Size"
        },
        [5] = {
            type = "slider",
            name = "Font Size",
            min = 10,
            max = 48,
            step = 1,
            getFunc = function() return self.savedVars.fontSize end,
            setFunc = function(value)
                self.savedVars.fontSize = value
                self:UpdateLabelSettings()
            end,
            default = 24,
        },
        [6] = {
            type = "slider",
            name = "Label X Position",
            min = 0,
            max = 1920,
            step = 10,
            getFunc = function() return self.savedVars.labelPosX end,
            setFunc = function(value)
                self.savedVars.labelPosX = value
                self:UpdateLabelSettings()
            end,
            default = 560,
        },
        [7] = {
            type = "slider",
            name = "Label Y Position",
            min = 0,
            max = 1080,
            step = 10,
            getFunc = function() return self.savedVars.labelPosY end,
            setFunc = function(value)
                self.savedVars.labelPosY = value
                self:UpdateLabelSettings()
            end,
            default = 60,
        },
        [8] = {
            type = "divider",
        },
        [9] = {
            type = "checkbox",
            name = "Enable Debug Notifications",
            getFunc = function() return self.savedVars.showNotifications end,
            setFunc = function(value) self.savedVars.showNotifications = value end,
            default = false,
        },
    }
    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, optionsTable)
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
