PetBattleFrame.BottomFrame.LeftEndCap:Hide()
PetBattleFrame.BottomFrame.RightEndCap:Hide()

PetBattleFrame.BottomFrame.PetSelectionFrame:SetPoint("Bottom", UIParent, "Center", 0, -200 / 2)

local xpBarWidth = 360
local numXPDivs = 5
PetBattleFrameXPBar:SetWidth(xpBarWidth)
for i = 1, 6 do
    local texture = _G["PetBattleXPBarDiv" .. i]
    if i < numXPDivs then
        texture:SetPoint("Left", floor(xpBarWidth / numXPDivs * i - 9 / 2), 1)
    else
        texture:Hide()
    end
end

hooksecurefunc("PetBattleAbilityButton_OnEnter", function(self)
    PetBattleAbilityTooltip_Show("BottomLeft", self, "TopRight")
end)