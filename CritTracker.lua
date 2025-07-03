local defaults = {
    fontSize = 28,
    labelPosX = 560,
    labelPosY = 60,
    showNotifications = false
}

CritTracker = {}
local ADDON_NAME = "CritTracker"

CritTracker.savedVars = nil
CritTracker.critCount = 0
CritTracker.normalCount = 0
CritTracker.totalCritDamage = 0
CritTracker.totalNormalDamage = 0
CritTracker.inCombat = false

--=============================================================================
-- DEBUG HELPER
--=============================================================================
function BossFightContribution:DebugPrint(message)
    if self.savedVars and self.savedVars.showNotifications then
        d(message)
    end
end

--=============================================================================
-- GET STAT SHEET CRIT CHANCE
--=============================================================================
function CritTracker:GetStatSheetCritChance()
    local baseCritRating = 10
    local critRating = GetPlayerStat(STAT_CRITICAL_STRIKE)

    -- Convert rating to percentage (ESO formula)
    local critChance = (critRating / 219) + baseCritRating

    -- Cap at 100%
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

        if result == ACTION_RESULT_CRITICAL_DAMAGE then
            d("CRITICAL hit for" .. hitValue)
            self.critCount = self.critCount + 1
        elseif result == ACTION_RESULT_DAMAGE then
            self.normalCount = self.normalCount + 1
            d("NORMAL hit for" .. hitValue)
        end

        -- Show crit ratio
        local totalHits = self.critCount + self.normalCount
        if totalHits > 0 then
            local critRate = (self.critCount / totalHits) * 100
            d(string.format("Crit Rate: %.1f%% (%d crits / %d total)", critRate, self.critCount, totalHits))
        end
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
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT,
        function(...) CritTracker:OnCombatEvent(...) end)
    CritTracker:CreateSettingsMenu()
end

--=============================================================================
-- UI MANAGEMENT
--=============================================================================
function BossFightContribution:UpdateLabelSettings()
    local fontSize = self.savedVars.fontSize or 48
    local posX = self.savedVars.labelPosX or 100
    local posY = self.savedVars.labelPosY or 100
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

--=============================================================================
-- TRACK PLAYER DAMAGE
--=============================================================================
function CritTracker:CreateSettingsMenu()
    local LAM = LibAddonMenu2
    local panelName = "CritTracker"
    local panelData = {
        type = "panel",
        name = "CritTracker",
        displayName = "CritTracker",
        author = "YFNatey",
        version = "1.0",
        registerForRefresh = true,
        registerForDefaults = true
    }
    local optionsTable = {
        [1] = {
            type = "button",
            name = "Toggle UI",
            func = function()
                local labels = self:GetLabels()
                local isCurrentlyHidden = labels[1] and labels[1]:IsHidden()

                if isCurrentlyHidden then
                    -- Show and refresh content
                    for i, label in ipairs(labels) do
                        if label then
                            label:SetHidden(false)
                        end
                    end
                else
                    -- Hide
                    for i, label in ipairs(labels) do
                        if label then
                            label:SetHidden(true)
                        end
                    end
                    return
                end
            end
        },
        [2] = {
            type = "description",
            text = "Adjust UI"
        },
        [3] = {
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
        [4] = {
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
            default = 100,
        },
        [5] = {
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
            default = 100,
        },
        [6] = {
            type = "divider",
        },
        [7] = {
            type = "checkbox",
            name = "Enable Debug Notifications",
            getFunc = function() return self.savedVars.showNotifications end,
            setFunc = function(value) self.savedVars.showNotifications = value end,
            default = defaults.showNotifications,
        },
    }

    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, optionsTable)
end

--=============================================================================
-- EVENT MANAGERS
--=============================================================================
-- Register start and stop for combat state
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE,
    function(_, inCombat)
        CritTracker:OnCombatStateChanged(inCombat)
    end)

local function OnAddOnLoaded(event, addonName)
    if addonName == ADDON_NAME then
        d("AddOn Loaded: " .. addonName)
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
        Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

-- Periodic update
EVENT_MANAGER:RegisterForUpdate(ADDON_NAME .. "_UpdateStatus", 1000, function()
    CritTracker:UpdateStatus()
end)
