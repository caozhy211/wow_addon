local tooltip = CreateFrame("GameTooltip", "NamePlateTooltip", UIParent, "GameTooltipTemplate")

local function IsQuestUnit(unit)
    local questArea = false
    local questPlayer = false
    local questGroup = false

    local guid = UnitGUID(unit)
    if guid then
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetHyperlink("unit:" .. guid)

        for i = 3, tooltip:NumLines() do
            local line = _G["NamePlateTooltipTextLeft" .. i]
            local text = line:GetText()
            local r, g, b = line:GetTextColor()
            if r > 0.99 and g > 0.82 and b == 0 then
                questArea = true
            else
                local name, progress = text:match("^ ([^ ]-) ?%- (.+)$")
                if progress then
                    questArea = nil

                    if name then
                        local current, goal = progress:match("(%d+)/(%d+)")
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

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if frame.unit:find("nameplate") then
        local name = GetUnitName(frame.unit, true)
        if (C_Commentator.IsSpectating() and name) then
            local overrideName = C_Commentator.GetPlayerOverrideName(name)
            if overrideName then
                name = overrideName
            end
        end

        frame.name:SetText(name)

        if UnitIsUnit(frame.unit, "target") then
            -- 目標顏色
            frame.name:SetVertexColor(1, 0, 1)

            -- 目標箭頭
            if not frame.left1 then
                frame.left1 = frame:CreateTexture()
                frame.left1:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                frame.left1:SetSize(1, 30)
                frame.left1:SetPoint("Right", frame, "Left", -8, 13)
                frame.left1:SetRotation(0.5)
                frame.left2 = frame:CreateTexture()
                frame.left2:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                frame.left2:SetSize(1, 30)
                frame.left2:SetPoint("Right", frame, "Left", -8, -13)
                frame.left2:SetRotation(-0.5)

                frame.right1 = frame:CreateTexture()
                frame.right1:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                frame.right1:SetSize(1, 30)
                frame.right1:SetPoint("Left", frame, "Right", 8, 13)
                frame.right1:SetRotation(-0.5)
                frame.right2 = frame:CreateTexture()
                frame.right2:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                frame.right2:SetSize(1, 30)
                frame.right2:SetPoint("Left", frame, "Right", 8, -13)
                frame.right2:SetRotation(0.5)
            else
                frame.left1:Show()
                frame.left2:Show()
                frame.right1:Show()
                frame.right2:Show()
            end
        else
            frame.name:SetVertexColor(1, 1, 1)

            if frame.left1 then
                frame.left1:Hide()
                frame.left2:Hide()
                frame.right1:Hide()
                frame.right2:Hide()
            end
        end

        -- 字體
        frame.name:SetFont(GameFontNormal:GetFont(), 12)
        frame.name:SetPoint("Bottom", frame, "Top", 0, -25)

        frame.name:Show()

        -- 任務標記
        if IsQuestUnit(frame.unit) then
            if not frame.quest1 then
                frame.quest1 = frame:CreateTexture()
                frame.quest1:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                frame.quest1:SetSize(5, 15)
                frame.quest1:SetPoint("Left", frame, "Right", -8, 5)
                frame.quest1:SetVertexColor(1, 1, 0)

                frame.quest2 = frame:CreateTexture()
                frame.quest2:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                frame.quest2:SetSize(5, 5)
                frame.quest2:SetPoint("Top", frame.quest1, "Bottom", 0, -5)
                frame.quest2:SetVertexColor(1, 1, 0)
            else
                frame.quest1:Show()
                frame.quest2:Show()
            end
        elseif frame.quest1 then
            frame.quest1:Hide()
            frame.quest2:Hide()
        end
    end
end)

local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f億", number / 1e8)
    elseif number >= 1e4 then
        return format("%.2f萬", number / 1e4)
    end
    return number
end

-- 顯示生命值
hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
    if frame.unit:find("nameplate") then
        if not frame.healthBar.text then
            frame.healthBar.text = frame.healthBar:CreateFontString()
            frame.healthBar.text:SetFont(GameFontNormal:GetFont(), 10, "Outline")
            frame.healthBar.text:SetPoint("Center")
        end

        local current = UnitHealth(frame.displayedUnit)
        local max = UnitHealthMax(frame.displayedUnit)
        local percent = ceil(current / max * 100)

        frame.healthBar.text:SetText(FormatNumber(current) .. " - " .. percent .. "%")
    end
end)

-- DeBuff位置
hooksecurefunc(NameplateBuffContainerMixin, "UpdateBuffs", function(self, unit, filter, showAll)
    for i = 1, BUFF_MAX_DISPLAY do
        local buff = self.buffList[i]
        if buff then
            buff.CountFrame.Count:SetFont(GameFontNormal:GetFont(), 8, "Outline")

            buff:ClearAllPoints()
            if i == 1 then
                buff:SetPoint("BottomLeft", self:GetParent(), "TopLeft", 8, -10)
            elseif i % 6 == 1 then
                buff:SetPoint("Bottom", self.buffList[i - 6], "Top", 0, 2)
            else
                buff:SetPoint("Left", self.buffList[i - 1], "Right", 3, 0)
            end
        end
    end
end)