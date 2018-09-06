-- CVar值全部重置：/console cvar_default
-- 設置CVar值：/run SetCVar("scriptErrors", 1)或/console scriptErrors 1
-- 查看CVar值：/dump GetCVar("scriptErrors")
-- 查看CVar默認值：/dump GetCVarDefault("scriptErrors")
-- 恢復CVar默認值：/run SetCVar("scriptErrors", GetCVarDefault("scriptErrors"))
SetCVar("scriptErrors", 1) -- 顯示LUA錯誤
SetCVar("alwaysCompareItems", 1) -- 總是對比裝備
SetCVar("cameraDistanceMaxZoomFactor", 2.6) -- 最大視距
SetCVar("floatingCombatTextFloatMode", 3) -- 戰鬥文字捲動顯示方式爲弧型
SetCVar("floatingCombatTextCombatHealing", 0) -- 隱藏目標戰鬥文字捲動的治療數字
SetCVar("floatingCombatTextReactives", 0) -- 隱藏戰鬥文字捲動的法術警示
SetCVar("floatingCombatTextCombatState", 1) -- 啟用進入/離開戰鬥提示
SetCVar("taintLog", 1) -- 啟用插件汙染日誌
SetCVar("rawMouseEnable", 1) -- 啟用魔獸世界滑鼠，防止視角晃動過大
SetCVar("ffxDeath", 0) -- 關閉死亡效果
SetCVar("lockActionBars", 0) -- 不鎖定快捷列
SetCVar("enableFloatingCombatText", 1) -- 啟用自己的戰鬥文字捲動
SetCVar("Sound_SFXVolume", 0.7) -- 音效音量
SetCVar("Sound_MusicVolume", 0.5) -- 音樂音量
SetCVar("Sound_AmbienceVolume", 1) -- 環境音量
SetCVar("Sound_DialogVolume", 1) -- 對話音量
SetCVar("movieSubtitle", 1) -- 啟用動畫字幕
------------------------------------------------------------------------------------------------------------------------
-- 隱藏製造者
ITEM_CREATED_BY = nil
------------------------------------------------------------------------------------------------------------------------
-- 隱藏快捷列背景
MainMenuBarArtFrameBackground:Hide()
------------------------------------------------------------------------------------------------------------------------
-- 隱藏主快捷列兩邊的材質
MainMenuBarArtFrame.LeftEndCap:Hide()
MainMenuBarArtFrame.RightEndCap:Hide()
-- 隱藏載具快捷列兩邊的材質
OverrideActionBarEndCapL:Hide()
OverrideActionBarEndCapR:Hide()
------------------------------------------------------------------------------------------------------------------------
-- 設置快捷列滑入滑出效果的距離和時間
MainMenuBar.slideOut:GetAnimations():SetOffset(0, 0)
OverrideActionBar.slideOut:GetAnimations():SetDuration(0)
------------------------------------------------------------------------------------------------------------------------
-- 技能范圍外時快捷列按鈕著色
hooksecurefunc("ActionButton_OnUpdate", function(self, elapsed)
    if (self.rangeTimer == TOOLTIP_UPDATE_TIME) then
        local valid = IsActionInRange(self.action)
        if (valid == false) then
            self.icon:SetVertexColor(0.8, 0.1, 0.1)
        else
            ActionButton_UpdateUsable(self)
        end
    end
end)
------------------------------------------------------------------------------------------------------------------------
-- 設置離開載具按鈕位置
hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
    MainMenuBarVehicleLeaveButton:ClearAllPoints()
    MainMenuBarVehicleLeaveButton:SetPoint("Left", MultiBarBottomLeftButton12, "Right", 6, 0)
end)
------------------------------------------------------------------------------------------------------------------------
-- 隱藏區域技能鍵材質
ZoneAbilityFrame.SpellButton.Style:Hide()
-- 設置區域技能鍵位置
ZoneAbilityFrame:ClearAllPoints()
ZoneAbilityFrame:SetPoint("Center", UIParent, "Center", 180, -150)
ZoneAbilityFrame.SetPoint = function()
end
------------------------------------------------------------------------------------------------------------------------
-- 隱藏額外快捷鍵材質
ExtraActionButton1.style:Hide()
-- 設置額外快捷鍵位置
ExtraActionBarFrame:ClearAllPoints()
ExtraActionBarFrame:SetPoint("Center", UIParent, "Center", -180, -150)
ExtraActionBarFrame.SetPoint = function()
end
------------------------------------------------------------------------------------------------------------------------
-- 特殊能量條始終顯示數值
hooksecurefunc("UnitPowerBarAltStatus_ToggleFrame", function(self)
    if self.enabled then
        self:Show()
        UnitPowerBarAltStatus_UpdateText(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
-- 隱藏失去控制框架的紅色邊框
LossOfControlFrame.RedLineTop:Hide()
LossOfControlFrame.RedLineBottom:Hide()
-- 設置失去控制框架位置
LossOfControlFrame:ClearAllPoints()
LossOfControlFrame:SetPoint("Center", UIParent, "Center", 0, -285)
------------------------------------------------------------------------------------------------------------------------
-- 團隊框架滑塊值
CompactUnitFrameProfilesGeneralOptionsFrameHeightSlider:SetMinMaxValues(22, 33)
CompactUnitFrameProfilesGeneralOptionsFrameWidthSlider:SetMinMaxValues(70, 114)
------------------------------------------------------------------------------------------------------------------------
-- 隱藏拾取框
LootFrame:SetAlpha(0)
------------------------------------------------------------------------------------------------------------------------
-- 聊天框
for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    -- 離左、右、上、下邊界的距離，正數向左和下移動，負數向右和上移動
    chatFrame:SetClampRectInsets(-35, 38, 38, -117)
    -- 設置聊天框的最小尺寸和最大尺寸
    chatFrame:SetMinResize(461, 181)
    chatFrame:SetMaxResize(461, 181)

    -- 隱藏輸入框的邊框
    _G["ChatFrame" .. i .. "EditBoxLeft"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxMid"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxRight"]:Hide()
    -- 設置輸入框位置
    local editBox = chatFrame.editBox
    editBox:ClearAllPoints()
    editBox:SetPoint("BottomLeft", ChatFrame1, "TopLeft", 155, -2)
    editBox:SetPoint("BottomRight", ChatFrame1, "TopRight", 25, -2)

    editBox:SetAltArrowKeyMode(false)
end
------------------------------------------------------------------------------------------------------------------------
MinimapBorderTop:Hide() -- 隱藏地點邊框
MinimapBorder:Hide() -- 隱藏地圖邊框
MiniMapWorldMapButton:Hide() -- 隱藏世界地圖按鈕
MinimapZoomIn:Hide() -- 隱藏放大按鈕
MinimapZoomOut:Hide() -- 隱藏縮小按鈕

-- 方形小地圖
Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
Minimap:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                      insets = { top = -1, left = -1, bottom = -1, right = -1 } })
Minimap:SetBackdropColor(0.53, 0.53, 0.93, 1)

-- 滾輪縮放小地圖
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(self, value)
    if value > 0 then
        MinimapZoomIn:Click()
    else
        MinimapZoomOut:Click()
    end
end)
------------------------------------------------------------------------------------------------------------------------
-- 隱藏自己的戰鬥文字捲動的治療數字
if LoadAddOn("Blizzard_CombatText") then
    COMBAT_TEXT_TYPE_INFO["HEAL"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_CRIT"] = nil
    COMBAT_TEXT_TYPE_INFO["ABSORB_ADDED"] = nil
end
------------------------------------------------------------------------------------------------------------------------
-- 設置NPC說話框架位置
if LoadAddOn("Blizzard_TalkingHeadUI") then
    TalkingHeadFrame.ignorePositionFrameManager = true
    TalkingHeadFrame:ClearAllPoints()
    TalkingHeadFrame:SetPoint("TopLeft", UIParent, "TopLeft", 10, 10)
    TalkingHeadFrame.SetPoint = function()
    end
end
------------------------------------------------------------------------------------------------------------------------
-- 自動填寫DELETE
hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
    self.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)
------------------------------------------------------------------------------------------------------------------------
-- 設置背包的位置
-- 不調整背包垂直方向的移動，例如使用物品、上下載具的時候
UIPARENT_MANAGED_FRAME_POSITIONS["CONTAINER_OFFSET_Y"] = nil
hooksecurefunc("UpdateContainerFrameAnchors", function()
    -- 修改这两个值移动
    local moveOffsetX = 0 -- 正數向左移動，負數向右移動
    local moveOffsetY = 105 -- 正數向上移動， 負數向下移動

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
        xOffset = (CONTAINER_OFFSET_X + moveOffsetX) / containerScale
        yOffset = (CONTAINER_OFFSET_Y + moveOffsetY) / containerScale
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
    xOffset = (CONTAINER_OFFSET_X + moveOffsetX) / containerScale
    yOffset = (CONTAINER_OFFSET_Y + moveOffsetY) / containerScale
    -- freeScreenHeight決定什麼時候開始新的一列
    freeScreenHeight = screenHeight - yOffset
    column = 0
    for index = 1, #ContainerFrame1.bags do
        frame = _G[ContainerFrame1.bags[index]]
        frame:SetScale(containerScale)
        if index == 1 then
            -- 第一個背包
            frame:SetPoint("BottomRight", frame:GetParent(), "BottomRight", -xOffset, yOffset)
        elseif (freeScreenHeight < frame:GetHeight()) then
            -- 開始新的一列
            column = column + 1
            freeScreenHeight = screenHeight - yOffset
            frame:SetPoint(
                    "BottomRight", frame:GetParent(), "BottomRight", -(column * CONTAINER_WIDTH) - xOffset, yOffset)
        else
            -- 以上一個背包作爲錨點
            frame:SetPoint("BottomRight", ContainerFrame1.bags[index - 1], "TopRight", 0, CONTAINER_SPACING)
        end
        freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
    end
end)