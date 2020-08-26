---@param frame Button|BaseNamePlateUnitFrameTemplate
hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
    if not frame:IsForbidden() and strmatch(frame.unit, "^nameplate%d$") then
        local label = frame.healthBar.label
        if not label then
            label = frame.healthBar:CreateFontString(frame:GetName() .. "HealthLabel", "ARTWORK", "Game10Font_o1")
            frame.healthBar.label = label
            label:SetPoint("CENTER")
        end
        local health = UnitHealth(frame.displayedUnit)
        local healthString
        if health >= 1e8 then
            healthString = format("%.2f%s", health / 1e8, SECOND_NUMBER_CAP)
        elseif health >= 1e4 then
            healthString = format("%.2f%s", health / 1e4, FIRST_NUMBER_CAP)
        else
            healthString = format("%d", health)
        end
        local maxHealth = UnitHealthMax(frame.displayedUnit)
        label:SetFormattedText("%s - %s", healthString, FormatPercentage(PercentageBetween(health, 0, maxHealth)))
    end
end)

---@param frame Button|BaseNamePlateUnitFrameTemplate
hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", function(frame)
    if not frame:IsForbidden() then
        frame.name:SetFontObject("SystemFont_LargeNamePlate")
        frame.ClassificationFrame:SetPoint("RIGHT", frame.name, "LEFT")
    end
end)

---@param frame Button|BaseNamePlateUnitFrameTemplate
hooksecurefunc("DefaultCompactNamePlateFrameAnchorInternal", function(frame)
    if not frame:IsForbidden() then
        PixelUtil.SetPoint(frame.name, "BOTTOM", frame.healthBar, "TOP", 0, 2)
    end
end)

---@param frame Button|BaseNamePlateUnitFrameTemplate
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if not frame:IsForbidden() and strmatch(frame.unit, "^nameplate%d$") then
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

hooksecurefunc("CreateFrame", function(_, frameName, _, template)
    if frameName and template == "NameplateBuffButtonTemplate" then
        ---@type Button|NameplateBuffButtonTemplate
        local frame = _G[frameName]
        if not frame:IsForbidden() then
            frame.CountFrame:SetFrameLevel(frame.CountFrame:GetFrameLevel() - 1)
            frame.CountFrame.Count:SetFontObject("Game10Font_o1")
            frame.CountFrame.Count:ClearAllPoints()
            frame.CountFrame.Count:SetPoint("BOTTOMRIGHT", 3, 0)
        end
    end
end)

---@param frame Button|BaseNamePlateUnitFrameTemplate
local function ShowSelectionIndicators(frame)
    if not frame.selectionIndicator1 then
        local width = 2
        local height = 30
        local r, g, b = 1, 1, 0
        ---@type Texture
        frame.selectionIndicator1 = frame:CreateTexture()
        frame.selectionIndicator1:SetSize(width, height)
        frame.selectionIndicator1:SetPoint("BOTTOMRIGHT", frame.healthBar.border.Left, "LEFT")
        frame.selectionIndicator1:SetRotation(rad(45), 1, 0)
        frame.selectionIndicator1:SetColorTexture(r, g, b)
        ---@type Texture
        frame.selectionIndicator2 = frame:CreateTexture()
        frame.selectionIndicator2:SetSize(width, height)
        frame.selectionIndicator2:SetPoint("TOPRIGHT", frame.healthBar.border.Left, "LEFT")
        frame.selectionIndicator2:SetRotation(rad(-45), 1, 1)
        frame.selectionIndicator2:SetColorTexture(r, g, b)
        ---@type Texture
        frame.selectionIndicator3 = frame:CreateTexture()
        frame.selectionIndicator3:SetSize(width, height)
        frame.selectionIndicator3:SetPoint("BOTTOMLEFT", frame.healthBar.border.Right, "RIGHT")
        frame.selectionIndicator3:SetRotation(rad(-45), 0, 0)
        frame.selectionIndicator3:SetColorTexture(r, g, b)
        ---@type Texture
        frame.selectionIndicator4 = frame:CreateTexture()
        frame.selectionIndicator4:SetSize(width, height)
        frame.selectionIndicator4:SetPoint("TOPLEFT", frame.healthBar.border.Right, "RIGHT")
        frame.selectionIndicator4:SetRotation(rad(45), 0, 1)
        frame.selectionIndicator4:SetColorTexture(r, g, b)
    else
        frame.selectionIndicator1:Show()
        frame.selectionIndicator2:Show()
        frame.selectionIndicator3:Show()
        frame.selectionIndicator4:Show()
    end
end

---@param frame Button
local function HideSelectionIndicators(frame)
    if frame.selectionIndicator1 then
        frame.selectionIndicator1:Hide()
        frame.selectionIndicator2:Hide()
        frame.selectionIndicator3:Hide()
        frame.selectionIndicator4:Hide()
    end
end

---@param frame Button
hooksecurefunc("CompactUnitFrame_UpdateSelectionHighlight", function(frame)
    if not frame:IsForbidden() and strmatch(frame.unit, "^nameplate%d$") then
        if UnitIsUnit(frame.displayedUnit, "target") then
            ShowSelectionIndicators(frame)
        else
            HideSelectionIndicators(frame)
        end
    end
end)

local scenarioName
local acceptQuests = {}
---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WlkNameplateUnitScanner", UIParent, "GameTooltipTemplate")

local function IsTitleText(r, g, b)
    local red = 1
    local green = 0.82
    local blue = 0
    return abs(r - red) < 0.005 and abs(g - green) < 0.005 and abs(b - blue) < 0.005
end

local function IsQuestUnit(unit)
    local checkProgress, progress
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:SetUnit(unit)
    for i = 3, scanner:NumLines() do
        ---@type FontString
        local line = _G["WlkNameplateUnitScannerTextLeft" .. i]
        local text = line:GetText()
        local r, g, b = line:GetTextColor()
        if IsTitleText(r, g, b) then
            if text == scenarioName or text == UnitName("player") or acceptQuests[text] then
                checkProgress = true
            else
                break
            end
        elseif checkProgress then
            local current, total = strmatch(text, "(%d+)/(%d+)")
            local percent = strmatch(text, "%((%d+)%%%)") or strmatch(text, "(%d+)%%$")
            if current and total and current ~= total then
                progress = tonumber(total) - tonumber(current)
            elseif percent and percent ~= "100" then
                progress = percent .. "%"
            end
        end
    end
    return progress
end

local function UpdateQuestIcon(nameplate)
    ---@type Button
    local frame = nameplate.UnitFrame
    if frame then
        local icon = frame.questIcon
        local progress = IsQuestUnit(frame.unit)
        if progress then
            if not icon then
                icon = frame:CreateTexture()
                frame.questIcon = icon
                icon:SetSize(22, 22)
                icon:SetPoint("LEFT", frame.healthBar, "RIGHT", 7, 0)
                icon:SetAtlas("QuestNormal")
                ---@type FontString
                local label = frame:CreateFontString()
                frame.progressLabel = label
                label:SetFontObject("SystemFont_LargeNamePlate")
                label:SetPoint("LEFT", icon, "RIGHT", -7, 0)
                label:SetText(progress)
            else
                icon:Show()
                frame.progressLabel:SetText(progress)
                frame.progressLabel:Show()
            end
        elseif icon then
            icon:Hide()
            frame.progressLabel:Hide()
        end
    end
end

local function UpdateNameplatesQuestIcon()
    local nameplates = C_NamePlate.GetNamePlates()
    for _, nameplate in ipairs(nameplates) do
        UpdateQuestIcon(nameplate)
    end
end

---@type Frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player")
eventFrame:RegisterEvent("SCENARIO_UPDATE")
eventFrame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        scenarioName = C_Scenario.GetInfo()
        for i = 1, GetNumQuestLogEntries() do
            local title, _, _, isHeader, _, _, _, questId, _, _, _, _, _, isBounty = GetQuestLogTitle(i)
            if not isHeader and not isBounty and not acceptQuests[title] then
                acceptQuests[title] = questId
            end
        end
        UpdateNameplatesQuestIcon()
    elseif event == "QUEST_ACCEPTED" then
        local questIndex, questId = ...
        local title = GetQuestLogTitle(questIndex)
        if title and not acceptQuests[title] then
            acceptQuests[title] = questId
            UpdateNameplatesQuestIcon()
        end
    elseif event == "QUEST_REMOVED" then
        local questId = ...
        for title, id in pairs(acceptQuests) do
            if id == questId then
                acceptQuests[title] = nil
                break
            end
        end
    elseif event == "UNIT_QUEST_LOG_CHANGED" then
        UpdateNameplatesQuestIcon()
    elseif event == "SCENARIO_UPDATE" then
        scenarioName = C_Scenario.GetInfo()
    elseif event == "SCENARIO_CRITERIA_UPDATE" then
        UpdateNameplatesQuestIcon()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unitToken = ...
        UpdateQuestIcon(C_NamePlate.GetNamePlateForUnit(unitToken))
    end
end)
