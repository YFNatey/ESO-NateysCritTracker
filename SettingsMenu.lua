--=============================================================================
-- UI MANAGEMENT
--=============================================================================
function CritTracker:GetLabels()
    return {
        _G["line1_CritInfo"],
        _G["line2_CritDamage"]
    }
end

function CritTracker:UpdateLabelSettings()
    local fontSize = self.savedVars.fontSize or 24
    local posX = self.savedVars.labelPosX or 560
    local posY = self.savedVars.labelPosY or 60
    local labels = self:GetLabels()

    for i, label in ipairs(labels) do
        if label then
            label:SetFont(string.format("$(CHAT_FONT)|%d|soft-shadow-thick", fontSize))
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
            func = function()
                self.critCount = 0
                self.normalCount = 0
                self.totalCritDamage = 0
                self.totalNormalDamage = 0
                self.critDamagePercent = 0
                self.critMultiplier = 0
                self:UpdateDisplay()
                self:DebugPrint("Crit stats reset")
            end
        },
        [3] = {
            type = "divider",
        },
        [4] = {
            type = "description",
            text = "Adjust UI"
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
            max = 5000,
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
            max = 7000,
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
            name = "Simple Display Mode",
            getFunc = function() return self.savedVars.simpleMode end,
            setFunc = function(value)
                self.savedVars.simpleMode = value
                self:UpdateDisplay()
            end,
            default = false,
        },
        [10] = {
            type = "checkbox",
            name = "Show Average Crit Damage",
            tooltip =
            "Early readings may exceed the 125% cap or seem inaccurate due to small sample size - accuracy improves with more combat data.",
            getFunc = function() return self.savedVars.showCritDmg end,
            setFunc = function(value)
                self.savedVars.showCritDmg = value
                self:UpdateDisplay()
            end,
            default = false,
        },
        [11] = {
            type = "divider",
        },
        [12] = {
            type = "checkbox",
            name = "Show Combat Stats",
            getFunc = function() return self.savedVars.showNotifications end,
            setFunc = function(value) self.savedVars.showNotifications = value end,
            default = false,
        },
    }
    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, optionsTable)
end
