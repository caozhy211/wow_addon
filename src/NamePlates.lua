--- 显示当前生命值
hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
    if strfind(frame.unit, "^nameplate") then
        ---@type StatusBar
        local healthBar = frame.healthBar
        ---@type FontString
        local healthLabel = healthBar.label

        if not healthLabel then
            healthLabel = healthBar:CreateFontString(nil, "ARTWORK", "Game10Font_o1")
            healthLabel:SetPoint("CENTER")
            healthBar.label = healthLabel
        end

        local health = UnitHealth(frame.displayedUnit)
        local maxHealth = UnitHealthMax(frame.displayedUnit)
        local formatStr, divisor
        if health < 1e4 then
            formatStr = "%d"
            divisor = 1
        elseif health < 1e8 then
            formatStr = "%.2f" .. SECOND_NUMBER
            divisor = 1e4
        else
            formatStr = "%.2f" .. SECOND_NUMBER_CAP
            divisor = 1e8
        end
        healthLabel:SetFormattedText(formatStr .. " - " .. "%d%%", health / divisor, health / maxHealth * 100)
    end
end)

--- 设置名称字体和类别标记的位置
hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", function(frame)
    ---@type FontString
    local nameLabel = frame.name
    nameLabel:SetFontObject(SystemFont_LargeNamePlate)
    ---@type Frame
    local classificationFrame = frame.ClassificationFrame
    classificationFrame:SetPoint("RIGHT", frame.name, "LEFT")
end)

--- 调整名称位置
hooksecurefunc("DefaultCompactNamePlateFrameAnchorInternal", function(frame)
    PixelUtil.SetPoint(frame.name, "BOTTOM", frame.healthBar, "TOP", 0, 2)
end)

--- 姓名板始终显示名称
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    local unit = frame.unit
    if strfind(unit, "^nameplate") then
        ---@type FontString
        local nameLabel = frame.name
        nameLabel:SetText(UnitName(unit))
        if CompactUnitFrame_IsTapDenied(frame) then
            nameLabel:SetVertexColor(0.5, 0.5, 0.5)
        elseif frame.optionTable.colorNameBySelection then
            if frame.optionTable.considerSelectionInCombatAsHostile and CompactUnitFrame_IsOnThreatListWithPlayer(
                    frame.displayedUnit) then
                nameLabel:SetVertexColor(1.0, 0.0, 0.0)
            else
                nameLabel:SetVertexColor(UnitSelectionColor(unit, frame.optionTable.colorNameWithExtendedColors))
            end
        end
        nameLabel:Show()
    end
end)

--- 调整 BuffContainer 位置
---@param self Frame
hooksecurefunc(NameplateBuffContainerMixin, "UpdateAnchor", function(self)
    self:SetPoint("BOTTOM", self:GetParent().name, "TOP")
end)

--- 创建箭头纹理
---@param frame Button
local function CreateSelectionArrow(frame)
    local width = 2
    local height = 45
    local r, g, b = GetTableColor(HIGHLIGHT_FONT_COLOR)

    ---@type Texture
    local arrowTopLeft = frame:CreateTexture()
    arrowTopLeft:SetSize(width, height)
    arrowTopLeft:SetPoint("BOTTOMRIGHT", frame.healthBar.border.Left, "LEFT")
    arrowTopLeft:SetRotation(rad(45), 1, 0)
    arrowTopLeft:SetColorTexture(r, g, b)
    frame.arrowTopLeft = arrowTopLeft
    ---@type Texture
    local arrowBottomLeft = frame:CreateTexture()
    arrowBottomLeft:SetSize(width, height)
    arrowBottomLeft:SetPoint("TOPRIGHT", frame.healthBar.border.Left, "LEFT")
    arrowBottomLeft:SetRotation(rad(-45), 1, 1)
    arrowBottomLeft:SetColorTexture(r, g, b)
    frame.arrowBottomLeft = arrowBottomLeft
    ---@type Texture
    local arrowTopRight = frame:CreateTexture()
    arrowTopRight:SetSize(width, height)
    arrowTopRight:SetPoint("BOTTOMLEFT", frame.healthBar.border.Right, "RIGHT")
    arrowTopRight:SetRotation(rad(-45), 0, 0)
    arrowTopRight:SetColorTexture(r, g, b)
    frame.arrowTopRight = arrowTopRight
    ---@type Texture
    local arrowBottomRight = frame:CreateTexture()
    arrowBottomRight:SetSize(width, height)
    arrowBottomRight:SetPoint("TOPLEFT", frame.healthBar.border.Right, "RIGHT")
    arrowBottomRight:SetRotation(rad(45), 0, 1)
    arrowBottomRight:SetColorTexture(r, g, b)
    frame.arrowBottomRight = arrowBottomRight

    frame.selectionArrow = true
end

--- 显示目标箭头
local function ShowSelectionArrow(frame)
    if not frame.selectionArrow then
        CreateSelectionArrow(frame)
    end
    ---@type Texture
    local arrowTopLeft = frame.arrowTopLeft
    arrowTopLeft:Show()
    ---@type Texture
    local arrowBottomLeft = frame.arrowBottomLeft
    arrowBottomLeft:Show()
    ---@type Texture
    local arrowTopRight = frame.arrowTopRight
    arrowTopRight:Show()
    ---@type Texture
    local arrowBottomRight = frame.arrowBottomRight
    arrowBottomRight:Show()
end

--- 隐藏目标箭头
local function HideSelectionArrow(frame)
    if frame.selectionArrow then
        ---@type Texture
        local arrowTopLeft = frame.arrowTopLeft
        arrowTopLeft:Hide()
        ---@type Texture
        local arrowBottomLeft = frame.arrowBottomLeft
        arrowBottomLeft:Hide()
        ---@type Texture
        local arrowTopRight = frame.arrowTopRight
        arrowTopRight:Hide()
        ---@type Texture
        local arrowBottomRight = frame.arrowBottomRight
        arrowBottomRight:Hide()
    end
end

--- 更新目标选择箭头
hooksecurefunc("CompactUnitFrame_UpdateSelectionHighlight", function(frame)
    if strfind(frame.unit, "^nameplate") then
        if UnitIsUnit(frame.displayedUnit, "target") then
            ShowSelectionArrow(frame)
        else
            HideSelectionArrow(frame)
        end
    end
end)

---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WLK_NamePlateScanner", UIParent, "GameTooltipTemplate")

--- 检查 unit 是否是任务单位
local function IsQuestUnit(unit)
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:SetUnit(unit)
    for i = 3, scanner:NumLines() do
        ---@type FontString
        local line = _G[scanner:GetName() .. "TextLeft" .. i]
        local r, g, b = line:GetTextColor()
        if r > 0.99 and g > 0.82 and b == 0 then
            return true
        else
            local text = line:GetText()
            local name, progress = strmatch(text, "^ ([^ ]-) ?%- (.+)$")
            local areaProgress = strmatch(text, "(%d+)%%$")
            if name and (progress or areaProgress) then
                local current, goal
                if areaProgress then
                    current = areaProgress
                    goal = 100
                else
                    current, goal = strmatch(progress, "(%d+)/(%d+)")
                end
                if current and goal then
                    return current ~= goal and (name == "" or name == UnitName("player"))
                end
                return name == "" or name == UnitName("player")
            end
        end
    end
end

--- 更新任务图标
---@param namePlate Frame
local function UpdateQuestIcon(namePlate)
    ---@type Button
    local frame = namePlate.UnitFrame
    if frame then
        ---@type Texture
        local icon = frame.questIcon

        if IsQuestUnit(frame.unit) then
            if icon then
                icon:Show()
            else
                icon = frame:CreateTexture()
                icon:SetSize(22, 22)
                icon:SetPoint("LEFT", frame.healthBar, "RIGHT", 7, 0)
                icon:SetTexture("Interface/WorldMap/UI-WorldMap-QuestIcon")
                icon:SetAtlas("QuestNormal")
                frame.questIcon = icon
            end
        elseif icon then
            icon:Hide()
        end
    end
end

---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("PLAYER_LOGIN")
eventListener:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventListener:RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player")

---@param self Frame
eventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "UNIT_QUEST_LOG_CHANGED" then
        local namePlates = C_NamePlate.GetNamePlates()
        for i = 1, #namePlates do
            UpdateQuestIcon(namePlates[i])
        end
        if event == "PLAYER_LOGIN" then
            self:UnregisterEvent(event)
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unitToken = ...
        UpdateQuestIcon(C_NamePlate.GetNamePlateForUnit(unitToken))
    end
end)
