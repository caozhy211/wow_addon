UIParent:SetAttribute("TOP_OFFSET", -141)

if LoadAddOn("Blizzard_TalkingHeadUI") then
    local topOffset = UIParent:GetAttribute("TOP_OFFSET")
    TalkingHeadFrame:ClearAllPoints()
    TalkingHeadFrame:SetPoint("Center", UIParent, "TopLeft", 570 / 2, (topOffset + 11) / 2)
    TalkingHeadFrame.SetPoint = nop
end

local function MoveBuffFrame()
    local frameWidth = 30 * BUFFS_PER_ROW + 5 * (BUFFS_PER_ROW - 1)
    local buffRowSpacing = 10

    hooksecurefunc("UIParent_UpdateTopFramePositions", function()
        local buffsAreaTopOffset = 13

        if OrderHallCommandBar and OrderHallCommandBar:IsShown() then
            buffsAreaTopOffset = buffsAreaTopOffset + OrderHallCommandBar:GetHeight()
        end

        BuffFrame:SetPoint("TopRight", -570 + frameWidth, -buffsAreaTopOffset)
    end)

    hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
        local buff, aboveBuff, index
        local numBuffs = 0
        local slack = BuffFrame.numEnchants

        for i = 1, BUFF_ACTUAL_DISPLAY do
            buff = _G["BuffButton" .. i]
            numBuffs = numBuffs + 1
            index = numBuffs + slack

            if index > 1 and index % BUFFS_PER_ROW == 1 then
                buff:ClearAllPoints()
                buff:SetPoint("Top", aboveBuff, "Bottom", 0, -buffRowSpacing)
                aboveBuff = buff
            elseif index == 1 then
                aboveBuff = buff
            elseif numBuffs == 1 and slack > 0 then
                buff:ClearAllPoints()
                buff:SetPoint("TopRight", _G["TempEnchant" .. slack], "TopLeft", BUFF_HORIZ_SPACING, 0)
                aboveBuff = TempEnchant1
            end
        end
    end)

    hooksecurefunc("DebuffButton_UpdateAnchors", function(buttonName, index)
        local numBuffs = BUFF_ACTUAL_DISPLAY + BuffFrame.numEnchants

        local rows = ceil(numBuffs / BUFFS_PER_ROW)
        local buff = _G[buttonName .. index]

        if index > 1 and index % BUFFS_PER_ROW == 1 then
            buff:SetPoint("Top", _G[buttonName .. (index - BUFFS_PER_ROW)], "Bottom", 0, -buffRowSpacing)
        elseif index == 1 then
            local offsetY
            if rows < 2 then
                offsetY = 2 * buffRowSpacing + BUFF_BUTTON_HEIGHT
            else
                offsetY = rows * (buffRowSpacing + BUFF_BUTTON_HEIGHT)
            end
            buff:SetPoint("TopRight", BuffFrame, "BottomRight", 0, -offsetY)
        end
    end)

    hooksecurefunc("AuraButton_OnUpdate", function(self)
        self.duration:SetFontObject(SMALLER_AURA_DURATION_FONT)
        self.duration:ClearAllPoints()
        self.duration:SetPoint("Bottom", self, "Top")
    end)
end

local function MoveLossOfControlFrame()
    local scale = 0.7
    local bottom = 150 + 30 + 3 + 2 + 20 + 33
    local top = 360 - (405 - 360)
    LossOfControlFrame:SetScale(scale)
    LossOfControlFrame:SetPoint("Center", UIParent, "Bottom", 0, (bottom + (top - bottom) / 2) / scale)
end

local function MoveZoneAbilityFrame()
    local scale = 0.75
    ZoneAbilityFrame:SetScale(scale)
    ZoneAbilityFrame:ClearAllPoints()
    ZoneAbilityFrame:SetPoint("Center", 30 / scale, -180 / scale)
    ZoneAbilityFrame.SetPoint = nop
end

local function MoveTrackerFrame()
    ObjectiveTrackerFrame:SetMovable(true)
    ObjectiveTrackerFrame:SetUserPlaced(true)
    local listener = CreateFrame("Frame")
    listener:RegisterEvent("PLAYER_LOGIN")
    listener:SetScript("OnEvent", function()
        ObjectiveTrackerFrame:SetPoint("TopLeft", 1622 + 27, -330)
        ObjectiveTrackerFrame:SetPoint("BottomRight", -(298 - 235 - 27), 88 + 2)
    end)
end

local function MoveCompactRaidGroups()
    local spacing = 2
    local rows = 2

    local listener = CreateFrame("Frame")
    local frames = {}

    local function MoveFrame(frame)
        local totalHeight = frame.title:GetHeight()
        local totalWidth = 0
        local frame1 = _G[frame:GetName() .. "Member1"]
        frame1:ClearAllPoints()

        if CUF_HORIZONTAL_GROUPS then
            frame1:SetPoint("TopLeft", 0, -totalHeight - spacing)

            for i = 2, MEMBERS_PER_RAID_GROUP do
                local unitFrame = _G[frame:GetName() .. "Member" .. i]
                unitFrame:ClearAllPoints()
                unitFrame:SetPoint("Left", _G[frame:GetName() .. "Member" .. (i - 1)], "Right", spacing, 0)
            end

            totalHeight = totalHeight + spacing + frame1:GetHeight()
            totalWidth = totalWidth + frame1:GetWidth() * MEMBERS_PER_RAID_GROUP + spacing * (MEMBERS_PER_RAID_GROUP - 1)
        else
            local id = frame:GetID()
            if id ~= 0 and id % rows ~= 1 then
                frame.title:ClearAllPoints()
                frame.title:SetPoint("Top", 0, -spacing)
                totalHeight = totalHeight + spacing
            end
            frame1:SetPoint("TopRight", 0, -totalHeight - spacing)

            for i = 2, MEMBERS_PER_RAID_GROUP do
                local unitFrame = _G[frame:GetName() .. "Member" .. i]
                unitFrame:ClearAllPoints()
                unitFrame:SetPoint("Top", _G[frame:GetName() .. "Member" .. (i - 1)], "Bottom", 0, -spacing)
            end

            totalHeight = totalHeight + (frame1:GetHeight() + spacing) * MEMBERS_PER_RAID_GROUP
            totalWidth = totalWidth + frame1:GetWidth() + spacing
        end

        if frame.borderFrame:IsShown() then
            totalWidth = totalWidth + 12
            totalHeight = totalHeight + 4
        end

        frame:SetSize(totalWidth, totalHeight)
    end

    listener:SetScript("OnEvent", function(self, event)
        for i = 1, #frames do
            MoveFrame(frames[i])
        end
        wipe(frames)
        self:UnregisterEvent(event)
    end)

    hooksecurefunc("CompactRaidGroup_UpdateLayout", function(frame)
        if InCombatLockdown() then
            frames[#frames + 1] = frame
            if not listener:IsEventRegistered("PLAYER_REGEN_ENABLED") then
                listener:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
        else
            MoveFrame(frame)
        end
    end)
end

MoveBuffFrame()
MoveLossOfControlFrame()
MoveZoneAbilityFrame()
MoveTrackerFrame()
MoveCompactRaidGroups()