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
SlidingActionBarTexture0:SetAlpha(0)
SlidingActionBarTexture1:SetAlpha(0)