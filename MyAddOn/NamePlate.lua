local font = GameFontNormal:GetFont()
local verticalSpacing = 2
local tooltip = CreateFrame("GameTooltip", "MyNamePlateTooltip", UIParent, "GameTooltipTemplate")

local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f億", number / 1e8)
    elseif number >= 1e4 then
        return format("%.2f萬", number / 1e4)
    end
    return number
end

hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
    if strfind(frame.unit, "nameplate") then
        if not frame.healthBar.text then
            frame.healthBar.text = frame.healthBar:CreateFontString()
            frame.healthBar.text:SetFont(font, 10, "Outline")
            frame.healthBar.text:SetPoint("Center")
        end

        local currentHealth = UnitHealth(frame.displayedUnit)
        local maxHealth = UnitHealthMax(frame.displayedUnit)
        local percent = floor(currentHealth / maxHealth * 100 + 0.5) .. "%"

        frame.healthBar.text:SetText(FormatNumber(currentHealth) .. " - " .. percent)
    end
end)

local function IsQuestUnit(unit)
    local questArea = false
    local questPlayer = false
    local questGroup = false

    local guid = UnitGUID(unit)
    if guid then
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetHyperlink("unit:" .. guid)
        for i = 3, tooltip:NumLines() do
            local line = _G["MyNamePlateTooltipTextLeft" .. i]
            local text = line:GetText()
            local r, g, b = line:GetTextColor()
            if r > 0.99 and g > 0.82 and b == 0 then
                questArea = true
            else
                local name, progress = strmatch(text, "^ ([^ ]-) ?%- (.+)$")
                if progress then
                    questArea = nil
                    if name then
                        local current, goal = strmatch(progress, "(%d+)/(%d+)")
                        if current and goal then
                            if current ~= goal then
                                if name == "" or name == UnitName("player") then
                                    questPlayer = true
                                else
                                    questGroup = true
                                end
                                break
                            end
                        else
                            if name == "" or name == UnitName("player") then
                                questPlayer = true
                            else
                                questGroup = true
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    local questType = ((questPlayer or questArea) and 1) or false
    return questType ~= false, questType
end

local function ShowTargetArrow(frame)
    if not frame.leftArrowTop then
        local width = 2
        local height = 45
        local rotation = PI / 4
        local xOffset = height / 2 * math.sin(rotation) + 2
        local yOffset = height / 2 - height / 2 * math.cos(rotation) + width / 2 * math.sin(rotation)

        frame.leftArrowTop = frame:CreateTexture()
        frame.leftArrowTop:SetSize(width, height)
        frame.leftArrowTop:SetPoint("Bottom", frame.healthBar, "Left", -xOffset, -yOffset)
        frame.leftArrowTop:SetRotation(rotation)
        frame.leftArrowTop:SetColorTexture(1, 1, 1)
        frame.leftArrowBottom = frame:CreateTexture()
        frame.leftArrowBottom:SetSize(width, height)
        frame.leftArrowBottom:SetPoint("Top", frame.healthBar, "Left", -xOffset, yOffset)
        frame.leftArrowBottom:SetRotation(-rotation)
        frame.leftArrowBottom:SetColorTexture(1, 1, 1)

        frame.rightArrowTop = frame:CreateTexture()
        frame.rightArrowTop:SetSize(width, height)
        frame.rightArrowTop:SetPoint("Bottom", frame.healthBar, "Right", xOffset, -yOffset)
        frame.rightArrowTop:SetRotation(-rotation)
        frame.rightArrowTop:SetColorTexture(1, 1, 1)
        frame.rightArrowBottom = frame:CreateTexture()
        frame.rightArrowBottom:SetSize(width, height)
        frame.rightArrowBottom:SetPoint("Top", frame.healthBar, "Right", xOffset, yOffset)
        frame.rightArrowBottom:SetRotation(rotation)
        frame.rightArrowBottom:SetColorTexture(1, 1, 1)
    else
        frame.leftArrowTop:Show()
        frame.leftArrowBottom:Show()
        frame.rightArrowTop:Show()
        frame.rightArrowBottom:Show()
    end
end

local function HideTargetArrow(frame)
    if not frame.leftArrowTop then
        return
    end
    frame.leftArrowTop:Hide()
    frame.leftArrowBottom:Hide()
    frame.rightArrowTop:Hide()
    frame.rightArrowBottom:Hide()
end

local function ShowQuestMark(frame)
    if not frame.questMarkTop then
        local width = 4
        local height = 20
        local spacing = 3
        local xOffset = height / 2 * math.sin(PI / 4)

        frame.questMarkTop = frame:CreateTexture()
        frame.questMarkTop:SetSize(width, height - width - spacing)
        frame.questMarkTop:SetPoint("Top", frame, "Right", xOffset, height / 2)
        frame.questMarkTop:SetColorTexture(1, 1, 0)
        frame.questMarkBottom = frame:CreateTexture()
        frame.questMarkBottom:SetSize(width, width)
        frame.questMarkBottom:SetPoint("Top", frame.questMarkTop, "Bottom", 0, -spacing)
        frame.questMarkBottom:SetColorTexture(1, 1, 0)
    else
        frame.questMarkTop:Show()
        frame.questMarkBottom:Show()
    end
end

local function HideQuestMark(frame)
    if not frame.questMarkTop then
        return
    end
    frame.questMarkTop:Hide()
    frame.questMarkBottom:Hide()
end

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if strfind(frame.unit, "nameplate") then
        local name = GetUnitName(frame.unit, true)
        if C_Commentator.IsSpectating() and name then
            local overrideName = C_Commentator.GetPlayerOverrideName(name)
            if overrideName then
                name = overrideName
            end
        end
        frame.name:SetText(name)
        frame.name:SetFont(font, 12, "Outline")
        frame.name:SetPoint("Bottom", frame.healthBar, "Top", frame.classificationIndicator:IsShown() and (14 / 2) or 0, verticalSpacing)
        frame.name:Show()

        frame.ClassificationFrame:SetPoint("Right", frame.name, "Left")

        if UnitIsUnit(frame.unit, "target") then
            frame.name:SetVertexColor(1, 0, 1)
            ShowTargetArrow(frame)
        else
            frame.name:SetVertexColor(1, 1, 1)
            HideTargetArrow(frame)
        end

        if IsQuestUnit(frame.unit) then
            ShowQuestMark(frame)
        else
            HideQuestMark(frame)
        end
    end
end)

local function MoveBuffs()
    local numPerLine = 6
    local horizSpacing = (130 - numPerLine * 20) / (numPerLine - 1)

    hooksecurefunc(NameplateBuffContainerMixin, "UpdateBuffs", function(self)
        for i = 1, BUFF_MAX_DISPLAY do
            local buff = self.buffList[i]
            if buff then
                local namePlate = self:GetParent()

                buff.CountFrame.Count:SetFont(font, 8, "Outline")
                buff:ClearAllPoints()
                if i == 1 then
                    buff:SetPoint("BottomLeft", namePlate.healthBar, "TopLeft", 0, namePlate.name:GetHeight() + verticalSpacing * 2)
                elseif i % numPerLine == 1 then
                    buff:SetPoint("Bottom", self.buffList[i - numPerLine], "Top", 0, verticalSpacing)
                else
                    buff:SetPoint("Left", self.buffList[i - 1], "Right", horizSpacing, 0)
                end
            end
        end
    end)
end

MoveBuffs()