--- PetActionButton, PossessButton, StanceButton 的大小
local BUTTON_SIZE = 30
--- PetActionButton 之间, PossessButton之间的水平间距
local SPACING1 = 8
--- StanceButton 之间的水平间距
local SPACING2 = 7
local MAX_NO_GRID_MULTI_BAR_BUTTON_INDEX = 6
local buttonSize = 29
local xpBarWidth = 360
local xpMidWidth = xpBarWidth - 16
local numDivs = 9
local divXOffset = xpBarWidth / (numDivs + 1)
local classR, classG, classB = GetClassColor(select(2, UnitClass("player")))
local backdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }
---@type Texture[]
local textures = {
    MainMenuBar.ArtFrame.LeftEndCap, MainMenuBar.ArtFrame.RightEndCap, OverrideActionBar.EndCapL,
    OverrideActionBar.EndCapR, OverrideActionBar._Border, OverrideActionBar.Divider2,
    OverrideActionBar.leaveFrame.Divider3, SlidingActionBarTexture0, SlidingActionBarTexture1,
    PossessButton1.NormalTexture, PossessBackground1, PossessButton2.NormalTexture, PossessBackground2, StanceBarLeft,
    StanceBarMiddle, StanceBarRight, ExtraActionBarFrame.button.style, ZoneAbilityFrame.Style,
}
local prefixes = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
    "MultiBarLeftButton",
}
---@type Frame[]
local actionBarFrames = { MainMenuBar.ArtFrame, MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft, }
local duration = MainMenuBar.slideOut:GetDuration()

---@type Translation
local multiBarLeftSlideOutAnim = MultiBarLeft.slideOut:GetAnimations()
---@type Translation
local multiBarRightSlideOutAnim = MultiBarRight.slideOut:GetAnimations()

MainMenuBar.ArtFrame.Background:Hide()

for _, texture in ipairs(textures) do
    texture:SetTexture(nil)
    texture:Hide()
end

for _, prefix in ipairs(prefixes) do
    for i = 1, NUM_ACTIONBAR_BUTTONS do
        local name = prefix .. i
        ---@type ActionButtonTemplate|ActionBarActionButtonMixin
        local button = _G[name]
        ---@type Texture
        local floatingBG = _G[name .. "FloatingBG"]

        Mixin(button, BackdropTemplateMixin)

        button:SetBackdrop(backdrop)
        button:SetBackdropBorderColor(classR, classG, classB)
        if prefix == "ActionButton" then
            button:SetAttribute("showgrid", ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
            button:ShowGrid(ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
        elseif prefix == "MultiBarBottomRightButton" and i <= MAX_NO_GRID_MULTI_BAR_BUTTON_INDEX then
            _G[name].noGrid = nil
        elseif prefix == "MultiBarRightButton" then
            button:SetSize(buttonSize, buttonSize)
        end

        button.NormalTexture:SetTexture(nil)
        button.FlyoutBorder:SetTexture(nil)
        button.FlyoutBorderShadow:SetTexture(nil)
        if floatingBG then
            floatingBG:SetTexture(nil)
        end
    end
end

for i = 1, NUM_STANCE_SLOTS do
    ---@type Texture
    local texture = _G["StanceButton" .. i .. "NormalTexture2"]
    texture:Hide()
end

ActionButton1:SetPoint("BOTTOMLEFT", MainMenuBar.ArtFrame.Background, 8, 2)

MultiBarBottomLeftButton1:SetPoint("BOTTOMLEFT", ActionButton1, "TOPLEFT", 0, 1)

MultiBarBottomRightButton7:SetPoint("BOTTOMLEFT", MultiBarBottomRightButton1, "TOPLEFT", 0, 1)

MultiBarRightButton1:SetPoint("TOPRIGHT", UIParent, 0, -320)

PetActionButton1:ClearAllPoints()
PetActionButton1:SetPoint("BOTTOM", UIParent, ((BUTTON_SIZE + SPACING1) * (1 - NUM_PET_ACTION_SLOTS) + 1) / 2, 100)

PossessButton1:ClearAllPoints()
PossessButton1:SetPoint("BOTTOM", UIParent, (BUTTON_SIZE + SPACING1) * (1 - NUM_POSSESS_SLOTS) / 2, 100)

StanceButton1:ClearAllPoints()
StanceButton1:SetPoint("BOTTOM", UIParent, (BUTTON_SIZE + SPACING2) * (1 - NUM_STANCE_SLOTS) / 2, 100)

MainMenuBar.VehicleLeaveButton:ClearAllPoints()
MainMenuBar.VehicleLeaveButton:SetPoint("CENTER", MultiBarBottomLeftButton12, "RIGHT", 22.5, 0)

ExtraActionBarFrame.button:ClearAllPoints()
ExtraActionBarFrame.button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -10, 155)

ZoneAbilityFrame.SpellButtonContainer:ClearAllPoints()
ZoneAbilityFrame.SpellButtonContainer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 10, 155)

-- 可能会覆盖其它框架，导致其它框架无法被点击
ExtraActionBarFrame:SetSize(0.01, 0.01)
PetActionBarFrame:SetSize(0.01, 0.01)

for _, frame in ipairs(actionBarFrames) do
    frame:SetAttribute("unit2", "player")
end

---@param self ActionButtonTemplate|ActionBarActionButtonMixin
hooksecurefunc("ActionButton_UpdateRangeIndicator", function(self, checkRange, inRange)
    if checkRange and not inRange then
        local icon = self.icon
        icon:SetVertexColor(1, 0, 0)
    elseif self.action then
        self:UpdateUsable()
    end
end)

multiBarLeftSlideOutAnim:SetDuration(duration)

multiBarRightSlideOutAnim:SetDuration(duration)

OverrideActionBar.xpBar:ClearAllPoints()
OverrideActionBar.xpBar:SetPoint("BOTTOM", OverrideActionBar._BG, "TOP")

hooksecurefunc("OverrideActionBar_CalcSize", function()
    OverrideActionBar.xpBar:SetWidth(xpBarWidth)
    OverrideActionBar.xpBar.XpMid:SetWidth(xpMidWidth)
    for i = 1, 19 do
        ---@type Texture
        local div = OverrideActionBar.xpBar["XpDiv" .. i]
        if i <= numDivs then
            div:ClearAllPoints()
            div:SetPoint("CENTER", OverrideActionBar.xpBar.XpMid, "LEFT", floor(divXOffset * i) - 8, 10)
        else
            div:Hide()
        end
    end
end)

OverrideActionBar.powerBar:HookScript("OnValueChanged", function(_, value)
    local _, maxValue = OverrideActionBar.powerBar:GetMinMaxValues()
    if maxValue > 0 then
        OverrideActionBar.powerBar.parentKey:SetFormattedText("%.0f%%", value / maxValue * 100)
    end
end)
OverrideActionBar.powerBar:HookScript("OnShow", function()
    local _, maxValue = OverrideActionBar.powerBar:GetMinMaxValues()
    if maxValue > 0 then
        local value = OverrideActionBar.powerBar:GetValue()
        OverrideActionBar.powerBar.parentKey:SetFormattedText("%.0f%%", value / maxValue * 100)
        OverrideActionBar.powerBar.parentKey:Show()
    end
end)

MainMenuBar.VehicleLeaveButton.ClearAllPoints = nop
MainMenuBar.VehicleLeaveButton.SetPoint = nop
