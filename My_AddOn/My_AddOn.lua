-- CVar值全部重置：/console cvar_default
-- 設置CVar值：/run SetCVar("scriptErrors", 1)或/console scriptErrors 1
-- 查看CVar值：/dump GetCVar("scriptErrors")
-- 查看CVar默認值：/dump GetCVarDefault("scriptErrors")
-- 恢復CVar默認值：/run SetCVar("scriptErrors", GetCVarDefault("scriptErrors"))
-- 顯示LUA錯誤
SetCVar("scriptErrors", 1)
-- 總是對比裝備
SetCVar("alwaysCompareItems", 1)
-- 最大視距
SetCVar("cameraDistanceMaxZoomFactor", 2.6)
-- 戰鬥文字捲動顯示方式爲弧型
SetCVar("floatingCombatTextFloatMode", 3)
-- 隱藏目標戰鬥文字捲動的治療數字
SetCVar("floatingCombatTextCombatHealing", 0)
-- 隱藏戰鬥文字捲動的法術警示
SetCVar("floatingCombatTextReactives", 0)
-- 啟用進入/離開戰鬥提示
SetCVar("floatingCombatTextCombatState", 1)
-- 啟用插件汙染日誌
SetCVar("taintLog", 1)
-- 啟用魔獸世界滑鼠，防止視角晃動過大
SetCVar("rawMouseEnable", 1)
-- 關閉死亡效果
SetCVar("ffxDeath", 0)
-- 不鎖定快捷列
SetCVar("lockActionBars", 0)
-- 啟用自己的戰鬥文字捲動
SetCVar("enableFloatingCombatText", 1)
-- 音效音量
SetCVar("Sound_SFXVolume", 0.7)
-- 音樂音量
SetCVar("Sound_MusicVolume", 0.5)
-- 環境音量
SetCVar("Sound_AmbienceVolume", 1)
-- 對話音量
SetCVar("Sound_DialogVolume", 1)
-- 顯示名條的最大距離
SetCVar("nameplateMaxDistance", 40)

-- 設置快捷列滑入滑出效果的距離和時間
MainMenuBar.slideOut:GetAnimations():SetOffset(0, 0)
OverrideActionBar.slideOut:GetAnimations():SetDuration(0)

-- 技能范圍外時快捷列按鈕著色
hooksecurefunc("ActionButton_OnUpdate", function(self)
    if (self.rangeTimer == TOOLTIP_UPDATE_TIME) then
        local valid = IsActionInRange(self.action)
        if (valid == false) then
            self.icon:SetVertexColor(0.8, 0.1, 0.1)
        else
            ActionButton_UpdateUsable(self)
        end
    end
end)

-- 特殊能量條始終顯示數值
hooksecurefunc("UnitPowerBarAltStatus_ToggleFrame", function(self)
    if self.enabled then
        self:Show()
        UnitPowerBarAltStatus_UpdateText(self)
    end
end)

-- 團隊框架滑塊值
CompactUnitFrameProfilesGeneralOptionsFrameHeightSlider:SetMinMaxValues(52, 52)
CompactUnitFrameProfilesGeneralOptionsFrameWidthSlider:SetMinMaxValues(137, 137)

-- 方形小地圖
Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
Minimap:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
Minimap:SetBackdropBorderColor(0.53, 0.53, 0.93, 1)

-- 滾輪縮放小地圖
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(self, value)
    if value > 0 then
        MinimapZoomIn:Click()
    else
        MinimapZoomOut:Click()
    end
end)

-- 自動填寫DELETE
hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
    self.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)