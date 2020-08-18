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

local NUM_MULTI_BAR_BUTTON_IN_MAIN_MENU_BAR = 6

---@type Frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("VARIABLES_LOADED")

eventFrame:SetScript("OnEvent", function(_, event)
    eventFrame:UnregisterEvent(event)
    if GetCVar("alwaysShowActionBars") == "1" then
        -- 总是显示快捷列时，显示最下面一排按钮的边框
        for i = 1, NUM_ACTIONBAR_BUTTONS do
            ---@type Button
            local button = _G["ActionButton" .. i]
            button:SetAttribute("showgrid", ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
            ActionButton_ShowGrid(button, ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
            if i <= NUM_MULTI_BAR_BUTTON_IN_MAIN_MENU_BAR then
                button = _G["MultiBarBottomRightButton" .. i]
                button:SetAttribute("showgrid", ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
                ActionButton_ShowGrid(button, ACTION_BUTTON_SHOW_GRID_REASON_CVAR)
                button.noGrid = nil
            end
        end
    end
end)

--- MultiBarBottomLeftButton 顶部相对 OverrideActionBar 顶部的偏移值
local OFFSET_Y3 = 8
--- MultiBarBottomLeftButton 和 ActionButton 的垂直间距
local SPACING5 = 13

MultiBarBottomLeftButton1:ClearAllPoints()
MultiBarBottomLeftButton1:SetPoint("BOTTOMLEFT", ActionButton1, "TOPLEFT", 0, SPACING5 - OFFSET_Y3)
MultiBarBottomLeftButton1.SetPoint = nop

MultiBarBottomRightButton7:ClearAllPoints()
MultiBarBottomRightButton7:SetPoint("BOTTOMLEFT", MultiBarBottomRightButton1, "TOPLEFT", 0, SPACING5 - OFFSET_Y3)
MultiBarBottomRightButton7.SetPoint = nop

--- VehicleSeatIndicator 底部相对 UIParent 顶部的偏移值
local OFFSET_Y1 = -320
MultiBarRightButton1:ClearAllPoints()
MultiBarRightButton1:SetPoint("TOPRIGHT", UIParent, 0, OFFSET_Y1)
MultiBarRightButton1.SetPoint = nop

--- ObjectiveTrackerFrame 的宽度
local WIDTH1 = 235
--- QuestPOIButtonNormalTexture 的宽度
local WIDTH2 = 32
--- MultiBarRightButton 和 MultiBarRightButtonFlyoutBorder 的差距
local MARGIN1 = 6
--- MultiBarRightButton 和 MultiBarRightButtonFlyoutBorderShadow 的差距
local MARGIN2 = 12

--- QuestPOIButtonNormalTexture 左边相对 UIParent 右边的偏移值
local offsetX = -298
local width = -offsetX - WIDTH1 - WIDTH2

for i = 1, NUM_ACTIONBAR_BUTTONS do
    ---@type Button|ActionButtonTemplate
    local button = _G["MultiBarRightButton" .. i]
    button:SetSize(width, width)
    button.FlyoutBorder:SetSize(width + MARGIN1, width + MARGIN1)
    button.FlyoutBorderShadow:SetSize(width + MARGIN2, width + MARGIN2)
end

---@type Frame[]
local actionBars = { MainMenuBarArtFrame, MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft, }

for _, actionBar in ipairs(actionBars) do
    actionBar:SetAttribute("unit2", "player")
end

---@param self ActionButtonTemplate
hooksecurefunc("ActionButton_UpdateRangeIndicator", function(self, checksRange, inRange)
    if checksRange and not inRange then
        self.icon:SetVertexColor(GetTableColor(RED_FONT_COLOR))
    elseif self.action then
        ActionButton_UpdateUsable(self)
    end
end)

-- 使右方快捷列的和快捷列的滑动动画时间一致，这样离开载具，右方快捷列出现时不会闪一下
local duration = MainMenuBar.slideOut:GetDuration()
--- @type Animation
local animation = MultiBarLeft.slideOut:GetAnimations()
animation:SetDuration(duration)
animation = MultiBarRight.slideOut:GetAnimations()
animation:SetDuration(duration)

--- OverrideActionBarXpBar 和 OverrideActionBarXpBarXpMid 的宽度差
local DIFF1 = 16
--- OverrideActionBarXpBarXpMidXpDiv 的数量
local NUM_DIV = 19
--- OverrideActionBarXpBarXpMidXpDiv 中心相对 OverrideActionBarXpBarXpMid 中心的垂直偏移值
local OFFSET_Y2 = 10

local xpBarWidth = 360
local xpMidWidth = 360 - DIFF1
local numDiv = 9
local divOffsetX = xpBarWidth / (numDiv + 1)

hooksecurefunc("OverrideActionBar_CalcSize", function()
    OverrideActionBar.xpBar:SetWidth(xpBarWidth)
    OverrideActionBar.xpBar.XpMid:SetWidth(xpMidWidth)
    for i = 1, NUM_DIV do
        ---@type Texture
        local div = OverrideActionBar.xpBar["XpDiv" .. i]
        div:ClearAllPoints()
        if i <= numDiv then
            div:SetPoint("CENTER", OverrideActionBar.xpBar.XpMid, "LEFT", floor(divOffsetX * i) - DIFF1 / 2, OFFSET_Y2)
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

---@param self StatusBar
OverrideActionBarPowerBar:HookScript("OnUpdate", function(self)
    if not self.disconnected and not self.lockValues then
        local predictedCost = self:GetParent().predictedPowerCost
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
local WIDTH3 = 30
--- PetActionButton 的高度
local HEIGHT1 = 30
--- PetActionButton 的水平间距
local SPACING1 = 8

local spacing = 5

---@type Frame
local petActionBarFrame = CreateFrame("Frame", "WlkPetActionBarFrame", UIParent)
petActionBarFrame:SetSize(WIDTH3 * NUM_PET_ACTION_SLOTS + SPACING1 * (NUM_PET_ACTION_SLOTS - 1), HEIGHT1)
petActionBarFrame:SetPoint("LEFT", UIParent, "CENTER", -petActionBarFrame:GetWidth() / 2, 0)
petActionBarFrame:SetPoint("BOTTOM", MultiBarBottomLeftButton1, "TOP", 0, spacing)

for i = 1, NUM_PET_ACTION_SLOTS do
    ---@type Button
    local button = _G["PetActionButton" .. i]
    button:ClearAllPoints()
    button:SetPoint("LEFT", petActionBarFrame, (i - 1) * (WIDTH3 + SPACING1), 0)
    button.SetPoint = nop
end

--- PossessButton 的水平间距
local SPACING2 = 8
--- PossessButton 的宽度
local WIDTH4 = 30

PossessButton1:ClearAllPoints()
PossessButton1:SetPoint("BOTTOM", petActionBarFrame, -((NUM_POSSESS_SLOTS - 1) * (WIDTH4 + SPACING2)) / 2, 0)
PossessButton1.SetPoint = nop

--- StanceButton 的水平间距
local SPACING3 = 7
--- StanceButton 的宽度
local WIDTH5 = 30

StanceButton1:ClearAllPoints()
StanceButton1:SetPoint("BOTTOM", petActionBarFrame, -((NUM_STANCE_SLOTS - 1) * (WIDTH5 + SPACING3)) / 2, 0)
StanceButton1.SetPoint = nop

--- MultiBarBottomLeftButton12 和 MultiBarBottomRightButton7 的水平间距
local SPACING4 = 45

hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
    MainMenuBarVehicleLeaveButton:ClearAllPoints()
    MainMenuBarVehicleLeaveButton:SetPoint("CENTER", MultiBarBottomLeftButton12, "RIGHT", SPACING4 / 2, 0)
end)
