local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function()
    -- 移動特殊能量條
    PlayerPowerBarAlt:SetMovable(true)
    PlayerPowerBarAlt:SetUserPlaced(true)
    PlayerPowerBarAlt:ClearAllPoints()
    PlayerPowerBarAlt:SetPoint("Center", UIParent, 255, -120)

    -- 移動追蹤框架
    ObjectiveTrackerFrame:SetMovable(true)
    ObjectiveTrackerFrame:SetUserPlaced(true)
    ObjectiveTrackerFrame:ClearAllPoints()
    ObjectiveTrackerFrame:SetPoint("TopRight", UIParent, -50, -330)
    ObjectiveTrackerFrame:SetHeight(673)
end)

for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    -- 離左、右、上、下邊界的距離，正數向左和下移動，負數向右和上移動
    chatFrame:SetClampRectInsets(-35, 38, 38, -117)
    -- 設置聊天框的最小尺寸和最大尺寸
    chatFrame:SetMinResize(481, 181)
    chatFrame:SetMaxResize(481, 181)

    -- 隱藏輸入框的邊框
    _G["ChatFrame" .. i .. "EditBoxLeft"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxMid"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxRight"]:Hide()
    -- 移動輸入框
    local editBox = chatFrame.editBox
    editBox:ClearAllPoints()
    editBox:SetPoint("BottomLeft", ChatFrame1, "TopLeft", 155, -2)
    editBox:SetPoint("BottomRight", ChatFrame1, "TopRight", 5, -2)

    editBox:SetAltArrowKeyMode(false)
end

-- 移動寵物快捷列
local petBar = CreateFrame("Frame", "PetBarFrame", UIParent)

petBar:SetWidth(372)
petBar:SetHeight(30)
petBar:SetPoint("BottomLeft", 566, 113)

petBar:RegisterEvent("PET_BATTLE_OPENING_START")
petBar:RegisterEvent("PET_BATTLE_OPENING_DONE")
petBar:RegisterEvent("PET_BATTLE_CLOSE")

for i = 1, 10 do
    local button = _G["PetActionButton" .. i]
    button:ClearAllPoints()
    button:SetPoint("Left", petBar, (i - 1) * 38, 0)
end

petBar:SetScript("OnEvent", function(self, event)
    if event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_OPENING_DONE" then
        self:Hide()
    else
        self:Show()
    end
end)

-- 移動失去控制框架
LossOfControlFrame:SetPoint("Center", UIParent, 0, -245)

-- 移動姿態快捷列
StanceBarFrame:ClearAllPoints()
StanceBarFrame:SetPoint("BottomLeft", UIParent, 935, 110)
StanceBarFrame.SetPoint = function()
end

-- 移動區域技能鍵
ZoneAbilityFrame:SetScale(0.75)
ZoneAbilityFrame:ClearAllPoints()
ZoneAbilityFrame:SetPoint("Center", UIParent, 40, -200)
ZoneAbilityFrame.SetPoint = function()
end

-- 移動額外快捷鍵
ExtraActionBarFrame:SetScale(0.75)
ExtraActionBarFrame:ClearAllPoints()
ExtraActionBarFrame:SetPoint("Center", UIParent, -200, -200)
ExtraActionBarFrame.SetPoint = function()
end

-- 移動NPC說話框架
if LoadAddOn("Blizzard_TalkingHeadUI") then
    TalkingHeadFrame:ClearAllPoints()
    TalkingHeadFrame:SetPoint("TopLeft", UIParent, 10, 10)
    TalkingHeadFrame.SetPoint = function()
    end
end

-- 移動離開載具按鈕
hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
    MainMenuBarVehicleLeaveButton:ClearAllPoints()
    MainMenuBarVehicleLeaveButton:SetPoint("BottomLeft", MainMenuBar, 512, 55)
end)

-- 移動增益框架
hooksecurefunc("UIParent_UpdateTopFramePositions", function()
    local buffsAreaTopOffset = 13

    if (OrderHallCommandBar and OrderHallCommandBar:IsShown()) then
        buffsAreaTopOffset = buffsAreaTopOffset + OrderHallCommandBar:GetHeight();
    end

    BuffFrame:SetPoint("TOPRIGHT", UIParent, -295, 0 - buffsAreaTopOffset);
end)

-- 移動自己的增益光環
hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
    local BUFF_ROW_SPACING = 10

    local buff, aboveBuff, index
    local numBuffs = 0
    local slack = BuffFrame.numEnchants

    for i = 1, BUFF_ACTUAL_DISPLAY do
        buff = _G["BuffButton" .. i]
        numBuffs = numBuffs + 1
        index = numBuffs + slack

        if index > 1 and index % BUFFS_PER_ROW == 1 then
            -- New row
            buff:ClearAllPoints()
            buff:SetPoint("Top", aboveBuff, "Bottom", 0, -BUFF_ROW_SPACING)
            aboveBuff = buff
        elseif index == 1 then
            aboveBuff = buff
        elseif numBuffs == 1 and slack > 0 then
            buff:ClearAllPoints()
            buff:SetPoint("TOPRIGHT", _G["TempEnchant" .. slack], "TOPLEFT", BUFF_HORIZ_SPACING, 0);
            aboveBuff = TempEnchant1
        end
    end
end)

-- 移動自己的減益光環
hooksecurefunc("DebuffButton_UpdateAnchors", function(buttonName, index)
    local BUFF_ROW_SPACING = 10

    local numBuffs = BUFF_ACTUAL_DISPLAY + BuffFrame.numEnchants

    local rows = ceil(numBuffs / BUFFS_PER_ROW)
    local buff = _G[buttonName .. index]

    -- Position debuffs
    if index > 1 and index % BUFFS_PER_ROW == 1 then
        -- New row
        buff:SetPoint("Top", _G[buttonName .. (index - BUFFS_PER_ROW)], "Bottom", 0, -BUFF_ROW_SPACING)
    elseif index == 1 then
        local offsetY
        if rows < 2 then
            offsetY = 2 * BUFF_ROW_SPACING + BUFF_BUTTON_HEIGHT
        else
            offsetY = rows * (BUFF_ROW_SPACING + BUFF_BUTTON_HEIGHT)
        end
        buff:SetPoint("TopRight", BuffFrame, "BottomRight", 0, -offsetY)
    end
end)

-- 移動自己的光環計時
hooksecurefunc("AuraButton_OnUpdate", function(self)
    self.duration:SetFontObject(SMALLER_AURA_DURATION_FONT)
    self.duration:ClearAllPoints()
    self.duration:SetPoint("Bottom", self, "Top")
end)

-- 不改變背包錨點垂直方向的位置
UIPARENT_MANAGED_FRAME_POSITIONS["CONTAINER_OFFSET_Y"] = nil
-- 移動背包
hooksecurefunc("UpdateContainerFrameAnchors", function()
    local CONTAINER_OFFSET_Y = 190

    local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
    local screenWidth = GetScreenWidth()
    local containerScale = 1
    local leftLimit = 0
    if BankFrame:IsShown() then
        leftLimit = BankFrame:GetRight() - 25
    end

    while containerScale > CONTAINER_SCALE do
        screenHeight = GetScreenHeight() / containerScale
        -- 根據快捷列調整背包的起始錨點
        xOffset = CONTAINER_OFFSET_X / containerScale
        yOffset = CONTAINER_OFFSET_Y / containerScale
        -- freeScreenHeight決定什麼時候開始新的一列
        freeScreenHeight = screenHeight - yOffset
        leftMostPoint = screenWidth - xOffset
        column = 1
        local frameHeight
        for index = 1, #ContainerFrame1.bags do
            frameHeight = _G[ContainerFrame1.bags[index]]:GetHeight()
            if freeScreenHeight < frameHeight then
                -- 開始新的一列
                column = column + 1
                leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
                freeScreenHeight = screenHeight - yOffset
            end
            freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
        end
        if leftMostPoint < leftLimit then
            containerScale = containerScale - 0.01
        else
            break
        end
    end

    if containerScale < CONTAINER_SCALE then
        containerScale = CONTAINER_SCALE
    end

    screenHeight = GetScreenHeight() / containerScale
    -- 根據快捷列調整背包的起始錨點
    xOffset = CONTAINER_OFFSET_X / containerScale
    yOffset = CONTAINER_OFFSET_Y / containerScale
    -- freeScreenHeight決定什麼時候開始新的一列
    freeScreenHeight = screenHeight - yOffset
    column = 0
    for index = 1, #ContainerFrame1.bags do
        frame = _G[ContainerFrame1.bags[index]]
        frame:SetScale(containerScale)
        if index == 1 then
            -- 第一個背包
            frame:SetPoint("BottomRight", -xOffset, yOffset)
        elseif (freeScreenHeight < frame:GetHeight()) then
            -- 開始新的一列
            column = column + 1
            freeScreenHeight = screenHeight - yOffset
            frame:SetPoint("BottomRight", -(column * CONTAINER_WIDTH) - xOffset, yOffset)
        else
            -- 以上一個背包作爲錨點
            frame:SetPoint("BottomRight", ContainerFrame1.bags[index - 1], "TopRight", 0, CONTAINER_SPACING)
        end
        freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
    end
end)
