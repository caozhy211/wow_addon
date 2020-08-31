MainMenuBarArtFrameBackground:Hide()

---@type Texture[]
local textures = {
    MainMenuBarArtFrame.LeftEndCap, MainMenuBarArtFrame.RightEndCap, OverrideActionBarEndCapL, OverrideActionBarEndCapR,
    SlidingActionBarTexture0, SlidingActionBarTexture1, PossessButton1NormalTexture, PossessButton2NormalTexture,
    PossessBackground1, PossessBackground2,
}

for _, texture in ipairs(textures) do
    texture:SetTexture(nil)
    texture:Hide()
end

local actionBarButtonNamePrefixes = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
    "MultiBarLeftButton",
}

local _, class = UnitClass("player")
local r, g, b = GetClassColor(class)
local backdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }

for _, prefix in ipairs(actionBarButtonNamePrefixes) do
    for i = 1, NUM_ACTIONBAR_BUTTONS do
        ---@type Button|ActionButtonTemplate
        local button = _G[prefix .. i]
        ---@type Texture
        local bg = _G[button:GetName() .. "FloatingBG"]
        if bg then
            bg:SetTexture(nil)
        end
        button.NormalTexture:SetTexture(nil)
        button:SetBackdrop(backdrop)
        button:SetBackdropBorderColor(r, g, b)
        button.Name:Hide()
    end
end

local NUM_NO_GRID_MULTI_BAR_BUTTONS = 6

---@type Frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("VARIABLES_LOADED")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "VARIABLES_LOADED" then
        eventFrame:UnregisterEvent(event)
        if GetCVar("alwaysShowActionBars") == "1" then
            -- 总是显示快捷列时，显示最下面一排按钮的边框
            for i = 1, NUM_ACTIONBAR_BUTTONS do
                ---@type Button
                local button = _G["ActionButton" .. i]
                button:SetAttribute("showgrid", ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
                ActionButton_ShowGrid(button, ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
                if i <= NUM_NO_GRID_MULTI_BAR_BUTTONS then
                    button = _G["MultiBarBottomRightButton" .. i]
                    button:SetAttribute("showgrid", ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
                    ActionButton_ShowGrid(button, ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
                    button.noGrid = nil
                end
            end
        end
    end
end)

--- MultiBarBottomLeftButton1 顶部相对 OverrideActionBar 顶部的偏移值
local OFFSET_Y1 = 8
--- MultiBarBottomLeftButton1 底部相对 ActionButton1 的顶部的偏移值
local OFFSET_Y2 = 13

MultiBarBottomLeftButton1:ClearAllPoints()
MultiBarBottomLeftButton1:SetPoint("BOTTOMLEFT", ActionButton1, "TOPLEFT", 0, OFFSET_Y2 - OFFSET_Y1)
MultiBarBottomLeftButton1.SetPoint = nop

MultiBarBottomRightButton7:ClearAllPoints()
MultiBarBottomRightButton7:SetPoint("BOTTOMLEFT", MultiBarBottomRightButton1, "TOPLEFT", 0, OFFSET_Y2 - OFFSET_Y1)
MultiBarBottomRightButton7.SetPoint = nop

--- VehicleSeatIndicator 底部相对 UIParent 顶部的偏移值
local OFFSET_Y3 = -320

MultiBarRightButton1:ClearAllPoints()
MultiBarRightButton1:SetPoint("TOPRIGHT", UIParent, 0, OFFSET_Y3)
MultiBarRightButton1.SetPoint = nop

--- UIParent 右边相对 ObjectiveTrackerFrame 右边的偏移值
local offsetX1 = 31
--- MultiBarRightButton 和 MultiBarRightButtonFlyoutBorder 的宽度差
local WIDTH_DIFF1 = 6
--- MultiBarRightButton 和 MultiBarRightButtonFlyoutBorderShadow 的宽度差
local WIDTH_DIFF2 = 12

for i = 1, NUM_ACTIONBAR_BUTTONS do
    ---@type Button|ActionButtonTemplate
    local button = _G["MultiBarRightButton" .. i]
    button:SetSize(offsetX1, offsetX1)
    button.FlyoutBorder:SetSize(offsetX1 + WIDTH_DIFF1, offsetX1 + WIDTH_DIFF1)
    button.FlyoutBorderShadow:SetSize(offsetX1 + WIDTH_DIFF2, offsetX1 + WIDTH_DIFF2)
end

---@type Frame[]
local actionBars = { MainMenuBarArtFrame, MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft, }

for _, actionBar in ipairs(actionBars) do
    actionBar:SetAttribute("unit2", "player")
end

---@param self ActionButtonTemplate
hooksecurefunc("ActionButton_UpdateRangeIndicator", function(self, checksRange, inRange)
    if checksRange and not inRange then
        self.icon:SetVertexColor(1, 0, 0)
    elseif self.action then
        ActionButton_UpdateUsable(self)
    end
end)

-- 使右方快捷列的和快捷列的滑动动画时间一致，这样离开载具时，右方快捷列不会闪一下
local duration = MainMenuBar.slideOut:GetDuration()
--- @type Animation
local animation = MultiBarLeft.slideOut:GetAnimations()
animation:SetDuration(duration)
animation = MultiBarRight.slideOut:GetAnimations()
animation:SetDuration(duration)

--- OverrideActionBarXpBar 和 OverrideActionBarXpBarXpMid 的宽度差
local WIDTH_DIFF3 = 16
--- OverrideActionBarXpBarXpMidXpDiv 的数量
local NUM_DIVS = 19
--- OverrideActionBarXpBarXpMidXpDiv 中心相对 OverrideActionBarXpBarXpMid 中心的垂直偏移值
local OFFSET_Y4 = 10

local xpBarWidth = 360
local xpMidWidth = xpBarWidth - WIDTH_DIFF3
local numDivs = 9
local divOffsetX = xpBarWidth / (numDivs + 1)

hooksecurefunc("OverrideActionBar_CalcSize", function()
    OverrideActionBar.xpBar:SetWidth(xpBarWidth)
    OverrideActionBar.xpBar.XpMid:SetWidth(xpMidWidth)
    for i = 1, NUM_DIVS do
        ---@type Texture
        local div = OverrideActionBar.xpBar["XpDiv" .. i]
        div:ClearAllPoints()
        if i <= numDivs then
            div:SetPoint("CENTER", OverrideActionBar.xpBar.XpMid, "LEFT", floor(divOffsetX * i) - WIDTH_DIFF3 / 2,
                    OFFSET_Y4)
        else
            div:Hide()
        end
    end
end)

--- 更新 OverrideActionBarPowerBar 的文字标签（暴雪把 OverrideActionBarPowerBarText 的 parentKey="text" 误写成了 
--- parentKey="parentKey"）
local function UpdateOverrideActionBarPowerBarText()
    local value = OverrideActionBarPowerBar:GetValue()
    local minValue, maxValue = OverrideActionBarPowerBar:GetMinMaxValues()
    TextStatusBar_UpdateTextStringWithValues(OverrideActionBarPowerBar, OverrideActionBarPowerBar.parentKey, value,
            minValue, maxValue)
end

hooksecurefunc("UnitFrameManaBar_Update", function(statusbar, unit)
    if statusbar == OverrideActionBarPowerBar and unit == "vehicle" and not statusbar.lockValues then
        UpdateOverrideActionBarPowerBarText()
    end
end)

OverrideActionBarPowerBar:HookScript("OnUpdate", function(self)
    if not self.disconnected and not self.lockValues then
        local predictedCost = OverrideActionBarPowerBar:GetParent().predictedPowerCost
        local currValue = UnitPower(self.unit, self.powerType)
        if predictedCost then
            currValue = currValue - predictedCost
        end
        if currValue ~= self.currValue or self.forceUpdate and (self.ignoreNoUnit or UnitGUID(self.unit)) then
            UpdateOverrideActionBarPowerBarText()
        end
    end
end)

hooksecurefunc("SetTextStatusBarTextPrefix", function(manaBar, text)
    if manaBar == OverrideActionBarPowerBar then
        manaBar.prefix = text
    end
end)

--- PetActionButton 的宽度
local WIDTH1 = 30
--- PetActionButton 的高度
local HEIGHT1 = 30
--- PetActionButton 的水平间距
local SPACING1 = 8

local spacing = 5

---@type Frame
local petActionBarFrame = CreateFrame("Frame", "WlkPetActionBarFrame", UIParent)
petActionBarFrame:SetSize(WIDTH1 * NUM_PET_ACTION_SLOTS + SPACING1 * (NUM_PET_ACTION_SLOTS - 1), HEIGHT1)
petActionBarFrame:SetPoint("LEFT", UIParent, "CENTER", -petActionBarFrame:GetWidth() / 2, 0)
petActionBarFrame:SetPoint("BOTTOM", MultiBarBottomLeftButton1, "TOP", 0, spacing)

for i = 1, NUM_PET_ACTION_SLOTS do
    ---@type Button
    local button = _G["PetActionButton" .. i]
    button:ClearAllPoints()
    button:SetPoint("LEFT", petActionBarFrame, (i - 1) * (WIDTH1 + SPACING1), 0)
    button.SetPoint = nop
end

--- PossessButton 的水平间距
local SPACING2 = 8
--- PossessButton 的宽度
local WIDTH2 = 30

PossessButton1:ClearAllPoints()
PossessButton1:SetPoint("BOTTOM", petActionBarFrame, -((NUM_POSSESS_SLOTS - 1) * (WIDTH2 + SPACING2)) / 2, 0)
PossessButton1.SetPoint = nop

--- StanceButton 的水平间距
local SPACING3 = 7
--- StanceButton 的宽度
local WIDTH3 = 30

StanceButton1:ClearAllPoints()
StanceButton1:SetPoint("BOTTOM", petActionBarFrame, -((NUM_STANCE_SLOTS - 1) * (WIDTH3 + SPACING3)) / 2, 0)
StanceButton1.SetPoint = nop

--- MultiBarBottomRightButton7 左边相对 MultiBarBottomLeftButton12 右边的偏移值
local OFFSET_X1 = 45

hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
    MainMenuBarVehicleLeaveButton:ClearAllPoints()
    MainMenuBarVehicleLeaveButton:SetPoint("CENTER", MultiBarBottomLeftButton12, "RIGHT", OFFSET_X1 / 2, 0)
end)

--- WorldMapFrame 底部相对 UIParent 底部的偏移值
local OFFSET_Y5 = 433
--- ZoneAbilityFrame.SpellButton.Style 和 ExtraActionButton1.style 的高度
local HEIGHT2 = 128

local scale = 0.5

ExtraActionBarFrame:SetScale(scale)
ExtraActionBarFrame:ClearAllPoints()
ExtraActionBarFrame:SetPoint("CENTER", UIParent, "BOTTOM", 0, (OFFSET_Y5 - HEIGHT2 / 2 * scale) / scale)
ExtraActionBarFrame.SetPoint = nop

ZoneAbilityFrame:SetScale(scale)
ZoneAbilityFrame:ClearAllPoints()
ZoneAbilityFrame:SetPoint("CENTER", UIParent, "BOTTOM", 0, (OFFSET_Y5 - (HEIGHT2 + HEIGHT2 / 2) * scale) / scale)
ZoneAbilityFrame.SetPoint = nop
