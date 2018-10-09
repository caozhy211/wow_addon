-- 隱藏快捷列背景
MainMenuBarArtFrameBackground:Hide()

-- 隱藏快捷列左右材質
MainMenuBarArtFrame.LeftEndCap:Hide()
MainMenuBarArtFrame.RightEndCap:Hide()

-- 隱藏載具快捷列左右材質
OverrideActionBarEndCapL:Hide()
OverrideActionBarEndCapR:Hide()

-- 隱藏小地圖元素
MinimapBorderTop:Hide()
MinimapBorder:Hide()
MiniMapWorldMapButton:Hide()
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()
MiniMapTrackingButtonBorder:Hide()
MiniMapTrackingBackground:Hide()
QueueStatusMinimapButtonBorder:Hide()

-- 隱藏製造者
ITEM_CREATED_BY = nil

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

-- 隱藏拾取框
--LootFrame:SetAlpha(0)

-- 隱藏滑動快捷列材質
SlidingActionBarTexture0:SetTexture(nil)
SlidingActionBarTexture1:SetTexture(nil)

-- 隱藏佔用快捷列背景
PossessBackground1:SetTexture(nil)
PossessBackground2:SetTexture(nil)

-- 隱藏佔用按鈕的正常材質
PossessButton1NormalTexture:SetTexture(nil)
PossessButton2NormalTexture:SetTexture(nil)

-- 隱藏框架
local hideFrame = CreateFrame("Frame")
hideFrame:Hide()
local function HideFrames(taint, ...)
    for i = 1, select("#", ...) do
        local frame = select(i, ...)
        frame:UnregisterAllEvents()
        frame:Hide()

        if (frame.manabar) then
            frame.manabar:UnregisterAllEvents()
        end
        if (frame.healthbar) then
            frame.healthbar:UnregisterAllEvents()
        end
        if (frame.spellbar) then
            frame.spellbar:UnregisterAllEvents()
        end
        if (frame.powerBarAlt) then
            frame.powerBarAlt:UnregisterAllEvents()
        end

        if (taint) then
            frame.Show = function()
            end
        else
            frame:SetParent(hideFrame)
            frame:HookScript("OnShow", function(self)
                if not InCombatLockdown() then
                    self:Hide()
                end
            end)
        end
    end
end

PlayerFrame:Hide()
HideFrames(false, TargetFrame, FocusFrame, LootFrame, AlertFrame)
for i = 1, MAX_BOSS_FRAMES do
    local name = "Boss" .. i .. "TargetFrame"
    HideFrames(false, _G[name], _G[name .. "HealthBar"], _G[name .. "ManaBar"])
end