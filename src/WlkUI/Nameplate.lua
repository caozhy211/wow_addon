local TITLE_R, TITLE_G, TITLE_B = 1, 0.82, 0
local scenarioName
local acceptedQuests = {}
local scannerName = "WlkNameplateUnitScanner"

---@type Frame
local listener = CreateFrame("Frame")
---@type GameTooltip
local scanner = CreateFrame("GameTooltip", scannerName, UIParent, "GameTooltipTemplate")

---@param frame Button
local function isNotForbiddenNameplateUnitFrame(frame)
    return not frame:IsForbidden() and strmatch(frame.unit, "^nameplate%d+$")
end

---@param frame WlkNameplateUnitFrame
local function createHighlight(frame)
    local width = 2
    local height = 30
    local r, g, b = 1, 1, 0
    frame.highlight1 = frame:CreateTexture()
    frame.highlight1:SetSize(width, height)
    frame.highlight1:SetPoint("BOTTOMRIGHT", frame.healthBar.border.Left, "LEFT")
    frame.highlight1:SetRotation(rad(45), 1, 0)
    frame.highlight1:SetColorTexture(r, g, b)
    frame.highlight2 = frame:CreateTexture()
    frame.highlight2:SetSize(width, height)
    frame.highlight2:SetPoint("TOPRIGHT", frame.healthBar.border.Left, "LEFT")
    frame.highlight2:SetRotation(rad(-45), 1, 1)
    frame.highlight2:SetColorTexture(r, g, b)
    frame.highlight3 = frame:CreateTexture()
    frame.highlight3:SetSize(width, height)
    frame.highlight3:SetPoint("BOTTOMLEFT", frame.healthBar.border.Right, "RIGHT")
    frame.highlight3:SetRotation(rad(-45), 0, 0)
    frame.highlight3:SetColorTexture(r, g, b)
    frame.highlight4 = frame:CreateTexture()
    frame.highlight4:SetSize(width, height)
    frame.highlight4:SetPoint("TOPLEFT", frame.healthBar.border.Right, "RIGHT")
    frame.highlight4:SetRotation(rad(45), 0, 1)
    frame.highlight4:SetColorTexture(r, g, b)
end

---@param frame WlkNameplateUnitFrame
local function setHighlightShown(frame, show)
    if show then
        if frame.highlight1 then
            frame.highlight1:Show()
            frame.highlight2:Show()
            frame.highlight3:Show()
            frame.highlight4:Show()
        else
            createHighlight(frame)
        end
    elseif frame.highlight1 then
        frame.highlight1:Hide()
        frame.highlight2:Hide()
        frame.highlight3:Hide()
        frame.highlight4:Hide()
    end
end

local function isQuestTitleColor(r, g, b)
    return abs(r - TITLE_R) < 0.005 and abs(g - TITLE_G) < 0.005 and abs(b - TITLE_B) < 0.005
end

local function getQuestProgress(unit)
    if unit then
        local checkProgress
        local progress
        scanner:SetOwner(UIParent, "ANCHOR_NONE")
        scanner:SetUnit(unit)
        for i = 3, scanner:NumLines() do
            ---@type FontString
            local label = _G[scannerName .. "TextLeft" .. i]
            local text = label:GetText()
            local r, g, b = label:GetTextColor()
            if isQuestTitleColor(r, g, b) then
                if text == scenarioName or text == UnitName("player") or acceptedQuests[text] then
                    checkProgress = true
                else
                    return
                end
            elseif checkProgress then
                local current, goal = strmatch(text, "(%d+)/(%d+)")
                if current and goal and current ~= goal then
                    progress = tonumber(goal) - tonumber(current)
                else
                    local percent = strmatch(text, "%((%d+)%%%)") or strmatch(text, "(%d+)%%$")
                    if percent and percent ~= "100" then
                        progress = percent .. "%"
                    end
                end
                if progress then
                    return progress
                end
            end
        end
    end
end

---@param frame WlkNameplateUnitFrame
local function updateQuestIndicator(frame)
    local progress = getQuestProgress(frame.unit)
    if progress then
        if not frame.questIcon then
            frame.questIcon = frame:CreateTexture()
            frame.questIcon:SetSize(22, 22)
            frame.questIcon:SetPoint("LEFT", frame.healthBar, "RIGHT", 7, 0)
            frame.questIcon:SetAtlas("QuestNormal")
            frame.progressLabel = frame:CreateFontString(nil, "ARTWORK", "NumberFont_Shadow_Small")
            frame.progressLabel:SetPoint("LEFT", frame.questIcon, "RIGHT", -7, 0)
            frame.progressLabel:SetText(progress)
        else
            frame.questIcon:Show()
            frame.progressLabel:SetText(progress)
            frame.progressLabel:Show()
        end
    elseif frame.questIcon then
        frame.questIcon:Hide()
        frame.progressLabel:Hide()
    end
end

local function updateAllNameplateQuestIndicator()
    local nameplates = C_NamePlate.GetNamePlates()
    for _, nameplate in pairs(nameplates) do
        updateQuestIndicator(nameplate.UnitFrame)
    end
end

listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterEvent("QUEST_ACCEPTED")
listener:RegisterEvent("QUEST_REMOVED")
listener:RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player")
listener:RegisterEvent("SCENARIO_UPDATE")
listener:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
listener:RegisterEvent("NAME_PLATE_UNIT_ADDED")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        scenarioName = C_Scenario.GetInfo()
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if not info.isHeader and not info.isBounty and not acceptedQuests[info.title] then
                acceptedQuests[info.title] = info.questID
            end
        end
    elseif event == "QUEST_ACCEPTED" then
        local questId = ...
        local title = C_QuestLog.GetTitleForQuestID(questId)
        if title and not acceptedQuests[title] then
            acceptedQuests[title] = questId
            C_Timer.NewTicker(0.1, updateAllNameplateQuestIndicator, 2)
        end
    elseif event == "QUEST_REMOVED" then
        local questId = ...
        for title, id in pairs(acceptedQuests) do
            if id == questId then
                acceptedQuests[title] = nil
                break
            end
        end
    elseif event == "UNIT_QUEST_LOG_CHANGED" then
        updateAllNameplateQuestIndicator()
    elseif event == "SCENARIO_UPDATE" then
        scenarioName = C_Scenario.GetInfo()
    elseif event == "SCENARIO_CRITERIA_UPDATE" then
        updateAllNameplateQuestIndicator()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unitToken = ...
        ---@type BaseNamePlateUnitFrameTemplate
        local unitFrame = C_NamePlate.GetNamePlateForUnit(unitToken).UnitFrame
        unitFrame.healthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill")
        unitFrame.name:SetFontObject("NumberFont_Shadow_Small")
        unitFrame.ClassificationFrame:SetPoint("RIGHT", unitFrame.name, "LEFT")
        C_Timer.NewTicker(0.1, function()
            updateQuestIndicator(unitFrame)
        end, 2)
    end
end)

hooksecurefunc("CompactUnitFrame_UpdateSelectionHighlight", function(frame)
    if isNotForbiddenNameplateUnitFrame(frame) then
        setHighlightShown(frame, UnitIsUnit(frame.displayedUnit, "target"))
    end
end)

---@param frame WlkNameplateUnitFrame
hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
    if isNotForbiddenNameplateUnitFrame(frame) then
        ---@type FontString
        local label = frame.healthBar.label
        if not label then
            label = frame.healthBar:CreateFontString(nil, "ARTWORK", "NumberFont_Shadow_Small")
            label:SetPoint("CENTER")
            frame.healthBar.label = label
        end
        local health = UnitHealth(frame.displayedUnit)
        local healthString
        if health >= 1e8 then
            healthString = format("%.2f%s", health / 1e8, SECOND_NUMBER_CAP)
        elseif health >= 1e4 then
            healthString = format("%.2f%s", health / 1e4, FIRST_NUMBER_CAP)
        else
            healthString = format("%.0f", health)
        end
        local maxHealth = UnitHealthMax(frame.displayedUnit)
        label:SetText(healthString .. " - " .. FormatPercentage(PercentageBetween(health, 0, maxHealth)))
    end
end)

---@param frame BaseNamePlateUnitFrameTemplate
hooksecurefunc("DefaultCompactNamePlateFrameAnchorInternal", function(frame)
    if not frame:IsForbidden() then
        PixelUtil.SetPoint(frame.name, "BOTTOM", frame.healthBar, "TOP", 0, 2)
    end
end)

---@param frame BaseNamePlateUnitFrameTemplate
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if isNotForbiddenNameplateUnitFrame(frame) then
        local name = GetUnitName(frame.unit, true)
        frame.name:SetText(name)
        if CompactUnitFrame_IsTapDenied(frame) then
            frame.name:SetVertexColor(0.5, 0.5, 0.5)
        elseif frame.optionTable.colorNameBySelection then
            if frame.optionTable.considerSelectionInCombatAsHostile
                    and CompactUnitFrame_IsOnThreatListWithPlayer(frame.displayedUnit) then
                frame.name:SetVertexColor(1, 0, 0)
            else
                frame.name:SetVertexColor(UnitSelectionColor(frame.unit, frame.optionTable.colorNameWithExtendedColors))
            end
        end
        frame.name:Show()
    end
end)

---@param self Frame
hooksecurefunc(NameplateBuffContainerMixin, "UpdateAnchor", function(self)
    if not self:IsForbidden() then
        self:SetPoint("BOTTOM", self:GetParent().name, "TOP")
    end
end)

---@class WlkNameplateUnitFrame:BaseNamePlateUnitFrameTemplate
