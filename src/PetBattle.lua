---@type Texture
local leftEndCap = PetBattleFrame.BottomFrame.LeftEndCap
leftEndCap:Hide()
---@type Texture
local rightEndCap = PetBattleFrame.BottomFrame.RightEndCap
rightEndCap:Hide()

---@type Frame
local petSelectionFrame = PetBattleFrame.BottomFrame.PetSelectionFrame
--- PetBattlePetSelectionButton 底部相对 PetSelectionFrame 底部偏移 0px，PetBattlePetSelectionButton 的高度是 200px
petSelectionFrame:SetPoint("BOTTOM", UIParent, "CENTER", 0, -200 / 2)

local xpBarWidth = 380
local numXPDivs = 5
---@type StatusBar
local xpBar = PetBattleFrameXPBar
xpBar:SetWidth(xpBarWidth)
for i = 1, 6 do
    ---@type Texture
    local div = _G["PetBattleXPBarDiv" .. i]
    if i < numXPDivs then
        div:SetPoint("CENTER", xpBar, "LEFT", floor(xpBarWidth / numXPDivs * i), 1)
    else
        div:Hide()
    end
end

--- 调整技能按钮鼠标提示的位置
hooksecurefunc("PetBattleAbilityButton_OnEnter", function(self)
    PetBattleAbilityTooltip_Show("BOTTOMLEFT", self, "TOPRIGHT")
end)
